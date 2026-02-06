# fs-kitty Troubleshooting Playbook

This guide is for when FSKit or fs-kitty gets into a bad state, from mild mount failures to full system hangs.

## Scope

Use this for:

- `mount -t fskitty ...` hangs
- extension does not launch
- `sudo killall fskitd fskit_agent` hangs
- terminal/app UI hangs around file operations in home directory or mount points

If your machine is already hanging, skip straight to **Emergency Recovery**.

## Emergency Recovery (System Unresponsive)

If commands hang and apps stop opening:

1. Stop running new FSKit commands.
2. Reboot immediately.
3. If `sudo reboot` hangs, use UI restart.
4. If UI restart hangs, do a hard power cycle.

After reboot:

1. Verify shell/app responsiveness first.
2. Do not run destructive cleanup yet.
3. Run only read-only checks:
   - `pluginkit -m -v -p com.apple.fskit.fsmodule`
   - `ps aux | rg -i 'fskit|FsKittyExt'`

Then proceed to **Post-Reboot Baseline Validation**.

## Post-Reboot Baseline Validation

Goal: prove fs-kitty baseline works before testing dependent repos (like vixen).

1. In `~/bearcove/fs-kitty`, build/install as documented:
   - `just build-xcode`
   - copy to `/Applications/FsKitty.app`
2. Enable extension in System Settings if needed.
3. Start sample server:
   - `just server`
4. Mount sample fs using documented flow.
5. Confirm:
   - mount succeeds quickly
   - `FsKittyExt` process appears
   - simple file ops work

Only after this baseline passes should you test integrations.

## Fast Triage Matrix

### Symptom: extension registered, but mount hangs

Checks:

- `pluginkit -m -v -p com.apple.fskit.fsmodule`
- `just logs` in a separate terminal

Actions (in order):

1. Re-enable extension in System Settings.
2. Restart FSKit daemons:
   - `sudo killall fskitd fskit_agent`
3. Retry mount with a fresh mount point.
4. If killall itself hangs, reboot and return to baseline validation.

### Symptom: no `FsKittyExt` process ever appears

Checks:

- signing/entitlements
- Release build (not Debug)

Actions:

1. Clean and rebuild Release.
2. Reinstall app in `/Applications`.
3. Re-enable extension.

### Symptom: machine-wide hangs (terminal/app open hangs)

Action:

- Treat as OS-level failure, reboot immediately.
- Avoid repeated force-kill loops before reboot.

## Logging Checklist

Capture these when reporting issues:

1. Exact mount command
2. Timestamp
3. `just logs` output around failure
4. `pluginkit -m -v -p com.apple.fskit.fsmodule`
5. Whether `FsKittyExt` process appeared
6. Whether `killall fskitd fskit_agent` completed or hung

## Integration Note (vixen / others)

If fs-kitty baseline fails, integration failures are expected and not actionable yet.

Always establish fs-kitty baseline first, then debug integration.
