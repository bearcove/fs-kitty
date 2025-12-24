// Spike1: Prove Swift can link and call a Rust static library via swift-bridge
import Foundation
import BridgeHeaders

print("Spike1: Testing Swift -> Rust integration via swift-bridge")
print("----------------------------------------------------------")

// Phase 1: Simple function call
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
