# Adim 013 - Proje Tarafi ve Kisi Kayit Modelleri

## Amac

Bu adimin amaci, santiyede yer alan firma, kurum ve iletisim kisilerini ileride takip edebilmek icin sade veri modelleri olusturmaktir.

## Bu Adimda Ne Eklendi?

`app/models.py` icine `ProjectPartyRecord` ve `ContactPersonRecord` modelleri eklendi. `tests/test_models.py` icine bu modellerin alanlarini ve varsayilan degerlerini kontrol eden testler eklendi.

## Cozulen Santiye Problemi

Santiyede isveren, yuklenici, alt yuklenici, yapi denetim, tedarikci ve proje muellifi gibi cok sayida taraf vardir. Ayrica bu taraflarin iletisim kurulacak kisileri bulunur. Bu bilgiler daginik kalirsa sorumluluk ve iletisim takibi zorlasir.

## Proje Tarafi Nedir?

Proje tarafi, santiyede resmi veya teknik rolu olan firma, kurum veya paydastir. Isveren, yuklenici, alt yuklenici, belediye, yapi denetim firmasi veya tedarikci bir proje tarafi olabilir.

## Iletisim Kisisi Nedir?

Iletisim kisisi, proje taraflari icinde veya proje surecinde belirli bir sorumluluk alanindan ulasilacak kisidir. Bu kisi bir saha muhendisi, santiye sefi, kalite sorumlusu, satin alma yetkilisi veya yapi denetim personeli olabilir.

## ProjectPartyRecord Model Kodu

```python
@dataclass
class ProjectPartyRecord:
    """Represents a project party such as an employer or contractor."""

    party_name: str
    party_type: str | None = None
    role: str | None = None
    tax_or_id_no: str | None = None
    phone: str | None = None
    email: str | None = None
    address: str | None = None
    status: str = "active"
    notes: str | None = None
```

## ProjectPartyRecord Kodunun Satir Satir Aciklamasi

- `@dataclass`: Python'a bu class'in veri tasiyan sade bir model oldugunu soyler.
- `class ProjectPartyRecord:` proje tarafi kaydi icin yeni model tanimlar.
- `party_name: str`: Firma, kurum veya taraf adini zorunlu alan olarak tutar.
- `party_type: str | None = None`: Taraf tipini opsiyonel tutar.
- `role: str | None = None`: Projedeki rol bilgisini opsiyonel tutar.
- `tax_or_id_no: str | None = None`: Vergi no, kimlik no veya kurumsal tanimlayiciyi opsiyonel tutar.
- `phone: str | None = None`: Genel telefon bilgisini opsiyonel tutar.
- `email: str | None = None`: Genel e-posta bilgisini opsiyonel tutar.
- `address: str | None = None`: Adres bilgisini opsiyonel tutar.
- `status: str = "active"` kaydi varsayilan olarak aktif durumda baslatir.
- `notes: str | None = None`: Serbest aciklama alanini opsiyonel tutar.

Sunu yaptik: Firma ve kurum taraflarini `ProjectPartyRecord` modeliyle ayri tanimladik.

Boyle yaptik: Taraf adini zorunlu, diger bilgileri opsiyonel alanlar olarak tuttuk.

Cunku: Ilk kayit aninda telefon, e-posta, vergi no veya adres bilgisi bilinmeyebilir.

Boylece: Proje tarafi kaydi erken asamada acilabilir ve detaylar sonra tamamlanabilir.

## ContactPersonRecord Model Kodu

```python
@dataclass
class ContactPersonRecord:
    """Represents a contact person for project communication."""

    full_name: str
    organization: str | None = None
    role: str | None = None
    phone: str | None = None
    email: str | None = None
    responsibility_area: str | None = None
    status: str = "active"
    notes: str | None = None
```

## ContactPersonRecord Kodunun Satir Satir Aciklamasi

- `@dataclass`: Bu class'in sade veri modeli olarak kullanilacagini belirtir.
- `class ContactPersonRecord:` iletisim kisisi kaydi icin yeni model tanimlar.
- `full_name: str`: Kisinin ad soyad bilgisini zorunlu alan olarak tutar.
- `organization: str | None = None`: Kisinin bagli oldugu kurum veya firmayi opsiyonel tutar.
- `role: str | None = None`: Kisinin gorev veya unvan bilgisini opsiyonel tutar.
- `phone: str | None = None`: Telefon bilgisini opsiyonel tutar.
- `email: str | None = None`: E-posta bilgisini opsiyonel tutar.
- `responsibility_area: str | None = None`: Sorumluluk alanini opsiyonel tutar.
- `status: str = "active"` kaydi varsayilan olarak aktif durumda baslatir.
- `notes: str | None = None`: Serbest aciklama alanini opsiyonel tutar.

Sunu yaptik: Kisileri `ContactPersonRecord` modeliyle firma kaydindan ayri tuttuk.

Boyle yaptik: Ad soyadi zorunlu, kurum ve iletisim bilgilerini opsiyonel tuttuk.

Cunku: Kisi bilgisi firma kaydindan once de bilinebilir veya firma iliskisi daha sonra netlesebilir.

Boylece: Iletisim kisisi sade sekilde kaydedilebilir ve ileride firma kaydiyla baglanabilir.

## Test Kodlari

```python
def test_project_party_record_holds_values_and_defaults() -> None:
    party = ProjectPartyRecord(
        party_name="ABC Insaat A.S.",
        party_type="Yuklenici",
        role="Ana yuklenici",
        tax_or_id_no="1234567890",
        phone="+90 212 000 00 00",
        email="info@example.com",
        address="Istanbul",
    )

    assert party.party_name == "ABC Insaat A.S."
    assert party.party_type == "Yuklenici"
    assert party.role == "Ana yuklenici"
    assert party.tax_or_id_no == "1234567890"
    assert party.phone == "+90 212 000 00 00"
    assert party.email == "info@example.com"
    assert party.address == "Istanbul"
    assert party.notes is None
    assert party.status == "active"
```

```python
def test_contact_person_record_holds_values_and_defaults() -> None:
    person = ContactPersonRecord(
        full_name="Ali Yilmaz",
        organization="ABC Insaat A.S.",
        role="Saha muhendisi",
        phone="+90 532 000 00 00",
        email="ali.yilmaz@example.com",
        responsibility_area="Betonarme imalat",
    )

    assert person.full_name == "Ali Yilmaz"
    assert person.organization == "ABC Insaat A.S."
    assert person.role == "Saha muhendisi"
    assert person.phone == "+90 532 000 00 00"
    assert person.email == "ali.yilmaz@example.com"
    assert person.responsibility_area == "Betonarme imalat"
    assert person.notes is None
    assert person.status == "active"
```

## Testlerin Satir Satir Aciklamasi

- `party = ProjectPartyRecord(...)`: Yeni proje tarafi kaydi nesnesi olusturur.
- `party_name="ABC Insaat A.S."`: Firma veya kurum adini verir.
- `party_type="Yuklenici"`: Taraf tipini verir.
- `role="Ana yuklenici"`: Projedeki rolunu verir.
- `tax_or_id_no="1234567890"`: Vergi veya kimlik numarasini metin olarak verir.
- `phone=...`: Genel telefon bilgisini verir.
- `email=...`: Genel e-posta bilgisini verir.
- `address="Istanbul"`: Adres bilgisini verir.
- `assert party.notes is None`: Not girilmediginde alanin bos kalabildigini kontrol eder.
- `assert party.status == "active"`: Taraf kaydinin varsayilan olarak aktif basladigini kontrol eder.
- `person = ContactPersonRecord(...)`: Yeni iletisim kisisi kaydi nesnesi olusturur.
- `full_name="Ali Yilmaz"`: Kisinin ad soyad bilgisini verir.
- `organization="ABC Insaat A.S."`: Kisinin bagli oldugu kurum bilgisini verir.
- `role="Saha muhendisi"`: Gorev veya unvan bilgisini verir.
- `responsibility_area="Betonarme imalat"`: Sorumluluk alanini verir.
- `assert person.notes is None`: Not girilmediginde alanin bos kalabildigini kontrol eder.
- `assert person.status == "active"`: Kisi kaydinin varsayilan olarak aktif basladigini kontrol eder.

Bu testler; alan adlari degisirse, opsiyonel not alani beklenenden farkli baslarsa veya `status` varsayilani bozulursa hatayi yakalar.

## Teknik Karar Tablosu

| Sunu yaptik | Boyle yaptik | Cunku | Boylece |
| --- | --- | --- | --- |
| Proje tarafini ayri tuttuk | `ProjectPartyRecord` dataclass yazdik | Firma ve kurumlar kisi kayitlarindan farkli bilgiler tasir | Proje paydasi tek nesnede temsil edilir |
| Iletisim kisilerini ayri tuttuk | `ContactPersonRecord` dataclass yazdik | Kisiler bir kuruma bagli olabilir ama ayri takip edilmelidir | Kisi bilgisi sade sekilde temsil edilir |
| Dogrulama eklemedik | Telefon, e-posta ve vergi no metin olarak tutuldu | Bu adimda gercek rehber sistemi kurulmayacak | Model sade ve test edilebilir kalir |
| Kod seviyesinde iliski kurmadik | `organization` metinsel alan olarak tutuldu | Veritabani veya iliski sistemi henuz yok | Ileride baglanti kurulabilecek temel olusur |

## Neden Gercek Rehber Sistemi Kurmadik?

Gercek rehber veya CRM sistemi arama, filtreleme, kisi-firma eslestirme, telefon/e-posta dogrulama, yetki, veri kaliciligi ve arayuz gerektirir. Bu adimda once hangi taraf ve kisi bilgilerinin tutulacagini netlestirdik.

## ProjectPartyRecord ile ContactPersonRecord Ileride Nasil Birlesebilir?

Bu adimda `ContactPersonRecord.organization` sadece metinsel bilgi olarak tutulur. Ileride taraf kayitlarina kimlik alani eklenirse, kisi kaydi ilgili `ProjectPartyRecord` kaydina baglanabilir. Boylece bir firmaya ait tum kisiler listelenebilir.

## Bu Modeller Diger CSE Kayitlariyla Ileride Nasil Birlesebilir?

Proje taraflari ve iletisim kisileri ileride RFI, submittal, toplanti aksiyonu, malzeme, uygunsuzluk ve gunluk rapor kayitlarinda sorumlu taraf veya iletisim kisisi olarak kullanilabilir. Bu adimda bu baglanti kod seviyesinde kurulmaz.

## Mini Sozluk

`Proje tarafi`: Projede resmi, teknik veya ticari rolu olan firma, kurum ya da paydas.

`ProjectPartyRecord`: Proje tarafi bilgisini temsil eden veri modeli.

`ContactPersonRecord`: Iletisim kisisi bilgisini temsil eden veri modeli.

`party_name`: Firma, kurum veya taraf adini tutan alan.

`party_type`: Tarafin isveren, yuklenici, tedarikci gibi tipini tutan alan.

`tax_or_id_no`: Vergi no, kimlik no veya kurumsal tanimlayiciyi tutan alan.

`full_name`: Kisinin ad soyad bilgisini tutan alan.

`organization`: Kisinin bagli oldugu firma veya kurum bilgisini tutan alan.

`responsibility_area`: Kisinin sorumluluk alanini tutan alan.

`Iletisim kisisi`: Projede belirli konuda ulasilacak kisi.

`Isveren`: Isi yaptiran taraf.

`Yuklenici`: Isi yapmayi ustlenen ana taraf.

`Alt yuklenici`: Yukleniciye bagli belirli isi yapan firma veya ekip.

`Yapi denetim`: Yapinin uygunlugunu denetleyen kurum veya firma.

`Tedarikci`: Malzeme veya hizmet saglayan firma.

`Sorumluluk alani`: Kisinin projede takip ettigi konu, bolge veya is kalemi.

## Sonraki Kucuk Adim

Adim 014 icin onerilen konu: Basit santiye lokasyon / mahal kayit modeli baslangici. Bu adimda Adim 014 uygulamasina gecilmedi.
