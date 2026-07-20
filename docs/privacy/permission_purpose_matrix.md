# Mobil İzin Amaç Matrisi

| Platform/izin | Amaç | İstem zamanı | Red sonucu |
|---|---|---|---|
| Android `CAMERA` / iOS Camera | Kullanıcının başlattığı saha kanıt fotoğrafı | Kamera seçilince | Kayıt korunur, fotoğraf işlemi `denied/unavailable` olur. |
| Android `POST_NOTIFICATIONS` / iOS Notifications | Yerel kullanıcı planlı tek-seferlik veya tekrarlayan hatırlatıcı | Kullanıcı planlı reminder oluşturduğunda | Reminder SQLite'ta kalır, binding `permission_denied` olur. |
| Android `RECEIVE_BOOT_COMPLETED` | Cihaz açılışında pending yerel notification'ları yeniden kurmak | Kullanıcı arayüzü izni değildir | SQLite truth açılışta reconcile edilir. |
| Android `SCHEDULE_EXACT_ALARM` | Kullanıcının belirlediği 15/30/60 dakika, yarın ve saatlik saha hatırlatıcılarını uygulama kapalıyken güvenilir zamanda teslim etmek | Yalnız kullanıcı planlı reminder oluşturduğunda Android özel erişim ekranı açılır | Reminder SQLite'ta ve mümkünse açıkça `inexact` yedek planda kalır; binding teslimat garantisi vermeyen tanı durumuna geçer. |
| Android Photo Picker / iOS Photo Library Picker | Kullanıcının tekil fotoğraf seçimi | Kullanıcı galeri seçince | Geniş erişim verilmez; seçim iptal/ret ile kapanır. |
| Android SAF / iOS document picker | Kullanıcının tekil PDF/dosya seçimi ve backup seçimi | Kullanıcı dosya seçince | Kayıt mutasyonu başlamaz. |

Release izin allowlist'i yalnız `CAMERA`, `POST_NOTIFICATIONS`,
`RECEIVE_BOOT_COMPLETED` ve kullanıcı tarafından yönetilen
`SCHEDULE_EXACT_ALARM` özel erişimidir. `INTERNET`, broad media/storage,
location, microphone, contact, `USE_EXACT_ALARM` ve foreground service
izinleri yasaktır. Debug manifestindeki
`INTERNET` yalnız Flutter debug bağlantısı içindir ve release merge'e girmez.
AndroidX'in merged manifestte oluşturduğu
`com.faliardic.chiefsiteengineer.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`
yalnız aynı imzalı uygulamaya açık `signature` korumalı app-private izindir;
sensitive OS izni allowlist'ine dahil değildir ve exact adı/seviyesi test edilir.
