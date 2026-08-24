# Issue #476 Task — Living Plan Intelligence UI + Isolated Device Acceptance

## Authority and routing

- Repository: `faliardic/chief-site-engineer`
- Issue: `#476`
- Owner authority: `https://github.com/faliardic/chief-site-engineer/issues/476#issuecomment-5384566983`
- Parent Epic / V2 item: `#385` / `V2.5 — 7 Günlük Yaşayan İş Programı`
- Policy / risk / validation: `CSE-MRP-1.0` / `R4` / `release-critical`
- Requested executor: `gpt-5.6-sol`, reasoning `max`
- Execution mode / orchestration: `standard` / `single-agent`
- Allowed fallback: `null`; review floor: independent `gpt-5.6-sol` / `max`
- Runtime metadata hidden: actual model `unknown`, actual effort `null`, invocation `unverified`, mismatch `null`.

## Exact preflight

- Base: `cc7c49fa30b50aae09b349eb0bfa1161c5cdc814`
- Branch: `codex/issue-476-living-plan-intelligence-ui`
- Worktree: `V:\1_PROJECTS\2_ACTIVE\Python\CSE-Worktrees\issue-476-living-plan-intelligence-ui`
- Issue #474 closed; PR #475 merged; parallel open PR `0`.
- Initial tracked/staged: clean / `0`; tracked paths: `1243`.
- Protected paths: `1232`; manifest SHA-256: `4ff04b32af09f0c442a953d2e6bb7690c201af01b5538bcb4aae040996a6b895`.

## Objective

Expose merged actual-progress, deterministic forecast and immutable historical
dependency-impact cores as a read-only Living Plan intelligence projection.
Bind only to each item's exact `referenceSnapshotId`; never rebind to a current
or newer snapshot/graph. Legacy graph unavailable may keep a valid forecast but
must not fabricate impact or backfill. The caller supplies canonical UTC-midnight
`asOfDate`; no clock read. Intelligence failures must not block lifecycle or
progress actions. No Living Plan, reference schedule, database, event or receipt
mutation is authorized.

## Validation order

Focused intelligence application → Living Plan widget → bootstrap → forecast and
impact regressions → affected static only if needed → analyze → diff/drift → only
all PASS exactly one full test → acceptance Build mode → only all host PASS and
one usable authorized device, Device mode once.

Each failed focused/analyze/full/build/device gate permits at most one exact
correction and one retry. A 19th path, protected edit, historical rebind/backfill,
schema/mutation need, real-user-data need or scope expansion is a hard stop.

Schema stays `17`, backup format `1`, version `0.1.0+1`. PASS alone authorizes
minimal commit(s), normal push and one Draft PR. No force/amend/rebase, Ready,
merge, close, Item 5/V2.5 completion, successor, release or store action.

## Exact active allowlist

1. `mobile/lib/domain/construction_living_plan_intelligence_models.dart`
2. `mobile/lib/application/construction_living_plan_intelligence_application.dart`
3. `mobile/lib/bootstrap/app_bootstrap.dart`
4. `mobile/lib/app.dart`
5. `mobile/lib/features/living_plan/living_plan_page.dart`
6. `mobile/test/construction_living_plan_intelligence_application_test.dart`
7. `mobile/test/living_plan_widget_test.dart`
8. `mobile/test/app_bootstrap_test.dart`
9. `mobile/integration_test/support/living_plan_acceptance_fixture.dart`
10. `scripts/run_living_plan_device_acceptance.ps1`
11. `ROADMAP.md`
12. `docs/v2/CSE_V2_SCOPE.md`
13. `docs/project_decisions.md`
14. `CHANGELOG.md`
15. `.cse/tasks/476_task.md`
16. `.cse/results/476_result.md`

Conditional paths `mobile/test/release_static_configuration_test.dart` and
`mobile/test/widget_test.dart` remained unedited. The existing release/static
test is affected by the runner and is therefore executed read-only; no new
assertion or 17th changed path was needed.

Protected forecast, dependency-impact, date-engine, snapshot repository,
database/schema, Living Plan mutation, corpus/graph/dependency repositories,
backup production, pubspec/lock and Android/iOS production bytes remain subject
to the initial protected manifest. Device work remains unopened until every host
gate and host APK Build mode passes.

## Consumed focused retry budget

- Intelligence application primary: compile stopped on four non-const fixture
  constructors inside two const lists. Exact correction removed only those two
  list const contexts; the single retry passed `5/5`.
- Living Plan widget primary: compile stopped on six `DateTime.utc` values inside
  two const fixture lists. Exact correction removed only those two list const
  contexts; the single retry passed `19/19`.
- No production correction was needed. These two focused retry budgets are now
  exhausted; bootstrap/forecast/impact/static/analyze/full/build/device budgets
  remain governed independently by the owner authority.

## Fail-closed stop — analyze retry exhausted

`flutter analyze --no-pub` primary reported three info lints: two
`prefer_initializing_formals` findings in the new intelligence application and
one `use_null_aware_elements` finding in the widget-test fake. The single exact
correction converted the constructor parameters to initializing formals and
rewrote only the fake result-map construction. The authorized analyze retry then
reported two `type_init_formals` info lints because the initializing formals still
carry explicit typedef annotations at lines 34 and 36.

The concrete remaining edit would remove only those two redundant type
annotations, but analyze correction + retry budget is exhausted. No further code
edit or test invocation is authorized without new owner authority. Full Flutter,
acceptance Build mode, APK verification, ADB/Device mode, commit, push and Draft
PR remain unopened. Current WIP is exact `16` authorized paths, staged `0`, HEAD
still exact base `cc7c49fa30b50aae09b349eb0bfa1161c5cdc814`.

## Owner correction authority — analyze blocker

Owner comment `5385942260` accepted the completed focused evidence and granted
one semantic no-op correction plus exactly one additional analyze invocation.
The correction removed only the two redundant typedef annotations from the new
intelligence application's initializing formals; no other source, test, fixture,
dependency, platform or contract edit was authorized.

Preflight confirmed the exact worktree, branch, base HEAD, `16` authorized WIP
paths and staged `0`. The other `15` WIP file hashes remained byte-identical
during correction. Corrected application SHA-256:
`c669a3a235f84c924c63bae8c2f822a409174a6acb4335874d68298aeac86d29`.

The newly authorized single `flutter analyze --no-pub` invocation passed with
`No issues found!` in `7.5s`. Previously passing focused suites were not rerun.
Continuation is limited to diff/drift checks, one full Flutter suite, host Build
mode and then Device mode only under the single-authorized-device contract.

## Post-analyze drift gate — PASS

`git diff --check` returned exit `0`. The changed-path set remained exact
`16/16`, protected drift was `0`, staged remained `0`, and Android/iOS
production drift was `0`. Schema `17`, backup format `1`, app version
`0.1.0+1`, and the initial pubspec/lock SHA-256 values were exact. The next
authorized invocation is the single unopened full `flutter test --no-pub`.

## Full suite and Build correction

The single full `flutter test --no-pub` invocation passed `751/751`. Host Build
mode primary then stopped before the APK build because offline metadata cleanup
could not delete the ignored worktree-local
`mobile/ios/Flutter/ephemeral/Packages/.packages` directory. The exact root was
inside this worktree, ignored, contained no tracked path, and carried read-only
directory attributes. Under the original per-operation correction budget, only
that generated `mobile/ios/Flutter/ephemeral/` root had read-only attributes
cleared and was removed. Tracked WIP remained exact `16`; staged remained `0`.
The single Build-mode retry is now the only authorized next invocation.

## Fail-closed stop — Build retry exhausted

The single Build-mode retry passed offline metadata preparation but its only APK
build invocation ended after `157.9s` with `Gradle task assembleDebug failed with
exit code 1`. The runner reported only the non-fatal future KGP compatibility
warning and no further concrete Gradle cause. No fresh shared or release-gate APK
exists. The retry also left one `0`-byte untracked Kotlin compiler session marker;
that exact generated marker was removed so the final WIP returned to the exact
`16` authorized paths with staged `0`.

Build correction + retry budget is exhausted. No new edit, build invocation,
ADB/device action, commit, push or Draft PR is authorized without new owner
authority. Previously passing focused/analyze/drift/full evidence remains
recorded; publication and Device mode remain unopened.

## Owner continuation authority — guarded Build diagnosis

Owner comment `5386027504` preserves every prior PASS gate and authorizes only
read-only Gradle/OpenJDK diagnosis, a proven non-product generated-state or
repository-daemon correction, and exactly one new Build-mode invocation. No
tracked source/test/docs edit is authorized; task/result evidence remains the
explicit append-only exception.

Diagnosis bound the failed build to Gradle `9.1.0` daemon PID `16520`, Android
Studio JetBrains Runtime `21.0.8`. The daemon started with `-Xmx8G`,
`MaxMetaspaceSize=4G` and `ReservedCodeCacheSize=512m` on a host with `15775 MiB`
visible physical memory. Its log accepted the exact worktree build, emitted only
the non-fatal future KGP warning, then ended abruptly without Gradle exception,
normal shutdown, OOM dump or JVM crash artifact. Wrapper `--status` reported no
running daemons and PID `16520 STOPPED (by user or operating system)`.

No Java/Gradle/Flutter process remains. No compile error or tracked-file need was
found. The failed invocation left no APK but did leave partial worktree-local
generated output and lock/cache state in `mobile/build/`,
`mobile/.dart_tool/flutter_build/`, `mobile/android/.gradle/`, the empty
`mobile/android/.kotlin/`, and regenerated `mobile/ios/Flutter/ephemeral/`.
These roots are the only authorized correction target; no global daemon/cache,
JDK, source, test, runner or platform file may be changed.

## Guarded non-product correction — PASS

With active Java/Gradle/Flutter process count `0`, read-only attributes were
cleared only under the five exact worktree-local targets and the stale partial
state was removed: `mobile/build/`, `mobile/.dart_tool/flutter_build/`,
`mobile/android/.gradle/`, empty `mobile/android/.kotlin/`, and
`mobile/ios/Flutter/ephemeral/`. All five are now absent. No global daemon/cache
or JDK state was changed; `--status` had already proved there was no daemon to
stop. The tracked WIP remains exact `16`, staged `0`. Build remains unopened
under this authority pending the mandated pre-Build drift checks.

## Guarded host Build — PASS; evidence-order fail-closed

Mandatory pre-Build verification passed exact `16/16`, staged/protected/
platform drift `0`, schema `17`, backup `1`, version `0.1.0+1`, exact
pubspec/lock hashes, `git diff --check` exit `0`, clean generated roots and
active build processes `0`. The authority's exactly one Build-mode invocation
passed: Gradle `assembleDebug` completed in `99.4s`; runner verified package
`com.faliardic.sefim.acceptance`, label `Şefim`, `arm64-v8a` and fresh artifact
SHA-256 `d0a746dc48c8c2fac768671df7fc3162053de2c244c95f1cc2c8593ca1207a25`
at `96892411` bytes. Shared output and release-gate copy are exact equal.

Before ADB preflight, append-integrity audit found that the new diagnosis and
cleanup result blocks had been inserted before older result evidence rather than
at EOF because an ambiguous historical `review_recommendation` context matched.
Current authority grants append-only evidence but no relocation/non-append
exception. Device, commit, push and Draft PR therefore remain unopened pending
new owner direction on exact evidence relocation or acceptance of the ordering.

## Evidence append-order correction authority — PASS

Owner comment `5386082341` authorized only byte-identical relocation of the
misplaced diagnosis and generated-state cleanup evidence blocks, followed by
the preserved Build-PASS APK's isolated Device continuation. The result file's
pre-relocation SHA-256 was
`09a6cece78d150d753a49e8dced66b1928ba44a14dfbb47b35c9da2d8a2a4514` at
`15139` bytes. Relocation preserved the diagnosis block as `1741` bytes / SHA-256
`a5d25fb73639c60e5d30b2611ea39ee378f06a37b1645a9fe2a55728ff9bf85d`,
the cleanup content as `848` bytes / SHA-256
`0ed377b9443ea17d9f8833d4ae5828213501c2ee04924ccaafe6709f908e160e`,
and their exact ordered content as `2589` bytes / SHA-256
`ba4c0b7ff2ef3d8b4674e39f26ba9e07a24ef88107bcad51bb1c47bed0599dfa`
at EOF. The original `7941`-byte historical suffix remains byte-identical at
SHA-256 `4796311c5cf80de34418a5cf4d56c15012801a8dc37aa55f6e0038874654ae76`;
one structural LF separates it from the relocated blocks. Result encoding
remains UTF-8 without BOM and LF-only; post-relocation SHA-256 is
`9b8ca28e487b6103657c3321ae85e43bfc8406c995fd52226f7d0ffc4804587b`.

Post-correction verification retained exact `16/16` authorized WIP paths,
staged `0`, protected tracked drift `0` across `1232` paths, and no unexpected
path. Analyze, full Flutter and host Build were not rerun. Device preflight is
the next and only opened gate.

## Isolated Device continuation — FAIL / fail-closed

The preserved acceptance APK remained exact at `96892411` bytes and SHA-256
`d0a746dc48c8c2fac768671df7fc3162053de2c244c95f1cc2c8593ca1207a25`.
Read-only preflight resolved exactly one physical usable device, masked serial
`sha256:c68cbe516264`, model `SM-S938B`, API `36`, ABI `arm64-v8a`, with
offline/unauthorized count `0`.

Exactly one authorized Device-mode invocation was executed. Six-package
baseline inventory completed and `install -r` changed only
`com.faliardic.sefim.acceptance`; installation returned `Success`. The runner
then terminated with exit `1` at
`scripts/run_living_plan_device_acceptance.ps1:373`:
`Acceptance UI text was not found: Başlangıç`.

Owner authority requires fail-closed on any Device failure. No second device
command/invocation, correction, test, analyze, full Flutter, Build, commit,
push or PR operation followed. Final host-side state remains exact `16/16`,
staged `0`, protected drift `0`, base HEAD
`cc7c49fa30b50aae09b349eb0bfa1161c5cdc814`; the APK hash is unchanged.

## Device diagnosis correction authority — root cause proven

Owner comment `5386161653` authorizes one read-only diagnosis, one exact
correction and one Device retry. Foreground verification stayed strictly inside
`com.faliardic.sefim.acceptance`; no raw-coordinate action or prod/debug
package/data access occurred. UIAutomator showed the acceptance entrypoint's
safe `acceptance_fixture_failed` panel instead of the expected Home shell.

Immutable read-only queries of the acceptance synthetic database proved schema
`17`, the dependency-capable current snapshot and manifest, the exact
intelligence item binding, `STARTED + 47`, revision `3`, and aligned three-event/
three-receipt history. The reference source finishes `2026-03-06`; as-of
`2026-08-23` leaves `1.59`, rounded to `2` working days, with a mandatory FS
successor, so the fixture's positive-delay expectation is valid.

A system-temp copy run through the production SQLite intelligence wrapper then
proved the exact failure: `DatabaseException(error database_closed)`, from
`ConstructionScheduleSnapshotRepository.loadSnapshotById` through
`construction_living_plan_intelligence_application.dart:244`. `_run()` returned
the inner Future without awaiting it, allowing `finally` to close SQLite before
the non-empty snapshot read completed. Classification: real Living Plan
intelligence/application regression, not runner navigation mismatch and not
fixture/state corruption.

The single correction is limited to the already-authorized intelligence
application plus its already-authorized focused test: await the inner read before
closing SQLite and add a non-empty SQLite lifetime regression case. Fixture, UI,
runner, schema, backup and version remain unchanged. Because executable source
changes, focused intelligence + analyzer + drift gates + a fresh Build are
required before the one authorized Device retry; the old APK cannot be reused.

## Device correction host gates — PASS

The single correction added `await` to the inner non-empty intelligence read
before `_run()` closes SQLite and added one focused SQLite lifetime regression
test. Application SHA-256 changed from
`c669a3a235f84c924c63bae8c2f822a409174a6acb4335874d68298aeac86d29` to
`e1c5eff957196b76b3e616d029a001152efd6e53874ad37a7c6f70de96931c91`;
focused-test SHA-256 changed from
`7ad2843f84678bb1bb8af9f23f46d6fd462026acffd35878662961719b5d5acc` to
`74e0ce5b0aed563803947dcc446ec4005bca43610c3f26d278ee1c9327b4e9b1`.
No fixture, UI, runner, schema, backup or version byte changed during the
correction.

Post-correction proportional validation:

- focused intelligence: `6/6 PASS` in one invocation
- `flutter analyze --no-pub`: PASS in one invocation
- `git diff --check`: PASS
- exact WIP allowlist: `16/16`; staged: `0`
- protected drift: `0`; unchanged WIP hash mismatch: `0`
- schema `17`; backup format `1`; app version `0.1.0+1`
- pubspec/lock/platform-production drift: `0`

The prior full Flutter result was not rerun: authority requires proportional
validation, and this exact asynchronous resource-lifetime correction is covered
by the new focused SQLite regression, analyzer and the required fresh executable
Build. The old APK SHA is invalidated; exactly one fresh Build-mode invocation is
the next authorized gate.

## Fresh Build-mode gate — FAIL, fail-closed

Exactly one post-correction Build-mode invocation was executed. It exited `1`
before compiling the APK because Flutter could not delete the generated path
`mobile/ios/Flutter/ephemeral/Packages/.packages`. Read-only inspection proved
that exact worktree-local directory still exists with attributes
`ReadOnly, Directory`.

No generated-state cleanup, source edit, Build retry or Device invocation
followed. The only APK remaining is the stale pre-correction artifact at
`96892411` bytes and SHA-256
`d0a746dc48c8c2fac768671df7fc3162053de2c244c95f1cc2c8593ca1207a25`;
it is not valid executable evidence for the corrected source and was not used.
Final read-only verification remains exact WIP `16/16`, staged `0`,
`git diff --check` PASS, base HEAD
`cc7c49fa30b50aae09b349eb0bfa1161c5cdc814`, with pubspec/lock unchanged.
Authority requires fresh Build PASS before the single Device retry, so work stops
fail-closed without commit, push or PR.

## Generated-state cleanup authority — Build retry FAIL

Owner comment `5386260264` accepted the corrected application, focused
intelligence `6/6 PASS`, analyzer PASS and prior drift evidence, and authorized
only worktree-local generated cleanup under
`mobile/ios/Flutter/ephemeral/` plus exactly one fresh Build retry.

The resolved generated root was exact and ignored under the isolated worktree.
Read-only preflight found five read-only generated directories inside its
`Packages` subtree, including the concrete `.packages` blocker. System `attrib`
cleared only those generated read-only bits; no file deletion and no tracked
source/config change occurred. Remaining read-only entries under the authorized
ephemeral root: `0`.

Pre-Build gates reconfirmed exact WIP `16/16`, staged `0`, protected drift `0`,
authorized source/test hash mismatch `0`, `git diff --check` PASS, schema `17`,
backup format `1`, version `0.1.0+1`, pubspec/lock/platform-production drift `0`,
and no parallel worktree Gradle/Flutter build. Focused intelligence and analyzer
were not rerun, exactly as required.

The single authorized fresh Build retry passed dependency preparation and the
prior ephemeral cleanup point, then exited `1` in Gradle task
`:app:cleanMergeDebugAssets`: Gradle could not delete
`mobile/build/app/intermediates/assets/debug/mergeDebugAssets` and its generated
children. `mobile/build/` is outside this authority's cleanup scope. No cleanup,
second Build, Device invocation or publication followed. The only APK remains
the stale pre-correction artifact (`96892411` bytes, SHA-256
`d0a746dc48c8c2fac768671df7fc3162053de2c244c95f1cc2c8593ca1207a25`)
and was not used. Final state remains exact 16-path WIP, staged `0`,
`git diff --check` PASS. Stop fail-closed pending new owner authority.

## Android generated-state authority — cleanup and fresh Build PASS

Owner comment `5386290197` authorized read-only diagnosis and cleanup limited to
worktree-local generated `mobile/build/`, followed by exactly one fresh Build.
Diagnosis found the failing `mergeDebugAssets` target and nine reported child
directories all carrying the `ReadOnly` directory attribute, while ACLs allowed
modification. No worktree-specific daemon lock was proven, so no Java, OpenJDK,
Gradle or Kotlin process was stopped.

System `attrib` cleared only the exact `mobile/build/` generated tree. The root's
own remaining read-only bit was then cleared and the verified exact generated
root was deleted. No tracked source/config/product/test byte changed. Pre-Build
gates reconfirmed exact WIP `16/16`, staged `0`, protected/platform drift `0`,
authorized baseline hash mismatch `0`, `git diff --check` PASS, schema `17`,
backup `1`, version `0.1.0+1`, and no parallel worktree build. Focused
intelligence and analyzer were not rerun.

The single fresh Build-mode invocation PASSed. Fresh Flutter output and
release-gate copy are exact at `96884027` bytes, timestamp
`2026-08-23T13:41:28.5716588Z`, package
`com.faliardic.sefim.acceptance`, label `Şefim`, ABI `arm64-v8a`, SHA-256
`05824fa62e88acf58340c013375cadcaf482726b1f9bb6a05d2eb28e9bf5f590`.
Device preflight resolved exactly one usable `SM-S938B`, API `36`,
`arm64-v8a`, masked serial `sha256:c68cbe516264`, with offline/unauthorized
count `0`. Exactly one Device-mode invocation using only this fresh APK is next.

## Fresh APK Device acceptance — FAIL, fail-closed

Exactly one Device-mode invocation used the fresh Build-PASS APK. Preflight again
confirmed the authorized `SM-S938B`, API `36`, ABI `arm64-v8a`, masked serial
`sha256:c68cbe516264`. Six-package baseline inventory completed, `install -r`
changed only `com.faliardic.sefim.acceptance`, and installation returned
`Success`.

The semantic flow then exited `1` at
`scripts/run_living_plan_device_acceptance.ps1:373` because exact text
`Başlangıç` was not found. Owner authority requires immediate fail-closed on
Device failure. No post-failure device diagnosis, correction, second Device
invocation, source/test edit, commit, push or PR operation followed. Host state
remains exact WIP `16/16`, staged `0`, `git diff --check` PASS; the fresh APK
remains `96884027` bytes with SHA-256
`05824fa62e88acf58340c013375cadcaf482726b1f9bb6a05d2eb28e9bf5f590`.

## Owner correction `5386341957` — proven fixture calendar defect

Read-only acceptance-package diagnosis proved that the repeated missing
`Başlangıç` symptom was the safe `acceptance_fixture_failed` panel, not runner
navigation. The fixture reached the SQLite intelligence application after the
prior await-before-close fix, then failed with
`ConstructionLivingPlanForecastFailure(forecast_invalid_as_of_calendar)`:
device as-of/window start `2026-08-23` is Sunday while the selected exact
reference activity used `WORKING_DAY`. The protected date engine correctly
rejects a non-working start, so neither the assertion nor production calendar
semantics may be weakened.

Candidate audit against the exact current immutable snapshot and dependency
manifest selected unused exact activity `TR-BLD-09-008-RADYE-KUR@B-A`
(`Radye kür`, `CALENDAR_DAY`). At the same caller-supplied Sunday and progress
`47`, the existing forecast/impact engines produced positive variance and `682`
downstream impacts. The one narrow correction changed only the acceptance
fixture's synthetic intelligence IDs/activity/query and the runner's matching
item ID. Existing synthetic items, production UI/application/core, schema and
backup bytes were not changed.

Proportional host continuation PASS:

- corrected fixture on an unchanged acceptance DB system-temp copy: `1/1 PASS`
- release/static runner focused: `6/6 PASS`
- `flutter analyze --no-pub`: PASS
- `git diff --check`: PASS
- exact WIP `16/16`; staged `0`; protected/platform drift `0`
- schema `17`; backup format `1`; version `0.1.0+1`
- pubspec/lock drift `0`
- exactly one full `flutter test --no-pub`: `752/752 PASS`

Because the fixture is an APK input, prior APK
`05824fa62e88acf58340c013375cadcaf482726b1f9bb6a05d2eb28e9bf5f590`
is stale. Exactly one fresh Build-mode acceptance invocation is the next gate;
Device mode remains unopened for this authority.

Concrete pre-Build audit found `2265` read-only entries only under the exact
ignored worktree-local `mobile/build/` generated root. No worktree build
process was active. System `attrib` cleared only that tree and the verified
generated root was deleted; tracked drift remained zero. The single fresh Build
then PASSed.

Fresh output and release-gate copy are byte-identical at `96891207` bytes,
timestamp `2026-08-23T14:17:20.3832395Z`, SHA-256
`b190296c4e0a7d3e93e58f9b4d1e91bd90a0287b0e14e048f5cecda4db978927`.
Package `com.faliardic.sefim.acceptance`, label `Şefim`, launchable activity
and `arm64-v8a` native library contract PASSed. Post-Build state remains exact
`16/16`, staged `0`, protected/platform/pubspec-lock drift `0`.

Device preflight resolved exactly one usable physical device, masked serial
`sha256:c68cbe516264`, model `SM-S938B`, API `36`, ABI `arm64-v8a`,
offline/unauthorized `0`. Exactly one isolated Device-mode invocation using
only this fresh APK is now authorized.

## Owner correction `5386341957` — Device FAIL / fail-closed

Exactly one Device-mode invocation used only fresh APK SHA-256
`b190296c4e0a7d3e93e58f9b4d1e91bd90a0287b0e14e048f5cecda4db978927`.
Six-package baseline inventory PASSed and `install -r` returned `Success` for
only `com.faliardic.sefim.acceptance`. The runner then exited at line `497`
because this exact semantic selector was not visible:

```text
47600000-0000-4000-8000-000000000041.*Tahmini kalan:.*Tahmini bitiş:.*Referansa göre:
```

Per authority, no post-failure diagnosis, edit, second Device invocation, test,
analyze, Build, commit, push or PR action followed. Final host state is exact
`16/16`, staged `0`, protected/platform drift `0`, and
`git diff --check` PASS. Stop fail-closed pending new owner authority.

## Owner correction `5386637867` — consolidated recovery, Device FAIL

Read-only current-dataset inventory executed all five active batch items
individually. Exactly two produced
`ConstructionLivingPlanForecastFailure(forecast_invalid_as_of_calendar)`:

- `cb502e04-1a84-4acd-8b40-738766785bb0`, Mobilizasyon planı,
  `STARTED / 68`, planned `2026-08-15`, overdue `WORKING_DAY`
- `47600000-0000-4000-8000-000000000031`, Geçici elektrik,
  `STARTED / 47`, planned `2026-08-23`, `WORKING_DAY`

Both used Sunday `2026-08-23` as `asOf`; their working-day finish calculation
rejected the non-workday start. The other three batch items passed with
`plannedNotStarted`, `startedProgressUnknown` and calendar-day
`startedReferenceRemaining`. Notes, fixed IDs and event histories proved both
poison rows were prior #476 acceptance-owned synthetic leftovers.

One consolidated correction changed only the acceptance fixture. It validates
synthetic ownership, then completes both legacy rows through public Living Plan
commands with deterministic event IDs `...0035` and `...0036`; repeated fixture
execution is a no-op. Focused fixture `1/1 PASS`, analyze PASS, full Flutter
`752/752 PASS`, and fresh Build PASS. Fresh APK: `96893055` bytes, SHA-256
`1609a5daa4c1eeef3ded5f7ec10923f38d0c32db038a014bb206bbe14e403167`.

The exactly-one Device invocation installed only the acceptance package and
failed at runner line `1089`: the impact detail exposed no positive `+N gün`
shift node. Per authority, no diagnosis, second correction, retry, commit, push
or PR action followed. Stop fail-closed pending new owner authority.

## Owner correction `5386723374` — impact-detail semantic diagnosis

The authority was read in full before action. Read-only diagnosis was limited to
`com.faliardic.sefim.acceptance`, its current UI hierarchy, filtered process
diagnostics and a binary DB copy under system temp. No repository edit or Device
retry occurred before classification.

Exact production-engine comparison bound item
`47600000-0000-4000-8000-000000000041` to snapshot
`57612536-6036-48d9-930e-66d8df12c837` and its persisted `1226`-edge graph
fingerprint `a7b9bc32a4e38372d878e2d87b3047b8205ecaa650594317d3de4c9fa36968fd`.
The STARTED/47 forecast had finish variance `+37` days and the direct dependency
engine produced `682` positive shifted rows. The visible first rows matched the
engine exactly, including `+36` and `+37` finish shifts, but Android exposed each
row as one combined `content-desc`; the runner searched only a standalone `text`
node. Root-cause class `2` is proven: UI shows positive shift, runner selector is
wrong.

The single correction changes only
`scripts/run_living_plan_device_acceptance.ps1`: a row may satisfy the positive
shift assertion through a standalone positive `text` node or through one combined
semantic row that also contains exact projected-start and projected-finish date
lines. The positive non-zero requirement is preserved. PowerShell parse PASS and
the proportional release/static gate is `6/6 PASS`. Production, fixture and test
hashes remain frozen; APK inputs and APK SHA-256 remain unchanged. Reuse the
current APK and perform exactly one newly authorized Device invocation next.

## Owner correction `5386723374` — Device FAIL / final fail-closed

The final preflight proved one usable `arm64-v8a` device, zero
offline/unauthorized devices, exact user-0 six-package inventory, WIP `16/16`,
staged `0`, platform-production drift `0`, and byte-identical shared/release-gate
APK SHA-256
`1609a5daa4c1eeef3ded5f7ec10923f38d0c32db038a014bb206bbe14e403167`.

Exactly one Device-mode invocation was made. Its six-package baseline PASSed and
`install -r` returned `Success` for only `com.faliardic.sefim.acceptance`. The
runner later terminated in the generic bounded text wait at line `373` with:

```text
Acceptance UI text was not found: Kaydet
```

The runner contains three possible `Kaydet` callers at source lines `1260`,
`1282`, and `1387`; terminal output does not disambiguate them. Authority makes
any Device failure terminal, so no post-failure device diagnosis, second source
correction, Device invocation, test, analyze, Build, commit, push or PR action is
authorized. Stop fail-closed pending new owner authority.

## Owner diagnostic authority `5386914948` — `diagnosis_insufficient`

Diagnosis used only the existing runner output/task-result evidence and
read-only runner source. No tracked edit, test, build, Device invocation or
package/data mutation was performed.

All three callers use the identical operation and therefore produce the same
generic throw at `Wait-UiNode` line `373`:

- line `1260`: progress-47 `İlerlemeyi güncelle` form
- line `1282`: note-edit form
- line `1387`: progress-63 `İlerlemeyi güncelle` form

The existing output contains no caller tag, stack context, checkpoint output or
failure hierarchy. The last semantic step common to every possible path is that
the first progress editor title `İlerlemeyi güncelle` was found, its value was
replaced with `47`, and the keyboard-back step returned. Evidence does not prove
whether the following line-1260 save failed or succeeded and execution later
reached the note or progress-63 save.

`Find-UiNode` already checks both exact `text` and exact `content-desc`, with
clickability required here. Without the failure hierarchy, evidence cannot prove
whether the correct save surface was standalone text, combined semantics, a
form-anchored descendant, a key/resource selector, or whether navigation/state
was wrong. Exact caller, exact immediately preceding successful step and defect
class therefore cannot be determined without guessing. Stop
`diagnosis_insufficient` for new owner authority.

## Owner authority `5386943692` — observability correction / diagnostic FAIL

Exactly one runner-only observability correction added stable labels for the
three `Kaydet` callers and bounded failure hierarchy JSON capture. Existing
`Wait-UiNode('Kaydet', clickable)` attempts, exact text/content-desc matching,
tap/navigation and every fixture/product/application assertion remained
unchanged. PowerShell parse PASS, release/static `6/6 PASS`; APK remained
`96893055` bytes with SHA-256
`1609a5daa4c1eeef3ded5f7ec10923f38d0c32db038a014bb206bbe14e403167`.

The exactly-one diagnostic Device invocation PASSed device/package baseline and
`install -r` for only `com.faliardic.sefim.acceptance`, but failed before any
`DIAGNOSTIC_KAYDET_CHECKPOINT` was emitted. Exact caller was
`Run-LivingPlanAcceptanceFlow`, first UI assertion at current runner line `1225`:

```text
Wait-UiNode -Text 'Başlangıç' -Contains
Acceptance UI text was not found: Başlangıç
```

The preceding successful operational checkpoint was acceptance-package launch
via `am start -W`; no flow semantic checkpoint had yet passed. Read-only failure
hierarchy contained `Kabul ortamı · sentetik veri`,
`Uygulama güvenli biçimde başlatılamadı.`, the non-repeat warning, and stable
`Tanı kodu: acceptance_fixture_failed`, all on `content-desc`; `Başlangıç` was
absent from both text and content-desc. Therefore this failure is exactly
acceptance fixture/state initialization, not a `Başlangıç` selector mismatch and
not a reached `Kaydet` caller. No second correction or Device retry; stop
fail-closed for new owner authority.

## Owner authority `5387002495` — read-only fixture diagnosis

Acceptance-package-only diagnosis used the foreground activity/semantics,
PID-filtered logs, fixture/catch source, and a binary read-only copy of only
`com.faliardic.sefim.acceptance` database under system temp. Production/debug
package data was not accessed and device/package state was not mutated.

The exact first failing fixture stage is `_completeLegacyRunnerItem`. Current
snapshot `57612536-6036-48d9-930e-66d8df12c837` is dependency-capable and
contains activity instance `TR-BLD-01-002-MOBILIZASYON-PLANI@PROJECT`. Candidate
binding therefore resolves to acceptance-owned item
`cb502e04-1a84-4acd-8b40-738766785bb0`, currently `STARTED`, progress `47`,
revision `22`, historical snapshot
`900beb90-4695-41a6-853d-1cd12c0a46d1`.

Fixture completion reuses fixed event ID
`47600000-0000-4000-8000-000000000036`, whose durable receipt already records
`COMPLETED` intent at expected revision `18` and result revision `19`. The
current expected revision `22` changes the canonical intent, so replay-first
mutation deterministically throws
`ConstructionLivingPlanFailure(living_plan_event_id_conflict)`. This is a stale
acceptance fixture recovery event-ID defect, not production UI/application/
domain behavior. The single correction budget will be used for one narrow
fixture fix plus its focused regression.

## Owner authority `5387002495` — correction gate FAIL / fail-closed

The one correction budget was consumed by replacing the legacy runner cleanup's
reused fixed event ID with a revision-scoped deterministic fixture UUID and by
adding its focused regression in the already-authorized bootstrap test path.
No production application/UI/domain behavior or acceptance assertion changed.

The relevant focused fixture test was invoked exactly once. It failed before
exercising the recovery assertion because the unit-test process could not load
the bundled construction corpus:

```text
corpus_load_failed
package:chief_site_engineer/application/construction_corpus_repository.dart 47:7
```

The single correction budget is exhausted. No test setup edit, focused retry,
release/static test, analyze, full Flutter, diff gate, generated cleanup, Build,
Device, commit, push or PR operation is authorized in this cycle. Exact WIP
remains `16/16`, staged `0`, protected/platform drift `0`, schema `17`, backup
format `1`, version `0.1.0+1`. Stop fail-closed pending new owner authority.

## Owner authority `5387336963` — read-only corpus failure diagnosis

The failed focused invocation reached the fixture's first bundled corpus load.
The canonical activity-corpus asset exists at the declared pubspec path, is
`19205` bytes, and retains expected SHA-256
`a9b225d6403168f7d3fd35494eceb4907d1ea705492700bc865add95021f42ca`.
No pubspec/lock, bundled asset, generated-state or corpus repository drift is
present.

`BundledConstructionCorpusRepository` defaults to `rootBundle.loadString`.
Every existing passing corpus/schedule/Living Plan test that uses this loader
initializes `TestWidgetsFlutterBinding`; the newly added focused bootstrap
regression does not. Its first `rootBundle` call therefore throws the framework
binding initialization `FlutterError`, whose stable message begins
`Binding has not yet been initialized`, and the repository's broad loader catch
maps it to `ConstructionCorpusFailure(corpus_load_failed)`. Classification:
existing-allowlist test-harness defect. Preserve the revision-scoped fixture
UUID correction; use one remaining narrow source correction only to initialize
the Flutter test binding, then retry only the invalidated focused gate once.

## Owner authority `5387336963` — stabilization gates and terminal parse FAIL

One narrow test-harness correction added
`TestWidgetsFlutterBinding.ensureInitialized()`; the revision-scoped fixture
event UUID correction remained byte-identical. The exact focused retry PASSed
`1/1`. Release/static remained reusable because it does not read the fixture and
the runner was then unchanged. Final `flutter analyze --no-pub` PASSed and the
single final full Flutter invocation PASSed `753/753`.

Authorized generated cleanup removed only worktree-local `mobile/build/` and
`mobile/ios/Flutter/ephemeral/`. The exactly-one fresh Build-mode invocation
PASSed and produced package `com.faliardic.sefim.acceptance`, label `Şefim`,
`arm64-v8a`, `96893447` bytes, SHA-256
`3395793c47568bedf9e5eadb4f6eaa2fcc4df85f35b09ef97a1c8da48658eea6`.

Before Device, the remaining final narrow correction was used to make every
runner failure emit the authority-required global checkpoint, hierarchy,
filtered diagnostics, fixture state and APK/source digests. Its mandatory
PowerShell parse gate FAILed at line `352`, column `62`, exact extent
`$AnchorText:`: the interpolation needs an explicit variable delimiter before
the colon. The two remaining source correction budgets are now exhausted.
Per immediate-stop authority, do not edit, run static, invoke Device, commit,
push or create a PR. Stop fail-closed for owner escalation.
## Owner authority `5387491798` — runner-only closure window

The authority-mandated parser correction changed only ambiguous
`$AnchorText:` interpolation to `${AnchorText}:`; PowerShell parse and the
release/static focused suite PASSed `6/6`. Frozen APK inputs remained
byte-identical, so no Flutter focused/analyze/full/Build gate was rerun and the
verified APK remained `96893447` bytes / SHA-256
`3395793c47568bedf9e5eadb4f6eaa2fcc4df85f35b09ef97a1c8da48658eea6`.

Two root-cause-proven additional runner-only corrections were consumed:

1. Failure diagnostics read `InvocationInfo.MyCommand.Name` under strict mode
   even when `MyCommand` had no `Name` property. It now records the safe string
   representation. Parse and release/static PASSed; the exact current failure
   checkpoint emitted summary, bounded hierarchy, current window, PID-filtered
   diagnostics, fixture state and APK/source digests without masking the error.
2. Lifecycle action lookup accepted an exact semantics node whose tap centre
   could be covered by the fixed `İmalat ekle` FAB. The runner now scrolls and
   resolves the same exact item/action again only while that tap point is
   covered. Parse and release/static PASSed. The exact `note_update_save`
   checkpoint proved `pre_blocked=True`, `corrected_blocked=False`, found the
   single note field and clickable `Kaydet`, then closed without a data write;
   synthetic state remained `STARTED`, progress `47`, revision `26` and
   six-package isolation remained exact.

The exactly-one final full isolated Device invocation FAILed during
`Assert-RelaunchPersistence`: after relaunch the UI was on the
`23.08.2026`–`29.08.2026` window while the target synthetic item remained bound
outside that window at `09.08.2026`, so bounded list scroll could not find
`Acceptance persistence notu guncellendi`. The same failure evidence also
reported the target as `COMPLETED`, progress `100`, revision `36`, which does
not match the flow's expected relaunch projection `STARTED`, progress `63`.
The runner-only budget is exhausted and any further runner or fixture/Dart
correction requires new authority. Stop fail-closed: no retry, commit, push or
PR.

## CleanAcceptance relaunch closure — fail-closed execution

Authority: https://github.com/faliardic/chief-site-engineer/issues/476#issuecomment-5390393976
Timestamp UTC: 2026-08-24T04:07:01.5960784Z

The Issue body and latest owner authority were read in full. Read-only preflight
PASSed exact branch/HEAD `cc7c49fa30b50aae09b349eb0bfa1161c5cdc814`,
16/16 WIP, staged 0, protected/platform drift 0, one usable
`R5CY21WKZFX` arm64 device, offline/unauthorized 0, and the required
six-package inventory.

The exact acceptance APK remained `com.faliardic.sefim.acceptance`,
96,893,447 bytes, SHA-256
`3395793c47568bedf9e5eadb4f6eaa2fcc4df85f35b09ef97a1c8da48658eea6`.
Package/label/activity/ABI and every APK input digest PASSed.

Read-only audit proved no bounded relaunch-only scenario existed. The one
authorized runner-only correction added `CleanRelaunch` isolation,
deterministic baseline/relaunch checks and failure screenshot evidence. APK
inputs did not change. PowerShell parse PASSed with 0 errors and release/static
PASSed 6/6. The initial bare `flutter` lookup opened no test body; the
pinned SDK ran the static suite once.

Authorized reset ran only:
`pm clear --user 0 com.faliardic.sefim.acceptance` → `Success`.

The exactly-one Stage A invocation proved all functional checkpoints:

- active window and target date: `2026-08-24`
- exact three-item fixture; no stale runner item/window
- baseline target: `STARTED / 47 / revision 3`
- neighbors: `PLANNED / NULL / revision 1 / 2026-08-23` and
  `STARTED / NULL / revision 2 / 2026-08-24`
- mutation: exact `PROGRESS_UPDATED` to
  `STARTED / 63 / revision 4 / 2026-08-24`
- force-stop/relaunch preserved target and neighbors
- fatal diagnostics absent; final six-package isolation PASSed

The invocation nevertheless exited FAIL at runner line 2025 while printing its
PASS summary. `Run-CleanAcceptanceRelaunchScenario` emitted additional
pipeline output, so `$stageAResult` was an aggregate without
`targetItemId`. This is a runner result-aggregation defect after all
Stage A assertions, not a fixture or product defect.

Same-invocation screenshot:
`C:\Users\Fatih\AppData\Local\Temp\cse-device-failure-8afbed0e1c094d6f9133aa691aaa3ad1.png`,
108,819 bytes, SHA-256
`f26db6456149819947d554c29860e4aa256bb5114d88d9bb22baf487f95422f6`.

The runner-only correction budget is exhausted. The unused fixture correction
does not apply. Fail-closed: no second runner edit/Stage A invocation, no Stage
B clear/full Device invocation, no commit, push or PR.

## Owner authority `5390660956` — runner-only Stage A normalization closure

The authorized runner-only correction normalized
`Run-CleanAcceptanceRelaunchScenario` output by selecting the final emitted
object with `@(...)[-1]`. No fixture, Dart, product, assertion, navigation,
package-mutation or APK-input behavior changed. PowerShell parse PASSed with
zero errors and release/static PASSed `6/6`; Flutter focused tests, analyze,
full Flutter and Build were not rerun because APK inputs remained identical.

The first outer closure attempt stopped before Stage A because ADB daemon-start
diagnostics preceded the successful `pm clear` result. Read-only evidence proved
the acceptance package clear itself succeeded. The one additional authorized
runner-only correction normalized that outer clear check to native exit code
zero plus final non-empty line exactly `Success`; parser and release/static
again PASSed without a repository edit for this wrapper-only correction.

The corrected combined closure then ran the authorized sequence once. Stage A
PASSed clean baseline, progress mutation and force-stop/relaunch persistence for
item `47600000-0000-4000-8000-000000000041` at `STARTED / 63 / revision 4 /
2026-08-24`, followed by exact isolation and fatal-diagnostic checks. The second
acceptance-only clear succeeded and Stage B opened from a fresh fixture.

Stage B FAILed at runner line 533 in `Get-ScrollableNode`, reached from
`Assert-LifecycleCheckpoint` through `Set-LivingPlanWindowForDate`, with exact
message `Acceptance UI has no selector-derived scrollable boundary.` The
bounded failure hierarchy contained the Living Plan `ScrollView`, the active
`10.08.2026` window selector, and the generated Mobilizasyon item, but the
runner could not derive its selector boundary. Same-invocation evidence includes
the hierarchy, screenshot, current window, PID-filtered diagnostics, fresh
fixture state and APK/source digests.

The additional correction budget is exhausted. Stop fail-closed: no further
runner/source edit, Device invocation, package clear, test, Build, commit, push
or Draft PR without new owner authority.

## Owner publication authority `5396110781`

Authority: https://github.com/faliardic/chief-site-engineer/issues/476#issuecomment-5396110781
Canonical master: `eeec91673069ef6518295f7fdce97352015f5936`.

The merged `origin/master` AGENTS and workflow acceleration protocol, Issue
#479, this authority, and task/result EOF were read in full. The
documentation-only master commit was not merged into the uncommitted WIP.

Exact publication status: `IMPLEMENTED — MANUAL TEST PENDING`.

Source-level publication preflight PASSed:

- authorized WIP paths: exact `16/16`
- staged paths: `0`
- unexpected user changes: `0`
- protected-path drift: `0`
- `git diff --check`: PASS
- schema / backup / version: `17 / 1 / 0.1.0+1`
- pubspec/lock drift: `0`
- platform-production drift: `0`

No automated application test, Flutter test, analyzer, build, scripted UI,
ADB/device flow, install, launch, force-stop or package clear was run under
the owner-led manual testing policy. No new automated correction was made.

Manual Test Register: https://github.com/faliardic/chief-site-engineer/issues/479
Stable tests `MT-476-001..013` remain `PENDING`.

Historical automated evidence and failures remain factual history only; they
were not reused as an owner manual PASS and do not support a `VERIFIED`,
`FIELD_ACCEPTED`, `PRODUCTION_READY` or `RELEASE_READY` claim.

Publication is authorized next as one minimal intentional commit, normal push
and one Draft PR against current master. Ready, merge, Issue/Epic closure,
V2.5 completion and V2.6 work remain forbidden.
