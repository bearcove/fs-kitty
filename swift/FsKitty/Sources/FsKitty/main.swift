// FsKitty: Pure Swift VFS client using rapace-swift
import Foundation
import Rapace
import Postcard

func main() async {
    print("FsKitty: Pure Swift VFS client via rapace-swift")
    print("================================================\n")

    do {
        // Connect to VFS server
        print("Connecting to VFS server at 127.0.0.1:10001...")
        let client = try await VfsClient(host: "127.0.0.1", port: 10001)
        print("Connected!\n")

        // Ping
        print("--- ping ---")
        let pong = try await client.ping()
        print("Response: \"\(pong)\"\n")

        // Read root directory
        print("--- readDir (/) ---")
        let root = try await client.readDir(item_id: 1, cursor: 0)
        for entry in root.entries {
            let icon = entry.item_type == .directory ? "📁" : "📄"
            print("  \(icon) \(entry.name)")
        }
        print()

        // Lookup and read hello.txt
        print("--- read hello.txt ---")
        let lookup = try await client.lookup(parent_id: 1, name: "hello.txt")
        let content = try await client.read(item_id: lookup.item_id, offset: 0, len: 1024)
        if let text = String(data: Data(content.data), encoding: .utf8) {
            print("Content: \"\(text.trimmingCharacters(in: .newlines))\"")
        }
        print()

        // Create, write, read, delete a test file
        print("--- create/write/read/delete test ---")
        let created = try await client.create(parent_id: 1, name: "swift-test.txt", item_type: .file)
        print("Created file id=\(created.item_id)")

        let testData = Array("Hello from pure Swift!".utf8)
        let written = try await client.write(item_id: created.item_id, offset: 0, data: testData)
        print("Wrote \(written.bytes_written) bytes")

        let readBack = try await client.read(item_id: created.item_id, offset: 0, len: 1024)
        if let text = String(data: Data(readBack.data), encoding: .utf8) {
            print("Read back: \"\(text)\"")
        }

        let deleted = try await client.delete(created.item_id)
        print("Deleted (error=\(deleted.error))")
        print()

        print("================================================")
        print("All operations successful! Pure Swift VFS works.")

    } catch {
        print("ERROR: \(error)")
    }
}

// Run async main
Task {
    await main()
    exit(0)
}
RunLoop.main.run()
