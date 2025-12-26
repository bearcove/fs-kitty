import FSKit
import Foundation
import os

/// FSKit Volume implementation that delegates to the Rust VFS client.
final class Volume: FSVolume {

    private let log = Logger(subsystem: "FsKittyExt", category: "Volume")

    /// Item cache: itemId -> Item
    private var items: [UInt64: Item] = [:]

    /// Root item ID (always 1 in our VFS protocol)
    private let rootId: UInt64 = 1

    init() {
        let volumeId = FSVolume.Identifier(uuid: UUID())
        let volumeName = FSFileName(string: "FsKitty")
        super.init(volumeID: volumeId, volumeName: volumeName)
    }

    // MARK: - Item Cache

    private func cacheItem(_ item: Item) {
        items[item.itemId] = item
    }

    private func getItem(_ fsItem: FSItem, fn: StaticString = #function) throws -> Item {
        guard let item = fsItem as? Item else {
            log.e("\(fn): unexpected FSItem type")
            throw fs_errorForPOSIXError(POSIXError.EINVAL.rawValue)
        }
        return item
    }
}

// MARK: - FSVolume.Operations

extension Volume: FSVolume.Operations {
    var supportedVolumeCapabilities: FSVolume.SupportedCapabilities {
        let caps = FSVolume.SupportedCapabilities()
        caps.supportsSymbolicLinks = false  // TODO: enable when implemented
        caps.supportsHardLinks = false
        caps.supportsPersistentObjectIDs = true
        caps.supports64BitObjectIDs = true
        caps.caseFormat = .sensitive
        return caps
    }

    var volumeStatistics: FSStatFSResult {
        log.d("volumeStatistics")
        // Return basic stats - in production, query the backend
        let stats = FSStatFSResult(fileSystemTypeName: "fskitty")
        stats.blockSize = 4096
        stats.ioSize = 4096
        stats.totalBlocks = 1_000_000
        stats.freeBlocks = 500_000
        stats.availableBlocks = 500_000
        stats.totalFiles = 100_000
        stats.freeFiles = 50_000
        return stats
    }

    func mount(options: FSTaskOptions) async throws {
        log.d("mount")
        // Connection is already established in Bridge.loadResource
    }

    func unmount() async {
        log.d("unmount")
        items.removeAll()
    }

    func synchronize(flags: FSSyncFlags) async throws {
        log.d("synchronize")
        // Our VFS is already synchronized (memory-based for now)
    }

    func activate(options: FSTaskOptions) async throws -> FSItem {
        log.d("activate - returning root item")

        // Get root directory attributes from VFS
        let attrs = try vfs_get_attributes(rootId)

        let rootAttrs = FSItem.Attributes.fromVfs(
            itemId: attrs.item_id,
            itemType: attrs.item_type,
            size: attrs.size,
            modifiedTime: attrs.modified_time,
            createdTime: attrs.created_time,
            mode: attrs.mode
        )

        // Mark as root directory
        if let id = FSItem.Identifier(rawValue: 1) {
            rootAttrs.parentID = id
        }

        let root = Item(itemId: rootId, name: "", attributes: rootAttrs)
        cacheItem(root)
        return root
    }

    func deactivate(options: FSDeactivateOptions = []) async throws {
        log.d("deactivate")
        items.removeAll()
    }

    func attributes(
        _ desiredAttributes: FSItem.GetAttributesRequest,
        of fsItem: FSItem
    ) async throws -> FSItem.Attributes {
        let item = try getItem(fsItem)
        log.d("attributes: itemId=\(item.itemId)")

        let attrs = try vfs_get_attributes(item.itemId)

        let fsAttrs = FSItem.Attributes.fromVfs(
            itemId: attrs.item_id,
            itemType: attrs.item_type,
            size: attrs.size,
            modifiedTime: attrs.modified_time,
            createdTime: attrs.created_time,
            mode: attrs.mode
        )
        item.updateAttributes(fsAttrs)
        return fsAttrs
    }

    func setAttributes(
        _ newAttributes: FSItem.SetAttributesRequest,
        on fsItem: FSItem
    ) async throws -> FSItem.Attributes {
        let item = try getItem(fsItem)
        log.d("setAttributes: itemId=\(item.itemId)")
        // For now, just return current attributes (read-only VFS)
        return item.cachedAttributes
    }

    func lookupItem(
        named name: FSFileName,
        inDirectory directory: FSItem
    ) async throws -> (FSItem, FSFileName) {
        let dirItem = try getItem(directory)
        let nameStr = name.string ?? ""
        log.d("lookupItem: name=\(nameStr) in dir=\(dirItem.itemId)")

        let result = try vfs_lookup(dirItem.itemId, nameStr)

        if result.error != 0 {
            log.d("lookupItem: not found (error=\(result.error))")
            throw fs_errorForPOSIXError(result.error)
        }

        // Get full attributes for the found item
        let attrs = try vfs_get_attributes(result.item_id)

        let itemType: UInt8
        switch result.item_type {
        case 0: itemType = 0  // File
        case 1: itemType = 1  // Directory
        case 2: itemType = 2  // Symlink
        default: itemType = 0
        }

        let fsAttrs = FSItem.Attributes.fromVfs(
            itemId: result.item_id,
            itemType: itemType,
            size: attrs.size,
            modifiedTime: attrs.modified_time,
            createdTime: attrs.created_time,
            mode: attrs.mode
        )

        // Check if we already have this item cached
        if let existing = items[result.item_id] {
            existing.updateAttributes(fsAttrs)
            return (existing, existing.name)
        }

        let item = Item(itemId: result.item_id, name: nameStr, attributes: fsAttrs)
        cacheItem(item)
        return (item, item.name)
    }

    func reclaimItem(_ fsItem: FSItem) async throws {
        let item = try getItem(fsItem)
        log.d("reclaimItem: itemId=\(item.itemId)")
        items.removeValue(forKey: item.itemId)
    }

    func readSymbolicLink(_ fsItem: FSItem) async throws -> FSFileName {
        let item = try getItem(fsItem)
        log.d("readSymbolicLink: itemId=\(item.itemId)")
        // TODO: implement symlink reading
        throw fs_errorForPOSIXError(POSIXError.ENOTSUP.rawValue)
    }

    func createItem(
        named name: FSFileName,
        type: FSItem.ItemType,
        inDirectory directory: FSItem,
        attributes newAttributes: FSItem.SetAttributesRequest
    ) async throws -> (FSItem, FSFileName) {
        let dirItem = try getItem(directory)
        let nameStr = name.string ?? ""
        log.d("createItem: name=\(nameStr) in dir=\(dirItem.itemId)")

        let vfsType: UInt8 = (type == .directory) ? 1 : 0
        let result = try vfs_create(dirItem.itemId, nameStr, vfsType)

        if result.error != 0 {
            throw fs_errorForPOSIXError(result.error)
        }

        // Get attributes for new item
        let attrs = try vfs_get_attributes(result.item_id)

        let fsAttrs = FSItem.Attributes.fromVfs(
            itemId: result.item_id,
            itemType: vfsType,
            size: attrs.size,
            modifiedTime: attrs.modified_time,
            createdTime: attrs.created_time,
            mode: attrs.mode
        )

        let item = Item(itemId: result.item_id, name: nameStr, attributes: fsAttrs)
        cacheItem(item)
        return (item, item.name)
    }

    func createSymbolicLink(
        named name: FSFileName,
        inDirectory directory: FSItem,
        attributes newAttributes: FSItem.SetAttributesRequest,
        linkContents contents: FSFileName
    ) async throws -> (FSItem, FSFileName) {
        log.d("createSymbolicLink: not supported")
        throw fs_errorForPOSIXError(POSIXError.ENOTSUP.rawValue)
    }

    func createLink(
        to item: FSItem,
        named name: FSFileName,
        inDirectory directory: FSItem
    ) async throws -> FSFileName {
        log.d("createLink: not supported (hard links)")
        throw fs_errorForPOSIXError(POSIXError.ENOTSUP.rawValue)
    }

    func removeItem(
        _ fsItem: FSItem,
        named name: FSFileName,
        fromDirectory directory: FSItem
    ) async throws {
        let item = try getItem(fsItem)
        log.d("removeItem: itemId=\(item.itemId)")

        let result = try vfs_delete(item.itemId)

        if result.error != 0 {
            throw fs_errorForPOSIXError(result.error)
        }

        items.removeValue(forKey: item.itemId)
    }

    func renameItem(
        _ fsItem: FSItem,
        inDirectory sourceDirectory: FSItem,
        named sourceName: FSFileName,
        to destinationName: FSFileName,
        inDirectory destinationDirectory: FSItem,
        overItem: FSItem?
    ) async throws -> FSFileName {
        let item = try getItem(fsItem)
        let destDir = try getItem(destinationDirectory)
        let destName = destinationName.string ?? ""
        log.d("renameItem: itemId=\(item.itemId) -> \(destName) in \(destDir.itemId)")

        let result = try vfs_rename(item.itemId, destDir.itemId, destName)

        if result.error != 0 {
            throw fs_errorForPOSIXError(result.error)
        }

        return destinationName
    }

    func enumerateDirectory(
        _ directory: FSItem,
        startingAt cookie: FSDirectoryCookie,
        verifier: FSDirectoryVerifier,
        attributes: FSItem.GetAttributesRequest?,
        packer: FSDirectoryEntryPacker
    ) async throws -> FSDirectoryVerifier {
        let dirItem = try getItem(directory)
        log.d("enumerateDirectory: itemId=\(dirItem.itemId) cookie=\(cookie.rawValue)")

        let result = try vfs_read_dir(dirItem.itemId, cookie.rawValue)

        if result.error != 0 {
            throw fs_errorForPOSIXError(result.error)
        }

        // Iterate using parallel arrays (swift-bridge doesn't support Vec<Struct> yet)
        let count = result.names.len()
        var nextCookie: UInt64 = 1
        var i: UInt = 0
        while i < count {
            let nameStr = result.names.get(index: i)!.as_str().toString()
            let itemId = result.item_ids.get(index: i)!
            let itemType = result.item_types.get(index: i)!

            // DirEntry doesn't include mode, use default based on type
            // Real mode is fetched when lookupItem or attributes is called
            let defaultMode: UInt32 = (itemType == 1) ? 0o755 : 0o644
            let entryAttrs = FSItem.Attributes.fromVfs(
                itemId: itemId,
                itemType: itemType,
                size: 0,  // Size not included in DirEntry
                modifiedTime: 0,
                createdTime: 0,
                mode: defaultMode
            )

            let entryItem = Item(itemId: itemId, name: nameStr, attributes: entryAttrs)
            cacheItem(entryItem)

            let shouldContinue = packer.packEntry(
                name: FSFileName(string: nameStr),
                itemType: entryAttrs.type,
                itemID: entryAttrs.fileID,
                nextCookie: FSDirectoryCookie(nextCookie),
                attributes: attributes != nil ? entryAttrs : nil
            )

            if !shouldContinue {
                break
            }
            nextCookie += 1
            i += 1
        }

        return FSDirectoryVerifier(result.next_cursor)
    }
}

// MARK: - FSVolume.ReadWriteOperations

extension Volume: FSVolume.ReadWriteOperations {
    func read(
        from fsItem: FSItem,
        at offset: off_t,
        length: Int,
        into buffer: FSMutableFileDataBuffer
    ) async throws -> Int {
        let item = try getItem(fsItem)
        log.d("read: itemId=\(item.itemId) offset=\(offset) length=\(length)")

        let result = try vfs_read(item.itemId, UInt64(offset), UInt64(length))

        if result.error != 0 {
            throw fs_errorForPOSIXError(result.error)
        }

        // Copy from RustVec to buffer
        let dataLen = result.data.len()
        let copyLen = min(buffer.length, Int(dataLen))

        _ = buffer.withUnsafeMutableBytes { dst in
            for i in 0..<copyLen {
                if let byte = result.data.get(index: UInt(i)) {
                    dst.storeBytes(of: byte, toByteOffset: i, as: UInt8.self)
                }
            }
        }

        return copyLen
    }

    func write(
        contents: Data,
        to fsItem: FSItem,
        at offset: off_t
    ) async throws -> Int {
        let item = try getItem(fsItem)
        log.d("write: itemId=\(item.itemId) offset=\(offset) length=\(contents.count)")

        // Convert Data to RustVec<UInt8>
        let rustVec = RustVec<UInt8>()
        for byte in contents {
            rustVec.push(value: byte)
        }

        let result = try vfs_write(item.itemId, UInt64(offset), rustVec)

        if result.error != 0 {
            throw fs_errorForPOSIXError(result.error)
        }

        return Int(result.bytes_written)
    }
}

// MARK: - FSVolume.PathConfOperations

extension Volume: FSVolume.PathConfOperations {
    var maximumLinkCount: Int { 1 }
    var maximumNameLength: Int { 255 }
    var restrictsOwnershipChanges: Bool { true }
    var truncatesLongNames: Bool { false }
    var maximumXattrSize: Int { 0 }
    var maximumXattrSizeInBits: Int { 0 }
    var maximumFileSize: UInt64 { UInt64.max }
    var maximumFileSizeInBits: Int { 64 }
}

// MARK: - FSVolume.OpenCloseOperations

extension Volume: FSVolume.OpenCloseOperations {
    var isOpenCloseInhibited: Bool {
        get { true }  // We don't track open/close state
        set { }
    }

    func openItem(_ item: FSItem, modes: FSVolume.OpenModes) async throws {
        // No-op: we don't track open state
    }

    func closeItem(_ item: FSItem, modes: FSVolume.OpenModes) async throws {
        // No-op: we don't track open state
    }
}

// MARK: - FSVolume.AccessCheckOperations

extension Volume: FSVolume.AccessCheckOperations {
    var isAccessCheckInhibited: Bool {
        get { true }  // Allow all access for now
        set { }
    }

    func checkAccess(
        to theItem: FSItem,
        requestedAccess access: FSVolume.AccessMask
    ) async throws -> Bool {
        return true  // Allow all access
    }
}
