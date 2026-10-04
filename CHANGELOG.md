# Changelog

## 0.159.0 — 2026-10-04

- Schema provenance: official `@openai/codex@0.159.0` experimental export,
  verified byte-for-byte against all 440 files in the clean stable public
  `rust-v0.159.0` source bundle at peeled commit
  `687a119f0fcaace47e1f1abcc77cec6c813fd6da`.
- Contract: `thread/items/list` cursors now accept an opaque string or a tagged
  item anchor. Adds optional MCP server-name filtering and the
  `tooManyDenials` error value. No RPCs, schema files, or definitions were
  removed; opaque string cursors remain valid on the wire.
- Swift compatibility: the item cursor parameter now takes a generated
  `ThreadItemsListCursor`, a source-level change for callers passing strings
  directly. Use `.init(value1: cursorString)` for an opaque cursor or
  `.init(value2: .init(itemId: itemID, _type: .item))` for an anchor.
  Added a serialization/decode regression test covering both complete request
  payloads. No generator or handwritten model repair was required.
- Verification: idempotent generation, `swift build --target AppServerClient`,
  all 17 `swift test` cases, `git diff --check`, and unchanged
  `Package.resolved` passed. Initialize, account, usage, and empty thread-list
  smoke calls passed against the exact official CLI using an isolated
  authenticated home; the copied credential was removed afterward.
  No turn-list or downstream iOS coverage is claimed.

## 0.158.0 — 2026-10-04

- Schema provenance: official `@openai/codex@0.158.0` experimental export,
  verified byte-for-byte against all 440 files in the clean stable public
  `rust-v0.158.0` source bundle at peeled commit
  `064c6b8c737f5b41d171fdda80bd9ef10ad06eb3`.
- Contract: removes `PluginSummary.extensions` and the eight plugin-extension
  schema definitions introduced in 0.157.0, including their generated Swift
  models. Adds optional `EnvironmentAddParams.authBearerToken` for secure or
  loopback executor connections, `PlanType.promax`, and the
  `flexUnavailable` error value. No RPCs or exported schema files were removed.
- Swift compatibility: regenerated the breaking plugin-model removal and new
  authentication/error/plan fields. Existing source compiles without additional
  handwritten compatibility fixes; gateway OAuth mappings remain covered.
- Verification: idempotent generation, `swift build --target AppServerClient`,
  all 16 `swift test` cases, `git diff --check`, and unchanged
  `Package.resolved` passed. Initialize, account, usage, and empty thread-list
  smoke calls passed against the exact official CLI using an isolated
  authenticated home; the copied credential was removed afterward.
  No turn-list or downstream iOS coverage is claimed.

## 0.157.1 — 2026-10-04

- Schema provenance: official `@openai/codex@0.157.1` experimental export,
  verified byte-for-byte against all 440 files in the clean stable public
  `rust-v0.157.1` source bundle at peeled commit
  `36650394c5b38c2990ccf2a3457165ca3e9d9726`.
- Contract: no public contract change from 0.157.0; all schema files and
  generated request mappings are unchanged. The official upstream patch release
  does not identify additional release highlights.
- Swift compatibility: updated version metadata, retaining the tested gateway
  OAuth response mappings; no new compatibility fixes.
- Verification: idempotent generation, `swift build --target AppServerClient`,
  all 16 `swift test` cases, `git diff --check`, and unchanged
  `Package.resolved` passed. Initialize, account, usage, and empty thread-list
  smoke calls passed against the exact official CLI using an isolated
  authenticated home; the copied credential was removed afterward.
  No turn-list or downstream iOS coverage is claimed.

## 0.157.0 — 2026-10-04

- Schema provenance: official `@openai/codex@0.157.0` experimental export,
  verified byte-for-byte against all 440 files in the clean stable public
  `rust-v0.157.0` source bundle at peeled commit
  `00c972ed5d6ff6499317fd41b7f23605b8e6850d`.
- Contract: adds `account/gatewayOAuth/read`, `login`, and `cancel` RPCs
  plus `account/gatewayOAuth/changed`; initialization gains
  `explicitGatewayOauth`. Adds optional MCP resource targets (with required,
  nullable link IDs), MCP HTTP origins, structured plugin extensions and
  entrypoints, int64 item start/completion timestamps, and realtime backend
  reasoning status. No existing RPCs, schema files, or wire fields were removed.
- Swift compatibility: adds narrow generator response mappings for the three
  gateway OAuth RPCs and compile-time regression coverage in the response-type
  test. Regenerated null-parameter request support and all new models; existing
  handwritten wire overrides remain unchanged.
- Verification: idempotent generation, `swift build --target AppServerClient`,
  all 16 `swift test` cases, `git diff --check`, and unchanged
  `Package.resolved` passed. Initialize, account, usage, and empty thread-list
  smoke calls passed against the exact official CLI using an isolated
  authenticated home; the copied credential was removed afterward.
  No turn-list or downstream iOS coverage is claimed.

## 0.156.1 — 2026-10-04

- Schema provenance: official `@openai/codex@0.156.1` experimental export,
  verified byte-for-byte against all 436 files in the clean stable public
  `rust-v0.156.1` source bundle at peeled commit
  `b412ff32c417f855c2b2d1581b77058eed87c84b`.
- Contract: no public contract change from 0.156.0; all schema files and
  generated request mappings are unchanged. Upstream updates its model catalog
  and rate-limit recommendations; these do not alter the exported API shape.
- Swift compatibility: updated version metadata; no new compatibility fixes.
- Verification: idempotent generation, `swift build --target AppServerClient`,
  all 16 `swift test` cases, `git diff --check`, and unchanged
  `Package.resolved` passed. Initialize, account, usage, and empty thread-list
  smoke calls passed against the exact official CLI using an isolated
  authenticated home; the copied credential was removed afterward.
  No turn-list or downstream iOS coverage is claimed.

## 0.156.0 — 2026-10-04

- Schema provenance: official `@openai/codex@0.156.0` experimental export,
  verified byte-for-byte against all 436 files in the clean stable public
  `rust-v0.156.0` source bundle at peeled commit
  `fe74a774532af67b5a4a3dec03ce9469e17f89af`.
- Contract: removes `thread/rollback` and its request/response models;
  `thread/revert` remains available. Adds `rollout/compress`, file-ID image
  inputs alongside URL inputs, disabled plugin IDs, resume collaboration mode,
  workspace account routing, managed login/provider requirements, program
  access controls, MCP app UI/capabilities, verification enrollment keys,
  elicitation metadata, and plugin onboarding skills.
  Removes `windowsSandboxPrivateDesktop` from requirements; sandbox
  implementations now use `WindowsSandboxImplementation`, adding `mxc`.
- Swift compatibility: regenerated models and request mappings, including the
  breaking rollback removal and image-union constructors. Existing URL wire
  forms remain valid, and the handwritten local-image input builder is
  unchanged and tested. No generator or override repairs were needed.
- Verification: idempotent generation, `swift build --target AppServerClient`,
  all 16 `swift test` cases, `git diff --check`, and unchanged
  `Package.resolved` passed. Initialize, account, usage, and empty thread-list
  smoke calls passed against the exact official CLI using an isolated
  authenticated home; the copied credential was removed afterward.
  No turn-list or downstream iOS coverage is claimed.

## 0.155.1 — 2026-10-04

- Schema provenance: official `@openai/codex@0.155.1` experimental export,
  verified byte-for-byte against all 437 files in the clean stable public
  `rust-v0.155.1` source bundle at peeled commit
  `be2951ea34f0d295ed0becf97079f92fa5f6950e`.
- Contract: no public contract change from 0.155.0; all schema files and
  generated request mappings are unchanged. Upstream restores the TUI's
  default reasoning summary to none for providers that do not support it.
- Swift compatibility: updated version metadata; no new compatibility fixes.
- Verification: idempotent generation, `swift build --target AppServerClient`,
  all 16 `swift test` cases, `git diff --check`, and unchanged
  `Package.resolved` passed. Initialize, account, usage, and empty thread-list
  smoke calls passed against the exact official CLI using an isolated
  authenticated home; the copied credential was removed afterward.
  No turn-list or downstream iOS coverage is claimed.

## 0.155.0 — 2026-10-04

- Schema provenance: official `@openai/codex@0.155.0` experimental export,
  verified byte-for-byte against all 437 files in the clean stable public
  `rust-v0.155.0` source bundle at peeled commit
  `f0a1b8f0849d90960bc406b848f32e5a129b0457`.
- Contract: adds `memory/status`, `thread/attachment/add`,
  `thread/attachment/list`, `thread/attachment/remove`,
  `thread/attachment/updated`, and `userVerification/cancel`.
  Feedback uploads gain an optional prompt hash. Eleven schema files were added;
  no files or RPCs were removed, and existing wire fields retain their names
  and types. Upstream also introduces experimental voice conversations and
  native MCP verification on supported builds.
- Swift compatibility: regenerated the request/response mappings and models,
  retaining the tested MCP verification-mode override from 0.154.0.
  No new generator or handwritten type repairs were needed.
- Verification: idempotent generation, `swift build --target AppServerClient`,
  all 16 `swift test` cases, `git diff --check`, and unchanged
  `Package.resolved` passed. Initialize, account, usage, and empty thread-list
  smoke calls passed against the exact official CLI in an isolated authenticated
  home; the copied credential was removed afterward. No turn-list or downstream
  iOS coverage is claimed.

## 0.154.0 — 2026-10-04

- Schema provenance: official `@openai/codex@0.154.0` experimental export,
  verified byte-for-byte against all 426 files in the clean stable public
  `rust-v0.154.0` source bundle at peeled commit
  `6b9826e3aa83b1a5947db50f4332cb9c65f1b340`.
- Contract: adds the four `userVerification/*` RPCs and the
  `openai/userVerification` MCP elicitation mode, typed optional
  `account/rateLimits/read` parameters, application network requirements,
  browser WebMCP requirements, thread environments/originator/Daybreak metadata,
  ordinary-usage eligibility, quota model aliases, MCP discovery errors, and
  durable reasoning configuration items. Detached reviews are deprecated.
  No schema files or RPCs were removed. Approval paths retain their string
  wire representation while accepting target-native paths.
- Swift compatibility: extends the handwritten MCP elicitation override with
  the user-verification case and tests its full wire round trip.
  `AccountRateLimitsRead.Params` is now `GetAccountRateLimitsParams?`;
  exhaustive MCP-mode switches must handle `userVerification`.
- Verification: generation, `swift build --target AppServerClient`, all
  16 `swift test` cases, `git diff --check`, and unchanged `Package.resolved`
  passed. Initialize, account, usage, and empty thread-list smoke calls passed
  against the exact official CLI in an isolated authenticated home; the copied
  credential was removed afterward. No turn-list or downstream iOS coverage
  is claimed.

## 0.153.4 — 2026-09-07

- Schema provenance: official `@openai/codex@0.153.4` experimental export,
  byte-for-byte verified against the clean stable public `rust-v0.153.4`
  source bundle at peeled commit
  `3d2ee51ca2d5db578f328aa75e20aa22c0197c9a`.
- Contract: no public contract change from 0.153.3; all 416 schema files and
  generated request mappings are unchanged. Upstream updates Astra's bundled default and picker visibility and makes asynchronous-question guidance conditional on tool availability.
- Swift compatibility: updated version metadata; no compatibility fixes needed.
- Verification: idempotent generation, `swift build --target AppServerClient`,
  all 15 `swift test` cases, `git diff --check`, and unchanged `Package.resolved`
  passed. Initialize, account, usage, and empty thread-list smoke calls passed
  against the exact official CLI using an isolated authenticated home, removed
  afterward. No turn-list or downstream iOS coverage is claimed.

## 0.153.3 — 2026-09-07

- Schema provenance: official `@openai/codex@0.153.3` experimental export,
  byte-for-byte verified against the clean stable public `rust-v0.153.3`
  source bundle at peeled commit
  `b1a547b1f73ce86205d9222ac19cff334b3b7a2e`.
- Contract: no public contract change from 0.153.2; all 416 schema files and
  generated request mappings are unchanged. Upstream adds GPT-6-Astra to Bedrock catalogs and corrects asynchronous-question guidance.
- Swift compatibility: updated version metadata; no compatibility fixes needed.
- Verification: idempotent generation, `swift build --target AppServerClient`,
  all 15 `swift test` cases, `git diff --check`, and unchanged `Package.resolved`
  passed. Initialize, account, usage, and empty thread-list smoke calls passed
  against the exact official CLI using an isolated authenticated home, removed
  afterward. No turn-list or downstream iOS coverage is claimed.

## 0.153.2 — 2026-09-07

- Schema provenance: official `@openai/codex@0.153.2` experimental export,
  byte-for-byte verified against the clean stable public `rust-v0.153.2`
  source bundle at peeled commit
  `657a993cbee87acf52d14b758ce49dbd46d1b8eb`.
- Contract: no public contract change from 0.153.1; all 416 schema files and
  generated request mappings are unchanged. Upstream corrects the GPT-6-Astra Fast tier description; request execution is unchanged.
- Swift compatibility: updated version metadata; no compatibility fixes needed.
- Verification: idempotent generation, `swift build --target AppServerClient`,
  all 15 `swift test` cases, `git diff --check`, and unchanged `Package.resolved`
  passed. Initialize, account, usage, and empty thread-list smoke calls passed
  against the exact official CLI using an isolated authenticated home, removed
  afterward. No turn-list or downstream iOS coverage is claimed.

## 0.153.1 — 2026-09-07

- Schema provenance: official `@openai/codex@0.153.1` experimental export,
  byte-for-byte verified against the clean stable public `rust-v0.153.1`
  source bundle at peeled commit
  `985641272869835d01d025ed2a218fbbce35fa9f`.
- Contract: no public contract change from 0.153.0; all 416 schema files and
  generated request mappings are unchanged. Upstream adds API configuration
  support for GPT-6-Astra without changing the default or picker visibility.
- Swift compatibility: updated version metadata; no compatibility fixes needed.
- Verification: idempotent generation, `swift build --target AppServerClient`,
  all 15 `swift test` cases, `git diff --check`, and unchanged `Package.resolved`
  passed. Initialize, account, usage, and empty thread-list smoke calls passed
  against the exact official CLI using an isolated authenticated home, removed
  afterward. No turn-list or downstream iOS coverage is claimed.

## 0.153.0 — 2026-09-07

- Schema provenance: experimental export from official `@openai/codex@0.153.0`,
  verified byte-for-byte against all 416 files in the clean stable public tag
  `rust-v0.153.0` at peeled commit
  `41e22fee981a63b3698df7ed36bad393cda24715`. The tag's exporter
  uses this precomputed experimental bundle.
- Contract: adds `plugin/reconcile`, thread model and reasoning-effort
  metadata, asynchronous questions on agent messages, per-account app approval
  settings, raw-response usage metadata, and active-turn approval-reviewer
  updates. Two schema files were added and 28 existing files changed, with no
  removed files or RPCs. Existing fields retain their wire names and types.
- Swift compatibility: regenerated the request mapping and models and updated
  compatibility metadata. No generator or hand-written type repair was needed.
  Added a source-bundle export verifier and documented the equivalent export
  route and user-approved isolated release workflow.
- Verification: idempotent generation, `swift build --target AppServerClient`,
  all 15 `swift test` cases, `git diff --check`, and unchanged `Package.resolved`
  passed. Basic smoke passed initialize, account, usage, and empty thread-list
  calls against the exact official CLI in an isolated authenticated home,
  removed afterward. No turn-list or downstream iOS coverage is claimed.

## 0.152.1 — 2026-09-07

- Schema provenance: experimental export from stable public Codex tag
  `rust-v0.152.1`, peeled commit
  `5adb68a49933ae446bf11935662c83dba55a0804`. Built the exact tag's CLI,
  restored Cargo's workspace-version-only lockfile normalization, and exported
  from the clean tag checkout with `--experimental`. The result also matches
  the official `@openai/codex@0.152.1` export byte-for-byte.
- Contract: no public contract change from 0.152.0; all 414 JSON Schema files
  are unchanged. Upstream fixes Guardian review of model-provided Node REPL
  policies; this does not change the exported app-server contract.
- Swift compatibility: updated compatibility metadata and default client
  version. No generator or hand-written compatibility fix was necessary.
- Verification: idempotent generation, `swift build --target AppServerClient`,
  all 15 `swift test` cases, `git diff --check`, and unchanged `Package.resolved`
  passed. The smoke CLI passed initialize, account, usage, and empty thread-list
  calls against official `@openai/codex@0.152.1` in an isolated authenticated
  home, which was removed afterward. No turn-list coverage is claimed.
- Release isolation: pending voice examples and stdio changes in the normal
  checkout were excluded; this release was prepared in a clean worktree.

## 0.152.0 — 2026-09-01

- Schema provenance: regenerated and synchronized the exact experimental
  (`--experimental`) export from stable public Codex tag `rust-v0.152.0`,
  peeled commit
  `316795b3cf2a45e90d121d9f46499d4658b2645c`.
- Contract: the export grows from 413 to 414 JSON Schema files, with 1
  addition, no removals, and 14 modified existing files. It adds authentication
  recovery started and completed notifications, the `openaiForm` MCP-server
  elicitation action, project sorting, expanded rate-limit metadata, and a
  shell-command `timeoutMs` field.
- Swift compatibility: added a hand-written elicitation-request override that
  keeps the `openai/form` and `openaiForm` wire modes as distinct Swift cases,
  with focused decoding and encoding coverage. Historical smoke-test guidance
  now prefers the exact official npm CLI in a fresh isolated authenticated
  Codex home and documents honest coverage limits for empty homes and older
  0.144.x servers.
- Verification: the generator was idempotent; `swift build --target
  AppServerClient`, all 15 `swift test` cases, `git diff --check`, and the
  `Package.resolved` unchanged check passed. `swift run appserver-smoke`
  passed initialize, account, usage, and empty thread-list calls against the
  exact public `@openai/codex@0.152.0` CLI in an isolated authenticated Codex
  home; no turn-list coverage is claimed because that home had no threads.

## 0.151.0 — 2026-08-29

- Schema provenance: regenerated and synchronized the exact experimental
  (`--experimental`) export from stable public Codex tag `rust-v0.151.0`,
  peeled commit
  `78c290807ce710180111df227df3b7a4fe845452`.
- Contract: the export grows from 411 to 413 JSON Schema files, with 2
  additions, no removals, and 31 modified existing files. It adds the
  `turn/settings/update` RPC, a `functionCallOutput` thread-item case, the
  `rateLimitExceeded` error code, and turn-scoped settings and usage metadata.
- Swift compatibility: updated both exhaustive thread-item switches in the
  smoke executable for the new `functionCallOutput` case.
- Verification: the generator was idempotent; `swift build --target
  AppServerClient`, all 14 `swift test` cases, `git diff --check`, and the
  `Package.resolved` unchanged check passed. `swift run appserver-smoke`
  passed initialize, account, usage, and empty thread-list calls against the
  exact public `@openai/codex@0.151.0` CLI in an isolated authenticated Codex
  home; no turn-list coverage is claimed because that home had no threads.

## 0.150.1 — 2026-08-27

- Schema provenance: regenerated and synchronized the exact experimental
  (`--experimental`) export from stable public Codex tag `rust-v0.150.1`,
  peeled commit
  `90854393966b21e9ebfd21b122334eb09a20c93d`.
- Contract: no public contract change from 0.150.0. Canonical comparison of all
  411 JSON Schema files found no additions, removals, or semantic changes.
- Swift compatibility: advanced package metadata, the default client version,
  and version-specific documentation to 0.150.1. No generator, override, or
  call-site fix was required.
- Verification: the generator was idempotent; `swift build --target
  AppServerClient`, all 14 `swift test` cases, `git diff --check`, and the
  `Package.resolved` unchanged check passed. `swift run appserver-smoke`
  passed initialize, account, usage, and empty thread-list calls against the
  exact public `@openai/codex@0.150.1` CLI in an isolated authenticated Codex
  home; no turn-list coverage is claimed because that home had no threads.

## 0.150.0 — 2026-08-26

- Schema provenance: regenerated and synchronized the exact experimental
  (`--experimental`) export from stable public Codex tag `rust-v0.150.0`,
  peeled commit
  `3b3b4f8fb3f6403e72c2d0533ed0d2f309c59717`.
- Contract: the export grows from 401 to 411 JSON Schema files, with 10
  additions, no removals, and 42 modified existing files. It adds MCP server
  event-stream start and stop RPCs, thread timeline listing, MCP event
  notifications, and realtime item-started, item-completed, and transcript
  delta notifications. Amazon Bedrock access-key login moves to dedicated
  union cases while the `accessKeys` Bedrock setup branch is removed.
  Collaboration and approval unions also gain new cases.
- Swift compatibility: no additional hand-written compatibility fix was
  required.
- Verification: the generator was idempotent; `swift build --target
  AppServerClient`, all 14 `swift test` cases, `git diff --check`, and the
  `Package.resolved` unchanged check passed. `swift run appserver-smoke`
  passed initialize, account, usage, and empty thread-list calls against the
  exact public `@openai/codex@0.150.0` CLI in an isolated authenticated Codex
  home; no turn-list coverage is claimed because that home had no threads.

## 0.149.1 — 2026-08-24

- Schema provenance: regenerated and synchronized the exact experimental
  (`--experimental`) export from stable public Codex tag `rust-v0.149.1`,
  peeled commit
  `ff29a44391deccde0aba0f8390337d7f3c319ea4`.
- Contract: no public contract change from 0.149.0. Canonical comparison of all
  401 JSON Schema files found no additions, removals, or semantic changes.
- Swift compatibility: advanced package metadata, the default client version,
  and version-specific documentation to 0.149.1. No generator, override, or
  call-site fix was required.
- Verification: the generator was idempotent; `swift build --target
  AppServerClient`, all 14 `swift test` cases, `git diff --check`, and the
  `Package.resolved` unchanged check passed. `swift run appserver-smoke`
  passed initialize, account, usage, and empty thread-list calls against the
  exact public `@openai/codex@0.149.1` CLI in an isolated authenticated Codex
  home; no turn-list coverage is claimed because that home had no threads.

## 0.149.0 — 2026-08-20

- Schema provenance: regenerated and synchronized the exact experimental
  (`--experimental`) export from stable public Codex tag `rust-v0.149.0`,
  peeled commit
  `758ef40f50c1a458425c7cfbf1eb12cbc07af0b0`.
- Contract: the export grows from 380 to 401 JSON Schema files, with 21
  additions, no removals, and 34 modified existing files. It adds Amazon
  Bedrock discovery and setup plus project create, delete, import, list, move,
  read, and update RPCs. It also adds project lifecycle and strict-review
  notifications. Threads gain required project assignment and filtering, and
  plan types gain `edu_plus` and `edu_pro`.
- Swift compatibility: added hand-written response overrides for
  `BedrockDiscoverResponse` and `BedrockSetupResponse`, with focused
  compile-time response-mapping coverage.
- Verification: the generator was idempotent; `swift build --target
  AppServerClient`, all 14 `swift test` cases, `git diff --check`, and the
  `Package.resolved` unchanged check passed. `swift run appserver-smoke`
  passed initialize, account, usage, and empty thread-list calls against the
  exact public `@openai/codex@0.149.0` CLI in an isolated authenticated Codex
  home; no turn-list coverage is claimed because that home had no threads.

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
