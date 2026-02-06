import FSKit
import Foundation
import os
import RoamRuntime

extension VfsClient: @unchecked Sendable {}

final class NoopDispatcher: ServiceDispatcher, @unchecked Sendable {
    func preregister(methodId: UInt64, payload: [UInt8], registry: ChannelRegistry) async {}

    func dispatch(
        methodId: UInt64,
        payload: [UInt8],
        requestId: UInt64,
        registry: ChannelRegistry,
        taskTx: @escaping @Sendable (TaskMessage) -> Void
    ) async {
        taskTx(.response(requestId: requestId, payload: encodeUnknownMethodError()))
    }
}

/// Global VFS client shared across the extension
actor VfsConnection {
    static let shared = VfsConnection()

    private var client: VfsClient?
    private var driverTask: Task<Void, Never>?
    private let log = Logger(subsystem: "me.amos.fs-kitty.ext", category: "VfsConnection")

    func connect(address: String) async throws {
        if client != nil {
            log.info("Already connected")
            return
        }

        // Parse host:port
        let parts = address.split(separator: ":")
        guard parts.count == 2,
              let port = Int(parts[1]) else {
            throw NSError(domain: "VFS", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid address format: \(address)"])
        }

        let host = String(parts[0])
        log.info("Connecting to \(host):\(port)")

        let transport = try await RoamRuntime.connect(host: host, port: port)
        let hello = Hello.v3(maxPayloadSize: 1024 * 1024, initialChannelCredit: 64 * 1024)
        let (handle, driver) = try await establishInitiator(
            transport: transport,
            ourHello: hello,
            dispatcher: NoopDispatcher()
        )

        let logger = log
        driverTask = Task {
            do {
                try await driver.run()
                logger.error("Roam driver exited cleanly — server is gone")
            } catch {
                logger.error("Roam driver exited with error: \(error.localizedDescription)")
            }
            logger.error("Connection to VFS server lost, terminating extension")
            exit(0)
        }
        client = VfsClient(connection: handle)
        log.info("Connected to \(address)")
    }

    func disconnect() {
        driverTask?.cancel()
        driverTask = nil
        client = nil
    }

    func getClient() throws -> VfsClient {
        guard let client = client else {
            throw NSError(domain: "VFS", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not connected"])
        }
        return client
    }
}

/// Wrapper to make FSKit callbacks Sendable for Swift 6 concurrency.
/// FSKit callbacks are thread-safe in practice.
struct SendableReplyHandler<T>: @unchecked Sendable {
    let handler: (T?, (any Error)?) -> Void
}

struct SendableVoidReplyHandler: @unchecked Sendable {
    let handler: ((any Error)?) -> Void
}

/// The bridge between FSKit and our VFS client.
/// Implements FSUnaryFileSystem which is the top-level FSKit protocol.
final class Bridge: FSUnaryFileSystem, FSUnaryFileSystemOperations, @unchecked Sendable {

    // FSKit manages concurrency - singleton is safe here
    static let shared = Bridge()

    private let log = Logger(subsystem: "me.amos.fs-kitty.ext", category: "Bridge")

    private override init() {
        log.info("Bridge initialized")
        super.init()
    }

    /// Called by FSKit to check if we can handle this resource
    func probeResource(
        resource: FSResource,
        replyHandler: @escaping (FSProbeResult?, (any Error)?) -> Void
    ) {
        log.info("probeResource")

        // Extract server address from URL resource
        guard let address = extractServerAddress(from: resource) else {
            log.error("probeResource: not a valid fskitty:// URL resource")
            replyHandler(nil, nil)
            return
        }

        let sendable = SendableReplyHandler(handler: replyHandler)
        Task {
            do {
                try await VfsConnection.shared.connect(address: address)

                let containerUUID = UUID()
                let result = FSProbeResult.usable(
                    name: "FsKitty",
                    containerID: FSContainerIdentifier(uuid: containerUUID)
                )
                sendable.handler(result, nil)
            } catch {
                self.log.error("probeResource FAILED: \(error.localizedDescription)")
                sendable.handler(nil, nil)
            }
        }
    }

    /// Called by FSKit to load the filesystem and get a volume
    func loadResource(
        resource: FSResource,
        options: FSTaskOptions,
        replyHandler: @escaping (FSVolume?, (any Error)?) -> Void
    ) {
        log.info("loadResource")

        // Extract server address from URL resource
        guard let address = extractServerAddress(from: resource) else {
            log.error("loadResource: not a valid fskitty:// URL resource")
            replyHandler(nil, fs_errorForPOSIXError(POSIXError.EINVAL.rawValue))
            return
        }

        let sendable = SendableReplyHandler(handler: replyHandler)
        Task {
            do {
                try await VfsConnection.shared.connect(address: address)

                let volume = Volume()
                self.containerStatus = .ready
                sendable.handler(volume, nil)
            } catch {
                self.log.error("loadResource FAILED: \(error.localizedDescription)")
                sendable.handler(nil, fs_errorForPOSIXError(POSIXError.EIO.rawValue))
            }
        }
    }

    /// Called when FSKit wants to unload the resource
    func unloadResource(
        resource: FSResource,
        options: FSTaskOptions,
        replyHandler reply: @escaping ((any Error)?) -> Void
    ) {
        log.info("unloadResource")
        let sendable = SendableVoidReplyHandler(handler: reply)
        Task {
            await VfsConnection.shared.disconnect()
            sendable.handler(nil)
        }
    }

    /// Called after loading completes
    func didFinishLoading() {
        log.info("didFinishLoading")
    }

    // MARK: - URL Resource Handling

    /// Extract server address from FSGenericURLResource
    /// Expected URL format: fskitty://host:port or fskitty://host (defaults to port 10001)
    private func extractServerAddress(from resource: FSResource) -> String? {
        guard let urlResource = resource as? FSGenericURLResource else {
            return nil
        }

        let url = urlResource.url

        guard url.scheme == "fskitty" else {
            return nil
        }

        guard let host = url.host else {
            return nil
        }

        let port = url.port ?? 10001
        return "\(host):\(port)"
    }
}
