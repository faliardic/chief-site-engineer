# Issue #227 — Reminder Trash/Restore Öğrenme Notu

## Amaç

Bu adımda “Sil” niyetini veri kaybı oluşturmayan ayrı bir visibility lifecycle
olarak uyguladık. Reminder'ın iş durumu ile ekranda görünür olma durumu aynı
kavram yapılmadı.

## Gerçek kodda ne değişti?

| Katman | Değişiklik | Amaç |
| --- | --- | --- |
| Domain | `trashedAt`, trash view ve iki mutation | Status'tan bağımsız görünürlük |
| SQLite | Schema 9 ve event vocabulary | Atomik, geri alınabilir persistence |
| Application | Query filtresi, mutation ve reconciliation | Lifecycle/source/notification korunumu |
| UI | `Sil`, confirmation, Trash listesi, `Geri yükle` | Açık ve geri alınabilir kullanıcı yolu |
| Backup | Schema 1–8 → 9 matrisi ve schema 9 round-trip | Eski yedekleri kaybetmeme |

## Neden yeni status eklemedik?

Status şu soruya cevap verir:

```text
İş açık mı, tamamlandı mı, iptal mi?
```

Trash ise şuna cevap verir:

```text
Bu kayıt normal reminder görünümlerinde gösterilmeli mi?
```

Bu iki ekseni birleştirsek completed reminder trash edildiğinde önceki terminal
sonucu kaybolur, restore sırasında hangi duruma dönüleceği ayrıca saklanmak
zorunda kalırdı. Nullable timestamp ile status/schedule/outcome zaten olduğu
yerde kalır:

```dart
case ReminderMutationAction.moveToTrash:
  if (current.trashedAt != null) return 'trashed';
  values['trashed_at'] = nowValue;
  return 'trashed';

case ReminderMutationAction.restoreFromTrash:
  if (current.trashedAt == null) return 'restored_from_trash';
  values['trashed_at'] = null;
  return 'restored_from_trash';
```

No-op kontrolü update/event yazımından önce çalıştığı için duplicate komut
revision veya history üretmez.

## Atomik migration nasıl çalışıyor?

Schema 9 iki işi aynı SQLite transaction'ında yapar:

1. `follow_up_items` tablosuna nullable, canonical biçim kontrollü
   `trashed_at` ekler.
2. `follow_up_events` tablosunu mevcut satırları değiştirmeden yeni event
   vocabulary ile rebuild eder.

Migration runner yalnız bütün işlemler başarılı olursa `user_version = 9` ve
schema history satırını yazar. Enjekte edilen hata testinde column, geçici event
tablosu ve version değişikliği birlikte rollback olur.

## Normal sorgular neden iki kez korunuyor?

SQL normal yüzeylerde açık filtre taşır:

```sql
WHERE f.trashed_at IS NULL AND (...)
```

Saf Bugün classifier'ı da dışarıdan verilmiş adayları savunmacı biçimde
atlar:

```dart
for (final reminder in reminders) {
  if (reminder.trashedAt != null) continue;
  unique.putIfAbsent(reminder.id, () => reminder);
}
```

SQL performans ve count doğruluğunu sağlar. Saf classifier koruması ise test
fake'i veya gelecekteki farklı repository yanlışlıkla trash aday gönderirse UI
görünürlüğünün bozulmasını önler.

## Source bağlantıları nasıl korundu?

Trash yalnız reminder satırını günceller. `field_observations`,
`attendance_days`, `concrete_pours`, attendance link ve concrete follow-up
satırlarında update/delete yoktur.

Source uygulamalarının otomatik reminder eşitlemesi trash kaydı görürse
lifecycle update'ini atlar. Böylece source kaydı doğal iş akışında değişse bile
trash reminder'ın “restore edildiğinde aynen dön” snapshot'ı bozulmaz.

## Notification reconciliation

Eligibility artık şu dört koşuldur:

```text
trashed_at IS NULL
AND status = active
AND next_attention_at IS NOT NULL
AND due > now
```

Trash edilen kayıt work listesinde kalır fakat eligible olmaz. Bu sayede aynı
platform ID cancel edilir ve binding satırı silinmeden `scheduled_for = NULL`
olur. Cancel gateway hatası `cancel_failed` diagnostic'i bırakır; database
trash mutation'ı geri alınmaz.

Restore edilen gelecekteki timed kayıt aynı platform ID ile yeniden
planlanabilir. Overdue timed kayıt Gecikenler'e döner fakat geçmiş an için yeni
alarm kurulmaz. All-day kayıt hiçbir yapay saate çevrilmez.

## Testlerin amacı

- `app_database_test.dart`: boş/dolu schema 8 → 9, source/binding/history/FK,
  canonical alan, delete trigger ve rollback.
- `reminder_lifecycle_test.dart`: active/all-day/inbox/terminal trash/restore,
  exact alan korunumu, no-op/stale, source, sıra ve notification failure.
- `agenda_application_test.dart`: mevcut Bugün/Yarın/read-model
  regresyonlarının korunması.
- `mobile_backup_application_test.dart`: schema 1–8 → 9 ve schema 9
  trash/event round-trip.
- `attendance_application_test.dart` ve `concrete_application_test.dart`:
  source lifecycle regresyonları.
- `reminder_widget_test.dart`: confirmation, normal görünümden çıkma, Trash
  empty/list/restore, 44 px hedef ve büyük yazı.
- `flutter analyze --no-pub`: bütün mobile static API/type kontrolü.

## Teknik karar tablosu

| Karar | Alternatif | Neden |
| --- | --- | --- |
| Nullable `trashed_at` | `cancelled` status | Önceki lifecycle'ı aynen korur |
| Binding satırını koru | Binding delete/recreate | Platform ID ve audit sürekliliği |
| Source sync'i trash'ta durdur | Trash kaydı sessizce güncelle | Restore snapshot'ı bozulmaz |
| No-op duplicate | İkinci event | History yalnız gerçek mutation taşır |
| Backup format 1 | Yeni envelope formatı | Wire format değişmedi |

## Şunu şöyle yaptık ki...

- Şunu şöyle yaptık ki yanlışlıkla silinen tamamlanmış kayıt tekrar aktif
  olmasın: status/outcome alanlarına dokunmadan yalnız `trashed_at` yazdık.
- Şunu şöyle yaptık ki Ajanda/Puantaj/Beton kanıtı kaybolmasın: source ve link
  tablolarını hiç mutate etmedik.
- Şunu şöyle yaptık ki notification iptal hatası veri kaybına dönüşmesin:
  persistence commit'ini authoritative bırakıp binding'e güvenli diagnostic
  yazdık.
- Şunu şöyle yaptık ki eski backup'lar kullanılabilsin: format 1'i koruyup
  schema 1–8 paketlerini staging DB'de schema 9'a migrate ettik.
- Şunu şöyle yaptık ki Trash listesi her okumada aynı olsun:
  trash zamanı, update zamanı ve ID ile deterministik sıra kullandık.

## Bilinçli olarak yapılmayanlar

Kalıcı delete, retention job, attachment byte temizliği, source cascade,
platform kodu, release artifact/gate, gerçek kullanıcı restore'u ve sonraki
roadmap blokları bu adımda başlatılmadı.
