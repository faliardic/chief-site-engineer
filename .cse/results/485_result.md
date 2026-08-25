# Issue #485 — Execution Result

## Outcome

`FAIL-CLOSED — FINAL SOURCE ANALYZER FAILED`

Implementation source is present as uncommitted WIP on
`codex/issue-485-material-requests-v1` at exact base
`dbe370e61b5ece843238c35e049bbaa4e7df19cb`, but publication gates did not
all pass. The implementation must not be described as verified, published or
production-ready.

## Implemented WIP

- Additive schema `17 → 18` introduces only
  `material_requests`, `material_request_events`, indexes and triggers.
- Canonical lifecycle is `needed → requested/cancelled`,
  `requested → received/cancelled` and explicit
  `received/cancelled → needed` reopen.
- Optimistic revision, source-row/event transaction, append-only event guards,
  event-ID replay/collision checks, physical-delete rejection and exact
  same-project mahal/Living Plan validation are implemented.
- Home includes exact project selection, `+ Malzeme` capture,
  open/history lists, quick lifecycle actions and append-only detail history.
- Backup format and application version were not changed.

## Final source gate evidence

- Touched Dart format: completed for six authorized Dart files.
- Generated metadata preparation: the official worktree and isolated worktree
  `pubspec.lock` SHA-256 were both
  `2B75E59A051A8CFCFEC3D6883B04779205C63678B0F4814A4535E50DB77DC441`.
  Three ignored `.dart_tool` metadata files were copied byte-identically;
  no tracked dependency file changed.
- Exactly one `flutter analyze --no-pub`: exit `1`,
  `13 issues found`.
- All 13 diagnostics were
  `prefer_interpolation_to_compose_strings` info lints:
  one in `material_request_application.dart` and twelve in
  `material_requests_page.dart`.
- Compile errors: `0` reported.
- `git diff --check`: PASS.
- Pre-result changed paths: `11/12`; unexpected paths `0`.
- Staged paths: `0`.
- Schema source: exact `18`.
- Additive migration audit: no added `ALTER TABLE`, `DROP TABLE`,
  table rename, existing-row `UPDATE` or `DELETE FROM` statement.
  Added UPDATE/DELETE tokens are only immutability/guard trigger clauses on the
  two new material tables.
- Backup format: exact `1`.
- Version: exact `0.1.0+1`.
- `pubspec.yaml` / `pubspec.lock` drift: `0`.
- Android/iOS platform-production drift: `0`.

## Explicitly not run

- Flutter unit, widget, integration or full tests
- APK/AAB build
- emulator, ADB or device acceptance
- scripted UI acceptance
- application launch
- real user data access

This follows the owner-led manual testing policy; no PASS result was invented.

## Publication status

- Commit: not created
- Push: not performed
- Draft PR: not created
- Issue #485 completion evidence: not posted
- Issue #479 MT-485 register entries: not posted
- Ready / merge / Issue close / V2.8 complete / V2.9: not performed

## execution_record

```yaml
policy_version: CSE-MRP-1.0
task_risk: R4
requested_model: gpt-5.6-sol
requested_reasoning_effort: max
actual_model: unknown
actual_reasoning_effort: null
invocation_verification_status: unverified
execution_mode: standard
orchestration: single-agent
verification_mode: owner_led_manual_testing
implementation_status: IN_PROGRESS
manual_test_status: PENDING
source_gate_status: FAIL
publication_status: NOT_PUBLISHED
failure_code: final_flutter_analyze_info_lints
analyzer_invocations: 1
analyzer_retry_authorized: false
```

## review_recommendation

Do not publish or request independent source review from this revision. Preserve
the exact WIP and request owner authority for the narrow interpolation-only
source correction plus a new analyzer invocation. The application tests remain
owner-led and were not opened.
## Owner-authorized correction result — PASS

Owner authority `5412555097` authorized only the exact 13 analyzer-reported
interpolation lints and one analyzer retry. The earlier FAIL record above remains
historical evidence and is superseded for publication by this correction result.

### Correction proof

- Preflight: exact `12/12` WIP, staged `0`, unexpected path `0`.
- Corrected paths:
  - `mobile/lib/application/material_request_application.dart`
  - `mobile/lib/features/material_requests/material_requests_page.dart`
- Change type: string composition to Dart interpolation only.
- Exact analyzer sites corrected: `13`.
- Other ten WIP paths: byte-identical to the frozen pre-correction SHA-256
  manifest.
- Touched-file format: `2 files / 0 changed`.
- Single authorized analyzer retry: `PASS`, exit `0`,
  `No issues found`.

### Final source-level verification

- Exact changed paths: `12/12`.
- Unexpected/protected drift: `0`.
- `git diff --check`: PASS.
- Schema: exact `18`.
- Migration: additive-only; no existing-table rename/rebuild and no
  existing-user-row rewrite.
- Backup format: exact `1`.
- Version: exact `0.1.0+1`.
- Pubspec/lock drift: `0`.
- Platform-production drift: `0`.
- Flutter application tests/build/device/scripted acceptance: not run by
  explicit owner-led manual testing policy.

### Publication classification

`IMPLEMENTED — MANUAL TEST PENDING`

Stable `MT-485-001..017` tests are PENDING for Issue #479 registration.
This is not VERIFIED, FIELD_ACCEPTED, PRODUCTION_READY or RELEASE_READY.

### execution_record

```yaml
policy_version: CSE-MRP-1.0
task_risk: R4
requested_model: gpt-5.6-sol
requested_reasoning_effort: max
actual_model: unknown
actual_reasoning_effort: null
invocation_verification_status: unverified
execution_mode: standard
orchestration: single-agent
verification_mode: owner_led_manual_testing
implementation_status: IMPLEMENTED
manual_test_status: PENDING
source_gate_status: PASS
analyzer_retry_invocations: 1
application_tests_run: false
build_run: false
device_run: false
publication_status: AUTHORIZED
```

### review_recommendation

Publish as one Draft PR and request independent ChatGPT source/diff review.
Keep the PR Draft and retain all MT-485 tests as PENDING until owner-reported
manual results. Do not mark Ready, merge, close Issue #485, declare V2.8
complete, update the Epic checkbox or begin V2.9.

## Independent-review correction result — FAIL / fail-closed

Owner authority: Issue #485 comment `5413025911`.

### Applied source correction

- Exact published starting head:
  `a53c88ec869b1465023313ba30a4543c6cf38541`.
- Source edits remained within the existing 12-path allowlist:
  `app_database.dart`, `material_request_application.dart`,
  `app_bootstrap.dart`, and `material_requests_page.dart`.
- Timestamp correction count: exactly four dynamic Material Request row
  references. The event timestamp trigger remained outside the diff.
- Shared coordinator correction: bootstrap passes its existing coordinator and
  the complete database open/action/close boundary is queued by
  `coordinator.run(...)`.
- Quantity correction: validation and submit share one parser accepting decimal
  comma or point; positive finite and quantity/unit pairing checks remain;
  display no longer performs lossy fixed-two-decimal rounding.
- Touched Dart formatting: PASS, `4 files / 0 changed`.

### Source gate failure

The single authorized `flutter analyze --no-pub` invocation returned exit
code `1`:

- `app_database.dart:4134:47` —
  `unnecessary_brace_in_string_interps`
- `app_database.dart:4136:47` —
  `unnecessary_brace_in_string_interps`
- `app_database.dart:4150:47` —
  `unnecessary_brace_in_string_interps`
- `app_database.dart:4152:47` —
  `unnecessary_brace_in_string_interps`

No unrelated analyzer diagnostic was reported. Nevertheless, the required
analyzer gate did not PASS and its exactly-one invocation budget is exhausted.
No second edit or retry was made. Downstream publication gates were not used.

### execution_record

~~~yaml
policy_version: CSE-MRP-1.0
task_risk: R4
requested_model: gpt-5.6-sol
requested_reasoning_effort: max
actual_model: unknown
actual_reasoning_effort: null
invocation_verification_status: unverified
execution_mode: standard
orchestration: single-agent
verification_mode: owner_led_manual_testing
implementation_status: IN_PROGRESS
manual_test_status: PENDING
manual_test_ids: MT-485-001..019
source_gate_status: FAIL
failure_code: correction_analyzer_unnecessary_interpolation_braces
analyzer_invocations_this_authority: 1
analyzer_retry_authorized: false
application_tests_run: false
build_run: false
device_run: false
publication_status: BLOCKED
published_head_unchanged: a53c88ec869b1465023313ba30a4543c6cf38541
~~~

### review_recommendation

Preserve the exact correction WIP and request a narrow owner authority for the
four semantic-no-op interpolation brace removals plus one new analyzer
invocation. Keep Draft PR #486 unchanged and all manual tests PENDING. Do not
mark Ready, merge, close Issue #485, declare V2.8 complete, update the Epic
checkbox or begin V2.9.

## Final lint correction and source publication gates — PASS

Owner authority: Issue #485 comment `5413317956`.

### Correction proof

- Starting published head:
  `a53c88ec869b1465023313ba30a4543c6cf38541`.
- Exact correction: four
  `unnecessary_brace_in_string_interps` sites changed from braced to simple
  Dart interpolation in `app_database.dart`.
- Source meaning is unchanged: each trigger template emits a valid
  `NEW.<timestamp_column>` SQLite reference.
- No other migration, SQL, application, coordinator, UI, validation, quantity
  or lifecycle behavior was changed in this lint pass.
- Touched formatting: `1 file / 0 changed`.
- Single authorized analyzer invocation: PASS, exit `0`,
  `No issues found`.

### Final source-level verification

- Exact changed paths against master: `12/12`.
- Unexpected/protected drift: `0`.
- Staged before publication: `0`.
- `git diff --check`: PASS.
- Schema: exact `18`.
- Migration: additive-only; two new material tables; existing table
  rename/rebuild and existing user-row rewrite statements: `0`.
- Backup format: exact `1`.
- Version: exact `0.1.0+1`.
- Pubspec/lock drift: `0`.
- Platform-production drift: `0`.
- Flutter application tests and scripted acceptance: not run.
- Manual tests `MT-485-001..019`: `PENDING`.

### execution_record

~~~yaml
policy_version: CSE-MRP-1.0
task_risk: R4
requested_model: gpt-5.6-sol
requested_reasoning_effort: max
actual_model: unknown
actual_reasoning_effort: null
invocation_verification_status: unverified
execution_mode: standard
orchestration: single-agent
verification_mode: owner_led_manual_testing
implementation_status: IMPLEMENTED
manual_test_status: PENDING
manual_test_ids: MT-485-001..019
source_gate_status: PASS
analyzer_invocations_this_authority: 1
application_tests_run: false
scripted_acceptance_run: false
artifact_stage_status: PENDING
device_stage_status: PENDING
publication_status: AUTHORIZED_PENDING_COMMIT
ready: false
merge: false
~~~

### review_recommendation

Create and push the single correction commit, update Draft PR #486 and Issue
#485 evidence, then proceed only with the owner-authorized acceptance debug
arm64 APK build and user-0 install/launch handoff. Keep the PR Draft.

## Owner-requested acceptance artifact result — FAIL / no artifact

### Published source state

- Correction commit:
  `bf5120989193a315da100d32cefd50451d6d4d74`
- Normal push: PASS.
- Draft PR #486: open and Draft.
- Source analyzer and all source publication gates: PASS.

### Primary build evidence

Invocation contract:

- acceptance harness: enabled
- build type: debug
- target ABI: android-arm64
- dependency resolution: `--no-pub`
- Gradle workers: `1`
- parallel build: disabled
- persistent daemon: disabled through invocation-local options

Result:

- Gradle task: `:app:compileDebugJavaWithJavac`
- exit code: `1`
- failure source:
  `mobile/android/app/src/main/java/com/dexterous/flutterlocalnotifications/CseReminderBootReceiver.java:25`
- diagnostic:
  `cannot find symbol: class ScheduledNotificationBootReceiver`
- pinned plugin: `flutter_local_notifications 22.1.0`
- read-only plugin-source proof: the referenced public class exists in the
  pinned plugin source, but was not resolved by the app-module compile surface.
- generated-state classification: not an authorized stale/read-only
  `mobile/build/` or `mobile/ios/Flutter/ephemeral/` blocker.
- cleanup used: none.
- build retry used: none.
- fresh APK: absent.
- APK path/size/SHA/package/label/version/activity/ABI: unavailable.

### Device safety result

Device preflight and ADB were not opened because the host build gate failed.
No install, uninstall, clear, launch, package inventory or user-data access
occurred. Production package, normal debug package, acceptance package and
Secure Folder user 150 were untouched.

### execution_record

~~~yaml
policy_version: CSE-MRP-1.0
task_risk: R4
requested_model: gpt-5.6-sol
requested_reasoning_effort: max
actual_model: unknown
actual_reasoning_effort: null
invocation_verification_status: unverified
execution_mode: standard
orchestration: single-agent
verification_mode: owner_led_manual_testing
phone_connection_required: true
artifact_mode: acceptance_debug_arm64
source_gate_status: PASS
source_commit: bf5120989193a315da100d32cefd50451d6d4d74
primary_build_invocations: 1
primary_build_status: FAIL
build_retry_authorized_for_failure: false
fresh_artifact_available: false
device_preflight_run: false
install_run: false
launch_run: false
manual_test_status: PENDING
manual_test_ids: MT-485-001..019
ready: false
merge: false
~~~

### review_recommendation

Keep Draft PR #486 at the published source correction. Request a narrow owner
correction authority for the Android notification receiver compile integration
blocker before any new build. Do not use generated-state cleanup or retry this
build, and do not enter device install/launch without a fresh verified
acceptance APK.

## Android receiver linkage correction and artifact verification — PASS

### Source/static correction

- Exact reflection delegation contract: PASS.
- Obsolete compile-time constructor reference: absent.
- Direct
  `FlutterLocalNotificationsPlugin.rescheduleNotifications` call: absent.
- Static source contract updated within the newly authorized test path.
- Existing task/result evidence prefix preserved append-only.
- Exact total allowlist: `14/14`; unexpected/protected drift: `0`.
- Manifest, Gradle, dependency, pubspec/lock and unauthorized platform edits:
  `0`.
- Schema: `18`; backup format: `1`; version: `0.1.0+1`.
- `git diff --check`: PASS.
- Flutter tests and analyzer invocations in this authority: `0`.

### Fresh acceptance artifact

- Build invocation count: `1`.
- Build status: PASS.
- Build mode: acceptance debug, android-arm64, `--no-pub`.
- APK:
  `V:\1_PROJECTS\2_ACTIVE\Python\CSE-Worktrees\issue-485-material-requests-v1\mobile\build\app\outputs\flutter-apk\app-debug.apk`
- Size: `93036159` bytes.
- SHA-256:
  `F6CC0D8365F7FD62C618352FFC960A8C248244A9A3035EC3D62528FC84BD23C2`.
- Package: `com.faliardic.sefim.acceptance`.
- Label: `Şefim`.
- versionName/versionCode: `0.1.0-acceptance` / `1`.
- Launchable activity:
  `com.faliardic.chiefsiteengineer.MainActivity`.
- Native ABI: exact `arm64-v8a`.

### execution_record

~~~yaml
policy_version: CSE-MRP-1.0
task_risk: R4
requested_model: gpt-5.6-sol
requested_reasoning_effort: max
actual_model: unknown
actual_reasoning_effort: null
invocation_verification_status: unverified
execution_mode: standard
orchestration: single-agent
verification_mode: owner_led_manual_testing
source_static_gate_status: PASS
flutter_tests_run: false
analyzer_rerun: false
fresh_build_invocations: 1
fresh_build_status: PASS
artifact_package: com.faliardic.sefim.acceptance
artifact_sha256: F6CC0D8365F7FD62C618352FFC960A8C248244A9A3035EC3D62528FC84BD23C2
artifact_bytes: 93036159
device_stage_status: PENDING
manual_test_status: PENDING
manual_test_ids: MT-485-001..019
ready: false
merge: false
~~~

### review_recommendation

Commit and normally push this four-path local correction/evidence set, update
Issue #485 and Draft PR #486, then use only the verified APK above for the
authorized user-0 device preflight/install/launch handoff.

## Device handoff result — FAIL-CLOSED at preflight

The verified artifact and published correction are valid, but no physical
device was visible to ADB at the authorized preflight.

- Device entries: `0`.
- ADB state `device`: `0`.
- Offline: `0`.
- Unauthorized: `0`.
- Device model / Android / API / ABI / users: unavailable.
- Protected package inventory: not opened.
- User-0 install: not run.
- Launch / foreground / immediate-crash check: not run.
- Production/debug/acceptance/Secure Folder mutation: none.
- Fresh APK remains at the verified host path with SHA-256
  `F6CC0D8365F7FD62C618352FFC960A8C248244A9A3035EC3D62528FC84BD23C2`.

### execution_record

~~~yaml
policy_version: CSE-MRP-1.0
task_risk: R4
requested_model: gpt-5.6-sol
requested_reasoning_effort: max
actual_model: unknown
actual_reasoning_effort: null
invocation_verification_status: unverified
verification_mode: owner_led_manual_testing
source_commit: dc87f1980dbc79069317134c6c0cdf94c3e1bc6a
source_static_gate_status: PASS
fresh_build_status: PASS
artifact_sha256: F6CC0D8365F7FD62C618352FFC960A8C248244A9A3035EC3D62528FC84BD23C2
device_preflight_invocations: 1
device_preflight_status: FAIL
device_entries: 0
install_run: false
launch_run: false
manual_test_status: PENDING
manual_test_ids: MT-485-001..019
ready: false
merge: false
~~~

### review_recommendation

Preserve the verified APK and published Draft PR. Resume only after one physical
ADB device is connected and a new owner authority permits a fresh device
preflight/install/launch attempt. Do not rebuild, reinstall, clear, uninstall or
modify protected packages from this failed preflight state.

## Existing frozen APK install/launch authority result — FAIL-CLOSED

Owner authority: Issue #485 comment `5413680219`.

### Artifact preflight

- Path: exact expected acceptance APK.
- Size: `93036159` bytes — PASS.
- SHA-256:
  `F6CC0D8365F7FD62C618352FFC960A8C248244A9A3035EC3D62528FC84BD23C2`
  — PASS.
- Rebuild: not run.

### Device preflight

- Total ADB device entries: `0`.
- Usable state `device`: `0`.
- Offline: `0`.
- Unauthorized: `0`.
- Physical-device cardinality requirement: FAIL.
- Device model / Android / API / ABI / users: unavailable.
- Protected package inventory: not opened.
- Install invocation: `0`.
- Launch invocation: `0`.
- Production/debug/acceptance/Secure Folder mutation: none.

### execution_record

~~~yaml
policy_version: CSE-MRP-1.0
task_risk: R2
requested_model: gpt-5.6-sol
requested_reasoning_effort: high
actual_model: unknown
actual_reasoning_effort: null
invocation_verification_status: unverified
verification_mode: owner_led_manual_testing
rebuild_authorized: false
automated_tests_authorized: false
artifact_preflight_status: PASS
artifact_sha256: F6CC0D8365F7FD62C618352FFC960A8C248244A9A3035EC3D62528FC84BD23C2
device_preflight_status: FAIL
device_entries: 0
install_run: false
launch_run: false
manual_test_status: PENDING
manual_test_ids: MT-485-001..019
ready: false
merge: false
issue_close: false
v2_8_complete: false
v2_9: not_started
~~~

### review_recommendation

Connect, unlock and authorize exactly one physical Android device before any
new authority is used. Preserve the frozen APK and avoid rebuild. Do not retry
install/launch without a passing fresh device preflight.

## Final device installation and launch handoff — PASS

### Frozen artifact

- Path: exact verified acceptance APK.
- Size: `93036159` bytes.
- SHA-256:
  `F6CC0D8365F7FD62C618352FFC960A8C248244A9A3035EC3D62528FC84BD23C2`.
- Rebuild: not run.

### Device and user scope

- Serial: `R5CY21WKZFX`.
- Manufacturer/model: Samsung `SM-S938B`.
- Android/API: `16` / `36`.
- Physical device count: `1`.
- State: `device`.
- ABI: `arm64-v8a`.
- Owner user: `0`.
- Secure Folder user `150`: present; inventory request was read-only and
  platform-denied; mutation `0`.

### Install and launch

- Install command scope: acceptance package, user 0, replacement install.
- Install result: PASS — `Success`.
- Install retries: `0`.
- Uninstall / clear / downgrade: `0`.
- Launch invocations: exactly `1`.
- Launch result: PASS.
- Foreground:
  `com.faliardic.sefim.acceptance/com.faliardic.chiefsiteengineer.MainActivity`.
- Acceptance PID after launch: `8402`.
- Immediate fatal crash in bounded PID/package-filtered observation: `0`.
- Application left installed and foreground.
- Production/debug package mutation: `0`.
- Scripted UI acceptance, fixture, form automation and user-data inspection:
  `0`.

### execution_record

~~~yaml
policy_version: CSE-MRP-1.0
task_risk: R2
requested_model: gpt-5.6-sol
requested_reasoning_effort: high
actual_model: unknown
actual_reasoning_effort: null
invocation_verification_status: unverified
verification_mode: owner_led_manual_testing
source_head: dc87f1980dbc79069317134c6c0cdf94c3e1bc6a
artifact_preflight_status: PASS
artifact_sha256: F6CC0D8365F7FD62C618352FFC960A8C248244A9A3035EC3D62528FC84BD23C2
device_preflight_status: PASS
device_serial: R5CY21WKZFX
device_model: SM-S938B
android_version: 16
api_level: 36
install_invocations: 1
install_status: PASS
launch_invocations: 1
launch_status: PASS
foreground_status: PASS
immediate_fatal_crash: false
acceptance_left_installed: true
production_package_mutated: false
debug_package_mutated: false
secure_folder_mutated: false
manual_test_status: PENDING
manual_test_ids: MT-485-001..019
ready: false
merge: false
issue_close: false
v2_8_complete: false
v2_9: not_started
~~~

### review_recommendation

Commit and normally push only these two final evidence files, update Issue #485
and Draft PR #486, then stop for owner-led manual tests and independent review.
Keep the PR Draft; do not mark Ready, merge, close the Issue, declare V2.8
complete or begin V2.9.

## Startup failure diagnosis result — exact platform root cause

### Device reproduction

- Device: Samsung `SM-S938B`, Android `16`, API `36`,
  `arm64-v8a`, owner user `0`.
- Package: `com.faliardic.sefim.acceptance`,
  `0.1.0-acceptance` / `1`.
- Force-stop: acceptance process only, PASS.
- Diagnosis launch: exactly `1`, PASS.
- Foreground activity: exact acceptance `MainActivity`.
- Owner-visible result retained without UI automation:
  `Uygulama güvenli biçimde başlatılamadı.`

### Exact error and first failing operation

Observed native exception:

`java.lang.ClassNotFoundException:
io.flutter.plugins.GeneratedPluginRegistrant`

Observed stack:

1. `GeneratedPluginRegister.registerGeneratedPlugins`
2. `FlutterActivity.configureFlutterEngine`
3. `MainActivity.configureFlutterEngine(MainActivity.kt:27)`

Static/build proof:

- generated registrant files: `0`;
- `.flutter-plugins-dependencies`: absent;
- pinned path_provider/sqflite plugin packages: present.

AppBootstrap order proves the first application operation requiring a plugin is
`directoriesProvider()`, whose production implementation calls
`getApplicationSupportDirectory()`. Plugin registration has already failed,
so bootstrap exits through the generic `on Object` as
`BootstrapFailure(code: startup_failed)` before database creation/open.

Negative evidence in the bounded PID/package log window:

- SQLiteLog/sqflite DatabaseException: `0`;
- material migration/schema/foreign-key/trigger failure: `0`;
- attendance/agenda/restore stage failure: `0`.

Classification: **F — Android/plugin/platform**.

### Correction decision

No correction was applied. The defect is not schema-18 Material Request SQL or
current #485 bootstrap wiring; resolving missing generated plugin registration
requires a generated metadata/build-pipeline action outside the currently
authorized product paths. Per authority, diagnosis stopped fail-closed.

No source edit, analyzer, Flutter test, fresh build, reinstall, clear, uninstall
or production/debug/Secure Folder mutation was performed.

### execution_record

~~~yaml
policy_version: CSE-MRP-1.0
task_risk: R4
requested_model: gpt-5.6-sol
requested_reasoning_effort: max
actual_model: unknown
actual_reasoning_effort: null
invocation_verification_status: unverified
verification_mode: owner_led_manual_testing
diagnosis_status: PASS
root_cause_class: F_android_plugin_platform
exact_exception: java.lang.ClassNotFoundException_io.flutter.plugins.GeneratedPluginRegistrant
first_failing_bootstrap_stage: directoriesProvider_getApplicationSupportDirectory
database_open_reached: false
schema18_migration_reached: false
same_scope_correction_applied: false
fresh_build_run: false
reinstall_run: false
mt_485_020: FAIL
mt_485_001_019: unchanged
ready: false
merge: false
issue_close: false
v2_8_complete: false
~~~

### review_recommendation

Request a narrow owner authority for deterministic offline Flutter plugin
metadata preparation and a fresh acceptance build. Preserve source unless that
preparation still fails to generate `GeneratedPluginRegistrant`. Do not
change schema, backup, version, product behavior, permissions or dependencies,
and do not reinstall the current broken artifact.
## Plugin registrant recovery — PASS / normal Home reached

Authority: Issue #485 comment `5414057108`.

### Recovery and artifact

- Product source correction: none. Initial head
  `fe9fc26c6f0aff250d9ccd93e15c17ad49d36ff0`; staged `0`.
- Pubspec SHA-256
  `704EE4A64B534D14264984F68B8275570B8F87C06190EE48340830D971EABFA7`
  and lock SHA-256
  `2B75E59A051A8CFCFEC3D6883B04779205C63678B0F4814A4535E50DB77DC441`
  were byte-identical before/after recovery; tracked dependency drift `0`.
- Authorized generated roots were inside the worktree; read-only entries `0`.
  A preliminary PATH lookup failed before Flutter launched. Pinned SDK single
  real clean: exit `0`. Exactly one offline pub get: exit `0`; no network fetch.
- `.flutter-plugins-dependencies` and
  `mobile/android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java`
  exist. Required plugin result `6/6 PASS`: FilePicker, local notifications,
  image picker, permission handler, share plus and sqflite.
- `python scripts/prepare_flutter_release_registrant.py`: exit `0`, PASS.
- Exactly one fresh build: exit `0`, PASS.
- APK: `mobile/build/app/outputs/flutter-apk/app-debug.apk`; `96992107` bytes;
  SHA-256 `4E9514C7224DDD7C7B6EB81A93EF1F5189FE713A14905FD5C4576B3939589D4F`;
  written `2026-08-25T17:22:50.0030358Z` UTC.
- Contract PASS: `com.faliardic.sefim.acceptance`, `Şefim`,
  `0.1.0-acceptance` / `1`, exact MainActivity, arm64 native libraries.
  Android SDK Dex inspection found exact class
  `io.flutter.plugins.GeneratedPluginRegistrant` and `registerWith`.

### Device bootstrap

- Preflight PASS: one physical Samsung `SM-S938B`, Android 16/API 36, serial
  `R5CY21WKZFX`, user 0, `arm64-v8a`; emulator/offline/unauthorized `0`.
- User-150 read-only inventory attempt was denied by Android `SecurityException`;
  no mutation. Production/debug packages were untouched.
- Exactly one user-0 `-r` install: `Success`.
- Exactly one MainActivity launch: `Status: ok`; foreground exact acceptance.
- Read-only hierarchy showed normal MobileShell/Home: `Başlangıç`,
  `Saha hafızanız cihazınızda.`, `7 Günlük Plan`, `Günlük Log`, and
  `İstenecek Malzemeler`. Prior safe-start failure surface was absent.
- Bootstrap result: **PASS — normal Home reached**. Failure logcat was not needed.
- `MT-485-020`: `PENDING` pending explicit owner visual confirmation; no manual
  PASS was inferred.

### execution_record

~~~yaml
policy_version: CSE-MRP-1.0
task_risk: R4
requested_model: gpt-5.6-sol
requested_reasoning_effort: max
actual_model: unknown
actual_reasoning_effort: null
invocation_verification_status: unverified
verification_mode: owner_led_manual_testing
recovery_class: android_plugin_generated_metadata
product_source_edit_applied: false
flutter_clean_real_invocations: 1
offline_pub_get_invocations: 1
pubspec_lock_drift: 0
registrant_plugins: 6/6_PASS
helper: PASS
fresh_build_invocations: 1
fresh_apk_sha256: 4E9514C7224DDD7C7B6EB81A93EF1F5189FE713A14905FD5C4576B3939589D4F
device_install_invocations: 1
device_launch_invocations: 1
bootstrap_home: PASS
mt_485_020: PENDING
ready: false
merge: false
issue_close: false
v2_8_complete: false
v2_9: not_started
~~~

### review_recommendation

Keep PR #486 Draft. Owner should visually confirm normal Home and report
`MT-485-020 PASS` if satisfied. Generated metadata/registrant/APK remain ignored.
