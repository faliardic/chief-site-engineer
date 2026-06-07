# Adim 040 - NonconformityClosureRecord Modeli Ogrenim Notu

## Model Ne Ise Yarar?

`NonconformityClosureRecord`, kesin uygunsuzluk / NCR kaydinin kapanis kararini temsil eder.

Bu model, NCR kaydinin hangi tarihte kapatildigini, kim tarafindan kapatildigini, kapanis sonucunu ve kapanis gerekcesini veri olarak saklar.

## Duzeltici Faaliyet Dogrulamasi Ile NCR Kapatma Arasindaki Fark

`NonconformityCorrectiveActionVerificationRecord`, duzeltici faaliyetin sahada kontrol sonucunu temsil eder.

`NonconformityClosureRecord`, NCR kaydinin resmi kapanis kararini temsil eder.

Yani dogrulama kaydi "faaliyet uygun mu?" sorusuna cevap verir. Kapatma kaydi ise "NCR artik kapatildi mi?" sorusuna cevap verir.

## "Faaliyet Uygun Bulundu" Ile "Uygunsuzluk Kapatildi" Ayrimi

Sahada bir duzeltici faaliyet uygun bulunabilir. Fakat bu bilgi tek basina NCR kaydinin kapatildigi anlamina gelmez.

Kapanis icin yetkili kisinin karari, kapanis tarihi, kapanis gerekcesi ve nihai durum ayrica kayda alinmalidir.

Bu model, bu ayrimi veri seviyesinde net tutar.

## Dataclass / Model Mantigi

Bu model bir `dataclass` olarak tanimlandi. `dataclass`, veri tutan sade Python siniflari icin kullanilir.

Model otomatik kapatma veya onay calistirmaz. Sadece kapanis kararini alanlar halinde saklar.

```python
@dataclass
class NonconformityClosureRecord:
    """Represents a simple nonconformity closure record."""

    nonconformity_id: str
    closure_date: str
    closed_by: str
    closure_result: str
    closure_reason: str
    verified_action_id: str
    final_status: str = "closed"
    requires_follow_up: bool = False
    follow_up_note: str | None = None
    notes: str | None = None
```

## Varsayilan Degerler

Modelde su varsayilanlar vardir:

- `final_status: str = "closed"`: Kapanis kaydi varsayilan olarak kapali nihai durumuyla olusur.
- `requires_follow_up: bool = False`: Varsayilan olarak ek takip gerekmez.
- `follow_up_note: str | None = None`: Takip notu verilmezse bos kalir.
- `notes: str | None = None`: Ek not verilmezse bos kalir.

## Neden API, GUI, Otomatik Kapatma veya Onay Akisi Eklenmedi?

Bu adimda amac, kapanis kararinin veri seklini tanimlamaktir.

Otomatik kapatma veya onay akisi daha genis kurallar ister. Kimin kapatma yetkisi oldugu, hangi dogrulama sonucunun kapatma icin yeterli oldugu ve takip gerektiren durumlarda ne yapilacagi sonraki adimlarda ayrica ele alinmalidir.

Bu nedenle Adim 040 sadece model ve test seviyesinde tutuldu.

## Santiye Pratiginde Kalite Arsivi Acisindan Onemi

NCR kaydi kapatildiginda kalite arsivinde su sorularin cevabi bulunmalidir:

- Kim kapatti?
- Ne zaman kapatti?
- Hangi gerekceyle kapatti?
- Hangi dogrulanmis faaliyete dayanarak kapatti?
- Kapanis sonrasi takip gerekiyor mu?

`NonconformityClosureRecord`, bu cevaplari sade bir veri kaydinda toplar.

## Testte Ne Kontrol Edildi?

Testte modelin verilen degerleri dogru tuttugu kontrol edildi:

```python
closure = NonconformityClosureRecord(
    nonconformity_id="NCR-001",
    closure_date="2026-07-04",
    closed_by="Kalite muduru",
    closure_result="accepted_and_closed",
    closure_reason="Duzeltici faaliyet dogrulandi ve NCR kapatildi.",
    verified_action_id="NCR-CAV-001",
)
```

Ayrica `final_status` alaninin `closed`, `requires_follow_up` alaninin `False`, `follow_up_note` ve `notes` alanlarinin `None` geldigi dogrulandi.

## Kapsam Disi Birakilanlar

- API
- GUI
- Veritabani sorgusu
- JSON kayit sistemi
- Otomatik kapatma
- Otomatik onay
- Bildirim
- Dosya islemi

## Kisa Ozet

Adim 040 ile kesin uygunsuzluk / NCR kapatma modeli eklendi.

Bu model, "Bu NCR kim tarafindan, ne zaman, hangi gerekceyle ve hangi dogrulanmis faaliyete dayanarak kapatildi?" sorusunun veri seviyesindeki baslangic cevabini verir.
