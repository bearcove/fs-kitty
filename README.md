# fskitty

A Rust-first FSKit file system extension for macOS. Own every line of code.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│           macOS FSKit (XPC)                                  │
└───────────────┬─────────────────────────────────────────────┘
                │
┌───────────────▼─────────────────────────────────────────────┐
│  fskitty-fsext.appex                                        │
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

## De-risking Phases

We're validating each layer before building on it:

### Phase 1-2: Swift-Rust Linking (In Progress)
- Can Swift link against a Rust static library?
- Does swift-bridge codegen work?
- Can we pass structs across the boundary?

### Phase 3: Async swift-bridge (Complete)
**Key findings:**
- Async IS supported with `features = ["async"]`
- Supports Result<T, E>, Option<T>, custom structs/enums
- **CRITICAL**: `Vec<T>` cannot be returned from async functions (Issue #344)
- Workaround: Use opaque buffer types for read operations
- Requires Swift 5.9+ for typed throws

### Phase 4: Rapace TCP (In Progress)
- Prove rapace RPC works over TCP
- Define minimal VFS service trait
- Test bidirectional RPC

### Phase 5: Integration
- Swift → swift-bridge → Rust rapace client → TCP → Rust VFS backend

### Phase 6: FSKit Extension
- Minimal FSKit appex that mounts a real filesystem

## Crates

| Crate | Purpose |
|-------|---------|
| `fskitty-swift` | Rust lib exposed to Swift via swift-bridge |
| `spike-vfs-server` | Spike: rapace VFS server (TCP) |
| `spike-vfs-client` | Spike: rapace VFS client (TCP) |

## Building

```bash
# Build all crates
cargo build

# Build release (needed for Swift linking)
cargo build --release
```

## Running the Spikes

```bash
# Terminal 1: Start VFS server
cargo run --package spike-vfs-server

# Terminal 2: Run VFS client
cargo run --package spike-vfs-client
```

## Dependencies

- [rapace](https://github.com/bearcove/rapace) - High-performance RPC
- [swift-bridge](https://github.com/chinedufn/swift-bridge) - Swift-Rust FFI
- [facet](https://github.com/facet-rs/facet) - Serialization (used by rapace)

## License

MIT OR Apache-2.0
