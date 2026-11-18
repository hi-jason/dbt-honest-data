"""Adversarial unit tests for the starter smoke checker."""
import json
import tempfile
import unittest
from pathlib import Path

from validate_results import SmokeFailure, check, EXPECTED_NAMES


class SmokeCheckerTests(unittest.TestCase):
    def setUp(self):
        temp = tempfile.TemporaryDirectory()
        self.addCleanup(temp.cleanup)
        self.path = Path(temp.name)

    def write(self, phase, statuses=None, count=None):
        expected = {"positive": (16, "pass", "test"),
                    "negative": (7, "fail", "test"),
                    "unit": (2, "pass", "unit_test")}
        n, ok_status, kind = expected[phase]
        n = n if count is None else count
        statuses = statuses or [ok_status] * n
        sel = self.path / "select.jsonl"
        result = self.path / "results.json"
        names = sorted(EXPECTED_NAMES[phase])[:n]
        sel.write_text("\n".join(json.dumps({
            "unique_id": f"x{i}", "resource_type": kind, "name": names[i]})
            for i in range(n)))
        result.write_text(json.dumps({"results": [
            {"unique_id": f"x{i}", "status": s} for i, s in enumerate(statuses)]}))
        return sel, result

    def test_valid_positive(self):
        self.assertEqual(check("positive", *self.write("positive")), 16)

    def test_valid_negative(self):
        self.assertEqual(check("negative", *self.write("negative")), 7)

    def test_valid_unit(self):
        self.assertEqual(check("unit", *self.write("unit")), 2)

    def test_mutant_accidentally_passes(self):
        with self.assertRaises(SmokeFailure):
            check("negative", *self.write("negative", ["pass"] + ["fail"] * 6))

    def test_sql_error_is_not_detected_corruption(self):
        with self.assertRaises(SmokeFailure):
            check("negative", *self.write("negative", ["error"] + ["fail"] * 6))

    def test_missing_positive_test(self):
        with self.assertRaises(SmokeFailure):
            check("positive", *self.write("positive", count=15))

    def test_skipped_unit_is_not_pass(self):
        with self.assertRaises(SmokeFailure):
            check("unit", *self.write("unit", ["skipped", "pass"]))

    def test_run_result_missing(self):
        sel, result = self.write("negative")
        result.unlink()
        with self.assertRaises(SmokeFailure):
            check("negative", sel, result)

    def test_wrong_result_id(self):
        sel, result = self.write("positive")
        data = json.loads(result.read_text())
        data["results"][0]["unique_id"] = "unselected"
        result.write_text(json.dumps(data))
        with self.assertRaises(SmokeFailure):
            check("positive", sel, result)

    def test_same_count_substitution_rejected(self):
        sel, results = self.write("positive")
        nodes = [json.loads(line) for line in sel.read_text().splitlines()]
        nodes[0]["name"] = "a_replacement_with_same_count"
        sel.write_text("\n".join(json.dumps(n) for n in nodes))
        with self.assertRaises(SmokeFailure):
            check("positive", sel, results)

    def test_same_name_duplicate_rejected(self):
        sel, results = self.write("negative")
        nodes = [json.loads(line) for line in sel.read_text().splitlines()]
        nodes[1]["name"] = nodes[0]["name"]
        sel.write_text("\n".join(json.dumps(n) for n in nodes))
        with self.assertRaises(SmokeFailure):
            check("negative", sel, results)


if __name__ == "__main__":
    unittest.main()
