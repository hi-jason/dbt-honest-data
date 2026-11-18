"""Adversarial self-tests, independent of dbt runtime."""
import json
import tempfile
import unittest
from pathlib import Path
from verify import EXPECTED, VerificationError, verify_phase, verify_inventory


class ValidationTests(unittest.TestCase):
    def setUp(self):
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        self.root = Path(tmp.name)

    def write_selection(self, name, test_names):
        path = self.root / (name + ".jsonl")
        path.write_text("\n".join(json.dumps({
            "resource_type": "test", "unique_id": "test.x." + x, "name": x
        }) for x in test_names))
        return path

    def write_results(self, test_names, status="pass"):
        path = self.root / "results.json"
        path.write_text(json.dumps({"results": [
            {"unique_id": "test.x." + x, "status": status} for x in test_names
        ]}))
        return path

    def test_valid_positive(self):
        names = sorted(EXPECTED["positive"])
        self.assertEqual(verify_phase("positive",
                         self.write_selection("pos", names),
                         self.write_results(names)), 9)

    def test_valid_negative(self):
        names = sorted(EXPECTED["negative"])
        self.assertEqual(verify_phase("negative",
                         self.write_selection("neg", names),
                         self.write_results(names, "fail")), 7)

    def test_unexpected_pass_on_mutation_rejected(self):
        names = sorted(EXPECTED["negative"])
        with self.assertRaises(VerificationError):
            verify_phase("negative", self.write_selection("neg", names),
                         self.write_results(names, "pass"))

    def test_sql_error_does_not_count_as_negative(self):
        names = sorted(EXPECTED["negative"])
        with self.assertRaises(VerificationError):
            verify_phase("negative", self.write_selection("neg", names),
                         self.write_results(names, "error"))

    def test_same_count_substitution_rejected(self):
        names = sorted(EXPECTED["positive"])
        names[0] = "unexpected_same_count"
        with self.assertRaises(VerificationError):
            verify_phase("positive", self.write_selection("pos", names),
                         self.write_results(names))

    def test_missing_result_rejected(self):
        names = sorted(EXPECTED["positive"])
        path = self.write_results(names)
        path.unlink()
        with self.assertRaises(VerificationError):
            verify_phase("positive", self.write_selection("pos", names), path)

    def test_ungraded_global_test_rejected(self):
        allnames = sorted(set().union(*EXPECTED.values()))
        allfile = self.write_selection("all", allnames)
        p = [self.write_selection(k, sorted(v)) for k, v in EXPECTED.items()]
        # One genuine expected test not included in any phase selection.
        p[1] = self.write_selection("positive", sorted(EXPECTED["positive"])[1:])
        with self.assertRaises(VerificationError):
            verify_inventory(allfile, p)

    def test_full_inventory_accepted(self):
        names = sorted(set().union(*EXPECTED.values()))
        allfile = self.write_selection("all", names)
        p = [self.write_selection(k, sorted(v)) for k, v in EXPECTED.items()]
        self.assertEqual(verify_inventory(allfile, p), 17)


if __name__ == "__main__":
    unittest.main()
