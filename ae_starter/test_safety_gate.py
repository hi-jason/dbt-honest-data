"""Check safety refusals WITHOUT touching a database or running dbt."""
import os
import subprocess
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent


class SafetyGateTests(unittest.TestCase):
    def denied(self, adapter, **kwargs):
        env = {
            "PATH": os.environ.get("PATH", ""),
            "DBT": "/bin/true",  # Prevent any database tool invocation.
            "AE_STARTER_ADAPTER": adapter,
            "PGHOST": "localhost",
            "PGUSER": "synthetic_only",
            "PGDATABASE": "ae_quality_synthetic",
        }
        env.update(kwargs)
        run = subprocess.run(
            ["bash", str(ROOT / "run.sh")],
            cwd=ROOT, env=env,
            capture_output=True, text=True, timeout=10, check=False
        )
        self.assertEqual(run.returncode, 2, run.stderr)
        self.assertIn("REFUSED", run.stderr)

    def test_refuses_production_named_database(self):
        self.denied("postgres", PGDATABASE="real_production")

    def test_refuses_remote_postgres(self):
        self.denied("postgres", PGHOST="remote.example.invalid")

    def test_refuses_unknown_adapter(self):
        self.denied("some-warehouse")


if __name__ == "__main__":
    unittest.main()
