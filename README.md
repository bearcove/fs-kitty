# fs-kitty

A Rust-first FSKit file system extension for macOS. Own every line of code.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│           macOS FSKit (XPC)                                  │
└───────────────┬─────────────────────────────────────────────┘
                │
┌───────────────▼─────────────────────────────────────────────┐
│  FsKitty.appex                                              │
│  ┌────────────────────────────────────────────────────────┐ │
│  │ Swift: FSKit protocol impl (thin layer)                │ │
│  └──────────────┬─────────────────────────────────────────┘ │
│                 │ swift-bridge                              │
│  ┌──────────────▼─────────────────────────────────────────┐ │
│  │ Rust: rapace client                                    │ │
│  └──────────────┬─────────────────────────────────────────┘ │
└─────────────────┼───────────────────────────────────────────┘
                  │ TCP (rapace protocol)
┌─────────────────▼───────────────────────────────────────────┐
│  Your Rust VFS App (rapace server)                          │
│  (implements actual filesystem logic)                        │
└─────────────────────────────────────────────────────────────┘
```

## Key Design Decisions

1. **Swift only where we must** - FSKit requires Swift, but we keep that layer as thin as possible
2. **Rust for everything else** - The rapace client in the fsext, the protocol, the VFS backend
3. **rapace for IPC** - High-performance multiplexed RPC (not protobuf)
4. **swift-bridge for FFI** - Swift calls into Rust, not the other way around
5. **TCP first** - Start simple, SHM zero-copy can come later

## Status

### What Works ✅

- **Swift ↔ Rust FFI** via swift-bridge (sync and async functions, structs, `Vec<T>`, `Result<T, E>`)
- **Rapace RPC** over TCP with bidirectional calls
- **Full VFS protocol** - lookup, read, write, readdir, create, delete, rename
- **Rust client/server** tested end-to-end
- **Swift → Rust → TCP chain** tested with `swift/FsKitty`
- **FSKit extension code** implemented in `xcode/FsKittyExt/`

### What's Next

1. ~~**Test Swift → Rust → TCP chain**~~ ✅ Complete
2. ~~**FSKit extension code**~~ ✅ Complete - see `xcode/FsKittyExt/`
3. **Create Xcode project** - set up FsKitty.app + FsKittyExt.appex
4. **Mount a real filesystem** - connect FSKit to the VFS backend

## Project Structure

```
fs-kitty/
├── crates/
│   ├── fs-kitty-proto/     # Shared VFS protocol types
│   ├── fs-kitty-swift/     # Rust lib exposed to Swift via swift-bridge
│   ├── fs-kitty-server/    # In-memory VFS server (for testing)
│   └── fs-kitty-client/    # CLI VFS client (for testing)
├── swift/FsKitty/          # SPM test harness for swift-bridge
└── xcode/
    ├── FsKitty/            # Host app source files
    └── FsKittyExt/         # FSKit extension source files
        ├── FsKittyExt.swift    # Extension entry point
        ├── Bridge.swift        # FSUnaryFileSystem implementation
        ├── Volume.swift        # FSVolume implementation
        ├── Item.swift          # FSItem wrapper
        ├── BridgeHeaders/      # C headers for swift-bridge
        ├── SwiftBridgeCore.swift
        └── fs-kitty-swift.swift
```

## Building

### Prerequisites

- macOS 15.4+ (for FSKit)
- Xcode 16+
- Rust toolchain

### Build Rust Library

```bash
# Build release (generates headers and static library)
cargo build --release --package fs-kitty-swift
```

### Setting Up the Xcode Project

The FSKit extension requires an Xcode project. Create one manually:

1. **Create new macOS App** in Xcode:
   - Product Name: `FsKitty`
   - Organization: `com.bearcove`
   - Bundle ID: `com.bearcove.fskitty`

2. **Add File System Extension target**:
   - File → New → Target → File System Extension
   - Product Name: `FsKittyExt`
   - Embed in: `FsKitty`

3. **Replace generated files** with files from `xcode/`:
   - Copy `xcode/FsKitty/` contents to your app target
   - Copy `xcode/FsKittyExt/` contents to your extension target

4. **Configure extension target**:
   - Add `BridgeHeaders/` to Header Search Paths
   - Add linker flags: `-L$(PROJECT_DIR)/../../target/release -lfs_kitty_swift`
   - Ensure entitlements include `com.apple.developer.fskit.fsmodule`

5. **Build and archive** with your signing identity

## Running

```bash
# Terminal 1: Start VFS server
cargo run --package fs-kitty-server

# Terminal 2: Test with CLI client
cargo run --package fs-kitty-client

# Or test Swift → Rust integration
cd swift/FsKitty && swift run
```

### Mounting (after Xcode project is set up)

```bash
# Install the app
cp -r /path/to/FsKitty.app /Applications/
open -a /Applications/FsKitty.app

# Enable extension in System Settings → General → Login Items & Extensions → File System Extensions

# Create mount point
sudo mkdir -p /Volumes/FsKitty

# Create and attach disk image
mkfile -n 1m /tmp/fskitty.dmg
DEVICE=$(hdiutil attach -imagekey diskimage-class=CRawDiskImage -nomount /tmp/fskitty.dmg)

# Mount
mount -F -t fskitty "$DEVICE" /Volumes/FsKitty

# Unmount
umount -f /Volumes/FsKitty
hdiutil detach "$DEVICE"
```

## Dependencies

- [rapace](https://github.com/bearcove/rapace) - High-performance RPC
- [swift-bridge](https://github.com/chinedufn/swift-bridge) - Swift-Rust FFI
- [facet](https://github.com/facet-rs/facet) - Serialization (used by rapace)

## License

MIT OR Apache-2.0
