# Datadog Android SDK - NDK Crash Reporting Bindings

.NET bindings for the Datadog Android SDK NDK library (`com.datadog.android:dd-sdk-android-ndk`).

## Overview

NDK Crash Reporting enables tracking of crashes from native (C/C++) libraries in your Android application, providing complete crash visibility alongside your managed code crashes.

**Package Information:**
- **NuGet Package**: `Bcr.Datadog.Android.Sdk.Ndk`
- **Native Artifact**: `com.datadog.android:dd-sdk-android-ndk:2.21.0`
- **Namespace**: `Datadog.Android.Ndk`

## Installation

```xml
<ItemGroup>
  <PackageReference Include="Bcr.Datadog.Android.Sdk.Core" Version="2.21.0-pre.1" />
  <PackageReference Include="Bcr.Datadog.Android.Sdk.Rum" Version="2.21.0-pre.1" />
  <PackageReference Include="Bcr.Datadog.Android.Sdk.Ndk" Version="2.21.0-pre.1" />
</ItemGroup>
```

## Implementation Guide

### Step 1: Initialize Core SDK and Enable RUM

```csharp
using Datadog.Android;
using Datadog.Android.Core.Configuration;
using Datadog.Android.Privacy;
using Datadog.Android.Rum;

var config = new DDConfiguration.Builder(
    "YOUR_CLIENT_TOKEN", "production", string.Empty, "my-app"
).Build();
Datadog.Initialize(this, config, TrackingConsent.Granted);

var rumConfig = new RumConfiguration.Builder("YOUR_APPLICATION_ID").Build();
Datadog.Android.Rum.Rum.Enable(rumConfig);
```

### Step 2: Enable NDK Crash Reporting

```csharp
using Datadog.Android.Ndk;

NdkCrashReports.Enable();
```

## Sample Usage

```csharp
using Android.App;
using Android.OS;
using Datadog.Android;
using Datadog.Android.Core.Configuration;
using Datadog.Android.Ndk;
using Datadog.Android.Privacy;
using Datadog.Android.Rum;

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
            .Build();
        Datadog.Android.Rum.Rum.Enable(rumConfig);

        // Enable NDK crash reporting
        NdkCrashReports.Enable();

        SetContentView(Resource.Layout.activity_main);
    }
}
```

## API Reference

| Native API (Kotlin/Java) | .NET Binding |
|--------------------------|--------------|
| `NdkCrashReports.enable()` | `NdkCrashReports.Enable()` |

## Related Documentation

- **Official Docs**: [NDK Crash Reporting](https://docs.datadoghq.com/real_user_monitoring/error_tracking/mobile/android/?tab=us#add-ndk-crash-reporting)
- **Datadog Android SDK**: [GitHub](https://github.com/DataDog/dd-sdk-android)

## Important Notes

- **RUM Required**: NDK crash reporting requires RUM to be enabled
- **Native Crashes Only**: This tracks crashes from native (C/C++) code, not managed .NET exceptions

## License

This package is licensed under the MIT License. See the LICENSE file for details.

### NOTICE

This package includes software developed at Datadog (https://www.datadoghq.com/).

Those portions are Copyright 2019 Datadog, Inc.

For more information, please refer to the [Datadog Android SDK repository](https://github.com/DataDog/dd-sdk-android).
