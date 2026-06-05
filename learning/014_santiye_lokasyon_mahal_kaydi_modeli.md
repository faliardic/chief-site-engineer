# Adim 014 - Santiye Lokasyon / Mahal Kayit Modeli

## Amac

Bu adimin amaci, santiyedeki blok, kat, mahal, aks, cephe, bolge veya calisma alanlarini ileride kayitlarla iliskilendirebilmek icin sade bir veri modeli olusturmaktir.

## Bu Adimda Ne Eklendi?

`app/models.py` icine `SiteLocationRecord` modeli eklendi. `tests/test_models.py` icine bu modelin alanlarini ve varsayilan degerlerini kontrol eden test eklendi.

## Cozulen Santiye Problemi

Sahadaki kayitlar cogu zaman belirli bir yere baglidir. Bir uygunsuzluk, malzeme kullanimi, kontrol, fotograf veya gunluk not hangi blokta, hangi katta ya da hangi mahalde oldugunu belirtmelidir. Bu model, lokasyon bilgisini tek ve sade bir kayit olarak dusunmeye baslar.

## Santiye Lokasyonu / Mahal Nedir?

Santiye lokasyonu veya mahal; sahadaki belirli calisma alanini anlatir. Ornek olarak A Blok, 3. Kat, bodrum otopark, kuzey cephe, merdiven kovasi veya belirli aks araligi bir lokasyon olabilir.

## SiteLocationRecord Model Kodu

```python
@dataclass
class SiteLocationRecord:
    """Represents a site location or work area."""

    location_name: str
    block: str | None = None
    floor: str | None = None
    zone: str | None = None
    axis: str | None = None
    discipline: str | None = None
    description: str | None = None
    status: str = "active"
    notes: str | None = None
```

## SiteLocationRecord Kodunun Satir Satir Aciklamasi

- `@dataclass`: Python'a bu class'in veri tasiyan sade bir model oldugunu soyler.
- `class SiteLocationRecord:` santiye lokasyon veya mahal kaydi icin yeni model tanimlar.
- `location_name: str`: Mahal veya calisma alani adini zorunlu alan olarak tutar.
- `block: str | None = None`: Blok bilgisini opsiyonel tutar.
- `floor: str | None = None`: Kat bilgisini opsiyonel tutar.
- `zone: str | None = None`: Bolge, mahal veya calisma alani bilgisini opsiyonel tutar.
- `axis: str | None = None`: Aks bilgisini opsiyonel tutar.
- `discipline: str | None = None`: Ilgili disiplini opsiyonel tutar.
- `description: str | None = None`: Lokasyon aciklamasini opsiyonel tutar.
- `status: str = "active"` kaydi varsayilan olarak aktif durumda baslatir.
- `notes: str | None = None`: Serbest aciklama alanini opsiyonel tutar.

Sunu yaptik: Lokasyon bilgisini `SiteLocationRecord` modeliyle ayri tanimladik.

Boyle yaptik: Lokasyon adini zorunlu, blok/kat/bolge/aks gibi detaylari opsiyonel tuttuk.

Cunku: Ilk kayit aninda sadece mahal adi bilinebilir; detaylar daha sonra netlesebilir.

Boylece: Sade bir lokasyon kaydi acilabilir ve ileride diger kayitlarla baglanabilecek temel olusur.

## Test Kodu

```python
def test_site_location_record_holds_values_and_defaults() -> None:
    location = SiteLocationRecord(
        location_name="A Blok 3. Kat Kuzey Cephe",
        block="A Blok",
        floor="3. Kat",
        zone="Kuzey cephe",
        axis="A-B / 1-4",
        discipline="Mimari",
        description="Cephe kaplama calisma alani",
    )

    assert location.location_name == "A Blok 3. Kat Kuzey Cephe"
    assert location.block == "A Blok"
    assert location.floor == "3. Kat"
    assert location.zone == "Kuzey cephe"
    assert location.axis == "A-B / 1-4"
    assert location.discipline == "Mimari"
    assert location.description == "Cephe kaplama calisma alani"
    assert location.notes is None
    assert location.status == "active"
```

## Testin Satir Satir Aciklamasi

- `location = SiteLocationRecord(...)`: Yeni lokasyon kaydi nesnesi olusturur.
- `location_name="A Blok 3. Kat Kuzey Cephe"`: Lokasyon adini verir.
- `block="A Blok"`: Blok bilgisini verir.
- `floor="3. Kat"`: Kat bilgisini verir.
- `zone="Kuzey cephe"`: Bolge veya cephe bilgisini verir.
- `axis="A-B / 1-4"`: Aks araligini verir.
- `discipline="Mimari"`: Ilgili disiplini verir.
- `description="Cephe kaplama calisma alani"`: Lokasyon aciklamasini verir.
- `assert location.notes is None`: Not girilmediginde alanin bos kalabildigini kontrol eder.
- `assert location.status == "active"`: Lokasyon kaydinin varsayilan olarak aktif basladigini kontrol eder.

Bu test; alan adlari degisirse, opsiyonel not alani beklenenden farkli baslarsa veya `status` varsayilani bozulursa hatayi yakalar.

## Teknik Karar Tablosu

| Sunu yaptik | Boyle yaptik | Cunku | Boylece |
| --- | --- | --- | --- |
| Lokasyon modelini ayri tuttuk | `SiteLocationRecord` dataclass yazdik | Saha kayitlari belirli alanlara baglanmak ister | Lokasyon bilgisi tek nesnede temsil edilir |
| Lokasyon adini zorunlu tuttuk | `location_name: str` yazdik | Her lokasyonun okunabilir bir adi olmali | Kayit tek basina anlasilir olur |
| Detaylari opsiyonel tuttuk | `block`, `floor`, `zone`, `axis` alanlarini `str | None` yaptik | Her projede ayni lokasyon detayi olmayabilir | Model farkli santiye tiplerine uyumlu kalir |
| Gercek lokasyon sistemi kurmadik | Sadece veri alanlari tanimladik | Kat plani, harita ve hiyerarsi daha buyuk kapsamdir | Adim kucuk ve test edilebilir kalir |

## Neden Gercek Lokasyon Yonetim Sistemi Kurmadik?

Gercek lokasyon yonetimi kat plani, harita, mahal hiyerarsisi, arama/filtreleme, veri kaliciligi ve arayuz gerektirir. Bu adimda once lokasyon bilgisinin hangi alanlardan olusacagini netlestirdik.

## SiteLocationRecord Ileride Hangi Modellerle Birlesebilir?

`SiteLocationRecord` ileride uygunsuzluk, gunluk rapor, malzeme, toplanti aksiyonu, RFI/Submittal, fotograf/ek ve kontrol kayitlariyla baglanabilir. Bu adimda kod seviyesinde boyle bir bag kurulmaz.

## Mini Sozluk

`Santiye lokasyonu`: Santiyede belirli bir blok, kat, mahal, cephe veya calisma alani.

`Mahal kaydi`: Bir saha alaninin kayit altina alinmis hali.

`SiteLocationRecord`: Santiye lokasyon veya mahal bilgisini temsil eden veri modeli.

`location_name`: Lokasyon veya mahal adini tutan alan.

`block`: Blok bilgisini tutan alan.

`floor`: Kat bilgisini tutan alan.

`zone`: Bolge veya calisma alani bilgisini tutan alan.

`axis`: Aks bilgisini tutan alan.

`discipline`: Ilgili is disiplinini tutan alan.

`Blok`: Projedeki ana yapi bolumu.

`Kat`: Yapidaki dusey seviye.

`Mahal`: Yapida belirli oda, alan veya bolge.

`Aks`: Projede konum belirlemek icin kullanilan referans cizgisi veya araligi.

`Disiplin`: Betonarme, mimari, mekanik, elektrik gibi is alani.

`Calisma alani`: Sahada is yapilan belirli bolge.

## Sonraki Kucuk Adim

Adim 015 icin onerilen konu: Basit ekip/iscilik kayit modeli baslangici. Bu adimda Adim 015 uygulamasina gecilmedi.
