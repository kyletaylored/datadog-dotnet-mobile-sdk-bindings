# .NET Bindings for the Datadog Mobile iOS SDK

These bindings are only for iOS; tvOS is not included.

> **NOTE:** These bindings are only against the Objective-C interop layer for the iOS SDK. As such, only code that is part of that layer is currently available.

Using the Objective-C layer requires you to import the entire SDK (Logs, RUM, and Trace are bundled together). In contrast, the Swift layer allows you to import only the specific packages you need.

## Prerequisites

### For Using the Bindings

Before using the iOS SDK bindings, make sure you have the following:

- iOS 17.0+
- .NET 9 or 10
- macOS development environment with Xcode 16.1 or later

**Note:** These bindings multi-target `net9.0-ios` and `net10.0-ios`, with a minimum supported iOS version of 17.0 to support both .NET 9 and .NET 10.

### For Building from Source

If you need to build the bindings from source, you'll also need:

- **Carthage** - iOS dependency manager
  ```bash
  brew install carthage
  ```
- **Objective Sharpie** - C# binding generator
  ```bash
  brew install objectivesharpie
  ```
- Git submodules initialized
  ```bash
  git submodule update --init --recursive
  ```

See [BUILDING_AND_VERSIONING.md](../../BUILDING_AND_VERSIONING.md) for detailed build instructions.

## Available Packages

### Core Package (Required)

- **`Bcr.Datadog.iOS.ObjC`** - Core SDK including Logs, RUM, and Trace functionality

### Feature Packages (Optional)

- **`Bcr.Datadog.iOS.CR`** - Crash Reporting
- **`Bcr.Datadog.iOS.SR`** - Session Replay
- **`Bcr.Datadog.iOS.Web`** - WebView Tracking

### Low-Level Bindings (Internal Dependencies)

The following packages are internal dependencies of `Bcr.Datadog.iOS.ObjC` and typically don't need to be referenced directly:

- **`Bcr.Datadog.iOS.Core`** - Core framework binding
- **`Bcr.Datadog.iOS.Logs`** - Logs framework binding
- **`Bcr.Datadog.iOS.RUM`** - RUM framework binding
- **`Bcr.Datadog.iOS.Trace`** - Trace framework binding
- **`Bcr.Datadog.iOS.Int`** - Internal framework binding
- **`Bcr.Otel.Api.iOS`** - OpenTelemetry API binding

## Installation

```xml
<!-- Core SDK with Logs, RUM, and Trace (required) -->
<PackageReference Include="Bcr.Datadog.iOS.ObjC" Version="2.26.0" />

<!-- Additional features (install as needed) -->
<PackageReference Include="Bcr.Datadog.iOS.CR" Version="2.26.0" />   <!-- Crash Reporting -->
<PackageReference Include="Bcr.Datadog.iOS.SR" Version="2.26.0" />   <!-- Session Replay -->
<PackageReference Include="Bcr.Datadog.iOS.Web" Version="2.26.0" />  <!-- WebView Tracking -->
```

## Usage

See the [Datadog iOS SDK repository](https://github.com/DataDog/dd-sdk-ios) for more information about initialization for any given piece of functionality.

All functionality requires you to initialize the SDK before use. The Datadog documentation has more information; the basics are to initialize in `FinishedLaunching()`:

### Basic Initialization

```csharp
using Datadog.iOS.ObjC;
using Datadog.iOS.CrashReporting;  // If using crash reporting
using Datadog.iOS.SessionReplay;   // If using session replay

public override bool FinishedLaunching(UIApplication application, NSDictionary launchOptions)
{
    // 1. Configure Datadog SDK
    var config = new DDConfiguration(
        clientToken: "<YOUR_CLIENT_TOKEN>",
        env: "production"
    );
    config.Service = "my-ios-app";
    config.Site = DDDatadogSite.Us1;  // US1, US3, US5, EU1, AP1, etc.

    // 2. Initialize Datadog
    DDDatadog.Initialize(config, DDTrackingConsent.Granted);
    DDDatadog.VerbosityLevel = DDSDKVerbosityLevel.Debug;

    // 3. Enable Logs
    DDLogs.Enable(new DDLogsConfiguration(null));

    // 4. Enable RUM
    var rumConfig = new DDRUMConfiguration("<YOUR_APPLICATION_ID>");
    rumConfig.SessionSampleRate = 100.0f;
    DDRUM.Enable(rumConfig);

    // 5. Enable Trace
    DDTrace.Enable(new DDTraceConfiguration());

    // 6. Enable Crash Reporting (optional)
    DDCrashReporter.Enable();

    // 7. Enable Session Replay (optional)
    var replayConfig = new DDSessionReplayConfiguration(
        100.0f,  // Sample rate
        DDTextAndInputPrivacyLevel.MaskAll,
        DDImagePrivacyLevel.MaskAll,
        DDTouchPrivacyLevel.Hide
    );
    DDSessionReplay.Enable(replayConfig);

    // 8. Create and use a logger
    var logConfig = new DDLoggerConfiguration();
    logConfig.Service = "my-ios-app";
    logConfig.PrintLogsToConsole = true;
    var logger = DDLogger.Create(logConfig);
    logger.Debug("Application started");

    return true;
}
```

### Working Example

See [src/iOS/T/AppDelegate.cs](T/AppDelegate.cs) for a complete working example demonstrating all features.

## Documentation

For detailed feature-specific documentation, see the individual binding READMEs:

- **[ObjC (Core)](Bindings/ObjC/README.md)** - Main package with Logs, RUM, and Trace
- **[Crash Reporting](Bindings/CrashReporting/README.md)** - Native crash detection
- **[Session Replay](Bindings/SessionReplay/README.md)** - User session recording
- **[WebView Tracking](Bindings/WebViewTracking/README.md)** - WebView instrumentation

For more information on using the Datadog iOS SDK, refer to the [official documentation](https://docs.datadoghq.com/real_user_monitoring/ios/).

## FAQ

### Why am I getting errors like `Could not find a part of the path...` when I add this NuGet package to my app and try to build it using Visual Studio on Windows?

This is the notorious "max path" bug in Visual Studio that limits paths to 260 characters. It particularly affects .NET for iOS apps, as `.xcframework` files are folders with very deep structures.

The `.xcframework` paths have been shortened as much as is practical. You have the following options:

1. First, upvote the [Visual Studio Dev Community](https://developercommunity.visualstudio.com/t/Allow-building-running-and-debugging-a/351628) issue. This problem has been known for years, and yet still no action has been taken.
2. Enable the Windows registry setting for long path support.
3. Perform all your NuGet restoration and builds on the command line.
4. Shorten your source code path to be VERY short, as in one or two characters (if possible)
5. Shorten your Git repository path of your clone to also be as short as possible.
6. You may also need configure a `nuget.config` file to shorten the location of your NuGet packages. For example:

```xml
<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <config>
    <add key="globalPackagesFolder" value="C:\n" />
  </config>
</configuration>
```

## License

This project is licensed under the [MIT License](LICENSE).

This product includes software developed at Datadog (https://www.datadoghq.com/), used under the [Apache License, v2.0](https://github.com/DataDog/dd-sdk-ios/blob/develop/LICENSE)

Those portions are Copyright 2019 Datadog, Inc.
