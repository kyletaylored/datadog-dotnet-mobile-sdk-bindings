using Datadog.iOS.ObjC;
using Datadog.iOS.CrashReporting;
using Datadog.iOS.SessionReplay;
using Datadog.iOS.WebViewTracking;
using WebKit;

#pragma warning disable CS8604 // Possible null reference argument.

namespace TestApp
{
    /// <summary>
    /// Comprehensive test app demonstrating all Datadog iOS SDK features.
    ///
    /// This AppDelegate serves as both a functional test and live code reference
    /// for the Datadog .NET iOS bindings. Each feature section includes:
    /// - Configuration examples with inline documentation
    /// - Usage examples demonstrating key functionality
    /// - References to detailed README documentation
    ///
    /// Feature Documentation:
    /// - Core SDK: src/iOS/Bindings/ObjC/README.md
    /// - Logs: src/iOS/Bindings/DDLogs/README.md
    /// - Crash Reporting: src/iOS/Bindings/CrashReporting/README.md
    /// - RUM: src/iOS/Bindings/Rum/README.md
    /// - Session Replay: src/iOS/Bindings/SessionReplay/README.md
    /// - Trace: src/iOS/Bindings/Trace/README.md
    /// - WebView Tracking: src/iOS/Bindings/WebViewTracking/README.md
    /// </summary>
    [Register("AppDelegate")]
    public class AppDelegate : UIApplicationDelegate
    {
        private DDLogger? _logger;

        public override UIWindow? Window
        {
            get;
            set;
        }

        public override bool FinishedLaunching(UIApplication application, NSDictionary launchOptions)
        {
            // Create a new window instance based on the screen size
            Window = new UIWindow(UIScreen.MainScreen.Bounds);

            // =============================================================================
            // 1. CORE SDK - Initialization
            // =============================================================================
            // The Core SDK must be initialized before any other Datadog features.
            // This is the foundation for all Datadog functionality.
            // Documentation: src/iOS/Bindings/ObjC/README.md
            //
            // Key Methods:
            // - DDDatadog.Initialize(config, trackingConsent)
            // - DDDatadog.SetUserInfoWithId(id, name, email, extraInfo)
            // - DDDatadog.VerbosityLevel (property for debugging)
            //
            // Configuration Properties:
            // - Site: DDSite (Us1, Us3, Us5, Eu1, Ap1, Us1Fed)
            // - Service: string
            // - BatchSize: Small, Medium, Large
            // - UploadFrequency: Frequent, Average, Rare

            DDConfiguration config = new DDConfiguration(
                "<CLIENT_TOKEN>",       // Your Datadog client token
                "<ENV>"                 // Environment (e.g., "production", "staging")
            );

            config.Service = "<SERVICE_NAME>";  // Service name (e.g., "my-ios-app")
            config.Site = DDSite.Us1;           // Datadog site

            // Initialize the SDK with tracking consent granted
            DDDatadog.Initialize(config, DDTrackingConsent.Granted);

            // Set verbosity for debugging (Debug shows all internal SDK logs)
            DDDatadog.VerbosityLevel = DDSDKVerbosityLevel.Debug;

            // Set user information (optional - can be updated anytime)
            // This information is attached to all RUM events, logs, and traces
            DDDatadog.SetUserInfoWithId(
                id: "12345",
                name: "John Doe",
                email: "john.doe@example.com",
                extraInfo: null  // Can pass NSDictionary<NSString, NSObject> with custom attributes
            );

            // =============================================================================
            // 2. LOGS SDK - Structured Logging
            // =============================================================================
            // The Logs SDK enables structured logging with support for multiple log levels,
            // custom attributes, and exception tracking. Logs are automatically correlated
            // with RUM sessions and traces when enabled.
            // Documentation: src/iOS/Bindings/DDLogs/README.md
            //
            // Key Methods:
            // - DDLogs.Enable(config)
            // - DDLogger.Create(loggerConfig)
            // - logger.Debug(message, attributes)
            // - logger.Info(message, attributes)
            // - logger.Warn(message, attributes)
            // - logger.Error(message, error, attributes)
            // - logger.AddAttribute(forKey, value)
            // - logger.AddTag(withKey, value)
            //
            // Logger Configuration Properties:
            // - Service: Logger service name
            // - NetworkInfoEnabled: Include network info
            // - PrintLogsToConsole: Also write to console
            // - BundleWithRumEnabled: Bundle with RUM events

            // Enable Logs SDK
            DDLogs.Enable(new DDLogsConfiguration(null));

            // Create a logger instance with custom configuration
            DDLoggerConfiguration logConfig = new DDLoggerConfiguration();
            logConfig.Service = "ios-test-app";              // Logger service name
            logConfig.NetworkInfoEnabled = true;             // Include network info in logs
            logConfig.PrintLogsToConsole = true;             // Also write to console
            logConfig.BundleWithRumEnabled = true;           // Bundle logs with RUM events

            _logger = DDLogger.Create(logConfig);

            // Add global attributes and tags to all logs from this logger
            // These attributes are included in every log message
            _logger.AddAttribute(forKey: "app.version", value: "1.0.0");
            _logger.AddAttribute(forKey: "build.number", value: "42");
            _logger.AddTag(withKey: "platform", value: "ios");
            _logger.AddTag(withKey: "build_configuration", value: "debug");

            // Example: Log messages with different severity levels
            _logger.Debug("Debug message - detailed info for debugging");

            _logger.Info("Application started", attributes: new NSDictionary<NSString, NSObject>(
                new NSString("screen"), new NSString("AppDelegate")
            ));

            _logger.Warn("Warning message - something unusual happened", attributes: new NSDictionary<NSString, NSObject>(
                new NSString("warning.type"), new NSString("api_slow_response")
            ));

            // Example: Log exception with stack trace
            // Demonstrates nested exception handling with full error context
            try
            {
                // Simulate nested exceptions to show complete error tracking
                Exception inner;
                try
                {
                    throw new InvalidOperationException("An inner exception for testing.");
                }
                catch (Exception e)
                {
                    inner = e;
                }
                throw new Exception("This is a test exception with inner exception.", inner);
            }
            catch (Exception e)
            {
                // Create NSError to pass to Datadog
                var nsError = new NSError(
                    new NSString("ERROR"),
                    1001,
                    new NSDictionary<NSString, NSObject>(
                        NSError.LocalizedDescriptionKey, new NSString(e.Message)
                    )
                );

                // Log error with full context
                _logger.Error(
                    e.Message,
                    nsError,
                    new NSDictionary<NSString, NSObject>(
                        new NSString("error.stack"), new NSString(e.ToString()),
                        new NSString("error.type"), new NSString(e.GetType().Name)
                    )
                );
            }

            // =============================================================================
            // 3. CRASH REPORTING - Native Crash Reporting
            // =============================================================================
            // Enable crash reporting to capture native crashes and exceptions.
            // Crash reports are automatically linked to RUM sessions.
            // Documentation: src/iOS/Bindings/CrashReporting/README.md
            //
            // Key Methods:
            // - DDCrashReporter.Enable()

            DDCrashReporter.Enable();
            _logger?.Info("Crash reporting enabled");

            // =============================================================================
            // 4. RUM SDK - Real User Monitoring
            // =============================================================================
            // RUM tracks user interactions, views, actions, resources, and errors.
            // Provides end-to-end visibility into user experience and app performance.
            // Documentation: src/iOS/Bindings/Rum/README.md
            //
            // Key Methods:
            // - DDRUM.Enable(config)
            // - DDRUM.SharedInstance() - Get global RUM monitor (for manual tracking)
            //
            // Configuration Properties:
            // - SessionSampleRate: Sample rate (0-100)
            // - UIKitViewsPredicate: Auto-track view controllers
            // - UIKitActionsPredicate: Auto-track UIKit actions
            // - TrackBackgroundEvents: Track events when backgrounded
            // - TrackFrustrations: Track user frustrations
            // - LongTaskThreshold: Track long tasks (in seconds)
            //
            // RUM Monitor Methods (manual tracking):
            // - monitor.StartViewWithKey(key, name, attributes)
            // - monitor.StopViewWithKey(key, attributes)
            // - monitor.AddUserAction(type, name, attributes)
            // - monitor.StartResourceLoadingWithKey(key, request, attributes)
            // - monitor.StopResourceLoadingWithKey(key, response, size, attributes)
            // - monitor.AddErrorWithMessage(message, source, exception, attributes)
            // - monitor.AddAttribute(forKey, value) - Add global RUM attributes

            var rumConfig = new DDRUMConfiguration(applicationID: "<RUM_APP_ID>");  // Your RUM application ID
            rumConfig.SessionSampleRate = 100.0f;                    // Sample 100% of sessions

            DDRUM.Enable(rumConfig);

            _logger?.Info("RUM monitoring enabled", attributes: new NSDictionary<NSString, NSObject>(
                new NSString("rum.app_id"), new NSString("<RUM_APP_ID>")
            ));

            // Note: Get RUM monitor for manual tracking with DDRUM.SharedInstance()
            // Views are automatically tracked if UIKitViewsPredicate is configured
            // Actions are automatically tracked if UIKitActionsPredicate is configured

            // =============================================================================
            // 5. SESSION REPLAY - Record User Sessions
            // =============================================================================
            // Session Replay records user sessions with configurable privacy settings.
            // Replays are automatically linked to RUM sessions for debugging.
            // Documentation: src/iOS/Bindings/SessionReplay/README.md
            //
            // Key Methods:
            // - DDSessionReplay.Enable(config)
            //
            // Configuration Parameters:
            // - replaySampleRate: Sample rate (0-100)
            // - defaultPrivacyLevel: DDTextAndInputPrivacyLevel
            //   - MaskAll: Mask all text and inputs
            //   - MaskSensitiveInputs: Mask only sensitive inputs
            // - imagePrivacyLevel: DDImagePrivacyLevel
            //   - MaskAll: Mask all images
            //   - MaskNone: Show all images
            // - touchPrivacyLevel: DDTouchPrivacyLevel
            //   - Hide: Hide all touches
            //   - Show: Show all touches

            DDSessionReplayConfiguration replayConfig = new DDSessionReplayConfiguration(
                replaySampleRate: 100.0f,                             // Sample rate (0-100)
                defaultPrivacyLevel: DDTextAndInputPrivacyLevel.MaskAll,  // Mask all text and inputs
                imagePrivacyLevel: DDImagePrivacyLevel.MaskAll,       // Mask all images
                touchPrivacyLevel: DDTouchPrivacyLevel.Hide           // Hide touch interactions
            );

            DDSessionReplay.Enable(replayConfig);

            _logger?.Info("Session Replay enabled", attributes: new NSDictionary<NSString, NSObject>(
                new NSString("replay.sample_rate"), new NSString("100.0"),
                new NSString("replay.privacy"), new NSString("mask_all")
            ));

            // =============================================================================
            // 6. TRACE SDK - APM and Distributed Tracing
            // =============================================================================
            // The Trace SDK enables APM tracing with automatic trace injection.
            // Traces are automatically correlated with RUM sessions and logs.
            // Documentation: src/iOS/Bindings/Trace/README.md
            //
            // Key Methods:
            // - DDTrace.Enable(config)
            // - DDTracer.Shared - Get global tracer instance
            //
            // Tracer Methods (manual span creation):
            // - tracer.StartSpanWithOperationName(operationName, tags, startTime)
            // - span.SetTag(key, value)
            // - span.Finish(at: finishTime)
            //
            // URL Session Tracking:
            // - DDURLSessionInstrumentation.Enable(config) - Auto-instrument URLSession

            DDTrace.Enable(new DDTraceConfiguration());

            // Get the shared tracer instance for manual span creation
            _ = DDTracer.Shared;

            _logger?.Info("APM tracing enabled");

            // To create custom spans manually:
            // var span = DDTracer.Shared.StartSpanWithOperationName("operation_name", tags: null, startTime: null);
            // span.SetTag(key: "custom.tag", value: "value");
            // try { /* work */ } finally { span.Finish(); }

            // =============================================================================
            // 7. WEBVIEW TRACKING - Track WebView Content
            // =============================================================================
            // WebView tracking enables RUM and logging from web content loaded in WKWebViews.
            // Allows you to track the full user journey across native and web content.
            // Documentation: src/iOS/Bindings/WebViewTracking/README.md
            //
            // Key Methods:
            // - DDWebViewTracking.Enable(webView)
            // - DDWebViewTracking.Enable(webView, hosts, logsSampleRate)
            //
            // Parameters:
            // - webView: The WKWebView instance to track
            // - hosts: NSSet of allowed hosts to track (optional)
            // - logsSampleRate: Sample rate for logs from web content (0-100)

            // Example: Enable WebView tracking for demo purposes
            // Note: In a real app, you would pass your actual WKWebView instance
            var exampleWebView = new WKWebView(CGRect.Empty, new WKWebViewConfiguration());
            DDWebViewTracking.Enable(exampleWebView);

            _logger?.Info("WebView tracking enabled (example)");

            // =============================================================================
            // DEMO: Create UI
            // =============================================================================

            // Create a UIViewController with a single UILabel showing all enabled features
            var vc = new UIViewController();
            vc.View!.AddSubview(new UILabel(Window!.Frame)
            {
                BackgroundColor = UIColor.SystemBackground,
                TextAlignment = UITextAlignment.Center,
                Text = "Datadog iOS SDK Test App\n\n" +
                       "✓ Core SDK Initialized\n" +
                       "✓ Logs Enabled\n" +
                       "✓ Crash Reporting Enabled\n" +
                       "✓ RUM Enabled\n" +
                       "✓ Session Replay Enabled\n" +
                       "✓ Trace Enabled\n" +
                       "✓ WebView Tracking Enabled",
                AutoresizingMask = UIViewAutoresizing.All,
                Lines = 0,  // Allow multiple lines
                Font = UIFont.SystemFontOfSize(14)
            });
            Window.RootViewController = vc;

            // Make the window visible
            Window.MakeKeyAndVisible();

            _logger?.Info("Application finished launching successfully");

            return true;
        }

        public override void OnResignActivation(UIApplication application)
        {
            // Track app moving to inactive state
            // This is called when the app is about to move from active to inactive state
            // (e.g., incoming phone call, SMS, etc.)
            _logger?.Debug("Application will resign active");
        }

        public override void DidEnterBackground(UIApplication application)
        {
            // Track app entered background
            // This is called when the app moves to the background
            // RUM automatically captures background events if trackBackgroundEvents is enabled
            _logger?.Debug("Application entered background");
        }

        public override void WillEnterForeground(UIApplication application)
        {
            // Track app will enter foreground
            // This is called before the app becomes active again
            _logger?.Debug("Application will enter foreground");
        }

        public override void OnActivated(UIApplication application)
        {
            // Track app became active
            // This is called when the app becomes active and ready for user interaction
            _logger?.Debug("Application became active");
        }

        public override void WillTerminate(UIApplication application)
        {
            // Track app termination
            // This is called when the app is about to terminate
            // Note: This may not always be called (e.g., if app is force-quit)
            _logger?.Info("Application will terminate");
        }
    }
}
