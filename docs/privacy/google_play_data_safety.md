# Google Play Data Safety Cevap Matrisi

Bu matris `0.1.0` RC artifact'i ve kaynak audit'i içindir; Play Console'a
gönderim yapılmamıştır.

| Soru | RC cevabı | Kanıt/gerekçe |
|---|---|---|
| Uygulama kullanıcı verisi topluyor mu? | Hayır | Veriler yalnız cihazda işlenir; release manifestinde `INTERNET` yoktur, runtime endpoint/analytics audit'i temizdir. |
| Veri başka şirket/kuruluşla paylaşılıyor mu? | Hayır | Otomatik transfer yoktur. Kullanıcının sistem paylaşım ekranında seçtiği hedefe açık transferi, CSE geliştiricisinin sunucusuna paylaşım değildir. |
| Analytics, reklam veya tracking var mı? | Hayır | İlgili SDK bağımlılığı ve tracking domain'i yoktur. |
| Veri aktarımda şifreleniyor mu? | Uygulanamaz | Geliştiriciye ağ aktarımı yoktur. Kullanıcı-seçimli hedef uygulama kendi güvenliğinden sorumludur. |
| Hesap oluşturma/silme var mı? | Hayır / uygulanamaz | Uygulama tek-owner ve hesapsızdır. |
| Uygulama verisi silinebilir mi? | OS uygulama kaldırma ile | Kaldırma öncesi doğrulanmış `.csebackup` zorunlu kullanıcı uyarısıdır. |
| Güvenlik uygulaması | Parolalı taşınabilir yedek | `.csebackup` AES-256-GCM ve PBKDF2-HMAC-SHA256 kullanır; parola kurtarılamaz. |

Google'ın Data Safety tanımı, yalnız cihazda kalan ve cihaz dışına iletilmeyen
erişimi “collection” saymayabilir. Buna rağmen nihai Console cevapları upload
edilecek exact artifact ve o tarihteki bütün SDK'lar yeniden audit edilerek
hesap sahibi tarafından doğrulanmalıdır.

Resmî kaynaklar:

- https://support.google.com/googleplay/android-developer/answer/10787469
- https://support.google.com/googleplay/android-developer/answer/14115180
