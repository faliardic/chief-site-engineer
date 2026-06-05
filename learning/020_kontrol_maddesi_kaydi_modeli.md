# Adim 020 - ChecklistItemRecord Modeli Ogrenim Notu

## 1. Bu Adimda Ne Ogreniyoruz?

Bu adimda, ileride kontrol listelerine veya denetim formlarina donusebilecek tekil kontrol maddelerini sade bir Python veri modeliyle temsil etmeyi ogreniyoruz.

Amac, tam bir checklist veya denetim sistemi kurmak degil, kontrol maddesi kaydinin hangi alanlarla temsil edilecegini netlestirmektir.

## 2. Santiye Problemi

Santiye sefi sahada kontrol edilmesi gereken tekil maddelerle karsilasir. Bu maddeler bir kalite kontrol noktasi, is guvenligi uyarisi veya saha duzeni konusu olabilir.

Bu bilgiler kaybolursa, ileride olusturulacak checklist veya denetim formlari eksik kalabilir. Basit bir kontrol maddesi kaydi, bu bilgiyi erken asamada korur.

## 3. ChecklistItem ile ChecklistItemRecord Ayrimi

Projede eski `ChecklistItem` modeli vardir. Bu model cekirdek veri modeli adiminda genel checklist ogesini temsil etmek icin eklenmistir.

`ChecklistItemRecord` ise Adim 020 kapsaminda tekil kontrol maddesi kaydini temsil eden daha spesifik bir modeldir. Bu adimda `ChecklistItem` degistirilmez ve iki model arasinda kod seviyesinde bag kurulmaz.

## 4. Model Kodu

```python
@dataclass
class ChecklistItemRecord:
    """Represents a simple checklist item record."""

    item_title: str
    item_category: str | None = None
    related_area: str | None = None
    check_reference: str | None = None
    status: str = "pending"
    notes: str | None = None
```

## 5. Model Kodunun Satir Satir Aciklamasi

- `@dataclass`: Python'a bu class'in veri tasiyan sade bir model oldugunu soyler.
- `class ChecklistItemRecord:` kontrol maddesi kaydi icin yeni model tanimlar.
- `"""Represents a simple checklist item record."""`: Modelin neyi temsil ettigini kisa olarak aciklar.
- `item_title: str`: Kontrol maddesi basligini zorunlu alan olarak tutar.
- `item_category: str | None = None`: Kontrol maddesi kategorisini opsiyonel tutar.
- `related_area: str | None = None`: Ilgili saha alani veya konuyu opsiyonel tutar.
- `check_reference: str | None = None`: Kontrol maddesinin dayandigi referansi opsiyonel tutar.
- `status: str = "pending"` kontrol maddesini varsayilan olarak beklemede baslatir.
- `notes: str | None = None`: Serbest not alanini opsiyonel tutar.

Sunu yaptik: Kontrol maddesi bilgisini `ChecklistItemRecord` adli ayri bir veri modeliyle tanimladik.

Boyle yaptik: Kontrol maddesi basligini zorunlu, kategori, ilgili alan, referans ve notlari opsiyonel tuttuk.

Cunku: Ilk kayit aninda sadece kontrol maddesi basligi kesin bilinebilir; diger bilgiler daha sonra tamamlanabilir.

Boylece: Santiye sefi tam checklist sistemi kurmadan tekil kontrol maddelerini kayda alabilir.

## 6. Test Kodu

```python
def test_checklist_item_record_holds_values_and_defaults() -> None:
    checklist_item = ChecklistItemRecord(
        item_title="Kuzey cephe iskele kontrolu",
        item_category="is guvenligi",
        related_area="A Blok kuzey cephe",
        check_reference="Saha gozlemi",
    )

    assert checklist_item.item_title == "Kuzey cephe iskele kontrolu"
    assert checklist_item.item_category == "is guvenligi"
    assert checklist_item.related_area == "A Blok kuzey cephe"
    assert checklist_item.check_reference == "Saha gozlemi"
    assert checklist_item.notes is None
    assert checklist_item.status == "pending"
```

## 7. Test Kodunun Satir Satir Aciklamasi

- `def test_checklist_item_record_holds_values_and_defaults() -> None:` test fonksiyonunu tanimlar.
- `checklist_item = ChecklistItemRecord(...)` test icin bir kontrol maddesi kaydi olusturur.
- `item_title="Kuzey cephe iskele kontrolu"` kontrol maddesi basliginin kayda verilebildigini gosterir.
- `item_category="is guvenligi"` kontrol maddesi kategorisinin tutuldugunu gosterir.
- `related_area="A Blok kuzey cephe"` ilgili alan bilgisinin tutuldugunu test eder.
- `check_reference="Saha gozlemi"` kontrol referansinin tutuldugunu test eder.
- `assert checklist_item.notes is None` not verilmediginde varsayilan degerin `None` oldugunu kontrol eder.
- `assert checklist_item.status == "pending"` durum alaninin varsayilan olarak `pending` geldigini kontrol eder.

## 8. Teknik Karar Tablosu

| Karar | Boyle Yapildi | Cunku | Boylece |
| --- | --- | --- | --- |
| Eski model korunur | `ChecklistItem` degistirilmedi | Mevcut cekirdek model davranisi bozulmamali | Geriye donuk uyum korunur |
| Yeni kayit modeli ayri tutuldu | `ChecklistItemRecord` eklendi | Adim 020 tekil kontrol maddesi kaydi baslangicidir | Kapsam net kalir |
| Baslik zorunlu yapildi | `item_title: str` kullanildi | Basliksiz kontrol maddesi anlamli olmaz | En azindan kontrol konusu bilinir |
| Referans metin tutuldu | `check_reference: str | None` kullanildi | Bu adimda denetim formu veya belge baglantisi kurulmaz | Kod seviyesi iliski eklenmez |
| Iliski kurulmadi | Baska modele referans eklenmedi | Bu adim sadece model baslangici | Mimari sade kalir |

## 9. Neden Checklist / Denetim Formu / Uygunsuzluk / Puanlama / Onay Is Akisi Sistemi Kurmadik?

Checklist, denetim formu, uygunsuzluk, puanlama ve onay is akisi sistemleri form yapisi, sonuc alanlari, puan kurallari, onay adimlari, belge ekleri ve raporlama gibi daha detayli kararlar ister.

Bu adimda henuz bu kurallari tasarlamiyoruz. Once santiyede tekil kontrol maddesi bilgisinin hangi alanlarla temsil edilecegini netlestiriyoruz.

## 10. Mini Sozluk

`Kontrol maddesi kaydi`: Tekil kontrol maddesinin kayit altina alinmis hali.

`ChecklistItemRecord`: Kontrol maddesi kaydini temsil eden Python veri modeli.

`item_title`: Kontrol maddesinin kisa basligini tutan alan.

`item_category`: Kontrol maddesinin kategorisini tutan alan.

`check_reference`: Kontrol maddesinin dayandigi referansi tutan alan.

`pending`: Kontrol maddesinin beklemede oldugunu belirten durum.

`Checklist sistemi`: Birden fazla kontrol maddesinin liste ve takip kurallariyla yonetildigi sistem.

`Onay is akisi`: Bir kaydin onay adimlari ve durum gecisleriyle ilerledigi surec.

## 11. Sonraki Kucuk Adim Onerisi

Sonraki kucuk adim olarak Adim 021'de basit kontrol sonucu kayit modeli baslatilabilir.
