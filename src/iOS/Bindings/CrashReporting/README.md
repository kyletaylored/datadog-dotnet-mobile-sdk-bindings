# Datadog iOS SDK - Crash Reporting Bindings

.NET bindings for the Datadog iOS SDK CrashReporting framework.

## Overview

Crash Reporting enables automatic detection and reporting of application crashes to Datadog, providing detailed stack traces and crash context.

**Package Information:**
- **NuGet Package**: `Bcr.Datadog.iOS.CrashReporting`
- **Target Frameworks**: `net9.0-ios`, `net10.0-ios`
- **Namespace**: `Datadog.iOS.CrashReporting`

## Requirements

- iOS 17.0+
- .NET 9 or 10
- **Prerequisite**: `Bcr.Datadog.iOS.ObjC` must be installed and initialized

## Installation

```xml
<ItemGroup>
  <PackageReference Include="Bcr.Datadog.iOS.ObjC" Version="3.4.0" />
  <PackageReference Include="Bcr.Datadog.iOS.CrashReporting" Version="3.4.0" />
</ItemGroup>
```

## Implementation Guide

```csharp
using Foundation;
using UIKit;
using Datadog.iOS.ObjC;
using Datadog.iOS.CrashReporting;

namespace MyApp;

[Register("AppDelegate")]
public class AppDelegate : UIApplicationDelegate
{
    public override bool FinishedLaunching(UIApplication application, NSDictionary launchOptions)
    {
        // Initialize Datadog SDK first
        var config = new DDConfiguration("YOUR_CLIENT_TOKEN", "production");
        config.Service = "my-ios-app";
        DDDatadog.Initialize(config, DDTrackingConsent.Granted);

        // Enable RUM (required for crash reporting)
        var rumConfig = new DDRUMConfiguration("YOUR_APPLICATION_ID");
        DDRUM.Enable(rumConfig);

        // Enable Crash Reporting
        DDCrashReporter.Enable();

        return true;
    }
}
```

## API Reference

| Native API | .NET Binding |
|-----------|--------------|
| `CrashReporting.enable()` | `DDCrashReporter.Enable()` |

## Related Documentation

- **Official Docs**: [iOS Crash Reporting](https://docs.datadoghq.com/real_user_monitoring/error_tracking/mobile/ios/)
- **Datadog iOS SDK**: [GitHub](https://github.com/DataDog/dd-sdk-ios)

## License

This project is licensed under the [MIT License](LICENSE).

This product includes software developed at Datadog (https://www.datadoghq.com/), used under the [Apache License, v2.0](https://github.com/DataDog/dd-sdk-ios/blob/develop/LICENSE)

Those portions are Copyright 2019 Datadog, Inc.
