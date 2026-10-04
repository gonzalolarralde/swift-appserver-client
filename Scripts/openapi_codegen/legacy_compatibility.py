"""Retain removed Swift symbols without changing the upstream JSON Schema export."""

import copy
import json
from pathlib import Path
from typing import Any


def retain_legacy_symbols(document: dict[str, Any]) -> None:
    with Path(__file__).with_name("legacy-schemas.json").open(encoding="utf-8") as handle:
        legacy = json.load(handle)
    schemas = document["components"]["schemas"]
    added = set()
    for name, schema in legacy["components"].items():
        if name not in schemas:
            schemas[name] = copy.deepcopy(schema)
            added.add(name)
    for name, properties in legacy["properties"].items():
        if name in schemas:
            for key, schema in properties.items():
                schemas[name]["properties"].setdefault(key, copy.deepcopy(schema))
            schemas[name]["properties"] = dict(sorted(schemas[name]["properties"].items()))
    for name in legacy["clientRequestComponents"]:
        if name in added:
            method = schemas[name]["properties"]["method"]["enum"][0]
            reference = f"#/components/schemas/{name}"
            schemas["ClientRequest"]["oneOf"].append({"$ref": reference})
            schemas["ClientRequest"]["discriminator"]["mapping"][method] = reference
