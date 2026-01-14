# Android Bindings Internals

This document explains how .NET Android bindings work, the role of Metadata.xml and Additions, and how to create and maintain bindings. This is a technical reference for developers and AI coding agents working on the binding layer.

> 📱 **Platform Comparison**: See [iOS Bindings Internals](IOS_BINDINGS_INTERNALS.md) to understand how iOS bindings differ (hand-written vs auto-generated).

## Table of Contents

- [Overview](#overview)
- [How Android Bindings Work](#how-android-bindings-work)
- [The Binding Generation Process](#the-binding-generation-process)
- [Metadata.xml Transformations](#metadataxml-transformations)
- [Additions - Manual Code](#additions---manual-code)
- [Common Binding Patterns](#common-binding-patterns)
- [Troubleshooting Binding Errors](#troubleshooting-binding-errors)
- [Best Practices](#best-practices)
- [References](#references)

---

## Overview

.NET Android bindings allow C# code to call Java/Kotlin libraries. The binding process converts Java APIs into C# equivalents that can be consumed by .NET applications.

```
┌─────────────────────────────────────────────────────────────┐
│                       Your C# App                           │
└──────────────────────────┬──────────────────────────────────┘
                           │ Calls C# APIs
┌──────────────────────────▼──────────────────────────────────┐
│                  .NET Android Binding                       │
│  ┌─────────────────────┐  ┌─────────────────────────────┐  │
│  │  Auto-Generated     │  │  Manual Additions           │  │
│  │  (from Java API)    │  │  (Fixes & Enhancements)     │  │
│  └─────────────────────┘  └─────────────────────────────┘  │
│              Controlled by Metadata.xml                     │
└──────────────────────────┬──────────────────────────────────┘
                           │ JNI Bridge
┌──────────────────────────▼──────────────────────────────────┐
│              Native Android Library (Java/Kotlin)           │
│                    (AAR/JAR files)                          │
└─────────────────────────────────────────────────────────────┘
```

**Key Components:**

1. **AAR/JAR Files**: Native Android libraries containing compiled Java/Kotlin bytecode
2. **Metadata.xml**: XML transformation rules that control the binding generation
3. **Auto-Generated Code**: C# code automatically created from Java APIs
4. **Additions**: Hand-written C# code to fix issues or add convenience methods

---

## How Android Bindings Work

### The Java Native Interface (JNI) Bridge

.NET Android bindings use the Java Native Interface (JNI) to bridge between managed C# code and native Java/Kotlin code:

```csharp
// Your C# code
var config = new DDConfiguration("client-token", "prod");

// Generated binding (simplified)
public partial class DDConfiguration : Java.Lang.Object
{
    static IntPtr class_ref = JNIEnv.FindClass("com/datadog/android/core/configuration/Configuration");
    static IntPtr id_ctor = JNIEnv.GetMethodID(class_ref, "<init>", "(Ljava/lang/String;Ljava/lang/String;)V");

    public DDConfiguration(string clientToken, string env)
    {
        // Marshal C# strings to Java strings
        IntPtr native_clientToken = JNIEnv.NewString(clientToken);
        IntPtr native_env = JNIEnv.NewString(env);

        // Call Java constructor via JNI
        Handle = JNIEnv.NewObject(class_ref, id_ctor, new JValue[] {
            new JValue(native_clientToken),
            new JValue(native_env)
        });
    }
}
```

This bridging happens automatically - you write normal C# code, and the binding layer handles the JNI calls.

### Type Mappings

Java types are mapped to C# equivalents:

| Java Type | C# Type | Notes |
|-----------|---------|-------|
| `java.lang.String` | `string` | Automatic marshaling |
| `int`, `long`, `float`, `double` | `int`, `long`, `float`, `double` | Direct mapping |
| `boolean` | `bool` | Direct mapping |
| `void` | `void` | Direct mapping |
| `java.util.List<T>` | `IList<T>` | Collection interface |
| `java.util.Map<K,V>` | `IDictionary<K,V>` | Dictionary interface |
| `kotlin.Function0<T>` | `Func<T>` | Lambda/delegate |
| Custom Java classes | C# classes inheriting `Java.Lang.Object` | Binding generated |

### Kotlin-Specific Challenges

Kotlin introduces patterns that don't map cleanly to C#:

**Companion Objects:**
```kotlin
// Kotlin
class MyClass {
    companion object {
        const val CONSTANT = "value"
        fun create(): MyClass = MyClass()
    }
}

// Usage in Kotlin
val instance = MyClass.create()
val value = MyClass.CONSTANT
```

The binding generator tries to create a nested `Companion` class, which often causes issues:
- Duplicate type names
- Invalid field types
- Circular dependencies

**Solution:** Remove Companion objects in Metadata.xml (they're usually not needed).

**Extension Functions:**
```kotlin
// Kotlin
fun Context.showToast(message: String) {
    Toast.makeText(this, message, Toast.LENGTH_SHORT).show()
}

// Usage
context.showToast("Hello")
```

Extension functions are compiled to static methods in a class ending with `Kt`:
```csharp
// Generated C# binding
public static class ExtensionsKt
{
    public static void ShowToast(this Context context, string message)
    {
        // JNI bridge to Kotlin static method
    }
}
```

---

## The Binding Generation Process

### Build Pipeline

```
┌────────────────────┐
│   AAR/JAR Files    │  ← Native Android libraries
└─────────┬──────────┘
          │
          ▼
┌────────────────────┐
│  Extract classes   │  ← Unzip AAR, read JAR bytecode
│   (classes.jar)    │
└─────────┬──────────┘
          │
          ▼
┌────────────────────┐
│  Generate api.xml  │  ← XML description of all Java APIs
└─────────┬──────────┘
          │
          ▼
┌────────────────────┐
│ Apply Metadata.xml │  ← Transform/remove/rename APIs
└─────────┬──────────┘
          │
          ▼
┌────────────────────┐
│ Generate C# code   │  ← Create .cs files with bindings
│   (obj/generated/) │
└─────────┬──────────┘
          │
          ▼
┌────────────────────┐
│  Merge Additions/  │  ← Combine with manual C# code
└─────────┬──────────┘
          │
          ▼
┌────────────────────┐
│   Compile to DLL   │  ← Final binding assembly
└────────────────────┘
```

### Project Structure

```
src/Android/Bindings/Core/
├── Core.csproj                    # MSBuild project file
├── Transforms/
│   └── Metadata.xml              # Binding transformations
├── Additions/                     # Manual C# code
│   └── CustomExtensions.cs
├── aars/                         # Native library files
│   ├── dd-sdk-android-core.aar
│   ├── kronos-android.aar
│   └── opentelemetry-api.jar
└── obj/                          # Generated files (gitignored)
    └── Release/
        └── net9.0-android/
            ├── api.xml           # Extracted Java API description
            └── generated/        # Auto-generated C# bindings
                └── src/
                    └── Com.Datadog.Android.*.cs
```

### Core.csproj Configuration

```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <!-- Target Android on .NET 8/9/10 -->
    <TargetFrameworks>net8.0-android;net9.0-android;net10.0-android</TargetFrameworks>

    <!-- This is a binding project -->
    <IsBindingProject>true</IsBindingProject>

    <!-- Package metadata -->
    <PackageId>Bcr.Datadog.Android.Core</PackageId>
    <PackageVersion>3.4.0</PackageVersion>
  </PropertyGroup>

  <!-- Reference AAR/JAR files -->
  <ItemGroup>
    <AndroidLibrary Include="aars\dd-sdk-android-core.aar" />
    <AndroidJavaLibrary Include="aars\kronos-android.aar" />
    <EmbeddedJar Include="aars\opentelemetry-api.jar" />
  </ItemGroup>

  <!-- Metadata transformations -->
  <ItemGroup>
    <TransformFile Include="Transforms\Metadata.xml" />
  </ItemGroup>
</Project>
```

**Key ItemGroup Types:**

- `<AndroidLibrary>`: Full Android AAR (includes resources, manifests, etc.)
- `<AndroidJavaLibrary>`: Java library AAR (no Android resources)
- `<EmbeddedJar>`: Pure Java JAR file
- `<TransformFile>`: Metadata.xml transformation rules

---

## Metadata.xml Transformations

Metadata.xml files control how Java APIs are converted to C#. They use XPath to target specific classes, methods, or fields and apply transformations.

### Basic Structure

```xml
<metadata>
  <!-- Remove problematic types -->
  <remove-node path="/api/package[@name='com.example']/class[@name='InternalHelper']" />

  <!-- Rename to follow C# conventions -->
  <attr path="/api/package[@name='com.example']/class[@name='MyClass']/field[@name='MY_CONSTANT']"
        name="managedName">MyConstant</attr>

  <!-- Change visibility -->
  <attr path="/api/package[@name='com.example']/class[@name='MyClass']/method[@name='internalMethod']"
        name="visibility">internal</attr>
</metadata>
```

### Common Transformation Patterns

#### 1. Removing Internal/Private APIs

**Problem:** The binding generator tries to bind internal Kotlin/Java APIs that shouldn't be public.

```xml
<!-- Remove all internal packages -->
<remove-node path="/api/package[starts-with(@name, 'com.datadog.android.internal')]" />

<!-- Remove specific internal classes -->
<remove-node path="/api/package[@name='com.datadog.android']/class[@name='_InternalProxy']" />
```

#### 2. Removing Kotlin Companion Objects

**Problem:** Kotlin companion objects cause duplicate type name errors.

```kotlin
// Kotlin
class Feature {
    companion object {
        const val VERSION = "1.0"
    }
}
```

The generator creates both `Feature` and `Feature.Companion`, causing conflicts.

```xml
<!-- Remove the Companion field to prevent duplicate -->
<remove-node path="/api/package[@name='com.datadog.android.api.feature']/interface[@name='Feature']/field[@name='Companion']" />
```

#### 3. Removing Kotlin Component Methods

**Problem:** Kotlin data classes generate `componentN()` methods for destructuring that aren't useful in C#.

```kotlin
// Kotlin data class
data class UserInfo(val id: String, val name: String, val email: String)
// Generates: component1(), component2(), component3()
```

```xml
<!-- Remove all componentN methods -->
<remove-node path="/api/package[@name='com.datadog.android.api.context']/class[@name='UserInfo']/method[starts-with(@name,'component')]" />
```

#### 4. Renaming for C# Conventions

**Problem:** Java naming doesn't follow C# conventions (e.g., constants should be PascalCase).

```xml
<!-- Rename constant from ALL_CAPS to PascalCase -->
<attr path="/api/package[@name='com.datadog.android']/class[@name='DatadogSite']/field[@name='US1']"
      name="managedName">US1</attr>

<!-- Rename method from getXxx to Xxx (property-style) -->
<attr path="/api/package[@name='com.datadog.android.api']/interface[@name='SdkCore']/method[@name='isCoreActive']"
      name="managedName">IsCoreActive</attr>
```

#### 5. Changing Nullability

**Problem:** Java/Kotlin nullability annotations don't always map correctly.

```xml
<!-- Make parameter nullable -->
<attr path="/api/package[@name='com.datadog.android.trace.opentelemetry']/class[@name='OtelTracerProvider']/method[@name='get']/parameter[1]"
      name="managedType">string?</attr>
```

#### 6. Hiding Implementation Details

**Problem:** Methods that expose internal types or implementation details.

```xml
<!-- Change to internal visibility -->
<attr path="/api/package[@name='com.datadog.android.core.configuration']/class[@name='BackPressureStrategy']/method[@name='getOnItemDropped']"
      name="visibility">internal</attr>
```

#### 7. Removing Types with Invalid Dependencies

**Problem:** Some types reference other types that can't be bound correctly.

```xml
<!-- Remove interface that depends on unbindable types -->
<remove-node path="/api/package[@name='com.datadog.android.api.feature']/interface[@name='FeatureSdkCore']" />
<remove-node path="/api/package[@name='com.datadog.android.api.feature']/interface[@name='FeatureScope']" />
```

**Reason:** If `FeatureSdkCore.getFeature()` returns `FeatureScope` and `FeatureScope` has methods that can't be bound, we need to remove both to prevent cascading errors.

### XPath Targeting

Metadata.xml uses XPath to target specific API elements:

```xml
<!-- Target by package name -->
/api/package[@name='com.datadog.android']

<!-- Target class by name -->
/api/package[@name='com.datadog.android']/class[@name='Datadog']

<!-- Target interface -->
/api/package[@name='com.datadog.android.api']/interface[@name='SdkCore']

<!-- Target method by name -->
/api/package[@name='...']/class[@name='...']/method[@name='methodName']

<!-- Target method by signature (when overloaded) -->
/api/package[@name='...']/class[@name='...']/method[@name='get' and count(parameter)=1 and parameter[1][@type='java.lang.String']]

<!-- Target field -->
/api/package[@name='...']/class[@name='...']/field[@name='CONSTANT']

<!-- Pattern matching -->
/api/package[starts-with(@name, 'com.datadog.android.internal')]  <!-- All internal packages -->
/api/package[@name='...']/class[@name='...']/method[starts-with(@name,'component')]  <!-- All componentN methods -->
```

### Real-World Example: Datadog Core Metadata.xml

Here's an annotated excerpt from the actual Core binding:

```xml
<metadata>
  <!-- ═══════════════════════════════════════════════════════════════ -->
  <!-- REMOVAL SECTION: Remove problematic types -->
  <!-- ═══════════════════════════════════════════════════════════════ -->

  <!-- Remove all internal APIs not meant for public use -->
  <remove-node path="/api/package[starts-with(@name, 'com.datadog.android.core.internal')]" />

  <!-- Remove Kotlin companion objects (cause duplicate type errors) -->
  <remove-node path="/api/package[@name='com.datadog.android.api.context']/class[@name='TimeInfo']/field[@name='Companion']" />
  <remove-node path="/api/package[@name='com.datadog.android.api.feature']/interface[@name='Feature']/field[@name='Companion']" />

  <!-- Remove Kotlin data class component methods (not useful in C#) -->
  <remove-node path="/api/package[@name='com.datadog.android.api.context']/class[@name='TimeInfo']/method[starts-with(@name,'component')]" />

  <!-- Remove interfaces with invalid return types -->
  <remove-node path="/api/package[@name='com.datadog.android.api.feature']/interface[@name='FeatureSdkCore']" />
  <remove-node path="/api/package[@name='com.datadog.android.api.feature']/interface[@name='FeatureScope']" />
  <remove-node path="/api/package[@name='com.datadog.android.api.storage.datastore']/interface[@name='DataStoreHandler']" />

  <!-- ═══════════════════════════════════════════════════════════════ -->
  <!-- RENAMING SECTION: Follow C# naming conventions -->
  <!-- ═══════════════════════════════════════════════════════════════ -->

  <!-- Rename Configuration to DDConfiguration (avoid conflicts with System.Configuration) -->
  <attr path="/api/package[@name='com.datadog.android.core.configuration']/class[@name='Configuration']"
        name="managedName">DDConfiguration</attr>

  <!-- Rename constants to PascalCase -->
  <attr path="/api/package[@name='com.datadog.android']/class[@name='DatadogSite']/field[@name='US1']"
        name="managedName">US1</attr>

  <!-- ═══════════════════════════════════════════════════════════════ -->
  <!-- VISIBILITY SECTION: Hide internal implementation -->
  <!-- ═══════════════════════════════════════════════════════════════ -->

  <!-- Make internal constructors inaccessible -->
  <attr path="/api/package[@name='com.datadog.android.core.configuration']/class[@name='BackPressureStrategy']/constructor[@name='BackPressureStrategy' and count(parameter)=4]"
        name="visibility">internal</attr>
</metadata>
```

---

## Additions - Manual Code

Additions allow you to add hand-written C# code that merges with the auto-generated bindings. This is useful for:

1. **Fixing binding bugs**: When the generator produces incorrect code
2. **Adding convenience methods**: Extension methods, operator overloads, etc.
3. **Implementing missing interfaces**: When Java patterns don't map to C#
4. **Working around limitations**: JNI marshaling issues, null handling, etc.

### How Additions Work

Additions use C# partial classes to extend the generated bindings:

```
┌─────────────────────────────────────────────────────────┐
│                   Compiled Assembly                     │
│                                                         │
│  ┌──────────────────┐    ┌──────────────────────────┐  │
│  │  Auto-Generated  │    │  Manual Additions        │  │
│  │                  │    │                          │  │
│  │  public partial  │ +  │  public partial          │  │
│  │  class MyClass   │    │  class MyClass           │  │
│  │  {               │    │  {                       │  │
│  │    // JNI code   │    │    // Custom code        │  │
│  │  }               │    │  }                       │  │
│  └──────────────────┘    └──────────────────────────┘  │
│         Merge at compile time →                         │
└─────────────────────────────────────────────────────────┘
```

### Additions Structure

```
src/Android/Bindings/Trace/
├── Additions/
│   ├── AboutAdditions.txt         # Documentation (not compiled)
│   ├── SpanExtensions.cs          # Custom extension methods
│   └── TracerExtensions.cs        # More custom methods
```

**Important:** Only `.cs` files in `Additions/` are compiled. The `AboutAdditions.txt` file is for documentation only.

### Example: Fixing a Binding Bug

**Problem:** The auto-generated `Span.SetError()` method doesn't handle null correctly.

**Auto-Generated Code (simplified):**
```csharp
// obj/Release/net9.0-android/generated/src/Com.Datadog.Android.Trace.ISpan.cs
public partial interface ISpan : IJavaObject
{
    void SetError(Java.Lang.Throwable throwable);
}
```

**Addition (fix null handling):**
```csharp
// Additions/SpanExtensions.cs
namespace Datadog.Android.Trace;

public static class SpanExtensions
{
    /// <summary>
    /// Safely sets an error on the span, handling null spans gracefully.
    /// </summary>
    /// <param name="span">The span to set the error on (can be null)</param>
    /// <param name="exception">The exception to record</param>
    public static void SafeSetError(this ISpan? span, Exception exception)
    {
        if (span == null) return;

        // Convert .NET Exception to Java Throwable
        var throwable = Java.Lang.Throwable.FromException(exception);
        span.SetError(throwable);
    }
}
```

**Usage:**
```csharp
ISpan? span = tracer.BuildSpan("operation").Start();
try
{
    // work
}
catch (Exception ex)
{
    span.SafeSetError(ex);  // Works even if span is null
}
finally
{
    span?.Finish();
}
```

### Example: Adding Convenience Methods

**Problem:** The Java API requires creating intermediate objects for common operations.

**Java API:**
```kotlin
// Kotlin
val logger = Logger.Builder()
    .setNetworkInfoEnabled(true)
    .setLogcatLogsEnabled(true)
    .build()
```

**Generated C# (verbose):**
```csharp
var loggerBuilder = new Logger.Builder();
loggerBuilder.SetNetworkInfoEnabled(true);
loggerBuilder.SetLogcatLogsEnabled(true);
var logger = loggerBuilder.Build();
```

**Addition (fluent API):**
```csharp
// Additions/LoggerExtensions.cs
namespace Datadog.Android.Logs;

public static class LoggerExtensions
{
    /// <summary>
    /// Creates a logger with common default settings.
    /// </summary>
    public static Logger CreateDefault(string name)
    {
        return new Logger.Builder()
            .SetNetworkInfoEnabled(true)
            .SetLogcatLogsEnabled(true)
            .SetName(name)
            .Build();
    }
}
```

**Usage:**
```csharp
var logger = LoggerExtensions.CreateDefault("my-logger");
```

### When to Use Additions

**✅ DO Use Additions For:**

- Fixing null handling issues
- Adding extension methods for convenience
- Implementing C# interfaces on Java types
- Converting between .NET and Java types (e.g., `Exception` ↔ `Throwable`)
- Adding strongly-typed wrappers around loosely-typed Java APIs

**❌ DON'T Use Additions For:**

- Wrapping every method "just because"
- Implementing business logic (belongs in your app)
- Duplicating functionality that already exists
- Working around issues that should be fixed in Metadata.xml

### Maintenance Considerations

Additions files are **tightly coupled** to the native SDK version:

- **SDK updates can break Additions**: Method signatures change, methods get removed
- **Document why each Addition exists**: Add XML comments explaining the reason
- **Keep Additions minimal**: Only add what's absolutely necessary
- **Test after SDK updates**: Additions are the #1 source of binding errors

See [TROUBLESHOOTING_BINDING_ERRORS.md](TROUBLESHOOTING_BINDING_ERRORS.md) for guidance on fixing broken Additions after SDK updates.

---

## Common Binding Patterns

### Pattern 1: Remove Internal Kotlin APIs

**Situation:** Kotlin SDK exposes internal classes that shouldn't be public.

```xml
<!-- Remove all internal packages -->
<remove-node path="/api/package[starts-with(@name, 'com.datadog.android.internal')]" />
<remove-node path="/api/package[starts-with(@name, 'com.datadog.android.core.internal')]" />
```

### Pattern 2: Handle Kotlin Companion Objects

**Situation:** Kotlin companion objects generate duplicate nested types.

**Error:**
```
Skipping 'Datadog.Android.Api.Feature.IFeature.Companion' due to a duplicate nested type name.
```

**Fix:**
```xml
<remove-node path="/api/package[@name='com.datadog.android.api.feature']/interface[@name='Feature']/field[@name='Companion']" />
```

### Pattern 3: Remove Data Class Component Methods

**Situation:** Kotlin data classes generate `component1()`, `component2()`, etc. for destructuring.

```xml
<remove-node path="/api/package[@name='com.datadog.android.api.context']/class[@name='TimeInfo']/method[starts-with(@name,'component')]" />
<remove-node path="/api/package[@name='com.datadog.android.api.context']/class[@name='UserInfo']/method[starts-with(@name,'component')]" />
```

### Pattern 4: Remove Types with Circular Dependencies

**Situation:** Type A depends on Type B, but Type B can't be bound correctly.

**Error:**
```
Invalid return type 'com.datadog.android.api.feature.FeatureScope' for member 'GetFeature'
Invalidating 'IFeatureSdkCore' and all its nested types because some of its methods were invalid.
```

**Fix:** Remove both types:
```xml
<remove-node path="/api/package[@name='com.datadog.android.api.feature']/interface[@name='FeatureSdkCore']" />
<remove-node path="/api/package[@name='com.datadog.android.api.feature']/interface[@name='FeatureScope']" />
```

### Pattern 5: Rename to Avoid C# Conflicts

**Situation:** Java class name conflicts with C# framework types.

```xml
<!-- Avoid conflict with System.Configuration -->
<attr path="/api/package[@name='com.datadog.android.core.configuration']/class[@name='Configuration']"
      name="managedName">DDConfiguration</attr>
```

### Pattern 6: Remove Types with Unresolvable Generics

**Situation:** Java generics that can't be expressed in C#.

**Error:**
```
Unknown parameter type 'com.datadog.android.core.internal.persistence.Deserializer<java.lang.String, T>'
Invalidating 'IDataStoreHandler' and all its nested types
```

**Fix:**
```xml
<remove-node path="/api/package[@name='com.datadog.android.api.storage.datastore']/interface[@name='DataStoreHandler']" />
```

### Pattern 7: Remove OpenTelemetry Internal Classes

**Situation:** OpenTelemetry classes with incompatible Java patterns.

**Error:**
```
'ReadOnlyArrayMap.EntrySet()': return type must be 'ICollection' to match overridden member 'AbstractMap.EntrySet()'
```

**Fix:**
```xml
<remove-node path="/api/package[@name='io.opentelemetry.api.internal']/class[@name='ReadOnlyArrayMap']" />
```

---

## Troubleshooting Binding Errors

### Diagnostic Strategy

1. **Read the error message carefully**
   - Error code (CS1501, CS0103, CS0117, etc.)
   - File path and line number
   - What it's complaining about

2. **Identify the source**
   - Is it in `obj/.../generated/` (auto-generated)?
   - Is it in `Additions/` (manual code)?
   - Is it in `Metadata.xml` (transformation rules)?

3. **Check if the Java API changed**
   - Search the native SDK for the class/method
   - Check CHANGELOG.md and MIGRATION.md
   - Compare with previous SDK version

4. **Apply the appropriate fix**
   - Auto-generated errors → Add Metadata.xml transformation
   - Additions errors → Update or remove the Addition
   - Metadata.xml errors → Fix the XPath or remove the rule

### Common Error Patterns

#### Error: Duplicate nested type name

**Full Error:**
```
Skipping 'Datadog.Android.Api.Feature.IFeature.Companion' due to a duplicate nested type name.
```

**Cause:** Kotlin companion object creates a field and a nested class with the same name.

**Fix:** Remove the Companion field:
```xml
<remove-node path="/api/package[@name='com.datadog.android.api.feature']/interface[@name='Feature']/field[@name='Companion']" />
```

#### Error: Return type must be X to match overridden member

**Full Error:**
```
'ReadOnlyArrayMap.EntrySet()': return type must be 'ICollection' to match overridden member 'AbstractMap.EntrySet()'
```

**Cause:** The binding generator produces an override that doesn't match the base class signature.

**Fix:** Remove the problematic type entirely:
```xml
<remove-node path="/api/package[@name='io.opentelemetry.api.internal']/class[@name='ReadOnlyArrayMap']" />
```

#### Error: Invalid return type for member

**Full Error:**
```
Invalid return type 'com.datadog.android.api.feature.FeatureScope' for member 'GetFeature'
Invalidating 'IFeatureSdkCore' and all its nested types
```

**Cause:** The return type can't be bound (has its own issues), so the method can't be generated.

**Fix:** Remove both the interface and the return type:
```xml
<remove-node path="/api/package[@name='com.datadog.android.api.feature']/interface[@name='FeatureSdkCore']" />
<remove-node path="/api/package[@name='com.datadog.android.api.feature']/interface[@name='FeatureScope']" />
```

#### Error: Unexpected field type

**Full Error:**
```
Unexpected field type `com.datadog.android.api.context.TimeInfo.Companion` (Datadog.Android.Api.Context.TimeInfo.GetTime ()).
```

**Cause:** The field type is a Companion object, which doesn't have a valid C# mapping.

**Fix:** Remove the Companion field:
```xml
<remove-node path="/api/package[@name='com.datadog.android.api.context']/class[@name='TimeInfo']/field[@name='Companion']" />
```

### Detailed Troubleshooting Guide

See [TROUBLESHOOTING_BINDING_ERRORS.md](TROUBLESHOOTING_BINDING_ERRORS.md) for a comprehensive guide to diagnosing and fixing binding errors.

---

## Best Practices

### Metadata.xml Guidelines

1. **Organize by purpose**: Group remove-node rules together, then attr rules
2. **Add comments**: Explain why each transformation is needed
3. **Use patterns**: Use `starts-with()` and wildcards for multiple items
4. **Test incrementally**: Build after each major change to Metadata.xml
5. **Keep it minimal**: Only transform what's necessary

**Good Example:**
```xml
<metadata>
  <!-- ═════════════════════════════════════════════════ -->
  <!-- Remove Internal APIs -->
  <!-- ═════════════════════════════════════════════════ -->

  <!-- Internal packages are not meant for public consumption -->
  <remove-node path="/api/package[starts-with(@name, 'com.datadog.android.internal')]" />

  <!-- ═════════════════════════════════════════════════ -->
  <!-- Remove Kotlin Artifacts -->
  <!-- ═════════════════════════════════════════════════ -->

  <!-- Companion objects cause duplicate type errors -->
  <remove-node path="/api/package[@name='com.datadog.android.api.context']/class[@name='TimeInfo']/field[@name='Companion']" />

  <!-- ═════════════════════════════════════════════════ -->
  <!-- Naming Conventions -->
  <!-- ═════════════════════════════════════════════════ -->

  <!-- Rename to avoid conflict with System.Configuration -->
  <attr path="/api/package[@name='com.datadog.android.core.configuration']/class[@name='Configuration']"
        name="managedName">DDConfiguration</attr>
</metadata>
```

### Additions Guidelines

1. **Document the reason**: Add XML comments explaining why the Addition exists
2. **Keep it focused**: One Addition file per logical grouping
3. **Use extension methods**: Prefer extensions over inheritance
4. **Handle nulls**: Always check for null before calling JNI methods
5. **Consider SDK updates**: Additions break when the SDK changes

**Good Example:**
```csharp
// Additions/SpanExtensions.cs
namespace Datadog.Android.Trace;

/// <summary>
/// Extension methods for <see cref="ISpan"/> to provide safe null handling
/// and .NET-friendly exception conversion.
///
/// REASON: Auto-generated bindings don't handle nulls gracefully.
/// CREATED: 2024-01-15 for SDK 3.4.0
/// </summary>
public static class SpanExtensions
{
    /// <summary>
    /// Safely sets an error on the span, handling null spans and converting
    /// .NET exceptions to Java throwables.
    /// </summary>
    /// <param name="span">The span (can be null)</param>
    /// <param name="exception">The .NET exception to record</param>
    public static void SafeSetError(this ISpan? span, Exception exception)
    {
        if (span == null) return;

        var throwable = Java.Lang.Throwable.FromException(exception);
        span.SetError(throwable);
    }
}
```

### Dependency Management

1. **Use dependencies.yaml**: Centralize dependency decisions
2. **Prefer NuGet packages**: Use existing bindings (Gson, OkHttp, AndroidX)
3. **Download only what's needed**: Skip embedded/transitive dependencies
4. **Document decisions**: Add comments to dependencies.yaml

See [ANDROID_DEPENDENCIES.md](ANDROID_DEPENDENCIES.md) for details.

### Testing Strategy

1. **Build incrementally**: Test after each major change
2. **Test all target frameworks**: Build for net8/9/10-android
3. **Run the test app**: Ensure runtime behavior is correct
4. **Check SDK version**: Use `make ci-android` to simulate CI

---

## References

### Official Documentation

- **Microsoft: Android Binding Documentation**
  - [Binding a Java Library](https://learn.microsoft.com/en-us/xamarin/android/platform/binding-java-library/)
  - [Binding Metadata](https://learn.microsoft.com/en-us/xamarin/android/platform/binding-java-library/customizing-bindings/java-bindings-metadata)
  - [Troubleshooting Bindings](https://learn.microsoft.com/en-us/xamarin/android/platform/binding-java-library/troubleshooting-bindings)

- **Microsoft: Native Library Interop in .NET MAUI**
  - [Blog Post](https://devblogs.microsoft.com/dotnet/native-library-interop-dotnet-maui/#creating-the-api-interface)
  - Shows end-to-end example of creating Android bindings

- **Java Native Interface (JNI) Specification**
  - [Oracle JNI Docs](https://docs.oracle.com/javase/8/docs/technotes/guides/jni/spec/jniTOC.html)

### Project-Specific Documentation

- [ANDROID_DEPENDENCIES.md](ANDROID_DEPENDENCIES.md) - Dependency management with yq
- [TROUBLESHOOTING_BINDING_ERRORS.md](TROUBLESHOOTING_BINDING_ERRORS.md) - Error diagnosis guide
- [DEVELOPER_SETUP.md](DEVELOPER_SETUP.md) - Environment setup
- [QUICK_START.md](QUICK_START.md) - Common development tasks

### Datadog SDK Documentation

- [Datadog Android SDK](https://github.com/DataDog/dd-sdk-android)
- [Datadog Android SDK Docs](https://docs.datadoghq.com/real_user_monitoring/android/)

---

## Glossary

- **AAR**: Android Archive - Android library format containing compiled code, resources, and manifest
- **JAR**: Java Archive - Pure Java bytecode (no Android resources)
- **JNI**: Java Native Interface - Bridge between native code and Java
- **Binding**: C# wrapper around Java/Kotlin code
- **Metadata.xml**: XML file controlling binding generation transformations
- **Additions**: Hand-written C# code merged with generated bindings
- **api.xml**: XML description of Java APIs extracted from bytecode
- **Companion Object**: Kotlin singleton associated with a class
- **Extension Function**: Kotlin function that appears to extend a class
- **Partial Class**: C# class split across multiple files (used for merging generated + manual code)
