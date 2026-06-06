# Adim 022 - NonconformityCandidateRecord Modeli Ogrenim Notu

## 1. Bu Adimda Ne Ogreniyoruz?

Bu adimda, santiyede ileride uygunsuzluk kaydina donusebilecek erken asama bilgiyi sade bir Python veri modeliyle temsil etmeyi ogreniyoruz.

Amac, uygunsuzluk yonetimi veya NCR sureci kurmak degil, uygunsuzluk adayi kaydinin hangi alanlarla temsil edilecegini netlestirmektir.

## 2. Santiye Problemi

Santiye sefi sahada bir eksik, hata, risk veya kontrol sonucu notu fark edebilir. Bu bilgi henuz resmi uygunsuzluk olmayabilir, ancak takip edilmek uzere kaybolmadan tutulmalidir.

Basit bir uygunsuzluk adayi kaydi, bu erken asama bilgiyi resmi surec baslatmadan once korur.

## 3. Model Kodu

```python
@dataclass
class NonconformityCandidateRecord:
    """Represents a simple nonconformity candidate record."""

    candidate_title: str
    candidate_type: str | None = None
    location: str | None = None
    observed_issue: str | None = None
    detected_by: str | None = None
    detection_date: str | None = None
    status: str = "open"
    notes: str | None = None
```

## 4. Model Kodunun Satir Satir Aciklamasi

- `@dataclass`: Python'a bu class'in veri tasiyan sade bir model oldugunu soyler.
- `class NonconformityCandidateRecord:` uygunsuzluk adayi kaydi icin yeni model tanimlar.
- `"""Represents a simple nonconformity candidate record."""`: Modelin neyi temsil ettigini kisa olarak aciklar.
- `candidate_title: str`: Uygunsuzluk adayinin basligini zorunlu alan olarak tutar.
- `candidate_type: str | None = None`: Adayin turunu opsiyonel tutar.
- `location: str | None = None`: Aday uygunsuzlugun goruldugu konumu opsiyonel tutar.
- `observed_issue: str | None = None`: Gozlenen sorun veya risk aciklamasini opsiyonel tutar.
- `detected_by: str | None = None`: Adayi fark eden kisi bilgisini opsiyonel metin olarak tutar.
- `detection_date: str | None = None`: Tespit tarihini opsiyonel tutar.
- `status: str = "open"` kaydi varsayilan olarak acik durumda baslatir.
- `notes: str | None = None`: Serbest not alanini opsiyonel tutar.

Sunu yaptik: Uygunsuzluk adayini `NonconformityCandidateRecord` adli ayri bir veri modeliyle tanimladik.

Boyle yaptik: Aday basligini zorunlu, tur, konum, gozlenen sorun, tespit eden kisi, tespit tarihi ve notlari opsiyonel tuttuk.

Cunku: Ilk kayit aninda sadece aday basligi kesin bilinebilir; diger bilgiler daha sonra tamamlanabilir.

Boylece: Santiye sefi resmi uygunsuzluk sureci kurmadan erken asama bir sorunu kayda alabilir.

## 5. Test Kodu

```python
def test_nonconformity_candidate_record_holds_values_and_defaults() -> None:
    candidate = NonconformityCandidateRecord(
        candidate_title="Kuzey cephe korkuluk eksigi",
        candidate_type="eksik",
        location="A Blok kuzey cephe",
        observed_issue="Korkuluk ara elemani eksik goruldu",
        detected_by="Santiye sefi",
        detection_date="2026-06-05",
    )

    assert candidate.candidate_title == "Kuzey cephe korkuluk eksigi"
    assert candidate.candidate_type == "eksik"
    assert candidate.location == "A Blok kuzey cephe"
    assert candidate.observed_issue == "Korkuluk ara elemani eksik goruldu"
    assert candidate.detected_by == "Santiye sefi"
    assert candidate.detection_date == "2026-06-05"
    assert candidate.notes is None
    assert candidate.status == "open"
```

## 6. Test Kodunun Satir Satir Aciklamasi

- `def test_nonconformity_candidate_record_holds_values_and_defaults() -> None:` test fonksiyonunu tanimlar.
- `candidate = NonconformityCandidateRecord(...)` test icin bir uygunsuzluk adayi kaydi olusturur.
- `candidate_title="Kuzey cephe korkuluk eksigi"` aday basliginin kayda verilebildigini gosterir.
- `candidate_type="eksik"` aday turunun tutuldugunu test eder.
- `location="A Blok kuzey cephe"` konum bilgisinin tutuldugunu test eder.
- `observed_issue="Korkuluk ara elemani eksik goruldu"` gozlenen sorun aciklamasinin tutuldugunu test eder.
- `detected_by="Santiye sefi"` tespit eden kisi bilgisinin tutuldugunu test eder.
- `detection_date="2026-06-05"` tespit tarihinin tutuldugunu test eder.
- `assert candidate.notes is None` not verilmediginde varsayilan degerin `None` oldugunu kontrol eder.
- `assert candidate.status == "open"` durum alaninin varsayilan olarak `open` geldigini kontrol eder.

## 7. Teknik Karar Tablosu

| Karar | Boyle Yapildi | Cunku | Boylece |
| --- | --- | --- | --- |
| Uygunsuzluk adayi modeli ayri tutuldu | `NonconformityCandidateRecord` eklendi | Aday kayit resmi uygunsuzluk kaydindan farkli bir kavramdir | Kapsam net kalir |
| Aday basligi zorunlu yapildi | `candidate_title: str` kullanildi | Basliksiz aday kayit anlamli olmaz | En azindan sorun konusu bilinir |
| Tespit eden kisi metin tutuldu | `detected_by: str | None` kullanildi | Bu adimda kisi modeliyle bag kurulmaz | Kod seviyesi iliski eklenmez |
| Durum sade tutuldu | `status: str = "open"` kullanildi | Bu adimda kapatma veya onay akisi kurulmaz | Model basit kalir |
| Iliski kurulmadi | Baska modele referans eklenmedi | Bu adim sadece model baslangici | Mimari sade kalir |

## 8. Neden Uygunsuzluk Yonetimi / NCR / Duzeltici Faaliyet / Sorumlu Atama / Onay / Kapatma / Dosya Eki / Raporlama Sistemi Kurmadik?

Uygunsuzluk yonetimi, NCR sureci, duzeltici faaliyet, sorumlu atama, onay/kapatma is akisi, dosya eki ve raporlama sistemleri durum kurallari, sorumluluklar, tarih takipleri, belge ekleri ve rapor uretimi gibi daha detayli kararlar ister.

Bu adimda henuz bu kurallari tasarlamiyoruz. Once santiyede uygunsuzluk adayi bilgisinin hangi alanlarla temsil edilecegini netlestiriyoruz.

## 9. Mini Sozluk

`Uygunsuzluk adayi kaydi`: Henuz gercek uygunsuzluk kaydi olmayan, ileride uygunsuzluk kaydina donusebilecek gozlem, eksik, hata veya risk bilgisinin kayit altina alinmis hali.

`NonconformityCandidateRecord`: Uygunsuzluk adayi bilgisini temsil eden Python veri modeli.

`candidate_title`: Uygunsuzluk adayinin kisa basligini tutan alan.

`candidate_type`: Uygunsuzluk adayinin turunu tutan alan.

`observed_issue`: Gozlenen sorun veya risk aciklamasini tutan alan.

`detected_by`: Uygunsuzluk adayini fark eden kisi bilgisini tutan alan.

`detection_date`: Uygunsuzluk adayinin fark edildigi veya kaydedildigi tarihi tutan alan.

`NCR sureci`: Uygunsuzlugun resmi adimlarla yonetildigi surec.

## 10. Sonraki Kucuk Adim Onerisi

Sonraki kucuk adim olarak Adim 023'te basit duzeltici faaliyet adayi kayit modeli baslatilabilir.
