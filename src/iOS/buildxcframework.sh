#!/usr/bin/env bash
#

# Define workspace and scheme
WORKSPACE="${PWD}/dd-sdk-ios/Datadog.xcworkspace"
FRAMEWORK_NAMES=("DatadogInternal" "DatadogCore" "DatadogLogs" "DatadogTrace" "DatadogRUM" "DatadogSessionReplay" "DatadogCrashReporting" "DatadogWebViewTracking")
XCFRAMEWORK_NAMES=("DDInt" "DDC" "DDL" "DDT" "DDR" "DDSR" "DDCR" "DWVT")
CONFIGURATION="Release"
DERIVED_DATA_PATH="${PWD}/src/iOS/DerivedData"
BUILD_DIR="${DERIVED_DATA_PATH}/Build/Products/${CONFIGURATION}"
CARTFILE_DIRECTORY="${PWD}/dd-sdk-ios"
CARTHAGE_OUTPUT="${CARTFILE_DIRECTORY}/Carthage/Build"
BINDINGS_FOLDER_PATH="./src/iOS/Bindings"
HEADER_FILE_PREFIXES=("DatadogCrashReporting" "DatadogSessionReplay" "DatadogWebViewTracking")
HEADER_XCFRAMEWORK_NAMES=("DDCR" "DDSR" "DWVT")
HEADER_FILES_TARGET_PATH="${BINDINGS_FOLDER_PATH}/Headers"

# Debug statements
echo "PWD: ${PWD}"
echo "WORKSPACE: ${WORKSPACE}"
echo "CARTFILE_DIRECTORY: ${CARTFILE_DIRECTORY}"
echo "CARTHAGE_OUTPUT: ${CARTHAGE_OUTPUT}"
echo "BINDINGS_FOLDER_PATH: ${BINDINGS_FOLDER_PATH}"
echo "HEADER_FILES_TARGET_PATH: ${HEADER_FILES_TARGET_PATH}"
echo "HEADER_XCFRAMEWORK_NAMES: ${HEADER_XCFRAMEWORK_NAMES[@]}"

echo
echo "Building XCFrameworks for Datadog SDK."
echo

# Check if GITHUB_PAT is set and use it if available
if [ -n "${GITHUB_PAT}" ]; then
  echo "Using Github token for Carthage."
  GITHUB_ACCESS_TOKEN=${GITHUB_PAT} carthage bootstrap --platform iOS --use-xcframeworks --cache-builds --project-directory "${CARTFILE_DIRECTORY}"
else
  echo "Github token not set. Running Carthage without authentication."
  carthage bootstrap --platform iOS --use-xcframeworks --cache-builds --project-directory "${CARTFILE_DIRECTORY}"
fi

if [ $? -ne 0 ]; then
  echo "Carthage bootstrap failed. Exiting."
  exit 1
fi

# Define output folder environment variable
OUTPUT_FOLDER="${PWD}/src/iOS/build"
 
echo
echo "Cleaning up old .xcframework files at ${OUTPUT_FOLDER}."
if find "${OUTPUT_FOLDER}" -name "*.xcframework" -type d | grep -q .; then
  find "${OUTPUT_FOLDER}" -name "*.xcframework" -type d -exec rm -rf {} \; || true
  echo "Removed existing .xcframework files."
else
  echo "No existing .xcframework files to remove."
fi

function build_framework {
  local SCHEME="$1"
  local SDK="$2"
  local ARCHIVE_PATH="$3"
  local FRAMEWORK_NAME="$4"

  echo "▸ Building framework: $SCHEME for sdk: $SDK"
  echo "▸ Archive path: $ARCHIVE_PATH"

  # Determine architectures and destination based on SDK type
  if [[ "$SDK" == "iphonesimulator" ]]; then
    ARCHS="x86_64 arm64"
    # Get the first available iPhone simulator and extract its UUID
    # The format is: "    iPhone 15 Pro (5A1AB396-285D-464E-B00C-267CEE8F9F8D) (Shutdown)"
    # We need to extract the UUID which is the first parentheses group
    SIMULATOR_ID=$(xcrun simctl list devices available | grep -m 1 "iPhone" | sed -E 's/.*\(([A-F0-9-]+)\).*/\1/')
    if [ -z "$SIMULATOR_ID" ]; then
      echo "Error: No simulator found"
      exit 1
    fi
    echo "Using simulator: $SIMULATOR_ID"
    DESTINATION="id=$SIMULATOR_ID"
  else
    ARCHS="arm64"
    DESTINATION="generic/platform=iOS"
  fi

  # Build the framework
  if ! xcodebuild build \
    -workspace "${WORKSPACE}" \
    -scheme "$SCHEME" \
    -destination "$DESTINATION" \
    -configuration "${CONFIGURATION}" \
    -derivedDataPath "${DERIVED_DATA_PATH}" \
    ONLY_ACTIVE_ARCH=NO \
    ARCHS="${ARCHS}" \
    IPHONEOS_DEPLOYMENT_TARGET=17.0 \
    ENABLE_BITCODE=NO \
    SKIP_INSTALL=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    DEBUG_INFORMATION_FORMAT="dwarf-with-dsym" \
    SYMROOT="${ARCHIVE_PATH}/Products" \
    OBJROOT="${ARCHIVE_PATH}/Intermediates" \
    OTHER_LDFLAGS="-lc++"; then
      echo "Build for $FRAMEWORK_NAME failed. Exiting."
      echo
      exit 1
  fi

  # Create archive structure similar to what xcodebuild archive creates
  # The output directory will be named based on the SDK version used
  mkdir -p "${ARCHIVE_PATH}/Products/Library/Frameworks"

  # Find the built framework (could be in Release-iphoneos18.0 or similar)
  BUILT_FRAMEWORK=$(find "${ARCHIVE_PATH}/Products" -name "${FRAMEWORK_NAME}.framework" -type d | head -n 1)

  if [ -z "$BUILT_FRAMEWORK" ]; then
    echo "Error: Could not find built framework at ${ARCHIVE_PATH}/Products"
    echo "Contents:"
    ls -la "${ARCHIVE_PATH}/Products" || true
    exit 1
  fi

  cp -R "$BUILT_FRAMEWORK" "${ARCHIVE_PATH}/Products/Library/Frameworks/"
}

for INDEX in "${!FRAMEWORK_NAMES[@]}"; do
  FRAMEWORK_NAME="${FRAMEWORK_NAMES[$INDEX]}"
  XCFRAMEWORK_NAME="${XCFRAMEWORK_NAMES[$INDEX]}"
  SCHEME="${FRAMEWORK_NAME} iOS"
  SIMULATOR_ARCHIVE_PATH="${BUILD_DIR}/${FRAMEWORK_NAME}-iphonesimulator.xcarchive"
  DEVICE_ARCHIVE_PATH="${BUILD_DIR}/${FRAMEWORK_NAME}-iphoneos.xcarchive"
  xcoptions=()

  ### Build frameworks
  # Simulator
  echo
  echo "Creating Simulator build for ${FRAMEWORK_NAME}."
  echo

  build_framework "${SCHEME}" iphonesimulator "${SIMULATOR_ARCHIVE_PATH}" "${FRAMEWORK_NAME}"
  xcoptions+=(-framework "${SIMULATOR_ARCHIVE_PATH}/Products/Library/Frameworks/${FRAMEWORK_NAME}.framework")

  # Device
  echo
  echo "Creating Device build for ${FRAMEWORK_NAME}."
  echo

  build_framework "${SCHEME}" iphoneos "${DEVICE_ARCHIVE_PATH}" "${FRAMEWORK_NAME}"
  xcoptions+=(-framework "${DEVICE_ARCHIVE_PATH}/Products/Library/Frameworks/${FRAMEWORK_NAME}.framework")

  # Create XCFramework by combining all frameworks
  echo "Creating XCFramework ${XCFRAMEWORK_NAME} for ${FRAMEWORK_NAME} framework."
  echo
  if ! xcodebuild -create-xcframework \
    "${xcoptions[@]}" \
    -output "${OUTPUT_FOLDER}/${XCFRAMEWORK_NAME}.xcframework"; then
      echo "Creating XCFramework ${XCFRAMEWORK_NAME} for ${FRAMEWORK_NAME} failed. Exiting."
      echo
      exit 1
  fi
  echo "Done creating XCFramework ${XCFRAMEWORK_NAME} for ${FRAMEWORK_NAME} framework."
  echo 

done

echo "Done with all frameworks."
echo

echo
echo "Copying .xcframework/dependencies to binding project path."
echo

SOURCE_DIR="${OUTPUT_FOLDER}"
TARGET_DIR="${PWD}/src/iOS/Bindings/Libs"

# Create the target directory if it does not exist
mkdir -p "${TARGET_DIR}"

echo "Cleaning up old .xcframework files at ${TARGET_DIR}."
echo
if find "${TARGET_DIR}" -name "*.xcframework" -type d | grep -q .; then
  find "${TARGET_DIR}" -name "*.xcframework" -type d -exec rm -rf {} +
  echo "Removed existing .xcframework files."
else
  echo "No existing .xcframework files to remove."
fi

# Find .xcframework files in the source directory
echo
echo "Copying .xcframeworks from ${SOURCE_DIR} to target directory ${TARGET_DIR}."
echo
find "$SOURCE_DIR" -name "*.xcframework" -type d | while read -r framework
do
  # Copy the framework to the target directory
  if ! cp -R "$framework" "$TARGET_DIR"; then
    echo "Failed to copy $framework. Exiting."
    exit 1
  fi
done

echo "Copying OpenTelemetryApi.xcframework to target directory ${TARGET_DIR}."
echo
if ! cp -R "${CARTHAGE_OUTPUT}/OpenTelemetryApi.xcframework" "${TARGET_DIR}"; then
  echo "Failed to copy OpenTelemetryApi.xcframework. Exiting."
  exit 1
fi

# Search for all folders that don't start with ios-arm64 in TARGET_DIR and its subfolders
# so it will remove anything NOT for device and simulator for ios-arm64/64e and ios-arm64_x86_64-simulator
echo
echo "Searching for extra architectures in ${TARGET_DIR} and its subfolders."
echo
EXTRA_ARCHS=$(find "${TARGET_DIR}" -type d -path "*/.xcframework/*" ! -name "ios-arm64*")

if [ -z "$EXTRA_ARCHS" ]; then
  echo "No extra architectures found in ${TARGET_DIR} and its subfolders."
else
  # Remove the non-ios-arm64 folders
  echo
  echo "Found the following extra architectures:"
  echo "$EXTRA_ARCHS"
  echo
  echo "Removing all extra architectures..."
  find "${TARGET_DIR}" -type d -path "*/.xcframework/*" ! -name "ios-arm64*" -exec rm -rf {} +
  echo "All extra architectures removed."
fi

echo
echo "Copying Swift header files to target directory ${HEADER_FILES_TARGET_PATH}."
echo

for ((i=0; i<${#HEADER_FILE_PREFIXES[@]}; i++)); do
  FRAMEWORK_NAME="${HEADER_FILE_PREFIXES[i]}"
  XCFRAMEWORK_PATH="${OUTPUT_FOLDER}/${HEADER_XCFRAMEWORK_NAMES[i]}.xcframework"
  
  # Debug: List contents of the xcframework path
  echo "Looking for ${FRAMEWORK_NAME}-Swift.h in ${XCFRAMEWORK_PATH}"
  find "${XCFRAMEWORK_PATH}" -type f -name "*.h" || echo "No header files found"
  
  # Search more broadly in case the file structure isn't what we expect
  HEADER_FILE_PATH=$(find "${XCFRAMEWORK_PATH}" -name "${FRAMEWORK_NAME}-Swift.h" | head -n 1)
  if [ -z "${HEADER_FILE_PATH}" ]; then
    echo "Failed to find ${FRAMEWORK_NAME}-Swift.h in ${XCFRAMEWORK_PATH}."
    echo "Trying alternate paths..."
    
    # Try looking in ios-arm64 subdirectory
    HEADER_FILE_PATH=$(find "${XCFRAMEWORK_PATH}/ios-arm64" -name "${FRAMEWORK_NAME}-Swift.h" 2>/dev/null | head -n 1)
    
    if [ -z "${HEADER_FILE_PATH}" ]; then
      # Try looking in ios-arm64_x86_64-simulator subdirectory
      HEADER_FILE_PATH=$(find "${XCFRAMEWORK_PATH}/ios-arm64_x86_64-simulator" -name "${FRAMEWORK_NAME}-Swift.h" 2>/dev/null | head -n 1)
    fi
    
    if [ -z "${HEADER_FILE_PATH}" ]; then
      echo "Still failed to find ${FRAMEWORK_NAME}-Swift.h. Exiting."
      exit 1
    fi
  fi
  
  echo "Copying ${HEADER_FILE_PATH} to ${HEADER_FILES_TARGET_PATH}"
  cp -f "${HEADER_FILE_PATH}" "${HEADER_FILES_TARGET_PATH}"
  if [ $? -ne 0 ]; then
    echo "Failed to copy ${HEADER_FILE_PATH} to ${HEADER_FILES_TARGET_PATH}. Exiting."
    exit 1
  fi
done

echo
echo "Done."
echo
