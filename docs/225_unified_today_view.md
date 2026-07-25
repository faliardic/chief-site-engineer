# Issue #225 — Birleşik ve Sade Bugün Görünümü

## Amaç

Hatırlatıcı sekmesi açıldığında kullanıcı filtre seçmeden bugünkü çalışma
yükünü tek ekranda görür:

```text
Gecikenler
Saatli bugün
Tam gün
```

Boş bölüm gösterilmez. Üç bölüm de boşsa tek sade boş durum görünür.

## Application read-model sözleşmesi

`ReminderTodayOverview` dört değer üretir:

| Alan | İçerik |
| --- | --- |
| `overdue` | Geçmiş timed, geçmiş gün all-day ve 18:00 sonrası bugünkü all-day |
| `timedToday` | Bugün olan ve henüz geçmemiş timed reminder |
| `allDayToday` | Bugünkü all-day, yalnız 18:00'dan önce |
| `inboxCount` | Schedule almamış açık kayıt sayısı |

Sınıflandırma UI içinde yapılmaz. Application katmanı tek `asOfUtc` değeri
alır, Europe/Istanbul yerel gün/saat karşılığını `CseTimeCodec` ile hesaplar ve
reminder kimliği bazında tekilleştirir.

## 18.00 sınırı

| Europe/Istanbul zamanı | Bugünkü all-day bölümü |
| --- | --- |
| `17:59:59` | Tam gün |
| `18:00:00` | Gecikenler |
| `18:00:01` | Gecikenler |

Bu eşik kanonik ürün varsayılanıdır. Project-level ayar veya persistence alanı
eklenmemiştir.

## Deterministik sıralama

- Saatli bugün: en erken `next_attention_at`, eşitlikte önemli kayıt, sonra
  `created_at` ve `id`.
- Tam gün: önemli kayıt, sonra `created_at` ve `id`.
- Gecikenler: logical schedule zamanı, önemli kayıt, `created_at` ve `id`.

Timed kayıt `next_attention_at < asOfUtc` ise gecikmiştir. Eşit timestamp henüz
gecikmiş sayılmaz.

## Kart etiketleri

- bugün timed: `Bugün • HH:mm`;
- bugün all-day: `Tam gün`;
- geciken timed: `Gecikti • DD.MM.YYYY HH:mm:ss`;
- 18.00 sonrası bugünkü all-day: `Gecikti • Tam gün`;
- yarın timed: `Yarın • HH:mm`;
- yarın all-day: `Yarın • Tam gün`.

`Yarın` kart eylemi bir tarih etiketi değildir; mevcut reminder mutation'ını
çalıştıran açık kullanıcı eylemidir.

## Navigasyon

Ana seçim yalnız:

```text
Bugün | Yarın | Diğer
```

`Diğer` bottom sheet'i mevcut ikincil görünümleri korur:

- Yaklaşanlar
- Unutma Kutusu
- Tekrar kontrol
- Geçmiş

Bugün read-modelinde inbox kaydı gösterilmez. Inbox doluysa
`Unutma Kutusunda N kayıt var` eylemi doğrudan ikincil Unutma Kutusu görünümünü
açar ve sessiz schedule/mutation üretmez.

## Tekilleştirme

Sınıflandırma başlamadan önce kayıtlar `reminder.id` ile tekilleştirilir. Bir
reminder en fazla bir bölüme girer. Puantaj veya Beton source linki ikinci kart
üretme nedeni değildir.

## Değişmeyen sözleşmeler

- Mobil schema `8`;
- backup format `1`;
- timed/all-day persistence invariant'ları;
- notification gateway ve native scheduling;
- complete, snooze ve Yarın mutation'ları;
- Android/iOS platform kodu.

Project-level 18.00 ayarı, trash/restore, attachment görünürlüğü ve sonraki ürün
blokları bu Issue'da uygulanmamıştır.

## Validation

Validation class `narrow-ui`dır:

- agenda application/read-model focused testleri;
- reminder widget focused testleri;
- `flutter analyze --no-pub`;
- `git diff --check`;
- exact changed-file allowlist.

Python suite, mobile full suite, APK/AAB/signing, Android release gate,
ARM64/16 KiB, background/reboot acceptance, backup/restore ve production RC
çalıştırılmaz.
