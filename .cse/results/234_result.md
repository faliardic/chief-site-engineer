# Issue 234 Result — Beton Sınıfı ve Döküm Zaman Çizgisi

## Başlangıç

- Resmî repo: `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer`
- `master = origin/master = b45e09913a3a306075bcbae14cb958275aef16c1`
- Branch: `codex/issue-234-concrete-class-timeline`
- Başlangıçta tracked/staged değişiklik ve açık PR: `0`
- `device-backups/`, `reports/` ve ignored kullanıcı/yerel dosyaları
  değiştirilmedi.

## Persistence ve katalog

- Mobil schema `9 → 10` tek migration transaction'ında üç tablo ekledi:
  proje Beton sınıfı kataloğu, append-only sınıf event geçmişi ve composite
  proje FK'li paket bağlamı.
- Legacy sınıflar `project_id + trim/case/whitespace normalized name`
  anahtarıyla deterministik seed edildi. Aynı projedeki ` C30/37 ` ve
  `c30/37` tek sınıfa, farklı projedeki aynı metin ayrı sınıfa bağlandı.
- Boş legacy snapshot fail-closed rollback olur. Mevcut status, gerçek
  başlangıç/bitiş, mikser ve event geçmişi korundu.
- Paket üzerindeki zorunlu `concrete_class` tarihsel snapshot olarak kaldı.
  Yeni paket aktif same-project katalog kimliği seçer; varsayılan slump yalnız
  form ön değeridir ve paket değeri ayrıca düzenlenebilir.
- Archive/restore revision ve append-only event üretir; normalized duplicate
  aynı projede reddedilir ve arşivli sınıf yeni pakette seçilemez.

## Lifecycle ve yönetilen Ajanda

- Üç aşamalı sunum gerçek timestamp'ten türetilir:
  `Planlandı → Devam ediyor → Tamamlandı`; ayrıntılı status zinciri korunur.
- `Dökümü başlat`, draft/prepared paket için zorunlu checklist'i aynı
  transaction'da doğrular; ilk `actual_started_at` retry/no-op ile değişmez.
- `Dökümü bitir` en az bir mikser ister, ilk `actual_ended_at` değerini korur
  ve follow-up/closed zincirini otomatik tamamlamaz.
- İlk başarılı başlangıç Beton update/event, tek category `concrete` Ajanda
  row/event ve unique linki aynı SQLite transaction'ında üretir. Agenda
  write hook hatası ile bütün row, timestamp, event ve linklerin rollback
  olduğu doğrulandı.
- Bitiş ikinci Ajanda kaydı açmadan aynı kaydı gerçek hacim, mikser sayısı ve
  süreyle günceller. Repeated start/finish ve legacy repair duplicate üretmez.
- Başlamadan iptal Ajanda oluşturmaz. Başladıktan sonra iptal gerçek başlangıcı
  korur, sahte bitiş yazmaz ve aynı Ajanda kaydına event ekler; reopen gerçek
  zamanları silmez.
- Managed Ajanda kaydının bağımsız ana metin edit/archive mutation'ı application
  katmanında reddedilir; UI managed read-only açıklaması ve iki yönlü
  Beton–Ajanda navigation sunar.

## Backup compatibility

- Backup format `1` değişmedi.
- Schema `1–9` paketlerinin schema 10'a restore edilmesi test edildi.
- Schema 10 round-trip katalog, class/context linkleri, Ajanda linki,
  timestamp'ler ve append-only event geçmişini korudu.
- Bilinmeyen daha yeni schema fail-closed kalır.

## Doğrulama

Birleşik focused matris:

```text
flutter test --no-pub \
  test/app_database_test.dart \
  test/concrete_application_test.dart \
  test/agenda_application_test.dart \
  test/concrete_widget_test.dart \
  test/mobile_agenda_widget_test.dart \
  test/mobile_backup_application_test.dart
```

Sonuç: `106/106 PASS`

- App database/migration: `20/20 PASS`
- Concrete application: `21/21 PASS`
- Agenda application/integration: `18/18 PASS`
- Concrete widget: `9/9 PASS`
- Agenda widget/deep-link: `9/9 PASS`
- Mobile backup/restore: `29/29 PASS`
- `flutter analyze --no-pub`: `No issues found`
- `git diff --check`: PASS
- Protected Android/iOS/release-script diff: boş
- Schema/static API: schema `10`, backup format `1`, yeni katalog/context
  tabloları ve katalog kimliği create API'si doğrulandı.

## Çalıştırılmayan geniş kapılar

Focused matris ortak regresyon göstermediği için mobile full suite
çalıştırılmadı. Python full suite, Android release gate, APK/AAB/signing,
ARM64/16 KiB, reboot/background acceptance, production RC, integration/device
smoke ve fiziksel cihaz kabulü Issue sözleşmesi gereği çalıştırılmadı.

## Yeniden kullanılan merged kanıt

- Mevcut Beton Paketi PR'ları: checklist, mikser, numune, kanıt, takip ve
  kapanış validation'ları
- PR #228: schema 9, backup ve reminder source bağlantıları
- PR #231: Ajanda source navigation
- PR #217: minimum yeterli validation protocol

## Bütçe ve sınırlar

- Validation class: `persistence + cross-domain vertical slice`
- Focused acceptance matrisindeki compile/widget fixture uyuşmazlıkları için
  tek exact blocking correction yapıldı; geniş doğrulama zinciri başlatılmadı.
- Hedef 120 dakika / hard stop 180 dakika sınırı içinde kalındı.
- Keyword önerisi, attachment v2, viewer, mix-design, API/AI ve platform/release
  kapsamları başlatılmadı.

## Publication

Bu dosya pre-publication factual evidence'tir. Commit SHA, remote divergence,
push ve Draft PR bağlantısı Issue #234 completion yorumunda tutulur; metadata
için ikinci commit üretilmez. PR merge edilmez.
