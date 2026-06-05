# Adim 009 - Malzeme Kaydi Modeli

## Amac

Bu adimin amaci, santiye sahasina gelen veya sahada kullanilan malzemeleri ileride takip edebilmek icin sade bir veri modeli baslangici olusturmaktir.

## Bu Adimda Ne Eklendi?

`app/models.py` icine `MaterialRecord` modeli eklendi. `tests/test_models.py` icine bu modelin alanlarini ve varsayilan degerlerini kontrol eden test eklendi.

## Cozulen Santiye Problemi

Santiye sefi sahaya hangi malzemenin geldigini, hangi firmadan geldigini, irsaliye numarasini, miktarini, birimini ve hangi alanda kullanildigini takip etmek ister. Bu model, ileride kurulacak malzeme takip sisteminin ilk veri temelidir.

## MaterialRecord Model Kodu

```python
@dataclass
class MaterialRecord:
    """Represents a material entry or usage record."""

    material_name: str
    supplier: str | None = None
    delivery_note_no: str | None = None
    quantity: float | None = None
    unit: str | None = None
    area: str | None = None
    received_date: str | None = None
    used_date: str | None = None
    status: str = "received"
    notes: str | None = None
```

## Kodun Satir Satir Aciklamasi

- `@dataclass`: Python'a bu class'in veri tasiyan sade bir model oldugunu soyler.
- `class MaterialRecord:` malzeme kaydi icin yeni model tanimlar.
- `material_name: str`: Malzeme adini zorunlu alan olarak tutar.
- `supplier: str | None = None`: Tedarikci bilgisini opsiyonel tutar.
- `delivery_note_no: str | None = None`: Irsaliye numarasini opsiyonel tutar.
- `quantity: float | None = None`: Miktari ondalikli sayi olarak opsiyonel tutar.
- `unit: str | None = None`: Malzeme birimini opsiyonel tutar.
- `area: str | None = None`: Malzemenin geldigi veya kullanildigi mahal/alan bilgisini opsiyonel tutar.
- `received_date: str | None = None`: Malzemenin santiye giris tarihini opsiyonel tutar.
- `used_date: str | None = None`: Malzemenin kullanim tarihini opsiyonel tutar.
- `status: str = "received"` kaydi varsayilan olarak teslim alindi durumunda baslatir.
- `notes: str | None = None`: Serbest aciklama alanini opsiyonel tutar.

Sunu yaptik: Malzeme kaydini ayri bir model olarak tanimladik.

Boyle yaptik: Malzeme adi zorunlu, diger saha bilgilerini opsiyonel alanlar olarak tuttuk.

Cunku: Ilk kayit aninda irsaliye, miktar veya kullanim tarihi her zaman tam bilinmeyebilir.

Boylece: Sadece malzeme adiyla basit kayit olusturulabilir, detaylar daha sonra tamamlanabilir.

## Test Kodu

```python
def test_material_record_holds_values_and_defaults() -> None:
    material = MaterialRecord(
        material_name="C30 beton",
        supplier="ABC Beton",
        delivery_note_no="IRS-001",
        quantity=24.5,
        unit="m3",
        area="Temel",
        received_date="2026-06-05",
    )

    assert material.material_name == "C30 beton"
    assert material.supplier == "ABC Beton"
    assert material.delivery_note_no == "IRS-001"
    assert material.quantity == 24.5
    assert material.unit == "m3"
    assert material.area == "Temel"
    assert material.received_date == "2026-06-05"
    assert material.used_date is None
    assert material.notes is None
    assert material.status == "received"
```

## Testin Satir Satir Aciklamasi

- `material = MaterialRecord(...)`: Yeni malzeme kaydi nesnesi olusturur.
- `material_name="C30 beton"`: Malzeme adini verir.
- `supplier="ABC Beton"`: Tedarikci bilgisini verir.
- `delivery_note_no="IRS-001"`: Irsaliye numarasini verir.
- `quantity=24.5`: Miktari ondalikli sayi olarak verir.
- `unit="m3"`: Birimi metrekup olarak verir.
- `area="Temel"`: Malzemenin ilgili alanini verir.
- `received_date="2026-06-05"`: Santiye giris tarihini verir.
- `assert material.material_name == "C30 beton"`: Malzeme adinin dogru saklandigini kontrol eder.
- `assert material.used_date is None`: Kullanim tarihi verilmediyse bos kalabildigini kontrol eder.
- `assert material.notes is None`: Not verilmediyse bos kalabildigini kontrol eder.
- `assert material.status == "received"`: Varsayilan durumun teslim alindi oldugunu kontrol eder.

Bu test; alan adlari yanlis yazilirsa, opsiyonel alanlar beklenenden farkli baslarsa veya `status` varsayilani degisirse hatayi yakalar.

## Teknik Karar Tablosu

| Sunu yaptik | Boyle yaptik | Cunku | Boylece |
| --- | --- | --- | --- |
| Malzeme kaydi modeli ekledik | `MaterialRecord` dataclass yazdik | Malzeme girisleri ileride takip edilmeli | Malzeme bilgisi tek nesnede temsil edilir |
| Gercek stok sistemi kurmadik | Sadece veri alanlari tanimladik | Bu adim kucuk model baslangici olmali | Kod sade ve test edilebilir kalir |
| Irsaliye bilgisini opsiyonel tuttuk | `delivery_note_no: str | None = None` yazdik | Irsaliye ilk anda girilmeyebilir | Kayit eksik bilgiyle baslatilabilir |
| Kullanim tarihini opsiyonel tuttuk | `used_date: str | None = None` yazdik | Malzeme giris aninda henuz kullanilmamis olabilir | Giris ve kullanim ayrimi ileride kurulabilir |

## Neden Gercek Stok Sistemi Kurmadik?

Bu adimda amac stok dusmek, miktar hesaplamak veya depo hareketi yonetmek degildir. Once malzeme kaydinin hangi alanlardan olusacagini netlestirdik. Gercek stok sistemi daha sonra bu model uzerine kurulabilir.

## MaterialRecord ile AttachmentRecord Ileride Nasil Birlesebilir?

`MaterialRecord`, malzemenin temel bilgilerini tutar. `AttachmentRecord` ise dosya eki referansini tutar. Ileride bir irsaliye fotografi veya kalite belgesi `AttachmentRecord.related_model = "MaterialRecord"` ve `related_id` ile malzeme kaydina baglanabilir. Bu adimda kod seviyesinde boyle bir bag kurulmaz.

## Mini Sozluk

`Malzeme kaydi`: Sahaya gelen veya sahada kullanilan malzemeye ait temel takip bilgisi.

`MaterialRecord`: Malzeme giris/kullanim bilgisini temsil eden veri modeli.

`material_name`: Malzeme adini tutan alan.

`supplier`: Malzemeyi saglayan firma.

`delivery_note_no`: Irsaliye numarasini tutan alan.

`quantity`: Malzeme miktari.

`unit`: Malzeme birimi.

`area`: Malzemenin geldigi veya kullanildigi mahal/alan.

`received_date`: Malzemenin santiye giris tarihi.

`used_date`: Malzemenin kullanim tarihi.

`received`: Teslim alindi durumunu anlatan status degeri.

## Sonraki Kucuk Adim

Adim 010 icin iki makul secenek var: Malzeme kaydi kalite kontrolu ve commit, ya da proje akisina gore toplanti/aksiyon kayit modeli baslangici. Bu adimda Adim 010 uygulamasina gecilmedi.
