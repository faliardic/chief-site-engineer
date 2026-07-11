# Step 208 Learning - FieldObservationRecord Veri Sozlesmesi

## Bu Adimda Ne Yaptik?

Bu adimda kod yazmadik. Bunun yerine gelecekte eklenecek `FieldObservationRecord` modeli icin once bir veri sozlesmesi yazdik.

Sebep su: saha kaydi gibi urunun merkezinde olan bir modeli hemen kodlamak kolay gorunur, ama hangi alanlar zorunlu, hangileri sonradan eklenebilir, attachment nasil baglanir, resmi kayit ile ozel not nasil ayrilir gibi kararlar net degilse kod hizla karisir.

## Sunu soyle yaptik ki...

Sunu soyle yaptik ki sahada kayit acma 20-30 saniyeyi gecmesin:

```text
Required at initial capture:
- observation_id
- project_id
- observed_at
- location
- category
- description
```

`reported_to` ve attachment bilgisini ilk anda zorunlu yapmadik. Boylece santiye sefi once sahadaki gozlemi kaydeder, sonra fotograf ekleyebilir veya kime bildirdigini tamamlayabilir.

Sunu soyle yaptik ki resmi kayit ile ozel alan karismasin:

```text
FieldObservationRecord = resmi/proje kaydi
Personal/private note = kullanicinin ozel alani
```

Ozel nottan resmi gozlem kaydina donusum ancak acik kullanici islemiyle olabilir. Sistem kendi kendine ozel notu resmi kayda kopyalamaz.

Sunu soyle yaptik ki attachment yapisi buyumesin:

```text
FieldObservationRecord
  observation_id = "obs-001"

FileAttachmentRecord
  related_record_type = "field_observation"
  related_record_id = "obs-001"
```

Observation record icine dosya listesi veya binary data koymadik. Dosya metadata kaydi ayri kalir.

## Veri Sozlesmesi Nedir?

Veri sozlesmesi, bir modelin hangi alanlari tasiyacagini ve bu alanlarin nasil yorumlanacagini onceden yazili hale getirmektir.

Basit bir ornek:

```python
FieldObservationRecord(
    observation_id="obs-001",
    project_id="prj-001",
    observed_at="2026-07-11T18:30:00",
    location="A Blok 2. Kat",
    category="quality",
    description="Kalip birlesiminde aciklik goruldu.",
    status="open",
)
```

Bu kod bu adimda eklenmedi. Sadece gelecekte nasil gorunebilecegini anlamak icin ornek olarak yazildi.

Satir satir:

- `observation_id`: Bu gozlem kaydinin benzersiz kimligi.
- `project_id`: Gozlemin hangi projeye ait oldugu.
- `observed_at`: Gozlemin ne zaman yapildigi.
- `location`: Sahadaki hizli konum bilgisi.
- `category`: Gozlemin turu.
- `description`: Kisa saha aciklamasi.
- `status`: Kaydin yasam dongusu durumu.

## Status Neden Basit Tutuldu?

Ilk vocabulary:

```text
open
tracking
closed
```

Anlami:

| Status | Anlam |
| --- | --- |
| `open` | Kayit acildi, takip veya inceleme bekliyor. |
| `tracking` | Konu takip ediliyor. |
| `closed` | Yasam dongusu tamamlandi. Silinmis anlamina gelmez. |

`closed` ile `is_archived` ayni sey degildir. Bir kayit kapanmis olabilir ama raporlarda gorunmeye devam edebilir. Arsivleme ise ayri bir gorunurluk/saklama karari olur.

## Mevcut Kodla Iliski

Mevcut `app/models.py` icinde su sinirlar incelendi:

```text
SiteProject
TrackingRecord
DailySiteLog
FileAttachmentRecord
DailyReportRecord
ContactPersonRecord
SiteLocationRecord
SiteNoteRecord
```

Gelecek model bunlari kopyalamadan, sadece dogru yerlerde iliski kuracak:

| Mevcut model | FieldObservationRecord ile iliski |
| --- | --- |
| `SiteProject` | `project_id` bu projeye baglanir. |
| `SiteLocationRecord` | Gelecekte structured location icin kullanilabilir. |
| `ContactPersonRecord` | Gelecekte `reported_to` normalize etmek icin kullanilabilir. |
| `FileAttachmentRecord` | Dosya metadata baglantisi burada tutulur. |
| `DailySiteLog` | Ileride gunluk kayitlar observation verisini tuketebilir. |
| `DailyReportRecord` | Ileride rapor ozetleri observation verisini kullanabilir. |

## Neden Hemen Kod Yazmadik?

Teknik karar tablosu:

| Karar | Neden |
| --- | --- |
| `FieldObservationRecord` bu adimda implemente edilmedi | Issue #32 sadece contract/documentation izni verdi. |
| Attachment ilk kayitta zorunlu degil | Sahada hizli kayit hedefi korunur. |
| `reported_to` ilk kayitta zorunlu degil | Kisi bilgisi sonradan tamamlanabilir. |
| `location` text/snapshot kaldi | Structured location daha sonra yavaslatmadan planlanir. |
| Private note otomatik resmi kayda donusmez | Ozel alan/resmi kayit ayrimi korunur. |
| Hard validation eklenmedi | Validation davranisi ayri explicit task gerektirir. |

## Gelecekte Kod Akisi Nasil Olabilir?

Step 209 review ve merge sonrasi yetki verilirse, basit bir dataclass su akisa sahip olabilir:

```text
User sees issue on site
-> creates FieldObservationRecord
-> record starts with status=open
-> optional photo is added later through FileAttachmentRecord
-> optional reported_to is filled later
-> status moves to tracking or closed
-> daily/weekly reports consume records later
```

Bu adimda bu akis calisan kod haline getirilmedi. Sadece ileride nasil dusunulecegi belgelendi.

## Testler Ne Dogruladi?

Bu adim documentation-only oldugu icin yeni test eklenmedi.

Yine de tum mevcut testler calistirilacak:

```powershell
python -m pytest
```

Bu komut sunu dogrular:

- Mevcut modeller bozulmadi.
- Mevcut repository davranislari bozulmadi.
- Attachment integrity ve export helper davranislari bozulmadi.
- Dokumantasyon-only adim production davranisini degistirmedi.

Ek kontroller:

```powershell
git diff --check
python -m json.tool .cse/state/project_state.json
git diff -- app/models.py tests/test_models.py .github/workflows/pytest.yml
```

Bu komutlar sirasiyla whitespace hatasi, JSON gecerliligi ve korunan dosyalarda degisiklik olup olmadigini kontrol eder.

## Terimler

- Veri sozlesmesi: Bir modelin alanlarini, anlamlarini ve sinirlarini implementasyondan once yazili hale getirme.
- Fast-capture field: Sahada hizli girilebilmesi icin basit tutulan alan.
- Snapshot field: Ilk anda yazilan metinsel degerin, gelecekte structured kayda baglansa bile o anki gorunumu saklamasi.
- Lifecycle state: Kaydin yasam dongusundeki durumu; burada `open`, `tracking`, `closed`.
- Physical deletion: Kaydin gercekten silinmesi. CSE resmi kayitlarda bunu varsayilan davranis yapmaz.

## Sonuc

Step 208, Field MVP icin ilk gercek saha degerine donus adimidir; fakat bilincli olarak sadece contract yazdi. Bu sayede Step 209 implementasyonu basladiginda hangi alanlarin gerekli oldugu, hangi davranislarin yasak oldugu ve mevcut modellerle nasil iliski kurulacagi onceden belli olacak.
