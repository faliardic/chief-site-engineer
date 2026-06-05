# 005 Beton Dokum ve Numune Modeli

## Bu adimda ne yaptik?

Bu adimda beton dokum ve beton numune takibi icin iki yeni veri modeli ekledik:

- `ConcretePour`
- `ConcreteSample`

Bu modeller sadece Python dataclass olarak kuruldu. Veritabani, JSON, EBIS, API veya rapor sistemi eklenmedi.

## Neden bunu yaptik?

Uygulama acisindan beton dokumleri ve numuneler ileride ayrica takip edilecek kritik kayitlardir.

Santiye sefi acisindan beton dokumu; tarih, lokasyon, beton sinifi, tedarikci ve numune takibiyle birlikte kontrol edilmesi gereken onemli bir imalattir.

## Hangi dosyalara dokunduk?

```text
app/models.py
tests/test_models.py
docs/005_beton_dokum_ve_numune_takip_baslangici.md
learning/005_beton_dokum_ve_numune_modeli.md
learning/GLOSSARY.md
docs/project_decisions.md
CHANGELOG.md
ROADMAP.md
```

`app/models.py`: Beton dokum ve numune modellerini tutar.

`tests/test_models.py`: Bu modellerin dogru olustugunu ve varsayilan degerleri dogru kullandigini test eder.

## ConcretePour modeli

### Kod blogu

```python
@dataclass
class ConcretePour:
    """Represents a concrete pour planned or performed on site."""

    pour_id: str
    project_id: str
    date: str
    location: str
    concrete_class: str
    volume_m3: float | None = None
    supplier: str | None = None
    truck_count: int | None = None
    weather: str | None = None
    notes: str | None = None
    status: str = "planned"
```

### Kodun amaci

Bu model, santiyede planlanan veya yapilan bir beton dokumunu temsil eder.

### Satir satir aciklama

- `@dataclass`: Python'a bu class'in veri tasiyan sade bir model oldugunu soyler.
- `class ConcretePour:` beton dokumu icin yeni model tanimlar.
- `pour_id: str`: Beton dokumunun benzersiz kimligini tutar.
- `project_id: str`: Dokumun hangi projeye ait oldugunu belirtir.
- `date: str`: Dokum tarihini tutar.
- `location: str`: Dokumun yapildigi yeri belirtir.
- `concrete_class: str`: Beton sinifini tutar.
- `volume_m3: float | None = None`: Metrekup cinsinden hacim girilebilir veya bos kalabilir.
- `supplier: str | None = None`: Beton tedarikcisi girilebilir veya bos kalabilir.
- `truck_count: int | None = None`: Mikser sayisi girilebilir veya bos kalabilir.
- `weather: str | None = None`: Hava durumu girilebilir veya bos kalabilir.
- `notes: str | None = None`: Ek notlar tutulabilir.
- `status: str = "planned"` yeni dokumu varsayilan olarak planlandi durumunda baslatir.

### Sunu yaptik / Boyle yaptik / Cunku / Boylece

- Sunu yaptik: Beton dokumunu ayri bir veri modeli yaptik.
- Boyle yaptik: Dokum kimligi, proje, tarih, lokasyon ve beton sinifini zorunlu alan yaptik.
- Cunku: Bir beton dokumu bu temel bilgiler olmadan anlamli takip edilemez.
- Boylece: Ileride beton dokumleri listelenebilir, sayilabilir ve durumlarina gore izlenebilir.

### Santiye karsiligi

Bu model, santiye sefinin beton dokum formundaki temel bilgileri tek yerde toplamasina benzer.

## ConcreteSample modeli

### Kod blogu

```python
@dataclass
class ConcreteSample:
    """Represents a concrete sample group taken from a pour."""

    sample_id: str
    pour_id: str
    project_id: str
    sample_date: str
    sample_count: int
    seven_day_test_date: str | None = None
    twenty_eight_day_test_date: str | None = None
    seven_day_result_mpa: float | None = None
    twenty_eight_day_result_mpa: float | None = None
    laboratory: str | None = None
    status: str = "waiting"
```

### Kodun amaci

Bu model, bir beton dokumunden alinan numune grubunu temsil eder.

### Satir satir aciklama

- `@dataclass`: Numune modelini sade veri class'i olarak kurar.
- `class ConcreteSample:` beton numunesi icin yeni model tanimlar.
- `sample_id: str`: Numune grubunun benzersiz kimligini tutar.
- `pour_id: str`: Numunenin hangi beton dokumunden alindigini belirtir.
- `project_id: str`: Numunenin hangi projeye ait oldugunu belirtir.
- `sample_date: str`: Numunenin alindigi tarihi tutar.
- `sample_count: int`: Alinan numune sayisini tutar.
- `seven_day_test_date: str | None = None`: 7 gunluk test tarihi sonra girilebilir.
- `twenty_eight_day_test_date: str | None = None`: 28 gunluk test tarihi sonra girilebilir.
- `seven_day_result_mpa: float | None = None`: 7 gunluk basinc dayanimi sonucu sonra girilebilir.
- `twenty_eight_day_result_mpa: float | None = None`: 28 gunluk basinc dayanimi sonucu sonra girilebilir.
- `laboratory: str | None = None`: Laboratuvar bilgisi opsiyoneldir.
- `status: str = "waiting"` numune varsayilan olarak beklemede baslar.

### Sunu yaptik / Boyle yaptik / Cunku / Boylece

- Sunu yaptik: Beton numunesini ayri veri modeli yaptik.
- Boyle yaptik: Numune kimligi, dokum baglantisi, tarih ve numune sayisini zorunlu alan yaptik.
- Cunku: Numune, hangi dokumden alindigi bilinmeden takip edilemez.
- Boylece: 7 ve 28 gunluk test surecleri ileride bu model uzerinden izlenebilir.

### Santiye karsiligi

Bu model, beton dokumunden alinan numune setinin laboratuvara giden takip fisine benzer.

## Test kodlari uzerinden aciklama

### ConcretePour testi

```python
def test_concrete_pour_holds_values_and_defaults() -> None:
    pour = ConcretePour(
        pour_id="pour-001",
        project_id="prj-001",
        date="2026-06-05",
        location="Temel",
        concrete_class="C30/37",
    )

    assert pour.pour_id == "pour-001"
    assert pour.project_id == "prj-001"
    assert pour.date == "2026-06-05"
    assert pour.location == "Temel"
    assert pour.concrete_class == "C30/37"
    assert pour.volume_m3 is None
    assert pour.supplier is None
    assert pour.truck_count is None
    assert pour.weather is None
    assert pour.notes is None
    assert pour.status == "planned"
```

Testin amaci:
`ConcretePour` modelinin zorunlu alanlarla olustugunu, opsiyonel alanlarin `None` geldigini ve `status` degerinin `"planned"` oldugunu dogrular.

Bu test su hatalari yakalar:

- Zorunlu alanlar yanlis attribute'a yazilirsa.
- Opsiyonel alanlar `None` yerine baska degerle baslarsa.
- Varsayilan `status` yanlislikla degistirilirse.

### ConcreteSample testi

```python
def test_concrete_sample_holds_values_and_defaults() -> None:
    sample = ConcreteSample(
        sample_id="sample-001",
        pour_id="pour-001",
        project_id="prj-001",
        sample_date="2026-06-05",
        sample_count=6,
    )

    assert sample.sample_id == "sample-001"
    assert sample.pour_id == "pour-001"
    assert sample.project_id == "prj-001"
    assert sample.sample_date == "2026-06-05"
    assert sample.sample_count == 6
    assert sample.seven_day_test_date is None
    assert sample.twenty_eight_day_test_date is None
    assert sample.seven_day_result_mpa is None
    assert sample.twenty_eight_day_result_mpa is None
    assert sample.laboratory is None
    assert sample.status == "waiting"
```

Testin amaci:
`ConcreteSample` modelinin zorunlu alanlari tuttugunu, 7 ve 28 gunluk test alanlarini bos baslattigini ve durumun `"waiting"` oldugunu kontrol eder.

Bu test su hatalari yakalar:

- Numune ile dokum baglantisi bozulursa.
- Test tarihleri veya sonuclari yanlis varsayilanla baslarsa.
- `status` beklemede yerine farkli bir degerle baslarsa.

## Kodun calisma akisi

1. Python `ConcretePour` ve `ConcreteSample` class'larini okur.
2. `@dataclass` bu class'lar icin otomatik baslatma yapisi uretir.
3. Testler zorunlu alanlari vererek nesne olusturur.
4. Verilen alanlar nesne attribute'larina yerlesir.
5. Verilmeyen opsiyonel alanlar `None` olur.
6. Varsayilan durumlar `planned` ve `waiting` olarak atanir.
7. Testler bu alanlari `assert` ile kontrol eder.

## Teknik karar tablosu

| Sunu yaptik | Boyle yaptik | Cunku | Boylece |
| --- | --- | --- | --- |
| Beton dokum modeli ekledik | `ConcretePour` dataclass yazdik | Beton dokumleri ayri takip edilmeli | Dokum bilgisi tek nesnede temsil edilir |
| Beton numune modeli ekledik | `ConcreteSample` dataclass yazdik | Numune takibi dokume bagli ilerler | Test tarihleri ve sonuclari izlenebilir |
| Test sonuclarini opsiyonel tuttuk | `float | None = None` kullandik | Sonuclar ilk kayit aninda bilinmez | Numune sonucu gelmeden kayit olusabilir |
| Entegrasyon eklemedik | EBIS, JSON ve veritabani kurmadik | Once veri sekli netlesmeli | Model sade ve test edilebilir kalir |

## Bu adimda bilincli olarak ne yapmadik?

Veritabani, JSON kayit sistemi, EBIS baglantisi, API, GUI/web arayuzu, PDF/Excel cikti, dosya yukleme ve yeni bagimlilik eklemedik.

Cunku bu adimin amaci beton takip sistemini tamamen kurmak degil, beton dokum ve numune verisinin seklini netlestirmektir.

## Mini sozluk

`Beton dokum`: Betonun santiyede belirli bir imalat bolgesine yerlestirilmesi.

`Beton numunesi`: Dokulen betondan test icin alinan ornek.

`ConcretePour`: Beton dokumunu temsil eden veri modeli.

`ConcreteSample`: Beton numunesini temsil eden veri modeli.

`Beton sinifi`: Betonun dayanim sinifini belirten ifade.

`Basinc dayanimi`: Betonun basinca karsi gosterdigi dayanim.

`7 gunluk test`: Betonun erken dayanimini kontrol eden test.

`28 gunluk test`: Betonun nihai dayanimini kontrol eden test.

`Laboratuvar`: Numune testlerinin yapildigi kurum veya birim.

`Tedarikci`: Betonu saglayan firma.

`planned`: Planlandi durumunu anlatan status degeri.

`waiting`: Beklemede durumunu anlatan status degeri.

`float`: Ondalik sayi veri tipi.

`int`: Tam sayi veri tipi.

## Sonraki adima baglanti

Beton dokum ve numune modelleri hazir oldugu icin sonraki adimlarda numune tarihlerini izleyen, bekleyen testleri listeleyen veya beton dokumlerini raporlayan yardimci davranislar kurulabilir.
