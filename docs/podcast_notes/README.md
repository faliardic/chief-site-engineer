# CSE NotebookLM Podcast Notları Protokolü

Bu klasör, CHIEF SITE ENGINEER gelişimini NotebookLM için Türkçe ve
dinlenebilir kaynaklara dönüştüren canonical podcast notlarını tutar.

## Tarihsel dönemler

Podcast 001–035 legacy numaralı adımları kapsar:

```text
XXX_adim_AAA_BBB_notebooklm_podcast_notu.md
```

Bu dönem Adım 001–225 ile kapanmıştır. Dosyalar tarihsel kayıttır; yeni Issue
durumuna göre yeniden yazılmaz.

Podcast 036 ile GitHub Issue tabanlı dönem başlar:

```text
XXX_issue_AAA_BBB_notebooklm_podcast_notu.md
```

Issue aralığı kesintisiz bir adım listesi değildir. Generator yalnız
`CHANGELOG.md` içindeki gerçek `## Issue #NNN - ...` bölümlerini alır; aralıkta
bulunmayan numaraları uydurmaz.

Güncel kaynak:

- Podcast 036:
  `docs/podcast_notes/036_issue_227_277_notebooklm_podcast_notu.md`
- Aralık türü: `issue`
- Issue aralığı: `227-277`
- Legacy son numaralı adım: `225`

## Rolling NotebookLM source

NotebookLM'e eklenebilecek sabit website source:

```text
https://raw.githubusercontent.com/faliardic/chief-site-engineer/master/docs/notebooklm/CSE_PODCAST_LATEST_SOURCE.md
```

İlgili dosyalar:

```text
docs/notebooklm/NOTEBOOKLM_INSTRUCTIONS.md
docs/notebooklm/CSE_PODCAST_LATEST_SOURCE.md
docs/notebooklm/CSE_PODCAST_SOURCE_MANIFEST.json
```

Yeni not ve canonical state güncellendikten sonra:

```powershell
python scripts/build_notebooklm_podcast_source.py
```

Generator ağ erişimi kullanmaz; UTF-8 source ve JSON manifesti deterministik
üretir. NotebookLM'in kaydedilmiş website source'u kendiliğinden yenilediği
doğrulanmamıştır; gerekiyorsa refresh durumu arayüzden kontrol edilir.

## Podcast notu sözleşmesi

Podcast 035 ve sonrası şu bölümleri taşır:

1. NotebookLM kullanım talimatı
2. Notun kapsamı
3. Dönemin ana teması
4. Güncel işlerin ayrıntılı anlatımı
5. Güncel dönem özeti
6. Önceki adımların ayrı ayrı özeti
7. Birikimli ürün ve teknik durum
8. Test ve güvenli nokta kanıtı
9. Bilerek ertelenenler
10. Sonraki doğal yön
11. NotebookLM kısa direktifi
12. Kapanış sorusu ve kısa cevap

Legacy `adim` notlarında strict validator, önceki adım başlıklarının eksiksiz,
tekil ve artan sırada olmasını korur. `issue` notlarında bu kural uygulanmaz;
çünkü Issue numaraları kesintisiz proje adımları değildir. İki türde de en
yüksek podcast numarası güncel nottur ve aynı podcast numarası iki dosyada
kullanılamaz.

Her not:

- birleşmiş davranışı plan ve birleşmemiş işten ayırır;
- güncel safe point, test kanıtı, schema ve backup sürümünü açıklar;
- test başarısını field-ready veya production-ready ilanı gibi sunmaz;
- kaynakta bulunmayan entegrasyon veya otomasyon uydurmaz.

Önerilen commit mesajı:

```text
Add NotebookLM podcast notes for issues AAA-BBB
```
