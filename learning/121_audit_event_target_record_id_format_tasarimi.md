# Adim 121 - Audit Event Target Record ID Format Tasarimi

## Bu adimda ne yaptik?

Bu adimda `AuditEventRecord.target_record_id` alani icin ilk format tasarimini dokumante ettik.

Kod yazmadik. Test eklemedik. Validation davranisini degistirmedik.

Yaptigimiz is, ileride `target_record_id` icin regex, prefix veya pattern validation dusunulmeden once guvenli bir tasarim zemini olusturmaktir.

## Neden yaptik?

Adim 120'de `target_record_type` artik desteklenen degerlerle sinirlandi.

Ancak `target_record_id` hala yalnizca bos olmama seviyesinde kontrol ediliyor. Bu alanin ileride nasil gorunmesi gerektigini once dokumante etmek gerekir.

Santiye karsiligi sudur: Bir klasorde "hangi belge turu?" etiketi kadar "hangi belge numarasi?" bilgisi de onemlidir. Belge numarasi aciklama cumlesi gibi yazilirsa arama, takip ve raporlama zorlasir.

## Dokunulan dosyalar

```text
docs/121_audit_event_target_record_id_format_tasarimi.md
learning/121_audit_event_target_record_id_format_tasarimi.md
CHANGELOG.md
ROADMAP.md
docs/project_decisions.md
docs/120_audit_event_target_record_type_validation.md
learning/GLOSSARY.md
```

Bu adimda `app/models.py` ve `tests/test_models.py` dosyalarina dokunulmadı.

## Target record id nedir?

`target_record_id`, audit event olayinin iliskili oldugu kaydin kimligini anlatir.

Ornek:

```text
event_type = attachment.linked
target_record_type = attachment
target_record_id = ATT-2026-0001
```

Bu ornekte:

- `event_type`, dosya ekinin baglandigini soyler.
- `target_record_type`, ilgili kaydin attachment oldugunu soyler.
- `target_record_id`, hangi attachment kaydi oldugunu soyler.

Sunu soyle yaptik ki:
Olay turu, kayit turu ve kayit kimligi birbirine karismasin.

Boyle yaptik:
Her alanin cevap verdigi soruyu ayri tuttuk.

Cunku:
Audit event kayitlari ileride filtrelenebilir ve raporlanabilir olmali.

Boylece:
Bir olay hem insan hem de yazilim tarafindan daha net okunur.

## Neden serbest metin gibi birakilmamali?

`target_record_id` serbest metin gibi yazilirsa kimlik alani aciklama alanina donusur.

Yanlis kullanim:

```text
target_record_id = kalip kontrol notu guncellendi
```

Bu deger bir kayit kimligi degildir. Bu bilgi `reason` alanina yazilmalidir.

Dogru kullanim:

```text
event_type = record.updated
target_record_type = project_record
target_record_id = REC-2026-0007
reason = Kalip kontrol notu guncellendi.
```

Bu ayrim ileride `target_record_id` validation eklenirse hatalarin daha anlasilir olmasini saglar.

## Ilk format yaklasimi

Bu adimda zorunlu regex eklemedik.

Ilk tasarim onerisi:

```text
<TYPE_PREFIX>-<YEAR>-<SEQUENCE>
```

Ornekler:

```text
PRJ-2026-0001
REC-2026-0007
ATT-2026-0001
AMD-2026-0003
AIR-2026-0001
JEX-2026-0002
BCK-2026-0001
RST-2026-0001
HND-2026-0001
AUD-2026-0001
```

Bu formatta:

- `TYPE_PREFIX`, kayit turunu temsil eden kisa koddur.
- `YEAR`, kaydin yil bilgisidir.
- `SEQUENCE`, o tur/yil icindeki sira numarasidir.

## Target type / prefix aday tablosu

| target_record_type | Onerilen prefix | Ornek target_record_id |
| --- | ---: | --- |
| `project` | `PRJ` | `PRJ-2026-0001` |
| `project_record` | `REC` | `REC-2026-0007` |
| `attachment` | `ATT` | `ATT-2026-0001` |
| `attachment_metadata` | `AMD` | `AMD-2026-0003` |
| `attachment_integrity_report` | `AIR` | `AIR-2026-0001` |
| `json_export` | `JEX` | `JEX-2026-0002` |
| `backup_package` | `BCK` | `BCK-2026-0001` |
| `restore_operation` | `RST` | `RST-2026-0001` |
| `handover_package` | `HND` | `HND-2026-0001` |
| `audit_event` | `AUD` | `AUD-2026-0001` |

Bu tablo bugun validation listesi degildir. Ileride validation veya id generator tasarlanirken referans alinabilecek aday tablodur.

## Dogru / yanlis kullanim ornekleri

Dogru:

```text
event_type = integrity.report_generated
target_record_type = attachment_integrity_report
target_record_id = AIR-2026-0001
```

Yanlis:

```text
target_record_id = integrity raporu olusturuldu
```

Yanlis deger bir kimlik degil, aciklama cumlesidir.

## Alanlarin ayrimi

| Alan | Ne soyler? | Ne tasimamali? |
| --- | --- | --- |
| `event_type` | Olayin ne oldugunu soyler. | Kayit id veya gerekce tasimamali. |
| `target_record_type` | Hangi tur kayitla ilgili oldugunu soyler. | Kimlik veya aciklama cumlesi tasimamali. |
| `target_record_id` | Hangi kayit kimligiyle ilgili oldugunu soyler. | Gerekce, not, snapshot veya degisen deger tasimamali. |
| `reason` | Olayin neden yapildigini aciklar. | Kayit kimligi yerine kullanilmamali. |
| `notes` | Insan tarafindan okunacak ek notu tutar. | Makine-okunabilir id yerine kullanilmamali. |
| `old_value` | Eski degerin kisa ve guvenli ozetidir. | Kayit kimligi yerine kullanilmamali. |
| `new_value` | Yeni degerin kisa ve guvenli ozetidir. | Kayit kimligi yerine kullanilmamali. |

## Ileride kodlanabilecek validation akisi

Bugun kodlanmayan ama ileride dusunulebilecek akis:

```text
1. Required audit event fields kontrol edilir.
2. event_type allowed-list kontrol edilir.
3. target_record_type / target_record_id pair validation calisir.
4. target_record_type allowed-list kontrol edilir.
5. target_record_id bos veya whitespace mi kontrol edilir.
6. target_record_id genel format pattern'ine uyuyor mu kontrol edilir.
7. target_record_id prefix'i target_record_type ile uyumlu mu kontrol edilir.
```

Onerilen gelecek hata mesajlari:

```text
target_record_id is required
target_record_id format is not supported
target_record_id prefix does not match target_record_type
```

Bu akis bu adimda uygulanmadi; yalnizca tasarim olarak kaydedildi.

## Teknik karar tablosu

| Sunu yaptik | Boyle yaptik | Cunku | Boylece |
| --- | --- | --- | --- |
| ID format tasarimini yazdik | `<TYPE_PREFIX>-<YEAR>-<SEQUENCE>` bicimini dokumante ettik | Kimlikler ileride okunabilir ve validation'a uygun olmali | Kod eklemeden once sozlesme zemini olustu |
| Prefix adaylarini belirledik | Target type / prefix tablosu ekledik | Her kayit turu icin okunabilir bir baslangic kodu lazim | Prefix validation ileride daha kolay tasarlanabilir |
| Validation'i erteledik | Regex veya prefix kontrolu eklemedik | Gercek model id alanlariyla uyum kontrolu yapilmali | Mevcut davranislar kirilmadi |
| Alan ayrimini netlestirdik | `reason`, `notes`, `old_value`, `new_value` ayrimini anlattik | Kimlik alani aciklama alanina donusmemeli | Audit event kayitlari temiz kalir |

## "Sunu soyle yaptik ki..." bolumu

Sunu yaptik:
`target_record_id` icin ilk format onerisi yazdik.

Boyle yaptik:
`<TYPE_PREFIX>-<YEAR>-<SEQUENCE>` bicimini ve prefix aday tablosunu dokumante ettik.

Cunku:
Kimlikler ileride makine tarafindan kontrol edilebilir ve insan tarafindan okunabilir olmali.

Boylece:
Validation eklemeden once hangi formata dogru gidilecegi gorunur hale geldi.

Sunu yaptik:
Prefix validation'i bu adimda eklemedik.

Boyle yaptik:
Bu adimi documentation-only tuttuk.

Cunku:
Gercek modellerin mevcut id alanlariyla uyum kontrolu yapmadan prefix zorlamak erken olur.

Boylece:
Adim 121 guvenli bir tasarim adimi olarak kaldi.

## Bilincli olarak yapilmayanlar

Bu adimda uygulama kodu degistirilmedi.

Bu adimda test dosyasi degistirilmedi.

Bu adimda regex validation, prefix validation, ID generator, ID normalizer veya existing id migration eklenmedi.

Bu adimda target type constants, event type constants, database, repository, migration, JSON export/import, audit event persistence, otomatik audit event uretimi, API, GUI veya CLI davranisi degistirilmedi.

## Mini sozluk

`Target Record ID`: Audit event olayinin iliskili oldugu kaydin kimligini anlatan alan.

`ID Prefix`: Kimligin basinda yer alan ve kayit turunu temsil eden kisa kod.

`ID Format`: Kimligin hangi parcalardan olusacagini anlatan bicim kurali.

`Prefix Validation`: Kimlik prefix'inin target record type ile uyumlu olup olmadigini kontrol etme davranisi.

`ID Generator`: Yeni kimlikleri belirli bir formata gore otomatik ureten mekanizma.

## Adim 122'ye baglanti

Onerilen sonraki adim:

```text
Adim 122 - Audit event target record id validation tasarimi veya serialization tasarimi
```

Adim 122'de bu format tasarimi validation tasarimina donusturulebilir veya audit event kayitlarinin serialize edilmesi ele alinabilir.
