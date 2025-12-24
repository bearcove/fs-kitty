import FSKit
import Foundation
import os

@main
struct FsKittyExt: UnaryFileSystemExtension {
    var fileSystem: FSUnaryFileSystem & FSUnaryFileSystemOperations {
        Bridge.shared
    }
}

extension Logger {
    func d(_ message: String) {
        self.debug("\(message, privacy: .public)")
    }

    func e(_ message: String) {
        self.error("\(message, privacy: .public)")
    }

    func posixError(_ function: String, _ code: Int32) {
        self.e("\(function): failure (code = \(code))")
    }
}
