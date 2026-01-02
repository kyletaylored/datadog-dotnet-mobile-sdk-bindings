# .NET Bindings for the Datadog Mobile SDKs

Unofficial .NET bindings for the **Datadog Mobile SDKs** on **Android** and **iOS**, enabling Real User Monitoring (RUM), Logging, Tracing, and Session Replay in:

- .NET for Android
- .NET for iOS
- .NET MAUI (via platform-specific initialization)

## What Are These Bindings?

These are **binding layers** that expose the native Datadog Android (Java/Kotlin) and iOS (Objective-C/Swift) SDK APIs directly to C#. They are **not wrapper SDKs** - they provide 1:1 API mappings to the native SDKs.

For more information about the underlying SDKs:

- [Datadog iOS SDK Repository](https://github.com/DataDog/dd-sdk-ios)
- [Datadog Android SDK Repository](https://github.com/DataDog/dd-sdk-android)
- [Datadog Documentation](https://docs.datadoghq.com/)

## Requirements

### .NET

- **.NET 10** (required for Android due to 16KB page size and binding fixes)
- .NET 8 or 9 may work for iOS

### Android

- Android API Level **26+** (Android 8.0 Oreo)
- Java SDK configured (`JAVA_HOME`)

### iOS

- iOS **17.0+**
- Xcode with command line tools
- macOS development environment

## Quick Start

### Installation

Install the NuGet packages you need for your platform and features:

#### Android Packages

```xml
<!-- Core SDK (required) -->
<PackageReference Include="Bcr.Datadog.Android.Sdk.Core" Version="2.21.0-pre.1" />

<!-- Feature packages (install as needed) -->
<PackageReference Include="Bcr.Datadog.Android.Sdk.Logs" Version="2.21.0-pre.1" />
<PackageReference Include="Bcr.Datadog.Android.Sdk.Rum" Version="2.21.0-pre.1" />
<PackageReference Include="Bcr.Datadog.Android.Sdk.Trace" Version="2.21.0-pre.1" />
<PackageReference Include="Bcr.Datadog.Android.Sdk.SessionReplay" Version="2.21.0-pre.1" />
<PackageReference Include="Bcr.Datadog.Android.Sdk.WebView" Version="2.21.0-pre.1" />
<PackageReference Include="Bcr.Datadog.Android.Sdk.Ndk" Version="2.21.0-pre.1" />
<PackageReference Include="Bcr.Datadog.Android.Sdk.Trace.Otel" Version="2.21.0-pre.1" />
```

#### iOS Packages

```xml
<!-- Core SDK with Logs, RUM, and Trace (required) -->
<PackageReference Include="Bcr.Datadog.iOS.ObjC" Version="2.26.0" />

<!-- Additional feature packages (install as needed) -->
<PackageReference Include="Bcr.Datadog.iOS.CR" Version="2.26.0" />   <!-- Crash Reporting -->
<PackageReference Include="Bcr.Datadog.iOS.SR" Version="2.26.0" />   <!-- Session Replay -->
<PackageReference Include="Bcr.Datadog.iOS.Web" Version="2.26.0" />  <!-- WebView Tracking -->

<!-- Low-level framework bindings (typically not needed directly) -->
<PackageReference Include="Bcr.Datadog.iOS.Logs" Version="2.26.0" />  <!-- Used by ObjC -->
<PackageReference Include="Bcr.Datadog.iOS.RUM" Version="2.26.0" />   <!-- Used by ObjC -->
<PackageReference Include="Bcr.Datadog.iOS.Trace" Version="2.26.0" /> <!-- Used by ObjC -->
```

### Basic Initialization

#### Android (MainActivity.cs)

```csharp
using Datadog.Android.Core.Configuration;
using Datadog.Android.Log;
using Datadog.Android.Rum;
using Datadog.Android.Privacy;

[Activity(Label = "@string/app_name", MainLauncher = true)]
public class MainActivity : Activity
{
    protected override void OnCreate(Bundle? savedInstanceState)
    {
        base.OnCreate(savedInstanceState);

        // 1. Configure Datadog SDK
        var config = new DDConfiguration.Builder(
            clientToken: "<YOUR_CLIENT_TOKEN>",
            env: "prod",
            variantName: string.Empty,
            serviceName: "my-android-app"
        )
        .UseSite(DatadogSite.Us1) // US1, US3, US5, EU1, AP1, US1Fed, etc.
        .Build();

        // 2. Initialize Datadog (required before enabling features)
        Datadog.Android.Datadog.Initialize(this, config, TrackingConsent.Granted);
        Datadog.Android.Datadog.Verbosity = (int)Android.Util.LogPriority.Verbose;

        // 3. Enable Logs
        var logsConfig = new LogsConfiguration.Builder().Build();
        Logs.Enable(logsConfig);

        // 4. Enable RUM
        var rumConfig = new RumConfiguration.Builder("<YOUR_APPLICATION_ID>")
            .TrackLongTasks()
            .TrackFrustrations(true)
            .TrackBackgroundEvents(true)
            .Build();
        Datadog.Android.Rum.Rum.Enable(rumConfig);

        // 5. Create and use a logger
        var logger = new Logger.Builder()
            .SetName("MyLogger")
            .Build();

        logger.D("Application started", null, null);

        SetContentView(Resource.Layout.activity_main);
    }
}
```

#### iOS (AppDelegate.cs)

```csharp
using Datadog.iOS.ObjC;
using Datadog.iOS.CrashReporting;
using Datadog.iOS.SessionReplay;

[Register("AppDelegate")]
public class AppDelegate : UIApplicationDelegate
{
    public override bool FinishedLaunching(UIApplication application, NSDictionary launchOptions)
    {
        // 1. Configure Datadog SDK
        var config = new DDConfiguration(
            clientToken: "<YOUR_CLIENT_TOKEN>",
            env: "prod"
        );
        config.Service = "my-ios-app";
        config.Site = DDDatadogSite.Us1; // US1, US3, US5, EU1, AP1, etc.

        // 2. Initialize Datadog (required before enabling features)
        DDDatadog.Initialize(config, DDTrackingConsent.Granted);
        DDDatadog.VerbosityLevel = DDSDKVerbosityLevel.Debug;

        // 3. Enable Logs
        DDLogs.Enable(new DDLogsConfiguration(null));

        // 4. Enable RUM
        var rumConfig = new DDRUMConfiguration("<YOUR_APPLICATION_ID>");
        rumConfig.SessionSampleRate = 100f;
        DDRUM.Enable(rumConfig);

        // 5. Enable Crash Reporting (optional)
        DDCrashReporter.Enable();

        // 6. Create and use a logger
        var logConfig = new DDLoggerConfiguration();
        logConfig.Service = "my-ios-app";
        logConfig.PrintLogsToConsole = true;

        var logger = DDLogger.Create(logConfig);
        logger.Debug("Application started.");

        return true;
    }
}
```

#### .NET MAUI Usage

For MAUI apps, initialize in platform-specific entry points:

```csharp
// In Platforms/Android/MainActivity.cs
protected override void OnCreate(Bundle? savedInstanceState)
{
    #if ANDROID
    // Android initialization code here
    #endif
    base.OnCreate(savedInstanceState);
}

// In Platforms/iOS/AppDelegate.cs
public override bool FinishedLaunching(UIApplication application, NSDictionary launchOptions)
{
    #if IOS
    // iOS initialization code here
    #endif
    return base.FinishedLaunching(application, launchOptions);
}
```

## Features

These bindings provide access to all major Datadog Mobile SDK features:

| Feature              | Android Package                         | iOS Package                | Description                          |
| -------------------- | --------------------------------------- | -------------------------- | ------------------------------------ |
| **Core**             | `Bcr.Datadog.Android.Sdk.Core`          | `Bcr.Datadog.iOS.ObjC`     | Required base SDK (iOS includes Logs, RUM, Trace) |
| **Logs**             | `Bcr.Datadog.Android.Sdk.Logs`          | _(included in ObjC)_       | Log collection and forwarding        |
| **RUM**              | `Bcr.Datadog.Android.Sdk.Rum`           | _(included in ObjC)_       | Real User Monitoring                 |
| **Trace**            | `Bcr.Datadog.Android.Sdk.Trace`         | _(included in ObjC)_       | APM and distributed tracing          |
| **Session Replay**   | `Bcr.Datadog.Android.Sdk.SessionReplay` | `Bcr.Datadog.iOS.SR`       | User session recording               |
| **WebView Tracking** | `Bcr.Datadog.Android.Sdk.WebView`       | `Bcr.Datadog.iOS.Web`      | WebView instrumentation              |
| **Crash Reporting**  | `Bcr.Datadog.Android.Sdk.Ndk`           | `Bcr.Datadog.iOS.CR`       | Native crash detection               |
| **OpenTelemetry**    | `Bcr.Datadog.Android.Sdk.Trace.Otel`    | `Bcr.Otel.Api.iOS`         | OTel integration                     |

### Feature Documentation

- **Logs**: [Android Docs](https://docs.datadoghq.com/logs/log_collection/android/) | [iOS Docs](https://docs.datadoghq.com/logs/log_collection/ios/)
- **RUM**: [Android Docs](https://docs.datadoghq.com/real_user_monitoring/android/) | [iOS Docs](https://docs.datadoghq.com/real_user_monitoring/ios/)
- **Trace**: [Android Docs](https://docs.datadoghq.com/tracing/trace_collection/automatic_instrumentation/dd_libraries/android/) | [iOS Docs](https://docs.datadoghq.com/tracing/trace_collection/automatic_instrumentation/dd_libraries/ios/)
- **Session Replay**: [Mobile Setup Docs](https://docs.datadoghq.com/real_user_monitoring/session_replay/mobile/setup_and_configuration/)
- **WebView Tracking**: [Mobile WebView Docs](https://docs.datadoghq.com/real_user_monitoring/mobile_and_tv_monitoring/web_view_tracking/)

## Samples

Working examples are available:

- **Android**: [src/Android/Bindings/Test/TestBindings/](src/Android/Bindings/Test/TestBindings/)
- **iOS**: [src/iOS/T/](src/iOS/T/)

These samples demonstrate real-world initialization and usage patterns.

## Documentation

- **[Getting Started Guide](GETTING_STARTED.md)** - Detailed setup and usage examples
- **Platform-specific docs**:
  - [Android Documentation](src/Android/)
  - [iOS Documentation](src/iOS/)

### IntelliSense Support

- **iOS**: Full IntelliSense documentation available
- **Android**: Limited IntelliSense; refer to [Android SDK documentation](https://github.com/DataDog/dd-sdk-android)

## Versioning

Binding versions mirror the native SDK versions:

- Version `2.21.0-pre.1` binds version `2.21.0` of the native SDK
- The revision number (`.1`) is incremented for binding-specific updates

## Important Notes

### For .NET MAUI Developers

- **No cross-platform abstraction**: Initialize in platform-specific entry points
- **Use conditional compilation**: `#if ANDROID` / `#if IOS`
- **Platform lifecycle matters**:
  - Android: Initialize in `MainActivity.OnCreate`
  - iOS: Initialize in `AppDelegate.FinishedLaunching`

### Binding Layer Constraints

- These are **bindings, not wrappers**
- APIs closely mirror native SDK naming and structure
- Platform-specific types remain exposed (Context, Activity, UIApplication, etc.)
- Refer to official Datadog documentation for detailed API behavior

## Support

This repository provides bindings only. For SDK usage, features, and troubleshooting:

- Refer to [Official Datadog Documentation](https://docs.datadoghq.com/)
- See [Datadog Support](https://www.datadoghq.com/support/)

For binding-specific issues (compilation, missing APIs, etc.), please open an issue in this repository.

## Contributing

Not accepting contributions at this time.

## License

This repository is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

### NOTICE

This repository includes software developed at Datadog (https://www.datadoghq.com/), which is licensed under the [Apache License 2.0](https://www.apache.org/licenses/LICENSE-2.0).

Those portions are Copyright 2019 Datadog, Inc.

For more information, please refer to the [Datadog Android SDK repository](https://github.com/DataDog/dd-sdk-android) or the [Datadog iOS SDK repository](https://github.com/DataDog/dd-sdk-ios).
