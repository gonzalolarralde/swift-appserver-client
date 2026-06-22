from __future__ import annotations

import copy
import json
from pathlib import Path
from typing import Any
from urllib.parse import unquote

from openapi_codegen.common import pascal_case


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

# Set this to a set of schema names to constrain discriminator generation.
# DISCRIMINATED_UNION_SCHEMAS = {
#     "ClientRequest",
#     "ServerRequest",
#     "ServerNotification",
# }
DISCRIMINATED_UNION_SCHEMAS: set[str] | None = None


class Bundler:
    def __init__(self, template_path: Path) -> None:
        self.template_path = template_path.resolve()
        self.components: dict[str, Any] = {}
        self.documents: dict[Path, Any] = {}
        self.in_progress: set[tuple[Path, str]] = set()
        self.union_case_names: dict[tuple[str, int, str], str] = {}

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
        optionalized_properties: set[str] = set()
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
                output[key] = {}
                for item_key, item_value in child.items():
                    optionalized_schema = (
                        self.optionalized_nullable_property_schema(
                            item_value,
                            base_path=base_path,
                        )
                        if key == "properties"
                        else None
                    )
                    if optionalized_schema is not None:
                        output[key][item_key] = optionalized_schema
                        optionalized_properties.add(item_key)
                    else:
                        output[key][item_key] = self.normalize_schema(
                            item_value,
                            base_path=base_path,
                            suggested_name=item_key,
                        )
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

        self.remove_optionalized_properties_from_required(
            output,
            optionalized_properties,
        )
        return self.normalize_nullable(output)

    def optionalized_nullable_property_schema(
        self,
        schema: Any,
        *,
        base_path: Path,
    ) -> Any | None:
        non_null_schema = self.extract_complex_nullable_schema(schema)
        if non_null_schema is None:
            return None
        return self.normalize_schema(non_null_schema, base_path=base_path)

    def extract_complex_nullable_schema(self, schema: Any) -> Any | None:
        if not isinstance(schema, dict):
            return None

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
            non_null_schema = variants[1 - null_index]
            if self.is_complex_schema(non_null_schema):
                return non_null_schema

        schema_type = schema.get("type")
        if isinstance(schema_type, list) and "null" in schema_type:
            non_null_types = [item for item in schema_type if item != "null"]
            if len(non_null_types) == 1 and non_null_types[0] in {"array", "object"}:
                output = copy.deepcopy(schema)
                output["type"] = non_null_types[0]
                return output

        return None

    def is_complex_schema(self, schema: Any) -> bool:
        return isinstance(schema, dict) and (
            "$ref" in schema
            or schema.get("type") in {"array", "object"}
            or any(key in schema for key in ("allOf", "anyOf", "oneOf"))
        )

    def remove_optionalized_properties_from_required(
        self,
        schema: dict[str, Any],
        optionalized_properties: set[str],
    ) -> None:
        if not optionalized_properties:
            return
        required = schema.get("required")
        if not isinstance(required, list):
            return
        schema["required"] = [
            property_name
            for property_name in required
            if property_name not in optionalized_properties
        ]

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
            normalized = self.normalize_component_schema(
                name,
                schema,
                base_path=base_path,
            )
            if self.components[name] != normalized:
                raise ValueError(f"Conflicting schema definition for {name}")
            return
        if import_key in self.in_progress:
            return

        self.in_progress.add(import_key)
        normalized = self.normalize_component_schema(
            name,
            schema,
            base_path=base_path,
        )
        self.components[name] = normalized
        self.in_progress.remove(import_key)

    def normalize_component_schema(
        self,
        name: str,
        schema: Any,
        *,
        base_path: Path,
    ) -> Any:
        discriminator_key = self.discriminator_key_for_schema(name, schema)
        if discriminator_key is not None:
            return self.normalize_discriminated_union_schema(
                name,
                schema,
                discriminator_key=discriminator_key,
                base_path=base_path,
            )
        return self.normalize_schema(schema, base_path=base_path)

    def discriminator_key_for_schema(self, name: str, schema: Any) -> str | None:
        if DISCRIMINATED_UNION_SCHEMAS is not None and name not in DISCRIMINATED_UNION_SCHEMAS:
            return None
        if not isinstance(schema, dict) or not isinstance(schema.get("oneOf"), list):
            return None
        if len(schema["oneOf"]) < 2:
            return None

        tag_sets = [
            self.singleton_string_tags(variant)
            for variant in schema["oneOf"]
        ]
        if any(not tags for tags in tag_sets):
            if DISCRIMINATED_UNION_SCHEMAS is not None:
                raise ValueError(f"{name} does not have a usable discriminator tag")
            return None

        common_keys = set(tag_sets[0])
        for tags in tag_sets[1:]:
            common_keys &= set(tags)

        candidates = []
        for key in sorted(common_keys):
            values = [tags[key] for tags in tag_sets]
            if len(set(values)) == len(values):
                candidates.append(key)

        if not candidates:
            if DISCRIMINATED_UNION_SCHEMAS is not None:
                raise ValueError(f"{name} does not have unique discriminator values")
            return None
        return candidates[0]

    def singleton_string_tags(self, schema: Any) -> dict[str, str]:
        if not isinstance(schema, dict):
            return {}
        properties = schema.get("properties")
        if not isinstance(properties, dict):
            return {}

        tags: dict[str, str] = {}
        for property_name, property_schema in properties.items():
            if not isinstance(property_schema, dict):
                continue
            enum_values = property_schema.get("enum")
            if (
                isinstance(enum_values, list)
                and len(enum_values) == 1
                and isinstance(enum_values[0], str)
            ):
                tags[property_name] = enum_values[0]
                continue
            const_value = property_schema.get("const")
            if isinstance(const_value, str):
                tags[property_name] = const_value
        return tags

    def normalize_discriminated_union_schema(
        self,
        name: str,
        schema: Any,
        *,
        discriminator_key: str,
        base_path: Path,
    ) -> Any:
        if not isinstance(schema, dict) or not isinstance(schema.get("oneOf"), list):
            return self.normalize_schema(schema, base_path=base_path)

        output: dict[str, Any] = {}
        optionalized_properties: set[str] = set()
        for key, child in schema.items():
            if key in {"$schema", "definitions", "$defs", "oneOf", "discriminator"}:
                continue
            if key == "$ref" and isinstance(child, str):
                output[key] = self.rewrite_ref(child, base_path=base_path)
            elif key == "const":
                output["enum"] = [self.normalize_non_schema(child)]
            elif key in SCHEMA_MAP_KEYS:
                output[key] = {}
                for item_key, item_value in child.items():
                    optionalized_schema = (
                        self.optionalized_nullable_property_schema(
                            item_value,
                            base_path=base_path,
                        )
                        if key == "properties"
                        else None
                    )
                    if optionalized_schema is not None:
                        output[key][item_key] = optionalized_schema
                        optionalized_properties.add(item_key)
                    else:
                        output[key][item_key] = self.normalize_schema(
                            item_value,
                            base_path=base_path,
                            suggested_name=item_key,
                        )
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

        self.remove_optionalized_properties_from_required(
            output,
            optionalized_properties,
        )
        one_of: list[dict[str, str]] = []
        mapping: dict[str, str] = {}
        used_names: set[str] = set()
        for index, variant in enumerate(schema["oneOf"], start=1):
            discriminator_value = self.discriminator_value_for_variant(
                name,
                index,
                variant,
                discriminator_key=discriminator_key,
            )
            component_name = self.union_case_component_name(
                parent_name=name,
                variant=variant,
                discriminator_value=discriminator_value,
                index=index,
                used_names=used_names,
            )
            used_names.add(component_name)
            self.import_component(
                component_name,
                variant,
                base_path=base_path,
                source_key=f"#/components/schemas/{name}/oneOf/{index - 1}",
            )
            component_ref = f"#/components/schemas/{component_name}"
            one_of.append({"$ref": component_ref})
            mapping[discriminator_value] = component_ref

        output["oneOf"] = one_of
        output["discriminator"] = {
            "propertyName": discriminator_key,
            "mapping": mapping,
        }
        return self.normalize_nullable(output)

    def discriminator_value_for_variant(
        self,
        parent_name: str,
        index: int,
        variant: Any,
        *,
        discriminator_key: str,
    ) -> str:
        try:
            property_schema = variant["properties"][discriminator_key]
        except (KeyError, TypeError) as error:
            raise ValueError(
                f"{parent_name} oneOf case {index} is missing properties.{discriminator_key}"
            ) from error

        enum_values = property_schema.get("enum")
        if (
            isinstance(enum_values, list)
            and len(enum_values) == 1
            and isinstance(enum_values[0], str)
        ):
            return enum_values[0]
        const_value = property_schema.get("const")
        if isinstance(const_value, str):
            return const_value
        raise ValueError(
            f"{parent_name} oneOf case {index} must have exactly one string discriminator value"
        )

    def union_case_component_name(
        self,
        *,
        parent_name: str,
        variant: Any,
        discriminator_value: str,
        index: int,
        used_names: set[str],
    ) -> str:
        cache_key = (parent_name, index, discriminator_value)
        if cache_key in self.union_case_names:
            return self.union_case_names[cache_key]

        raw_name = variant.get("title") if isinstance(variant, dict) else None
        base_name = f"{parent_name}{pascal_case(raw_name or discriminator_value)}"
        component_name = base_name
        suffix = 2
        while component_name in self.components or component_name in used_names:
            component_name = f"{base_name}{suffix}"
            suffix += 1
        self.union_case_names[cache_key] = component_name
        return component_name

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
