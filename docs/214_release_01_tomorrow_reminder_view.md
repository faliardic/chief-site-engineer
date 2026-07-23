# Issue #214 — Yarın Hatırlatıcı Görünümü

## Amaç

Hatırlatıcı ana ekranında `Bugün` ve `Yaklaşanlar`dan ayrı bir `Yarın`
projection'ı sunmak. Kullanıcı yalnız Europe/Istanbul yerel takvimine göre yarın
due olan, hâlâ takip edilebilir aktif/bekleyen kayıtları görür.

## Görünüm sırası ve dokunma hedefi

Filtre sırası şöyledir:

```text
Şimdi ilgilen | Gecikenler | Bugün | Yarın
Bekliyorum | Tekrar kontrol | Yaklaşanlar
Unutma Kutusu | Geçmiş
```

Ekran genişliğine göre `Wrap` yeni satıra geçebilir. Her `ChoiceChip` en az 48
px yüksekliğe zorlanır. 320 px/koyu tema ve 430 px/açık tema, 1,6× metin
ölçeğiyle test edilir.

## Europe/Istanbul yarın aralığı

Uygulama saati bir kez okunur. Bu UTC an önce İstanbul yerel gün anahtarına
çevrilir. Yerel yarın günü bir gün kaydırılarak bulunur ve şu yarı açık aralık
kullanılır:

```text
[yarın 00:00 Europe/Istanbul, sonraki gün 00:00 Europe/Istanbul)
```

Her iki sınır kanonik UTC string'e dönüştürüldükten sonra SQL parametresi olur.
Bu nedenle UTC tarih parçası yerel tarihten farklı olsa bile kayıt doğru gruba
girer. Başlangıç dahildir, sonraki gün başlangıcı hariçtir.

## Read-model sözleşmesi

`Yarın` yalnız aşağıdaki koşulların tümünü sağlayan kayıtları döndürür:

- status `active` veya `waiting`;
- `next_attention_at` null değil;
- due, İstanbul yarın aralığında;
- sıralama due artan, important azalan, created/id deterministic tie-break.

Bugün, geçmiş, yarından sonrası, `inbox`, `completed` ve `cancelled` kayıtlar
gösterilmez. Filtreyi açmak reminder, event veya native notification mutation'ı
üretmez.

## Puantaj tekilleştirmesi

Issue #212 ile eklenen source bağlantılı tekilleştirme hem `Yaklaşanlar` hem
`Yarın` için ortak yardımcıdan çalışır:

- `attendanceDayId` ve `projectId` taşıyan kayıtlar proje kimliğiyle gruplanır;
- due sırasındaki ilk Puantaj görünür;
- farklı projeler için birer kayıt görünür;
- bağımsız reminder'lar aynen korunur;
- bütün fiziksel Puantaj/reminder/link/event kayıtları SQLite'ta kalır.

## Kart davranışı ve boş durum

`Yarın` filtresindeki kart detay sayfasını açar fakat kart altında hızlı `Yarın`
mutation'ı göstermez. Aynı isimli filtre ile erteleme eylemi karışmaz. Detay
sayfasındaki `Yarın`, `Yeni tarih` ve kısa erteleme eylemleri korunur.

`Şimdi ilgilen`, `Gecikenler` ve `Yaklaşanlar` kartlarındaki hızlı `Yarın`
eylemi değişmez.

Boş projection yalnız şu kullanıcı mesajını gösterir:

```text
Yarın için planlanmış hatırlatıcı yok.
```

Boş durumda native notification diagnostic'i üretilmez.

## Veri ve sürüm sınırı

- Mobil SQLite schema `7` değişmez; migration yoktur.
- `.csebackup` format `1` değişmez.
- Notification scheduling, exact alarm, boot reconciliation ve payload değişmez.
- Logical reminder, Puantaj, link veya event kaydı silinmez/birleştirilmez.
- Debug application ID `com.faliardic.chiefsiteengineer.debug` değişmez.
- Fiziksel cihazda uninstall, disable, `pm clear`, data/cache clear yasaktır.
- Kurulum yalnız yeni sidecar ile `adb install -r` üzerinden yapılır.

## Test ve kabul matrisi

| Kapı | Doğrulanan sözleşme |
|---|---|
| Application | İstanbul 23:59/00:00/23:59/sonraki 00:00 sınırları; UTC/yerel tarih farkı; status ve due-null dışlama; read-only revision/event |
| Puantaj | Aynı projede birden çok fiziksel yarın occurrence'ından en erken; iki projede birer; bağımsız reminder korunumu |
| Widget | Ayrı filtre, özel boş durum, kart hızlı mutation yokluğu, diğer üç yüzeyin korunması, detail navigation |
| Responsive | 320 px dark ve 430 px light, 1,6× metin, 48 px filtre/kart hedefleri |
| Kalıcılık | Restart, timezone, backup/restore, schema/format ve append-only regresyonları |
| Release | Flutter analyze/full test, Python full test, permission/privacy/ARM64/16 KiB/entrypoint/imza |
| Cihaz | Fresh backup, yalnız `adb install -r`, package/veri sonkoşulları ve gerçek API 36 UX kabulü |

## Saha kabul kanıtı

### Test, release ve artifact

- `flutter analyze`: uyarı/hata yok.
- Tam Flutter paketi: `206 passed`.
- Tam Python paketi: `1005 passed, 7 skipped`.
- API 36 emülatör smoke, permission/privacy, normal entrypoint, debug package,
  ARM64, 16 KiB zip alignment, APK imza, unsigned/signed AAB ve universal RC
  kapıları tek release-gate koşusunda geçti.
- Normal sidecar:
  `chief-site-engineer-0.1.0-issue214-tomorrow-reminder-view-debug.apk`,
  `94.517.788` bayt, SHA-256
  `0f6649712f2d62ccd72305c959334478554704128a5aac4bde7caf3d676377c7`.
- Ephemeral RC: `22.937.796` bayt, SHA-256
  `4324f6db3bcdb2dd8f7436f52968f3842b5af84e7ae02449cb8814123ab9c9a8`.
- Background acceptance APK SHA-256:
  `bab1dde3e593972c8b096fc7e3fdeca9a63da7c142ae4e67c8705cca5dbbb7c9`.
- Reboot acceptance APK SHA-256:
  `0be10681e9af195976956a1547da1f375bfa1c49fd998dcb993f60be26183ada`.
- Acceptance build'leri ayrı `.acceptance` sandbox'ında kaldı ve normal sidecar
  hash'ini değiştirmedi.

### Emülatör background/reboot kabulü

- Background ilk açılışta 15/30/60 dakika için üç planı `created` üretti;
  ikinci açılışta üç benzersiz platform ID aynı kaldı ve `reused` oldu.
- Reboot planı `2026-07-23T02:15:29Z` due ve `468694911` platform ID ile taze
  oluşturuldu. Reboot sonrasında app UI açılmadan boot audit `completed` oldu.
- Due sonrasında aynı package/platform ID active notification olarak görüldü;
  acceptance activity kendiliğinden resumed olmadı. Sonraki kullanıcı açılışı
  kaydı `reused` ve aynı platform ID olarak gösterdi.

### Veri koruyan fiziksel kurulum

- Cihaz: `R5CY21WKZFX`, Samsung SM-S938B, Android 16 / API 36.
- UI'dan yeni pre-install yedek oluşturuldu. App-private ve Downloads kopyaları
  `16.262.903` bayt ve aynı SHA-256 değerindedir:
  `3b0716ff013c79e9f611af078d114c76a07705209523f644fda449346d86c8d5`.
- Dış kopya:
  `C:\Users\Fatih\Downloads\cse_mobile_backup_issue214_preinstall_20260723_022033.csebackup`.
  Parola rapora/loga yazılmadı; yalnız Windows Credential Manager
  `CSE-Issue214-PreInstall-Backup` hedefinde saklandı.
- Önceki kurulu APK SHA-256 değeri Issue #212 sidecar'ıyla aynıydı:
  `fee56c8e00dd937a461dc8990c2747a6d06b788f939ec349a2906f4213b2ea5b`.
- Kurulum yalnız `adb install -r` ile yapıldı. Uninstall, `pm clear`, app-data
  clear, cache clear veya debug package disable kullanılmadı.
- Uygulama açılmadan hemen önce/sonra DB SHA-256 değeri birebir
  `a62224dd2f07439dece4de3cb286c577574822adefb9b123837b089ffa3ad15f`,
  boyut `667.648` bayt ve private dosya sayısı `16 -> 16` kaldı.
- Kurulu APK hash'i sidecar hash'iyle aynı; `.debug` açık, production package
  kapalı kaldı.

### Gerçek cihaz Yarın UX kabulü

- Normal `MainActivity` `1231 ms` toplam sürede `ok` açıldı, focus `.debug`
  package'ta kaldı ve fatal crash görülmedi.
- Filtre sırası gerçek cihazda `Şimdi ilgilen > Gecikenler > Bugün > Yarın >
  Bekliyorum > Tekrar kontrol > Yaklaşanlar > Unutma Kutusu > Geçmiş` olarak
  doğrulandı.
- Privacy-safe DB sayımı yarın aralığında `1` fiziksel Puantaj, `1` proje ve `0`
  bağımsız reminder buldu; beklenen tekilleştirilmiş sonuç `1`, UI kartı da `1`.
- Yarın kartında hızlı Yarın eylemi `0`; kart `Hatırlatıcı detayı`na açıldı ve
  detay Yarın eylemi korundu. Kritik native-plan tanısı görünmedi.
- Şimdi ilgilen, Gecikenler ve Yaklaşanlar yüzeylerinde hızlı Yarın eylemi
  sırasıyla `2`, `2`, `1` adet görünür kaldı.
- Son salt-okunur snapshot: schema `7`, `integrity_check=ok`, foreign-key ihlali
  `0`. Gerçek Ajanda, Puantaj, Beton, kişi ve belge içerikleri okunmadı veya
  rapora yazılmadı.
