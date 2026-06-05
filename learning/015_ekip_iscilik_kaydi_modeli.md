# Adim 015 - Ekip / Iscilik Kayit Modeli

## Amac

Bu adimin amaci, santiyede calisan ekipleri ve iscilik gruplarini sade bir Python veri modeliyle temsil etmektir.

## Bu Adimda Ne Eklendi?

`app/models.py` icine `WorkforceRecord` modeli eklendi. `tests/test_models.py` icine `test_workforce_record_holds_values_and_defaults` testi eklendi.

## Cozulen Santiye Problemi

Santiye sefi gunluk olarak hangi ekibin nerede, kac kisiyle ve hangi isi yaptigini bilmek ister. Bu bilgi gunluk rapor, saha ilerleme takibi, taseron koordinasyonu ve mahal bazli kontrol icin temel kayittir.

## Ekip / Iscilik Kaydi Nedir?

Ekip / iscilik kaydi, sahada belirli bir isi yapan calisma grubunun temel bilgisidir. Ornek olarak kalip ekibi, demir ekibi, mekanik ekip veya temizlik ekibi birer iscilik grubu olarak dusunulebilir.

## WorkforceRecord Model Kodu

```python
@dataclass
class WorkforceRecord:
    """Represents a crew or workforce record."""

    crew_name: str
    crew_type: str | None = None
    company: str | None = None
    worker_count: int | None = None
    work_area: str | None = None
    work_date: str | None = None
    task_description: str | None = None
    status: str = "active"
    notes: str | None = None
```

## WorkforceRecord Kodunun Satir Satir Aciklamasi

- `@dataclass`: Python'a bu class'in veri tasiyan sade bir model oldugunu soyler.
- `class WorkforceRecord:` ekip veya iscilik kaydi icin yeni model tanimlar.
- `crew_name: str`: Ekip adini zorunlu alan olarak tutar.
- `crew_type: str | None = None`: Ekip turunu opsiyonel tutar.
- `company: str | None = None`: Ekibin bagli oldugu firma veya taseron bilgisini opsiyonel tutar.
- `worker_count: int | None = None`: Kisi sayisini opsiyonel sayisal alan olarak tutar.
- `work_area: str | None = None`: Calisma alanini opsiyonel tutar.
- `work_date: str | None = None`: Calisma tarihini opsiyonel tutar.
- `task_description: str | None = None`: Yapilan isin kisa aciklamasini opsiyonel tutar.
- `status: str = "active"` kaydi varsayilan olarak aktif durumda baslatir.
- `notes: str | None = None`: Serbest not alanini opsiyonel tutar.

Sunu yaptik: Ekip bilgisini `WorkforceRecord` adli ayri bir veri modeliyle tanimladik.

Boyle yaptik: Ekip adini zorunlu, ekip turu, firma, kisi sayisi, alan, tarih ve notlari opsiyonel tuttuk.

Cunku: Ilk kayit aninda sadece ekip adi kesin bilinebilir; diger bilgiler saha ilerledikce tamamlanabilir.

Boylece: Santiye sefi sade bir ekip kaydi acabilir ve ileride bu kaydi gunluk rapor veya mahal bilgisiyle baglayabilir.

## Test Kodu

```python
def test_workforce_record_holds_values_and_defaults() -> None:
    workforce = WorkforceRecord(
        crew_name="Kalip ekibi",
        crew_type="kalip",
        company="ABC Kalip Tas.",
        worker_count=12,
        work_area="A Blok 2. Kat",
        work_date="2026-06-05",
        task_description="Doseme kalip imalati",
    )

    assert workforce.crew_name == "Kalip ekibi"
    assert workforce.crew_type == "kalip"
    assert workforce.company == "ABC Kalip Tas."
    assert workforce.worker_count == 12
    assert workforce.work_area == "A Blok 2. Kat"
    assert workforce.work_date == "2026-06-05"
    assert workforce.task_description == "Doseme kalip imalati"
    assert workforce.notes is None
    assert workforce.status == "active"
```

## Testin Satir Satir Aciklamasi

- `def test_workforce_record_holds_values_and_defaults() -> None:` test fonksiyonunu tanimlar.
- `workforce = WorkforceRecord(...)` test icin bir ekip/iscilik kaydi olusturur.
- `crew_name="Kalip ekibi"` ekip adinin kayda verilebildigini gosterir.
- `crew_type="kalip"` ekip turunun tutuldugunu gosterir.
- `company="ABC Kalip Tas."` bagli firma bilgisini test eder.
- `worker_count=12` kisi sayisinin sayisal olarak tutuldugunu test eder.
- `work_area="A Blok 2. Kat"` calisma alaninin tutuldugunu test eder.
- `work_date="2026-06-05"` calisma tarihinin tutuldugunu test eder.
- `task_description="Doseme kalip imalati"` yapilan is aciklamasinin tutuldugunu test eder.
- `assert workforce.notes is None` not verilmediginde varsayilan degerin `None` oldugunu kontrol eder.
- `assert workforce.status == "active"` durum alaninin varsayilan olarak `active` geldigini kontrol eder.

## Teknik Karar Tablosu

| Karar | Boyle Yapildi | Cunku | Boylece |
| --- | --- | --- | --- |
| Ekip modeli ayri tutuldu | `WorkforceRecord` eklendi | Iscilik bilgisi gunluk rapordan daha temel bir veri olabilir | Ileride farkli kayitlarla baglanabilir |
| Ekip adi zorunlu yapildi | `crew_name: str` kullanildi | Isimsiz ekip kaydi anlamli olmaz | En azindan hangi ekibin kaydedildigi bilinir |
| Detay alanlari opsiyonel tutuldu | `str | None` ve `int | None` kullanildi | Ilk anda tum saha bilgileri bilinmeyebilir | Kayit erken acilabilir |
| Durum varsayilani verildi | `status: str = "active"` kullanildi | Yeni ekip kaydi genelde aktif kabul edilir | Ek bilgi girilmeden kullanilabilir |
| Iliski kurulmadi | Baska modele referans eklenmedi | Bu adim sadece model baslangici | Mimari sade kalir |

## Neden Gercek Puantaj veya Bordro Sistemi Kurmadik?

Puantaj ve bordro sistemleri calisma saati, ucret, fazla mesai, izin, vardiya ve resmi kayit gibi daha hassas kurallar ister. Bu adimda henuz bu kurallari tasarlamiyoruz. Once santiyede ekip bilgisinin hangi alanlarla temsil edilecegini netlestiriyoruz.

## WorkforceRecord Ileride Hangi Modellerle Birlesebilir?

`WorkforceRecord` ileride `DailyReportRecord` ile gunluk raporlara, `SiteLocationRecord` ile mahal/lokasyon bilgisine, `ProjectPartyRecord` ile taseron veya firma bilgisine ve saha ilerleme kayitlariyla is programina baglanabilir.

## Mini Sozluk

`Ekip kaydi`: Santiyede belirli bir ekip veya calisma grubunun kayit altina alinmis hali.

`Iscilik kaydi`: Ekip, kisi sayisi, calisma alani ve yapilan is bilgisini tutan kayit.

`WorkforceRecord`: Ekip veya iscilik bilgisini temsil eden Python veri modeli.

`crew_name`: Ekip adini tutan alan.

`worker_count`: Ekipteki kisi sayisini tutan alan.

`Puantaj`: Calisanlarin hangi gun ve ne kadar calistigini izleyen kayit sistemi.

`Bordro`: Calisan ucret ve odeme bilgilerinin resmi kayit sistemi.

`Vardiya`: Calisma zaman dilimi.

## Sonraki Kucuk Adim

Sonraki kucuk adim olarak Adim 016'da basit ekipman/makine kayit modeli baslatilabilir.
