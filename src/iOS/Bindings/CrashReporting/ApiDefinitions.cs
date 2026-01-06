using Foundation;

namespace Datadog.iOS.CrashReporting
{
	// @interface DDCrashReporter
	interface DDCrashReporter
	{
		// +(void)enable;
		[Static]
		[Export ("enable")]
		void Enable ();
	}
}
