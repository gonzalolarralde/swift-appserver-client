# Swift AppServer Client repository instructions

This package mirrors the experimental public `codex app-server` contract.
Follow [UPGRADE.md](UPGRADE.md) for every compatibility release.

## Compatibility invariants

- This repository intentionally publishes parity releases for stable, public
  Codex GitHub Releases only. Prereleases and the earlier
  `rust-v0.143.0-alpha.10-ios` Swift tag are outside this stable parity series.
  The first stable parity baseline is Codex `rust-v0.144.1`, published here as
  Swift tag `0.144.1`.
- A Swift release version must equal its Codex base version after removing the
  `rust-v` prefix.
- Export the contract directly from an exact stable public Codex tag. Do not
  export from the downstream iOS patch stack, a moving branch, a prerelease
  tag, or a dirty checkout. Validate the maintained iOS branch separately when
  useful, and never use that validation checkout as schema input.
- Keep `Package.resolved` unchanged during a protocol upgrade. Dependency
  upgrades are separate changes.
- Treat published tags as immutable. Never force-push `main` or move an
  existing release tag.

## Generated and hand-written files

The following are generated and must not be edited by hand:

- `Sources/AppServerClient/JSONSchema/`
- `Sources/AppServerClient/openapi.json`
- `Sources/AppServerClient/Models/DataModelMapping.swift`

Generate them by exporting the experimental JSON Schema from the matching exact
public Codex tag, synchronizing `JSONSchema/`, and running:

```sh
python3 Scripts/generate-openapi.py
```

If generation or compilation fails, fix the generator or the narrow
hand-written compatibility layer. Common repair points are:

- `Scripts/openapi_codegen/swift_mapping.py` for request/response names that
  cannot be inferred;
- `Sources/AppServerClient/Models/TypeOverrides/` for schema shapes that need a
  stable Swift representation;
- exhaustive switches in the smoke CLI or tests when a generated union gains a
  case.

When changing the compatibility version, update every tracked version
reference. At minimum, check:

- `README.md`;
- `Sources/AppServerClient/openapi.json.template`;
- the default `ClientInfo.version` in
  `Sources/AppServerClient/AppServerClient.swift`;
- version-specific comments in hand-written overrides.

Use `rg` to confirm that the previous version no longer appears where it
describes current compatibility.

## Required verification

Run from the repository root:

```sh
python3 Scripts/generate-openapi.py
swift build --target AppServerClient
swift test
git diff --check
git diff --exit-code -- Package.resolved
```

Also run `swift run appserver-smoke` with the binary built from the exact public
Codex tag first on `PATH`. The smoke CLI always covers initialize, account,
usage, and thread-list calls; it covers turn-list calls only when the selected
Codex home contains a thread. Do not claim turn coverage unless the output
shows it. Review every generated diff, especially removed RPCs, renamed fields,
optionality changes, discriminator changes, and integer-width changes.

An optional build or integration test of the maintained iOS branch is separate
downstream evidence. Record its exact commit and results, but do not substitute
it for public-tag generation or smoke verification.

## Release discipline

- Keep one reviewed commit per stable Codex version, even when regeneration is
  byte-for-byte identical apart from version metadata.
- Update `CHANGELOG.md` with the Codex tag and peeled commit, contract changes,
  Swift compatibility fixes, and verification. Record an iOS branch commit
  only when separate optional downstream validation was actually performed.
- Use an annotated Swift tag named only with the version, for example
  `0.152.0`.
- Push the reviewed commit before its tag, then create the GitHub release from
  that existing tag. Do not let release tooling create an unreviewed tag.
