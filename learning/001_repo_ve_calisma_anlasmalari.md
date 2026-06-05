# 001 Repo ve Calisma Anlasmalari

## 1. Bu adimda ne yaptik?

Bu adimda Chief Site Engineer projesi icin ilk repo iskeletini kurduk. Repo, projenin dosyalarini ve Git gecmisini tutan ana calisma alanidir. Proje koku, komutlari calistirdigimiz ana klasordur.

Bu adimda temel klasorler, basit Python baslangic dosyasi, smoke test, pytest ayari, README, AGENTS, changelog, roadmap ve bos klasorleri koruyan `.gitkeep` dosyalari olusturuldu.

## 2. Neden bunu yaptik?

Uygulama acisindan once duzenli bir kod organizasyonu gerekir. Kod organizasyonu, dosyalarin hangi klasorde ve hangi amacla duracagini belirler.

Santiye sefi acisindan bu, santiyede evrak klasorlerini basinda ayirmaya benzer: proje notlari, arsiv, dokumanlar ve testler karisik durmaz.

## 3. Hangi dosyalara dokunduk?

```text
app/
tests/
docs/
learning/
archive/
data/
exports/
README.md
AGENTS.md
CHANGELOG.md
ROADMAP.md
PROJECT_RULES.md
requirements.txt
pyproject.toml
```

`app/`: Uygulama kodlarinin durdugu klasordur.

`tests/`: Test kodlarinin durdugu klasordur.

`docs/`: Proje kararlarini ve teknik dokumantasyonu tutar.

`learning/`: Kullaniciya Python ve yazilim mantigini ogreten dosyalari tutar.

`archive/`, `data/`, `exports/`: Ileride arsiv, veri ve cikti dosyalari icin ayrilan klasorlerdir.

## 4. Kod bloklari uzerinden aciklama

### Proje baslangic noktasi

```python
def main() -> str:
    """Return a simple startup message for the application."""
    return "Chief Site Engineer sistemi basladi."


if __name__ == "__main__":
    print(main())
```

Bu kodun amaci:
Projenin calisabilir bir Python baslangic noktasi oldugunu gostermek.

Satir satir aciklama:

- `def main() -> str:` `main` adinda bir fonksiyon tanimlar ve metin dondurecegini soyler.
- `"""Return..."""` fonksiyonun ne yaptigini kisaca anlatan dokumantasyon metnidir.
- `return "Chief Site Engineer sistemi basladi."` fonksiyon cagrildiginda geri donecek metni belirler.
- `if __name__ == "__main__":` dosya dogrudan calistirildiginda altindaki kodun calismasini saglar.
- `print(main())` `main()` fonksiyonunu calistirir ve sonucunu ekrana yazar.

Sunu yaptik:
Projeye en kucuk calisan baslangic fonksiyonu ekledik.

Boyle yaptik:
`app/main.py` icinde sade bir `main()` fonksiyonu tanimladik.

Cunku:
Repo iskeletinin sadece klasorlerden degil, test edilebilir kucuk bir Python davranisindan olusmasini istedik.

Boylece:
Smoke test ile projenin temel calisirligini kontrol edebiliyoruz.

### Pytest ayari

```toml
[tool.pytest.ini_options]
testpaths = ["tests"]
pythonpath = ["."]
addopts = "-q"
```

Bu kodun amaci:
`pytest` aracina testleri nerede bulacagini ve projeyi nasil okuyacagini soylemek.

Satir satir aciklama:

- `[tool.pytest.ini_options]` pytest ayarlarinin basladigini gosterir.
- `testpaths = ["tests"]` testlerin `tests/` klasorunde aranacagini belirtir.
- `pythonpath = ["."]` proje kokunun Python import yoluna eklenecegini belirtir.
- `addopts = "-q"` test ciktisinin daha sade olmasini saglar.

Santiye karsiligi:
Bu ayar, kontrol listesinin hangi klasorde tutuldugunu onceden belirlemek gibidir.

### requirements.txt

```text
pytest
```

Bu dosyanin amaci:
Projenin ihtiyac duydugu Python paketlerini listelemek.

Bu adimda sadece `pytest` var. Cunku ilk adimda framework, veritabani veya ekstra paket eklemedik.

## 5. Test kodlari uzerinden aciklama

```python
from app.main import main


def test_main_returns_startup_message() -> None:
    assert main() == "Chief Site Engineer sistemi basladi."
```

Bu testin amaci:
`main()` fonksiyonunun beklenen baslangic mesajini dondurdugunu kontrol etmek.

Satir satir aciklama:

- `from app.main import main` test icin `main` fonksiyonunu iceri alir.
- `def test_main_returns_startup_message() -> None:` yeni bir test fonksiyonu tanimlar.
- `assert main() == ...` `main()` sonucunun beklenen metne esit oldugunu kontrol eder.

Smoke test:
Smoke test, sistemin en temel parcasinin calisip calismadigini hizlica kontrol eden basit testtir. Burada amac tum uygulamayi test etmek degil, repo baslangicinin kirilmadigini gormektir.

## 6. Kodun calisma akisi

1. Python `app/main.py` dosyasini okur.
2. `main()` fonksiyonunu tanir.
3. Test dosyasi `main` fonksiyonunu import eder.
4. Test `main()` fonksiyonunu cagirir.
5. Fonksiyon baslangic mesajini dondurur.
6. `assert` bu mesajin beklenen mesajla ayni olup olmadigini kontrol eder.
7. `pytest` test basariliysa yesil sonuc verir.

## 7. "Sunu yaptik / Boyle yaptik / Cunku / Boylece" teknik karar tablosu

| Sunu yaptik | Boyle yaptik | Cunku | Boylece |
| --- | --- | --- | --- |
| Repo iskeleti kurduk | `app/`, `tests/`, `docs/`, `learning/` klasorlerini ayirdik | Kod, test ve dokumanlar karismamali | Proje buyurken duzen korunur |
| Baslangic fonksiyonu ekledik | `app/main.py` icinde `main()` yazdik | Repo test edilebilir bir davranis icermeli | Smoke test yazilabilir oldu |
| Pytest ayari ekledik | `pyproject.toml` icinde test ayarlari yaptik | Test komutu sade calismali | `python -m pytest` proje kokunden calisir |
| Bos klasorleri koruduk | `.gitkeep` dosyalari kullandik | Git bos klasorleri takip etmez | `data/`, `exports/`, `archive/` repoda kalir |

## 8. Yeni ogrenilen yazilim kavramlari

```text
Repo:
Proje dosyalarini ve Git gecmisini tutan ana calisma alanidir.

Bu projedeki karsiligi:
chief-site-engineer klasoru repo kokudur.

Santiye benzetmesi:
Tum proje klasorlerinin durdugu ana santiye dosyasi gibidir.
```

```text
Proje baslangic noktasi:
Uygulamanin ilk calistirilan sade giris davranisidir.

Bu projedeki karsiligi:
app/main.py icindeki main() fonksiyonu.
```

```text
Test edilebilirlik:
Kodun otomatik testlerle kontrol edilebilir olmasidir.

Bu projedeki karsiligi:
main() fonksiyonu deger dondurdugu icin test edilebiliyor.
```

## 9. Bu adimda bilincli olarak ne yapmadik?

Framework, veritabani, API, GUI, JSON kayit sistemi ve gelismis mimari eklemedik.

Cunku ilk adimda amac uygulamayi buyutmek degil, saglam ve test edilebilir repo temelini kurmaktir.

## 10. Mini sozluk

`Repo`: Proje dosyalari ve Git gecmisinin bulundugu ana alan.

`Proje koku`: Komutlarin calistirildigi ana proje klasoru.

`Klasor yapisi`: Dosyalarin hangi klasorlerde durdugunu gosteren duzen.

`app/`: Uygulama kodlarinin klasoru.

`tests/`: Test kodlarinin klasoru.

`docs/`: Teknik dokumanlarin klasoru.

`learning/`: Ogrenme dosyalarinin klasoru.

`archive/`: Arsiv icin ayrilan klasor.

`__init__.py`: Bir klasorun Python paketi olarak kullanilabilecegini gosteren dosya.

`main.py`: Uygulamanin baslangic dosyasi.

`pytest`: Python testlerini calistiran arac.

`pyproject.toml`: Python araclarinin ayarlarini tutabilen proje dosyasi.

`Markdown`: Baslik, liste ve kod bloklari yazmak icin kullanilan sade dokuman bicimi.

`Changelog`: Degisiklik gecmisi.

`Roadmap`: Projenin yol haritasi.

`.gitkeep`: Bos klasorlerin Git tarafindan takip edilmesini saglayan yer tutucu dosya.

## 11. Sonraki adima baglanti

Repo iskeleti ve smoke test hazir oldugu icin sonraki adimda uygulamanin temel veri modelleri guvenle eklenebilir.
