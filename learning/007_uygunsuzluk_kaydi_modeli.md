# 007 Uygunsuzluk Kaydi Modeli

## Bu adimda ne yaptik?

Bu adimda sahada tespit edilen uygunsuzluklari temsil eden `NonconformityRecord` modelini ekledik.

Bu model sadece Python dataclass olarak kuruldu. Fotograf, dosya, tutanak, PDF, veritabani, JSON, API, GUI veya bildirim sistemi eklenmedi.

## Neden bunu yaptik?

Uygulama acisindan uygunsuzluklar, saha kalite ve denetim surecinin takip edilmesi gereken ana kayitlarindandir.

Santiye sefi acisindan bu model, "sorun neydi, nerede goruldu, kim sorumlu, nasil duzeltilecek, kapandi mi?" sorularini duzenli takip etmeye hazirliktir.

## Hangi dosyalara dokunduk?

```text
app/models.py
tests/test_models.py
docs/007_uygunsuzluk_kayitlari.md
learning/007_uygunsuzluk_kaydi_modeli.md
learning/GLOSSARY.md
docs/project_decisions.md
CHANGELOG.md
ROADMAP.md
```

`app/models.py`: `NonconformityRecord` veri modelini tutar.

`tests/test_models.py`: Modelin zorunlu alanlari, opsiyonel alanlari ve varsayilan degerlerini test eder.

## Kod bloklari uzerinden aciklama

### NonconformityRecord modeli

```python
@dataclass
class NonconformityRecord:
    """Represents a nonconformity found on site."""

    nonconformity_id: str
    project_id: str
    date: str
    title: str
    description: str
    location: str | None = None
    category: str | None = None
    severity: str = "medium"
    responsible_party: str | None = None
    corrective_action: str | None = None
    due_date: str | None = None
    closed_date: str | None = None
    related_inspection_request_id: str | None = None
    related_pour_id: str | None = None
    notes: str | None = None
    status: str = "open"
```

### Kodun amaci

Bu model, sahada gorulen veya denetim surecinde ortaya cikan uygunsuzlugu yazilim icinde temsil eder.

### Satir satir aciklama

- `@dataclass`: Python'a bu class'in veri tasiyan sade bir model oldugunu soyler.
- `class NonconformityRecord:` uygunsuzluk kaydi icin yeni model tanimlar.
- `nonconformity_id: str`: Uygunsuzluk kaydinin benzersiz kimligini tutar.
- `project_id: str`: Kaydin hangi projeye ait oldugunu belirtir.
- `date: str`: Uygunsuzlugun kayit tarihini tutar.
- `title: str`: Uygunsuzlugun kisa basligini tutar.
- `description: str`: Uygunsuzlugun detayli aciklamasini tutar.
- `location: str | None = None`: Konum bilgisi girilebilir veya bos kalabilir.
- `category: str | None = None`: Kategori bilgisi girilebilir veya bos kalabilir.
- `severity: str = "medium"` onem seviyesini varsayilan olarak orta yapar.
- `responsible_party: str | None = None`: Sorumlu taraf sonra girilebilir.
- `corrective_action: str | None = None`: Duzeltici faaliyet sonra girilebilir.
- `due_date: str | None = None`: Termin tarihi sonra girilebilir.
- `closed_date: str | None = None`: Kapatma tarihi sonra girilebilir.
- `related_inspection_request_id: str | None = None`: Iliskili kontrol cagrisi opsiyoneldir.
- `related_pour_id: str | None = None`: Iliskili beton dokumu opsiyoneldir.
- `notes: str | None = None`: Ek notlar tutulabilir.
- `status: str = "open"` yeni uygunsuzluk kaydini acik durumda baslatir.

### Sunu yaptik / Boyle yaptik / Cunku / Boylece

- Sunu yaptik: Uygunsuzluk kaydini ayri veri modeli yaptik.
- Boyle yaptik: Kimlik, proje, tarih, baslik ve aciklamayi zorunlu alan yaptik.
- Cunku: Bir uygunsuzluk bu temel bilgiler olmadan takip edilemez.
- Boylece: Uygunsuzluklar ileride sorumlu taraf, durum, onem seviyesi veya iliskili kayitlara gore izlenebilir.

### Santiye karsiligi

Bu model, santiye sefinin sahada gordugu hatali imalati veya denetimde cikan sorunu uygunsuzluk formuna kaydetmesine benzer.

## Test kodlari uzerinden aciklama

### NonconformityRecord testi

```python
def test_nonconformity_record_holds_values_and_defaults() -> None:
    record = NonconformityRecord(
        nonconformity_id="ncr-001",
        project_id="prj-001",
        date="2026-06-05",
        title="Eksik donati",
        description="Temel bolgesinde ek donati eksik goruldu.",
    )

    assert record.nonconformity_id == "ncr-001"
    assert record.project_id == "prj-001"
    assert record.date == "2026-06-05"
    assert record.title == "Eksik donati"
    assert record.description == "Temel bolgesinde ek donati eksik goruldu."
    assert record.location is None
    assert record.category is None
    assert record.severity == "medium"
    assert record.responsible_party is None
    assert record.corrective_action is None
    assert record.due_date is None
    assert record.closed_date is None
    assert record.related_inspection_request_id is None
    assert record.related_pour_id is None
    assert record.notes is None
    assert record.status == "open"
```

### Testin amaci

Bu test, `NonconformityRecord` modelinin zorunlu alanlarla olustugunu, opsiyonel alanlarin `None` basladigini, `severity` degerinin `"medium"` ve `status` degerinin `"open"` oldugunu dogrular.

### Satir satir aciklama

- `record = NonconformityRecord(...)`: Yeni uygunsuzluk kaydi nesnesi olusturur.
- `nonconformity_id`, `project_id`, `date`, `title`, `description`: Zorunlu alanlar olarak verilir.
- `assert record.nonconformity_id == ...`: Kayit kimligini kontrol eder.
- `assert record.project_id == ...`: Proje baglantisini kontrol eder.
- `assert record.date == ...`: Kayit tarihini kontrol eder.
- `assert record.title == ...`: Basligin dogru saklandigini kontrol eder.
- `assert record.description == ...`: Aciklamanin dogru saklandigini kontrol eder.
- `assert record.location is None`: Konum verilmediyse bos kaldigini dogrular.
- `assert record.category is None`: Kategori verilmediyse bos kaldigini dogrular.
- `assert record.severity == "medium"` onem seviyesinin orta basladigini kontrol eder.
- `assert record.responsible_party is None`: Sorumlu taraf verilmediyse bos kaldigini dogrular.
- `assert record.corrective_action is None`: Duzeltici faaliyet verilmediyse bos kaldigini dogrular.
- `assert record.due_date is None`: Termin tarihi verilmediyse bos kaldigini dogrular.
- `assert record.closed_date is None`: Kapatma tarihi verilmediyse bos kaldigini dogrular.
- `assert record.related_inspection_request_id is None`: Iliskili kontrol cagrisi yoksa bos kaldigini dogrular.
- `assert record.related_pour_id is None`: Iliskili beton dokumu yoksa bos kaldigini dogrular.
- `assert record.notes is None`: Not verilmediyse bos kaldigini dogrular.
- `assert record.status == "open"` kaydin acik durumda basladigini kontrol eder.

### Testin hangi hatalari yakalayacagi

- Zorunlu alanlar yanlis attribute'a yazilirsa.
- Opsiyonel alanlar `None` yerine baska varsayilanla baslarsa.
- `related_inspection_request_id` veya `related_pour_id` zorunlu hale getirilirse.
- `severity` yanlislikla `"medium"` disinda baslarsa.
- `status` yanlislikla `"open"` disinda baslarsa.

## Kodun calisma akisi

1. Python `NonconformityRecord` class'ini okur.
2. `@dataclass` bu class icin otomatik baslatma yapisi uretir.
3. Test zorunlu alanlari vererek `NonconformityRecord(...)` nesnesi olusturur.
4. Verilen alanlar nesnenin attribute'larina yerlesir.
5. Verilmeyen opsiyonel alanlar `None` olur.
6. `severity` verilmedigi icin `"medium"` olur.
7. `status` verilmedigi icin `"open"` olur.
8. Testler tum alanlari `assert` ile kontrol eder.

## Teknik karar tablosu

| Sunu yaptik | Boyle yaptik | Cunku | Boylece |
| --- | --- | --- | --- |
| Uygunsuzluk modeli ekledik | `NonconformityRecord` dataclass yazdik | Sahadaki sorunlar ayri takip edilmeli | Uygunsuzluk bilgisi tek nesnede temsil edilir |
| Iliskili kayitlari opsiyonel tuttuk | `related_inspection_request_id` ve `related_pour_id` alanlarini `None` baslattik | Her uygunsuzluk denetim veya beton dokumune bagli olmayabilir | Model farkli kaynaklardan gelen uygunsuzluklari tasir |
| Varsayilan onem seviyesi verdik | `severity: str = "medium"` kullandik | Yeni kayit icin baslangic onem seviyesi gerekli | Kayit orta seviye onemle baslar |
| Varsayilan durum verdik | `status: str = "open"` kullandik | Yeni uygunsuzluk henuz kapanmis sayilmamali | Kayit acik durumda takip edilir |

## Bu adimda bilincli olarak ne yapmadik?

Veritabani, JSON kayit sistemi, API, GUI/web arayuzu, fotograf/dosya yukleme, tutanak/PDF/Excel cikti, resmi yazisma uretimi, bildirim sistemi ve yeni bagimlilik eklemedik.

Cunku bu adimin amaci uygunsuzluk takip sistemini tamamen kurmak degil, uygunsuzluk kaydinin veri seklini netlestirmektir.

## Mini sozluk

`Uygunsuzluk`: Proje, sartname, kalite veya is guvenligi beklentisine uymayan durum.

`NonconformityRecord`: Uygunsuzluk kaydini temsil eden veri modeli.

`corrective_action`: Uygunsuzlugu gidermek icin planlanan duzeltici faaliyet.

`severity`: Uygunsuzlugun onem seviyesini tutan alan.

`medium`: Orta onem seviyesi.

`open`: Kaydin acik durumda oldugunu anlatan status degeri.

`due_date`: Duzeltme icin hedef tarih.

`closed_date`: Uygunsuzlugun kapatildigi tarih.

`responsible_party`: Duzeltmeden sorumlu taraf.

`related_inspection_request_id`: Iliskili yapi denetim kontrol cagrisi kimligi.

`related_pour_id`: Iliskili beton dokumu kimligi.

## Sonraki adima baglanti

Uygunsuzluk kaydi modeli hazir oldugu icin sonraki adimda dosya/ek arsivleme veya uygunsuzluklara bagli takip davranislari daha anlamli sekilde kurulabilir.
