import unittest
from pathlib import Path

from openapi_codegen.schema_bundler import Bundler


class MultiTypeSchemaTests(unittest.TestCase):
    def test_disjoint_types_become_openapi_union(self):
        bundler = Bundler(Path(__file__))
        self.assertEqual(
            bundler.normalize_schema({"type": ["string", "object"]}, base_path=Path(__file__)),
            {"oneOf": [{"type": "string"}, {"type": "object"}]},
        )

    def test_nullability_survives_multi_type_normalization(self):
        bundler = Bundler(Path(__file__))
        self.assertEqual(
            bundler.normalize_schema({"type": ["string", "object", "null"]}, base_path=Path(__file__)),
            {"oneOf": [{"type": "string"}, {"type": "object"}], "nullable": True},
        )


if __name__ == "__main__":
    unittest.main()
