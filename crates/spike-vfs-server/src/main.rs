//! Spike: rapace VFS server
//!
//! This demonstrates using rapace RPC over TCP for a minimal VFS service.
//! The server listens on TCP port 10001 and handles ping/lookup operations.

use std::collections::HashMap;
use tokio::net::TcpListener;

/// Result type for VFS operations - uses i32 for errno compatibility.
/// Positive values are item IDs, negative values are errno codes.
#[derive(Debug, Clone, facet::Facet)]
pub struct LookupResult {
    /// Item ID if found (> 0), or 0 if not found
    pub item_id: u64,
    /// Error code (0 = success, non-zero = errno-like error)
    pub error: i32,
}

/// A minimal VFS service trait demonstrating rapace RPC.
///
/// This defines the contract between the Swift FileProvider extension
/// and the Rust VFS backend.
#[allow(async_fn_in_trait)]
#[rapace::service]
pub trait Vfs {
    /// Simple ping to verify connectivity.
    /// Returns a greeting message.
    async fn ping(&self) -> String;

    /// Look up a path and return its item ID.
    /// Returns LookupResult with item_id on success, or error code on failure.
    async fn lookup(&self, path: String) -> LookupResult;

    /// Get the name of an item by its ID.
    /// Returns the name, or empty string if not found.
    async fn get_name(&self, item_id: u64) -> String;
}

/// Implementation of the VFS service with dummy data.
struct VfsImpl {
    /// Simulated file system: path -> item_id
    items: HashMap<String, u64>,
    /// Reverse mapping: item_id -> name
    names: HashMap<u64, String>,
}

impl VfsImpl {
    fn new() -> Self {
        let mut items = HashMap::new();
        let mut names = HashMap::new();

        // Populate with some dummy data
        items.insert("/".to_string(), 1);
        names.insert(1, "/".to_string());

        items.insert("/foo".to_string(), 2);
        names.insert(2, "foo".to_string());

        items.insert("/foo/bar.txt".to_string(), 3);
        names.insert(3, "bar.txt".to_string());

        items.insert("/documents".to_string(), 4);
        names.insert(4, "documents".to_string());

        Self { items, names }
    }
}

impl Vfs for VfsImpl {
    async fn ping(&self) -> String {
        println!("  [server] ping() called");
        "Hello from VFS server!".to_string()
    }

    async fn lookup(&self, path: String) -> LookupResult {
        println!("  [server] lookup({:?}) called", path);
        match self.items.get(&path) {
            Some(&item_id) => {
                println!("  [server] -> found item_id={}", item_id);
                LookupResult { item_id, error: 0 }
            }
            None => {
                println!("  [server] -> not found (ENOENT)");
                LookupResult {
                    item_id: 0,
                    error: 2, // ENOENT
                }
            }
        }
    }

    async fn get_name(&self, item_id: u64) -> String {
        println!("  [server] get_name({}) called", item_id);
        match self.names.get(&item_id) {
            Some(name) => {
                println!("  [server] -> {:?}", name);
                name.clone()
            }
            None => {
                println!("  [server] -> not found");
                String::new()
            }
        }
    }
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    // Initialize tracing
    tracing_subscriber::fmt()
        .with_env_filter(
            tracing_subscriber::EnvFilter::from_default_env()
                .add_directive(tracing::Level::INFO.into()),
        )
        .init();

    let addr = "127.0.0.1:10001";
    let listener = TcpListener::bind(addr).await?;
    println!("=== VFS Server ===");
    println!("Listening on {}", addr);
    println!();
    println!("Service methods:");
    println!("  - ping() -> String");
    println!("  - lookup(path: String) -> LookupResult");
    println!("  - get_name(item_id: u64) -> String");
    println!();
    println!("Waiting for connections...");

    loop {
        let (socket, peer_addr) = listener.accept().await?;
        println!("\n[server] New connection from {}", peer_addr);

        tokio::spawn(async move {
            // Create transport from the TCP stream
            let transport = rapace::Transport::stream(socket);

            // Create server and serve requests
            let server = VfsServer::new(VfsImpl::new());
            if let Err(e) = server.serve(transport).await {
                eprintln!("[server] Connection error from {}: {}", peer_addr, e);
            }
            println!("[server] Connection from {} closed", peer_addr);
        });
    }
}
