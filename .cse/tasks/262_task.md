# Issue #262 — Hatırlatıcı `Yarına ertele` uygunluğu

## Güvenli başlangıç

- Resmî yerel repo: `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer`
- Başlangıç dalı: `master`
- Beklenen ve doğrulanan base SHA: `6b64ed29e15d0f839e10fb4ff0b7bbe739a0fd8a`
- Çalışma dalı: `codex/issue-262-reminder-tomorrow-action-eligibility`
- Master divergence: `0 0`
- Validation class: `domain`
- Codex modeli: bu çalışmadaki mevcut tam Codex modeli
- Reasoning seviyesi: `Extra High`
- Seçim nedeni: Europe/Istanbul gün sınırı, source ownership, application mutation fail-closed davranışı, event/revision/notification atomikliği ve birden çok reminder UI yüzeyini birlikte etkileyen regresyon duyarlı domain değişikliği.
- Paralel alt ajan: yok.

## Değişen sözleşmeler

- `Yarına ertele` uygunluğu kart, detay ve application mutation için tek merkezi domain/read-model helper üzerinden değerlendirilir.
- Timed kayıtlar `next_attention_at` UTC değerinden Europe/Istanbul yerel gününe; all-day kayıtlar `all_day_local_date` üzerinden değerlendirilir.
- Gecikmiş ve bugün tarihli, bağımsız, aktif ve trash olmayan reminder uygundur.
- Yarın veya daha ileri tarihli, `attendanceDayId` taşıyan, terminal ya da trash reminder uygun değildir.
- Uygun olmayan direct mutation fail-closed reddedilir; row, revision, event ve notification binding değişmez.
- Uygun bağımsız reminder için mevcut yerel saat/all-day yarın ve notification reconciliation davranışı korunur.
- Puantaj recurrence/occurrence motoru, kaynak deep-link'i ve saat sözleşmesi değiştirilmez.
- Schema `10`, backup formatı `1` ve mevcut migration seti değişmez.

## Zorunlu sentetik kök neden kanıtı

Gerçek kullanıcı reminder veya Puantaj verisi okunmaz.

1. Bugün tarihli bağımsız reminder — uygun.
2. Gecikmiş bağımsız reminder — uygun.
3. Yarın tarihli bağımsız reminder — uygun değil.
4. Yarından sonraki bağımsız reminder — uygun değil.
5. Bugün tarihli Puantaj reminder'ı — uygun değil.
6. UTC tarihi farklı fakat İstanbul yerel günü yarın olan reminder — uygun değil.

## Başlangıç exact changed-file allowlist

Preflight gerçek call-site'lara göre bu üst sınırı daraltabilir. Yalnız aşağıdaki dosyalar değiştirilebilir:

1. `.cse/tasks/262_task.md`
2. `.cse/results/262_result.md`
3. `CHANGELOG.md`
4. `ROADMAP.md`
5. `docs/262_reminder_tomorrow_action_eligibility.md`
6. `docs/project_decisions.md`
7. `learning/262_reminder_tomorrow_action_eligibility.md`
8. `mobile/lib/domain/agenda_models.dart`
9. `mobile/lib/application/agenda_application.dart`
10. `mobile/lib/features/reminders/reminders_page.dart`
11. `mobile/lib/features/reminders/reminder_detail_page.dart`
12. `mobile/test/reminder_lifecycle_test.dart`
13. `mobile/test/reminder_widget_test.dart`
14. `mobile/test/support/fake_agenda_application.dart`

Allowlist dışında production veya test dosyası ihtiyacı çıkarsa edit durur; kapsam kendiliğinden genişletilmez.

## Zorunlu uygulama

- Ortak eligibility helper'ı reminder source, lifecycle, trash ve Europe/Istanbul yerel günü üzerinden fail-closed tanımla.
- Kart ve detay action görünürlüğünü aynı helper'a bağla.
- `snoozeTomorrowMorning` application mutation'ını aynı helper ile koru.
- Uygun mutation'da saatli yerel saati, all-day yarın gününü ve mevcut notification reconciliation yolunu koru.
- Uygun olmayan mutation'da row/revision/event/notification binding değişmezliğini test et.
- Puantaj kaynaklı kart ve detayda `Yarına ertele` gösterme; mevcutsa `Puantajı aç` yolunu koru.
- Gizli action'ın boş/bozuk UI alanı bırakmamasını ve double-tap guard'ı koru.

## İzin verilen doğrulama

- Focused reminder domain/application testleri: timed/all-day bugün, gecikmiş, yarın, gelecek, attendance-linked, terminal/trash, İstanbul gece yarısı, mutation semantics, rollback/no-op, revision/event/notification binding, stale revision, idempotent retry.
- Focused reminder widget testleri: Bugün/Gecikenler görünürlük, Yarın/Yaklaşanlar gizleme, Puantaj kart/detay, kaynak deep-link, 320 px, büyük yazı, dark theme, double-tap guard ve boş action alanı.
- `flutter test --no-pub`.
- `flutter analyze --no-pub`.
- `git diff --check`.
- Exact allowlist ve protected-path kontrolleri.
- Bütün kaynak kapıları PASS olursa imza uyumlu veri koruyan normal field APK build'i ve yalnız sentetik reminder kayıtlarıyla dar fiziksel cihaz smoke.

Flutter yalnız:

`C:\Users\Fatih\.cache\flutter-sdk\3.44.6-ee80f08\flutter\bin\flutter.bat`

## Fiziksel cihaz minimum kapsamı

- Normal field APK; uninstall, clear-data veya downgrade yok.
- Yalnız sentetik kayıtlar: bugün bağımsız reminder, yarın bağımsız reminder ve Puantaj kaynaklı reminder.
- Bugün reminder'da eylem görünür; yarın ve Puantaj reminder'larında görünmez.
- Uygun kayıtta erteleme çalışır ve normal kapat/aç sonrası zaman korunur.
- Gerçek kullanıcı kaydını açma, okuma, değiştirme veya içeriğini raporlama yok.
- Draft PR #259 acceptance harness'ına bağımlılık yok.

## Yeniden kullanılacak kanıt ve kapsam dışı

- Schema 10, backup formatı 1, signing/application ID ve değişmeyen release/notification altyapısı için current merged kanıt yeniden kullanılır; bu sözleşmeler değiştirilmeyecektir.
- Draft PR #259 kodu merge, cherry-pick, copy veya hotfix branch'ine taşıma yoluyla kullanılmaz.
- Puantaj recurrence/occurrence motoru, Puantaj saat ayarı, Ajanda–Hatırlatıcı metin senkronu, liste/scroll konumu, Türkçe kopyalama menüsü, günlük log export ve başka kaynak reminder politikaları kapsam dışıdır.
- `device-backups/`, `reports/`, Issue #255 stale generated dizinleri ve diğer kullanıcı ignored/untracked alanları listelenmez, okunmaz, değiştirilmez, silinmez, taşınmaz, stage veya commit edilmez.

## Bütçe ve stop koşulları

- Tek primary implementation run.
- Yalnız doğrulanmış blocker için en fazla bir correction run; aynı başarısız adım exact düzeltmeden sonra yalnız bir kez tekrarlanır.
- Schema/migration, allowlist dışı production dosyası, gerçek kullanıcı verisi, downgrade/uninstall/clear-data veya ikinci correction ihtiyacı çıkarsa dur ve raporla.
- Bütün kapılar PASS olmadan commit, push veya PR yok.

## GitHub yetkileri

- Commit mesajı: `Align reminder tomorrow action eligibility`
- Ordinary commit ve normal push: yalnız bütün kapılar PASS ise izinli.
- Draft PR: yalnız bütün kapılar PASS ise izinli.
- Ready/merge, force push, branch silme, reset, clean, stash ve kullanıcı dosyalarını etkileyen checkout: izinli değil.
