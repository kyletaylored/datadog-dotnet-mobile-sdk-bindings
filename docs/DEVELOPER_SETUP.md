# Developer Setup Guide

This guide covers setting up your development environment for contributing to the Datadog .NET Mobile SDK Bindings.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Initial Setup](#initial-setup)
- [Android Development Setup](#android-development-setup)
- [iOS Development Setup](#ios-development-setup)
- [IDE Configuration](#ide-configuration)
- [Verification](#verification)

---

## Prerequisites

### Required Tools

| Tool | Version | Purpose |
|------|---------|---------|
| **Git** | Latest | Source control |
| **.NET SDK** | 8.x, 9.x, 10.x | Build system (all three recommended) |
| **yq** | Latest | YAML processing for dependency management |

### Platform-Specific Requirements

**macOS (iOS development):**
- Xcode 26.2 (for .NET 10) or 16.1+ (for .NET 8/9)
- Command Line Tools: `xcode-select --install`

**Any Platform (Android development):**
- Java JDK 17+
- Android SDK (via Android Studio or command-line tools)

---

## Initial Setup

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/datadog-dotnet-mobile-sdk-bindings.git
cd datadog-dotnet-mobile-sdk-bindings
```

### 2. Initialize Submodules

The repository includes the native Datadog SDKs as submodules:

```bash
git submodule update --init --recursive
```

This downloads:
- `dd-sdk-android` - Native Android SDK source
- `dd-sdk-ios` - Native iOS SDK source

### 3. Install yq (YAML Processor)

yq is used for YAML processing in dependency resolution scripts:

**macOS:**
```bash
brew install yq
```

**Linux:**
```bash
snap install yq
```

**Or download binary:**
Visit [yq releases](https://github.com/mikefarah/yq/releases) and download the appropriate binary for your platform.

**Verify installation:**
```bash
yq --version
```

---

## Android Development Setup

### 1. Install Java JDK

**Required:** Java 17 or higher

**macOS (Homebrew):**
```bash
brew install openjdk@17
```

**Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install openjdk-17-jdk
```

**Windows:**
Download from [Adoptium](https://adoptium.net/) or [Microsoft Build of OpenJDK](https://www.microsoft.com/openjdk)

**Set JAVA_HOME:**
```bash
# macOS/Linux (add to ~/.bashrc or ~/.zshrc)
export JAVA_HOME=$(/usr/libexec/java_home -v 17)  # macOS
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64  # Linux

# Windows (PowerShell)
$env:JAVA_HOME = "C:\Program Files\Eclipse Adoptium\jdk-17.0.x-hotspot"
```

**Verify:**
```bash
java -version
# Should show version 17 or higher
```

### 2. Install Android SDK

**Option A: Via Android Studio (Recommended)**
1. Download [Android Studio](https://developer.android.com/studio)
2. Install Android SDK during setup
3. Set `ANDROID_HOME` environment variable

**Option B: Command-line Tools Only**
1. Download [Android Command Line Tools](https://developer.android.com/studio#command-tools)
2. Extract to a directory (e.g., `~/Android/cmdline-tools/latest`)
3. Install SDK components:
   ```bash
   sdkmanager "platforms;android-34" "build-tools;34.0.0" "platform-tools"
   ```

**Set ANDROID_HOME:**
```bash
# macOS/Linux (add to ~/.bashrc or ~/.zshrc)
export ANDROID_HOME=$HOME/Library/Android/sdk  # macOS
export ANDROID_HOME=$HOME/Android/Sdk  # Linux

# Windows (PowerShell)
$env:ANDROID_HOME = "$env:LOCALAPPDATA\Android\Sdk"
```

### 3. Install .NET Android Workload

```bash
dotnet workload install android
```

### 4. Download Android Dependencies

The Android bindings require AAR/JAR files from Maven Central:

```bash
# From repository root
./src/Android/setup-aars.sh
```

**What this does:**
- Downloads Datadog Android SDK AARs for all modules
- Reads POM files to discover dependencies
- Downloads required third-party dependencies based on `src/Android/dependencies.yaml`
- Uses yq to parse the YAML configuration

See [ANDROID_DEPENDENCIES.md](ANDROID_DEPENDENCIES.md) for detailed information about dependency management.

### 5. Build Android Bindings

```bash
dotnet build src/Android/AndroidDatadogBindings.sln --configuration Release
```

---

## iOS Development Setup

**Prerequisites:** macOS only (iOS development requires Xcode)

### 1. Install Xcode

**For .NET 10:**
- Install Xcode 26.2 from the Mac App Store or [Apple Developer Downloads](https://developer.apple.com/download/)

**For .NET 8/9:**
- Install Xcode 16.1+ from the Mac App Store

**Verify installation:**
```bash
xcode-select -p
# Should output: /Applications/Xcode.app/Contents/Developer
```

**Accept license:**
```bash
sudo xcodebuild -license accept
```

### 2. Install .NET iOS Workload

```bash
# For .NET 10
dotnet workload install ios

# For .NET 8/9 (if using older .NET versions)
dotnet workload install ios-net8  # or ios-net9
```

### 3. Download iOS XCFrameworks

The iOS bindings require XCFrameworks from Datadog:

```bash
# From repository root
./src/iOS/setup-xcframeworks.sh
```

**What this does:**
- Downloads pre-built XCFrameworks from Datadog's GitHub releases
- Extracts them to `src/iOS/Bindings/Libs/`
- Renames them to match binding project expectations

### 4. Build iOS Bindings

```bash
dotnet build src/iOS/iOSDatadogBindings.sln --configuration Release
```

---

## IDE Configuration

### Visual Studio Code

See [VSCODE_SETUP.md](VSCODE_SETUP.md) for complete VS Code configuration including:
- Required extensions
- IntelliSense configuration
- OmniSharp settings
- Debugging setup

### Visual Studio (Windows)

1. Install [Visual Studio 2022](https://visualstudio.microsoft.com/)
2. Select workloads:
   - **.NET Multi-platform App UI development**
   - **Mobile development with .NET**
3. Open `AndroidDatadogBindings.sln` for Android development

### Visual Studio for Mac

1. Install [Visual Studio for Mac](https://visualstudio.microsoft.com/vs/mac/)
2. Open `iOSDatadogBindings.sln` for iOS development
3. Open `AndroidDatadogBindings.sln` for Android development

---

## Verification

### Verify Android Setup

```bash
# Check Java
java -version
# Expected: openjdk version "17.x.x" or higher

# Check Android SDK
echo $ANDROID_HOME
# Expected: Path to Android SDK directory

# Check .NET Android workload
dotnet workload list
# Expected: Should show "android" as installed

# Check yq
yq --version
# Expected: yq (https://github.com/mikefarah/yq/) version 4.x or higher

# Build test
cd src/Android
dotnet build AndroidDatadogBindings.sln --configuration Release
```

### Verify iOS Setup (macOS only)

```bash
# Check Xcode
xcodebuild -version
# Expected: Xcode 26.2 (for .NET 10) or 16.1+ (for .NET 8/9)

# Check .NET iOS workload
dotnet workload list
# Expected: Should show "ios" as installed

# Build test
cd src/iOS
dotnet build iOSDatadogBindings.sln --configuration Release
```

---

## Next Steps

Once your environment is set up:

1. **Explore the codebase:**
   - [Android Bindings](../src/Android/Bindings/)
   - [iOS Bindings](../src/iOS/Bindings/)

2. **Review developer guides:**
   - [Quick Start](QUICK_START.md) - Common development tasks
   - [Building & Versioning](BUILDING_AND_VERSIONING.md) - Build from source, update SDK versions
   - [Android Dependencies](ANDROID_DEPENDENCIES.md) - Understanding Android dependency management

3. **Try building locally:**
   ```bash
   # Android packages
   ./scripts/build-local-android-packages.sh

   # iOS packages (macOS only)
   ./scripts/build-local-ios-packages.sh
   ```

4. **Run test apps:**
   - Android: [src/Android/Test/TestApp/](../src/Android/Test/TestApp/)
   - iOS: [src/iOS/Test/](../src/iOS/Test/)

---

## Troubleshooting

### yq Installation Issues

**Problem:** `yq: command not found`

**Solution:**
```bash
# macOS
brew install yq

# Linux
snap install yq

# Or download from https://github.com/mikefarah/yq/releases
```

### Android AAR Download Failures

**Problem:** `setup-aars.sh` fails with network errors

**Solution:**
1. Check internet connection
2. Verify Maven Central is accessible: `curl -I https://repo1.maven.org/maven2/`
3. Try downloading specific version: `./src/Android/setup-aars.sh 3.4.0`

### .NET Workload Installation Issues

**Problem:** `dotnet workload install` fails

**Solution:**
```bash
# Clear workload cache
dotnet workload clean

# Try installing again
dotnet workload install android  # or ios
```

### Xcode Command Line Tools Issues

**Problem:** Xcode tools not found

**Solution:**
```bash
# Install command line tools
xcode-select --install

# Reset to Xcode
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer

# Verify
xcodebuild -version
```

---

## Environment Variables Summary

Add these to your shell profile (`~/.bashrc`, `~/.zshrc`, or equivalent):

```bash
# Java (Android)
export JAVA_HOME=$(/usr/libexec/java_home -v 17)  # macOS
# OR
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64  # Linux

# Android SDK
export ANDROID_HOME=$HOME/Library/Android/sdk  # macOS
# OR
export ANDROID_HOME=$HOME/Android/Sdk  # Linux

# PATH additions
export PATH=$JAVA_HOME/bin:$PATH
export PATH=$ANDROID_HOME/platform-tools:$PATH
export PATH=$ANDROID_HOME/cmdline-tools/latest/bin:$PATH
```

---

## Additional Resources

### Getting Started
- [Quick Start Guide](QUICK_START.md)
- [Building & Versioning Guide](BUILDING_AND_VERSIONING.md)
- [VS Code Setup Guide](VSCODE_SETUP.md)
- [CI Local Testing](CI_LOCAL_TESTING.md)

### Platform-Specific Guides
- [Android Bindings Internals](ANDROID_BINDINGS_INTERNALS.md) - How Android bindings work (Metadata.xml, Additions, JNI)
- [iOS Bindings Internals](IOS_BINDINGS_INTERNALS.md) - How iOS bindings work (ApiDefinitions, Objective-C runtime)
- [Android Dependencies Documentation](ANDROID_DEPENDENCIES.md) - Managing AAR/JAR dependencies with yq

### Troubleshooting
- [Troubleshooting Binding Errors](TROUBLESHOOTING_BINDING_ERRORS.md)
