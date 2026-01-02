# Datadog Android SDK - WebView Tracking Bindings

.NET bindings for the Datadog Android SDK WebView library (`com.datadog.android:dd-sdk-android-webview`).

## Overview

WebView Tracking enables you to forward logs and RUM events captured in a WebView to Datadog, linking them with the mobile session for complete visibility.

**Package Information:**
- **NuGet Package**: `Bcr.Datadog.Android.Sdk.WebView`
- **Native Artifact**: `com.datadog.android:dd-sdk-android-webview:2.21.0`
- **Namespace**: `Datadog.Android.WebView`

## Installation

```xml
<ItemGroup>
  <PackageReference Include="Bcr.Datadog.Android.Sdk.Core" Version="2.21.0-pre.1" />
  <PackageReference Include="Bcr.Datadog.Android.Sdk.Rum" Version="2.21.0-pre.1" />
  <PackageReference Include="Bcr.Datadog.Android.Sdk.WebView" Version="2.21.0-pre.1" />
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

### Step 2: Enable WebView Tracking

```csharp
using Datadog.Android.WebView;
using Android.Webkit;

var webView = FindViewById<WebView>(Resource.Id.webview);

// Enable tracking for this WebView
WebViewTracking.Enable(webView, allowedHosts: new[] { "example.com", "myapp.com" });

// Configure WebView settings
webView.Settings.JavaScriptEnabled = true;
webView.LoadUrl("https://example.com");
```

## Sample Usage

```csharp
using Android.App;
using Android.OS;
using Android.Webkit;
using Datadog.Android;
using Datadog.Android.Core.Configuration;
using Datadog.Android.Privacy;
using Datadog.Android.Rum;
using Datadog.Android.WebView;

namespace MyApp;

[Activity(Label = "@string/app_name")]
public class WebViewActivity : Activity
{
    private WebView? _webView;

    protected override void OnCreate(Bundle? savedInstanceState)
    {
        base.OnCreate(savedInstanceState);
        SetContentView(Resource.Layout.activity_webview);

        // Initialize Datadog (if not already done)
        var config = new DDConfiguration.Builder(
            "YOUR_CLIENT_TOKEN", "production", string.Empty, "my-app"
        ).Build();
        Datadog.Initialize(this, config, TrackingConsent.Granted);

        var rumConfig = new RumConfiguration.Builder("YOUR_APPLICATION_ID").Build();
        Datadog.Android.Rum.Rum.Enable(rumConfig);

        // Setup WebView
        _webView = FindViewById<WebView>(Resource.Id.webview);

        // Enable Datadog tracking
        WebViewTracking.Enable(
            _webView,
            allowedHosts: new[] { "example.com", "myapp.com" }
        );

        // Configure WebView
        _webView.Settings.JavaScriptEnabled = true;
        _webView.Settings.DomStorageEnabled = true;

        // Load content
        _webView.LoadUrl("https://example.com/app");
    }
}
```

## API Reference

| Native API (Kotlin/Java) | .NET Binding |
|--------------------------|--------------|
| `WebViewTracking.enable(webView, hosts)` | `WebViewTracking.Enable(webView, allowedHosts)` |

## Related Documentation

- **Official Docs**: [WebView Tracking](https://docs.datadoghq.com/real_user_monitoring/mobile_and_tv_monitoring/web_view_tracking/?tab=android)
- **Datadog Android SDK**: [GitHub](https://github.com/DataDog/dd-sdk-android)

## License

This package is licensed under the MIT License. See the LICENSE file for details.

### NOTICE

This package includes software developed at Datadog (https://www.datadoghq.com/).

Those portions are Copyright 2019 Datadog, Inc.

For more information, please refer to the [Datadog Android SDK repository](https://github.com/DataDog/dd-sdk-android).
