# Testing GitHub Actions Workflows Locally

This guide explains how to test your GitHub Actions workflows locally before pushing to GitHub.

## Quick Start

### Test Android Build Workflow

```bash
make ci-android
```

This simulates the complete GitHub Actions Android build workflow:
1. Updates git submodules
2. Sets up .NET environment
3. Builds Android AAR files from source
4. Restores and builds .NET bindings
5. Creates NuGet packages

Output packages will be in `./local-packages/`

### Test iOS Build Workflow (macOS only)

```bash
make ci-ios
```

This simulates the complete GitHub Actions iOS build workflow:
1. Updates git submodules
2. Sets up .NET and iOS workload
3. Builds XCFrameworks using Carthage and xcodebuild
4. Restores and builds .NET bindings
5. Creates NuGet packages

Output packages will be in `./local-packages/`

### Test Both Workflows

```bash
make ci-all
```

Runs both Android and iOS workflows sequentially (macOS only).

### Test with Validation

```bash
make ci-test
```

Runs the Android CI workflow and then validates the packages by building the test application. This ensures the packages are valid and can be consumed.

## Available Commands

| Command | Description |
|---------|-------------|
| `make ci-android` | Simulate Android build workflow |
| `make ci-ios` | Simulate iOS build workflow (macOS) |
| `make ci-all` | Simulate both workflows |
| `make ci-test` | Build and validate with test app |
| `make help` | Show all available commands |

## What Gets Tested

The CI simulation commands mirror your GitHub Actions workflows:

### Android Workflow (`.github/workflows/build-android.yml`)
- ✅ Submodule checkout
- ✅ .NET SDK setup
- ✅ AAR file building (`build-aars.sh`)
- ✅ AAR file copying (`copy-aars.sh`)
- ✅ Solution restore
- ✅ Solution build (Release)
- ✅ NuGet package creation

### iOS Workflow (`.github/workflows/build-ios.yml`)
- ✅ Submodule checkout
- ✅ .NET SDK setup
- ✅ iOS workload installation
- ✅ XCFramework building (`buildxcframework.sh`)
- ✅ Solution restore
- ✅ Solution build (Release)
- ✅ NuGet package creation

## Differences from GitHub Actions

### What's the Same
- Build scripts and commands
- Package output
- Dependency resolution
- Compilation and binding generation

### What's Different
- **Environment**: Runs on your local machine, not GitHub's runners
- **Caching**: No GitHub Actions caching (runs clean each time)
- **Secrets**: Uses your local credentials, not GitHub secrets
- **Matrix Builds**: Single build, not parallelized like GitHub Actions
- **macOS Version**: Uses your installed macOS/Xcode, not GitHub's runner version

## Troubleshooting

### Android Build Fails

**Issue**: Gradle or Java errors

**Solution**:
```bash
# Check Java version (needs JDK 17)
java -version

# Set JAVA_HOME if needed
export JAVA_HOME=$(/usr/libexec/java_home -v 17)

# Clean and retry
make clean-all
make ci-android
```

### iOS Build Fails

**Issue**: Carthage or Xcode errors

**Solution**:
```bash
# Check Xcode version
xcodebuild -version

# Ensure Carthage is installed
brew install carthage

# Clean and retry
make clean-all
make ci-ios
```

### AAR Files Missing

**Issue**: Build fails with "AAR files not found"

**Solution**:
```bash
# Rebuild AAR files explicitly
make build-android-aars

# Then run CI
make ci-android
```

### XCFrameworks Missing

**Issue**: Build fails with "XCFrameworks not found"

**Solution**:
```bash
# Rebuild XCFrameworks explicitly
make build-ios-frameworks

# Then run CI
make ci-ios
```

## Speed Optimization

If you're iterating on binding code (Metadata.xml, Additions, etc.) and don't need to rebuild native libraries:

### Skip AAR Rebuild (Android)
```bash
# First time: full build
make ci-android

# After changes to bindings only:
dotnet restore src/Android/AndroidDatadogBindings.sln
dotnet build src/Android/AndroidDatadogBindings.sln --configuration Release --no-restore
dotnet pack src/Android/AndroidDatadogBindings.sln --configuration Release --no-build --output ./local-packages
```

### Skip XCFramework Rebuild (iOS)
```bash
# First time: full build
make ci-ios

# After changes to bindings only:
dotnet restore src/iOS/iOSDatadogBindings.sln
dotnet build src/iOS/iOSDatadogBindings.sln --configuration Release --no-restore
dotnet pack src/iOS/iOSDatadogBindings.sln --configuration Release --no-build --output ./local-packages
```

Or use the quick build commands:
```bash
make build-android-quick  # Skips AAR rebuild
make build-ios-quick      # Skips XCFramework rebuild
```

## CI Pipeline Testing Workflow

Recommended workflow for testing before pushing:

```bash
# 1. Make your changes to bindings/metadata
# ... edit files ...

# 2. Clean previous builds
make clean

# 3. Run CI simulation
make ci-test

# 4. Verify packages
ls -lh ./local-packages/*.nupkg

# 5. If successful, commit and push
git add .
git commit -m "Fix: Updated bindings for SDK 3.4.0"
git push
```

## Comparing with GitHub Actions

To ensure your local build matches GitHub Actions:

1. **Run local CI**:
   ```bash
   make ci-android
   ```

2. **Check package versions**:
   ```bash
   ls -lh ./local-packages/
   ```

3. **Push to GitHub** and compare the workflow output

4. **Compare package sizes**: Local and GitHub packages should be similar in size

## Additional Notes

- The `ci-*` commands always clean and rebuild from scratch (like GitHub Actions)
- Local packages go to `./local-packages/` (cleared on each run)
- GitHub Actions artifacts go to `artifacts-*` directories
- Both should produce identical `.nupkg` files (except timestamps)

## Related Documentation

- [Makefile](Makefile) - All available commands
- [LOCAL_BUILD_README.md](LOCAL_BUILD_README.md) - General local build guide
- [.github/workflows/](. github/workflows/) - Actual GitHub Actions workflows
