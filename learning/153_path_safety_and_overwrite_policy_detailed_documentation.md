# Adim 153 - Ogrenme Notu

Bu adimda path safety ve overwrite policy detayli olarak belgelendi.

Bu adim kod yazmadi.

Export / file writing helper implementasyonu yapilmadi.

JSON veya Markdown export dosyasi uretilmedi.

Hard validation eklenmedi.

`blocked` status eklenmedi.

Podcast 026 olusturulmadi.

## Ana ders

Dosya yazmak, sadece metin uretmekten daha risklidir.

Format helper bir raporu Python dict veya Markdown string olarak hazirlar.

File-writing export helper ise ileride bu hazir ciktinin kalici dosyaya yazilmasindan sorumlu olabilir.

Kalici dosya yazimi:

- Yanlis klasore yazabilir.
- Var olan dosyayi ezebilir.
- Proje disina cikabilir.
- Hassas dosyalara dokunabilir.
- Handover veya audit ciktisini backup/restore davranisiyla karistirabilir.

Bu nedenle path safety ve overwrite policy once dokumante edilmelidir.

## Path traversal neden tehlikelidir?

Path traversal, dosya yolunun beklenen klasorden cikmak icin kullanilmasidir.

Basit bir ornek:

```text
exports/report.md
```

Bu normal bir export hedefi gibi dusunulebilir.

Riskli bir ornek:

```text
exports/../../.env
```

Bu tur bir path, eger kontrol edilmezse izinli klasorden cikmaya calisir.

Benzer riskler:

- `..` kullanimi.
- `/` ve `\` separator'larinin karisik kullanimi.
- Encoded traversal denemeleri.
- Dosya adi icine path separator yerlestirilmesi.

Bu yuzden guvenli export helper ileride path'i sadece metin olarak okumamali, cozumlenmis hedefin izinli export kokunun icinde kaldigini dogrulamalidir.

Bu adimda bu dogrulama kodu yazilmadi; sadece prensip belgelendi.

## Overwrite neden varsayilan olarak false olmalidir?

Overwrite, mevcut bir dosyanin uzerine yazmak demektir.

Varsayilan `overwrite=True` olursa kullanici fark etmeden eski bir handover raporunu, audit QC ciktisini veya onemli bir export dosyasini ezebilir.

Guvenli varsayilan:

```text
overwrite=False
```

Bu durumda:

- Mevcut dosya korunur.
- Uzerine yazma ancak explicit istekle yapilir.
- `overwrite=True` davranisi ayri test edilir.
- Sessiz veri kaybi riski azalir.

Bir santiye devir dosyasinda bu cok onemlidir. Onceki sefin teslim ettigi raporun yanlislikla ezilmesi, sonradan kimin hangi veriyi gordugunu anlamayi zorlastirir.

## Format helper neden export helper'dan ayri tutulmalidir?

Format helper'in isi sunum ciktisi hazirlamaktir.

Ornek:

- JSON-ready Python dict.
- Markdown string.

Format helper:

- Dosya yazmaz.
- Path bilmez.
- Overwrite karari vermez.
- Backup / restore davranisi ustlenmez.
- Kayit reddetmez.
- Hard validation yapmaz.

Export helper ise ileride dosya yazarsa baska bir sorumluluk tasir:

- Output path alir.
- Izinli export kokunu kontrol eder.
- Dosya uzantisini kontrol eder.
- Mevcut dosya varsa overwrite policy uygular.
- UTF-8 gibi encoding kararlarina uyar.

Bu ayrim kodu daha okunur ve guvenli yapar.

Bir helper hem raporu hesaplayip hem formatlayip hem dosyaya yazip hem de karar verirse sorumluluklar karisir. CSE projesinde bu nedenle katmanlar kucuk tutulur.

## Insaat projesi / handover ornegi

Bir projede yeni santiye sefi gorevi devralacak olsun.

Sistem ileride bir handover QC Markdown raporu uretebilir:

```text
exports/handover_qc_2026_07_09.md
```

Bu raporun amaci:

- Yeni santiye sefine gorunurluk saglamak.
- Review/attention gerektiren kayitlari gostermek.
- Eksik veya riskli record ID orneklerini manuel incelemeye acmak.

Bu rapor:

- Devir paketini otomatik bloke etmez.
- Kayit reddetmez.
- Hard validation tetiklemez.
- `blocked` status uretmez.

Path safety burada sunu garanti etmeye calisir:

- Rapor izinli export alanina yazilir.
- `.git` veya `.env` gibi hassas dosyalara yazilmaz.
- Backup ZIP dosyalari export kapsamina karistirilmaz.
- Var olan rapor explicit izin olmadan ezilmez.

## Parent directory dersi

Bir export path'i soyle olabilir:

```text
exports/handover/2026/report.md
```

Eger `exports/handover/2026` klasoru yoksa helper ne yapmalidir?

Bu karar onemlidir.

Guvenli yaklasim:

- Varsayilan olarak eksik parent directory hata olabilir.
- Eger otomatik olusturma istenirse explicit parametre gerekir.
- Olusturma sadece izinli export kokunun altinda yapilabilir.

Bu sayede helper proje disinda veya hassas klasorlerde yanlislikla klasor olusturmaz.

## Dosya adi dersi

Dosya adi bos olmamalidir.

Dosya adi path separator icermemelidir.

Dosya adi cok uzun olmamalidir.

Ozel karakterler ve Windows reserved names dikkate alinmalidir.

Ornek riskli adlar:

```text
../report.md
CON.md
handover/report.md
```

Bu adimda dosya adi temizleme veya validation helper'i yazilmadi. Sadece ilerideki guvenli davranis icin karar zemini hazirlandi.

## Hata davranisi dersi

Gelecekte export helper hata alirsa iki yol dusunulebilir:

- Exception firlatmak.
- Diagnostic result dict dondurmek.

Hangisi secilirse secilsin hata su anlama gelmemelidir:

- Kayit reddi.
- Hard validation.
- Otomatik migration.
- Devir paketini bloke etme.
- `blocked` status.

Hata sadece file-writing isleminin guvenli sekilde tamamlanamadigini anlatmalidir.

## Bu adim ne yapmadi?

Bu adim:

- Export helper yazmadi.
- Dosya yazma kodu eklemedi.
- JSON export dosyasi uretmedi.
- Markdown export dosyasi uretmedi.
- Backup / restore davranisi eklemedi.
- Database / repository / API / GUI / CLI eklemedi.
- Hard validation eklemedi.
- `AuditEventRecord.__post_init__` degistirmedi.
- `FileAttachmentRecord` davranisini degistirmedi.
- `blocked` status eklemedi.
- Podcast 026 olusturmadi.

## Sonuc

Adim 153'un dersi sudur:

Dosya yazimi kucuk gorunebilir, ama kalici etki yarattigi icin once guvenlik siniri gerekir.

Path safety, allowed output root ve overwrite policy netlestirilmeden export helper implementasyonuna gecilmemelidir.
