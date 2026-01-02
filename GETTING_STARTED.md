# Getting Started with Datadog .NET Mobile SDK Bindings

This guide provides detailed instructions for integrating Datadog monitoring into your .NET for Android, .NET for iOS, or .NET MAUI applications.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Initialization](#initialization)
  - [Android Setup](#android-setup)
  - [iOS Setup](#ios-setup)
  - [.NET MAUI Setup](#net-maui-setup)
- [Feature Configuration](#feature-configuration)
  - [Logging](#logging)
  - [Real User Monitoring (RUM)](#real-user-monitoring-rum)
  - [Distributed Tracing](#distributed-tracing)
  - [Session Replay](#session-replay)
  - [WebView Tracking](#webview-tracking)
  - [Crash Reporting](#crash-reporting)
- [API Mapping Reference](#api-mapping-reference)
- [Common Patterns](#common-patterns)
- [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Development Environment

- **For Android**:
  - .NET 10 SDK
  - Android API Level 26+ (Android 8.0 Oreo)
  - Java SDK configured (`JAVA_HOME` environment variable set)
  - Android development workload installed

- **For iOS**:
  - .NET 10 SDK (or .NET 8/9)
  - macOS with Xcode
  - iOS 17.0+ deployment target
  - iOS development workload installed

### Datadog Account

Before you begin, you'll need:
1. A Datadog account (sign up at [datadoghq.com](https://www.datadoghq.com/))
2. Your **Client Token** (from Datadog portal)
3. Your **Application ID** (for RUM features)
4. Your **Datadog Site** (e.g., US1, EU1, US3, US5, AP1)

---

## Installation

### Android

Add the following NuGet packages to your `.csproj` file:

```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net10.0-android</TargetFramework>
    <SupportedOSPlatformVersion>26</SupportedOSPlatformVersion>
  </PropertyGroup>

  <ItemGroup>
    <!-- Core SDK (required) -->
    <PackageReference Include="Bcr.Datadog.Android.Sdk.Core" Version="2.21.0-pre.1" />

    <!-- Add features you need -->
    <PackageReference Include="Bcr.Datadog.Android.Sdk.Logs" Version="2.21.0-pre.1" />
    <PackageReference Include="Bcr.Datadog.Android.Sdk.Rum" Version="2.21.0-pre.1" />
    <PackageReference Include="Bcr.Datadog.Android.Sdk.Trace" Version="2.21.0-pre.1" />
    <PackageReference Include="Bcr.Datadog.Android.Sdk.SessionReplay" Version="2.21.0-pre.1" />
    <PackageReference Include="Bcr.Datadog.Android.Sdk.Ndk" Version="2.21.0-pre.1" />

    <!-- Optional: AndroidX dependencies to resolve warnings -->
    <PackageReference Include="Xamarin.AndroidX.Collection.Ktx" Version="1.4.5.2" />
    <PackageReference Include="Xamarin.AndroidX.Lifecycle.Runtime.Ktx" Version="2.8.7.2" />
  </ItemGroup>
</Project>
```

### iOS

Add the following NuGet packages to your `.csproj` file:

```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net10.0-ios</TargetFramework>
    <SupportedOSPlatformVersion>17.0</SupportedOSPlatformVersion>
  </PropertyGroup>

  <ItemGroup>
    <!-- Core SDK (required) -->
    <PackageReference Include="Bcr.Datadog.iOS.Sdk.ObjC" Version="2.x.x" />

    <!-- Add features you need -->
    <PackageReference Include="Bcr.Datadog.iOS.Sdk.DDLogs" Version="2.x.x" />
    <PackageReference Include="Bcr.Datadog.iOS.Sdk.Rum" Version="2.x.x" />
    <PackageReference Include="Bcr.Datadog.iOS.Sdk.Trace" Version="2.x.x" />
    <PackageReference Include="Bcr.Datadog.iOS.Sdk.SessionReplay" Version="2.x.x" />
    <PackageReference Include="Bcr.Datadog.iOS.Sdk.CrashReporting" Version="2.x.x" />
    <PackageReference Include="Bcr.Datadog.iOS.Sdk.WebViewTracking" Version="2.x.x" />
  </ItemGroup>
</Project>
```

---

## Initialization

### Android Setup

Initialize Datadog in your `MainActivity.cs` **before** any other Datadog API calls:

```csharp
using Android.App;
using Android.OS;
using Datadog.Android.Core.Configuration;
using Datadog.Android.Log;
using Datadog.Android.Rum;
using Datadog.Android.Privacy;

namespace MyApp;

[Activity(Label = "@string/app_name", MainLauncher = true)]
public class MainActivity : Activity
{
    protected override void OnCreate(Bundle? savedInstanceState)
    {
        base.OnCreate(savedInstanceState);

        // Step 1: Configure the SDK
        var configuration = new DDConfiguration.Builder(
            clientToken: "YOUR_CLIENT_TOKEN",
            env: "production",
            variantName: string.Empty,
            serviceName: "my-android-app"
        )
        .UseSite(DatadogSite.Us1) // Set your Datadog site
        .SetBatchSize(BatchSize.Medium)
        .SetUploadFrequency(UploadFrequency.Frequent)
        .Build();

        // Step 2: Initialize Datadog SDK
        Datadog.Android.Datadog.Initialize(this, configuration, TrackingConsent.Granted);

        // Step 3: Set verbosity level (optional, for debugging)
        Datadog.Android.Datadog.Verbosity = (int)Android.Util.LogPriority.Debug;

        // Step 4: Enable features (see sections below)
        EnableLogging();
        EnableRUM();

        SetContentView(Resource.Layout.activity_main);
    }

    private void EnableLogging()
    {
        var logsConfig = new LogsConfiguration.Builder()
            .Build();
        Logs.Enable(logsConfig);
    }

    private void EnableRUM()
    {
        var rumConfig = new RumConfiguration.Builder("YOUR_APPLICATION_ID")
            .TrackLongTasks()
            .TrackFrustrations(true)
            .TrackBackgroundEvents(true)
            .TrackNonFatalAnrs(true)
            .Build();

        Datadog.Android.Rum.Rum.Enable(rumConfig);
    }
}
```

### iOS Setup

Initialize Datadog in your `AppDelegate.cs` inside `FinishedLaunching`:

```csharp
using Foundation;
using UIKit;
using Datadog.iOS.ObjC;
using Datadog.iOS.CrashReporting;
using Datadog.iOS.SessionReplay;

namespace MyApp;

[Register("AppDelegate")]
public class AppDelegate : UIApplicationDelegate
{
    public override UIWindow? Window { get; set; }

    public override bool FinishedLaunching(UIApplication application, NSDictionary launchOptions)
    {
        // Step 1: Configure the SDK
        var configuration = new DDConfiguration(
            clientToken: "YOUR_CLIENT_TOKEN",
            env: "production"
        );
        configuration.Service = "my-ios-app";
        configuration.Site = DDDatadogSite.Us1; // Set your Datadog site

        // Step 2: Initialize Datadog SDK
        DDDatadog.Initialize(configuration, DDTrackingConsent.Granted);

        // Step 3: Set verbosity level (optional, for debugging)
        DDDatadog.VerbosityLevel = DDSDKVerbosityLevel.Debug;

        // Step 4: Enable features
        EnableLogging();
        EnableRUM();
        EnableCrashReporting();

        // Your UI setup code...
        Window = new UIWindow(UIScreen.MainScreen.Bounds);
        return true;
    }

    private void EnableLogging()
    {
        DDLogs.Enable(new DDLogsConfiguration(null));
    }

    private void EnableRUM()
    {
        var rumConfig = new DDRUMConfiguration("YOUR_APPLICATION_ID");
        rumConfig.SessionSampleRate = 100.0f; // 100% of sessions
        DDRUM.Enable(rumConfig);
    }

    private void EnableCrashReporting()
    {
        DDCrashReporter.Enable();
    }
}
```

### .NET MAUI Setup

For .NET MAUI, use platform-specific initialization in each platform's entry point:

#### Platforms/Android/MainActivity.cs

```csharp
using Android.App;
using Android.Content.PM;
using Android.OS;
using Datadog.Android.Core.Configuration;
using Datadog.Android.Privacy;

namespace MyMauiApp;

[Activity(Theme = "@style/Maui.SplashTheme", MainLauncher = true,
    ConfigurationChanges = ConfigChanges.ScreenSize | ConfigChanges.Orientation)]
public class MainActivity : MauiAppCompatActivity
{
    protected override void OnCreate(Bundle? savedInstanceState)
    {
        #if ANDROID
        InitializeDatadog();
        #endif

        base.OnCreate(savedInstanceState);
    }

    private void InitializeDatadog()
    {
        var config = new DDConfiguration.Builder(
            "YOUR_CLIENT_TOKEN",
            "production",
            string.Empty,
            "my-maui-app"
        )
        .UseSite(DatadogSite.Us1)
        .Build();

        Datadog.Android.Datadog.Initialize(this, config, TrackingConsent.Granted);

        // Enable features...
    }
}
```

#### Platforms/iOS/AppDelegate.cs

```csharp
using Foundation;
using UIKit;
using Datadog.iOS.ObjC;

namespace MyMauiApp;

[Register("AppDelegate")]
public class AppDelegate : MauiUIApplicationDelegate
{
    protected override MauiApp CreateMauiApp() => MauiProgram.CreateMauiApp();

    public override bool FinishedLaunching(UIApplication application, NSDictionary launchOptions)
    {
        #if IOS
        InitializeDatadog();
        #endif

        return base.FinishedLaunching(application, launchOptions);
    }

    private void InitializeDatadog()
    {
        var config = new DDConfiguration(
            "YOUR_CLIENT_TOKEN",
            "production"
        );
        config.Service = "my-maui-app";
        config.Site = DDDatadogSite.Us1;

        DDDatadog.Initialize(config, DDTrackingConsent.Granted);

        // Enable features...
    }
}
```

---

## Feature Configuration

### Logging

#### Android

```csharp
using Datadog.Android.Log;

// Enable logging
var logsConfig = new LogsConfiguration.Builder()
    .Build();
Logs.Enable(logsConfig);

// Create a logger
var logger = new Logger.Builder()
    .SetName("MyLogger")
    .SetNetworkInfoEnabled(true)
    .SetLogcatLogsEnabled(true)
    .Build();

// Log messages
logger.D("Debug message", null, null);
logger.I("Info message", null, null);
logger.W("Warning message", null, null);
logger.E("Error message", null, null);

// Log with attributes
logger.D("User action", null, new Dictionary<string, Java.Lang.Object>
{
    { "user.id", new Java.Lang.String("12345") },
    { "action.type", new Java.Lang.String("button_click") }
});

// Log exceptions
try
{
    throw new Exception("Something went wrong");
}
catch (Exception ex)
{
    var javaException = new Java.Lang.Exception(ex.Message);
    logger.E("Exception occurred", javaException, new Dictionary<string, Java.Lang.Object>
    {
        { "error.stack", new Java.Lang.String(ex.StackTrace ?? "") }
    });
}
```

#### iOS

```csharp
using Datadog.iOS.ObjC;
using Foundation;

// Enable logging
DDLogs.Enable(new DDLogsConfiguration(null));

// Create a logger
var logConfig = new DDLoggerConfiguration();
logConfig.Service = "my-ios-app";
logConfig.NetworkInfoEnabled = true;
logConfig.PrintLogsToConsole = true;
logConfig.BundleWithRumEnabled = true;

var logger = DDLogger.Create(logConfig);

// Log messages
logger.Debug("Debug message");
logger.Info("Info message");
logger.Warn("Warning message");
logger.Error("Error message");

// Log with attributes
var attributes = new NSDictionary<NSString, NSObject>(
    new NSString("user.id"), new NSString("12345"),
    new NSString("action.type"), new NSString("button_click")
);
logger.Debug("User action", attributes);

// Log exceptions
try
{
    throw new Exception("Something went wrong");
}
catch (Exception ex)
{
    var nsError = new NSError(
        new NSString("ERROR_DOMAIN"),
        1001,
        new NSDictionary<NSString, NSObject>(
            NSError.LocalizedDescriptionKey,
            new NSString(ex.Message)
        )
    );

    var errorAttributes = new NSDictionary<NSString, NSObject>(
        new NSString("error.stack"),
        new NSString(ex.StackTrace ?? "")
    );

    logger.Error(ex.Message, nsError, errorAttributes);
}
```

### Real User Monitoring (RUM)

#### Android

```csharp
using Datadog.Android.Rum;

// Enable RUM
var rumConfig = new RumConfiguration.Builder("YOUR_APPLICATION_ID")
    .TrackLongTasks()                    // Track tasks blocking UI thread
    .TrackFrustrations(true)             // Track user frustrations (rage taps, etc.)
    .TrackBackgroundEvents(true)         // Track events when app is backgrounded
    .TrackNonFatalAnrs(true)             // Track Application Not Responding events
    .SetSessionSampleRate(100.0f)        // Sample 100% of sessions
    .Build();

Datadog.Android.Rum.Rum.Enable(rumConfig);

// Get the global RUM monitor
var rumMonitor = GlobalRumMonitor.Get();

// Track views
rumMonitor.StartView("HomeScreen", "Home", new Dictionary<string, Java.Lang.Object>());
rumMonitor.StopView("HomeScreen", new Dictionary<string, Java.Lang.Object>());

// Track user actions
rumMonitor.AddAction(
    RumActionType.Tap,
    "login_button",
    new Dictionary<string, Java.Lang.Object>
    {
        { "button.label", new Java.Lang.String("Login") }
    }
);

// Track resources (network calls)
rumMonitor.StartResource(
    "api_call_123",
    RumResourceMethod.Get,
    "https://api.example.com/users",
    new Dictionary<string, Java.Lang.Object>()
);

rumMonitor.StopResource(
    "api_call_123",
    200,
    1024L, // size in bytes
    RumResourceKind.Native,
    new Dictionary<string, Java.Lang.Object>()
);

// Track errors
rumMonitor.AddError(
    "Network timeout",
    RumErrorSource.Network,
    new Java.Lang.Exception("Connection timeout"),
    new Dictionary<string, Java.Lang.Object>()
);
```

#### iOS

```csharp
using Datadog.iOS.ObjC;
using Foundation;

// Enable RUM
var rumConfig = new DDRUMConfiguration("YOUR_APPLICATION_ID");
rumConfig.SessionSampleRate = 100.0f;
rumConfig.TrackBackgroundEvents = true;
rumConfig.TrackFrustrations = true;

DDRUM.Enable(rumConfig);

// Get the global RUM monitor
var rumMonitor = DDRUMMonitor.Shared;

// Track views
rumMonitor.StartView("HomeViewController", "Home", new NSDictionary());
rumMonitor.StopView("HomeViewController", new NSDictionary());

// Track user actions
rumMonitor.AddAction(
    DDRUMActionType.Tap,
    "login_button",
    new NSDictionary<NSString, NSObject>(
        new NSString("button.label"),
        new NSString("Login")
    )
);

// Track resources
var resourceKey = "api_call_123";
rumMonitor.StartResource(
    resourceKey,
    DDRUMMethod.Get,
    new NSUrl("https://api.example.com/users"),
    new NSDictionary()
);

rumMonitor.StopResource(
    resourceKey,
    200,
    DDRUMResourceType.Native,
    1024,
    new NSDictionary()
);

// Track errors
rumMonitor.AddError(
    "Network timeout",
    DDRUMErrorSource.Network,
    null,
    new NSDictionary<NSString, NSObject>(
        new NSString("error.message"),
        new NSString("Connection timeout")
    )
);
```

### Distributed Tracing

#### Android

```csharp
using Datadog.Android.Trace;

// Enable tracing
var traceConfig = new TraceConfiguration.Builder().Build();
Trace.Enable(traceConfig);

// Get the global tracer
var tracer = AndroidTracer.Builder().Build();

// Create spans
var span = tracer.BuildSpan("network.request").Start();
span.SetTag("http.url", "https://api.example.com/users");
span.SetTag("http.method", "GET");

try
{
    // Your operation here
}
catch (Exception ex)
{
    span.SetTag("error", true);
    span.SetTag("error.message", ex.Message);
}
finally
{
    span.Finish();
}
```

#### iOS

```csharp
using Datadog.iOS.ObjC;

// Enable tracing
DDTrace.Enable(new DDTraceConfiguration());

// Get the shared tracer
var tracer = DDTracer.Shared;

// Create spans
var span = tracer.StartSpan("network.request", new NSDictionary(), null);
span.SetTag("http.url", "https://api.example.com/users");
span.SetTag("http.method", "GET");

try
{
    // Your operation here
}
catch (Exception ex)
{
    span.SetTag("error", true);
    span.SetTag("error.message", ex.Message);
}
finally
{
    span.Finish();
}
```

### Session Replay

#### Android

```csharp
using Datadog.Android.SessionReplay;

// Enable Session Replay
var replayConfig = new SessionReplayConfiguration.Builder(100.0f) // 100% sample rate
    .SetPrivacy(SessionReplayPrivacy.Mask) // MASK, ALLOW, or MASK_USER_INPUT
    .Build();

SessionReplay.Enable(replayConfig);
```

#### iOS

```csharp
using Datadog.iOS.SessionReplay;

// Enable Session Replay
var replayConfig = new DDSessionReplayConfiguration(
    100.0f,                                    // Sample rate
    DDTextAndInputPrivacyLevel.MaskAll,        // Text privacy
    DDImagePrivacyLevel.MaskAll,               // Image privacy
    DDTouchPrivacyLevel.Hide                   // Touch privacy
);

DDSessionReplay.Enable(replayConfig);
```

### WebView Tracking

#### Android

```csharp
using Datadog.Android.WebView;
using Android.Webkit;

// Enable WebView tracking
WebViewTracking.Enable(myWebView, allowedHosts: new[] { "example.com" });

// Configure WebView
myWebView.Settings.JavaScriptEnabled = true;
myWebView.LoadUrl("https://example.com");
```

#### iOS

```csharp
using Datadog.iOS.WebViewTracking;
using WebKit;
using CoreGraphics;

// Enable WebView tracking
var webView = new WKWebView(CGRect.Empty, new WKWebViewConfiguration());
DDWebViewTracking.Enable(webView);

// Load content
webView.LoadRequest(new NSUrlRequest(new NSUrl("https://example.com")));
```

### Crash Reporting

#### Android

```csharp
using Datadog.Android.Ndk;

// Enable NDK crash reporting (for native crashes)
NdkCrashReports.Enable();
```

#### iOS

```csharp
using Datadog.iOS.CrashReporting;

// Enable crash reporting
DDCrashReporter.Enable();
```

---

## API Mapping Reference

This table helps you translate between native SDK documentation and .NET bindings:

### Core SDK

| Feature | Native (Android) | .NET Android Binding |
|---------|------------------|---------------------|
| Initialize | `Datadog.initialize(context, config, consent)` | `Datadog.Android.Datadog.Initialize(context, config, consent)` |
| Set verbosity | `Datadog.setVerbosity(priority)` | `Datadog.Android.Datadog.Verbosity = (int)LogPriority.Verbose` |
| Configuration | `Configuration.Builder(...)` | `DDConfiguration.Builder(...)` |
| Set site | `.useSite(site)` | `.UseSite(site)` |

| Feature | Native (iOS) | .NET iOS Binding |
|---------|--------------|-----------------|
| Initialize | `Datadog.initialize(configuration: config, trackingConsent: consent)` | `DDDatadog.Initialize(config, consent)` |
| Set verbosity | `Datadog.verbosityLevel = .debug` | `DDDatadog.VerbosityLevel = DDSDKVerbosityLevel.Debug` |
| Configuration | `Datadog.Configuration(...)` | `DDConfiguration(...)` |

### Logging

| Feature | Native (Android) | .NET Android Binding |
|---------|------------------|---------------------|
| Enable logs | `Logs.enable(config)` | `Logs.Enable(config)` |
| Create logger | `Logger.Builder().build()` | `new Logger.Builder().Build()` |
| Log debug | `logger.d("message", attributes)` | `logger.D("message", null, attributes)` |
| Log error | `logger.e("message", throwable, attributes)` | `logger.E("message", exception, attributes)` |

| Feature | Native (iOS) | .NET iOS Binding |
|---------|--------------|-----------------|
| Enable logs | `Logs.enable(with: config)` | `DDLogs.Enable(config)` |
| Create logger | `Logger.create(with: config)` | `DDLogger.Create(config)` |
| Log debug | `logger.debug("message", attributes: attrs)` | `logger.Debug("message", attributes)` |
| Log error | `logger.error("message", error: error, attributes: attrs)` | `logger.Error("message", error, attributes)` |

### RUM

| Feature | Native (Android) | .NET Android Binding |
|---------|------------------|---------------------|
| Enable RUM | `RUM.enable(config)` | `Datadog.Android.Rum.Rum.Enable(config)` |
| Get monitor | `GlobalRumMonitor.get()` | `GlobalRumMonitor.Get()` |
| Start view | `monitor.startView(key, name, attributes)` | `monitor.StartView(key, name, attributes)` |
| Add action | `monitor.addAction(type, name, attributes)` | `monitor.AddAction(type, name, attributes)` |
| Add error | `monitor.addError(message, source, throwable, attributes)` | `monitor.AddError(message, source, throwable, attributes)` |

| Feature | Native (iOS) | .NET iOS Binding |
|---------|--------------|-----------------|
| Enable RUM | `RUM.enable(with: config)` | `DDRUM.Enable(config)` |
| Get monitor | `RUMMonitor.shared()` | `DDRUMMonitor.Shared` |
| Start view | `monitor.startView(key: key, name: name, attributes: attrs)` | `monitor.StartView(key, name, attributes)` |
| Add action | `monitor.addAction(type: type, name: name, attributes: attrs)` | `monitor.AddAction(type, name, attributes)` |
| Add error | `monitor.addError(message: msg, source: src, attributes: attrs)` | `monitor.AddError(message, source, null, attributes)` |

### Tracing

| Feature | Native (Android) | .NET Android Binding |
|---------|------------------|---------------------|
| Enable tracing | `Trace.enable(config)` | `Trace.Enable(config)` |
| Build tracer | `AndroidTracer.Builder().build()` | `AndroidTracer.Builder().Build()` |
| Create span | `tracer.buildSpan(operationName).start()` | `tracer.BuildSpan(operationName).Start()` |

| Feature | Native (iOS) | .NET iOS Binding |
|---------|--------------|-----------------|
| Enable tracing | `Trace.enable(with: config)` | `DDTrace.Enable(config)` |
| Get tracer | `Tracer.shared()` | `DDTracer.Shared` |
| Create span | `tracer.startSpan(operationName: name)` | `tracer.StartSpan(name, tags, startTime)` |

---

## Common Patterns

### Pattern 1: Adding Custom User Information

#### Android
```csharp
using Datadog.Android;

Datadog.SetUserInfo(
    id: "user-123",
    name: "John Doe",
    email: "john@example.com",
    extraInfo: new Dictionary<string, Java.Lang.Object>
    {
        { "subscription", new Java.Lang.String("premium") }
    }
);
```

#### iOS
```csharp
using Datadog.iOS.ObjC;

DDDatadog.SetUserInfo(
    "user-123",                              // id
    "John Doe",                              // name
    "john@example.com",                      // email
    new NSDictionary<NSString, NSObject>(    // extra info
        new NSString("subscription"),
        new NSString("premium")
    )
);
```

### Pattern 2: Manual RUM View Tracking

#### Android
```csharp
public class MyActivity : Activity
{
    protected override void OnResume()
    {
        base.OnResume();
        GlobalRumMonitor.Get().StartView(
            "MyActivity",
            "My Screen",
            new Dictionary<string, Java.Lang.Object>()
        );
    }

    protected override void OnPause()
    {
        GlobalRumMonitor.Get().StopView(
            "MyActivity",
            new Dictionary<string, Java.Lang.Object>()
        );
        base.OnPause();
    }
}
```

#### iOS
```csharp
public class MyViewController : UIViewController
{
    public override void ViewDidAppear(bool animated)
    {
        base.ViewDidAppear(animated);
        DDRUMMonitor.Shared.StartView(
            "MyViewController",
            "My Screen",
            new NSDictionary()
        );
    }

    public override void ViewDidDisappear(bool animated)
    {
        DDRUMMonitor.Shared.StopView(
            "MyViewController",
            new NSDictionary()
        );
        base.ViewDidDisappear(animated);
    }
}
```

### Pattern 3: Tracking Network Requests

#### Android
```csharp
using System.Net.Http;
using Datadog.Android.Rum;

var client = new HttpClient();
var requestKey = Guid.NewGuid().ToString();
var rumMonitor = GlobalRumMonitor.Get();

try
{
    rumMonitor.StartResource(
        requestKey,
        RumResourceMethod.Get,
        "https://api.example.com/data",
        new Dictionary<string, Java.Lang.Object>()
    );

    var response = await client.GetAsync("https://api.example.com/data");
    var content = await response.Content.ReadAsStringAsync();

    rumMonitor.StopResource(
        requestKey,
        (int)response.StatusCode,
        content.Length,
        RumResourceKind.Native,
        new Dictionary<string, Java.Lang.Object>()
    );
}
catch (Exception ex)
{
    rumMonitor.StopResourceWithError(
        requestKey,
        ex.Message,
        RumErrorSource.Network,
        new Java.Lang.Exception(ex.Message),
        new Dictionary<string, Java.Lang.Object>()
    );
}
```

#### iOS
```csharp
using System.Net.Http;
using Datadog.iOS.ObjC;

var client = new HttpClient();
var requestKey = Guid.NewGuid().ToString();
var rumMonitor = DDRUMMonitor.Shared;

try
{
    rumMonitor.StartResource(
        requestKey,
        DDRUMMethod.Get,
        new NSUrl("https://api.example.com/data"),
        new NSDictionary()
    );

    var response = await client.GetAsync("https://api.example.com/data");
    var content = await response.Content.ReadAsStringAsync();

    rumMonitor.StopResource(
        requestKey,
        (int)response.StatusCode,
        DDRUMResourceType.Native,
        content.Length,
        new NSDictionary()
    );
}
catch (Exception ex)
{
    rumMonitor.StopResourceWithError(
        requestKey,
        ex.Message,
        DDRUMErrorSource.Network,
        new NSDictionary<NSString, NSObject>(
            new NSString("error.message"),
            new NSString(ex.Message)
        )
    );
}
```

---

## Troubleshooting

### Android Issues

**Problem: "Could not find method ... on type ..."**
- Ensure you're using .NET 10 (required for Android binding fixes)
- Verify all required AndroidX packages are installed
- Check that `JAVA_HOME` is properly configured

**Problem: APIs not found at runtime**
- Make sure you've called `Initialize()` before using features
- Verify the correct packages are referenced
- Check that features are enabled (e.g., `Rum.Enable()` before using RUM)

**Problem: Dictionary conversion issues**
- Use `Java.Lang.Object` for dictionary values
- Wrap strings in `Java.Lang.String`: `new Java.Lang.String("value")`
- Example: `new Dictionary<string, Java.Lang.Object> { { "key", new Java.Lang.String("value") } }`

### iOS Issues

**Problem: "Could not find type ..."**
- Ensure all iOS NuGet packages are installed
- Verify deployment target is iOS 17.0+
- Check that Xcode command line tools are installed

**Problem: NSDictionary creation errors**
- Use the correct NSDictionary constructor: `new NSDictionary<NSString, NSObject>(...)`
- Wrap strings: `new NSString("value")`
- For errors, use `NSError` with proper error domain

**Problem: Initialization not working**
- Must initialize in `FinishedLaunching`, not in a constructor
- Check that client token and application ID are correct
- Verify site configuration matches your Datadog account

### General Issues

**Problem: No data appearing in Datadog**
- Verify network connectivity
- Check client token and application ID are correct
- Ensure consent is set to `Granted`
- Increase verbosity level to see debug logs
- Check Datadog site configuration matches your account region

**Problem: Build errors about missing types**
- Run `dotnet restore` or clean and rebuild
- Ensure NuGet packages are properly restored
- For Android, verify Java SDK is configured

---

## Next Steps

- Explore [Android binding samples](src/Android/Bindings/Test/TestBindings/)
- Explore [iOS binding samples](src/iOS/T/)
- Review [Official Datadog Documentation](https://docs.datadoghq.com/)
- Check [Android SDK repository](https://github.com/DataDog/dd-sdk-android)
- Check [iOS SDK repository](https://github.com/DataDog/dd-sdk-ios)

For binding-specific issues, please open an issue in this repository.
