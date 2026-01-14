using Datadog.Android.Core.Configuration;
using Datadog.Android.Log;
using Datadog.Android.Ndk;
using Datadog.Android.Privacy;
using Datadog.Android.Rum;
using Datadog.Android.SessionReplay;
using Datadog.Android.Trace;
using Datadog.Android.WebView;
using Object = Java.Lang.Object;
using System.Collections.Generic;

#pragma warning disable CS8604 // Possible null reference argument.

namespace TestApp;

/// <summary>
/// Comprehensive test app demonstrating all Datadog Android SDK features.
///
/// This MainActivity serves as both a functional test and live code reference
/// for the Datadog .NET Android bindings. Each feature section includes:
/// - Configuration examples with inline documentation
/// - Usage examples demonstrating key functionality
/// - References to detailed README documentation
///
/// Feature Documentation:
/// - Core SDK: src/Android/Bindings/Core/README.md
/// - Logs: src/Android/Bindings/DatadogLogs/README.md
/// - NDK: src/Android/Bindings/Ndk/README.md
/// - RUM: src/Android/Bindings/Rum/README.md
/// - Session Replay: src/Android/Bindings/SessionReplay/README.md
/// - Trace: src/Android/Bindings/Trace/README.md
/// - WebView: src/Android/Bindings/WebView/README.md
/// </summary>
[Activity(Label = "@string/app_name", MainLauncher = true)]
public class MainActivity : Activity
{
    private Logger? _logger;
    private IRumMonitor? _rumMonitor;

    protected override void OnCreate(Bundle? savedInstanceState)
    {
        base.OnCreate(savedInstanceState);

        // =============================================================================
        // 1. CORE SDK - Initialization
        // =============================================================================
        // The Core SDK must be initialized before any other Datadog features.
        // Documentation: src/Android/Bindings/Core/README.md

        // Configure first-party hosts for automatic trace injection
        IList<string> firstPartyHosts = new List<string> { "localhost", "api.example.com" };

        var config = new DDConfiguration.Builder(
                "<CLIENT_TOKEN>",      // Your Datadog client token
                "<ENV>",               // Environment (e.g., "production", "staging")
                string.Empty,          // Variant (optional, use empty string if not needed)
                "<SERVICE_NAME>"       // Service name (e.g., "my-android-app")
            )
            .UseSite(Datadog.Android.DatadogSite.US1)    // Datadog site (US1, US3, US5, EU1, AP1, US1_FED)
            .SetCrashReportsEnabled(true)                 // Enable crash reporting
            .SetFirstPartyHosts(firstPartyHosts)          // Hosts for automatic trace injection
            .SetBatchSize(Datadog.Android.Core.Configuration.BatchSize.Medium)  // Batch size for uploads
            .SetUploadFrequency(Datadog.Android.Core.Configuration.UploadFrequency.Average)  // Upload frequency
            .Build();

        // Initialize the SDK with tracking consent granted
        Datadog.Android.Datadog.Initialize(this, config, TrackingConsent.Granted);

        // Set verbosity for debugging (Verbose shows all internal SDK logs)
        Datadog.Android.Datadog.Verbosity = (int)Android.Util.LogPriority.Verbose;

        // Set user information (optional - can be updated anytime)
        Datadog.Android.Datadog.SetUserInfo(
            id: "12345",
            name: "John Doe",
            email: "john.doe@example.com",
            extraInfo: new Dictionary<string, Object>
            {
                { "plan", (string)("premium") },
                { "signup_date", (string)("2024-01-15") }
            }
        );

        // =============================================================================
        // 2. LOGS SDK - Structured Logging
        // =============================================================================
        // The Logs SDK enables structured logging with support for multiple log levels,
        // custom attributes, and exception tracking.
        // Documentation: src/Android/Bindings/DatadogLogs/README.md

        var logsConfig = new LogsConfiguration.Builder()
            .Build();
        Logs.Enable(logsConfig);

        // Create a logger instance with custom configuration
        _logger = new Logger.Builder()
            .SetName("MainActivity")                      // Logger name (appears in Datadog)
            .SetNetworkInfoEnabled(true)                  // Include network info in logs
            .SetLogcatLogsEnabled(true)                   // Also write to Android logcat
            .SetBundleWithRumEnabled(true)                // Bundle logs with RUM events
            .SetBundleWithTraceEnabled(true)              // Bundle logs with traces
            .SetRemoteSampleRate(100.0f)                  // Sample rate (0-100)
            .Build();

        // Add global attributes to all logs from this logger
        _logger.AddAttribute("app.version", "1.0.0");
        _logger.AddAttribute("build.number", "42");
        _logger.AddTag("platform", "android");

        // Example: Log messages with different severity levels
        _logger.D("Debug message - detailed info for debugging", null, new Dictionary<string, Object>());

        _logger.I("Application started", null, new Dictionary<string, Object>
        {
            { "screen", (string)("MainActivity") },
            { "startup_time_ms", (long)(DateTimeOffset.UtcNow.ToUnixTimeMilliseconds()) }
        });

        _logger.W("Warning message - something unusual happened", null, new Dictionary<string, Object>
        {
            { "warning.type", (string)("api_slow_response") },
            { "duration.ms", (long)(5000) }
        });

        // Example: Log exception with stack trace
        try
        {
            // Simulate an exception
            throw new InvalidOperationException("Example exception for testing");
        }
        catch (Exception ex)
        {
            _logger.E(
                "Exception occurred during startup",
                new Java.Lang.Exception(ex.Message),  // Wrap .NET exception
                new Dictionary<string, Object>
                {
                    { "error.stack", (string)(ex.StackTrace ?? "") },
                    { "error.type", (string)(ex.GetType().Name) },
                    { "error.message", (string)(ex.Message) }
                }
            );
        }

        // =============================================================================
        // 3. NDK CRASH REPORTS - Native Crash Reporting
        // =============================================================================
        // Enable NDK crash reporting to capture native (C/C++) crashes.
        // Documentation: src/Android/Bindings/Ndk/README.md

        NdkCrashReports.Enable();
        _logger?.I("NDK crash reporting enabled", null, new Dictionary<string, Object>());

        // =============================================================================
        // 4. RUM SDK - Real User Monitoring
        // =============================================================================
        // RUM tracks user interactions, views, actions, resources, and errors.
        // Documentation: src/Android/Bindings/Rum/README.md

        var rumConfiguration = new RumConfiguration.Builder("<RUM_APP_ID>")  // Your RUM application ID
            .SetSessionSampleRate(100.0f)                 // Sample 100% of sessions
            .TrackUserInteractions()                      // Track taps, scrolls, swipes
            .TrackLongTasks(100)                          // Track long tasks (threshold in ms)
            .TrackFrustrations(true)                      // Track user frustrations
            .TrackBackgroundEvents(true)                  // Track events when app is backgrounded
            .TrackNonFatalAnrs(true)                      // Track non-fatal ANRs (Android Not Responding)
            .Build();

        Datadog.Android.Rum.Rum.Enable(rumConfiguration);

        // Get the global RUM monitor instance
        _rumMonitor = Datadog.Android.Rum.GlobalRumMonitor.Get();

        // Start a view (typically done in each Activity/Fragment)
        _rumMonitor?.StartView(
            key: this.GetType().Name,
            name: "MainActivity",
            attributes: new Dictionary<string, Object>
            {
                { "screen.type", (string)("main") },
                { "feature", (string)("demo") }
            }
        );

        // Add global RUM attributes (included in all RUM events)
        _rumMonitor?.AddAttribute("app.theme", "light");
        _rumMonitor?.AddAttribute("user.tier", "premium");

        // Example: Track a user action
        _rumMonitor?.AddAction(
            type: RumActionType.Tap,
            name: "app_start_action",
            attributes: new Dictionary<string, Object>
            {
                { "action.target", (string)("MainActivity") },
                { "action.timestamp", (long)(DateTimeOffset.UtcNow.ToUnixTimeMilliseconds()) }
            }
        );

        _logger?.I("RUM monitoring enabled", null, new Dictionary<string, Object>
        {
            { "rum.app_id", (string)("<RUM_APP_ID>") },
            { "session.sample_rate", (float)(100.0f) }
        });

        // =============================================================================
        // 5. SESSION REPLAY - Record User Sessions
        // =============================================================================
        // Session Replay records user sessions with configurable privacy settings.
        // Documentation: src/Android/Bindings/SessionReplay/README.md

        var sessionReplayConfig = new SessionReplayConfiguration.Builder(100.0f)  // Sample rate (0-100)
            .SetImagePrivacy(ImagePrivacy.MaskAll)                     // Mask all images
            .SetTouchPrivacy(TouchPrivacy.Hide)                        // Hide touch interactions
            .SetTextAndInputPrivacy(TextAndInputPrivacy.MaskAllInputs) // Mask all input fields
            .StartRecordingImmediately(true)                           // Start recording immediately
            .Build();

        // Enable Session Replay (use fully qualified name to avoid namespace conflict)
        Datadog.Android.SessionReplay.SessionReplay.Enable(sessionReplayConfig);

        _logger?.I("Session Replay enabled", null, new Dictionary<string, Object>
        {
            { "replay.sample_rate", (float)(100.0f) },
            { "replay.privacy", (string)("mask_all") }
        });

        // Session Replay can be controlled programmatically:
        // SessionReplay.StartRecording()  // Start recording
        // SessionReplay.StopRecording()   // Stop recording

        // =============================================================================
        // 6. TRACE SDK - APM and Distributed Tracing
        // =============================================================================
        // The Trace SDK enables APM tracing with automatic trace injection.
        // Documentation: src/Android/Bindings/Trace/README.md

        var traceConfig = new TraceConfiguration.Builder()
            .SetNetworkInfoEnabled(true)                  // Include network info in traces
            .Build();

        Datadog.Android.Trace.Trace.Enable(traceConfig);

        _logger?.I("APM tracing enabled", null, new Dictionary<string, Object>
        {
            { "trace.network_info", (bool)(true) }
        });

        // To create custom spans, use the DatadogTracing API:
        // var tracer = DatadogTracing.NewTracerBuilder().Build();
        // var span = tracer.BuildSpan("operation_name").Start();
        // try { /* work */ } finally { span.Finish(); }

        // =============================================================================
        // 7. WEBVIEW TRACKING - Track WebView Content
        // =============================================================================
        // WebView tracking enables RUM and logging from web content.
        // Documentation: src/Android/Bindings/WebView/README.md

        // Uncomment to enable WebView tracking:
        // var allowedHosts = new List<string> { "example.com", "api.example.com" };
        // var webView = FindViewById<Android.Webkit.WebView>(Resource.Id.webview);
        // if (webView != null)
        // {
        //     WebViewTracking.Enable(webView, allowedHosts, 100.0f);
        //     _logger?.I("WebView tracking enabled", null, new Dictionary<string, Object>
        //     {
        //         { "allowed_hosts", (string)(string.Join(", ", allowedHosts)) }
        //     });
        // }

        // =============================================================================
        // DEMO: Simulate User Interactions
        // =============================================================================

        SimulateUserInteraction();

        // Set our view from the "main" layout resource
        SetContentView(Resource.Layout.activity_main);
    }

    /// <summary>
    /// Simulates a user interaction to demonstrate RUM action tracking and error logging.
    /// </summary>
    private void SimulateUserInteraction()
    {
        // Track a button click action
        _rumMonitor?.AddAction(
            type: RumActionType.Tap,
            name: "simulate_button_click",
            attributes: new Dictionary<string, Object>
            {
                { "button.id", (string)("demo_button") },
                { "button.label", (string)("Simulate Action") }
            }
        );

        _logger?.D("Button clicked - simulating user action", null, new Dictionary<string, Object>
        {
            { "button.id", (string)("demo_button") },
            { "timestamp", (long)(DateTimeOffset.UtcNow.ToUnixTimeMilliseconds()) }
        });

        try
        {
            // Simulate a resource load (e.g., API call)
            var resourceKey = "api_call_get_user_data";
            _rumMonitor?.StartResource(
                key: resourceKey,
                method: RumResourceMethod.Get,
                url: "https://api.example.com/users/12345",
                attributes: new Dictionary<string, Object>
                {
                    { "api.endpoint", (string)("/users/:id") },
                    { "api.version", (string)("v1") }
                }
            );

            // Simulate processing
            System.Threading.Thread.Sleep(100);

            // Stop the resource successfully (parameters: key, statusCode, size, kind, attributes)
            _rumMonitor?.StopResource(
                resourceKey,
                (int)(200),
                (long)(1024),
                RumResourceKind.Native,
                new Dictionary<string, Object>
                {
                    { "response.cached", (bool)(false) }
                }
            );

            _logger?.I("Resource loaded successfully", null, new Dictionary<string, Object>
            {
                { "resource.url", (string)("https://api.example.com/users/12345") },
                { "resource.status", (int)(200) },
                { "resource.size_bytes", (long)(1024) }
            });
        }
        catch (Exception ex)
        {
            // Track error in RUM
            _rumMonitor?.AddError(
                message: "Failed to load user data",
                source: RumErrorSource.Network,
                throwable: new Java.Lang.Exception(ex.Message),
                attributes: new Dictionary<string, Object>
                {
                    { "error.stack", (string)(ex.StackTrace ?? "") },
                    { "error.type", (string)(ex.GetType().Name) }
                }
            );

            // Log error
            _logger?.E(
                "Failed to load resource",
                new Java.Lang.Exception(ex.Message),
                new Dictionary<string, Object>
                {
                    { "error.stack", (string)(ex.StackTrace ?? "") },
                    { "error.type", (string)(ex.GetType().Name) },
                    { "resource.url", (string)("https://api.example.com/users/12345") }
                }
            );
        }
    }

    protected override void OnResume()
    {
        base.OnResume();

        // Track view resume in RUM
        _logger?.D("Activity resumed", null, new Dictionary<string, Object>());

        // RUM automatically tracks view state, but you can add custom attributes
        _rumMonitor?.AddAttribute("view.state", "resumed");
    }

    protected override void OnPause()
    {
        base.OnPause();

        // Track view pause in RUM
        _logger?.D("Activity paused", null, new Dictionary<string, Object>());

        _rumMonitor?.AddAttribute("view.state", "paused");
    }

    protected override void OnDestroy()
    {
        // Stop the current RUM view
        _rumMonitor?.StopView(
            key: this.GetType().Name,
            attributes: new Dictionary<string, Object>
            {
                { "view.duration_ms", (long)(DateTimeOffset.UtcNow.ToUnixTimeMilliseconds()) }
            }
        );

        _logger?.I("Activity destroyed", null, new Dictionary<string, Object>());

        base.OnDestroy();
    }
}