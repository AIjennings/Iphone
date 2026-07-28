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
