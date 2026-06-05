# Adim 011 - RFI / Submittal Lite Kayit Modelleri

## Amac

Bu adimin amaci, santiyede teknik soru/cevap ve teknik gonderim/onay sureclerini ileride takip edebilmek icin sade veri modelleri olusturmaktir.

## Bu Adimda Ne Eklendi?

`app/models.py` icine `RFIRecord` ve `SubmittalRecord` modelleri eklendi. `tests/test_models.py` icine bu iki modelin alanlarini ve varsayilan degerlerini kontrol eden testler eklendi.

## Cozulen Santiye Problemi

Santiyede bazen proje detayi belirsiz olur, teknik soru sorulur veya malzeme/urun onaya sunulur. Bu bilgiler daginik e-posta, mesaj veya dosyalarda kalirsa takip zorlasir. Bu adim, teknik soru ve teknik gonderim bilgisini iki sade veri modeliyle baslatir.

## RFI Nedir?

RFI, "Request for Information" ifadesinin kisaltmasidir. Turkce olarak bilgi talebi veya teknik soru gibi dusunulebilir. Santiye tarafinin proje, detay, uygulama veya karar icin resmi soru sormasini temsil eder.

## Submittal Nedir?

Submittal, bir malzeme, urun, teknik foy, cizim veya belgeyi inceleme/onay icin sunma kaydidir. Bu adimda sadece gonderim bilgisinin veri modeli kurulur.

## RFIRecord Model Kodu

```python
@dataclass
class RFIRecord:
    """Represents a request for information record."""

    subject: str
    question: str | None = None
    requested_by: str | None = None
    assigned_to: str | None = None
    request_date: str | None = None
    due_date: str | None = None
    answer: str | None = None
    status: str = "open"
    notes: str | None = None
```

## RFIRecord Kodunun Satir Satir Aciklamasi

- `@dataclass`: Python'a bu class'in veri tasiyan sade bir model oldugunu soyler.
- `class RFIRecord:` RFI kaydi icin yeni model tanimlar.
- `subject: str`: RFI konusunu zorunlu alan olarak tutar.
- `question: str | None = None`: Teknik soru veya aciklama talebini opsiyonel tutar.
- `requested_by: str | None = None`: Soruyu olusturan kisi veya tarafi opsiyonel tutar.
- `assigned_to: str | None = None`: Cevaplamasi beklenen kisi veya tarafi opsiyonel tutar.
- `request_date: str | None = None`: Soru tarihini opsiyonel tutar.
- `due_date: str | None = None`: Cevap icin hedef tarihi opsiyonel tutar.
- `answer: str | None = None`: Gelen cevabi opsiyonel tutar.
- `status: str = "open"` kaydi varsayilan olarak acik durumda baslatir.
- `notes: str | None = None`: Serbest aciklama alanini opsiyonel tutar.

Sunu yaptik: Teknik soru kaydini `RFIRecord` modeliyle ayri tanimladik.

Boyle yaptik: Konuyu zorunlu, soru/cevap/tarih/sorumlu alanlarini opsiyonel tuttuk.

Cunku: Ilk kayit aninda cevap, termin veya atanacak taraf henuz net olmayabilir.

Boylece: RFI kaydi erken asamada acilabilir ve detaylar sonra tamamlanabilir.

## SubmittalRecord Model Kodu

```python
@dataclass
class SubmittalRecord:
    """Represents a technical submission record."""

    subject: str
    submitted_by: str | None = None
    submitted_to: str | None = None
    submit_date: str | None = None
    review_due_date: str | None = None
    response: str | None = None
    status: str = "submitted"
    notes: str | None = None
```

## SubmittalRecord Kodunun Satir Satir Aciklamasi

- `@dataclass`: Bu class'in sade veri modeli olarak kullanilacagini belirtir.
- `class SubmittalRecord:` teknik gonderim kaydi icin yeni model tanimlar.
- `subject: str`: Gonderim konusunu zorunlu alan olarak tutar.
- `submitted_by: str | None = None`: Gonderen kisi veya tarafi opsiyonel tutar.
- `submitted_to: str | None = None`: Inceleyen veya onaylayan tarafi opsiyonel tutar.
- `submit_date: str | None = None`: Gonderim tarihini opsiyonel tutar.
- `review_due_date: str | None = None`: Inceleme hedef tarihini opsiyonel tutar.
- `response: str | None = None`: Inceleme cevabini opsiyonel tutar.
- `status: str = "submitted"` kaydi varsayilan olarak gonderildi durumunda baslatir.
- `notes: str | None = None`: Serbest aciklama alanini opsiyonel tutar.

Sunu yaptik: Teknik gonderim kaydini `SubmittalRecord` modeliyle ayri tanimladik.

Boyle yaptik: Konuyu zorunlu, taraf/tarih/cevap alanlarini opsiyonel tuttuk.

Cunku: Teknik gonderim ilk olustugunda inceleme cevabi veya hedef tarih henuz bilinmeyebilir.

Boylece: Submittal kaydi sade sekilde baslatilabilir ve surec bilgileri sonra eklenebilir.

## Test Kodlari

```python
def test_rfi_record_holds_values_and_defaults() -> None:
    rfi = RFIRecord(
        subject="Temel drenaj detayi",
        question="Drenaj borusu kotu nasil uygulanacak?",
        requested_by="Santiye sefi",
        assigned_to="Proje muellifi",
        request_date="2026-06-05",
        due_date="2026-06-12",
    )

    assert rfi.subject == "Temel drenaj detayi"
    assert rfi.question == "Drenaj borusu kotu nasil uygulanacak?"
    assert rfi.requested_by == "Santiye sefi"
    assert rfi.assigned_to == "Proje muellifi"
    assert rfi.request_date == "2026-06-05"
    assert rfi.due_date == "2026-06-12"
    assert rfi.answer is None
    assert rfi.notes is None
    assert rfi.status == "open"
```

```python
def test_submittal_record_holds_values_and_defaults() -> None:
    submittal = SubmittalRecord(
        subject="Seramik teknik foyi",
        submitted_by="Yuklenici",
        submitted_to="Isveren temsilcisi",
        submit_date="2026-06-05",
        review_due_date="2026-06-12",
    )

    assert submittal.subject == "Seramik teknik foyi"
    assert submittal.submitted_by == "Yuklenici"
    assert submittal.submitted_to == "Isveren temsilcisi"
    assert submittal.submit_date == "2026-06-05"
    assert submittal.review_due_date == "2026-06-12"
    assert submittal.response is None
    assert submittal.notes is None
    assert submittal.status == "submitted"
```

## Testlerin Satir Satir Aciklamasi

- `rfi = RFIRecord(...)`: Yeni RFI kaydi nesnesi olusturur.
- `subject="Temel drenaj detayi"`: RFI konusunu verir.
- `question=...`: Teknik soruyu verir.
- `requested_by="Santiye sefi"`: Soruyu olusturan tarafi verir.
- `assigned_to="Proje muellifi"`: Cevaplamasi beklenen tarafi verir.
- `request_date="2026-06-05"`: Soru tarihini verir.
- `due_date="2026-06-12"`: Hedef cevap tarihini verir.
- `assert rfi.answer is None`: Cevap gelmediginde alanin bos kalabildigini kontrol eder.
- `assert rfi.notes is None`: Not girilmediginde alanin bos kalabildigini kontrol eder.
- `assert rfi.status == "open"`: RFI kaydinin varsayilan olarak acik basladigini kontrol eder.
- `submittal = SubmittalRecord(...)`: Yeni teknik gonderim kaydi nesnesi olusturur.
- `subject="Seramik teknik foyi"`: Gonderim konusunu verir.
- `submitted_by="Yuklenici"`: Gonderen tarafi verir.
- `submitted_to="Isveren temsilcisi"`: Inceleyen veya onaylayan tarafi verir.
- `submit_date="2026-06-05"`: Gonderim tarihini verir.
- `review_due_date="2026-06-12"`: Inceleme hedef tarihini verir.
- `assert submittal.response is None`: Cevap gelmediginde alanin bos kalabildigini kontrol eder.
- `assert submittal.notes is None`: Not girilmediginde alanin bos kalabildigini kontrol eder.
- `assert submittal.status == "submitted"`: Submittal kaydinin varsayilan olarak gonderildi basladigini kontrol eder.

Bu testler; alan adlari degisirse, opsiyonel alanlar beklenenden farkli baslarsa veya varsayilan durum degerleri bozulursa hatayi yakalar.

## Teknik Karar Tablosu

| Sunu yaptik | Boyle yaptik | Cunku | Boylece |
| --- | --- | --- | --- |
| RFI modelini ayri tuttuk | `RFIRecord` dataclass yazdik | Teknik soru/cevap sureci ayri takip edilmeli | RFI kaydi sade bir nesnede temsil edilir |
| Submittal modelini ayri tuttuk | `SubmittalRecord` dataclass yazdik | Teknik gonderim/onay sureci ayri takip edilmeli | Gonderim kaydi sade bir nesnede temsil edilir |
| Gercek onay akisi kurmadik | Sadece veri alanlari tanimladik | Bu adim kucuk model baslangici olmali | Kod sade ve test edilebilir kalir |
| Ek dosya baglantisi kurmadik | `AttachmentRecord` ile kod iliskisi eklemedik | Dosya sistemi ve iliski mantigi sonraki adim isi | Modeller bagimsiz kalir |

## Neden Gercek Onay Akisi Kurmadik?

Gercek onay akisi; onay, ret, revizyon, e-posta, bildirim, dosya eki, rol ve surec kurallari gerektirir. Bu adimda once teknik soru ve teknik gonderim kayitlarinin hangi alanlardan olusacagini netlestirdik.

## RFIRecord ile AttachmentRecord Ileride Nasil Birlesebilir?

`RFIRecord`, teknik sorunun metinsel bilgisini tutar. Ileride cizim, fotograf veya teknik aciklama dosyasi `AttachmentRecord.related_model = "RFIRecord"` ve `related_id` mantigiyla RFI kaydina baglanabilir. Bu adimda kod seviyesinde boyle bir bag kurulmaz.

## SubmittalRecord ile MaterialRecord Ileride Nasil Birlesebilir?

`SubmittalRecord`, teknik gonderim ve onay bilgisini tutar. Ileride bir malzeme onayi gerekiyorsa, submittal kaydi `MaterialRecord` ile baglanabilir. Boylece malzemenin sahaya girisi ile onay sureci birlikte izlenebilir.

## Mini Sozluk

`RFI`: Teknik bilgi talebi veya resmi soru kaydi.

`Request for Information`: RFI ifadesinin acilimi; bilgi talebi anlamina gelir.

`RFIRecord`: Teknik soru/cevap takibini temsil eden veri modeli.

`Submittal`: Inceleme veya onay icin yapilan teknik gonderim.

`SubmittalRecord`: Teknik gonderim/onay takibini temsil eden veri modeli.

`subject`: Kaydin konusunu tutan alan.

`question`: RFI icindeki teknik soruyu tutan alan.

`requested_by`: RFI kaydini olusturan kisi veya taraf.

`assigned_to`: RFI cevabindan sorumlu kisi veya taraf.

`request_date`: RFI soru tarihini tutan alan.

`submitted_by`: Submittal kaydini gonderen kisi veya taraf.

`submitted_to`: Submittal kaydini inceleyen veya onaylayan taraf.

`submit_date`: Submittal gonderim tarihini tutan alan.

`review_due_date`: Submittal incelemesi icin hedef tarihi tutan alan.

`response`: Inceleme cevabini tutan alan.

`submitted`: Kaydin gonderildi durumunda oldugunu anlatan status degeri.

`Teknik soru`: Proje veya uygulama belirsizligi icin sorulan teknik aciklama talebi.

`Teknik gonderim`: Onay veya inceleme icin sunulan teknik belge, urun veya bilgi.

`Onay sureci`: Bir teknik bilginin incelenip kabul, ret veya revizyon sonucuna baglanmasi.

## Sonraki Kucuk Adim

Adim 012 icin onerilen konu: Gunluk rapor ozet modeli baslangici. Bu adimda Adim 012 uygulamasina gecilmedi.
