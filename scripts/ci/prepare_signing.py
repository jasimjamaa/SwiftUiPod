"""Validate the supplied Apple profile and generate manual signing settings."""

import datetime
import hashlib
import os
from pathlib import Path
import plistlib
import re
import shutil
import subprocess
import uuid


def signing_settings(profile, bundle_id, method, identities, now=None):
    if method not in {"release-testing", "app-store-connect", "debugging"}:
        raise ValueError("Unsupported IOS_EXPORT_METHOD")
    if not re.fullmatch(r"[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)+", bundle_id):
        raise ValueError("IOS_BUNDLE_ID must be an explicit bundle identifier")
    now = now or datetime.datetime.now(datetime.timezone.utc)
    expiration = profile["ExpirationDate"].replace(tzinfo=datetime.timezone.utc)
    if expiration <= now:
        raise ValueError("Provisioning profile has expired")
    if "iOS" not in profile.get("Platform", []):
        raise ValueError("Provisioning profile must support iOS")

    team = profile["TeamIdentifier"][0]
    if not re.fullmatch(r"[A-Z0-9]{10}", team):
        raise ValueError("Invalid team identifier")
    profile_uuid = str(uuid.UUID(profile["UUID"])).upper()
    entitlements = profile["Entitlements"]
    # Older accounts may have an App ID prefix different from their team ID.
    app_ids = {f"{prefix}.{bundle_id}" for prefix in profile["ApplicationIdentifierPrefix"]}
    if entitlements.get("application-identifier") not in app_ids:
        raise ValueError("Profile must match IOS_BUNDLE_ID exactly (no wildcard profiles)")
    if entitlements.get("com.apple.developer.team-identifier") != team:
        raise ValueError("Profile entitlement and team identifier disagree")

    development = entitlements.get("get-task-allow", False)
    devices = bool(profile.get("ProvisionedDevices"))
    if profile.get("ProvisionsAllDevices"):
        raise ValueError("Enterprise profiles are not supported by this workflow")
    if method == "debugging" and not (development and devices):
        raise ValueError("debugging requires an iOS Development profile")
    if method == "release-testing" and (development or not devices):
        raise ValueError("release-testing requires an Ad Hoc distribution profile")
    if method == "app-store-connect" and (development or devices):
        raise ValueError("app-store-connect requires an App Store distribution profile")

    valid_identities = set(re.findall(r"\b[0-9A-Fa-f]{40}\b", identities.upper()))
    certificates = [hashlib.sha1(cert).hexdigest().upper()
                    for cert in profile["DeveloperCertificates"]]
    identity = next((cert for cert in certificates if cert in valid_identities), None)
    if identity is None:
        raise ValueError("No valid signing identity matches the profile; check the P12 and its private key")

    environment = {"TEAM_ID": team, "PROFILE_UUID": profile_uuid, "SIGNING_IDENTITY": identity}
    options = {
        "method": method,
        "destination": "export",
        "signingStyle": "manual",
        "teamID": team,
        "signingCertificate": identity,
        "provisioningProfiles": {bundle_id: profile_uuid},
        "manageAppVersionAndBuildNumber": False,
        "stripSwiftSymbols": True,
    }
    return environment, options


def main():
    temporary = Path(os.environ["RUNNER_TEMP"])
    profile_path = temporary / "signing.mobileprovision"
    profile = plistlib.loads(subprocess.check_output(
        ["security", "cms", "-D", "-i", str(profile_path)]))
    identities = subprocess.check_output(
        ["security", "find-identity", "-v", "-p", "codesigning", os.environ["KEYCHAIN_PATH"]],
        text=True,
    )
    environment, options = signing_settings(
        profile, os.environ["BUNDLE_ID"], os.environ["EXPORT_METHOD"], identities)
    directory = Path.home() / "Library/Developer/Xcode/UserData/Provisioning Profiles"
    directory.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(profile_path, directory / "SwiftUiPod-CI.mobileprovision")
    with (temporary / "ExportOptions.plist").open("wb") as stream:
        plistlib.dump(options, stream)
    with open(os.environ["GITHUB_ENV"], "a") as stream:
        for key, value in environment.items():
            stream.write(f"{key}={value}\n")


if __name__ == "__main__":
    try:
        main()
    except (ValueError, KeyError) as error:
        raise SystemExit(f"Invalid signing configuration: {error}") from error
