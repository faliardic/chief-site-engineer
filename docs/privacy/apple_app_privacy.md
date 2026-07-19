# Apple App Privacy Cevap Matrisi

Bu matris `0.1.0` RC kaynak/audit kanıtıdır; App Store Connect'e gönderim
yapılmamıştır.

| App Privacy alanı | RC cevabı | Gerekçe |
|---|---|---|
| Data Used to Track You | Yok | `NSPrivacyTracking=false`, tracking domain'i/reklam kimliği/SDK'sı yok. |
| Data Linked to You | Toplanmıyor | Hesap ve geliştirici sunucusu yok; içerik yalnız cihazda kalır. |
| Data Not Linked to You | Toplanmıyor | Analytics, crash telemetry ve off-device diagnostic gönderimi yok. |
| Photos or Videos | Geliştirici tarafından toplanmıyor | Kullanıcı tekil fotoğrafı sistem seçicisiyle cihaz-içi saha kaydına bağlar. |
| User Content | Geliştirici tarafından toplanmıyor | Serbest metin ve saha kayıtları yalnız cihazda işlenir. |
| Diagnostics | Toplanmıyor | Raw crash/stack kullanıcıya gösterilmez ve uzak crash servisine gönderilmez. |

Apple'ın açıklamasına göre yalnız cihazda işlenen ve sunucuya gönderilmeyen veri
“collected” sayılmaz. Nihai archive, macOS/Xcode Privacy Report ile incelenmeden
App Store beyanı tamamlanmış sayılmaz.

Resmî kaynaklar:

- https://developer.apple.com/app-store/app-privacy-details/
- https://developer.apple.com/documentation/bundleresources/adding-a-privacy-manifest-to-your-app-or-third-party-sdk
