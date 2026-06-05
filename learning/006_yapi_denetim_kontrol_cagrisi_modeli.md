# 006 Yapi Denetim Kontrol Cagrisi Modeli

## Bu adimda ne yaptik?

Bu adimda yapi denetim kontrol cagrilarini temsil eden `InspectionRequest` modelini ekledik.

Bu model sadece Python dataclass olarak kuruldu. EBIS, bildirim, takvim, veritabani, JSON, API veya GUI eklenmedi.

## Neden bunu yaptik?

Uygulama acisindan kontrol cagrilari, sahadaki imalatlarin denetim sureciyle baglanmasini saglar.

Santiye sefi acisindan bu model, "hangi kontrolu ne zaman talep ettim, hangi firma gelecek, kontrol sonucu ne oldu?" sorularini duzenli takip etmeye hazirliktir.

## Hangi dosyalara dokunduk?

```text
app/models.py
tests/test_models.py
docs/006_yapi_denetim_kontrol_cagrilari.md
learning/006_yapi_denetim_kontrol_cagrisi_modeli.md
learning/GLOSSARY.md
docs/project_decisions.md
CHANGELOG.md
ROADMAP.md
```

`app/models.py`: `InspectionRequest` veri modelini tutar.

`tests/test_models.py`: Modelin zorunlu alanlari, opsiyonel alanlari ve varsayilan durumunu test eder.

## Kod bloklari uzerinden aciklama

### InspectionRequest modeli

```python
@dataclass
class InspectionRequest:
    """Represents an inspection request sent to a building inspection company."""

    request_id: str
    project_id: str
    requested_date: str
    inspection_type: str
    requested_by: str | None = None
    inspection_company: str | None = None
    related_pour_id: str | None = None
    planned_inspection_date: str | None = None
    completed_date: str | None = None
    result: str | None = None
    notes: str | None = None
    status: str = "requested"
```

### Kodun amaci

Bu model, yapi denetim firmasina yapilan bir kontrol cagrisini yazilim icinde temsil eder.

### Satir satir aciklama

- `@dataclass`: Python'a bu class'in veri tasiyan sade bir model oldugunu soyler.
- `class InspectionRequest:` kontrol cagrisi icin yeni model tanimlar.
- `request_id: str`: Kontrol cagrisi kaydinin benzersiz kimligini tutar.
- `project_id: str`: Cagrinin hangi projeye ait oldugunu belirtir.
- `requested_date: str`: Cagrinin talep edildigi tarihi tutar.
- `inspection_type: str`: Kontrolun tipini tutar.
- `requested_by: str | None = None`: Talep eden kisi girilebilir veya bos kalabilir.
- `inspection_company: str | None = None`: Yapi denetim firmasi girilebilir veya bos kalabilir.
- `related_pour_id: str | None = None`: Cagri bir beton dokumuyle iliskiliyse dokum kimligini tutar.
- `planned_inspection_date: str | None = None`: Planlanan kontrol tarihi sonra girilebilir.
- `completed_date: str | None = None`: Kontrol tamamlaninca tarih girilebilir.
- `result: str | None = None`: Denetim sonucu sonra girilebilir.
- `notes: str | None = None`: Ek notlar tutulabilir.
- `status: str = "requested"` yeni cagrinin varsayilan durumunu talep edildi yapar.

### Sunu yaptik / Boyle yaptik / Cunku / Boylece

- Sunu yaptik: Yapi denetim kontrol cagrisini ayri veri modeli yaptik.
- Boyle yaptik: Talep kimligi, proje, talep tarihi ve kontrol tipini zorunlu alan yaptik.
- Cunku: Kontrol cagrisi bu temel bilgiler olmadan takip edilemez.
- Boylece: Kontrol cagrilari ileride durumuna, tarihine veya iliskili beton dokumune gore izlenebilir.

### Santiye karsiligi

Bu model, santiye sefinin yapi denetim firmasina yaptigi kontrol cagrisini bir takip formuna kaydetmesine benzer.

## Test kodlari uzerinden aciklama

### InspectionRequest testi

```python
def test_inspection_request_holds_values_and_defaults() -> None:
    request = InspectionRequest(
        request_id="insp-001",
        project_id="prj-001",
        requested_date="2026-06-05",
        inspection_type="Temel demir kontrolu",
    )

    assert request.request_id == "insp-001"
    assert request.project_id == "prj-001"
    assert request.requested_date == "2026-06-05"
    assert request.inspection_type == "Temel demir kontrolu"
    assert request.requested_by is None
    assert request.inspection_company is None
    assert request.related_pour_id is None
    assert request.planned_inspection_date is None
    assert request.completed_date is None
    assert request.result is None
    assert request.notes is None
    assert request.status == "requested"
```

### Testin amaci

Bu test, `InspectionRequest` modelinin zorunlu alanlarla olustugunu, opsiyonel alanlarin `None` basladigini, `related_pour_id` alaninin bos kalabildigini ve durumun `"requested"` oldugunu dogrular.

### Satir satir aciklama

- `request = InspectionRequest(...)`: Yeni kontrol cagrisi nesnesi olusturur.
- `request_id`, `project_id`, `requested_date`, `inspection_type`: Zorunlu alanlar olarak verilir.
- `assert request.request_id == ...`: Cagri kimliginin dogru saklandigini kontrol eder.
- `assert request.project_id == ...`: Proje baglantisini kontrol eder.
- `assert request.requested_date == ...`: Talep tarihini kontrol eder.
- `assert request.inspection_type == ...`: Kontrol tipini kontrol eder.
- `assert request.requested_by is None`: Talep eden kisi verilmediyse bos kaldigini dogrular.
- `assert request.inspection_company is None`: Firma verilmediyse bos kaldigini dogrular.
- `assert request.related_pour_id is None`: Iliskili beton dokumu yoksa alanin bos kalabildigini dogrular.
- `assert request.planned_inspection_date is None`: Planlanan kontrol tarihi verilmediyse bos kaldigini dogrular.
- `assert request.completed_date is None`: Tamamlanma tarihi verilmediyse bos kaldigini dogrular.
- `assert request.result is None`: Denetim sonucu henuz yoksa bos kaldigini dogrular.
- `assert request.notes is None`: Not girilmediyse bos kaldigini dogrular.
- `assert request.status == "requested"` cagrinin talep edildi durumunda basladigini kontrol eder.

### Testin hangi hatalari yakalayacagi

- Zorunlu alanlar yanlis attribute'a yazilirsa.
- Opsiyonel alanlar `None` yerine baska varsayilanla baslarsa.
- `related_pour_id` zorunlu hale getirilirse.
- `status` yanlislikla `"requested"` disinda bir degerle baslarsa.

## Kodun calisma akisi

1. Python `InspectionRequest` class'ini okur.
2. `@dataclass` bu class icin otomatik baslatma yapisi uretir.
3. Test zorunlu alanlari vererek `InspectionRequest(...)` nesnesi olusturur.
4. Verilen alanlar nesnenin attribute'larina yerlesir.
5. Verilmeyen opsiyonel alanlar `None` olur.
6. `status` verilmedigi icin `"requested"` olur.
7. Testler tum alanlari `assert` ile kontrol eder.

## Teknik karar tablosu

| Sunu yaptik | Boyle yaptik | Cunku | Boylece |
| --- | --- | --- | --- |
| Kontrol cagrisi modeli ekledik | `InspectionRequest` dataclass yazdik | Yapi denetim cagrilari ayri takip edilmeli | Cagri bilgisi tek nesnede temsil edilir |
| Beton dokum baglantisini opsiyonel tuttuk | `related_pour_id: str | None = None` yazdik | Her kontrol beton dokumuyle ilgili olmayabilir | Model hem betonlu hem betonsuz kontrolleri tasir |
| Varsayilan status verdik | `status: str = "requested"` kullandik | Yeni cagri tamamlanmis sayilmamali | Cagri talep edildi durumunda baslar |
| Entegrasyon eklemedik | EBIS, bildirim ve takvim kurmadik | Once veri sekli netlesmeli | Model sade ve test edilebilir kalir |

## Bu adimda bilincli olarak ne yapmadik?

Veritabani, JSON kayit sistemi, EBIS baglantisi, API, GUI/web arayuzu, bildirim sistemi, takvim entegrasyonu, PDF/Excel cikti, dosya yukleme ve yeni bagimlilik eklemedik.

Cunku bu adimin amaci yapi denetim surecini tamamen otomatiklestirmek degil, kontrol cagrisi verisinin seklini netlestirmektir.

## Mini sozluk

`Yapi denetim`: Yapinin proje ve mevzuata uygunlugunu kontrol eden denetim sureci.

`Kontrol cagrisi`: Belirli bir saha kontrolu icin yapi denetim firmasina yapilan talep.

`InspectionRequest`: Kontrol cagrisini temsil eden veri modeli.

`inspection_type`: Kontrolun tipini belirten alan.

`requested_date`: Cagrinin talep edildigi tarih.

`planned_inspection_date`: Kontrolun planlanan tarihi.

`completed_date`: Kontrolun tamamlandigi tarih.

`related_pour_id`: Kontrol cagrisinin iliskili beton dokumu kimligi.

`requested`: Talep edildi durumunu anlatan status degeri.

`result`: Denetim sonucunu tutan alan.

`Denetim sonucu`: Kontrolun olumlu, olumsuz veya notlu sonuc bilgisi.

`Iliskili kayit`: Bir kaydin baska bir kayitla baglantisini anlatan bilgi.

## Sonraki adima baglanti

Yapi denetim kontrol cagrisi modeli hazir oldugu icin sonraki adimda uygunsuzluk kayitlari veya kontrol sonucuna bagli takip davranislari daha anlamli sekilde kurulabilir.
