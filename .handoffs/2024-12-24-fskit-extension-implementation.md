# Handoff: FSKit Extension Implementation

## Current State

### Done ✅

1. **Full project rename**: `fskitty` → `fs-kitty`, `Spike1` → `FsKitty`

2. **Swift → Rust → TCP chain working**: The test in `swift/FsKitty` successfully:
   - Calls `add(2, 3)` → 5 (sync FFI)
   - Calls `async_greet("fs-kitty")` → "Hello, fs-kitty!" (async FFI)
   - Calls `vfs_connect()` / `vfs_ping()` → connects to VFS server over TCP

3. **FSKit extension code complete** in `xcode/FsKittyExt/`:
   - `FsKittyExt.swift` - Entry point with `@main` and `UnaryFileSystemExtension`
   - `Bridge.swift` - `FSUnaryFileSystem` implementation (probe/load/unload)
   - `Volume.swift` - Full `FSVolume` with Operations, ReadWrite, PathConf, OpenClose, AccessCheck
   - `Item.swift` - `FSItem` wrapper with VFS attribute mapping
   - `BridgeHeaders/` - Combined C headers + modulemap for swift-bridge
   - `SwiftBridgeCore.swift`, `fs-kitty-swift.swift` - Generated FFI code

4. **Host app source** in `xcode/FsKitty/`:
   - `FsKittyApp.swift` - SwiftUI app showing setup instructions
   - `Info.plist`, `FsKitty.entitlements`

5. **Extended Rust bridge** (`crates/fs-kitty-swift/src/lib.rs`):
   - All VFS operations exposed: `vfs_lookup`, `vfs_get_attributes`, `vfs_read_dir`, `vfs_read`, `vfs_write`, `vfs_create`, `vfs_delete`, `vfs_rename`
   - FFI-safe structs with `#[swift_bridge(swift_repr = "struct")]`

### Not Done

- **Xcode project file (.xcodeproj)**: The source files exist but there's no project.pbxproj. Creating one manually is complex.
- **Actual FSKit testing**: Haven't built/run the extension yet

## Next Steps

1. **Create Xcode project**:
   - Open Xcode, create new macOS App "FsKitty"
   - Add File System Extension target "FsKittyExt"
   - Replace generated files with `xcode/FsKitty/` and `xcode/FsKittyExt/`
   - Configure linker: `-L$(PROJECT_DIR)/../../target/release -lfs_kitty_swift`
   - Add BridgeHeaders to Header Search Paths

2. **Build and sign**

3. **Test mounting**:
   ```bash
   cargo run --package fs-kitty-server &
   # Install app, enable extension in System Settings
   sudo mkdir -p /Volumes/FsKitty
   mkfile -n 1m /tmp/fskitty.dmg
   DEVICE=$(hdiutil attach -imagekey diskimage-class=CRawDiskImage -nomount /tmp/fskitty.dmg)
   mount -F -t fskitty "$DEVICE" /Volumes/FsKitty
   ```

## Key Files

| File | Purpose |
|------|---------|
| `xcode/FsKittyExt/Volume.swift` | Main FSKit implementation - all FS operations |
| `xcode/FsKittyExt/Bridge.swift` | FSUnaryFileSystem - handles probe/load |
| `crates/fs-kitty-swift/src/lib.rs` | Rust FFI bridge with all VFS operations |
| `crates/fs-kitty-proto/src/lib.rs` | VFS protocol types (rapace service trait) |
| `README.md` | Updated with Xcode setup instructions |

## Gotchas

1. **swift-bridge async vs sync**: VFS functions are sync in the bridge (not `async fn`) because they create their own Tokio runtime internally. Using `async fn` with `block_on` inside causes "Cannot start a runtime from within a runtime" panic.

2. **Field naming**: FFI structs use snake_case (`item_id`, `item_type`) - Swift code must match.

3. **RustVec iteration**: Use `result.entries.len()` and `result.entries.get(index: i)` instead of `for entry in result.entries`.

4. **FSKit requires macOS 15.4+** and proper entitlements (`com.apple.developer.fskit.fsmodule`).

5. **Header order matters**: BridgeHeaders.h must include SwiftBridgeCore.h before fs-kitty-swift.h.

## Commands

```bash
# Build Rust library (regenerates headers)
cargo build --release --package fs-kitty-swift

# Start VFS server
cargo run --package fs-kitty-server

# Test Swift→Rust→TCP chain
cd swift/FsKitty && swift run

# Check FSKit extension registration (after install)
pluginkit -m -vv -p com.apple.fskit.fsmodule

# View extension logs
log stream --info --debug --style syslog --predicate 'subsystem == "FsKittyExt"'
```

## Reference

- FSKitBridge reference implementation: `~/bearcove/FSKitBridge/`
- Especially useful: `FSKitExt/Volume.swift`, `FSKitExt/Bridge.swift`
