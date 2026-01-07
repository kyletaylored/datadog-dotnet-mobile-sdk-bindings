# Datadog iOS SDK - Session Replay Bindings

.NET bindings for the Datadog iOS SDK SessionReplay framework.

## Overview

Session Replay allows you to record and replay user sessions, providing visual insights into user interactions and behaviors in your iOS application.

**Package Information:**
- **NuGet Package**: `Bcr.Datadog.iOS.SessionReplay`
- **Target Frameworks**: `net9.0-ios`, `net10.0-ios`
- **Namespace**: `Datadog.iOS.SessionReplay`

## Requirements

- iOS 17.0+
- .NET 9 or 10
- **Prerequisite**: `Bcr.Datadog.iOS.ObjC` must be installed and initialized

## Installation

```xml
<ItemGroup>
  <PackageReference Include="Bcr.Datadog.iOS.ObjC" Version="3.4.0" />
  <PackageReference Include="Bcr.Datadog.iOS.SessionReplay" Version="3.4.0" />
</ItemGroup>
```

## Implementation Guide

```csharp
using Foundation;
using UIKit;
using Datadog.iOS.ObjC;
using Datadog.iOS.SessionReplay;

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

        // Enable RUM (required for Session Replay)
        var rumConfig = new DDRUMConfiguration("YOUR_APPLICATION_ID");
        rumConfig.SessionSampleRate = 100.0f;
        DDRUM.Enable(rumConfig);

        // Enable Session Replay
        var replayConfig = new DDSessionReplayConfiguration(
            100.0f,                                  // Sample rate (100%)
            DDTextAndInputPrivacyLevel.MaskAll,      // Text privacy
            DDImagePrivacyLevel.MaskAll,             // Image privacy
            DDTouchPrivacyLevel.Hide                 // Touch privacy
        );
        DDSessionReplay.Enable(replayConfig);

        return true;
    }
}
```

## Configuration Options

### Privacy Levels

**Text and Input Privacy:**
- `DDTextAndInputPrivacyLevel.MaskAll` - Mask all text and input
- `DDTextAndInputPrivacyLevel.MaskSensitiveInputs` - Mask only sensitive inputs
- `DDTextAndInputPrivacyLevel.Allow` - Record all text

**Image Privacy:**
- `DDImagePrivacyLevel.MaskAll` - Mask all images
- `DDImagePrivacyLevel.MaskNonBundledOnly` - Mask non-bundled images
- `DDImagePrivacyLevel.MaskNone` - Show all images

**Touch Privacy:**
- `DDTouchPrivacyLevel.Hide` - Hide all touches
- `DDTouchPrivacyLevel.Show` - Show all touches

## API Reference

| Native API | .NET Binding |
|-----------|--------------|
| `SessionReplay.enable(with:)` | `DDSessionReplay.Enable(config)` |
| `SessionReplayConfiguration(replaySampleRate:textAndInputPrivacy:imagePrivacy:touchPrivacy:)` | `new DDSessionReplayConfiguration(rate, textPrivacy, imagePrivacy, touchPrivacy)` |

## Related Documentation

- **Official Docs**: [Session Replay](https://docs.datadoghq.com/real_user_monitoring/session_replay/mobile/setup_and_configuration/?tab=ios)
- **Datadog iOS SDK**: [GitHub](https://github.com/DataDog/dd-sdk-ios)

## License

This project is licensed under the [MIT License](LICENSE).

This product includes software developed at Datadog (https://www.datadoghq.com/), used under the [Apache License, v2.0](https://github.com/DataDog/dd-sdk-ios/blob/develop/LICENSE)

Those portions are Copyright 2019 Datadog, Inc.
