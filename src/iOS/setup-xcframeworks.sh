#!/usr/bin/env bash
#
# Smart XCFramework Setup - Download pre-built frameworks from GitHub releases
#
# This script downloads pre-built Datadog iOS SDK XCFrameworks from GitHub releases
# instead of building them from source. This is much faster and doesn't require
# Carthage or Xcode build tools.
#
# Usage:
#   ./setup-xcframeworks.sh [SDK_VERSION]
#
# If SDK_VERSION is not provided, it reads from dd-sdk-ios submodule

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
DD_SDK_ROOT="$REPO_ROOT/dd-sdk-ios"
OUTPUT_DIR="$SCRIPT_DIR/Bindings/Libs"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Determine SDK version
if [ $# -eq 0 ]; then
  if [ -d "$DD_SDK_ROOT" ]; then
    cd "$DD_SDK_ROOT"
    SDK_VERSION=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
    cd - > /dev/null
    if [ -z "$SDK_VERSION" ]; then
      echo -e "${RED}Error: Could not determine SDK version from submodule${NC}"
      echo "Usage: $0 [SDK_VERSION]"
      exit 1
    fi
  else
    echo -e "${RED}Error: dd-sdk-ios submodule not found${NC}"
    echo "Usage: $0 [SDK_VERSION]"
    exit 1
  fi
else
  SDK_VERSION="$1"
fi

echo -e "${BLUE}=========================================="
echo "Smart XCFramework Setup"
echo "=========================================="
echo -e "SDK Version: ${GREEN}$SDK_VERSION${NC}"
echo ""

# GitHub release URL
GITHUB_RELEASE_URL="https://github.com/DataDog/dd-sdk-ios/releases/download/${SDK_VERSION}"

# Function to download and extract XCFramework
download_xcframework() {
  local variant=$1
  local url="${GITHUB_RELEASE_URL}/Datadog${variant}.xcframework.zip"
  local temp_zip="/tmp/Datadog${variant}.xcframework.zip"

  echo -e "${YELLOW}Downloading Datadog${variant}.xcframework.zip...${NC}"

  if curl -f -L -s "$url" -o "$temp_zip" 2>/dev/null; then
    echo -e "${GREEN}✓ Downloaded${NC}"

    # Extract to temporary directory
    local temp_dir="/tmp/datadog-ios-extract-$$"
    mkdir -p "$temp_dir"

    echo -e "${YELLOW}Extracting XCFrameworks...${NC}"
    unzip -q "$temp_zip" -d "$temp_dir"

    # Create output directory
    mkdir -p "$OUTPUT_DIR"

    # The zip contains a Datadog.xcframework directory with all frameworks inside
    # We need to move the individual frameworks to the output directory
    local datadog_dir="$temp_dir/Datadog.xcframework"
    if [ -d "$datadog_dir" ]; then
      # Use a different approach to avoid subshell issues
      for framework in "$datadog_dir"/*.xcframework; do
        if [ -d "$framework" ]; then
          local framework_name=$(basename "$framework")
          local dest="$OUTPUT_DIR/$framework_name"

          # Remove existing framework if present
          if [ -d "$dest" ]; then
            rm -rf "$dest"
          fi

          mv "$framework" "$dest"
          echo -e "${GREEN}  ✓ ${framework_name}${NC}"
        fi
      done
    else
      echo -e "${RED}✗ Unexpected zip structure${NC}"
      rm -rf "$temp_dir" "$temp_zip"
      return 1
    fi

    # Cleanup
    rm -rf "$temp_dir" "$temp_zip"

    return 0
  else
    echo -e "${RED}✗ Failed to download: ${url}${NC}"
    return 1
  fi
}

# Download the standard variant (without arm64e)
echo -e "${BLUE}Downloading standard XCFrameworks...${NC}"
if ! download_xcframework ""; then
  echo -e "${RED}Error: Failed to download XCFrameworks${NC}"
  exit 1
fi

echo ""
echo -e "${BLUE}Renaming XCFrameworks to match binding expectations...${NC}"

# Mapping from downloaded names to expected abbreviated names (using parallel arrays for bash 3.x compatibility)
ORIGINAL_NAMES=(
  "DatadogInternal.xcframework"
  "DatadogCore.xcframework"
  "DatadogLogs.xcframework"
  "DatadogTrace.xcframework"
  "DatadogRUM.xcframework"
  "DatadogSessionReplay.xcframework"
  "DatadogCrashReporting.xcframework"
  "DatadogWebViewTracking.xcframework"
)

ABBREVIATED_NAMES=(
  "DDInt.xcframework"
  "DDC.xcframework"
  "DDL.xcframework"
  "DDT.xcframework"
  "DDR.xcframework"
  "DDSR.xcframework"
  "DDCR.xcframework"
  "DWVT.xcframework"
)

for i in "${!ORIGINAL_NAMES[@]}"; do
  original_name="${ORIGINAL_NAMES[$i]}"
  abbreviated_name="${ABBREVIATED_NAMES[$i]}"
  original_path="$OUTPUT_DIR/$original_name"
  abbreviated_path="$OUTPUT_DIR/$abbreviated_name"

  if [ -d "$original_path" ]; then
    if [ -d "$abbreviated_path" ]; then
      rm -rf "$abbreviated_path"
    fi
    mv "$original_path" "$abbreviated_path"
    echo -e "${GREEN}  ✓ ${original_name} → ${abbreviated_name}${NC}"
  fi
done

echo ""
echo -e "${GREEN}=========================================="
echo "✓ Setup Complete!"
echo "==========================================${NC}"
echo ""
echo -e "${YELLOW}Downloaded XCFrameworks:${NC}"
ls -1 "$OUTPUT_DIR" | grep "\.xcframework$" | sed 's/^/  - /'
echo ""
echo -e "${YELLOW}Summary:${NC}"
echo "- Downloaded from: ${GITHUB_RELEASE_URL}"
echo "- Installed to: src/iOS/Bindings/Libs/"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "1. Build bindings: dotnet build src/iOS/iOSDatadogBindings.sln"
echo "2. Create packages: ./scripts/build-local-ios-packages.sh"
echo ""
