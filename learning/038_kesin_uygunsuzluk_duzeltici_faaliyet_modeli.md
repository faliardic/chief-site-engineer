# Adim 038 - NonconformityCorrectiveActionRecord Modeli Ogrenim Notu

## Model Ne Ise Yarar?

`NonconformityCorrectiveActionRecord`, kesin uygunsuzluk / NCR kaydi icin planlanan duzeltici faaliyeti temsil eder.

Bu model, problemi kaydetmekten farkli olarak problemin nasil giderilecegini anlatan faaliyet bilgisini tutar.

## Duzeltici Faaliyet Ile Uygunsuzluk Kaydi Arasindaki Fark

`NonconformityRecord`, uygunsuzlugun kendisini anlatir. Problem nedir, nerede ortaya cikti, kim tespit etti ve mevcut durumu nedir gibi bilgileri tasir.

`NonconformityCorrectiveActionRecord`, bu probleme karsi uygulanacak faaliyeti anlatir. Ne yapilacak, kim sorumlu, ne zaman baslayacak, ne zamana kadar tamamlanacak ve dogrulama gerekecek mi sorularina odaklanir.

## Dataclass / Model Mantigi

Bu model bir `dataclass` olarak tanimlandi. `dataclass`, veri tutan sade Python siniflari icin kullanilir.

Model davranis calistirmak yerine alanlari duzenli bicimde saklar.

```python
@dataclass
class NonconformityCorrectiveActionRecord:
    """Represents a simple nonconformity corrective action record."""

    nonconformity_id: str
    action_title: str
    action_description: str
    responsible_party: str
    planned_start_date: str
    due_date: str
    completion_date: str | None = None
    verification_required: bool = True
    status: str = "planned"
    notes: str | None = None
```

## Varsayilan Degerler

Modelde su varsayilanlar vardir:

- `verification_required: bool = True`: Duzeltici faaliyet tamamlandiktan sonra dogrulama gerekecegi varsayilir.
- `status: str = "planned"`: Yeni faaliyet kaydi planlanmis durumda baslar.
- `completion_date: str | None = None`: Faaliyet henuz tamamlanmadigi icin tamamlanma tarihi bos kalir.
- `notes: str | None = None`: Ek not verilmezse not alani bos kalir.

## Neden API, GUI veya Otomatik Kapatma Eklenmedi?

Bu adimda amac, once verinin seklini guvenli bicimde tanimlamaktir.

API, GUI veya otomatik kapatma eklemek daha genis is kurallari ister. Faaliyet tamamlandi mi, kim dogrulayacak, hangi durumda NCR kapanacak gibi kararlar sonraki adimlarda ayrica ele alinmalidir.

Bu nedenle Adim 038 sadece model ve test seviyesinde tutuldu.

## Santiye Pratiginde Anlami

Sahada NCR kaydi acildiginda duzeltici faaliyet takibi cok kritiktir. Bir problemin kaydedilmesi kadar, o probleme karsi hangi duzeltmenin planlandigi ve bu duzeltmenin kim tarafindan yapilacagi da bilinmelidir.

`NonconformityCorrectiveActionRecord`, bu takibi baslangic seviyesinde veri haline getirir.

## Testte Ne Kontrol Edildi?

Testte modelin verilen degerleri dogru tuttugu kontrol edildi:

```python
action = NonconformityCorrectiveActionRecord(
    nonconformity_id="NCR-001",
    action_title="Korkuluk eksigini tamamla",
    action_description="Kuzey cephede eksik korkuluk imalati tamamlanacak.",
    responsible_party="Alt yuklenici saha ekibi",
    planned_start_date="2026-06-27",
    due_date="2026-07-02",
)
```

Ayrica `verification_required` alaninin `True`, `status` alaninin `planned`, `completion_date` ve `notes` alanlarinin `None` geldigi dogrulandi.

## Kapsam Disi Birakilanlar

- API
- GUI
- Veritabani sorgusu
- JSON kayit sistemi
- Otomatik kapatma
- Onay akisi
- Bildirim
- Dosya islemi

## Kisa Ozet

Adim 038 ile kesin uygunsuzluk / NCR icin duzeltici faaliyet kaydi modeli eklendi.

Bu model, "Bu NCR icin hangi duzeltici faaliyet yapilacak, kim sorumlu, ne zaman baslayacak, ne zamana kadar tamamlanacak ve dogrulama gerekecek mi?" sorularinin veri seviyesindeki baslangic cevabini verir.
