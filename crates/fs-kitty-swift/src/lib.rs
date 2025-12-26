//! fs-kitty-swift: Swift bridge for VFS operations
//!
//! Exposes the Rust VFS client to Swift via swift-bridge FFI.

use fs_kitty_proto::{
    CreateResult, GetAttributesResult, ItemType, LookupResult, ReadDirResult, ReadResult,
    VfsClient, VfsResult, WriteResult,
};
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

// Swift-bridge struct definitions for FFI
// These are simpler versions of the protocol structs that swift-bridge can handle

#[swift_bridge::bridge]
mod ffi {
    // Lookup result: item_type is 0=File, 1=Directory, 2=Symlink
    #[swift_bridge(swift_repr = "struct")]
    struct FfiLookupResult {
        item_id: u64,
        item_type: u8,
        error: i32,
    }

    // Item attributes
    #[swift_bridge(swift_repr = "struct")]
    struct FfiItemAttributes {
        item_id: u64,
        item_type: u8,
        size: u64,
        modified_time: u64,
        created_time: u64,
        mode: u32,
        error: i32,
    }

    // Read directory result - using parallel arrays since swift-bridge
    // doesn't yet support Vec<TransparentStruct> (see issue #305)
    #[swift_bridge(swift_repr = "struct")]
    struct FfiReadDirResult {
        names: Vec<String>,
        item_ids: Vec<u64>,
        item_types: Vec<u8>,
        next_cursor: u64,
        error: i32,
    }

    // Read result with data
    #[swift_bridge(swift_repr = "struct")]
    struct FfiReadResult {
        data: Vec<u8>,
        error: i32,
    }

    // Write result
    #[swift_bridge(swift_repr = "struct")]
    struct FfiWriteResult {
        bytes_written: u64,
        error: i32,
    }

    // Create result
    #[swift_bridge(swift_repr = "struct")]
    struct FfiCreateResult {
        item_id: u64,
        error: i32,
    }

    // Simple result (success/error)
    #[swift_bridge(swift_repr = "struct")]
    struct FfiVfsResult {
        error: i32,
    }

    extern "Rust" {
        // Basic sync function (for testing)
        fn add(a: i32, b: i32) -> i32;

        // Async functions (for testing async works)
        async fn async_add(a: i32, b: i32) -> i32;
        async fn async_greet(name: String) -> String;

        // VFS connection management
        fn vfs_connect(addr: String) -> Result<(), String>;
        fn vfs_disconnect();
        fn vfs_ping() -> Result<String, String>;

        // VFS operations (all sync, using internal Tokio runtime)
        fn vfs_lookup(parent_id: u64, name: String) -> Result<FfiLookupResult, String>;
        fn vfs_get_attributes(item_id: u64) -> Result<FfiItemAttributes, String>;
        fn vfs_read_dir(item_id: u64, cursor: u64) -> Result<FfiReadDirResult, String>;
        fn vfs_read(item_id: u64, offset: u64, len: u64) -> Result<FfiReadResult, String>;
        fn vfs_write(item_id: u64, offset: u64, data: Vec<u8>) -> Result<FfiWriteResult, String>;
        fn vfs_create(parent_id: u64, name: String, item_type: u8) -> Result<FfiCreateResult, String>;
        fn vfs_delete(item_id: u64) -> Result<FfiVfsResult, String>;
        fn vfs_rename(item_id: u64, new_parent_id: u64, new_name: String) -> Result<FfiVfsResult, String>;
    }
}

// Re-export FFI types for internal use
use ffi::*;

fn add(a: i32, b: i32) -> i32 {
    a + b
}

async fn async_add(a: i32, b: i32) -> i32 {
    a + b
}

async fn async_greet(name: String) -> String {
    format!("Hello, {}!", name)
}

// VFS connection management

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

    VFS.set(VfsState {
        runtime,
        client,
        transport,
    })
    .map_err(|_| "Failed to set state".to_string())?;

    Ok(())
}

fn vfs_disconnect() {
    // OnceCell doesn't support removal, but we can signal disconnection
    // For now, this is a no-op as the state persists until process exit
}

fn vfs_ping() -> Result<String, String> {
    let state = VFS.get().ok_or("Not connected")?;
    state
        .runtime
        .block_on(state.client.ping())
        .map_err(|e| e.to_string())
}

// VFS operations

fn vfs_lookup(parent_id: u64, name: String) -> Result<FfiLookupResult, String> {
    let state = VFS.get().ok_or("Not connected")?;
    let result: LookupResult = state
        .runtime
        .block_on(state.client.lookup(parent_id, name))
        .map_err(|e| e.to_string())?;

    Ok(FfiLookupResult {
        item_id: result.item_id,
        item_type: item_type_to_u8(result.item_type),
        error: result.error,
    })
}

fn vfs_get_attributes(item_id: u64) -> Result<FfiItemAttributes, String> {
    let state = VFS.get().ok_or("Not connected")?;
    let result: GetAttributesResult = state
        .runtime
        .block_on(state.client.get_attributes(item_id))
        .map_err(|e| e.to_string())?;

    Ok(FfiItemAttributes {
        item_id: result.attrs.item_id,
        item_type: item_type_to_u8(result.attrs.item_type),
        size: result.attrs.size,
        modified_time: result.attrs.modified_time,
        created_time: result.attrs.created_time,
        mode: result.attrs.mode,
        error: result.error,
    })
}

fn vfs_read_dir(item_id: u64, cursor: u64) -> Result<FfiReadDirResult, String> {
    let state = VFS.get().ok_or("Not connected")?;
    let result: ReadDirResult = state
        .runtime
        .block_on(state.client.read_dir(item_id, cursor))
        .map_err(|e| e.to_string())?;

    // Build parallel arrays (swift-bridge doesn't support Vec<Struct> yet)
    let mut names = Vec::with_capacity(result.entries.len());
    let mut item_ids = Vec::with_capacity(result.entries.len());
    let mut item_types = Vec::with_capacity(result.entries.len());

    for entry in result.entries {
        names.push(entry.name);
        item_ids.push(entry.item_id);
        item_types.push(item_type_to_u8(entry.item_type));
    }

    Ok(FfiReadDirResult {
        names,
        item_ids,
        item_types,
        next_cursor: result.next_cursor,
        error: result.error,
    })
}

fn vfs_read(item_id: u64, offset: u64, len: u64) -> Result<FfiReadResult, String> {
    let state = VFS.get().ok_or("Not connected")?;
    let result: ReadResult = state
        .runtime
        .block_on(state.client.read(item_id, offset, len))
        .map_err(|e| e.to_string())?;

    Ok(FfiReadResult {
        data: result.data,
        error: result.error,
    })
}

fn vfs_write(item_id: u64, offset: u64, data: Vec<u8>) -> Result<FfiWriteResult, String> {
    let state = VFS.get().ok_or("Not connected")?;
    let result: WriteResult = state
        .runtime
        .block_on(state.client.write(item_id, offset, data))
        .map_err(|e| e.to_string())?;

    Ok(FfiWriteResult {
        bytes_written: result.bytes_written,
        error: result.error,
    })
}

fn vfs_create(parent_id: u64, name: String, item_type: u8) -> Result<FfiCreateResult, String> {
    let state = VFS.get().ok_or("Not connected")?;
    let result: CreateResult = state
        .runtime
        .block_on(state.client.create(parent_id, name, u8_to_item_type(item_type)))
        .map_err(|e| e.to_string())?;

    Ok(FfiCreateResult {
        item_id: result.item_id,
        error: result.error,
    })
}

fn vfs_delete(item_id: u64) -> Result<FfiVfsResult, String> {
    let state = VFS.get().ok_or("Not connected")?;
    let result: VfsResult = state
        .runtime
        .block_on(state.client.delete(item_id))
        .map_err(|e| e.to_string())?;

    Ok(FfiVfsResult {
        error: result.error,
    })
}

fn vfs_rename(item_id: u64, new_parent_id: u64, new_name: String) -> Result<FfiVfsResult, String> {
    let state = VFS.get().ok_or("Not connected")?;
    let result: VfsResult = state
        .runtime
        .block_on(state.client.rename(item_id, new_parent_id, new_name))
        .map_err(|e| e.to_string())?;

    Ok(FfiVfsResult {
        error: result.error,
    })
}

// Helper functions for ItemType conversion

fn item_type_to_u8(t: ItemType) -> u8 {
    match t {
        ItemType::File => 0,
        ItemType::Directory => 1,
        ItemType::Symlink => 2,
    }
}

fn u8_to_item_type(v: u8) -> ItemType {
    match v {
        0 => ItemType::File,
        1 => ItemType::Directory,
        2 => ItemType::Symlink,
        _ => ItemType::File,
    }
}
