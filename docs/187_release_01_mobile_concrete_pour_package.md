# Issue #187 — Release 0.1 Mobil Beton Döküm Paketi

## Amaç ve sınır

Bu dilim, şantiye şefinin tek bir beton dökümünü telefonda planlamasından
kapanış kanıtına kadar yönetir. Telefon device-of-truth, mobil SQLite business
source-of-truth'tur. Android ve iOS aynı Dart domain/application sözleşmesini
kullanır; Python/Flask, ağ, LAN veya cloud çalışma bağımlılığı değildir.

Bu teslim genel `PackageTemplate` motoru, otomatik kabul/red, dış kurum API'si,
OCR, ücret/hakediş, çoklu kullanıcı, release hardening veya store submission
değildir. Uygulama eksikleri görünür ve kapanış kapılarını fail-closed tutar;
teknik kabul kararını kullanıcı adına vermez.

## Schema 4 → 5

Tek atomik migration aşağıdaki tabloları ekler:

| Tablo | Sorumluluk |
| --- | --- |
| `concrete_pours` | Proje/döküm kodu, plan, durum, revision ve terminal zamanlar |
| `concrete_check_items` | On bir deterministic hazırlık kontrolü |
| `concrete_trucks` | Mikser, irsaliye, zaman, metraj ve sonuç |
| `concrete_sample_sets` | Numune kimlikleri, teslim ve sonuç tarihleri |
| `concrete_follow_up_items` | Kür, yüzey, kalıp, sonuç ve eksik kanıt takibi |
| `concrete_attachments` | Kesin source, MIME, boyut, SHA-256 ve relative path |
| `concrete_pour_events` | Monoton sequence kullanan append-only geçmiş |

`follow_up_items` ve `follow_up_events`, optional Beton kaynağı için güvenli
table rebuild ile genişletilir. Observation, Puantaj günü ve Beton kaynağından
en fazla biri dolu olabilir. Concrete source varsa project zorunludur ve
composite foreign key aynı projeyi doğrular. Eski Ajanda, notification binding,
Puantaj linki ve event satırları birebir kopyalanır. Migration failure bütün
schema/veri değişikliklerini rollback eder.

## Aggregate ve yaşam döngüsü

Her mutation immutable command ve `expectedRevision` alır. Stale command yeni
row/event yazmadan reddedilir. No-op revision veya event üretmez. Başarılı
mutation aggregate revision'ını ve `concrete_pour_events` sequence'ini tek
transaction içinde ilerletir.

```text
draft → prepared → pouring → poured → follow_up → closed
  │         │          │         │          │
  └─────────┴──────────┴─────────┴──────────┴→ cancelled
closed/cancelled ── gerekçeli reopen ──→ draft
```

`poured → closed` doğrudan geçiş de desteklenir; ancak aynı kapanış kapıları
uygulanır. Required pending checklist, truck yokluğu, eksik irsaliye/mikser
kanıtı, açık numune/takip veya açıklamasız metraj farkı kapanışı engeller.
`not_applicable` ve `exception` açık gerekçe ister.

## Mikser, numune ve türetilen özet

Mikser sıra ve irsaliye numarası döküm içinde unique'tir. Batch, varış ve
boşaltma zamanları kronolojik; metraj pozitif olmalıdır. `held`, `returned` ve
`partial` sonuçları gerekçesiz kaydedilemez. Gerçek gelen metraj ayrı düzenlenen
kolon değildir:

```text
actualDelivered = Σ received.volumeM3 + Σ partial.volumeM3
variance = actualDelivered - plannedVolume
variancePercent = variance / plannedVolume × 100
```

Numune seti kaynak mikser taşıyabilir. Sampled durumunda alma zamanı, pozitif
adet ve her numunenin etiketi; delivered ve sonrası için teslim zamanı;
exception için gerekçe zorunludur. Laboratuvar teslimi ve her sonuç tarihi
Beton kaynağına ilk insert'ten itibaren bağlı reminder üretir.

## Kanıt dosyası transaction sınırı

Kanıt işlemi şu sırayı kullanır:

1. Paket, revision ve exact truck/sample/check kaynağı salt-okunur doğrulanır.
2. Kamera, galeri veya dosya picker permission sonucu güvenli biçimde alınır.
3. Uzantıya değil byte imzasına bakılarak JPEG/PNG/HEIC/PDF MIME tanınır.
4. Boyut sınırı uygulanır, staging dosyası yazılır ve SHA-256 hesaplanır.
5. Dosya güvenli application attachment kökünde atomik rename ile finalize olur.
6. Transaction kaynakları tekrar doğrular; duplicate hash'i açıkça reddeder.
7. Attachment row, aggregate revision ve `evidence.attached` event'i birlikte
   yazılır.
8. DB/event failure olursa final orphan dosya temizlenir; file failure row
   üretmez.

Database yalnız package-relative path saklar. Absolute cihaz yolu, raw platform
exception, secret veya signing verisi event/report içine girmez. Restart
okuması dosyanın SHA-256 değerini yeniden hesaplayarak `ok | missing | tampered`
diagnostic üretir.

## Reminder orkestrasyonu

Santral, yapı denetim, laboratuvar, döküm başlangıcı, kür, ilk yüzey kontrolü,
kalıp notu ve eksik kanıt built-in takipleri paketle oluşturulur. Numune teslim
ve sonuç reminder'ları numune setiyle eklenir. Takip adımı tamamlanınca follow-up
row, linked reminder row, iki append-only geçmiş ve notification binding aynı
SQLite transaction'ında tutarlı hale gelir.

Reminder ekranındaki erteleme, tamamlama veya başlık değişikliği source Beton
paketini sessizce değiştirmez. Reminder detayından pakete, paketten reminder
detayına deep-link vardır. Permission/plugin failure reminder veya package
row'unu kaybettirmez; SQLite kaynak kayıt olarak kalır ve reconciliation yeniden
denenir. Android exact-alarm izni kullanılmaz.

## Mobil yüzey

Liste şu grupları ve deterministic `planned_at, created_at, id` sırasını sunar:

- Bugün;
- Yaklaşan;
- Dökümde;
- Takipte;
- Kapalı/iptal.

Proje, İstanbul tarihi ve wildcard yorumlamayan `instr` literal arama filtreleri
vardır. Kart açık checklist, eksik truck kanıtı ve açık takip sayılarını gösterir.
Oluşturma formu minimum proje, mahal, İstanbul tarih/saat, beton sınıfı ve
pozitif plan metrajı ister; kod boşsa sabit create UUID'sinden görünür kod üretir.
Slump, santral/randevu, pompa, laboratuvar/randevu ve yapı denetim bildirimi
opsiyonel fakat görünürdür. Validation hatasında controller state ve sabit UUID
korunur; submit sırasında çift dokunma devre dışıdır.

Döküm günü ekranı 320–430 px dikey kullanımda özet, checklist, geçişler,
mikser/irsaliye, iki ayrı truck kanıt düğmesi, numune, takip, reminder, event
timeline ve export işlemini tek kaydırılabilir yüzeyde verir. Material düğmeler
minimum 48 px hedef sağlar.

## Rapor

Markdown raporu UTF-8 BOM ile ve deterministic sırayla şunları taşır:

- proje, mahal, İstanbul zamanı, beton sınıfı ve metraj;
- planlama tarafları;
- checklist durum ve exception'ları;
- mikser/irsaliye zaman çizelgesi;
- kanıt relative adı, türü, boyutu, SHA-256 ve integrity diagnostic;
- numune/takip/reminder bilgileri;
- event özeti ve JSON-ready veri.

Truck CSV helper'ı quote escaping ve `= + - @` formula injection koruması
uygular. Rapor staging → atomic finalize ile yazılır. `report.exported` yalnız
dosya başarıyla hazırlandıktan sonra eklenir; sonraki transaction failure staged
dosyayı temizler. Share sheet yalnız kullanıcı işlemiyle açılır.

## Doğrulama kapsamı

- schema 4→5 korunumu, rollback, FK, unique, append-only ve no-delete;
- create/update/idempotent/stale/no-op ve bütün status geçişleri;
- checklist, truck kronolojisi/metrajı, sample lifecycle ve kapanış kapıları;
- exact Beton reminder linki, bağımsız reminder mutation ve transaction rollback;
- MIME/boyut/hash/duplicate/atomic finalize/orphan cleanup ve restart integrity;
- türetilen metraj/sayaç/timeline;
- 320 px, uzun Türkçe, input preservation ve double tap;
- UTF-8/formula-safe deterministic export;
- mevcut Flutter ve Python regresyonları, Android build/integration ve iOS statik
  platform konfigürasyonu.
