import copy
import datetime
import hashlib
import unittest

from prepare_signing import signing_settings


class SigningSettingsTests(unittest.TestCase):
    def setUp(self):
        self.now = datetime.datetime(2026, 1, 1, tzinfo=datetime.timezone.utc)
        self.bundle = "com.swiftuipod.neonotes.Notes"
        self.certificate = b"test certificate"
        self.identity = hashlib.sha1(self.certificate).hexdigest().upper()
        self.profile = {
            "ExpirationDate": datetime.datetime(2027, 1, 1),
            "Platform": ["iOS"],
            "TeamIdentifier": ["ABCDEFGHIJ"],
            "ApplicationIdentifierPrefix": ["OLDPREFIX1"],
            "UUID": "12345678-1234-1234-1234-123456789ABC",
            "Entitlements": {
                "application-identifier": f"OLDPREFIX1.{self.bundle}",
                "com.apple.developer.team-identifier": "ABCDEFGHIJ",
                "get-task-allow": False,
            },
            "ProvisionedDevices": ["test-device"],
            "DeveloperCertificates": [self.certificate],
        }

    def settings(self, method="release-testing", identities=None):
        return signing_settings(
            self.profile, self.bundle, method,
            self.identity if identities is None else identities, self.now)

    def test_ad_hoc_with_legacy_app_id_prefix(self):
        environment, options = self.settings()
        self.assertEqual(environment["TEAM_ID"], "ABCDEFGHIJ")
        self.assertEqual(options["signingCertificate"], self.identity)
        self.assertEqual(options["provisioningProfiles"], {self.bundle: self.profile["UUID"]})
        self.assertEqual(options["destination"], "export")
        self.assertFalse(options["manageAppVersionAndBuildNumber"])

    def test_app_store_and_development(self):
        del self.profile["ProvisionedDevices"]
        self.assertEqual(self.settings("app-store-connect")[1]["method"], "app-store-connect")
        self.profile["ProvisionedDevices"] = ["test-device"]
        self.profile["Entitlements"]["get-task-allow"] = True
        self.assertEqual(self.settings("debugging")[1]["method"], "debugging")

    def test_wrong_distribution_method(self):
        for method in ["app-store-connect", "debugging", "invalid"]:
            with self.subTest(method=method), self.assertRaises(ValueError):
                self.settings(method)

    def test_invalid_profiles(self):
        original = copy.deepcopy(self.profile)
        for mutation in [
            lambda p: p.update(ExpirationDate=datetime.datetime(2025, 1, 1)),
            lambda p: p.update(Platform=["OSX"]),
            lambda p: p.update(ProvisionsAllDevices=True),
            lambda p: p["Entitlements"].update({"application-identifier": "OLDPREFIX1.*"}),
            lambda p: p["Entitlements"].update({"com.apple.developer.team-identifier": "WRONGTEAM1"}),
            lambda p: p.update(UUID="invalid\nINJECTED=value"),
        ]:
            self.profile = copy.deepcopy(original)
            mutation(self.profile)
            with self.subTest(profile=self.profile), self.assertRaises(ValueError):
                self.settings()

    def test_missing_or_unrelated_private_key(self):
        for identities in ["0 valid identities found", "A" * 40]:
            with self.subTest(identities=identities), self.assertRaises(ValueError):
                self.settings(identities=identities)


if __name__ == "__main__":
    unittest.main()
