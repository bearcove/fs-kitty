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

- **Swift ↔ Rust FFI** via swift-bridge (sync and async functions, structs, enums, `Vec<T>`, `Result<T, E>`)
- **Rapace RPC** over TCP with bidirectional calls
- **Full VFS protocol** - lookup, read, write, readdir, create, delete, rename
- **Rust client/server** tested end-to-end

### What's Next

1. ~~**Test Swift → Rust → TCP chain**~~ ✅ Complete - Swift calls Rust, Rust talks TCP to VFS server
2. **FSKit extension** - create `.appex` bundle implementing FSKit protocols
3. **Mount a real filesystem** - connect FSKit to the VFS backend

## Crates

| Crate | Purpose |
|-------|---------|
| `fs-kitty-proto` | Shared VFS protocol types |
| `fs-kitty-swift` | Rust lib exposed to Swift via swift-bridge |
| `fs-kitty-server` | In-memory VFS server (for testing) |
| `fs-kitty-client` | CLI VFS client (for testing) |

## Building

```bash
# Build all crates
cargo build

# Build release (needed for Swift linking)
cargo build --release
```

## Running

```bash
# Terminal 1: Start VFS server
cargo run --package fs-kitty-server

# Terminal 2: Run VFS client
cargo run --package fs-kitty-client

# Or run Swift test (needs server running)
cd swift/FsKitty && swift run
```

## Dependencies

- [rapace](https://github.com/bearcove/rapace) - High-performance RPC
- [swift-bridge](https://github.com/chinedufn/swift-bridge) - Swift-Rust FFI
- [facet](https://github.com/facet-rs/facet) - Serialization (used by rapace)

## License

MIT OR Apache-2.0
