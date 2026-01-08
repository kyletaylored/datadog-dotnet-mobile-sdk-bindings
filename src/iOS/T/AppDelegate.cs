using Datadog.iOS.ObjC;
using Datadog.iOS.CrashReporting;
using Datadog.iOS.SessionReplay;
using Datadog.iOS.WebViewTracking;
using WebKit;

namespace T
{
    [Register("AppDelegate")]
    public class AppDelegate : UIApplicationDelegate
    {
        public override UIWindow? Window
        {
            get;
            set;
        }

        public override bool FinishedLaunching(UIApplication application, NSDictionary launchOptions)
        {
            // create a new window instance based on the screen size
            Window = new UIWindow(UIScreen.MainScreen.Bounds);

            // initialize the Datadog SDK
            DDConfiguration config = new DDConfiguration(
                "<client token>", "<environment>"
            );

            config.Service = "<service name>";
            // config.Site = DDSite.Us1; // Set your Datadog site (Us1, Us3, Us5, Eu1, etc.)

            DDDatadog.Initialize(config, DDTrackingConsent.Granted);
            DDDatadog.VerbosityLevel = DDSDKVerbosityLevel.Debug;
            DDLogs.Enable(new DDLogsConfiguration(null));

            DDCrashReporter.Enable();

            var rumConfig = new DDRUMConfiguration("<app-id>");
            rumConfig.SessionSampleRate = 100f;
            DDRUM.Enable(rumConfig);

            DDSessionReplayConfiguration replayConfig = new DDSessionReplayConfiguration(
                100.0F, 
                DDTextAndInputPrivacyLevel.MaskAll, 
                DDImagePrivacyLevel.MaskAll, 
                DDTouchPrivacyLevel.Hide);
            DDSessionReplay.Enable(replayConfig);

            DDTrace.Enable(new DDTraceConfiguration());
            _ = DDTracer.Shared;

            DDWebViewTracking.Enable(new WKWebView(CGRect.Empty, new WKWebViewConfiguration()));

            // init the logger
            DDLoggerConfiguration logConfig = new DDLoggerConfiguration();
            logConfig.Service = "<log service>";
            logConfig.NetworkInfoEnabled = false;
            logConfig.PrintLogsToConsole = true;
            logConfig.BundleWithRumEnabled = false;

            DDLogger logger = DDLogger.Create(logConfig);

            // test logger
            logger.Debug("Logging a debug message.");

            try
            {
                Exception inner;
                try
                {
                    throw new Exception("An inner exception.");
                }
                catch (Exception e)
                {
                    inner = e;
                }
                throw new Exception("This is a test exception.", inner);
            }
            catch (Exception e)
            {
                var nsError = new NSError(new NSString("ERROR"), 1001, new NSDictionary<NSString, NSObject>(
                    NSError.LocalizedDescriptionKey, new NSString(e.Message)));
                logger.Error(e.Message, nsError, 
                    new NSDictionary<NSString, NSObject>(new NSString("error.stack"), new NSString(e.ToString())));
            }
            // create a UIViewController with a single UILabel
            var vc = new UIViewController();
            vc.View!.AddSubview(new UILabel(Window!.Frame)
            {
                BackgroundColor = UIColor.SystemBackground,
                TextAlignment = UITextAlignment.Center,
                Text = "Hello, iOS!",
                AutoresizingMask = UIViewAutoresizing.All,
            });
            Window.RootViewController = vc;

            // make the window visible
            Window.MakeKeyAndVisible();

            return true;
        }
    }
}
