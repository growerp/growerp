

Linux executable can be created with:

flutter build linux --release

it is required to load the required libraries to create and als to run the application:

sudo apt-get install libgtk-3-0 libblkid1 liblzma5

after creation put the whole bundle directory in a zip:

build/linux/x64/release


Use the snap store to distribute with build-snap.sh

# GrowERP Admin Snap Package

This directory contains the configuration for building a Snap package of the GrowERP Admin application.

## Prerequisites

1. **Snapcraft**: Install snapcraft if you haven't already:
   ```bash
   sudo snap install snapcraft --classic
   ```

2. **Flutter Build**: Ensure you have built the Linux version of the app:
   ```bash
   flutter build linux --release
   ```

## Building the Snap

### Option 1: Using the build script (Recommended)
```bash
./build-snap.sh
```

### Option 2: Manual build
```bash
# Clean previous builds
rm -rf parts prime stage *.snap

# Build the snap
snapcraft pack --destructive-mode
```

## Installing the Snap

### Local Installation (Recommended - Latest Version)
After building, install the snap locally:
```bash
sudo snap install --dangerous growerp-admin_*.snap
```

### Snap Store Installation (May have OpenGL issues)
You can also install from the Snap Store:
```bash
sudo snap install growerp-admin
```

**Note**: The current Snap Store version may have OpenGL/Mesa driver issues causing segmentation faults. If you encounter libGL errors, please use the local build which includes the necessary Mesa drivers.

## Running the Application

```bash
growerp-admin.growerp-admin
```

The application will also appear in your desktop environment's application menu.

## Features

This snap package includes:
- Complete GTK3 and desktop integration
- Audio support (PulseAudio/ALSA)
- Network access for ERP functionality
- File system access (home and removable media)
- Proper icon and MIME type integration
- Wayland and X11 support

## Snap Store Publishing

To publish to the Snap Store:

1. **Register the name** (one time):
   ```bash
   snapcraft register growerp-admin
   ```

2. **Login to Snap Store**:
   ```bash
   snapcraft login
   ```

3. **Upload and release**:
   ```bash
   snapcraft upload growerp-admin_*.snap --release=stable
   ```

## Troubleshooting

### Common Issues

1. **OpenGL/Mesa Driver Errors**: If you see libGL errors like "failed to open iris" or "failed to load driver", this indicates missing Mesa drivers:
   ```
   libGL error: MESA-LOADER: failed to open iris: /usr/lib/dri/iris_dri.so: cannot open shared object file
   ```
   **Solution**: Use the locally built snap package which includes all necessary Mesa drivers, or wait for the Snap Store version to be updated.

2. **Permission denied errors**: Ensure you're using `--destructive-mode` flag or run snapcraft in a LXD container.

3. **Missing libraries**: The snapcraft.yaml includes comprehensive library dependencies. If you encounter missing library errors, check the stage-packages section.

4. **Desktop integration**: If the app doesn't appear in the application menu, check that the desktop file is correctly generated.

### Debug Commands

```bash
# Check snap connections
snap connections growerp-admin

# Run with debug output
SNAPD_DEBUG=1 growerp-admin.growerp-admin

# Check snap logs
snap logs growerp-admin

# Run in shell mode for debugging
snap run --shell growerp-admin.growerp-admin
```

## File Structure

- `snapcraft.yaml` - Main snap configuration
- `build-snap.sh` - Build script
- `build/linux/x64/release/bundle/` - Flutter Linux build output (source)

## Configuration Details

The snap is configured with:
- **Base**: core22 (Ubuntu 22.04 LTS)
- **Confinement**: strict (secure)
- **Grade**: stable (production ready)
- **Architectures**: amd64

The application has access to:
- Network (for ERP server communication)
- Desktop integration (GTK, icons, etc.)
- Audio playback
- Home directory and removable media
- Settings (gsettings)

## Version Management

The version in `snapcraft.yaml` should be kept in sync with the version in `pubspec.yaml`. Currently set to version `1.9.13`.

