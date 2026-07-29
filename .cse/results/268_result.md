# Issue #268 — Ajanda sıralama doğrulama sonucu

## Repository ve kapsam

- Resmî repo:
  `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer`
- Base commit:
  `1179870a7c69d1e3f090e5fc61da9c7bbfc42879`
- Branch:
  `codex/issue-268-agenda-sort-order`
- Source/test checkpoint:
  `c8b22cf813189137dd11b4277ccb7ea03d54fbc7`
- Validation class: `narrow-ui`
- Cumulative exact allowlist: `14/14`
- Draft PR #259 ancestry/cherry-pick/merge: `0`

## Değişen davranış

- `AgendaQuery` iki değerli typed `AgendaSortOrder` taşır ve varsayılan
  `newestFirst` değeridir.
- `newestFirst`, `observed_at`, `created_at`, `id` alanlarını azalan;
  `oldestFirst` aynı alanları artan sırada kullanır.
- `updated_at` sıralamaya katılmaz ve UI client-side `reverse()` uygulamaz.
- `AgendaPage`, `agenda-sort-order` semantic key'iyle `En yeni üstte` ve
  `En eski üstte` seçeneklerini gösterir.
- Seçim route-local kalır; gün, aktif/arşiv, proje, tür ve literal arama
  filtreleriyle birlikte application query katmanına gönderilir.
- Detay dönüşü ve detail mutation reload'u seçili sıralamayı, filtreleri,
  aramayı ve geçerli scroll bağlamını korur.

## Source/test doğrulaması

Validation worktree:

`C:\Users\Fatih\AppData\Local\Temp\cse268-source-validation-c57609ed77f14da7997708369b577162`

- Exact source/test snapshot: `8/8`
- Kaynak/hedef SHA-256 eşitliği: PASS
- Unexpected tracked path: `0`
- Dependency churn: `0`
- Static configuration:
  `5 PASS / 0 FAIL`
- Agenda application + widget:
  `42 PASS / 0 FAIL`
- Agenda + static combined focused:
  `47 PASS / 0 FAIL`
- Full Flutter:
  `308 PASS / 0 FAIL`
- Flutter analyze:
  `PASS — No issues found`
- `git diff --check`: PASS
- Schema: `10`
- Backup formatı: `1`
- Migration: `0`
- Protected-path mutation: `0`

Disposable Windows worktree'deki CRLF satır sonu, localization dependency
testinin LF-only multiline karşılaştırmasında false-negative üretmişti. Test
yalnız satır sonlarını normalize edecek şekilde platform bağımsızlaştırıldı;
dependency adı, exact indent ve `sdk: flutter` sözleşmesi değiştirilmedi.
Bu correction sırasında Agenda production source'u byte-identical kaldı.

## APK ve fiziksel cihaz

Build worktree:

`C:\Users\Fatih\AppData\Local\Temp\cse268-build-validation-c9e35f2eb22e44368775211d5ceff17e`

Artifact:

- Exact path:
  `C:\Users\Fatih\AppData\Local\Temp\cse268-build-validation-c9e35f2eb22e44368775211d5ceff17e\mobile\build\app\outputs\flutter-apk\app-debug.apk`
- Build invocation başlangıcı:
  `2026-07-29T03:50:09.5684374Z`
- Length:
  `170517410`
- Last-write:
  `2026-07-29T03:52:30.2571924Z`
- SHA-256:
  `d206dcf9a6e0cb6d6216e8477634b4b5cb5d3dacc00bc951cc7ef5f3170dbf2a`
- Current invocation sonrasında üretildi: PASS
- applicationId:
  `com.faliardic.chiefsiteengineer.debug`
- Launchable activity:
  `com.faliardic.chiefsiteengineer.MainActivity`
- Version code:
  `1`
- Debug signer certificate SHA-256:
  `329f42b542af8576367279b59fb2802dfd545253b2906f7ba2ac12c7c6d5c869`
- Kurulu paketle version/signing uyumu: PASS
- `adb install -r -g`: PASS

Fiziksel cihaz:

- Serial: `R5CY21WKZFX`
- Preflight durumu: exact `device`
- Sentetik proje:
  `CSE268SMOKE-20260729-0355`
- Dört aynı-gün sentetik log:
  `06:00`, `06:10`, `06:20`, `06:30`
- Default `En yeni üstte`; `06:30` ilk: PASS
- `En eski üstte`; `06:00` ilk: PASS
- Proje, `Genel not` ve `CSE268SMOKE` literal filtrelerinde sort korunumu:
  PASS
- `06:00` açıklaması detail mutation ile güncellendi: PASS
- Detay dönüşünde fresh açıklama, `En eski üstte`, filtreler ve olay-zamanı
  konumu korundu: PASS
- App bar back: PASS
- System back: PASS
- Dört sentetik log güvenli ve geri getirilebilir arşive taşındı: PASS
- Aktif sentetik log: `0`
- Sentetik proje için archive UI bulunmadığından izole kap olarak bırakıldı.
- Gerçek kullanıcı kaydı açma/değiştirme: `0`
- Uninstall / clear-data / downgrade / hard-delete:
  `0 / 0 / 0 / 0`

## Git ve yayınlama kaydı

- Checkpoint commit:
  `c8b22cf813189137dd11b4277ccb7ea03d54fbc7`
- Completion commit mesajı:
  `Complete Agenda sort validation`
- Force/amend/Ready/merge/Issue close: `0`

Completion commit SHA, normal push sonrası divergence ve Draft PR URL,
self-referential metadata commit üretmemek için GitHub Issue/PR metadata ve
final Codex raporunda kaydedilir.
