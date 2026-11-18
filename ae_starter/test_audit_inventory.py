"""Adversarial inventory tests: an untagged data test cannot silently escape grading."""
import json
import tempfile
import unittest
from pathlib import Path

from audit_inventory import InventoryError, audit


class InventoryTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)

    def write(self, name, ids):
        p = self.root / name
        p.write_text("\n".join(json.dumps({
            "unique_id": i, "resource_type": "test"}) for i in ids))
        return p

    def fixture(self):
        positives = [f"good_{i}" for i in range(16)]
        negatives = [f"bad_{i}" for i in range(7)]
        return (self.write("all.jsonl", positives + negatives),
                self.write("positive.jsonl", positives),
                self.write("negative.jsonl", negatives))

    def test_full_coverage_passes(self):
        self.assertEqual(audit(*self.fixture()), 23)

    def test_unselected_negative_detected(self):
        all_file, positive, negative = self.fixture()
        all_file.write_text(all_file.read_text().replace('"bad_6"', '"invisible_bad_6"'))
        with self.assertRaises(InventoryError):
            audit(all_file, positive, negative)

    def test_missing_total_detected(self):
        all_file, positive, negative = self.fixture()
        all_file.write_text("\n".join(all_file.read_text().splitlines()[:-1]))
        with self.assertRaises(InventoryError):
            audit(all_file, positive, negative)

    def test_duplicate_id_detected(self):
        all_file, positive, negative = self.fixture()
        all_file.write_text(all_file.read_text() + "\n" +
                            json.dumps({"unique_id": "good_1", "resource_type": "test"}))
        with self.assertRaises(InventoryError):
            audit(all_file, positive, negative)

    def test_missing_selection_detected(self):
        all_file, positive, negative = self.fixture()
        negative.unlink()
        with self.assertRaises(InventoryError):
            audit(all_file, positive, negative)


if __name__ == "__main__":
    unittest.main()
