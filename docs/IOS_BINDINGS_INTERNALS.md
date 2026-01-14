# iOS Bindings Internals

This document explains how .NET iOS bindings work, the role of ApiDefinitions.cs and StructsAndEnums.cs files, and how to create and maintain bindings. This is a technical reference for developers and AI coding agents working on the binding layer.

> 🤖 **Platform Comparison**: See [Android Bindings Internals](ANDROID_BINDINGS_INTERNALS.md) to understand how Android bindings differ (auto-generated vs hand-written).

## Table of Contents

- [Overview](#overview)
- [How iOS Bindings Work](#how-ios-bindings-work)
- [The Binding Process](#the-binding-process)
- [ApiDefinitions.cs - The Core Bindings](#apidefinitionscs---the-core-bindings)
- [StructsAndEnums.cs - Type Definitions](#structsandenumcs---type-definitions)
- [Extras.cs - Manual Additions](#extrascs---manual-additions)
- [Common Binding Patterns](#common-binding-patterns)
- [Troubleshooting Binding Errors](#troubleshooting-binding-errors)
- [Best Practices](#best-practices)
- [References](#references)

---

## Overview

.NET iOS bindings allow C# code to call Swift/Objective-C libraries. Unlike Android bindings (which are mostly auto-generated), iOS bindings are **hand-written** C# interfaces decorated with attributes that describe the Objective-C interface.

```
┌─────────────────────────────────────────────────────────────┐
│                       Your C# App                           │
└──────────────────────────┬──────────────────────────────────┘
                           │ Calls C# APIs
┌──────────────────────────▼──────────────────────────────────┐
│                  .NET iOS Binding                           │
│  ┌─────────────────────┐  ┌─────────────────────────────┐  │
│  │  ApiDefinitions.cs  │  │  StructsAndEnums.cs         │  │
│  │  (Classes/Methods)  │  │  (Types/Constants)          │  │
│  └─────────────────────┘  └─────────────────────────────┘  │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  Extras.cs (Optional convenience methods)           │   │
│  └─────────────────────────────────────────────────────┘   │
│                Hand-Written C# with Attributes              │
└──────────────────────────┬──────────────────────────────────┘
                           │ Objective-C Runtime Bridge
┌──────────────────────────▼──────────────────────────────────┐
│       Native iOS Library (Swift/Objective-C)                │
│              (XCFramework files)                            │
└─────────────────────────────────────────────────────────────┘
```

**Key Components:**

1. **XCFramework Files**: Native iOS frameworks containing compiled Swift/Objective-C code
2. **ApiDefinitions.cs**: Hand-written C# interfaces with `[Export]` attributes describing the Objective-C API
3. **StructsAndEnums.cs**: C# enums, structs, and constants matching the native types
4. **Extras.cs** (Optional): Additional convenience methods or extensions

**Key Difference from Android:**

| Aspect | Android Bindings | iOS Bindings |
|--------|------------------|--------------|
| Generation | **Auto-generated** from Java bytecode | **Hand-written** from Objective-C headers |
| Metadata | Metadata.xml transforms generated code | Attributes directly in C# code |
| Maintenance | Update Metadata.xml when SDK changes | Update C# code when SDK changes |
| Tools | Binding generator reads JAR/AAR | Attributes describe Objective-C selectors |

---

## How iOS Bindings Work

### The Objective-C Runtime Bridge

.NET iOS bindings use the Objective-C runtime to bridge between managed C# code and native Objective-C/Swift code. The runtime uses **selectors** (method names) and **message passing** to invoke native methods.

```csharp
// Your C# code
var config = new DDConfiguration("client-token", "prod");
config.Service = "my-app";

// Generated binding (simplified)
[BaseType (typeof(NSObject), Name = "_TtC11DatadogObjc15DDConfiguration")]
interface DDConfiguration
{
    [Export ("initWithClientToken:env:")]
    NativeHandle Constructor (string clientToken, string env);

    [Export ("service")]
    string Service { get; set; }
}

// At runtime, the CLR generates this (conceptual):
// 1. Allocate Objective-C object: objc_msgSend(DDConfiguration.class, @selector(alloc))
// 2. Call init: objc_msgSend(obj, @selector(initWithClientToken:env:), token, env)
// 3. Set property: objc_msgSend(obj, @selector(setService:), "my-app")
```

The `[Export]` attribute tells the runtime which Objective-C selector to call. The runtime handles:
- Converting C# types to Objective-C types
- Managing object lifetime and memory
- Marshaling strings, arrays, and other complex types
- Handling delegates and blocks

### Swift vs Objective-C

The Datadog iOS SDK is written in Swift, but it provides an **Objective-C compatibility layer** for bindings:

```swift
// Swift (internal)
@objc(DDConfiguration)
public class Configuration: NSObject {
    @objc public var clientToken: String
    @objc public var env: String
    @objc public var service: String?

    @objc(initWithClientToken:env:)
    public init(clientToken: String, env: String) {
        self.clientToken = clientToken
        self.env = env
    }
}
```

The `@objc` attributes expose Swift classes/methods to Objective-C, which allows .NET bindings to call them. The `Name` parameter in `[BaseType]` specifies the mangled Swift name:

```csharp
[BaseType (typeof(NSObject), Name = "_TtC11DatadogObjc15DDConfiguration")]
//                            ↑ Mangled Swift class name
```

### Type Mappings

Objective-C types are mapped to C# equivalents:

| Objective-C Type | C# Type | Notes |
|------------------|---------|-------|
| `NSString *` | `string` | Automatic marshaling |
| `NSInteger`, `NSUInteger` | `nint`, `nuint` | Native integer types |
| `int`, `long`, `float`, `double` | `int`, `long`, `float`, `double` | Direct mapping |
| `BOOL` | `bool` | Objective-C boolean |
| `void` | `void` | Direct mapping |
| `NSArray *` | `NSArray` or `T[]` | Can be strongly typed |
| `NSDictionary *` | `NSDictionary` or `NSDictionary<K,V>` | Generic version available |
| `id` (any object) | `NSObject` | Base Objective-C type |
| `nullable id` | `NSObject?` | Nullable reference |
| Blocks (closures) | `Action<T>` or `Func<T,R>` | Lambda/delegate |
| Custom classes | C# classes inheriting `NSObject` | Binding defined |
| Enums | C# enums with `[Native]` attribute | Native size enums |

---

## The Binding Process

### Build Pipeline

```
┌────────────────────┐
│ XCFramework Files  │  ← Native Swift/Objective-C frameworks
└─────────┬──────────┘
          │
          ▼
┌────────────────────┐
│ Write C# Bindings  │  ← Hand-write ApiDefinitions.cs
│  (ApiDefinitions)  │     matching Objective-C headers
└─────────┬──────────┘
          │
          ▼
┌────────────────────┐
│  Define Types      │  ← Create StructsAndEnums.cs for
│ (StructsAndEnums)  │     enums, constants, delegates
└─────────┬──────────┘
          │
          ▼
┌────────────────────┐
│ Add Extras (Opt)   │  ← Optional Extras.cs for convenience
└─────────┬──────────┘
          │
          ▼
┌────────────────────┐
│ Build & Generate   │  ← .NET compiles + generates runtime
│                    │     bridge code
└─────────┬──────────┘
          │
          ▼
┌────────────────────┐
│   Compile to DLL   │  ← Final binding assembly
└────────────────────┘
```

### Project Structure

```
src/iOS/Bindings/Core/
├── Core.csproj                    # MSBuild project file
├── ApiDefinition.cs              # Empty template (not used)
├── ApiDefinitions.cs             # Actual hand-written bindings ← The important one!
├── StructsAndEnums.cs            # Enums and constants
├── Extras.cs                     # (Optional) Extension methods
└── README.md                     # Package documentation
```

**Important Naming:**
- `ApiDefinition.cs` (singular) - Template file with comments, not compiled
- `ApiDefinitions.cs` (plural) - Actual bindings, this is what gets compiled!

### Core.csproj Configuration

```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <!-- Target iOS on .NET 8/9/10 -->
    <TargetFrameworks>net8.0-ios;net9.0-ios;net10.0-ios</TargetFrameworks>

    <!-- This is a binding project -->
    <IsBindingProject>true</IsBindingProject>

    <!-- Minimum iOS version -->
    <SupportedOSPlatformVersion>17.0</SupportedOSPlatformVersion>

    <!-- Assembly name (lowercase to avoid conflicts) -->
    <AssemblyName>core</AssemblyName>

    <!-- Package metadata -->
    <PackageId>Bcr.Datadog.iOS.Core</PackageId>
    <PackageVersion>3.4.0</PackageVersion>
  </PropertyGroup>

  <!-- Reference the XCFramework -->
  <ItemGroup>
    <NativeReference Include="../Libs/DDC.xcframework">
      <Kind>Framework</Kind>
      <Frameworks>Foundation</Frameworks>
      <SmartLink>True</SmartLink>
      <ForceLoad>True</ForceLoad>
    </NativeReference>
  </ItemGroup>

  <!-- Include binding source files -->
  <ItemGroup>
    <ObjcBindingApiDefinition Include="ApiDefinitions.cs" />
    <ObjcBindingCoreSource Include="StructsAndEnums.cs" />
  </ItemGroup>
</Project>
```

**Key ItemGroup Types:**

- `<NativeReference>`: XCFramework to link against
- `<ObjcBindingApiDefinition>`: C# files with `[BaseType]` and `[Export]` attributes
- `<ObjcBindingCoreSource>`: C# files with enums, structs, and helpers

---

## ApiDefinitions.cs - The Core Bindings

ApiDefinitions.cs contains hand-written C# interfaces that describe the Objective-C API. Each interface represents an Objective-C class, protocol, or category.

### Basic Class Binding

**Objective-C Header:**
```objc
// DDConfiguration.h
@interface DDConfiguration : NSObject

@property (nonatomic, copy) NSString *clientToken;
@property (nonatomic, copy) NSString *env;
@property (nonatomic, copy, nullable) NSString *service;

- (instancetype)initWithClientToken:(NSString *)clientToken
                                env:(NSString *)env;
@end
```

**C# Binding:**
```csharp
// ApiDefinitions.cs
[BaseType (typeof(NSObject), Name = "_TtC11DatadogObjc15DDConfiguration")]
[DisableDefaultCtor]
interface DDConfiguration
{
    // @property (copy, nonatomic) NSString * _Nonnull clientToken;
    [Export ("clientToken")]
    string ClientToken { get; set; }

    // @property (copy, nonatomic) NSString * _Nonnull env;
    [Export ("env")]
    string Env { get; set; }

    // @property (copy, nonatomic) NSString * _Nullable service;
    [NullAllowed, Export ("service")]
    string Service { get; set; }

    // -(instancetype _Nonnull)initWithClientToken:(NSString * _Nonnull)clientToken env:(NSString * _Nonnull)env;
    [Export ("initWithClientToken:env:")]
    [DesignatedInitializer]
    NativeHandle Constructor (string clientToken, string env);
}
```

**Key Attributes:**

- `[BaseType(typeof(NSObject))]`: Specifies the base class
- `Name = "..."`: Mangled Swift class name (use `nm` to find it)
- `[DisableDefaultCtor]`: Prevent parameterless constructor
- `[Export("selector")]`: Maps to Objective-C method/property selector
- `[NullAllowed]`: Indicates nullable parameter or return type
- `[DesignatedInitializer]`: Marks the primary constructor

### Property Bindings

**Read/Write Property:**
```csharp
[Export ("clientToken")]
string ClientToken { get; set; }
```

**Read-Only Property:**
```csharp
[Export ("version")]
string Version { get; }
```

**Nullable Property:**
```csharp
[NullAllowed, Export ("service")]
string Service { get; set; }
```

**Strong Reference (Object):**
```csharp
[Export ("site", ArgumentSemantic.Strong)]
DDSite Site { get; set; }
```

**Enum Property:**
```csharp
[Export ("batchSize", ArgumentSemantic.Assign)]
DDBatchSize BatchSize { get; set; }
```

### Method Bindings

**Simple Method:**
```csharp
// -(void)start;
[Export ("start")]
void Start ();
```

**Method with Parameters:**
```csharp
// -(void)setUserInfoWithId:(NSString *)id name:(NSString *)name email:(NSString *)email;
[Export ("setUserInfoWithId:name:email:")]
void SetUserInfo (string id, string name, string email);
```

**Method with Nullable Parameters:**
```csharp
[Export ("setUserInfoWithId:name:email:extraInfo:")]
void SetUserInfo (
    [NullAllowed] string id,
    [NullAllowed] string name,
    [NullAllowed] string email,
    [NullAllowed] NSDictionary<NSString, NSObject> extraInfo
);
```

**Method Returning Value:**
```csharp
// -(DDLogger *)createLogger:(DDLoggerConfiguration *)config;
[Export ("createLogger:")]
DDLogger CreateLogger (DDLoggerConfiguration config);
```

**Static Method:**
```csharp
[Static]
[Export ("sharedInstance")]
DDLogger SharedInstance { get; }
```

### Constructor Bindings

**Designated Initializer:**
```csharp
[Export ("initWithClientToken:env:")]
[DesignatedInitializer]
NativeHandle Constructor (string clientToken, string env);
```

**Convenience Initializer:**
```csharp
[Export ("init")]
NativeHandle Constructor ();
```

**Multiple Constructors:**
```csharp
interface DDLoggerConfiguration
{
    [Export ("init")]
    NativeHandle Constructor ();

    [Export ("initWithService:")]
    NativeHandle Constructor (string service);
}
```

### Protocol Bindings

Protocols are Objective-C interfaces (similar to C# interfaces).

**Objective-C Protocol:**
```objc
@protocol DDDataEncryption
- (NSData *)encryptWithData:(NSData *)data error:(NSError **)error;
- (NSData *)decryptWithData:(NSData *)data error:(NSError **)error;
@end
```

**C# Binding:**
```csharp
[Protocol (Name = "_TtP11DatadogObjc16DDDataEncryption_")]
interface DDDataEncryption
{
    [Abstract]
    [Export ("encryptWithData:error:")]
    [return: NullAllowed]
    NSData EncryptWithData (NSData data, NSObject error);

    [Abstract]
    [Export ("decryptWithData:error:")]
    [return: NullAllowed]
    NSData DecryptWithData (NSData data, NSObject error);
}
```

**Attributes:**

- `[Protocol]`: Marks this as a protocol, not a class
- `[Abstract]`: Required protocol method (like `@required` in Objective-C)
- `[return: NullAllowed]`: Return value can be nil

### Delegate Bindings

Delegates are C# types for Objective-C blocks/closures.

**Objective-C Block:**
```objc
typedef void (^CompletionHandler)(BOOL success, NSError *error);

- (void)performActionWithCompletion:(CompletionHandler)completion;
```

**C# Binding:**
```csharp
// Define delegate type in StructsAndEnums.cs
delegate void CompletionHandler (bool success, NSError error);

// Use in ApiDefinitions.cs
[Export ("performActionWithCompletion:")]
void PerformAction (CompletionHandler completion);
```

**Usage:**
```csharp
obj.PerformAction ((success, error) => {
    if (success) {
        Console.WriteLine("Success!");
    } else {
        Console.WriteLine($"Error: {error}");
    }
});
```

---

## StructsAndEnums.cs - Type Definitions

StructsAndEnums.cs contains C# definitions for Objective-C enums, constants, delegates, and simple types.

### Enum Bindings

**Objective-C Enum:**
```objc
typedef NS_ENUM(NSInteger, DDBatchSize) {
    DDBatchSizeSmall,
    DDBatchSizeMedium,
    DDBatchSizeLarge
};
```

**C# Binding:**
```csharp
[Native]
public enum DDBatchSize : long
{
    Small = 0,
    Medium = 1,
    Large = 2
}
```

**Attributes:**

- `[Native]`: Uses native platform integer size (NSInteger)
- `: long`: Base type (NSInteger is usually long)

### Constants

**Objective-C Constants:**
```objc
extern NSString *const DDErrorDomain;
extern const NSInteger DDErrorCodeNetwork;
```

**C# Binding:**
```csharp
[Field ("DDErrorDomain", "__Internal")]
NSString DDErrorDomain { get; }

public const nint DDErrorCodeNetwork = 100;
```

### Delegate Types

**Objective-C Block Typedef:**
```objc
typedef void (^DDLoggerBlock)(NSString *message);
typedef BOOL (^DDFilterBlock)(NSObject *event);
```

**C# Binding:**
```csharp
delegate void DDLoggerBlock (string message);
delegate bool DDFilterBlock (NSObject @event);
```

### Struct Bindings (Rare)

**Objective-C Struct:**
```objc
typedef struct {
    double latitude;
    double longitude;
} DDCoordinate;
```

**C# Binding:**
```csharp
[StructLayout(LayoutKind.Sequential)]
public struct DDCoordinate
{
    public double Latitude;
    public double Longitude;
}
```

---

## Extras.cs - Manual Additions

Extras.cs files contain optional convenience methods, extensions, and helper code that make the API more C#-friendly.

### Extension Methods

```csharp
// Extras.cs
namespace Datadog.iOS.ObjC
{
    public static class DDConfigurationExtensions
    {
        /// <summary>
        /// Creates a DDConfiguration with common default settings.
        /// </summary>
        public static DDConfiguration CreateDefault(string clientToken, string env)
        {
            var config = new DDConfiguration(clientToken, env);
            config.BatchSize = DDBatchSize.Medium;
            config.UploadFrequency = DDUploadFrequency.Average;
            return config;
        }
    }
}
```

### Partial Classes

You can extend bound classes using partial classes:

```csharp
// ApiDefinitions.cs
[BaseType (typeof(NSObject))]
interface DDLogger
{
    [Export ("debug:")]
    void Debug (string message);
}

// Extras.cs
public partial class DDLogger
{
    /// <summary>
    /// Logs a debug message with string interpolation support.
    /// </summary>
    public void DebugFormat(string format, params object[] args)
    {
        Debug(string.Format(format, args));
    }
}
```

### Type Conversions

```csharp
public static class DDErrorExtensions
{
    /// <summary>
    /// Converts a .NET Exception to an NSError.
    /// </summary>
    public static NSError ToNSError(this Exception ex)
    {
        return new NSError(
            new NSString("DDErrorDomain"),
            1000,
            NSDictionary.FromObjectAndKey(
                new NSString(ex.Message),
                NSError.LocalizedDescriptionKey
            )
        );
    }
}
```

---

## Common Binding Patterns

### Pattern 1: Finding the Mangled Swift Name

**Problem:** You need the `Name` parameter for `[BaseType]` when binding a Swift class.

**Solution:** Use `nm` to list symbols in the XCFramework:

```bash
# Extract symbols from XCFramework
nm -gU src/iOS/Bindings/Libs/DDC.xcframework/ios-arm64/DDC.framework/DDC | grep DDConfiguration

# Output shows mangled name:
# _TtC11DatadogObjc15DDConfiguration
```

Use this in your binding:
```csharp
[BaseType (typeof(NSObject), Name = "_TtC11DatadogObjc15DDConfiguration")]
```

### Pattern 2: Binding Optional Parameters

**Objective-C:**
```objc
- (void)logWithMessage:(NSString *)message
            attributes:(NSDictionary *)attributes;
```

**C# Binding:**
```csharp
[Export ("logWithMessage:attributes:")]
void Log (string message, [NullAllowed] NSDictionary<NSString, NSObject> attributes);
```

**Usage:**
```csharp
logger.Log("Test message", null);  // attributes can be null
```

### Pattern 3: Binding Enums with String Values

Some Swift enums are backed by strings, not integers.

**Swift:**
```swift
@objc public enum DDSite: String {
    case us1 = "US1"
    case eu1 = "EU1"
}
```

These are usually bound as classes with static properties:

```csharp
[BaseType (typeof(NSObject))]
interface DDSite
{
    [Static, Export ("us1")]
    DDSite US1 { get; }

    [Static, Export ("eu1")]
    DDSite EU1 { get; }
}
```

### Pattern 4: Binding Class Methods

**Objective-C:**
```objc
@interface DDDatadog : NSObject
+ (void)initialize:(DDConfiguration *)configuration;
+ (DDDatadog *)shared;
@end
```

**C# Binding:**
```csharp
[BaseType (typeof(NSObject))]
interface DDDatadog
{
    [Static]
    [Export ("initialize:")]
    void Initialize (DDConfiguration configuration);

    [Static]
    [Export ("shared")]
    DDDatadog Shared { get; }
}
```

### Pattern 5: Binding Methods with Out Parameters

**Objective-C:**
```objc
- (BOOL)saveToFile:(NSString *)path error:(NSError **)error;
```

**C# Binding:**
```csharp
[Export ("saveToFile:error:")]
bool SaveToFile (string path, out NSError error);
```

**Usage:**
```csharp
NSError error;
bool success = obj.SaveToFile("/path/to/file", out error);
if (!success) {
    Console.WriteLine($"Error: {error.LocalizedDescription}");
}
```

### Pattern 6: Binding Generic Types

**Objective-C:**
```objc
@interface DDCache<T> : NSObject
- (void)set:(T)value forKey:(NSString *)key;
- (T)getForKey:(NSString *)key;
@end
```

.NET doesn't support generic Objective-C classes directly. Use `NSObject`:

```csharp
[BaseType (typeof(NSObject))]
interface DDCache
{
    [Export ("set:forKey:")]
    void Set (NSObject value, string key);

    [Export ("getForKey:")]
    NSObject Get (string key);
}
```

---

## Troubleshooting Binding Errors

### Error: "Does not contain a definition for X"

**Cause:** The `[Export]` selector doesn't match the Objective-C method name.

**Fix:** Check the selector carefully. Objective-C selectors include colons:

```objc
// Objective-C: Two parameters, selector has two parts
- (void)setUserInfo:(NSString *)name email:(NSString *)email;

// WRONG:
[Export ("setUserInfo")]
void SetUserInfo (string name, string email);

// CORRECT:
[Export ("setUserInfo:email:")]
void SetUserInfo (string name, string email);
```

### Error: "Selector not found"

**Cause:** The method doesn't exist in the native library, or the name is wrong.

**Fix:** Use `nm` or `otool` to verify the symbol exists:

```bash
nm -gU DDC.framework/DDC | grep setUserInfo
```

### Error: "Cannot marshal type X"

**Cause:** The C# type can't be automatically marshaled to Objective-C.

**Fix:** Use a supported type or manual marshaling:

```csharp
// Instead of System.DateTime
[Export ("setDate:")]
void SetDate (NSDate date);

// Convert when calling:
obj.SetDate((NSDate)DateTime.Now);
```

### Error: "DesignatedInitializer required"

**Cause:** Objective-C class requires a specific initializer.

**Fix:** Add `[DesignatedInitializer]` to the primary constructor:

```csharp
[Export ("initWithClientToken:env:")]
[DesignatedInitializer]
NativeHandle Constructor (string clientToken, string env);
```

### Error: Crashes at Runtime

**Common Causes:**

1. **Wrong selector:** The `[Export]` doesn't match the actual method
   ```bash
   # Verify with:
   nm -gU Framework.framework/Framework | grep methodName
   ```

2. **Wrong base type:** Class doesn't actually inherit from NSObject
   ```csharp
   // Fix: Check the actual base class in headers
   [BaseType (typeof(CorrectBaseClass))]
   ```

3. **Missing ForceLoad:** The framework isn't linked
   ```xml
   <!-- Add to .csproj: -->
   <ForceLoad>True</ForceLoad>
   ```

---

## Best Practices

### ApiDefinitions.cs Guidelines

1. **Match Objective-C structure**: Keep the same order as the headers for easy reference
2. **Include comments**: Copy Objective-C comments above each binding
3. **Use clear names**: Follow C# naming conventions (PascalCase for methods/properties)
4. **Group related items**: Keep constructors, properties, and methods together
5. **Test incrementally**: Build after adding each class to catch errors early

**Good Example:**
```csharp
// @interface DDConfiguration
[BaseType (typeof(NSObject), Name = "_TtC11DatadogObjc15DDConfiguration")]
[DisableDefaultCtor]
interface DDConfiguration
{
    // MARK: - Properties

    // @property (copy, nonatomic) NSString * _Nonnull clientToken;
    [Export ("clientToken")]
    string ClientToken { get; set; }

    // @property (copy, nonatomic) NSString * _Nonnull env;
    [Export ("env")]
    string Env { get; set; }

    // MARK: - Initializers

    // -(instancetype _Nonnull)initWithClientToken:(NSString * _Nonnull)clientToken env:(NSString * _Nonnull)env;
    [Export ("initWithClientToken:env:")]
    [DesignatedInitializer]
    NativeHandle Constructor (string clientToken, string env);
}
```

### StructsAndEnums.cs Guidelines

1. **Use [Native] for NS enums**: Match the native integer size
2. **Define delegates early**: Other types may reference them
3. **Group by purpose**: Keep related enums together
4. **Document values**: Add XML comments explaining enum values

**Good Example:**
```csharp
namespace Datadog.iOS.ObjC
{
    /// <summary>
    /// Specifies the batch size for uploading data.
    /// </summary>
    [Native]
    public enum DDBatchSize : long
    {
        /// <summary>Small batches for low bandwidth</summary>
        Small = 0,

        /// <summary>Medium batches (recommended)</summary>
        Medium = 1,

        /// <summary>Large batches for high bandwidth</summary>
        Large = 2
    }
}
```

### Maintenance Strategy

**When the Native SDK Updates:**

1. **Compare headers**: Use `diff` to see what changed in Objective-C headers
   ```bash
   cd dd-sdk-ios
   git diff 2.17.0..2.18.0 -- DatadogCore/Sources/Public/
   ```

2. **Update bindings**: Add new methods, remove deprecated ones, update signatures

3. **Update enums**: Check for new enum values or types

4. **Test thoroughly**: Build and run the test app to verify functionality

5. **Update version**: Increment package version in .csproj

**Tracking Changes:**

```bash
# See what changed in public API
cd dd-sdk-ios
git log --oneline --all DatadogCore/Sources/Public/

# See specific file history
git log -p DatadogCore/Sources/Public/Datadog.swift
```

---

## References

### Official Documentation

- **Microsoft: iOS Binding Documentation**
  - [Binding Objective-C Libraries](https://learn.microsoft.com/en-us/xamarin/ios/platform/binding-objective-c/)
  - [Binding Types Reference](https://learn.microsoft.com/en-us/xamarin/ios/platform/binding-objective-c/binding-types-reference)
  - [Objective Sharpie](https://learn.microsoft.com/en-us/xamarin/cross-platform/macios/binding/objective-sharpie/) - Tool to generate initial bindings

- **Microsoft: Native Library Interop in .NET MAUI**
  - [Blog Post](https://devblogs.microsoft.com/dotnet/native-library-interop-dotnet-maui/#creating-the-api-interface)
  - Shows end-to-end example of creating iOS bindings

- **Apple: Objective-C Runtime**
  - [Objective-C Runtime Programming Guide](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Introduction/Introduction.html)

### Tools

- **Objective Sharpie**: Auto-generates initial bindings from Objective-C headers
  ```bash
  sharpie bind --output=Generated --namespace=Datadog.iOS.Core \
    --sdk=iphoneos16.0 Headers/*.h
  ```

- **nm**: List symbols in Mach-O binaries
  ```bash
  nm -gU Framework.framework/Framework
  ```

- **otool**: Examine Mach-O files
  ```bash
  otool -L Framework.framework/Framework  # Show dependencies
  ```

### Project-Specific Documentation

- [ANDROID_BINDINGS_INTERNALS.md](ANDROID_BINDINGS_INTERNALS.md) - Android binding reference (contrast with iOS)
- [TROUBLESHOOTING_BINDING_ERRORS.md](TROUBLESHOOTING_BINDING_ERRORS.md) - Error diagnosis guide
- [DEVELOPER_SETUP.md](DEVELOPER_SETUP.md) - Environment setup
- [QUICK_START.md](QUICK_START.md) - Common development tasks

### Datadog SDK Documentation

- [Datadog iOS SDK](https://github.com/DataDog/dd-sdk-ios)
- [Datadog iOS SDK Docs](https://docs.datadoghq.com/real_user_monitoring/ios/)

---

## Glossary

- **XCFramework**: iOS framework format containing compiled Swift/Objective-C code for multiple architectures
- **Objective-C Runtime**: Dynamic runtime that handles method dispatch and object management
- **Selector**: Objective-C method name (e.g., `setUserInfo:email:`)
- **Message Passing**: Objective-C method invocation mechanism
- **NSObject**: Base class for all Objective-C objects
- **Export Attribute**: `[Export]` maps C# method to Objective-C selector
- **BaseType Attribute**: `[BaseType]` specifies the Objective-C base class
- **Protocol**: Objective-C interface (similar to C# interface)
- **Block**: Objective-C closure (mapped to C# delegate)
- **Mangled Name**: Swift name encoding for Objective-C compatibility
- **Native Handle**: Reference to native Objective-C object
- **NullAllowed**: Indicates nullable Objective-C reference
- **DesignatedInitializer**: Primary constructor for a class
