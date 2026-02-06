# fs-kitty (Archived)

This repository has been retired.

## What happened

`fs-kitty` was folded into the Vixen monorepo and now lives there as the macOS app/extension stack used by Vixen.

- New home: https://github.com/bearcove/vixen
- Migration context: https://github.com/bearcove/vixen/issues/56

## Where the code is now

In `bearcove/vixen`:

- macOS app + FSKit extension + mount helper:
  - `apps/mac/xcode`
- Swift support code:
  - `apps/mac/swift`
- Shared VFS protocol crate (vendored from this repo):
  - `crates/fs-kitty-proto`
- Rust runtime integration:
  - `crates/vx-vfs`
  - `crates/vx-rhea`

## Why this repo still exists

This repository remains as a pointer for existing links, stars, and references.

If you are looking for active development, issues, or pull requests, please use:

- https://github.com/bearcove/vixen

