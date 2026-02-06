import Darwin
import DiskArbitration
import Foundation
import os

private let log = Logger(subsystem: "me.amos.fs-kitty.mount", category: "Main")

struct Config {
    let mountPoint: String
    let port: Int
    let host: String
    let scheme: String
    let fsType: String
    let parentPID: pid_t

    var source: String {
        "\(scheme)://\(host):\(port)"
    }

    static func parse(from args: [String]) throws -> Config {
        var mountPoint: String?
        var port: Int?
        var host = "localhost"
        var scheme = "fskitty"
        let fsType = "fskitty"
        let parentPID = getppid()

        var index = 0
        while index < args.count {
            let arg = args[index]
            switch arg {
            case "--mount-point":
                index += 1
                mountPoint = try valueArg(args, index: index, name: "--mount-point")
            case "--port":
                index += 1
                let value = try valueArg(args, index: index, name: "--port")
                guard let parsed = Int(value), parsed > 0 else {
                    throw MountError.invalidArgument("--port must be a positive integer")
                }
                port = parsed
            case "--host":
                index += 1
                host = try valueArg(args, index: index, name: "--host")
            case "--scheme":
                index += 1
                scheme = try valueArg(args, index: index, name: "--scheme")
            case "--help":
                throw MountError.usage
            default:
                throw MountError.invalidArgument("Unknown argument: \(arg)")
            }
            index += 1
        }

        guard let mountPoint else {
            throw MountError.invalidArgument("Missing required --mount-point argument")
        }
        guard let port else {
            throw MountError.invalidArgument("Missing required --port argument")
        }

        return Config(
            mountPoint: mountPoint,
            port: port,
            host: host,
            scheme: scheme,
            fsType: fsType,
            parentPID: parentPID
        )
    }

    private static func valueArg(_ args: [String], index: Int, name: String) throws -> String {
        guard index < args.count else {
            throw MountError.invalidArgument("\(name) requires a value")
        }
        return args[index]
    }
}

enum MountError: Error, CustomStringConvertible {
    case invalidArgument(String)
    case mountFailed(errno: Int32)
    case unmountFailed(String)
    case usage

    var description: String {
        switch self {
        case .invalidArgument(let message):
            return message
        case .mountFailed(let code):
            return "mount failed: errno=\(code) (\(String(cString: strerror(code))))"
        case .unmountFailed(let message):
            return "unmount failed: \(message)"
        case .usage:
            return """
                Usage:
                  fskittymount --port <port> --mount-point <path> [--host <host>] [--scheme <scheme>]
                """
        }
    }
}

final class ParentExitWatcher {
    private let pid: pid_t
    private let queue: DispatchQueue
    private var source: DispatchSourceProcess?
    private let onExit: () -> Void

    init(pid: pid_t, queue: DispatchQueue, onExit: @escaping () -> Void) {
        self.pid = pid
        self.queue = queue
        self.onExit = onExit
    }

    func start() {
        guard pid > 1 else {
            onExit()
            return
        }
        if kill(pid, 0) != 0, errno == ESRCH {
            onExit()
            return
        }
        let source = DispatchSource.makeProcessSource(
            identifier: pid, eventMask: .exit, queue: queue)
        source.setEventHandler { [onExit] in
            onExit()
        }
        source.setCancelHandler {}
        source.resume()
        self.source = source
    }

    func stop() {
        source?.cancel()
        source = nil
    }
}

final class MountLifecycle {
    private let config: Config
    private let queue = DispatchQueue(label: "me.amos.fs-kitty.mount.lifecycle")
    private var cleanupStarted = false
    private var signalSources: [DispatchSourceSignal] = []
    private var parentWatcher: ParentExitWatcher?

    init(config: Config) {
        self.config = config
    }

    func run() throws {
        try ensureMountPointExists()
        try mount()
        installSignalHandlers()
        installParentWatcher()
        let mountedPath = self.config.mountPoint
        let mountedSource = self.config.source
        log.notice(
            "mounted \(mountedPath, privacy: .public) from \(mountedSource, privacy: .public)")
        dispatchMain()
    }

    private func ensureMountPointExists() throws {
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: config.mountPoint, isDirectory: &isDir) {
            if !isDir.boolValue {
                throw MountError.invalidArgument(
                    "Mount point exists but is not a directory: \(config.mountPoint)")
            }
            return
        }
        try FileManager.default.createDirectory(
            atPath: config.mountPoint, withIntermediateDirectories: true)
    }

    private func mount() throws {
        let result = config.source.withCString { sourcePtr in
            config.mountPoint.withCString { targetPtr in
                config.fsType.withCString { fsTypePtr in
                    Darwin.mount(
                        fsTypePtr, targetPtr, 0, UnsafeMutableRawPointer(mutating: sourcePtr))
                }
            }
        }
        guard result == 0 else {
            throw MountError.mountFailed(errno: errno)
        }
    }

    private func installSignalHandlers() {
        for signalNumber in [SIGINT, SIGTERM, SIGHUP] {
            signal(signalNumber, SIG_IGN)
            let source = DispatchSource.makeSignalSource(signal: signalNumber, queue: queue)
            source.setEventHandler { [weak self] in
                log.notice("received signal \(signalNumber), unmounting")
                self?.performCleanupAndExit(status: 0)
            }
            source.resume()
            signalSources.append(source)
        }
    }

    private func installParentWatcher() {
        let parentPID = self.config.parentPID
        let queue = self.queue
        let lifecycle = self
        let watcher = ParentExitWatcher(pid: parentPID, queue: queue) {
            log.notice("parent pid \(parentPID) exited, unmounting")
            lifecycle.performCleanupAndExit(status: 0)
        }
        watcher.start()
        parentWatcher = watcher
    }

    private func performCleanupAndExit(status: Int32) {
        guard !cleanupStarted else { return }
        cleanupStarted = true
        parentWatcher?.stop()
        do {
            try unmount()
            let mountedPath = self.config.mountPoint
            log.notice("unmounted \(mountedPath, privacy: .public)")
        } catch {
            log.error("cleanup unmount failed: \(String(describing: error), privacy: .public)")
        }
        exit(status)
    }

    private func unmount() throws {
        if try unmountWithDiskArbitration() {
            return
        }
        if Darwin.unmount(config.mountPoint, MNT_FORCE) == 0 {
            return
        }
        throw MountError.unmountFailed("errno=\(errno) (\(String(cString: strerror(errno))))")
    }

    private func unmountWithDiskArbitration() throws -> Bool {
        guard let session = DASessionCreate(kCFAllocatorDefault) else {
            return false
        }
        DASessionSetDispatchQueue(session, queue)
        defer { DASessionSetDispatchQueue(session, nil) }

        let url = URL(fileURLWithPath: config.mountPoint) as CFURL
        guard let disk = DADiskCreateFromVolumePath(kCFAllocatorDefault, session, url) else {
            return false
        }

        let callbackContext = CallbackContext(semaphore: DispatchSemaphore(value: 0))
        let context = Unmanaged.passRetained(callbackContext)

        DADiskUnmount(
            disk,
            DADiskUnmountOptions(kDADiskUnmountOptionForce),
            { _, dissenter, context in
                let holder = Unmanaged<CallbackContext>.fromOpaque(context!).takeRetainedValue()
                if let dissenter {
                    let status = DADissenterGetStatus(dissenter)
                    holder.error = "DA dissenter status=\(status)"
                }
                holder.semaphore.signal()
            },
            context.toOpaque()
        )

        let waitResult = callbackContext.semaphore.wait(timeout: .now() + .seconds(5))
        if waitResult == .timedOut {
            throw MountError.unmountFailed("DiskArbitration unmount timed out")
        }
        if let message = callbackContext.error {
            throw MountError.unmountFailed(message)
        }
        return true
    }
}

final class CallbackContext {
    let semaphore: DispatchSemaphore
    var error: String?

    init(semaphore: DispatchSemaphore) {
        self.semaphore = semaphore
    }
}

do {
    let config = try Config.parse(from: Array(CommandLine.arguments.dropFirst()))
    try MountLifecycle(config: config).run()
} catch let error as MountError {
    fputs("fskittymount: \(error.description)\n", stderr)
    if case .usage = error {
        exit(0)
    }
    exit(2)
} catch {
    fputs("fskittymount: unexpected error: \(error)\n", stderr)
    exit(3)
}
