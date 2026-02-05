# fs-kitty build recipes

# Default recipe - build everything
default: build

# Build everything (Rust server + Xcode app)
build: build-rust build-xcode
    @echo "Build complete! Output in build/"

# Build Rust components (server, client, proto)
build-rust:
    cargo build --release

# Build the Xcode project (Release config - Debug stub doesn't work with ExtensionKit)
build-xcode: xcode-gen
    mkdir -p build
    xcodebuild -project xcode/FsKitty.xcodeproj \
        -scheme FsKitty \
        -configuration Release \
        -allowProvisioningUpdates \
        build \
        SYMROOT="$(pwd)/build"
    @echo "FsKitty.app is at build/Release/FsKitty.app"

# Build debug configuration (WARNING: Debug stub doesn't work with ExtensionKit!)
build-debug: xcode-gen
    mkdir -p build
    xcodebuild -project xcode/FsKitty.xcodeproj \
        -scheme FsKitty \
        -configuration Debug \
        -allowProvisioningUpdates \
        build \
        SYMROOT="$(pwd)/build"
    @echo "FsKitty.app is at build/Debug/FsKitty.app (won't launch as extension!)"

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

# Test pure Swift VFS client
test-swift:
    cd swift/FsKitty && swift run

# Run Rust tests
test:
    cargo test

# Check if extension is registered
check-extension:
    pluginkit -m -vv -p com.apple.fskit.fsmodule | grep -i fskitty || echo "Extension not registered"

# Stream extension logs (includes FSKit system logs)
logs:
    log stream --info --debug --style syslog --predicate 'subsystem == "com.apple.FSKit" OR subsystem == "me.amos.fs-kitty.ext" OR composedMessage CONTAINS "fskitty" OR composedMessage CONTAINS "FsKittyExt"'
