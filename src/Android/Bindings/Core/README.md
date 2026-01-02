# Datadog Android SDK - Core Bindings

.NET bindings for the Datadog Android SDK Core library (`com.datadog.android:dd-sdk-android-core`).

## Overview

The Core binding provides the foundational functionality for the Datadog Android SDK. It is **required** for all other Datadog features (RUM, Logs, Trace, etc.) and must be initialized before enabling any additional features.

**Key Capabilities:**
- SDK initialization and configuration
- User tracking and session management
- Network connectivity detection
- Data upload management
- Privacy and consent tracking
- Custom attributes and tags

**Package Information:**
- **NuGet Package**: `Bcr.Datadog.Android.Sdk.Core`
- **Native Artifact**: `com.datadog.android:dd-sdk-android-core:2.21.0`
- **Namespace**: `Datadog.Android`

## Requirements

- .NET 10 (required due to Android 16KB page size and binding fixes)
- Android API Level 26+ (Android 8.0 Oreo)
- Java SDK configured (`JAVA_HOME`)

## Installation

Add the NuGet package to your `.csproj`:

```xml
<ItemGroup>
  <PackageReference Include="Bcr.Datadog.Android.Sdk.Core" Version="2.21.0-pre.1" />
</ItemGroup>
```

## Implementation Guide

### Step 1: Configure the SDK

Create a `DDConfiguration` instance with your Datadog credentials:

```csharp
using Datadog.Android.Core.Configuration;
using Datadog.Android.Privacy;

var configuration = new DDConfiguration.Builder(
    clientToken: "YOUR_CLIENT_TOKEN",
    env: "production",
    variantName: string.Empty,
    serviceName: "my-android-app"
)
.UseSite(DatadogSite.Us1)  // US1, US3, US5, EU1, AP1, US1Fed
.SetBatchSize(BatchSize.Medium)
.SetUploadFrequency(UploadFrequency.Frequent)
.Build();
```

### Step 2: Initialize Datadog

Initialize the SDK in your `MainActivity.OnCreate()` method **before** enabling any features:

```csharp
using Datadog.Android;

[Activity(Label = "@string/app_name", MainLauncher = true)]
public class MainActivity : Activity
{
    protected override void OnCreate(Bundle? savedInstanceState)
    {
        base.OnCreate(savedInstanceState);

        // Initialize Datadog SDK
        Datadog.Initialize(
            this,                        // Android Context
            configuration,               // Configuration from Step 1
            TrackingConsent.Granted      // User consent
        );

        // Optional: Set verbosity for debugging
        Datadog.Verbosity = (int)Android.Util.LogPriority.Verbose;

        // Now you can enable features (RUM, Logs, etc.)
        // ... feature initialization ...

        SetContentView(Resource.Layout.activity_main);
    }
}
```

### Step 3: Configure User Tracking (Optional)

Add user information to enrich your data:

```csharp
using Datadog.Android;

Datadog.SetUserInfo(
    id: "user-12345",
    name: "John Doe",
    email: "john.doe@example.com",
    extraInfo: new Dictionary<string, Java.Lang.Object>
    {
        { "plan", new Java.Lang.String("premium") },
        { "signup_date", new Java.Lang.String("2025-01-01") }
    }
);
```

### Step 4: Set Global Tracking Consent

Control data collection based on user consent:

```csharp
using Datadog.Android.Privacy;

// User granted consent
Datadog.SetTrackingConsent(TrackingConsent.Granted);

// User declined consent
Datadog.SetTrackingConsent(TrackingConsent.NotGranted);

// Pending user response
Datadog.SetTrackingConsent(TrackingConsent.Pending);
```

## Sample Usage

### Complete Initialization Example

```csharp
using Android.App;
using Android.OS;
using Datadog.Android;
using Datadog.Android.Core.Configuration;
using Datadog.Android.Privacy;

namespace MyApp;

[Activity(Label = "@string/app_name", MainLauncher = true)]
public class MainActivity : Activity
{
    protected override void OnCreate(Bundle? savedInstanceState)
    {
        base.OnCreate(savedInstanceState);

        // 1. Build configuration
        var config = new DDConfiguration.Builder(
            clientToken: "pub1234567890abcdef1234567890abcd",
            env: "production",
            variantName: string.Empty,
            serviceName: "my-android-app"
        )
        .UseSite(DatadogSite.Us1)
        .SetBatchSize(BatchSize.Medium)
        .SetUploadFrequency(UploadFrequency.Frequent)
        .TrackCrashes(true)
        .Build();

        // 2. Initialize SDK
        Datadog.Initialize(this, config, TrackingConsent.Granted);
        Datadog.Verbosity = (int)Android.Util.LogPriority.Debug;

        // 3. Set user information
        Datadog.SetUserInfo(
            "user-123",
            "John Doe",
            "john@example.com",
            new Dictionary<string, Java.Lang.Object>
            {
                { "subscription", new Java.Lang.String("premium") }
            }
        );

        // 4. Add global attributes
        Datadog.AddAttribute("app.version", "1.0.0");
        Datadog.AddAttribute("device.type", "phone");

        // 5. Enable features (example)
        // Logs.Enable(...);
        // Rum.Enable(...);

        SetContentView(Resource.Layout.activity_main);
    }
}
```

### Adding Global Tags

```csharp
// Add tags that will be applied to all data
Datadog.AddTag("env", "production");
Datadog.AddTag("team", "mobile");
Datadog.AddTag("region", "us-east");
```

### Removing Attributes or Tags

```csharp
// Remove a specific attribute
Datadog.RemoveAttribute("device.type");

// Remove a specific tag
Datadog.RemoveTag("region");
```

### Managing Tracking Consent Dynamically

```csharp
public class PrivacyManager
{
    public void OnUserAcceptsTracking()
    {
        // User accepted - start collecting data
        Datadog.SetTrackingConsent(TrackingConsent.Granted);
    }

    public void OnUserDeclinesTracking()
    {
        // User declined - stop collecting data
        Datadog.SetTrackingConsent(TrackingConsent.NotGranted);
    }

    public void OnUserDismissesPrompt()
    {
        // User hasn't decided yet - buffer data
        Datadog.SetTrackingConsent(TrackingConsent.Pending);
    }
}
```

## Configuration Options

### Datadog Sites

| Site | Description | Configuration |
|------|-------------|---------------|
| US1 | US (default) | `DatadogSite.Us1` |
| US3 | US3 | `DatadogSite.Us3` |
| US5 | US5 | `DatadogSite.Us5` |
| EU1 | Europe | `DatadogSite.Eu1` |
| AP1 | Asia Pacific | `DatadogSite.Ap1` |
| US1_FED | US1 Federal | `DatadogSite.Us1Fed` |

### Batch Size Options

Controls how much data is batched before upload:

- `BatchSize.Small` - Smaller batches, more frequent uploads
- `BatchSize.Medium` - Balanced (default)
- `BatchSize.Large` - Larger batches, fewer uploads

### Upload Frequency Options

Controls how often data is uploaded:

- `UploadFrequency.Frequent` - Upload more often
- `UploadFrequency.Average` - Balanced (default)
- `UploadFrequency.Rare` - Upload less frequently

### Tracking Consent Values

- `TrackingConsent.Granted` - User has granted consent, collect all data
- `TrackingConsent.NotGranted` - User has declined consent, do not collect data
- `TrackingConsent.Pending` - Waiting for user consent, buffer data locally

## API Reference

### Core Initialization

| Native API (Kotlin/Java) | .NET Binding |
|--------------------------|--------------|
| `Datadog.initialize(context, config, consent)` | `Datadog.Initialize(context, config, consent)` |
| `Datadog.setVerbosity(priority)` | `Datadog.Verbosity = (int)LogPriority.Verbose` |
| `Configuration.Builder(...)` | `DDConfiguration.Builder(...)` |
| `.useSite(site)` | `.UseSite(site)` |
| `.setBatchSize(size)` | `.SetBatchSize(size)` |
| `.setUploadFrequency(freq)` | `.SetUploadFrequency(freq)` |

### User Tracking

| Native API (Kotlin/Java) | .NET Binding |
|--------------------------|--------------|
| `Datadog.setUserInfo(id, name, email, extra)` | `Datadog.SetUserInfo(id, name, email, extra)` |
| `Datadog.addUserProperties(props)` | `Datadog.AddUserProperties(props)` |

### Attributes & Tags

| Native API (Kotlin/Java) | .NET Binding |
|--------------------------|--------------|
| `Datadog.addAttribute(key, value)` | `Datadog.AddAttribute(key, value)` |
| `Datadog.removeAttribute(key)` | `Datadog.RemoveAttribute(key)` |
| `Datadog.addTag(key, value)` | `Datadog.AddTag(key, value)` |
| `Datadog.removeTag(key)` | `Datadog.RemoveTag(key)` |

### Consent Management

| Native API (Kotlin/Java) | .NET Binding |
|--------------------------|--------------|
| `Datadog.setTrackingConsent(consent)` | `Datadog.SetTrackingConsent(consent)` |
| `TrackingConsent.GRANTED` | `TrackingConsent.Granted` |
| `TrackingConsent.NOT_GRANTED` | `TrackingConsent.NotGranted` |
| `TrackingConsent.PENDING` | `TrackingConsent.Pending` |

## Related Documentation

- **Official Datadog Android SDK**: [GitHub Repository](https://github.com/DataDog/dd-sdk-android)
- **Datadog Android Documentation**: [Getting Started](https://docs.datadoghq.com/real_user_monitoring/mobile_and_tv_monitoring/setup/android/)
- **SDK Configuration**: [Advanced Configuration](https://docs.datadoghq.com/real_user_monitoring/mobile_and_tv_monitoring/advanced_configuration/android/)
- **Privacy & Compliance**: [Data Collection](https://docs.datadoghq.com/data_security/real_user_monitoring/)

## Important Notes

1. **Initialization Order**: Core SDK **must** be initialized before enabling any features (RUM, Logs, Trace)
2. **.NET 10 Requirement**: Android bindings require .NET 10 due to 16KB page size support
3. **Context Requirement**: Android `Context` (typically `this` in Activity) is required for initialization
4. **Dictionary Values**: Use `Java.Lang.Object` types for dictionary values (e.g., `new Java.Lang.String("value")`)

## Troubleshooting

**Issue**: "Datadog.Initialize() not found"
- Ensure `Bcr.Datadog.Android.Sdk.Core` is installed
- Check that you're using `using Datadog.Android;`

**Issue**: Dictionary conversion errors
- Wrap strings in `Java.Lang.String`: `new Java.Lang.String("value")`
- Use `Java.Lang.Object` as dictionary value type

**Issue**: No data appearing in Datadog
- Verify client token is correct
- Check that `TrackingConsent.Granted` is set
- Ensure network connectivity
- Increase verbosity to see debug logs: `Datadog.Verbosity = (int)Android.Util.LogPriority.Verbose`

## License

This package is licensed under the MIT License. See the LICENSE file for details.

### NOTICE

This package includes software developed at Datadog (https://www.datadoghq.com/).

Those portions are Copyright 2019 Datadog, Inc.

For more information, please refer to the [Datadog Android SDK repository](https://github.com/DataDog/dd-sdk-android).
