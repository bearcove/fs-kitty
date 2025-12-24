// Phase 1: Basic linking test
// Phase 2: swift-bridge sync
// Phase 3: swift-bridge async

#[swift_bridge::bridge]
mod ffi {
    // Phase 2: struct passing
    #[swift_bridge(swift_repr = "struct")]
    struct Point {
        x: f64,
        y: f64,
    }

    extern "Rust" {
        // Phase 1: simplest possible function
        fn add(a: i32, b: i32) -> i32;

        // Phase 2: struct passing
        fn distance(a: Point, b: Point) -> f64;
    }
}

fn add(a: i32, b: i32) -> i32 {
    a + b
}

fn distance(a: ffi::Point, b: ffi::Point) -> f64 {
    let dx = b.x - a.x;
    let dy = b.y - a.y;
    (dx * dx + dy * dy).sqrt()
}
