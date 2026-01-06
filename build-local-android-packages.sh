#!/usr/bin/env bash
#
# Build Android NuGet packages locally with all target frameworks (net9.0-android, net10.0-android)
#
# Usage:
#   ./build-local-android-packages.sh [output-directory]
#
# Requirements:
#   - .NET SDK 9.0.x and 10.0.x installed
#   - Java 17+ installed
#   - Android SDK installed
#

set -e  # Exit on error

# Parse arguments
OUTPUT_DIR="${1:-./local-packages}"

echo "========================================"
echo "Building Android NuGet Packages Locally"
echo "========================================"
echo ""
echo "Output directory: $OUTPUT_DIR"
echo ""

# Check prerequisites
echo "Checking prerequisites..."
if ! command -v dotnet &> /dev/null; then
    echo "❌ .NET SDK not found. Please install .NET SDK 9.0 and 10.0"
    exit 1
fi

if ! command -v java &> /dev/null; then
    echo "❌ Java not found. Please install Java 17+"
    exit 1
fi

# Check Java version
JAVA_VERSION=$(java -version 2>&1 | head -n 1 | cut -d'"' -f2 | cut -d'.' -f1)
if [ "$JAVA_VERSION" -lt 17 ]; then
    echo "❌ Java 17+ required. Found version: $JAVA_VERSION"
    exit 1
fi

# Check for multiple SDK versions
DOTNET_SDKS=$(dotnet --list-sdks)
echo "Found .NET SDKs:"
echo "$DOTNET_SDKS"
echo ""

if ! echo "$DOTNET_SDKS" | grep -q "^9\."; then
    echo "❌ .NET SDK 9.0.x not found. Please install it from https://dotnet.microsoft.com/download"
    exit 1
fi

if ! echo "$DOTNET_SDKS" | grep -q "^10\."; then
    echo "❌ .NET SDK 10.0.x not found. Please install it from https://dotnet.microsoft.com/download"
    exit 1
fi

echo "✅ All prerequisites met"
echo ""

# Initialize submodules
echo "Step 1/7: Initializing submodules..."
git submodule update --init --recursive

# Get SDK 9 version and build with it
DOTNET_9_VERSION=$(dotnet --list-sdks | grep "^9\." | tail -1 | awk '{print $1}')
echo ""
echo "Step 2/7: Using .NET SDK 9: $DOTNET_9_VERSION"

# Create temporary global.json for SDK 9
cat > global.json <<EOF
{
  "sdk": {
    "version": "$DOTNET_9_VERSION",
    "rollForward": "latestPatch"
  }
}
EOF

echo ""
echo "Step 3/7: Installing Android workload for .NET SDK 9..."
dotnet workload install android

echo ""
echo "Step 4/7: Building with .NET SDK 9 (net9.0-android)..."
dotnet restore src/Android/AndroidDatadogBindings.sln
dotnet build src/Android/AndroidDatadogBindings.sln --configuration Release --no-restore --verbosity minimal
dotnet pack src/Android/AndroidDatadogBindings.sln --configuration Release --no-build --output ./temp-packages-net9 2>&1 | grep -v "prerelease dependency" || true

# Remove global.json and build with SDK 10
rm -f global.json

echo ""
echo "Step 5/7: Building with .NET SDK 10 (net10.0-android)..."
dotnet workload install android
dotnet restore src/Android/AndroidDatadogBindings.sln
dotnet build src/Android/AndroidDatadogBindings.sln --configuration Release --no-restore --verbosity minimal
dotnet pack src/Android/AndroidDatadogBindings.sln --configuration Release --no-build --output ./temp-packages-net10 2>&1 | grep -v "prerelease dependency" || true

# Combine packages
echo ""
echo "Step 6/7: Combining packages with all target frameworks..."
mkdir -p "$OUTPUT_DIR"
mkdir -p ./temp-extract

for net9_pkg in ./temp-packages-net9/*.nupkg; do
    pkg_name=$(basename "$net9_pkg" | sed 's/\.[0-9]\+\.[0-9]\+\.[0-9]\+.*\.nupkg$//')
    version=$(basename "$net9_pkg" | sed -n 's/.*\.\([0-9]\+\.[0-9]\+\.[0-9]\+[^.]*\)\.nupkg$/\1/p')
    net10_pkg="./temp-packages-net10/${pkg_name}.${version}.nupkg"

    echo "  Processing $pkg_name version $version"

    if [ -f "$net10_pkg" ]; then
        # Extract both packages
        unzip -q "$net9_pkg" -d "./temp-extract/net9"
        unzip -q "$net10_pkg" -d "./temp-extract/net10"

        # Copy net10.0-android lib to net9 package structure
        if [ -d "./temp-extract/net10/lib/net10.0-android" ]; then
            cp -r "./temp-extract/net10/lib/net10.0-android" "./temp-extract/net9/lib/"
        fi

        # Repackage the combined content
        (cd "./temp-extract/net9" && zip -q -r "../../${OUTPUT_DIR}/${pkg_name}.${version}.nupkg" *)

        # Clean up temp directory
        rm -rf "./temp-extract/net9" "./temp-extract/net10"

        echo "    ✅ Created combined package: ${pkg_name}.${version}.nupkg"
    else
        echo "    ⚠️  No matching net10 package found, using net9 only"
        cp "$net9_pkg" "$OUTPUT_DIR/"
    fi
done

# Clean up
echo ""
echo "Step 7/7: Cleaning up temporary files..."
rm -rf ./temp-packages-net9 ./temp-packages-net10 ./temp-extract
rm -f global.json

# Summary
echo ""
echo "=========================================="
echo "✅ Build Complete!"
echo "=========================================="
echo ""
echo "Packages created in: $OUTPUT_DIR"
echo ""
ls -lh "$OUTPUT_DIR"
echo ""
echo "Package count: $(ls -1 "$OUTPUT_DIR"/*.nupkg 2>/dev/null | wc -l | tr -d ' ')"
echo ""
echo "To use these packages locally:"
echo "  1. Add local source: dotnet nuget add source $(pwd)/$OUTPUT_DIR --name local-datadog-android"
echo "  2. Install packages: dotnet add package Bcr.Datadog.Android.Core"
echo ""
