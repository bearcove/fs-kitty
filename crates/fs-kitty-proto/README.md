# fs-kitty-proto

VFS protocol for fs-kitty filesystem implementations.

## What is this?

This crate defines the RPC protocol for fs-kitty, a macOS FSKit filesystem that forwards operations to a backend server over TCP.

**Built for [vixen](https://github.com/bearcove/vixen)**, a hermetic Rust build system. The VFS protocol enables:
- **Build hermeticity** - Control exactly what files a build can access
- **On-the-fly materialization** - Provide proc-macro inputs and other requirements that aren't statically declared

If you want to implement your own VFS backend (e.g., mounting a database, cloud storage, or custom data structure as a filesystem), implement the `Vfs` trait from this crate.

**Status:** ✅ Tested and working end-to-end on macOS with signed FSKit extension. This protocol has been successfully used to mount real filesystems through macOS FSKit.

## Quick Start

Add to your `Cargo.toml`:

```toml
[dependencies]
fs-kitty-proto = { git = "https://github.com/bearcove/fs-kitty" }
rapace = { git = "https://github.com/bearcove/rapace" }
tokio = { version = "1", features = ["full"] }
```

Implement the `Vfs` trait:

```rust
use fs_kitty_proto::*;
use std::collections::HashMap;
use std::sync::RwLock;

struct MyVfs {
    items: RwLock<HashMap<ItemId, MyItem>>,
}

impl Vfs for MyVfs {
    async fn lookup(&self, parent_id: ItemId, name: String) -> LookupResult {
        let items = self.items.read().unwrap();
        for item in items.values() {
            if item.parent_id == parent_id && item.name == name {
                return LookupResult {
                    item_id: item.id,
                    item_type: item.item_type,
                    error: errno::OK,
                };
            }
        }
        LookupResult {
            item_id: 0,
            item_type: ItemType::File,
            error: errno::ENOENT,
        }
    }

    async fn get_attributes(&self, item_id: ItemId) -> GetAttributesResult {
        // ... implement
    }

    // ... implement other methods
}
```

Serve it over TCP:

```rust
use rapace::RpcSession;
use std::sync::Arc;
use tokio::net::TcpListener;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let listener = TcpListener::bind("127.0.0.1:10001").await?;
    let vfs = Arc::new(MyVfs::new());

    loop {
        let (socket, peer) = listener.accept().await?;
        println!("New connection from {}", peer);

        let vfs = Arc::clone(&vfs);
        tokio::spawn(async move {
            let transport = rapace::Transport::stream(socket);
            let session = Arc::new(RpcSession::new(transport.clone()));

            let vfs_server = VfsServer::new(vfs);
            session.set_dispatcher(vfs_server.into_session_dispatcher(transport));

            if let Err(e) = session.run().await {
                eprintln!("Connection error: {}", e);
            }
        });
    }
}
```

Then install the FSKit extension and mount:

```bash
# Install the FsKitty.app (see main repo README)
# Start your server
cargo run

# Mount the filesystem
mkfile -n 100m /tmp/test.dmg
hdiutil attach -nomount /tmp/test.dmg
mount -t fskitty /dev/diskN ~/mountpoint
```

## Protocol Overview

The protocol supports standard POSIX filesystem operations:

- **Lookup**: Find items by name in a directory
- **Get/Set Attributes**: File metadata (size, times, permissions)
- **Read/Write**: File content I/O
- **Create/Delete**: File and directory creation/deletion
- **Rename**: Move/rename items
- **Read Dir**: List directory contents

All operations use errno-style error codes (`errno::ENOENT`, `errno::EACCES`, etc.).

## Item IDs

Items are identified by unique 64-bit IDs. **Item ID 1 is reserved for the root directory**.

## Common Use Cases

### Intercepting Writes

To control what gets written during a build (for hermeticity), implement custom logic in the `write` method:

```rust
use fs_kitty_proto::*;

impl Vfs for MyVfs {
    async fn write(&self, item_id: ItemId, offset: u64, data: Vec<u8>) -> WriteResult {
        // Get the file path for logging/policy decisions
        let path = self.get_path(item_id); // your helper method

        // Policy: block writes to certain paths
        if path.starts_with("/read-only/") {
            return WriteResult {
                bytes_written: 0,
                error: errno::EACCES, // Permission denied
            };
        }

        // Log all writes for build reproducibility
        tracing::info!("write: {} ({} bytes at offset {})", path, data.len(), offset);

        // Validate write size limits
        if data.len() > 100_000_000 {
            return WriteResult {
                bytes_written: 0,
                error: errno::ENOSPC, // No space left on device
            };
        }

        // Actually perform the write
        self.do_write(item_id, offset, data).await
    }

    // ... other methods
}
```

This gives you full control over:
- **Which files can be written** (e.g., block writes outside the build output directory)
- **Write auditing** (log every write for reproducibility analysis)
- **Write validation** (enforce size limits, content policies, etc.)
- **On-the-fly materialization** (materialize files from cache/network when first written)

### Exposing Executable Files

The protocol supports Unix file permissions through the `mode` field in `ItemAttributes`.

The `ItemAttributes` struct includes:
- `item_id: ItemId` (u64)
- `item_type: ItemType` (enum: File, Directory, Symlink)
- `size: u64`
- `modified_time: u64` (Unix timestamp)
- `created_time: u64` (Unix timestamp)
- `mode: u32` - Unix permissions (e.g., 0o755 for executable, 0o644 for regular file)

**Setting file permissions** in your VFS implementation:

```rust
use fs_kitty_proto::*;

impl Vfs for MyVfs {
    async fn get_attributes(&self, item_id: ItemId) -> GetAttributesResult {
        let item = self.get_item(item_id);

        // Use the provided mode constants
        let file_mode = if item.is_executable {
            mode::FILE_EXECUTABLE  // 0o755 rwxr-xr-x
        } else if item.item_type == ItemType::Directory {
            mode::DIRECTORY  // 0o755 directories need 'x' to traverse
        } else {
            mode::FILE_REGULAR  // 0o644 rw-r--r--
        };

        GetAttributesResult {
            attrs: ItemAttributes {
                item_id: item.id,
                item_type: item.item_type,
                size: item.size,
                modified_time: item.modified_time,
                created_time: item.created_time,
                mode: file_mode,
            },
            error: errno::OK,
        }
    }
}
```

**Available mode constants:**
- `mode::FILE_REGULAR` (0o644) - Regular file, read-write for owner, read-only for others
- `mode::FILE_EXECUTABLE` (0o755) - Executable file
- `mode::DIRECTORY` (0o755) - Directory (needs 'x' bit to be traversable)
- `mode::FILE_PRIVATE` (0o600) - Private file, owner only
- `mode::FILE_PRIVATE_EXECUTABLE` (0o700) - Private executable, owner only

**Changing permissions with `set_attributes`:**

```rust
impl Vfs for MyVfs {
    async fn set_attributes(&self, item_id: ItemId, params: SetAttributesParams) -> VfsResult {
        let mut item = self.get_item_mut(item_id)?;

        if let Some(mode) = params.mode {
            item.mode = mode;
        }
        if let Some(modified_time) = params.modified_time {
            item.modified_time = modified_time;
        }

        VfsResult { error: errno::OK }
    }
}
```

**Note:** The protocol uses number-typed APIs (u64 for item_id, i32 for error codes, u32 for mode) which keeps it simple but requires understanding the numeric constants. Use the provided `mode::*` constants to avoid hardcoding octal values.

## See Also

- [fs-kitty](https://github.com/bearcove/fs-kitty) - Main repository with FSKit extension
- [fs-kitty-server](../fs-kitty-server) - Example in-memory VFS implementation
- [rapace](https://github.com/bearcove/rapace) - RPC framework
