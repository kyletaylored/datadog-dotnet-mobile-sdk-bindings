#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
DD_SDK_ROOT="$REPO_ROOT/dd-sdk-android"
GRADLEW="$DD_SDK_ROOT/gradlew"

if [ ! -d "$DD_SDK_ROOT" ]; then
  echo "Error: dd-sdk-android not found at $DD_SDK_ROOT"
  exit 1
fi
if [ ! -f "$GRADLEW" ]; then
  echo "Error: gradlew not found in $DD_SDK_ROOT"
  exit 1
fi
chmod +x "$GRADLEW"

# Detect installed NDK version (use the highest available version)
ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-$HOME/Library/Android/sdk}"
NDK_DIR="$ANDROID_SDK_ROOT/ndk"
INSTALLED_NDK=""

if [ -d "$NDK_DIR" ]; then
  # Find the highest version NDK that has a source.properties file
  for ndk_version_dir in "$NDK_DIR"/*; do
    if [ -d "$ndk_version_dir" ] && [ -f "$ndk_version_dir/source.properties" ]; then
      INSTALLED_NDK=$(basename "$ndk_version_dir")
      break
    fi
  done
fi

if [ -z "$INSTALLED_NDK" ]; then
  echo "Warning: No valid NDK installation found in $NDK_DIR"
  echo "Please install the Android NDK via Android Studio or sdkmanager"
  exit 1
fi

echo "Using installed NDK version: $INSTALLED_NDK"

# Create a gradle.properties override to use the installed NDK
GRADLE_PROPS="$DD_SDK_ROOT/gradle.properties"
if [ ! -f "$GRADLE_PROPS" ]; then
  touch "$GRADLE_PROPS"
fi

# Backup original gradle.properties if it exists and has content
if [ -s "$GRADLE_PROPS" ]; then
  cp "$GRADLE_PROPS" "$GRADLE_PROPS.backup"
fi

# Add NDK override (will be cleaned up later)
echo "android.ndkVersion=$INSTALLED_NDK" >> "$GRADLE_PROPS"

# Setup cleanup trap to restore gradle.properties on exit
cleanup() {
  if [ -f "$GRADLE_PROPS.backup" ]; then
    mv "$GRADLE_PROPS.backup" "$GRADLE_PROPS"
    echo "Restored original gradle.properties"
  else
    # Remove the NDK override line we added
    if [ -f "$GRADLE_PROPS" ]; then
      grep -v "^android.ndkVersion=" "$GRADLE_PROPS" > "$GRADLE_PROPS.tmp" || true
      mv "$GRADLE_PROPS.tmp" "$GRADLE_PROPS"
    fi
  fi
}
trap cleanup EXIT

# stop any running daemon to avoid cached state
cd "$DD_SDK_ROOT"
"$GRADLEW" --stop || true

# run a clean first to ensure fresh outputs (disable build cache)
echo "Running Gradle clean..."
"$GRADLEW" clean --no-daemon --no-build-cache --info

tasks=()
tasks+=( ":dd-sdk-android-core:assembleRelease" )
tasks+=( ":dd-sdk-android-internal:assembleRelease" )

FEATURES_DIR="$DD_SDK_ROOT/features"
if [ -d "$FEATURES_DIR" ]; then
  for d in "$FEATURES_DIR"/dd-sdk-android-*; do
    [ -e "$d" ] || continue
    [ -d "$d" ] || continue
    name=$(basename "$d")
    if [ -f "$d/build.gradle" ] || [ -f "$d/build.gradle.kts" ]; then
      # use the full project path under the 'features' container
      tasks+=( ":features:$name:assembleRelease" )
    fi
  done
fi

if [ "${#tasks[@]}" -eq 0 ]; then
  echo "No Gradle tasks to run."
  exit 0
fi

echo "Running Gradle tasks:"
for t in "${tasks[@]}"; do echo "  $t"; done

# run assemble with no build cache and force task execution
"$GRADLEW" "${tasks[@]}" --no-daemon --no-build-cache --rerun-tasks --info

# Note: gradle.properties cleanup happens automatically via the EXIT trap