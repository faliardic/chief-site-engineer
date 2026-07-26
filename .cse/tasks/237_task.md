# Issue #237 — Ajanda → Beton önerisi ve deep-link

## Güvenli başlangıç

- Başlangıç dalı: `master`
- Güvenli başlangıç SHA: `470827abc8b1f69ba8732de027b17d4b0ccb1193`
- Çalışma dalı: `codex/issue-237-agenda-concrete-suggestion-deeplink`
- Validation class: `narrow-ui + read-only cross-feature navigation`
- Model/politika: mevcut Codex tam model; paralel alt ajan yok; gereksiz mimari genişletme yok.

## Değişen sözleşmeler

- Ajanda açıklaması, ayrıntılı notu ve açık `AgendaCategory.concrete` seçimi üzerinden deterministik Beton sinyali.
- Kelime sınırına dayalı `beton` / `betonaj` algılama; `betonarme` ve `betoniyer` tek başına sinyal değildir.
- Yeni Ajanda formunda non-blocking öneri, yalnız local kategori seçimi ve same-project/same-Istanbul-day Beton destination.
- Form taslağı ve pending fotoğraflar push/pop navigasyonunda korunur; navigasyon create/event üretmez.
- Unmanaged Ajanda detayında salt-okunur öneri; managed Beton Ajanda kaydında mevcut exact managed bağlantısı tek yol kalır.
- Concrete/attachment bağımlılığı olmayan hostlarda fail-soft davranış.

## Exact changed-file allowlist

Yalnız aşağıdaki dosyalar değiştirilebilir:

1. `.cse/tasks/237_task.md`
2. `.cse/results/237_result.md`
3. `CHANGELOG.md`
4. `ROADMAP.md`
5. `docs/237_agenda_concrete_suggestion_deeplink.md`
6. `docs/project_decisions.md`
7. `learning/237_agenda_concrete_suggestion_deeplink.md`
8. `mobile/lib/features/agenda/agenda_concrete_signal.dart`
9. `mobile/lib/features/agenda/agenda_concrete_suggestion_card.dart`
10. `mobile/lib/features/agenda/agenda_page.dart`
11. `mobile/lib/features/agenda/log_form_page.dart`
12. `mobile/lib/features/agenda/log_detail_page.dart`
13. `mobile/lib/features/concrete/concrete_destination_page.dart`
14. `mobile/lib/features/concrete/concrete_page.dart`
15. `mobile/test/agenda_concrete_signal_test.dart`
16. `mobile/test/mobile_agenda_widget_test.dart`
17. `mobile/test/concrete_widget_test.dart`

## İzin verilen doğrulama

- Detector unit testleri.
- Focused Ajanda form widget testleri.
- Focused Ajanda detail widget testleri.
- Focused Concrete destination/widget testleri.
- 320 px genişlik, 1.6 text scale ve en az 44 px eylem hedefi kontrolleri.
- İlgili focused test dosyaları, ortak regresyon görülürse yalnız etkili suite.
- `flutter analyze --no-pub`.
- `git diff --check`.
- Exact allowlist ve schema/backup/platform protected diff kontrolleri.

Flutter yalnız:

`C:\Users\Fatih\.cache\flutter-sdk\3.44.6-ee80f08\flutter\bin\flutter.bat`

## Yeniden kullanılacak kanıtlar

- Güvenli başlangıç SHA'sında schema 10 / backup format 1 sözleşmesi ve Issue #234 / PR #235 persistence-cross-domain kanıtları değişmeden yeniden kullanılır.
- Platform/release sözleşmesi değişmediği için mevcut merged kanıtlar yeniden kullanılır.

## Kapsam dışı ve çalıştırılmayacak kapılar

- Otomatik Beton paketi, otomatik kategori mutation'ı, otomatik reminder.
- Beton sınıfı, mahal, metraj veya tarih tahmini.
- Schema, migration, persistence, backup ve attachment v2.
- Medya albümü, platform/release kodu ve paketler arası otomatik eşleştirme.
- Fuzzy, ML, LLM veya teknik anlam çıkarımı.
- Mobile full suite (focused testler ortak regresyon göstermedikçe).
- App database/migration, backup, Python, Android release, APK/AAB/signing, ARM64/16 KiB, reboot/background, integration/device ve fiziksel cihaz kabulü.
- `device-backups/`, `reports/` ve ignored kullanıcı dosyaları.

## Bütçe

- Hedef: 75 dakika.
- Hard stop: 120 dakika.
- Retry: 1 primary run; aynı başarısız adım için en fazla 1 correction run.
- Fiziksel cihaz minimum kapsamı: yok; Issue açıkça kapsam dışı bırakır.
