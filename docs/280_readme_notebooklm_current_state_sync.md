# Issue #280 — README ve NotebookLM Current-State Senkronizasyonu

## Amaç

Bu çalışma root/mobile README, canonical state ve NotebookLM podcast kaynağını
son birleşmiş safe point ile hizalar. Production davranışını değiştirmez.

## Canonical safe point

| Alan | Değer |
| --- | --- |
| Issue / PR | `#277 / #278` |
| Merge commit | `c72f6bc55fc658996a546d9833b85a2614b99327` |
| Mobil sürüm | `0.1.0+1` |
| Schema / backup | `10 / 1` |
| Timezone | `Europe/Istanbul` |
| Tablet kabulü | Samsung `SM-X610`, PASS |

Issue #277 için focused lifecycle `48/48`, focused widget `46/46`, Beton
regression `1/1`, full Flutter `333/333`, analyze `0` ve tablet wide smoke PASS
kanıtı yeniden kullanılır. Dokümantasyon değişikliği mobil runtime'ı
değiştirmediği için Flutter/build/ADB/device kapıları tekrar edilmez.

## Durum ayrımı

- Issue #279: `paused_for_readme_notebooklm_sync`; branch
  `codex/issue-279-reminder-quick-earlier-time`; birleşmemiş ve yayımlanmamış.
  Focused reminder widget retry `47 PASS / 4 FAIL` blocker'ında fail-closed
  durmuştur. Full/analyze/build/tablet çalıştırılmamıştır.
- PR #259: açık, Draft ve conflicting physical smoke acceptance harness
  çalışmasıdır; merged ürün altyapısı değildir.
- Issue #280: yalnız documentation, developer tooling, deterministic source
  generation ve test kapsamıdır.

## NotebookLM range geçişi

Podcast 001–035, legacy Adım 001–225 tarihini taşır ve değiştirilmez.
Podcast 036 şu dosyayla Issue dönemini başlatır:

```text
docs/podcast_notes/036_issue_227_277_notebooklm_podcast_notu.md
```

Dosya adı `adim` veya `issue` range türünü açıkça taşır. `issue` aralığı
kesintisiz değildir. Generator, yalnız CHANGELOG'daki canonical başlıkları
toplar:

```markdown
## Issue #277 - Hatırlatıcı Exact Hızlı Planlama Zamanları
```

Örneğin #227–#277 aralığında bulunmayan Issue numarası için sentetik başlık ya
da “tamamlandı” kaydı üretilmez.

## Generator ve manifest

`scripts/build_notebooklm_podcast_source.py`:

1. En yüksek podcast numarasını seçer.
2. Dosya range türü ve sınırlarını doğrular.
3. Legacy adım özetlerini Adım 001–225 için geriye uyumlu toplar.
4. `issue` notunda yalnız gerçek CHANGELOG Issue bölümlerini artan sırayla
   toplar.
5. Küçük canonical state'ten Issue/PR/commit/test safe point'ini okur.
6. UTF-8 rolling source ile sort edilmiş JSON manifesti ağ erişimsiz üretir.

Manifest; `latest_range_kind`, `latest_range`, `latest_issue_range`,
`legacy_last_numbered_step`, legacy/Issue summary sayıları ve safe point
Issue/PR/commit alanlarını taşır. Stable public URL değişmemiştir.

## Dokümantasyon sınırı

README'ler:

- güncel Flutter mobil ürünü ana ürün olarak tanımlar;
- Python/Flask kodunu tarihsel çekirdek ve repository destek kodu olarak ayırır;
- schema `10`, backup `1`, Android exact alarm özel erişimi ve güncel mobile
  capability'leri kaynakla uyumlu anlatır;
- tablet-only dar Issue kabulünü telefon promotion gibi sunmaz;
- field-ready, production-ready veya store-released iddiasında bulunmaz.

## Doğrulama

Issue sözleşmesindeki sıra:

1. focused NotebookLM testleri;
2. generator run 1;
3. source/manifest snapshot;
4. generator run 2 ve byte-for-byte karşılaştırma;
5. JSON parse ve state/manifest consistency;
6. README factual assertion/stale-token taraması;
7. full Python suite;
8. exact allowlist ve production-path empty diff kontrolü.

Podcast 001–035 diff dışında kalır. Flutter, APK/AAB, install, ADB ve fiziksel
cihaz işlemi bu docs-only sözleşmede çalıştırılmaz.
