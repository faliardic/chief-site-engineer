# Issue #212 — Reminder Pilot Kullanım Sözleşmesi

## Amaç

Pilot kullanıcının `Yaklaşanlar` ekranını günlük Puantaj zinciriyle doldurmadan,
hatırlatıcıyı tek dokunuşla yarına taşıyabilmesini ve geçmiş aktif kayıtları
altyapı arızası yerine doğru iş durumu olan `Gecikti` olarak görebilmesini
sağlamak.

## Yaklaşan Puantaj tekilleştirmesi

Puantaj hatırlatma ayarı her proje için 14 günlük kayan pencere üretmeye devam
eder. SQLite içindeki `attendance_days`, `attendance_day_reminder_links`,
`follow_up_items` ve event kayıtları silinmez veya birleştirilmez.

`Yaklaşanlar` read-model'i, zaten due zamanına göre sıralanmış sonuçta:

- `attendance_day_id` ve `project_id` taşıyan zincir kayıtlarından proje başına
  yalnız ilkini gösterir;
- farklı projeler için birer ilk Puantaj gösterir;
- bağımsız Ajanda/reminder kayıtlarını aynen gösterir;
- görünen ilk Puantaj tamamlanınca, iptal edilince veya geçmiş gruba düşünce
  sıradaki ileri kaydı doğal olarak görünür kılar.

Bu bir veri temizleme işlemi değil, yalnız ekran okuma projeksiyonudur.

## Doğrudan `Yarın` eylemi

`Yarın` aşağıdaki yüzeylerde menü veya dialog açmadan doğrudan bulunur:

- reminder detayı;
- `Şimdi ilgilen` kartı;
- `Gecikenler` kartı;
- aktif/bekleyen uygun `Yaklaşanlar` kartı;
- notification payload'ından açılan aynı reminder detay sayfası.

Eylem mevcut `snoozeTomorrowMorning` application mutation'ını kullanır. Bir due
varsa İstanbul yerel saat/dakikası korunur ve tarih yarına alınır. Due yoksa
yarın 09:00 Europe/Istanbul seçilir. Mutation optimistic revision, tek event,
no-op ve transaction rollback kurallarını değiştirmez; başarılı değişiklikten
sonra native notification reconciliation yeniden çalışır. İşlem sürerken buton
pasiftir ve çift dokunuş ikinci mutation üretmez.

## Gecikmiş kayıt tanısı

Teslim edilmemiş aktif reminder için sınıflama sırası şöyledir:

1. due geçmişte veya şimdi ise `Gecikti`;
2. due gelecekte ve native plan varsa `Bekliyor`;
3. due gelecekte ve native plan yoksa `Native plan bulunamadı`.

Geçmiş aktif kayıtta kritik altyapı kartı gösterilmez. `Gecikti` iş durumu
detayda görünür ve eylemler ondan sonra `Tamamla`, `Yarın`, kısa ertelemeler,
`Yeni tarih` sırasıyla sunulur. Gelecekteki native-plan eksikliği kritik tanı
olmaya devam eder. Tamamlanmış/iptal edilmiş terminal kayıtta kritik tanı
gösterilmez.

## Veri ve sürüm sınırı

- Mobil SQLite schema `7` değişmez; migration yoktur.
- `.csebackup` format `1` değişmez.
- Offline SQLite cihaz source-of-truth olmaya devam eder.
- Debug application ID `com.faliardic.chiefsiteengineer.debug` değişmez.
- Fiziksel cihaz kabulünde uninstall ve app data clear yasaktır.
- Kurulum yalnız yeni sidecar ile `adb install -r` üzerinden yapılır.
- Sentetik background/reboot APK'ları `.acceptance` sandbox'ında kalır.

## Test ve kabul matrisi

| Kapı | Doğrulanan sözleşme |
|---|---|
| Application testleri | 14 günlük zincirde tek görünür kayıt; iki projede birer kayıt; bağımsız reminder korunması; ilk kayıt tamamlanınca sıradaki |
| Lifecycle testleri | Yerel saat ve 09:00 varsayılanı; no-op; stale; rollback; native yeniden planlama; geçmiş/gelecek tanı ayrımı |
| Widget testleri | Detay, Şimdi, Gecikenler, Yaklaşanlar ve deep-link üzerinde doğrudan `Yarın`; çift dokunuş; hata; terminal/gecikmiş tanı; 320 px, büyük metin, koyu tema ve 48 px hedef |
| Kalıcılık kapıları | Restart, boot reconciliation, backup preflight/restore ve schema/format değişmezliği |
| Release kapıları | Flutter analyze/full test, Python full test, static/permission/privacy/ARM64/16 KiB/entrypoint/imza kontrolleri |
| Cihaz kapısı | Fresh doğrulanmış backup, yalnız `adb install -r`, package/veri sonkoşulları ve gerçek API 36 kabulü |

## Saha kabul kanıtı

### Artifact ve otomatik kapılar

- Saha sidecar'ı:
  `chief-site-engineer-0.1.0-issue212-reminder-pilot-ux-debug.apk`
- Boyut: `94.517.164` bayt
- SHA-256:
  `fee56c8e00dd937a461dc8990c2747a6d06b788f939ec349a2906f4213b2ea5b`
- Package: `com.faliardic.chiefsiteengineer.debug`
- Normal entrypoint marker'ı doğrulandı; sentetik background/reboot marker'ı
  normal sidecar'da bulunmadı.
- `flutter analyze`: PASS, uyarı/hata yok.
- Tam Flutter paketi: `201 passed`.
- Tam Python paketi: `1005 passed, 7 skipped`.
- Release gate: permission/privacy, ARM64, 16 KiB, APK imza, AAB ve normal
  entrypoint kontrolleriyle PASS.
- Sentetik API 36 background kabulünde 15/30/60 dakika planları ilk açılışta
  oluşturuldu, ikinci açılışta aynı platform kimlikleriyle yeniden kullanıldı.
- Sentetik API 36 reboot kabulünde boot audit `completed`; aynı logical reminder
  ve platform kimliği reboot sonrası korundu ve bildirim due sonrasında görüldü.
- Acceptance artifact'ları `.acceptance` package sandbox'ında kaldı; normal
  sidecar hash'i build öncesi/sonrası aynıydı.

### Veri koruyan fiziksel cihaz kurulumu

- Cihaz: Samsung `SM-S938B`, Android `16` / API `36`.
- Kurulum öncesi uygulama UI'ından yeni parola korumalı tam backup üretildi.
- Dış backup boyutu: `16.260.274` bayt.
- Backup SHA-256:
  `8232c6d1df1ef14cfc8b3baeaa928982aeef759312c359c9a7de96a10157a932`.
- Parola loga/dokümana yazılmadı; Windows Credential Manager'da
  `CSE-Issue212-PreInstall-Backup` hedefinde tutuldu.
- Kurulum yalnız şu veri koruyan komutla yapıldı:

```powershell
adb -s R5CY21WKZFX install -r "mobile\build\release_gate\chief-site-engineer-0.1.0-issue212-reminder-pilot-ux-debug.apk"
```

- Uninstall, `pm clear`, app data clear veya cache clear uygulanmadı.
- Kurulum öncesi/sonrası debug SQLite boyutu `651.264` bayt ve SHA-256 değeri
  `0db6bdcd27c4fb9551befb44ec6ef2c08a705de30a0e2db49fec57ad26370943`
  olarak birebir aynı kaldı.
- Yönetilen app-private dosya sayısı `14 -> 14`; schema `7` olarak açıldı.
- Cihazdaki `base.apk` SHA-256 değeri sidecar ile birebir aynı doğrulandı.
- Debug package etkin kaldı. Benzersiz veri yokluğu kanıtlanmamış production
  package kaldırılmadı; kullanıcı `0` için disabled durumda ve pilotta yalnız
  debug launcher etkindir.

### Gerçek cihaz UX kabulü

- Normal `lib/main.dart` entrypoint'i açıldı; FATAL/ANR/SQLite fatal görülmedi.
- Fiziksel DB'de bir proje için `13` ileri aktif Puantaj reminder'ı korunurken
  gerçek `Yaklaşanlar` read-model'inde yalnız `1` Puantaj kartı görüldü.
- Uygun `Yaklaşanlar` kartında doğrudan `Yarın` görüldü.
- Normal UI'da oluşturulan sentetik reminder'ın gerçek notification payload'ı
  exact detay sayfasını açtı; `Tamamla`, `Yarın` ve `Yeni tarih` doğrudan
  erişilebilirdi.
- Detaydaki `Yarın` tek dokunuşu due değerini
  `2026-07-22T18:22:42Z -> 2026-07-23T18:22:00Z` taşıdı; yerel saat/dakika,
  logical kimlik ve aynı native platform kimliği korundu, revision `1 -> 2`
  oldu ve sync `scheduled` kaldı.
- İkinci sentetik reminder `2026-07-22T18:27:59Z` due değeriyle planlandı;
  uygulama süreci due öncesinde kapalıydı ve bildirim due öncesinde yoktu.
  Android bildirimi `2026-07-22T18:28:25Z` kontrolünde, yaklaşık `26` saniye
  sonra gerçek notification service üzerinde görüldü.
- Notification shade içindeki exact sentetik satıra dokunmak aynı reminder
  detayını açtı. Birleşik Flutter semantiğinde exact başlık, `Gecikti`,
  `Tamamla`, `Yarın` ve `Yeni tarih` birlikte görüldü;
  `Arka plan teslimatı garanti edilemiyor` ve `Native plan bulunamadı` yoktu.
- Tap sonrasında logical kayıt aktif, due ve revision `1` olarak kaldı;
  auto-cancel edilen native binding `cancelled` oldu ve append-only event sayısı
  `3` olarak okundu. Son salt-okunur snapshot'ta SQLite `integrity_check=ok`,
  foreign-key ihlali `0` ve schema `7` idi.

Gerçek Ajanda, Puantaj, Beton, kişi veya belge içerikleri bu kanıta yazılmadı;
yalnız privacy-safe yapısal sayım, durum ve hash değerleri kullanıldı.
