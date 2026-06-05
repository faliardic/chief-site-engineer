# CSE Learning Standardi

## Amac

Bu proje sadece uygulama gelistirmek icin degil, uygulama gelistirirken Python ve yazilim mantigini ogrenmek icin de ilerler.

Learning klasoru, proje ilerledikce kullanicinin kendi Python, yazilim gelistirme ve santiye otomasyon mufredati haline gelir.

## Temel anlatim ilkesi

Her yeni gelistirme su mantikla aciklanir:

"Sunu soyle yaptik ki su davranis calissin."

Ancak bu aciklama soyut kalmaz. Her onemli bolum gercek kod blogu uzerinden anlatilir.

Ornek anlatim mantigi:

```python
@dataclass
class DailySiteLog:
    log_id: str
    project_id: str
    date: str
    status: str = "draft"
```

Bu kodda sunu yaptik:
`DailySiteLog` adinda bir veri modeli olusturduk.

Boyle yaptik:
Python'daki `@dataclass` yapisini kullandik.

Cunku:
Santiye gunlugu ayni tip bilgilerden olusur. Bunlari daginik degiskenler yerine tek bir sinif altinda toplamak daha duzenlidir.

Boylece:
Bir gune ait saha kaydini tek bir nesne olarak temsil edebiliriz.

## Her learning dosyasinda bulunmasi gereken bolumler

### 1. Bu adimda ne yaptik?

Bu bolum kisa ozet verir.

Ornek:
Bu adimda `DailySiteLog` modelini ekledik. Bu model, santiye sefinin gunluk saha kaydini temsil eder.

### 2. Neden bunu yaptik?

Bu bolum iki acidan aciklanir:

- Uygulama acisindan neden gerekli?
- Santiye sefi acisindan neye karsilik geliyor?

Ornek:
Santiye sefi her gun sahada yapilan imalati, hava durumunu, ekip durumunu, denetimleri ve sorunlari not eder. Yazilimda bu bilgileri temsil edecek bir model gerekir.

### 3. Hangi dosyalara dokunduk?

Bu bolumde dosyalar tek tek yazilir.

Ornek:

```text
app/models.py
tests/test_models.py
docs/003_gunluk_saha_kaydi.md
learning/003_gunluk_saha_kaydi_modeli.md
```

Her dosyanin gorevi aciklanir.

Ornek:
`app/models.py`: Veri modellerinin tutuldugu dosyadir.
`tests/test_models.py`: Modellerin dogru calisip calismadigini kontrol eden test dosyasidir.

### 4. Kod bloklari uzerinden aciklama

Bu bolum learning dosyasinin ana bolumudur.

Her onemli kod parcasi su sirayla anlatilir:

1. Kod blogu
2. Kodun genel amaci
3. Satir satir aciklama
4. "Sunu soyle yaptik ki..." aciklamasi
5. Santiye karsiligi

Ornek format:

```python
@dataclass
class ChecklistItem:
    item_id: str
    title: str
    category: str
    required: bool = True
    status: str = "pending"
```

Bu kodun amaci:
Bir kontrol maddesini yazilim icinde temsil etmek.

Satir satir aciklama:

- `@dataclass`: Python'a bu sinifin veri tasiyan bir sinif oldugunu soyler.
- `class ChecklistItem`: Kontrol maddesi icin yeni bir sinif tanimlar.
- `item_id: str`: Her kontrol maddesinin benzersiz kimligini tutar.
- `title: str`: Kontrol maddesinin basligini tutar.
- `category: str`: Kontrol maddesinin hangi gruba ait oldugunu belirtir.
- `required: bool = True`: Bu kontrolun zorunlu olup olmadigini belirtir.
- `status: str = "pending"`: Kontrol maddesinin baslangic durumunu beklemede yapar.

Sunu yaptik:
Kontrol maddesini ayri bir model haline getirdik.

Boyle yaptik:
Her bilgiyi sinif icinde ayri alan olarak tanimladik.

Cunku:
Santiyede kontrol maddeleri baslik, kategori, zorunluluk ve durum bilgisiyle takip edilir.

Boylece:
Ileride "bekleyen kontrolleri listele", "tamamlanan kontrolleri ayir", "zorunlu kontrolleri goster" gibi islemler yapilabilir.

### 5. Test kodlari uzerinden aciklama

Her learning dosyasinda sadece uygulama kodu degil, test kodu da aciklanacak.

Ornek:

```python
def test_daily_site_log_defaults():
    log = DailySiteLog(
        log_id="LOG-001",
        project_id="PRJ-001",
        date="2026-06-05",
    )

    assert log.status == "draft"
    assert log.weather is None
```

Bu testin amaci:
`DailySiteLog` modeli olusturuldugunda varsayilan degerlerin dogru gelip gelmedigini kontrol etmek.

Satir satir aciklama:

- `def test_daily_site_log_defaults():` yeni bir test fonksiyonu tanimlar.
- `log = DailySiteLog(...)` ornek bir gunluk saha kaydi olusturur.
- `assert log.status == "draft"` baslangic durumunun draft oldugunu kontrol eder.
- `assert log.weather is None` hava durumu girilmemisse bos birakildigini kontrol eder.

Sunu yaptik:
Modelin varsayilan davranisini test ettik.

Boyle yaptik:
Modelden ornek bir nesne olusturup alanlarini `assert` ile kontrol ettik.

Cunku:
Kod ileride degisirse bu temel davranislarin bozulmasini istemiyoruz.

Boylece:
Yanlislikla `status` degeri degistirilirse test bunu yakalar.

### 6. Kodun calisma akisi

Bu bolumde kodun nasil calistigi adim adim anlatilir.

Ornek:

1. Python `DailySiteLog` sinifini okur.
2. `@dataclass` bu sinif icin otomatik baslatma yapisi uretir.
3. Biz `DailySiteLog(...)` yazarak yeni bir nesne olustururuz.
4. Verdigimiz degerler nesnenin alanlarina yerlesir.
5. Vermedigimiz opsiyonel alanlar varsayilan degerlerini alir.
6. Testler bu degerlerin dogru olup olmadigini kontrol eder.

### 7. Yeni ogrenilen yazilim kavramlari

Bu bolumde yeni duyulan her teknik terim aciklanir.

Her terim su formatta yazilir:

```text
Terim:
Kisa aciklama.

Bu projedeki karsiligi:
Bu terimi bu adimda nerede kullandik?

Santiye benzetmesi:
Gerekirse insaat/santiye uzerinden benzetme.
```

Ornek:

```text
Varsayilan deger:
Bir alan icin kullanici deger girmezse Python'un otomatik kullandigi baslangic degeridir.

Bu projedeki karsiligi:
DailySiteLog.status alani varsayilan olarak "draft" gelir.

Santiye benzetmesi:
Bir tutanagin ilk olusturuldugunda "taslak" durumda olmasi gibidir.
```

### 8. "Sunu soyle yaptik ki..." teknik karar tablosu

Her learning dosyasinda en az bir teknik karar tablosu olmali.

Format:

| Sunu yaptik | Boyle yaptik | Cunku | Boylece |
| --- | --- | --- | --- |
| Gunluk kayit modeli ekledik | `DailySiteLog` dataclass yazdik | Santiye gunlukleri tek yapida tutulmali | Gunluk kayitlar duzenli temsil edilir |
| Varsayilan status verdik | `status: str = "draft"` yazdik | Yeni kayit hemen tamamlanmis sayilmamali | Kayit taslak olarak baslar |

### 9. Bu adimda bilincli olarak ne yapmadik?

Bu bolum scope kontrolu icindir.

Ornek:
Bu adimda veritabani kurmadik. Cunku once verinin seklini netlestiriyoruz. Veri modeli oturmadan kalici kayit sistemine gecmek ileride karmasa olusturur.

### 10. Mini sozluk

Bu bolumde o adimda gecen yeni terimler kisa tanimlanir.

Ayrica kalici terimler `learning/GLOSSARY.md` dosyasina eklenir.

### 11. Sonraki adima baglanti

Bu bolumde mevcut adimin bir sonraki adima nasil temel oldugu anlatilir.

Ornek:
`DailySiteLog` modeli kuruldugu icin bir sonraki adimda bu kayitlari listeleyen, sayan veya filtreleyen yardimci fonksiyonlar yazilabilir.

## Yazim kurallari

- Learning dosyalari kisa gecilmeyecek.
- Kod blogu olmadan teknik konu anlatilmayacak.
- Her onemli kod blogu sade Turkce ile aciklanacak.
- Yeni terimler ilk gectigi yerde tanimlanacak.
- Baslangic seviyesi kabul edilecek.
- Gerektiginde santiye benzetmesi yapilacak.
- Test kodu da en az uygulama kodu kadar aciklanacak.
- "Neden bunu boyle yaptik?" sorusu mutlaka cevaplanacak.
- Sadece ne yapildigi degil, neden o sekilde yapildigi anlatilacak.

## Minimum learning dosyasi beklentisi

Her yeni adimin learning dosyasinda en az sunlar bulunmali:

- En az 2 gercek kod blogu
- En az 1 test kodu blogu
- En az 1 teknik karar tablosu
- En az 1 kod calisma akisi
- Yeni terimler icin mini sozluk
- `learning/GLOSSARY.md` guncellemesi
- Bilerek yapilmayanlar bolumu
