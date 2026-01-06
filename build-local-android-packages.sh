#!/usr/bin/env bash
#
# Build Android NuGet packages locally
#
# Usage:
#   ./build-local-android-packages.sh [output-directory]
#
# Requirements:
#   - .NET SDK 10.0.x (or 9.0.x) installed
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
    echo "❌ .NET SDK not found. Please install .NET SDK 9.0+ or 10.0+"
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

echo "✅ All prerequisites met"
echo ""

# Initialize submodules
echo "Step 1/5: Initializing submodules..."
git submodule update --init --recursive

# Remove global.json if it exists (Android doesn't need SDK 8)
rm -f global.json

# Install Android workload
echo ""
echo "Step 2/5: Installing Android workload..."
dotnet workload install android

# Restore dependencies
echo ""
echo "Step 3/5: Restoring dependencies..."
dotnet restore src/Android/AndroidDatadogBindings.sln

# Build
echo ""
echo "Step 4/5: Building Android bindings..."
dotnet build src/Android/AndroidDatadogBindings.sln --configuration Release --no-restore --verbosity minimal

# Pack
echo ""
echo "Step 5/5: Creating NuGet packages..."
mkdir -p "$OUTPUT_DIR"

# Suppress prerelease dependency warnings
dotnet pack src/Android/AndroidDatadogBindings.sln --configuration Release --no-build --output "$OUTPUT_DIR" 2>&1 | grep -v "prerelease dependency" || true

# Summary
echo ""
echo "========================================"
echo "✅ Build Complete!"
echo "========================================"
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
