# Adim 064 - Uygunsuzluk Id Ile Kayit Bulma

## Amac

Bu adimda `NonconformityRepository.find_by_id(nonconformity_id)` davranisi test ve dokumantasyonla netlestirildi.

Bu davranis, verilen NCR kimligine sahip kaydi repository icinde bulmak icin kullanilir.

## Onemli Not

`find_by_id()` methodu repository icinde zaten bulunuyordu. Bu nedenle Adim 064'te ayni method tekrar eklenmedi.

Bu adimda mevcut davranis, aktif kayitlar, arsivlenmis kayitlar, restore edilmis kayitlar ve olmayan id durumlari icin ek testlerle sabitlendi.

## Beklenen Davranis

`find_by_id(nonconformity_id)` su kurallara gore calisir:

- Verilen `nonconformity_id` ile eslesen kaydi dondurur.
- Eslesen kayit yoksa `None` dondurur.
- Aktif kayitlari bulur.
- Arsivlenmis kayitlari da bulur.
- Restore edilmis kayitlari bulmaya devam eder.
- Kayitlari silmez.
- `status` alanini degistirmez.
- `is_archived` alanini degistirmez.
- Otomatik history veya workflow olusturmaz.

## Arsiv Kayitlari Neden Dislanmaz?

Id ile arama, repository icindeki tam kayit hafizasi uzerinde calisir. Bu nedenle kayit aktif olsa da arsivlenmis olsa da bulunabilmelidir.

Arsivlenmis kayitlar kalite gecmisinin parcasidir. Id biliniyorsa kaydin sistemde bulunmasi gerekir.

## Restore Sonrasi Beklenti

Bir kayit once arsivlenip sonra restore edilirse, ayni `nonconformity_id` ile bulunmaya devam eder.

Restore yeni kayit olusturmaz. Mevcut kaydin `is_archived` alanini tekrar `False` yapar.

## Kapsam Disi Birakilanlar

Bu adimda sunlar eklenmedi:

- JSON
- SQLite
- API
- GUI
- CLI
- Buyuk refactor
- Silme mantigi
- Yeni query engine
- Otomatik history
- Otomatik workflow

Bu adim sadece mevcut bellek ici id ile kayit bulma davranisini netlestirir.

## Santiye Pratigindeki Karsiligi

Sahada bir NCR numarasi biliniyorsa, kaydin aktif veya arsivlenmis olmasindan bagimsiz olarak bulunabilmesi gerekir.

Bu davranis, "NCR-075 kaydi nerede?" gibi net bir soruya hizli cevap verir. Kalite denetimi, toplantilar ve gecmise donuk incelemeler icin temel bir arama davranisidir.
