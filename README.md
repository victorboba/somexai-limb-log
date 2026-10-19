# Limb Log

A measurement diary for lymphedema, lipedema and chronic swelling: tape circumferences at fixed points, estimated limb volume, affected side versus the other, symptoms, and a PDF for the therapist. It is for patients who measure at home.

One of a set of niche iPhone apps built from a shared SwiftUI template. It was never released on the App Store; the code is here for anyone to use. The template is [somexai-ios-template](https://github.com/victorboba/somexai-ios-template) and the collection is [somexai-ios-apps](https://github.com/victorboba/somexai-ios-apps).

## What it does

- Limb setup: arm or leg, affected side, units (cm or inches), tape points as distance from the wrist or ankle (every 10 cm by default, editable), therapist, next appointment and measuring interval.
- Measure: one field per point, prefilled from the last measurement of that side, with a live volume estimate, notes and a photo. If both sides are measured within 3 days the app pairs them.
- Volume: truncated-cone (frustum) formula between consecutive points, in mL (`VolumeMath`), with percent difference versus the other side and change since baseline.
- Symptoms: heaviness, tightness, pain (0 to 3), skin signs, therapies done and garment hours.
- History: volume chart for both sides (Swift Charts) and every measurement and symptom entry, editable.
- Report: 30, 90 or 365 days or all; baseline, latest, change and side-to-side; a PDF with the chart, readings, symptom table and photos; two CSVs.
- Reminder on the day the next measurement is due, a widget, a Siri App Shortcut and a How-to guide.

## The boundary

The app stores what you measured and estimates volume from it. It does not diagnose, stage or treat lymphedema or replace your therapist's measurements, and the report says the numbers are patient-entered. Sudden swelling, redness, warmth or fever can mean infection; the app tells you to contact your clinic.

## Privacy

Data stays on the device in SwiftData. There is no account, no analytics and no network access, and iCloud sync is off (`iCloudSyncEnabled = false`). Nothing leaves the phone unless you export a PDF or CSV and share it yourself.

## Build and run

- Requirements: Xcode 26 or later, [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`), iOS 17 or later.
- Run `xcodegen generate`, open `LimbLog.xcodeproj`, pick the `LimbLog` scheme and an iPhone simulator, and Run.
- Tests: `xcodebuild -scheme LimbLog -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' test`.
- Paywall: the app has a hard paywall (annual subscription or lifetime purchase). Running from Xcode uses the bundled `Products.storekit` file, so purchases are simulated and free. Debug builds can also skip it with the `-unlock` launch argument or the Debug switch in Settings.
- To run on your own device or ship it: set your team in `project.yml` (`DEVELOPMENT_TEAM`), change the `com.example` bundle ID prefix in `project.yml`, both `.entitlements` files and `Products.storekit`, and update `supportEmail`, `privacyPolicyURL` and `appStoreID` in `Shared/AppConfig.swift`.

## Project layout

- `LimbLog/App/`, `LimbLog/Core/`: app entry and root gate, StoreKit entitlement, export, review prompt, App Shortcut, widget sync.
- `LimbLog/Features/`: the screens.
- `LimbLog/Models/`: SwiftData models.
- `LimbLog/Core/VolumeMath.swift`, `Core/Notifications/`: volume calculation and local reminders.
- `LimbLogWidget/`: the Home Screen widget, fed from a snapshot in the App Group.
- `Shared/AppConfig.swift`: everything that changes per app (name, copy, product IDs, links, How-to guide, disclaimer).
- `LimbLogTests/`, `LimbLogUITests/`: unit and UI tests.
- `scripts/`, `docs/`: icon and screenshot helpers, capability notes.

## License

MIT. See [LICENSE](LICENSE).
