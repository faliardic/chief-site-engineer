# Adim 010 - Toplanti ve Aksiyon Kayit Modelleri

## Amac

Bu adimin amaci, santiyede yapilan toplantilari ve bu toplantilardan cikan aksiyonlari ileride takip edebilmek icin sade veri modelleri olusturmaktir.

## Bu Adimda Ne Eklendi?

`app/models.py` icine `MeetingRecord` ve `MeetingActionRecord` modelleri eklendi. `tests/test_models.py` icine bu iki modelin alanlarini ve varsayilan degerlerini kontrol eden testler eklendi.

## Cozulen Santiye Problemi

Santiye toplantilarinda kararlar, sorumlular ve terminler konusulur. Bu bilgiler daginik notlarda kalirsa takip zorlasir. Bu adim, toplanti bilgisini ve toplantidan cikan aksiyonu ayri iki sade kayit olarak dusunmeye baslar.

## MeetingRecord Model Kodu

```python
@dataclass
class MeetingRecord:
    """Represents a meeting minutes record."""

    meeting_title: str
    meeting_date: str | None = None
    location: str | None = None
    organizer: str | None = None
    participants: str | None = None
    agenda: str | None = None
    decisions: str | None = None
    notes: str | None = None
    status: str = "draft"
```

## MeetingRecord Kodunun Satir Satir Aciklamasi

- `@dataclass`: Python'a bu class'in veri tasiyan sade bir model oldugunu soyler.
- `class MeetingRecord:` toplanti tutanagi icin yeni model tanimlar.
- `meeting_title: str`: Toplanti basligini zorunlu alan olarak tutar.
- `meeting_date: str | None = None`: Toplanti tarihini opsiyonel tutar.
- `location: str | None = None`: Toplantinin yapildigi yeri opsiyonel tutar.
- `organizer: str | None = None`: Toplantiyi organize eden kisi veya tarafi opsiyonel tutar.
- `participants: str | None = None`: Katilimcilari bu adimda metin olarak opsiyonel tutar.
- `agenda: str | None = None`: Gundem maddelerini bu adimda metin olarak opsiyonel tutar.
- `decisions: str | None = None`: Alinan kararlari opsiyonel tutar.
- `notes: str | None = None`: Serbest aciklama alanini opsiyonel tutar.
- `status: str = "draft"` kaydi varsayilan olarak taslak durumda baslatir.

Sunu yaptik: Toplanti bilgisini `MeetingRecord` modeliyle ayri bir veri kaydi yaptik.

Boyle yaptik: Toplanti basligini zorunlu, diger bilgileri opsiyonel alan olarak tuttuk.

Cunku: Toplanti ilk acildiginda tarih, katilimci veya karar bilgileri henuz tamamlanmamis olabilir.

Boylece: Toplanti kaydi erken asamada taslak olarak baslatilabilir ve detaylar sonra tamamlanabilir.

## MeetingActionRecord Model Kodu

```python
@dataclass
class MeetingActionRecord:
    """Represents an action item from a meeting."""

    action_title: str
    meeting_title: str | None = None
    responsible: str | None = None
    due_date: str | None = None
    status: str = "open"
    notes: str | None = None
```

## MeetingActionRecord Kodunun Satir Satir Aciklamasi

- `@dataclass`: Bu class'in sade veri modeli olarak kullanilacagini belirtir.
- `class MeetingActionRecord:` toplanti aksiyonu icin yeni model tanimlar.
- `action_title: str`: Aksiyon veya gorev basligini zorunlu alan olarak tutar.
- `meeting_title: str | None = None`: Aksiyonun hangi toplantidan ciktigini metinsel olarak opsiyonel tutar.
- `responsible: str | None = None`: Sorumlu kisiyi opsiyonel tutar.
- `due_date: str | None = None`: Termin tarihini opsiyonel tutar.
- `status: str = "open"` aksiyonu varsayilan olarak acik durumda baslatir.
- `notes: str | None = None`: Serbest aciklama alanini opsiyonel tutar.

Sunu yaptik: Toplantidan cikan isi ayri `MeetingActionRecord` modeliyle temsil ettik.

Boyle yaptik: Sadece aksiyon basligini zorunlu tuttuk; toplanti basligi, sorumlu ve termin alanlarini opsiyonel yaptik.

Cunku: Toplantida aksiyon fikri dogabilir ama sorumlu kisi veya termin daha sonra netlesebilir.

Boylece: Eksik bilgiyle de takip edilebilir bir aksiyon kaydi baslatilabilir.

## Test Kodlari

```python
def test_meeting_record_holds_values_and_defaults() -> None:
    meeting = MeetingRecord(
        meeting_title="Haftalik santiye koordinasyon toplantisi",
        meeting_date="2026-06-05",
        location="Santiye ofisi",
        organizer="Santiye sefi",
        participants="Isveren, yuklenici, taseron temsilcileri",
        agenda="Imalat ilerlemesi ve kalite kontrolleri",
    )

    assert meeting.meeting_title == "Haftalik santiye koordinasyon toplantisi"
    assert meeting.meeting_date == "2026-06-05"
    assert meeting.location == "Santiye ofisi"
    assert meeting.organizer == "Santiye sefi"
    assert meeting.participants == "Isveren, yuklenici, taseron temsilcileri"
    assert meeting.agenda == "Imalat ilerlemesi ve kalite kontrolleri"
    assert meeting.decisions is None
    assert meeting.notes is None
    assert meeting.status == "draft"
```

```python
def test_meeting_action_record_holds_values_and_defaults() -> None:
    action = MeetingActionRecord(
        action_title="Temel izolasyon detayini kontrol et",
        meeting_title="Haftalik santiye koordinasyon toplantisi",
        responsible="Saha muhendisi",
        due_date="2026-06-12",
    )

    assert action.action_title == "Temel izolasyon detayini kontrol et"
    assert action.meeting_title == "Haftalik santiye koordinasyon toplantisi"
    assert action.responsible == "Saha muhendisi"
    assert action.due_date == "2026-06-12"
    assert action.notes is None
    assert action.status == "open"
```

## Testlerin Satir Satir Aciklamasi

- `meeting = MeetingRecord(...)`: Yeni toplanti kaydi nesnesi olusturur.
- `meeting_title="Haftalik santiye koordinasyon toplantisi"`: Toplanti basligini verir.
- `meeting_date="2026-06-05"`: Toplanti tarihini verir.
- `location="Santiye ofisi"`: Toplantinin yapildigi yeri verir.
- `organizer="Santiye sefi"`: Toplantiyi organize eden kisiyi verir.
- `participants=...`: Katilimcilari metin olarak verir.
- `agenda=...`: Gundemi metin olarak verir.
- `assert meeting.decisions is None`: Karar girilmediginde alanin bos kalabildigini kontrol eder.
- `assert meeting.notes is None`: Not girilmediginde alanin bos kalabildigini kontrol eder.
- `assert meeting.status == "draft"`: Toplanti kaydinin varsayilan olarak taslak basladigini kontrol eder.
- `action = MeetingActionRecord(...)`: Yeni aksiyon kaydi nesnesi olusturur.
- `action_title=...`: Aksiyon basligini verir.
- `meeting_title=...`: Aksiyonun kaynak toplantisini metinsel olarak verir.
- `responsible="Saha muhendisi"`: Sorumlu kisiyi verir.
- `due_date="2026-06-12"`: Termin tarihini verir.
- `assert action.notes is None`: Not girilmediginde bos kalabildigini kontrol eder.
- `assert action.status == "open"`: Aksiyonun varsayilan olarak acik basladigini kontrol eder.

Bu testler; alan adlari degisirse, opsiyonel alanlar beklenenden farkli baslarsa veya varsayilan durum degerleri bozulursa hatayi yakalar.

## Teknik Karar Tablosu

| Sunu yaptik | Boyle yaptik | Cunku | Boylece |
| --- | --- | --- | --- |
| Toplanti kaydi modeli ekledik | `MeetingRecord` dataclass yazdik | Toplanti bilgileri ileride takip edilmeli | Tutanak bilgisi tek nesnede temsil edilir |
| Aksiyon kaydi modeli ekledik | `MeetingActionRecord` dataclass yazdik | Toplantidan cikan islerin ayri takip edilmesi gerekir | Aksiyonlar toplanti notundan bagimsiz dusunulebilir |
| Katilimci ve gundemi metin tuttuk | Liste yerine `str | None` kullandik | Bu adimda model kucuk kalmali | Karmasik iliski veya liste yapisi eklenmez |
| Toplanti ile aksiyonu kodla baglamadik | `meeting_title` metinsel referans olarak tutuldu | Veritabani veya iliski sistemi henuz yok | Ileride baglanti kurulabilecek sade temel olusur |

## Neden Otomatik Gorev Uretmedik?

Bu adimda amac, tutanak metnini okuyup otomatik gorev ureten bir sistem kurmak degildir. Once toplantinin ve aksiyonun hangi temel alanlarla temsil edilecegini netlestirdik. Otomatik gorev uretme daha sonra metin isleme, karar ayrirma ve is atama kurallari gerektirir.

## MeetingRecord ile MeetingActionRecord Ileride Nasil Birlesebilir?

Bu adimda `MeetingActionRecord.meeting_title` sadece metinsel bilgi olarak tutulur. Ileride toplantilar kimlik alanlariyla genisletilirse, aksiyon kaydi toplantinin ID degerine baglanabilir. Boylece bir toplantinin tum aksiyonlari listelenebilir.

## MeetingActionRecord ile Issue/Punch/Task Modulu Ileride Nasil Birlesebilir?

Toplanti aksiyonu ileride issue, punch veya task modulune donusebilir. Ornegin toplantida "Eksik imalati tamamla" karari cikarsa bu karar bir aksiyon olarak baslar, daha sonra saha takip gorevine veya punch list maddesine baglanabilir. Bu adimda bu bag kurulmadi; sadece aksiyon bilgisinin veri sekli hazirlandi.

## Mini Sozluk

`Toplanti tutanagi`: Toplantida konusulan gundem, karar ve notlari tutan kayit.

`MeetingRecord`: Toplanti bilgisini temsil eden veri modeli.

`MeetingActionRecord`: Toplantidan cikan aksiyon veya gorev fikrini temsil eden veri modeli.

`meeting_title`: Toplanti basligini tutan alan.

`meeting_date`: Toplanti tarihini tutan alan.

`organizer`: Toplantiyi organize eden kisi veya taraf.

`participants`: Toplanti katilimcilarini metin olarak tutan alan.

`agenda`: Toplanti gundemini tutan alan.

`decisions`: Toplantida alinan kararlari tutan alan.

`action_title`: Aksiyon basligini tutan alan.

`responsible`: Aksiyondan sorumlu kisiyi tutan alan.

`due_date`: Aksiyonun hedef bitis tarihini tutan alan.

`draft`: Kaydin henuz taslak oldugunu anlatan durum.

`open`: Kaydin acik ve henuz tamamlanmamis oldugunu anlatan durum.

`Termin`: Bir isin tamamlanmasi beklenen hedef tarih.

`Aksiyon kaydi`: Toplantidan cikan takip edilecek is veya gorev kaydi.

## Sonraki Kucuk Adim

Adim 011 icin onerilen konu: RFI/submittal lite kayit modeli baslangici. Bu adimda Adim 011 uygulamasina gecilmedi.
