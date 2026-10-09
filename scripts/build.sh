#!/bin/bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

xcodebuild \
  -project "$project_root/applications/iOS/notes/Notes.xcodeproj" \
  -scheme Notes \
  -configuration "${CONFIGURATION:-Debug}" \
  -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath "${DERIVED_DATA_PATH:-$project_root/build}" \
  CODE_SIGNING_ALLOWED=NO \
  build
