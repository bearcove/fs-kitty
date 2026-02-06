# fs-kitty Development Guide

For system-hang and recovery procedures, see:
- [`docs/TROUBLESHOOTING.md`](docs/TROUBLESHOOTING.md)

## Building

The extension requires Release configuration because Debug builds use a stub executable structure that ExtensionKit cannot launch:

```bash
# Build everything (Rust + Xcode)
just build-xcode

# Install to /Applications (required for proper registration)
rm -rf /Applications/FsKitty.app
cp -R build/Release/FsKitty.app /Applications/
open /Applications/FsKitty.app
```

## Testing

**Mount points go under `~/.fs-kitty/`**, never directly in `~/`. If the extension hangs with a mount in `~/`, shells can't open (they stat `~` on startup and block on the dead mount).

```bash
# Start the VFS server
just server

# Mount the filesystem
mkdir -p ~/.fs-kitty/mnt
mount -t fskitty fskitty://localhost:10001 ~/.fs-kitty/mnt

# Watch logs in another terminal
just logs
```

## Troubleshooting: Extension Won't Launch

When you run `mount -t fskitty fskitty://host:port /mount/point` and it **hangs** with no extension process spawning, try these fixes in order of increasing violence:

### 1. Verify Extension Registration (Gentlest)

Check if the extension is registered with the system:

```bash
pluginkit -m -v -p com.apple.fskit.fsmodule
```

Should show `me.amos.fs-kitty.ext` in the list. If missing, rebuild and reinstall.

### 2. Check System Settings

The extension can get disabled after failed launches:

1. Open **System Settings** → **Privacy & Security**
2. Scroll down to **File System Extensions**
3. Find **FsKittyExt** and ensure it's **enabled**
4. If it shows as "disabled", toggle it back on

Or via command line:
```bash
# Check status
pluginkit -e use -i me.amos.fs-kitty.ext

# If disabled, enable it
pluginkit -e use -i me.amos.fs-kitty.ext -p com.apple.fskit.fsmodule
```

### 3. Restart FSKit Daemons ⭐ **MOST RELIABLE FIX**

FSKit daemons (`fskitd` and `fskit_agent`) can get stuck with stale state. Killing them clears the state and they auto-restart:

```bash
sudo killall fskitd fskit_agent
# They will auto-restart automatically
```

Then try mounting again. **Once this works, unmount/remount cycles work reliably without needing to kill daemons again.**

This is the most reliable workaround - start your development session by killing the daemons once, then everything works smoothly.

### 4. Use a Fresh Mount Point

Stale mount points can hold bad state:

```bash
umount ~/.fs-kitty/mnt || true
mkdir -p ~/.fs-kitty/mnt2
mount -t fskitty fskitty://localhost:10001 ~/.fs-kitty/mnt2
```

### 5. Clean Build

Stale Debug builds can cause issues:

```bash
# Clean everything
just clean

# Rebuild Release
just build-xcode

# Reinstall
rm -rf /Applications/FsKitty.app
cp -R build/Release/FsKitty.app /Applications/
open /Applications/FsKitty.app

# Re-enable in System Settings if needed
```

### 6. Clear Network Extension Cache (Nuclear)

A stale network policy cache can prevent the extension from launching. **WARNING: This will delete all VPN/network extension configurations!**

```bash
# Backup first
sudo cp /Library/Preferences/com.apple.networkextension.plist ~/netex.backup.plist

# Delete the cache
sudo defaults delete /Library/Preferences/com.apple.networkextension

# Kill network daemons
sudo killall nesessionmanager networkextensiond nehelper

# They will auto-restart with fresh cache
```

You'll need to reconfigure any VPNs after this. To restore:
```bash
sudo cp ~/netex.backup.plist /Library/Preferences/com.apple.networkextension.plist
sudo killall nesessionmanager
```

### 7. Reboot (Most Violent)

When all else fails:
```bash
sudo reboot
```

After reboot, rebuild and reinstall everything from scratch.

## Common Issues

### Extension Registered But Won't Spawn

**Symptom**: `pluginkit` lists the extension, logs show "Found extension for fsShortName" and "applyResource starting", but no FsKittyExt process appears.

**Cause**: Usually FSKit daemon state or network policy cache.

**Fix**: Try solutions #3 (restart daemons) or #6 (clear network cache).

### "Resource busy" During Unmount

**Symptom**: `umount` fails with "Resource busy"

**Cause**: Hanging mount process holding the mountpoint.

**Fix**:
```bash
# Kill hanging mount processes
killall mount

# Force unmount
diskutil unmount force ~/.fs-kitty/mnt
```

### Wrong Build Configuration

**Symptom**: Build succeeds but extension immediately fails with ExtensionKit errors.

**Cause**: Debug build creates stub executable that ExtensionKit can't launch.

**Fix**: Always use Release builds. The Justfile defaults to Release, but verify:
```bash
# Should output "Release"
grep -A3 "^build-xcode:" Justfile | grep configuration
```

### Facet "Shape not compatible" Errors

**Symptom**: Extension launches but VFS operations fail with JIT shape mismatches.

**Cause**: Mismatched facet/roam versions between server and client.

**Fix**:
```bash
# Update all dependencies
cargo update

# Rebuild everything
just clean
just build
```

## Debugging Tips

### Watch All Logs

```bash
just logs
```

This shows:
- FSKit system logs (`com.apple.FSKit`)
- Extension logs (`me.amos.fs-kitty.ext`)
- Any messages containing "fskitty" or "FsKittyExt"

Look for emoji markers in extension logs:
- 🚀 Extension initialization
- 🌉 Bridge setup
- 📋 probeResource
- 📦 loadResource
- 🔗 VFS connection

### Check Extension Process

```bash
# Should show FsKittyExt process(es) when mounted
ps aux | grep FsKittyExt | grep -v grep
```

### Check Console.app

Console.app sometimes shows errors that `log show` misses:
1. Open Console.app
2. Select your Mac in sidebar
3. Search for "FsKittyExt" or "extensionkit"
4. Look around the timestamp when mount hangs

## Architecture Notes

### ExtensionKit vs App Extensions

FSKit modules MUST use ExtensionKit (`extensionkit-extension` product type), not legacy app extensions (`app-extension`). This is configured in `xcode/project.yml`:

```yaml
FsKittyExt:
  type: extensionkit-extension  # NOT app-extension!
```

### Required Entitlements

Minimal required set (in `xcode/FsKittyExt/FsKittyExt.entitlements`):

```xml
<key>com.apple.security.app-sandbox</key>
<true/>
<key>com.apple.security.network.client</key>
<true/>
<key>com.apple.developer.fskit.fsmodule</key>
<true/>
```

Extra entitlements can cause ExtensionKit to reject the extension at launch time.

### Network Policy Cache

The system caches network policies per bundle ID. If you change bundle IDs during development, the old ID's policies can block the new extension from launching. This is why clearing `/Library/Preferences/com.apple.networkextension.plist` sometimes fixes mysterious launch failures.

### Debug vs Release Builds

- **Debug**: Creates stub executable (~59KB) + separate `.debug.dylib` (~10MB). ExtensionKit cannot launch this structure.
- **Release**: Single monolithic executable (~10MB). Works correctly with ExtensionKit.

Always use Release builds for FSKit development.
