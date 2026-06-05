# Adim 021 - CheckResultRecord Modeli Ogrenim Notu

## 1. Bu Adimda Ne Ogreniyoruz?

Bu adimda, santiyede yapilan kontrollerin basit sonuc bilgisini sade bir Python veri modeliyle temsil etmeyi ogreniyoruz.

Amac, tam bir checklist, denetim veya raporlama sistemi kurmak degil, kontrol sonucu kaydinin hangi alanlarla temsil edilecegini netlestirmektir.

## 2. Santiye Problemi

Santiye sefi sahada kontrol yaptiginda sonucunu kisa ve sade sekilde kaydetmek ister. Bu sonuc uygun olabilir, eksik icerebilir veya tekrar kontrol gerektirebilir.

Bu bilgiler kaybolursa, yapilan kontrollerin temel sonucu takip edilemez. Basit bir kontrol sonucu kaydi, bu bilgiyi erken asamada korur.

## 3. Model Kodu

```python
@dataclass
class CheckResultRecord:
    """Represents a simple check result record."""

    check_title: str
    check_area: str | None = None
    result: str | None = None
    checked_by: str | None = None
    check_date: str | None = None
    status: str = "recorded"
    notes: str | None = None
```

## 4. Model Kodunun Satir Satir Aciklamasi

- `@dataclass`: Python'a bu class'in veri tasiyan sade bir model oldugunu soyler.
- `class CheckResultRecord:` kontrol sonucu kaydi icin yeni model tanimlar.
- `"""Represents a simple check result record."""`: Modelin neyi temsil ettigini kisa olarak aciklar.
- `check_title: str`: Kontrol basligini zorunlu alan olarak tutar.
- `check_area: str | None = None`: Kontrol alanini opsiyonel tutar.
- `result: str | None = None`: Kontrol sonucunu opsiyonel tutar.
- `checked_by: str | None = None`: Kontrolu yapan kisi bilgisini opsiyonel metin olarak tutar.
- `check_date: str | None = None`: Kontrol tarihini opsiyonel tutar.
- `status: str = "recorded"` kontrol sonucunu varsayilan olarak kaydedilmis durumda baslatir.
- `notes: str | None = None`: Serbest not alanini opsiyonel tutar.

Sunu yaptik: Kontrol sonucu bilgisini `CheckResultRecord` adli ayri bir veri modeliyle tanimladik.

Boyle yaptik: Kontrol basligini zorunlu, alan, sonuc, kontrol eden kisi, tarih ve notlari opsiyonel tuttuk.

Cunku: Ilk kayit aninda sadece kontrol basligi kesin bilinebilir; diger bilgiler daha sonra tamamlanabilir.

Boylece: Santiye sefi tam denetim veya checklist sistemi kurmadan kontrol sonucunu kayda alabilir.

## 5. Test Kodu

```python
def test_check_result_record_holds_values_and_defaults() -> None:
    check_result = CheckResultRecord(
        check_title="Kuzey cephe iskele kontrol sonucu",
        check_area="A Blok kuzey cephe",
        result="Uygun",
        checked_by="Santiye sefi",
        check_date="2026-06-05",
    )

    assert check_result.check_title == "Kuzey cephe iskele kontrol sonucu"
    assert check_result.check_area == "A Blok kuzey cephe"
    assert check_result.result == "Uygun"
    assert check_result.checked_by == "Santiye sefi"
    assert check_result.check_date == "2026-06-05"
    assert check_result.notes is None
    assert check_result.status == "recorded"
```

## 6. Test Kodunun Satir Satir Aciklamasi

- `def test_check_result_record_holds_values_and_defaults() -> None:` test fonksiyonunu tanimlar.
- `check_result = CheckResultRecord(...)` test icin bir kontrol sonucu kaydi olusturur.
- `check_title="Kuzey cephe iskele kontrol sonucu"` kontrol basliginin kayda verilebildigini gosterir.
- `check_area="A Blok kuzey cephe"` kontrol alaninin tutuldugunu test eder.
- `result="Uygun"` kontrol sonucunun tutuldugunu test eder.
- `checked_by="Santiye sefi"` kontrolu yapan kisi bilgisinin metin olarak tutuldugunu test eder.
- `check_date="2026-06-05"` kontrol tarihinin tutuldugunu test eder.
- `assert check_result.notes is None` not verilmediginde varsayilan degerin `None` oldugunu kontrol eder.
- `assert check_result.status == "recorded"` durum alaninin varsayilan olarak `recorded` geldigini kontrol eder.

## 7. Teknik Karar Tablosu

| Karar | Boyle Yapildi | Cunku | Boylece |
| --- | --- | --- | --- |
| Kontrol sonucu modeli ayri tutuldu | `CheckResultRecord` eklendi | Sonuc kaydi kontrol maddesinden farkli bir kavramdir | Kapsam net kalir |
| Kontrol basligi zorunlu yapildi | `check_title: str` kullanildi | Basliksiz kontrol sonucu anlamli olmaz | En azindan kontrol konusu bilinir |
| Kontrol eden kisi metin tutuldu | `checked_by: str | None` kullanildi | Bu adimda kisi modeliyle bag kurulmaz | Kod seviyesi iliski eklenmez |
| Sonuc metin tutuldu | `result: str | None` kullanildi | Bu adimda puanlama veya sonuc enum sistemi kurulmaz | Model sade kalir |
| Iliski kurulmadi | Baska modele referans eklenmedi | Bu adim sadece model baslangici | Mimari sade kalir |

## 8. Neden Checklist / Denetim Formu / Uygunsuzluk / Puanlama / Onay Is Akisi / Dosya Eki / Raporlama Sistemi Kurmadik?

Checklist, denetim formu, uygunsuzluk, puanlama, onay is akisi, dosya eki ve raporlama sistemleri form yapisi, sonuc kurallari, puanlama, onay adimlari, belge ekleri ve rapor uretimi gibi daha detayli kararlar ister.

Bu adimda henuz bu kurallari tasarlamiyoruz. Once santiyede kontrol sonucu bilgisinin hangi alanlarla temsil edilecegini netlestiriyoruz.

## 9. Mini Sozluk

`Kontrol sonucu kaydi`: Yapilan bir kontrolun basit sonuc bilgisinin kayit altina alinmis hali.

`CheckResultRecord`: Kontrol sonucu bilgisini temsil eden Python veri modeli.

`check_title`: Yapilan kontrolun kisa basligini tutan alan.

`check_area`: Kontrolun ilgili oldugu saha alani veya konuyu tutan alan.

`result`: Kontrolun basit sonuc bilgisini tutan alan.

`checked_by`: Kontrolu yapan veya kaydi olusturan kisi bilgisini metin olarak tutan alan.

`check_date`: Kontrolun yapildigi veya kaydedildigi tarihi tutan alan.

`recorded`: Kontrol sonucu kaydinin kaydedilmis durumda oldugunu belirten durum.

## 10. Sonraki Kucuk Adim Onerisi

Sonraki kucuk adim olarak Adim 022'de basit uygunsuzluk adayi kayit modeli baslatilabilir.
