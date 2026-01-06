#!/usr/bin/env bash
#
# Build iOS NuGet packages locally with all target frameworks (net8.0-ios, net9.0-ios, net10.0-ios)
#
# Usage:
#   ./build-local-ios-packages.sh [output-directory]
#
# Requirements:
#   - macOS with Xcode installed
#   - .NET SDK 8.0.x and 9.0.x (or 10.0.x) installed
#   - Carthage installed (brew install carthage)
#

set -e  # Exit on error

# Parse arguments
OUTPUT_DIR="${1:-./local-packages}"

echo "===================================="
echo "Building iOS NuGet Packages Locally"
echo "===================================="
echo ""
echo "Output directory: $OUTPUT_DIR"
echo ""

# Check prerequisites
echo "Checking prerequisites..."
if ! command -v carthage &> /dev/null; then
    echo "❌ Carthage not found. Install with: brew install carthage"
    exit 1
fi

if ! command -v dotnet &> /dev/null; then
    echo "❌ .NET SDK not found. Please install .NET SDK 8.0+ and 9.0+"
    exit 1
fi

# Check for multiple SDK versions
DOTNET_SDKS=$(dotnet --list-sdks)
echo "Found .NET SDKs:"
echo "$DOTNET_SDKS"
echo ""

if ! echo "$DOTNET_SDKS" | grep -q "^8\."; then
    echo "❌ .NET SDK 8.0.x not found. Please install it from https://dotnet.microsoft.com/download"
    exit 1
fi

if ! echo "$DOTNET_SDKS" | grep -qE "^(9\.|10\.)"; then
    echo "❌ .NET SDK 9.0.x or 10.0.x not found. Please install it from https://dotnet.microsoft.com/download"
    exit 1
fi

echo "✅ All prerequisites met"
echo ""

# Initialize submodules
echo "Step 1/8: Initializing submodules..."
git submodule update --init --recursive

# Build XCFrameworks
echo ""
echo "Step 2/8: Building XCFrameworks..."
echo "This may take 15-20 minutes..."
./src/iOS/buildxcframework.sh

# Get SDK 8 version
DOTNET_8_VERSION=$(dotnet --list-sdks | grep "^8\." | tail -1 | awk '{print $1}')
echo ""
echo "Step 3/8: Using .NET SDK 8: $DOTNET_8_VERSION"

# Create temporary global.json for SDK 8
cat > global.json <<EOF
{
  "sdk": {
    "version": "$DOTNET_8_VERSION",
    "rollForward": "latestPatch"
  }
}
EOF

# Build with SDK 8
echo ""
echo "Step 4/8: Installing iOS workload for .NET SDK 8..."
dotnet workload install ios

echo ""
echo "Step 5/8: Building with .NET SDK 8 (net8.0-ios)..."
dotnet restore src/iOS/iOSBindings.sln
dotnet build src/iOS/iOSBindings.sln --configuration Release --no-restore
dotnet pack src/iOS/iOSBindings.sln --configuration Release --no-build --output ./temp-packages-net8

# Remove global.json and build with SDK 9+
rm -f global.json

echo ""
echo "Step 6/8: Building with .NET SDK 9+ (net9.0-ios, net10.0-ios)..."
dotnet workload install ios
dotnet restore src/iOS/iOSBindings.sln
dotnet build src/iOS/iOSBindings.sln --configuration Release --no-restore
dotnet pack src/iOS/iOSBindings.sln --configuration Release --no-build --output ./temp-packages-net9plus

# Combine packages
echo ""
echo "Step 7/8: Combining packages with all target frameworks..."
mkdir -p "$OUTPUT_DIR"
mkdir -p ./temp-extract

for net8_pkg in ./temp-packages-net8/*.nupkg; do
    pkg_name=$(basename "$net8_pkg" | sed 's/\.[0-9]\+\.[0-9]\+\.[0-9]\+\.nupkg$//')
    version=$(basename "$net8_pkg" | sed -n 's/.*\.\([0-9]\+\.[0-9]\+\.[0-9]\+\)\.nupkg$/\1/p')
    net9plus_pkg="./temp-packages-net9plus/${pkg_name}.${version}.nupkg"

    echo "  Processing $pkg_name version $version"

    if [ -f "$net9plus_pkg" ]; then
        # Extract both packages
        unzip -q "$net8_pkg" -d "./temp-extract/net8"
        unzip -q "$net9plus_pkg" -d "./temp-extract/net9plus"

        # Copy net9.0-ios and net10.0-ios libs to net8 package structure
        if [ -d "./temp-extract/net9plus/lib/net9.0-ios" ]; then
            cp -r "./temp-extract/net9plus/lib/net9.0-ios" "./temp-extract/net8/lib/"
        fi
        if [ -d "./temp-extract/net9plus/lib/net10.0-ios" ]; then
            cp -r "./temp-extract/net9plus/lib/net10.0-ios" "./temp-extract/net8/lib/"
        fi

        # Repackage the combined content
        (cd "./temp-extract/net8" && zip -q -r "../../${OUTPUT_DIR}/${pkg_name}.${version}.nupkg" *)

        # Clean up temp directory
        rm -rf "./temp-extract/net8" "./temp-extract/net9plus"

        echo "    ✅ Created combined package: ${pkg_name}.${version}.nupkg"
    else
        echo "    ⚠️  No matching net9+ package found, using net8 only"
        cp "$net8_pkg" "$OUTPUT_DIR/"
    fi
done

# Clean up
echo ""
echo "Step 8/8: Cleaning up temporary files..."
rm -rf ./temp-packages-net8 ./temp-packages-net9plus ./temp-extract
rm -f global.json

# Summary
echo ""
echo "===================================="
echo "✅ Build Complete!"
echo "===================================="
echo ""
echo "Packages created in: $OUTPUT_DIR"
echo ""
ls -lh "$OUTPUT_DIR"
echo ""
echo "Package count: $(ls -1 "$OUTPUT_DIR"/*.nupkg 2>/dev/null | wc -l | tr -d ' ')"
echo ""
echo "To use these packages locally:"
echo "  1. Add local source: dotnet nuget add source $(pwd)/$OUTPUT_DIR --name local-datadog-ios"
echo "  2. Install packages: dotnet add package Bcr.Datadog.iOS.Core"
echo ""
