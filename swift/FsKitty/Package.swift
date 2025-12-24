// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "FsKitty",
    platforms: [.macOS(.v14)],
    targets: [
        // C module that exposes the Rust FFI headers
        .target(
            name: "BridgeHeaders",
            path: "Sources/BridgeHeaders",
            publicHeadersPath: "."
        ),
        // Main executable
        .executableTarget(
            name: "FsKitty",
            dependencies: ["BridgeHeaders"],
            path: "Sources/FsKitty",
            linkerSettings: [
                .unsafeFlags([
                    "-L../../target/release",
                    "-lfs_kitty_swift",
                ])
            ]
        ),
    ]
)
