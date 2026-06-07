# Adim 059 - Uygunsuzluk Tum Kayitlari Listeleme

## Bu Adimda Ne Ogrenildi?

Bu adimda `NonconformityRepository.list_all()` davranisinin ne ise yaradigi test ve dokumantasyonla netlestirildi.

`list_all()` repository icindeki tum NCR kayitlarini dondurur. Bu davranis aktif ve arsivlenmis kayit ayrimi yapmaz.

## Method Zaten Var Miydi?

Evet. `list_all()` methodu repository icinde zaten bulunuyordu.

Bu nedenle bu adimda ayni method tekrar yazilmadi. Bunun yerine mevcut davranisin beklenen sekilde calistigini gosteren ek testler yazildi.

## Repository Icinde Tam Liste

Repository icinde kayitlar bellek icinde bir liste olarak tutulur. `list_all()` bu listenin kopyasini dondurur.

Basit mantik sudur:

```python
return list(self._records)
```

Bu yaklasim, disaridan dondurulen listenin repository icindeki ana liste nesnesiyle ayni liste olmamasini saglar.

## Bos Liste Neden Dogru?

Repository icinde hic kayit olmayabilir. Bu durumda tum kayitlar listesi de bos olmalidir.

Beklenen sonuc sudur:

```python
[]
```

Bu davranis hata firlatmaz; cunku kayit olmamasi normal bir durumdur.

## Aktif ve Arsivlenmis Kayitlar Birlikte Neden Doner?

`list_all()` filtreleme metodu degildir. Bu method repository'nin tam hafizasini gosterir.

Aktif kayitlar icin `list_active()`, arsivlenmis kayitlar icin `list_archived()` kullanilir. Ancak tam kayit listesi gerektiginde `list_all()` hem aktif hem arsivlenmis kayitlari birlikte dondurur.

## Archive ve Restore Sonrasi Neden Degismez?

`archive()` ve `restore()` kaydin repository icinde varligini degistirmez. Sadece `is_archived` alanini gunceller.

Bu nedenle kayit arsivlense veya restore edilse bile `list_all()` sonucunda kalmaya devam eder. Toplam kayit sayisi da degismez.

## Neden API veya Veritabani Degil?

Bu adim sadece bellek ici Python davranisidir. JSON, SQLite, API, GUI veya CLI eklenmedi.

Amac, repository'nin en temel listeleme davranisini testlerle guvence altina almaktir.

## Santiye Pratigindeki Anlami

Santiye kalite yonetiminde aktif kayitlar gunluk takip icin, arsivlenmis kayitlar ise denetim ve kalite hafizasi icin gereklidir.

`list_all()` bu iki grubu birlikte gostererek sistemin eksiksiz NCR hafizasini temsil eder.

## Testlerin Kapsami

Bu adimda testler su durumlari guvence altina aldi:

- Bos repository icin tum kayit listesi bos doner.
- Sadece aktif kayitlar varsa hepsi listelenir.
- Aktif ve arsivlenmis kayitlar birlikte varsa hepsi listelenir.
- Restore sonrasi tam liste ve toplam kayit sayisi degismez.

Bu testler mevcut `archive`, `restore`, `list_active`, `list_archived` ve `get_archive_summary` davranislarinin bozulmadigini da destekler.
