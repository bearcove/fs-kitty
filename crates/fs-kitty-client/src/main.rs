//! Spike: roam VFS client using fs-kitty-proto
//!
//! This tests the VFS server by performing various filesystem operations.

use fs_kitty_proto::{ItemType, VfsClient, errno};
use roam_stream::{Connector, HandshakeConfig, NoDispatcher, connect};
use tokio::net::TcpStream;

struct TcpConnector {
    addr: String,
}

impl Connector for TcpConnector {
    type Transport = TcpStream;

    async fn connect(&self) -> std::io::Result<TcpStream> {
        TcpStream::connect(&self.addr).await
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
    println!("=== fs-kitty VFS Client ===");
    println!("Connecting to {}...", addr);

    let connector = TcpConnector {
        addr: addr.to_string(),
    };
    let client = connect(connector, HandshakeConfig::default(), NoDispatcher);
    let vfs = VfsClient::new(client);

    println!("Connected!\n");

    // --- Test 1: Ping ---
    println!("--- Test 1: ping() ---");
    let response = vfs.ping().await?;
    println!("Response: {:?}\n", response);

    // --- Test 2: Lookup root ---
    println!("--- Test 2: get_attributes(1) (root) ---");
    let result = vfs.get_attributes(1).await?;
    assert_eq!(result.error, errno::OK);
    println!(
        "Root: type={:?}, size={}\n",
        result.attrs.item_type, result.attrs.size
    );

    // --- Test 3: Read root directory ---
    println!("--- Test 3: read_dir(1) (root) ---");
    let result = vfs.read_dir(1, 0).await?;
    assert_eq!(result.error, errno::OK);
    println!("Root directory contents:");
    for entry in &result.entries {
        println!(
            "  {} (id={}, type={:?})",
            entry.name, entry.item_id, entry.item_type
        );
    }
    println!();

    // --- Test 4: Lookup hello.txt ---
    println!("--- Test 4: lookup(1, \"hello.txt\") ---");
    let result = vfs.lookup(1, "hello.txt".to_string()).await?;
    assert_eq!(result.error, errno::OK);
    let hello_id = result.item_id;
    println!("Found hello.txt with id={}\n", hello_id);

    // --- Test 5: Read hello.txt ---
    println!("--- Test 5: read({}, 0, 1024) ---", hello_id);
    let result = vfs.read(hello_id, 0, 1024).await?;
    assert_eq!(result.error, errno::OK);
    let content = String::from_utf8_lossy(&result.data);
    println!("Content: {:?}\n", content);

    // --- Test 6: Navigate to nested file ---
    println!("--- Test 6: lookup(1, \"documents\") ---");
    let result = vfs.lookup(1, "documents".to_string()).await?;
    assert_eq!(result.error, errno::OK);
    let docs_id = result.item_id;
    println!("Found documents/ with id={}", docs_id);

    println!("--- lookup({}, \"readme.md\") ---", docs_id);
    let result = vfs.lookup(docs_id, "readme.md".to_string()).await?;
    assert_eq!(result.error, errno::OK);
    let readme_id = result.item_id;
    println!("Found readme.md with id={}\n", readme_id);

    // --- Test 7: Read nested file ---
    println!("--- Test 7: read({}, 0, 1024) ---", readme_id);
    let result = vfs.read(readme_id, 0, 1024).await?;
    assert_eq!(result.error, errno::OK);
    let content = String::from_utf8_lossy(&result.data);
    println!("Content: {:?}\n", content);

    // --- Test 8: Create a new file ---
    println!("--- Test 8: create(1, \"newfile.txt\", File) ---");
    let result = vfs
        .create(1, "newfile.txt".to_string(), ItemType::File)
        .await?;
    assert_eq!(result.error, errno::OK);
    let new_id = result.item_id;
    println!("Created newfile.txt with id={}\n", new_id);

    // --- Test 9: Write to new file ---
    println!("--- Test 9: write({}, 0, \"Test content\") ---", new_id);
    let result = vfs
        .write(new_id, 0, b"Test content from client!".to_vec())
        .await?;
    assert_eq!(result.error, errno::OK);
    println!("Wrote {} bytes\n", result.bytes_written);

    // --- Test 10: Read back ---
    println!("--- Test 10: read({}, 0, 1024) ---", new_id);
    let result = vfs.read(new_id, 0, 1024).await?;
    assert_eq!(result.error, errno::OK);
    let content = String::from_utf8_lossy(&result.data);
    println!("Content: {:?}\n", content);

    // --- Test 11: Lookup non-existent ---
    println!("--- Test 11: lookup(1, \"nonexistent\") ---");
    let result = vfs.lookup(1, "nonexistent".to_string()).await?;
    assert_eq!(result.error, errno::ENOENT);
    println!("Got expected ENOENT error\n");

    // --- Test 12: Delete the file we created ---
    println!("--- Test 12: delete({}) ---", new_id);
    let result = vfs.delete(new_id).await?;
    assert_eq!(result.error, errno::OK);
    println!("Deleted newfile.txt\n");

    // Verify deletion
    println!("--- Verify deletion: read_dir(1) ---");
    let result = vfs.read_dir(1, 0).await?;
    println!("Root directory now contains:");
    for entry in &result.entries {
        println!("  {} (id={})", entry.name, entry.item_id);
    }
    println!();

    println!("\n=== All tests passed! ===");

    Ok(())
}
