"""Dependency-free adversarial cases for the results validator."""
import json
import tempfile
import unittest
from pathlib import Path
from validate_results import ValidationError, check_results, check_selection, read_selection

def test_node(uid, macro):
    return {"unique_id": uid, "resource_type": "test", "name": macro + "_example",
            "test_metadata": {"name": macro}}

class ValidatorTests(unittest.TestCase):
    def setUp(self):
        t = tempfile.TemporaryDirectory()
        self.addCleanup(t.cleanup)
        self.tmp = Path(t.name)
    def selection(self, nodes):
        path = self.tmp / "selection.jsonl"
        path.write_text("\n".join(json.dumps(x) for x in nodes))
        return read_selection(path)
    def results(self, data):
        path = self.tmp / "run_results.json"
        path.write_text(json.dumps({"results": data}))
        return path
    def test_expected_positive(self):
        nodes = self.selection([test_node("a", "known_cases")])
        self.assertEqual(check_results(self.results([{"unique_id":"a","status":"pass"}]),nodes,"pass"),1)
    def test_expected_negative(self):
        nodes = self.selection([test_node("a", "known_cases")])
        self.assertEqual(check_results(self.results([{"unique_id":"a","status":"fail"}]),nodes,"fail"),1)
    def test_error_is_not_negative_assertion(self):
        nodes = self.selection([test_node("a", "known_cases")])
        with self.assertRaises(ValidationError):
            check_results(self.results([{"unique_id":"a","status":"error"}]),nodes,"fail")
    def test_missing_artifact(self):
        nodes = self.selection([test_node("a", "known_cases")])
        with self.assertRaises(ValidationError):
            check_results(self.tmp/"missing.json",nodes,"fail")
    def test_stale_partial_result(self):
        nodes = self.selection([test_node("a", "known_cases"),test_node("b","partitions_into")])
        with self.assertRaises(ValidationError):
            check_results(self.results([{"unique_id":"a","status":"fail"}]),nodes,"fail")
    def test_dropped_case(self):
        nodes = self.selection([test_node("a","partitions_into")])
        with self.assertRaises(ValidationError):
            check_selection(nodes,{"count":2,"macros":{"partitions_into":2}})
    def test_wrong_macro_same_count(self):
        nodes = self.selection([test_node("a","partitions_into"),test_node("b","known_cases")])
        with self.assertRaises(ValidationError):
            check_selection(nodes,{"count":2,"macros":{"partitions_into":2}})
    def test_same_macro_fixture_substitution_is_rejected(self):
        # A same-macro replacement keeps the old per-macro count.
        a = test_node("a", "partitions_into")
        a["name"] = "honest_data_partitions_into_unexpected_model_example"
        selected = self.selection([a])
        with self.assertRaises(ValidationError):
            check_selection(selected, {
                "count": 1,
                "macros": {"partitions_into": 1},
                "cases": ["expected_model|partitions_into"]
            })

    def test_anchored_case_inventory_accepts_expected_model(self):
        a = test_node("a", "partitions_into")
        a["name"] = "honest_data_partitions_into_expected_model_example"
        selected = self.selection([a])
        check_selection(selected, {
            "count": 1,
            "macros": {"partitions_into": 1},
            "cases": ["expected_model|partitions_into"]
        })

    def test_duplicate_same_model_and_macro_count_cannot_disappear(self):
        a = test_node("a", "claim_requires_evidence")
        a["name"] = "honest_data_claim_requires_evidence_changes_coherent_x"
        b = test_node("b", "claim_requires_evidence")
        b["name"] = "honest_data_claim_requires_evidence_other_model_x"
        selected = self.selection([a, b])
        with self.assertRaises(ValidationError):
            check_selection(selected, {
                "count": 2,
                "macros": {"claim_requires_evidence": 2},
                "cases": ["changes_coherent|claim_requires_evidence"] * 2
            })

    def test_missing_case_catalog_is_rejected(self):
        a = test_node("a", "partitions_into")
        a["name"] = "honest_data_partitions_into_example_x"
        selected = self.selection([a])
        with self.assertRaises(ValidationError):
            check_selection(selected, {
                "count": 1,
                "macros": {"partitions_into": 1}
            })

    def test_duplicate_results(self):
        nodes = self.selection([test_node("a","known_cases")])
        with self.assertRaises(ValidationError):
            check_results(self.results([{"unique_id":"a","status":"fail"},{"unique_id":"a","status":"fail"}]),nodes,"fail")

if __name__ == "__main__":
    unittest.main()
