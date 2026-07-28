# Issue #260 — Sonuç

## Durum

`PASS`

Beton checklist başlığı, checklist satırları ve `Dökümü başlat` validation'ı
aynı required-pending source-of-truth üzerinde hizalandı. Schema/migration ve
backup formatı değişmedi. Normal field APK ile yalnız sentetik Beton paketi
üzerindeki fiziksel smoke tamamlandı.

## Güvenli branch ve kapsam

- Base: `master` / `7a90a201a31dec06d94df763bac18760a4c0d69c`
- Branch: `codex/issue-260-concrete-checklist-start-hotfix`
- PR #259 BLOCKED harness commit'i branch ancestor'ı değildir.
- PR #259 kodu merge, cherry-pick, copy veya hotfix branch'ine taşıma yoluyla
  kullanılmadı.
- Mobil schema: `10` — değişmedi.
- Backup formatı: `1` — değişmedi.
- Migration: eklenmedi.

## Sentetik kök neden kanıtı

Production editinden önce tek sentetik focused test çalıştırıldı.

- Manuel kalemler tamam, laboratuvar/yapı denetim alanları boşken iki exact
  blocker current satırlarda kaldı.
- Eski uygulama generic
  `Dökümü başlatmak için zorunlu checklist kalemleri tamamlanmalıdır.`
  metniyle testi FAIL etti.
- Bu kanıt gerçek kullanıcı Beton kaydı okunmadan üretildi.

Uygulama sonrasında aynı sentetik senaryo:

- `Yapı denetim bilgilendirildi`
- `Laboratuvar randevusu alındı`

blocker'larını exact gösterdi; iki kaynak alan tamamlanınca required pending
count `0` oldu ve transition başladı.

## Uygulanan davranış

- Required pending kümesi `ConcreteCheckItem` current durumundan deterministik
  hesaplanır; ayrı mutable sayaç yoktur.
- UI başlığı, detail metriği ve transition validation aynı domain helper'ını
  kullanır. Liste projection'ı aynı required-pending SQL koşuluna hizalandı.
- Laboratuvar/yapı denetim checklist kalemleri system-owned'dur.
- Manuel `updateCheck` bu iki kalemi fail-closed reddeder.
- Bulk completion yalnız manual checklist/follow-up kümesini tek transaction'da
  tamamlar.
- Alan set/clear işlemi ilgili checklist, follow-up, linked reminder ve event'i
  aynı transaction içinde tamamlar veya yeniden açar.
- Derived event failure source alan dahil tüm transaction'ı rollback eder.
- Same event ID retry duplicate event/revision üretmez.
- Mutation fresh `ConcretePourDetail` döndürür.
- UI dili `Manuel maddeleri tamamla` oldu; onay dialog'u iki kaynak alanın ayrıca
  gerektiğini açıklar.
- Exact eylemler mevcut ortak alan dialog'una bağlandı:
  `Laboratuvar randevusunu güncelle` ve
  `Yapı denetime bildirimi güncelle`.

## Kaynak doğrulaması

- Focused Beton application: `24 PASS`
- Focused Beton widget: `13 PASS`
- Flutter full suite: `275 PASS`
- Flutter analyze: `PASS` / `No issues found`
- `git diff --check`: `PASS`
- Tracked exact allowlist: `PASS`
- Protected-path diff: `PASS`
- Schema/backup diff: `PASS`

Focused testlerde manual/system ayrımı, doğru count, field set/clear, transition
success/failure, stale rollback, event failure rollback, idempotent retry ve
restart persistence kapsandı. Widget testinde 320 px, 1.6 büyük metin, dark
theme, exact blocker eylemleri, double-tap guard, partial optimistic UI yokluğu,
otomatik `0 açık`, refresh gerektirmeyen start/finish ve yeniden oluşturma
kalıcılığı doğrulandı.

İlk analyze çağrısı komut zaman sınırında sonuç üretmeden sonlandı. Source
değişmeden aynı analyze tek timeout correction ile tamamlandı ve PASS oldu.

## Normal field APK

- Build başlangıcı UTC: `2026-07-28T13:37:48.6799233Z`
- Exact path:
  `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer\mobile\build\app\outputs\flutter-apk\app-debug.apk`
- Length: `168839578`
- Last-write UTC: `2026-07-28T13:39:21.0269661Z`
- SHA-256:
  `1BFFCD9B2C1FDE13D41F0F72FA44026F5E4C678C45854354C83508AC3478BEBC`
- applicationId: `com.faliardic.chiefsiteengineer.debug`
- Entrypoint: `lib/main.dart`
- Normal marker: `CSE_ENTRYPOINT_NORMAL_LIB_MAIN_DART_V1` — mevcut.
- Acceptance marker: yok.
- Launchable activity:
  `com.faliardic.chiefsiteengineer.MainActivity`
- Kurulu ve yeni APK certificate SHA-256:
  `329f42b542af8576367279b59fb2802dfd545253b2906f7ba2ac12c7c6d5c869`
- Signature match: `PASS`
- Version code: `1` → `1`; downgrade yok.
- Install: `adb install -r -g` / `PASS`
- Install öncesi/sonrası SQLite inode–size–mtime:
  `1901148:1179648:1785244349` — değişmedi.
- Uninstall: yapılmadı.
- Clear-data: yapılmadı.
- Acceptance harness/build: kullanılmadı.

## Fiziksel cihaz smoke

- Device: `R5CY21WKZFX` / `device`
- Package: yalnız `com.faliardic.chiefsiteengineer.debug`
- Sentetik Beton kodu: `CSE260SMOKE`
- Sentetik mahal: `CSE260SYNTHETIC`
- Başlangıç: `11 açık`
- Manuel maddeler tamamlandıktan sonra: `2 açık`
- Exact iki system-owned eylem: görünür.
- İki gerçek kaynak alan kaydedildikten sonra: aynı mutation/reload zincirinde
  `0 açık`; refresh ikonuna basılmadı.
- `Dökümü başlat`: `PASS`; `Devam ediyor` ve `Gerçek başlangıç` görünür.
- Mevcut finish validation korunarak sentetik `CSE260` / `1 m³` mikser eklendi.
- `Dökümü bitir`: `PASS`; `Tamamlandı` ve `Gerçek bitiş` görünür.
- HOME ile normal kapatma ve launcher ile yeniden açma sonrasında sentetik kod,
  `Tamamlandı` ve `Gerçek bitiş` kalıcı: `PASS`.
- Gerçek kullanıcı Beton kaydı okunmadı, açılmadı veya değiştirilmedi.
- Raporlara gerçek proje, sınıf veya Beton kayıt içeriği yazılmadı.

Yeniden açılış sonrasındaki ek `0 açık` görünürlük araması timeout oldu; otomatik
`0 açık` değeri alan mutation'ından hemen sonra zaten doğrulandı ve yeniden
açılışta aggregate'in bitmiş durumu kalıcıydı. Yeni build/install/smoke denemesi
başlatılmadı.

## Git durumu

Ordinary commit, normal push ve Draft PR yalnız final combined allowlist ve
staging kontrolleri de PASS olduktan sonra oluşturulacaktır. Merge yapılmaz.
