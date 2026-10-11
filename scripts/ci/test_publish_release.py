"""Exercise release routing and metadata without publishing to GitHub."""

import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest


SCRIPT = Path(__file__).with_name("publish_release.sh").resolve()


class PublishReleaseTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        (self.root / "release-assets").mkdir()
        (self.root / "release-assets/Notes-unsigned.ipa").write_bytes(b"test artifact")
        tools = self.root / "bin"
        tools.mkdir()
        gh = tools / "gh"
        gh.write_text(
            "#!/usr/bin/env python3\n"
            "import json, os, sys\n"
            "from pathlib import Path\n"
            "Path(os.environ['RELEASE_CALL']).write_text(json.dumps(sys.argv[1:]))\n"
            "sys.exit(int(os.environ.get('GH_EXIT_CODE', '0')))\n"
        )
        gh.chmod(0o755)
        self.environment = {
            **os.environ,
            "PATH": f"{tools}{os.pathsep}{os.environ['PATH']}",
            "RELEASE_CALL": str(self.root / "call.json"),
            "GITHUB_EVENT_NAME": "push",
            "GITHUB_REF": "refs/heads/main",
            "GITHUB_REF_NAME": "main",
            "GITHUB_RUN_NUMBER": "7",
            "GITHUB_RUN_ATTEMPT": "2",
            "GITHUB_RUN_ID": "123",
            "GITHUB_SHA": "a" * 40,
            "GITHUB_SERVER_URL": "https://github.com",
            "GITHUB_REPOSITORY": "example/Notes",
            "GITHUB_STEP_SUMMARY": str(self.root / "summary.md"),
            "RUNNER_TEMP": str(self.root),
            "EXPORT_METHOD": "unsigned",
        }

    def run_script(self, **overrides):
        return subprocess.run(
            ["bash", str(SCRIPT)], cwd=self.root,
            env={**self.environment, **overrides}, capture_output=True, text=True)

    def test_main_build_is_unsigned_prerelease_at_exact_commit(self):
        result = self.run_script()
        self.assertEqual(result.returncode, 0, result.stderr)
        call = json.loads((self.root / "call.json").read_text())
        self.assertEqual(call[:3], ["release", "create", "build-7-2"])
        self.assertIn("--prerelease", call)
        self.assertIn("--latest=false", call)
        self.assertEqual(call[call.index("--target") + 1], "a" * 40)
        notes = (self.root / "ipa-release-notes.md").read_text()
        self.assertIn("unsigned", notes)
        self.assertIn("example/Notes/actions/runs/123", notes)
        self.assertIn("/releases/tag/build-7-2", (self.root / "summary.md").read_text())

    def test_version_tag_verifies_existing_tag_and_uses_selected_signing_method(self):
        result = self.run_script(
            GITHUB_REF="refs/tags/v1.0.0", GITHUB_REF_NAME="v1.0.0",
            EXPORT_METHOD="app-store-connect")
        self.assertEqual(result.returncode, 0, result.stderr)
        call = json.loads((self.root / "call.json").read_text())
        self.assertEqual(call[2], "v1.0.0")
        self.assertIn("--verify-tag", call)
        self.assertNotIn("--prerelease", call)
        self.assertIn("not direct installation", (self.root / "ipa-release-notes.md").read_text())

    def test_manual_main_build_can_publish(self):
        self.assertEqual(self.run_script(GITHUB_EVENT_NAME="workflow_dispatch").returncode, 0)

    def test_pull_requests_other_branches_and_unknown_methods_cannot_publish(self):
        for overrides in [
            {"GITHUB_EVENT_NAME": "pull_request"},
            {"GITHUB_REF": "refs/heads/feature", "GITHUB_EVENT_NAME": "workflow_dispatch"},
            {"EXPORT_METHOD": "invalid"},
        ]:
            with self.subTest(overrides=overrides):
                self.assertNotEqual(self.run_script(**overrides).returncode, 0)
                self.assertFalse((self.root / "call.json").exists())

    def test_missing_ipa_does_not_create_release(self):
        (self.root / "release-assets/Notes-unsigned.ipa").unlink()
        self.assertNotEqual(self.run_script().returncode, 0)
        self.assertFalse((self.root / "call.json").exists())

    def test_failed_publication_does_not_report_success(self):
        self.assertNotEqual(self.run_script(GH_EXIT_CODE="1").returncode, 0)
        self.assertFalse((self.root / "summary.md").exists())


if __name__ == "__main__":
    unittest.main()
