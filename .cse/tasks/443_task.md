# Issue #443 Task — Construction Activity Corpus Runtime Foundation

## Owner-directed priority

14 Ağustos 2026 ürün kararıyla CSE Construction Corpus entegrasyonu production yönüne alınmıştır. Bu ilk dilim yalnız salt-okunur **activity catalog runtime foundation** kurar; kullanıcı verisi, SQLite schema, plan persistence, dependency scheduling veya görünür UI değiştirmez.

## Exact base

`496e5bd0100a55d42e0320b932e510d34453f2dd`

## Scope

- derlenmiş, YFK ham/uzun metin, fiyat veya kaynak katsayılarını içermeyen runtime activity-catalog asseti;
- corpus/domain modelleri;
- asset loader/repository;
- typed applicability evaluator;
- activity search + project-profile filtering;
- count/version/package-reference validation;
- focused unit tests.

## Explicitly out of scope

- dependency graph/runtime schedule generation;
- YFK PDF veya tam analiz metnini uygulamaya gömmek;
- YFK fiyat veya kaynak katsayılarını dağıtmak;
- SQLite schema/migration;
- project activity persistence;
- 7-day look-ahead UI;
- resource/material/machine planner;
- actual/project-learned feedback;
- AI/cloud runtime;
- V2.5 Daily Output implementation.

## Safety

Corpus metadata `RESEARCH_RESOURCE_SEED / NOT_FOR_PRODUCTION` sınırını korur. D/E duration verisi source-backed gibi gösterilemez. Asset yalnız WBS + activity catalog + project applicability/read-only seçim omurgasını taşır; YFK-derived resource coefficients bu ilk production diliminde özellikle dahil edilmez.

## Expected changed files

- `mobile/assets/corpus/cse_construction_activity_catalog_v0_3.b64`
- `mobile/lib/domain/construction_corpus_models.dart`
- `mobile/lib/application/construction_corpus_repository.dart`
- `mobile/test/construction_corpus_repository_test.dart`
- `mobile/pubspec.yaml`
- `.cse/tasks/443_task.md`

## Acceptance

- bundled asset parse edilir;
- corpus version ve runtime scope doğrulanır;
- 34 WBS ve 316 aktif faaliyet okunur;
- duplicate activity/WBS/profile-field ID reddedilir;
- activity → WBS/package dangling referansı reddedilir;
- typed applicability `always/eq/neq/in/any/all/not` destekler;
- unsupported applicability fail-closed;
- missing profile field field-based rule'larda fail-closed;
- profile filtering deterministic;
- activity search Türkçe ad + alias üzerinden deterministic;
- YFK resource coefficients/raw text/prices assette bulunmaz;
- schema 13 / Backup format 1 değişmez;
- `mobile/lib/storage/app_database.dart` değişmez.

## Validation

- focused: `flutter test --no-pub test/construction_corpus_repository_test.dart`;
- `dart format` changed Dart files;
- `flutter analyze --no-pub` if focused test compiles;
- `git diff --check`;
- exact changed-file / protected-path classification;
- dependency/lockfile/schema/Backup/platform drift = 0.

Full mobile suite, APK/device, backup/restore and release gates are not required unless the slice escapes its read-only asset/domain/application boundary.

## Reasoning

- **Codex akıl yürütme seviyesi: Extra High.** Yeni kalıcı ürün omurgasının ilk runtime sözleşmesi kuruluyor ve corpus güven sınırları production katmanında korunmalı.
- **Asistan akıl yürütme önerisi: Extra High.** Bu dilim sonraki Project Activity / Dependency / Schedule Engine katmanlarının temel API'sini belirlediği için dar fakat yüksek etkili bir contract adımıdır.
