# Issue #272 — Hatırlatıcı Bildirim İzolasyonu

## Yürütme kimliği

- Resmî repository: `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer`
- Issue: `#272`
- Beklenen base/master: `b113f0d2bf964a51d2cf3f195a5a1ec038ad234c`
- Branch: `codex/issue-272-reminder-notification-isolation`
- Codex modeli: current full model
- Reasoning seviyesi: Extra High
- Seçim nedeni: Notification reconciliation, optimistic revision, append-only event ve platform binding izolasyonu regresyon duyarlı production sözleşmeleridir.
- Validation class: `domain`

## Değişen sözleşmeler

- Native pending listesinde bulunmayan, teslim edilmiş fakat source reminder'ı hâlâ aktif olan gecikmiş tek-seferlik notification terminal sayılmaz.
- Başka bir reminder mutation/reconcile akışında bu notification iptal edilmez, yeniden planlanmaz ve binding alanları güncellenmez.
- Completed, cancelled, trashed, inbox veya gerçekten geçersiz binding yalnız kendi platform kimliğiyle iptal edilir.
- Future pending, overdue repeat, permission/channel, exact-alarm fallback, capacity, orphan/mismatched payload, platform kimliği ve deep-link UUID davranışları değişmez.

## Başlangıç durumu

- Exact başlangıç komutları sırasıyla çalıştırıldı.
- Branch: `master`
- `HEAD`: `b113f0d2bf964a51d2cf3f195a5a1ec038ad234c`
- `origin/master...master`: `0 0`
- Tracked diff: `0`
- Staged diff: `0`
- Önceden mevcut protected/stale untracked dizinler okunmadı ve değiştirilmedi.
- GitHub Issue execution contract yorumu: `#issuecomment-5117943838`

## Yetkili dosyalar

Source/test checkpoint allowlist:

1. `.cse/tasks/272_task.md`
2. `mobile/lib/application/agenda_application.dart`
3. `mobile/test/reminder_lifecycle_test.dart`

Production PASS sonrasında completion allowlist:

4. `.cse/results/272_result.md`
5. `CHANGELOG.md`
6. `ROADMAP.md`
7. `docs/272_reminder_notification_isolation.md`
8. `docs/project_decisions.md`
9. `learning/272_reminder_notification_isolation.md`

Production editinden önce yalnız task ve test dosyası değişebilir. Production çözümü yalnız `agenda_application.dart` içinde kalmalıdır.

## Baseline kapısı

- Base: exact merged master `b113f0d2bf964a51d2cf3f195a5a1ec038ad234c`
- İlk worktree: `C:\Users\Fatih\AppData\Local\Temp\cse272-baseline-20260729155052961-60ff4a91`
- İlk kopya SHA-256 eşliği: `2/2`
- İlk deneme sonucu: yeni testte var olmayan `ReminderLifecycleDetail` type annotation'ı nedeniyle test yükleme/compile hatası; behavior assertion'ı çalışmadı.
- Correction: explicit type kaldırıldı; izin verilen tek source/test correction kullanıldı. İlk worktree değiştirilmedi, yeniden kullanılmadı ve silinmedi.
- Düzeltilmiş worktree: `C:\Users\Fatih\AppData\Local\Temp\cse272-baseline-20260729155236515-65892d2a`
- Kopyalanan dosyalar: task + test
- Düzeltilmiş SHA-256 eşliği: `2/2`
- Komutlar: disposable `mobile` içinde bir kez `flutter pub get`, ardından `flutter test --no-pub test/reminder_lifecycle_test.dart`
- Beklenen: yeni delivered-one-time izolasyon testi FAIL; unrelated failure `0`
- Sonuç: `32 PASS / 1 expected FAIL / 0 unrelated failure`.
- Exact expected failure: `Expected: [77460680]`, `Actual: [127793537, 77460680, 94238299]`; completing middle reminder cancelled A, B ve C platform kimliklerini birlikte hedefledi.
- Baseline worktree yeniden kullanılmayacak, değiştirilmeyecek veya silinmeyecek.

## Focused test matrisi

En az şu 24 senaryo doğrulanır:

1. Üç delivered one-time reminder, ortadakini complete.
2. Üç delivered one-time reminder, ortadakini cancel.
3. Üç delivered one-time reminder, ortadakini trash.
4. Delivered aktif reminder + explicit reconcile.
5. Delivered aktif reminder + yeniden açılmış application reconcile.
6. Delivered aktif A + başka B snooze.
7. A snooze yalnız A platform kimliğini hedefler.
8. C cancel yalnız C platform kimliğini hedefler.
9. C trash yalnız C platform kimliğini hedefler.
10. Gelecekteki üç pending reminder korunur.
11. Overdue repeat mevcut normal reconcile davranışını korur.
12. Terminal reminder targeted cancel olur.
13. Inbox reminder targeted cancel olur.
14. Trashed reminder targeted cancel olur.
15. Orphan pending temizlenir.
16. Mismatched reminder payload pending temizlenir.
17. Eksik schedule yeniden kurulur.
18. Platform notification ID'leri benzersiz kalır.
19. İlgisiz binding `platform_notification_id` değişmez.
20. İlgisiz binding `scheduled_for/repeat/safe_error` değişmez.
21. Duplicate event ID yeni business event üretmez.
22. Stale revision row/event/binding durumunu değiştirmez.
23. Cancel failure source mutation'ını geri almaz ve güvenli hata durumunu yazar.
24. Permission denied davranışı korunur.
25. Channel disabled + restart davranışı korunur.
26. Exact alarm fallback davranışı korunur.
27. Capacity-limited reminder davranışı korunur.
28. Displayed state pending sorgusundan bağımsız kalır.
29. Cancel yalnız exact ID'yi pending ve displayed listelerinden kaldırır.
30. Notification payload doğru reminder UUID'sini taşır.

## İzin verilen doğrulamalar

Focused tests:

- `flutter test --no-pub test/reminder_lifecycle_test.dart`
- `flutter test --no-pub test/delayed_hourly_notification_test.dart`
- Normal `flutter test` ile desteklenen ilgili exact background/reboot testleri

Allowed broad gates:

- Unique disposable source-validation worktree'de bir kez `flutter test --no-pub`
- Aynı worktree'de bir kez `flutter analyze --no-pub`
- Source/test checkpoint sonrasında unique disposable build worktree'de tam bir `flutter build apk --debug --target lib\main.dart --no-pub`
- Exact cihazda minimum fiziksel smoke

Main worktree'de `flutter pub get`, test, analyze, build veya clean çalıştırılmaz.

## Source/test validation kaydı

- Worktree: `C:\Users\Fatih\AppData\Local\Temp\cse272-source-validation-20260729155829118-b9d391c8`
- Detached base: `b113f0d2bf964a51d2cf3f195a5a1ec038ad234c`
- Exact dosya SHA-256 eşliği: `3/3`
- Unexpected tracked path: `0`
- `flutter pub get` invocation: `1`
- Lockfile diff: `0`
- İlk focused sonuç: `42 PASS / 2 test-only expectation failure`.
- Exact test-only blockers: duplicate complete event retry mevcut optimistic revision sözleşmesi gereği validation failure döndürür; future schedule kendi ID'sini normal pre-schedule cancel ile hedefler. Delivered peer ID'si hedeflenmedi.
- Düzeltme: yalnız bu iki test beklentisi daraltıldı; production source değişmedi. İlk source-validation worktree değiştirilmedi, yeniden kullanılmayacak ve silinmeyecek.
- Correction source-validation worktree: `C:\Users\Fatih\AppData\Local\Temp\cse272-source-validation-20260729160048773-dec7b0a1`
- Correction focused: `44/44 PASS`
- Related delayed-hourly: `4/4 PASS`
- Background/reboot/static configuration: `14/14 PASS`
- Full Flutter suite: `320/320 PASS`
- Analyze: yalnız yeni testte kullanılmayan `completed` yerel değişkeni için `1` warning; production warning/error `0`.
- Analyze exact fix: completed status assertion'ı eklendi; production source değişmedi.
- Final source-validation worktree: `C:\Users\Fatih\AppData\Local\Temp\cse272-source-validation-20260729160400914-521b9220`
- Final exact dosya SHA-256 eşliği: `3/3`
- Final unexpected tracked path: `0`
- Final `flutter pub get` invocation: `1`
- Final lockfile diff: `0`
- Final focused: `44/44 PASS`
- Final full Flutter suite: `320/320 PASS`
- Final analyze: `0 issue`
- Related delayed-hourly `4/4` ve background/reboot/static `14/14` kanıtı aynı production source revision'daki önceki correction worktree'den yeniden kullanıldı; son değişiklik yalnız focused testte status assertion'ıdır.
- `git diff --check`: PASS
- Schema: `10`
- Backup format: `1`
- Migration değişikliği: `0`
- Protected/gateway/native/storage diff: `0`

## Yeniden kullanılacak kanıtlar

- Schema `10`, backup format `1`, migration `0`: bu Issue schema, migration, persistence veya backup sözleşmesini değiştirmez.
- Application/package ID, signing, background delivery ve reboot sözleşmeleri: production değişikliği application reconciliation ile sınırlıdır; son merged kanıtlar yeniden kullanılır ve yeni debug artifact uyumluluğu ayrıca okunur.
- PR #259, PR #271, PR #273 source branch ve Issue #268 branch kodu/ancestry taşınmaz.

## Fiziksel cihaz kabulü

- Exact serial: `R5CY21WKZFX`
- Install: yalnız `adb install -r -g <exact-disposable-apk>`
- Sentetik prefix: `CSE272SMOKE-<timestamp>`
- Üç timed one-time reminder panelde görünür; B tamamlanınca yalnız B kaybolur.
- Restart/reconcile A ve C'yi korur; A snooze yalnız A'yı, C cancel/trash yalnız C'yi hedefler.
- Deep-link her zaman doğru sentetik reminder UUID'sini açar.
- Temizlik yalnız mevcut geri getirilebilir UI akışıyla yapılır; yoksa sentetik proje bırakılır.
- Uninstall, data clear, downgrade, hard delete, gerçek kullanıcı kaydı okuma/değiştirme: `0`.

## Bütçe ve stop sözleşmesi

- Primary run: `1`
- Correction run: exact source/test blocker için en fazla `1`
- Aynı başarısız işlem retry: exact düzeltmeden sonra en fazla `1`; build retry `0`
- Build invocation: tam `1`
- Hedef süre: `45 dakika`
- Hard stop: `60 dakika`

Stop conditions:

- Başlangıç SHA/branch/cleanliness/divergence uyumsuzluğu.
- Baseline hipotezinin doğrulanmaması veya unrelated failure.
- Notification gateway/native/schema/migration/backup ya da allowlist dışı production dosyası gereksinimi.
- Source validation, tek build, artifact uyumluluğu veya exact cihaz kapısının başarısızlığı.
- Fiziksel smoke failure, protected path mutation veya gerçek kullanıcı verisi riski.

## Kapsam dışı

- D29.2 Ajanda arama odağı/klavye işi.
- Yarın sabah/hafta başı erteleme veya erkene alma.
- Proje filtresi, özel bildirim sesi, Beton notification/widget.
- Genel notification framework rewrite.
- Gateway/native/schema/migration/backup formatı değişikliği.
- PR #259, PR #271, PR #273 source branch veya Issue #268 branch değişiklikleri.

## GitHub yayınlama izni

Bütün kapılar PASS olursa:

1. `Fix reminder notification isolation`
2. `Complete reminder notification isolation validation`

olmak üzere tam iki ordinary commit, normal push ve `Related to #272` ile başlayan `Preserve unrelated reminder notifications` başlıklı tek Draft PR yetkilidir.

Force-push, amend, Ready, merge, Issue close ve branch delete yetkili değildir.
