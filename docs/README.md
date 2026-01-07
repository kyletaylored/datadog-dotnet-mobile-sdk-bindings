# Documentation Index

This directory contains all documentation for the Datadog .NET Mobile SDK Bindings project.

## For Users

- **[Getting Started Guide](GETTING_STARTED.md)** - Complete setup guide, examples, and API usage for consuming the NuGet packages

## For Contributors

### Quick References
- **[Quick Start](QUICK_START.md)** - Quick reference card for common development tasks
- **[SDK Update Guide](SDK_UPDATE_GUIDE.md)** - How to update to new Datadog SDK versions

### Building & Deployment
- **[Building & Versioning Guide](BUILDING_AND_VERSIONING.md)** - Build from source, versioning strategy, and package structure
- **[Local Package Building](LOCAL_BUILD_README.md)** - Generate NuGet packages locally for development and testing
- **[Release Process Guide](RELEASE_PROCESS.md)** - Publishing new versions to NuGet.org

### Platform-Specific
- **[Android NDK Setup](ANDROID_NDK_SETUP.md)** - Android NDK installation and configuration for building AAR files
- **[Setup NuGet Guide](SETUP_NUGET_README.md)** - NuGet package source configuration

## Quick Links

### External Documentation
- [Main Repository README](../README.md)
- [Datadog Android SDK](https://github.com/DataDog/dd-sdk-android)
- [Datadog iOS SDK](https://github.com/DataDog/dd-sdk-ios)
- [Official Datadog Documentation](https://docs.datadoghq.com/)

### Platform-Specific Implementation
- [iOS Implementation Details](../src/iOS/)
- [Android Implementation Details](../src/Android/)

## Document Organization

| Document | Purpose | Audience |
|----------|---------|----------|
| GETTING_STARTED.md | How to use the packages | Package consumers |
| QUICK_START.md | Common development tasks | Contributors |
| SDK_UPDATE_GUIDE.md | Update SDK versions | Contributors/Maintainers |
| BUILDING_AND_VERSIONING.md | Build system details | Contributors/Maintainers |
| LOCAL_BUILD_README.md | Local development builds | Contributors |
| RELEASE_PROCESS.md | Publishing workflow | Maintainers |
| ANDROID_NDK_SETUP.md | Android NDK configuration | Contributors |
| SETUP_NUGET_README.md | NuGet setup | Contributors |

## Getting Help

```bash
# Show all available make commands
make help

# Check current SDK versions
make status

# List available SDK versions
make list-versions
```

## Contributing

See the main [README](../README.md) for contribution guidelines and links to all documentation.
