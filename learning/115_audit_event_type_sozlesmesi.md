# Adim 115 - Audit Event Type Sozlesmesi

## Bu adimda ne yaptik?

Bu adimda `AuditEventRecord.event_type` alani icin ilk resmi adlandirma sozlesmesini dokumante ettik.

Kod degistirmedik. Test eklemedik. Validation, enum, constants, repository veya persistence eklemedik.

## Neden yaptik?

Audit event kayitlari ileride cok farkli olaylari anlatabilir:

- kayit olusturma
- kayit guncelleme
- attachment baglama
- integrity raporu uretme
- JSON export alma
- backup veya restore olayi
- handover paketi hazirlama

Bu olaylari her seferinde serbest metinle yazarsak sistem ileride ayni olayi farkli ifadelerle gormeye baslar. Bu da filtreleme, raporlama ve validation icin zor bir zemin olusturur.

Bu yuzden once `event_type` degerlerinin nasil yazilacagini belgeledik.

## Dokunulan dosyalar

```text
docs/115_audit_event_type_sozlesmesi.md
learning/115_audit_event_type_sozlesmesi.md
CHANGELOG.md
ROADMAP.md
docs/project_decisions.md
learning/GLOSSARY.md
```

`docs/115_audit_event_type_sozlesmesi.md`: Event type sozlesmesinin ana teknik dokumani.

`learning/115_audit_event_type_sozlesmesi.md`: Konunun ogrenme amacli aciklamasi.

`CHANGELOG.md`: Step 115 kaydi.

`ROADMAP.md`: Adim 115 tamamlandi ve Adim 116 onerisi guncellendi.

`docs/project_decisions.md`: Kisa karar kaydi.

`learning/GLOSSARY.md`: Yeni kalici terimler.

## Event type nedir?

`event_type`, audit event kaydinin hangi tur olay oldugunu gosteren kisa, sabit ve makine tarafindan okunabilir metindir.

Ornek:

```text
record.created
record.updated
integrity.report_generated
json.export_failed
```

Bu degerler kullaniciya gosterilecek uzun aciklama degildir. Sistem icinde ayni olay turunu tutarli sekilde temsil etmek icin kullanilir.

## Neden serbest metin gibi birakilmamali?

Serbest metin insanlar icin rahattir ama sistem icin zorlayicidir.

Ornegin ayni olay su sekillerde yazilabilir:

```text
Kayit arsivlendi
record archived
arsivleme yapildi
NCR arsive alindi
```

Bu ifadeler insan icin benzer gorunebilir. Ama kod tarafinda hepsi farkli string degerleridir.

Bu nedenle `event_type` serbest aciklama alani olmamali. Serbest aciklama gerekiyorsa `reason` veya `notes` alanlari kullanilmali.

## Domain/action mantigi

Bu adimda event type bicimi su sekilde planlandi:

```text
domain.action
```

`domain`, olay ailesini anlatir.

`action`, o domain icinde gerceklesen eylemi anlatir.

Ornek:

```text
record.created
attachment.linked
integrity.checked
backup.generated
restore.failed
```

Bu yaklasim sayesinde event type degeri hem kisa kalir hem de hangi sistem alanina ait oldugu kolay anlasilir.

## Ilk event type adaylari tablosu

| Kategori | Event type adaylari | Ne anlatir? |
| --- | --- | --- |
| Kayit olaylari | `record.created`, `record.updated`, `record.archived`, `record.restored` | Resmi veya domain kayitlari uzerindeki temel olaylar |
| Attachment olaylari | `attachment.linked`, `attachment.unlinked`, `attachment.metadata_updated` | Dosya metadata baglantisi ve guncelleme olaylari |
| Attachment integrity olaylari | `integrity.checked`, `integrity.report_generated`, `integrity.issue_detected` | Butunluk kontrolu ve rapor olaylari |
| JSON export olaylari | `json.exported`, `json.export_failed` | Snapshot veya rapor export olaylari |
| Backup / restore olaylari | `backup.generated`, `backup.validated`, `restore.started`, `restore.completed`, `restore.failed` | Backup ve geri yukleme sureci olaylari |
| Handover olaylari | `handover.package_generated`, `handover.package_validated` | Devir paketi hazirlama ve kontrol olaylari |
| Audit sistem olaylari | `audit.event_created`, `audit.validation_failed` | Audit hattinin kendi olaylari |

## Dogru / yanlis event type ornekleri

Dogru ornekler:

```text
record.created
record.archived
attachment.metadata_updated
integrity.issue_detected
json.export_failed
```

Yanlis ornekler:

```text
Record Created
kayit.olusturuldu
record created
NCR arsivlendi
record.created.because.user.clicked.button
```

Yanlis orneklerin sorunlari:

- Buyuk harf var.
- Turkce karakter veya Turkce fiil var.
- Bosluk var.
- Serbest aciklama gibi yazilmis.
- Fazla uzun ve olay turu yerine detay anlatiyor.

## `event_type`, `reason`, `notes`, `old_value`, `new_value` ayrimi

`event_type` olayin turunu anlatir.

`reason` olayin neden yapildigini anlatir.

`notes` ek insan aciklamasini tutar.

`old_value` olaydan onceki degeri veya durum ozetini tutar.

`new_value` olaydan sonraki degeri veya durum ozetini tutar.

Dogru ayrim:

```text
event_type: record.updated
reason: Saha kontrolu sonrasi durum guncellendi.
old_value: status=open
new_value: status=closed
notes: Kapanis onayi kalite sorumlusu tarafindan verildi.
```

Yanlis ayrim:

```text
event_type: Saha kontrolu sonrasi status open iken closed yapildi
reason:
old_value:
new_value:
notes:
```

Bu yanlis kullanimda `event_type` hem olay turu hem aciklama hem de degisim bilgisi gibi kullanilmistir. Bu ileride filtreleme ve raporlama icin sorun uretir.

## Teknik karar tablosu

| Sunu yaptik | Boyle yaptik | Cunku | Boylece |
| --- | --- | --- | --- |
| Event type sozlesmesi yazdik | `domain.action` bicimini dokumante ettik | Serbest metin audit hattini dagitir | Olay turleri tutarli adlandirilir |
| Ilk adaylari grupladik | Record, attachment, integrity, JSON, backup, handover ve audit kategorileri kullandik | CSE'nin mevcut teknik hatlari bu alanlara ayriliyor | Ileride validation daha kolay tasarlanir |
| Aciklamayi event type disina aldik | `reason` ve `notes` alanlarini ayirdik | Event type kisa ve makine okunabilir kalmali | Insan aciklamasi dogru alanda tutulur |
| Degisim bilgisini ayirdik | `old_value` ve `new_value` alanlarini vurguladik | Event type deger gecmisini tasimamali | Once/sonra bilgisi daha temiz temsil edilir |
| Kod yazmadik | Sadece dokumantasyon ekledik | Sozlesme once karar seviyesinde netlesmeli | Implementasyon sonraki adima kalir |

## "Sunu soyle yaptik ki..." bolumu

Sunu yaptik:
`event_type` icin `domain.action` bicimini sectik.

Soyle yaptik:
Olayin ait oldugu alani domain, gerceklesen eylemi action olarak yazdik.

Ki:
`record.created`, `integrity.checked`, `json.exported` gibi degerler hem okunabilir hem de kod tarafindan kolay filtrelenebilir olsun.

Sunu yaptik:
`reason`, `notes`, `old_value` ve `new_value` alanlarini `event_type` alanindan ayirdik.

Soyle yaptik:
Event type degerini kisa tuttuk; insan aciklamasini ve once/sonra bilgisini ayri alanlara yonlendirdik.

Ki:
Audit event kaydi hem insan icin anlasilir hem de sistem icin duzenli kalsin.

## Bilincli olarak yapilmayanlar

Bu adimda uygulama kodu degistirilmedi.

Bu adimda test dosyasi degistirilmedi.

Bu adimda event type validation eklenmedi.

Bu adimda enum veya constants eklenmedi.

Bu adimda database, repository, JSON export, audit persistence veya otomatik audit event uretimi eklenmedi.

Bu adimda scanner, attachment integrity kodu, backup/restore davranisi, API, GUI veya CLI degistirilmedi.

## Mini sozluk

`Event Type`: Audit event kaydinda olay turunu anlatan sabit metin degeri.

`Domain/Action Naming`: Olay turunu `domain.action` biciminde adlandirma yaklasimi.

`Machine-Readable Value`: Kodun kolayca okuyup filtreleyebilecegi sabit deger.

`Human-Readable Note`: Insan tarafindan okunacak aciklama veya not.

`Reason`: Bir olay yapilirken neden yapildigini anlatan alan.

`Old Value`: Olaydan onceki deger veya durum ozeti.

`New Value`: Olaydan sonraki deger veya durum ozeti.

## Adim 116'ya baglanti

Bu adim event type sozlesmesini sadece dokumante etti.

Adim 116 icin uygun sonraki konu, audit event type validation veya sabit sozlesme implementasyonudur. O adimda bu dokumandaki adaylarin kod seviyesinde enum, constants veya validation olarak kullanilip kullanilmayacagi degerlendirilebilir.
