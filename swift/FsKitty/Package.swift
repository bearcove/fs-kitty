// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "FsKitty",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(url: "https://github.com/bearcove/roam.git", branch: "main"),
    ],
    targets: [
        .executableTarget(
            name: "FsKitty",
            dependencies: [
                .product(name: "RoamRuntime", package: "roam"),
            ],
            path: "Sources/FsKitty"
        ),
    ]
)
