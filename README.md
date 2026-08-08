# CHIEF SITE ENGINEER

CHIEF SITE ENGINEER (CSE), şantiye şefinin saha notunu, takibini, kanıtını,
puantajını, beton kaydını ve yedeğini cihaz üzerinde güvenilir biçimde yöneten
offline-first kişisel saha asistanıdır.

Güncel ürün Flutter ile geliştirilir; cihaz-içi SQLite ve uygulamaya özel yerel
dosya alanını kullanır. Python/Flask çekirdeği repository içinde tarihsel ürün
omurgası, sözleşme referansı ve geliştirici araçları için korunur; mobil runtime
bir Python sunucusuna bağlanmaz.

## Güncel ürün durumu

| Alan | Değer |
| --- | --- |
| Ürün fazı | V1 tamamlandı; V2 planlama/truth-sync başladı |
| V1 baseline commit | `7c9f65a811c9f4bca561adab6bd1f8e64e6908cc` |
| Son V1 baseline PR | `#382` |
| Mobil sürüm | `0.1.0+1` |
| SQLite schema | `10` |
| `.csebackup` formatı | `1` |
| Canonical timezone | `Europe/Istanbul` |
| Android compile/target SDK | `36 / 36` |
| Saha kullanımı | Proje sahibi tarafından yaklaşık bir ay |
| GitHub Release / store release | Henüz ilan edilmedi |

V1'in tamamlanması ve sahada kullanılmış olması, kamuya açık production veya
store release yapıldığı anlamına gelmez. Aynı şekilde V1 modülleri dondurulmuş
değildir; V2 içinde geliştirilmeye devam eder.

## V1 mobil baseline

### Ajanda

- Proje, gün, tür, aktif/arşiv ve literal arama filtreleri
- Geçmiş saha zamanı ve deterministik sıralama
- Fotoğraf/PDF kanıtı ve güvenli attachment bütünlüğü
- Beton sinyalinden kullanıcı kontrollü öneri ve deep-link
- Detail dönüşünde route-local filtre, arama, focus ve scroll korunumu
- Salt-okunur alan değişikliği geçmişi

### Hatırlatıcı

- Standalone veya Ajanda, Puantaj ve Beton kaynaklı kayıt
- Schedule/reschedule, inbox, complete/cancel, reopen ve çöp/geri yükleme
- Tam gün ve saatli planlama
- `Yarına ertele`, iki/üç saat, ertesi gün ve hafta başı hızlı eylemleri
- Append-only lifecycle geçmişi ve optimistic revision
- SQLite source-of-truth ile native notification reconciliation
- Bir reminder mutation'ının ilgisiz bildirimi silmemesi için izolasyon

### Puantaj ve Sicil

- Taşeron, ekip ve personel bağlamı
- Tam/yarım gün, gelmedi, izin, fazla mesai ve notlar
- Taslak, tamamlandı, çalışma yok ve explicit reopen
- Gün/ekip toplamları ve CSV çıktısı
- Kaynağa bağlı çalışma günü hatırlatıcıları

### Beton

- Proje bazlı Beton sınıfı kataloğu
- Planlandı → Devam ediyor → Tamamlandı zaman çizgisi
- Required checklist, mikser/irsaliye, numune ve takip kayıtları
- Kullanıcı kararıyla kapanış ve açıklanabilir blocker görünümü
- Yönetilen Ajanda projeksiyonu
- İnsan okunabilir rapor ve attachment manifesti

### Hafıza ve yedekleme

- SQLite ve etkin kanıtları tek `.csebackup` format `1` paketinde toplama
- PBKDF2-HMAC-SHA256 ve AES-256-GCM authenticated encryption
- Attachment size/hash audit ve paket bütünlüğü
- Atomik finalize, restore preflight, safety backup, journal ve rollback
- Gerçek hazırlama, paketleme, doğrulama ve kaydetme aşamalarının görünürlüğü
- Parola, secret, absolute kullanıcı yolu ve signing materyalinin repository'ye
  yazılmaması

## CSE V2

Güncel kanonik kapsam:

[`docs/v2/CSE_V2_SCOPE.md`](docs/v2/CSE_V2_SCOPE.md)

V2 paketi 13 maddeden oluşur:

1. Proje ve Mahal omurgası
2. Sicil / Puantaj V2 / Saha Rehberi
3. Attachment / Fotoğraf / Medya V2
4. Ajanda V2 ve kontrollü Ajanda–Hatırlatıcı senkronu
5. Günlük Log Çıktısı v1
6. İş / Yapılacaklar / Gün Planı
7. İş Zinciri / Bağlı Log v1
8. İstenecek Malzemeler
9. Deterministik kişi/firma/etiket önerileri
10. Telefon görüşmesi sonucu → Ajanda
11. Proje fotoğraf/video albümü
12. Günlük Log Çıktısı v2
13. Mini hesap makinesi

Ana bağımlılık:

```text
Proje/Mahal
→ Saha Rehberi
→ Attachment v2
→ Ajanda v2
→ İş/Yapılacak
→ İş Zinciri
→ Günlük Log v2
```

İlk production yönü **Proje ve Mahal omurgasıdır**. Issue #383 yalnız
documentation/state truth-sync işidir; production davranışı değiştirmez.

## Kaynak otoritesi

| Bilgi | Yetkili kaynak |
| --- | --- |
| Kalıcı ürün amacı ve veri ilkeleri | `docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md` |
| Güncel V2 kapsamı | `docs/v2/CSE_V2_SCOPE.md` |
| Güncel sıra | `ROADMAP.md` |
| Operasyon ve güvenlik | `docs/protocols/CSE_PROJECT_INSTRUCTIONS.md` |
| Doğrulama politikası | `docs/protocols/CSE_MINIMUM_SUFFICIENT_VALIDATION_PROTOCOL.md` |
| Aktif iş | Güncel GitHub Issue |
| İkincil machine-readable snapshot | `.cse/state/project_state.json` |

Eski roadmap, Epic, Orchestrator, Bridge, Work Mode, handoff veya podcast
kayıtları tarihsel bağlamdır; güncel V2 kapsamını override etmez.

## Repository yapısı

```text
mobile/                 Flutter Android/iOS uygulaması
app/                    Python/Flask tarihsel çekirdek ve destek kodu
tests/                  Python doğrulama suite'i
scripts/                Deterministik geliştirici ve release araçları
tools/                  Geliştirici otomasyon araçları
docs/                   Protokoller, kararlar, V2 kapsamı ve teknik belgeler
.cse/state/             Machine-readable proje snapshot'ı
.cse/tasks/             Issue yürütme sözleşmeleri
.cse/results/           Doğrulama ve tamamlama kanıtları
```

## Geliştirici başlangıcı

Python doğrulaması:

```powershell
python -m pytest
```

Flutter geliştirme:

```powershell
cd mobile
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

Her dar Issue bu komutların tamamını otomatik çalıştırmaz. Değişen sözleşmeye
uygun minimum yeterli doğrulama:

[`docs/protocols/CSE_MINIMUM_SUFFICIENT_VALIDATION_PROTOCOL.md`](docs/protocols/CSE_MINIMUM_SUFFICIENT_VALIDATION_PROTOCOL.md)

tarafından belirlenir.

## Android ve iOS sınırı

Android release kimliği `com.faliardic.chiefsiteengineer`, debug kimliği
`com.faliardic.chiefsiteengineer.debug`dır. Android uygulaması camera,
notification, reboot ve user-managed exact alarm erişimini dar sözleşmeleri
için kullanır; broad storage/media ve `INTERNET` izni merged manifestte yoktur.

iOS project/scheme ve kimlikler tracked durumdadır. Gerçek archive/TestFlight
yalnız macOS, Xcode, Apple Developer hesabı ve repository dışında tutulan
signing materyaliyle üretilebilir.

Ayrıntılar:

[`docs/release/mobile_identity_signing_and_rc.md`](docs/release/mobile_identity_signing_and_rc.md)

## Olgunluk sınırı

- **V1 ürün fazı:** tamamlandı
- **Owner saha kullanımı:** yaklaşık bir ay
- **V2:** planlama ve repository truth-sync
- **Kamuya açık production release:** ilan edilmedi
- **Google Play/App Store yayını:** ilan edilmedi
- **Çok kullanıcılı/SaaS ürün:** kapsam dışı

Tarihsel test veya tablet kabulü, tek başına store-ready ilanı değildir. Saha
kullanımı da geriye dönük, gün gün kanıt uydurulmasına gerekçe oluşturmaz.
