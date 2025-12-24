# Handoff: fskitty Swift-Rapace Integration

## Current State

We're building **fskitty** - a Rust-first FSKit filesystem extension for macOS. The architecture:

```
Swift (FSKit) → swift-bridge → Rust (rapace client) → TCP → Rust VFS backend
```

### What's Done ✅

1. **Phase 1-2: Swift-Rust linking** - COMPLETE
   - swift-bridge codegen works
   - Struct passing works (Point type)
   - Swift Package builds and links against Rust staticlib

2. **Phase 3: Async swift-bridge** - COMPLETE
   - `async fn` works perfectly
   - `Vec<u8>` returns from async - WORKS (the limitation was overblown)
   - `Vec<Struct>` returns from async - WORKS
   - `Result<T, String>` with throws - WORKS

3. **Phase 4: Rapace TCP** - COMPLETE
   - Server/client communicate over TCP
   - Bidirectional RPC works
   - Full VFS CRUD operations tested

4. **fskitty-proto crate** - COMPLETE
   - Shared `Vfs` trait and types
   - Used by both server and client

5. **fskitty-swift as rapace client** - COMPILES
   - Has `vfs_connect(addr)` and `vfs_ping()` exposed to Swift
   - Uses global `OnceCell<VfsState>` for connection management
   - Tokio runtime embedded

### What's In Progress 🔄

**Swift package header update** - 90% done, just need to rebuild:

The generated headers were just combined:
```bash
cat generated/SwiftBridgeCore.h generated/fskitty-swift/fskitty-swift.h > swift/Spike1/Sources/BridgeHeaders/BridgeHeaders.h
```

Need to rebuild Swift package and test the full chain.

## Next Steps

1. **Build and test Swift package**
   ```bash
   cd swift/Spike1 && swift build
   ```

2. **Run full chain test**
   ```bash
   # Terminal 1
   cargo run --package spike-vfs-server

   # Terminal 2
   cd swift/Spike1 && swift run
   ```

3. **Add more VFS operations to fskitty-swift**
   - `vfs_lookup`, `vfs_read`, `vfs_read_dir`, etc.
   - Currently only `vfs_connect` and `vfs_ping` are exposed

4. **Commit Phase 5 work**

5. **Phase 6: Actual FSKit extension**
   - Create appex bundle
   - Implement FSKit protocols calling into fskitty-swift

## Key Files

| File | Purpose |
|------|---------|
| `crates/fskitty-proto/src/lib.rs` | Shared Vfs trait and types |
| `crates/fskitty-swift/src/lib.rs` | Swift bridge + rapace client |
| `crates/spike-vfs-server/src/main.rs` | In-memory VFS server |
| `swift/Spike1/Sources/Spike1/main.swift` | Swift test harness |
| `swift/Spike1/Sources/BridgeHeaders/BridgeHeaders.h` | Combined C headers |
| `README.md` | Project overview and phase status |
| `ARCHITECTURE.md` | Detailed design doc |

## Gotchas

1. **Struct definitions go OUTSIDE `extern "Rust"`** in swift-bridge
   ```rust
   mod ffi {
       #[swift_bridge(swift_repr = "struct")]
       struct Foo { ... }  // ✅ HERE

       extern "Rust" {
           // NOT here
           fn use_foo() -> Foo;
       }
   }
   ```

2. **Headers must be combined** - BridgeHeaders.h needs both SwiftBridgeCore.h and fskitty-swift.h content

3. **Facet version must match rapace** - use git dependency:
   ```toml
   facet = { git = "https://github.com/facet-rs/facet", branch = "main" }
   ```

4. **Remove old Swift files** - there was a duplicate `FskittySwift.swift` causing conflicts (already removed)

5. **Enums need `#[repr(u8)]`** for facet serialization

## Commands

```bash
# Build everything
cargo build --release

# Run VFS server
cargo run --package spike-vfs-server

# Run Rust client test
cargo run --package spike-vfs-client

# Build Swift package
cd swift/Spike1 && swift build

# Run Swift test (needs server running)
cd swift/Spike1 && swift run

# Regenerate headers after Rust changes
cargo build --package fskitty-swift --release
cat crates/fskitty-swift/generated/SwiftBridgeCore.h \
    crates/fskitty-swift/generated/fskitty-swift/fskitty-swift.h \
    > swift/Spike1/Sources/BridgeHeaders/BridgeHeaders.h
cp crates/fskitty-swift/generated/fskitty-swift/fskitty-swift.swift \
   swift/Spike1/Sources/Spike1/
cp crates/fskitty-swift/generated/SwiftBridgeCore.swift \
   swift/Spike1/Sources/Spike1/
# Add "import BridgeHeaders" to SwiftBridgeCore.swift after copying
```

## Test Output (Rust client working)

```
=== fskitty VFS Client ===
Connecting to 127.0.0.1:10001...
Connected!

--- Test 1: ping() ---
Response: "pong from memory VFS"

--- Test 3: read_dir(1) (root) ---
Root directory contents:
  hello.txt (id=2, type=File)
  documents (id=3, type=Directory)

--- Test 5: read(2, 0, 1024) ---
Content: "Hello, World!\n"

=== All tests passed! ===
```

The Rust→Rust chain is fully working. Swift→Rust→Rust is one header rebuild away.
