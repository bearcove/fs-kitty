# fs-kitty Lifecycle Sequences

This document describes the teardown and callback order we expect from FSKit, and the callback order we now log explicitly.

## Lifecycle Logging

`FsKittyExt` now logs ordered lifecycle markers as:

- `lifecycle[N] bridge.*`
- `lifecycle[N] volume.*`
- `lifecycle[N] vfs.*`

Use `just logs` and filter for `lifecycle[` to see callback order.

## Scenario 1: RPC Peer Dies (common)

Trigger:

- Rust VFS server exits or connection drops unexpectedly.

Expected flow:

1. `vfs.driver.exit.unexpected`
2. FSKit may continue issuing operations (for example `attributes`) against the mounted volume.
3. Teardown callbacks (`volume.unmount.*`, `volume.deactivate.*`, `bridge.unloadResource.*`) are not guaranteed to appear immediately in this path.

Notes:

- We intentionally do **not** `exit(0)` on peer disconnect.
- Current behavior is primarily for observation while we diagnose FSKit teardown behavior after backend loss.

## Scenario 2: Mount Point Unmounted Directly

Trigger:

- User runs `umount <mountpoint>` (or Finder/system unmount action).

Observed variants:

1. `volume.unmount.begin/done` followed by `volume.deactivate.begin/done`
2. `volume.deactivate.begin/done` without `volume.unmount.*` (seen in force-unmount paths)
3. Extension process termination by FSKit may occur before `bridge.unloadResource.*` appears

## Debug Checklist

When teardown is suspicious:

1. Capture lifecycle logs around the failure window.
2. Confirm which teardown variant occurred (`unmount+deactivate` vs `deactivate-only`).
3. Confirm whether disconnect is `vfs.driver.exit.unexpected` or `vfs.disconnect`.
4. Save the full ordered sequence with timestamps for comparison across runs.
