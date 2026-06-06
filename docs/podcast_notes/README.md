# CSE NotebookLM Podcast Notlari Protokolu

## Amac

CHIEF SITE ENGINEER projesinde her 5 gelistirme adiminda bir, yapilan isleri NotebookLM'e verilecek sekilde ozetleyen podcast notlari hazirlanir.

Bu notlarin amaci:

1. Projenin gelisimini sozlu olarak dinlenebilir hale getirmek.
2. Her 5 adimda bir teknik ilerlemeyi arsivlemek.
3. Kod, test, dokumantasyon ve ogrenim tarafindaki kazanimlari toparlamak.
4. Santiye sefi bakis acisiyla sistemin neden gelistigini aciklamak.
5. NotebookLM icinde podcast bolumleri olusturmak icin temiz kaynak metin uretmek.

## Podcast Notu Uretim Araligi

Her 5 adimda bir podcast notu hazirlanir.

Araliklar:

```text
Adim 001-005
Adim 006-010
Adim 011-015
Adim 016-020
Adim 021-025
Adim 026-030
Adim 031-035
Adim 036-040
```

Podcast notu, ilgili araliktaki son adim commitlendikten sonra hazirlanir.

Ornek:

```text
Adim 025 commitlendikten sonra:
docs/podcast_notes/005_adim_021_025_notebooklm_podcast_notu.md
```

## Dosya Konumu

Podcast notlari su klasorde tutulur:

```text
docs/podcast_notes/
```

Dosya adlandirma formati:

```text
XXX_adim_AAA_BBB_notebooklm_podcast_notu.md
```

Ornekler:

```text
001_adim_001_005_notebooklm_podcast_notu.md
002_adim_006_010_notebooklm_podcast_notu.md
003_adim_011_015_notebooklm_podcast_notu.md
004_adim_016_020_notebooklm_podcast_notu.md
005_adim_021_025_notebooklm_podcast_notu.md
```

## Podcast Notu Icerigi

Her podcast notu su basliklari icermelidir:

```text
# CSE NotebookLM Podcast Notu - Adim XXX-YYY

## 1. Bolumun Ana Konusu
Bu 5 adimda sistemin hangi ana yetenegi gelisti?

## 2. Kisa Ozet
5-10 cumlelik genel anlatim.

## 3. Adim Adim Gelisim
Her adim icin:
- Adim numarasi
- Eklenen model / yapi / karar
- Bu eklemenin amaci
- Hangi dosyalar guncellendi?
- Hangi test eklendi?
- Ogrenme acisindan ne kazandirdi?

## 4. Teknik Kazanimlar
Bu bolumde ogrenilen Python, test, dataclass, modelleme, dokumantasyon veya proje yonetimi konulari.

## 5. Santiye Sefi Acisindan Anlami
Bu 5 adim gercek santiye yonetiminde neye karsilik geliyor?

## 6. Sistem Mimarisi Acisindan Anlami
CHIEF SITE ENGINEER uygulamasi bu 5 adimda nasil daha guclu hale geldi?

## 7. Ozellikle Eklenmeyen Seyler
Bu aralikta bilincli olarak eklenmeyen seyler:
- Veritabani
- API
- GUI
- JSON kayit
- Dosya islemi
- Buyuk mimari sicrama

## 8. Ogrenme Notlari
Python learner acisindan onemli dersler.

## 9. Podcast Sunucusu Icin Anlatim Talimati
NotebookLM podcastinde konusma su tarzda olmali:
- Turkce anlat
- Teknik ama anlasilir konus
- Santiye sefi bakis acisini koru
- Kod tarafini basitlestirerek acikla
- Her adimi ayri ayri ama akici bicimde bagla
- Projenin kucuk, guvenli ve testli ilerledigini vurgula
- Gereksiz abarti yapma
- Sanki bir muhendislik gunlugu anlatiliyormus gibi ilerle

## 10. NotebookLM'e Verilecek Kisa Direktif
Asagidaki metin NotebookLM'e podcast uretimi icin ayrica verilecek.
```

## NotebookLM Podcast Direktifi Sablonu

```text
Bu kaynak metni kullanarak Turkce bir podcast bolumu olustur.

Podcastin konusu CHIEF SITE ENGINEER adli Python tabanli santiye kontrol, takip ve arsivleme sisteminin gelistirme surecidir.

Bu bolumde Adim XXX-YYY arasinda yapilan gelistirmeleri anlat.

Anlatim tarzi:
- Teknik ama anlasilir olsun.
- Santiye sefi bakis acisi korunsun.
- Kod detaylari sadelestirilerek anlatilsin.
- Her adimin gercek santiyedeki karsiligi aciklansin.
- Testli ve kucuk adimlarla ilerleme yaklasimi vurgulansin.
- Ogrenme tarafi ayrica anlatilsin.
- Gereksiz motivasyon konusmasi yapilmasin.
- Proje gunlugu / muhendislik guncesi gibi ilerlesin.

Bolum sonunda su soruya cevap ver:
"Bu 5 adim, CHIEF SITE ENGINEER sistemini hangi yonde olgunlastirdi?"
```

## Commit Kurali

Podcast notu, ilgili 5 adimlik araligin son adimi tamamlandiktan sonra ayri bir kucuk adim olarak degil, ilgili adimin dokumantasyon ciktisi olarak hazirlanabilir.

Ornek:

```text
Adim 025 tamamlandiktan sonra:
- Adim 025 kalite kontrol yapilir.
- Adim 025 commitlenir.
- Ardindan Adim 021-025 podcast notu hazirlanir.
- Podcast notu icin ayri kalite kontrol yapilir.
- Podcast notu ayri commitlenebilir.
```

Onerilen commit mesaji:

```text
Add NotebookLM podcast notes for steps 021-025
```

## Mevcut Duruma Uygulama

Proje su anda Adim 022 asamasindadir.

Son tamamlanan 5'li aralik:

```text
Adim 016-020
```

Aktif devam eden 5'li aralik:

```text
Adim 021-025
```

Bu nedenle sonraki podcast notu Adim 025 tamamlandiktan sonra hazirlanacaktir:

```text
docs/podcast_notes/005_adim_021_025_notebooklm_podcast_notu.md
```
