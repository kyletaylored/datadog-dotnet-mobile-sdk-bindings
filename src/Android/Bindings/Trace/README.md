# Datadog Android SDK - Trace Bindings

.NET bindings for the Datadog Android SDK Trace library (`com.datadog.android:dd-sdk-android-trace`).

## Overview

The Trace binding enables distributed tracing and APM (Application Performance Monitoring) in your .NET for Android application. Track local operations, measure performance, and connect traces across services.

**Package Information:**
- **NuGet Package**: `Bcr.Datadog.Android.Sdk.Trace`
- **Native Artifact**: `com.datadog.android:dd-sdk-android-trace:2.21.0`
- **Namespace**: `Datadog.Android.Trace`

## Installation

```xml
<ItemGroup>
  <PackageReference Include="Bcr.Datadog.Android.Sdk.Core" Version="2.21.0-pre.1" />
  <PackageReference Include="Bcr.Datadog.Android.Sdk.Trace" Version="2.21.0-pre.1" />
</ItemGroup>
```

## Implementation Guide

### Step 1: Initialize Core SDK and Enable Trace

```csharp
using Datadog.Android;
using Datadog.Android.Core.Configuration;
using Datadog.Android.Privacy;
using Datadog.Android.Trace;

// Initialize Core SDK
var config = new DDConfiguration.Builder(
    "YOUR_CLIENT_TOKEN", "production", string.Empty, "my-app"
).Build();
Datadog.Initialize(this, config, TrackingConsent.Granted);

// Enable Trace
var traceConfig = new TraceConfiguration.Builder().Build();
Trace.Enable(traceConfig);
```

### Step 2: Create a Tracer

```csharp
using Datadog.OpenTracing;

var tracer = AndroidTracer.Builder().Build();
```

### Step 3: Create and Use Spans

```csharp
// Create a span
var span = tracer.BuildSpan("network.request").Start();
span.SetTag("http.url", "https://api.example.com/users");
span.SetTag("http.method", "GET");

try
{
    // Your operation here
    await MakeNetworkRequest();
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

## Sample Usage

```csharp
using Datadog.OpenTracing;

public class DataService
{
    private readonly AndroidTracer _tracer;

    public DataService()
    {
        _tracer = AndroidTracer.Builder()
            .SetServiceName("my-android-app")
            .Build();
    }

    public async Task<UserData> FetchUserDataAsync(string userId)
    {
        var span = _tracer.BuildSpan("fetch_user_data").Start();
        span.SetTag("user.id", userId);
        span.SetTag("operation.type", "database");

        try
        {
            var data = await _database.GetUserAsync(userId);
            span.SetTag("result.found", data != null);
            return data;
        }
        catch (Exception ex)
        {
            span.SetTag("error", true);
            span.SetTag("error.message", ex.Message);
            span.SetTag("error.type", ex.GetType().Name);
            throw;
        }
        finally
        {
            span.Finish();
        }
    }
}
```

## API Reference

| Native API (Kotlin/Java) | .NET Binding |
|--------------------------|--------------|
| `Trace.enable(config)` | `Trace.Enable(config)` |
| `AndroidTracer.Builder()` | `AndroidTracer.Builder()` |
| `tracer.buildSpan(name)` | `tracer.BuildSpan(name)` |
| `span.setTag(key, value)` | `span.SetTag(key, value)` |
| `span.finish()` | `span.Finish()` |

## Related Documentation

- **Official Docs**: [Android Tracing](https://docs.datadoghq.com/tracing/trace_collection/automatic_instrumentation/dd_libraries/android/)
- **Datadog Android SDK**: [GitHub](https://github.com/DataDog/dd-sdk-android)

## License

This package is licensed under the MIT License. See the LICENSE file for details.

### NOTICE

This package includes software developed at Datadog (https://www.datadoghq.com/).

Those portions are Copyright 2019 Datadog, Inc.

For more information, please refer to the [Datadog Android SDK repository](https://github.com/DataDog/dd-sdk-android).
