# Changelog

## 0.148.0 — 2026-08-18

- Schema provenance: regenerated and synchronized the exact experimental
  (`--experimental`) export from stable public Codex tag `rust-v0.148.0`,
  peeled commit
  `3ba0f711642a888aec92a611a3f3b2211157ff89`.
- Contract: the export grows from 361 to 380 JSON Schema files, with 19
  additions, no removals, and 42 modified existing files. It adds server
  diagnostics, thread queue management, and thread revert RPCs, plus queue
  change and thread-reverted notifications. Existing account usage reads can
  now accept optional parameters. Discriminated unions gain packaged-default
  config layers, MCP-tool hook handlers, misalignment policy errors, and
  persistent MCP policy approval.
- Swift compatibility: updated the smoke client to pass an explicit empty
  optional params value to `account/usage/read`, matching its new typed
  optional params contract.
- Verification: the generator was idempotent; `swift build --target
  AppServerClient`, all 14 `swift test` cases, `git diff --check`, and the
  `Package.resolved` unchanged check passed. `swift run appserver-smoke`
  passed initialize, account, usage, and empty thread-list calls against the
  exact public `@openai/codex@0.148.0` CLI in an isolated authenticated Codex
  home; no turn-list coverage is claimed because that home had no threads.

## 0.147.0 — 2026-08-07

- Schema provenance: regenerated and synchronized the exact experimental
  (`--experimental`) export from stable public Codex tag `rust-v0.147.0`,
  peeled commit
  `be6e8eac029b183056b7e4402879f15d2c85f61b`.
- Contract: the export grows from 349 to 361 JSON Schema files, with 12
  additions, no removals, and 48 modified existing files. It adds plugin search
  and thread-section create, delete, list, move, and update RPCs. Thread
  sections replace the short-lived pinning fields and add section-position
  sorting. Tool user-input requests also gain a required `isBlocking` field.
- Swift compatibility: no additional hand-written compatibility fix was
  required.
- Verification: the generator was idempotent; `swift build --target
  AppServerClient`, all 14 `swift test` cases, `git diff --check`, and the
  `Package.resolved` unchanged check passed. `swift run appserver-smoke`
  passed initialize, account, usage, and empty thread-list calls against the
  exact public `@openai/codex@0.147.0` CLI in an isolated authenticated Codex
  home; no turn-list coverage is claimed because that home had no threads.

## 0.146.1 — 2026-08-05

- Schema provenance: regenerated and synchronized the exact experimental
  (`--experimental`) export from stable public Codex tag `rust-v0.146.1`,
  peeled commit
  `79b4f03d35962b005b007a015113b38930711665`.
- Contract: the export remains at 349 JSON Schema files, with no additions or
  removals and 3 modified files. The only semantic change is a nullable
  `modelSpecialty` field on `Model`, propagated through `ModelListResponse` and
  the aggregate schema bundles.
- Swift compatibility: no additional hand-written compatibility fix was
  required.
- Verification: the generator was idempotent; `swift build --target
  AppServerClient`, all 14 `swift test` cases, `git diff --check`, and the
  `Package.resolved` unchanged check passed. `swift run appserver-smoke`
  passed initialize, account, usage, and empty thread-list calls against the
  exact public `@openai/codex@0.146.1` CLI in an isolated authenticated Codex
  home; no turn-list coverage is claimed because that home had no threads.

## 0.146.0 — 2026-07-29

- Schema provenance: regenerated and synchronized the exact experimental
  (`--experimental`) export from stable public Codex tag `rust-v0.146.0`,
  peeled commit
  `e363b08c9175ac1cbe5893615dd2cb9ddf95043b`.
- Contract: the export grows from 347 to 349 JSON Schema files, with 2
  additions, no removals, and 44 modified existing files. It adds the
  `externalAgentConfig/import/recordHistory` RPC, thread pinning fields and
  filters, external-agent import attribution and detection bounds, and the
  `ent26` plan type.
- Swift compatibility: added an
  `ExternalAgentConfigImportHistoryRecordResponse` response override for the
  new RPC and extended the response-type compile check.
- Verification: the generator was idempotent; `swift build --target
  AppServerClient`, all 14 `swift test` cases, `git diff --check`, and the
  `Package.resolved` unchanged check passed. `swift run appserver-smoke`
  passed initialize, account, usage, and empty thread-list calls against the
  exact public `@openai/codex@0.146.0` CLI in an isolated authenticated Codex
  home; no turn-list coverage is claimed because that home had no threads.

## 0.145.0 — 2026-07-21

- Schema provenance: regenerated and synchronized the exact experimental
  (`--experimental`) export from stable public Codex tag `rust-v0.145.0`,
  peeled commit
  `25af12f7e61572b0bc18ddb1008be543b91519b0`.
- Contract: the export grows from 337 to 347 JSON Schema files, with 10
  additions, no removals, and 61 modified existing files. New RPCs cover
  installed-app reads, app metadata reads, environment status, and thread
  search occurrences; new notifications report environment connection state.
  The contract also adds audio input/output union cases and Amazon Bedrock
  login cases. Notably, the denied review decision changes from a string case
  to an object containing a rejection reason.
- Swift compatibility: added response overrides for `AppsReadResponse` and
  `AppsInstalledResponse` so the new request/response pairs generate and
  compile correctly.
- Verification: the generator was idempotent; `swift build --target
  AppServerClient`, all 14 `swift test` cases, `git diff --check`, and the
  `Package.resolved` unchanged check passed. `swift run appserver-smoke`
  passed initialize, account, usage, and empty thread-list calls against the
  exact public `@openai/codex@0.145.0` CLI in an isolated authenticated Codex
  home; no turn-list coverage is claimed because that home had no threads.

## 0.144.6 — 2026-07-18

- Schema provenance: regenerated and synchronized the exact experimental
  (`--experimental`) export from stable public Codex tag `rust-v0.144.6`,
  peeled commit
  `5d1fbf26c43abc65a203928b2e31561cb039e06d`.
- Contract: no public contract change from 0.144.5. Canonical comparison of all
  337 JSON Schema files found no additions, removals, or semantic changes.
- Swift compatibility: advanced package metadata, the default client version,
  and version-specific documentation to 0.144.6. No generator, override, or
  call-site fixes were required.
- Verification: the generator was idempotent; `swift build --target
  AppServerClient`, all 13 `swift test` cases, `git diff --check`, and the
  `Package.resolved` unchanged check passed. The exact public
  `@openai/codex@0.144.6` CLI identified itself as `codex-cli 0.144.6`, but the
  smoke gate stopped at `thread/list` with JSON-RPC `-32601` (`paginated_threads
  is not supported yet`); the basic gate therefore did not pass and no smoke
  call coverage is claimed.

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
