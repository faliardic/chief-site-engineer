# Adim 130 - Central Record ID Contract Plan

## Bu adimda ne yaptik?

Bu adimda kod yazmadik. Record ID'lerin nasil adlandirilmasi gerektigini planladik.

Adim 129 bize su resmi gostermisti: Projede ID ornekleri tek bicimde degil. Bu yuzden `AuditEventRecord.target_record_id` alanina hemen kati validation eklemek riskli.

Adim 130'da bu riski azaltmak icin merkezi record ID sozlesmesi planini hazirladik.

## ID sozlesmesi neden veri omurgasinin parcasidir?

Bir kaydin ID'si, o kaydin sistem icindeki adresidir.

Santiye karsiligi sudur: Bir tutanaga, fotograf ekine, uygunsuzluk kaydina veya gunluk rapora tekrar ulasmak istiyorsak onun kimligini guvenilir sekilde bilmeliyiz.

Ornek:

```text
NCR-001
ATT-001
PRJ-001
```

Bu degerler sadece metin degildir. Sistemin "hangi kayit?" sorusuna verdigi cevaptir.

ID sozlesmesi olmadiginda ayni tur kayit farkli bicimlerde yazilabilir:

```text
ncr-001
NCR-001
NCR-2026-0001
```

Bu durum kucuk projede tolere edilebilir. Ancak audit, arama, export, backup ve raporlama buyudukce merkezi sozlesme gerekir.

## Prefix standardi neden tek basina yeterli degildir?

Prefix, ID'nin basindaki kisa etikettir.

Ornek:

```text
NCR-001
ATT-001
MAT-DEL-001
```

Burada `NCR`, `ATT` ve `MAT-DEL` prefix gibi davranir.

Ama sadece prefix bilmek yetmez. Su sorular da cevaplanmalidir:

- Prefix hangi model ailesine ait?
- ID icinde yil olacak mi?
- Sira numarasi kac haneli olacak?
- Eski lower-case ID ornekleri kabul edilecek mi?
- Explicit ID alani olmayan modeller nasil ele alinacak?

Bu yuzden merkezi ID sozlesmesi sadece "prefix listesi" degildir. Prefix, alan adi, ornek format, uyumluluk riski ve audit target mapping birlikte dusunulmelidir.

## Audit target_record_type + target_record_id iliskisi neden onemlidir?

Audit event, sistemde olan bir olayi anlatir.

O olay belirli bir kayda bagliysa iki bilgi gerekir:

```python
target_record_type = "project_record"
target_record_id = "NCR-001"
```

`target_record_type`, hedef kaydin turunu veya ailesini anlatir.

`target_record_id`, o aile icindeki belirli kaydi anlatir.

Sadece `target_record_id` olursa `NCR-001` degerinin hangi baglamda yorumlanacagi zayif kalir.

Sadece `target_record_type` olursa hangi kaydin hedeflendigi bilinmez.

Bu nedenle once pair validation eklenmisti. Ama format validation icin daha fazlasi gerekir: `target_record_type` hangi ID ailelerini kabul eder, bunun merkezi mapping'i olmalidir.

## Hard validation neden gec uygulanmalidir?

Hard validation, uygun olmayan degeri dogrudan reddeder.

Bu gucludur, ama erken uygulanirsa zararli olabilir.

Ornek:

```text
Beklenen format: NCR-2026-0001
Mevcut test: NCR-001
```

Eger hemen hard validation eklenirse, proje icindeki mevcut anlamli ornekler kirilir.

Bu yuzden guvenli sira sudur:

1. Once dokumantasyon.
2. Sonra constants ve mapping.
3. Sonra test orneklerinin standardizasyonu.
4. Sonra soft validation veya uyari.
5. En sonda hard validation.

Boylece sistem aceleyle daralmaz; veri sozlesmesi olgunlasarak guclenir.

## CSE'de neden once plan, sonra helper, sonra test standardizasyonu?

Chief Site Engineer projesi sahadaki gercek bilgi akisini yavas ve kontrollu sekilde modele tasiyor.

Bir ID sozlesmesi yanlis kurulursa ileride su alanlari etkiler:

- Audit log
- Attachment metadata
- Attachment integrity raporu
- JSON export
- Backup / restore
- Handover package
- Resmi kayit / ozel alan ayrimi

Bu nedenle CSE'de once plan yapilir.

Sonra helper veya constants ile sozlesme tek yerde temsil edilir.

Ardindan yeni test ornekleri bu sozlesmeye gore yazilir.

Sonra soft validation ile riskler gorunur hale getirilir.

Hard validation ise en sonda gelir.

## Bu adimda ne yapmadik?

- `app/models.py` degistirilmedi.
- Test dosyalari degistirilmedi.
- `AuditEventRecord` validation davranisi degistirilmedi.
- `target_record_id` format validation eklenmedi.
- `FileAttachmentRecord` degistirilmedi.
- Podcast 021 olusturulmadi.
- Commit veya push yapilmadi.

## Sonraki guvenli teknik adim

Bir sonraki guvenli adim, record ID constants and mapping helper plan hazirlamaktir.

Bu plan sunu tarif etmelidir:

```text
target_record_type -> izinli ID aileleri
```

Ornek:

```text
project -> PRJ
attachment -> ATT, file-att
audit_event -> AUD, audit
project_record -> NCR, LOG, NOTE, MAT-DEL, REC
```

Bu henuz validation degildir. Sadece ileride validation'in hangi bilgiye dayanacagini netlestiren sozlesme zeminidir.
