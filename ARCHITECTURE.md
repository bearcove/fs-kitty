# fs-kitty Architecture

## Phase 5: Integration Design

### The Full Stack

```
┌─────────────────────────────────────────────────────────────┐
│  Swift (FSKit Extension)                                    │
│  - Implements FSKit protocols                               │
│  - Calls into fs-kitty-swift via swift-bridge              │
└──────────────────────────┬──────────────────────────────────┘
                           │ async fn (swift-bridge)
┌──────────────────────────▼──────────────────────────────────┐
│  fs-kitty-swift (Rust staticlib)                            │
│  - Exposes VFS operations to Swift                          │
│  - Manages rapace client connection                         │
│  - Runs on tokio runtime                                    │
└──────────────────────────┬──────────────────────────────────┘
                           │ TCP (rapace protocol)
┌──────────────────────────▼──────────────────────────────────┐
│  VFS Backend (any Rust app)                                 │
│  - Implements Vfs trait                                     │
│  - Could be in-process or remote                            │
└─────────────────────────────────────────────────────────────┘
```

### Connection Management

The fs-kitty-swift crate needs a singleton rapace client:

```rust
// Global client state
static CLIENT: OnceCell<Arc<VfsClientHandle>> = OnceCell::new();

struct VfsClientHandle {
    session: Arc<RpcSession>,
    client: VfsClient,
    runtime: Runtime,
}
```

Exposed to Swift as:
```rust
#[swift_bridge::bridge]
mod ffi {
    extern "Rust" {
        async fn vfs_connect(addr: String) -> Result<(), String>;
        async fn vfs_disconnect();

        async fn vfs_lookup(path: String) -> Result<VfsItem, VfsError>;
        // ...
    }
}
```

### The Vec<u8> Problem and Solution

**Problem**: `Vec<T>` cannot be returned from async swift-bridge functions.

**Solution**: Use an opaque `RustBuffer` type:

```rust
#[swift_bridge::bridge]
mod ffi {
    extern "Rust" {
        type RustBuffer;

        // Sync methods on the buffer - called after async read completes
        fn rust_buffer_len(buffer: &RustBuffer) -> usize;
        fn rust_buffer_copy_to(buffer: &RustBuffer, dest: *mut u8);
    }

    extern "Rust" {
        // Returns opaque buffer handle
        async fn vfs_read(item_id: u64, offset: u64, len: u64) -> Result<RustBuffer, VfsError>;
    }
}

// Swift usage:
// let buffer = try await vfs_read(itemId, offset, len)
// let data = Data(bytesNoCopy: UnsafeMutableRawPointer.allocate(byteCount: buffer.len(), alignment: 1),
//                 count: Int(buffer.len()),
//                 deallocator: .free)
// buffer.copy_to(data.baseAddress!)
```

### VFS Service Trait

Shared between fs-kitty-swift (client) and VFS backends (server):

```rust
#[rapace::service]
pub trait Vfs {
    // Metadata
    async fn lookup(&self, parent_id: u64, name: String) -> LookupResult;
    async fn get_attributes(&self, item_id: u64) -> AttributesResult;

    // Directory operations
    async fn read_directory(&self, item_id: u64, cursor: u64) -> DirEntriesResult;

    // File I/O
    async fn read(&self, item_id: u64, offset: u64, len: u64) -> ReadResult;
    async fn write(&self, item_id: u64, offset: u64, data: Vec<u8>) -> WriteResult;

    // Modification
    async fn create(&self, parent_id: u64, name: String, item_type: ItemType) -> CreateResult;
    async fn delete(&self, item_id: u64) -> DeleteResult;
    async fn rename(&self, item_id: u64, new_parent: u64, new_name: String) -> RenameResult;
}
```

### FSKit Integration (Phase 6)

FSKit's `FSBlockDeviceFileSystemBase` or `FSUnaryFileSystemBase` protocols map to our Vfs trait:

| FSKit Method | Vfs Method |
|--------------|------------|
| `lookup(in:name:)` | `vfs_lookup(parent_id, name)` |
| `attributes(of:)` | `vfs_get_attributes(item_id)` |
| `contents(of:range:)` | `vfs_read(item_id, offset, len)` |
| `write(contents:to:at:)` | `vfs_write(item_id, offset, data)` |

### Crate Organization

```
crates/
├── fs-kitty-proto/      # Shared types: Vfs trait, VfsError, etc.
├── fs-kitty-swift/      # Swift bridge + rapace client
├── fs-kitty-server/     # Example/test VFS backend
└── fs-kitty-client/     # CLI test client
```

### Next Steps

1. Test full chain: Swift test → fs-kitty-swift → fs-kitty-server
2. Phase 6: actual FSKit extension (.appex bundle)
