import FSKit
import Foundation

/// Wrapper around FSItem that holds our VFS item state.
final class Item: FSItem {
    /// VFS item ID (unique identifier)
    let itemId: UInt64

    /// File name
    private(set) var name: FSFileName

    /// Cached attributes
    private(set) var cachedAttributes: FSItem.Attributes

    init(itemId: UInt64, name: String, attributes: FSItem.Attributes) {
        self.itemId = itemId
        self.name = FSFileName(string: name)
        self.cachedAttributes = attributes
    }

    func updateAttributes(_ attrs: FSItem.Attributes) {
        self.cachedAttributes = attrs
    }
}

// MARK: - Attribute Helpers

extension FSItem.Attributes {
    /// Create attributes from VFS response
    static func fromVfs(
        itemId: UInt64,
        itemType: UInt8,
        size: UInt64,
        modifiedTime: UInt64,
        createdTime: UInt64
    ) -> FSItem.Attributes {
        let attrs = FSItem.Attributes()

        // Set file ID
        if let id = FSItem.Identifier(rawValue: itemId) {
            attrs.fileID = id
        }

        // Set type
        switch itemType {
        case 0: // File
            attrs.type = .file
        case 1: // Directory
            attrs.type = .directory
        case 2: // Symlink
            attrs.type = .symlink
        default:
            attrs.type = .file
        }

        // Set size
        attrs.size = size

        // Set times
        attrs.modifyTime = timespec(tv_sec: Int(modifiedTime), tv_nsec: 0)
        attrs.birthTime = timespec(tv_sec: Int(createdTime), tv_nsec: 0)
        attrs.changeTime = timespec(tv_sec: Int(modifiedTime), tv_nsec: 0)
        attrs.accessTime = timespec(tv_sec: Int(modifiedTime), tv_nsec: 0)

        // Default permissions (rwxr-xr-x for dirs, rw-r--r-- for files)
        if attrs.type == .directory {
            attrs.mode = 0o755
        } else {
            attrs.mode = 0o644
        }

        // Default uid/gid
        attrs.uid = 501
        attrs.gid = 20

        // Link count
        attrs.linkCount = 1

        return attrs
    }
}
