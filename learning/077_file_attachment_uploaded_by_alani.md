# Adim 077 - FileAttachmentRecord uploaded_by Alani

## Amac

Bu adimda `FileAttachmentRecord.uploaded_by` alani opsiyonel metadata olarak netlestirildi.

Bu alan, dosya ekinin kim tarafindan sisteme eklendigini metin olarak saklamak icin kullanilir.

Ornek degerler:

- `Fatih`
- `santiye_sefi`
- `teknik_ofis`
- `yapi_denetim`
- `tasaron_ekibi`
- `ofis_personeli`

## Neden String Metadata?

Bu asamada CHIEF SITE ENGINEER icinde kullanici modeli, rol modeli veya yetkilendirme sistemi kurulmadı.

Bu nedenle `uploaded_by` alani sadece sade bir string metadata alanidir. Alan, ileride daha gelismis bir kullanici sistemi kurulmadan once dosya ekinin kimin tarafindan kayda alindigini hatirlatir.

## Denetim Izi Acisindan Onemi

Dosya ekleri saha kaniti olabilir.

Bir fotograf, video, PDF veya belge icin su soru onemlidir:

```text
Bu dosyayi kim ekledi?
```

`uploaded_by` bu sorunun ilk basit cevabini verir. Daha sonra audit trail veya kullanici sistemi eklenirse bu bilgi daha guclu bir kayit yapisina baglanabilir.

## Varsayilan None Degeri

`uploaded_by` verilmezse deger:

```text
None
```

olur.

Bu, yukleyen kisi bilgisinin o kayitta tutulmadigini veya henuz bilinmedigini gosterir.

## Python Acisindan Anlami

Alan tipi:

```text
str | None
```

Varsayilan deger:

```text
None
```

Bu alan zorunlu degildir. Dosya eki kaydi, yukleyen kisi bilgisi olmadan da olusturulabilir.

## Kapsam Disi

Bu adimda sunlar eklenmedi:

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
