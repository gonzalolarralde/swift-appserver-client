import copy
import json
import unittest
from pathlib import Path

from legacy_compatibility import retain_legacy_symbols


class LegacyCompatibilityTests(unittest.TestCase):
    def setUp(self):
        self.legacy = json.loads(Path(__file__).with_name("legacy-schemas.json").read_text())
        self.document = {"components": {"schemas": {
            "ClientRequest": {"oneOf": [], "discriminator": {"mapping": {}}},
            "PluginSummary": {"properties": {"id": {"type": "string"}}},
            "ConfigRequirements": {"properties": {}},
        }}}

    def test_repeated_application_is_idempotent(self):
        retain_legacy_symbols(self.document)
        once = copy.deepcopy(self.document)
        retain_legacy_symbols(self.document)
        self.assertEqual(self.document, once)
        schemas = self.document["components"]["schemas"]
        self.assertEqual(schemas["ClientRequest"]["discriminator"]["mapping"], {
            "thread/rollback": "#/components/schemas/ClientRequestThreadRollbackRequest"
        })

    def test_reintroduced_upstream_symbols_are_never_overridden(self):
        current = {name: {"type": "object", "description": "Current upstream contract"}
                   for name in self.legacy["components"]}
        current["PluginSummary"] = {"properties": {"extensions": {"type": "string"}}}
        schemas = self.document["components"]["schemas"]
        schemas.update(copy.deepcopy(current))
        retain_legacy_symbols(self.document)
        self.assertEqual({name: schemas[name] for name in current}, current)
        self.assertEqual(schemas["ClientRequest"]["oneOf"], [])


if __name__ == "__main__":
    unittest.main()
