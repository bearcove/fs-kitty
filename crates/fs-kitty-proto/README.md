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

## See Also

- [fs-kitty](https://github.com/bearcove/fs-kitty) - Main repository with FSKit extension
- [fs-kitty-server](../fs-kitty-server) - Example in-memory VFS implementation
- [rapace](https://github.com/bearcove/rapace) - RPC framework
