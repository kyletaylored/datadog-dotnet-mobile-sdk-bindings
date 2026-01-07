.PHONY: help update-sdks update-android update-ios list-versions build-android build-android-aars build-android-quick build-ios build-all test-android test-ios clean status check-prereqs

# Default target
.DEFAULT_GOAL := help

# Colors for output
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[1;33m
RED := \033[0;31m
NC := \033[0m # No Color

##@ General

help: ## Display this help message
	@awk 'BEGIN {FS = ":.*##"; printf "\n$(BLUE)Usage:$(NC)\n  make $(GREEN)<target>$(NC)\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  $(GREEN)%-20s$(NC) %s\n", $$1, $$2 } /^##@/ { printf "\n$(BLUE)%s$(NC)\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

status: ## Show current SDK versions and git status
	@echo "$(BLUE)=========================================="
	@echo "Current SDK Versions"
	@echo "==========================================$(NC)"
	@echo ""
	@echo "$(YELLOW)Android SDK:$(NC)"
	@cd dd-sdk-android && git describe --tags 2>/dev/null || echo "  (not checked out)"
	@echo ""
	@echo "$(YELLOW)iOS SDK:$(NC)"
	@cd dd-sdk-ios && git describe --tags 2>/dev/null || echo "  (not checked out)"
	@echo ""
	@echo "$(BLUE)=========================================="
	@echo "Git Status"
	@echo "==========================================$(NC)"
	@git status --short
	@echo ""

check-prereqs: ## Check if all prerequisites are installed
	@echo "$(BLUE)Checking prerequisites...$(NC)"
	@command -v dotnet >/dev/null 2>&1 || { echo "$(RED)✗ .NET SDK not found$(NC)"; exit 1; }
	@command -v java >/dev/null 2>&1 || { echo "$(RED)✗ Java not found$(NC)"; exit 1; }
	@echo "$(GREEN)✓ .NET SDK found:$(NC) $$(dotnet --version)"
	@echo "$(GREEN)✓ Java found:$(NC) $$(java -version 2>&1 | head -n 1)"
	@if [ "$$(uname)" = "Darwin" ]; then \
		command -v carthage >/dev/null 2>&1 || { echo "$(RED)✗ Carthage not found (required for iOS)$(NC)"; exit 1; }; \
		echo "$(GREEN)✓ Carthage found:$(NC) $$(carthage version)"; \
		command -v xcodebuild >/dev/null 2>&1 || { echo "$(RED)✗ Xcode not found (required for iOS)$(NC)"; exit 1; }; \
		echo "$(GREEN)✓ Xcode found:$(NC) $$(xcodebuild -version | head -n 1)"; \
	fi
	@echo "$(GREEN)✓ All prerequisites met$(NC)"

##@ SDK Management

update-sdks: ## Update both Android and iOS SDKs to latest versions
	@echo "$(BLUE)Updating SDKs to latest versions...$(NC)"
	@./scripts/update-sdk-versions.sh

update-android: ## Update Android SDK to latest version
	@echo "$(BLUE)Fetching latest Android SDK version...$(NC)"
	@cd dd-sdk-android && git fetch --tags
	@LATEST=$$(cd dd-sdk-android && git tag --sort=-v:refname | grep -E "^[0-9]+\.[0-9]+\.[0-9]+$$" | head -1); \
	echo "$(GREEN)Latest version: $$LATEST$(NC)"; \
	./scripts/update-sdk-versions.sh --android-version $$LATEST

update-ios: ## Update iOS SDK to latest version
	@echo "$(BLUE)Fetching latest iOS SDK version...$(NC)"
	@cd dd-sdk-ios && git fetch --tags
	@LATEST=$$(cd dd-sdk-ios && git tag --sort=-v:refname | grep -E "^[0-9]+\.[0-9]+\.[0-9]+$$" | head -1); \
	echo "$(GREEN)Latest version: $$LATEST$(NC)"; \
	./scripts/update-sdk-versions.sh --ios-version $$LATEST

check-updates: ## Check for new SDK releases without updating
	@echo "$(BLUE)Checking for SDK updates...$(NC)"
	@echo ""
	@echo "$(YELLOW)Android SDK:$(NC)"
	@cd dd-sdk-android && git fetch --tags >/dev/null 2>&1
	@CURRENT=$$(cd dd-sdk-android && git describe --tags 2>/dev/null); \
	LATEST=$$(cd dd-sdk-android && git tag --sort=-v:refname | grep -E "^[0-9]+\.[0-9]+\.[0-9]+$$" | head -1); \
	echo "  Current: $$CURRENT"; \
	echo "  Latest:  $$LATEST"; \
	if [ "$$CURRENT" != "$$LATEST" ]; then \
		echo "  $(GREEN)✓ Update available!$(NC)"; \
	else \
		echo "  $(YELLOW)Already up to date$(NC)"; \
	fi
	@echo ""
	@echo "$(YELLOW)iOS SDK:$(NC)"
	@cd dd-sdk-ios && git fetch --tags >/dev/null 2>&1
	@CURRENT=$$(cd dd-sdk-ios && git describe --tags 2>/dev/null); \
	LATEST=$$(cd dd-sdk-ios && git tag --sort=-v:refname | grep -E "^[0-9]+\.[0-9]+\.[0-9]+$$" | head -1); \
	echo "  Current: $$CURRENT"; \
	echo "  Latest:  $$LATEST"; \
	if [ "$$CURRENT" != "$$LATEST" ]; then \
		echo "  $(GREEN)✓ Update available!$(NC)"; \
	else \
		echo "  $(YELLOW)Already up to date$(NC)"; \
	fi
	@echo ""

list-versions: ## List available SDK versions (10 most recent)
	@./scripts/update-sdk-versions.sh --list-versions

##@ iOS Build

build-ios-frameworks: ## Build iOS XCFrameworks from SDK source (requires macOS)
	@echo "$(BLUE)Building iOS XCFrameworks...$(NC)"
	@if [ "$$(uname)" != "Darwin" ]; then \
		echo "$(RED)Error: iOS builds require macOS$(NC)"; \
		exit 1; \
	fi
	@./src/iOS/buildxcframework.sh

build-ios: build-ios-frameworks ## Build iOS NuGet packages (full build with frameworks)
	@echo "$(BLUE)Building iOS NuGet packages...$(NC)"
	@./scripts/build-local-ios-packages.sh

build-ios-quick: ## Build iOS packages without rebuilding frameworks
	@echo "$(BLUE)Building iOS NuGet packages (using existing frameworks)...$(NC)"
	@if [ ! -d "src/iOS/Bindings/Libs" ] || [ -z "$$(ls -A src/iOS/Bindings/Libs/*.xcframework 2>/dev/null)" ]; then \
		echo "$(YELLOW)Warning: No XCFrameworks found. Running full build...$(NC)"; \
		$(MAKE) build-ios; \
	else \
		./scripts/build-local-ios-packages.sh; \
	fi

##@ Android Build

build-android-aars: ## Build Android AAR files from SDK source
	@echo "$(BLUE)Building Android AAR files...$(NC)"
	@./src/Android/build-aars.sh
	@echo "$(BLUE)Copying AAR files to binding projects...$(NC)"
	@./src/Android/copy-aars.sh
	@echo "$(GREEN)✓ AAR files built and copied$(NC)"

build-android: build-android-aars ## Build Android NuGet packages
	@echo "$(BLUE)Building Android NuGet packages...$(NC)"
	@./scripts/build-local-android-packages.sh

build-android-quick: ## Build Android packages without rebuilding AARs
	@echo "$(BLUE)Building Android NuGet packages (using existing AARs)...$(NC)"
	@if [ ! -d "src/Android/Bindings/Core/aars" ] || [ -z "$$(ls -A src/Android/Bindings/Core/aars/*.aar 2>/dev/null)" ]; then \
		echo "$(YELLOW)Warning: No AAR files found. Running full build...$(NC)"; \
		$(MAKE) build-android; \
	else \
		./scripts/build-local-android-packages.sh; \
	fi

build-android-sdk9: ## Build Android packages with .NET SDK 9 only
	@echo "$(BLUE)Building Android packages (SDK 9 only)...$(NC)"
	@echo '{"sdk":{"version":"9.0.308","rollForward":"latestPatch"}}' > global.json
	@dotnet workload install android
	@dotnet restore src/Android/AndroidDatadogBindings.sln
	@dotnet build src/Android/AndroidDatadogBindings.sln --configuration Release --no-restore
	@dotnet pack src/Android/AndroidDatadogBindings.sln --configuration Release --no-build --output ./local-packages
	@rm -f global.json
	@echo "$(GREEN)✓ Build complete. Packages in ./local-packages$(NC)"

build-android-sdk10: ## Build Android packages with .NET SDK 10 only
	@echo "$(BLUE)Building Android packages (SDK 10 only)...$(NC)"
	@rm -f global.json
	@dotnet workload install android
	@dotnet restore src/Android/AndroidDatadogBindings.sln
	@dotnet build src/Android/AndroidDatadogBindings.sln --configuration Release --no-restore
	@dotnet pack src/Android/AndroidDatadogBindings.sln --configuration Release --no-build --output ./local-packages
	@echo "$(GREEN)✓ Build complete. Packages in ./local-packages$(NC)"

##@ Combined Build

build-all: build-android build-ios ## Build both Android and iOS packages

build: build-all ## Alias for build-all

##@ CI/CD Simulation

ci-android: ## Simulate GitHub Actions Android build workflow locally
	@echo "$(BLUE)=========================================="
	@echo "Simulating GitHub Actions: Android Build"
	@echo "==========================================$(NC)"
	@echo ""
	@echo "$(YELLOW)Step 1/5: Checking out submodules...$(NC)"
	@git submodule update --init --recursive
	@echo "$(GREEN)✓ Submodules updated$(NC)"
	@echo ""
	@echo "$(YELLOW)Step 2/5: Setting up .NET...$(NC)"
	@dotnet --version
	@echo "$(GREEN)✓ .NET ready$(NC)"
	@echo ""
	@echo "$(YELLOW)Step 3/5: Building Android AAR files...$(NC)"
	@chmod +x src/Android/build-aars.sh
	@chmod +x src/Android/copy-aars.sh
	@./src/Android/build-aars.sh
	@./src/Android/copy-aars.sh
	@echo "$(GREEN)✓ AAR files built$(NC)"
	@echo ""
	@echo "$(YELLOW)Step 4/5: Restoring and building bindings...$(NC)"
	@dotnet restore src/Android/AndroidDatadogBindings.sln
	@dotnet build src/Android/AndroidDatadogBindings.sln --configuration Release --no-restore > /tmp/dotnet-build.log 2>&1 || { \
		echo "$(RED)Build failed! Errors:$(NC)"; \
		grep -E "error (CS|NU)[0-9]+:" /tmp/dotnet-build.log | head -30; \
		echo ""; \
		echo "$(YELLOW)Full log saved to: /tmp/dotnet-build.log$(NC)"; \
		exit 1; \
	}
	@echo "$(GREEN)✓ Bindings built$(NC)"
	@echo ""
	@echo "$(YELLOW)Step 5/5: Creating NuGet packages...$(NC)"
	@rm -rf ./local-packages
	@mkdir -p ./local-packages
	@dotnet pack src/Android/AndroidDatadogBindings.sln --configuration Release --no-build --output ./local-packages
	@echo "$(GREEN)✓ Packages created$(NC)"
	@echo ""
	@echo "$(GREEN)=========================================="
	@echo "✓ Android CI workflow complete!"
	@echo "==========================================$(NC)"
	@echo ""
	@echo "Packages location: ./local-packages/"
	@ls -lh ./local-packages/*.nupkg 2>/dev/null || true
	@echo ""

ci-ios: ## Simulate GitHub Actions iOS build workflow locally (requires macOS)
	@echo "$(BLUE)=========================================="
	@echo "Simulating GitHub Actions: iOS Build"
	@echo "==========================================$(NC)"
	@echo ""
	@if [ "$$(uname)" != "Darwin" ]; then \
		echo "$(RED)Error: iOS builds require macOS$(NC)"; \
		exit 1; \
	fi
	@echo "$(YELLOW)Step 1/5: Checking out submodules...$(NC)"
	@git submodule update --init --recursive
	@echo "$(GREEN)✓ Submodules updated$(NC)"
	@echo ""
	@echo "$(YELLOW)Step 2/5: Setting up .NET and iOS workload...$(NC)"
	@dotnet --version
	@dotnet workload install ios --skip-sign-check 2>/dev/null || true
	@echo "$(GREEN)✓ .NET ready$(NC)"
	@echo ""
	@echo "$(YELLOW)Step 3/5: Building XCFrameworks...$(NC)"
	@chmod +x src/iOS/buildxcframework.sh
	@./src/iOS/buildxcframework.sh
	@echo "$(GREEN)✓ XCFrameworks built$(NC)"
	@echo ""
	@echo "$(YELLOW)Step 4/5: Restoring and building bindings...$(NC)"
	@dotnet restore src/iOS/iOSDatadogBindings.sln
	@dotnet build src/iOS/iOSDatadogBindings.sln --configuration Release --no-restore
	@echo "$(GREEN)✓ Bindings built$(NC)"
	@echo ""
	@echo "$(YELLOW)Step 5/5: Creating NuGet packages...$(NC)"
	@rm -rf ./local-packages
	@mkdir -p ./local-packages
	@dotnet pack src/iOS/iOSDatadogBindings.sln --configuration Release --no-build --output ./local-packages
	@echo "$(GREEN)✓ Packages created$(NC)"
	@echo ""
	@echo "$(GREEN)=========================================="
	@echo "✓ iOS CI workflow complete!"
	@echo "==========================================$(NC)"
	@echo ""
	@echo "Packages location: ./local-packages/"
	@ls -lh ./local-packages/*.nupkg 2>/dev/null || true
	@echo ""

ci-all: ci-android ci-ios ## Simulate both Android and iOS GitHub Actions workflows

ci-test: ci-android ## Run CI simulation with test validation
	@echo ""
	@echo "$(BLUE)=========================================="
	@echo "Testing Built Packages"
	@echo "==========================================$(NC)"
	@echo ""
	@echo "$(YELLOW)Adding local package source...$(NC)"
	@dotnet nuget add source $$(pwd)/local-packages --name ci-test 2>/dev/null || true
	@echo ""
	@echo "$(YELLOW)Building test application...$(NC)"
	@dotnet restore src/Android/Bindings/Test/TestBindings/TestBindings.csproj
	@dotnet build src/Android/Bindings/Test/TestBindings/TestBindings.csproj --configuration Release
	@echo "$(GREEN)✓ Test build successful$(NC)"
	@echo ""
	@dotnet nuget remove source ci-test 2>/dev/null || true
	@echo "$(GREEN)=========================================="
	@echo "✓ CI test workflow complete!"
	@echo "==========================================$(NC)"

##@ Testing

test-android: build-android ## Build and test Android packages
	@echo "$(BLUE)Testing Android packages...$(NC)"
	@dotnet nuget add source $$(pwd)/local-packages --name local-test 2>/dev/null || true
	@echo "$(YELLOW)Building test app...$(NC)"
	@dotnet restore src/Android/Bindings/Test/TestBindings/TestBindings.csproj
	@dotnet build src/Android/Bindings/Test/TestBindings/TestBindings.csproj --configuration Release
	@echo "$(GREEN)✓ Android test build successful$(NC)"
	@dotnet nuget remove source local-test 2>/dev/null || true

test-ios: build-ios ## Build and test iOS packages (requires macOS)
	@echo "$(BLUE)Testing iOS packages...$(NC)"
	@if [ "$$(uname)" != "Darwin" ]; then \
		echo "$(RED)Error: iOS testing requires macOS$(NC)"; \
		exit 1; \
	fi
	@dotnet nuget add source $$(pwd)/local-packages --name local-test 2>/dev/null || true
	@echo "$(YELLOW)Building iOS test app...$(NC)"
	@if [ -d "src/iOS/T" ]; then \
		dotnet restore src/iOS/T/T.csproj 2>/dev/null && \
		dotnet build src/iOS/T/T.csproj --configuration Release 2>/dev/null && \
		echo "$(GREEN)✓ iOS test build successful$(NC)"; \
	else \
		echo "$(YELLOW)No iOS test app found, skipping$(NC)"; \
	fi
	@dotnet nuget remove source local-test 2>/dev/null || true

test: test-android ## Run all tests (Android by default, iOS if on macOS)
	@if [ "$$(uname)" = "Darwin" ]; then \
		$(MAKE) test-ios; \
	fi

##@ Cleanup

clean: ## Clean build artifacts and temporary files
	@echo "$(BLUE)Cleaning build artifacts...$(NC)"
	@rm -rf local-packages temp-packages-* artifacts-* release-packages-* temp-extract
	@rm -f global.json
	@find . -type d -name "bin" -o -name "obj" | grep -E "(src/Android|src/iOS)" | xargs rm -rf 2>/dev/null || true
	@echo "$(GREEN)✓ Clean complete$(NC)"

clean-all: clean ## Clean everything including XCFrameworks and AARs
	@echo "$(BLUE)Cleaning all build artifacts including XCFrameworks and AARs...$(NC)"
	@rm -rf src/iOS/Bindings/Libs/*.xcframework 2>/dev/null || true
	@find src/Android/Bindings -type d -name "aars" -exec rm -rf {} + 2>/dev/null || true
	@cd dd-sdk-android && ./gradlew clean --quiet 2>/dev/null || true
	@echo "$(GREEN)✓ Deep clean complete$(NC)"

##@ Development

dev-setup: check-prereqs ## Set up development environment
	@echo "$(BLUE)Setting up development environment...$(NC)"
	@git submodule update --init --recursive
	@dotnet workload install android
	@if [ "$$(uname)" = "Darwin" ]; then \
		dotnet workload install ios; \
		echo "$(GREEN)✓ iOS workload installed$(NC)"; \
	fi
	@echo "$(GREEN)✓ Development environment ready$(NC)"

format: ## Format code (placeholder for future formatter)
	@echo "$(YELLOW)Code formatting not yet implemented$(NC)"

lint: ## Lint code (placeholder for future linter)
	@echo "$(YELLOW)Linting not yet implemented$(NC)"

##@ Release

prepare-release: ## Prepare a new release (update SDKs, build, test)
	@echo "$(BLUE)=========================================="
	@echo "Preparing Release"
	@echo "==========================================$(NC)"
	@$(MAKE) update-sdks
	@echo ""
	@$(MAKE) build-all
	@echo ""
	@$(MAKE) test
	@echo ""
	@echo "$(GREEN)=========================================="
	@echo "✓ Release preparation complete!"
	@echo "==========================================$(NC)"
	@echo ""
	@echo "$(YELLOW)Next steps:$(NC)"
	@echo "  1. Review changes: git diff"
	@echo "  2. Commit: git add -A && git commit -m 'Prepare release X.Y.Z'"
	@echo "  3. Push: git push"
	@echo "  4. Create release via GitHub Actions"
	@echo ""

##@ Documentation

docs: ## Generate or update documentation (placeholder)
	@echo "$(YELLOW)Documentation generation not yet implemented$(NC)"

readme: ## Display quick reference README
	@echo "$(BLUE)=========================================="
	@echo "Datadog .NET Bindings - Quick Reference"
	@echo "==========================================$(NC)"
	@echo ""
	@echo "$(GREEN)Common Commands:$(NC)"
	@echo "  make help          - Show all available commands"
	@echo "  make status        - Show current state"
	@echo "  make check-updates - Check for new SDK versions"
	@echo "  make update-sdks   - Update to latest SDK versions"
	@echo "  make build         - Build all packages"
	@echo "  make test          - Test packages"
	@echo "  make clean         - Clean build artifacts"
	@echo ""
	@echo "$(GREEN)Platform-Specific:$(NC)"
	@echo "  make build-android       - Build Android packages only"
	@echo "  make build-ios           - Build iOS packages (macOS only)"
	@echo "  make build-ios-frameworks - Rebuild iOS XCFrameworks"
	@echo ""
	@echo "$(GREEN)Development:$(NC)"
	@echo "  make dev-setup     - First-time setup"
	@echo "  make prepare-release - Full release preparation"
	@echo ""
	@echo "For more details, see:"
	@echo "  - README.md"
	@echo "  - docs/SDK_UPDATE_GUIDE.md"
	@echo "  - docs/SDK_VERSIONING_STRATEGY.md"
	@echo "  - docs/TROUBLESHOOTING_BINDING_ERRORS.md"
	@echo "  - docs/CI_LOCAL_TESTING.md"
	@echo "  - docs/LOCAL_BUILD_README.md"
	@echo ""
