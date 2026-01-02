# Datadog Android SDK - Session Replay Bindings

.NET bindings for the Datadog Android SDK SessionReplay library (`com.datadog.android:dd-sdk-android-session-replay`).

## Overview

Session Replay allows you to record and replay user sessions in your Android application, providing visual insights into user interactions and behaviors.

**Package Information:**
- **NuGet Package**: `Bcr.Datadog.Android.Sdk.SessionReplay`
- **Native Artifact**: `com.datadog.android:dd-sdk-android-session-replay:2.21.0`
- **Namespace**: `Datadog.Android.SessionReplay`

## Installation

```xml
<ItemGroup>
  <PackageReference Include="Bcr.Datadog.Android.Sdk.Core" Version="2.21.0-pre.1" />
  <PackageReference Include="Bcr.Datadog.Android.Sdk.Rum" Version="2.21.0-pre.1" />
  <PackageReference Include="Bcr.Datadog.Android.Sdk.SessionReplay" Version="2.21.0-pre.1" />
</ItemGroup>
```

## Implementation Guide

### Step 1: Initialize Core SDK and Enable RUM

```csharp
using Datadog.Android;
using Datadog.Android.Core.Configuration;
using Datadog.Android.Privacy;
using Datadog.Android.Rum;

// Initialize Core
var config = new DDConfiguration.Builder(
    "YOUR_CLIENT_TOKEN", "production", string.Empty, "my-app"
).Build();
Datadog.Initialize(this, config, TrackingConsent.Granted);

// Enable RUM (required for Session Replay)
var rumConfig = new RumConfiguration.Builder("YOUR_APPLICATION_ID")
    .Build();
Datadog.Android.Rum.Rum.Enable(rumConfig);
```

### Step 2: Enable Session Replay

```csharp
using Datadog.Android.SessionReplay;

var replayConfig = new SessionReplayConfiguration.Builder(100.0f) // 100% sample rate
    .SetPrivacy(SessionReplayPrivacy.Mask)  // MASK, ALLOW, or MASK_USER_INPUT
    .Build();

SessionReplay.Enable(replayConfig);
```

## Sample Usage

```csharp
using Android.App;
using Android.OS;
using Datadog.Android;
using Datadog.Android.Core.Configuration;
using Datadog.Android.Privacy;
using Datadog.Android.Rum;
using Datadog.Android.SessionReplay;

namespace MyApp;

[Activity(Label = "@string/app_name", MainLauncher = true)]
public class MainActivity : Activity
{
    protected override void OnCreate(Bundle? savedInstanceState)
    {
        base.OnCreate(savedInstanceState);

        // Initialize Datadog
        var config = new DDConfiguration.Builder(
            "YOUR_CLIENT_TOKEN", "production", string.Empty, "my-app"
        ).Build();
        Datadog.Initialize(this, config, TrackingConsent.Granted);

        // Enable RUM
        var rumConfig = new RumConfiguration.Builder("YOUR_APPLICATION_ID")
            .TrackFrustrations(true)
            .Build();
        Datadog.Android.Rum.Rum.Enable(rumConfig);

        // Enable Session Replay
        var replayConfig = new SessionReplayConfiguration.Builder(100.0f)
            .SetPrivacy(SessionReplayPrivacy.MaskUserInput)
            .Build();
        SessionReplay.Enable(replayConfig);

        SetContentView(Resource.Layout.activity_main);
    }
}
```

## Configuration Options

### Privacy Levels

- `SessionReplayPrivacy.Allow` - Record all content
- `SessionReplayPrivacy.Mask` - Mask all text and input fields
- `SessionReplayPrivacy.MaskUserInput` - Mask only user input fields

## API Reference

| Native API (Kotlin/Java) | .NET Binding |
|--------------------------|--------------|
| `SessionReplay.enable(config)` | `SessionReplay.Enable(config)` |
| `SessionReplayConfiguration.Builder(rate)` | `new SessionReplayConfiguration.Builder(rate)` |
| `.setPrivacy(privacy)` | `.SetPrivacy(privacy)` |

## Related Documentation

- **Official Docs**: [Session Replay Setup](https://docs.datadoghq.com/real_user_monitoring/session_replay/mobile/setup_and_configuration/?tab=android)
- **Datadog Android SDK**: [GitHub](https://github.com/DataDog/dd-sdk-android)

## License

This package is licensed under the MIT License. See the LICENSE file for details.

### NOTICE

This package includes software developed at Datadog (https://www.datadoghq.com/).

Those portions are Copyright 2019 Datadog, Inc.

For more information, please refer to the [Datadog Android SDK repository](https://github.com/DataDog/dd-sdk-android).
