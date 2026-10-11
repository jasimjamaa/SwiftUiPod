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
