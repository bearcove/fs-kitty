# fs-kitty

A Rust-first FSKit file system extension for macOS. Own every line of code.

Troubleshooting:
- [`docs/TROUBLESHOOTING.md`](docs/TROUBLESHOOTING.md)
- [`DEVELOP.md`](DEVELOP.md)

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
│  │ Pure Swift: FSKit impl + Roam-generated VfsClient     │ │
│  └──────────────┬─────────────────────────────────────────┘ │
└─────────────────┼───────────────────────────────────────────┘
                  │ TCP (roam protocol)
┌─────────────────▼───────────────────────────────────────────┐
│  Your Rust VFS App (rapace server)                          │
│  (implements actual filesystem logic)                        │
└─────────────────────────────────────────────────────────────┘
```

## Key Design Decisions

1. **Pure Swift in the fsext** - No FFI, no Rust in the extension. Swift talks directly to the server.
2. **Rust for the server** - The VFS backend is 100% Rust
3. **roam for IPC** - High-performance RPC with postcard serialization
4. **Roam Swift runtime** - Generated Swift client code + runtime, no bridging required
5. **TCP first** - Simple and debuggable, SHM zero-copy can come later

## Status

### What Works ✅

- **Pure Swift VFS client** via Roam-generated Swift bindings (no FFI!)
- **Roam RPC** over TCP with full postcard wire format
- **Full VFS protocol** - lookup, read, write, readdir, create, delete, rename, setAttributes
- **Rust server** tested end-to-end
- **FSKit extension** signed and working with Developer ID
- **Real filesystem mounting** - successfully tested end-to-end with macOS FSKit

### What's Next

- SHM zero-copy transport for high-performance workloads
- Streaming support for large file operations

## Project Structure

```
fs-kitty/
├── crates/
│   ├── fs-kitty-proto/     # Shared VFS protocol types (roam service)
│   ├── fs-kitty-server/    # In-memory VFS server (for testing)
│   └── fs-kitty-client/    # CLI VFS client (for testing)
├── swift/FsKitty/          # SPM test harness (pure Swift via RoamRuntime)
└── xcode/
    ├── FsKitty/            # Host app source files
    └── FsKittyExt/         # FSKit extension source files
        ├── FsKittyExt.swift    # Extension entry point
        ├── Bridge.swift        # FSUnaryFileSystem implementation
        ├── Volume.swift        # FSVolume implementation
        ├── Item.swift          # FSItem wrapper
        └── VfsClient.swift     # Generated roam client
```

## Building

### Prerequisites

- macOS 26+ (Tahoe) for URL-based mounting
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

# Or test pure Swift VFS client
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

# 5. Mount using fskitty:// URL
mount -t fskitty fskitty://localhost:10001 /Volumes/FsKitty

# 6. Use it!
ls /Volumes/FsKitty
echo "hello" > /Volumes/FsKitty/test.txt
cat /Volumes/FsKitty/test.txt

# 7. Unmount when done
umount /Volumes/FsKitty
```

The URL format is `fskitty://host:port` (port defaults to 10001 if omitted).

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

- [roam](https://github.com/bearcove/roam) - High-performance RPC + Swift runtime/codegen
- [facet](https://github.com/facet-rs/facet) - Serialization (used by roam)

## Generating the Swift Client

The `VfsClient.swift` files are generated from `fs-kitty-proto` using `roam-codegen`:

```bash
# In fs-kitty:
cargo run -p fs-kitty-codegen
# Outputs:
# - swift/FsKitty/Sources/FsKitty/VfsClient.swift
# - xcode/FsKittyExt/VfsClient.swift
```

This generates a pure Swift client with:
- All VFS types (`LookupResult`, `ReadDirResult`, `ItemAttributes`, etc.)
- `VfsClient` class with async methods for all RPC calls
- Postcard serialization (varints, zigzag, length-prefixed strings)
- No FFI, no Rust runtime required

## License

MIT OR Apache-2.0
