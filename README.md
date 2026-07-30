# CHIEF SITE ENGINEER

CHIEF SITE ENGINEER (CSE), şantiye şefinin dağınık saha bilgisini hızlı kayıt,
kanıt, takip, arşiv ve devir düzenine taşıyan offline-first mobil uygulamadır.
Güncel ürün Flutter ile geliştirilir; cihaz-içi SQLite ve uygulamaya özel yerel
dosya alanını kullanır.

Python/Flask çekirdeği repository içinde tarihsel ürün omurgası, sözleşme
referansı ve geliştirici araçları için korunur. Mobil runtime bir Python/Flask
sunucusuna bağlanmaz.

## Güncel güvenli nokta

Son birleşmiş ve tamamlanmış safe point:

| Alan | Değer |
| --- | --- |
| Issue | `#277` |
| Pull Request | `#278` |
| Merge commit | `c72f6bc55fc658996a546d9833b85a2614b99327` |
| Mobil sürüm | `0.1.0+1` |
| SQLite schema | `10` |
| `.csebackup` formatı | `1` |
| Canonical timezone | `Europe/Istanbul` |
| Android compile/target SDK | `36 / 36` |

Issue #277 kanıtı focused lifecycle `48/48`, focused widget `46/46`, Beton
regression `1/1`, full Flutter `333/333`, `flutter analyze` `0` ve Samsung
`SM-X610` tablet wide smoke PASS sonucudur. Bu dar Issue için kullanıcı tablet
PASS'i fiziksel tamamlanma kapısı seçti; telefon promotion yapılmadı.

Bu kanıt test edilmiş merged davranışı gösterir. CSE henüz field-ready,
production-ready veya store-released ilan edilmiş değildir.

## Birleşmiş mobil yetenekler

### Ajanda

- Proje, gün, tür, aktif/arşiv, literal arama ve deterministik yeni/eski
  sıralama.
- Geçmiş saha zamanı, kaynak fotoğrafları ve güvenli attachment integrity yolu.
- Beton sinyalinden kullanıcı kontrollü öneri ve aynı proje/gün bağlamıyla
  Beton oluşturma deep-link'i; otomatik saha kararı veya paket üretimi yoktur.
- Detail dönüşünde route-local filtre, arama ve scroll bağlamı korunur; arama
  odağı ve klavye yalnız kullanıcı niyetiyle etkinleşir.

### Hatırlatıcı

- Ajanda, Puantaj ve Beton kaynak bağları; standalone reminder desteği.
- Schedule/reschedule, waiting, inbox, complete/cancel, reopen, çöp/geri
  yükleme ve append-only lifecycle geçmişi.
- `Yarına ertele`, iki/üç saat, ertesi gün `08:00` ve sonraki pazartesi `08:00`
  hızlı planlama davranışları.
- Source-of-truth SQLite ile Android/iOS pending notification reconciliation;
  bir reminder mutation'ının ilgisiz reminder bildirimini silmemesi için
  izolasyon.
- Reminder detayında kaynak Ajanda fotoğraflarının salt-okunur görünümü.

### Puantaj

- Proje personeli, ekip/taşeron, tam/yarım gün, gelmedi/izin, fazla mesai ve
  notlar.
- Taslak, tamamlandı, çalışma yok ve explicit reopen yaşam döngüsü.
- Gün/ekip toplamları, CSV paylaşımı ve kaynağa bağlı çalışma günü
  hatırlatıcıları.

### Beton

- Proje bazlı Beton sınıfı kataloğu ve legacy değerler için deterministik
  schema `10` migration'ı.
- Paket oluşturma; planlanan/gerçek zaman çizgisi; required checklist,
  mikser/irsaliye, numune, takip ve kapanış blocker'ları.
- System-owned checklist kalemleri, optimistic revision, append-only event ve
  transaction içinde yönetilen Ajanda projeksiyonu.
- JPEG/PNG/HEIC/PDF kanıtı için MIME sniff, boyut/hash kontrolü, atomik staging
  ve orphan cleanup.
- İnsan-okunabilir paket raporu, CSV/JSON-ready özet ve attachment manifesti.

### Hafıza ve yedekleme

- Mobil SQLite ve aktif kanıtları tek `.csebackup` format `1` paketine alan
  şifreli backup.
- PBKDF2-HMAC-SHA256 anahtar türetme, AES-256-GCM authenticated encryption,
  hash/size/integrity kontrolleri ve atomik finalize.
- Restore preflight, traversal/symlink/extra-entry reddi, desteklenen eski
  schema'ların yalnız staging'de schema `10`a migration'ı, safety backup,
  journal ve fail-closed rollback.
- Secret, parola, absolute kullanıcı yolu ve signing materyali state ya da
  manifest içine yazılmaz.

## Uygulanan ve uygulanmayan iş sınırı

| Durum | Kayıt | Ürün gerçeği |
| --- | --- | --- |
| Birleşmiş safe point | Issue `#277`, PR `#278` | Uygulanmış ve doğrulanmış |
| Aktif, duraklatılmış | Issue `#279` | README/NotebookLM senkronu için paused; birleşmemiş davranış uygulanmış sayılmaz |
| Açık Draft altyapı | PR `#259` | Conflicting; physical smoke acceptance harness birleşmiş değildir |
| Açık pilot/release işleri | Issues `#245`, `#254`, `#256`, `#257` | Plan/altyapı kaydı; merged ürün özelliği değildir |

Issue #279 dalındaki fail-closed widget blocker'ı, bu safe point'in ve README'de
anlatılan birleşmiş davranışın parçası değildir. PR #259 da ayrı bir Draft
altyapı çalışmasıdır; mobil ürün capability'si gibi sunulmaz.

## Repository yapısı

```text
mobile/                 Flutter Android/iOS uygulaması
src/                    Python/Flask tarihsel çekirdek ve destek kodu
tests/                  Python doğrulama suite'i
scripts/                Deterministik geliştirici ve release araçları
docs/                   Protokoller, kararlar, podcast ve öğrenim belgeleri
.cse/state/             Küçük canonical proje durumu
.cse/tasks/             Issue yürütme sözleşmeleri
.cse/results/           Issue doğrulama ve tamamlama kanıtları
```

## Geliştirici başlangıcı

Python doğrulaması:

```powershell
python -m pytest
```

NotebookLM rolling source:

```powershell
python -m pytest tests/test_notebooklm_podcast_source.py
python scripts/build_notebooklm_podcast_source.py
```

Flutter geliştirme:

```powershell
cd mobile
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

Bu komutların tamamı her dar Issue için otomatik zorunlu değildir. Current
Issue sözleşmesi ve
`docs/protocols/CSE_MINIMUM_SUFFICIENT_VALIDATION_PROTOCOL.md`, değişen riske
uygun minimum yeterli doğrulamayı belirler.

## Android ve iOS sınırı

Android release kimliği `com.faliardic.chiefsiteengineer`, debug kimliği
`com.faliardic.chiefsiteengineer.debug`dır. Android uygulaması camera,
notification, reboot ve user-managed exact alarm erişimini kendi dar
sözleşmeleri için kullanır; broad storage/media ve `INTERNET` izni merged
manifestte yoktur.

iOS project/scheme ve kimlikler tracked durumdadır; gerçek archive/TestFlight
yalnız macOS, Xcode, Apple Developer hesabı ve repository dışında tutulan
signing materyaliyle üretilebilir.

Release/signing ayrıntıları:
[`docs/release/mobile_identity_signing_and_rc.md`](docs/release/mobile_identity_signing_and_rc.md).

## Dokümantasyon ve podcast

- Güncel roadmap: [`ROADMAP.md`](ROADMAP.md)
- Değişiklik geçmişi: [`CHANGELOG.md`](CHANGELOG.md)
- Teknik kararlar: [`docs/project_decisions.md`](docs/project_decisions.md)
- Mobil ayrıntılar: [`mobile/README.md`](mobile/README.md)
- Podcast protokolü:
  [`docs/podcast_notes/README.md`](docs/podcast_notes/README.md)
- Stable NotebookLM source:
  [`docs/notebooklm/CSE_PODCAST_LATEST_SOURCE.md`](docs/notebooklm/CSE_PODCAST_LATEST_SOURCE.md)

Podcast 036, legacy Adım 001–225 döneminden Issue tabanlı döneme geçer ve
Issue #227–#277 arasındaki gerçek CHANGELOG bölümlerini kapsar. Eksik Issue
numaraları tamamlanmış iş gibi uydurulmaz.
