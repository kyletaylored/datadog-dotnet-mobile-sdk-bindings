# SDK Versioning and Branching Strategy

This document outlines our strategy for versioning, branching, and maintaining the .NET bindings as the upstream Datadog SDKs evolve.

## Philosophy: Keep It Simple

We follow a **single main branch** approach with git tags for releases. Maintenance branches are created **only when actually needed**, not preemptively.

> "Start simple, add complexity only when required."

---

## Table of Contents
- [Version Numbering](#version-numbering)
- [Branching Strategy](#branching-strategy)
- [Update Workflows](#update-workflows)
- [When to Create Maintenance Branches](#when-to-create-maintenance-branches)
- [Support Policy](#support-policy)

---

## Version Numbering

### Format: `MAJOR.MINOR.PATCH.BUILD`

We use 4-part semantic versioning:

```
Datadog SDK Version → Binding Version
────────────────────────────────────
3.4.0              → 3.4.0.0  (initial binding)
3.4.0              → 3.4.0.1  (binding bugfix)
3.5.0              → 3.5.0.0  (new SDK version)
```

**Components:**
- `MAJOR.MINOR.PATCH` = Upstream Datadog SDK version
- `BUILD` = Our binding revision (for binding-specific fixes)

**Why 4 parts?**
- ✅ Clear which upstream SDK version we track
- ✅ Allows fixing binding bugs without upstream changes
- ✅ Easy to understand: first 3 numbers = SDK version

### Examples

| Scenario | Version | Notes |
|----------|---------|-------|
| Initial binding for SDK 3.5.0 | `3.5.0.0` | First release tracking SDK 3.5.0 |
| Fix binding null reference bug | `3.5.0.1` | SDK still 3.5.0, binding fixed |
| SDK updates to 3.6.0 | `3.6.0.0` | New SDK, reset BUILD to 0 |
| Pre-release testing | `3.6.0-pre.1` | Pre-release suffix for beta testing |

---

## Branching Strategy

### Default: Single Main Branch

```
main (always tracks latest stable SDK)
├── v3.4.0.0 (git tag)
├── v3.4.0.1 (git tag)
├── v3.5.0.0 (git tag)
└── v3.6.0.0 (git tag) ← current
```

**All development happens on `main`:**
- Simple: one active branch
- Git tags mark releases
- Submodules pin to exact SDK versions

### Workflow for Normal Updates

```bash
# 1. Update SDK version on main
./update-sdk-versions.sh --android-version 3.5.0 --ios-version 3.5.0

# 2. Fix any issues, test, commit
git add -A
git commit -m "Update to Datadog SDK 3.5.0"

# 3. Tag the release
git tag v3.5.0.0
git push origin main --tags

# 4. CI publishes NuGet packages
```

Simple! No branching needed for 95% of updates.

---

## When to Create Maintenance Branches

**Create a maintenance branch ONLY when:**

1. ✅ **Datadog releases breaking changes** (e.g., 3.x → 4.x)
2. ✅ **Multiple customers need old version support**
3. ✅ **Critical security fix needed for old version**

**Don't create branches preemptively.** Wait until there's a concrete need.

### Example: Major SDK Update (3.x → 4.x)

```bash
# Datadog releases 4.0.0 with breaking changes
# Some customers can't upgrade immediately

# 1. Create maintenance branch from last 3.x release
git checkout v3.7.0.0
git checkout -b maint/3.x
git push origin maint/3.x

# 2. Continue 4.x development on main
git checkout main
./update-sdk-versions.sh --android-version 4.0.0 --ios-version 4.0.0
# ... handle breaking changes ...
git commit -m "feat: Upgrade to SDK 4.0.0

BREAKING CHANGES:
- Configuration API changed
- Removed deprecated methods

See docs/MIGRATION_4.0.md for upgrade guide"
git tag v4.0.0.0
git push origin main --tags

# 3. Result: Two active branches
# main → 4.x development (latest)
# maint/3.x → 3.x security fixes only
```

### Example: Backporting a Critical Fix

```bash
# Customer on 3.x needs critical bugfix
# You're now on 4.x

# 1. Fix on main first
git checkout main
# ... fix the bug ...
git commit -m "fix: Critical binding null reference issue"
git tag v4.1.0.1

# 2. Backport to 3.x
git checkout maint/3.x
git cherry-pick <commit-sha>
git tag v3.7.0.1
git push origin maint/3.x --tags
```

---

## Update Workflows

### Minor/Patch Update (3.4.0 → 3.5.0)

**Expected:** Few or no breaking changes

```bash
# Use the update script
make update-sdks
# or
./update-sdk-versions.sh --android-version 3.5.0 --ios-version 3.5.0

# Build and test
make ci-android
make ci-ios

# Commit and tag
git add -A
git commit -m "chore: Update to SDK 3.5.0"
git tag v3.5.0.0
git push origin main --tags
```

**If issues occur:**
- Check [TROUBLESHOOTING_BINDING_ERRORS.md](TROUBLESHOOTING_BINDING_ERRORS.md)
- Usually just need to update Metadata.xml
- Rarely need to change Additions files

### Major Update (3.x → 4.x)

**Expected:** Significant breaking changes

```bash
# 1. Review native SDK migration guides
cd dd-sdk-android
cat MIGRATION.md | grep -A 50 "4.0"
cd ../dd-sdk-ios
cat MIGRATION.md | grep -A 50 "4.0"
cd ..

# 2. Create maintenance branch for 3.x
git checkout -b maint/3.x
git tag v3.7.0.0-final
git push origin maint/3.x --tags

# 3. Update main to 4.x
git checkout main
./update-sdk-versions.sh --android-version 4.0.0 --ios-version 4.0.0

# 4. Build and fix issues systematically
make ci-android 2>&1 | tee /tmp/build-errors.txt
make ci-ios 2>&1 | tee -a /tmp/build-errors.txt

# 5. Update bindings (see troubleshooting guide)
# - Update Metadata.xml
# - Remove obsolete Additions files
# - Update test apps

# 6. Create migration guide
# See docs/MIGRATION_4.0.md template below

# 7. Commit with detailed message
git add -A
git commit -m "feat: Upgrade to SDK 4.0.0

BREAKING CHANGES:
- List breaking changes here
- Include migration instructions

See docs/MIGRATION_4.0.md"
git tag v4.0.0.0
git push origin main --tags
```

---

## Decision Tree: Do I Need a Maintenance Branch?

```
┌─────────────────────────────────────┐
│ Someone needs a fix in old version  │
└─────────────┬───────────────────────┘
              │
         ┌────▼────┐
         │ Is it   │
         │ latest? │  YES  ┌──────────────────┐
         │         ├──────►│ Fix on main      │
         └────┬────┘       │ Tag new release  │
              │ NO         └──────────────────┘
              │
         ┌────▼────────────────────┐
         │ Does maint/X.x branch   │  YES  ┌──────────────────┐
         │ already exist?          ├──────►│ Cherry-pick fix  │
         └────┬────────────────────┘       │ Tag release      │
              │ NO                          └──────────────────┘
              │
         ┌────▼──────────────────────────┐
         │ Is it critical/security issue │
         │ affecting multiple customers? │  YES  ┌────────────────┐
         └────┬──────────────────────────┘      │ Create maint/  │
              │ NO                                │ branch now     │
              │                                   └────────────────┘
         ┌────▼───────────────────────────┐
         │ Tell customer to upgrade to    │
         │ latest version                 │
         └────────────────────────────────┘
```

---

## Support Policy

### Active Support

| Version | Support Level | Duration |
|---------|--------------|----------|
| Latest major (4.x) | Full support | Ongoing |
| Previous major (3.x) | Security fixes only | 6 months after 4.x release |
| Older (2.x, 1.x) | End of life | No support |

### What "Security fixes only" means

For previous major versions:
- ✅ Critical security vulnerabilities
- ✅ Binding bugs that break existing code
- ❌ New features
- ❌ Deprecation warnings
- ❌ Non-critical bugs

**Default answer:** "Please upgrade to latest version."

---

## File Lifecycle Management

### When Updating SDKs

#### Metadata.xml
- **Keep rules** even if no longer match
- **Add comments** explaining SDK version changes
- **Never delete** old rules (historical context)

```xml
<!-- Added in SDK 3.0 - Internal API not meant for public use -->
<remove-node path="/api/package[@name='com.datadog.internal']" />

<!-- Removed in SDK 4.0 - API redesigned, see Migration guide -->
<remove-node path="/api/package[@name='com.datadog.legacy']" />
```

#### Additions/ Files

Decision matrix:

```
Does native API still exist?
├─ NO  → DELETE the Additions file
│       (API removed from SDK)
│
└─ YES → Does binding work without it?
        ├─ YES → DELETE (generator improved)
        └─ NO  → UPDATE to match new API
```

**When in doubt:** Try building without the file. If it works, delete it!

#### Test Applications

- **Always keep** test apps
- **Update for major versions** to show new APIs
- **Use ProjectReferences** (not PackageReferences)

---

## Version Compatibility Matrix

Maintain this in README.md:

```markdown
## Version Compatibility

| Binding Version | Android SDK | iOS SDK | .NET Version | Status |
|----------------|-------------|---------|--------------|--------|
| 3.5.0.x        | 3.5.0       | 3.5.0   | .NET 9, 10   | ✅ Current |
| 3.4.0.x        | 3.4.0       | 3.4.0   | .NET 9, 10   | Security fixes |
| 3.3.0.x        | 3.3.0       | 3.3.0   | .NET 9       | End of life |
```

---

## Quick Reference

### Common Commands

```bash
# Update to latest SDK
make update-sdks

# Build locally
make ci-android
make ci-ios

# Create release tag
git tag v3.5.0.0
git push origin --tags

# Create maintenance branch (only when needed!)
git checkout v3.7.0.0
git checkout -b maint/3.x
git push origin maint/3.x

# Cherry-pick fix to old version
git checkout maint/3.x
git cherry-pick <commit-sha>
git tag v3.7.0.1
git push origin maint/3.x --tags
```

### Update Frequency Recommendation

| SDK Change | Update Binding? | Priority |
|------------|-----------------|----------|
| Patch (3.5.0 → 3.5.1) | Optional | Low |
| Minor (3.5.0 → 3.6.0) | Recommended | Medium |
| Major (3.x → 4.x) | Required | High |
| Security fix | Immediate | Critical |

---

## Migration Guide Template

When creating a major version update, create `docs/MIGRATION_X.0.md`:

```markdown
# Migration Guide: v3.x → v4.x

## Overview

Datadog SDK 4.0 includes significant architectural changes...

## Breaking Changes

### 1. Configuration API Changed

**Before (3.x):**
```csharp
var config = new Configuration.Builder(...)
    .Build();
```

**After (4.x):**
```csharp
var config = new DatadogConfiguration(...)
    .Build();
```

### 2. Removed Deprecated APIs

- `SpanExt.SetError()` → Use `Span.SetError()` directly
- `SqliteExt.TransactionTraced()` → Removed, no replacement

## Step-by-Step Migration

1. Update NuGet packages to 4.x
2. Fix compilation errors (see breaking changes above)
3. Test thoroughly
4. Update documentation

## Need Help?

- [GitHub Issues](link)
- [Datadog Support](link)
```

---

## Best Practices

1. **Keep main simple** - Don't create branches until you need them
2. **Tag often** - Every release gets a git tag
3. **Document breaking changes** - Users need migration guides
4. **Encourage upgrades** - Latest version is best supported
5. **Cherry-pick conservatively** - Only backport critical fixes
6. **Test before tagging** - Tags should be production-ready

---

## Getting Help

Unsure about a versioning decision?

1. Check if native SDK API exists: `grep -r "ApiName" dd-sdk-*/`
2. Try building without controversial files
3. Review git history: `git log --follow path/to/file`
4. Ask team for consensus on breaking changes

**When in doubt:** Keep it for one more version cycle with a deprecation notice.

---

## Related Documentation

- [SDK Update Guide](SDK_UPDATE_GUIDE.md) - How to update SDK versions
- [Release Process](RELEASE_PROCESS.md) - How to publish releases
- [Troubleshooting](TROUBLESHOOTING_BINDING_ERRORS.md) - Fix binding errors
- [Building Guide](BUILDING_AND_VERSIONING.md) - Build packages locally
