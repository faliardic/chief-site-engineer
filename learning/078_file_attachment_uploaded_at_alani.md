# Adim 078 - FileAttachmentRecord uploaded_at Alani

## Amac

Bu adimda `FileAttachmentRecord.uploaded_at` alani opsiyonel metadata olarak netlestirildi.

Bu alan, dosya ekinin sisteme ne zaman eklendigini metin olarak saklamak icin kullanilir.

Ornek degerler:

- `2026-06-07`
- `2026-06-07 14:32`
- `2026-06-07T14:32:10`

## Neden Basit Metadata?

Bu asamada otomatik tarih uretimi veya tarih formatlama davranisi eklenmedi.

`uploaded_at` sadece dosya ekinin kayda alindigi zamani hatirlatan sade bir metadata alanidir.

Bu yaklasim, ileride datetime parsing, timezone yonetimi veya persistence davranisi eklenmeden once modeli kucuk ve okunabilir tutar.

## Otomatik Tarih Neden Eklenmedi?

Otomatik tarih uretimi daha buyuk bir davranistir.

Boyle bir davranis ileride sunlari gerektirebilir:

- Saat dilimi karari
- Tarih formatlama standardi
- Testlerde zaman sabitleme
- Persistence katmani ile uyum
- Kullanici veya sistem olayi bilgisi

Bu adim sadece model metadata alanini netlestirdigi icin otomatik tarih uretimi eklenmedi.

## uploaded_by ile Birlikte Anlami

`uploaded_by` dosyayi kimin ekledigini, `uploaded_at` ise ne zaman ekledigini anlatir.

Birlikte dusunuldugunde bu iki alan dosya eki icin basit bir denetim izi baslangici saglar.

Ornek soru:

```text
Bu dosyayi kim, ne zaman ekledi?
```

Bu adimda tam audit trail sistemi kurulmaz; sadece bu sorunun metadata temeli hazirlanir.

## Varsayilan None Degeri

`uploaded_at` verilmezse deger:

```text
None
```

olur.

Bu, yukleme zamani bilgisinin o kayitta tutulmadigini veya henuz bilinmedigini gosterir.

## Python Acisindan Anlami

Alan tipi:

```text
str | None
```

Varsayilan deger:

```text
None
```

Bu alan zorunlu degildir. Dosya eki kaydi, yukleme zamani bilgisi olmadan da olusturulabilir.

## Kapsam Disi

Bu adimda sunlar eklenmedi:

- Otomatik tarih / saat uretimi
- Datetime parsing
- Tarih formatlama fonksiyonu
- Kullanici modeli
- Rol veya yetki sistemi
- Authentication
- Authorization
- Dosya yukleme sistemi
- Fiziksel dosya kopyalama
- Dosya silme veya tasima
- Repository
- Persistence davranisi
- SQLite
- JSON
- API
- GUI
- CLI
- Thumbnail
- Preview
- Video oynatma
- Streaming

Bu adim sadece model metadata alani ve test adimidir.
