# Adim 037 - NonconformityAssignmentRecord Modeli Ogrenim Notu

## Model Ne Ise Yarar?

`NonconformityAssignmentRecord`, kesin uygunsuzluk / NCR kaydinin hangi kisi, ekip, firma veya sorumlu birime atandigini tutar.

Sahada bir uygunsuzluk kesin kayda donustugunde yalnizca problemin ne oldugunu bilmek yetmez. Bu kaydin kim tarafindan takip edilecegi, kimin atadigi, hangi kapsamda sorumluluk verildigi ve ne zamana kadar sonuc beklendigi de net olmalidir.

## Dataclass / Model Mantigi

Bu model bir `dataclass` olarak tanimlandi. `dataclass`, veri tutan sade Python siniflari icin kullanilir.

Modelin temel gorevi davranis calistirmak degil, bilgiyi duzenli alanlarla saklamaktir.

```python
@dataclass
class NonconformityAssignmentRecord:
    """Represents a simple nonconformity assignment record."""

    nonconformity_id: str
    assigned_to: str
    assigned_role: str
    assigned_by: str
    assigned_date: str
    responsibility_scope: str
    due_date: str | None = None
    status: str = "assigned"
    notes: str | None = None
```

## Varsayilan Degerler

Modelde iki temel varsayilan davranis vardir:

- `status: str = "assigned"`: Yeni atama kaydi varsayilan olarak atanmis durumda baslar.
- `notes: str | None = None`: Ek not verilmezse not alani bos kalir.

`due_date` alani da opsiyoneldir. Her atama icin hemen hedef tarih bilinmeyebilir.

## Neden Sadece Veri Modeli?

Bu adim API veya GUI degildir. Model herhangi bir ekranda veri gostermez, veritabanina kayit yazmaz, bildirim gondermez ve otomatik atama yapmaz.

Amac once verinin seklini guvenli bicimde tanimlamaktir. Daha sonra API, GUI veya is akisi eklenirse bu model temel olabilir.

## Santiye Pratiginde Anlami

Bir NCR acildiginda sorumluluk belirsiz kalirsa takip zayiflar. Saha ekibi problemin farkinda olabilir, kalite ekibi kaydi acmis olabilir, alt yuklenici ise duzeltmeyi yapmak zorunda olabilir.

`NonconformityAssignmentRecord`, "Bu kesin uygunsuzluk kime zimmetlendi ve hangi kapsamda takip edilecek?" sorusunun veri seviyesindeki baslangic cevabini verir.

## Testte Ne Kontrol Edildi?

Testte modelin verilen degerleri dogru tuttugu kontrol edildi:

```python
assignment = NonconformityAssignmentRecord(
    nonconformity_id="NCR-001",
    assigned_to="Saha kalite ekibi",
    assigned_role="quality_team",
    assigned_by="Santiye sefi",
    assigned_date="2026-06-26",
    responsibility_scope="Korkuluk eksiginin saha aksiyonunu takip et.",
    due_date="2026-06-30",
)
```

Ayrica `status` alaninin varsayilan olarak `assigned`, `notes` alaninin varsayilan olarak `None` geldigi dogrulandi.

## Kapsam Disi Birakilanlar

- API
- GUI
- Veritabani sorgusu
- JSON kayit sistemi
- Otomatik atama
- Bildirim
- Onay akisi
- Dosya islemi

## Kisa Ozet

Adim 037 ile kesin uygunsuzluk / NCR surecinde sorumluluk atamasini temsil eden baslangic model eklendi.

Bu model, NCR kaydinin kim tarafindan takip edilecegini ve sorumluluk kapsaminin ne oldugunu sade ve testli bir veri yapisiyla kayit altina alir.
