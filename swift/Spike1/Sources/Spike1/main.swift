// Spike1: Prove Swift can link and call a Rust static library via swift-bridge
import Foundation
import BridgeHeaders

print("Spike1: Testing Swift -> Rust integration via swift-bridge")
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

// Phase 2: Struct passing
print("\n--- Phase 2: Struct passing ---")
let p1 = Point(x: 0.0, y: 0.0)
let p2 = Point(x: 3.0, y: 4.0)
let dist = distance(p1, p2)

print("Point p1 = (\(p1.x), \(p1.y))")
print("Point p2 = (\(p2.x), \(p2.y))")
print("Calling Rust: distance(p1, p2) = \(dist)")

// 3-4-5 triangle -> distance should be 5.0
if abs(dist - 5.0) < 0.0001 {
    print("SUCCESS: Phase 2 complete - Struct passing works!")
} else {
    print("FAILURE: Expected 5.0, got \(dist)")
    exit(1)
}

print("\n==========================================================")
print("All phases complete! Swift <-> Rust integration working.")
