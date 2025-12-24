import FSKit
import Foundation
import os

/// The bridge between FSKit and our Rust VFS client.
/// Implements FSUnaryFileSystem which is the top-level FSKit protocol.
final class Bridge: FSUnaryFileSystem, FSUnaryFileSystemOperations, @unchecked Sendable {

    // FSKit manages concurrency - we're safe to use a singleton here
    nonisolated(unsafe) static let shared = Bridge()

    private let log = Logger(subsystem: "me.amos.fs-kitty.ext", category: "Bridge")

    /// Server address from Info.plist Configuration
    private var serverAddress: String = "127.0.0.1:10001"

    private override init() {
        log.error("🌉 Bridge init() START")
        super.init()
        log.error("🌉 Bridge super.init() done")
        // Read server address from Info.plist if configured
        if let config = Bundle.main.infoDictionary?["Configuration"] as? [String: Any],
           let addr = config["serverAddress"] as? String {
            serverAddress = addr
            log.error("🌉 Read serverAddress from plist: \(addr, privacy: .public)")
        } else {
            log.error("🌉 No Configuration in plist, using default: \(self.serverAddress, privacy: .public)")
        }
        log.error("🌉 Bridge initialized, server: \(self.serverAddress, privacy: .public)")
    }

    /// Called by FSKit to check if we can handle this resource
    func probeResource(
        resource: FSResource,
        replyHandler: @escaping (FSProbeResult?, (any Error)?) -> Void
    ) {
        log.error("📋 probeResource START - resource: \(String(describing: resource), privacy: .public)")

        // Connect to the Rust VFS server
        do {
            log.error("📋 probeResource: about to connect to VFS")
            try connectToVfs()
            log.error("📋 probeResource: connected to VFS")

            // For now, return a basic usable result
            // In a real implementation, we'd query the backend for container info
            let containerUUID = UUID()
            log.error("📋 probeResource: generated UUID \(containerUUID.uuidString, privacy: .public)")
            let result = FSProbeResult.usable(
                name: "FsKitty",
                containerID: FSContainerIdentifier(uuid: containerUUID)
            )
            log.error("📋 probeResource: returning usable result")
            replyHandler(result, nil)
        } catch {
            log.error("📋 probeResource FAILED: \(String(describing: error), privacy: .public)")
            replyHandler(nil, nil)
        }
    }

    /// Called by FSKit to load the filesystem and get a volume
    func loadResource(
        resource: FSResource,
        options: FSTaskOptions,
        replyHandler: @escaping (FSVolume?, (any Error)?) -> Void
    ) {
        log.error("📦 loadResource START - resource: \(String(describing: resource), privacy: .public)")

        do {
            log.error("📦 loadResource: about to connect to VFS")
            try connectToVfs()
            log.error("📦 loadResource: connected to VFS")

            // Create our volume which will handle all FS operations
            log.error("📦 loadResource: creating Volume")
            let volume = Volume()
            log.error("📦 loadResource: setting containerStatus to ready")
            containerStatus = .ready
            log.error("📦 loadResource: returning volume")
            replyHandler(volume, nil)
        } catch {
            log.error("📦 loadResource FAILED: \(String(describing: error), privacy: .public)")
            replyHandler(nil, fs_errorForPOSIXError(POSIXError.EIO.rawValue))
        }
    }

    /// Called when FSKit wants to unload the resource
    func unloadResource(
        resource: FSResource,
        options: FSTaskOptions,
        replyHandler reply: @escaping ((any Error)?) -> Void
    ) {
        log.error("🔌 unloadResource START")
        // Disconnect from VFS server
        vfs_disconnect()
        log.error("🔌 unloadResource: disconnected, returning")
        reply(nil)
    }

    /// Called after loading completes
    func didFinishLoading() {
        log.error("✅ didFinishLoading called")
    }

    // MARK: - VFS Connection

    private func connectToVfs() throws {
        log.error("🔗 connectToVfs: attempting to connect to \(self.serverAddress, privacy: .public)")
        do {
            try vfs_connect(serverAddress)
            log.error("🔗 connectToVfs: SUCCESS - connected to VFS server")
        } catch let error as RustString {
            let errorMsg = error.toString()
            log.error("🔗 connectToVfs: got error: \(errorMsg, privacy: .public)")
            // Already connected is fine
            if errorMsg.contains("Already connected") {
                log.error("🔗 connectToVfs: already connected, that's OK")
                return
            }
            log.error("🔗 connectToVfs: throwing error")
            throw NSError(domain: "VFS", code: -1, userInfo: [NSLocalizedDescriptionKey: errorMsg])
        } catch {
            log.error("🔗 connectToVfs: unexpected error type: \(String(describing: error), privacy: .public)")
            throw error
        }
    }
}
