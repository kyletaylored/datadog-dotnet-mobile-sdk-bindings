# Datadog iOS SDK - ObjC Bindings (Core)

> **⚠️ DEPRECATED:** This package is deprecated as of Datadog iOS SDK 3.0.
>
> The `DatadogObjc` module was removed in SDK 3.0. Objective-C APIs are now integrated into the individual product modules (Core, Logs, RUM, Trace).
>
> **Migration:** Please use the individual packages instead:
> - `Bcr.Datadog.iOS.Core`
> - `Bcr.Datadog.iOS.Logs`
> - `Bcr.Datadog.iOS.RUM`
> - `Bcr.Datadog.iOS.Trace`
>
> See the [migration guide](https://github.com/DataDog/dd-sdk-ios/blob/develop/MIGRATION.md#migration-from-2x-to-30) for details.

## Overview (Historical Reference)

This package provides the core Datadog iOS SDK functionality through Objective-C interop. It includes initialization, configuration, and access to all major Datadog features (Logs, RUM, Trace) in a single package.

**Package Information:**
- **NuGet Package**: `Bcr.Datadog.iOS.ObjC`
- **Target Frameworks**: `net9.0-ios`, `net10.0-ios`
- **Namespace**: `Datadog.iOS.ObjC`

**Included Features:**
- Core SDK initialization
- Logs (via `DDLogs`)
- RUM - Real User Monitoring (via `DDRUM`)
- Trace (via `DDTrace`)

**Additional Packages** (install separately):
- **CrashReporting**: `Bcr.Datadog.iOS.CrashReporting`
- **SessionReplay**: `Bcr.Datadog.iOS.SessionReplay`
- **WebViewTracking**: `Bcr.Datadog.iOS.WebViewTracking`

## Requirements

- iOS 17.0+
- .NET 9 or 10
- macOS development environment with Xcode

## Installation

```xml
<ItemGroup>
  <PackageReference Include="Bcr.Datadog.iOS.ObjC" Version="3.4.0" />
</ItemGroup>
```

## Implementation Guide

### Step 1: Initialize in AppDelegate

Initialize Datadog in `FinishedLaunching`:

```csharp
using Foundation;
using UIKit;
using Datadog.iOS.ObjC;

namespace MyApp;

[Register("AppDelegate")]
public class AppDelegate : UIApplicationDelegate
{
    public override bool FinishedLaunching(UIApplication application, NSDictionary launchOptions)
    {
        // 1. Create configuration
        var config = new DDConfiguration(
            clientToken: "YOUR_CLIENT_TOKEN",
            env: "production"
        );
        config.Service = "my-ios-app";
        config.Site = DDDatadogSite.Us1; // US1, US3, US5, EU1, AP1

        // 2. Initialize Datadog
        DDDatadog.Initialize(config, DDTrackingConsent.Granted);

        // 3. Set verbosity (optional, for debugging)
        DDDatadog.VerbosityLevel = DDSDKVerbosityLevel.Debug;

        // 4. Enable features
        DDLogs.Enable(new DDLogsConfiguration(null));

        var rumConfig = new DDRUMConfiguration("YOUR_APPLICATION_ID");
        rumConfig.SessionSampleRate = 100.0f;
        DDRUM.Enable(rumConfig);

        DDTrace.Enable(new DDTraceConfiguration());

        return true;
    }
}
```

## Sample Usage

### Complete Example

```csharp
using Foundation;
using UIKit;
using Datadog.iOS.ObjC;

namespace MyApp;

[Register("AppDelegate")]
public class AppDelegate : UIApplicationDelegate
{
    private DDLogger? _logger;

    public override UIWindow? Window { get; set; }

    public override bool FinishedLaunching(UIApplication application, NSDictionary launchOptions)
    {
        // Initialize Datadog
        var config = new DDConfiguration("YOUR_CLIENT_TOKEN", "production");
        config.Service = "my-ios-app";
        config.Site = DDDatadogSite.Us1;

        DDDatadog.Initialize(config, DDTrackingConsent.Granted);
        DDDatadog.VerbosityLevel = DDSDKVerbosityLevel.Debug;

        // Set user info
        DDDatadog.SetUserInfo(
            "user-123",
            "John Doe",
            "john@example.com",
            new NSDictionary<NSString, NSObject>(
                new NSString("subscription"),
                new NSString("premium")
            )
        );

        // Enable Logs
        DDLogs.Enable(new DDLogsConfiguration(null));
        var logConfig = new DDLoggerConfiguration();
        logConfig.Service = "my-ios-app";
        logConfig.PrintLogsToConsole = true;
        _logger = DDLogger.Create(logConfig);
        _logger.Debug("Application started");

        // Enable RUM
        var rumConfig = new DDRUMConfiguration("YOUR_APPLICATION_ID");
        rumConfig.SessionSampleRate = 100.0f;
        rumConfig.TrackFrustrations = true;
        DDRUM.Enable(rumConfig);

        // Enable Trace
        DDTrace.Enable(new DDTraceConfiguration());

        // UI setup
        Window = new UIWindow(UIScreen.MainScreen.Bounds);
        // ... your UI code
        Window.MakeKeyAndVisible();

        return true;
    }
}
```

### Logging Example

```csharp
// Create logger
var logConfig = new DDLoggerConfiguration();
logConfig.Service = "my-ios-app";
logConfig.NetworkInfoEnabled = true;
logConfig.PrintLogsToConsole = true;

var logger = DDLogger.Create(logConfig);

// Log messages
logger.Debug("Debug message");
logger.Info("Info message");
logger.Warn("Warning message");
logger.Error("Error message");

// Log with attributes
var attributes = new NSDictionary<NSString, NSObject>(
    new NSString("user.id"), new NSString("12345"),
    new NSString("action"), new NSString("button_click")
);
logger.Info("User action", attributes);
```

### RUM Tracking Example

```csharp
// Get RUM monitor
var rumMonitor = DDRUMMonitor.Shared;

// Track view
rumMonitor.StartView("HomeViewController", "Home", new NSDictionary());

// Track action
rumMonitor.AddAction(
    DDRUMActionType.Tap,
    "login_button",
    new NSDictionary<NSString, NSObject>(
        new NSString("button.label"),
        new NSString("Login")
    )
);

// Stop view
rumMonitor.StopView("HomeViewController", new NSDictionary());
```

### Tracing Example

```csharp
// Get tracer
var tracer = DDTracer.Shared;

// Create span
var span = tracer.StartSpan("network.request", new NSDictionary(), null);
span.SetTag("http.url", "https://api.example.com/users");
span.SetTag("http.method", "GET");

try
{
    // Your operation
    await MakeNetworkRequest();
}
catch (Exception ex)
{
    span.SetTag("error", true);
    span.SetTag("error.message", ex.Message);
}
finally
{
    span.Finish();
}
```

## Configuration Options

### Datadog Sites

| Site | Configuration |
|------|---------------|
| US1 (default) | `DDDatadogSite.Us1` |
| US3 | `DDDatadogSite.Us3` |
| US5 | `DDDatadogSite.Us5` |
| EU1 | `DDDatadogSite.Eu1` |
| AP1 | `DDDatadogSite.Ap1` |
| US1_FED | `DDDatadogSite.Us1Fed` |

### Tracking Consent

| Value | Description |
|-------|-------------|
| `DDTrackingConsent.Granted` | User granted consent, collect data |
| `DDTrackingConsent.NotGranted` | User declined, do not collect |
| `DDTrackingConsent.Pending` | Waiting for consent, buffer data |

### SDK Verbosity Levels

| Level | Description |
|-------|-------------|
| `DDSDKVerbosityLevel.None` | No logging |
| `DDSDKVerbosityLevel.Debug` | Debug messages |
| `DDSDKVerbosityLevel.Info` | Informational messages |
| `DDSDKVerbosityLevel.Warn` | Warnings |
| `DDSDKVerbosityLevel.Error` | Errors only |

## API Reference

### Core SDK

| Native API (Swift/Objective-C) | .NET Binding |
|--------------------------------|--------------|
| `Datadog.initialize(configuration:trackingConsent:)` | `DDDatadog.Initialize(config, consent)` |
| `Datadog.setVerbosityLevel(_:)` | `DDDatadog.VerbosityLevel = level` |
| `Datadog.setUserInfo(id:name:email:extraInfo:)` | `DDDatadog.SetUserInfo(id, name, email, extra)` |
| `Datadog.setTrackingConsent(_:)` | `DDDatadog.SetTrackingConsent(consent)` |

### Logs

| Native API | .NET Binding |
|-----------|--------------|
| `Logs.enable(with:)` | `DDLogs.Enable(config)` |
| `Logger.create(with:)` | `DDLogger.Create(config)` |
| `logger.debug(_:attributes:)` | `logger.Debug(message, attributes)` |

### RUM

| Native API | .NET Binding |
|-----------|--------------|
| `RUM.enable(with:)` | `DDRUM.Enable(config)` |
| `RUMMonitor.shared()` | `DDRUMMonitor.Shared` |

### Trace

| Native API | .NET Binding |
|-----------|--------------|
| `Trace.enable(with:)` | `DDTrace.Enable(config)` |
| `Tracer.shared()` | `DDTracer.Shared` |

## Related Documentation

- **Official Datadog iOS SDK**: [GitHub Repository](https://github.com/DataDog/dd-sdk-ios)
- **iOS Setup Guide**: [Getting Started](https://docs.datadoghq.com/real_user_monitoring/ios/)
- **iOS Advanced Configuration**: [Advanced Setup](https://docs.datadoghq.com/real_user_monitoring/mobile_and_tv_monitoring/advanced_configuration/ios/)

## Important Notes

1. **ObjC Layer Only**: These bindings use the Objective-C interop layer, which requires importing much of the SDK at once
2. **Initialize in FinishedLaunching**: Always initialize in `AppDelegate.FinishedLaunching`, not in constructors
3. **NSDictionary**: Use `NSDictionary<NSString, NSObject>` for attributes
4. **String Wrapping**: Wrap strings in `NSString`: `new NSString("value")`

## Troubleshooting

**Issue**: "Could not find a part of the path..." on Windows
- This is the Windows 260-character path limit issue
- See FAQ in original README for solutions (enable long paths, shorten paths, use command line builds)

**Issue**: No data appearing in Datadog
- Verify client token and application ID
- Check `DDTrackingConsent.Granted` is set
- Verify site configuration matches your Datadog account
- Check network connectivity

## License

This project is licensed under the [MIT License](LICENSE).

This product includes software developed at Datadog (https://www.datadoghq.com/), used under the [Apache License, v2.0](https://github.com/DataDog/dd-sdk-ios/blob/develop/LICENSE)

Those portions are Copyright 2019 Datadog, Inc.
