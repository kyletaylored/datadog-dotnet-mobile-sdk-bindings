#!/usr/bin/env bash
#

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Find the most compatible SDK for Objective Sharpie
# Sharpie 3.5 works best with iOS SDKs up to ~17.x
# Try to find an older SDK if available, otherwise use iphoneos
AVAILABLE_SDKS=$(xcodebuild -showsdks 2>/dev/null | grep iphoneos | awk '{print $NF}' | sed 's/iphoneos//' | sort -V)
PREFERRED_SDK="iphoneos"

# Check if we have iOS 17 or 18 SDK (better compatibility with Sharpie)
for sdk_version in $AVAILABLE_SDKS; do
  if [[ "$sdk_version" =~ ^1[78]\. ]]; then
    PREFERRED_SDK="iphoneos${sdk_version}"
    echo "Using iOS SDK ${sdk_version} for better Objective Sharpie compatibility"
    break
  fi
done

# If we couldn't find iOS 17/18, just use the default
if [[ "$PREFERRED_SDK" == "iphoneos" ]]; then
  echo "Using default iOS SDK (may cause compatibility warnings with Objective Sharpie)"
fi

TARGET_SDK="$PREFERRED_SDK"
FOLDER_PATH="${SCRIPT_DIR}/Bindings"
BINDING_OUTPUT_PATH="${FOLDER_PATH}"
HEADER_FILES_TARGET_PATH="${FOLDER_PATH}/Headers"
OUTPUT_FOLDER="${SCRIPT_DIR}/build"
HEADER_FILE_PREFIXES=("DatadogObjc" "DatadogCrashReporting" "DatadogSessionReplay" "DatadogWebViewTracking")
XCFRAMEWORK_NAMES=("DDObjc" "DDCR" "DDSR" "DWVT")
NAMESPACES=("Datadog.iOS.ObjC" "Datadog.iOS.CrashReporting" "Datadog.iOS.SessionReplay" "Datadog.iOS.WebViewTracking")
BINDING_PROJECT_PATHS=("ObjC" "CrashReporting" "SessionReplay" "WebViewTracking")

# Objective Sharpie
# echo "Creating bindings with Objective Sharpie."
echo

for ((i=0; i<${#HEADER_FILE_PREFIXES[@]}; i++)); do
  FRAMEWORK_NAME="${HEADER_FILE_PREFIXES[i]}"
  HEADER_FILE_PATH=$(find "${HEADER_FILES_TARGET_PATH}" -name "${FRAMEWORK_NAME}-Swift.h" | head -n 1)
  BINDING_PROJECT_FOLDER="${BINDING_PROJECT_PATHS[i]}"
  if [ -z "${HEADER_FILE_PATH}" ]; then
    echo "Failed to find ${FRAMEWORK_NAME}-Swift.h in ${HEADER_FILE_PATH}. Exiting."
    exit 1
  fi
  echo
  echo "Creating bindings for ${FRAMEWORK_NAME} with Objective Sharpie."
  echo

  # Build the sharpie command with extra flags to help with newer Xcode versions
  SHARPIE_CMD="sharpie bind -output \"$BINDING_OUTPUT_PATH/$BINDING_PROJECT_FOLDER\" -namespace \"${NAMESPACES[i]}\" -sdk $TARGET_SDK -scope \"$HEADER_FILES_TARGET_PATH\" \"$HEADER_FILE_PATH\""

  echo "Running: $SHARPIE_CMD"
  echo

  # Run sharpie and capture the exit code
  # Note: Sharpie often exits with code 1 even on success if there are warnings
  # We check if the output files were created instead
  eval $SHARPIE_CMD
  SHARPIE_EXIT_CODE=$?

  # Check if the binding files were actually created
  # ApiDefinitions.cs is always required, but StructsAndEnums.cs is optional
  if [ -f "$BINDING_OUTPUT_PATH/$BINDING_PROJECT_FOLDER/ApiDefinitions.cs" ]; then
    echo "Done creating bindings for ${FRAMEWORK_NAME}."
    if [ $SHARPIE_EXIT_CODE -ne 0 ]; then
      echo "Warning: Sharpie exited with code $SHARPIE_EXIT_CODE but generated binding files. Review the output above for any issues."
    fi
    # Create empty StructsAndEnums.cs if it doesn't exist
    if [ ! -f "$BINDING_OUTPUT_PATH/$BINDING_PROJECT_FOLDER/StructsAndEnums.cs" ]; then
      echo "Note: StructsAndEnums.cs not generated (no structs/enums found). Creating empty file."
      cat > "$BINDING_OUTPUT_PATH/$BINDING_PROJECT_FOLDER/StructsAndEnums.cs" << EOF
using System;

namespace ${NAMESPACES[i]}
{
    // No structs or enums were found in the header file
}
EOF
    fi
  else
    echo "Failed to create bindings for ${FRAMEWORK_NAME}. ApiDefinitions.cs not found."
    exit 1
  fi
  echo
done

echo "Done creating bindings."
echo