# Adim 024 - NonconformityCandidateActionRecord Modeli Ogrenim Notu

## 1. Bu Adimda Ne Ogreniyoruz?

Bu adimda, degerlendirilmis bir uygunsuzluk adayi icin alinan basit aksiyon kararini sade bir Python veri modeliyle temsil etmeyi ogreniyoruz.

Amac, gorev atama sistemi, kesin uygunsuzluk yonetimi veya duzeltici faaliyet sureci kurmak degil, degerlendirme sonrasi ilk aksiyon kararinin hangi alanlarla tutulacagini netlestirmektir.

## 2. Modelin Amaci

Sahada fark edilen bir eksik, hata veya risk once uygunsuzluk adayi olarak tutulabilir. Daha sonra bu aday degerlendirilir. Degerlendirme sonucunda bu aday icin bir ilk aksiyon karari alinabilir.

`NonconformityCandidateActionRecord`, bu ilk aksiyon kararini veri modeli olarak temsil eder.

## 3. Model Kodu

```python
@dataclass
class NonconformityCandidateActionRecord:
    """Represents a simple nonconformity candidate action record."""

    candidate_title: str
    review_result: str
    action_decision: str
    action_owner: str
    target_date: str
    action_description: str
    status: str = "planned"
    notes: str | None = None
```

## 4. Model Kodunun Satir Satir Aciklamasi

- `@dataclass`: Python'a bu class'in veri tasiyan sade bir model oldugunu soyler.
- `class NonconformityCandidateActionRecord:` uygunsuzluk adayi aksiyon kaydi icin yeni model tanimlar.
- `"""Represents a simple nonconformity candidate action record."""`: Modelin neyi temsil ettigini kisa olarak aciklar.
- `candidate_title: str`: Aksiyonun bagli oldugu uygunsuzluk adayinin basligini zorunlu alan olarak tutar.
- `review_result: str`: Onceki degerlendirme sonucunu zorunlu alan olarak tutar.
- `action_decision: str`: Alinan karar veya aksiyon turunu zorunlu alan olarak tutar.
- `action_owner: str`: Aksiyondan sorumlu kisi veya ekip bilgisini zorunlu alan olarak tutar.
- `target_date: str`: Aksiyonun hedef tarihini zorunlu alan olarak tutar.
- `action_description: str`: Aksiyonun kisa aciklamasini zorunlu alan olarak tutar.
- `status: str = "planned"` kaydi varsayilan olarak planlanmis durumda baslatir.
- `notes: str | None = None`: Ek not alanini opsiyonel tutar.

Sunu yaptik: Degerlendirilmis uygunsuzluk adayi icin ilk aksiyon kararini `NonconformityCandidateActionRecord` adli ayri bir veri modeliyle tanimladik.

Boyle yaptik: Aday basligi, degerlendirme sonucu, aksiyon karari, sorumlu, hedef tarih ve aciklamayi zorunlu tuttuk.

Cunku: Bir aksiyon karari, ne yapilacagi, kimin sorumlu oldugu ve ne zamana kadar hedeflendigi bilinmeden takip edilebilir olmaz.

Boylece: Santiye sefi degerlendirilmis aday sorun icin ilk karar bilgisini kayda alabilir.

## 5. Test Kodu

```python
def test_nonconformity_candidate_action_record_holds_values_and_defaults() -> None:
    action = NonconformityCandidateActionRecord(
        candidate_title="Kuzey cephe korkuluk eksigi",
        review_result="takip gerekli",
        action_decision="gorev adayi ac",
        action_owner="Saha ekibi",
        target_date="2026-06-10",
        action_description="Korkuluk ara elemani tamamlanacak",
    )

    assert action.candidate_title == "Kuzey cephe korkuluk eksigi"
    assert action.review_result == "takip gerekli"
    assert action.action_decision == "gorev adayi ac"
    assert action.action_owner == "Saha ekibi"
    assert action.target_date == "2026-06-10"
    assert action.action_description == "Korkuluk ara elemani tamamlanacak"
    assert action.status == "planned"
    assert action.notes is None
```

## 6. Test Kodunun Satir Satir Aciklamasi

- `def test_nonconformity_candidate_action_record_holds_values_and_defaults() -> None:` yeni test fonksiyonunu tanimlar.
- `action = NonconformityCandidateActionRecord(...)` test icin bir uygunsuzluk adayi aksiyon kaydi olusturur.
- `candidate_title="Kuzey cephe korkuluk eksigi"` aksiyonun hangi aday kayda bagli oldugunu gosterir.
- `review_result="takip gerekli"` onceki degerlendirme sonucunu verir.
- `action_decision="gorev adayi ac"` alinan aksiyon kararini verir.
- `action_owner="Saha ekibi"` aksiyondan sorumlu kisi veya ekibi verir.
- `target_date="2026-06-10"` hedef tarihi verir.
- `action_description="Korkuluk ara elemani tamamlanacak"` aksiyonun kisa aciklamasini verir.
- `assert action.candidate_title == ...` aday basliginin modelde tutuldugunu dogrular.
- `assert action.review_result == ...` degerlendirme sonucunun tutuldugunu dogrular.
- `assert action.action_decision == ...` aksiyon kararinin tutuldugunu dogrular.
- `assert action.action_owner == ...` aksiyon sorumlusunun tutuldugunu dogrular.
- `assert action.target_date == ...` hedef tarihin tutuldugunu dogrular.
- `assert action.action_description == ...` aksiyon aciklamasinin tutuldugunu dogrular.
- `assert action.status == "planned"` durum alaninin varsayilan olarak `planned` geldigini kontrol eder.
- `assert action.notes is None` not verilmediginde varsayilan degerin `None` oldugunu kontrol eder.

## 7. Teknik Karar Tablosu

| Karar | Boyle Yapildi | Cunku | Boylece |
| --- | --- | --- | --- |
| Aksiyon kaydi ayri model yapildi | `NonconformityCandidateActionRecord` eklendi | Degerlendirme karari ile sonraki aksiyon karari farkli bilgilerdir | Kapsam net kalir |
| Degerlendirme sonucu tutuldu | `review_result: str` kullanildi | Aksiyonun hangi degerlendirme sonucundan dogdugu bilinmelidir | Karar zinciri okunabilir olur |
| Aksiyon karari zorunlu tutuldu | `action_decision: str` kullanildi | Aksiyon kaydi ne yapilacagini belirtmelidir | Kayit anlamli olur |
| Sorumlu bilgisi zorunlu tutuldu | `action_owner: str` kullanildi | Aksiyonun kime veya hangi ekibe ait oldugu bilinmelidir | Takip zemini olusur |
| Hedef tarih zorunlu tutuldu | `target_date: str` kullanildi | Aksiyonun zaman hedefi olmalidir | Erteleme ve takip icin temel bilgi olusur |
| Durum sade tutuldu | `status: str = "planned"` kullanildi | Bu adimda takip akisi kurulmaz | Model basit kalir |

## 8. Mini Sozluk

`NonconformityCandidateActionRecord`: Degerlendirilmis uygunsuzluk adayi icin basit aksiyon kararini temsil eden Python veri modeli.

`candidate_title`: Aksiyonun bagli oldugu uygunsuzluk adayinin kisa basligini tutan alan.

`review_result`: Onceki degerlendirme sonucunu tutan alan.

`action_decision`: Alinan karar veya aksiyon turunu tutan alan.

`action_owner`: Aksiyondan sorumlu kisi veya ekip bilgisini tutan alan.

`target_date`: Aksiyonun hedef tarihini tutan alan.

`action_description`: Aksiyonun kisa aciklamasini tutan alan.

`planned`: Aksiyon kaydinin planlanmis durumda oldugunu anlatan varsayilan durum degeri.

## 9. Bu Adimda Ozellikle Eklenmeyenler

Bu adimda veritabani eklenmedi.

Bu adimda JSON kayit sistemi eklenmedi.

Bu adimda API eklenmedi.

Bu adimda GUI eklenmedi.

Bu adimda dosya/fotograf eki eklenmedi.

Bu adimda kesin uygunsuzluk yonetimi baslatilmadi.

Bu adimda duzeltici faaliyet sistemi kurulmadı.

Bu adimda gorev atama veya takip akisi kurulmadı.

Bu adim yalnizca degerlendirilen uygunsuzluk adayi icin basit aksiyon kararini tutan veri modelini ekler.
