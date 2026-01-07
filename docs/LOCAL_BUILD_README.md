# Building NuGet Packages Locally

This guide explains how to build the Datadog .NET iOS and Android binding NuGet packages locally for development and testing.

## Prerequisites

### For iOS Packages

- **macOS** with Xcode 16.1+ installed
- **.NET SDK 8.0.x** - [Download](https://dotnet.microsoft.com/download/dotnet/8.0)
- **.NET SDK 9.0.x or 10.0.x** - [Download](https://dotnet.microsoft.com/download/dotnet)
- **Carthage** - Install with `brew install carthage`

### For Android Packages

- **Linux, macOS, or Windows**
- **.NET SDK 9.0.x and 10.0.x** - [Download](https://dotnet.microsoft.com/download/dotnet)
- **Java 17+** - [Download](https://adoptium.net/)
- **Android SDK** - Usually installed with Visual Studio or Android Studio

## Building iOS Packages

The iOS build script will:

1. Initialize git submodules
2. Build XCFrameworks using Carthage (15-20 minutes)
3. Build with .NET SDK 8 for net8.0-ios
4. Build with .NET SDK 9+ for net9.0-ios and net10.0-ios
5. Combine all target frameworks into unified packages

### Usage

```bash
# Build to default directory (./local-packages)
./build-local-ios-packages.sh

# Build to custom directory
./build-local-ios-packages.sh ./my-packages
```

### What Gets Built

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

Each package contains binaries for:

- `net8.0-ios` (iOS 17.0+)
- `net9.0-ios` (iOS 17.0+)
- `net10.0-ios` (iOS 17.0+)

## Building Android Packages

The Android build script will:

1. Initialize git submodules
2. Build with .NET SDK 9 for net9.0-android
3. Build with .NET SDK 10 for net10.0-android
4. Combine all target frameworks into unified packages

### Usage

```bash
# Build to default directory (./local-packages)
./build-local-android-packages.sh

# Build to custom directory
./build-local-android-packages.sh ./my-packages
```

### What Gets Built

- `Bcr.Datadog.Android.Core.{version}.nupkg`
- `Bcr.Datadog.Android.Logs.{version}.nupkg`
- `Bcr.Datadog.Android.Trace.{version}.nupkg`
- `Bcr.Datadog.Android.RUM.{version}.nupkg`
- `Bcr.Datadog.Android.SR.{version}.nupkg` (Session Replay)
- `Bcr.Datadog.Android.Web.{version}.nupkg` (WebView Tracking)
- `Bcr.Datadog.Android.OTel.{version}.nupkg` (OpenTelemetry)

Each package contains binaries for:

- `net9.0-android` (Android API 26+)
- `net10.0-android` (Android API 26+, ⭐ recommended for 16KB page size support)

## Using Locally Built Packages

After building packages, you can use them in your projects:

### 1. Add Local Package Source

```bash
# For iOS packages
dotnet nuget add source /absolute/path/to/local-packages --name local-datadog-ios

# For Android packages
dotnet nuget add source /absolute/path/to/local-packages --name local-datadog-android
```

### 2. Install Packages

```bash
# Install specific package
dotnet add package Bcr.Datadog.iOS.Core
dotnet add package Bcr.Datadog.Android.Core

# Or install with specific version
dotnet add package Bcr.Datadog.iOS.RUM --version 2.26.0
```

### 3. Remove Local Source (When Done Testing)

```bash
dotnet nuget remove source local-datadog-ios
dotnet nuget remove source local-datadog-android
```

## Troubleshooting

### iOS Build Issues

**XCFrameworks not found:**

```bash
# Ensure submodules are initialized
git submodule update --init --recursive

# Rebuild XCFrameworks manually
./src/iOS/buildxcframework.sh
```

**Multiple .NET SDK versions required:**

```bash
# Check installed SDKs
dotnet --list-sdks

# You need both 8.0.x AND (9.0.x OR 10.0.x)
```

**Carthage build fails:**

```bash
# Update Carthage
brew upgrade carthage

# Clean Carthage cache
rm -rf ~/Library/Caches/org.carthage.CarthageKit
rm -rf dd-sdk-ios/Carthage
```

### Android Build Issues

**Multiple .NET SDK versions required:**

```bash
# Check installed SDKs
dotnet --list-sdks

# You need both 9.0.x AND 10.0.x
```

**Java version:**

```bash
# Check Java version (must be 17+)
java -version

# Set JAVA_HOME if needed
export JAVA_HOME=$(/usr/libexec/java_home -v 17)
```

**Android SDK not found:**

```bash
# Install Android workload
dotnet workload install android

# Or install Android Studio which includes the SDK
```

## Build Times

- **iOS**: 20-30 minutes (first time), 5-10 minutes (with cached Carthage builds)
- **Android**: 5-10 minutes

## Cleaning Up

```bash
# Remove built packages
rm -rf ./local-packages

# Clean build artifacts
dotnet clean src/iOS/iOSDatadogBindings.sln
dotnet clean src/Android/AndroidDatadogBindings.sln

# Remove XCFrameworks (will be rebuilt on next iOS build)
rm -rf src/iOS/Bindings/Libs/*.xcframework
```

## CI/CD vs Local Builds

- **CI/CD workflows** (`.github/workflows/`) use optimized caching and split builds for faster execution
- **Local scripts** are simpler and build everything sequentially for easier debugging
- Both produce identical NuGet packages with all target frameworks
