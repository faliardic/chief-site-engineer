# Issue #260 — Beton Checklist Source-of-Truth Hotfix

## Problem

Beton detay başlığı pending checklist satırlarının tamamını sayıyor, transition
validation ise yalnız required pending satırları ayrı SQL ile kontrol ediyordu.
Daha kritik olarak laboratuvar randevusu ve yapı denetim bildirimi Beton alanları
güncellendiğinde karşılık gelen required checklist satırları senkronlanmıyordu.
Bu nedenle kullanıcı manuel kalemleri tamamladığında iki gerçek kaynak alanı
doldursa bile `Dökümü başlat` generic blocker ile durabiliyordu.

Kök neden gerçek kullanıcı kaydı okunmadan iki sentetik durumla doğrulandı:

- Manuel kalemler tamam, iki kaynak alan boş: exact iki blocker açık kalır ve
  transition fail-closed durur.
- Manuel kalemler ve iki kaynak alan dolu: required pending kümesi boşalır,
  başlık `0 açık` olur ve transition başlayabilir.

## Uygulanan sözleşme

`pendingRequiredConcreteChecks` current checklist item'larından deterministik
required-pending kümesini üretir. Detay metriği, UI başlığı ve transition
validation aynı domain kuralına bağlandı. Liste metriğindeki SQL projection da
aynı `is_required = 1 AND status = 'pending'` koşulunu kullanır.

Laboratuvar ve yapı denetim checklist anahtarları domain'de system-owned olarak
tanımlandı. Sonuç olarak:

- `bulkComplete` yalnız pending manual checks ve manual follow-up'ları tamamlar;
- `updateCheck` system-owned satırı yeni bir event ile manuel değiştirmeyi
  reddeder;
- Beton alanı set edilince ilgili checklist satırı `completed`, temizlenince
  yeniden `pending` olur;
- checklist, follow-up, linked reminder ve event senkronu `updatePour`
  transaction'ının içindedir;
- mutation fresh `ConcretePourDetail` döndürür ve UI aynı mutation/reload
  zincirinde güncellenir.

## UI

Toplu eylem `Manuel maddeleri tamamla` olarak adlandırıldı. Onay dialog'u
laboratuvar randevusu ve yapı denetim bildiriminin ayrıca gerçek alanlarından
tamamlanacağını açıklar. Pending system-owned satırlar:

- `Laboratuvar randevusunu güncelle`
- `Yapı denetime bildirimi güncelle`

eylemlerini gösterir ve ikisi de mevcut `Laboratuvar / yapı denetim durumunu
güncelle` dialog'unu kullanır.

## Atomiklik ve compatibility

- Bulk completion tek transaction'dır.
- Stale revision hiçbir remaining item'ı değiştirmez.
- Derived checklist event insert hatası source alanlar ve iki checklist satırı
  dahil tüm transaction'ı rollback eder.
- Aynı event ID retry duplicate event veya ek revision üretmez.
- Schema `10`, backup formatı `1` ve migration seti değişmez.
- Döküm bitirme ve kapanış validation'ları korunur.

## Kaynak doğrulaması

- Focused Beton application: `24 PASS`
- Focused Beton widget: `13 PASS`
- Flutter full suite: `275 PASS`
- Flutter analyze: `PASS`

Fiziksel doğrulama yalnız imza uyumlu normal field APK ile, gerçek kullanıcı
Beton kayıtları okunmadan veya değiştirilmeden sentetik paket üzerinde yapılır.
