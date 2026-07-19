# Mobil Third-Party SDK ve Privacy Manifest Envanteri

Kaynak: `mobile/pubspec.lock`, Flutter `3.44.6`, Dart `3.12.2`. Bu envanter
19 Temmuz 2026 RC kilit dosyasını anlatır.

| Paket / kilitli platform paketi | Sürüm | Cihaz-içi amaç | iOS privacy manifest beklentisi |
|---|---:|---|---|
| `file_picker` | 10.3.10 | Sistem dosya seçicisi | Manifest var; collection/tracking/accessed API boş. |
| `flutter_local_notifications` | 22.1.0 | Yerel bildirim planlama/tap | Manifest var; UserDefaults `CA92.1`, collection/tracking yok. |
| `image_picker` / `image_picker_ios` | 1.2.3 / 0.8.13+6 | Kamera ve tekil galeri seçimi | iOS manifest var; collection/tracking/accessed API boş. |
| `path_provider` / `path_provider_foundation` | 2.1.6 / 2.6.0 | Uygulama support dizini | Paket kaynağında ayrı manifest yok; final Xcode privacy report zorunlu blocker. |
| `permission_handler` / Apple | 12.0.3 / 9.4.10 | Kamera/bildirim izin sonucu | Manifest var; UserDefaults `1C8F.1`, collection/tracking yok. |
| `share_plus` | 12.0.2 | Kullanıcının başlattığı share sheet | Manifest var; collection/tracking/accessed API boş. |
| `sqflite` / `sqflite_darwin` | 2.4.3 / 2.4.3+1 | Cihaz-içi SQLite | Manifest var; collection/tracking/accessed API boş. |
| `archive`, `crypto`, `cryptography` | 4.0.9 / 3.0.7 / 2.9.0 | Şifreli backup/ZIP/hash | Dart cihaz-içi kütüphaneler; tracking/telemetry yok. |
| `timezone` | 0.11.1 | Paketlenmiş Europe/Istanbul zaman verisi | Runtime ağ çağrısı yok; transitive `http` uygulama endpoint'i değildir. |

Doğrudan veya transitive paketlerde Firebase, Sentry, analytics, ads veya crash
telemetry servisi yoktur. `mobile/lib` endpoint audit'i boş; Android release
`INTERNET` izni yoktur. Package privacy manifest varlığı tek başına nihai Apple
uyumluluğu değildir: macOS üzerinde Xcode 26 archive, privacy report ve embedded
framework signature/manifest envanteri yeniden doğrulanır.
