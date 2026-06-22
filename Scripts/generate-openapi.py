#!/usr/bin/env python3
"""Bundle the app-server JSON Schemas into a Swift OpenAPI Generator input.

Swift OpenAPI Generator does not currently support external $ref file
references, so the checked-in template stays small and this script expands it
into Sources/AppServerClient/openapi.json.
"""

from __future__ import annotations

import argparse
import copy
import json
from pathlib import Path
from typing import Any
from urllib.parse import unquote


REPO_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_TEMPLATE = REPO_ROOT / "Sources/AppServerClient/openapi.json.template"
DEFAULT_OUTPUT = REPO_ROOT / "Sources/AppServerClient/openapi.json"

SCHEMA_MAP_KEYS = {
    "$defs",
    "definitions",
    "dependentSchemas",
    "patternProperties",
    "properties",
}

SCHEMA_LIST_KEYS = {
    "allOf",
    "anyOf",
    "oneOf",
    "prefixItems",
}

SCHEMA_VALUE_KEYS = {
    "additionalItems",
    "contains",
    "else",
    "if",
    "items",
    "not",
    "propertyNames",
    "then",
    "unevaluatedItems",
    "unevaluatedProperties",
}


class Bundler:
    def __init__(self, template_path: Path) -> None:
        self.template_path = template_path.resolve()
        self.components: dict[str, Any] = {}
        self.documents: dict[Path, Any] = {}
        self.in_progress: set[tuple[Path, str]] = set()

    def bundle(self) -> dict[str, Any]:
        template = self.load_json(self.template_path)
        output = copy.deepcopy(template)
        output["openapi"] = "3.0.3"
        output.setdefault("components", {})["schemas"] = {}

        template_schemas = template.get("components", {}).get("schemas", {})
        for name, schema in template_schemas.items():
            output["components"]["schemas"][name] = self.normalize_schema(
                schema,
                base_path=self.template_path,
                suggested_name=name,
            )

        output["components"]["schemas"] = self.components
        return output

    def load_json(self, path: Path) -> Any:
        path = path.resolve()
        if path not in self.documents:
            with path.open(encoding="utf-8") as handle:
                self.documents[path] = json.load(handle)
        return self.documents[path]

    def normalize_schema(
        self,
        value: Any,
        *,
        base_path: Path,
        suggested_name: str | None = None,
    ) -> Any:
        if value is True:
            return {}
        if value is False:
            return {"not": {}}
        if isinstance(value, list):
            return [
                self.normalize_schema(item, base_path=base_path)
                for item in value
            ]
        if not isinstance(value, dict):
            return value

        if "$ref" in value and self.is_external_ref(value["$ref"]):
            imported_ref = self.import_external_ref(
                value["$ref"],
                base_path=base_path,
                suggested_name=suggested_name,
            )
            siblings = {
                key: child
                for key, child in value.items()
                if key not in {"$ref", "$schema", "definitions", "$defs"}
            }
            if not siblings:
                return {"$ref": imported_ref}
            normalized = {"$ref": imported_ref}
            normalized.update(
                self.normalize_schema(
                    siblings,
                    base_path=base_path,
                )
            )
            return self.normalize_nullable(normalized)

        output: dict[str, Any] = {}
        for key, child in value.items():
            if key in {"$schema", "definitions", "$defs"}:
                continue
            if key == "$ref" and isinstance(child, str):
                output[key] = self.rewrite_ref(
                    child,
                    base_path=base_path,
                    suggested_name=suggested_name,
                )
            elif key == "const":
                output["enum"] = [self.normalize_non_schema(child)]
            elif key in SCHEMA_MAP_KEYS:
                output[key] = {
                    item_key: self.normalize_schema(
                        item_value,
                        base_path=base_path,
                        suggested_name=item_key,
                    )
                    for item_key, item_value in child.items()
                }
            elif key in SCHEMA_LIST_KEYS:
                output[key] = [
                    self.normalize_schema(item, base_path=base_path)
                    for item in child
                ]
            elif key == "additionalProperties":
                output[key] = (
                    child
                    if isinstance(child, bool)
                    else self.normalize_schema(child, base_path=base_path)
                )
            elif key in SCHEMA_VALUE_KEYS:
                output[key] = self.normalize_schema(child, base_path=base_path)
            else:
                output[key] = self.normalize_non_schema(child)

        return self.normalize_nullable(output)

    def normalize_non_schema(self, value: Any) -> Any:
        if isinstance(value, list):
            return [self.normalize_non_schema(item) for item in value]
        if isinstance(value, dict):
            return {
                key: self.normalize_non_schema(child)
                for key, child in value.items()
            }
        return value

    def normalize_nullable(self, schema: dict[str, Any]) -> dict[str, Any]:
        schema_type = schema.get("type")
        if schema_type == "null":
            schema.pop("type")
            schema["nullable"] = True
        elif isinstance(schema_type, list) and "null" in schema_type:
            non_null_types = [item for item in schema_type if item != "null"]
            if len(non_null_types) == 1:
                schema["type"] = non_null_types[0]
                schema["nullable"] = True

        for key in ("anyOf", "oneOf"):
            variants = schema.get(key)
            if not isinstance(variants, list) or len(variants) != 2:
                continue
            null_index = next(
                (
                    index
                    for index, variant in enumerate(variants)
                    if isinstance(variant, dict)
                    and variant.get("type") == "null"
                    and len(variant) == 1
                ),
                None,
            )
            if null_index is None:
                continue
            non_null_variant = variants[1 - null_index]
            schema.pop(key)
            if isinstance(non_null_variant, dict):
                schema.update(non_null_variant)
            schema["nullable"] = True

        return schema

    def rewrite_ref(
        self,
        ref: str,
        *,
        base_path: Path,
        suggested_name: str | None = None,
    ) -> str:
        if ref.startswith("#/definitions/"):
            name = self.decode_pointer_token(ref.removeprefix("#/definitions/"))
            self.import_definition(name, base_path=base_path)
            return f"#/components/schemas/{name}"
        if ref.startswith("#/$defs/"):
            name = self.decode_pointer_token(ref.removeprefix("#/$defs/"))
            self.import_definition(name, base_path=base_path, container="$defs")
            return f"#/components/schemas/{name}"
        if self.is_external_ref(ref):
            return self.import_external_ref(
                ref,
                base_path=base_path,
                suggested_name=suggested_name,
            )
        return ref

    def is_external_ref(self, ref: Any) -> bool:
        return isinstance(ref, str) and not ref.startswith("#")

    def import_external_ref(
        self,
        ref: str,
        *,
        base_path: Path,
        suggested_name: str | None,
    ) -> str:
        ref_path, pointer = self.split_ref(ref)
        document_path = (base_path.parent / ref_path).resolve()
        document = self.load_json(document_path)
        schema = self.resolve_pointer(document, pointer)
        name = suggested_name or schema.get("title") or document_path.stem
        self.import_component(
            name,
            schema,
            base_path=document_path,
            source_key=pointer or "#",
        )
        return f"#/components/schemas/{name}"

    def import_definition(
        self,
        name: str,
        *,
        base_path: Path,
        container: str = "definitions",
    ) -> None:
        document = self.load_json(base_path)
        definitions = document.get(container, {})
        if name not in definitions:
            raise KeyError(f"{base_path}: missing {container}/{name}")
        self.import_component(
            name,
            definitions[name],
            base_path=base_path,
            source_key=f"#/{container}/{name}",
        )

    def import_component(
        self,
        name: str,
        schema: Any,
        *,
        base_path: Path,
        source_key: str,
    ) -> None:
        import_key = (base_path.resolve(), source_key)
        if name in self.components:
            normalized = self.normalize_schema(schema, base_path=base_path)
            if self.components[name] != normalized:
                raise ValueError(f"Conflicting schema definition for {name}")
            return
        if import_key in self.in_progress:
            return

        self.in_progress.add(import_key)
        normalized = self.normalize_schema(schema, base_path=base_path)
        self.components[name] = normalized
        self.in_progress.remove(import_key)

    def split_ref(self, ref: str) -> tuple[str, str]:
        path, separator, fragment = ref.partition("#")
        pointer = f"#{fragment}" if separator else "#"
        return unquote(path), pointer

    def resolve_pointer(self, document: Any, pointer: str) -> Any:
        if pointer in {"", "#"}:
            return document
        if not pointer.startswith("#/"):
            raise ValueError(f"Unsupported JSON pointer: {pointer}")

        value = document
        for raw_token in pointer.removeprefix("#/").split("/"):
            token = self.decode_pointer_token(raw_token)
            value = value[token]
        return value

    def decode_pointer_token(self, token: str) -> str:
        return unquote(token).replace("~1", "/").replace("~0", "~")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("template", nargs="?", type=Path, default=DEFAULT_TEMPLATE)
    parser.add_argument("output", nargs="?", type=Path, default=DEFAULT_OUTPUT)
    args = parser.parse_args()

    bundler = Bundler(args.template)
    output = bundler.bundle()
    args.output.write_text(json.dumps(output, indent=2) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
