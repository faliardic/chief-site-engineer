# 002 Python Dataclass ve Veri Modeli

## 1. Bu adimda ne yaptik?

Bu adimda santiye sefi uygulamasinin ilk cekirdek veri modellerini `app/models.py` icinde tanimladik:

- `SiteProject`
- `ChecklistItem`
- `TrackingRecord`
- `ArchiveDocument`

Veri modeli, sistemde takip edilecek bilgilerin alanlarini ve anlamini tanimlayan yapidir.

## 2. Neden bunu yaptik?

Uygulama acisindan once hangi verilerle calisacagimizi bilmemiz gerekir.

Santiye sefi acisindan bu modeller; santiye bilgisi, kontrol maddesi, saha takip kaydi ve arsiv belgesi gibi gercek is nesnelerinin yazilim karsiligidir.

## 3. Hangi dosyalara dokunduk?

```text
app/models.py
tests/test_models.py
docs/002_cekirdek_veri_modeli.md
learning/002_python_dataclass_ve_veri_modeli.md
```

`app/models.py`: Veri modellerini tutar.

`tests/test_models.py`: Modellerin olusturulabildigini, alanlari tuttugunu ve varsayilan degerleri dogru kullandigini test eder.

## 4. Kod bloklari uzerinden aciklama

### SiteProject modeli

```python
@dataclass
class SiteProject:
    """Represents a construction site project."""

    project_id: str
    name: str
    location: str
    employer: str | None = None
    contractor: str | None = None
    building_inspection_company: str | None = None
    start_date: str | None = None
    status: str = "active"
```

Bu kodun amaci:
Bir santiyeyi yazilim icinde duzenli bir nesne olarak temsil etmek.

Satir satir aciklama:

- `@dataclass`: Python'a bu class'in veri tasiyan sade bir class oldugunu soyler.
- `class SiteProject:` santiye projesi icin yeni class tanimlar.
- `project_id: str`: Projenin benzersiz kimligini metin olarak tutar.
- `name: str`: Proje adini tutar.
- `location: str`: Proje konumunu tutar.
- `employer: str | None = None`: Isveren bilgisi metin olabilir veya henuz bilinmiyorsa `None` olabilir.
- `contractor: str | None = None`: Yuklenici bilgisi opsiyoneldir.
- `building_inspection_company: str | None = None`: Yapi denetim firmasi bilgisi opsiyoneldir.
- `start_date: str | None = None`: Baslangic tarihi henuz girilmemis olabilir.
- `status: str = "active"` proje durumunu varsayilan olarak aktif yapar.

Sunu yaptik:
Santiyeyi ayri bir veri modeli olarak tanimladik.

Boyle yaptik:
`@dataclass`, type hint ve varsayilan degerler kullandik.

Cunku:
Santiye bilgisi birden fazla alandan olusur ve bu alanlar tek yerde duzenli durmalidir.

Boylece:
Ileride santiyeleri listelemek, filtrelemek veya raporlamak kolaylasir.

### ChecklistItem modeli

```python
@dataclass
class ChecklistItem:
    """Represents a checklist item for site controls."""

    item_id: str
    title: str
    category: str
    description: str | None = None
    required: bool = True
    status: str = "pending"
```

Bu kodun amaci:
Bir kontrol maddesini yazilim icinde duzenli bir veri modeli olarak temsil etmek.

Satir satir aciklama:

- `@dataclass`: Bu class icin otomatik baslatma davranisi uretir.
- `class ChecklistItem:` kontrol maddesi modeli tanimlar.
- `item_id: str`: Kontrol maddesinin benzersiz kimligini tutar.
- `title: str`: Kontrol basligini tutar.
- `category: str`: Kontrolun hangi gruba ait oldugunu belirtir.
- `description: str | None = None`: Aciklama girilebilir, girilmezse bos kalabilir.
- `required: bool = True`: Kontrolun zorunlu olup olmadigini tutar.
- `status: str = "pending"` baslangic durumunu beklemede yapar.

Sunu yaptik:
Kontrol maddesini ayri bir class olarak tanimladik.

Boyle yaptik:
Her bilgiyi class icinde ayri field olarak yazdik.

Cunku:
Santiyede kontrol maddeleri baslik, kategori, zorunluluk ve durum bilgisiyle takip edilir.

Boylece:
Ileride bekleyen, tamamlanan veya zorunlu kontroller ayrilabilir.

### Diger modellerin kisa gorevi

```python
@dataclass
class TrackingRecord:
    """Represents a field tracking record."""

    record_id: str
    project_id: str
    title: str
    description: str
    date: str
    responsible_party: str | None = None
    status: str = "open"
```

`TrackingRecord`, sahadaki takip kaydini temsil eder. Bir isin basligi, aciklamasi, tarihi, sorumlusu ve durumu bu modelde tutulur.

```python
@dataclass
class ArchiveDocument:
    """Represents an archived project document."""

    document_id: str
    project_id: str
    title: str
    document_type: str
    file_path: str | None = None
    date: str | None = None
    notes: str | None = None
```

`ArchiveDocument`, arsivlenen belgeyi temsil eder. Belge yolu henuz yoksa `file_path` alani `None` kalabilir.

## 5. Test kodlari uzerinden aciklama

### SiteProject testi

```python
def test_site_project_holds_values_and_defaults() -> None:
    project = SiteProject(
        project_id="prj-001",
        name="Merkez Santiye",
        location="Istanbul",
    )

    assert project.project_id == "prj-001"
    assert project.name == "Merkez Santiye"
    assert project.location == "Istanbul"
    assert project.employer is None
    assert project.contractor is None
    assert project.building_inspection_company is None
    assert project.start_date is None
    assert project.status == "active"
```

Bu testin amaci:
`SiteProject` nesnesinin olusturulabildigini, verilen alanlari sakladigini ve verilmeyen alanlara varsayilan degerleri koydugunu kontrol etmek.

`assert`, beklenen davranisin dogru olup olmadigini kontrol eder. Kosul yanlissa test basarisiz olur.

### ChecklistItem testi

```python
def test_checklist_item_holds_values_and_defaults() -> None:
    item = ChecklistItem(
        item_id="chk-001",
        title="Kalip kontrolu",
        category="Betonarme",
    )

    assert item.item_id == "chk-001"
    assert item.title == "Kalip kontrolu"
    assert item.category == "Betonarme"
    assert item.description is None
    assert item.required is True
    assert item.status == "pending"
```

Bu test, kontrol maddesi icin model olusturma ve varsayilan deger testidir. `description` verilmedigi icin `None`, `required` verilmedigi icin `True`, `status` verilmedigi icin `"pending"` gelir.

## 6. Kodun calisma akisi

1. Python `app/models.py` dosyasini okur.
2. `@dataclass` ile isaretlenen class'lar icin otomatik baslatma yapisi hazirlanir.
3. Testte `SiteProject(...)` veya `ChecklistItem(...)` yazilinca yeni nesne olusur.
4. Verilen degerler nesnenin attribute alanlarina yerlesir.
5. Verilmeyen opsiyonel alanlar `None` veya tanimlanan varsayilan degeri alir.
6. Testler `assert` ile bu alanlari kontrol eder.

## 7. "Sunu yaptik / Boyle yaptik / Cunku / Boylece" teknik karar tablosu

| Sunu yaptik | Boyle yaptik | Cunku | Boylece |
| --- | --- | --- | --- |
| Santiye modeli ekledik | `SiteProject` dataclass yazdik | Santiye bilgileri duzenli tutulmali | Proje bilgisi tek nesnede temsil edilir |
| Kontrol maddesi modeli ekledik | `ChecklistItem` class'i yazdik | Kontroller tekrar eden alanlara sahip | Kontrol listeleri kurulabilir |
| Opsiyonel alanlar tanimladik | `str | None = None` kullandik | Her bilgi ilk anda bilinmeyebilir | Eksik bilgiyle de nesne olusturulabilir |
| Varsayilan durumlar verdik | `status = "active"` ve `"pending"` kullandik | Yeni kayitlar baslangic durumuna ihtiyac duyar | Test edilebilir davranis olusur |

## 8. Yeni ogrenilen yazilim kavramlari

```text
Class:
Benzer verileri ve davranislari tanimlayan sablon yapidir.

Bu projedeki karsiligi:
SiteProject ve ChecklistItem birer class'tir.
```

```text
Nesne:
Bir class'tan olusturulan gercek veri ornegidir.

Bu projedeki karsiligi:
project = SiteProject(...) bir nesnedir.
```

```text
Attribute / ozellik:
Bir nesnenin icindeki alan degeridir.

Bu projedeki karsiligi:
project.name ve item.status birer attribute'tur.
```

## 9. Bu adimda bilincli olarak ne yapmadik?

Veritabani, JSON kayit sistemi, API, GUI ve gelismis mimari eklemedik.

Cunku once veri sekli netlesmelidir. Veri modeli oturmadan kayit sistemi kurmak ileride karmasa olusturur.

## 10. Mini sozluk

`Dataclass`: Veri tutan sade class'lari daha az kodla yazmayi saglayan Python ozelligi.

`Veri modeli`: Sistemde takip edilecek bilgilerin alanlarini tanimlayan yapi.

`Class`: Nesne olusturmak icin kullanilan sablon.

`Field / alan`: Modelin tuttugu tek bilgi parcasi.

`Type hint`: Bir alanin hangi veri tipiyle calistigini gosteren ipucu.

`str`: Metin veri tipi.

`bool`: `True` veya `False` degeri alan veri tipi.

`None`: Degerin henuz olmadigini gosteren Python degeri.

`Optional`: Alanin bos kalabilecegini anlatan mantik.

`str | None`: Alan metin olabilir veya `None` olabilir demektir.

`Varsayilan deger`: Deger verilmezse otomatik kullanilan baslangic degeri.

`Model testi`: Modelin olusturulmasini ve alanlarini kontrol eden test.

`assert`: Testte beklenen kosulu kontrol eden ifade.

## 11. Sonraki adima baglanti

Cekirdek veri modelleri hazir oldugu icin sonraki adimda bu modellerden biri olan gunluk saha kaydi daha ayrintili sekilde kurulabilir.
