# Adim 019 - TaskCandidateRecord Modeli Ogrenim Notu

## 1. Bu Adimda Ne Ogreniyoruz?

Bu adimda, santiyede ileride goreve donusebilecek kucuk aksiyon adaylarini sade bir Python veri modeliyle temsil etmeyi ogreniyoruz.

Amac, tam bir gorev yonetimi sistemi kurmak degil, gorev adayinin hangi alanlarla kayda alinacagini netlestirmektir.

## 2. Santiye Problemi

Santiye sefi sahada gezerken veya toplantidan sonra bazi konularin takip edilmesi gerektigini fark eder. Ancak bu konular henuz resmi bir is emri, gorev kaydi veya is akisi olmayabilir.

Basit bir gorev adayi kaydi, bu kucuk aksiyon fikirlerinin kaybolmamasini saglar. Ileride bu adaylar gercek gorev, takvim veya is emri sureclerine temel olabilir.

## 3. Model Kodu

```python
@dataclass
class TaskCandidateRecord:
    """Represents a simple task candidate record."""

    task_title: str
    task_type: str | None = None
    related_area: str | None = None
    source: str | None = None
    target_date: str | None = None
    status: str = "open"
    notes: str | None = None
```

## 4. Model Kodunun Satir Satir Aciklamasi

- `@dataclass`: Python'a bu class'in veri tasiyan sade bir model oldugunu soyler.
- `class TaskCandidateRecord:` gorev adayi kaydi icin yeni model tanimlar.
- `"""Represents a simple task candidate record."""`: Modelin neyi temsil ettigini kisa olarak aciklar.
- `task_title: str`: Gorev adayinin basligini zorunlu alan olarak tutar.
- `task_type: str | None = None`: Gorev adayi turunu opsiyonel tutar.
- `related_area: str | None = None`: Ilgili saha alani veya konuyu opsiyonel tutar.
- `source: str | None = None`: Gorev adayinin hangi kaynaktan ciktigini opsiyonel metin olarak tutar.
- `target_date: str | None = None`: Hedef tarihi opsiyonel tutar.
- `status: str = "open"` gorev adayini varsayilan olarak acik durumda baslatir.
- `notes: str | None = None`: Serbest not alanini opsiyonel tutar.

Sunu yaptik: Gorev adayi bilgisini `TaskCandidateRecord` adli ayri bir veri modeliyle tanimladik.

Boyle yaptik: Gorev basligini zorunlu, tur, ilgili alan, kaynak, hedef tarih ve notlari opsiyonel tuttuk.

Cunku: Ilk kayit aninda sadece aday basligi kesin bilinebilir; diger bilgiler daha sonra tamamlanabilir.

Boylece: Santiye sefi tam gorev sistemi kurmadan kucuk aksiyon adaylarini kayda alabilir.

## 5. Test Kodu

```python
def test_task_candidate_record_holds_values_and_defaults() -> None:
    task_candidate = TaskCandidateRecord(
        task_title="Kuzey cephe iskele kontrolu takip et",
        task_type="takip",
        related_area="A Blok kuzey cephe",
        source="Saha notu",
        target_date="2026-06-12",
    )

    assert task_candidate.task_title == "Kuzey cephe iskele kontrolu takip et"
    assert task_candidate.task_type == "takip"
    assert task_candidate.related_area == "A Blok kuzey cephe"
    assert task_candidate.source == "Saha notu"
    assert task_candidate.target_date == "2026-06-12"
    assert task_candidate.notes is None
    assert task_candidate.status == "open"
```

## 6. Test Kodunun Satir Satir Aciklamasi

- `def test_task_candidate_record_holds_values_and_defaults() -> None:` test fonksiyonunu tanimlar.
- `task_candidate = TaskCandidateRecord(...)` test icin bir gorev adayi kaydi olusturur.
- `task_title="Kuzey cephe iskele kontrolu takip et"` gorev adayi basliginin kayda verilebildigini gosterir.
- `task_type="takip"` gorev adayi turunun tutuldugunu gosterir.
- `related_area="A Blok kuzey cephe"` ilgili alan bilgisinin tutuldugunu test eder.
- `source="Saha notu"` kaynak bilgisinin metin olarak tutuldugunu test eder.
- `target_date="2026-06-12"` hedef tarihin tutuldugunu test eder.
- `assert task_candidate.notes is None` not verilmediginde varsayilan degerin `None` oldugunu kontrol eder.
- `assert task_candidate.status == "open"` durum alaninin varsayilan olarak `open` geldigini kontrol eder.

## 7. Teknik Karar Tablosu

| Karar | Boyle Yapildi | Cunku | Boylece |
| --- | --- | --- | --- |
| Gorev adayi modeli ayri tutuldu | `TaskCandidateRecord` eklendi | Aday kayit tam gorev sisteminden daha kucuk bir kavramdir | Kapsam kucuk kalir |
| Gorev basligi zorunlu yapildi | `task_title: str` kullanildi | Basliksiz aday kayit anlamli olmaz | En azindan aday aksiyonun konusu bilinir |
| Kaynak metin olarak tutuldu | `source: str | None` kullanildi | Bu adimda saha notu veya rapor baglantisi kurulmaz | Kod seviyesi iliski eklenmez |
| Detay alanlari opsiyonel tutuldu | `str | None` kullanildi | Ilk anda tum takip bilgileri bilinmeyebilir | Kayit erken acilabilir |
| Iliski kurulmadi | Baska modele referans eklenmedi | Bu adim sadece model baslangici | Mimari sade kalir |

## 8. Neden Gercek Gorev Yonetimi / Hatirlatici / Bildirim / Takvim / Kisi Atama / Oncelik Sistemi Kurmadik?

Gercek gorev yonetimi, hatirlatici, bildirim, takvim, kisi atama ve oncelik sistemleri sorumlu kisi, tarih takibi, bildirim kanallari, is akisi, durum gecisleri ve yetki kurallari gibi daha detayli kararlar ister.

Bu adimda henuz bu kurallari tasarlamiyoruz. Once santiyede gorev adayi bilgisinin hangi alanlarla temsil edilecegini netlestiriyoruz.

## 9. Mini Sozluk

`Gorev adayi kaydi`: Henuz gercek gorev olmayan, ileride goreve donusebilecek aksiyon fikrinin kayit altina alinmis hali.

`TaskCandidateRecord`: Gorev adayini temsil eden Python veri modeli.

`task_title`: Gorev adayinin kisa basligini tutan alan.

`task_type`: Gorev adayi turunu tutan alan.

`related_area`: Gorev adayinin ilgili oldugu saha alani veya konuyu tutan alan.

`source`: Gorev adayinin hangi kaynaktan ciktigini metin olarak tutan alan.

`target_date`: Gorev adayinin hedef tarihini tutan alan.

`Is akisi`: Bir kaydin durumlar arasinda hangi kurallarla ilerledigini tanimlayan surec.

## 10. Sonraki Kucuk Adim Onerisi

Sonraki kucuk adim olarak Adim 020'de basit kontrol maddesi kayit modeli baslatilabilir.
