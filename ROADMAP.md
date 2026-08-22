# CSE V2 — Kanonik Ürün Yol Haritası

**Durum:** Güncel yürütme sırası
**Tarih:** 21 Ağustos 2026
**V2 kapsam kaynağı:** `docs/v2/CSE_V2_SCOPE.md`
**Güncel yön truth-sync:** Issue #468
**Güncel güvenli `master`:** `3eca007c34951095b24b1b0791146a533b3a8a6d` / PR #467

## 1. Güncel ürün durumu

CSE V1 tamamlanmış ve proje sahibi tarafından yaklaşık bir ay gerçek sahada
kullanılmıştır. V2 Items 1–4 tamamlanmış; schedule runtime, immutable
reference-schedule snapshots, Living Plan MVP/ilk cihaz kabulü ve actual-progress
core PR #467'ye kadar merge edilmiştir. Güncel teknik ve ürün durumu:

| Alan | Değer |
| --- | --- |
| V1 baseline commit | `7c9f65a811c9f4bca561adab6bd1f8e64e6908cc` |
| Güncel güvenli merge | `3eca007c34951095b24b1b0791146a533b3a8a6d` |
| Son Living Plan predecessor PR | `#467` |
| Mobil sürüm | `0.1.0+1` |
| SQLite schema | `16` |
| `.csebackup` formatı | `1` |
| Canonical timezone | `Europe/Istanbul` |
| Android compile/target SDK | `36 / 36` |
| Saha durumu | Owner tarafından yaklaşık bir ay kullanıldı |
| Store/public release | İlan edilmedi |

V1'in tamamlanması, modüllerin dondurulduğu anlamına gelmez. V2 aynı
offline-first mobil ürün üzerinde ilerler. Living Plan progress UI ve isolated
device acceptance Issue #468'in current işidir; public/store production release
ilan edilmemiştir.

## 2. Kaynak otoritesi

- Kalıcı ürün amacı ve veri ilkeleri:
  `docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md`
- Güncel V2 kapsamı:
  `docs/v2/CSE_V2_SCOPE.md`
- Güncel yürütme sırası:
  bu `ROADMAP.md`
- Operasyon ve güvenlik:
  `docs/protocols/CSE_PROJECT_INSTRUCTIONS.md`
- Aktif teknik kapsam:
  güncel GitHub Issue

Eski roadmap fazları, Epic #97/#105/#127–#140, Orchestrator O0–O10 programı,
Bridge, Work Mode ve PR #259 tarihsel kayıttır. Bunlar güncel V2 sırasını
override etmez ve aktif ürün blocker'ı sayılmaz.

## 3. V2 ana bağımlılık zinciri

```text
Proje/Mahal — complete
→ Saha Rehberi — complete
→ Attachment v2 — complete
→ Ajanda v2 — complete
→ schedule runtime + persistent reference snapshots — merged foundation
→ 7 Günlük Yaşayan İş Programı — current
→ Günlük Log v1
→ İş Zinciri
→ Günlük Log v2
```

Temel kural:

> Teknik sistem binlerce aktivite ve deterministik bağımlılık taşıyabilir;
> şantiye şefinin ana akışı ise aktiviteyi bulup yakın plana birkaç işlemle
> eklemek ve yalnız önündeki yedi günü güncel tutmak kadar sade kalır.

## 4. Dalga 1 — Kimlik ve bağlam omurgası

### V2.1 — Proje ve Mahal omurgası

Öncelik: `P0 foundation`

Durum: `complete`

Teslimatlar:

- Proje düzenleme ve recoverable archive/restore
- Stable mahal/konum kimliği
- Duplicate/normalization kuralları
- Eski kayıtların kontrollü migration'ı
- Ajanda, Hatırlatıcı, Puantaj ve Beton bağlarının korunması
- Backup/restore compatibility

Geçiş kapısı:

- Proje veya mahal adı değişse dahi source bağlantısı bozulmaz.
- Eski schema'dan yükseltme atomik ve testlidir.
- Saha kullanıcısı aktif/arşivli bağlamı güvenle yönetebilir.

Önerilen child Issue sırası:

1. Domain ve migration preflight
2. Schema/repository/application
3. Yönetim UI'sı
4. Mevcut modül adoption'ı
5. Backup/restore ve saha kabulü

### V2.2 — Sicil / Puantaj V2 / Saha Rehberi

Öncelik: `P0 data identity`

Durum: `complete`

Teslimatlar:

- Ortak kişi ve firma kimliği
- Taşeron → ekip → personel hiyerarşisi
- Puantajın canonical personel ID kullanması
- Aktif/arşiv yaşam döngüsü
- İletişim ve saha rehberi görünümü
- Mevcut belge/KKD/İSG/SGK bağlarının korunması

Geçiş kapısı:

- Aynı kişi farklı modüllerde duplicate kimlik oluşturmaz.
- Arşivlenen kişi geçmiş Puantajda kalır, yeni güne varsayılan eklenmez.
- Saha rehberi gerçek kullanımda hızlı ve filtrelenebilir durumdadır.

## 5. Dalga 2 — Ortak dosya ve günlük kayıt omurgası

### V2.3 — Attachment / Fotoğraf / Medya V2

Öncelik: `P0 integrity`

Durum: `complete`

Teslimatlar:

- Ortak attachment ve entity-link sözleşmesi
- Fotoğraf, video, ses ve belge desteği
- Çoklu seçim
- MIME/hash/size/path doğrulaması
- Atomik staging ve orphan diagnostic
- Tek dosya, çoklu kayıt bağlantısı
- Backup/restore bütünlüğü

Geçiş kapısı:

- Aynı binary farklı modüller için yeniden kopyalanmaz.
- Kırık bağlantı ve bozuk dosya görünürdür.
- Source kayıt ve exact attachment bağı korunur.

### V2.4 — Ajanda V2 ve kontrollü Ajanda–Hatırlatıcı senkronu

Öncelik: `P0 daily flow`

Durum: `complete`

Teslimatlar:

- Saha olay zaman çizgisi
- Kaynaklı Hatırlatıcı oluşturma
- Çift yönlü navigasyon ve durum görünürlüğü
- Kullanıcı kontrollü metin/durum senkronu
- Attachment görünürlüğü
- Revision/event geçmişi
- Duplicate/stale/rollback güvenliği

Geçiş kapısı:

- Ajanda ve Hatırlatıcı ayrı source-of-truth olarak kalır.
- Kullanıcı onayı olmadan sessiz yeniden yazma yoktur.
- Archive/trash sonrasında kaynak bağı kaybolmaz.

Kapanış durumu:

- Issue #432 / #434 / #437 dilimleri ve Issue #439 final closure merged
  `master` üzerindedir.
- Items 1–4 complete'tir; revised Item 5 current direction'dır.

## 6. Dalga 3 — Günlük iş yönetimi

### V2.5 — 7 Günlük Yaşayan İş Programı / İş ve Gün Planı

Öncelik: `P0 current site-management loop`

Durum: `current direction — not complete`

- Projeye özgü güncel yedi günlük pencere
- İnşaat aktivite kataloğunda arama ve birkaç işlemle plana ekleme
- Aktivite adı ile blok/kat/mahal bağlamı
- Onaylı baseline gibi sunulmayan öneri tarih ve süre
- Minimum durumlar: `Planlandı`, `Başladı`, `Tamamlandı`, `Ertelendi`
- Kısa saha notu, offline persistence ve normal backup/restore
- Immutable reference schedule'dan ayrı mutable/evented kullanıcı karar katmanı
- Stable project/activity-instance/snapshot kimliklerine referans
- Kullanıcı işlemiyle reference schedule'ı sessizce yeniden yazmama

Issue #466 / PR #467 ile merged schema 16 actual-progress source-of-truth
temelinde `NULL` raporlanmamış/bilinmeyen ilerleme, açık item için explicit
`0..99`, tamamlanan item için exact `100` anlamındadır. Optimistic revision,
durable idempotency/no-op receipt ve append-only event sözleşmesi korunur.

Issue #468 current evolution olarak bu progress gerçeğini kartlarda görünür
kılar, yalnız `STARTED`/`DEFERRED` item için `0..99` editini açar ve isolated
acceptance paketinde lifecycle/relaunch persistence kanıtını hedefler. Actual
quantity, reforecast ve project-specific productivity learning başlamaz. Item 5
not complete kalır; final completion sonraki owner kararı ve executable evidence'a
bağlıdır. Items 6–13'ün sırası değişmez.

### V2.6 — Günlük Log Çıktısı v1

Öncelik: `P1 reporting after usable living plan`

- Ajanda, Puantaj, Beton, açık takip ve living-plan/progress kaynaklı günlük
  taslak
- Proje/gün filtresi
- Deterministik sıra
- Private/project kapsam kontrolü
- Kaynak kayda geri bağlantı
- İlk insan okunabilir çıktı

### V2.7 — İş Zinciri / Bağlı Log v1

Öncelik: `P1 traceability`

- Başlangıç, takip, bekleme, kontrol ve sonuç bağlantıları
- Source-of-truth kayıtları değiştirmeyen read-model
- Kırık bağlantı diagnostic'i
- İşin neden açık/kapalı olduğunun görünürlüğü

Dalga 3 kapanış kapısı:

- Kullanıcı gün içindeki işi, kanıtı ve sonucu tekrar yazmadan izleyebilir.
- Günlük taslak kaynak kayıtlarla açıklanabilir.
- Ağır workflow motoru veya otomatik saha kararı eklenmemiştir.

## 7. Dalga 4 — Yardımcı saha akışları

### V2.8 — İstenecek Malzemeler

- Malzeme, miktar/birim, ihtiyaç tarihi, öncelik ve açıklama
- `İhtiyaç var → İstendi → Geldi / İptal`
- Proje/mahal/iş bağlantısı
- Tam satın alma, teklif, sipariş ve ERP kapsam dışı

### V2.9 — Deterministik kişi/firma/etiket önerileri

- Mevcut kayıtlardan açıklanabilir öneri
- Offline, deterministik ve kullanıcı onaylı
- Yeni kişi/firma uydurmama
- Kalıcı mutation öncesi açık seçim

### V2.10 — Telefon görüşmesi sonucu → Ajanda

- Kullanıcı tarafından başlatılan hızlı görüşme sonucu kaydı
- Kişi/firma/proje/mahal bağlamı
- Opsiyonel bağlı Hatırlatıcı veya iş
- Çağrı geçmişi ve rehber için gereksiz izin yok
- Gönderildi/okundu iddiası yok

## 8. Dalga 5 — Medya ve yayımlanmış günlük

### V2.11 — Proje fotoğraf/video albümü

- Ortak attachment read-modeli
- Proje, mahal, tarih, kategori ve kaynak filtreleri
- Thumbnail/player sınırı
- Depolama ve backup boyutu görünürlüğü
- Kaynak kayda hızlı geçiş

### V2.12 — Günlük Log Çıktısı v2

- v1 saha bulgularına dayalı geliştirme
- Seçilebilir bölümler
- İş zinciri, malzeme ve medya ilişkileri
- Canlı taslak ile yayımlanmış immutable snapshot ayrımı
- Revision/ek modeli
- Private veri sızıntısı regresyonu

## 9. Dalga 6 — Dar saha aracı

### V2.13 — Mini hesap makinesi

- Temel dört işlem
- Oran ve yüzde
- Decimal separator ve hata durumları
- Sonucun ilgili alana kullanıcı onayıyla aktarılması
- `eval`, arbitrary code ve ileri mühendislik hesapları yok

## 10. V2 dışında kalanlar

Aşağıdaki başlıklar V2 milestone'una alınmaz:

- Universal Capture
- Voice Capture / Asistan Gelen Kutusu
- Open Loop
- Sabah Brifingi / Akşam Kapanışı
- Büyük Resim / Saha Nabzı
- Beton Paketi V2
- Kalite / İSG özel dikeyleri
- Doküman Hafızası
- Şantiye krokisi
- Gömülü AI ve semantik arama
- Full-project Gantt editing ve Primavera replacement
- Approved/contractual baseline, critical path ve float hesapları
- Resource/material/machine optimization
- PC senkronizasyonu
- Multi-user, tenant, firma portalı ve SaaS
- Orchestrator, Bridge ve Work Mode geliştirmeleri

Bu başlıklar ayrı post-V2 backlog'da tarihsel olarak korunur.

## 11. Yürütme disiplini

1. Aynı anda yalnız bir production implementation Issue'su aktiftir.
2. Her Issue tek V2 maddesine ve dar değişen sözleşmeye bağlıdır.
3. `P0` veri kaybı, yanlış bağlama ve backup bozulması yeni özellikten önce
   çözülür.
4. Migration varsa eski schema ve backup compatibility test edilir.
5. Gerçek kullanıcı data root'u otomasyona açılmaz.
6. Değişmeyen release/device kapıları gereksiz tekrar edilmez.
7. Merge, release ve store yayını ayrı kullanıcı kararı gerektirir.
8. Geçmiş Issue/PR/test/podcast kayıtları geriye dönük yeniden yazılmaz.
9. Living Plan için yalnız tek dar MVP Core dilimi UI'dan önce gelebilir;
   immediate successor 7-day UI + APK/device kabulüdür.

## 12. Güncel işlem

Güncel canonical faz:

```text
Living 7-Day Plan — current, not complete
→ Issue #466 / PR #467 actual-progress source-of-truth core — merged
→ Issue #468 progress UI + isolated device acceptance — current
```

Items 1–4 complete'tir. Activity Catalog Runtime, typed Project Profile ve
Dependency Catalog, Project Activity Instance Graph, deterministic Schedule
Date Engine ve immutable persistent reference-schedule snapshots PR #444, #446,
#448, #456 ve #459 zinciriyle merged temeldir.

Issue #466 / PR #467 nullable actual-progress source-of-truth foundation'ını,
optimistic revision ve durable idempotency/no-op receipt sözleşmesini merged
temele ekler. Issue #468 yalnız progress UI ve isolated device acceptance current
evolution'ıdır; actual quantity, reforecast ve productivity learning başlamaz.
Item 5'in final completion sınırı sonraki owner kararı ve executable evidence
ile belirlenir; Items 6–13'ün sırası değişmez.

## 13. Tarihsel roadmap sınırı

31 Temmuz 2026 ve öncesindeki geniş Asistan-Öncelikli roadmap, Orchestrator
O0–O10 programı ve eski Faz 1–12 Epic'leri Git geçmişinde ve ilgili
Issue'larda korunur. Tamamlanmamış maddeler tamamlanmış sayılmaz. Güncel
production sırası yalnız bu roadmap ve `docs/v2/CSE_V2_SCOPE.md` üzerinden
belirlenir.
