# .NET for iOS Sample App for the Datadog iOS Mobile SDK

### Why is the name of this project so short?
This is to allow it to be built using Visual Studio for Windows, due to the 260-char path limit in that IDE.

## TestFlight
Authenticating Azure DevOps TestFlight upload task:

You first need to have a `.p8` file along with the other App Store Connect API credentials (issuer ID, etc.). Once those are in place:

1. Open the `.p8` file.
2. Copy the contents AS-IS - including the beginning and end lines.
3. Use [base64encode.org](https://base64encode.org) to encode the contents, using default settings.
4. Take the encoded string - and use in a pipeline variable, NOT in a secure file.