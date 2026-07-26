# Issue #234 — Beton Sınıfı ve Döküm Zaman Çizgisi

## Veri modeli

Mobil schema 10 üç yeni kalıcı sözleşme kurar:

- `project_concrete_classes`: proje bazlı sınıf kataloğu, normalize benzersizlik,
  varsayılan slump, revision ve archive zamanı;
- `project_concrete_class_events`: create/migrate/archive/restore append-only
  geçmişi;
- `concrete_pour_context_links`: paketin katalog sınıfı ve en fazla bir
  yönetilen Ajanda kaydıyla composite proje bağları.

`concrete_pours.concrete_class` zorunlu snapshot olarak korunur. Katalog
arşivlense de eski paket metni ve linki değişmez. Yeni paket aktif ve aynı
projeye ait `concrete_class_id` seçmeden oluşturulamaz.

Schema 9 legacy paketleri `project_id + normalized concrete_class` sınırında
seed edilir. Normalizasyon trim, ardışık whitespace birleştirme ve lowercase
işlemidir. Kimlikler içerikten deterministik üretilir. Boş legacy snapshot
sessizce değiştirilmez; migration transaction'ı fail-closed rollback olur.

## Lifecycle

Kullanıcıya dönük aşama yeni database status'u değildir:

```text
actual_started_at NULL                         → Planlandı
actual_started_at dolu, actual_ended_at NULL  → Devam ediyor
actual_ended_at dolu                           → Tamamlandı
```

`Dökümü başlat`, `draft` ve `prepared` için aynı zorunlu checklist
validation'ını uygular. Başarıda `pouring` ve ilk gerçek UTC başlangıç kaydedilir.
`Dökümü bitir` yalnız başlamış/bitmemiş `pouring` pakette ve en az bir mikserle
çalışır; `poured` ve ilk gerçek bitişi kaydeder. Retry aynı event kimliğiyle
timestamp veya event çoğaltmaz. Bitiş follow-up/closed zincirini tamamlamaz.

İptal gerçek başlangıç/bitişi silmez. Başlamadan iptal Ajanda oluşturmaz;
başladıktan sonra iptal bağlı loga audit event'i ve gerekçe ekler, sahte bitiş
yazmaz. Reopen gerçek geçmiş zamanlarını korur.

## Tek yönetilen Ajanda kaydı

İlk başarılı başlangıç aynı SQLite transaction içinde:

1. Beton status/revision/timestamp update;
2. `pour.started` event;
3. category `concrete` Ajanda row;
4. `concrete_pour.started` observation event;
5. unique paket–Ajanda linki;
6. `agenda.linked` Beton event'i

üretir. Her adım aynı transaction'dadır; Agenda hook/insert/event/link veya
Beton event hatası bütün değişiklikleri rollback eder.

Ajanda `observed_at` gerçek başlangıçtır. Açıklama döküm kodu, mahal, sınıf ve
planlanan metrajı içerir. Bitişte aynı row revision artırılarak gerçek metraj,
mikser sayısı ve süreyle güncellenir; `concrete_pour.completed` append-only
event'i eklenir. İkinci log veya ek reminder üretilmez.

Ajanda detail, linki `managedConcretePourId` olarak okur. Managed kaydın bağımsız
ana metin edit/archive mutation'ı application katmanında reddedilir; UI
`Beton paketi tarafından yönetiliyor` açıklamasıyla yalnız source pakete dönüş
sağlar. Fotoğraf/attachment sözleşmesi genişletilmez.

Schema 10 öncesinde başlamış ve linksiz paket `Ajanda kaydını oluştur` komutuyla
gerçek timestamp'lerden tek loga onarılır. Bitiş varsa tamamlanmış özet aynı
işlemde yazılır; aynı command retry duplicate üretmez.

## Backup ve sınırlar

Backup formatı `1` kalır. Schema `1–9` paketleri preflight/restore sırasında
schema 10'a yükseltilir. Schema 10 katalog, class link, Agenda link, gerçek
timestamp ve event geçmişiyle round-trip korunur. Bilinmeyen daha yeni schema
fail-closed reddedilir.

Beton keyword önerisi, generic attachment v2, PDF/Office/DWG viewer, mix-design,
laboratuvar/santral API, AI karar motoru ve Android/iOS platform kodu bu
değişiklikte başlatılmamıştır.
