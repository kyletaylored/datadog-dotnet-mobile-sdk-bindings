# Datadog Android SDK - Logs Bindings

.NET bindings for the Datadog Android SDK Logs library (`com.datadog.android:dd-sdk-android-logs`).

## Overview

The Logs binding enables you to send logs from your .NET for Android application to Datadog. It provides structured logging with support for log levels, custom attributes, and exception tracking.

**Key Capabilities:**
- Multiple log levels (Debug, Info, Warning, Error, Assert)
- Custom attributes and tags per log
- Exception tracking with stack traces
- Network info enrichment
- Console logging (logcat integration)
- Correlation with RUM sessions

**Package Information:**
- **NuGet Package**: `Bcr.Datadog.Android.Sdk.Logs`
- **Native Artifact**: `com.datadog.android:dd-sdk-android-logs:2.21.0`
- **Namespace**: `Datadog.Android.Log`

## Requirements

- .NET 10
- Android API Level 26+
- **Prerequisite**: `Bcr.Datadog.Android.Sdk.Core` must be installed and initialized first

## Installation

```xml
<ItemGroup>
  <PackageReference Include="Bcr.Datadog.Android.Sdk.Core" Version="2.21.0-pre.1" />
  <PackageReference Include="Bcr.Datadog.Android.Sdk.Logs" Version="2.21.0-pre.1" />
</ItemGroup>
```

## Implementation Guide

### Step 1: Initialize Core SDK

Before enabling logs, initialize the Datadog SDK:

```csharp
using Datadog.Android;
using Datadog.Android.Core.Configuration;
using Datadog.Android.Privacy;

var config = new DDConfiguration.Builder(
    "YOUR_CLIENT_TOKEN", "production", string.Empty, "my-app"
).Build();

Datadog.Initialize(this, config, TrackingConsent.Granted);
```

### Step 2: Enable Logs

Enable the Logs feature:

```csharp
using Datadog.Android.Log;

var logsConfig = new LogsConfiguration.Builder()
    .Build();

Logs.Enable(logsConfig);
```

### Step 3: Create a Logger

Create a logger instance with optional configuration:

```csharp
var logger = new Logger.Builder()
    .SetName("MyLogger")
    .SetNetworkInfoEnabled(true)
    .SetLogcatLogsEnabled(true)
    .SetBundleWithRumEnabled(true)
    .Build();
```

### Step 4: Log Messages

Use the logger to send log messages:

```csharp
// Basic logging
logger.D("Debug message", null, null);
logger.I("Info message", null, null);
logger.W("Warning message", null, null);
logger.E("Error message", null, null);

// Logging with attributes
logger.I("User logged in", null, new Dictionary<string, Java.Lang.Object>
{
    { "user.id", new Java.Lang.String("12345") },
    { "auth.method", new Java.Lang.String("oauth") }
});

// Logging exceptions
try
{
    throw new Exception("Something went wrong");
}
catch (Exception ex)
{
    var javaException = new Java.Lang.Exception(ex.Message);
    logger.E("Exception occurred", javaException, new Dictionary<string, Java.Lang.Object>
    {
        { "error.stack", new Java.Lang.String(ex.StackTrace ?? "") },
        { "error.type", new Java.Lang.String(ex.GetType().Name) }
    });
}
```

## Sample Usage

### Complete Example

```csharp
using Android.App;
using Android.OS;
using Datadog.Android;
using Datadog.Android.Core.Configuration;
using Datadog.Android.Log;
using Datadog.Android.Privacy;

namespace MyApp;

[Activity(Label = "@string/app_name", MainLauncher = true)]
public class MainActivity : Activity
{
    private Logger? _logger;

    protected override void OnCreate(Bundle? savedInstanceState)
    {
        base.OnCreate(savedInstanceState);

        // 1. Initialize Datadog SDK
        var config = new DDConfiguration.Builder(
            "YOUR_CLIENT_TOKEN", "production", string.Empty, "my-app"
        ).Build();
        Datadog.Initialize(this, config, TrackingConsent.Granted);

        // 2. Enable Logs
        var logsConfig = new LogsConfiguration.Builder().Build();
        Logs.Enable(logsConfig);

        // 3. Create Logger
        _logger = new Logger.Builder()
            .SetName("MainActivity")
            .SetNetworkInfoEnabled(true)
            .SetLogcatLogsEnabled(true)
            .SetBundleWithRumEnabled(true)
            .Build();

        // 4. Log application start
        _logger.I("Application started", null, new Dictionary<string, Java.Lang.Object>
        {
            { "app.version", new Java.Lang.String("1.0.0") },
            { "screen", new Java.Lang.String("MainActivity") }
        });

        SetContentView(Resource.Layout.activity_main);
    }

    private void SimulateUserAction()
    {
        _logger?.D("Button clicked", null, new Dictionary<string, Java.Lang.Object>
        {
            { "button.id", new Java.Lang.String("submit_button") },
            { "timestamp", new Java.Lang.Long(DateTimeOffset.UtcNow.ToUnixTimeMilliseconds()) }
        });

        try
        {
            // Simulate an operation that might fail
            ProcessUserData();
        }
        catch (Exception ex)
        {
            _logger?.E(
                "Failed to process user data",
                new Java.Lang.Exception(ex.Message),
                new Dictionary<string, Java.Lang.Object>
                {
                    { "error.stack", new Java.Lang.String(ex.StackTrace ?? "") },
                    { "error.type", new Java.Lang.String(ex.GetType().Name) },
                    { "user.action", new Java.Lang.String("data_processing") }
                }
            );
        }
    }

    private void ProcessUserData()
    {
        // Business logic here
        _logger?.D("Processing user data", null, null);
    }
}
```

### Logger Configuration Options

```csharp
var logger = new Logger.Builder()
    .SetName("CustomLogger")                     // Logger name (appears in Datadog)
    .SetNetworkInfoEnabled(true)                 // Include network info
    .SetLogcatLogsEnabled(true)                  // Also log to Android logcat
    .SetBundleWithRumEnabled(true)               // Bundle with RUM events
    .SetBundleWithTraceEnabled(true)             // Bundle with traces
    .SetRemoteSampleRate(100.0f)                 // Sample rate (0-100)
    .Build();
```

### Logging with Different Severity Levels

```csharp
// Debug - detailed information for debugging
logger.D("Detailed debug information", null, null);

// Info - general informational messages
logger.I("User completed onboarding", null, null);

// Warning - warning messages
logger.W("API response took longer than expected", null, new Dictionary<string, Java.Lang.Object>
{
    { "duration.ms", new Java.Lang.Long(5000) }
});

// Error - error conditions
logger.E("Failed to load user profile", null, new Dictionary<string, Java.Lang.Object>
{
    { "user.id", new Java.Lang.String("12345") }
});

// Assert - critical errors
logger.Wtf("Critical failure", null, null); // "What a Terrible Failure"
```

### Adding Logger Attributes

```csharp
// Add attribute to logger (will be included in all logs from this logger)
logger.AddAttribute("environment", "production");
logger.AddAttribute("team", "mobile");

// Add tag to logger
logger.AddTag("platform", "android");
logger.AddTag("version", "1.0.0");

// Remove attribute
logger.RemoveAttribute("environment");

// Remove tag
logger.RemoveTag("platform");
```

## Configuration Options

### LogsConfiguration Builder Options

| Method | Description |
|--------|-------------|
| `.Build()` | Build the configuration with defaults |

### Logger Builder Options

| Method | Description | Default |
|--------|-------------|---------|
| `.SetName(string)` | Set logger name | Package name |
| `.SetNetworkInfoEnabled(bool)` | Include network info in logs | `false` |
| `.SetLogcatLogsEnabled(bool)` | Also write logs to logcat | `false` |
| `.SetBundleWithRumEnabled(bool)` | Bundle logs with RUM events | `true` |
| `.SetBundleWithTraceEnabled(bool)` | Bundle logs with traces | `true` |
| `.SetRemoteSampleRate(float)` | Sample rate for remote logs (0-100) | `100.0` |

## API Reference

### Logs Initialization

| Native API (Kotlin/Java) | .NET Binding |
|--------------------------|--------------|
| `Logs.enable(config)` | `Logs.Enable(config)` |
| `LogsConfiguration.Builder()` | `new LogsConfiguration.Builder()` |

### Logger Creation

| Native API (Kotlin/Java) | .NET Binding |
|--------------------------|--------------|
| `Logger.Builder()` | `new Logger.Builder()` |
| `.setName(name)` | `.SetName(name)` |
| `.setNetworkInfoEnabled(enabled)` | `.SetNetworkInfoEnabled(enabled)` |
| `.setLogcatLogsEnabled(enabled)` | `.SetLogcatLogsEnabled(enabled)` |
| `.setBundleWithRumEnabled(enabled)` | `.SetBundleWithRumEnabled(enabled)` |
| `.build()` | `.Build()` |

### Logging Methods

| Native API (Kotlin/Java) | .NET Binding |
|--------------------------|--------------|
| `logger.d(message, attributes)` | `logger.D(message, null, attributes)` |
| `logger.i(message, attributes)` | `logger.I(message, null, attributes)` |
| `logger.w(message, attributes)` | `logger.W(message, null, attributes)` |
| `logger.e(message, throwable, attributes)` | `logger.E(message, throwable, attributes)` |
| `logger.wtf(message, attributes)` | `logger.Wtf(message, null, attributes)` |

### Logger Attributes

| Native API (Kotlin/Java) | .NET Binding |
|--------------------------|--------------|
| `logger.addAttribute(key, value)` | `logger.AddAttribute(key, value)` |
| `logger.removeAttribute(key)` | `logger.RemoveAttribute(key)` |
| `logger.addTag(key, value)` | `logger.AddTag(key, value)` |
| `logger.removeTag(key)` | `logger.RemoveTag(key)` |

## Related Documentation

- **Official Datadog Docs**: [Android Log Collection](https://docs.datadoghq.com/logs/log_collection/android/)
- **Datadog Android SDK**: [GitHub Repository](https://github.com/DataDog/dd-sdk-android)
- **Error Tracking**: [Android Error Tracking](https://docs.datadoghq.com/real_user_monitoring/error_tracking/mobile/android/)

## Important Notes

1. **Initialize Core First**: The Core SDK must be initialized before calling `Logs.Enable()`
2. **Dictionary Values**: Use `Java.Lang.Object` types (e.g., `new Java.Lang.String("value")`)
3. **Exception Logging**: Wrap .NET exceptions in `Java.Lang.Exception` for native SDK compatibility
4. **Second Parameter**: Log methods have a second parameter (typically `null`) for additional throwable info

## Troubleshooting

**Issue**: Logs not appearing in Datadog
- Ensure Core SDK is initialized with `TrackingConsent.Granted`
- Verify `Logs.Enable()` was called after SDK initialization
- Check network connectivity
- Increase verbosity: `Datadog.Verbosity = (int)Android.Util.LogPriority.Verbose`

**Issue**: Dictionary conversion errors
- Use `new Java.Lang.String("value")` for string values
- Use `new Java.Lang.Long(123)` for numeric values
- Dictionary type should be `Dictionary<string, Java.Lang.Object>`

**Issue**: Stack traces not appearing
- Ensure you're wrapping the .NET exception: `new Java.Lang.Exception(ex.Message)`
- Include stack trace in attributes: `{ "error.stack", new Java.Lang.String(ex.StackTrace ?? "") }`

## License

This package is licensed under the MIT License. See the LICENSE file for details.

### NOTICE

This package includes software developed at Datadog (https://www.datadoghq.com/).

Those portions are Copyright 2019 Datadog, Inc.

For more information, please refer to the [Datadog Android SDK repository](https://github.com/DataDog/dd-sdk-android).
