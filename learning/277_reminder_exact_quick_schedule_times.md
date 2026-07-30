# Issue #277 — Hatırlatıcı Exact Hızlı Planlama Zamanları Öğrenimi

## Gerçek hata modeli

“Yarın” ve “hafta başı” yalnız süre ekleme işlemi değildir:

```text
operation UTC zamanı
→ Europe/Istanbul yerel günü
→ takvim günü seçimi
→ yerel 08:00
→ canonical UTC timestamp
```

`now + 24 saat` takvim yarınıyla aynı sözleşme değildir. Benzer biçimde mevcut
hatırlatıcı saatini ertesi güne kopyalamak, kullanıcıya gösterilen `Yarın 08:00`
eylemini karşılamaz. Haftanın başlangıcında da “sonraki pazartesi” ile “içinde
bulunulan haftanın pazartesisi” açıkça ayrılmalıdır.

## Kod akışı

Takvim hesabı UI veya SQLite içinde tekrarlanmadı. Domain katmanındaki saf
resolver'lar yalnız `CseTimeCodec` kullanır:

```dart
final today = CseTimeCodec.istanbulDayKey(
  CseTimeCodec.encodeUtc(nowUtc),
);
final tomorrow = CseTimeCodec.shiftIstanbulDay(today, 1);
```

Sonraki hafta başlangıcı şu delta ile seçilir:

```dart
final dayDelta = 8 - local.weekday;
```

`DateTime.weekday` pazartesi için `1` verdiğinden pazartesi günü delta `7`,
pazar günü delta `1` olur. Seçilen yerel gün, `hour: 8, minute: 0` bileşenleriyle
canonical UTC'ye çevrilir.

Create ve detail reschedule akışı aynı resolver'ı iki amaçla kullanır:

1. Kullanıcı seçim yapmadan exact yerel tarih/saat preview'sini görür.
2. Application mutation, operation anında sonucu yeniden çözüp preview ile
   exact karşılaştırır.

Bu karşılaştırma gece sınırında açık kalan formun sessizce başka güne
planlanmasını engeller. Uyuşmazlıkta kullanıcı yeniden seçmeye yönlendirilir;
eski preview veya gizli fallback kabul edilmez.

Timed snooze doğrudan tomorrow resolver'ına gider:

```dart
values['next_attention_at'] = resolveReminderTomorrowMorningAt(now);
values['all_day_local_date'] = null;
```

All-day dalı bu kod yoluna girmez. Yerel gün bir artırılır,
`next_attention_at` boş kalır ve notification reconciliation saatli plan
üretmez.

## Test yaklaşımı

Saf resolver testleri ay sonu, yıl sonu, haftanın her günü ve pazartesi `+7`
gün sınırını fixed clock ile doğrular. Lifecycle testleri create, reschedule,
snooze, all-day korunumu, idempotency, rollback, append-only event ve
notification binding değerlerini exact canonical string'lerle karşılaştırır.

Widget testleri form preview'sini, detail sheet'teki iki exact subtitle'ı,
timed/all-day quick action dilini, async guard'ı ve stale preview fail-closed
hatasını doğrular. Concrete regression, başka bir feature içindeki eski timed
snooze beklentisini yeni ortak `08:00` sözleşmesine explicit canonical
değerlerle hizalar; production kapsamını genişletmez.

Tablet wide smoke aynı zinciri gerçek UI, SQLite row/event/binding ve native
notification planı üzerinde doğrular. Recents'tan kullanıcı-seviyesi kapatma
sonrası cold relaunch, canonical değerlerin yalnız geçici UI state'i olmadığını
kanıtlar.

## Teknik karar

Quick schedule timestamp'i saklanan yeni bir ayar veya platform davranışı
değildir. Domain resolver source-of-truth'tur; UI preview ve application
mutation bunun iki tüketicisidir. Preview timestamp'inin command'a taşınması
bir schedule override değil, kullanıcıya gösterilen seçimin operation anında
hâlâ geçerli olduğunu kanıtlayan optimistic guard'dır.

Schema `10`, backup formatı `1`, migration, storage DDL, notification gateway
ve Android native değişmedi. Telefon promotion ve D29.3'ün diğer maddeleri
ayrı kapsamda bırakıldı.

## Şunu şöyle yaptık ki...

İstanbul takvim gününü önce çözüp sonra yerel `08:00`ı canonical UTC'ye
çevirdik ki süre ekleme veya eski saati kopyalama hatası oluşmasın. Form ve
detail preview'sini aynı resolver'dan ürettik ki kullanıcı gördüğü exact zamanı
seçsin. Preview'yi mutation anında yeniden doğruladık ki gün sınırı geçildiğinde
sessizce farklı bir tarih kaydedilmesin. Timed ve all-day snooze dallarını ayrı
tuttuk ki exact saat sözleşmesi tam gün kayıtların türünü değiştirmesin.
