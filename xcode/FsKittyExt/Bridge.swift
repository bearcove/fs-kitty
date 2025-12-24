import FSKit
import Foundation
import os

/// The bridge between FSKit and our Rust VFS client.
/// Implements FSUnaryFileSystem which is the top-level FSKit protocol.
final class Bridge: FSUnaryFileSystem, FSUnaryFileSystemOperations, @unchecked Sendable {

    // FSKit manages concurrency - we're safe to use a singleton here
    nonisolated(unsafe) static let shared = Bridge()

    private let log = Logger(subsystem: "FsKittyExt", category: "Bridge")

    /// Server address from Info.plist Configuration
    private var serverAddress: String = "127.0.0.1:10001"

    private override init() {
        super.init()
        // Read server address from Info.plist if configured
        if let config = Bundle.main.infoDictionary?["Configuration"] as? [String: Any],
           let addr = config["serverAddress"] as? String {
            serverAddress = addr
        }
        log.d("Bridge initialized, server: \(serverAddress)")
    }

    /// Called by FSKit to check if we can handle this resource
    func probeResource(
        resource: FSResource,
        replyHandler: @escaping (FSProbeResult?, (any Error)?) -> Void
    ) {
        log.d("probeResource")

        // Connect to the Rust VFS server
        do {
            try connectToVfs()

            // For now, return a basic usable result
            // In a real implementation, we'd query the backend for container info
            let result = FSProbeResult.usable(
                name: "FsKitty",
                containerID: FSContainerIdentifier(uuid: UUID())
            )
            replyHandler(result, nil)
        } catch {
            log.e("probeResource failed: \(error)")
            replyHandler(nil, nil)
        }
    }

    /// Called by FSKit to load the filesystem and get a volume
    func loadResource(
        resource: FSResource,
        options: FSTaskOptions,
        replyHandler: @escaping (FSVolume?, (any Error)?) -> Void
    ) {
        log.d("loadResource")

        do {
            try connectToVfs()

            // Create our volume which will handle all FS operations
            let volume = Volume()
            containerStatus = .ready
            replyHandler(volume, nil)
        } catch {
            log.e("loadResource failed: \(error)")
            replyHandler(nil, fs_errorForPOSIXError(POSIXError.EIO.rawValue))
        }
    }

    /// Called when FSKit wants to unload the resource
    func unloadResource(
        resource: FSResource,
        options: FSTaskOptions,
        replyHandler reply: @escaping ((any Error)?) -> Void
    ) {
        log.d("unloadResource")
        // Disconnect from VFS server
        vfs_disconnect()
        reply(nil)
    }

    /// Called after loading completes
    func didFinishLoading() {
        log.d("didFinishLoading")
    }

    // MARK: - VFS Connection

    private func connectToVfs() throws {
        do {
            try vfs_connect(serverAddress)
            log.d("Connected to VFS server at \(serverAddress)")
        } catch {
            // Already connected is fine
            if "\(error)".contains("Already connected") {
                return
            }
            throw error
        }
    }
}
