# Implementing Your Own VFS Backend

This guide shows how to create a custom VFS backend for fs-kitty.

## Overview

fs-kitty uses a client-server architecture:

```
macOS Kernel
     ↓
FSKit Extension (Swift/Rust client)
     ↓ TCP
VFS Backend Server (Your code!)
```

The FSKit extension is pre-built and distributed as `FsKitty.app`. You just need to implement a VFS server that speaks the `fs-kitty-proto` protocol.

## Step 1: Add Dependencies

```toml
[dependencies]
fs-kitty-proto = { git = "https://github.com/bearcove/fs-kitty" }
roam = { git = "https://github.com/bearcove/roam" }
roam-stream = { git = "https://github.com/bearcove/roam" }
tokio = { version = "1", features = ["full"] }
```

## Step 2: Implement the `Vfs` Trait

The `Vfs` trait from `fs-kitty-proto` defines the filesystem operations:

```rust
use fs_kitty_proto::*;

struct MyVfs {
    // Your state here
}

impl Vfs for MyVfs {
    async fn lookup(&self, _cx: &roam::session::Context, parent_id: ItemId, name: String) -> LookupResult {
        // Find item by name in parent directory
        // Return LookupResult with item_id or errno::ENOENT
    }

    async fn get_attributes(&self, _cx: &roam::session::Context, item_id: ItemId) -> GetAttributesResult {
        // Return file metadata (size, times, type)
    }

    async fn read_dir(&self, _cx: &roam::session::Context, item_id: ItemId, cursor: u64) -> ReadDirResult {
        // List directory contents (paginated)
    }

    async fn read(&self, _cx: &roam::session::Context, item_id: ItemId, offset: u64, len: u64) -> ReadResult {
        // Read file contents
    }

    async fn write(&self, _cx: &roam::session::Context, item_id: ItemId, offset: u64, data: Vec<u8>) -> WriteResult {
        // Write file contents
    }

    async fn create(&self, _cx: &roam::session::Context, parent_id: ItemId, name: String, item_type: ItemType) -> CreateResult {
        // Create new file or directory
    }

    async fn delete(&self, _cx: &roam::session::Context, item_id: ItemId) -> VfsResult {
        // Delete file or empty directory
    }

    async fn rename(&self, _cx: &roam::session::Context, item_id: ItemId, new_parent_id: ItemId, new_name: String) -> VfsResult {
        // Move/rename item
    }

    async fn set_attributes(&self, _cx: &roam::session::Context, item_id: ItemId, params: SetAttributesParams) -> VfsResult {
        // Set permissions, timestamps, etc.
    }

    async fn ping(&self, _cx: &roam::session::Context) -> String {
        "pong".to_string()
    }
}
```

## Step 3: Serve Over TCP

Use roam-stream to serve your VFS over TCP:

```rust
use fs_kitty_proto::VfsDispatcher;
use roam_stream::{HandshakeConfig, accept};
use tokio::net::TcpListener;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let listener = TcpListener::bind("127.0.0.1:10001").await?;
    let vfs = MyVfs::new(); // Must implement Clone

    println!("VFS server listening on 127.0.0.1:10001");

    loop {
        let (socket, peer) = listener.accept().await?;
        println!("Connection from {}", peer);

        let vfs = vfs.clone();
        tokio::spawn(async move {
            let dispatcher = VfsDispatcher::new(vfs);
            match accept(socket, HandshakeConfig::default(), dispatcher).await {
                Ok((_handle, _incoming, driver)) => {
                    if let Err(e) = driver.run().await {
                        eprintln!("Connection error from {}: {}", peer, e);
                    }
                }
                Err(e) => {
                    eprintln!("Handshake error from {}: {}", peer, e);
                }
            }
        });
    }
}
```

## Step 4: Run and Mount

1. **Install the FSKit extension** (one-time setup):
   ```bash
   # Download FsKitty.app from releases
   cp -R FsKitty.app /Applications/
   open /Applications/FsKitty.app

   # Enable in System Settings → Privacy & Security → File System Extensions
   ```

2. **Start your VFS server**:
   ```bash
   cargo run
   ```

3. **Mount using the fskitty:// URL scheme**:
   ```bash
   mkdir -p ~/mymount
   mount -t fskitty fskitty://localhost:10001 ~/mymount
   ```

   The URL format is `fskitty://host:port` where:
   - `host` is the VFS server hostname (e.g., `localhost`, `127.0.0.1`)
   - `port` is optional, defaults to `10001`

4. **Test filesystem operations**:
   ```bash
   ls ~/mymount/
   touch ~/mymount/hello.txt
   echo "test" > ~/mymount/hello.txt
   cat ~/mymount/hello.txt
   ```

5. **Unmount when done**:
   ```bash
   umount ~/mymount
   ```

## Important Details

### Item IDs

- **Item ID 1 is always the root directory**
- All other IDs are assigned by your VFS
- IDs must be unique and stable across operations

### Error Codes

Use errno-style error codes from `fs_kitty_proto::errno`:

```rust
errno::OK         // Success (0)
errno::ENOENT     // No such file or directory
errno::EACCES     // Permission denied
errno::EEXIST     // File exists
errno::ENOTDIR    // Not a directory
errno::EISDIR     // Is a directory
errno::ENOTEMPTY  // Directory not empty
errno::EINVAL     // Invalid argument
```

### Concurrency

The RPC server is multi-threaded:
- Wrap shared state in `Arc<RwLock<T>>` or similar
- Each connection gets its own task
- Methods can be called concurrently

### Directory Listing Pagination

`read_dir` uses cursor-based pagination:
- Start with `cursor=0`
- Return entries and `next_cursor`
- `next_cursor=0` means no more entries

## Example Implementations

See the repository for examples:

- **`fs-kitty-server`** - In-memory filesystem (good starting point)
- Future: Database-backed, S3-backed, etc.

## Debugging

Watch logs in real-time:

```bash
log stream --info --debug --style syslog --predicate \
  'subsystem == "com.apple.FSKit" OR subsystem == "me.amos.fs-kitty.ext"'
```

## Troubleshooting

See [DEVELOP.md](../DEVELOP.md) for common issues and fixes, especially:
- Extension won't launch → kill FSKit daemons
- Permission errors → check System Settings
- Build issues → use Release configuration
