# Adim 042 - Repository Duplicate Id Kontrolu Ogrenim Notu

## Duplicate Id Problemi Nedir?

Duplicate id, ayni kimlik degerinin iki farkli kayit icin kullanilmasidir.

Kesin uygunsuzluk / NCR kayitlarinda bu durum ciddi karisiklik olusturur. Ornegin iki farkli saha problemi ayni `NCR-003` numarasiyla kaydedilirse hangi kaydin takip edilecegi belirsiz hale gelir.

## Repository Icinde Kimlik Benzersizligi Neden Onemli?

Repository, kayitlari ekleyen ve arayan siniftir. Bu nedenle ayni kimlikle ikinci kaydin eklenmesini en erken burada durdurmak mantiklidir.

Bu adimda `NonconformityRepository.add` metodu, yeni kaydi eklemeden once `find_by_id` ile mevcut kimligi kontrol eder.

## ValueError Kullanimi

`ValueError`, Python'da verilen deger kabul edilemez oldugunda kullanilan hata turudur.

Bu adimda ayni `nonconformity_id` ile ikinci kayit eklenmeye calisildiginda `ValueError` yukseltildi.

```python
if self.find_by_id(record.nonconformity_id) is not None:
    raise ValueError(
        f"NonconformityRecord with id '{record.nonconformity_id}' already exists."
    )
```

## Neden Veritabani Unique Constraint Degil?

Bu projede bu adimda JSON, SQLite veya baska bir kalici saklama katmani eklenmedi.

Bu nedenle benzersizlik kontrolu simdilik veritabani seviyesinde degil, bellek icinde Python koduyla yapilir.

Ileride SQLite veya baska bir veritabani eklendiginde unique constraint ayrica ele alinabilir.

## Santiye Pratiginde Anlami

Sahada ayni NCR numarasinin iki farkli sorun icin kullanilmasi kalite takibini bozar.

Bir ekip `NCR-003` icin duzeltme yaptigini soylerken baska bir ekip ayni numaranin farkli bir problemi anlattigini dusunebilir. Bu da kapatma, dogrulama ve arsiv sureclerinde hata dogurur.

## Testte Ne Kontrol Edildi?

Testte ayni `nonconformity_id` ile ikinci kayit eklendiginde `ValueError` yukseldigi dogrulandi.

Ayrica farkli `nonconformity_id` degerine sahip kaydin normal sekilde eklenebildigi kontrol edildi.

## Kapsam Disi Birakilanlar

- JSON
- SQLite
- API
- GUI
- CLI
- Dosya islemi
- Otomatik is akisi

## Kisa Ozet

Adim 042 ile `NonconformityRepository` icinde duplicate id kontrolu eklendi.

Bu adim, kesin uygunsuzluk kayitlarinin bellek icinde bile benzersiz NCR kimlikleriyle takip edilmesi icin kucuk ama onemli bir guvence saglar.
