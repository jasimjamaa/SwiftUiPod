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
