# Android Binding Dependencies

This document explains how Android binding dependencies work and how to maintain them.

> 💡 **For Technical Details**: See [Android Bindings Internals](ANDROID_BINDINGS_INTERNALS.md) for a comprehensive technical reference on how Android bindings work, including Metadata.xml transformations and the JNI bridge.

## Overview

Android bindings require **NuGet package references** for Java/Android libraries that the Datadog SDK depends on. These are Xamarin bindings of the native Java/Android libraries.

## Why Android Needs Dependencies But iOS Doesn't

| Platform | Approach | Dependencies |
|----------|----------|--------------|
| **Android** | Modular (separate AARs) | External NuGet packages required |
| **iOS** | Monolithic (XCFrameworks) | Self-contained (all code embedded) |

- **Android SDK** references separate Java libraries (Gson, OkHttp, etc.) as individual JAR/AAR files
- **iOS SDK** statically links all dependencies into the XCFramework - it's completely self-contained

## Dependency Mapping

### How to Find the Correct NuGet Version

1. **Check Gradle version catalog** in `dd-sdk-android/gradle/libs.versions.toml`:
   ```toml
   [versions]
   gson = "2.10.1"
   okHttp = "4.12.0"
   ```

2. **Search NuGet.org** for the corresponding Xamarin binding:
   - Go to [https://www.nuget.org/packages](https://www.nuget.org/packages)
   - Search for the library name (e.g., "gson", "okhttp")
   - Find the package with matching major.minor.patch version

3. **Version matching rules**:
   - **Major.Minor.Patch** must match the Java version exactly
   - **Fourth number** (e.g., `2.10.1.11`) is the binding revision - choose the latest available

### Current Dependency Map

Based on Datadog Android SDK version **3.4.0**:

| Java/Android Library | Gradle Version | Maven Artifact | NuGet Package | NuGet Version | Used In |
|---------------------|----------------|----------------|---------------|---------------|---------|
| **Gson** | 2.10.1 | `com.google.code.gson:gson` | `GoogleGson` | 2.10.1.11 | Core |
| **OkHttp3** | 4.12.0 | `com.squareup.okhttp3:okhttp` | `Square.OkHttp3` | 4.12.0 | Core |
| **Kronos NTP** | 0.0.1-alpha11 | `com.lyft.kronos:kronos-android` | *(embedded in AAR)* | N/A | Core |
| **AndroidX Work Runtime** | 2.8.1 | `androidx.work:work-runtime` | `Xamarin.AndroidX.Work.Runtime` | 2.8.1 | Core |
| **AndroidX Collection** | 1.4.5 | `androidx.collection:collection` | `Xamarin.AndroidX.Collection` | 1.4.5.2 | Various |
| **AndroidX Lifecycle** | 2.8.7 | `androidx.lifecycle:lifecycle-*` | `Xamarin.AndroidX.Lifecycle.*` | 2.8.7.2 | Various |

## How to Determine What Dependencies Are Required

### Method 1: Check Gradle Build Files (Recommended)

Look at the SDK's Gradle dependencies:

```bash
# View Core module dependencies
cat dd-sdk-android/dd-sdk-android-core/build.gradle.kts

# Check version catalog
cat dd-sdk-android/gradle/libs.versions.toml
```

### Method 2: Build and Fix Errors

Remove a PackageReference and try building:

```bash
dotnet build src/Android/Bindings/Core/Core.csproj
```

If you get errors like:
```
error : Java type 'com.google.gson.Gson' not found
```

Then you need a binding for that Java type.

### Method 3: Inspect AAR Dependencies

AARs declare their dependencies in their POM files on Maven Central:

```bash
# View POM for dd-sdk-android-core
curl https://repo1.maven.org/maven2/com/datadog/android/dd-sdk-android-core/3.4.0/dd-sdk-android-core-3.4.0.pom
```

## Updating Dependencies

When updating to a new Datadog SDK version:

1. **Check for version changes** in `dd-sdk-android/gradle/libs.versions.toml`
2. **Search NuGet.org** for updated binding versions
3. **Update `.csproj` files** with new PackageReference versions
4. **Test the build** to ensure compatibility

### Example: Updating Gson

```xml
<!-- Before -->
<PackageReference Include="GoogleGson" Version="2.10.1.11" />

<!-- After (if Datadog updates to gson 2.11.0) -->
<PackageReference Include="GoogleGson" Version="2.11.0.x" />
```

## Special Cases

### Kronos NTP (Alpha Version)

```xml
<AndroidLibrary Update="aars\kronos-android-0.0.1-alpha11.aar" Bind="false" />
<AndroidLibrary Update="aars\kronos-java-0.0.1-alpha11.jar" Bind="false" />
```

- **Why alpha?** This is the actual version Datadog SDK uses
- **Bind="false"** means we include it but don't generate C# bindings for it
- It's marked `Bind="false"` because it's a transitive dependency - Datadog SDK uses it internally

### AndroidX Dependencies

AndroidX libraries have a **fourth version number** (e.g., `2.8.7.2`) which is the Xamarin binding revision:

```xml
<!-- Java version: 2.8.7 -->
<!-- Xamarin binding: 2.8.7.2 (revision 2) -->
<PackageReference Include="Xamarin.AndroidX.Lifecycle.Common" Version="2.8.7.2" />
```

## AAR Files

AAR (Android Archive) and JAR (Java Archive) files contain the compiled native Android code that we create C# bindings for. These files are the **input** to the binding process, and get embedded in the final NuGet packages.

### Complete Build Flow

```
Phase 1: Get AAR/JAR files (native Android libraries)
  ↓
Phase 2: Build NuGet packages (C# bindings + embedded AARs)
  ↓
Phase 3: Publish to NuGet.org (for .NET developers to consume)
```

### Where AARs Come From

You have two options:

#### Option 1: Smart Setup from Maven Central (Recommended)

**Prerequisites:**
- yq (YAML processor) - Install via: `brew install yq` (macOS) or `snap install yq` (Linux)
- See [Developer Setup Guide](DEVELOPER_SETUP.md) for complete environment setup

```bash
# Intelligent AAR/JAR setup with automatic dependency resolution
./src/Android/setup-aars.sh [version]
```

**What it does:**
- Reads POM files from Maven Central to discover dependencies automatically
- Downloads Datadog SDK AARs for all modules
- Uses `src/Android/dependencies.yaml` (parsed with yq) to determine which dependencies to download
- Downloads only required third-party dependencies (JARs/AARs without NuGet equivalents)
- Recognizes dependencies with existing NuGet bindings (Gson, OkHttp, AndroidX)
- Skips embedded dependencies (Kotlin stdlib) and internal cross-references

**Pros:**
- Fast (no build required)
- No Android NDK or Gradle setup needed
- Automatically handles transitive dependencies
- Works in CI/CD easily
- Intelligent filtering prevents unnecessary downloads

**Cons:**
- Requires internet connection
- Dependency on Maven Central availability

#### Option 2: Build from Source

```bash
# Build AARs from dd-sdk-android submodule
./src/Android/build-aars.sh
./src/Android/copy-aars.sh
```

**Pros:**
- Works offline (once submodule is cloned)
- Can build unreleased versions
- Full control over build process

**Cons:**
- Requires Android NDK and Gradle setup
- Slower (15-20 minutes)
- Requires more disk space

### AAR Files Are Not Committed to Git

AAR and JAR files are excluded from git via `.gitignore`:

```gitignore
# Android AAR/JAR files (build artifacts - downloaded from Maven or built from dd-sdk-android submodule)
**/aars/*.aar
**/aars/*.jar
```

**Why?**
- Binary files bloat git repository
- AARs can be regenerated from source or downloaded
- Reduces git clone size and speed

**How to get AARs:**
1. Run `./src/Android/setup-aars.sh` (recommended - smart dependency resolution)
2. Or run `make build-android-aars` (builds from source)

### Dependency Configuration File

The `src/Android/dependencies.yaml` file controls which dependencies are downloaded vs referenced via NuGet. It uses YAML format with logical grouping by purpose and rich inline comments.

**Format:**
```yaml
download:
  # Comment explaining this dependency
  - groupId: ...
    artifactId: ...

nuget:
  - groupId: ...
    artifactId: ...
    nugetPackage: ...

skip:
  - groupId: ...
    artifactId: ...
    reason: ...
```

**Sections:**
- **`download`**: Dependencies to download as AAR/JAR (no NuGet binding available)
- **`nuget`**: Dependencies available as NuGet packages (reference via PackageReference)
- **`skip`**: Dependencies to skip (embedded, internal, or covered by other packages)

**Example entries:**
```yaml
download:
  # Lyft Kronos - NTP time synchronization
  - groupId: com.lyft.kronos
    artifactId: kronos-android

  # OpenTelemetry - Java API (not .NET)
  # Note: This is the Java OpenTelemetry API needed for trace-otel bindings,
  # NOT the .NET OpenTelemetry.Api NuGet package
  - groupId: io.opentelemetry
    artifactId: opentelemetry-api

nuget:
  # Google libraries
  - groupId: com.google.code.gson
    artifactId: gson
    nugetPackage: GoogleGson

skip:
  # AndroidX Core & UI (transitive from Material/Navigation)
  - groupId: androidx.core
    artifactId: core
    reason: Transitive from Material/Navigation packages in MAUI Core
```

**To add a new dependency:**
1. Add an entry to the appropriate section in `dependencies.yaml`
2. Run `./src/Android/setup-aars.sh` to download (if in `download` section)
3. Add `<PackageReference>` to `.csproj` files (if in `nuget` section)

### How the Script Works

The `setup-aars.sh` script uses a **two-phase approach**:

**Phase 1: Discover dependencies from POM files (with versions)**
```bash
# For each Datadog module (e.g., dd-sdk-android-core):
1. Download POM from Maven Central
   URL: https://repo1.maven.org/.../dd-sdk-android-core/3.4.0/dd-sdk-android-core-3.4.0.pom

2. Parse POM XML to extract all compile/runtime dependencies WITH versions
   Example: "com.google.code.gson:gson:2.10.1"
                                         ↑
                                    Version from POM
```

**Phase 2: Match against dependencies.json (without versions)**
```bash
# For each dependency found in POM:
3. Look up in dependencies.json using ONLY groupId:artifactId
   Searching for: { "groupId": "com.google.code.gson", "artifactId": "gson" }

4. Find in "nuget" section:
   {
     "groupId": "com.google.code.gson",
     "artifactId": "gson",
     "nugetPackage": "GoogleGson"
   }

5. Take action based on which section it's in:
   - "download" section: Download JAR/AAR using VERSION from POM (Step 2)
   - "nuget" section: Print "using NuGet binding"
   - "skip" section: Do nothing
   - Not found: Default to skip
```

**Key insight**: `dependencies.json` does NOT store versions. Versions come dynamically from POM files. This means when Datadog updates a dependency version (e.g., gson 2.10.1 → 2.11.0), the script automatically downloads the new version without config changes.

**Example flow:**
```
POM says: gson:2.10.1
JSON says: In "nuget" section with "nugetPackage": "GoogleGson"
Result: Skip download, assume .csproj has <PackageReference Include="GoogleGson" />

POM says: kronos-android:0.0.1-alpha11
JSON says: In "download" section
Result: Download kronos-android-0.0.1-alpha11.aar from Maven Central
```

## Troubleshooting

### Missing Dependency Errors

**Error:**
```
error : Java type 'com.example.SomeClass' not found
```

**Solution:**
1. Find which Java library provides that class
2. Search NuGet.org for a Xamarin binding
3. Add PackageReference to the `.csproj` file

### Version Mismatch Errors

**Error:**
```
error : Package 'GoogleGson' requires 'com.google.code.gson:gson' version '2.10.1' but found '2.9.0'
```

**Solution:**
- Update the NuGet package version to match the required Java version
- Check `dd-sdk-android/gradle/libs.versions.toml` for the correct version

### Missing AAR Files

**Error:**
```
error : Cannot find AAR file: aars/dd-sdk-android-core-release.aar
```

**Solution:**
```bash
# Setup AARs with automatic dependency resolution
./src/Android/setup-aars.sh

# Or build from source
./src/Android/build-aars.sh
./src/Android/copy-aars.sh
```

## Resources

- [NuGet Package Search](https://www.nuget.org/packages)
- [Maven Central Repository](https://repo1.maven.org/maven2/)
- [Xamarin.AndroidX Packages](https://www.nuget.org/packages?q=Xamarin.AndroidX)
- [Datadog Android SDK Repository](https://github.com/DataDog/dd-sdk-android)
- [Gradle Version Catalogs](https://docs.gradle.org/current/userguide/platforms.html)
