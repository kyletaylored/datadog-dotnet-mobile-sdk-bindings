# Android NDK Setup for Building AARs

## Overview

Building the Android AAR files from the `dd-sdk-android` SDK source requires the Android NDK (Native Development Kit) to be installed. The `build-aars.sh` script automatically detects and uses the installed NDK version.

## NDK Version Handling

The Datadog Android SDK (`dd-sdk-android`) may specify a particular NDK version in its build configuration. However, you don't need to have that exact version installed - the build script will automatically use whichever valid NDK version you have installed.

The `build-aars.sh` script:
1. Detects your installed NDK version
2. Temporarily overrides the SDK's NDK version requirement
3. Builds the AAR files
4. Cleans up the override (restores original `gradle.properties`)

## Installing the Android NDK

### Option 1: Via Android Studio (Recommended)

1. Open Android Studio
2. Go to **Tools** → **SDK Manager**
3. Click **SDK Tools** tab
4. Check **NDK (Side by side)**
5. Click **Apply** to install

### Option 2: Via Command Line

If you have Android SDK command-line tools installed:

```bash
# List available NDK versions
sdkmanager --list | grep ndk

# Install latest NDK
sdkmanager "ndk;27.1.12297006"

# Or install a specific version
sdkmanager "ndk;28.0.13004108"
```

### Option 3: Manual Download

Download from: https://developer.android.com/ndk/downloads

Extract to: `~/Library/Android/sdk/ndk/<version>/` (macOS)

## Verifying NDK Installation

```bash
# Check if NDK is installed
ls ~/Library/Android/sdk/ndk/

# Verify a valid installation (should have source.properties file)
ls ~/Library/Android/sdk/ndk/*/source.properties
```

## Troubleshooting

### Error: "NDK did not have a source.properties file"

This means the NDK directory exists but the installation is incomplete.

**Solution:**
```bash
# Remove the incomplete installation
rm -rf ~/Library/Android/sdk/ndk/28.0.13004108

# Reinstall via Android Studio or sdkmanager
```

### Error: "No valid NDK installation found"

The build script couldn't find any NDK installation.

**Solution:**
1. Install NDK via Android Studio (see above)
2. Or set `ANDROID_SDK_ROOT` environment variable:
   ```bash
   export ANDROID_SDK_ROOT="/path/to/android/sdk"
   ```

### Error: "NDK version disagrees with android.ndkVersion"

This error should not occur with the updated `build-aars.sh` script, as it automatically handles version mismatches. If you see this error:

1. Make sure you're using the latest `build-aars.sh` script
2. Check that `dd-sdk-android/gradle.properties` doesn't have manual NDK overrides
3. Try running: `cd dd-sdk-android && git checkout gradle.properties`

## Build Script Behavior

The `build-aars.sh` script modifies `dd-sdk-android/gradle.properties` temporarily during the build:

1. **Before build:** Adds `android.ndkVersion=<your-installed-version>`
2. **During build:** Gradle uses your installed NDK version
3. **After build:** Restores original `gradle.properties`

This approach ensures:
- ✅ No permanent modifications to the submodule
- ✅ Works with any installed NDK version
- ✅ Automatic cleanup even if build fails

## Notes

- The NDK version specified in `dd-sdk-android` build files is a recommendation, not a strict requirement
- Using a different NDK version (e.g., 27.x instead of 28.x) generally works fine for building AARs
- The `dd-sdk-android` submodule should never have local modifications committed

## Related Files

- `src/Android/build-aars.sh` - Main AAR build script with NDK detection
- `src/Android/copy-aars.sh` - Copies built AARs to binding projects
- `dd-sdk-android/gradle.properties` - Temporary NDK override location (auto-managed)
- `dd-sdk-android/local.properties` - Local SDK paths (git-ignored)

## Links

- [Android NDK Downloads](https://developer.android.com/ndk/downloads)
- [Android SDK Manager](https://developer.android.com/studio/intro/update#sdk-manager)
- [Datadog Android SDK](https://github.com/DataDog/dd-sdk-android)
