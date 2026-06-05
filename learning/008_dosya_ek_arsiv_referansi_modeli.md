# 008 Dosya/Ek Arsiv Referansi Modeli

## Bu adimda ne yaptik?

Bu adimda dosya veya ek arsiv referanslarini temsil eden `AttachmentRecord` modelini ekledik.

Bu model dosyanin kendisini kopyalamaz, tasimaz, silmez veya yuklemez. Sadece dosyaya ait ad, yol, tur ve iliski bilgilerini tutar.

## Neden bunu yaptik?

Uygulama acisindan saha kayitlarinin belgeler ve fotograflarla desteklenmesi gerekir.

Santiye sefi acisindan bu model, "bu fotograf hangi beton dokumune ait?", "bu belge hangi uygunsuzluk kaydina bagli?" gibi sorulara hazirliktir.

## Hangi dosyalara dokunduk?

```text
app/models.py
tests/test_models.py
docs/008_dosya_ek_arsivleme_baslangici.md
learning/008_dosya_ek_arsiv_referansi_modeli.md
learning/GLOSSARY.md
docs/project_decisions.md
CHANGELOG.md
ROADMAP.md
```

`app/models.py`: `AttachmentRecord` veri modelini tutar.

`tests/test_models.py`: Modelin zorunlu alanlari, opsiyonel alanlari ve varsayilan durumunu test eder.

## Kod bloklari uzerinden aciklama

### AttachmentRecord modeli

```python
@dataclass
class AttachmentRecord:
    """Represents a file attachment reference."""

    attachment_id: str
    project_id: str
    title: str
    file_name: str
    file_type: str | None = None
    file_path: str | None = None
    related_model: str | None = None
    related_id: str | None = None
    uploaded_by: str | None = None
    uploaded_date: str | None = None
    notes: str | None = None
    status: str = "active"
```

### Kodun amaci

Bu model, bir dosya ekinin sistem icindeki referans bilgisini temsil eder.

### Satir satir aciklama

- `@dataclass`: Python'a bu class'in veri tasiyan sade bir model oldugunu soyler.
- `class AttachmentRecord:` dosya eki referansi icin yeni model tanimlar.
- `attachment_id: str`: Ek kaydinin benzersiz kimligini tutar.
- `project_id: str`: Ekin hangi projeye ait oldugunu belirtir.
- `title: str`: Ekin okunabilir basligini tutar.
- `file_name: str`: Dosyanin adini tutar.
- `file_type: str | None = None`: Dosya turu girilebilir veya bos kalabilir.
- `file_path: str | None = None`: Dosya yolu girilebilir veya bos kalabilir.
- `related_model: str | None = None`: Ekin hangi modelle iliskili oldugunu tutar.
- `related_id: str | None = None`: Ekin iliskili kayit kimligini tutar.
- `uploaded_by: str | None = None`: Eki yukleyen kisi bilgisi sonra girilebilir.
- `uploaded_date: str | None = None`: Yukleme tarihi sonra girilebilir.
- `notes: str | None = None`: Ek notlar tutulabilir.
- `status: str = "active"` ek kaydini varsayilan olarak aktif baslatir.

### Sunu yaptik / Boyle yaptik / Cunku / Boylece

- Sunu yaptik: Dosya ekini ayri bir referans modeli yaptik.
- Boyle yaptik: Dosyanin adini zorunlu, yolunu ve iliski bilgilerini opsiyonel tuttuk.
- Cunku: Bu adimda gercek dosyayi yonetmiyoruz; sadece kaydini temsil ediyoruz.
- Boylece: Ileride farkli kayitlara dosya ekleri baglanabilir.

### Santiye karsiligi

Bu model, bir evrakin fiziksel klasorde nerede oldugunu ve hangi saha kaydiyla ilgili oldugunu not etmeye benzer.

## Test kodlari uzerinden aciklama

### AttachmentRecord testi

```python
def test_attachment_record_holds_values_and_defaults() -> None:
    attachment = AttachmentRecord(
        attachment_id="att-001",
        project_id="prj-001",
        title="Temel fotografi",
        file_name="temel-fotografi.jpg",
    )

    assert attachment.attachment_id == "att-001"
    assert attachment.project_id == "prj-001"
    assert attachment.title == "Temel fotografi"
    assert attachment.file_name == "temel-fotografi.jpg"
    assert attachment.file_type is None
    assert attachment.file_path is None
    assert attachment.related_model is None
    assert attachment.related_id is None
    assert attachment.uploaded_by is None
    assert attachment.uploaded_date is None
    assert attachment.notes is None
    assert attachment.status == "active"
```

### Testin amaci

Bu test, `AttachmentRecord` modelinin zorunlu alanlarla olustugunu, opsiyonel alanlarin `None` basladigini, `related_model` ve `related_id` alanlarinin bos kalabildigini ve `status` degerinin `"active"` oldugunu dogrular.

### Satir satir aciklama

- `attachment = AttachmentRecord(...)`: Yeni dosya eki referansi olusturur.
- `attachment_id`, `project_id`, `title`, `file_name`: Zorunlu alanlar olarak verilir.
- `assert attachment.attachment_id == ...`: Ek kimligini kontrol eder.
- `assert attachment.project_id == ...`: Proje baglantisini kontrol eder.
- `assert attachment.title == ...`: Basligin dogru saklandigini kontrol eder.
- `assert attachment.file_name == ...`: Dosya adinin dogru saklandigini kontrol eder.
- `assert attachment.file_type is None`: Dosya turu verilmediyse bos kaldigini dogrular.
- `assert attachment.file_path is None`: Dosya yolu verilmediyse bos kaldigini dogrular.
- `assert attachment.related_model is None`: Iliskili model verilmediyse bos kaldigini dogrular.
- `assert attachment.related_id is None`: Iliskili ID verilmediyse bos kaldigini dogrular.
- `assert attachment.uploaded_by is None`: Yukleyen kisi verilmediyse bos kaldigini dogrular.
- `assert attachment.uploaded_date is None`: Yukleme tarihi verilmediyse bos kaldigini dogrular.
- `assert attachment.notes is None`: Not verilmediyse bos kaldigini dogrular.
- `assert attachment.status == "active"` ek kaydinin aktif durumda basladigini kontrol eder.

### Testin hangi hatalari yakalayacagi

- Zorunlu alanlar yanlis attribute'a yazilirsa.
- Opsiyonel alanlar `None` yerine baska varsayilanla baslarsa.
- `related_model` veya `related_id` zorunlu hale getirilirse.
- `status` yanlislikla `"active"` disinda bir degerle baslarsa.

## Kodun calisma akisi

1. Python `AttachmentRecord` class'ini okur.
2. `@dataclass` bu class icin otomatik baslatma yapisi uretir.
3. Test zorunlu alanlari vererek `AttachmentRecord(...)` nesnesi olusturur.
4. Verilen alanlar nesnenin attribute'larina yerlesir.
5. Verilmeyen opsiyonel alanlar `None` olur.
6. `status` verilmedigi icin `"active"` olur.
7. Testler tum alanlari `assert` ile kontrol eder.

## Teknik karar tablosu

| Sunu yaptik | Boyle yaptik | Cunku | Boylece |
| --- | --- | --- | --- |
| Dosya eki modeli ekledik | `AttachmentRecord` dataclass yazdik | Belgeler ve fotograflar kayitlarla iliskilendirilmeli | Ek bilgisi tek nesnede temsil edilir |
| Gercek dosya islemi yapmadik | Sadece `file_name` ve `file_path` alanlari tuttuk | Bu adimda dosya sistemi yonetimi hedef degil | Model sade ve risksiz kalir |
| Iliski alanlari ekledik | `related_model` ve `related_id` kullandik | Ekler farkli kayit tiplerine baglanabilir | Beton, denetim, uygunsuzluk veya gunluk kayda ek baglanabilir |
| Varsayilan status verdik | `status: str = "active"` kullandik | Yeni ek referansi aktif kabul edilmeli | Arsiv kaydi baslangicta kullanilabilir olur |

## Bu adimda bilincli olarak ne yapmadik?

Gercek dosya kopyalama, dosya tasima, dosya silme, dosya yukleme, veritabani, JSON kayit sistemi, API, GUI/web arayuzu, PDF/Excel cikti ve yeni bagimlilik eklemedik.

Cunku bu adimin amaci dosya sistemini yonetmek degil, dosya eklerinin veri referansini netlestirmektir.

## Mini sozluk

`Dosya eki`: Bir kayitla ilgili belge, fotograf veya diger ek.

`Arsiv referansi`: Dosyanin kendisi yerine dosya hakkindaki takip bilgisi.

`AttachmentRecord`: Dosya eki referansini temsil eden veri modeli.

`file_name`: Dosyanin adi.

`file_path`: Dosyanin bulundugu yol.

`file_type`: Dosyanin turu.

`related_model`: Ekin bagli oldugu model adi.

`related_id`: Ekin bagli oldugu kaydin kimligi.

`uploaded_by`: Eki yukleyen kisi.

`uploaded_date`: Ekin yuklendigi tarih.

`active`: Kaydin aktif durumda oldugunu anlatan status degeri.

## Sonraki adima baglanti

Dosya eki referans modeli hazir oldugu icin sonraki adimlarda santiye sefinin ozel notlari, hatirlaticilari veya kayitlara bagli ek gorunumleri daha anlamli sekilde kurulabilir.
