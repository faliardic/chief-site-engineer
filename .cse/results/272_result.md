# Issue #272 Sonuç — Hatırlatıcı Bildirim İzolasyonu

## Sonuç

Issue #272'nin application katmanı düzeltmesi ve yetkili doğrulamaları PASS'tir.
Teslim edilmiş, aktif, gecikmiş tek-seferlik notification artık native pending
listesinde bulunmadığı için terminal sayılmaz. Başka bir reminder mutation'ı
bu kaydın notification ID'sini iptal etmez, yeniden planlamaz veya binding'ini
değiştirmez.

## Değişiklik

- `agenda_application.dart`, reminder'ları `schedulable`,
  `preserveDeliveredOneTime` ve `terminal` disposition'larına ayırır.
- Preserve edilen delivered one-time kayıt kapasite tüketmez ve normal,
  initialize-failure, permission, exact-alarm fallback ve pending-query-failure
  dallarında platform/binding churn üretmez.
- Completed, cancelled, trashed, inbox ve gerçekten geçersiz binding temizliği
  exact platform ID ile hedefli kalır.
- Gateway, native Android, schema, migration, backup ve storage değişikliği
  yapılmadı.

## Doğrulama kanıtı

- Baseline: `32 PASS / 1 expected FAIL / 0 unrelated`; eski kod orta reminder
  tamamlandığında A/B/C ID'lerini birlikte iptal etti.
- Focused reminder lifecycle: `44/44 PASS`.
- Related delayed-hourly: `4/4 PASS`.
- Background/reboot/static configuration: `14/14 PASS`.
- Full Flutter suite: `320/320 PASS`.
- Flutter analyze: `0 issue`.
- `git diff --check`: PASS.
- Schema `10`, backup formatı `1`, migration `0`.
- Exact disposable APK build: `1 PASS`, retry `0`; SHA-256
  `d9e3c15981ded35faf1863c364b438d34c18d0fb58b200ed902be68d447d1a9a`.
- Exact cihaz smoke: PASS. B tamamlandığında A/C korundu; bootstrap reconcile,
  A snooze, C cancel ve C deep-link izolasyonu doğrulandı.
- Sentetik A/B/C kayıtları geri alınabilir çöp yoluyla temizlendi; gerçek
  kullanıcı kaydı mutation'ı, uninstall, data clear ve hard delete `0`.

## Minimum yeterli doğrulama

Python full suite, release AAB/signing, ARM64/16 KiB, backup/restore ve tam
background/reboot cihaz zinciri çalıştırılmadı. Değişen sözleşme application
notification reconciliation ile sınırlıdır; schema/backup/native/package
sözleşmeleri değişmedi. Aynı source revision'daki focused, full Flutter,
analyze, static/background test ve yeni debug artifact/device kanıtı kullanıldı.

## Yayın durumu

- Checkpoint: `c42c17e347a1a934900ff41cc7a6e46e8825ec66`.
- Kapanış commit'i bu sonuç belgesiyle oluşturulur.
- Normal push sonrasında başlığı `Preserve unrelated reminder notifications`
  olan ve gövdesi `Related to #272` ile başlayan tek Draft PR açılır; URL final
  raporda verilir.
- Ready, merge, Issue close, branch delete, amend ve force-push yapılmaz.
- PR #259'a ve merge edilmemiş diğer branch'lere dokunulmadı.

## Kapsam dışı altyapı

Debug build sırasında görülen gelecekteki Kotlin Gradle Plugin geçiş uyarısı
ürün davranışını veya build sonucunu etkilemedi. Issue #272 kapsamına alınmadı.
