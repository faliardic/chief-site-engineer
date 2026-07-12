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

Her bes adimlik teknik blok tamamlandiginda bir podcast notu hazirlanir.

Genel aralik mantigi:

```text
Adim 001-005
Adim 006-010
Adim 011-015
...
```

Podcast notu, ilgili araliktaki son adim tamamlandiktan ve o aralik icin factual state netlestikten sonra hazirlanir.

Bu belge obsolete proje-stage metni tutmaz. Guncel proje durumu icin `README.md`, `.cse/state/project_state.json`, `ROADMAP.md` ve current GitHub Issue birlikte okunur.

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

## Factual Current Podcast State

- Podcast 030: `docs/podcast_notes/030_adim_196_200_notebooklm_podcast_notu.md`
- Podcast 030 kapsami: Steps 196-200
- Podcast 031: `docs/podcast_notes/031_adim_201_205_notebooklm_podcast_notu.md`
- Podcast 031 kapsami: Steps 201-205
- Podcast 032: `docs/podcast_notes/032_adim_206_210_notebooklm_podcast_notu.md`
- Podcast 032 kapsami: Steps 206-210
- Podcast 033: `docs/podcast_notes/033_adim_211_215_notebooklm_podcast_notu.md`
- Podcast 033 kapsami: Steps 211-215
- Podcast 034: `docs/podcast_notes/034_adim_216_220_notebooklm_podcast_notu.md`
- Podcast 034 kapsami: Steps 216-220
- Latest completed podcast: Podcast 034
- Sonraki besli aralik: Steps 221-225

Bu factual state yeni podcastler eklendikce guncellenir, ancak burada eski proje asamasi ornekleri veya cabuk bayatlayan "aktif adim" metinleri tutulmaz.

## Rolling NotebookLM Source Protokolu

NotebookLM'e her yeni podcast notunu elle eklemek yerine su stable website source bir kez eklenir:

```text
https://raw.githubusercontent.com/faliardic/chief-site-engineer/master/docs/notebooklm/CSE_PODCAST_LATEST_SOURCE.md
```

Permanent instruction, rolling source ve manifest:

```text
docs/notebooklm/NOTEBOOKLM_INSTRUCTIONS.md
docs/notebooklm/CSE_PODCAST_LATEST_SOURCE.md
docs/notebooklm/CSE_PODCAST_SOURCE_MANIFEST.json
```

Yeni podcast notu olusturulduktan ve canonical state guncellendikten sonra su komut calistirilir:

```powershell
python scripts/build_notebooklm_podcast_source.py
```

NotebookLM'in saved website source'u otomatik refresh ettigi dogrulanmamistir; gerekirse kullanici NotebookLM arayuzunde refresh durumunu kontrol eder.

## Podcast Notu Icerigi

Podcast 035 ve sonraki her podcast notu en az su basliklari icermelidir:

```text
1. NotebookLM kullanim talimati / instruction reference
2. Notun kapsami
3. Donemin ana temasi
4. Guncel adimlarin ayrintili anlatimi
5. Guncel donem ozeti
6. Onceki Adimlarin Ayri Ayri Ozeti
7. Birikimli urun ve teknik durum
8. Test ve guvenli nokta kaniti
9. Bilerek ertelenenler
10. Sonraki dogal yon
11. NotebookLM kisa direktifi
12. Kapanis sorusu ve kisa cevap
```

Onceki adimlar bolumunde her canonical adim `### Adim NNN - kisa baslik` biciminde ayri tanimlanir. Generator bu birikimli ozetleri rolling source icinde canonical `CHANGELOG.md`, `ROADMAP.md`, `.cse` state ve tracked step dokumanlarindan yeniden kurar.

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

Podcast notu, ilgili 5 adimlik araligin son adimi tamamlandiktan sonra ilgili adimin dokumantasyon ciktisi olarak hazirlanabilir.

Onerilen commit mesaji ornegi:

```text
Add NotebookLM podcast notes for steps AAA-BBB
```
