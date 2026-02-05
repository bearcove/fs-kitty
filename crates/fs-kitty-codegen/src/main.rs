use std::path::PathBuf;

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let workspace_root = PathBuf::from(env!("CARGO_MANIFEST_DIR"))
        .parent()
        .and_then(|p| p.parent())
        .ok_or("failed to locate workspace root")?
        .to_path_buf();

    let service = fs_kitty_proto::vfs_service_detail();
    let swift = roam_codegen::targets::swift::generate_service(&service);

    let outputs = [
        workspace_root.join("swift/FsKitty/Sources/FsKitty/VfsClient.swift"),
        workspace_root.join("xcode/FsKittyExt/VfsClient.swift"),
    ];

    for output in outputs {
        if let Some(parent) = output.parent() {
            std::fs::create_dir_all(parent)?;
        }
        std::fs::write(&output, &swift)?;
        println!("Wrote {}", output.display());
    }

    Ok(())
}
