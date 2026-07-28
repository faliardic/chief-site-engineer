# Issue #260 Öğrenme Notu — Beton Checklist Source-of-Truth

## Neyi düzelttik?

Ekrandaki açık checklist sayısı ile `Dökümü başlat` validation'ı aynı görünen
veri hakkında iki farklı yoldan karar veriyordu. Ayrıca laboratuvar ve yapı
denetim kalemleri kullanıcı tarafından checkbox gibi değiştirilebiliyor, gerçek
Beton alanları ise bu kalemlerin durumunu güncellemiyordu.

Tek kuralı domain'e taşıdık:

```dart
List<ConcreteCheckItem> pendingRequiredConcreteChecks(
  Iterable<ConcreteCheckItem> checks,
) => checks.where((item) => item.isPendingRequired).toList(growable: false);
```

Bu read-model ayrı bir mutable sayaç değildir. Her okumada current checklist
satırlarından yeniden hesaplanır. UI `detail.pendingRequiredCheckCount`,
application metriği ve transition validation aynı required-pending kümesini
kullanır.

## Manual ve system-owned farkı

Manuel kalemler saha şefi tarafından checklist üzerinden tamamlanabilir.
`inspection_notified` ve `laboratory_appointment` ise system-owned'dur; kanıtları
Beton paketinin ilgili kaynak alanlarıdır.

```dart
const concreteSystemOwnedCheckItemKeys = <String>{
  concreteInspectionNotifiedCheckKey,
  concreteLaboratoryAppointmentCheckKey,
};
```

Bulk query pending satırları okur, fakat domain helper yalnız manual olanları
seçer. `updateCheck` de system-owned kaleme yapılan yeni manuel mutation'ı
fail-closed reddeder.

## Transaction akışı

Alan güncellemesinde şu sıra tek SQLite transaction içindedir:

```text
ConcretePour alanlarını güncelle
→ pour.details_updated event'i
→ system-owned checklist set/clear senkronu
→ deterministic check.updated event'i
→ field follow-up ve linked reminder senkronu
→ fresh ConcretePourDetail
```

Checklist update veya event insert sırasında hata olursa source alan update'i de
rollback olur. Böylece UI'da laboratuvar alanı dolu görünürken blocker'ın açık
kalması gibi partial state oluşmaz. Deterministic event ID item revision'ını
içerdiği için aynı başarıyla kaydedilmiş mutation retry edildiğinde duplicate
event oluşmaz.

## Widget çalışma akışı

320 px, 1.6 büyük metin ve dark theme sentetik testinde:

1. Üç blocker ile start denendi ve exact blocker kümesi gösterildi.
2. Manuel bulk çift tetiklendi; yalnız bir mutation başladı ve beklerken sayı
   optimistic olarak değişmedi.
3. Bulk tamamlanınca yalnız iki system-owned blocker kaldı.
4. Exact laboratuvar/yapı denetim eylemi mevcut ortak dialog'u açtı.
5. İki gerçek alan tamamlanınca reload zincirinde `0 açık` göründü.
6. Refresh ikonuna basmadan `Dökümü başlat`, ardından `Dökümü bitir` çalıştı.
7. Sayfa yeniden oluşturulduğunda durum korundu.

## Testlerin amacı

- Application testleri: manual/system ayrımı, exact count ve blocker metni,
  field set/clear, transition, stale rollback, derived-event rollback,
  idempotent retry ve restart persistence.
- Widget testleri: dil, exact eylemler, otomatik reload, 320 px/büyük
  metin/dark theme, double-tap guard ve partial optimistic UI yokluğu.
- Full suite ve analyze: Beton dışındaki mevcut sözleşmelerin korunması.

## Şunu şöyle yaptık ki...

System-owned satırları UI'da yalnız kilitli göstermekle yetinmedik; application
katmanında da manuel mutation'ı reddettik ki başka bir çağrı noktası güvenlik
koşullarını atlayamasın. Alan set/clear senkronunu ayrı bir sonradan-onarım işi
yerine source mutation transaction'ına koyduk ki kullanıcı aynı ekranda hemen
doğru sayıyı görsün ve event/reminder hatası partial completion bırakmasın.
