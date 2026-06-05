# Adim 012 - Gunluk Rapor Ozet Modeli

## Amac

Bu adimin amaci, santiyede bir gune ait rapor ozetini ileride takip edebilmek icin sade bir veri modeli olusturmaktir.

## Bu Adimda Ne Eklendi?

`app/models.py` icine `DailyReportRecord` modeli eklendi. `tests/test_models.py` icine bu modelin alanlarini ve varsayilan degerlerini kontrol eden test eklendi.

## Cozulen Santiye Problemi

Santiye sefi bir gunde hangi islerin yapildigini, hava durumunu, sahadaki ekip durumunu, ekipmanlari, malzemeleri, sorunlari ve is guvenligi notlarini takip etmek ister. Bu model, ileride gunluk rapor uretme sisteminin veri temelini olusturur.

## Gunluk Rapor Nedir?

Gunluk rapor, santiyede bir gune ait isleyisi ozetleyen kayittir. Bu kayit; yapilan isleri, ekip ve ekipman durumunu, malzeme bilgisini, sorunlari ve genel notlari bir araya getirir.

## DailyReportRecord Model Kodu

```python
@dataclass
class DailyReportRecord:
    """Represents a daily site report summary."""

    report_date: str
    weather: str | None = None
    work_summary: str | None = None
    manpower_summary: str | None = None
    equipment_summary: str | None = None
    material_summary: str | None = None
    issue_summary: str | None = None
    safety_summary: str | None = None
    prepared_by: str | None = None
    status: str = "draft"
    notes: str | None = None
```

## DailyReportRecord Kodunun Satir Satir Aciklamasi

- `@dataclass`: Python'a bu class'in veri tasiyan sade bir model oldugunu soyler.
- `class DailyReportRecord:` gunluk rapor ozeti icin yeni model tanimlar.
- `report_date: str`: Rapor tarihini zorunlu alan olarak tutar.
- `weather: str | None = None`: Hava durumu bilgisini opsiyonel tutar.
- `work_summary: str | None = None`: O gun yapilan islerin ozetini opsiyonel tutar.
- `manpower_summary: str | None = None`: Iscilik veya ekip durumunu opsiyonel tutar.
- `equipment_summary: str | None = None`: Makine ve ekipman durumunu opsiyonel tutar.
- `material_summary: str | None = None`: Malzeme durumunu opsiyonel tutar.
- `issue_summary: str | None = None`: Sorun, uygunsuzluk veya dikkat edilmesi gereken olay ozetini opsiyonel tutar.
- `safety_summary: str | None = None`: Is guvenligi ozetini opsiyonel tutar.
- `prepared_by: str | None = None`: Raporu hazirlayan kisiyi opsiyonel tutar.
- `status: str = "draft"` kaydi varsayilan olarak taslak durumda baslatir.
- `notes: str | None = None`: Serbest aciklama alanini opsiyonel tutar.

Sunu yaptik: Gunluk rapor bilgisini `DailyReportRecord` modeliyle ayri tanimladik.

Boyle yaptik: Rapor tarihini zorunlu, diger rapor ozetlerini opsiyonel alan olarak tuttuk.

Cunku: Bir gunluk rapor once tarih bilgisiyle acilabilir; detaylar gun sonunda tamamlanabilir.

Boylece: Rapor taslak olarak baslatilabilir ve is, ekip, malzeme, sorun ve is guvenligi ozetleri sonra eklenebilir.

## Test Kodu

```python
def test_daily_report_record_holds_values_and_defaults() -> None:
    report = DailyReportRecord(
        report_date="2026-06-05",
        weather="Gunesli",
        work_summary="Temel izolasyon imalati tamamlandi.",
        manpower_summary="12 isci, 1 formen sahada calisti.",
        equipment_summary="1 ekskavator ve 1 vinc kullanildi.",
        material_summary="Izolasyon membrani sahaya alindi.",
        issue_summary="Kuzey cephede drenaj detayi netlestirilecek.",
        safety_summary="Is guvenligi uygunsuzlugu gorulmedi.",
        prepared_by="Santiye sefi",
    )

    assert report.report_date == "2026-06-05"
    assert report.weather == "Gunesli"
    assert report.work_summary == "Temel izolasyon imalati tamamlandi."
    assert report.manpower_summary == "12 isci, 1 formen sahada calisti."
    assert report.equipment_summary == "1 ekskavator ve 1 vinc kullanildi."
    assert report.material_summary == "Izolasyon membrani sahaya alindi."
    assert report.issue_summary == "Kuzey cephede drenaj detayi netlestirilecek."
    assert report.safety_summary == "Is guvenligi uygunsuzlugu gorulmedi."
    assert report.prepared_by == "Santiye sefi"
    assert report.notes is None
    assert report.status == "draft"
```

## Testin Satir Satir Aciklamasi

- `report = DailyReportRecord(...)`: Yeni gunluk rapor ozeti nesnesi olusturur.
- `report_date="2026-06-05"`: Rapor tarihini verir.
- `weather="Gunesli"`: Hava durumunu verir.
- `work_summary=...`: O gun yapilan islerin ozetini verir.
- `manpower_summary=...`: Iscilik durumunu verir.
- `equipment_summary=...`: Ekipman durumunu verir.
- `material_summary=...`: Malzeme durumunu verir.
- `issue_summary=...`: Sorun veya takip edilmesi gereken konuyu verir.
- `safety_summary=...`: Is guvenligi ozetini verir.
- `prepared_by="Santiye sefi"`: Raporu hazirlayan kisiyi verir.
- `assert report.notes is None`: Not girilmediginde alanin bos kalabildigini kontrol eder.
- `assert report.status == "draft"`: Gunluk raporun varsayilan olarak taslak basladigini kontrol eder.

Bu test; alan adlari degisirse, opsiyonel not alani beklenenden farkli baslarsa veya `status` varsayilani bozulursa hatayi yakalar.

## Teknik Karar Tablosu

| Sunu yaptik | Boyle yaptik | Cunku | Boylece |
| --- | --- | --- | --- |
| Gunluk rapor modelini ayri tuttuk | `DailyReportRecord` dataclass yazdik | Gunluk rapor bilgisi ileride raporlama temelidir | Rapor ozeti tek nesnede temsil edilir |
| Tarihi zorunlu tuttuk | `report_date: str` yazdik | Her gunluk rapor bir gune ait olmali | Kaydin hangi gune ait oldugu net olur |
| Ozetleri metin tuttuk | `str | None` alanlari kullandik | Bu adimda rapor sistemi kucuk kalmali | Liste, iliski ve rapor motoru eklenmez |
| Status varsayilanini draft yaptik | `status: str = "draft"` yazdik | Rapor ilk anda tamamlanmamis olabilir | Rapor taslak olarak baslatilabilir |

## Neden Gercek Rapor Uretimi Yapmadik?

Gercek rapor uretimi PDF/Excel sablonu, dosya kaydetme, veri toplama, formatlama ve disari aktarma kurallari gerektirir. Bu adimda once gunluk raporun hangi ozet alanlarina ihtiyac duydugunu netlestirdik.

## DailyReportRecord Ileride Hangi Modellerle Birlesebilir?

`DailyReportRecord` ileride `AttachmentRecord` ile fotograf ve ek dosyalara, `MaterialRecord` ile malzeme ozetlerine, `NonconformityRecord` ile uygunsuzluklara, `MeetingActionRecord` ile gunluk aksiyonlara, `RFIRecord` ve `SubmittalRecord` ile teknik sureclere baglanabilir. Bu adimda kod seviyesinde boyle bir bag kurulmaz.

## Mini Sozluk

`Gunluk rapor`: Santiyede bir gune ait is, ekip, malzeme, sorun ve not ozetlerini tutan kayit.

`DailyReportRecord`: Gunluk rapor ozet bilgisini temsil eden veri modeli.

`report_date`: Gunluk rapor tarihini tutan alan.

`weather`: Hava durumu bilgisini tutan alan.

`work_summary`: O gun yapilan islerin ozetini tutan alan.

`manpower_summary`: Iscilik veya ekip durumunu tutan ozet alan.

`equipment_summary`: Makine ve ekipman durumunu tutan ozet alan.

`material_summary`: Malzeme durumunu tutan ozet alan.

`issue_summary`: Sorun veya dikkat edilmesi gereken olay ozetini tutan alan.

`safety_summary`: Is guvenligi ozetini tutan alan.

`prepared_by`: Raporu hazirlayan kisiyi tutan alan.

`Rapor durumu`: Raporun taslak, tamamlandi veya benzeri durumunu anlatan bilgi.

`Gunluk is ozeti`: Bir gunde yapilan imalat ve saha islerinin kisa anlatimi.

`Iscilik ozeti`: Sahadaki ekip veya isci durumunun kisa anlatimi.

`Ekipman ozeti`: Sahadaki makine ve ekipman durumunun kisa anlatimi.

`Is guvenligi ozeti`: O gune ait is guvenligi durumunun kisa anlatimi.

## Sonraki Kucuk Adim

Adim 013 icin onerilen konu: Basit proje tarafi / kisi kayit modeli baslangici. Bu adimda Adim 013 uygulamasina gecilmedi.
