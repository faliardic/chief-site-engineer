# Adim 057 - Uygunsuzluk Arsivlenmis Kayitlari Listeleme Ogrenim Notu

## Repository Icinde Arsivlenmis Kayitlari Listeleme

Repository icinde aktif ve arsivlenmis kayitlari ayirmak, kalite kayitlarini silmeden yonetmenin temelidir.

Bu adimda `list_archived()` davranisi ek testlerle daha acik hale getirildi.

## list_archived Ne Ise Yarar?

`list_archived()`, repository icindeki sadece `is_archived == True` kayitlari dondurur.

Aktif kayitlar, yani `is_archived == False` olan kayitlar bu listenin icinde yer almaz.

## Neden Bos Liste Doner?

Repository bos olabilir veya icindeki tum kayitlar aktif olabilir.

Bu durumda hata uretmek yerine bos liste dondurmek dogrudur:

```python
[]
```

Bu davranis, repository icindeki diger filtreleme metotlariyla tutarlidir.

## Archive ve Restore ile Iliski

`archive(nonconformity_id)`, kaydin `is_archived` alanini `True` yapar. Bu kayit artik `list_archived()` sonucunda gorunmelidir.

`restore(nonconformity_id)`, kaydin `is_archived` alanini `False` yapar. Bu kayit artik `list_archived()` sonucunda gorunmemelidir.

## Status Alani Neden Degismez?

Arsiv listesi, kaydin gorunurluk / arsiv durumunu anlatir.

`status` ise kaydin is surecindeki durumunu anlatir. Bu nedenle arsiv listesi olusturulurken `status` alanina dokunulmaz.

## Neden JSON veya SQLite Degil?

Bu adimda kalici saklama katmani yoktur.

Kayitlar Python listesi icinde, bellek uzerinde tutulur. Bu nedenle arsivlenmis kayitlari listeleme davranisi simdilik bellek ici Python filtrelemesi olarak kalir.

## Santiye Pratiginde Anlami

Santiye kalite kayitlari denetim ve izlenebilirlik icin saklanir.

Aktif takipten cikan NCR kayitlarini silmeden arsiv listesinde ayri gorebilmek, kalite arsivini daha duzenli ve izlenebilir hale getirir.

## Testte Ne Kontrol Edildi?

Ilk test, bos repository icin `list_archived()` sonucunun bos liste oldugunu dogrular.

Ikinci test, sadece aktif kayitlar varken arsiv listesinin bos kaldigini dogrular.

Ucuncu test, `archive` sonrasi kayitlarin arsiv listesine girdigini ve `restore` sonrasi restore edilen kaydin arsiv listesinden ciktigini dogrular.

## Kapsam Disi Birakilanlar

- JSON
- SQLite
- API
- GUI
- CLI
- Buyuk refactor
- Kayit silme
- Otomatik history
- Otomatik workflow
- Otomatik status degisimi

## Kisa Ozet

Adim 057 ile `NonconformityRepository.list_archived()` davranisi, arsivlenmis NCR kayitlarini listeleme beklentileri icin ek test ve dokumantasyonla netlestirildi.

Bu adim, aktif ve arsiv kayit ayrimini silme yapmadan daha guvenilir hale getirir.
