# Adim 091 - Attachment Integrity Result Modeli

## Result Modeli Nedir?

Result modeli, bir kontrol veya islem sonucunu tek kayit halinde temsil eden veri modelidir.

`AttachmentIntegrityResult`, ileride scanner calistiginda her attachment icin uretecegi tekil sonucu tasimak icin hazirlandi.

## Neden Scanner Yazmadan Once Result Modeli Olusturuyoruz?

Scanner yazilmadan once scanner'in ne uretmesi gerektigini bilmek gerekir.

Bu model, ileride scanner implementasyonu gelmeden once sonuc formatini netlestirir. Boylece scanner, raporlama, audit event ve testler ayni sonuc yapisini paylasabilir.

## status_code ile severity Farki

`status_code`, bulunan durumun teknik kodudur. Ornegin `MISSING_FILE`, metadata kaydi oldugu halde dosyanin bulunamadigini anlatir.

`severity`, bu durumun onem seviyesidir. Ornegin `MISSING_FILE` icin `ERROR`, `ORPHAN_FILE` icin `WARNING`, `OK` icin `OK` kullanilabilir.

Status daha ayrintili durum bilgisidir; severity ise bu durumun ne kadar kritik oldugunu anlatan siniflandirmadir.

## metadata_exists ve file_exists Ne Ise Yarar?

`metadata_exists`, attachment metadata kaydinin var olup olmadigini belirtir.

`file_exists`, fiziksel dosyanin var olup olmadigini belirtir.

`MISSING_FILE` durumunda metadata vardir ama dosya yoktur:

```text
metadata_exists=True
file_exists=False
```

`ORPHAN_FILE` durumunda dosya vardir ama metadata yoktur:

```text
metadata_exists=False
file_exists=True
```

`OK` durumunda ikisi de vardir:

```text
metadata_exists=True
file_exists=True
```

## checked_at Neden Onemlidir?

`checked_at`, butunluk kontrolunun ne zaman yapildigini gosterir.

Attachment arsivi zamanla degisebilir. Bir dosya bugun varken yarin silinmis olabilir. Bu nedenle scanner sonucunun tarihi, raporlama ve audit acisindan onemlidir.

Bu adimda `checked_at` verilmezse UTC zaman atanir. Boylece sonuc kaydi bos tarihli kalmaz.

## Bu Adim Neden Dosya Sistemi Taramasi Degildir?

Bu adim dosya var mi diye kontrol etmez.

Klasor taramaz.

Metadata deposu okumaz.

Upload service, backup logic veya audit event implementasyonu eklemez.

Bu adim yalnizca scanner'in ileride uretmesi beklenen tekil sonuc modelini hazirlar.
