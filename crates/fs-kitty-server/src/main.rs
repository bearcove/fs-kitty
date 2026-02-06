//! Spike: roam VFS server using fs-kitty-proto
//!
//! This implements a simple in-memory filesystem for testing.

use fs_kitty_proto::{
    CreateResult, DirEntry, GetAttributesResult, ItemAttributes, ItemId, ItemType, LookupResult,
    ReadDirResult, ReadResult, SetAttributesParams, Vfs, VfsDispatcher, VfsResult, WriteResult,
    errno, mode,
};
use roam_stream::{HandshakeConfig, accept};
use std::collections::HashMap;
use std::sync::{Arc, RwLock};
use tokio::net::TcpListener;

/// In-memory filesystem item
#[derive(Clone)]
struct FsItem {
    id: ItemId,
    parent_id: ItemId,
    name: String,
    item_type: ItemType,
    data: Vec<u8>,
    modified_time: u64,
    created_time: u64,
    mode: u32,
}

/// Simple in-memory VFS implementation
#[derive(Clone)]
struct MemoryVfs {
    items: Arc<RwLock<HashMap<ItemId, FsItem>>>,
    next_id: Arc<RwLock<ItemId>>,
}

impl MemoryVfs {
    fn new() -> Self {
        let mut items = HashMap::new();

        // Create root directory
        items.insert(
            1,
            FsItem {
                id: 1,
                parent_id: 0, // root has no parent
                name: String::new(),
                item_type: ItemType::Directory,
                data: Vec::new(),
                modified_time: 0,
                created_time: 0,
                mode: mode::DIRECTORY,
            },
        );

        // Create some test files
        items.insert(
            2,
            FsItem {
                id: 2,
                parent_id: 1,
                name: "hello.txt".to_string(),
                item_type: ItemType::File,
                data: b"Hello, World!\n".to_vec(),
                modified_time: 0,
                created_time: 0,
                mode: mode::FILE_REGULAR,
            },
        );

        items.insert(
            3,
            FsItem {
                id: 3,
                parent_id: 1,
                name: "documents".to_string(),
                item_type: ItemType::Directory,
                data: Vec::new(),
                modified_time: 0,
                created_time: 0,
                mode: mode::DIRECTORY,
            },
        );

        items.insert(
            4,
            FsItem {
                id: 4,
                parent_id: 3,
                name: "readme.md".to_string(),
                item_type: ItemType::File,
                data: b"# README\n\nThis is a test file.\n".to_vec(),
                modified_time: 0,
                created_time: 0,
                mode: mode::FILE_REGULAR,
            },
        );

        // Create an executable file for testing
        items.insert(
            5,
            FsItem {
                id: 5,
                parent_id: 1,
                name: "test.sh".to_string(),
                item_type: ItemType::File,
                data: b"#!/bin/bash\necho \"Hello from executable!\"\n".to_vec(),
                modified_time: 0,
                created_time: 0,
                mode: mode::FILE_EXECUTABLE,
            },
        );

        Self {
            items: Arc::new(RwLock::new(items)),
            next_id: Arc::new(RwLock::new(6)),
        }
    }

    fn get_children(&self, parent_id: ItemId) -> Vec<FsItem> {
        let items = self.items.read().unwrap();
        items
            .values()
            .filter(|item| item.parent_id == parent_id)
            .cloned()
            .collect()
    }
}

impl Vfs for MemoryVfs {
    async fn lookup(
        &self,
        _cx: &roam::session::Context,
        parent_id: ItemId,
        name: String,
    ) -> LookupResult {
        println!("  [server] lookup(parent={}, name={:?})", parent_id, name);

        let items = self.items.read().unwrap();
        for item in items.values() {
            if item.parent_id == parent_id && item.name == name {
                println!("  [server] -> found id={}", item.id);
                return LookupResult {
                    item_id: item.id,
                    item_type: item.item_type,
                    error: errno::OK,
                };
            }
        }

        println!("  [server] -> not found");
        LookupResult {
            item_id: 0,
            item_type: ItemType::File,
            error: errno::ENOENT,
        }
    }

    async fn get_attributes(
        &self,
        _cx: &roam::session::Context,
        item_id: ItemId,
    ) -> GetAttributesResult {
        println!("  [server] get_attributes({})", item_id);

        let items = self.items.read().unwrap();
        match items.get(&item_id) {
            Some(item) => {
                println!("  [server] -> found {:?} (mode={:o})", item.name, item.mode);
                GetAttributesResult {
                    attrs: ItemAttributes {
                        item_id: item.id,
                        item_type: item.item_type,
                        size: item.data.len() as u64,
                        modified_time: item.modified_time,
                        created_time: item.created_time,
                        mode: item.mode,
                    },
                    error: errno::OK,
                }
            }
            None => {
                println!("  [server] -> not found");
                GetAttributesResult {
                    attrs: ItemAttributes {
                        item_id: 0,
                        item_type: ItemType::File,
                        size: 0,
                        modified_time: 0,
                        created_time: 0,
                        mode: 0,
                    },
                    error: errno::ENOENT,
                }
            }
        }
    }

    async fn read_dir(
        &self,
        _cx: &roam::session::Context,
        item_id: ItemId,
        cursor: u64,
    ) -> ReadDirResult {
        println!("  [server] read_dir({}, cursor={})", item_id, cursor);

        let items = self.items.read().unwrap();
        match items.get(&item_id) {
            Some(item) if item.item_type == ItemType::Directory => {
                let children = self.get_children(item_id);
                let entries: Vec<DirEntry> = children
                    .iter()
                    .skip(cursor as usize)
                    .take(100) // page size
                    .map(|child| DirEntry {
                        name: child.name.clone(),
                        item_id: child.id,
                        item_type: child.item_type,
                    })
                    .collect();

                let has_more = children.len() > (cursor as usize + entries.len());
                let next_cursor = if has_more {
                    cursor + entries.len() as u64
                } else {
                    0
                };

                println!("  [server] -> {} entries", entries.len());
                ReadDirResult {
                    entries,
                    next_cursor,
                    error: errno::OK,
                }
            }
            Some(_) => {
                println!("  [server] -> not a directory");
                ReadDirResult {
                    entries: Vec::new(),
                    next_cursor: 0,
                    error: errno::ENOTDIR,
                }
            }
            None => {
                println!("  [server] -> not found");
                ReadDirResult {
                    entries: Vec::new(),
                    next_cursor: 0,
                    error: errno::ENOENT,
                }
            }
        }
    }

    async fn read(
        &self,
        _cx: &roam::session::Context,
        item_id: ItemId,
        offset: u64,
        len: u64,
    ) -> ReadResult {
        println!(
            "  [server] read({}, offset={}, len={})",
            item_id, offset, len
        );

        let items = self.items.read().unwrap();
        match items.get(&item_id) {
            Some(item) if item.item_type == ItemType::File => {
                let start = (offset as usize).min(item.data.len());
                let end = ((offset + len) as usize).min(item.data.len());
                let data = item.data[start..end].to_vec();
                println!("  [server] -> {} bytes", data.len());
                ReadResult {
                    data,
                    error: errno::OK,
                }
            }
            Some(_) => {
                println!("  [server] -> is a directory");
                ReadResult {
                    data: Vec::new(),
                    error: errno::EISDIR,
                }
            }
            None => {
                println!("  [server] -> not found");
                ReadResult {
                    data: Vec::new(),
                    error: errno::ENOENT,
                }
            }
        }
    }

    async fn write(
        &self,
        _cx: &roam::session::Context,
        item_id: ItemId,
        offset: u64,
        data: Vec<u8>,
    ) -> WriteResult {
        println!(
            "  [server] write({}, offset={}, {} bytes)",
            item_id,
            offset,
            data.len()
        );

        let mut items = self.items.write().unwrap();
        match items.get_mut(&item_id) {
            Some(item) if item.item_type == ItemType::File => {
                let offset = offset as usize;
                // Extend if needed
                if offset + data.len() > item.data.len() {
                    item.data.resize(offset + data.len(), 0);
                }
                item.data[offset..offset + data.len()].copy_from_slice(&data);
                println!("  [server] -> wrote {} bytes", data.len());
                WriteResult {
                    bytes_written: data.len() as u64,
                    error: errno::OK,
                }
            }
            Some(_) => {
                println!("  [server] -> is a directory");
                WriteResult {
                    bytes_written: 0,
                    error: errno::EISDIR,
                }
            }
            None => {
                println!("  [server] -> not found");
                WriteResult {
                    bytes_written: 0,
                    error: errno::ENOENT,
                }
            }
        }
    }

    async fn create(
        &self,
        _cx: &roam::session::Context,
        parent_id: ItemId,
        name: String,
        item_type: ItemType,
    ) -> CreateResult {
        println!(
            "  [server] create(parent={}, name={:?}, type={:?})",
            parent_id, name, item_type
        );

        // Check parent exists and is a directory
        {
            let items = self.items.read().unwrap();
            match items.get(&parent_id) {
                Some(parent) if parent.item_type != ItemType::Directory => {
                    println!("  [server] -> parent not a directory");
                    return CreateResult {
                        item_id: 0,
                        error: errno::ENOTDIR,
                    };
                }
                None => {
                    println!("  [server] -> parent not found");
                    return CreateResult {
                        item_id: 0,
                        error: errno::ENOENT,
                    };
                }
                _ => {}
            }

            // Check if name already exists
            for item in items.values() {
                if item.parent_id == parent_id && item.name == name {
                    println!("  [server] -> already exists");
                    return CreateResult {
                        item_id: 0,
                        error: errno::EEXIST,
                    };
                }
            }
        }

        // Create new item
        let new_id = {
            let mut next_id = self.next_id.write().unwrap();
            let id = *next_id;
            *next_id += 1;
            id
        };

        // Set default mode based on type
        let default_mode = match item_type {
            ItemType::Directory => mode::DIRECTORY,
            ItemType::File => mode::FILE_REGULAR,
            ItemType::Symlink => 0o777, // symlinks typically have all permissions
        };

        let new_item = FsItem {
            id: new_id,
            parent_id,
            name,
            item_type,
            data: Vec::new(),
            modified_time: 0,
            created_time: 0,
            mode: default_mode,
        };

        self.items.write().unwrap().insert(new_id, new_item);
        println!("  [server] -> created id={}", new_id);

        CreateResult {
            item_id: new_id,
            error: errno::OK,
        }
    }

    async fn delete(&self, _cx: &roam::session::Context, item_id: ItemId) -> VfsResult {
        println!("  [server] delete({})", item_id);

        if item_id == 1 {
            println!("  [server] -> cannot delete root");
            return VfsResult {
                error: errno::EACCES,
            };
        }

        let mut items = self.items.write().unwrap();

        if let Some(item) = items.get(&item_id)
            && item.item_type == ItemType::Directory
        {
            let has_children = items.values().any(|i| i.parent_id == item_id);
            if has_children {
                println!("  [server] -> directory not empty");
                return VfsResult {
                    error: errno::ENOTEMPTY,
                };
            }
        }

        match items.remove(&item_id) {
            Some(_) => {
                println!("  [server] -> deleted");
                VfsResult { error: errno::OK }
            }
            None => {
                println!("  [server] -> not found");
                VfsResult {
                    error: errno::ENOENT,
                }
            }
        }
    }

    async fn rename(
        &self,
        _cx: &roam::session::Context,
        item_id: ItemId,
        new_parent_id: ItemId,
        new_name: String,
    ) -> VfsResult {
        println!(
            "  [server] rename({} -> parent={}, name={:?})",
            item_id, new_parent_id, new_name
        );

        if item_id == 1 {
            println!("  [server] -> cannot rename root");
            return VfsResult {
                error: errno::EACCES,
            };
        }

        let mut items = self.items.write().unwrap();

        // Check new parent exists and is a directory
        match items.get(&new_parent_id) {
            Some(parent) if parent.item_type != ItemType::Directory => {
                println!("  [server] -> new parent not a directory");
                return VfsResult {
                    error: errno::ENOTDIR,
                };
            }
            None => {
                println!("  [server] -> new parent not found");
                return VfsResult {
                    error: errno::ENOENT,
                };
            }
            _ => {}
        }

        // Check target doesn't already exist
        for item in items.values() {
            if item.parent_id == new_parent_id && item.name == new_name && item.id != item_id {
                println!("  [server] -> target already exists");
                return VfsResult {
                    error: errno::EEXIST,
                };
            }
        }

        // Perform rename
        match items.get_mut(&item_id) {
            Some(item) => {
                item.parent_id = new_parent_id;
                item.name = new_name;
                println!("  [server] -> renamed");
                VfsResult { error: errno::OK }
            }
            None => {
                println!("  [server] -> not found");
                VfsResult {
                    error: errno::ENOENT,
                }
            }
        }
    }

    async fn set_attributes(
        &self,
        _cx: &roam::session::Context,
        item_id: ItemId,
        params: SetAttributesParams,
    ) -> VfsResult {
        println!(
            "  [server] set_attributes({}, mode={:?}, modified_time={:?})",
            item_id, params.mode, params.modified_time
        );

        let mut items = self.items.write().unwrap();
        match items.get_mut(&item_id) {
            Some(item) => {
                if let Some(mode) = params.mode {
                    println!("  [server] -> setting mode to {:o}", mode);
                    item.mode = mode;
                }
                if let Some(modified_time) = params.modified_time {
                    println!("  [server] -> setting modified_time to {}", modified_time);
                    item.modified_time = modified_time;
                }
                println!("  [server] -> attributes updated");
                VfsResult { error: errno::OK }
            }
            None => {
                println!("  [server] -> not found");
                VfsResult {
                    error: errno::ENOENT,
                }
            }
        }
    }

    async fn ping(&self, _cx: &roam::session::Context) -> String {
        println!("  [server] ping()");
        "pong from memory VFS".to_string()
    }
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    tracing_subscriber::fmt()
        .with_env_filter(
            tracing_subscriber::EnvFilter::from_default_env()
                .add_directive(tracing::Level::INFO.into()),
        )
        .init();

    let addr = "127.0.0.1:10001";
    let listener = TcpListener::bind(addr).await?;

    println!("=== fs-kitty VFS Server ===");
    println!("Listening on {}", addr);
    println!();
    println!("In-memory filesystem with:");
    println!("  /hello.txt           - regular file (mode 0o644)");
    println!("  /test.sh             - executable file (mode 0o755)");
    println!("  /documents/          - directory (mode 0o755)");
    println!("  /documents/readme.md - regular file (mode 0o644)");
    println!();
    println!("Waiting for connections...");

    // Shared VFS instance (MemoryVfs is Clone via Arc internals)
    let vfs = MemoryVfs::new();

    loop {
        let (socket, peer_addr) = listener.accept().await?;
        println!("\n[server] New connection from {}", peer_addr);

        let vfs = vfs.clone();
        tokio::spawn(async move {
            let dispatcher = VfsDispatcher::new(vfs);
            match accept(socket, HandshakeConfig::default(), dispatcher).await {
                Ok((_handle, _incoming, driver)) => {
                    if let Err(e) = driver.run().await {
                        eprintln!("[server] Connection error from {}: {}", peer_addr, e);
                    }
                }
                Err(e) => {
                    eprintln!("[server] Handshake error from {}: {}", peer_addr, e);
                }
            }
            println!("[server] Connection from {} closed", peer_addr);
        });
    }
}
