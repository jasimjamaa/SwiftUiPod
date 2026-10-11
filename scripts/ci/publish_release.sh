#!/usr/bin/env bash
set -euo pipefail

# This script is only called for successful main/tag builds, never pull requests.
if [[ "$GITHUB_EVENT_NAME" != push && "$GITHUB_EVENT_NAME" != workflow_dispatch ]]; then
  echo '::error::Releases require a push or manual workflow run.'
  exit 1
fi
if [[ "$GITHUB_REF" != refs/heads/main && "$GITHUB_REF" != refs/tags/v* ]]; then
  echo '::error::Releases require main or a version tag.'
  exit 1
fi

shopt -s nullglob
ipas=(release-assets/*.ipa)
if [[ ${#ipas[@]} -ne 1 ]]; then
  echo '::error::Expected exactly one IPA from the successful build.'
  exit 1
fi

if [[ "$GITHUB_REF" == refs/tags/v* ]]; then
  tag="$GITHUB_REF_NAME"
  title="Notes $tag"
  flags=(--verify-tag)
else
  # Unique tags preserve the exact build and work with immutable releases.
  tag="build-$GITHUB_RUN_NUMBER-$GITHUB_RUN_ATTEMPT"
  title="Notes development build $GITHUB_RUN_NUMBER.$GITHUB_RUN_ATTEMPT"
  flags=(--prerelease --latest=false)
fi

case "$EXPORT_METHOD" in
  unsigned) installation='This IPA is unsigned. It must be signed before installation on an iPhone.' ;;
  release-testing) installation='Ad Hoc signed IPA: install only on devices included in the provisioning profile.' ;;
  debugging) installation='Development signed IPA: install only on registered development devices.' ;;
  app-store-connect) installation='App Store signed IPA: intended for a separate TestFlight/App Store upload, not direct installation.' ;;
  *) echo '::error::Unsupported export method.'; exit 1 ;;
esac

notes="$RUNNER_TEMP/ipa-release-notes.md"
{
  printf 'Download **%s** from **Assets** below.\n\n' "$(basename "${ipas[0]}")"
  printf '%s\n\n' "$installation"
  printf 'Source commit: %s\n\n' "$GITHUB_SHA"
  printf '[Build logs](%s/%s/actions/runs/%s)\n' "$GITHUB_SERVER_URL" "$GITHUB_REPOSITORY" "$GITHUB_RUN_ID"
} > "$notes"

# Do not replace already published assets (including immutable version releases).
# A failed create/upload is reported by gh and can be inspected in the job logs.
gh release create "$tag" "${ipas[0]}" \
  --repo "$GITHUB_REPOSITORY" \
  --target "$GITHUB_SHA" \
  --title "$title" \
  --notes-file "$notes" \
  "${flags[@]}"
printf '[Download IPA release](%s/%s/releases/tag/%s)\n' \
  "$GITHUB_SERVER_URL" "$GITHUB_REPOSITORY" "$tag" >> "$GITHUB_STEP_SUMMARY"
