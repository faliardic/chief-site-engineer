# Adim 058 - Uygunsuzluk Aktif Kayitlari Listeleme

## Bu Adimda Ne Ogrenildi?

Bu adimda `NonconformityRepository.list_active()` davranisinin ne ise yaradigi test ve dokumantasyonla netlestirildi.

`list_active()` repository icindeki sadece aktif NCR kayitlarini dondurur. Aktif kayit, `is_archived` degeri `False` olan kayittir.

## Method Zaten Var Miydi?

Evet. `list_active()` methodu onceki adimlarda repository icine eklenmisti.

Bu nedenle bu adimda ayni method tekrar yazilmadi. Bunun yerine mevcut davranisin beklenen sekilde calistigini gosteren ek testler yazildi.

## Repository Icinde Filtreleme

Repository icinde kayitlar bellek icinde bir liste olarak tutulur. Aktif kayitlari listelemek icin bu liste uzerinden `is_archived == False` kosulu kontrol edilir.

Basit mantik sudur:

```python
return [record for record in self._records if not record.is_archived]
```

Bu ifade yeni bir liste olusturur ve sadece aktif kayitlari dondurur.

## Bos Liste Neden Dogru?

Repository bos olabilir. Ya da repository icinde kayit vardir ama hepsi arsivlenmistir.

Bu iki durumda da aktif kayit yoktur. Bu nedenle `list_active()` icin en anlasilir sonuc bos listedir:

```python
[]
```

Bu davranis hata firlatmaz; cunku aktif kayit olmamasi normal bir durumdur.

## Archive ve Restore Iliskisi

`archive()` bir kaydi arsivli hale getirir. Bu kayit artik `list_active()` sonucunda gorunmez.

`restore()` arsivlenmis kaydi tekrar aktif hale getirir. Bu kayit yeniden `list_active()` sonucunda gorunur.

Bu ayrim, silme yapmadan aktif takip ile arsiv arasinda kontrollu gecis saglar.

## Status Neden Degismiyor?

Aktiflik burada `status` alaniyla degil, `is_archived` alaniyla belirlenir.

Bir kaydin `status` degeri `closed` olabilir ama kayit arsivlenmemisse aktif listede yer alabilir. Bu nedenle `list_active()` status alanini degistirmez ve status alanina gore karar vermez.

## Neden API veya Veritabani Degil?

Bu adim sadece bellek ici Python davranisidir. JSON, SQLite, API, GUI veya CLI eklenmedi.

Amac, once kucuk ve test edilebilir repository davranisini guvenli hale getirmektir. Daha sonra bu davranis dashboard, rapor veya AI soru-cevap sistemi tarafindan kullanilabilir.

## Santiye Pratigindeki Anlami

Santiye yonetiminde aktif NCR kayitlari gunluk takip listesidir. Bu kayitlar hala dikkate alinmasi gereken kalite problemlerini gosterir.

Arsivlenmis kayitlar kalite hafizasinda tutulur, ancak gunluk takipte aktif is gibi gorunmemelidir. `list_active()` bu ayrimi yazilim tarafinda sade bir modelle temsil eder.

## Testlerin Kapsami

Bu adimda testler su durumlari guvence altina aldi:

- Bos repository icin aktif liste bos doner.
- Sadece aktif kayitlar varsa hepsi aktif listede gorunur.
- Aktif ve arsivlenmis kayitlar birlikte varsa sadece aktif olanlar doner.
- Restore edilen kayit tekrar aktif listede gorunur.

Bu testler mevcut `archive`, `restore`, `list_archived` ve `get_archive_summary` davranislarinin bozulmadigini da dolayli olarak destekler.
