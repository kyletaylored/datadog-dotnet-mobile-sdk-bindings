# Building and Versioning Guide

This document explains how to build the Datadog .NET Mobile SDK Bindings from source, update to new Datadog SDK versions, and understand the versioning strategy.

## Table of Contents

- [Build Scripts Overview](#build-scripts-overview)
- [Updating SDK Versions](#updating-sdk-versions)
- [Android Build Process](#android-build-process)
- [iOS Build Process](#ios-build-process)
- [Versioning Strategy](#versioning-strategy)
- [16KB Page Size Requirement](#16kb-page-size-requirement)
- [Publishing Checklist](#publishing-checklist)

---

## Build Scripts Overview

### Android Scripts

| Script | Purpose | When to Run |
|--------|---------|-------------|
| [build-aars.sh](src/Android/build-aars.sh) | Build native `.aar` files from `dd-sdk-android` submodule | After updating Android SDK submodule |
| [copy-aars.sh](src/Android/copy-aars.sh) | Copy built `.aar` files to binding project folders | After `build-aars.sh` completes |

### iOS Scripts

| Script | Purpose | When to Run |
|--------|---------|-------------|
| [buildxcframework.sh](src/iOS/buildxcframework.sh) | Build XCFrameworks from `dd-sdk-ios` submodule | After updating iOS SDK submodule |
| [buildobjectivesharpiebindings.sh](src/iOS/buildobjectivesharpiebindings.sh) | Generate C# binding definitions with Objective Sharpie | After XCFrameworks are built |
| [buildmdoc.sh](src/iOS/Bindings/buildmdoc.sh) | Generate XML documentation from assemblies | After building bindings |

---

## Updating SDK Versions

This section explains how to update the Datadog SDK versions used in this repository.

### Automated Update Script

The repository includes an automated script to update SDK versions: `update-sdk-versions.sh`

#### List Available Versions

```bash
# Via Makefile (recommended)
make list-versions

# Or directly via script
./update-sdk-versions.sh --list-versions
```

#### Update to Latest Release (Recommended)

```bash
# Via Makefile (recommended)
make update-sdks

# Or directly via script
./update-sdk-versions.sh
```

This will:
1. Fetch the latest stable release tags from `dd-sdk-android` and `dd-sdk-ios`
2. Update the git submodules to those versions
3. Update all version references in `.csproj` files
4. Update documentation (`README.md`, `GETTING_STARTED.md`)

#### Update to Specific Versions

```bash
# Update both to specific versions
./update-sdk-versions.sh --android-version 3.2.0 --ios-version 3.2.0

# Update only Android (iOS will use latest)
./update-sdk-versions.sh --android-version 2.26.0

# Update only iOS (Android will use latest)
./update-sdk-versions.sh --ios-version 2.30.0
```

#### Get Help

```bash
./update-sdk-versions.sh --help
```

### What Gets Updated

The script updates:

**Android Packages:**
- All 10 Android binding `.csproj` files in `src/Android/Bindings/`
  - `<Version>` tag
  - `PackageReference` versions to other Android packages
  - `artifact_versioned` in `PackageTags`
- Test project: `src/Android/Bindings/Test/TestBindings/TestBindings.csproj`

**iOS Packages:**
- All 10 iOS binding `.csproj` files in `src/iOS/Bindings/`
  - `<Version>` tag
  - `PackageReference` versions to other iOS packages

**Documentation:**
- `README.md` - Package version examples
- `GETTING_STARTED.md` - Installation instructions

### After Running the Update Script

1. **Review the changes:**
   ```bash
   git diff
   ```

2. **Test the build locally:**
   ```bash
   # For Android
   make build-android

   # For iOS
   make build-ios
   ```

3. **Commit the changes:**
   ```bash
   git add -A
   git commit -m "Update to SDK versions Android X.Y.Z, iOS X.Y.Z"
   ```

4. **Create a pull request** or push directly to main

### Automated Update Checking (GitHub Actions)

The repository includes a GitHub Actions workflow that automatically checks for new SDK releases.

**Workflow:** `check-sdk-updates.yml`

- **Schedule:** Runs every Monday at 9 AM UTC
- **Manual trigger:** You can also run it manually from the Actions tab

**What it does:**
1. Checks for new releases in `dd-sdk-android` and `dd-sdk-ios`
2. Compares with current submodule versions
3. If updates are available, creates/updates a GitHub issue with:
   - Current versions
   - Latest versions
   - Links to release notes
   - Update instructions

**GitHub Issue:**
When updates are available, an issue titled **"New Datadog SDK versions available"** is created with:
- Labels: `sdk-update`, `enhancement`
- Current vs. latest versions
- Direct links to release notes
- Copy-paste command to update

The issue is automatically updated if it already exists.

### Manual Update Process

If you prefer to update manually:

#### 1. Update Git Submodules

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

#### 2. Update Android .csproj Files

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

#### 3. Update iOS .csproj Files

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

#### 4. Update Documentation

Update version numbers in:
- `README.md` - Package examples
- `GETTING_STARTED.md` - Installation instructions

#### 5. Rebuild Native Libraries

**For iOS:**
```bash
./src/iOS/buildxcframework.sh
```

This rebuilds the XCFrameworks from the updated submodule.

**For Android:**
Android AAR files are included in the submodule, so no rebuild is needed.

### Version Alignment

The Datadog Android and iOS SDKs typically stay in sync with version numbers. However, they can occasionally be at different versions. The update script handles this correctly by allowing different versions for each platform.

### Testing After Updates

After updating, thoroughly test:

1. **Local builds:**
   ```bash
   make build-android
   make build-ios
   ```

2. **CI/CD workflows:** Push and verify all workflows pass

3. **Integration test:** Test in a sample MAUI app to ensure compatibility

### Troubleshooting Updates

#### Issue: Script can't find git tags

```bash
cd dd-sdk-android
git fetch --tags
cd ../dd-sdk-ios
git fetch --tags
cd ..
```

#### Issue: Submodule is in detached HEAD state

This is expected. The submodules are pinned to specific tag versions.

#### Issue: Build fails after update

Check the release notes for breaking changes:
- [Android Release Notes](https://github.com/DataDog/dd-sdk-android/releases)
- [iOS Release Notes](https://github.com/DataDog/dd-sdk-ios/releases)

You may need to update bindings or metadata. See [TROUBLESHOOTING_BINDING_ERRORS.md](TROUBLESHOOTING_BINDING_ERRORS.md) for detailed guidance.

---

## Android Build Process

### Prerequisites

- .NET 10 SDK
- Java SDK (set `JAVA_HOME`)
- Android SDK
- Git (for submodules)

### Step-by-Step Build

#### 1. Update the Datadog Android SDK Submodule

```bash
cd /path/to/datadog-dotnet-mobile-sdk-bindings

# Update to latest version
git submodule update --init --recursive dd-sdk-android

# Or update to specific version
cd dd-sdk-android
git checkout v2.21.0
cd ..
git add dd-sdk-android
git commit -m "Update dd-sdk-android to 2.21.0"
```

#### 2. Build Native AAR Files

```bash
cd src/Android
./build-aars.sh
```

**What this does:**
1. Locates `dd-sdk-android/` submodule
2. Stops any running Gradle daemons to avoid cached state
3. Runs `./gradlew clean --no-build-cache`
4. Builds all modules:
   - `:dd-sdk-android-core:assembleRelease`
   - `:dd-sdk-android-internal:assembleRelease`
   - `:features:dd-sdk-android-logs:assembleRelease`
   - `:features:dd-sdk-android-rum:assembleRelease`
   - `:features:dd-sdk-android-trace:assembleRelease`
   - `:features:dd-sdk-android-session-replay:assembleRelease`
   - `:features:dd-sdk-android-webview:assembleRelease`
   - `:features:dd-sdk-android-ndk:assembleRelease`
   - And more...

**Output:** `.aar` files in `dd-sdk-android/*/build/outputs/aar/`

**Troubleshooting:**
- If Gradle fails, ensure `JAVA_HOME` is set correctly
- Check Android SDK is installed and `ANDROID_HOME` is set
- Verify submodule is on the correct branch/tag

#### 3. Copy AAR Files to Binding Projects

```bash
./copy-aars.sh
```

**What this does:**
Copies each `.aar` file to its corresponding binding project:

```
dd-sdk-android/dd-sdk-android-core/build/outputs/aar/dd-sdk-android-core-release.aar
  → src/Android/Bindings/Core/aars/dd-sdk-android-core-release.aar

dd-sdk-android/features/dd-sdk-android-rum/build/outputs/aar/dd-sdk-android-rum-release.aar
  → src/Android/Bindings/Rum/aars/dd-sdk-android-rum-release.aar
```

#### 4. Update Version Numbers

Edit each `.csproj` file to update the version:

```xml
<!-- src/Android/Bindings/Core/Core.csproj -->
<PropertyGroup>
  <Version>2.21.0-pre.1</Version>
  <PackageTags>artifact_versioned=com.datadog.android:dd-sdk-android-core:2.21.0</PackageTags>
</PropertyGroup>
```

**Version Format:** `<DatadogVersion>-pre.<revision>`
- `2.21.0` - Matches native Datadog SDK version
- `-pre` - Pre-release tag (remove when .NET 10 is GA)
- `.1` - Binding-specific revision number

#### 5. Build .NET Bindings

```bash
cd ../../
dotnet build src/Android/Bindings/Core/Core.csproj
dotnet build src/Android/Bindings/Rum/Rum.csproj
# Or build all
dotnet build src/Android/Bindings/
```

#### 6. Verify and Test

```bash
# Build the test app
dotnet build src/Android/Bindings/Test/TestBindings/TestBindings.csproj

# Run tests if available
dotnet test
```

---

## iOS Build Process

### Prerequisites

- macOS with Xcode 16.1 or later
- .NET 9 or 10 SDK
- **Carthage** - iOS dependency manager (required for building XCFrameworks)
  ```bash
  brew install carthage
  ```
- **Objective Sharpie** - C# binding generator (required for generating bindings)
  ```bash
  brew install objectivesharpie
  ```
- Git (for submodules)
  ```bash
  git submodule update --init --recursive
  ```
- Optional: `GITHUB_PAT` environment variable for Carthage authentication to avoid rate limiting

### Step-by-Step Build

#### 1. Update the Datadog iOS SDK Submodule

```bash
cd /path/to/datadog-dotnet-mobile-sdk-bindings

# Update to latest version
git submodule update --init --recursive dd-sdk-ios

# Or update to specific version
cd dd-sdk-ios
git checkout 2.26.0
cd ..
git add dd-sdk-ios
git commit -m "Update dd-sdk-ios to 2.26.0"
```

#### 2. Build XCFrameworks

```bash
cd src/iOS
./buildxcframework.sh
```

**What this does:**
1. **Runs Carthage** to fetch dependencies:
   ```bash
   carthage bootstrap --platform iOS --use-xcframeworks
   ```

2. **Builds device + simulator archives** for each framework:
   - DatadogInternal
   - DatadogCore
   - DatadogLogs
   - DatadogTrace
   - DatadogRUM
   - DatadogSessionReplay
   - DatadogCrashReporting
   - DatadogObjc
   - DatadogWebViewTracking

3. **Creates XCFrameworks** by combining archives:
   ```bash
   xcodebuild -create-xcframework \
     -archive iphonesimulator.xcarchive \
     -archive iphoneos.xcarchive \
     -output DDObjc.xcframework
   ```

4. **Copies frameworks** to `src/iOS/Bindings/Libs/`

5. **Removes non-iOS architectures** (keeps only `ios-arm64*`)

6. **Extracts Swift headers** to `src/iOS/Bindings/Headers/`:
   - `DatadogObjc-Swift.h`
   - `DatadogCrashReporting-Swift.h`
   - `DatadogSessionReplay-Swift.h`
   - `DatadogWebViewTracking-Swift.h`

**Output:**
- XCFrameworks in `src/iOS/Bindings/Libs/` (e.g., `DDObjc.xcframework`)
- Swift headers in `src/iOS/Bindings/Headers/`

**Troubleshooting:**
- If Carthage fails with rate limiting, set `GITHUB_PAT` environment variable
- If Xcode build fails, ensure Xcode command line tools are installed: `xcode-select --install`
- Check that you have enough disk space (builds can be large)

#### 3. Generate C# Binding Definitions

```bash
./buildobjectivesharpiebindings.sh
```

**What this does:**
1. Finds Swift header files in `src/iOS/Bindings/Headers/`
2. Runs Objective Sharpie for each framework:
   ```bash
   sharpie bind \
     -output ./Bindings/ObjC \
     -namespace Datadog.iOS.ObjC \
     -sdk iphoneos \
     -scope ./Bindings/Headers \
     DatadogObjc-Swift.h
   ```

3. Generates for each binding project:
   - `ApiDefinitions.cs` - C# interface definitions
   - `StructsAndEnums.cs` - Enums and structs

**Important:** Objective Sharpie output requires manual review and fixes:
- Check for `[Verify]` attributes - these need manual verification
- Fix any incorrect type mappings
- Add missing protocol implementations
- Update method signatures as needed

#### 4. Update Version Numbers

Edit each `.csproj` file:

```xml
<!-- src/iOS/Bindings/ObjC/ObjC.csproj -->
<PropertyGroup>
  <TargetFrameworks>net9.0-ios17.0;net10.0-ios17.0</TargetFrameworks>
  <PackageVersion>2.26.0</PackageVersion>
</PropertyGroup>
```

#### 5. Build .NET Bindings

```bash
cd ../../
dotnet build src/iOS/Bindings/ObjC/ObjC.csproj
dotnet build src/iOS/Bindings/CrashReporting/CrashReporting.csproj
# Or build all
dotnet build src/iOS/Bindings/
```

#### 6. Generate Documentation (Optional)

```bash
cd src/iOS/Bindings
./buildmdoc.sh
```

This generates XML documentation files in `docs/` folder that provide IntelliSense support.

#### 7. Verify and Test

```bash
# Build the test app
dotnet build src/iOS/T/T.csproj

# Run on simulator or device
dotnet build -t:Run src/iOS/T/T.csproj
```

---

## Versioning Strategy

### Version Format

**Android:** `<DatadogVersion>-pre.<revision>`
- Example: `2.21.0-pre.1`
- Remove `-pre` when .NET 10 is GA (November 2025)

**iOS:** `<DatadogVersion>`
- Example: `2.26.0`
- No pre-release tag needed (works with .NET 8+)

### Target Framework Strategy

#### Android: Single Target

```xml
<TargetFramework>net10.0-android</TargetFramework>
<SupportedOSPlatformVersion>26</SupportedOSPlatformVersion>
```

**Why .NET 10 only?**
- **16KB page size requirement**: Required for Android 15+ compatibility (see section below)
- **Critical binding bugs**: .NET 9 has breaking bugs in Android binding projects, fixed in .NET 10
- Apps must target .NET 10 to use these bindings

**Migration Path:**
- ❌ .NET 8/9 apps cannot use current bindings
- ✅ Upgrade app to .NET 10: `<TargetFramework>net10.0-android</TargetFramework>`

#### iOS: Multi-Target

```xml
<TargetFrameworks>net9.0-ios17.0;net10.0-ios17.0</TargetFrameworks>
```

**Why multiple targets?**
- Provides backwards compatibility with .NET 9 and 10
- Allows gradual migration
- No iOS-specific binding issues in .NET 9/10

**Compatibility:**
- ✅ .NET 9 apps use `net9.0-ios` target (minimum iOS 17.0)
- ✅ .NET 10 apps use `net10.0-ios` target (minimum iOS 17.0)

### Version Compatibility Matrix

| .NET Version | Android Support | iOS Support | Notes |
|--------------|-----------------|-------------|-------|
| .NET 8 | ❌ Not supported | ❌ Not supported | Dropped support |
| .NET 9 | ❌ Not supported | ✅ Supported | Android binding bugs |
| .NET 10 | ✅ Required | ✅ Supported | Only version for Android |
| .NET 11+ | 🔜 Future | 🔜 Future | Add when available |

### When to Publish New Versions

#### Scenario 1: Native SDK Version Update

```
Datadog SDK: 2.21.0 → 2.22.0
Action: Update binding version to match
```

**Steps:**
1. Update submodule to new Datadog version
2. Run build scripts
3. Update all `.csproj` files: `<Version>2.22.0-pre.1</Version>`
4. Update package tags: `artifact_versioned=com.datadog.android:dd-sdk-android-core:2.22.0`
5. Build, test, and publish

#### Scenario 2: Binding-Specific Fix

```
Current: 2.21.0-pre.1
Action: Increment revision to 2.21.0-pre.2
Reason: Fixed Metadata.xml, added Additions code, etc.
```

**When:**
- Fixed C# binding code
- Updated `Metadata.xml` transforms
- Added missing `Additions/` code
- Fixed NuGet package configuration
- Native SDK version unchanged

#### Scenario 3: .NET Version Update

**Android - Add .NET 11 Support:**
```xml
<!-- Update when .NET 11 is GA -->
<TargetFramework>net11.0-android</TargetFramework>
```

**iOS - Add .NET 11 Support:**
```xml
<TargetFrameworks>net9.0-ios17.0;net10.0-ios17.0;net11.0-ios</TargetFrameworks>
```

**When:** After new .NET version is GA and tested

#### Scenario 4: Platform OS Version Update

```xml
<!-- If Datadog SDK raises minimum Android version -->
<SupportedOSPlatformVersion>29</SupportedOSPlatformVersion> <!-- Android 10 -->

<!-- If Datadog SDK requires iOS 18 -->
<TargetFrameworks>net9.0-ios18.0;net10.0-ios18.0</TargetFrameworks>
<!-- Note: Currently supporting iOS 17.0+ -->
```

**When:** Native Datadog SDK drops support for older OS versions

### Publishing Decision Tree

```
┌─ Native SDK version changed?
│  ├─ Yes → Update version to match (2.21.0 → 2.22.0)
│  │        Update PackageTags artifact version
│  │        Publish new packages
│  └─ No  → Continue
│
├─ Binding code changed?
│  ├─ Yes → Increment revision (2.21.0-pre.1 → 2.21.0-pre.2)
│  │        Publish new packages
│  └─ No  → Continue
│
├─ .NET version added/removed?
│  ├─ Yes → Update TargetFramework(s)
│  │        Test thoroughly
│  │        Publish new packages
│  └─ No  → Continue
│
└─ Minimum OS version changed?
   ├─ Yes → Update SupportedOSPlatformVersion
   │        Update documentation
   │        Publish new packages
   └─ No  → No publish needed
```

---

## 16KB Page Size Requirement

### What is it?

Android 15+ is transitioning from 4KB to 16KB memory page sizes for better performance on devices with more RAM.

**Benefits:**
- 3.16% faster app launches on average (up to 30% for some apps)
- 4.56% lower power consumption during launch
- Better overall system responsiveness

### Does it Affect These Bindings?

**Short Answer:** Yes, which is why we require .NET 10.

**Explanation:**

The 16KB page size requirement affects:
1. ✅ **Native libraries (`.so` files)** compiled with 4KB alignment
2. ✅ **.NET runtime libraries** not compiled for 16KB
3. ✅ **Third-party native dependencies** in AAR files

**How to Check if AAR Contains Native Libraries:**

```bash
# Check an AAR file for native libraries
unzip -l src/Android/Bindings/Core/aars/dd-sdk-android-core-release.aar | grep -E '\.(so|a)$'
```

**Datadog Android SDK Status:**
- ✅ Datadog's native SDK is **pure Java/Kotlin** - no native `.so` files
- ✅ Dependencies (OkHttp, Gson, etc.) are also pure Java
- ❌ BUT: .NET for Android runtime has native components that needed fixing

### .NET Support Timeline

| .NET Version | 16KB Support | Status |
|--------------|--------------|--------|
| .NET 8 | ❌ No | Out of support (May 14, 2025) |
| .NET 9 | ⚠️ Partial | Has binding project bugs |
| .NET 10 | ✅ Full | Required - GA November 2025 |

**From Microsoft's Blog:**
> ".NET MAUI 9 supports 16 KB page sizes out of the box, so make sure that your .NET MAUI (and .NET for Android) app is on .NET 9"

**However:** .NET 9 has critical bugs in binding projects specifically, which is why we require .NET 10.

### How to Verify Your App is Compatible

#### 1. Check Target Framework

```xml
<!-- Your app's .csproj -->
<TargetFramework>net10.0-android</TargetFramework>
```

#### 2. Test on Android 15+ Device

```bash
# Build and deploy to device
dotnet build -f net10.0-android -c Release
dotnet build -t:Run -f net10.0-android

# Check logcat for page size warnings
adb logcat | grep -i "page"
```

#### 3. Check for Crashes on Startup

If your app crashes immediately on Android 15+ with a native crash, it's likely a page size issue.

**Error Symptoms:**
- App crashes on launch on Android 15+ devices
- Works fine on Android 14 and below
- Logcat shows memory alignment errors

### What if I Can't Use .NET 10 Yet?

**Option 1: Wait for .NET 10 GA** (November 2025)
- These bindings require .NET 10
- Cannot be used with .NET 8/9 due to Android-specific requirements

**Option 2: Use Older Datadog SDK Versions**
- Not recommended - missing features and bug fixes
- May have security vulnerabilities

**Option 3: Fork and Modify**
- You could try building for .NET 9, but expect binding issues
- Not officially supported

### When Can We Remove the .NET 10 Requirement?

**After:**
1. .NET 10 is GA (November 2025)
2. All known binding bugs are resolved
3. Majority of users have migrated to .NET 10+
4. .NET 9 support policy ends

**Earliest:** Q4 2025 or later

---

## Publishing Checklist

### Before Publishing

- [ ] Update Datadog SDK submodule to target version
- [ ] Run build scripts successfully
- [ ] Update version numbers in all `.csproj` files
- [ ] Update `artifact_versioned` in `PackageTags`
- [ ] Update `<PackageReleaseNotes>` with changes
- [ ] Build all binding projects without errors
- [ ] Build and test sample apps
- [ ] Test on physical devices (Android 15+, iOS 17+)
- [ ] Review generated NuGet package contents
- [ ] Update CHANGELOG.md

### Android-Specific Checklist

- [ ] AAR files copied to all `aars/` folders
- [ ] No Gradle build errors
- [ ] Metadata.xml transforms are correct
- [ ] Additions code compiles
- [ ] Test app builds and runs
- [ ] Verify .NET 10 requirement in README

### iOS-Specific Checklist

- [ ] XCFrameworks built for both simulator and device
- [ ] Swift headers extracted correctly
- [ ] Objective Sharpie bindings reviewed
- [ ] `[Verify]` attributes addressed
- [ ] Multi-targeting works for .NET 9 and 10
- [ ] Test app builds and runs
- [ ] Documentation generated (optional)

### Publishing

```bash
# Build NuGet packages
dotnet pack -c Release src/Android/Bindings/Core/Core.csproj
dotnet pack -c Release src/iOS/Bindings/ObjC/ObjC.csproj

# Verify package contents
unzip -l bin/Release/Bcr.Datadog.Android.Sdk.Core.2.21.0-pre.1.nupkg

# Publish to NuGet (example)
dotnet nuget push bin/Release/*.nupkg --api-key YOUR_KEY --source https://api.nuget.org/v3/index.json
```

### After Publishing

- [ ] Tag release in Git: `git tag v2.21.0-pre.1`
- [ ] Push tags: `git push --tags`
- [ ] Create GitHub release with notes
- [ ] Update documentation with new version
- [ ] Announce in release notes/blog
- [ ] Monitor for issues from users

---

## Troubleshooting

### Android Build Issues

**Problem:** `JAVA_HOME is not set`
```bash
# Set JAVA_HOME
export JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-17.jdk/Contents/Home
```

**Problem:** Gradle build fails with "Could not resolve dependencies"
```bash
# Clear Gradle caches
./dd-sdk-android/gradlew clean --no-daemon
rm -rf ~/.gradle/caches/
```

**Problem:** AAR file not found
```bash
# Check if build actually produced the AAR
ls dd-sdk-android/*/build/outputs/aar/
```

### iOS Build Issues

**Problem:** Carthage rate limiting
```bash
# Set GitHub token
export GITHUB_PAT=your_github_token
./buildxcframework.sh
```

**Problem:** Xcode build fails
```bash
# Check Xcode is installed
xcode-select -p

# Install command line tools
xcode-select --install

# Clear derived data
rm -rf src/iOS/DerivedData
```

**Problem:** Objective Sharpie not found
```bash
# Install Objective Sharpie
brew install objectivesharpie

# Or download from Microsoft
```

### .NET Build Issues

**Problem:** "TargetFramework 'net10.0-android' is not supported"
```bash
# Install .NET 10 SDK
# Download from: https://dotnet.microsoft.com/download/dotnet/10.0
```

**Problem:** Binding errors during build
- Check `Metadata.xml` for typos
- Verify AAR/XCFramework is present
- Review `Additions/` code for errors

---

## Additional Resources

- [Datadog Android SDK](https://github.com/DataDog/dd-sdk-android)
- [Datadog iOS SDK](https://github.com/DataDog/dd-sdk-ios)
- [Microsoft: Android 16KB Page Size](https://devblogs.microsoft.com/dotnet/android-16kb-page-size/)
- [.NET for Android Documentation](https://learn.microsoft.com/dotnet/android/)
- [.NET for iOS Documentation](https://learn.microsoft.com/dotnet/ios/)
- [Objective Sharpie Documentation](https://learn.microsoft.com/xamarin/cross-platform/macios/binding/objective-sharpie/)

---

## Questions?

For binding-specific issues, open an issue in this repository.

For Datadog SDK questions, refer to [official Datadog documentation](https://docs.datadoghq.com/).
