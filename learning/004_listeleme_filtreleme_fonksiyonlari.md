# 004 Bellek Ici Basit Kayit Listeleme

## Bu adimda ne yaptik?

Bu adimda veritabani veya dosya kaydi kullanmadan, Python listeleri uzerinde calisan dort sade yardimci fonksiyon yazdik:

- `list_records`
- `count_records`
- `filter_records_by_project_id`
- `filter_records_by_status`

## Neden bunu yaptik?

Uygulama acisindan, veri modelleri olustuktan sonra bu modellerden olusan kayitlari listelemek, saymak ve basit kosullara gore filtrelemek gerekir.

Santiye sefi acisindan bu, "tum kayitlari goster", "kac kayit var", "bu santiyenin kayitlarini goster" ve "taslak kayitlari goster" gibi temel ihtiyaclara karsilik gelir.

## Hangi dosyalara dokunduk?

```text
app/records.py
tests/test_records.py
docs/004_bellek_ici_kayit_listeleme.md
learning/004_listeleme_filtreleme_fonksiyonlari.md
```

`app/records.py`: Bellek ici kayit listeleme ve filtreleme yardimci fonksiyonlarini tutar.

`tests/test_records.py`: Bu fonksiyonlarin beklenen davranislari verip vermedigini kontrol eder.

`docs/004_bellek_ici_kayit_listeleme.md`: Adim 004'un uygulama acisindan kararlarini aciklar.

`learning/004_listeleme_filtreleme_fonksiyonlari.md`: Gercek kod bloklari uzerinden bu adimi ogretir.

## Fonksiyon 1: list_records

### Fonksiyon kod blogu

```python
def list_records(records: list[RecordT]) -> list[RecordT]:
    return records
```

### Satir satir aciklama

- `def list_records(...)`: Kayitlari listelemek icin fonksiyon tanimlar.
- `records: list[RecordT]`: Fonksiyona bir Python listesi verilecegini belirtir.
- `-> list[RecordT]`: Fonksiyonun yine ayni tipte kayitlardan olusan bir liste dondurecegini anlatir.
- `return records`: Verilen listeyi degistirmeden geri dondurur.

### Sunu yaptik / Boyle yaptik / Cunku / Boylece

- Sunu yaptik: Verilen kayit listesini oldugu gibi donduren fonksiyon yazdik.
- Boyle yaptik: Liste uzerinde ek islem yapmadan `return records` kullandik.
- Cunku: Ilk adimda amac kayitlari kalici bir sistemden degil, bellekteki listeden okumayi anlamak.
- Boylece: Kayitlari gosterme davranisinin en sade temelini kurduk.

### Santiye karsiligi

Bu fonksiyon, masadaki tum saha formlarini hic ayirmadan oldugu gibi onune almak gibidir.

### Test kodu ve testin neyi dogruladigi

```python
def test_list_records_returns_given_list() -> None:
    records = [
        DailySiteLog(log_id="log-001", project_id="prj-001", date="2026-06-05"),
    ]

    result = list_records(records)

    assert result == records
```

Bu test, `list_records` fonksiyonunun verilen listeyi aynen geri dondurdugunu dogrular.

## Fonksiyon 2: count_records

### Fonksiyon kod blogu

```python
def count_records(records: list[RecordT]) -> int:
    return len(records)
```

### Satir satir aciklama

- `def count_records(...)`: Kayit sayisini hesaplayan fonksiyon tanimlar.
- `records: list[RecordT]`: Sayilacak kayit listesini alir.
- `-> int`: Fonksiyonun tam sayi dondurecegini belirtir.
- `return len(records)`: Python'un `len` fonksiyonu ile listedeki eleman sayisini dondurur.

### Sunu yaptik / Boyle yaptik / Cunku / Boylece

- Sunu yaptik: Kayit sayisini veren fonksiyon yazdik.
- Boyle yaptik: Listenin uzunlugunu `len(records)` ile hesapladik.
- Cunku: Liste icinde kac saha kaydi oldugunu bilmek temel bir ihtiyactir.
- Boylece: Ileride ozet ekranlari ve raporlar icin sayma davranisi hazir oldu.

### Santiye karsiligi

Bu fonksiyon, klasordeki tutanak veya gunluk form sayisini saymaya benzer.

### Test kodu ve testin neyi dogruladigi

```python
def test_count_records_returns_record_count() -> None:
    records = [
        DailySiteLog(log_id="log-001", project_id="prj-001", date="2026-06-05"),
        DailySiteLog(log_id="log-002", project_id="prj-001", date="2026-06-06"),
    ]

    result = count_records(records)

    assert result == 2
```

Bu test, iki kayit verilen fonksiyonun sonucu `2` olarak dondurdugunu dogrular.

## Fonksiyon 3: filter_records_by_project_id

### Fonksiyon kod blogu

```python
def filter_records_by_project_id(
    records: list[RecordT],
    project_id: str,
) -> list[RecordT]:
    return [
        record
        for record in records
        if hasattr(record, "project_id") and record.project_id == project_id
    ]
```

### Satir satir aciklama

- `def filter_records_by_project_id(...)`: Proje kimligine gore filtreleme fonksiyonu tanimlar.
- `records: list[RecordT]`: Filtrelenecek kayit listesini alir.
- `project_id: str`: Aranan proje kimligini alir.
- `-> list[RecordT]`: Eslesen kayitlardan olusan yeni liste dondurur.
- `return [`: Liste uretmeye baslar.
- `record for record in records`: Kayitlari tek tek gezer.
- `hasattr(record, "project_id")`: Kayitta `project_id` alani var mi diye kontrol eder.
- `record.project_id == project_id`: Alan varsa degerin aranan proje kimligiyle ayni olup olmadigina bakar.

### Sunu yaptik / Boyle yaptik / Cunku / Boylece

- Sunu yaptik: Kayitlari proje kimligine gore filtreledik.
- Boyle yaptik: Once `hasattr` ile alan var mi kontrol ettik, sonra degeri karsilastirdik.
- Cunku: Liste icinde `project_id` alani olmayan dummy veya farkli nesneler olabilir.
- Boylece: Fonksiyon hata vermeden sadece uygun kayitlari secer.

### Santiye karsiligi

Bu fonksiyon, karisik evraklar arasindan sadece belirli santiyenin dosya numarasina ait olanlari ayirmaya benzer.

### Test kodu ve testin neyi dogruladigi

```python
def test_filter_records_by_project_id_returns_matching_records() -> None:
    records = [
        DailySiteLog(log_id="log-001", project_id="prj-001", date="2026-06-05"),
        DailySiteLog(log_id="log-002", project_id="prj-002", date="2026-06-05"),
        TrackingRecord(
            record_id="trk-001",
            project_id="prj-001",
            title="Demir kontrolu",
            description="Donati kontrol edildi.",
            date="2026-06-05",
        ),
    ]

    result = filter_records_by_project_id(records, "prj-001")

    assert len(result) == 2
    assert result[0].project_id == "prj-001"
    assert result[1].project_id == "prj-001"
```

Bu test, farkli projelerin kayitlari ayni listede olsa bile sadece `prj-001` kayitlarinin dondugunu dogrular.

```python
def test_filter_records_by_project_id_ignores_records_without_project_id() -> None:
    records = [
        DummyRecord(),
        DailySiteLog(log_id="log-001", project_id="prj-001", date="2026-06-05"),
    ]

    result = filter_records_by_project_id(records, "prj-001")

    assert len(result) == 1
    assert result[0].project_id == "prj-001"
```

Bu test, `project_id` alani olmayan dummy nesnenin hata vermeden yok sayildigini dogrular.

## Fonksiyon 4: filter_records_by_status

### Fonksiyon kod blogu

```python
def filter_records_by_status(records: list[RecordT], status: str) -> list[RecordT]:
    return [
        record
        for record in records
        if hasattr(record, "status") and record.status == status
    ]
```

### Satir satir aciklama

- `def filter_records_by_status(...)`: Duruma gore filtreleme fonksiyonu tanimlar.
- `records: list[RecordT]`: Filtrelenecek listeyi alir.
- `status: str`: Aranan durum degerini alir.
- `-> list[RecordT]`: Eslesen kayitlari liste olarak dondurur.
- `hasattr(record, "status")`: Kayitta `status` alani var mi diye kontrol eder.
- `record.status == status`: Alan varsa degerin aranan durumla ayni olup olmadigina bakar.

### Sunu yaptik / Boyle yaptik / Cunku / Boylece

- Sunu yaptik: Kayitlari durum bilgisine gore filtreledik.
- Boyle yaptik: `status` alani olan kayitlari aranan durumla karsilastirdik.
- Cunku: Taslak, acik, kapali veya onaylanmis kayitlari ayri gormek gerekir.
- Boylece: Santiye sefi sadece ilgilendigi durumdaki kayitlara odaklanabilir.

### Santiye karsiligi

Bu fonksiyon, evraklari "taslak", "onaylandi" veya "kapandi" etiketlerine gore ayirmaya benzer.

### Test kodu ve testin neyi dogruladigi

```python
def test_filter_records_by_status_returns_matching_records() -> None:
    records = [
        DailySiteLog(log_id="log-001", project_id="prj-001", date="2026-06-05"),
        DailySiteLog(
            log_id="log-002",
            project_id="prj-001",
            date="2026-06-06",
            status="approved",
        ),
        TrackingRecord(
            record_id="trk-001",
            project_id="prj-001",
            title="Beton dokum takibi",
            description="Dokum basladi.",
            date="2026-06-05",
            status="closed",
        ),
    ]

    result = filter_records_by_status(records, "draft")

    assert len(result) == 1
    assert result[0].status == "draft"
```

Bu test, sadece `draft` durumundaki kaydin secildigini dogrular.

```python
def test_filter_records_by_status_ignores_records_without_status() -> None:
    records = [
        DummyRecord(),
        DailySiteLog(log_id="log-001", project_id="prj-001", date="2026-06-05"),
    ]

    result = filter_records_by_status(records, "draft")

    assert len(result) == 1
    assert result[0].status == "draft"
```

Bu test, `status` alani olmayan dummy nesnenin hata vermeden yok sayildigini dogrular.

## Bos liste testi

```python
def test_record_helpers_handle_empty_lists() -> None:
    records = []

    assert list_records(records) == []
    assert count_records(records) == 0
    assert filter_records_by_project_id(records, "prj-001") == []
    assert filter_records_by_status(records, "draft") == []
```

Bu test, tum yardimci fonksiyonlarin bos listeyle hata vermeden calistigini dogrular.

## Kodun calisma akisi

1. Uygulama veya test bir Python listesi olusturur.
2. Liste icine `DailySiteLog`, `TrackingRecord` veya dummy nesne koyabilir.
3. `list_records` listeyi oldugu gibi dondurur.
4. `count_records` listenin uzunlugunu hesaplar.
5. `filter_records_by_project_id` kayitlari proje kimligine gore secer.
6. `filter_records_by_status` kayitlari durum bilgisine gore secer.
7. `hasattr` sayesinde ilgili alan yoksa nesne hata vermeden atlanir.
8. Testler sonucu `assert` ile kontrol eder.

## Teknik karar tablosu

| Sunu yaptik | Boyle yaptik | Cunku | Boylece |
| --- | --- | --- | --- |
| Kayit listeleme ekledik | `list_records` ile listeyi dondurduk | Once en sade listeleme davranisi gerekli | Kayitlar bellek icinde gorulebilir |
| Kayit sayma ekledik | `count_records` ve `len` kullandik | Rapor ve ozetler sayiya ihtiyac duyar | Kac kayit oldugu hesaplanabilir |
| Projeye gore filtreleme ekledik | `filter_records_by_project_id` yazdik | Birden fazla santiye kaydi olabilir | Secilen santiyenin kayitlari ayrilir |
| Duruma gore filtreleme ekledik | `filter_records_by_status` yazdik | Kayitlar farkli durumlarda olabilir | Sadece istenen durumdaki kayitlar gorulur |
| Alan yoksa hata vermemeyi sagladik | `hasattr` kullandik | Listede farkli nesneler olabilir | Fonksiyonlar daha dayanikli calisir |

## Yeni ogrenilen yazilim kavramlari

```text
Bellek ici calisma:
Veriyi dosyaya veya veritabanina yazmadan, program calisirken Python listesi icinde tutmaktir.

Bu projedeki karsiligi:
Kayitlar testlerde liste icinde olusturuldu.

Santiye benzetmesi:
Evraklari kalici arsive kaldirmadan once masada gecici olarak siralamak gibidir.
```

```text
Dummy nesne:
Testte belirli bir davranisi denemek icin kullanilan basit sahte nesnedir.

Bu projedeki karsiligi:
project_id veya status alani olmayan nesnelerin hata uretmedigini denemek icin kullanildi.

Santiye benzetmesi:
Yanlis klasorden gelmis bir kagidi sisteme zarar vermeden kenara ayirmak gibidir.
```

## Bu adimda bilincli olarak ne yapmadik?

Veritabani, JSON kayit sistemi, dosyaya yazma/okuma, API, GUI ve yeni paket eklemedik.

Cunku bu adimin amaci kayit sistemini kurmak degil, Python listesi uzerinde temel listeleme ve filtreleme davranisini sade sekilde oturtmaktir.

## Mini sozluk

`Fonksiyon`: Belirli bir isi yapan adlandirilmis kod parcasi.

`Liste`: Birden fazla degeri sirali sekilde tutan Python yapisi.

`Bellek ici calisma`: Veriyi sadece program calisirken listede tutma yaklasimi.

`Filtreleme`: Liste icinden belirli kosula uyan kayitlari secme islemi.

`hasattr`: Bir nesnede belirli alan var mi diye kontrol eden Python fonksiyonu.

`Dummy nesne`: Test icin kullanilan basit sahte nesne.

`Saf yardimci fonksiyon`: Dis sisteme dokunmadan verilen girdiden sonuc ureten yardimci fonksiyon.

## Sonraki adima baglanti

Bellek ici listeleme davranisi netlestigi icin sonraki adimlarda bu kayitlar uzerinden arsivleme, raporlama veya daha ayrintili saha takip ozetleri kurulabilir.
