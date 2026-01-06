# Release Checklist

Quick checklist for releasing version **______**

## Pre-Release

- [ ] **Monitor** dd-sdk-ios and dd-sdk-android for new release
- [ ] **Update submodules** to new version tag
  ```bash
  cd dd-sdk-ios && git checkout X.Y.Z && cd ..
  cd dd-sdk-android && git checkout X.Y.Z && cd ..
  ```
- [ ] **Update PackageVersion** in all `.csproj` files to match
  - [ ] iOS: 10 projects in `src/iOS/Bindings/*/`
  - [ ] Android: 9 projects in `src/Android/Bindings/*/`
- [ ] **Rebuild bindings** if API changed (see BUILDING_AND_VERSIONING.md)
- [ ] **Build locally** and test
  ```bash
  ./build-local-ios-packages.sh ./test-packages
  ./build-local-android-packages.sh ./test-packages
  ```
- [ ] **Test in sample app** - verify initialization and basic functionality
- [ ] **Commit changes**
  ```bash
  git commit -m "Release version X.Y.Z"
  git push origin main
  ```

## Dry Run

- [ ] **Run prepare-release workflow** (GitHub Actions)
  - Version: `X.Y.Z`
  - Platform: `both`
  - Do NOT check "Publish to NuGet"
- [ ] **Download artifacts** and inspect packages
- [ ] **Verify versions** in package names
- [ ] **Check package contents** (unzip and inspect)

## Publication

- [ ] **Run publish-release workflow** (GitHub Actions)
  - Version: `X.Y.Z`
  - Platform: `both`
  - ✅ **Check "Publish to NuGet.org"**
  - Pre-release: Check only if `-pre.N` version
- [ ] **Monitor workflow** for successful completion
- [ ] **Verify on NuGet.org**
  - Check all packages are live
  - Verify version numbers
  - Check metadata and descriptions
- [ ] **Verify GitHub Release**
  - Release created with correct tag
  - Release notes are accurate
  - Package attachments are present
- [ ] **Test installation** from NuGet.org
  ```bash
  dotnet new console -n Test
  cd Test
  dotnet add package Bcr.Datadog.iOS.ObjC --version X.Y.Z
  dotnet add package Bcr.Datadog.Android.Core --version X.Y.Z
  dotnet restore
  ```

## Post-Release

- [ ] **Update CHANGELOG.md** with release notes
- [ ] **Update documentation** if API changed
  - [ ] GETTING_STARTED.md
  - [ ] README.md example code
  - [ ] Platform-specific docs
- [ ] **Announce release**
  - [ ] GitHub Discussions (if enabled)
  - [ ] Social media / channels
  - [ ] Email users (if applicable)
- [ ] **Close related issues** that this release addresses
- [ ] **Update project board** (if applicable)

## Rollback (If Needed)

If something goes wrong after publication:

- [ ] **Unlist packages** on NuGet.org (don't delete)
- [ ] **Mark GitHub Release** as draft or delete
- [ ] **Investigate issue** and document
- [ ] **Fix problem** in code
- [ ] **Increment version** (e.g., X.Y.Z → X.Y.Z.1)
- [ ] **Re-run release process** with new version

---

## Quick Links

- [Full Release Process Guide](../RELEASE_PROCESS.md)
- [Building & Versioning Guide](../BUILDING_AND_VERSIONING.md)
- [Local Build Instructions](../LOCAL_BUILD_README.md)
- [NuGet.org Packages](https://www.nuget.org/packages?q=bcr.datadog)
- [GitHub Releases](../../releases)

---

## Notes

Release Date: __________

Issues Addressed: __________

Breaking Changes: __________

Additional Notes:
