# Adim 016 - EquipmentRecord Modeli Ogrenim Notu

## 1. Bu Adimda Ne Ogreniyoruz?

Bu adimda, santiyede kullanilan ekipman, makine ve araclari sade bir Python veri modeliyle temsil etmeyi ogreniyoruz.

Amac, ekipman takibini tam bir sisteme donusturmek degil, ekipman bilgisinin hangi alanlarla kayda alinacagini netlestirmektir.

## 2. Santiye Problemi

Santiyede kule vinc, ekskavator, beton pompasi, jeneretor, kamyonet, kompresor veya olcum cihazi gibi farkli ekipmanlar bulunabilir.

Santiye sefi bu ekipmanlarin adini, turunu, sahibini, seri/plaka bilgisini, nerede kullanildigini ve kimin sorumlulugunda oldugunu bilmek ister. Bu bilgi ileride gunluk rapor, lokasyon takibi, ekip koordinasyonu ve bakim sureclerine temel olabilir.

## 3. Model Kodu

```python
@dataclass
class EquipmentRecord:
    """Represents a site equipment or machine record."""

    equipment_name: str
    equipment_type: str | None = None
    owner_company: str | None = None
    serial_or_plate: str | None = None
    work_area: str | None = None
    assigned_to: str | None = None
    status: str = "available"
    notes: str | None = None
```

## 4. Model Kodunun Satir Satir Aciklamasi

- `@dataclass`: Python'a bu class'in veri tasiyan sade bir model oldugunu soyler.
- `class EquipmentRecord:` ekipman veya makine kaydi icin yeni model tanimlar.
- `"""Represents a site equipment or machine record."""`: Modelin neyi temsil ettigini kisa olarak aciklar.
- `equipment_name: str`: Ekipman adini zorunlu alan olarak tutar.
- `equipment_type: str | None = None`: Ekipman turunu opsiyonel tutar.
- `owner_company: str | None = None`: Sahip firma veya kiralama sirketi bilgisini opsiyonel tutar.
- `serial_or_plate: str | None = None`: Seri numarasi veya plaka bilgisini opsiyonel tutar.
- `work_area: str | None = None`: Ekipmanin bulundugu veya calistigi alani opsiyonel tutar.
- `assigned_to: str | None = None`: Ekipmandan sorumlu kisi, ekip veya firma bilgisini opsiyonel tutar.
- `status: str = "available"` ekipman kaydini varsayilan olarak kullanilabilir durumda baslatir.
- `notes: str | None = None`: Serbest not alanini opsiyonel tutar.

Sunu yaptik: Ekipman bilgisini `EquipmentRecord` adli ayri bir veri modeliyle tanimladik.

Boyle yaptik: Ekipman adini zorunlu, ekipman turu, sahip firma, seri/plaka, calisma alani, sorumlu ve notlari opsiyonel tuttuk.

Cunku: Ilk kayit aninda sadece ekipman adi kesin bilinebilir; diger bilgiler saha ilerledikce tamamlanabilir.

Boylece: Santiye sefi sade bir ekipman kaydi acabilir ve ileride bu kaydi gunluk rapor, lokasyon veya bakim bilgisiyle baglayabilir.

## 5. Test Kodu

```python
def test_equipment_record_holds_values_and_defaults() -> None:
    equipment = EquipmentRecord(
        equipment_name="Kule vinc",
        equipment_type="vinc",
        owner_company="ABC Makine Kiralama",
        serial_or_plate="KV-34-001",
        work_area="A Blok saha geneli",
        assigned_to="Kalip ekibi",
    )

    assert equipment.equipment_name == "Kule vinc"
    assert equipment.equipment_type == "vinc"
    assert equipment.owner_company == "ABC Makine Kiralama"
    assert equipment.serial_or_plate == "KV-34-001"
    assert equipment.work_area == "A Blok saha geneli"
    assert equipment.assigned_to == "Kalip ekibi"
    assert equipment.notes is None
    assert equipment.status == "available"
```

## 6. Test Kodunun Satir Satir Aciklamasi

- `def test_equipment_record_holds_values_and_defaults() -> None:` test fonksiyonunu tanimlar.
- `equipment = EquipmentRecord(...)` test icin bir ekipman/makine kaydi olusturur.
- `equipment_name="Kule vinc"` ekipman adinin kayda verilebildigini gosterir.
- `equipment_type="vinc"` ekipman turunun tutuldugunu gosterir.
- `owner_company="ABC Makine Kiralama"` sahip firma bilgisini test eder.
- `serial_or_plate="KV-34-001"` seri veya plaka bilgisinin tutuldugunu test eder.
- `work_area="A Blok saha geneli"` ekipmanin calisma alaninin tutuldugunu test eder.
- `assigned_to="Kalip ekibi"` sorumlu kisi, ekip veya firma bilgisinin tutuldugunu test eder.
- `assert equipment.notes is None` not verilmediginde varsayilan degerin `None` oldugunu kontrol eder.
- `assert equipment.status == "available"` durum alaninin varsayilan olarak `available` geldigini kontrol eder.

## 7. Teknik Karar Tablosu

| Karar | Boyle Yapildi | Cunku | Boylece |
| --- | --- | --- | --- |
| Ekipman modeli ayri tutuldu | `EquipmentRecord` eklendi | Ekipman bilgisi gunluk rapordan daha temel bir veri olabilir | Ileride farkli kayitlarla baglanabilir |
| Ekipman adi zorunlu yapildi | `equipment_name: str` kullanildi | Isimsiz ekipman kaydi anlamli olmaz | En azindan hangi ekipmanin kaydedildigi bilinir |
| Detay alanlari opsiyonel tutuldu | `str | None` kullanildi | Ilk anda tum saha bilgileri bilinmeyebilir | Kayit erken acilabilir |
| Durum varsayilani verildi | `status: str = "available"` kullanildi | Yeni ekipman kaydi genelde kullanilabilir kabul edilir | Ek bilgi girilmeden kullanilabilir |
| Iliski kurulmadi | Baska modele referans eklenmedi | Bu adim sadece model baslangici | Mimari sade kalir |

## 8. Neden Bakim / Yakit / Zimmet Sistemi Kurmadik?

Bakim, yakit ve zimmet sistemleri ariza kaydi, periyodik kontrol, yakit tuketimi, teslim alan kisi, iade sureci, resmi sorumluluk ve maliyet gibi daha detayli kurallar ister.

Bu adimda henuz bu kurallari tasarlamiyoruz. Once santiyede ekipman bilgisinin hangi alanlarla temsil edilecegini netlestiriyoruz.

## 9. Mini Sozluk

`Ekipman kaydi`: Santiyede kullanilan ekipman, makine veya aracin kayit altina alinmis hali.

`Makine kaydi`: Is makinesi veya saha makinesinin temel bilgisini tutan kayit.

`EquipmentRecord`: Ekipman veya makine bilgisini temsil eden Python veri modeli.

`equipment_name`: Ekipman adini tutan alan.

`equipment_type`: Ekipman turunu tutan alan.

`owner_company`: Ekipmanin sahibi olan firma bilgisini tutan alan.

`serial_or_plate`: Seri numarasi veya plaka bilgisini tutan alan.

`assigned_to`: Ekipmandan sorumlu kisi, ekip veya firma bilgisini tutan alan.

`available`: Ekipmanin kullanilabilir durumda oldugunu belirten durum.

`Zimmet`: Bir ekipmanin belirli kisi veya ekibe sorumluluk olarak verilmesi.

## 10. Sonraki Kucuk Adim Onerisi

Sonraki kucuk adim olarak Adim 017'de basit malzeme kayit modeli baslatilabilir.
