#!/usr/bin/env python3
"""Verify a CLI export byte-for-byte against an exact tag's schema bundle."""

import argparse
import json
from pathlib import Path
import subprocess


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("codex_worktree", type=Path)
    parser.add_argument("schema_output", type=Path)
    args = parser.parse_args()
    if subprocess.check_output(
        ["git", "-C", str(args.codex_worktree), "status", "--porcelain"], text=True
    ).strip():
        parser.error("Codex worktree must be clean")
    archive = args.codex_worktree / "codex-rs/app-server-protocol/schema/precomputed/app-server-exports-experimental.json.zst"
    bundle = json.loads(subprocess.check_output(["zstd", "-dc", str(archive)]))
    expected = bundle["json_schema"]
    actual = {
        path.relative_to(args.schema_output).as_posix(): path.read_bytes()
        for path in args.schema_output.rglob("*") if path.is_file()
    }
    if set(expected) != set(actual):
        parser.error(f"Export file set differs: missing={sorted(set(expected) - set(actual))}, extra={sorted(set(actual) - set(expected))}")
    changed = [name for name, content in expected.items() if content.encode("utf-8") != actual[name]]
    if changed:
        parser.error(f"Export contents differ: {changed}")
    print(f"Verified all {len(expected)} files against the exact source bundle.")


if __name__ == "__main__":
    main()
