# Upgrading for a Codex stable release

This runbook keeps Swift AppServer Client in version parity with public stable
Codex releases. Stable-only tracking is an explicit repository policy: alpha,
beta, release-candidate, nightly, draft, and Git-tag-only builds are out of
scope. The earlier `rust-v0.143.0-alpha.10-ios` Swift tag predates this stable
parity series. The first stable baseline is Codex `rust-v0.144.1` / Swift
`0.144.1`.

Generate the checked-in contract directly from an exact public Codex stable
tag. The downstream iOS app-server patch stack is not schema provenance and
must never be replayed into the export checkout. It may be built or tested
separately as optional downstream validation.

## 1. Prerequisites and safety checks

Required tools are `git`, `gh`, `jq`, `rg`, `rsync`, Python 3, Rust/Cargo,
Node.js/npm, and Swift 6.2 or newer. Authenticate `gh` for both repositories
before starting.

Use explicit paths and a temporary root:

```sh
codex_repo=/Users/openclaw/src/codex
client_repo=/Users/openclaw/src/swift-appserver-client
release_root=$(mktemp -d -t swift-appserver-release.XXXXXX)
```

Before changing either repository:

```sh
git -C "$codex_repo" status --short --branch
git -C "$client_repo" status --short --branch
git -C "$codex_repo" fetch --tags upstream
git -C "$client_repo" fetch --tags origin
git -C "$client_repo" switch main
git -C "$client_repo" pull --ff-only origin main
git -C "$client_repo" diff --exit-code -- Package.resolved
```

Stop if a checkout is dirty, the expected remote is missing, or `main` cannot
fast-forward. Do not use `reset --hard`, force-push, or retag to work around a
failed preflight.

## 2. Discover stable releases and the parity gap

Use official GitHub Releases as the source of truth. A raw Git tag is not enough
because Codex publishes prerelease tags frequently.

```sh
gh release list \
  --repo openai/codex \
  --limit 500 \
  --json tagName,isDraft,isPrerelease,publishedAt \
| jq -r '.[]
    | select(.isDraft == false and .isPrerelease == false)
    | select(.tagName | test("^rust-v[0-9]+\\.[0-9]+\\.[0-9]+$"))
    | .tagName' \
| sort -V
```

Compare that list, starting with `rust-v0.144.1`, with client tags after
stripping `rust-v`. Process every missing version in ascending order. Do not
skip a stable patch release merely because the public schema appears unchanged;
regenerate and verify it, then publish a parity tag with a no-contract-change
changelog entry.

For one release, define its refs explicitly:

```sh
previous_version=0.151.0
release_version=0.152.0
previous_codex_tag="rust-v${previous_version}"
codex_tag="rust-v${release_version}"
codex_worktree="${release_root}/codex-${release_version}"
client_worktree="${release_root}/client-${release_version}"
release_branch="release/${release_version}"
schema_output=$(mktemp -d "${release_root}/schema-${release_version}.XXXXXX")
```

Confirm that the official release and local tag agree:

```sh
gh release view "$codex_tag" --repo openai/codex \
  --json tagName,isDraft,isPrerelease,publishedAt,url
codex_commit=$(git -C "$codex_repo" rev-parse --verify "${codex_tag}^{commit}")
```

Stop if the GitHub release is a draft or prerelease, or if the local tag does
not resolve.

## 3. Create an exact-tag Codex worktree

Never move the normal Codex checkout while exporting a historical release.
Create a detached worktree at the exact public tag:

```sh
git -C "$codex_repo" worktree add --detach "$codex_worktree" "$codex_tag"
```

Verify that the worktree is exactly the peeled public tag and is clean:

```sh
test "$(git -C "$codex_worktree" rev-parse HEAD)" = "$codex_commit"
test -z "$(git -C "$codex_worktree" status --short)"
```

Do not create a branch or apply downstream commits in this worktree. Record
`codex_tag` and `codex_commit` in the Swift changelog.

## 4. Export the experimental app-server schema

`schema_output` was created with `mktemp`, so it is unique to this attempt.
Verify that it is empty before export; the Codex exporter overwrites files but
does not remove stale files left by an earlier run.

```sh
test -d "$schema_output"
test -z "$(find "$schema_output" -mindepth 1 -print -quit)"
cd "$codex_worktree/codex-rs"
cargo run -p codex-cli --bin codex -- \
  app-server generate-json-schema \
  --out "$schema_output" \
  --experimental
```

Do not use schema files left by another version. Record the exact export inputs
in the changelog:

- public Codex tag and peeled commit;
- the `--experimental` flag;
- confirmation that the export worktree was the clean public tag.

## 5. Prepare the Swift release worktree

Start each release from current reviewed `main`. During a historical backfill,
finish and fast-forward the preceding version before beginning the next so the
release commits and tags remain linear. Capture the base commit and require it
to be the preceding Swift release tag:

```sh
release_base_commit=$(git -C "$client_repo" rev-parse main)
previous_client_commit=$(git -C "$client_repo" rev-parse "${previous_version}^{commit}")
test "$release_base_commit" = "$previous_client_commit"
```

The following command is for a fresh attempt. If the release branch or
worktree already exists, use the recovery procedure instead of passing `-b`
again.

```sh
git -C "$client_repo" worktree add \
  -b "$release_branch" \
  "$client_worktree" \
  "$release_base_commit"
```

Verify the target before the destructive schema synchronization. It must end in
`/swift-appserver-client` or `/client-${release_version}` and contain
`Package.swift` plus `Scripts/generate-openapi.py`.

Synchronize only the generated schema directory:

```sh
rsync -a --delete \
  "${schema_output}/" \
  "${client_worktree}/Sources/AppServerClient/JSONSchema/"
```

Never point `rsync --delete` at a repository root or at an unverified variable.

## 6. Update version metadata and regenerate

Replace the previous compatibility version with `release_version` in all
current-version references:

- compatibility, requirements, dependency, and notes text in `README.md`;
- `info.version` in
  `Sources/AppServerClient/openapi.json.template`;
- the default initialization `ClientInfo.version` in
  `Sources/AppServerClient/AppServerClient.swift`;
- version-specific comments in `Models/TypeOverrides/` when they remain true.

Use `apply_patch` for hand-written edits. Do not edit generated JSON or Swift
mapping files directly. Then regenerate:

```sh
cd "$client_worktree"
python3 Scripts/generate-openapi.py
```

Search for stale compatibility strings and inspect the full change:

```sh
rg -n --fixed-strings \
  -e "$previous_version" \
  -e "$previous_codex_tag" \
  README.md Sources Scripts Tests
git status --short
git diff --stat
git diff -- Sources/AppServerClient/openapi.json.template
```

The search should retain the preceding version only where it describes
intentional historical behavior. Historical changelog entries are not included
in this current-version search.

## 7. Repair generator and Swift compatibility failures

Run generation before making compatibility guesses. Typical failures are:

1. A request component does not infer its response name. Add the narrow mapping
   to `RESPONSE_OVERRIDES` in
   `Scripts/openapi_codegen/swift_mapping.py`.
2. A JSON Schema union or nullable shape produces an unusable public Swift API.
   Extend the bundler or add a focused hand-written type under
   `Models/TypeOverrides/` and register it in
   `openapi-generator-config.yaml`.
3. A generated union gains a case. Update every exhaustive switch in the smoke
   CLI, tests, and hand-written library code.
4. A request's `params` becomes null or optional. Confirm that the generated
   `ClientRequestable.Params` and the no-params `send(request:)` overload still
   encode the correct wire value.

Prefer a generator fix that will work for later releases over editing one
generated artifact. Add or update focused tests for every hand-written mapping
or override.

## 8. Review the contract delta

Compare the newly exported experimental contract and generated Swift result
with the preceding released client commit:

```sh
git -C "$client_worktree" diff "$release_base_commit" -- \
  Sources/AppServerClient/JSONSchema \
  Sources/AppServerClient/openapi.json \
  Sources/AppServerClient/Models/DataModelMapping.swift
```

The base commit is the preceding Swift parity tag, whose `JSONSchema/` directory
contains that release's `--experimental` export. This makes the directory diff
an experimental-to-experimental comparison. Do not substitute a diff of Codex's
checked-in `codex-rs/app-server-protocol/schema/json` directory; those are the
stable fixture files and are not the export set used by this client.

Review additions, removals, wire renames, discriminator values, required versus
optional fields, nullability, numeric widths, and changed request/response
pairings. A zero schema diff is still meaningful: record that the experimental
schema was regenerated from the exact public tag.

## 9. Build, test, and smoke test

From the Swift worktree:

```sh
python3 Scripts/generate-openapi.py
swift build --target AppServerClient
swift test
git diff --check "$release_base_commit" --
git diff --exit-code "$release_base_commit" -- Package.resolved
```

`Package.resolved` is intentionally pinned and must not change. If dependency
resolution modifies it, restore it with a targeted patch before continuing; do
not include dependency drift in the protocol release.

For a historical backfill, prefer the exact official npm CLI. Use a fresh Codex
home with only the authenticated user's auth file so the historical binary does
not try to parse newer thread rollouts from the normal Codex home:

```sh
smoke_home=$(mktemp -d -t swift-appserver-smoke.XXXXXX)
cp ~/.codex/auth.json "$smoke_home/auth.json"
chmod 600 "$smoke_home/auth.json"

env CODEX_HOME="$smoke_home" \
  npm exec --yes --package="@openai/codex@${release_version}" -- \
  codex --version
env CODEX_HOME="$smoke_home" \
  npm exec --yes --package="@openai/codex@${release_version}" -- \
  swift run appserver-smoke
```

Require `codex --version` to print the expected release before accepting the
result. Copy authentication only; do not copy thread or session rollouts into
the isolated home. Building the exact public tag remains a valid alternative:

```sh
env CODEX_HOME="$smoke_home" \
  PATH="${codex_worktree}/codex-rs/target/debug:${PATH}" \
  swift run appserver-smoke
```

The basic release gate is successful initialize, account, usage, and thread-list
calls. An empty thread list is a successful basic gate, but it provides no
turn-list coverage. Claim turn-list coverage only when the output shows that
call completed. If turn coverage is mandatory, use a controlled, compatible
home containing a known thread. Exact 0.144.x CLIs can instead stop at
`thread/list` with JSON-RPC `-32601` because paginated threads are unsupported;
record that failure and do not claim basic or turn-list coverage.

After recording the result, remove the isolated home and its copied credential:

```sh
rm -R "$smoke_home"
```

### Optional downstream iOS validation

The maintained iOS branch may be built or tested after the public-tag release
gate. Use a separate checkout, record its exact commit and the validation that
actually ran, and follow that branch's current build instructions. Do not run
schema export or synchronize `JSONSchema/` from the iOS checkout. A macOS stdio
smoke against that branch is downstream runtime evidence; it does not exercise
the iOS callback bridge.

## 10. Write the changelog and release notes

Add a `CHANGELOG.md` entry for every stable version. Generate the first draft
from the official Codex release notes, the schema diff, and the Swift diff, then
review it manually. Each entry must include:

- Swift version and release date;
- public Codex tag and peeled commit;
- contract additions, removals, and breaking changes;
- generator, override, or call-site fixes;
- verification commands and results;
- an explicit “no public contract change” statement when applicable.

If optional downstream iOS validation ran, add its exact source commit and
results as a separate item. Do not describe that commit as schema provenance.

Use the same entry as the basis of a version-specific release-notes file under
the temporary release root. Do not claim compatibility based only on upstream
release notes; the generated diff and tests are authoritative.

## 11. Commit, tag, push, and publish

Review the exact release payload:

```sh
git -C "$client_worktree" status --short
git -C "$client_worktree" diff --check "$release_base_commit" --
git -C "$client_worktree" diff --exit-code \
  "$release_base_commit" -- Package.resolved
```

Commit one version at a time:

```sh
git -C "$client_worktree" add \
  AGENTS.md UPGRADE.md CHANGELOG.md README.md Scripts Sources Tests
git -C "$client_worktree" commit -m "Update client for Codex ${release_version}"
release_commit=$(git -C "$client_worktree" rev-parse HEAD)
test "$(git -C "$client_worktree" rev-parse "${release_commit}^")" = \
  "$release_base_commit"
test -z "$(git -C "$client_worktree" status --short)"
```

Omit unchanged paths rather than forcing them into the commit. The parent check
enforces one linear release commit. Fast-forward `main`, push that exact commit,
and verify the remote before tagging. Stop if `main` advanced after the release
worktree was created; rebuild the release on the new base instead of merging an
outdated release commit.

```sh
git -C "$client_repo" switch main
git -C "$client_repo" pull --ff-only origin main
test "$(git -C "$client_repo" rev-parse HEAD)" = "$release_base_commit"
git -C "$client_repo" merge --ff-only "$release_commit"
test "$(git -C "$client_repo" rev-parse HEAD)" = "$release_commit"
git -C "$client_repo" push origin \
  "refs/heads/main:refs/heads/main"
git -C "$client_repo" fetch origin main
test "$(git -C "$client_repo" rev-parse origin/main)" = "$release_commit"

git -C "$client_repo" tag -a "$release_version" "$release_commit" \
  -m "Swift AppServer Client ${release_version}"
git -C "$client_repo" push origin "refs/tags/${release_version}"
```

If repository policy requires a pull request, push `release_branch` for review
and require an integration method that preserves the reviewed release commit.
Do not create the tag until `release_commit` is reachable from `origin/main`;
always pass that exact SHA to `git tag`.

Create the GitHub release from the existing tag:

```sh
gh release create "$release_version" \
  --repo gonzalolarralde/swift-appserver-client \
  --verify-tag \
  --title "Swift AppServer Client ${release_version}" \
  --notes-file "${release_root}/release-${release_version}.md"
```

Verify tag, commit, and release agree:

```sh
test "$(git -C "$client_repo" rev-parse "${release_version}^{commit}")" = \
  "$release_commit"
test "$(git -C "$client_repo" rev-parse origin/main)" = "$release_commit"
gh release view "$release_version" \
  --repo gonzalolarralde/swift-appserver-client \
  --json tagName,targetCommitish,publishedAt,url
```

## 12. Idempotency and recovery

Check state before retrying any release. These probes are conditional because a
missing tag or release is an expected recovery state:

```sh
if git -C "$client_repo" ls-remote --tags origin \
  "refs/tags/${release_version}" | rg -q .; then
  echo "remote tag exists: ${release_version}"
fi

if gh release view "$release_version" \
  --repo gonzalolarralde/swift-appserver-client >/dev/null 2>&1; then
  echo "GitHub release exists: ${release_version}"
fi

git -C "$codex_repo" worktree list --porcelain
git -C "$client_repo" worktree list --porcelain
if git -C "$client_repo" show-ref --verify --quiet \
  "refs/heads/${release_branch}"; then
  echo "local release branch exists: ${release_branch}"
fi
```

On retry:

- If `codex_worktree` exists, reuse it only when it is clean and its `HEAD`
  equals `codex_commit`. Otherwise stop and choose a new verified path.
- If `release_branch` is already attached to a worktree, reuse that worktree.
  If the branch exists but has no worktree, attach it with
  `git -C "$client_repo" worktree add "$client_worktree" "$release_branch"`
  instead of using `-b`.
- Allocate a new `schema_output` with `mktemp` for every export attempt. Never
  reuse a previous schema directory.

Handle partial states as follows:

- No commit or tag: fix the release branch, rerun generation and verification,
  and continue normally.
- Commit exists only on the release branch: review it, then fast-forward through
  the normal policy. Do not create a tag early.
- Commit is on `origin/main`, tag is absent: verify the embedded versions and
  test evidence, then create the annotated tag.
- Tag exists, GitHub release is absent: verify the tag target, then rerun
  `gh release create --verify-tag`.
- GitHub release exists: verify it and skip publication. Re-running discovery
  must treat that stable version as complete.
- A published tag points at the wrong commit: stop. Never move or overwrite it;
  coordinate a corrective release with a new version.

Before removing temporary worktrees, require them to be clean:

```sh
test -z "$(git -C "$codex_worktree" status --short)"
test -z "$(git -C "$client_worktree" status --short)"
git -C "$codex_repo" worktree remove "$codex_worktree"
git -C "$client_repo" worktree remove "$client_worktree"
```

Delete temporary release data only after the GitHub release has been verified.
If cleanup is interrupted, `git worktree list` is the source of truth; do not
recursively delete an unverified path.
