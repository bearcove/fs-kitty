//! # fs-kitty-proto
//!
//! VFS protocol for fs-kitty filesystem implementations.
//!
//! ## For Backend Implementers
//!
//! To create your own VFS backend, simply implement the [`Vfs`] trait:
//!
//! ```rust,no_run
//! use fs_kitty_proto::*;
//!
//! struct MyVfs;
//!
//! impl Vfs for MyVfs {
//!     async fn lookup(&self, parent_id: ItemId, name: String) -> LookupResult {
//!         // Your implementation here
//!         todo!()
//!     }
//!     // ... implement other methods
//! #   async fn get_attributes(&self, item_id: ItemId) -> GetAttributesResult { todo!() }
//! #   async fn read_dir(&self, item_id: ItemId, cursor: u64) -> ReadDirResult { todo!() }
//! #   async fn read(&self, item_id: ItemId, offset: u64, len: u64) -> ReadResult { todo!() }
//! #   async fn write(&self, item_id: ItemId, offset: u64, data: Vec<u8>) -> WriteResult { todo!() }
//! #   async fn create(&self, parent_id: ItemId, name: String, item_type: ItemType) -> CreateResult { todo!() }
//! #   async fn delete(&self, item_id: ItemId) -> VfsResult { todo!() }
//! #   async fn rename(&self, item_id: ItemId, new_parent_id: ItemId, new_name: String) -> VfsResult { todo!() }
//! #   async fn ping(&self) -> String { todo!() }
//! }
//! ```
//!
//! Then serve it over TCP using rapace:
//!
//! ```rust,no_run
//! # use fs_kitty_proto::*;
//! # struct MyVfs;
//! # impl Vfs for MyVfs {
//! #   async fn lookup(&self, parent_id: ItemId, name: String) -> LookupResult { todo!() }
//! #   async fn get_attributes(&self, item_id: ItemId) -> GetAttributesResult { todo!() }
//! #   async fn read_dir(&self, item_id: ItemId, cursor: u64) -> ReadDirResult { todo!() }
//! #   async fn read(&self, item_id: ItemId, offset: u64, len: u64) -> ReadResult { todo!() }
//! #   async fn write(&self, item_id: ItemId, offset: u64, data: Vec<u8>) -> WriteResult { todo!() }
//! #   async fn create(&self, parent_id: ItemId, name: String, item_type: ItemType) -> CreateResult { todo!() }
//! #   async fn delete(&self, item_id: ItemId) -> VfsResult { todo!() }
//! #   async fn rename(&self, item_id: ItemId, new_parent_id: ItemId, new_name: String) -> VfsResult { todo!() }
//! #   async fn ping(&self) -> String { todo!() }
//! # }
//! use rapace::RpcSession;
//! use std::sync::Arc;
//! use tokio::net::TcpListener;
//!
//! #[tokio::main]
//! async fn main() -> Result<(), Box<dyn std::error::Error>> {
//!     let listener = TcpListener::bind("127.0.0.1:10001").await?;
//!     let vfs = Arc::new(MyVfs);
//!
//!     loop {
//!         let (socket, _) = listener.accept().await?;
//!         let vfs = Arc::clone(&vfs);
//!
//!         tokio::spawn(async move {
//!             let transport = rapace::Transport::stream(socket);
//!             let session = Arc::new(RpcSession::new(transport.clone()));
//!             let vfs_server = VfsServer::new(vfs);
//!             session.set_dispatcher(vfs_server.into_session_dispatcher(transport));
//!             let _ = session.run().await;
//!         });
//!     }
//! }
//! ```
//!
//! ## Architecture
//!
//! This crate defines the rapace service trait and types shared between:
//! - `fs-kitty-swift` - the Swift/Rust client embedded in the FSKit extension
//! - VFS backends - servers implementing the filesystem (like `fs-kitty-server`)

/// Item ID type - unique identifier for files/directories.
/// ID 1 is reserved for the root directory.
pub type ItemId = u64;

/// File/directory attributes
#[derive(Debug, Clone, facet::Facet)]
pub struct ItemAttributes {
    pub item_id: ItemId,
    pub item_type: ItemType,
    pub size: u64,
    /// Unix timestamp (seconds since epoch)
    pub modified_time: u64,
    /// Unix timestamp (seconds since epoch)
    pub created_time: u64,
}

/// Type of filesystem item
#[derive(Debug, Clone, Copy, PartialEq, Eq, facet::Facet)]
#[repr(u8)]
pub enum ItemType {
    File,
    Directory,
    Symlink,
}

/// Result of a lookup operation
#[derive(Debug, Clone, facet::Facet)]
pub struct LookupResult {
    pub item_id: ItemId,
    pub item_type: ItemType,
    /// 0 = success, non-zero = errno-like error code
    pub error: i32,
}

/// Result of reading file contents
#[derive(Debug, Clone, facet::Facet)]
pub struct ReadResult {
    pub data: Vec<u8>,
    /// 0 = success, non-zero = errno-like error code
    pub error: i32,
}

/// Result of a write operation
#[derive(Debug, Clone, facet::Facet)]
pub struct WriteResult {
    pub bytes_written: u64,
    /// 0 = success, non-zero = errno-like error code
    pub error: i32,
}

/// A directory entry
#[derive(Debug, Clone, facet::Facet)]
pub struct DirEntry {
    pub name: String,
    pub item_id: ItemId,
    pub item_type: ItemType,
}

/// Result of reading a directory
#[derive(Debug, Clone, facet::Facet)]
pub struct ReadDirResult {
    pub entries: Vec<DirEntry>,
    /// Cursor for pagination (0 = no more entries)
    pub next_cursor: u64,
    /// 0 = success, non-zero = errno-like error code
    pub error: i32,
}

/// Result of getting attributes
#[derive(Debug, Clone, facet::Facet)]
pub struct GetAttributesResult {
    pub attrs: ItemAttributes,
    /// 0 = success, non-zero = errno-like error code
    pub error: i32,
}

/// Result of create operation
#[derive(Debug, Clone, facet::Facet)]
pub struct CreateResult {
    pub item_id: ItemId,
    /// 0 = success, non-zero = errno-like error code
    pub error: i32,
}

/// Simple success/error result
#[derive(Debug, Clone, facet::Facet)]
pub struct VfsResult {
    /// 0 = success, non-zero = errno-like error code
    pub error: i32,
}

/// The VFS service trait - defines the RPC interface between client and server.
#[allow(async_fn_in_trait)]
#[rapace::service]
pub trait Vfs {
    /// Look up an item by name in a parent directory.
    async fn lookup(&self, parent_id: ItemId, name: String) -> LookupResult;

    /// Get attributes for an item.
    async fn get_attributes(&self, item_id: ItemId) -> GetAttributesResult;

    /// Read directory contents.
    /// Use cursor=0 for first page, then use returned next_cursor for subsequent pages.
    async fn read_dir(&self, item_id: ItemId, cursor: u64) -> ReadDirResult;

    /// Read file contents.
    async fn read(&self, item_id: ItemId, offset: u64, len: u64) -> ReadResult;

    /// Write file contents.
    async fn write(&self, item_id: ItemId, offset: u64, data: Vec<u8>) -> WriteResult;

    /// Create a new file or directory.
    async fn create(&self, parent_id: ItemId, name: String, item_type: ItemType) -> CreateResult;

    /// Delete an item.
    async fn delete(&self, item_id: ItemId) -> VfsResult;

    /// Rename/move an item.
    async fn rename(&self, item_id: ItemId, new_parent_id: ItemId, new_name: String) -> VfsResult;

    /// Ping for connectivity check.
    async fn ping(&self) -> String;
}

/// Common errno-like error codes
pub mod errno {
    /// No error
    pub const OK: i32 = 0;
    /// No such file or directory
    pub const ENOENT: i32 = 2;
    /// I/O error
    pub const EIO: i32 = 5;
    /// Permission denied
    pub const EACCES: i32 = 13;
    /// File exists
    pub const EEXIST: i32 = 17;
    /// Not a directory
    pub const ENOTDIR: i32 = 20;
    /// Is a directory
    pub const EISDIR: i32 = 21;
    /// Invalid argument
    pub const EINVAL: i32 = 22;
    /// No space left on device
    pub const ENOSPC: i32 = 28;
    /// Directory not empty
    pub const ENOTEMPTY: i32 = 66;
}
