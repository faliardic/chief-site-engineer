# Adim 076 - FileAttachmentRecord original_file_name Alani

## Amac

Bu adimda `FileAttachmentRecord` modeline `original_file_name` alani eklendi.

Bu alan, sistem icinde standartlastirilmis `file_name` degerinden ayri olarak, kullanicinin yukledigi dosyanin orijinal adini metadata olarak saklamak icin kullanilir.

## Neden Ayrı Alan?

Sistem dosya adi guvenli, okunabilir ve standart olmalidir.

Ornek sistem dosya adi:

```text
20260607_143210__concrete_pour__CP-000123__image__001.jpg
```

Kullanicinin yukledigi orijinal dosya adi daha serbest olabilir:

```text
WhatsApp Image 2026-06-07 at 14.32.10.jpeg
```

Bu iki bilgi ayni sey degildir. `file_name` sistemin kullandigi standart addir. `original_file_name` ise kullanicidan gelen ilk dosya adini hatirlamak icin metadata olarak tutulur.

## Varsayilan Deger

`original_file_name` opsiyoneldir.

Verilmezse:

```text
None
```

olur.

Bu sayede eski kullanimlar bozulmadan devam eder.

## Python Acisindan Anlami

Bu adim dataclass modeline opsiyonel bir alan ekleme ornegidir.

Alan tipi:

```text
str | None
```

Varsayilan deger:

```text
None
```

Bu, alanin metin olarak tutulabilecegini veya hic verilmemis olabilecegini anlatir.

## Kapsam Disi

Bu adimda sunlar eklenmedi:

- Dosya yukleme sistemi
- Fiziksel dosya kopyalama
- Dosya silme veya tasima
- Dosya adi standartlastirma fonksiyonu
- Repository
- SQLite
- JSON persistence
- API
- GUI
- CLI
- Thumbnail
- Preview
- Video oynatma
- Streaming

Bu adim sadece model metadata alani ve test adimidir.
