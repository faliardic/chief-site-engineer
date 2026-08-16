# Issue #458 Result — Persistent Reference-Schedule Snapshot Foundation

## Durum

`PASS` — Issue #458 teknik sözleşmesi tamamlandı. Schema 14, immutable reference-schedule snapshot persistence, atomik current replacement, deterministic fingerprint, date-window query ve format-1 backup/restore uyumluluğu doğrulandı.

## Repository ve Git kanıtı

- Resmî repository: `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer`
- İzole linked worktree: `V:\1_PROJECTS\2_ACTIVE\Python\CSE-Worktrees\issue-458-schedule-snapshot-20260816T050816999Z`
- Exact base: `df3090eb3c47c39cd77c6a0070fe8384f6b82b08`
- Branch: `codex/issue-458-schedule-snapshot-foundation`
- Resmî `master`: `df3090eb3c47c39cd77c6a0070fe8384f6b82b08`
- `origin/master`: `df3090eb3c47c39cd77c6a0070fe8384f6b82b08`
- Master divergence: `0 0`
- Result yazımı öncesi branch HEAD: `df3090eb3c47c39cd77c6a0070fe8384f6b82b08`; validated değişiklikler henüz commitlenmemişti.
- Remote branch/push: result dosyası oluşturulurken henüz yapılmadı; final commit/push SHA ve divergence Issue completion evidence ile PR metadata'sında kaydedilecektir.
- PR: result dosyası oluşturulurken henüz açılmadı; yalnız Draft açılacaktır.
- Merge/Ready: yapılmadı ve yetkisiz.

## Uygulanan sözleşme

- `AppDatabase.schemaVersion`: `13 -> 14`.
- Backup format: `1` olarak kaldı; envelope/crypto production kodu değişmedi.
- `project_schedule_snapshots` ve `project_schedule_snapshot_activities` additive olarak eklendi.
- Project/composite foreign key, canonical date/range/check constraint'leri, lowercase SHA constraint'i, tek-current partial unique indexi, deterministic history/window indexleri ve immutable/supersede-only trigger'ları eklendi.
- Typed `ConstructionScheduleSnapshotMetadata`, `ConstructionScheduleSnapshot` ve fail-closed failure contract'ı eklendi.
- Repository her write öncesi mevcut `ConstructionScheduleDateEngine.validateSchedule` çağrısını aynı profile/graph/seed catalog ile kullanıyor; scheduling semantics tekrar uygulanmadı.
- Persisted projection exact Issue alanlarıyla `instance_id ASC`, compact JSON, sorted object keys, UTF-8 ve lowercase SHA-256 olarak üretildi.
- Current replacement tek SQLite transaction içinde old-current supersede + metadata + bütün activity satırları + count/current verification yapıyor.
- Current/by-id/history/inclusive date-window operations deterministic sıralama ve corruption validation ile eklendi.
- Load path profile/provenance/date/enum/duration/milestone/project/count/summary/fingerprint/current invariant ihlallerinde fail closed davranıyor.
- Mid-insert failure injection eski current snapshot'ı ve bütün satırlarını eksiksiz koruyan rollback kanıtladı.

## Exact changed-file list

Issue allowlist production/evidence/test dosyaları:

- `.cse/tasks/458_task.md`
- `.cse/results/458_result.md`
- `mobile/lib/storage/app_database.dart`
- `mobile/lib/domain/construction_schedule_models.dart`
- `mobile/lib/application/construction_schedule_snapshot_repository.dart`
- `mobile/test/app_database_test.dart`
- `mobile/test/construction_schedule_snapshot_repository_test.dart`
- `mobile/test/mobile_backup_application_test.dart`

İlk full suite'in yakaladığı stale schema-13 sabitlerini current schema-14 sözleşmesine bağlayan, owner comment ile açıkça yetkili zararsız test/debug düzeltmeleri:

- `mobile/test/attachment_schema_migration_test.dart`
- `mobile/test/platform_notification_configuration_test.dart`
- `mobile/test/project_location_schema_migration_test.dart`

Allowlist dışı production edit yoktur. `mobile/lib/application/mobile_backup_application.dart` değişmedi.

## Focused validation

1. `flutter.bat pub get --offline`: exit `0`; `pubspec.yaml` / `pubspec.lock` drift `0`.
2. `test/app_database_test.dart`: `22/22 PASS`.
   - Fresh contiguous schema 14 ve 13→14 additive migration.
   - Eski schema object/rows exact korunumu.
   - Tek-current, composite FK, immutable update/delete, supersede-only/no-resurrection.
   - `PRAGMA foreign_key_check`: empty.
   - `PRAGMA integrity_check`: `ok`.
3. `test/construction_schedule_snapshot_repository_test.dart`: `7/7 PASS`.
   - Exact save/load/reconstruction, hard-coded fingerprint `e3fa78d2aa8eebd238d8b2320e35fce6f15d4bc2988caab447057b591d35d617`.
   - Current replacement, immutable history, window overlap/order, empty window.
   - D/E provenance, isolated/milestone flags, duplicate/missing/multiple-current/corruption fail-closed.
   - Invalid engine schedule before mutation ve mid-insert atomic rollback.
4. `test/construction_schedule_date_engine_test.dart`: `23/23 PASS`.
   - Zero-day WORKING_DAY non-workday guard.
   - Exact deterministic successor-start validation.
   - P01/P02/P03 exact schedule/root/leaf/isolated fingerprints.
   - Sunday/holiday/synthetic `0 / 0 / 0` sözleşmesi.
5. `test/mobile_backup_application_test.dart`: `36/36 PASS`.
   - Schema-14 schedule snapshot format-1 backup → clean target restore → normal `AppDatabase` reopen; metadata/rows/current/SHA exact.
   - Schema-13 format-1 backup → real preflight/restore → normal open/migrate schema 14.
   - Mevcut backup, attachment, notification ve corruption regression zinciri PASS.
6. Stale schema test correction focused doğrulaması: `3/3 PASS`.

## Full suite ve kalite kapıları

- İlk full run: `656 PASS / 3 FAIL`; üç fail yalnız stale hard-coded schema `13` expectations idi.
- Owner-authorized zararsız test correction sonrası final full `flutter test --no-pub`: `659/659 PASS`.
- Aynı başarısız aşama için yalnız bir correction run kullanıldı; source değişmeden full suite tekrarlanmadı.
- Changed Dart `dart format --output=none --set-exit-if-changed`: PASS, `0 changed`.
- `flutter analyze --no-pub`: PASS, `No issues found`.
- `git diff --check`: PASS.
- Exact authorized changed-path classification: PASS.
- Protected path drift: `0`.
- `exports/`: yalnız `.gitkeep`.
- APK/AAB/device/release/reboot/notification gate: çalıştırılmadı; Issue UI/platform/release/notification sözleşmesini değiştirmiyor.
- Değişmeyen release/device kanıtları yeniden çalıştırılmadı.

## Protected corpus/dependency/schedule-seed kanıtı

- Activity asset: `19205` bytes, SHA-256 `a9b225d6403168f7d3fd35494eceb4907d1ea705492700bc865add95021f42ca`.
- Dependency asset: `10708` bytes, SHA-256 `07f58de9912fe76303d18b48863b45aeaaac0f0f203aa14ebe8f8b1a8db12c86`.
- Schedule-seed asset: `5896` bytes, SHA-256 `b80ebe90f57fa71bafcaee5102acfe3dda29368f53cd5a164b248b6530b9587e`.
- Git diff asset drift: `0`.
- `.gitattributes`, `mobile/pubspec.yaml`, `mobile/pubspec.lock`, Android/iOS/platform/config drift: `0`.
- Kanonik ZIP repository'ye eklenmedi; linked worktree içinde bulunmuyor ve resmî checkout'taki ignored ZIP'e dokunulmadı.

## Bütçe ve kapsam

- Bir primary execution ve full-suite aşamasında bir owner-authorized correction kullanıldı.
- Full suite, migration+persistence+engine+backup focused kapıları PASS olmadan başlatılmadı.
- İlk PATH formatter preflight'ı repository mutation üretmeden resmi cached Flutter SDK yolu ile düzeltildi.
- Kapsam dışı altyapı sorunu yoktur.
- 7-day UI, progress/actual, reforecast, productivity learning, duration override, critical path, approved baseline, notification ve Issue #459 uygulanmadı.
- Sonraki adım yalnız bağımsız ChatGPT review'dur; Ready/merge/sonraki Slice bu yürütmede yoktur.

```yaml
execution_record:
  requested_model: "gpt-5.6-sol"
  actual_model: "unknown"
  requested_reasoning_effort: "max"
  actual_reasoning_effort: "unknown"
  execution_mode: "standard"
  orchestration: "single-agent"
  routing_request_evidence: "https://github.com/faliardic/chief-site-engineer/issues/458#issuecomment-5305832941"
  invocation_evidence: null
  invocation_verification_status: "unverified"
  mismatch_detected: null
  runtime_verification_status: "unverified"
```

```yaml
review_recommendation:
  risk_observed: "R4"
  recommended_chatgpt_model: "gpt-5.6-sol"
  recommended_reasoning_effort: "max"
  recommended_mode: "standard"
  recommendation_reason: "SQLite migration, immutable schedule history, atomic replacement, integrity fingerprint ve backup/restore backward compatibility R4 review gerektirir."
  must_review:
    - "schema-14 CHECK/FK/index/trigger invariants ve 13-to-14 additive migration"
    - "engine-before-write, canonical persisted projection ve fail-closed reconstruction"
    - "atomic rollback/current-history semantics ve date-window query plan"
    - "format-1 schema-14 roundtrip ile schema-13 restore/migrate compatibility"
    - "owner-authorized stale schema test corrections ve protected drift 0"
    - "runtime model/reasoning verification belirsizliği"
  residual_uncertainty: "Runtime actual model/effort metadata görünmüyor; invocation ve runtime unverified."
  escalation_condition: "Unexpected production diff, schema/backup evidence contradiction, fingerprint incompatibility veya review sırasında yeni R4 bütünlük riski."
```
