fn main() {
    swift_bridge_build::parse_bridges(vec!["src/lib.rs"])
        .write_all_concatenated("generated", env!("CARGO_PKG_NAME"));
}
