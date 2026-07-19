# Mobil İzin Amaç Matrisi

| Platform/izin | Amaç | İstem zamanı | Red sonucu |
|---|---|---|---|
| Android `CAMERA` / iOS Camera | Kullanıcının başlattığı saha kanıt fotoğrafı | Kamera seçilince | Kayıt korunur, fotoğraf işlemi `denied/unavailable` olur. |
| Android `POST_NOTIFICATIONS` / iOS Notifications | Yerel tek-seferlik hatırlatıcı | Kullanıcı planlı reminder oluşturduğunda | Reminder SQLite'ta kalır, binding `permission_denied` olur. |
| Android `RECEIVE_BOOT_COMPLETED` | Cihaz açılışında pending yerel notification'ları yeniden kurmak | Kullanıcı arayüzü izni değildir | SQLite truth açılışta reconcile edilir. |
| Android Photo Picker / iOS Photo Library Picker | Kullanıcının tekil fotoğraf seçimi | Kullanıcı galeri seçince | Geniş erişim verilmez; seçim iptal/ret ile kapanır. |
| Android SAF / iOS document picker | Kullanıcının tekil PDF/dosya seçimi ve backup seçimi | Kullanıcı dosya seçince | Kayıt mutasyonu başlamaz. |

Release izin allowlist'i yalnız `CAMERA`, `POST_NOTIFICATIONS` ve
`RECEIVE_BOOT_COMPLETED`'dır. `INTERNET`, broad media/storage, location,
microphone, contact ve `USE/SCHEDULE_EXACT_ALARM` yasaktır. Debug manifestindeki
`INTERNET` yalnız Flutter debug bağlantısı içindir ve release merge'e girmez.
AndroidX'in merged manifestte oluşturduğu
`com.faliardic.chiefsiteengineer.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`
yalnız aynı imzalı uygulamaya açık `signature` korumalı app-private izindir;
sensitive OS izni allowlist'ine dahil değildir ve exact adı/seviyesi test edilir.
