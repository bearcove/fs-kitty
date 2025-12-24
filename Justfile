# fs-kitty build recipes

# Default recipe - build everything
default: build

# Build everything (Rust + Xcode) and copy to build/
build: build-rust build-xcode
    @echo "Build complete! Output in build/"

# Build just the Rust library
build-rust:
    cargo build --release --package fs-kitty-swift

# Regenerate Swift bindings and copy to xcode directory
update-bindings: build-rust
    cp crates/fs-kitty-swift/generated/SwiftBridgeCore.swift xcode/FsKittyExt/
    cp crates/fs-kitty-swift/generated/fs-kitty-swift/fs-kitty-swift.swift xcode/FsKittyExt/
    cat crates/fs-kitty-swift/generated/SwiftBridgeCore.h \
        crates/fs-kitty-swift/generated/fs-kitty-swift/fs-kitty-swift.h \
        > xcode/FsKittyExt/BridgeHeaders/BridgeHeaders.h
    # Add import BridgeHeaders to generated Swift files
    sed -i '' '1s/^/import BridgeHeaders\n\n/' xcode/FsKittyExt/fs-kitty-swift.swift
    sed -i '' 's/^import Foundation$/import Foundation\nimport BridgeHeaders/' xcode/FsKittyExt/SwiftBridgeCore.swift

# Build the Xcode project
build-xcode: build-rust xcode-gen
    mkdir -p build
    xcodebuild -project xcode/FsKitty.xcodeproj \
        -scheme FsKitty \
        -configuration Debug \
        -allowProvisioningUpdates \
        build \
        SYMROOT="$(pwd)/build"
    @echo "FsKitty.app is at build/Debug/FsKitty.app"

# Build release configuration
build-release: build-rust xcode-gen
    mkdir -p build
    xcodebuild -project xcode/FsKitty.xcodeproj \
        -scheme FsKitty \
        -configuration Release \
        -allowProvisioningUpdates \
        build \
        SYMROOT="$(pwd)/build"
    @echo "FsKitty.app is at build/Release/FsKitty.app"

# Clean build artifacts
clean:
    cargo clean
    rm -rf build
    rm -rf ~/Library/Developer/Xcode/DerivedData/FsKitty-*

# Regenerate xcode project from project.yml
xcode-gen:
    cd xcode && xcodegen generate

# Start the VFS server (for testing)
server:
    cargo run --package fs-kitty-server

# Test Swift → Rust → TCP chain
test-swift:
    cd swift/FsKitty && swift run

# Run Rust tests
test:
    cargo test

# Check if extension is registered
check-extension:
    pluginkit -m -vv -p com.apple.fskit.fsmodule | grep -i fskitty || echo "Extension not registered"

# Stream extension logs
logs:
    log stream --info --debug --style syslog --predicate 'subsystem == "FsKittyExt"'
