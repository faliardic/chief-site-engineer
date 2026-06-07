# Adim 053 - Repository Aktif / Arsiv Filtreleme Ogrenim Notu

## Repository Icinde Aktif / Arsiv Filtreleme

Repository icinde kayitlari sadece durum veya sorumlu tarafa gore degil, arsiv durumuna gore de ayirmak gerekebilir.

Bu adimda `NonconformityRepository` icine `list_active` ve `list_archived` metotlari eklendi.

## list_active Ne Ise Yarar?

`list_active()`, `is_archived` degeri `False` olan kayitlari dondurur.

Bu kayitlar normal takipte kalan aktif NCR kayitlari olarak dusunulur.

## list_archived Ne Ise Yarar?

`list_archived()`, `is_archived` degeri `True` olan kayitlari dondurur.

Bu kayitlar silinmeyen, ancak aktif takip listesinden ayrilmis arsiv kayitlari olarak dusunulur.

## is_archived Alani Nasil Kullanilir?

`is_archived` boolean bir model alanidir:

```text
False -> aktif kayit
True  -> arsiv kaydi
```

Repository bu alani okuyarak kayitlari iki gruba ayirir.

## Silme Yerine Arsivleme

Kalite kayitlari genellikle silinmemelidir. Silme yerine arsivlemek, kaydin gecmisini ve izlenebilirligini korur.

Bu adimda silme yapilmadi; sadece aktif ve arsiv kayitlarini ayirmaya yarayan filtreleme eklendi.

## Eslesmeyen Kayit Icin Neden Bos Liste?

Filtreleme sonucunda eslesen kayit yoksa bos liste dondurmek dogrudur.

Bu, hata uretmeden "bu grupta kayit yok" bilgisini verir ve diger repository filtreleme davranislariyla tutarlidir.

## Neden JSON veya SQLite Sorgusu Degil?

Bu adimda kalici saklama katmani yoktur.

Kayitlar Python listesi icinde, bellek uzerinde tutulur. Bu nedenle aktif / arsiv filtreleme simdilik bellek ici Python filtrelemesi olarak kalir.

## Santiye Pratiginde Anlami

Santiye kalite kayitlari denetim ve izlenebilirlik icin korunur.

Aktif NCR kayitlari gunluk takipte kalirken, kapanmis veya pasif hale gelmis kayitlar arsivde saklanabilir. Boylece kayitlar silinmeden duzenli bir sekilde ayrilir.

## Testte Ne Kontrol Edildi?

Ilk test, `list_active()` metodunun sadece `is_archived == False` kayitlari ve eklenme sirasini koruyarak dondurdugunu dogrular.

Ikinci test, `list_archived()` metodunun sadece `is_archived == True` kayitlari dondurdugunu ve eslesme yoksa bos liste verdigini dogrular.

## Kapsam Disi Birakilanlar

- NonconformityRecord model degisikligi
- JSON
- SQLite
- API
- GUI
- CLI
- Dashboard
- Dosya islemi
- Silme
- Otomatik arsivleme
- Restore
- Otomatik is akisi

## Kisa Ozet

Adim 053 ile `NonconformityRepository` icinde aktif ve arsiv kayitlarini ayiran bellek ici filtreleme davranislari eklendi.

Bu adim, kalite kayitlarini silmeden takip ve arsiv gorunumlerine ayirmak icin sade bir temel saglar.
