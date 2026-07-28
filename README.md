# Signal Field — native iPhone app

This is a SwiftUI Xcode project for sideloading on iPhone.

## What it reads

- Current Wi‑Fi SSID, security state, and the iOS-provided signal-strength estimate using `NEHotspotNetwork.fetchCurrent`.
- Current cellular radio technology using `CTTelephonyNetworkInfo`, including 5G / 5G NSA detection.
- Pull-to-refresh and local-only status display.

## Apple platform limits

Apple does not expose raw cellular RSRP/RSRQ/dBm measurements to normal third-party iOS apps. The app therefore reports the cellular radio type and explicitly avoids fake numeric 5G measurements.

## Build and sideload

1. Open `SignalField.xcodeproj` on a Mac in Xcode.
2. Add your Apple Developer Team under Signing & Capabilities. The Wi‑Fi Information entitlement may need to be enabled for the selected provisioning profile.
3. Connect the iPhone, select it as the run destination, and press Run.
4. For a personal/free Apple ID, the app generally requires periodic re-signing. A paid Apple Developer account gives a more durable sideload workflow.

The Windows machine that generated this source package does not have Xcode or an Apple signing environment, so an IPA cannot be truthfully claimed until this project is opened and signed on macOS.

## GitHub Actions IPA build

The repository includes `.github/workflows/build-ipa.yml`. It runs manually on a macOS GitHub runner and uploads `SignalField.ipa` as an Actions artifact.

Add these repository secrets at **Settings → Secrets and variables → Actions → New repository secret**:

- `APPLE_TEAM_ID` — your Apple Developer Team ID
- `PROVISIONING_PROFILE_NAME` — exact provisioning profile name for `com.ariatechnology.signalfield`
- `BUILD_CERTIFICATE_BASE64` — base64 contents of your `.p12` signing certificate
- `P12_PASSWORD` — password used when exporting the `.p12`
- `KEYCHAIN_PASSWORD` — a new temporary password for the Actions keychain
- `BUILD_PROVISION_PROFILE_BASE64` — base64 contents of your `.mobileprovision` file

Generate base64 values locally; do not paste certificates or private keys into Telegram. On macOS, for example:

```bash
base64 -i signing_certificate.p12 | pbcopy
base64 -i SignalField.mobileprovision | pbcopy
```

Then open **Actions → Build signed iOS IPA → Run workflow**. When the run finishes, download the `SignalField-IPA` artifact. The workflow uses a development export, so the target iPhone must be included in the provisioning profile.
