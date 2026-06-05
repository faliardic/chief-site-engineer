# Adim 018 - SiteNoteRecord Modeli Ogrenim Notu

## 1. Revizyon Sebebi

Onceki Adim 018 onerisi `ContactPersonRecord` uzerineydi. Ancak projede `ContactPersonRecord` zaten Adim 013 kapsaminda bulunuyordu.

Bu nedenle ayni isimle ikinci model eklemek yerine Adim 018, saha notu kaydi olarak revize edildi.

## 2. Bu Adimda Ne Ogreniyoruz?

Bu adimda, santiye sefinin sahada aldigi kisa notlari sade bir Python veri modeliyle temsil etmeyi ogreniyoruz.

Amac, notlari tam bir gorev veya hatirlatici sistemine donusturmek degil, saha notu bilgisinin hangi alanlarla kayda alinacagini netlestirmektir.

## 3. Santiye Problemi

Santiye sefi sahada gezerken kucuk notlar alir. Bu notlar bir gozlem, uyari, hatirlatma veya serbest aciklama olabilir.

Bu bilgiler kaybolursa, kucuk saha detaylari unutulabilir. Sade bir saha notu kaydi, ileride gorev adayi, gunluk rapor, denetim veya uygunsuzluk sureclerine temel olabilir.

## 4. Model Kodu

```python
@dataclass
class SiteNoteRecord:
    """Represents a simple site note record."""

    note_title: str
    note_type: str | None = None
    location: str | None = None
    related_subject: str | None = None
    note_date: str | None = None
    status: str = "open"
    notes: str | None = None
```

## 5. Model Kodunun Satir Satir Aciklamasi

- `@dataclass`: Python'a bu class'in veri tasiyan sade bir model oldugunu soyler.
- `class SiteNoteRecord:` saha notu kaydi icin yeni model tanimlar.
- `"""Represents a simple site note record."""`: Modelin neyi temsil ettigini kisa olarak aciklar.
- `note_title: str`: Saha notunun basligini zorunlu alan olarak tutar.
- `note_type: str | None = None`: Not turunu opsiyonel tutar.
- `location: str | None = None`: Notun ilgili oldugu saha konumunu opsiyonel tutar.
- `related_subject: str | None = None`: Notun ilgili oldugu konu veya is basligini opsiyonel tutar.
- `note_date: str | None = None`: Not tarihini opsiyonel tutar.
- `status: str = "open"` saha notunu varsayilan olarak acik durumda baslatir.
- `notes: str | None = None`: Serbest not alanini opsiyonel tutar.

Sunu yaptik: Saha notu bilgisini `SiteNoteRecord` adli ayri bir veri modeliyle tanimladik.

Boyle yaptik: Not basligini zorunlu, not turu, konum, ilgili konu, tarih ve notlari opsiyonel tuttuk.

Cunku: Ilk kayit aninda sadece not basligi kesin bilinebilir; diger bilgiler saha ilerledikce tamamlanabilir.

Boylece: Santiye sefi sade bir saha notu acabilir ve ileride bu kaydi gorev, gunluk rapor veya denetim surecleriyle baglayabilir.

## 6. Test Kodu

```python
def test_site_note_record_holds_values_and_defaults() -> None:
    site_note = SiteNoteRecord(
        note_title="Kuzey cephe iskele kontrolu",
        note_type="uyari",
        location="A Blok kuzey cephe",
        related_subject="Iskele guvenligi",
        note_date="2026-06-05",
    )

    assert site_note.note_title == "Kuzey cephe iskele kontrolu"
    assert site_note.note_type == "uyari"
    assert site_note.location == "A Blok kuzey cephe"
    assert site_note.related_subject == "Iskele guvenligi"
    assert site_note.note_date == "2026-06-05"
    assert site_note.notes is None
    assert site_note.status == "open"
```

## 7. Test Kodunun Satir Satir Aciklamasi

- `def test_site_note_record_holds_values_and_defaults() -> None:` test fonksiyonunu tanimlar.
- `site_note = SiteNoteRecord(...)` test icin bir saha notu kaydi olusturur.
- `note_title="Kuzey cephe iskele kontrolu"` not basliginin kayda verilebildigini gosterir.
- `note_type="uyari"` not turunun tutuldugunu gosterir.
- `location="A Blok kuzey cephe"` konum bilgisinin tutuldugunu test eder.
- `related_subject="Iskele guvenligi"` ilgili konunun tutuldugunu test eder.
- `note_date="2026-06-05"` not tarihinin tutuldugunu test eder.
- `assert site_note.notes is None` not verilmediginde varsayilan degerin `None` oldugunu kontrol eder.
- `assert site_note.status == "open"` durum alaninin varsayilan olarak `open` geldigini kontrol eder.

## 8. Teknik Karar Tablosu

| Karar | Boyle Yapildi | Cunku | Boylece |
| --- | --- | --- | --- |
| Iletisim kisisi yerine saha notu kapsami secildi | `SiteNoteRecord` eklendi | `ContactPersonRecord` zaten mevcut | Model isim cakismasi onlendi |
| Saha notu modeli ayri tutuldu | Not bilgisi ayri dataclass oldu | Kucuk saha gozlemleri farkli sureclere temel olabilir | Ileride farkli kayitlarla baglanabilir |
| Not basligi zorunlu yapildi | `note_title: str` kullanildi | Basliksiz not kaydi anlamli olmaz | En azindan notun konusu bilinir |
| Detay alanlari opsiyonel tutuldu | `str | None` kullanildi | Ilk anda tum saha bilgileri bilinmeyebilir | Kayit erken acilabilir |
| Iliski kurulmadi | Baska modele referans eklenmedi | Bu adim sadece model baslangici | Mimari sade kalir |

## 9. Neden Gorev Yonetimi / Hatirlatici / Bildirim / Gunluk Rapor / Denetim / Uygunsuzluk Sistemi Kurmadik?

Gorev yonetimi, hatirlatici, bildirim, gunluk rapor, denetim ve uygunsuzluk sistemleri sorumlu kisi, tarih takibi, atama, oncelik, bildirim kanallari, form alanlari ve belge ekleri gibi daha detayli kurallar ister.

Bu adimda henuz bu kurallari tasarlamiyoruz. Once santiyede saha notu bilgisinin hangi alanlarla temsil edilecegini netlestiriyoruz.

## 10. Mini Sozluk

`Saha notu kaydi`: Santiyede gorulen kisa not, gozlem, uyari veya hatirlatmanin kayit altina alinmis hali.

`SiteNoteRecord`: Saha notu bilgisini temsil eden Python veri modeli.

`note_title`: Saha notunun kisa basligini tutan alan.

`note_type`: Notun turunu tutan alan.

`related_subject`: Notun ilgili oldugu konu veya is basligini tutan alan.

`note_date`: Notun alindigi tarihi tutan alan.

`open`: Saha notunun acik durumda oldugunu belirten durum.

`Gorev yonetimi`: Islerin sorumlu, tarih ve durum kurallariyla yonetildigi sistem.

`Hatirlatici sistemi`: Kullaniciya belirli zamanda hatirlatma veren sistem.

## 11. Sonraki Kucuk Adim Onerisi

Sonraki kucuk adim olarak Adim 019'da basit gorev adayi kayit modeli baslatilabilir.
