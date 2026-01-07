#!/usr/bin/env bash
#
# Update Datadog SDK versions to the latest release
#
# This script:
# 1. Fetches the latest release tags from dd-sdk-android and dd-sdk-ios
# 2. Updates git submodules to those tags
# 3. Updates all version references in .csproj files
#
# Usage:
#   ./update-sdk-versions.sh [--android-version X.Y.Z] [--ios-version X.Y.Z]
#
# If versions are not specified, the script will use the latest stable release.
#

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Parse arguments
ANDROID_VERSION=""
IOS_VERSION=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --android-version)
      ANDROID_VERSION="$2"
      shift 2
      ;;
    --ios-version)
      IOS_VERSION="$2"
      shift 2
      ;;
    --list-versions)
      echo "Fetching available SDK versions..."
      echo ""
      echo "Android SDK versions:"
      cd dd-sdk-android
      git fetch --tags --quiet 2>/dev/null
      git tag --sort=-v:refname | grep -E "^[0-9]+\.[0-9]+\.[0-9]+$" | head -10
      cd - > /dev/null
      echo ""
      echo "iOS SDK versions:"
      cd dd-sdk-ios
      git fetch --tags --quiet 2>/dev/null
      git tag --sort=-v:refname | grep -E "^[0-9]+\.[0-9]+\.[0-9]+$" | head -10
      cd - > /dev/null
      exit 0
      ;;
    --help)
      echo "Usage: $0 [OPTIONS]"
      echo ""
      echo "Update Datadog SDK versions in the repository."
      echo ""
      echo "Options:"
      echo "  --android-version X.Y.Z    Update to specific Android SDK version"
      echo "  --ios-version X.Y.Z        Update to specific iOS SDK version"
      echo "  --list-versions            List available SDK versions (10 most recent)"
      echo "  --help                     Show this help message"
      echo ""
      echo "Examples:"
      echo "  $0                                    # Update both to latest"
      echo "  $0 --android-version 3.2.0            # Update Android to 3.2.0, iOS to latest"
      echo "  $0 --android-version 3.2.0 --ios-version 3.1.0  # Specific versions"
      echo "  $0 --list-versions                    # Show available versions"
      echo ""
      echo "If versions are not specified, the latest stable release will be used."
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      echo "Use --help for usage information"
      exit 1
      ;;
  esac
done

echo -e "${BLUE}=========================================="
echo "Updating Datadog SDK Versions"
echo -e "==========================================${NC}"
echo ""

# Function to get latest stable version from a git repo
get_latest_version() {
  local repo_path=$1
  cd "$repo_path"
  git fetch --tags --quiet
  # Get latest semver tag (X.Y.Z format only, no suffixes)
  local version=$(git tag --sort=-v:refname | grep -E "^[0-9]+\.[0-9]+\.[0-9]+$" | head -1)
  cd - > /dev/null
  echo "$version"
}

# Get Android SDK version
if [ -z "$ANDROID_VERSION" ]; then
  echo -e "${YELLOW}Fetching latest dd-sdk-android version...${NC}"
  ANDROID_VERSION=$(get_latest_version "dd-sdk-android")
  echo -e "${GREEN}Latest dd-sdk-android version: $ANDROID_VERSION${NC}"
else
  echo -e "${BLUE}Using specified dd-sdk-android version: $ANDROID_VERSION${NC}"
fi

# Get iOS SDK version
if [ -z "$IOS_VERSION" ]; then
  echo -e "${YELLOW}Fetching latest dd-sdk-ios version...${NC}"
  IOS_VERSION=$(get_latest_version "dd-sdk-ios")
  echo -e "${GREEN}Latest dd-sdk-ios version: $IOS_VERSION${NC}"
else
  echo -e "${BLUE}Using specified dd-sdk-ios version: $IOS_VERSION${NC}"
fi

echo ""

# Verify tags exist
echo -e "${YELLOW}Verifying tags exist...${NC}"
cd dd-sdk-android
if ! git rev-parse "$ANDROID_VERSION" >/dev/null 2>&1; then
  echo -e "${RED}Error: Tag $ANDROID_VERSION does not exist in dd-sdk-android${NC}"
  exit 1
fi
cd ..

cd dd-sdk-ios
if ! git rev-parse "$IOS_VERSION" >/dev/null 2>&1; then
  echo -e "${RED}Error: Tag $IOS_VERSION does not exist in dd-sdk-ios${NC}"
  exit 1
fi
cd ..

echo -e "${GREEN}✓ Tags verified${NC}"
echo ""

# Update submodules
echo -e "${YELLOW}Updating git submodules...${NC}"
git submodule update --init --recursive

echo -e "${YELLOW}Checking out dd-sdk-android $ANDROID_VERSION...${NC}"
cd dd-sdk-android
git checkout "$ANDROID_VERSION"
cd ..

echo -e "${YELLOW}Checking out dd-sdk-ios $IOS_VERSION...${NC}"
cd dd-sdk-ios
git checkout "$IOS_VERSION"
cd ..

echo -e "${GREEN}✓ Submodules updated${NC}"
echo ""

# Update Android .csproj files
echo -e "${YELLOW}Updating Android .csproj files to version $ANDROID_VERSION...${NC}"

ANDROID_FILES=(
  "src/Android/Bindings/Core/Core.csproj"
  "src/Android/Bindings/DatadogLogs/DatadogLogs.csproj"
  "src/Android/Bindings/Internal/Internal.csproj"
  "src/Android/Bindings/Ndk/Ndk.csproj"
  "src/Android/Bindings/Rum/Rum.csproj"
  "src/Android/Bindings/SessionReplay/SessionReplay.csproj"
  "src/Android/Bindings/SessionReplay.Material/SessionReplay.Material.csproj"
  "src/Android/Bindings/Trace/Trace.csproj"
  "src/Android/Bindings/Trace.Otel/Trace.Otel.csproj"
  "src/Android/Bindings/WebView/WebView.csproj"
)

for file in "${ANDROID_FILES[@]}"; do
  if [ -f "$file" ]; then
    # Update <Version> tag
    perl -i -pe "s/<Version>[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.]+)?<\\/Version>/<Version>$ANDROID_VERSION<\\/Version>/g" "$file"

    # Update artifact_versioned in PackageTags
    perl -i -pe "s/artifact_versioned=([^:]+):[0-9]+\.[0-9]+\.[0-9]+/artifact_versioned=\$1:$ANDROID_VERSION/g" "$file"

    # Update PackageReference versions to other Android packages
    perl -i -pe "s/(Bcr\.Datadog\.Android\.Sdk\.[^\"]+)\" Version=\"[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.]+)?\"/\$1\" Version=\"$ANDROID_VERSION\"/g" "$file"

    echo "  Updated: $file"
  fi
done

# Update TestBindings references
TEST_FILE="src/Android/Bindings/Test/TestBindings/TestBindings.csproj"
if [ -f "$TEST_FILE" ]; then
  perl -i -pe "s/(Bcr\.Datadog\.Android\.Sdk\.[^\"]+)\" Version=\"[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.]+)?\"/\$1\" Version=\"$ANDROID_VERSION\"/g" "$TEST_FILE"
  echo "  Updated: $TEST_FILE"
fi

echo -e "${GREEN}✓ Android .csproj files updated${NC}"
echo ""

# Update iOS .csproj files
echo -e "${YELLOW}Updating iOS .csproj files to version $IOS_VERSION...${NC}"

IOS_FILES=(
  "src/iOS/Bindings/Core/Core.csproj"
  "src/iOS/Bindings/CrashReporting/CrashReporting.csproj"
  "src/iOS/Bindings/DDLogs/DDLogs.csproj"
  "src/iOS/Bindings/Internal/Internal.csproj"
  "src/iOS/Bindings/ObjC/ObjC.csproj"
  "src/iOS/Bindings/OpenTelemetryApi/OpenTelemetryApi.csproj"
  "src/iOS/Bindings/Rum/Rum.csproj"
  "src/iOS/Bindings/SessionReplay/SessionReplay.csproj"
  "src/iOS/Bindings/Trace/Trace.csproj"
  "src/iOS/Bindings/WebViewTracking/WebViewTracking.csproj"
)

for file in "${IOS_FILES[@]}"; do
  if [ -f "$file" ]; then
    # Update <Version> tag
    perl -i -pe "s/<Version>[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.]+)?<\\/Version>/<Version>$IOS_VERSION<\\/Version>/g" "$file"

    # Update PackageReference versions to other iOS packages
    perl -i -pe "s/(Bcr\.Datadog\.iOS\.[^\"]+)\" Version=\"[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.]+)?\"/\$1\" Version=\"$IOS_VERSION\"/g" "$file"

    echo "  Updated: $file"
  fi
done

echo -e "${GREEN}✓ iOS .csproj files updated${NC}"
echo ""

# Update documentation
echo -e "${YELLOW}Updating documentation...${NC}"

# Update README.md and GETTING_STARTED.md with new versions
for doc in README.md GETTING_STARTED.md; do
  if [ -f "$doc" ]; then
    # Update Android package versions
    perl -i -pe "s/Bcr\.Datadog\.Android[^\"]+\" Version=\"[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.]+)?\"/Bcr.Datadog.Android\${1}\" Version=\"$ANDROID_VERSION\"/g" "$doc"

    # Update iOS package versions
    perl -i -pe "s/Bcr\.Datadog\.iOS[^\"]+\" Version=\"[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.]+)?\"/Bcr.Datadog.iOS\${1}\" Version=\"$IOS_VERSION\"/g" "$doc"

    echo "  Updated: $doc"
  fi
done

echo -e "${GREEN}✓ Documentation updated${NC}"
echo ""

# Summary
echo -e "${GREEN}=========================================="
echo "✓ SDK Versions Updated Successfully!"
echo -e "==========================================${NC}"
echo ""
echo -e "Android SDK: ${GREEN}$ANDROID_VERSION${NC}"
echo -e "iOS SDK:     ${GREEN}$IOS_VERSION${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Review the changes: git diff"
echo "  2. Test the build locally"
echo "  3. Commit the changes: git add -A && git commit -m \"Update to SDK versions Android $ANDROID_VERSION, iOS $IOS_VERSION\""
echo ""
