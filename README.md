# SwiftUiPod
A modernised iPodOS-style application, built entirely in Swift.

## A Brief Description
SwiftUiPod is a demonstration of the power of SwiftUI. The aim of this project is to build a modernised iPod simulator, with a functional Springboard and multiple applications within it.
These applications will also be available as standalone iPhone applications, but the aim of SwiftUiPod is to restrict touch input so that the simulated click wheel is the primary input, while the touchscreen frame is secondary, similar to how to Digital Crown operates on Apple Watch. 

### Applications

| Application | iOS | iPod |
| :---        |    :----:   |          ---: |
| Books | – | – |
| Calendar | – | – |
| Classics | – | – |
| Clock | – | – |
| Files | – | – |
| Music | – | – |
| Notes | v0.1 | v0 |
| Photos | – | – |
| Podcasts | – | – |
| Radio | – | – |
| Settings | – | – |
| TV | – | – |
| Voice Memos | – | – |

## iOS CI and IPA downloads

The [iOS workflow](.github/workflows/ios.yml) builds the standalone **Notes** app
using the shared `Notes` scheme on GitHub's `macos-26` runner. By default, pull
requests to `main`, pushes to `main`, tags matching `v*`, and manual runs produce
an **unsigned IPA**, with no Apple account, certificate, or repository secrets
required. Download `Notes-unsigned.ipa` from the workflow run's **Artifacts**
section; artifacts are retained for 14 days. Signing is optional as described
below. The workflow does not upload to App Store Connect.

An unsigned IPA is a packaged device build for later signing; it cannot be
installed directly on a normal iPhone or run in the iOS Simulator.
For personal testing without a paid membership, open the project in Xcode,
sign in with your Apple Account, select your Personal Team under **Signing &
Capabilities**, enable automatic signing, and run on your connected iPhone.
Xcode creates the signing assets for you. Free Personal Team provisioning
expires after seven days, so you may need to rebuild and reinstall.
See [Apple's membership comparison](https://developer.apple.com/support/compare-memberships/)
and [running an app on a device](https://help.apple.com/xcode/mac/current/en.lproj/dev5a825a1ca.html).

### Optional signing setup

Use an Apple Developer Program account to create an explicit App ID for
`com.swiftuipod.neonotes.Notes` (or set the repository variable `IOS_BUNDLE_ID`
to your own registered identifier). For an Ad Hoc export, create an
Apple Distribution certificate and an Ad Hoc provisioning profile containing
that certificate, App ID, and the registered devices that will install the app.
Export the certificate **with its private key** from Keychain Access as a
password-protected `.p12` file, and download the `.mobileprovision` profile.

Under **Settings → Secrets and variables → Actions**, add these repository secrets:

| Secret | Value |
| :--- | :--- |
| `BUILD_CERTIFICATE_BASE64` | Base64-encoded `.p12` signing certificate and private key |
| `P12_PASSWORD` | Password protecting the `.p12` file |
| `BUILD_PROVISION_PROFILE_BASE64` | Base64-encoded `.mobileprovision` profile |

For example, pipe the files directly to GitHub CLI (the password command prompts
for a hidden value):

```sh
base64 -i /path/to/signing.p12 | gh secret set BUILD_CERTIFICATE_BASE64 --repo meitham/SwiftUiPod
gh secret set P12_PASSWORD --repo meitham/SwiftUiPod
base64 -i /path/to/Notes.mobileprovision | gh secret set BUILD_PROVISION_PROFILE_BASE64 --repo meitham/SwiftUiPod
```

The workflow creates a temporary keychain with a random password, derives the
team and signing identity from the supplied profile, and checks the profile's
expiry, bundle ID, export method, and matching private key before building.
Signing material is removed in an `always()` cleanup step. Keep certificate and
profile files out of the repository; renew the GitHub secrets when they expire.
See [GitHub's Apple signing guide](https://docs.github.com/en/actions/how-tos/deploy/deploy-to-third-party-platforms/sign-xcode-applications)
for more detail on certificate export and secret setup.
Once those secrets are configured, set `IOS_EXPORT_METHOD` to `release-testing`
for signed builds on pushes, or select that method for a manual run.

### Distribution options

Set the repository **variable** `IOS_EXPORT_METHOD` to choose the export method
for pushes (defaults to `unsigned`). Manual runs have their own `export_method`
dropdown, also defaulting to `unsigned`. Pull requests always produce unsigned
builds. For signed builds, the certificate and profile secrets must match the
selected method:

| Method | Certificate and profile | Intended use |
| :--- | :--- | :--- |
| `unsigned` (default) | None | Package for later signing; cannot install directly |
| `release-testing` | Apple Distribution + Ad Hoc | Install on devices listed in the profile |
| `app-store-connect` | Apple Distribution + App Store | Export for a later TestFlight/App Store upload |
| `debugging` | Apple Development + iOS Development | Install on registered development devices |

Signing supports only explicit iOS profiles for this single app. An App Store IPA
cannot be installed directly on a phone. The CI build number is
`<GitHub run number>.<run attempt>`; the app's marketing version stays in the
Xcode project.

To validate the archive locally without signing:

```sh
python3 -m unittest discover -s scripts/ci -p 'test_*.py'
xcodebuild -project applications/iOS/notes/Notes.xcodeproj -scheme Notes \
  -configuration Release -destination 'generic/platform=iOS' \
  -derivedDataPath /tmp/SwiftUiPod-DerivedData \
  -archivePath /tmp/Notes.xcarchive CODE_SIGNING_ALLOWED=NO archive
```

## Development

The current buildable application is Notes, under `applications/iOS/notes`.
It targets iPhone with iOS 18.6 or later and has no third-party dependencies.

### Requirements

- A Mac with full Xcode installed. The project was created with Xcode 26.3;
  CI uses that version, and local builds have also been verified with Xcode 27.0.
- Complete Xcode's first-launch setup. Check `xcodebuild -version` to confirm
  the active installation. Standalone Command Line Tools are insufficient.
- An iOS Simulator runtime is needed to run the app, but not to compile it.

You can edit the Swift files in any editor. If the wrong developer directory
is selected, point the current terminal session at your installation:

```sh
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
```

### Build from the terminal

From the repository root:

```sh
bash scripts/build.sh
CONFIGURATION=Release bash scripts/build.sh
```

The script builds for the iOS Simulator without signing credentials. Debug
output is at `build/Build/Products/Debug-iphonesimulator/Notes.app`.
Set `DERIVED_DATA_PATH` to use a different build directory.

Alternatively, open `applications/iOS/notes/Notes.xcodeproj` in Xcode and
select the shared **Notes** scheme and an iPhone simulator.

### Run in the simulator

If no iOS runtime is installed, download one first (several GB):

```sh
xcodebuild -downloadPlatform iOS
```

List available devices, then use an iPhone UUID from the output below:

```sh
xcrun simctl list devices available
SIMULATOR_ID="replace-with-an-available-iphone-uuid"
xcrun simctl boot "$SIMULATOR_ID" # Skip if already booted.
xcrun simctl bootstatus "$SIMULATOR_ID" -b
xcrun simctl install "$SIMULATOR_ID" build/Build/Products/Debug-iphonesimulator/Notes.app
xcrun simctl launch "$SIMULATOR_ID" com.swiftuipod.neonotes.Notes
```

To view the device, open Simulator from Xcode's developer tools menu.
On Xcode 27, open Device Hub instead; the installation verified locally uses
`/Applications/Xcode.app/Contents/Applications/DeviceHub.app`.

Notes are stored in the app's private data container under
`Library/Application Support/NeoNotes/Notes/`. Each UUID-named `.txt` file
contains metadata followed by `---TEXT---` and the note body. Locate the
container with:

```sh
xcrun simctl get_app_container "$SIMULATOR_ID" com.swiftuipod.neonotes.Notes data
```

### Contributing and checks

Create a branch, keep changes focused, and describe the change and validation
in your pull request. Avoid committing build output or personal Xcode settings.

GitHub Actions builds Debug and Release for the iOS Simulator on pull requests
and pushes to `main`. The workflow selects Xcode 26.3 explicitly on `macos-15`;
when updating it, check the [runner's installed Xcode versions](https://github.com/actions/runner-images/blob/main/images/macos/macos-15-Readme.md).

There is currently no automated test target. Before submitting behavior changes,
run the app and check creating, editing, renaming, searching and deleting notes.
Restart the app to confirm saved text and settings persist.
