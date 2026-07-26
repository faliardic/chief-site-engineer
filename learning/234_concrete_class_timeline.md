# Issue #234 — Beton Kataloğu ve Yönetilen Ajanda Öğrenme Notu

## Neyi çözdük?

Beton paketinde iki ayrı problem aynı dikey işlemde çözüldü: sınıf adlarının
serbest metinle dağılması ve saha başlangıç/bitişinin Ajanda'da ikinci bir
gerçekliğe dönüşmesi. Beton Paketi source-of-truth kaldı; katalog tekrar
kullanımı, Ajanda ise yönetilen projection sağlar.

## Migration yaklaşımı

Mevcut `concrete_pours` child graph'ını yeniden kurmak yerine schema 10'da
composite FK'li bir context tablosu eklendi:

```text
concrete_pours (snapshot)
        │
        └── concrete_pour_context_links
              ├── project_concrete_classes
              └── field_observations (nullable, unique)
```

Bu tasarım mevcut mikser, numune, kanıt, reminder ve event FK'lerini olduğu
gibi bırakırken aynı proje invariant'ını database seviyesinde kurar. Legacy
seed sırası `project_id, created_at, id` olduğundan ilk görünür yazım ve
varsayılan slump deterministiktir. Kimlik içerikten `_migrationStableUuid`
ile türetilir.

```dart
final displayName = snapshot.trim().replaceAll(RegExp(r'\s+'), ' ');
if (displayName.isEmpty) {
  throw StateError('legacy concrete class is empty');
}
final normalizedName = displayName.toLowerCase();
```

Boş değeri “Tanımsız” diye sessizce düzeltmedik; kullanıcı verisinin anlamını
uydurmak yerine tüm migration'ı rollback ettik.

## Snapshot neden katalogdan ayrı?

Katalog display adı veya archive durumu zamanla değişebilir. Paket üzerindeki
`concrete_class` ise döküm anındaki tarihsel kanıttır. Yeni create command
`concreteClassId` alır, application aktif/same-project kataloğu doğrular ve o
andaki display adını snapshot'a yazar. Sonraki paket update'i snapshot metnini
değiştirmeye çalışırsa reddedilir.

Varsayılan slump yalnız form ön değeridir:

```dart
final targetSlump =
    command.targetSlump ?? selectedClass.defaultTargetSlump;
```

Kullanıcı paket özelinde bunu değiştirebilir; katalog geçmiş paketi yeniden
yazmaz.

## Atomik Beton–Ajanda akışı

Başlatma içinde Agenda application'ı ayrı connection ile çağırmak transaction'ı
bölerdi. Bunun yerine Concrete application aynı SQLite transaction'da kanonik
Ajanda tablolarına yönetilen projection yazar:

```text
validate checklist
→ update Concrete + actual_started_at
→ append pour.started
→ insert field_observation
→ append concrete_pour.started
→ set unique Agenda link
→ append agenda.linked
→ COMMIT
```

Test hook'u Agenda yazımından önce hata ürettiğinde Beton status, timestamp,
event, Ajanda row ve linkin hiçbirinin kalmadığı doğrulanır. Bitiş aynı logun
revision'ını artırır ve `concrete_pour.completed` event'i ekler.

## Idempotency ve gerçek zaman

Transition idempotency kontrolü stale revision kontrolünden önce aynı
`eventId + pourId` çiftini tanır. Böylece network/UI retry eski expected revision
ile gelse bile zaten tamamlanan command no-op döner. İlk timestamp:

```dart
actualStartedAt = existing.actualStartedAt ?? now;
actualEndedAt = existing.actualEndedAt ?? now;
```

olarak korunur. Bitişin başlangıçtan önce olması açıkça reddedilir. `poured`
yalnız saha dökümünün bittiğini söyler; follow-up ve close validation'ları ayrı
kalır.

## Split truth nasıl engellendi?

Agenda detail read-modeli unique context linkinden `managedConcretePourId`
okur. UI edit/archive düğmelerini göstermez. Daha önemlisi yalnız UI'a
güvenilmez: `updateAgendaLog` ve `mutateAgendaLogArchive` transaction içinde
managed link kontrolü yapıp mutation'ı reddeder. İki taraf da karşı kayda
deep-link verir.

Fotoğraflar ve attachment store değiştirilmedi. Yönetilen loga yeni reminder
otomatik eklenmedi; mevcut Beton follow-up reminder sayısı başlangıç ve bitişte
aynı kaldı.

## Testlerin amacı

- `app_database_test.dart`: seed normalizasyonu, proje izolasyonu, snapshot ve
  child history korunumu, fail-closed rollback, FK/trigger.
- `concrete_application_test.dart`: katalog lifecycle, default slump/snapshot,
  direct draft/prepared start, gerçek zaman/idempotency, tek log, rollback,
  split-truth reddi ve legacy repair.
- `agenda_application_test.dart`: mevcut Agenda davranışının regresyonsuzluğu.
- `concrete_widget_test.dart` ve `mobile_agenda_widget_test.dart`: üç aşama,
  ana eylemler, büyük metin/minimum hedef ve çift yönlü managed navigation.
- `mobile_backup_application_test.dart`: format 1 ile schema `1–9 → 10` restore
  ve schema 10 katalog/link/event round-trip.

## Şunu şöyle yaptık ki...

- Şunu şöyle yaptık ki eski dökümler katalog değişiminden etkilenmesin:
  snapshot metnini pakette zorunlu bıraktık.
- Şunu şöyle yaptık ki Ajanda ikinci source-of-truth olmasın: logu Beton
  transaction'ının yönettiği projection yaptık ve bağımsız edit/archive'i hem
  application hem UI katmanında kapattık.
- Şunu şöyle yaptık ki retry gerçek zamanı değiştirmesin: command event
  idempotency'sini revision reddinden önce kontrol ettik.
- Şunu şöyle yaptık ki kısmi başlangıç oluşmasın: Beton, Ajanda, link ve iki
  event zincirini tek SQLite transaction'a aldık.
- Şunu şöyle yaptık ki kapsam büyümesin: keyword, attachment v2, viewer,
  mix-design, API ve platform/release koduna başlamadık.
