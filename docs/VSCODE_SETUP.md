# VS Code IntelliSense Setup (macOS)

This guide explains how to get **working IntelliSense and autocomplete** in VS Code when developing **Datadog .NET mobile SDK bindings** (Android and iOS).

The key rule is simple:

> **Open and work with ONE solution (.sln) at a time.**

---

## Prerequisites

1. **VS Code extension**

   - Install **C#** (Microsoft)

2. **.NET SDK**

   - Use the SDK version required by the repo (`global.json`)
   - Verify:
     ```bash
     dotnet --version
     ```

3. **Toolchains**

   - iOS: Xcode installed
   - Android: Android SDK + JDK configured

4. **Restore must succeed**
   ```bash
   dotnet restore path/to/YourSolution.sln
   ```

If restore fails, IntelliSense will not work.

---

## Required VS Code Configuration (OmniSharp)

Binding projects work best with **OmniSharp**, not C# Dev Kit.

### 1) Disable C# Dev Kit

- Disable or uninstall **C# Dev Kit**
- Keep **C#** extension enabled

### 2) Add workspace settings

Create `.vscode/settings.json` at the repo root:

```json
{
  "dotnet.server.useOmnisharp": true,
  "dotnet.dotnetPath": "/usr/local/share/dotnet",

  "omnisharp.useModernNet": true,
  "omnisharp.enableMsBuildLoadProjectsOnDemand": true,

  "files.watcherExclude": {
    "**/bin/**": true,
    "**/obj/**": true,
    "**/dd-sdk-android/**": true,
    "**/dd-sdk-ios/**": true,
    "**/local-packages/**": true
  },
  "search.exclude": {
    "**/bin/**": true,
    "**/obj/**": true,
    "**/dd-sdk-android/**": true,
    "**/dd-sdk-ios/**": true,
    "**/local-packages/**": true
  }
}
```

> If `which dotnet` shows a different path, update `dotnet.dotnetPath` accordingly.

---

## Android Setup (Test App)

1. Open the Android test folder:

   ```bash
   code src/Android/Test
   ```

2. Select the solution:

   - Command Palette → **OmniSharp: Select Project**
   - Choose: `AndroidTest.sln`

3. Restore:

   ```bash
   dotnet restore src/Android/Test/AndroidTest.sln
   ```

4. Verify IntelliSense:

   - Open `MainActivity.cs`
   - Autocomplete, hover, and go-to-definition should work

---

## iOS Setup (Test App)

1. Open the iOS test folder:

   ```bash
   code src/iOS/Test
   ```

2. Select the solution:

   - Command Palette → **OmniSharp: Select Project**
   - Choose: `Test.sln`

3. Restore:

   ```bash
   dotnet restore src/iOS/Test/Test.sln
   ```

4. Verify IntelliSense:

   - Open `AppDelegate.cs`
   - Autocomplete and navigation should work

---

## Namespaces Reference

### Android

```csharp
using Datadog.Android.Core.Configuration;
using Datadog.Android.Log;
using Datadog.Android.Rum;
using Datadog.Android.Ndk;
```

### iOS

```csharp
using Datadog.iOS.ObjC;
using Datadog.iOS.CrashReporting;
using Datadog.iOS.SessionReplay;
using Datadog.iOS.WebViewTracking;
```

---

## Verifying IntelliSense Works

You should be able to:

- See autocomplete for Datadog types and members
- Hover over types to see signatures
- Use **Cmd+Click / F12** to jump to definitions
- See no red squiggles on `using` statements

---

## Troubleshooting

### IntelliSense not working

1. Reload VS Code:

   - Command Palette → **Developer: Reload Window**

2. Ensure OmniSharp is active:

   - C# Dev Kit is disabled
   - `"dotnet.server.useOmnisharp": true` is set

3. Manually select the solution:

   - Command Palette → **OmniSharp: Select Project**

4. Check logs:

   - View → Output → **OmniSharp Log**
   - Look for project load or restore errors

### Types or namespaces missing

```bash
dotnet restore path/to/YourSolution.sln
dotnet build path/to/YourSolution.sln
```

---

## Important Notes

- **Only open one solution at a time**
- Do **not** open the entire repo root if IntelliSense is unstable
- IntelliSense depends on successful MSBuild project loading

---

## Resources

- VS Code C# docs: [https://code.visualstudio.com/docs/languages/csharp](https://code.visualstudio.com/docs/languages/csharp)
- OmniSharp config: [https://github.com/OmniSharp/omnisharp-roslyn/wiki/Configuration-Options](https://github.com/OmniSharp/omnisharp-roslyn/wiki/Configuration-Options)
