# Adim 030 - NonconformityCandidateClosureRecord Modeli Ogrenim Notu

## 1. Bu Adimda Ne Ogreniyoruz?

Bu adimda, bir uygunsuzluk adayinin kapanis ve sonuc bilgisini ayri bir veri modeliyle temsil etmeyi ogreniyoruz.

Uygunsuzluk adayi sureci acik kalabilir, takip gerektirebilir, sahada giderilmis olabilir veya kesin uygunsuzluga donusmesi gerekebilir. Bu karar aninin kim tarafindan ve hangi gerekceyle verildigi kayit altina alinmalidir.

## 2. Modelin Amaci

`NonconformityCandidateClosureRecord`, uygunsuzluk adayinin nasil sonuclandigini tutar.

Bu model, "kapatildi mi, kim kapatti, neden kapatti, takip gerekiyor mu, kesin uygunsuzluga donustu mu" sorularina baslangic veri modeliyle cevap verir.

Sunu yaptik: Uygunsuzluk adayi icin kapanis / sonuc modelini ekledik.

Boyle yaptik: Aday kodu, kapanis karari, kapanis gerekcesi, kapatan kisi, kapanis tarihi, nihai durum, sonuc notu ve takip gerekliligi alanlarini kullandik.

Cunku: Bir aday kaydin sureci tamamlandiginda bunun nedeni ve sonucu kaybolmamalidir.

Boylece: Santiye sefi aday kaydin nasil sonuclandigini geriye donuk okuyabilir.

## 3. Model Kodu

```python
@dataclass
class NonconformityCandidateClosureRecord:
    """Represents a simple nonconformity candidate closure record."""

    candidate_id: str
    closure_decision: str
    closure_reason: str
    closed_by: str
    closure_date: str
    final_status: str
    result_note: str | None = None
    requires_follow_up: bool = False
    notes: str | None = None
```

## 4. Model Kodunun Satir Satir Aciklamasi

- `@dataclass`: Python'a bu class'in veri tasiyan sade bir model oldugunu soyler.
- `class NonconformityCandidateClosureRecord:` uygunsuzluk adayi kapanis kaydi icin yeni model tanimlar.
- `candidate_id: str`: Kapatilan veya sonuclandirilan aday kaydin kodunu zorunlu alan olarak tutar.
- `closure_decision: str`: Aday kaydin nasil sonuclandigini zorunlu alan olarak tutar.
- `closure_reason: str`: Kapanis kararinin gerekcesini zorunlu alan olarak tutar.
- `closed_by: str`: Kaydi kapatan kisiyi zorunlu alan olarak tutar.
- `closure_date: str`: Kapanis tarihini zorunlu alan olarak tutar.
- `final_status: str`: Kapanis sonrasi nihai durumu zorunlu alan olarak tutar.
- `result_note: str | None = None`: Sonuc notunu opsiyonel tutar.
- `requires_follow_up: bool = False`: Kapanis sonrasi takip gerekliligini varsayilan olarak `False` tutar.
- `notes: str | None = None`: Ek not alanini opsiyonel tutar.

## 5. Test Kodu

```python
def test_nonconformity_candidate_closure_record_holds_values_and_defaults() -> None:
    closure = NonconformityCandidateClosureRecord(
        candidate_id="NCR-CAND-001",
        closure_decision="takip tamamlandi",
        closure_reason="Korkuluk eksigi sahada giderildi.",
        closed_by="Santiye sefi",
        closure_date="2026-06-19",
        final_status="closed",
        result_note="Yerinde kontrol sonrasi aday kayit kapatildi.",
        requires_follow_up=True,
    )

    assert closure.candidate_id == "NCR-CAND-001"
    assert closure.closure_decision == "takip tamamlandi"
    assert closure.closure_reason == "Korkuluk eksigi sahada giderildi."
    assert closure.closed_by == "Santiye sefi"
    assert closure.closure_date == "2026-06-19"
    assert closure.final_status == "closed"
    assert closure.result_note == "Yerinde kontrol sonrasi aday kayit kapatildi."
    assert closure.requires_follow_up is True
    assert closure.notes is None
```

## 6. Test Kodunun Satir Satir Aciklamasi

- `def test_nonconformity_candidate_closure_record_holds_values_and_defaults() -> None:` modelin verilen degerleri sakladigini ve not alaninin varsayilanini test eder.
- `closure = NonconformityCandidateClosureRecord(...)` test icin bir kapanis kaydi olusturur.
- `candidate_id="NCR-CAND-001"` kapatilan aday kaydi belirtir.
- `closure_decision="takip tamamlandi"` kapanis kararini belirtir.
- `closure_reason=...` kapanis gerekcesini belirtir.
- `closed_by="Santiye sefi"` kapatan kisiyi belirtir.
- `closure_date="2026-06-19"` kapanis tarihini belirtir.
- `final_status="closed"` nihai durumu belirtir.
- `result_note=...` kapanis sonuc notunu belirtir.
- `requires_follow_up=True` kapanis sonrasi takip gerektigini belirtir.
- `assert closure.notes is None` ek not verilmediginde `None` kaldigini kontrol eder.

## 7. Varsayilan Deger Testi

```python
def test_nonconformity_candidate_closure_record_optional_fields_default() -> None:
    closure = NonconformityCandidateClosureRecord(
        candidate_id="NCR-CAND-002",
        closure_decision="kesin uygunsuzluga donustur",
        closure_reason="Eksik giderilmedigi icin resmi kayit gerekli.",
        closed_by="Kalite sorumlusu",
        closure_date="2026-06-20",
        final_status="converted_to_ncr",
    )

    assert closure.result_note is None
    assert closure.requires_follow_up is False
    assert closure.notes is None
```

Bu test, sonuc notu ve ek not verilmediginde opsiyonel alanlarin `None`, takip gerekliliginin ise `False` basladigini gosterir.

## 8. Teknik Karar Tablosu

| Karar | Boyle Yapildi | Cunku | Boylece |
| --- | --- | --- | --- |
| Kapanis bilgisi ayri model yapildi | `NonconformityCandidateClosureRecord` eklendi | Aday kaydin sonucu baslangic kaydindan farkli bir karar bilgisidir | Kapsam net kalir |
| Karar ve gerekce zorunlu tutuldu | `closure_decision` ve `closure_reason` kullanildi | Kapanis karari gerekcesiz kalmamalidir | Denetim izi guclenir |
| Takip gerekliligi boolean tutuldu | `requires_follow_up: bool = False` kullanildi | Takip gerekir/gerekmez bilgisi ikili karardir | Test edilebilir varsayilan olusur |
| Kesin NCR otomasyonu eklenmedi | Sadece `final_status` metni tutuldu | Bu adim resmi uygunsuzluk olusturma sistemi degildir | Model sade kalir |

## 9. Mini Sozluk

`NonconformityCandidateClosureRecord`: Uygunsuzluk adayinin kapanis ve sonuc bilgisini temsil eden veri modeli.

`Kapanis kaydi`: Bir kaydin nasil sonuclandigini ve kim tarafindan kapatildigini gosteren kayit.

`closure_decision`: Uygunsuzluk adayinin nasil sonuclandigini anlatan karar alani.

`closure_reason`: Kapanis kararinin gerekcesini tutan alan.

`closed_by`: Kaydi kapatan kisi bilgisini tutan alan.

`closure_date`: Kaydin kapatildigi tarihi tutan alan.

`final_status`: Kapanis sonrasi nihai durum bilgisini tutan alan.

`result_note`: Kapanis sonucunu aciklayan not alani.

`requires_follow_up`: Kapanis sonrasinda ek takip gerekip gerekmedigini gosteren boolean alan.

## 10. Bu Adimda Ozellikle Eklenmeyenler

Bu adimda veritabani sorgusu eklenmedi.

Bu adimda API eklenmedi.

Bu adimda GUI eklenmedi.

Bu adimda otomatik kapatma eklenmedi.

Bu adimda otomatik durum guncelleme eklenmedi.

Bu adimda kesin uygunsuzluk/NCR olusturma eklenmedi.

Bu adimda JSON kayit sistemi eklenmedi.

Bu adimda dosya islemi eklenmedi.
