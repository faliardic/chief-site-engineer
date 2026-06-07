# Adim 060 - Uygunsuzluk Arsiv Listeleme Butunluk Kontrolu

## Amac

Bu adimda `NonconformityRepository` icindeki arsivleme, restore, aktif listeleme, arsiv listeleme, tum listeleme ve arsiv ozeti davranislarinin birlikte tutarli calistigi dogrulandi.

Bu bir yeni davranis ekleme adimi degildir. Mevcut davranislarin ayni is akisi icinde birbirini bozmadan calistigi test ve dokumantasyonla sabitlendi.

## Kontrol Edilen Davranis Zinciri

Butunluk testi su akisi kontrol eder:

- Birden fazla NCR kaydi repository'ye eklenir.
- Baslangicta `list_all()` tum kayitlari dondurur.
- Baslangicta `list_active()` tum kayitlari dondurur.
- Baslangicta `list_archived()` bos liste dondurur.
- Baslangicta `get_archive_summary()` aktif sayisini toplam kayit sayisina esit gosterir.
- Bazi kayitlar `archive()` ile arsivlenir.
- Arsivleme sonrasi `list_all()` toplam kayit listesini korur.
- Arsivleme sonrasi `list_active()` sadece aktif kalanlari dondurur.
- Arsivleme sonrasi `list_archived()` sadece arsivlenenleri dondurur.
- Arsivleme sonrasi `get_archive_summary()` aktif, arsivlenmis ve toplam sayilari dogru dondurur.
- Arsivlenmis bir kayit `restore()` ile tekrar aktif hale getirilir.
- Restore sonrasi kayit aktif listede gorunur ve arsiv listesinden cikar.
- Restore sonrasi `list_all()` toplam kayit listesini korur.
- Restore sonrasi `get_archive_summary()` guncel sayilari dondurur.

## Status Korunumu

Bu adimda ozellikle `status` alaninin kendiliginden degismedigi dogrulandi.

`archive()` ve `restore()` sadece `is_archived` alanini etkiler. Kaydin `status` degeri otomatik olarak `closed`, `open`, `archived` veya baska bir degere cevrilmez.

## Neden Yeni Method Eklenmedi?

Mevcut repository davranislari bu ihtiyaci zaten karsiliyordu:

- `archive()`
- `restore()`
- `list_active()`
- `list_archived()`
- `list_all()`
- `get_archive_summary()`

Bu nedenle uygulama kodu degistirilmedi. Bu adim test ve dokumantasyonla davranis butunlugunu guvence altina aldi.

## Kapsam Disi Birakilanlar

Bu adimda sunlar eklenmedi:

- JSON kayit sistemi
- SQLite veya veritabani sorgusu
- API
- GUI
- CLI
- Dashboard
- Silme mantigi
- Otomatik durum gecmisi
- Otomatik workflow
- Buyuk refactor

## Santiye Pratigindeki Karsiligi

Sahada bir NCR kaydi aktif takipten arsive alinabilir ve daha sonra tekrar aktif hale getirilebilir. Bu islemler sirasinda kaydin sistem hafizasindan silinmemesi gerekir.

Bu butunluk kontrolu, kalite kayitlarinin aktif, arsiv ve tum kayit listelerinde tutarli gorunmesini saglayan temel guvenlik kontroludur.
