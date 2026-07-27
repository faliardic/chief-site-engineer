# Issue #252 — Hatırlatıcı hızlı eylem netliği ve 2/3 saat erteleme

## Güvenli başlangıç

- Resmî yerel repo: `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer`
- Başlangıç dalı: `master`
- Beklenen ve doğrulanan base SHA: `4712c097688029b86787e2704681074497881c9f`
- Çalışma dalı: `codex/issue-252-reminder-quick-action-clarity`
- Validation class: `domain`
- Codex modeli: bu çalışmadaki mevcut tam Codex modeli
- Reasoning seviyesi: `High`
- Seçim nedeni: Dar fakat transaction, optimistic revision, notification reconciliation ve birden çok reminder kullanıcı yüzeyini birlikte etkileyen regresyon duyarlı mobil değişiklik.
- Paralel alt ajan: yok.

## Değişen sözleşmeler

- Reminder oluşturma ve yeniden planlama seçeneklerine ayrı `2 saat` ve `3 saat` davranışları eklenir.
- Reminder mutation sözleşmesine aktif kaydı tam iki veya üç saat ileri taşıyan ayrı eylemler eklenir.
- Üstteki salt-okunur `Yarın` görünüm filtresi değişmez.
- Kart ve detay mutation dili `Yarın` yerine `Yarına ertele` olur.
- Başarısız yarına erteleme metni `Hatırlatıcı yarına ertelenemedi.` olur.
- Canonical UTC, `snoozeTomorrowMorning`, transaction, optimistic revision, event idempotency ve native notification reconciliation sözleşmeleri korunur.

## Exact changed-file allowlist

Yalnız aşağıdaki dosyalar değiştirilebilir:

1. `.cse/tasks/252_task.md`
2. `.cse/results/252_result.md`
3. `.cse/state/project_state.json`
4. `CHANGELOG.md`
5. `ROADMAP.md`
6. `docs/252_reminder_quick_action_clarity.md`
7. `docs/project_decisions.md`
8. `learning/252_reminder_quick_action_clarity.md`
9. `learning/GLOSSARY.md` — yalnız gerçekten yeni kalıcı terim gerekiyorsa
10. `mobile/lib/domain/agenda_models.dart`
11. `mobile/lib/application/agenda_application.dart`
12. `mobile/lib/features/reminders/reminders_page.dart`
13. `mobile/lib/features/reminders/reminder_detail_page.dart`
14. `mobile/lib/features/reminders/reminder_form_page.dart`
15. `mobile/test/reminder_lifecycle_test.dart`
16. `mobile/test/reminder_widget_test.dart`
17. `mobile/test/agenda_application_test.dart` — yalnız enum/schedule regresyon matrisi gerektirirse
18. `mobile/test/support/fake_agenda_application.dart`

Allowlist dışında gerçek bir ihtiyaç çıkarsa edit durur; kapsam kendiliğinden genişletilmez.

## Zorunlu uygulama

- `ReminderScheduleKind` içinde 2 ve 3 saat seçeneklerini mevcut isim standardıyla ayrı temsil et.
- `ReminderMutationAction` içinde 2 ve 3 saat erteleme eylemlerini ayrı temsil et.
- Schedule resolution ve mutation akışını mevcut canonical UTC ve transaction yoluna bağla.
- Reminder formu ile detay yeniden planlama panelinde `2 saat` ve `3 saat` seçeneklerini göster.
- Uygun kart ve detay mutation düğmesini `Yarına ertele` olarak göster.
- Yarın görünümünde kart mutation düğmesini göstermeme davranışını koru.
- Mevcut notification reconciliation, stale revision, retry/no-op ve rollback davranışlarını koru.

## İzin verilen doğrulama

- Odaklı reminder domain/application testleri.
- Odaklı reminder widget testleri.
- `flutter test --no-pub` mobil full suite.
- `flutter analyze --no-pub`.
- `git diff --check`.
- Exact allowlist, production diff ve protected-path kontrolleri.

Flutter yalnız:

`C:\Users\Fatih\.cache\flutter-sdk\3.44.6-ee80f08\flutter\bin\flutter.bat`

## Yeniden kullanılacak kanıt

- Schema/migration, backup/restore, Android manifest, application ID, signing, ARM64/16 KiB, exact-alarm/permission, boot/update ve fiziksel cihaz artifact sözleşmeleri değişmez.
- Bu kapılar için PR #249 / merged `master` `4712c097688029b86787e2704681074497881c9f` ve bağlı release/saha kabul Issue kanıtları yeniden kullanılır.

## Kapsam dışı ve çalıştırılmayacak kapılar

- Schema, migration, persistence modeli ve backup formatı.
- Notification channel, permission, exact alarm, boot veya update sözleşmesi.
- Reminder kartlarının genel refactor'ı ve recurrence interval motoru.
- Ajanda–Hatırlatıcı metin senkronu, ana ekran ipuçları, Attachment v2 ve Universal Capture.
- Python full suite, release build, APK/AAB, signing, backup/restore, reboot ve fiziksel cihaz acceptance.
- Gerçek kullanıcı verisini okuma veya değiştirme.
- `device-backups/`, `reports/` ve diğer kullanıcıya ait ignored/untracked alanları okuma, değiştirme, silme, taşıma, stage etme veya commit kapsamına alma.

## Bütçe ve stop koşulları

- Hedef: 30–45 dakika.
- Hard stop: 75 dakika.
- Retry: 1 primary implementation run; yalnız doğrulanmış blocker için en fazla 1 correction run; aynı başarısız işlem exact düzeltmeden sonra en fazla bir kez tekrarlanır.
- Fiziksel cihaz minimum kapsamı: yok; runtime/artifact sözleşmesi değişmedikçe kaynak ve widget doğrulaması yeterlidir.
- Kapsam dışı dosya ihtiyacı, ikinci ortam/otomasyon hatası, release/platform değişikliği ihtiyacı, yeni kullanıcı verisi riski veya hard stop durumunda edit durur.

## GitHub yetkileri

- Commit: izinli.
- Push: izinli.
- Draft PR: izinli ve Issue tarafından isteniyor.
- Ready/merge: izinli değil; review ve kullanıcı onayı gerekir.
- Force push, branch silme, reset, clean, stash ve kullanıcı dosyalarını etkileyen checkout: yasak.
- Post-merge sync: bu çalışmanın kapsamında değil.

## Açık ikinci correction yetkisi

İlk correction sonrasında aynı iki eski widget testi viewport/materialization
nedeniyle blokajda kaldı. Kullanıcı ikinci correction'ı şu dar sınırla açıkça
yetkilendirdi:

- yalnız `mobile/test/reminder_widget_test.dart`;
- yalnız hata kartını assertion öncesi materialize eden scroll konumu ve
  teslimat etkileşim testinin viewport yüksekliği;
- production, domain/application, schema, backup, notification ve Android
  platform kodunda değişiklik yok;
- iki başarısız widget testi tek focused komutta yalnız bir kez tekrar edilir;
- PASS sonrasında kod değişmeden mobile full suite, analyze, diff ve protected
  path kapıları çalıştırılır.
