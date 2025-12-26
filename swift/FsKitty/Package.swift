// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "FsKitty",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(url: "https://github.com/bearcove/rapace-swift", branch: "main"),
    ],
    targets: [
        .executableTarget(
            name: "FsKitty",
            dependencies: [
                .product(name: "Rapace", package: "rapace-swift"),
                .product(name: "Postcard", package: "rapace-swift"),
            ],
            path: "Sources/FsKitty"
        ),
    ]
)
