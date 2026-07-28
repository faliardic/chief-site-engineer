# Issue #256 — Atomik Flutter build-root izolasyonu

## Güvenli başlangıç

- Resmî yerel repo: `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer`
- Base `master`: `defeab25f4a940c43f07e42faa3fa3fd2ef905de`
- Branch: `codex/issue-254-physical-smoke-acceptance-harness`
- Parent blocker: Issue #254
- Related recovery: Issue #255
- Issue #254 başlangıç tracked diff fingerprint:
  `c699bc9757b2617aa2e2ad444ab615049980ec6a`
- Validation class: `release-critical`
- Codex modeli: current full Codex modeli
- Reasoning seviyesi: `Extra High`
- Seçim nedeni: Windows generated-directory kilidi, artifact provenance,
  applicationId/entrypoint izolasyonu ve fiziksel cihaz acceptance zinciri
  birlikte fail-closed doğrulanacaktır.
- Primary run: `1`
- Correction bütçesi: yalnız doğrulanmış blocker için en fazla `1`

## Değişen sözleşmeler

- Her Flutter APK/AAB/integration build çağrısından önce yalnız mevcut
  `mobile/build` aynı parent altında
  `build.release-gate-<build-kind>-<run-id>-stale` adına atomik taşınır.
- Quarantine hedefi mevcutsa veya atomik rename başarısızsa ilgili Flutter
  çağrısı başlamaz.
- Flutter sonraki build için yeni `mobile/build` ağacını kendisi oluşturur;
  ardışık buildler arasında `flutter clean` kullanılmaz.
- Artifact yalnız current invocation sonrasında oluşmuşsa kabul edilir.
- Normal field/release ve `.acceptance` artifact adları, applicationId'leri ve
  entrypoint marker'ları birbirini fail-closed reddetmeye devam eder.
- Mevcut Issue #254 acceptance builder ve fiziksel runner yeni framework
  kurulmadan atomik release-gate Flutter proxy'si üzerinden çalıştırılır.

## Exact changed-file allowlist

1. `.cse/tasks/256_task.md`
2. `.cse/results/256_result.md`
3. `scripts/release_gate.ps1`
4. `tests/test_release_gate_static.py`

Yalnız gerekli completion çapraz referansı için
`.cse/tasks/254_task.md` veya `.cse/results/254_result.md` ayrıca değişebilir.
Başka dosyada edit gerekirse durulur.

## Zorunlu doğrulama

1. Existing `mobile/build` atomik ve unique ada rotate edilir.
2. Existing quarantine target fail-closed durur.
3. Rename hatası Flutter process başlamadan yayılır.
4. Normal ve acceptance çağrıları farklı build-kind/run-id kullanır.
5. Artifact freshness, marker, applicationId ve ad izolasyonu korunur.
6. `tests/test_release_gate_static.py` ve ilgili mevcut Python
   release-gate testleri PASS.
7. Protected Flutter test/analyze kanıtları source değişmediği için yeniden
   çalıştırılmaz.
8. Gerçek release gate içinde en az iki ardışık Flutter build PASS.
9. Acceptance APK package tam olarak
   `com.faliardic.chiefsiteengineer.acceptance` olur.
10. Issue #254 iki-faz fiziksel acceptance smoke PASS.
11. Production `.debug` package metadata/process/data inode mutation `0`.
12. `git diff --check`, combined allowlist ve protected-path kontrolü PASS.

## Yeniden kullanılan kanıt

- Issue #254: focused Flutter `11 PASS`, full Flutter `275 PASS`, Flutter
  analyze `PASS`.
- Issue #255: generated-root recovery, atomic stale rename ve `flutter clean`
  `PASS`.
- Issue #252 / PR #253: reminder production davranışı.
- Issues #207/#212/#214: değişmeyen background/reboot, signing, ARM64/16 KiB,
  permission/privacy, schema, backup ve data-preserving contracts.

## Yasak kapsam ve stop koşulları

- Flutter production/widget/domain source veya Issue #252 davranışı değişmez.
- `.dart_tool`, Gradle cache ve protected kullanıcı alanları yeni genel
  temizleme kapsamına alınmaz.
- Issue #255 stale dizinleri silinmez, taşınmaz veya stage edilmez.
- Process kill, ACL mutation, Windows restart, global Flutter/Gradle/PATH
  mutation yapılmaz.
- Rename/build/device blocker'ı tek exact correction sonrasında sürerse durulur.
- Bütün kapılar PASS olmadan stage, commit, push veya Draft PR yapılmaz.

## GitHub yetkileri

- Commit: bütün zorunlu kapılar PASS ise
  `Isolate Flutter release gate build roots`.
- Push: yalnız başarılı ordinary commit sonrasında normal push.
- Draft PR: Issue #254 ve Issue #256'yı bağlayan tek Draft PR.
- Ready/merge, force push ve destructive Git işlemleri yasaktır.
