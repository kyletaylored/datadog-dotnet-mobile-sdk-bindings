# .NET Bindings for the Datadog Mobile SDKs

Unofficial .NET bindings for the **Datadog Mobile SDKs** on **Android** and **iOS**, enabling Real User Monitoring (RUM), Logging, Tracing, and Session Replay in:

- .NET for Android
- .NET for iOS
- .NET MAUI (via platform-specific initialization)

---

## Documentation

### For Users
- **[Getting Started Guide](GETTING_STARTED.md)** - Detailed setup, examples, and API usage

### For Contributors
- **[Quick Start](QUICK_START.md)** - Quick reference for common development tasks
- **[SDK Update Guide](SDK_UPDATE_GUIDE.md)** - How to update Datadog SDK versions
- **[Building & Versioning Guide](BUILDING_AND_VERSIONING.md)** - Build from source and version updates
- **[Local Package Building](LOCAL_BUILD_README.md)** - Generate NuGet packages locally for development
- **[Release Process Guide](RELEASE_PROCESS.md)** - Publishing new versions to NuGet.org

> 💡 **Tip**: Use `make help` to see all available build commands

### Platform-Specific Documentation

- **[iOS Documentation](src/iOS/)** - iOS-specific implementation details
- **[Android Documentation](src/Android/)** - Android-specific implementation details

---

## Quick Start

### Installation

Install via NuGet Package Manager or add to your `.csproj`:

#### Android Packages

```xml
<!-- Core SDK (required) -->
<PackageReference Include="Bcr.Datadog.Android" Version="3.4.0" />

<!-- Feature packages (install as needed) -->
<PackageReference Include="Bcr.Datadog.Android" Version="3.4.0" />
<PackageReference Include="Bcr.Datadog.Android" Version="3.4.0" />
<PackageReference Include="Bcr.Datadog.Android" Version="3.4.0" />
<PackageReference Include="Bcr.Datadog.Android" Version="3.4.0" />
<PackageReference Include="Bcr.Datadog.Android" Version="3.4.0" />
<PackageReference Include="Bcr.Datadog.Android" Version="3.4.0" />
<PackageReference Include="Bcr.Datadog.Android" Version="3.4.0" />
```

#### iOS Packages

```xml
<!-- Core SDK with Logs, RUM, and Trace (required) -->
<PackageReference Include="Bcr.Datadog.iOS" Version="3.4.0" />

<!-- Additional feature packages (install as needed) -->
<PackageReference Include="Bcr.Datadog.iOS" Version="3.4.0" />   <!-- Crash Reporting -->
<PackageReference Include="Bcr.Datadog.iOS" Version="3.4.0" />   <!-- Session Replay -->
<PackageReference Include="Bcr.Datadog.iOS" Version="3.4.0" />  <!-- WebView Tracking -->
```

> 💡 **Note**: Both platforms support multiple target frameworks:
> - **Android**: `net9.0-android`, `net10.0-android` (⭐ `net10.0-android` recommended for 16KB page size support)
> - **iOS**: `net8.0-ios`, `net9.0-ios`, `net10.0-ios`

See [GETTING_STARTED.md](GETTING_STARTED.md) for complete initialization examples and API usage.

---

## Features

| Feature              | Android Package                     | iOS Package            | Description                                       |
| -------------------- | ----------------------------------- | ---------------------- | ------------------------------------------------- |
| **Core**             | `Bcr.Datadog.Android.Core`          | `Bcr.Datadog.iOS.ObjC` | Required base SDK (iOS includes Logs, RUM, Trace) |
| **Logs**             | `Bcr.Datadog.Android.Logs`          | _(included in ObjC)_   | Log collection and forwarding                     |
| **RUM**              | `Bcr.Datadog.Android.Rum`           | _(included in ObjC)_   | Real User Monitoring                              |
| **Trace**            | `Bcr.Datadog.Android.Trace`         | _(included in ObjC)_   | APM and distributed tracing                       |
| **Session Replay**   | `Bcr.Datadog.Android.SessionReplay` | `Bcr.Datadog.iOS.SR`   | User session recording                            |
| **WebView Tracking** | `Bcr.Datadog.Android.WebView`       | `Bcr.Datadog.iOS.Web`  | WebView instrumentation                           |
| **Crash Reporting**  | `Bcr.Datadog.Android.Ndk`           | `Bcr.Datadog.iOS.CR`   | Native crash detection                            |
| **OpenTelemetry**    | `Bcr.Datadog.Android.Trace.Otel`    | `Bcr.Otel.Api.iOS`     | OTel integration                                  |

### Official Feature Documentation

- **Logs**: [Android](https://docs.datadoghq.com/logs/log_collection/android/) | [iOS](https://docs.datadoghq.com/logs/log_collection/ios/)
- **RUM**: [Android](https://docs.datadoghq.com/real_user_monitoring/android/) | [iOS](https://docs.datadoghq.com/real_user_monitoring/ios/)
- **Trace**: [Android](https://docs.datadoghq.com/tracing/trace_collection/automatic_instrumentation/dd_libraries/android/) | [iOS](https://docs.datadoghq.com/tracing/trace_collection/automatic_instrumentation/dd_libraries/ios/)
- **Session Replay**: [Mobile Setup](https://docs.datadoghq.com/real_user_monitoring/session_replay/mobile/setup_and_configuration/)
- **WebView Tracking**: [Mobile WebView](https://docs.datadoghq.com/real_user_monitoring/mobile_and_tv_monitoring/web_view_tracking/)

---

## Requirements

### .NET SDK

- **.NET 8, 9, or 10**
  - **Android**: .NET 9 or 10 (supports `net9.0-android`, `net10.0-android`)
    - ⚠️ **Note**: `net10.0-android` recommended for 16KB page size support (Google Play requirement as of November 2025)
  - **iOS**: .NET 8, 9, or 10 (supports `net8.0-ios`, `net9.0-ios`, `net10.0-ios`)

### Android

- **Android API Level 26+** (Android 8.0 Oreo)
- Java SDK configured (`JAVA_HOME`)
- Android SDK

### iOS

- **iOS 17.0+**
- **Xcode 16.1** or later
- macOS development environment

---

## Development & Building

### Building Packages Locally

To build NuGet packages locally for development or testing:

```bash
# Build iOS packages (macOS only)
./build-local-ios-packages.sh [output-directory]

# Build Android packages (any platform)
./build-local-android-packages.sh [output-directory]
```

See **[LOCAL_BUILD_README.md](LOCAL_BUILD_README.md)** for detailed instructions, prerequisites, and troubleshooting.

### Building from Source

For contributors or those updating to new Datadog SDK versions:

**[BUILDING_AND_VERSIONING.md](BUILDING_AND_VERSIONING.md)**

This comprehensive guide covers:

- Building native Android AARs
- Building iOS XCFrameworks
- Generating C# bindings
- Version update procedures
- Publishing workflows

---

## Working Examples

Real-world sample applications demonstrating initialization and usage:

- **Android Sample**: [src/Android/Bindings/Test/TestBindings/](src/Android/Bindings/Test/TestBindings/)
- **iOS Sample**: [src/iOS/T/](src/iOS/T/)

---

## What Are These Bindings?

These are **binding layers** that expose the native Datadog Android (Java/Kotlin) and iOS (Objective-C/Swift) SDK APIs directly to C#. They are **not wrapper SDKs** - they provide 1:1 API mappings to the native SDKs.

### IntelliSense Support

- **iOS**: ✅ Full IntelliSense documentation available
- **Android**: ⚠️ Limited IntelliSense; refer to [Android SDK documentation](https://github.com/DataDog/dd-sdk-android)

### Binding Layer Constraints

- These are **bindings, not wrappers**
- APIs closely mirror native SDK naming and structure
- Platform-specific types remain exposed (`Context`, `Activity`, `UIApplication`, etc.)
- Refer to official Datadog documentation for detailed API behavior

---

## Versioning

Binding versions mirror the native SDK versions:

- Version `2.26.0` binds version `2.26.0` of the native SDK
- Pre-release tags like `2.21.0` indicate preview versions
- The revision number is incremented for binding-specific updates

See [BUILDING_AND_VERSIONING.md](BUILDING_AND_VERSIONING.md) for the complete versioning strategy.

---

## Important Notes

### For .NET MAUI Developers

- **No cross-platform abstraction**: Initialize in platform-specific entry points
- **Use conditional compilation**: `#if ANDROID` / `#if IOS`
- **Platform lifecycle matters**:
  - Android: Initialize in `MainActivity.OnCreate`
  - iOS: Initialize in `AppDelegate.FinishedLaunching`

### Multi-Framework Support

Both Android and iOS packages support multiple .NET versions:

**iOS Packages:**
- `net8.0-ios` - For .NET 8 projects
- `net9.0-ios` - For .NET 9 projects
- `net10.0-ios` - For .NET 10 projects

All frameworks target iOS 17.0+ and are included in a single NuGet package.

**Android Packages:**
- `net9.0-android` - For .NET 9 projects
- `net10.0-android` - For .NET 10 projects (⭐ **Recommended**)

All frameworks target Android API 26+ and are included in a single NuGet package. `net10.0-android` is recommended for 16KB page size support (Google Play requirement as of November 2025).

---

## Related Resources

### Native SDK Repositories

- [Datadog iOS SDK](https://github.com/DataDog/dd-sdk-ios)
- [Datadog Android SDK](https://github.com/DataDog/dd-sdk-android)

### Official Documentation

- [Datadog Documentation](https://docs.datadoghq.com/)
- [Mobile RUM Overview](https://docs.datadoghq.com/real_user_monitoring/mobile_and_tv_monitoring/)
- [Datadog Support](https://www.datadoghq.com/support/)

---

## Support

This repository provides bindings only. For SDK usage, features, and troubleshooting:

- Refer to [Official Datadog Documentation](https://docs.datadoghq.com/)
- See [Datadog Support](https://www.datadoghq.com/support/)

For binding-specific issues (compilation errors, missing APIs, platform-specific problems), please open an issue in this repository.

---

## License

This repository is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

### NOTICE

This repository includes software developed at Datadog (https://www.datadoghq.com/), which is licensed under the [Apache License 2.0](https://www.apache.org/licenses/LICENSE-2.0).

Those portions are Copyright 2019 Datadog, Inc.

For more information, please refer to the [Datadog Android SDK repository](https://github.com/DataDog/dd-sdk-android) or the [Datadog iOS SDK repository](https://github.com/DataDog/dd-sdk-ios).
