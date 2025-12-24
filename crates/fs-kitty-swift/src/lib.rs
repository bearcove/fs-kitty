//! fs-kitty-swift: Swift bridge for VFS operations
//!
//! Starting minimal, adding complexity incrementally.

use fs_kitty_proto::VfsClient;
use once_cell::sync::OnceCell;
use rapace::RpcSession;
use std::sync::Arc;
use tokio::net::TcpStream;
use tokio::runtime::Runtime;

/// Global VFS client state
struct VfsState {
    runtime: Runtime,
    client: VfsClient,
    transport: rapace::Transport,
}

static VFS: OnceCell<VfsState> = OnceCell::new();

#[swift_bridge::bridge]
mod ffi {
    // Phase 6: Struct definitions go outside extern block
    #[swift_bridge(swift_repr = "struct")]
    struct ReadResult {
        data: Vec<u8>,
        error: i32,
    }

    // Phase 7: Vec of structs
    #[swift_bridge(swift_repr = "struct")]
    struct DirEntry {
        name: String,
        item_id: u64,
    }

    #[swift_bridge(swift_repr = "struct")]
    struct ReadDirResult {
        entries: Vec<DirEntry>,
        error: i32,
    }

    extern "Rust" {
        // Phase 1: Original sync functions (known to work)
        fn add(a: i32, b: i32) -> i32;

        // Phase 2: Simplest async function
        async fn async_add(a: i32, b: i32) -> i32;

        // Phase 3: Async with String return
        async fn async_greet(name: String) -> String;

        // Phase 4: Async with Result
        async fn async_divide(a: i32, b: i32) -> Result<i32, String>;

        // Phase 5: Async with Vec<u8> - works fine!
        async fn async_get_bytes(len: usize) -> Vec<u8>;

        // Phase 6: Async with struct return
        async fn async_read() -> ReadResult;

        // Phase 7: Async with Vec<Struct>
        async fn async_read_dir() -> ReadDirResult;

        // Phase 8: Real VFS connection
        async fn vfs_connect(addr: String) -> Result<(), String>;
        async fn vfs_ping() -> Result<String, String>;
    }
}

fn add(a: i32, b: i32) -> i32 {
    a + b
}

async fn async_add(a: i32, b: i32) -> i32 {
    a + b
}

async fn async_greet(name: String) -> String {
    format!("Hello, {}!", name)
}

async fn async_divide(a: i32, b: i32) -> Result<i32, String> {
    if b == 0 {
        Err("Division by zero".to_string())
    } else {
        Ok(a / b)
    }
}

async fn async_get_bytes(len: usize) -> Vec<u8> {
    vec![42u8; len]
}

async fn async_read() -> ffi::ReadResult {
    ffi::ReadResult {
        data: b"Hello from async read!".to_vec(),
        error: 0,
    }
}

async fn async_read_dir() -> ffi::ReadDirResult {
    ffi::ReadDirResult {
        entries: vec![
            ffi::DirEntry { name: "foo.txt".to_string(), item_id: 1 },
            ffi::DirEntry { name: "bar.txt".to_string(), item_id: 2 },
        ],
        error: 0,
    }
}

// Phase 8: Real VFS operations
async fn vfs_connect(addr: String) -> Result<(), String> {
    if VFS.get().is_some() {
        return Err("Already connected".to_string());
    }

    let runtime = Runtime::new().map_err(|e| e.to_string())?;

    let (client, transport) = runtime.block_on(async {
        let stream = TcpStream::connect(&addr).await.map_err(|e| e.to_string())?;
        let transport = rapace::Transport::stream(stream);
        let session = Arc::new(RpcSession::new(transport.clone()));

        let session_clone = session.clone();
        tokio::spawn(async move {
            let _ = session_clone.run().await;
        });

        let client = VfsClient::new(session);
        Ok::<_, String>((client, transport))
    })?;

    VFS.set(VfsState { runtime, client, transport })
        .map_err(|_| "Failed to set state".to_string())?;

    Ok(())
}

async fn vfs_ping() -> Result<String, String> {
    let state = VFS.get().ok_or("Not connected")?;
    state.runtime.block_on(state.client.ping()).map_err(|e| e.to_string())
}
