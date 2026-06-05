# Adim 017 - SupplierRecord Modeli Ogrenim Notu

## 1. Revizyon Sebebi

Onceki Adim 017 onerisi `MaterialRecord` uzerineydi. Ancak projede `MaterialRecord` zaten Adim 009 kapsaminda bulunuyordu.

Bu nedenle ayni isimle ikinci model eklemek yerine Adim 017, tedarikci ve hizmet saglayici firma kaydi olarak revize edildi.

## 2. Bu Adimda Ne Ogreniyoruz?

Bu adimda, santiyede calisilan tedarikci ve hizmet saglayici firmalari sade bir Python veri modeliyle temsil etmeyi ogreniyoruz.

Amac, tedarikci takibini tam bir satin alma sistemine donusturmek degil, firma bilgisinin hangi alanlarla kayda alinacagini netlestirmektir.

## 3. Santiye Problemi

Santiyede malzeme tedarikcileri, ekipman kiralama firmalari, taseronlar ve hizmet saglayicilarla surekli iletisim kurulur.

Santiye sefi hangi firmanin hangi hizmet alaninda calistigini, kiminle iletisim kurulacagini ve firmanin kayit durumunu bilmek ister. Bu bilgi ileride satin alma, sozlesme, odeme veya performans sureclerine temel olabilir.

## 4. Model Kodu

```python
@dataclass
class SupplierRecord:
    """Represents a supplier or service provider record."""

    supplier_name: str
    supplier_type: str | None = None
    contact_person: str | None = None
    phone: str | None = None
    email: str | None = None
    service_area: str | None = None
    status: str = "active"
    notes: str | None = None
```

## 5. Model Kodunun Satir Satir Aciklamasi

- `@dataclass`: Python'a bu class'in veri tasiyan sade bir model oldugunu soyler.
- `class SupplierRecord:` tedarikci veya hizmet saglayici firma kaydi icin yeni model tanimlar.
- `"""Represents a supplier or service provider record."""`: Modelin neyi temsil ettigini kisa olarak aciklar.
- `supplier_name: str`: Tedarikci adini zorunlu alan olarak tutar.
- `supplier_type: str | None = None`: Tedarikci turunu opsiyonel tutar.
- `contact_person: str | None = None`: Iletisim kurulacak kisi bilgisini opsiyonel tutar.
- `phone: str | None = None`: Telefon bilgisini opsiyonel tutar.
- `email: str | None = None`: E-posta bilgisini opsiyonel tutar.
- `service_area: str | None = None`: Hizmet veya is kapsamini opsiyonel tutar.
- `status: str = "active"` tedarikci kaydini varsayilan olarak aktif durumda baslatir.
- `notes: str | None = None`: Serbest not alanini opsiyonel tutar.

Sunu yaptik: Tedarikci bilgisini `SupplierRecord` adli ayri bir veri modeliyle tanimladik.

Boyle yaptik: Tedarikci adini zorunlu, tur, iletisim kisisi, telefon, e-posta, hizmet alani ve notlari opsiyonel tuttuk.

Cunku: Ilk kayit aninda sadece firma adi kesin bilinebilir; diger bilgiler saha ilerledikce tamamlanabilir.

Boylece: Santiye sefi sade bir tedarikci kaydi acabilir ve ileride bu kaydi satin alma veya sozlesme surecleriyle baglayabilir.

## 6. Test Kodu

```python
def test_supplier_record_holds_values_and_defaults() -> None:
    supplier = SupplierRecord(
        supplier_name="ABC Beton",
        supplier_type="malzeme tedarikcisi",
        contact_person="Ayse Demir",
        phone="+90 212 111 22 33",
        email="ayse.demir@example.com",
        service_area="Hazir beton tedariki",
    )

    assert supplier.supplier_name == "ABC Beton"
    assert supplier.supplier_type == "malzeme tedarikcisi"
    assert supplier.contact_person == "Ayse Demir"
    assert supplier.phone == "+90 212 111 22 33"
    assert supplier.email == "ayse.demir@example.com"
    assert supplier.service_area == "Hazir beton tedariki"
    assert supplier.notes is None
    assert supplier.status == "active"
```

## 7. Test Kodunun Satir Satir Aciklamasi

- `def test_supplier_record_holds_values_and_defaults() -> None:` test fonksiyonunu tanimlar.
- `supplier = SupplierRecord(...)` test icin bir tedarikci kaydi olusturur.
- `supplier_name="ABC Beton"` tedarikci adinin kayda verilebildigini gosterir.
- `supplier_type="malzeme tedarikcisi"` tedarikci turunun tutuldugunu gosterir.
- `contact_person="Ayse Demir"` iletisim kurulacak kisinin tutuldugunu test eder.
- `phone="+90 212 111 22 33"` telefon bilgisinin tutuldugunu test eder.
- `email="ayse.demir@example.com"` e-posta bilgisinin tutuldugunu test eder.
- `service_area="Hazir beton tedariki"` hizmet alaninin tutuldugunu test eder.
- `assert supplier.notes is None` not verilmediginde varsayilan degerin `None` oldugunu kontrol eder.
- `assert supplier.status == "active"` durum alaninin varsayilan olarak `active` geldigini kontrol eder.

## 8. Teknik Karar Tablosu

| Karar | Boyle Yapildi | Cunku | Boylece |
| --- | --- | --- | --- |
| Malzeme yerine tedarikci kapsami secildi | `SupplierRecord` eklendi | `MaterialRecord` zaten mevcut | Model isim cakismasi onlendi |
| Tedarikci modeli ayri tutuldu | Firma bilgisi ayri dataclass oldu | Tedarikci bilgisi birden cok surece temel olabilir | Ileride farkli kayitlarla baglanabilir |
| Tedarikci adi zorunlu yapildi | `supplier_name: str` kullanildi | Isimsiz firma kaydi anlamli olmaz | En azindan hangi firmanin kaydedildigi bilinir |
| Detay alanlari opsiyonel tutuldu | `str | None` kullanildi | Ilk anda tum iletisim bilgileri bilinmeyebilir | Kayit erken acilabilir |
| Iliski kurulmadi | Baska modele referans eklenmedi | Bu adim sadece model baslangici | Mimari sade kalir |

## 9. Neden Satin Alma / Sozlesme / Odeme / Fatura / Irsaliye / Cari Hesap Sistemi Kurmadik?

Satin alma, sozlesme, odeme, fatura, irsaliye ve cari hesap sistemleri teklif, onay, sozlesme maddeleri, odeme planlari, belge numaralari, resmi muhasebe surecleri ve mali sorumluluk gibi daha detayli kurallar ister.

Bu adimda henuz bu kurallari tasarlamiyoruz. Once santiyede tedarikci bilgisinin hangi alanlarla temsil edilecegini netlestiriyoruz.

## 10. Mini Sozluk

`Tedarikci kaydi`: Santiyeye malzeme, ekipman veya hizmet saglayan firmanin kayit altina alinmis hali.

`SupplierRecord`: Tedarikci veya hizmet saglayici bilgisini temsil eden Python veri modeli.

`supplier_name`: Tedarikci adini tutan alan.

`supplier_type`: Tedarikci turunu tutan alan.

`contact_person`: Firma tarafinda iletisim kurulacak kisi bilgisini tutan alan.

`service_area`: Firmanin sagladigi hizmet veya is kapsamini tutan alan.

`Hizmet saglayici`: Santiyeye belirli bir hizmet sunan firma.

`Cari hesap`: Bir firma ile finansal borc/alacak hareketlerini izleyen hesap yapisi.

## 11. Sonraki Kucuk Adim Onerisi

Sonraki kucuk adim olarak Adim 018'de basit iletisim kisisi kayit modeli baslatilabilir.
