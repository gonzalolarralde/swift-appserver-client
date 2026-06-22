#!/usr/bin/env python3
"""Generate OpenAPI and Swift mapping files from app-server JSON Schemas."""

from __future__ import annotations

import argparse
import json
from pathlib import Path

from openapi_codegen.schema_bundler import Bundler
from openapi_codegen.swift_mapping import SwiftMappingGenerator


REPO_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_TEMPLATE = REPO_ROOT / "Sources/AppServerClient/openapi.json.template"
DEFAULT_OUTPUT = REPO_ROOT / "Sources/AppServerClient/openapi.json"
DEFAULT_MAPPING_OUTPUT = REPO_ROOT / "Sources/AppServerClient/DataModelMapping.swift"


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("template", nargs="?", type=Path, default=DEFAULT_TEMPLATE)
    parser.add_argument("output", nargs="?", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument("--mapping-output", type=Path, default=DEFAULT_MAPPING_OUTPUT)
    parser.add_argument("--no-mapping", action="store_true")
    args = parser.parse_args()

    bundler = Bundler(args.template)
    output = bundler.bundle()
    args.output.write_text(json.dumps(output, indent=2) + "\n", encoding="utf-8")

    if not args.no_mapping:
        mapping = SwiftMappingGenerator(output).generate()
        args.mapping_output.write_text(mapping, encoding="utf-8")


if __name__ == "__main__":
    main()
