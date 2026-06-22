from __future__ import annotations

import re
from dataclasses import dataclass


@dataclass(frozen=True)
class UnionCase:
    case_name: str
    alias_name: str
    component_name: str
    params_type: str
    properties: tuple[str, ...]


@dataclass(frozen=True)
class UnionMapping:
    schema_name: str
    protocol_name: str
    accessor_name: str
    build_return_type: str
    cases: tuple[UnionCase, ...]
    has_id: bool


def pascal_case(value: str) -> str:
    parts = [part for part in re.split(r"[^0-9A-Za-z]+", value) if part]
    name = "".join(part[:1].upper() + part[1:] for part in parts)
    return name or "Case"
