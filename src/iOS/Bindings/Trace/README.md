# Datadog iOS SDK - Trace Framework Binding

Low-level .NET bindings for the Datadog iOS SDK Trace framework.

## Overview

This package provides direct bindings to the DatadogTrace.xcframework, exposing the native iOS distributed tracing and APM APIs to .NET. It's an internal dependency used by the main [Bcr.Datadog.iOS.ObjC](../ObjC/README.md) package.

**Package Information:**
- **NuGet Package**: `Bcr.Datadog.iOS.Trace`
- **Target Frameworks**: `net9.0-ios17.0`, `net10.0-ios17.0`
- **XCFramework**: `DDT.xcframework`

> **⚠️ Important**: This is a low-level binding package. For most use cases, you should use [Bcr.Datadog.iOS.ObjC](../ObjC/README.md) instead, which includes Logs, RUM, and Trace in a single integrated package with easier-to-use APIs.

## When to Use This Package

Use this package directly only if you:
- Need fine-grained control over Trace framework dependencies
- Are building custom wrappers or abstractions
- Have specific modular architecture requirements

For standard iOS app integration, use [Bcr.Datadog.iOS.ObjC](../ObjC/README.md) instead.

## Installation

```xml
<ItemGroup>
  <PackageReference Include="Bcr.Datadog.iOS.Trace" Version="2.26.0" />
</ItemGroup>
```

## What's Included

This binding exposes the native DatadogTrace framework APIs:

- `DDTrace` - Trace feature configuration
- `DDTracer` - Global tracer singleton
- `DDSpan` - Span creation and management
- `DDTraceConfiguration` - Trace-specific configuration options
- OpenTelemetry API compatibility (via `Bcr.Otel.Api.iOS` dependency)

## Usage Example

```csharp
using Datadog.iOS.Trace;
using Foundation;

// Enable Trace (after Datadog SDK initialization)
var traceConfig = new DDTraceConfiguration();
DDTrace.Enable(traceConfig);

// Get tracer
var tracer = DDTracer.Shared;

// Create span for an operation
var span = tracer.StartSpan("network.request", new NSDictionary(), null);
span.SetTag("http.url", "https://api.example.com/users");
span.SetTag("http.method", "GET");
span.SetTag("service.name", "my-ios-app");

try
{
    // Perform your operation
    await MakeNetworkRequest();

    span.SetTag("http.status_code", 200);
}
catch (Exception ex)
{
    // Mark span as error
    span.SetTag("error", true);
    span.SetTag("error.type", ex.GetType().Name);
    span.SetTag("error.message", ex.Message);
    span.SetTag("error.stack", ex.StackTrace);
}
finally
{
    // Always finish the span
    span.Finish();
}
```

## Advanced Usage

### Creating Child Spans

```csharp
// Parent operation
var parentSpan = tracer.StartSpan("user.operation", new NSDictionary(), null);

// Child operation
var childSpan = tracer.StartSpan(
    "database.query",
    new NSDictionary(),
    parentSpan // Pass parent span
);
childSpan.SetTag("db.type", "sqlite");
childSpan.SetTag("db.statement", "SELECT * FROM users");
childSpan.Finish();

parentSpan.Finish();
```

### Adding Custom Tags

```csharp
var span = tracer.StartSpan("custom.operation", new NSDictionary(), null);

// Add business context
span.SetTag("user.id", "12345");
span.SetTag("user.tier", "premium");
span.SetTag("feature.flag", "new_checkout");

span.Finish();
```

## Common Tags

| Tag | Description | Example |
|-----|-------------|---------|
| `http.url` | Request URL | `https://api.example.com/users` |
| `http.method` | HTTP method | `GET`, `POST` |
| `http.status_code` | Response status | `200`, `404` |
| `error` | Error flag | `true` or `false` |
| `error.type` | Exception type | `NetworkException` |
| `error.message` | Error message | `Connection timeout` |
| `db.type` | Database type | `sqlite`, `postgresql` |
| `db.statement` | SQL query | `SELECT * FROM users` |

## Related Packages

- **[Bcr.Datadog.iOS.ObjC](../ObjC/README.md)** - Main package with Logs, RUM, and Trace (recommended)
- **[Bcr.Datadog.iOS.Logs](../DDLogs/README.md)** - Logs framework binding
- **[Bcr.Datadog.iOS.RUM](../Rum/README.md)** - RUM framework binding
- **[Bcr.Otel.Api.iOS](../OpenTelemetryApi/README.md)** - OpenTelemetry API bindings

## Related Documentation

- **iOS APM Setup**: [iOS Trace Collection](https://docs.datadoghq.com/tracing/trace_collection/automatic_instrumentation/dd_libraries/ios/)
- **iOS Advanced Configuration**: [Advanced APM Setup](https://docs.datadoghq.com/real_user_monitoring/mobile_and_tv_monitoring/advanced_configuration/ios/)
- **Official iOS SDK**: [GitHub Repository](https://github.com/DataDog/dd-sdk-ios)

## License

This project is licensed under the [MIT License](LICENSE).

This product includes software developed at Datadog (https://www.datadoghq.com/), used under the [Apache License, v2.0](https://github.com/DataDog/dd-sdk-ios/blob/develop/LICENSE)
