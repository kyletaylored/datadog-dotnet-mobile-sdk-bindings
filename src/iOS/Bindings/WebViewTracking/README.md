# Datadog iOS SDK - WebView Tracking Bindings

.NET bindings for the Datadog iOS SDK WebViewTracking framework.

## Overview

WebView Tracking enables you to forward logs and RUM events captured in a WKWebView to Datadog, linking them with your mobile session.

**Package Information:**
- **NuGet Package**: `Bcr.Datadog.iOS.WebViewTracking`
- **Target Frameworks**: `net8.0-ios17.0`, `net9.0-ios18.0`
- **Namespace**: `Datadog.iOS.WebViewTracking`

## Requirements

- iOS 17.0+
- .NET 8 or higher
- **Prerequisite**: `Bcr.Datadog.iOS.ObjC` must be installed and initialized

## Installation

```xml
<ItemGroup>
  <PackageReference Include="Bcr.Datadog.iOS.ObjC" Version="2.26.0" />
  <PackageReference Include="Bcr.Datadog.iOS.WebViewTracking" Version="2.26.0" />
</ItemGroup>
```

## Implementation Guide

```csharp
using Foundation;
using UIKit;
using WebKit;
using CoreGraphics;
using Datadog.iOS.ObjC;
using Datadog.iOS.WebViewTracking;

namespace MyApp;

public class WebViewController : UIViewController
{
    private WKWebView? _webView;

    public override void ViewDidLoad()
    {
        base.ViewDidLoad();

        // Create WebView
        var config = new WKWebViewConfiguration();
        _webView = new WKWebView(View!.Bounds, config);

        // Enable Datadog tracking for this WebView
        DDWebViewTracking.Enable(_webView);

        // Load content
        var url = new NSUrl("https://example.com");
        var request = new NSUrlRequest(url);
        _webView.LoadRequest(request);

        View.AddSubview(_webView);
    }
}
```

## Sample Usage

```csharp
using Foundation;
using UIKit;
using WebKit;
using Datadog.iOS.ObjC;
using Datadog.iOS.WebViewTracking;

namespace MyApp;

[Register("AppDelegate")]
public class AppDelegate : UIApplicationDelegate
{
    public override bool FinishedLaunching(UIApplication application, NSDictionary launchOptions)
    {
        // Initialize Datadog SDK
        var config = new DDConfiguration("YOUR_CLIENT_TOKEN", "production");
        config.Service = "my-ios-app";
        DDDatadog.Initialize(config, DDTrackingConsent.Granted);

        // Enable RUM
        var rumConfig = new DDRUMConfiguration("YOUR_APPLICATION_ID");
        DDRUM.Enable(rumConfig);

        // WebView tracking is enabled per-webview instance
        // See WebViewController example above

        return true;
    }
}
```

## API Reference

| Native API | .NET Binding |
|-----------|--------------|
| `WebViewTracking.enable(webView:)` | `DDWebViewTracking.Enable(webView)` |

## Related Documentation

- **Official Docs**: [WebView Tracking](https://docs.datadoghq.com/real_user_monitoring/mobile_and_tv_monitoring/web_view_tracking/?tab=ios)
- **Datadog iOS SDK**: [GitHub](https://github.com/DataDog/dd-sdk-ios)

## License

This project is licensed under the [MIT License](LICENSE).

This product includes software developed at Datadog (https://www.datadoghq.com/), used under the [Apache License, v2.0](https://github.com/DataDog/dd-sdk-ios/blob/develop/LICENSE)

Those portions are Copyright 2019 Datadog, Inc.
