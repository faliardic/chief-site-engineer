# Adim 089 - Attachment Metadata Integrity Kurallari

## 1. Amac

Bu dokuman, attachment metadata kayitlari ile fiziksel dosya arsivi arasindaki temel butunluk kurallarini tanimlar.

Bu adimda kod yazilmaz. Missing/orphan scanner, dosya sistemi taramasi veya upload service implementasyonu yapilmaz. Amac, ileride gelistirilecek scanner davranisinin hangi durumlari yakalayacagini ve nasil raporlayacagini onceden netlestirmektir.

## 2. Temel Kavramlar

`Attachment metadata`, dosyanin kendisini degil; dosya kimligi, bagli oldugu ana kayit, dosya yolu, dosya tipi, yukleyen kisi, yukleme zamani ve not gibi aciklayici bilgileri tutar.

`Physical attachment file`, dosyanin gercek fiziksel kopyasidir. Bu dosya yerel klasorde, sunucuda veya ileride bulut depolama ortaminda tutulabilir.

`Canonical attachment path`, Adim 085 ve Adim 088 ile netlesen standart dosya yolu semasidir:

```text
attachments/{project_id}/{record_type}/{yyyy}/{mm}/{dd}/{record_id}/{safe_file_name}
```

`Integrity check`, metadata ile fiziksel dosya arsivinin birbirini dogru sekilde isaret edip etmedigini kontrol etme isidir.

`Scanner report`, ileride scanner calistiginda her attachment icin uretecegi okunabilir kontrol sonucudur.

## 3. Butunluk Durumlari

`OK`: Metadata vardir ve beklenen fiziksel dosya vardir.

`MISSING_FILE`: Metadata vardir fakat beklenen fiziksel dosya yoktur.

`ORPHAN_FILE`: Fiziksel dosya vardir fakat ona karsilik gelen metadata kaydi yoktur.

`INVALID_PATH`: Metadata icindeki path bilgisi canonical path kuralina uymaz.

`DUPLICATE_METADATA`: Ayni fiziksel dosyaya birden fazla metadata kaydi isaret eder.

`UNREADABLE_FILE`: Dosya vardir fakat okunamaz veya erisilemez.

## 4. Hata / Uyari Siniflandirmasi

| Durum | Siniflandirma | Anlam |
| --- | --- | --- |
| `OK` | Sorun yok | Metadata ve dosya uyumlu gorunur. |
| `MISSING_FILE` | Kritik hata | Kanit dosyasi kayip olabilir. |
| `ORPHAN_FILE` | Uyari / inceleme | Dosya vardir ama sistem kaydi yoktur. |
| `INVALID_PATH` | Hata | Path standardi bozulmustur. |
| `DUPLICATE_METADATA` | Hata / yuksek oncelikli uyari | Ayni dosyaya birden fazla kayit isaret eder. |
| `UNREADABLE_FILE` | Hata | Dosya erisimi veya dosya sagligi sorunu vardir. |

## 5. Scanner Rapor Formati

Ileride scanner raporunda en az su bilgiler yer almalidir:

- `status_code`
- `attachment_id` veya metadata reference
- `expected_path`
- `actual_path` varsa
- `file_exists`
- `metadata_exists`
- `severity`
- `recommended_action`
- `checked_at`

Bu rapor hem insan tarafindan okunabilir olmali hem de ileride dashboard, audit event veya backup dogrulama hattina veri saglayabilecek kadar duzenli olmalidir.

## 6. Onerilen Aksiyonlar

`MISSING_FILE` icin yedekten geri yukleme, audit kayitlarini kontrol etme ve ilgili kullaniciya veya kalite sorumlusuna raporlama onerilir.

`ORPHAN_FILE` icin metadata olusturma, dosyayi karantinaya alma veya manuel inceleme secenekleri degerlendirilmelidir.

`INVALID_PATH` icin canonical path helper ile path yeniden uretilmeli veya metadata duzeltilmelidir.

`DUPLICATE_METADATA` icin kayitlar birlestirilmeli, yanlis kayit pasiflestirilmeli veya manuel kalite kontrol yapilmalidir.

`UNREADABLE_FILE` icin dosya izinleri, disk sagligi, dosya bozulmasi ve depolama erisimi kontrol edilmelidir.

## 7. Backup Hatti ile Iliskisi

Scanner ciktisi ileride backup dogrulama surecinin temel girdisi olabilir. Backup alindiktan sonra metadata ve fiziksel dosya sayilari karsilastirilabilir.

Backup restore sonrasinda ayni scanner tekrar calistirilabilir. Boylece geri yuklenen dosyalarin metadata ile uyumlu olup olmadigi kontrol edilir.

## 8. Upload Service ile Iliskisi

Upload sirasinda metadata kaydi ve fiziksel dosya birlikte olusmalidir. Bu iki parcadan biri basarili, digeri basarisiz olursa sistemde yarim kayit riski dogar.

Ornek riskler:

- Upload basarili olur ama metadata kaydi olusmazsa `ORPHAN_FILE` ortaya cikabilir.
- Metadata basarili olur ama dosya yazilamazsa `MISSING_FILE` ortaya cikabilir.
- Dosya yanlis path ile yazilirsa `INVALID_PATH` veya `ORPHAN_FILE` gorulebilir.

Bu nedenle ileride upload service, dosya yazma ve metadata olusturma islemlerini birlikte ele alan guvenli bir akisa sahip olmalidir.

## 9. Audit Event Hatti ile Iliskisi

Attachment create, update, delete, restore ve quarantine gibi olaylar ileride audit event olarak kaydedilmelidir.

Scanner tarafindan bulunan kritik durumlar da audit event uretebilir. Ornegin `MISSING_FILE`, `DUPLICATE_METADATA` veya `UNREADABLE_FILE` bulgulari kalite arsivi acisindan izlenebilir kalmalidir.

## 10. Bu Adimin Sinirlari

Bu adimda kod yazilmaz.

Scanner implement edilmez.

Dosya sistemi taramasi yapilmaz.

Upload service, database, API, GUI, auth, CI veya deployment eklenmez.

Bu adim yalnizca attachment metadata butunluk kurallarini ve ilerideki scanner tasarimina temel olacak karar cercevesini dokumante eder.
