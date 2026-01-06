using System;
using Foundation;
using ObjCRuntime;
using WebKit;

namespace Datadog.iOS.WebViewTracking
{
	// @interface DDWebViewTracking
	[BaseType (typeof(NSObject), Name = "_TtC25DatadogWebViewTracking17DDWebViewTracking")]
	[DisableDefaultCtor]
	interface DDWebViewTracking
	{
		// +(void)enableWithWebView:(WKWebView * _Nonnull)webView hosts:(id)hosts logsSampleRate:(float)logsSampleRate;
		[Static]
		[Export ("enableWithWebView:hosts:logsSampleRate:")]
		void EnableWithWebView (WKWebView webView, NSObject hosts, float logsSampleRate);

		// +(void)disableWithWebView:(WKWebView * _Nonnull)webView;
		[Static]
		[Export ("disableWithWebView:")]
		void DisableWithWebView (WKWebView webView);
	}
}
