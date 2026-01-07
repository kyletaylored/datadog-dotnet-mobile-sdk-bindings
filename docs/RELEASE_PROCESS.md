# Release Process Guide

This document explains the complete release process for publishing new versions of the Datadog .NET Mobile SDK Bindings to NuGet.org.

## Overview

The binding versions mirror the native Datadog SDK versions. When Datadog releases a new version of their mobile SDKs (e.g., `2.26.1` or `2.27.0`), we create matching binding packages with the same version number.

## Release Workflow

### 1. Monitor Upstream SDK Releases

Watch for new releases from the native Datadog SDKs:

- **iOS SDK**: https://github.com/DataDog/dd-sdk-ios/releases
- **Android SDK**: https://github.com/DataDog/dd-sdk-android/releases

Subscribe to release notifications to stay informed of new versions.

### 2. Update Submodules

When a new SDK version is released:

```bash
# Update iOS SDK submodule
cd dd-sdk-ios
git fetch --tags
git checkout <version-tag>  # e.g., 2.27.0
cd ..

# Update Android SDK submodule
cd dd-sdk-android
git fetch --tags
git checkout <version-tag>  # e.g., 2.27.0
cd ..

# Commit submodule updates
git add dd-sdk-ios dd-sdk-android
git commit -m "Update to Datadog SDK version 2.27.0"
git push
```

Alternatively, use the automated workflow:

```bash
# Trigger the update-submodules workflow in GitHub Actions
# This will create a PR with submodule updates
```

### 3. Update Package Versions

Update the `<PackageVersion>` in all `.csproj` files to match the new SDK version:

**iOS Projects** (`src/iOS/Bindings/*/`):
- `Core/Core.csproj`
- `CrashReporting/CrashReporting.csproj`
- `DDLogs/DDLogs.csproj`
- `Internal/Internal.csproj`
- `ObjC/ObjC.csproj`
- `OpenTelemetryApi/OpenTelemetryApi.csproj`
- `Rum/Rum.csproj`
- `SessionReplay/SessionReplay.csproj`
- `Trace/Trace.csproj`
- `WebViewTracking/WebViewTracking.csproj`

**Android Projects** (`src/Android/Bindings/*/`):
- `Core/Core.csproj`
- `DatadogLogs/DatadogLogs.csproj`
- `Internal/Internal.csproj`
- `Ndk/Ndk.csproj`
- `Rum/Rum.csproj`
- `SessionReplay/SessionReplay.csproj`
- `Trace/Trace.csproj`
- `Trace.Otel/Trace.Otel.csproj`
- `WebView/WebView.csproj`

Update `PackageReference` versions in projects that reference other binding packages.

### 4. Rebuild Native Bindings (if needed)

If the native SDK has API changes, you may need to rebuild bindings:

#### iOS

```bash
# Build XCFrameworks
./src/iOS/buildxcframework.sh

# Regenerate C# bindings (if API changed)
./src/iOS/buildobjectivesharpiebindings.sh

# Update documentation
cd src/iOS/Bindings
./buildmdoc.sh
```

#### Android

```bash
# Build AARs
cd src/Android
./build-aars.sh

# Copy AARs to binding projects
./copy-aars.sh
```

See [BUILDING_AND_VERSIONING.md](BUILDING_AND_VERSIONING.md) for detailed build instructions.

### 5. Test Locally

Build and test packages locally before releasing:

```bash
# Build iOS packages
./build-local-ios-packages.sh ./test-packages

# Build Android packages
./build-local-android-packages.sh ./test-packages

# Test in a sample project
dotnet nuget add source ./test-packages --name local-test
dotnet new maui -n TestApp
cd TestApp
dotnet add package Bcr.Datadog.iOS.ObjC --version 2.27.0
dotnet add package Bcr.Datadog.Android.Core --version 2.27.0
dotnet build
```

Verify that:
- ✅ Packages install correctly
- ✅ Projects build without errors
- ✅ Runtime initialization works
- ✅ API changes (if any) are documented

### 6. Commit and Push Changes

```bash
git add .
git commit -m "Release version 2.27.0

- Update dd-sdk-ios to 2.27.0
- Update dd-sdk-android to 2.27.0
- Update all package versions to 2.27.0
- [List any API changes or binding updates]"

git push origin main
```

### 7. Run Prepare Release Workflow (Dry Run)

Test the release workflow without publishing:

1. Go to **Actions** → **Prepare Release**
2. Click **Run workflow**
3. Enter version: `2.27.0`
4. Select platform: `both`
5. Click **Run workflow**

This will:
- Build all packages
- Run version validation
- Create artifacts (without publishing)

Review the generated packages in the workflow artifacts.

### 8. Publish to NuGet.org

Once testing is complete, publish the release:

1. Go to **Actions** → **Publish Release**
2. Click **Run workflow**
3. Fill in the form:
   - **Version**: `2.27.0`
   - **Platform**: `both` (or `android`/`ios`)
   - **Publish to NuGet.org**: ✅ **Check this box**
   - **Mark as pre-release**: ☐ (only for pre-releases like `2.27.0-pre.1`)
4. Click **Run workflow**

The workflow will:
1. ✅ Build all packages
2. ✅ Validate package versions and metadata
3. ✅ Publish to NuGet.org (if checked)
4. ✅ Create GitHub Release with assets
5. ✅ Generate release notes

### 9. Verify Publication

After the workflow completes:

1. **Check NuGet.org**: https://www.nuget.org/packages?q=bcr.datadog
   - Verify all packages are published
   - Check version numbers
   - Review package metadata

2. **Check GitHub Release**: https://github.com/your-org/your-repo/releases
   - Verify release is created
   - Check release notes
   - Verify package attachments

3. **Test Installation**:
   ```bash
   dotnet new console -n ReleaseTest
   cd ReleaseTest
   dotnet add package Bcr.Datadog.iOS.ObjC --version 2.27.0
   dotnet restore
   ```

### 10. Update Documentation

1. Update [CHANGELOG.md](CHANGELOG.md) with release notes
2. Update README.md if there are significant changes
3. Update [GETTING_STARTED.md](GETTING_STARTED.md) if API changed

### 11. Announce Release

- Post announcement on relevant channels
- Update any documentation sites
- Notify users of breaking changes (if any)

---

## Versioning Strategy

### Regular Releases

Format: `MAJOR.MINOR.PATCH` (e.g., `2.27.0`)

Matches the native SDK version exactly.

### Pre-releases

Format: `MAJOR.MINOR.PATCH-pre.N` (e.g., `2.27.0-pre.1`)

Used for:
- Testing new SDK versions
- Breaking changes that need user feedback
- Beta features

### Binding-Specific Updates

If you need to update bindings without a new SDK release, increment the patch version and add a note:

- SDK `2.27.0` → Binding `2.27.0.1` or `2.27.1`
- Document that it binds SDK version `2.27.0`

---

## Workflow Files

### prepare-release.yml

- **Purpose**: Build and validate packages
- **Trigger**: Manual or called by publish-release.yml
- **Output**: NuGet packages as artifacts
- **Use**: Testing and dry runs

### publish-release.yml

- **Purpose**: Publish validated packages to NuGet.org
- **Trigger**: Manual workflow dispatch
- **Output**:
  - Published NuGet packages
  - GitHub Release
  - Release notes
- **Use**: Production releases

### build-ios.yml

- **Purpose**: Build iOS packages with all target frameworks
- **Features**:
  - Shared XCFramework build
  - Split SDK 8 and 9+ builds
  - Package combining
  - Caching for speed

### build-android.yml

- **Purpose**: Build Android packages
- **Features**:
  - .NET 10 SDK
  - 16KB page size support

---

## Required Secrets

Configure these secrets in GitHub repository settings:

| Secret | Purpose | How to Get |
|--------|---------|------------|
| `NUGET_API_KEY` | Publish to NuGet.org | [Create API Key](https://www.nuget.org/account/apikeys) |
| `GITHUB_TOKEN` | Create releases | Automatically provided |

### Creating NuGet API Key

1. Log in to https://www.nuget.org/
2. Go to **API Keys** → **Create**
3. Settings:
   - **Key Name**: `Datadog .NET Bindings - Production`
   - **Package Owner**: Your NuGet account
   - **Scopes**: `Push new packages and package versions`
   - **Packages**: `Bcr.Datadog.*` (glob pattern)
   - **Expiration**: 365 days (rotate annually)
4. Copy the key immediately (shown only once)
5. Add to GitHub Secrets

---

## Troubleshooting

### Package Version Mismatch

**Error**: Package version doesn't match expected version

**Fix**: Ensure all `.csproj` files have the correct `<PackageVersion>`

```bash
# Find all csproj files with version
grep -r "PackageVersion" src/*/Bindings/*/*.csproj
```

### NuGet Publish Fails

**Error**: `Package already exists`

**Fix**: Version already published. Increment to next version.

**Error**: `The request was aborted: Could not create SSL/TLS secure channel`

**Fix**: Update .NET SDK or use `--api-key` with environment variable

### GitHub Release Creation Fails

**Error**: `Tag already exists`

**Fix**: Delete the tag first or use a different version

```bash
git tag -d v2.27.0
git push origin :refs/tags/v2.27.0
```

### Build Failures

**iOS XCFramework Build Fails**:
- Check Xcode version (16.1+ required)
- Verify submodules are updated: `git submodule status`
- Check Carthage is installed: `brew list carthage`

**Android AAR Build Fails**:
- Check Java version: `java -version` (17+ required)
- Verify JAVA_HOME: `echo $JAVA_HOME`
- Check Android SDK is installed

---

## Checklist

Use this checklist for each release:

- [ ] Monitor upstream SDK releases
- [ ] Update submodules to new version
- [ ] Update all `.csproj` PackageVersion values
- [ ] Rebuild native bindings (if API changed)
- [ ] Test packages locally
- [ ] Commit and push changes
- [ ] Run prepare-release workflow (dry run)
- [ ] Review generated packages
- [ ] Run publish-release workflow
- [ ] Verify packages on NuGet.org
- [ ] Verify GitHub Release
- [ ] Test package installation
- [ ] Update CHANGELOG.md
- [ ] Update documentation (if needed)
- [ ] Announce release

---

## Quick Reference

### File Locations

- **iOS Projects**: `src/iOS/Bindings/*/`
- **Android Projects**: `src/Android/Bindings/*/`
- **iOS Submodule**: `dd-sdk-ios/`
- **Android Submodule**: `dd-sdk-android/`
- **Workflows**: `.github/workflows/`
- **Build Scripts**:
  - iOS: `src/iOS/*.sh`
  - Android: `src/Android/*.sh`
  - Local: `build-local-*-packages.sh`

### Key Commands

```bash
# Update submodules
git submodule update --init --recursive

# Build locally
./build-local-ios-packages.sh ./packages
./build-local-android-packages.sh ./packages

# Test package
dotnet add package Bcr.Datadog.iOS.ObjC --version X.Y.Z

# Publish manually (emergency)
dotnet nuget push package.nupkg --api-key KEY --source https://api.nuget.org/v3/index.json
```

### Important URLs

- NuGet.org Packages: https://www.nuget.org/packages?q=bcr.datadog
- dd-sdk-ios Releases: https://github.com/DataDog/dd-sdk-ios/releases
- dd-sdk-android Releases: https://github.com/DataDog/dd-sdk-android/releases
- Datadog Documentation: https://docs.datadoghq.com/
