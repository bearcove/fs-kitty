import FSKit
import Foundation
import os

/// FSKit Volume implementation that delegates to the VFS client.
final class Volume: FSVolume {

    private let log = Logger(subsystem: "me.amos.fs-kitty.ext", category: "Volume")

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
            log.error("\(fn): unexpected FSItem type")
            throw fs_errorForPOSIXError(POSIXError.EINVAL.rawValue)
        }
        return item
    }

    // MARK: - VFS Client Access

    private func client() async throws -> VfsClient {
        try await VfsConnection.shared.getClient()
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
        log.debug("volumeStatistics")
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
        log.debug("mount")
        // Connection is already established in Bridge.loadResource
    }

    func unmount() async {
        log.debug("unmount")
        items.removeAll()
    }

    func synchronize(flags: FSSyncFlags) async throws {
        log.debug("synchronize")
        // Our VFS is already synchronized (memory-based for now)
    }

    func activate(options: FSTaskOptions) async throws -> FSItem {
        log.debug("activate - returning root item")

        // Get root directory attributes from VFS
        let vfsClient = try await client()
        let result = try await vfsClient.getAttributes(itemId: rootId)

        if result.error != 0 {
            throw fs_errorForPOSIXError(result.error)
        }

        let rootAttrs = FSItem.Attributes.fromVfs(
            itemId: result.attrs.itemId,
            itemType: result.attrs.itemType,
            size: result.attrs.size,
            modifiedTime: result.attrs.modifiedTime,
            createdTime: result.attrs.createdTime,
            mode: result.attrs.mode
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
        log.debug("deactivate")
        items.removeAll()
    }

    func attributes(
        _ desiredAttributes: FSItem.GetAttributesRequest,
        of fsItem: FSItem
    ) async throws -> FSItem.Attributes {
        let item = try getItem(fsItem)
        log.debug("attributes: itemId=\(item.itemId)")

        let vfsClient = try await client()
        let result = try await vfsClient.getAttributes(itemId: item.itemId)

        if result.error != 0 {
            throw fs_errorForPOSIXError(result.error)
        }

        let fsAttrs = FSItem.Attributes.fromVfs(
            itemId: result.attrs.itemId,
            itemType: result.attrs.itemType,
            size: result.attrs.size,
            modifiedTime: result.attrs.modifiedTime,
            createdTime: result.attrs.createdTime,
            mode: result.attrs.mode
        )
        item.updateAttributes(fsAttrs)
        return fsAttrs
    }

    func setAttributes(
        _ newAttributes: FSItem.SetAttributesRequest,
        on fsItem: FSItem
    ) async throws -> FSItem.Attributes {
        let item = try getItem(fsItem)
        log.debug("setAttributes: itemId=\(item.itemId)")

        // For now, just return current attributes
        // TODO: implement setAttributes when VFS supports it properly
        return item.cachedAttributes
    }

    func lookupItem(
        named name: FSFileName,
        inDirectory directory: FSItem
    ) async throws -> (FSItem, FSFileName) {
        let dirItem = try getItem(directory)
        let nameStr = name.string ?? ""
        log.debug("lookupItem: name=\(nameStr) in dir=\(dirItem.itemId)")

        let vfsClient = try await client()
        let result = try await vfsClient.lookup(parentId: dirItem.itemId, name: nameStr)

        if result.error != 0 {
            log.debug("lookupItem: not found (error=\(result.error))")
            throw fs_errorForPOSIXError(result.error)
        }

        // Get full attributes for the found item
        let attrsResult = try await vfsClient.getAttributes(itemId: result.itemId)

        let fsAttrs = FSItem.Attributes.fromVfs(
            itemId: result.itemId,
            itemType: result.itemType,
            size: attrsResult.attrs.size,
            modifiedTime: attrsResult.attrs.modifiedTime,
            createdTime: attrsResult.attrs.createdTime,
            mode: attrsResult.attrs.mode
        )

        // Check if we already have this item cached
        if let existing = items[result.itemId] {
            existing.updateAttributes(fsAttrs)
            return (existing, existing.name)
        }

        let item = Item(itemId: result.itemId, name: nameStr, attributes: fsAttrs)
        cacheItem(item)
        return (item, item.name)
    }

    func reclaimItem(_ fsItem: FSItem) async throws {
        let item = try getItem(fsItem)
        log.debug("reclaimItem: itemId=\(item.itemId)")
        items.removeValue(forKey: item.itemId)
    }

    func readSymbolicLink(_ fsItem: FSItem) async throws -> FSFileName {
        let item = try getItem(fsItem)
        log.debug("readSymbolicLink: itemId=\(item.itemId)")
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
        log.debug("createItem: name=\(nameStr) in dir=\(dirItem.itemId)")

        let vfsType: ItemType = (type == .directory) ? .directory : .file
        let vfsClient = try await client()
        let result = try await vfsClient.create(parentId: dirItem.itemId, name: nameStr, itemType: vfsType)

        if result.error != 0 {
            throw fs_errorForPOSIXError(result.error)
        }

        // Get attributes for new item
        let attrsResult = try await vfsClient.getAttributes(itemId: result.itemId)

        let fsAttrs = FSItem.Attributes.fromVfs(
            itemId: result.itemId,
            itemType: vfsType,
            size: attrsResult.attrs.size,
            modifiedTime: attrsResult.attrs.modifiedTime,
            createdTime: attrsResult.attrs.createdTime,
            mode: attrsResult.attrs.mode
        )

        let item = Item(itemId: result.itemId, name: nameStr, attributes: fsAttrs)
        cacheItem(item)
        return (item, item.name)
    }

    func createSymbolicLink(
        named name: FSFileName,
        inDirectory directory: FSItem,
        attributes newAttributes: FSItem.SetAttributesRequest,
        linkContents contents: FSFileName
    ) async throws -> (FSItem, FSFileName) {
        log.debug("createSymbolicLink: not supported")
        throw fs_errorForPOSIXError(POSIXError.ENOTSUP.rawValue)
    }

    func createLink(
        to item: FSItem,
        named name: FSFileName,
        inDirectory directory: FSItem
    ) async throws -> FSFileName {
        log.debug("createLink: not supported (hard links)")
        throw fs_errorForPOSIXError(POSIXError.ENOTSUP.rawValue)
    }

    func removeItem(
        _ fsItem: FSItem,
        named name: FSFileName,
        fromDirectory directory: FSItem
    ) async throws {
        let item = try getItem(fsItem)
        log.debug("removeItem: itemId=\(item.itemId)")

        let vfsClient = try await client()
        let result = try await vfsClient.delete(itemId: item.itemId)

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
        log.debug("renameItem: itemId=\(item.itemId) -> \(destName) in \(destDir.itemId)")

        let vfsClient = try await client()
        let result = try await vfsClient.rename(itemId: item.itemId, newParentId: destDir.itemId, newName: destName)

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
        log.debug("enumerateDirectory: itemId=\(dirItem.itemId) cookie=\(cookie.rawValue)")

        let vfsClient = try await client()
        let result = try await vfsClient.readDir(itemId: dirItem.itemId, cursor: cookie.rawValue)

        if result.error != 0 {
            throw fs_errorForPOSIXError(result.error)
        }

        var nextCookie: UInt64 = 1
        for entry in result.entries {
            // DirEntry doesn't include mode, use default based on type
            // Real mode is fetched when lookupItem or attributes is called
            let defaultMode: UInt32 = (entry.itemType == .directory) ? 0o755 : 0o644
            let entryAttrs = FSItem.Attributes.fromVfs(
                itemId: entry.itemId,
                itemType: entry.itemType,
                size: 0,  // Size not included in DirEntry
                modifiedTime: 0,
                createdTime: 0,
                mode: defaultMode
            )

            let entryItem = Item(itemId: entry.itemId, name: entry.name, attributes: entryAttrs)
            cacheItem(entryItem)

            let shouldContinue = packer.packEntry(
                name: FSFileName(string: entry.name),
                itemType: entryAttrs.type,
                itemID: entryAttrs.fileID,
                nextCookie: FSDirectoryCookie(nextCookie),
                attributes: attributes != nil ? entryAttrs : nil
            )

            if !shouldContinue {
                break
            }
            nextCookie += 1
        }

        return FSDirectoryVerifier(result.nextCursor)
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
        log.debug("read: itemId=\(item.itemId) offset=\(offset) length=\(length)")

        let vfsClient = try await client()
        let result = try await vfsClient.read(itemId: item.itemId, offset: UInt64(offset), len: UInt64(length))

        if result.error != 0 {
            throw fs_errorForPOSIXError(result.error)
        }

        // Copy data to buffer
        let copyLen = min(buffer.length, result.data.count)

        buffer.withUnsafeMutableBytes { dst in
            for i in 0..<copyLen {
                dst.storeBytes(of: result.data[i], toByteOffset: i, as: UInt8.self)
            }
        }

        return copyLen
    }

    func write(
        contents: Data,
        to fsItem: FSItem,
        at offset: off_t
    ) async throws -> Int {
        // IMPORTANT: Copy data immediately before any async suspension point.
        // FSKit may free the underlying NSData buffer, causing heap corruption
        // if we access it after an await.
        let bytes = [UInt8](contents)

        let item = try getItem(fsItem)
        log.debug("write: itemId=\(item.itemId) offset=\(offset) length=\(bytes.count)")

        let vfsClient = try await client()
        let result = try await vfsClient.write(itemId: item.itemId, offset: UInt64(offset), data: Data(bytes))

        if result.error != 0 {
            throw fs_errorForPOSIXError(result.error)
        }

        return Int(result.bytesWritten)
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
