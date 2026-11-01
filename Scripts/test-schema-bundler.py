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


class SharedUnionPropertyTests(unittest.TestCase):
    def test_common_properties_and_requirements_reach_each_tagged_object(self):
        bundler = Bundler(Path(__file__))
        schema = {
            "type": "object",
            "properties": {
                "threadId": {"type": "string"},
                "startedAtMs": {"type": ["integer", "null"], "format": "int64"},
            },
            "required": ["threadId"],
            "oneOf": [
                {"type": "object", "properties": {"type": {"enum": [tag], "type": "string"}},
                 "required": ["type"]}
                for tag in ("a", "b")
            ],
        }
        output = bundler.normalize_component_schema("Item", schema, base_path=Path(__file__))
        self.assertNotIn("properties", output)
        self.assertNotIn("required", output)
        for tag in ("a", "b"):
            self.assertEqual(bundler.components[f"Item{tag.upper()}"], {
                "type": "object",
                "properties": {
                    "type": {"enum": [tag], "type": "string"},
                    "threadId": {"type": "string"},
                    "startedAtMs": {"type": "integer", "format": "int64", "nullable": True},
                },
                "required": ["type", "threadId"],
            })

    def test_conflicting_shared_fields_are_not_silently_overwritten(self):
        bundler = Bundler(Path(__file__))
        schema = {
            "properties": {"id": {"type": "string"}},
            "oneOf": [
                {"properties": {"type": {"const": "a"}, "id": {"type": "integer"}}},
                {"properties": {"type": {"const": "b"}}},
            ],
        }
        with self.assertRaisesRegex(ValueError, "conflicting shared property id"):
            bundler.normalize_component_schema("Item", schema, base_path=Path(__file__))


if __name__ == "__main__":
    unittest.main()
