# Datadog SDK Update Guide

This guide explains how to update the Datadog SDK versions used in this repository.

## Automated Update Script

The repository includes an automated script to update SDK versions: `update-sdk-versions.sh`

### Usage

**Update to the latest stable release (recommended):**

```bash
./update-sdk-versions.sh
```

This will:
1. Fetch the latest stable release tags from `dd-sdk-android` and `dd-sdk-ios`
2. Update the git submodules to those versions
3. Update all version references in `.csproj` files
4. Update documentation (`README.md`, `GETTING_STARTED.md`)

**Update to specific versions:**

```bash
./update-sdk-versions.sh --android-version 3.4.0 --ios-version 3.4.0
```

**Get help:**

```bash
./update-sdk-versions.sh --help
```

### What Gets Updated

The script updates:

#### Android Packages
- All 10 Android binding `.csproj` files in `src/Android/Bindings/`
  - `<Version>` tag
  - `PackageReference` versions to other Android packages
  - `artifact_versioned` in `PackageTags`
- Test project: `src/Android/Bindings/Test/TestBindings/TestBindings.csproj`

#### iOS Packages
- All 10 iOS binding `.csproj` files in `src/iOS/Bindings/`
  - `<Version>` tag
  - `PackageReference` versions to other iOS packages

#### Documentation
- `README.md` - Package version examples
- `GETTING_STARTED.md` - Installation instructions

### After Running the Script

1. **Review the changes:**
   ```bash
   git diff
   ```

2. **Test the build locally:**
   ```bash
   # For Android
   ./build-local-android-packages.sh

   # For iOS
   ./build-local-ios-packages.sh
   ```

3. **Commit the changes:**
   ```bash
   git add -A
   git commit -m "Update to SDK versions Android X.Y.Z, iOS X.Y.Z"
   ```

4. **Create a pull request** or push directly to main

## Automated Update Checking (GitHub Actions)

The repository includes a GitHub Actions workflow that automatically checks for new SDK releases.

### Workflow: `check-sdk-updates.yml`

**Schedule:** Runs every Monday at 9 AM UTC

**Manual trigger:** You can also run it manually from the Actions tab

**What it does:**
1. Checks for new releases in `dd-sdk-android` and `dd-sdk-ios`
2. Compares with current submodule versions
3. If updates are available, creates/updates a GitHub issue with:
   - Current versions
   - Latest versions
   - Links to release notes
   - Update instructions

### GitHub Issue

When updates are available, an issue titled **"New Datadog SDK versions available"** is created with:
- Labels: `sdk-update`, `enhancement`
- Current vs. latest versions
- Direct links to release notes
- Copy-paste command to update

The issue is automatically updated if already exists.

## Manual Update Process

If you prefer to update manually:

### 1. Update Git Submodules

```bash
# Fetch latest tags
cd dd-sdk-android
git fetch --tags
git tag --sort=-v:refname | grep -E "^[0-9]+\.[0-9]+\.[0-9]+$" | head -5
cd ..

cd dd-sdk-ios
git fetch --tags
git tag --sort=-v:refname | grep -E "^[0-9]+\.[0-9]+\.[0-9]+$" | head -5
cd ..

# Checkout specific version
cd dd-sdk-android
git checkout 3.4.0
cd ..

cd dd-sdk-ios
git checkout 3.4.0
cd ..
```

### 2. Update Android .csproj Files

Update the following in all Android binding projects:

```xml
<!-- Update Version tag -->
<Version>3.4.0</Version>

<!-- Update PackageReference versions -->
<PackageReference Include="Bcr.Datadog.Android.Sdk.Core" Version="3.4.0" />

<!-- Update artifact_versioned in PackageTags -->
artifact_versioned=com.datadog.android:dd-sdk-android-core:3.4.0
```

**Files to update:**
- `src/Android/Bindings/Core/Core.csproj`
- `src/Android/Bindings/DatadogLogs/DatadogLogs.csproj`
- `src/Android/Bindings/Internal/Internal.csproj`
- `src/Android/Bindings/Ndk/Ndk.csproj`
- `src/Android/Bindings/Rum/Rum.csproj`
- `src/Android/Bindings/SessionReplay/SessionReplay.csproj`
- `src/Android/Bindings/SessionReplay.Material/SessionReplay.Material.csproj`
- `src/Android/Bindings/Trace/Trace.csproj`
- `src/Android/Bindings/Trace.Otel/Trace.Otel.csproj`
- `src/Android/Bindings/WebView/WebView.csproj`
- `src/Android/Bindings/Test/TestBindings/TestBindings.csproj`

### 3. Update iOS .csproj Files

Update the following in all iOS binding projects:

```xml
<!-- Update Version tag -->
<Version>3.4.0</Version>

<!-- Update PackageReference versions -->
<PackageReference Include="Bcr.Datadog.iOS.Core" Version="3.4.0" />
```

**Files to update:**
- `src/iOS/Bindings/Core/Core.csproj`
- `src/iOS/Bindings/CrashReporting/CrashReporting.csproj`
- `src/iOS/Bindings/DDLogs/DDLogs.csproj`
- `src/iOS/Bindings/Internal/Internal.csproj`
- `src/iOS/Bindings/ObjC/ObjC.csproj`
- `src/iOS/Bindings/OpenTelemetryApi/OpenTelemetryApi.csproj`
- `src/iOS/Bindings/Rum/Rum.csproj`
- `src/iOS/Bindings/SessionReplay/SessionReplay.csproj`
- `src/iOS/Bindings/Trace/Trace.csproj`
- `src/iOS/Bindings/WebViewTracking/WebViewTracking.csproj`

### 4. Update Documentation

Update version numbers in:
- `README.md` - Package examples
- `GETTING_STARTED.md` - Installation instructions

### 5. Rebuild Native Libraries

#### For iOS:
```bash
./src/iOS/buildxcframework.sh
```

This rebuilds the XCFrameworks from the updated submodule.

#### For Android:
Android AAR files are included in the submodule, so no rebuild is needed.

## Version Alignment

The Datadog Android and iOS SDKs typically stay in sync with version numbers. However, they can occasionally be at different versions. The update script handles this correctly by allowing different versions for each platform.

## Testing

After updating, thoroughly test:

1. **Local builds:**
   ```bash
   ./build-local-android-packages.sh
   ./build-local-ios-packages.sh
   ```

2. **CI/CD workflows:** Push and verify all workflows pass

3. **Integration test:** Test in a sample MAUI app to ensure compatibility

## Release Process

After updating SDKs:

1. Test builds locally
2. Run CI/CD
3. Update `CHANGELOG.md` with SDK version changes
4. Create a release using the prepare-release workflow
5. Publish to NuGet.org

## Troubleshooting

### Issue: Script can't find git tags

```bash
cd dd-sdk-android
git fetch --tags
cd ../dd-sdk-ios
git fetch --tags
cd ..
```

### Issue: Submodule is in detached HEAD state

This is expected. The submodules are pinned to specific tag versions.

### Issue: Build fails after update

Check the release notes for breaking changes:
- [Android Release Notes](https://github.com/DataDog/dd-sdk-android/releases)
- [iOS Release Notes](https://github.com/DataDog/dd-sdk-ios/releases)

You may need to update bindings or metadata.

## Links

- [Datadog Android SDK Releases](https://github.com/DataDog/dd-sdk-android/releases)
- [Datadog iOS SDK Releases](https://github.com/DataDog/dd-sdk-ios/releases)
- [Building & Versioning Guide](BUILDING_AND_VERSIONING.md)
