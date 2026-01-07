# Datadog iOS SDK - RUM Framework Binding

Low-level .NET bindings for the Datadog iOS SDK RUM framework.

## Overview

This package provides direct bindings to the DatadogRUM.xcframework, exposing the native iOS Real User Monitoring APIs to .NET. It's an internal dependency used by the main [Bcr.Datadog.iOS.ObjC](../ObjC/README.md) package.

**Package Information:**
- **NuGet Package**: `Bcr.Datadog.iOS.RUM`
- **Target Frameworks**: `net9.0-ios`, `net10.0-ios`
- **XCFramework**: `DDR.xcframework`

> **⚠️ Important**: This is a low-level binding package. For most use cases, you should use [Bcr.Datadog.iOS.ObjC](../ObjC/README.md) instead, which includes Logs, RUM, and Trace in a single integrated package with easier-to-use APIs.

## When to Use This Package

Use this package directly only if you:
- Need fine-grained control over RUM framework dependencies
- Are building custom wrappers or abstractions
- Have specific modular architecture requirements

For standard iOS app integration, use [Bcr.Datadog.iOS.ObjC](../ObjC/README.md) instead.

## Installation

```xml
<ItemGroup>
  <PackageReference Include="Bcr.Datadog.iOS.RUM" Version="3.4.0" />
</ItemGroup>
```

## What's Included

This binding exposes the native DatadogRUM framework APIs:

- `DDRUM` - RUM feature configuration
- `DDRUMMonitor` - Global RUM monitor singleton
- `DDRUMConfiguration` - RUM-specific configuration options
- `DDRUMActionType` - Action type enumeration (tap, swipe, scroll, custom)
- `DDRUMResourceType` - Resource type enumeration (image, xhr, fetch, etc.)
- `DDRUMMethod` - HTTP method enumeration (GET, POST, PUT, DELETE, etc.)
- `DDRUMErrorSource` - Error source enumeration (network, source, console, custom)

## Usage Example

```csharp
using Datadog.iOS.RUM;
using Foundation;

// Enable RUM (after Datadog SDK initialization)
var rumConfig = new DDRUMConfiguration("YOUR_APPLICATION_ID");
rumConfig.SessionSampleRate = 100.0f;
rumConfig.TrackFrustrations = true;
DDRUM.Enable(rumConfig);

// Get RUM monitor
var rumMonitor = DDRUMMonitor.Shared;

// Track view
rumMonitor.StartView("HomeViewController", "Home", new NSDictionary());

// Track user action
rumMonitor.AddAction(
    DDRUMActionType.Tap,
    "login_button",
    new NSDictionary<NSString, NSObject>(
        new NSString("button.label"),
        new NSString("Login")
    )
);

// Track resource (network request)
rumMonitor.StartResource(
    "fetch_users",
    DDRUMMethod.Get,
    "https://api.example.com/users"
);

// After request completes
rumMonitor.StopResource(
    "fetch_users",
    DDRUMResourceType.Xhr,
    200, // status code
    1024, // size in bytes
    null
);

// Track error
rumMonitor.AddError(
    "Network timeout",
    DDRUMErrorSource.Network,
    null, // exception
    new NSDictionary<NSString, NSObject>(
        new NSString("endpoint"),
        new NSString("/api/users")
    )
);

// Stop view
rumMonitor.StopView("HomeViewController", new NSDictionary());
```

## RUM Action Types

| Type | Description |
|------|-------------|
| `DDRUMActionType.Tap` | User tap/touch |
| `DDRUMActionType.Swipe` | Swipe gesture |
| `DDRUMActionType.Scroll` | Scroll action |
| `DDRUMActionType.Custom` | Custom action |

## RUM Resource Types

| Type | Description |
|------|-------------|
| `DDRUMResourceType.Image` | Image resource |
| `DDRUMResourceType.Xhr` | XMLHttpRequest |
| `DDRUMResourceType.Fetch` | Fetch API |
| `DDRUMResourceType.Native` | Native network call |

## Related Packages

- **[Bcr.Datadog.iOS.ObjC](../ObjC/README.md)** - Main package with Logs, RUM, and Trace (recommended)
- **[Bcr.Datadog.iOS.Logs](../DDLogs/README.md)** - Logs framework binding
- **[Bcr.Datadog.iOS.Trace](../Trace/README.md)** - Trace framework binding

## Related Documentation

- **iOS RUM Setup**: [Getting Started with iOS RUM](https://docs.datadoghq.com/real_user_monitoring/ios/)
- **iOS RUM Advanced**: [Advanced RUM Configuration](https://docs.datadoghq.com/real_user_monitoring/mobile_and_tv_monitoring/advanced_configuration/ios/)
- **Official iOS SDK**: [GitHub Repository](https://github.com/DataDog/dd-sdk-ios)

## License

This project is licensed under the [MIT License](LICENSE).

This product includes software developed at Datadog (https://www.datadoghq.com/), used under the [Apache License, v2.0](https://github.com/DataDog/dd-sdk-ios/blob/develop/LICENSE)
