# Changelog

## 0.144.5 — 2026-07-16

- Schema provenance: regenerated and synchronized the exact experimental
  (`--experimental`) export from stable public Codex tag `rust-v0.144.5`,
  peeled commit
  `87db9bc18ba5bc82c1cb4e4381b44f693ee35623`.
- Contract: no public contract change from 0.144.4. Canonical comparison of all
  337 JSON Schema files found no additions, removals, or semantic changes.
- Swift compatibility: advanced package metadata, the default client version,
  and version-specific documentation to 0.144.5. No generator, override, or
  call-site fixes were required.
- Verification: the generator was idempotent; `swift build --target
  AppServerClient`, all 13 `swift test` cases, `git diff --check`, and the
  `Package.resolved` unchanged check passed. The exact public
  `@openai/codex@0.144.5` CLI identified itself as `codex-cli 0.144.5`, but the
  smoke gate stopped at `thread/list` with JSON-RPC `-32601` (`paginated_threads
  is not supported yet`); the basic gate therefore did not pass and no smoke
  call coverage is claimed.

## 0.144.4 — 2026-07-14

- Schema provenance: regenerated and synchronized the exact experimental
  (`--experimental`) export from stable public Codex tag `rust-v0.144.4`,
  peeled commit
  `8c68d4c87dc54d38861f5114e920c3de2efa5876`.
- Contract: no public contract change from 0.144.3. Canonical comparison of all
  337 JSON Schema files found no additions, removals, or semantic changes.
- Swift compatibility: advanced package metadata, the default client version,
  and version-specific documentation to 0.144.4. No generator, override, or
  call-site fixes were required.
- Verification: the generator was idempotent; `swift build --target
  AppServerClient`, all 13 `swift test` cases, `git diff --check`, and the
  `Package.resolved` unchanged check passed. The exact public
  `@openai/codex@0.144.4` CLI identified itself as `codex-cli 0.144.4`, but the
  smoke gate stopped at `thread/list` with JSON-RPC `-32601` (`paginated_threads
  is not supported yet`); the basic gate therefore did not pass and no smoke
  call coverage is claimed.

## 0.144.3 — 2026-07-13

- Schema provenance: regenerated and synchronized the exact experimental
  (`--experimental`) export from stable public Codex tag `rust-v0.144.3`,
  peeled commit
  `78ad6e6bfd1d3b6a209acd3ef82172a96b25179c`.
- Contract: no public contract change from 0.144.2. Canonical comparison of all
  337 JSON Schema files found no additions, removals, or semantic changes.
- Swift compatibility: advanced package metadata, the default client version,
  and version-specific documentation to 0.144.3. No generator, override, or
  call-site fixes were required.
- Verification: the generator was idempotent; `swift build --target
  AppServerClient`, all 13 `swift test` cases, `git diff --check`, and the
  `Package.resolved` unchanged check passed. The exact public
  `@openai/codex@0.144.3` CLI identified itself as `codex-cli 0.144.3`, but the
  smoke gate stopped at `thread/list` with JSON-RPC `-32601` (`paginated_threads
  is not supported yet`); the basic gate therefore did not pass and no smoke
  call coverage is claimed.

## 0.144.2 — 2026-07-13

- Schema provenance: regenerated and synchronized the exact experimental
  (`--experimental`) export from stable public Codex tag `rust-v0.144.2`,
  peeled commit
  `a6645b6b8a656360fa16fb7e1c6721d0697d3d6a`.
- Contract: no public contract change from 0.144.1. Canonical comparison of all
  337 JSON Schema files found no additions, removals, or semantic changes.
- Swift compatibility: advanced package metadata, the default client version,
  and version-specific documentation to 0.144.2. No generator, override, or
  call-site fixes were required. The README now identifies the stable public
  Codex tag as schema provenance and no longer attributes the schema to the
  downstream iOS branch.
- Verification: the generator was idempotent; `swift build --target
  AppServerClient`, all 13 `swift test` cases, `git diff --check`, and the
  `Package.resolved` unchanged check passed. The exact public
  `@openai/codex@0.144.2` CLI identified itself as `codex-cli 0.144.2`, but the
  smoke gate stopped at `thread/list` with JSON-RPC `-32601` (`paginated_threads
  is not supported yet`); the basic gate therefore did not pass and no smoke
  call coverage is claimed.
