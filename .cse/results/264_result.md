# Issue #264 — Liste gezinme state doğrulama sonucu

## Sonuç

`PASS`

Ajanda, Hatırlatıcı, Beton ve Puantaj listeleri aynı canlı route instance'ında
detay push/pop sonrasında route-local bağlamını korur. Detay dönüşü reload'u
güncel veriyi getirirken scroll controller, seçili gün/proje/görünüm ve arama
state'i yeniden oluşturulmaz. Küçülen listede offset yeni extent içine clamp
edilir.

## Kök neden kanıtı

Production editinden önce uzun sentetik widget fixture'ları aynı detay
push/pop akışını çalıştırdı:

| Ekran | Detay öncesi offset | Baseline dönüş |
| --- | ---: | ---: |
| Ajanda | 3104 | 0 |
| Hatırlatıcı | 2884 | 0 |
| Beton | anlamlı alt bölge | kartlar ve offset korunuyordu |
| Puantaj | 5120 | 4990 |

Ajanda ve Hatırlatıcı async reload sırasında liste extent'ini sıfırladığı için
controller offset'i `0`a clamp ediyordu. Puantaj reload sonrasında eski offset'i
explicit geri yüklemiyordu. Beton mevcut state'i koruyordu; ortak güvenli
restore ve duplicate-navigation sözleşmesine alındı. Dört baseline'da hızlı iki
dokunma iki detail route açabiliyordu.

## Uygulama

- Her liste route'u kendi `ScrollController` ömrünü yönetir ve `dispose` eder.
- Detay açılmadan önce mevcut offset snapshot alınır.
- Dönüş reload'u bitince post-frame callback ile offset güncel
  `maxScrollExtent` sınırına clamp edilerek geri yüklenir.
- Ajanda ve Hatırlatıcı reload boyunca son geçerli listeyi korur; geçici boş
  extent oluşmaz.
- Ajanda arama metni explicit route-local controller ile korunur.
- Dört ekranda route-local navigation guard duplicate detail push'ını engeller.
- Beton kartlarına deterministik semantic key eklendi; random/global key yoktur.
- Direct detail/deep-link davranışı ve mevcut filtre değişim semantiği korunur.

Schema `10`, backup formatı `1` olarak kaldı. Migration, preference tablosu,
global mutable state veya router rewrite eklenmedi.

## Test kanıtı

- Focused widget:
  `flutter test --no-pub test/mobile_agenda_widget_test.dart test/reminder_widget_test.dart test/concrete_widget_test.dart test/attendance_widget_test.dart`
  — `82 PASS`
- Full Flutter: `flutter test --no-pub` — `290 PASS`
- Flutter analyze: `flutter analyze --no-pub` — `PASS`, issue `0`
- `git diff --check` — `PASS`
- Focused application/domain testi çalıştırılmadı; application/domain sözleşmesi
  değişmedi.
- Source/test checkpoint:
  `8ccf2f8d3144f215996f27492ec0966e4668a07e`

Focused testler push/pop görünür bölgesi, async reload, mutation sonrası fresh
data, gruptan çıkış sonrası clamp, iki instance izolasyonu, dispose, double-tap
guard, direct deep-link regresyonu, 320 px, büyük yazı, koyu tema,
boş/tek/uzun liste ve açık klavye ile Ajanda aramasını kapsar. Android system
back ve app bar back eşdeğer dönüş davranışıyla doğrulandı.

## Tek disposable build ve artifact provenance

- Detached worktree:
  `C:\Users\Fatih\AppData\Local\Temp\cse264-validation-20260728-202519-8eade1de`
- Checkpoint: `8ccf2f8d3144f215996f27492ec0966e4668a07e`
- Run ID: `CSE264-245646f92e274c0cbf4facbf4e7fe8bf`
- Invocation başlangıcı (UTC): `2026-07-28T17:25:57.7202209Z`
- Invocation bitişi (UTC): `2026-07-28T17:27:14.8413945Z`
- Tek komut: `flutter build apk --debug`
- Artifact:
  `C:\Users\Fatih\AppData\Local\Temp\cse264-validation-20260728-202519-8eade1de\mobile\build\app\outputs\flutter-apk\app-debug.apk`
- Length: `168852282`
- Last-write (UTC): `2026-07-28T17:27:12.0342717Z`
- SHA-256:
  `27da74ae3552aa74d9e7b398842abb0cadb881fbc20f8b76df6b60e668d60ede`
- applicationId: `com.faliardic.chiefsiteengineer.debug`
- Build ve kurulu package signing SHA-256:
  `329f42b542af8576367279b59fb2802dfd545253b2906f7ba2ac12c7c6d5c869`
- Exact hash yeniden doğrulandıktan sonra
  `adb install -r -g <exact-apk>` — `PASS`

Ana worktree `mobile/build` yolunda build yapılmadı. Build invocation `1`;
retry, clean, build-root rotation ve process kill `0`; uninstall, clear-data ve
downgrade `0`.

## Fiziksel cihaz sentetik smoke

- Device: `R5CY21WKZFX`, preflight `device`
- Package: `com.faliardic.chiefsiteengineer.debug`
- Yalnız `CSE264SMOKE` önekli sentetik kayıtlar hedeflendi.

### Ajanda

Altı sentetik kayıtta anlamlı scroll ve sentetik proje bağlamı kuruldu.
`CSE264SMOKE-AJANDA-02` detayda `-GUNCEL` olarak değiştirildi. App bar back
sonrasında aynı görünür kart sınırları, proje bağlamı ve güncel başlık görüldü:
mutation + fresh reload + state korunumu `PASS`.

### Hatırlatıcı

Altı bağımsız sentetik Bugün kaydında anlamlı scroll yapıldı.
`CSE264SMOKE-HATIRLATICI-03` system back sonrasında aynı görünür bölgede kaldı.
Alt listedeki `-06` güvenli biçimde Geri Dönüşüm Kutusu'na taşınınca kart
gruptan çıktı ve en yakın kart geçerli extent içine clamp edildi: `PASS`.

### Beton

Altı sentetik pakette sentetik proje ve Bugün/Taslak bağlamı korundu.
`CSE264SMOKE-BETON-05` detayından app bar back sonrasında aynı görünür kart
bölgesi ve status bağlamı görüldü: `PASS`.

### Puantaj

Altı sentetik ekip ve önceki yerel gün seçimiyle liste aşağı kaydırıldı.
Sentetik `Günlük Puantaj` detayı açılıp system back ile dönüldüğünde proje, gün
ve aynı görünür ekip/gün bölgesi korundu: `PASS`.

Gerçek kullanıcı Ajanda, Hatırlatıcı, Beton veya Puantaj kaydı açma/değiştirme
mutasyonu `0`dır. Gerçek kullanıcı içeriği raporlanmadı.

## Sentetik temizlik

- Altı sentetik Ajanda kaydı mevcut arşiv akışıyla arşivlendi.
- Altı sentetik bağımsız Hatırlatıcı mevcut Geri Dönüşüm Kutusu akışıyla
  taşındı.
- Altı sentetik Puantaj ekibi ve tek sentetik taşeron mevcut `Pasifleştir`
  akışıyla arşivlendi.
- Beton paketinde archive/trash eylemi bulunmadığından altı sentetik paket
  hard-delete edilmedi; mevcut geri alınabilir `İptal` yaşam döngüsüne geçirildi.
- Sentetik proje, Beton sınıfı ve Puantaj gün kabında archive/trash UI akışı
  bulunmadığından fiziksel silme yapılmadı ve izole sentetik kaplar korundu.

Hard-delete `0`; gerçek kullanıcı mutation `0`; protected-path mutation `0`.

## Bütçe ve kapsam

- Tek primary implementation run kullanıldı.
- Source/test için correction run kullanılmadı.
- Fiziksel validation için tek build invocation kullanıldı.
- Değişmeyen persistence, notification, recurrence, backup ve release
  sözleşmelerinin merged kanıtları yeniden kullanıldı.
- Cold restart pixel restoration, process-death restoration, yeni filtre,
  schema/migration ve genel router değişikliği kapsam dışı kaldı.
