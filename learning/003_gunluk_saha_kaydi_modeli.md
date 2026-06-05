# 003 Gunluk Saha Kaydi Modeli

## 1. Bu adimda ne yaptik?

Bu adimda `DailySiteLog` modelini ekledik. Bu model, santiye sefinin bir gune ait saha notunu temsil eder.

Gunluk saha kaydi; hava durumu, ekip ozeti, yapilan is, kontroller, sorunlar ve notlar gibi bilgileri bir arada tutar.

## 2. Neden bunu yaptik?

Uygulama acisindan gunluk saha kaydi, ileride raporlama ve arsivleme icin temel veridir.

Santiye sefi acisindan bu model, her gun tutulan saha defteri veya gunluk raporun yazilim karsiligidir.

## 3. Hangi dosyalara dokunduk?

```text
app/models.py
tests/test_models.py
docs/003_gunluk_saha_kaydi.md
learning/003_gunluk_saha_kaydi_modeli.md
```

`app/models.py`: `DailySiteLog` modelini tutar.

`tests/test_models.py`: `DailySiteLog` modelinin dogru olustugunu ve varsayilan davranisini kontrol eder.

## 4. Kod bloklari uzerinden aciklama

### DailySiteLog modeli

```python
@dataclass
class DailySiteLog:
    """Represents a daily field note for a construction site."""

    log_id: str
    project_id: str
    date: str
    weather: str | None = None
    workforce_summary: str | None = None
    work_performed: str | None = None
    inspections: str | None = None
    issues: str | None = None
    notes: str | None = None
    created_by: str | None = None
    status: str = "draft"
```

Bu kodun amaci:
Bir gune ait saha kaydini tek bir veri modeli altinda toplamak.

Satir satir aciklama:

- `@dataclass`: Python'a bu class'in veri tasiyan sade bir model oldugunu soyler.
- `class DailySiteLog:` gunluk saha kaydi icin yeni class tanimlar.
- `log_id: str`: Gunluk kaydin benzersiz kimligini tutar.
- `project_id: str`: Kaydin hangi santiyeye ait oldugunu belirtir.
- `date: str`: Kaydin tarihini tutar.
- `weather: str | None = None`: Hava durumu girilebilir veya bos kalabilir.
- `workforce_summary: str | None = None`: Ekip/is gucu ozeti girilebilir veya bos kalabilir.
- `work_performed: str | None = None`: O gun yapilan isler yazilabilir.
- `inspections: str | None = None`: Kontrol veya denetim notlari tutulabilir.
- `issues: str | None = None`: Sorunlar veya aksakliklar yazilabilir.
- `notes: str | None = None`: Ek saha notlari tutulabilir.
- `created_by: str | None = None`: Kaydi olusturan kisi bilgisi opsiyoneldir.
- `status: str = "draft"` yeni kaydin varsayilan durumunu taslak yapar.

Sunu yaptik:
Bir gunluk saha kaydini tek bir model altinda topladik.

Boyle yaptik:
Zorunlu alanlari ve opsiyonel alanlari dataclass icinde tanimladik.

Cunku:
Santiye sefi her gun benzer tipte bilgiler tutar ama her bilgi her gun olmayabilir.

Boylece:
Hava durumu veya denetim bilgisi girilmese bile gunluk kayit olusturulabilir.

### Zorunlu ve opsiyonel alan ayrimi

```python
log_id: str
project_id: str
date: str
weather: str | None = None
status: str = "draft"
```

Bu parca, modelin temel kararini gosterir.

- `log_id`, `project_id`, `date`: Zorunlu alanlardir. Kayit kimligi, proje baglantisi ve tarih olmadan gunluk kayit anlamli olmaz.
- `weather`: Opsiyonel alandir. Hava durumu henuz girilmemis olabilir.
- `status`: Varsayilan davranistir. Deger verilmezse kayit `draft` baslar.

## 5. Test kodlari uzerinden aciklama

```python
def test_daily_site_log_holds_values_and_defaults() -> None:
    log = DailySiteLog(
        log_id="log-001",
        project_id="prj-001",
        date="2026-06-05",
    )

    assert log.log_id == "log-001"
    assert log.project_id == "prj-001"
    assert log.date == "2026-06-05"
    assert log.weather is None
    assert log.workforce_summary is None
    assert log.work_performed is None
    assert log.inspections is None
    assert log.issues is None
    assert log.notes is None
    assert log.created_by is None
    assert log.status == "draft"
```

Bu testin amaci:
`DailySiteLog` nesnesinin olusturulabildigini, zorunlu alanlari tuttugunu, opsiyonel alanlarin `None` geldigini ve `status` degerinin `draft` oldugunu kontrol etmek.

Satir satir aciklama:

- `log = DailySiteLog(...)`: Yeni bir gunluk saha kaydi nesnesi olusturur.
- `log_id`, `project_id`, `date`: Zorunlu alanlar olarak verilir.
- `assert log.log_id == ...`: Kimlik alaninin dogru saklandigini kontrol eder.
- `assert log.project_id == ...`: Kaydin dogru projeye baglandigini kontrol eder.
- `assert log.date == ...`: Tarihin dogru saklandigini kontrol eder.
- `assert log.weather is None`: Hava durumu girilmediginde bos kaldigini dogrular.
- `assert log.workforce_summary is None`: Ekip ozeti girilmediginde bos kaldigini dogrular.
- `assert log.work_performed is None`: Yapilan is girilmediginde bos kaldigini dogrular.
- `assert log.inspections is None`: Denetim notu girilmediginde bos kaldigini dogrular.
- `assert log.issues is None`: Sorun bilgisi girilmediginde bos kaldigini dogrular.
- `assert log.notes is None`: Ek not girilmediginde bos kaldigini dogrular.
- `assert log.created_by is None`: Kaydi olusturan kisi verilmediginde bos kaldigini dogrular.
- `assert log.status == "draft"` kaydin taslak durumda basladigini kontrol eder.

Status degerinin `draft` olmasi onemlidir. Cunku yeni bir gunluk kayit hemen tamamlanmis veya onaylanmis sayilmamalidir.

## 6. Kodun calisma akisi

1. Python `DailySiteLog` class'ini okur.
2. `@dataclass` bu class icin otomatik baslatma yapisi uretir.
3. Test `DailySiteLog(log_id=..., project_id=..., date=...)` yazar.
4. Zorunlu alanlar nesneye yerlesir.
5. Verilmeyen opsiyonel alanlar `None` olur.
6. `status` verilmedigi icin `"draft"` olur.
7. Testler tum alanlari `assert` ile kontrol eder.

## 7. "Sunu yaptik / Boyle yaptik / Cunku / Boylece" teknik karar tablosu

| Sunu yaptik | Boyle yaptik | Cunku | Boylece |
| --- | --- | --- | --- |
| Gunluk saha kaydi modeli ekledik | `DailySiteLog` dataclass yazdik | Santiye gunlukleri tek yapida tutulmali | Bir gune ait saha kaydi tek nesnede temsil edilir |
| Zorunlu alanlari belirledik | `log_id`, `project_id`, `date` alanlarini varsayilansiz yazdik | Kimlik, proje ve tarih olmadan kayit eksik olur | Kayit temel bilgileri olmadan olusturulamaz |
| Opsiyonel alanlar ekledik | `str | None = None` kullandik | Her gun her bilgi girilmeyebilir | Eksik bilgiyle de taslak kayit olusur |
| Varsayilan status verdik | `status: str = "draft"` yazdik | Yeni kayit hemen tamamlanmis sayilmamali | Kayit taslak olarak baslar |

## 8. Yeni ogrenilen yazilim kavramlari

```text
DailySiteLog:
Bir gune ait saha kaydini temsil eden veri modelidir.

Bu projedeki karsiligi:
app/models.py icindeki gunluk saha kaydi class'i.
```

```text
Zorunlu alan:
Model olusturulurken verilmesi gereken alandir.

Bu projedeki karsiligi:
log_id, project_id ve date.
```

```text
Varsayilan davranis:
Kullanici deger vermezse kodun otomatik yaptigi davranistir.

Bu projedeki karsiligi:
status alaninin draft gelmesi.
```

## 9. Bu adimda bilincli olarak ne yapmadik?

Veritabani, JSON kayit sistemi, dosya yukleme, API, GUI ve raporlama eklemedik.

Cunku once gunluk kaydin hangi alanlardan olusacagini netlestirmek istedik. Kayit sistemi daha sonra bu model uzerine kurulabilir.

## 10. Mini sozluk

`DailySiteLog`: Gunluk saha kaydi modeli.

`Gunluk saha kaydi`: Bir gune ait saha notu ve takip bilgisi.

`Daily log`: Gunluk kayit anlamina gelir.

`Zorunlu alan`: Model olusturulurken verilmesi gereken alan.

`Opsiyonel alan`: Bos kalabilen alan.

`Status`: Kaydin durumunu gosteren alan.

`Draft`: Taslak durum.

`created_by`: Kaydi olusturan kisi bilgisi.

`workforce_summary`: Sahadaki ekip/is gucu ozeti.

`work_performed`: O gun yapilan islerin ozeti.

`inspections`: Kontrol veya denetim notlari.

`issues`: Sorunlar veya aksakliklar.

`notes`: Ek notlar.

`Varsayilan davranis`: Deger verilmezse otomatik gelen davranis.

## 11. Sonraki adima baglanti

Gunluk saha kaydi modeli hazir oldugu icin sonraki adimda bu kayitlari bellek icinde listeleyen, sayan ve filtreleyen yardimci fonksiyonlar yazilabilir.
