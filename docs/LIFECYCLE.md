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
2. FSKit should begin teardown of the mounted volume.
3. `volume.unmount.begin`
4. `volume.unmount.done`
5. `volume.deactivate.begin`
6. `volume.deactivate.done`
7. `bridge.unloadResource.begin`
8. `vfs.disconnect`
9. `bridge.unloadResource.done`

Notes:

- We intentionally do **not** `exit(0)` on peer disconnect anymore.
- The extension now waits for FSKit to drive unload/deactivate callbacks.

## Scenario 2: Mount Point Unmounted Directly

Trigger:

- User runs `umount <mountpoint>` (or Finder/system unmount action).

Expected flow:

1. `volume.unmount.begin`
2. `volume.unmount.done`
3. `volume.deactivate.begin`
4. `volume.deactivate.done`
5. `bridge.unloadResource.begin`
6. `vfs.disconnect`
7. `bridge.unloadResource.done`

## Container State Expectations

Current transitions:

- `bridge.loadResource.success` sets container state to `ready`
- `volume.mount.done` sets container state to `active`
- `volume.unmount.done` sets container state to `ready`
- `volume.deactivate.done` sets container state to `ready`
- `bridge.unloadResource.done` sets container state to `notReady`

## Debug Checklist

When teardown is suspicious:

1. Capture lifecycle logs around the failure window.
2. Confirm whether `volume.unmount.*` appears before `bridge.unloadResource.*`.
3. Confirm whether disconnect is `vfs.driver.exit.unexpected` or `vfs.disconnect`.
4. If order differs, save the full ordered sequence and timestamp it for follow-up.
