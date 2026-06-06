# Adim 029 - NonconformityCandidateAssignmentRecord Modeli Ogrenim Notu

## 1. Bu Adimda Ne Ogreniyoruz?

Bu adimda, bir kaydin sorumluluk ve atama bilgisini ayri bir veri modeliyle temsil etmeyi ogreniyoruz.

Uygunsuzluk adayi kaydi olustuktan sonra bu adayla kimin ilgilenecegi, atamayi kimin yaptigi, ne zamana kadar sonuc beklendigi ve oncelik seviyesinin ne oldugu takip edilmelidir.

## 2. Modelin Amaci

`NonconformityCandidateAssignmentRecord`, uygunsuzluk adayinin sorumluluk ve atama bilgisini tutar.

Bu model, "kim takip edecek, kim atadi, hedef tarih nedir, oncelik nedir" sorularina baslangic veri modeliyle cevap verir.

Sunu yaptik: Uygunsuzluk adayi icin sorumluluk / atama modelini ekledik.

Boyle yaptik: Aday kodu, atanan kisi, atayan kisi, atama tarihi, hedef tarih, sorumluluk notu, oncelik ve durum alanlarini kullandik.

Cunku: Bir aday kaydin takip edilmesi icin sorumluluk net olmalidir.

Boylece: Santiye sefi hangi aday kaydin kim tarafindan takip edilecegini kayit seviyesinde gorebilir.

## 3. Model Kodu

```python
@dataclass
class NonconformityCandidateAssignmentRecord:
    """Represents a simple nonconformity candidate assignment record."""

    candidate_id: str
    assigned_to: str
    assigned_by: str
    assignment_date: str
    due_date: str | None = None
    responsibility_note: str | None = None
    priority: str = "normal"
    status: str = "assigned"
    notes: str | None = None
```

## 4. Model Kodunun Satir Satir Aciklamasi

- `@dataclass`: Python'a bu class'in veri tasiyan sade bir model oldugunu soyler.
- `class NonconformityCandidateAssignmentRecord:` uygunsuzluk adayi atama kaydi icin yeni model tanimlar.
- `candidate_id: str`: Atama yapilan aday kaydin kodunu zorunlu alan olarak tutar.
- `assigned_to: str`: Takipten sorumlu kisi veya ekibi zorunlu alan olarak tutar.
- `assigned_by: str`: Atamayi yapan kisiyi zorunlu alan olarak tutar.
- `assignment_date: str`: Atama tarihini zorunlu alan olarak tutar.
- `due_date: str | None = None`: Hedef tarihi opsiyonel tutar.
- `responsibility_note: str | None = None`: Sorumluluk aciklamasini opsiyonel tutar.
- `priority: str = "normal"` onceligi varsayilan olarak `normal` baslatir.
- `status: str = "assigned"` atama kaydini varsayilan olarak atanmis durumda baslatir.
- `notes: str | None = None`: Ek not alanini opsiyonel tutar.

## 5. Test Kodu

```python
def test_nonconformity_candidate_assignment_record_holds_values_and_defaults() -> None:
    assignment = NonconformityCandidateAssignmentRecord(
        candidate_id="NCR-CAND-001",
        assigned_to="Saha muhendisi",
        assigned_by="Santiye sefi",
        assignment_date="2026-06-15",
        due_date="2026-06-18",
        responsibility_note="Korkuluk eksigi sahada takip edilecek.",
        priority="high",
    )

    assert assignment.candidate_id == "NCR-CAND-001"
    assert assignment.assigned_to == "Saha muhendisi"
    assert assignment.assigned_by == "Santiye sefi"
    assert assignment.assignment_date == "2026-06-15"
    assert assignment.due_date == "2026-06-18"
    assert assignment.responsibility_note == "Korkuluk eksigi sahada takip edilecek."
    assert assignment.priority == "high"
    assert assignment.status == "assigned"
    assert assignment.notes is None
```

## 6. Test Kodunun Satir Satir Aciklamasi

- `def test_nonconformity_candidate_assignment_record_holds_values_and_defaults() -> None:` modelin verilen degerleri sakladigini ve varsayilanlari kullandigini test eder.
- `assignment = NonconformityCandidateAssignmentRecord(...)` test icin bir atama kaydi olusturur.
- `candidate_id="NCR-CAND-001"` atama yapilan aday kaydi belirtir.
- `assigned_to="Saha muhendisi"` takibi yapacak kisiyi belirtir.
- `assigned_by="Santiye sefi"` atamayi yapan kisiyi belirtir.
- `assignment_date="2026-06-15"` atama tarihini belirtir.
- `due_date="2026-06-18"` hedef tarihi belirtir.
- `responsibility_note=...` sorumluluk aciklamasini belirtir.
- `priority="high"` atamanin oncelik seviyesini belirtir.
- `assert assignment.status == "assigned"` durumun varsayilan olarak `assigned` geldigini kontrol eder.
- `assert assignment.notes is None` not verilmediginde `None` kaldigini kontrol eder.

## 7. Varsayilan Deger Testi

```python
def test_nonconformity_candidate_assignment_record_optional_fields_default() -> None:
    assignment = NonconformityCandidateAssignmentRecord(
        candidate_id="NCR-CAND-002",
        assigned_to="Kalite sorumlusu",
        assigned_by="Santiye sefi",
        assignment_date="2026-06-16",
    )

    assert assignment.due_date is None
    assert assignment.responsibility_note is None
    assert assignment.priority == "normal"
    assert assignment.status == "assigned"
    assert assignment.notes is None
```

Bu test, hedef tarih ve sorumluluk notu verilmediginde opsiyonel alanlarin `None`, onceligin `normal`, durumun `assigned` kaldigini gosterir.

## 8. Teknik Karar Tablosu

| Karar | Boyle Yapildi | Cunku | Boylece |
| --- | --- | --- | --- |
| Atama bilgisi ayri model yapildi | `NonconformityCandidateAssignmentRecord` eklendi | Sorumluluk bilgisi aday kaydin kendisinden farkli bir takip bilgisidir | Kapsam net kalir |
| Atanan ve atayan kisi tutuldu | `assigned_to` ve `assigned_by` kullanildi | Takibi yapacak kisi ile atamayi yapan kisi ayridir | Sorumluluk okunabilir olur |
| Hedef tarih opsiyonel tutuldu | `due_date: str | None = None` kullanildi | Her atamada hedef tarih ilk anda bilinmeyebilir | Model esnek kalir |
| Oncelik varsayilani belirlendi | `priority: str = "normal"` kullanildi | Atama onceligi verilmezse baslangic degeri gerekir | Test edilebilir varsayilan olusur |

## 9. Mini Sozluk

`NonconformityCandidateAssignmentRecord`: Uygunsuzluk adayinin sorumluluk ve atama bilgisini temsil eden veri modeli.

`Sorumluluk atama kaydi`: Bir kaydin kime, kim tarafindan ve hangi hedef tarihle atandigini gosteren kayit.

`assigned_to`: Takipten sorumlu kisi veya ekip bilgisini tutan alan.

`assigned_by`: Bir kaydi veya takibi atayan kisi bilgisini tutan alan.

`assignment_date`: Atamanin yapildigi tarihi tutan alan.

`responsibility_note`: Atanan kisinin neyi takip edecegini aciklayan sorumluluk notu alani.

`priority`: Kaydin oncelik seviyesini tutan alan.

`assigned`: Kaydin bir kisiye veya ekibe atanmis durumda oldugunu anlatan status degeri.

## 10. Bu Adimda Ozellikle Eklenmeyenler

Bu adimda veritabani sorgusu eklenmedi.

Bu adimda API eklenmedi.

Bu adimda GUI eklenmedi.

Bu adimda otomatik bildirim eklenmedi.

Bu adimda otomatik gorev atama eklenmedi.

Bu adimda JSON kayit sistemi eklenmedi.

Bu adimda dosya islemi eklenmedi.
