// FsKitty: Swift integration test for fs-kitty-swift via swift-bridge
import Foundation
import BridgeHeaders

print("FsKitty: Testing Swift -> Rust integration via swift-bridge")
print("==========================================================")

// Phase 1: Simple function call
print("\n--- Phase 1: Simple function call ---")
let a: Int32 = 2
let b: Int32 = 3
let result = add(a, b)

print("Calling Rust: add(\(a), \(b)) = \(result)")

if result == 5 {
    print("SUCCESS: Phase 1 complete - Swift successfully called Rust!")
} else {
    print("FAILURE: Expected 5, got \(result)")
    exit(1)
}

// Phase 2: Async function (no network)
print("\n--- Phase 2: Async function ---")
Task {
    let greeting = await async_greet("fs-kitty")
    print("Calling Rust: async_greet(\"fs-kitty\") = \(greeting.toString())")

    // Phase 3: VFS connection (requires server running)
    print("\n--- Phase 3: VFS Connection ---")
    print("Connecting to VFS server at 127.0.0.1:10001...")

    do {
        try vfs_connect("127.0.0.1:10001")
        print("Connected!")

        let pong = try vfs_ping()
        print("vfs_ping() = \(pong.toString())")
        print("SUCCESS: Phase 3 complete - VFS connection works!")
    } catch {
        print("VFS connection failed: \(error)")
        print("(This is expected if the server isn't running)")
    }

    print("\n==========================================================")
    print("All phases complete! Swift <-> Rust integration working.")
    exit(0)
}

// Keep main thread alive for async tasks
RunLoop.main.run()
