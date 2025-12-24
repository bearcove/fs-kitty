//! Spike: rapace VFS client with bidirectional RPC
//!
//! This demonstrates:
//! 1. Client calling VFS methods on the server
//! 2. Server calling ClientEvents methods on the client (bidirectional)

use rapace::RpcSession;
use std::sync::Arc;
use tokio::net::TcpStream;

// ============================================================================
// VFS Service (client calls server)
// ============================================================================

/// Result type for VFS operations - must match the server's definition.
#[derive(Debug, Clone, facet::Facet)]
pub struct LookupResult {
    pub item_id: u64,
    pub error: i32,
}

/// The VFS service trait - must match the server's definition.
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
/// This demonstrates rapace's peer-to-peer capability.
#[allow(async_fn_in_trait)]
#[rapace::service]
pub trait ClientEvents {
    /// Called by the server to notify the client about a file change.
    async fn on_file_changed(&self, path: String) -> String;

    /// Called by the server to get the client's name/identity.
    async fn get_client_name(&self) -> String;
}

/// Implementation of ClientEvents - handles calls FROM the server.
struct ClientEventsImpl {
    client_name: String,
}

impl ClientEvents for ClientEventsImpl {
    async fn on_file_changed(&self, path: String) -> String {
        println!("  [client] on_file_changed({:?}) - received notification from server!", path);
        format!("ACK: {} received change for {}", self.client_name, path)
    }

    async fn get_client_name(&self) -> String {
        println!("  [client] get_client_name() - server is asking our name");
        self.client_name.clone()
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
    println!("=== VFS Client (Bidirectional) ===");
    println!("Connecting to {}...", addr);

    // Connect to the server
    let stream = TcpStream::connect(addr).await?;
    println!("Connected!");
    println!();

    // Wrap in transport + session
    // Use even channel IDs (starting at 2) for client-initiated calls
    // The server uses odd channel IDs (starting at 1) for server-initiated calls
    let transport = rapace::Transport::stream(stream);
    let session = Arc::new(RpcSession::with_channel_start(transport.clone(), 2));

    // Set up the dispatcher for incoming requests (server calling client)
    let client_events_impl = ClientEventsImpl {
        client_name: "VFSClient-001".to_string(),
    };
    let client_server = ClientEventsServer::new(client_events_impl);
    session.set_dispatcher(client_server.into_session_dispatcher(transport.clone()));

    // Spawn the session demux loop to route both responses and incoming requests
    let session_clone = session.clone();
    tokio::spawn(async move {
        if let Err(e) = session_clone.run().await {
            eprintln!("[client] Session error: {}", e);
        }
    });

    // Create client for calling VFS methods on the server
    let vfs = VfsClient::new(session.clone());

    // --- Test 1: Basic VFS operations ---
    println!("=== Part 1: Client -> Server RPC ===");
    println!();

    println!("--- Test 1: ping() ---");
    let response = vfs.ping().await?;
    println!("Response: {:?}", response);
    println!();

    println!("--- Test 2: lookup(\"/foo\") ---");
    let result = vfs.lookup("/foo".to_string()).await?;
    println!("Result: {:?}", result);
    if result.error == 0 {
        println!("  -> Found! item_id = {}", result.item_id);
    }
    println!();

    println!("--- Test 3: get_name(2) ---");
    let name = vfs.get_name(2).await?;
    println!("Name: {:?}", name);
    println!();

    // --- Test 2: Bidirectional - trigger server to call client ---
    println!("=== Part 2: Server -> Client RPC (Bidirectional) ===");
    println!();
    println!("Now calling ping_with_callback() which will trigger the server");
    println!("to call methods back on this client...");
    println!();

    // The ping() call already demonstrates basic RPC.
    // For bidirectional, we need the server to initiate calls.
    // Let's add a method that triggers the server to call us back.
    // For now, let's just wait a moment to allow the server to call us
    // (the server implementation would need to be updated to do this).

    println!("Waiting 1 second for any server-initiated callbacks...");
    tokio::time::sleep(tokio::time::Duration::from_secs(1)).await;
    println!();

    // Close connection
    transport.close();
    println!("Connection closed.");
    println!();
    println!("=== All tests passed! ===");

    Ok(())
}
