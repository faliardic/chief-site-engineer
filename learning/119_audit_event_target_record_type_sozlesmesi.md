# Adim 119 - Audit Event Target Record Type Sozlesmesi

## Bu adimda ne yaptik?

Bu adimda `AuditEventRecord.target_record_type` alani icin ilk resmi type sozlesmesini dokumante ettik.

Kod yazmadik. Test eklemedik. Validation davranisi degistirmedik.

Yaptigimiz is, Adim 117'de tanimlanan target record iliski kurallarini ve Adim 118'de eklenen pair validation davranisini bir sonraki seviyeye tasimak icin dokumantasyon zemini olusturmaktir.

Artik `target_record_type` alaninin serbest aciklama alani olmadigi daha net:

```text
target_record_type = attachment
target_record_id = ATT-2026-0001
event_type = attachment.linked
```

Bu ornekte `target_record_type`, olayla ilgili kaydin turunu soyler. Olayin ne oldugunu `event_type`, hangi kayit oldugunu `target_record_id` anlatir.

## Neden yaptik?

Audit event kayitlari ileride filtrelenebilir, raporlanabilir ve farkli sistem ciktilariyla iliskilendirilebilir olmalidir.

Eger `target_record_type` serbest metin gibi birakilirsa ayni kavram farkli sekillerde yazilabilir:

```text
attachment
ek dosya
dosya eklendi
attachment record
```

Bu durum yazilim icin sorunludur. Cunku makine ayni anlama gelen ama farkli yazilmis degerleri otomatik olarak ayni kategori gibi yorumlayamaz.

Santiye karsiligi sudur: Bir evrak klasorunde herkes kendi etiketini kullanirsa, bir sure sonra "ek dosya", "fotograf", "attachment", "dosya kaniti" gibi farkli basliklar ayni tur bilgiyi dagitir. Arama ve kontrol zorlasir.

## Dokunulan dosyalar

```text
docs/119_audit_event_target_record_type_sozlesmesi.md
learning/119_audit_event_target_record_type_sozlesmesi.md
CHANGELOG.md
ROADMAP.md
docs/project_decisions.md
docs/117_audit_event_target_record_iliski_kurallari.md
docs/118_audit_event_target_record_pair_validation.md
learning/GLOSSARY.md
```

`docs/119_audit_event_target_record_type_sozlesmesi.md`: Asil target record type sozlesmesini anlatir.

`learning/119_audit_event_target_record_type_sozlesmesi.md`: Bu adimin neden yapildigini ogretici dille aciklar.

`CHANGELOG.md`: Adim 119'da ne degistigini kaydeder.

`ROADMAP.md`: Adim 119'u tamamlandi olarak isaretler ve Adim 120'yi siradaki is olarak gosterir.

`docs/project_decisions.md`: Teknik karar ozetini kalici karar kaydina ekler.

`docs/117_audit_event_target_record_iliski_kurallari.md`: Adim 119 sozlesmesinin Adim 117 iliski kurallarindan ayri oldugunu belirtir.

`docs/118_audit_event_target_record_pair_validation.md`: Pair validation'in allowed-list kontrolu yapmadigini netlestirir.

`learning/GLOSSARY.md`: Yeni terimleri kalici sozluge ekler.

## Target record type nedir?

`target_record_type`, audit event olayinin hangi tur kayitla ilgili oldugunu anlatan makine-okunabilir kategori degeridir.

Ornek:

```text
event_type = integrity.report_generated
target_record_type = attachment_integrity_report
target_record_id = AIR-2026-0001
```

Satir satir dusunelim:

- `event_type = integrity.report_generated`: Olayin ne oldugunu soyler. Burada integrity raporu uretilmis.
- `target_record_type = attachment_integrity_report`: Olayin hangi tur kayit veya ciktiyla ilgili oldugunu soyler.
- `target_record_id = AIR-2026-0001`: Ilgili raporun kimligini soyler.

Sunu soyle yaptik ki:
Olay turu ile hedef kayit turu birbirine karismasin.

Boyle yaptik:
`event_type`, `target_record_type` ve `target_record_id` alanlarinin ayri sorulara cevap verdigini dokumante ettik.

Cunku:
Ileride "tum attachment integrity raporu olaylarini listele" gibi sorgular icin hedef kayit turu temiz kalmalidir.

Boylece:
Audit event kayitlari hem insan icin okunabilir hem de yazilim icin filtrelenebilir olur.

## Neden serbest metin gibi birakilmamali?

`target_record_type` serbest metin gibi yazilirsa alanin anlami bozulur.

Yanlis kullanim:

```text
target_record_type = kalip kontrol notu guncellendi
```

Bu deger aslinda kayit turu degildir. Bir aciklama cumlesidir.

Dogru kullanim:

```text
event_type = record.updated
target_record_type = project_record
target_record_id = REC-2026-0007
reason = Kalip kontrol notu guncellendi.
```

Burada bilgiler kendi yerine yazilir:

- Olay turu `event_type` alaninda.
- Kayit turu `target_record_type` alaninda.
- Kayit kimligi `target_record_id` alaninda.
- Gerekce `reason` alaninda.

Sunu soyle yaptik ki:
Makine-okunabilir alanlara insan cumlesi yazilmasin.

Boyle yaptik:
`target_record_type` icin kucuk harfli, bosluksuz, Turkce karaktersiz ve sabit adaylara uygun sozlesme tanimladik.

Cunku:
Serbest metin filtreleme, raporlama ve validation icin guvenilir degildir.

Boylece:
Ileride allowed-list validation eklemek kolaylasir.

## Ilk target record type adaylari tablosu

| Target record type | Ne zaman kullanilir? | Target record id neyi temsil eder? | Ornek event type | Not |
| --- | --- | --- | --- | --- |
| `project` | Genel proje kaydi olaylarinda | Proje kimligi | `record.updated` | Proje seviyesindeki olaylar icin. |
| `project_record` | Genel saha/kalite/takip kayitlarinda | Kayit kimligi | `record.updated` | Daha spesifik tip yoksa kullanilabilir. |
| `attachment` | Dosya/ek baglama olaylarinda | Attachment kimligi | `attachment.linked` | Dosyanin kendisini degil metadata referansini isaret eder. |
| `attachment_metadata` | Ek dosya metadata guncellemelerinde | Metadata kimligi | `attachment.metadata_updated` | Dosya icerigi degisikligi anlamina gelmez. |
| `attachment_integrity_report` | Integrity raporu olaylarinda | Rapor kimligi | `integrity.report_generated` | Rapor ciktisini isaret eder. |
| `json_export` | JSON export olaylarinda | Export kimligi | `json.exported` | JSON kalici veri deposu degildir. |
| `backup_package` | Backup paketi olaylarinda | Backup kimligi | `backup.generated` | Backup icerigi bu alana yazilmaz. |
| `restore_operation` | Restore sureci olaylarinda | Operasyon kimligi | `restore.started` | Surec kimligini isaret eder. |
| `handover_package` | Devir paketi olaylarinda | Handover kimligi | `handover.package_generated` | Devir paketini isaret eder. |
| `audit_event` | Audit sisteminin kendi olaylarinda | Audit event kimligi | `audit.event_created` | Dikkatli ve sinirli kullanilmalidir. |

## Dogru / yanlis kullanim ornekleri

Dogru ornek:

```text
target_record_type = backup_package
target_record_id = BCK-2026-0001
event_type = backup.generated
```

Bu ornekte backup paketi bir hedef kayit/cikti turu olarak isaretlenir.

Yanlis ornek:

```text
target_record_type = backup paketi olusturuldu ve kontrol edildi
```

Bu deger kayit turu degil, insan aciklamasidir. Bu bilgi gerekiyorsa `notes` veya `reason` alanina yazilmalidir.

## Alanlarin ayrimi

| Alan | Ne soyler? | Ne tasimamali? |
| --- | --- | --- |
| `event_type` | Olayin ne oldugunu soyler. | Kayit kimligi veya insan notu tasimamali. |
| `target_record_type` | Olayin hangi tur kayitla ilgili oldugunu soyler. | Gerekce, not, snapshot veya degisen deger tasimamali. |
| `target_record_id` | Olayin hangi kayit kimligiyle ilgili oldugunu soyler. | Aciklama cumlesi tasimamali. |
| `reason` | Olayin neden yapildigini aciklar. | Kayit turu yerine kullanilmamali. |
| `notes` | Insan tarafindan okunacak ek notu tutar. | Makine-okunabilir kategori yerine kullanilmamali. |
| `old_value` | Eski degerin kisa ve guvenli ozetidir. | Tam kayit snapshot'i tasimamali. |
| `new_value` | Yeni degerin kisa ve guvenli ozetidir. | Tam kayit snapshot'i tasimamali. |

## Ileride kodlanabilecek validation akisi

Bu adimda validation kodlamadik. Ancak ileride su akis mantikli olabilir:

```text
1. Required audit event fields kontrol edilir.
2. Event type allowed-list kontrol edilir.
3. target_record_type / target_record_id pair validation calisir.
4. target_record_type ve target_record_id bos string / whitespace mi kontrol edilir.
5. target_record_type desteklenen target type listesinde mi kontrol edilir.
```

Bu akisin amaci, hatalari kullaniciya daha anlasilir sirayla gostermektir.

Ornek gelecek hata mesajlari:

```text
target_record_type is required when target_record_id is provided
target_record_id is required when target_record_type is provided
target_record_type is not supported
```

Bu mesajlarda alan adlari gecmelidir. Boylece hatanin hangi alandan kaynaklandigi net olur.

## Teknik karar tablosu

| Sunu yaptik | Boyle yaptik | Cunku | Boylece |
| --- | --- | --- | --- |
| Target type sozlesmesini yazdik | Yeni docs dosyasi olusturduk | Kodlamadan once alan anlami netlesmeli | Adim 120 daha guvenli tasarlanabilir |
| Aday target type listesini belirledik | 10 makine-okunabilir deger dokumante ettik | Serbest metin ileride karmasa uretir | Allowed-list validation icin zemin olustu |
| Alan ayrimini netlestirdik | `event_type`, `target_record_type`, `reason`, `notes`, `old_value`, `new_value` ayrimini tabloyla anlattik | Her alanin sorumlulugu ayri olmali | Audit event kaydi daha okunabilir olur |
| Kod eklemedik | Documentation-only kaldik | Bu adim sozlesme adimi | Test sayisi ve davranis degismedi |

## Test ve kalite kontrol mantigi

Bu adimda yeni test yazmadik. Cunku uygulama davranisi degismedi; yalnizca dokumantasyon ve karar kayitlari guncellendi.

Yine de mevcut testleri calistirmak gerekir:

```text
python -m pytest
```

Bu komutun amaci, dokumantasyon adiminda yanlislikla uygulama veya test davranisinin bozulmadigini gormektir.

Sunu soyle yaptik ki:
Kod degistirmedigimiz halde proje butunlugu kontrol edilmis olsun.

Boyle yaptik:
Mevcut tum pytest testlerini tekrar calistirmayi kalite kontrol adimi olarak koruduk.

Cunku:
Documentation-only adimlarda bile yanlis dosyaya dokunma riski vardir.

Boylece:
Test sayisinin `237 passed` olarak kalmasi bu adimin davranis degistirmedigini destekler.

## "Sunu soyle yaptik ki..." bolumu

Sunu yaptik:
`target_record_type` icin ilk resmi sozlesmeyi yazdik.

Boyle yaptik:
Kucuk harfli, bosluksuz, Turkce karaktersiz ve makine-okunabilir degerler kullanilmasini dokumante ettik.

Cunku:
Bu alan ileride filtreleme, raporlama ve validation icin sabit kategori gibi davranacak.

Boylece:
Kod eklemeden once dogru degerlerin nasil gorunmesi gerektigini netlestirdik.

Sunu yaptik:
Allowed-list validation'i erteledik.

Boyle yaptik:
Bu adimda sadece dokuman, karar kaydi ve learning notu ekledik.

Cunku:
Validation eklemek runtime davranisini degistirir ve test gerektirir. Bu adim documentation-only kalmaliydi.

Boylece:
Adim 120'de hangi sabitlerin ve hangi hata mesajlarinin kodlanabilecegi daha temiz hale geldi.

## Bilincli olarak yapilmayanlar

Bu adimda uygulama kodu degistirilmedi.

Bu adimda test dosyasi degistirilmedi.

Bu adimda target type constants eklenmedi.

Bu adimda target type enum eklenmedi.

Bu adimda target type allowed-list validation eklenmedi.

Bu adimda `AuditEventRecord.__post_init__` degistirilmedi.

Bu adimda target record id format validation, bos string validation, whitespace validation, database, repository, migration, JSON schema, API, GUI, CLI, persistence veya otomatik audit event uretimi eklenmedi.

## Mini sozluk

`Target Record Type Contract`: `target_record_type` degerlerinin nasil yazilacagini ve hangi anlamda kullanilacagini belirleyen sozlesme.

`Allowed Target Type`: `target_record_type` icin izin verilen makine-okunabilir deger.

`Target Type Validation`: `target_record_type` degerinin izinli listede olup olmadigini kontrol edecek gelecek validation davranisi.

`Free Text Misuse`: Makine-okunabilir bir alana aciklama cumlesi yazilmasi hatasi.

`Snapshot`: Bir kaydin belirli andaki tum veya genis icerik kopyasi.

## Adim 120'ye baglanti

Bu adim Adim 120 icin sozlesme zemini olusturdu.

Onerilen sonraki adim:

```text
Adim 120 - Audit event target record type sabitleri ve validation
```

Adim 120'de bu dokumandaki adaylar sabit tuple veya benzeri sade bir yapiya alinabilir. Ardindan `target_record_type` icin allowed-list validation ve gerekli model testleri eklenebilir.
