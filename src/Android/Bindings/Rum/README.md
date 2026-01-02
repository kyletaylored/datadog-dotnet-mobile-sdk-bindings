# Datadog Android SDK - RUM (Real User Monitoring) Bindings

.NET bindings for the Datadog Android SDK RUM library (`com.datadog.android:dd-sdk-android-rum`).

## Overview

The RUM (Real User Monitoring) binding enables you to track user navigation, interactions, and application performance in your .NET for Android application. It provides comprehensive visibility into user sessions, screen views, user actions, network requests, and errors.

**Key Capabilities:**
- Automatic and manual view tracking
- User action tracking (taps, swipes, scrolls)
- Network request monitoring
- Error and crash tracking
- Long task detection
- User frustration signals (rage taps, error taps)
- Custom timing and performance metrics

**Package Information:**
- **NuGet Package**: `Bcr.Datadog.Android.Sdk.Rum`
- **Native Artifact**: `com.datadog.android:dd-sdk-android-rum:2.21.0`
- **Namespace**: `Datadog.Android.Rum`

## Requirements

- .NET 10
- Android API Level 26+
- **Prerequisite**: `Bcr.Datadog.Android.Sdk.Core` must be installed and initialized first
- **Application ID**: You need a RUM Application ID from your Datadog account

## Installation

```xml
<ItemGroup>
  <PackageReference Include="Bcr.Datadog.Android.Sdk.Core" Version="2.21.0-pre.1" />
  <PackageReference Include="Bcr.Datadog.Android.Sdk.Rum" Version="2.21.0-pre.1" />
</ItemGroup>
```

## Implementation Guide

### Step 1: Initialize Core SDK

```csharp
using Datadog.Android;
using Datadog.Android.Core.Configuration;
using Datadog.Android.Privacy;

var config = new DDConfiguration.Builder(
    "YOUR_CLIENT_TOKEN", "production", string.Empty, "my-app"
).Build();

Datadog.Initialize(this, config, TrackingConsent.Granted);
```

### Step 2: Enable RUM

```csharp
using Datadog.Android.Rum;

var rumConfig = new RumConfiguration.Builder("YOUR_APPLICATION_ID")
    .TrackLongTasks()                    // Track tasks blocking UI thread > 100ms
    .TrackFrustrations(true)             // Track user frustrations (rage taps, etc.)
    .TrackBackgroundEvents(true)         // Track events when app is backgrounded
    .TrackNonFatalAnrs(true)             // Track Application Not Responding events
    .SetSessionSampleRate(100.0f)        // Sample 100% of sessions
    .Build();

Datadog.Android.Rum.Rum.Enable(rumConfig);
```

### Step 3: Access the RUM Monitor

```csharp
var rumMonitor = GlobalRumMonitor.Get();
// or
var rumMonitor = GlobalRumMonitor.Instance;
```

### Step 4: Track Views

```csharp
// Start tracking a view
rumMonitor.StartView(
    "HomeScreen",                        // Unique key for the view
    "Home",                              // View name (displayed in Datadog)
    new Dictionary<string, Java.Lang.Object>
    {
        { "screen.type", new Java.Lang.String("main") }
    }
);

// Stop tracking the view
rumMonitor.StopView(
    "HomeScreen",
    new Dictionary<string, Java.Lang.Object>()
);
```

## Sample Usage

### Complete Example with Activity Tracking

```csharp
using Android.App;
using Android.OS;
using Datadog.Android;
using Datadog.Android.Core.Configuration;
using Datadog.Android.Privacy;
using Datadog.Android.Rum;

namespace MyApp;

[Activity(Label = "@string/app_name", MainLauncher = true)]
public class MainActivity : Activity
{
    private const string ViewKey = "MainActivity";

    protected override void OnCreate(Bundle? savedInstanceState)
    {
        base.OnCreate(savedInstanceState);

        // 1. Initialize Datadog SDK (only once per app lifecycle)
        var config = new DDConfiguration.Builder(
            "YOUR_CLIENT_TOKEN", "production", string.Empty, "my-app"
        ).Build();
        Datadog.Initialize(this, config, TrackingConsent.Granted);

        // 2. Enable RUM
        var rumConfig = new RumConfiguration.Builder("YOUR_APPLICATION_ID")
            .TrackLongTasks()
            .TrackFrustrations(true)
            .TrackBackgroundEvents(true)
            .TrackNonFatalAnrs(true)
            .Build();
        Datadog.Android.Rum.Rum.Enable(rumConfig);

        SetContentView(Resource.Layout.activity_main);
    }

    protected override void OnResume()
    {
        base.OnResume();

        // Start tracking this view
        var rumMonitor = GlobalRumMonitor.Get();
        rumMonitor.StartView(
            ViewKey,
            "Main Screen",
            new Dictionary<string, Java.Lang.Object>
            {
                { "screen.category", new Java.Lang.String("main") }
            }
        );
    }

    protected override void OnPause()
    {
        // Stop tracking this view
        var rumMonitor = GlobalRumMonitor.Get();
        rumMonitor.StopView(ViewKey, new Dictionary<string, Java.Lang.Object>());

        base.OnPause();
    }
}
```

### Tracking User Actions

```csharp
var rumMonitor = GlobalRumMonitor.Get();

// Track a tap action
rumMonitor.AddAction(
    RumActionType.Tap,
    "login_button",
    new Dictionary<string, Java.Lang.Object>
    {
        { "button.label", new Java.Lang.String("Login") },
        { "screen", new Java.Lang.String("LoginScreen") }
    }
);

// Track a swipe action
rumMonitor.AddAction(
    RumActionType.Swipe,
    "product_list",
    new Dictionary<string, Java.Lang.Object>
    {
        { "direction", new Java.Lang.String("down") }
    }
);

// Track a custom action
rumMonitor.AddAction(
    RumActionType.Custom,
    "filter_applied",
    new Dictionary<string, Java.Lang.Object>
    {
        { "filter.type", new Java.Lang.String("price") },
        { "filter.value", new Java.Lang.String("high_to_low") }
    }
);
```

### Tracking Network Requests

```csharp
var rumMonitor = GlobalRumMonitor.Get();
var requestKey = Guid.NewGuid().ToString();

// Start tracking a resource
rumMonitor.StartResource(
    requestKey,
    RumResourceMethod.Get,
    "https://api.example.com/users",
    new Dictionary<string, Java.Lang.Object>
    {
        { "api.version", new Java.Lang.String("v2") }
    }
);

try
{
    var client = new HttpClient();
    var response = await client.GetAsync("https://api.example.com/users");
    var content = await response.Content.ReadAsStringAsync();

    // Stop tracking resource on success
    rumMonitor.StopResource(
        requestKey,
        (int)response.StatusCode,
        content.Length,
        RumResourceKind.Native,
        new Dictionary<string, Java.Lang.Object>
        {
            { "response.cached", new Java.Lang.Boolean(false) }
        }
    );
}
catch (Exception ex)
{
    // Stop tracking resource with error
    rumMonitor.StopResourceWithError(
        requestKey,
        "Network request failed",
        RumErrorSource.Network,
        new Java.Lang.Exception(ex.Message),
        new Dictionary<string, Java.Lang.Object>
        {
            { "error.type", new Java.Lang.String(ex.GetType().Name) }
        }
    );
}
```

### Tracking Errors

```csharp
var rumMonitor = GlobalRumMonitor.Get();

// Track a generic error
rumMonitor.AddError(
    "Failed to load user data",
    RumErrorSource.Source,
    null,
    new Dictionary<string, Java.Lang.Object>
    {
        { "user.id", new Java.Lang.String("12345") }
    }
);

// Track an exception
try
{
    ProcessData();
}
catch (Exception ex)
{
    rumMonitor.AddError(
        ex.Message,
        RumErrorSource.Source,
        new Java.Lang.Exception(ex.Message),
        new Dictionary<string, Java.Lang.Object>
        {
            { "error.stack", new Java.Lang.String(ex.StackTrace ?? "") },
            { "error.type", new Java.Lang.String(ex.GetType().Name) }
        }
    );
}
```

### Adding Custom Timing

```csharp
var rumMonitor = GlobalRumMonitor.Get();

// Add a custom timing metric
rumMonitor.AddTiming("data_loaded");
rumMonitor.AddTiming("ui_ready");
```

## Configuration Options

### RumConfiguration Builder Options

| Method | Description | Default |
|--------|-------------|---------|
| `.TrackLongTasks(threshold)` | Track tasks blocking main thread | 100ms threshold |
| `.TrackFrustrations(enabled)` | Track user frustrations (rage taps, etc.) | `true` |
| `.TrackBackgroundEvents(enabled)` | Track events when app backgrounded | `false` |
| `.TrackNonFatalAnrs(enabled)` | Track Application Not Responding | `true` |
| `.SetSessionSampleRate(rate)` | Sample rate for sessions (0-100) | `100.0` |
| `.SetTelemetrySampleRate(rate)` | Sample rate for telemetry (0-100) | `20.0` |

### RUM Action Types

- `RumActionType.Tap` - Touch/tap actions
- `RumActionType.Swipe` - Swipe gestures
- `RumActionType.Scroll` - Scroll actions
- `RumActionType.Custom` - Custom user actions
- `RumActionType.Back` - Back button presses

### RUM Resource Methods

- `RumResourceMethod.Get`
- `RumResourceMethod.Post`
- `RumResourceMethod.Put`
- `RumResourceMethod.Delete`
- `RumResourceMethod.Head`
- `RumResourceMethod.Patch`

### RUM Resource Kinds

- `RumResourceKind.Native` - Native code resources
- `RumResourceKind.Image` - Image resources
- `RumResourceKind.Xhr` - XMLHttpRequest
- `RumResourceKind.Beacon` - Beacon requests
- `RumResourceKind.Fetch` - Fetch API requests
- `RumResourceKind.Document` - Document resources

### RUM Error Sources

- `RumErrorSource.Network` - Network errors
- `RumErrorSource.Source` - Source code errors
- `RumErrorSource.Console` - Console errors
- `RumErrorSource.Custom` - Custom errors

## API Reference

### RUM Initialization

| Native API (Kotlin/Java) | .NET Binding |
|--------------------------|--------------|
| `RUM.enable(config)` | `Datadog.Android.Rum.Rum.Enable(config)` |
| `RumConfiguration.Builder(appId)` | `new RumConfiguration.Builder(appId)` |
| `.trackLongTasks(threshold)` | `.TrackLongTasks(threshold)` |
| `.trackFrustrations(enabled)` | `.TrackFrustrations(enabled)` |
| `.build()` | `.Build()` |

### RUM Monitor Access

| Native API (Kotlin/Java) | .NET Binding |
|--------------------------|--------------|
| `GlobalRumMonitor.get()` | `GlobalRumMonitor.Get()` |
| `GlobalRumMonitor.get()` | `GlobalRumMonitor.Instance` |

### View Tracking

| Native API (Kotlin/Java) | .NET Binding |
|--------------------------|--------------|
| `monitor.startView(key, name, attrs)` | `monitor.StartView(key, name, attrs)` |
| `monitor.stopView(key, attrs)` | `monitor.StopView(key, attrs)` |
| `monitor.addTiming(name)` | `monitor.AddTiming(name)` |

### Action Tracking

| Native API (Kotlin/Java) | .NET Binding |
|--------------------------|--------------|
| `monitor.addAction(type, name, attrs)` | `monitor.AddAction(type, name, attrs)` |
| `RumActionType.TAP` | `RumActionType.Tap` |
| `RumActionType.SWIPE` | `RumActionType.Swipe` |

### Resource Tracking

| Native API (Kotlin/Java) | .NET Binding |
|--------------------------|--------------|
| `monitor.startResource(key, method, url, attrs)` | `monitor.StartResource(key, method, url, attrs)` |
| `monitor.stopResource(key, status, size, kind, attrs)` | `monitor.StopResource(key, status, size, kind, attrs)` |
| `monitor.stopResourceWithError(key, msg, src, error, attrs)` | `monitor.StopResourceWithError(key, msg, src, error, attrs)` |

### Error Tracking

| Native API (Kotlin/Java) | .NET Binding |
|--------------------------|--------------|
| `monitor.addError(msg, source, throwable, attrs)` | `monitor.AddError(msg, source, throwable, attrs)` |
| `RumErrorSource.NETWORK` | `RumErrorSource.Network` |
| `RumErrorSource.SOURCE` | `RumErrorSource.Source` |

## Related Documentation

- **Official Datadog Docs**: [Android RUM](https://docs.datadoghq.com/real_user_monitoring/android/)
- **Advanced Configuration**: [RUM Advanced Configuration](https://docs.datadoghq.com/real_user_monitoring/mobile_and_tv_monitoring/advanced_configuration/android/)
- **Datadog Android SDK**: [GitHub Repository](https://github.com/DataDog/dd-sdk-android)
- **Error Tracking**: [Mobile Error Tracking](https://docs.datadoghq.com/real_user_monitoring/error_tracking/mobile/android/)

## Important Notes

1. **Initialize Core First**: Core SDK must be initialized before calling `Rum.Enable()`
2. **Application ID Required**: You need a RUM Application ID from Datadog
3. **View Tracking**: Each view must have a unique key for proper tracking
4. **Resource Keys**: Use unique keys (like GUIDs) for each network request
5. **Dictionary Values**: Use `Java.Lang.Object` types for all dictionary values

## Troubleshooting

**Issue**: RUM data not appearing in Datadog
- Verify Application ID is correct
- Ensure `Rum.Enable()` was called after Core SDK initialization
- Check that `TrackingConsent.Granted` is set
- Verify network connectivity

**Issue**: Views not tracked properly
- Ensure `StartView()` is called in `OnResume()`
- Ensure `StopView()` is called in `OnPause()`
- Use consistent view keys

**Issue**: Network requests not showing
- Ensure you call both `StartResource()` and `StopResource()` (or `StopResourceWithError()`)
- Use unique keys for each request
- Verify resource method and kind are correct

## License

This package is licensed under the MIT License. See the LICENSE file for details.

### NOTICE

This package includes software developed at Datadog (https://www.datadoghq.com/).

Those portions are Copyright 2019 Datadog, Inc.

For more information, please refer to the [Datadog Android SDK repository](https://github.com/DataDog/dd-sdk-android).
