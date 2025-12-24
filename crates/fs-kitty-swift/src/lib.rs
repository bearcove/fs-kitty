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
    #[allow(dead_code)]
    transport: rapace::Transport,
}

static VFS: OnceCell<VfsState> = OnceCell::new();

#[swift_bridge::bridge]
mod ffi {
    extern "Rust" {
        // Basic sync function
        fn add(a: i32, b: i32) -> i32;

        // Async functions (no I/O, just prove async works)
        async fn async_add(a: i32, b: i32) -> i32;
        async fn async_greet(name: String) -> String;

        // VFS connection (sync - uses own Tokio runtime internally)
        fn vfs_connect(addr: String) -> Result<(), String>;
        fn vfs_ping() -> Result<String, String>;
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

// VFS operations - sync functions that use internal Tokio runtime
fn vfs_connect(addr: String) -> Result<(), String> {
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

fn vfs_ping() -> Result<String, String> {
    let state = VFS.get().ok_or("Not connected")?;
    state.runtime.block_on(state.client.ping()).map_err(|e| e.to_string())
}
