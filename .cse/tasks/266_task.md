# Issue #266 — Türkçe kullanıcı dili ve Puantaj `Kaydet` eylemi

## Kaynak ve branch

- Resmî repo: `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer`
- Beklenen base: `master` /
  `dec0a23c8a8effd5944a6fc62aacc4c8bb1a1d9e`
- Branch: `codex/issue-266-turkish-user-language-save-action`
- Draft PR #259 merge/cherry-pick edilmeyecek ve kodu bu branch'e
  taşınmayacaktır.

## Çalışma modeli

- Model: current full Codex modeli
- Reasoning: High
- Gerekçe: değişiklik dar kullanıcı dili ve Flutter root configuration
  kapsamındadır; dependency/lockfile, widget regresyonu ve fiziksel cihaz
  kanıtı kontrollü biçimde birlikte yürütülecektir.

## Validation class

`narrow-ui`

Issue içindeki `ui-config` tanımı repository protokolündeki karşılığı olan
`narrow-ui` sınıfına eşlenmiştir. Persistence, domain lifecycle, notification,
backup veya release sözleşmesi değişmeyecektir.

## Değişen sözleşmeler

- Kök `MaterialApp` locale'i deterministik Türkçe olur.
- `supportedLocales` yalnız Türkçe içerir; canonical
  Material/Widgets/Cupertino delegate seti kullanılır.
- İngilizce platform locale'inde bile yerleşik kullanıcı eylemleri Türkçe
  çözülür.
- `save-attendance-draft` key'i korunur; görünür etiket exact `Kaydet` olur.
- Save failure açık Türkçe `Puantaj kaydedilemedi.` metnini kullanır.
- Attendance save mutation draft lifecycle, event ID, revision, rollback,
  idempotency ve submitting guard davranışını değiştirmez.
- Yalnız `app.dart` ve `attendance_day_page.dart` içindeki doğrulanmış açık
  kullanıcı metinleri dar envanter kapsamında Türkçeleştirilir.

## Kök neden kanıtı

Production editinden önce sentetik widget fixture'larıyla şu mevcut davranış
kaydedilecektir:

1. `CseApp` altında Material localization etiketleri İngilizcedir.
2. `save-attendance-draft` butonu `Taslak kaydet` gösterir.
3. Save mutation günü tamamlamaz ve lifecycle status `draft` kalır.

Gerçek kullanıcı verisi ve gerçek clipboard içeriği okunmayacaktır. Clipboard
testi yalnız sentetik fixture kullanacaktır.

## Exact changed-file allowlist

Yalnız aşağıdaki 14 tracked path değiştirilebilir:

1. `.cse/tasks/266_task.md`
2. `.cse/results/266_result.md`
3. `CHANGELOG.md`
4. `ROADMAP.md`
5. `docs/266_turkish_user_language_and_save_action.md`
6. `docs/project_decisions.md`
7. `learning/266_turkish_user_language_and_save_action.md`
8. `mobile/pubspec.yaml`
9. `mobile/pubspec.lock`
10. `mobile/lib/app.dart`
11. `mobile/lib/features/attendance/attendance_day_page.dart`
12. `mobile/test/widget_test.dart`
13. `mobile/test/attendance_widget_test.dart`
14. `mobile/test/release_static_configuration_test.dart`

Yeni focused localization test dosyası oluşturulmayacaktır. Mevcut test
dosyaları kök app, selection toolbar ve Puantaj fixture'ları için yeterlidir.

## Dependency sınırı

- Yalnız Flutter SDK dependency'si eklenebilir:

  ```yaml
  flutter_localizations:
    sdk: flutter
  ```

- Haricî localization paketi, ARB kataloğu, dil seçici veya çoklu dil yoktur.
- `pubspec.lock` yalnız zorunlu SDK/transitive çözümleme kadar değişebilir.
- Beklenmeyen package veya version churn oluşursa production edit/build
  ilerletilmeden durulur.

## Doğrulama

### Çalıştırılacak

- Production editinden önce sentetik root-cause widget testleri.
- Focused app/localization ve selection toolbar testleri.
- Focused Puantaj widget testleri.
- İlgili regression fixture'ları.
- `flutter pub get` ve dependency/lockfile bütünlük kontrolü.
- `flutter test --no-pub`
- `flutter analyze --no-pub`
- `git diff --check`
- exact allowlist ve protected-path mutation kontrolü
- source/test PASS sonrasında checkpoint commit:
  `Localize Turkish user actions`
- exact checkpoint için unique disposable detached worktree'de dependency
  hazırlığı ve tek normal field APK build
- artifact provenance/applicationId/signing doğrulaması
- `adb install -r -g` ile veri koruyan replace-install
- yalnız sentetik fiziksel smoke
- PASS sonrasında completion evidence ve commit:
  `Complete Turkish language validation`

### Yeniden kullanılacak kanıt

- Schema `10` ve backup formatı `1`, base committeki merged kanıttır.
- Değişmeyen applicationId, signing, persistence, notification,
  backup/restore ve release sözleşmelerinin merged kanıtları yeniden
  kullanılacaktır; tek field artifact için yalnız Issue'nun istediği provenance
  ve signing uyumluluğu tekrar doğrulanacaktır.

### Geniş kapılar

- Issue açıkça istediği için mobil full Flutter suite bir kez çalıştırılır.
- Flutter analyze bir kez çalıştırılır.
- Python full suite, release gate, AAB, background/reboot, backup/restore ve
  permission matrisi çalıştırılmaz; değişen sözleşmeyle ilgili değildir.

### Minimum fiziksel cihaz kabulü

- Sentetik Günlük Puantaj formunda exact `Kaydet`.
- `Taslak kaydet` görünmez.
- Sentetik save sonrası lifecycle `draft`; `Günü tamamla` ayrı eylem.
- Sentetik editable TextField seçim menüsünde Türkçe eylemler.
- Date picker Material eylemleri Türkçe.
- Normal app reopen sonrasında Türkçe dil korunumu.
- Gerçek kullanıcı kaydı/clipboard içeriği okuma veya mutation `0`.
- Uninstall, clear-data, downgrade ve hard-delete `0`.

## Schema ve veri sınırı

- Schema `10`
- Backup formatı `1`
- Migration `0`
- Persisted tarih, sayı, UTC/İstanbul codec ve database değerlerinde değişiklik
  yoktur.

## Retry ve süre bütçesi

- Tek primary implementation run.
- Yalnız doğrulanmış source/test blocker için en fazla bir correction run.
- Fiziksel validation için tek build invocation; retry, clean, rotation,
  process kill veya ikinci build yok.
- `narrow-ui` hedefi 30 dakika, hard stop 45 dakikadır.

## Stop koşulları

- Beklenmeyen dependency/version churn.
- Schema, migration, persistence veya release scripti ihtiyacı.
- Allowlist dışı production/test dosyası gereksinimi.
- Disposable build veya fiziksel smoke başarısızlığı.
- Gerçek kullanıcı verisine/clipboard içeriğine yeni risk.

Bu koşullarda kapsam genişletilmez; push/Draft PR yapılmadan exact blocker
raporlanır.

## Kapsam dışı

- Çoklu dil, dil seçici veya ARB sistemi
- Repository-wide string sweep
- Teknik event/storage anahtarlarının çevirisi
- Puantaj lifecycle/domain değişikliği
- Tarih/ondalık persistence formatı
- Ajanda–Hatırlatıcı metin senkronu
- Draft PR #259 kodu
- Gerçek kullanıcı kaydı veya clipboard içeriği
- Protected/ignored/generated kullanıcı alanları

## GitHub yetkisi

Bütün kapılar PASS olursa iki ordinary commit normal push edilir ve
`Localize Turkish user actions` başlıklı, `Related to #266` içeren tek Draft PR
açılır. Force push, Ready, merge, issue close ve branch delete yapılmaz.
