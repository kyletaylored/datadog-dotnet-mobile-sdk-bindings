using ObjCRuntime;
using Foundation;

namespace Datadog.iOS.ObjC;

public partial class DDLoggerConfiguration
{
    public DDLoggerConfiguration(string? service = null, string? name = null) : this(service, name, NSNumber.FromBoolean(false), NSNumber.FromBoolean(true), NSNumber.FromBoolean(true), 100.0F, DDLogLevel.Debug, NSNumber.FromBoolean(false))
    {
    }
}

public partial class DDURLSessionInstrumentation
{
    public static void Disable<T>() where T : INSUrlSessionDataDelegate
    {
        DisableWithDelegateClass(new Class(typeof(T)));
    }
}