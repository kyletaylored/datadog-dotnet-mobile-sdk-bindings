# Troubleshooting .NET Binding Errors

This guide helps you understand and fix common errors that occur when updating to a new SDK version.

## Understanding the Architecture

### What are .NET Bindings?

.NET bindings are a bridge that lets C# code call native libraries (Java/Kotlin on Android, Swift/Objective-C on iOS). Think of them as translators between two languages.

```
┌─────────────────┐
│   Your C# App   │  ← Your application code
└────────┬────────┘
         │
┌────────▼────────┐
│  .NET Bindings  │  ← Auto-generated + Manual additions
└────────┬────────┘
         │
┌────────▼────────┐
│  Native SDK     │  ← Datadog's Java/Kotlin or Swift code
│  (Java/Swift)   │
└─────────────────┘
```

### Two Types of Binding Code

1. **Auto-generated Code** (`obj/.../generated/`)
   - Created automatically by the .NET binding generator
   - Reads Java/Kotlin classes and creates C# equivalents
   - Controlled by `Metadata.xml` files

2. **Manual Additions** (`Additions/` folder)
   - Hand-written C# code to fix issues or add convenience methods
   - **This is where most errors occur after SDK updates**

## Common Error Patterns After SDK Updates

### Error Type 1: "Method does not exist" or "No overload takes X arguments"

**Example Error:**
```
error CS1501: No overload for method 'SetError' takes 2 arguments
```

**What This Means:**
The native SDK changed a method signature. Either:
- Method was removed
- Number of parameters changed
- Parameter types changed

**How to Fix:**

#### Step 1: Find the method in the native SDK

```bash
# For Android (search Java/Kotlin files)
cd dd-sdk-android
grep -r "fun SetError\|fun setError" --include="*.kt" --include="*.java"

# For iOS (search Swift files)
cd dd-sdk-ios
grep -r "func setError" --include="*.swift"
```

#### Step 2: Compare old vs new signature

**Old SDK (might have been):**
```kotlin
fun setError(throwable: Throwable, message: String)
```

**New SDK:**
```kotlin
fun setError(throwable: Throwable)  // message parameter removed
```

#### Step 3: Update the Additions file

**Before:**
```csharp
// Additions/SpanExtensions.cs
span.SetError(exception, "Error message");
```

**After:**
```csharp
// Additions/SpanExtensions.cs
span.SetError(exception);  // Remove the second parameter
```

---

### Error Type 2: "Name does not exist in the current context"

**Example Error:**
```
error CS0103: The name 'BaggageItemsAsDictionary' does not exist in the current context
```

**What This Means:**
A method or property that used to exist was:
- Renamed
- Removed completely
- Moved to a different class

**How to Fix:**

#### Step 1: Check if it was renamed

Look in the `Metadata.xml` file for rename rules:

```xml
<!-- This shows BaggageItems was renamed to BaggageItemsAsDictionary -->
<attr path=".../method[@name='getBaggageItems']"
      name="managedName">BaggageItemsAsDictionary</attr>
```

#### Step 2: Search the native SDK

```bash
# Android
cd dd-sdk-android
grep -r "baggageItems\|baggage" --include="*.kt" --include="*.java"

# Look for the class that had this method
grep -r "class.*SpanContext" --include="*.kt" --include="*.java"
```

#### Step 3: Determine the fix

**Option A: Method was renamed**
```csharp
// Before
var items = context.BaggageItemsAsDictionary();

// After (if renamed to GetBaggage)
var items = context.GetBaggage();
```

**Option B: Method was removed**
```csharp
// Remove the entire Additions file if it's no longer needed
// or comment out/delete the broken method
```

---

### Error Type 3: "Does not contain a definition for X"

**Example Error:**
```
error CS0117: 'SpanExtKt' does not contain a definition for 'WithinSpan'
```

**What This Means:**
A Kotlin extension function or helper class was removed from the SDK.

**How to Fix:**

#### Step 1: Search for the function in the SDK

```bash
cd dd-sdk-android
grep -r "fun WithinSpan\|fun withinSpan" --include="*.kt"
```

#### Step 2: Check the SDK's CHANGELOG

```bash
cd dd-sdk-android
grep -i "withinspan\|removed.*span" CHANGELOG.md
```

Example from CHANGELOG:
```markdown
### Removed
- `withinSpan` extension function - use `tracer.buildSpan()` instead
```

#### Step 3: Update or remove the code

**Option A: Find replacement API**
```csharp
// Old code using removed API
SpanExtKt.WithinSpan(tracer, "operation", () => {
    // work
});

// New code using replacement
var span = tracer.BuildSpan("operation").Start();
try {
    // work
} finally {
    span.Finish();
}
```

**Option B: Remove if no longer needed**
Delete the entire Additions file if it was just wrapping a removed convenience method.

---

## Step-by-Step Troubleshooting Process

### 1. Identify the Error Type

Look at the error code:
- `CS1501` = Wrong number of arguments
- `CS0103` = Name doesn't exist
- `CS0117` = Class doesn't have that member
- `CS0246` = Type not found

### 2. Locate the Problematic Code

The error message tells you the file:
```
/path/to/Additions/SpanExtensions.cs(21,18): error CS1501
                                      ↑      ↑
                                    Line   Column
```

Open that file and go to that line.

### 3. Find the Native Method

**For Android:**
```bash
cd dd-sdk-android

# Search for the method name (try variations)
grep -r "setError\|SetError" features/ dd-sdk-android-core/src/main/
```

**For iOS:**
```bash
cd dd-sdk-ios

# Search for the method name
grep -r "setError" DatadogCore/ DatadogRUM/ DatadogTrace/
```

### 4. Check What Changed

**Compare with Metadata.xml:**
```bash
# See if the method was deliberately removed
grep -i "setError" src/Android/Bindings/Trace/Transforms/Metadata.xml
```

**Check the SDK's migration guide:**
```bash
cd dd-sdk-android
cat MIGRATION.md
```

### 5. Decide on a Fix

**Decision Tree:**

```
Is the method still in the native SDK?
├─ YES → Update the call to match new signature
└─ NO → Was it removed?
    ├─ Has replacement → Use new API
    └─ No replacement → Remove the Additions file
```

---

## Practical Examples from This Update (SDK 3.4.0)

### Example 1: BaggageItemsAsDictionary

**Error:**
```
error CS0103: The name 'BaggageItemsAsDictionary' does not exist
```

**Root Cause:**
The `Metadata.xml` had a rename rule that no longer applies because the method was removed from the OpenTracing API.

**Investigation:**
```bash
cd dd-sdk-android
grep -r "baggageItems" features/dd-sdk-android-trace-internal/
# Result: Method no longer exists
```

**Fix:**
Remove the Additions file since baggage is deprecated in newer tracing APIs.

---

### Example 2: SamplingPriorityInternal

**Error:**
```
error CS0103: The name 'SamplingPriorityInternal' does not exist
```

**Root Cause:**
This was a custom rename in Metadata.xml for a method that's now removed.

**Investigation:**
```bash
# Check Metadata.xml
grep "SamplingPriorityInternal" src/Android/Bindings/Trace/Transforms/Metadata.xml
```

Result:
```xml
<attr path=".../method[@name='getSamplingPriority']"
      name="managedName">SamplingPriorityInternal</attr>
```

But the method no longer exists in SDK 3.4.0.

**Fix:**
Remove the Additions file that uses it.

---

### Example 3: SetError Changed Signature

**Error:**
```
error CS1501: No overload for method 'SetError' takes 2 arguments
```

**Investigation:**
```bash
cd dd-sdk-android
grep -r "fun setError" features/dd-sdk-android-trace/
```

Result shows it now takes 1 parameter instead of 2.

**Old signature:**
```kotlin
fun setError(throwable: Throwable, message: String)
```

**New signature:**
```kotlin
fun setError(throwable: Throwable)
```

**Fix:**
Update the calls:
```csharp
// Before
span.SetError(exception, "Error occurred");

// After
span.SetError(exception);
```

---

## Tools and Commands Reference

### Search for Methods in Native SDKs

**Android (Java/Kotlin):**
```bash
# Search in features
cd dd-sdk-android
grep -r "methodName" features/ --include="*.kt" --include="*.java"

# Search in core
grep -r "methodName" dd-sdk-android-core/src/main/ --include="*.kt"

# Find a class
find . -name "*ClassName*.kt"
```

**iOS (Swift):**
```bash
cd dd-sdk-ios
grep -r "methodName" DatadogCore/ --include="*.swift"
grep -r "class.*ClassName" . --include="*.swift"
```

### Check Binding Metadata

```bash
# See what was removed
grep "remove-node" src/Android/Bindings/*/Transforms/Metadata.xml

# See what was renamed
grep "managedName" src/Android/Bindings/*/Transforms/Metadata.xml
```

### Find Additions Files

```bash
# List all manual additions
find src/Android/Bindings -path "*/Additions/*.cs"
find src/iOS/Bindings -path "*/Additions/*.cs"
```

### Test a Single Project

```bash
# Build just the problematic project
cd src/Android/Bindings/Trace
dotnet build -c Release
```

---

## Prevention: Making SDK Updates Easier

### 1. Keep Additions Minimal

Only add Additions files when absolutely necessary:
- ✅ DO: Fix binding bugs, add convenience overloads
- ❌ DON'T: Wrap every method "just in case"

### 2. Document Why Additions Exist

Add comments in Additions files:
```csharp
// Additions/SpanExtensions.cs
namespace Datadog.Android.Trace;

/// <summary>
/// REASON: The auto-generated SetError binding has incorrect nullability
/// FIX: Manually implement with correct null handling
/// UPSTREAM: https://github.com/DataDog/dd-sdk-android/issues/1234
/// </summary>
public static class SpanExtensions
{
    public static void SafeSetError(this ISpan span, Exception ex)
    {
        span?.SetError(ex);
    }
}
```

### 3. Check SDK Release Notes

Before updating, read:
- `dd-sdk-android/CHANGELOG.md`
- `dd-sdk-android/MIGRATION.md`
- `dd-sdk-ios/CHANGELOG.md`
- `dd-sdk-ios/MIGRATION.md`

Look for keywords:
- "Breaking change"
- "Removed"
- "Deprecated"
- "Renamed"

### 4. Test After Metadata Changes

When you update Metadata.xml to remove types:
1. Build immediately: `make ci-android`
2. Check if Additions files break
3. Remove/update Additions before committing

---

## Quick Reference Checklist

When you see binding errors after an SDK update:

- [ ] Note the error code (CS1501, CS0103, etc.)
- [ ] Find the file and line number
- [ ] Open the Additions file
- [ ] Search for the method in the native SDK
- [ ] Check if it exists, was renamed, or removed
- [ ] Consult CHANGELOG.md and MIGRATION.md
- [ ] Decide: Update, Replace, or Remove
- [ ] Test the fix: `make ci-android` or `make ci-ios`
- [ ] Document the change in commit message

---

## Getting Help

If stuck:

1. **Check the native SDK docs:**
   - Android: https://github.com/DataDog/dd-sdk-android
   - iOS: https://github.com/DataDog/dd-sdk-ios

2. **Search closed issues:**
   - Look for others who updated to the same version

3. **Compare with previous versions:**
   ```bash
   cd dd-sdk-android
   git log --all --grep="version you're upgrading to"
   ```

4. **Ask in the discussion:**
   - Provide: Error message, SDK version, steps you tried
