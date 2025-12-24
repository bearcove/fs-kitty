# fs-kitty

A Rust-first FSKit file system extension for macOS. Own every line of code.

**Built for [vixen](https://github.com/bearcove/vixen)** - a hermetic Rust build system. fs-kitty enables:
1. **Build hermeticity** - Control exactly what goes in and out of a build
2. **On-the-fly materialization** - Provide proc-macro inputs and other requirements that aren't statically declared

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
- **FSKit extension** signed and working with Developer ID
- **Real filesystem mounting** - successfully tested end-to-end with macOS FSKit

### What's Next

1. ~~**Test Swift → Rust → TCP chain**~~ ✅ Complete
2. ~~**FSKit extension code**~~ ✅ Complete - see `xcode/FsKittyExt/`
3. ~~**Create Xcode project**~~ ✅ Complete - `just build` works
4. ~~**Sign and test**~~ ✅ Complete - signed with Developer ID and tested
5. ~~**Mount a real filesystem**~~ ✅ Complete - successfully mounted and tested end-to-end

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
- [just](https://github.com/casey/just) command runner
- **Apple Developer Program membership** ($99/year) - required for FSKit entitlements

### Quick Build

```bash
# Build everything (Rust + Xcode), output to build/
just build

# Or step by step:
just build-rust    # Build Rust library
just build-xcode   # Build Xcode project
```

### Code Signing (Required for FSKit)

FSKit extensions **must be signed** with an Apple Developer certificate. Unsigned extensions won't appear in System Settings.

#### 1. Join Apple Developer Program

Sign up at [developer.apple.com](https://developer.apple.com/programs/) ($99/year).

#### 2. Create Certificates

In Xcode → Settings → Accounts → Manage Certificates:
- Create a **Developer ID Application** certificate (for distribution)
- Or use **Apple Development** certificate (for local testing)

#### 3. Create App IDs (in Apple Developer Portal)

Go to [Certificates, Identifiers & Profiles](https://developer.apple.com/account/resources/identifiers/list):

1. Create App ID for host app:
   - Identifier: `me.amos.fs-kitty`
   - Capabilities: (none special needed)

2. Create App ID for extension:
   - Identifier: `me.amos.fs-kitty.ext`
   - Capabilities: Enable **System Extension** (includes FSKit)

#### 4. Create Provisioning Profiles

For each App ID, create a provisioning profile:
- Type: **macOS App Development** (testing) or **Developer ID** (distribution)
- Download and double-click to install

#### 5. Configure Xcode Signing

Open `xcode/FsKitty.xcodeproj` in Xcode:

**For FsKitty target:**
- Signing & Capabilities → Team: Select your team
- Signing Certificate: Developer ID Application (or Apple Development)

**For FsKittyExt target:**
- Signing & Capabilities → Team: Select your team
- Signing Certificate: Developer ID Application (or Apple Development)
- Verify entitlement `com.apple.developer.fskit.fsmodule` is present

#### 6. Build Signed App

```bash
# From command line (uses Xcode's configured signing)
just build-xcode

# Or in Xcode: Product → Build
```

#### Troubleshooting Signing

```bash
# Check if app is signed
codesign -dv --verbose=4 build/Debug/FsKitty.app

# Check extension signing
codesign -dv --verbose=4 build/Debug/FsKitty.app/Contents/PlugIns/FsKittyExt.appex

# Verify entitlements
codesign -d --entitlements :- build/Debug/FsKitty.app/Contents/PlugIns/FsKittyExt.appex
```

### Manual Xcode Setup (if needed)

The project uses `xcodegen` to generate the Xcode project from `xcode/project.yml`:

```bash
# Regenerate project after changing project.yml
just xcode-gen
```

## Running

### Testing Without FSKit

```bash
# Terminal 1: Start VFS server
just server

# Terminal 2: Test with CLI client
cargo run --package fs-kitty-client

# Or test Swift → Rust → TCP integration
just test-swift
```

### Testing FSKit Extension (requires signing)

After signing the app (see Code Signing section above):

```bash
# 1. Install the app
cp -r build/Debug/FsKitty.app /Applications/
open /Applications/FsKitty.app

# 2. Enable extension:
#    System Settings → General → Login Items & Extensions → File System Extensions
#    Toggle ON "fskitty"

# 3. Start VFS server (keep running)
just server

# 4. Create mount point
sudo mkdir -p /Volumes/FsKitty

# 5. Create and attach disk image (FSKit needs a block device)
mkfile -n 1m /tmp/fskitty.dmg
DEVICE=$(hdiutil attach -imagekey diskimage-class=CRawDiskImage -nomount /tmp/fskitty.dmg)
echo "Attached device: $DEVICE"

# 6. Mount
mount -t fskitty "$DEVICE" /Volumes/FsKitty

# 7. Use it!
ls /Volumes/FsKitty
echo "hello" > /Volumes/FsKitty/test.txt
cat /Volumes/FsKitty/test.txt

# 8. Unmount when done
umount /Volumes/FsKitty
hdiutil detach "$DEVICE"
```

### Watching Logs

```bash
# Stream extension logs in real-time
just logs
```

### Check Extension Status

```bash
# See if extension is registered
just check-extension
```

## Dependencies

- [rapace](https://github.com/bearcove/rapace) - High-performance RPC
- [swift-bridge](https://github.com/chinedufn/swift-bridge) - Swift-Rust FFI
- [facet](https://github.com/facet-rs/facet) - Serialization (used by rapace)

## License

MIT OR Apache-2.0
