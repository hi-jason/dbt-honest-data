"""Adversarial checks for the independent reviewed contract-source inventory."""
import json
import tempfile
import unittest
from pathlib import Path

from verify_contract_sources import SourceIntegrityError, git_blob_sha, verify_sources


class SourceIntegrityTests(unittest.TestCase):
    def setUp(self):
        self.folder = tempfile.TemporaryDirectory()
        self.addCleanup(self.folder.cleanup)
        self.root = Path(self.folder.name)
        self.definitions = {
            "models/honest/schema.yml": b"version: 2\nmodels: []\n",
            "models/dishonest/schema.yml": b"version: 2\nmodels: []\n",
            "tests/honest/valid.sql": b"select 1 where 1 = 0\n",
            "tests/dishonest/invalid.sql": b"select 1 where 1 = 1\n",
        }
        for name, body in self.definitions.items():
            dest = self.root / name
            dest.parent.mkdir(parents=True, exist_ok=True)
            dest.write_bytes(body)
        self.write_manifest()

    def write_manifest(self):
        m = {"sources": {name: git_blob_sha(body) for name, body in self.definitions.items()}}
        (self.root / "expected_contract_sources.json").write_text(json.dumps(m))

    def test_original_inventory_passes(self):
        self.assertEqual(verify_sources(self.root), 4)

    def test_argument_edit_rejected_with_identical_case_count(self):
        p = self.root / "models/honest/schema.yml"
        p.write_bytes(p.read_bytes() + b"# toggled fail_when_empty: false\n")
        with self.assertRaises(SourceIntegrityError):
            verify_sources(self.root)

    def test_sql_test_edit_rejected(self):
        (self.root / "tests/dishonest/invalid.sql").write_text("select 1 where 1 = 0")
        with self.assertRaises(SourceIntegrityError):
            verify_sources(self.root)

    def test_new_unregistered_sql_test_rejected(self):
        (self.root / "tests/honest/unreviewed.sql").write_text("select 1")
        with self.assertRaises(SourceIntegrityError):
            verify_sources(self.root)

    def test_deleted_sql_test_rejected(self):
        (self.root / "tests/honest/valid.sql").unlink()
        with self.assertRaises(SourceIntegrityError):
            verify_sources(self.root)

    def test_missing_manifest_rejected(self):
        (self.root / "expected_contract_sources.json").unlink()
        with self.assertRaises(SourceIntegrityError):
            verify_sources(self.root)

    def test_source_manifest_drift_rejected(self):
        self.definitions["models/honest/schema.yml"] = b"modified"
        self.write_manifest()
        # Manifest and real file now disagree, even though all filenames exist.
        with self.assertRaises(SourceIntegrityError):
            verify_sources(self.root)

    def test_new_unreviewed_yaml_rejected(self):
        (self.root / "models/dishonest/extra.yml").write_text("version: 2")
        with self.assertRaises(SourceIntegrityError):
            verify_sources(self.root)

    def test_path_traversal_manifest_rejected(self):
        m = {"sources": {"../outside.yml": "a" * 40}}
        (self.root / "expected_contract_sources.json").write_text(json.dumps(m))
        with self.assertRaises(SourceIntegrityError):
            verify_sources(self.root)

    def test_symlinked_source_rejected(self):
        p = self.root / "tests/honest/valid.sql"
        p.unlink()
        p.symlink_to(self.root / "tests/dishonest/invalid.sql")
        with self.assertRaises(SourceIntegrityError):
            verify_sources(self.root)


if __name__ == "__main__":
    unittest.main()
