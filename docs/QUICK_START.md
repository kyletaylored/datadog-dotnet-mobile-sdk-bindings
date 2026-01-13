# Quick Start Guide

This is a quick reference for common tasks in the Datadog .NET Bindings repository.

## Prerequisites

Run this first to check if you have everything installed:

```bash
make check-prereqs
```

### Required
- .NET SDK 9.0.x and 10.0.x
- Java 17+

### macOS Only (for iOS builds)
- Xcode 16.1+
- Carthage
- Objective Sharpie (optional, for regenerating bindings)

## Common Workflows

### 🆕 First Time Setup

```bash
# Clone and setup
git clone https://github.com/brunck/datadog-dotnet-mobile-sdk-bindings.git
cd datadog-dotnet-mobile-sdk-bindings
make dev-setup
```

### 📦 Building Packages

#### Prerequisites

**For iOS packages:**
- macOS with Xcode 16.1+
- .NET SDK 8.0.x, 9.0.x, and 10.0.x
- Carthage: `brew install carthage`

**For Android packages:**
- .NET SDK 9.0.x and 10.0.x
- Java 17+: [Download](https://adoptium.net/)
- Android SDK (via Visual Studio or Android Studio)

#### Build Commands

```bash
# Build everything (Android + iOS)
make build

# Build Android only (includes AAR building)
make build-android

# Quick Android build (skip AAR rebuild)
make build-android-quick

# Build iOS only (macOS)
make build-ios

# Quick iOS build (skip framework rebuild)
make build-ios-quick
```

#### What Gets Built

**iOS packages** (output: `./local-packages/`):
- `Bcr.Datadog.iOS.Core.{version}.nupkg`
- `Bcr.Datadog.iOS.Logs.{version}.nupkg`
- `Bcr.Datadog.iOS.Trace.{version}.nupkg`
- `Bcr.Datadog.iOS.RUM.{version}.nupkg`
- `Bcr.Datadog.iOS.SR.{version}.nupkg` (Session Replay)
- `Bcr.Datadog.iOS.CR.{version}.nupkg` (Crash Reporting)
- `Bcr.Datadog.iOS.ObjC.{version}.nupkg`
- `Bcr.Datadog.iOS.Web.{version}.nupkg` (WebView Tracking)
- `Bcr.Datadog.iOS.Int.{version}.nupkg` (Internal)
- `Bcr.Datadog.iOS.OTel.{version}.nupkg` (OpenTelemetry)

Each iOS package contains: `net8.0-ios`, `net9.0-ios`, `net10.0-ios` (all iOS 17.0+)

**Android packages** (output: `./local-packages/`):
- `Bcr.Datadog.Android.Core.{version}.nupkg`
- `Bcr.Datadog.Android.Logs.{version}.nupkg`
- `Bcr.Datadog.Android.Trace.{version}.nupkg`
- `Bcr.Datadog.Android.RUM.{version}.nupkg`
- `Bcr.Datadog.Android.SR.{version}.nupkg` (Session Replay)
- `Bcr.Datadog.Android.Web.{version}.nupkg` (WebView Tracking)
- `Bcr.Datadog.Android.OTel.{version}.nupkg` (OpenTelemetry)

Each Android package contains: `net9.0-android`, `net10.0-android` (both API 26+)

#### Build Times
- **iOS**: 20-30 minutes (first time), 5-10 minutes (with cached Carthage builds)
- **Android**: 5-10 minutes

#### Troubleshooting Builds

**iOS build issues:**
```bash
# XCFrameworks not found - ensure submodules initialized
git submodule update --init --recursive
./src/iOS/buildxcframework.sh

# Multiple .NET SDK versions required
dotnet --list-sdks  # Check you have 8.0.x AND (9.0.x OR 10.0.x)

# Carthage build fails
brew upgrade carthage
rm -rf ~/Library/Caches/org.carthage.CarthageKit
rm -rf dd-sdk-ios/Carthage
```

**Android build issues:**
```bash
# Multiple .NET SDK versions required
dotnet --list-sdks  # Check you have both 9.0.x AND 10.0.x

# Java version issues
java -version  # Must be 17+
export JAVA_HOME=$(/usr/libexec/java_home -v 17)

# Android SDK not found
dotnet workload install android
```

### 🔄 Updating SDK Versions

```bash
# List available versions (10 most recent)
make list-versions

# Check for updates
make check-updates

# Update to latest versions
make update-sdks

# Update to specific versions (for historical packages)
./update-sdk-versions.sh --android-version 3.2.0 --ios-version 3.2.0

# Update Android only
make update-android

# Update iOS only
make update-ios
```

### 🧪 Testing

```bash
# Test everything
make test

# Test Android only
make test-android

# Test iOS only (macOS)
make test-ios
```

### 🧹 Cleaning

```bash
# Clean build artifacts
make clean

# Deep clean (including iOS XCFrameworks)
make clean-all
```

### 📊 Status & Info

```bash
# Show current versions and git status
make status

# Show help and all available commands
make help

# Show quick reference
make readme
```

### 🚀 Preparing a Release

```bash
# Full release preparation (update, build, test)
make prepare-release

# Then review, commit, and push
git diff
git add -A
git commit -m "Prepare release X.Y.Z"
git push
```

## Build Process Overview

### Android Build Flow

```
1. Initialize submodules (dd-sdk-android)
2. Build Android AAR files from SDK source (Gradle)
3. Copy AAR files to binding project directories
4. Build with .NET SDK 9 → net9.0-android packages
5. Build with .NET SDK 10 → net10.0-android packages
6. Combine both into unified NuGet packages
```

**Commands:**
```bash
# Full build (includes AAR building)
make build-android

# Quick build (skip AAR rebuild)
make build-android-quick

# Just build AARs
make build-android-aars
```

**Output:** `./local-packages/Bcr.Datadog.Android.*.nupkg`

### iOS Build Flow

```
1. Initialize submodules (dd-sdk-ios)
2. Build XCFrameworks using Carthage (15-20 min, first time)
3. Build with .NET SDK 8 → net8.0-ios packages
4. Build with .NET SDK 9+ → net9.0-ios, net10.0-ios packages
5. Combine all into unified NuGet packages
```

**Output:** `./local-packages/Bcr.Datadog.iOS.*.nupkg`

## Directory Structure

```
.
├── dd-sdk-android/          # Android SDK submodule
├── dd-sdk-ios/              # iOS SDK submodule
├── src/
│   ├── Android/
│   │   └── Bindings/        # 10 Android binding projects
│   └── iOS/
│       └── Bindings/        # 10 iOS binding projects
├── .github/workflows/       # CI/CD workflows
├── Makefile                 # Main build orchestration
├── update-sdk-versions.sh   # SDK version update script
└── build-local-*-packages.sh # Platform build scripts
```

## SDK Version Management

### Manual Update Process

```bash
# 1. Check for updates
make check-updates

# 2. Update to latest
make update-sdks

# 3. Review changes
git diff

# 4. Build and test
make build
make test
```

### What Gets Updated

- Git submodules (`dd-sdk-android`, `dd-sdk-ios`)
- All `.csproj` files (version tags, package references)
- Documentation (`README.md`, `GETTING_STARTED.md`)

### Automated Checking

A GitHub Actions workflow runs weekly to check for new SDK releases and creates issues automatically.

## Common Issues

### "Android workload not installed"

```bash
dotnet workload install android
```

### "iOS workload not installed" (macOS)

```bash
dotnet workload install ios
```

### "Cannot find AAR files" (Android)

```bash
make build-android-aars
```

### "Cannot find XCFrameworks" (iOS)

```bash
make build-ios-frameworks
```

### "Missing .NET SDK version"

Install the required SDK versions:
- [.NET 9](https://dotnet.microsoft.com/download/dotnet/9.0)
- [.NET 10](https://dotnet.microsoft.com/download/dotnet/10.0)

### Build fails after SDK update

Check the SDK release notes for breaking changes:
- [Android releases](https://github.com/DataDog/dd-sdk-android/releases)
- [iOS releases](https://github.com/DataDog/dd-sdk-ios/releases)

## Using Locally Built Packages

```bash
# Add local package source
dotnet nuget add source $(pwd)/local-packages --name local-datadog

# Install packages
dotnet add package Bcr.Datadog.Android.Sdk.Core
dotnet add package Bcr.Datadog.iOS.ObjC

# Remove local source when done
dotnet nuget remove source local-datadog
```

## CI/CD Workflows

### Build Workflows
- `.github/workflows/build-android.yml` - Android package builds
- `.github/workflows/build-ios.yml` - iOS package builds

### Automation
- `.github/workflows/check-sdk-updates.yml` - Weekly SDK update checks
- `.github/workflows/prepare-release.yml` - Release preparation

## Key Files

| File | Purpose |
|------|---------|
| `Makefile` | Main build orchestration |
| `update-sdk-versions.sh` | Update SDK versions |
| `build-local-android-packages.sh` | Build Android NuGet packages |
| `build-local-ios-packages.sh` | Build iOS NuGet packages |
| `src/Android/setup-aars.sh` | Smart AAR setup - intelligently downloads required AARs/JARs from Maven Central |
| `src/Android/build-aars.sh` | Build Android AAR files from SDK source (for development/unreleased versions) |
| `src/Android/copy-aars.sh` | Copy Android AAR files to binding projects (used with build-aars.sh) |
| `src/iOS/setup-xcframeworks.sh` | Smart XCFramework setup - downloads pre-built frameworks from GitHub releases |
| `src/iOS/buildxcframework.sh` | Build iOS XCFrameworks from SDK source (for development/unreleased versions) |

## Documentation

- **[README.md](../README.md)** - Main project documentation
- **[GETTING_STARTED.md](GETTING_STARTED.md)** - Usage guide for consumers
- **[BUILDING_AND_VERSIONING.md](BUILDING_AND_VERSIONING.md)** - Build system, SDK updates, and versioning details
- **[SDK_VERSIONING_STRATEGY.md](SDK_VERSIONING_STRATEGY.md)** - Versioning philosophy and branching strategy
- **[RELEASE_PROCESS.md](RELEASE_PROCESS.md)** - Publishing workflow

## Getting Help

```bash
# Show all available make commands
make help

# Show quick reference
make readme

# Check your setup
make check-prereqs

# Check current status
make status
```

## Development Workflow Example

```bash
# 1. Update SDKs
make check-updates
make update-sdks

# 2. Build
make build

# 3. Test
make test

# 4. Clean up if needed
make clean

# 5. Check status before committing
make status

# 6. Commit and push
git add -A
git commit -m "Update to SDK X.Y.Z"
git push
```

## Links

- [Main Repository](https://github.com/brunck/datadog-dotnet-mobile-sdk-bindings)
- [Datadog Android SDK](https://github.com/DataDog/dd-sdk-android)
- [Datadog iOS SDK](https://github.com/DataDog/dd-sdk-ios)
- [NuGet Packages](https://www.nuget.org/packages?q=Bcr.Datadog)

---

**Need more details?** Run `make help` or check the documentation files listed above.
