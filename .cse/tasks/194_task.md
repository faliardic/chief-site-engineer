# Issue #194 Görev Kaydı

## Yürütme

- Resmî repo: `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer`
- Güvenli base: `be365bb2f2400d54ca53b8de90d9f72ace52c347`
- Branch: `codex/issue-194-field-feedback-workforce-reminders`
- Model: Codex standart full model
- Reasoning: Extra High
- Seçim nedeni: atomik mobil schema 5→6 migration, legacy personel ve Puantaj
  geçmişi, canlı proje kataloğu, optimistic registry yaşam döngüsü, native
  notification reconciliation ve release artifact kapıları aynı veri güvenliği
  sınırında birlikte doğrulanmalıdır.

## Yetkili kapsam

- Flutter mobil SQLite schema v6; taşeron, ekip, personel bağlantıları, İSG
  belge görünürlüğü, KKD zimmet görünürlüğü ve append-only workforce event'leri.
- Ajanda, Hatırlatıcı, Puantaj ve Beton ekranlarının ortak canlı proje
  source-of-truth üzerinden uygulama restart'ı olmadan yenilenmesi.
- Puantaj taşeron → ekip → personel kayıt akışı, exact personel/team kimliğiyle
  günlük kullanım ve üç görünümlü personel detayı.
- Yeni beton paketinde iki idempotent bağlı görev, 60 dakikalık inexact yerel
  bildirim, alan tamamlama/reopen eşitlemesi ve kod istemeyen numune seti akışı.
- Aktif reminder kartlarında Europe/Istanbul takvimine göre `Yarın` işlemi.
- Backup format v1 korunarak schema 1–6 staging migration/round-trip;
  dokümantasyon, learning notu, state kaydı ve gerekli testler.

## Kabul kapıları

- Schema 5→6 atomik; deterministic legacy taşeron/ekip eşlemesi exact personel
  kimliğini, attendance entry/event geçmişini ve önceki bütün mobil veriyi korur.
- Registry unique/FK/check/no-physical-delete ve optimistic revision kuralları;
  no-op event üretmez, gerçek mutation aynı UoW içinde append-only event yazar.
- Proje oluşturma dönüşünde bütün açık modüller yenilenir; duplicate isim
  fail-closed reddedilir.
- İSG read-model tarih durumları ve KKD lifecycle yalnız kayıt/görünürlüktür;
  hukuki uygunluk veya işe kabul kararı üretmez.
- Beton saha görevleri source reminder'ı çoğaltmaz; `Yarın` saatlik tekrarı yeni
  due zamanına kadar bastırır; permission/plugin hatasında SQLite görevi kalır.
- Flutter analyze, bütün unit/widget/integration testleri, API 36 emülatör,
  Python full suite/compileall, backup/release gate, ARM64/16 KiB, state JSON,
  `git diff --check`, exact allowlist ve korunan alan kontrolleri geçer.

## Korunan sınırlar

- Ücret/bordro/maaş/SGK/hakediş, biyometri, cloud sync, çoklu kullanıcı,
  e-imza, otomatik hukuki karar ve store submission eklenmez.
- Gerçek kullanıcı verisi, gerçek `CSE_DATA_ROOT`, upload/signing key, Apple
  sertifikası, provisioning profile veya secret kullanılmaz.
- `reports/` okunmaz/değiştirilmez; `exports/.gitkeep`, mevcut ZIP ve ignored
  Flutter cache/build/artifact alanları korunur ve stage edilmez.
- Yeni ephemeral test signing malzemesi repository dışında oluşturulur; RC APK
  ignored release-gate alanında bırakılır.
- Tek ordinary commit `Address mobile field feedback`; normal push; amend,
  rebase, force-push ve PR yoktur.
