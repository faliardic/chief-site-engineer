# Android 0.1 RC Saha Kabul Checklist'i

Bu belge doldurulabilir kullanıcı kanıt şablonudur. Issue #191 hiçbir satırı
kullanıcı adına geçti saymaz.

Ön koşullar:

- [ ] Gerçek kullanıcı verisiyle başlamadan doğrulanmış `.csebackup` alındı.
- [ ] Backup parolasının kurtarılamadığı doğrulandı ve güvenli yerde tutuldu.
- [ ] RC APK SHA-256 checksum'u gate çıktısıyla eşleşti.
- [ ] Debug/RC package ve ephemeral imza çakışma etkisi anlaşıldı.

| # | Saha deneyi | Sonuç (`pass/fail/not run`) | Tarih/saat | Güvenli not (gerçek kayıt içeriği yok) |
|---:|---|---|---|---|
| 1 | Temiz kurulum ve ilk proje | not run |  |  |
| 2 | `+ Unutma` ve gerçek yerel bildirim | not run |  |  |
| 3 | Geriye dönük Ajanda kaydı | not run |  |  |
| 4 | Bir günlük Puantaj | not run |  |  |
| 5 | Beton Paketi + mikser + irsaliye fotoğrafı + numune | not run |  |  |
| 6 | Force-stop ve uygulama restart | not run |  |  |
| 7 | İnternet kapalı temel kullanım | not run |  |  |
| 8 | Kamera ve bildirim permission denied | not run |  |  |
| 9 | Parolalı tam backup oluşturma | not run |  |  |
| 10 | Veriyi değiştirip restore etme | not run |  |  |
| 11 | Attachment SHA bütünlüğü | not run |  |  |
| 12 | Önceki schema/app sürümünden update/upgrade | not run |  |  |

Kritik data loss, yanlış proje/private leakage, attachment bozulması, restore
recovery belirsizliği veya notification/reminder bağı kopması görülürse pilot
durdurulur; workaround ile `pass` verilmez.
