# SDK Versioning and Maintenance Strategy

This document outlines the strategy for maintaining .NET bindings across major SDK version updates.

## Table of Contents
- [Version Compatibility Model](#version-compatibility-model)
- [Branching Strategy](#branching-strategy)
- [Update Workflow](#update-workflow)
- [File Lifecycle Management](#file-lifecycle-management)
- [Decision Trees](#decision-trees)
- [Examples](#examples)

---

## Version Compatibility Model

### Understanding Semantic Versioning

Datadog SDKs follow semantic versioning: `MAJOR.MINOR.PATCH`

- **MAJOR** (e.g., 2.x → 3.x): Breaking API changes
- **MINOR** (e.g., 3.1 → 3.2): New features, backward compatible
- **PATCH** (e.g., 3.1.0 → 3.1.1): Bug fixes, backward compatible

### Our Binding Version Strategy

**Recommendation: Match the native SDK major version**

```
Native SDK Version    →    Binding NuGet Version
─────────────────────────────────────────────────
dd-sdk-android 2.26.0  →   Bcr.Datadog.Android.* 2.26.0
dd-sdk-android 3.4.0   →   Bcr.Datadog.Android.* 3.4.0
dd-sdk-ios 2.26.0      →   Bcr.Datadog.iOS.* 2.26.0
dd-sdk-ios 3.4.0       →   Bcr.Datadog.iOS.* 3.4.0
```

**Why?**
- Clear version alignment for users
- Signals breaking changes when native SDK breaks
- Easier support ("What version are you using?")

---

## Branching Strategy

### Production Branches

```
main
├── release/v2.x    (Maintenance branch for 2.x - frozen)
├── release/v3.x    (Active development for 3.x)
└── release/v4.x    (Future major version)
```

### When to Create a New Branch

**Create a new release branch when:**
1. Native SDK releases a new MAJOR version (e.g., 2.x → 3.x)
2. Breaking changes require removing/changing significant code
3. You need to support both old and new major versions simultaneously

**Example Timeline:**

```
2024-01-01: SDK 2.26.0
├── Work on main branch
├── Tag: v2.26.0
│
2024-06-01: SDK 3.0.0 released (BREAKING CHANGES)
├── Create branch: release/v2.x from main
├── Tag release/v2.x: v2.26.0 (last 2.x version)
├── Continue on main with 3.0.0 changes
│
2024-06-15: SDK 2.27.0 released (patch for 2.x users)
├── Optional: Cherry-pick to release/v2.x
├── Tag: v2.27.0 on release/v2.x branch
│
2024-07-01: SDK 3.4.0 released
├── Update on main branch
├── Tag: v3.4.0
```

### Branch Lifecycle

#### Active Branches
- **main**: Latest major version (currently 3.x)
- **release/v3.x**: Same as main (can be aliased)

#### Maintenance Branches
- **release/v2.x**: Security fixes only, frozen for new features
- **release/v1.x**: End of life, archived

#### Policy
- Maintain the previous major version for **6 months** after new major release
- After 6 months, archive and mark as unsupported

---

## Update Workflow

### Minor/Patch Updates (3.1.0 → 3.2.0 or 3.1.0 → 3.1.1)

**Expected changes:** Minimal breaking changes

```bash
# 1. Update SDK versions
./scripts/update-sdk-versions.sh --android-version 3.2.0 --ios-version 3.2.0

# 2. Build locally
make ci-android
make ci-ios

# 3. Check for errors
# - Usually none or minimal binding warnings
# - No Additions file changes needed

# 4. Test
make ci-test

# 5. Commit and tag
git add -A
git commit -m "Update to SDK 3.2.0"
git tag v3.2.0
git push origin main --tags
```

**If errors occur:**
- Check if new APIs were added (usually just warnings)
- Verify no public APIs were removed (rare in MINOR/PATCH)
- Follow [TROUBLESHOOTING_BINDING_ERRORS.md](TROUBLESHOOTING_BINDING_ERRORS.md)

### Major Updates (2.x → 3.x)

**Expected changes:** Significant breaking changes, API removals

```bash
# 1. Create maintenance branch for old version
git checkout -b release/v2.x
git tag v2.26.0-final
git push origin release/v2.x --tags

# 2. Return to main for 3.x work
git checkout main

# 3. Update SDK versions
./scripts/update-sdk-versions.sh --android-version 3.0.0 --ios-version 3.0.0

# 4. Review native SDK migration guides
cd dd-sdk-android
cat MIGRATION.md | grep -A 50 "3.0"

cd dd-sdk-ios
cat MIGRATION.md | grep -A 50 "3.0"

# 5. Build and identify issues
make ci-android 2>&1 | tee /tmp/build-errors.txt
make ci-ios 2>&1 | tee -a /tmp/build-errors.txt

# 6. Systematically fix each error
# - Update Metadata.xml to remove obsolete types
# - Remove/update Additions files
# - Document each change

# 7. Update documentation
# - Add migration guide for binding users
# - Update README with new version

# 8. Test thoroughly
make ci-test

# 9. Commit with detailed message
git add -A
git commit -m "feat: Upgrade to SDK 3.0.0

BREAKING CHANGES:
- Removed DatadogObjc bindings (deprecated in SDK 3.0)
- Removed trace extension methods (API simplified)
- Updated Metadata.xml to exclude removed types

Migration guide: See docs/MIGRATION_3.0.md"

git tag v3.0.0
git push origin main --tags
```

---

## File Lifecycle Management

### Types of Files and Their Lifecycle

#### 1. **Metadata.xml** Files

**Purpose:** Control what gets bound from native SDK

**Lifecycle:**
- **Born:** When a type needs to be excluded or renamed
- **Modified:** When SDK removes/renames types
- **Never Deleted:** These files accumulate rules over time

**Strategy:**
```xml
<!-- Keep removal rules even if type no longer exists -->
<!-- Reason: Prevents resurrection if SDK adds it back -->
<remove-node path="/api/package[@name='com.datadog.internal']" />

<!-- Comment old rules for historical context -->
<!-- Removed in SDK 3.0 - DatadogObjc module deprecated -->
<remove-node path="/api/package[@name='com.datadog.objc']" />
```

**When to clean up:**
- Never remove rules for major version updates (keeps clarity)
- Can consolidate duplicate rules
- Add comments explaining SDK version that introduced the rule

#### 2. **Additions/** Files

**Purpose:** Manual C# code to fix binding issues or add convenience

**Lifecycle:**
- **Born:** When auto-generated binding has issues
- **Modified:** When native API changes
- **Deleted:** When native API is removed OR binding generator improves

**Decision Matrix:**

```
Does the native API still exist?
├─ NO  → DELETE the Additions file
│       Example: SpanExtKt.setError() removed in SDK 3.0
│
└─ YES → Does the binding work now?
        ├─ YES → DELETE (generator improved)
        │        Example: Nullability fixed in .NET 9
        │
        └─ NO  → UPDATE to match new API
                 Example: Method signature changed
```

**Examples from SDK 3.0 Update:**

| File | Native API Status | Action | Reason |
|------|------------------|--------|--------|
| `SpanExtensions.cs` | Removed | ✅ DELETE | `SpanExtKt.setError()` gone |
| `SqliteExtensions.cs` | Removed | ✅ DELETE | `transactionTraced()` gone |
| `DDSpan.cs` | Removed | ✅ DELETE | `SamplingPriorityInternal` gone |
| `DDSpanContext.cs` | Removed | ✅ DELETE | `baggageItems()` gone |

#### 3. **README.md** Files (per package)

**Purpose:** User documentation for each NuGet package

**Lifecycle:**
- **Born:** With the binding project
- **Modified:** When APIs change significantly
- **Marked Deprecated:** When package is obsoleted (never deleted)

**Update Triggers:**
- Major version: Full review and update
- Minor version: Add new features if significant
- Deprecated: Add deprecation notice at top

**Example (ObjC package deprecated in 3.0):**
```markdown
# Datadog iOS SDK - ObjC Bindings

> **⚠️ DEPRECATED:** This package is deprecated as of SDK 3.0
> Use individual packages instead: Core, Logs, RUM, Trace
```

#### 4. **Test Applications** (`src/Android/Bindings/Test/`, `src/iOS/T/`)

**Purpose:** Smoke test that bindings work

**Lifecycle:**
- **Modified:** Every major update
- **Never Deleted:** Always keep test apps

**Update Strategy:**
```csharp
// KEEP: Use ProjectReferences, not PackageReferences
<ItemGroup>
  <ProjectReference Include="..\Bindings\Core\Core.csproj" />
  // ... other projects
</ItemGroup>

// WHY: Allows testing unreleased versions locally
```

---

## Decision Trees

### Should I Keep This Additions File?

```
START: An Additions file exists from a previous version
│
├─ Run build without the file
│  ├─ Build succeeds → DELETE (no longer needed)
│  └─ Build fails
│      │
│      ├─ Check if native API exists
│      │  ├─ API removed from native SDK → DELETE
│      │  └─ API still exists
│      │      │
│      │      └─ Fix the Additions file to match new API → KEEP & UPDATE
│
└─ File has clear comment explaining purpose → Review comment validity
    ├─ Purpose still valid → KEEP
    └─ Purpose no longer relevant → DELETE
```

### Should I Add a New Additions File?

```
START: Binding generation issue or missing functionality
│
├─ Is this a bug in the binding generator?
│  ├─ YES → File issue, then add workaround → TEMPORARY ADDITION
│  └─ NO
│      │
│      ├─ Is this for convenience (wrapper methods)?
│      │  ├─ YES → Is it widely useful?
│      │  │  ├─ YES → ADD with clear documentation
│      │  │  └─ NO → DON'T ADD (users can write their own)
│      │  │
│      │  └─ NO → Is binding incorrect/broken?
│      │      ├─ YES → ADD with TODO to remove when fixed
│      │      └─ NO → DON'T ADD
```

### Should I Remove a Type in Metadata.xml?

```
START: Native SDK removes a type/API
│
├─ Is it internal/private API?
│  ├─ YES → ADD remove-node (was never meant to be public)
│  └─ NO → Is it deprecated with migration path?
│      ├─ YES → ADD remove-node + document migration in README
│      └─ NO → Keep it (might be temporary removal)
│
└─ Result: ADD to Metadata.xml with comment
    Example:
    <!-- Removed in SDK 3.0 - Use replacement API instead -->
    <remove-node path="/api/package[@name='...']" />
```

---

## Examples

### Example 1: Minor Update (3.4.0 → 3.5.0)

**Scenario:** Patch release with bug fixes

**Changes Expected:**
- None to minimal in bindings
- Maybe some new optional APIs

**Actions:**
```bash
# Update
./scripts/update-sdk-versions.sh --android-version 3.5.0

# Build
make ci-android

# Expected result: Success with no changes needed

# Commit
git add dd-sdk-android
git commit -m "chore: Update Android SDK to 3.5.0"
```

**Additions Files:** No changes needed (stable APIs)

**Metadata.xml:** No changes needed

---

### Example 2: Minor Update with New Feature (3.4.0 → 3.5.0)

**Scenario:** New optional RUM feature added

**Changes Expected:**
- New classes in RUM module
- Existing APIs unchanged

**Actions:**
```bash
# Update
./scripts/update-sdk-versions.sh --android-version 3.5.0

# Build
make ci-android

# Result: New bindings auto-generated, warnings about new types

# Check if internal types leaked
cd dd-sdk-android
grep -r "internal" features/dd-sdk-android-rum/src/main/kotlin/.../NewFeature.kt

# If internal, add to Metadata.xml
```

**Metadata.xml Changes:**
```xml
<!-- Added in SDK 3.5.0 - Internal implementation detail -->
<remove-node path="/api/package[@name='com.datadog.rum.internal.feature']" />
```

**Additions Files:** No changes (new feature, old code still works)

---

### Example 3: Major Update with Breaking Changes (3.x → 4.x)

**Scenario:** Datadog releases SDK 4.0 with new architecture

**Changes Expected:**
- Core APIs restructured
- Old extension methods removed
- New configuration system

**Actions:**

```bash
# 1. Create maintenance branch
git checkout -b release/v3.x
git tag v3.4.0-final
git push origin release/v3.x --tags

# 2. Start 4.0 work on main
git checkout main
./scripts/update-sdk-versions.sh --android-version 4.0.0

# 3. Review migration guide
cd dd-sdk-android
cat MIGRATION.md | grep -A 100 "4.0"

# Key findings:
# - Configuration API changed
# - Core module split into multiple modules
# - Trace renamed to APM

# 4. Build and capture errors
make ci-android 2>&1 | tee /tmp/4.0-migration.log

# 5. Systematically address each issue:

# Issue 1: Configuration class renamed
# Solution: Update Metadata.xml
<attr path="/api/package[@name='com.datadog.config']/class[@name='DatadogConfiguration']"
      name="managedName">DDConfiguration</attr>

# Issue 2: Trace module renamed to APM
# Solution: Rename binding project
mv src/Android/Bindings/Trace src/Android/Bindings/Apm
# Update .csproj, namespaces, etc.

# Issue 3: Old Additions files reference removed APIs
# Solution: Remove obsolete files
rm -rf src/Android/Bindings/*/Additions/Datadog.Legacy.*/

# 6. Document breaking changes
```

**Create migration guide:**
```markdown
# Migration Guide: v3.x → v4.x

## Breaking Changes

### 1. Configuration API
**Before (3.x):**
```csharp
var config = new Configuration(...);
Datadog.Initialize(config);
```

**After (4.x):**
```csharp
var config = new DatadogConfiguration(...);
Datadog.Initialize(config);
```

### 2. Trace → APM
**Before (3.x):**
```csharp
using Datadog.Android.Trace;
```

**After (4.x):**
```csharp
using Datadog.Android.Apm;
```
```

---

### Example 4: Deprecating a Package

**Scenario:** iOS ObjC package deprecated in SDK 3.0

**Actions:**

1. **Mark package as deprecated in .csproj:**
```xml
<PropertyGroup>
  <IsPackable>false</IsPackable>
  <GeneratePackageOnBuild>false</GeneratePackageOnBuild>
  <PackageDeprecated>true</PackageDeprecated>
  <Description>[DEPRECATED] Use individual packages instead.</Description>
</PropertyGroup>
```

2. **Update README.md:**
```markdown
> **⚠️ DEPRECATED:** This package is deprecated as of SDK 3.0
>
> **Migration:** Use these packages instead:
> - Bcr.Datadog.iOS.Core
> - Bcr.Datadog.iOS.Logs
```

3. **Keep the project in the repository:**
- Don't delete (users on old versions still reference it)
- Don't publish new versions
- Provide clear migration path

4. **In next MAJOR version (4.0):**
- Can remove the project entirely
- No one should be jumping from 2.x → 4.x directly

---

## Incremental Update Checklist

Use this checklist for each SDK update:

### Pre-Update
- [ ] Check native SDK CHANGELOG.md for breaking changes
- [ ] Check native SDK MIGRATION.md for version-specific guides
- [ ] Decide if new branch needed (major version change)
- [ ] Create maintenance branch if major update

### During Update
- [ ] Update submodule versions
- [ ] Run local build: `make ci-android` and `make ci-ios`
- [ ] Document all errors in a file
- [ ] Group errors by type (see [TROUBLESHOOTING_BINDING_ERRORS.md](TROUBLESHOOTING_BINDING_ERRORS.md))

### Fixing Errors
- [ ] Remove Additions files for deleted APIs
- [ ] Update Metadata.xml for renamed/removed types
- [ ] Test each fix individually
- [ ] Document reason for each change in commit

### Validation
- [ ] Full build succeeds: `make ci-android && make ci-ios`
- [ ] Test apps build: `make ci-test`
- [ ] Smoke test packages locally
- [ ] Review warnings (ensure none are errors in disguise)

### Documentation
- [ ] Update README.md if public APIs changed
- [ ] Create migration guide if major version
- [ ] Update CHANGELOG.md
- [ ] Tag release with version

### Post-Update
- [ ] Monitor GitHub Issues for user-reported problems
- [ ] Be ready to hotfix if critical issues found
- [ ] Archive old branch if 6+ months passed

---

## Best Practices

### 1. **Document Why, Not Just What**

**Bad:**
```xml
<remove-node path="/api/package[@name='com.datadog.internal']" />
```

**Good:**
```xml
<!-- Removed in SDK 3.0 - Internal API not meant for public use
     See: https://github.com/DataDog/dd-sdk-android/pull/1234 -->
<remove-node path="/api/package[@name='com.datadog.internal']" />
```

### 2. **Keep Git History Clean**

```bash
# Good commit message
git commit -m "feat: Update to Android SDK 3.4.0

- Remove obsolete Trace Additions (SpanExtensions.cs)
- Add RequestFactory to Metadata.xml exclusions
- Update test app to use ProjectReferences

BREAKING CHANGES:
- Removed convenience methods in Trace (use native API directly)

Fixes #123"

# Bad commit message
git commit -m "Update SDK"
```

### 3. **Test Incrementally**

```bash
# Don't fix everything at once
# Fix one error, test, commit

# Fix Trace binding
rm src/Android/Bindings/Trace/Additions/SpanExtensions.cs
dotnet build src/Android/Bindings/Trace -c Release
git commit -m "fix: Remove obsolete SpanExtensions (API removed in SDK 3.0)"

# Fix Core binding
# ... next fix ...
```

### 4. **Maintain Backwards Compatibility When Possible**

If a native API was renamed but old one exists (deprecated):
```xml
<!-- Keep both for one major version cycle -->
<!-- Old name (deprecated) -->
<attr path=".../method[@name='oldMethod']" name="managedName">OldMethod</attr>
<!-- New name -->
<attr path=".../method[@name='newMethod']" name="managedName">NewMethod</attr>

<!-- In next major version, remove the old mapping -->
```

---

## Quick Reference

### File Retention Rules

| File Type | Keep? | Reason |
|-----------|-------|--------|
| Metadata.xml rules | ✅ Always | Historical context, prevents re-introduction |
| Additions for removed API | ❌ Delete | No longer needed, causes build errors |
| Additions for workarounds | ⚠️ Review | Delete if generator improved, keep if still needed |
| Deprecated package | ✅ Keep | Users on old versions need it |
| Test applications | ✅ Always | Validation essential |
| Documentation | ✅ Always | Even for deprecated packages |

### Update Frequency

| SDK Change Type | Update Binding? | Priority |
|----------------|-----------------|----------|
| Patch (x.x.1) | Optional | Low - bug fixes unlikely to affect bindings |
| Minor (x.1.x) | Recommended | Medium - new features, usually safe |
| Major (1.x.x) | Required | High - breaking changes guaranteed |
| Security | Immediate | Critical - even if patch version |

### Support Policy

| Version | Support Level | Duration |
|---------|--------------|----------|
| Latest major (3.x) | Full support | Ongoing |
| Previous major (2.x) | Security fixes only | 6 months after 3.0 release |
| Older (1.x) | Unsupported | Archived |

---

## Getting Help

If uncertain about whether to keep/remove something:

1. **Check native SDK**: Does the API still exist?
2. **Try building without it**: Does the build succeed?
3. **Review commit history**: Why was it added originally?
4. **Ask in team discussion**: Get consensus on breaking changes

When in doubt: **Keep it for one more version cycle with a deprecation warning**.
