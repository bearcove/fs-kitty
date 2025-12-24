// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Spike1",
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
            name: "Spike1",
            dependencies: ["BridgeHeaders"],
            path: "Sources/Spike1",
            linkerSettings: [
                .unsafeFlags([
                    "-L../../target/release",
                    "-lfskitty_swift",
                ])
            ]
        ),
    ]
)
