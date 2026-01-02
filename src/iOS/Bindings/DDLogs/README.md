# Datadog iOS SDK - Logs Framework Binding

Low-level .NET bindings for the Datadog iOS SDK DatadogLogs framework.

## Overview

This package provides direct bindings to the DatadogLogs.xcframework, exposing the native iOS logging APIs to .NET. It's an internal dependency used by the main [Bcr.Datadog.iOS.ObjC](../ObjC/README.md) package.

**Package Information:**
- **NuGet Package**: `Bcr.Datadog.iOS.Logs`
- **Target Frameworks**: `net8.0-ios17.0`, `net9.0-ios18.0`
- **XCFramework**: `DDL.xcframework`

> **⚠️ Important**: This is a low-level binding package. For most use cases, you should use [Bcr.Datadog.iOS.ObjC](../ObjC/README.md) instead, which includes Logs, RUM, and Trace in a single integrated package with easier-to-use APIs.

## When to Use This Package

Use this package directly only if you:
- Need fine-grained control over Logs framework dependencies
- Are building custom wrappers or abstractions
- Have specific modular architecture requirements

For standard iOS app integration, use [Bcr.Datadog.iOS.ObjC](../ObjC/README.md) instead.

## Installation

```xml
<ItemGroup>
  <PackageReference Include="Bcr.Datadog.iOS.Logs" Version="2.26.0" />
</ItemGroup>
```

## What's Included

This binding exposes the native DatadogLogs framework APIs:

- `DDLogs` - Logs feature configuration
- `DDLogger` - Logger instance creation and configuration
- `DDLogsConfiguration` - Logs-specific configuration options
- `DDLoggerConfiguration` - Per-logger configuration

## Usage Example

```csharp
using Datadog.iOS.Logs;
using Foundation;

// Enable Logs (after Datadog SDK initialization)
DDLogs.Enable(new DDLogsConfiguration(null));

// Create logger
var logConfig = new DDLoggerConfiguration();
logConfig.Service = "my-ios-app";
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

## Related Packages

- **[Bcr.Datadog.iOS.ObjC](../ObjC/README.md)** - Main package with Logs, RUM, and Trace (recommended)
- **[Bcr.Datadog.iOS.RUM](../Rum/README.md)** - RUM framework binding
- **[Bcr.Datadog.iOS.Trace](../Trace/README.md)** - Trace framework binding

## Related Documentation

- **iOS SDK Logging**: [Datadog iOS Logging Documentation](https://docs.datadoghq.com/logs/log_collection/ios/)
- **Official iOS SDK**: [GitHub Repository](https://github.com/DataDog/dd-sdk-ios)

## License

This project is licensed under the [MIT License](LICENSE).

This product includes software developed at Datadog (https://www.datadoghq.com/), used under the [Apache License, v2.0](https://github.com/DataDog/dd-sdk-ios/blob/develop/LICENSE)
