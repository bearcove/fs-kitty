//! Spike: rapace VFS server with bidirectional RPC
//!
//! This demonstrates:
//! 1. Server handling VFS requests from clients
//! 2. Server calling ClientEvents methods on the client (bidirectional)

use rapace::RpcSession;
use std::collections::HashMap;
use std::sync::Arc;
use tokio::net::TcpListener;

// ============================================================================
// VFS Service (client calls server)
// ============================================================================

/// Result type for VFS operations - uses i32 for errno compatibility.
#[derive(Debug, Clone, facet::Facet)]
pub struct LookupResult {
    pub item_id: u64,
    pub error: i32,
}

/// A minimal VFS service trait demonstrating rapace RPC.
#[allow(async_fn_in_trait)]
#[rapace::service]
pub trait Vfs {
    async fn ping(&self) -> String;
    async fn lookup(&self, path: String) -> LookupResult;
    async fn get_name(&self, item_id: u64) -> String;
}

// ============================================================================
// ClientEvents Service (server calls client - bidirectional RPC)
// ============================================================================

/// Events that the server can push to the client.
/// This is defined here so the server can use the generated ClientEventsClient.
#[allow(async_fn_in_trait)]
#[rapace::service]
pub trait ClientEvents {
    async fn on_file_changed(&self, path: String) -> String;
    async fn get_client_name(&self) -> String;
}

// ============================================================================
// VFS Implementation
// ============================================================================

/// Implementation of the VFS service with dummy data.
struct VfsImpl {
    items: HashMap<String, u64>,
    names: HashMap<u64, String>,
    /// Client for calling back to the connected client
    client_events: ClientEventsClient,
}

impl VfsImpl {
    fn new(client_events: ClientEventsClient) -> Self {
        let mut items = HashMap::new();
        let mut names = HashMap::new();

        items.insert("/".to_string(), 1);
        names.insert(1, "/".to_string());

        items.insert("/foo".to_string(), 2);
        names.insert(2, "foo".to_string());

        items.insert("/foo/bar.txt".to_string(), 3);
        names.insert(3, "bar.txt".to_string());

        items.insert("/documents".to_string(), 4);
        names.insert(4, "documents".to_string());

        Self {
            items,
            names,
            client_events,
        }
    }
}

impl Vfs for VfsImpl {
    async fn ping(&self) -> String {
        println!("  [server] ping() called");

        // Demonstrate bidirectional RPC: call back to the client!
        println!("  [server] -> Calling client's get_client_name()...");
        match self.client_events.get_client_name().await {
            Ok(name) => {
                println!("  [server] -> Client name: {:?}", name);

                // Also notify the client about a "change"
                println!("  [server] -> Calling client's on_file_changed()...");
                match self
                    .client_events
                    .on_file_changed("/foo/bar.txt".to_string())
                    .await
                {
                    Ok(ack) => {
                        println!("  [server] -> Client acknowledged: {:?}", ack);
                    }
                    Err(e) => {
                        println!("  [server] -> on_file_changed failed: {:?}", e);
                    }
                }

                format!("Hello {}! Greetings from VFS server!", name)
            }
            Err(e) => {
                println!("  [server] -> get_client_name failed: {:?}", e);
                "Hello from VFS server!".to_string()
            }
        }
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
                    error: 2,
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
    println!("=== VFS Server (Bidirectional) ===");
    println!("Listening on {}", addr);
    println!();
    println!("VFS Service methods (client -> server):");
    println!("  - ping() -> String");
    println!("  - lookup(path: String) -> LookupResult");
    println!("  - get_name(item_id: u64) -> String");
    println!();
    println!("ClientEvents methods (server -> client):");
    println!("  - on_file_changed(path: String) -> String");
    println!("  - get_client_name() -> String");
    println!();
    println!("Waiting for connections...");

    loop {
        let (socket, peer_addr) = listener.accept().await?;
        println!("\n[server] New connection from {}", peer_addr);

        tokio::spawn(async move {
            // Create transport from the TCP stream
            let transport = rapace::Transport::stream(socket);

            // Create session for bidirectional RPC
            // Use odd channel IDs (starting at 1) for server-initiated calls
            let session = Arc::new(RpcSession::with_channel_start(transport.clone(), 1));

            // Create a client for calling ClientEvents on the connected client
            let client_events = ClientEventsClient::new(session.clone());

            // Create VFS server with the client reference
            let vfs_impl = VfsImpl::new(client_events);
            let vfs_server = VfsServer::new(vfs_impl);

            // Set up the dispatcher for incoming VFS requests
            session.set_dispatcher(vfs_server.into_session_dispatcher(transport.clone()));

            // Run the session - this handles both:
            // - Incoming VFS requests from the client
            // - Routing responses for our ClientEvents calls
            if let Err(e) = session.run().await {
                eprintln!("[server] Connection error from {}: {}", peer_addr, e);
            }
            println!("[server] Connection from {} closed", peer_addr);
        });
    }
}
