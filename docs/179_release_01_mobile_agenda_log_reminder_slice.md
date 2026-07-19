# Issue #179 — Release 0.1 Mobil Ajanda Dilimi 1

## Sonuç

Issue #179, Flutter mobil uygulamada ilk gerçek saha dikey dilimini açar:

```text
Ajanda günlük logu
-> kaynak logdan bağlı hatırlatıcı
-> Hatırlatıcı listesi ve detay
-> kaynak Ajanda kaydına geri dönüş
```

Uygulama yalnız `mobile/` Dart kodunda çalışır. Telefon ana veri cihazıdır;
SQLite dosyası platform application-support sandbox'ındadır. İnternet,
bilgisayar, LAN veya Flask runtime gerekmez.

## Mobil schema 2

Schema `1` temeli korunarak tek transaction içinde schema `2` eklenir.

| Tablo | Görev | Değişmez |
| --- | --- | --- |
| `projects` | Mobil proje source-of-truth | UUID, revision, hard delete yok |
| `field_observations` | Ajanda log source-of-truth | project FK, olay/giriş zamanı ayrı |
| `observation_events` | Log geçmişi | append-only |
| `follow_up_items` | Reminder source-of-truth | project + source log composite FK |
| `follow_up_events` | Reminder geçmişi | append-only, source log ID açık |

Migration aynı transaction içinde:

1. tabloları ve constraint'leri oluşturur;
2. deterministik read-model indekslerini ekler;
3. event update/delete trigger'larını ekler;
4. aggregate hard-delete trigger'larını ekler;
5. `schema_versions` satırı ve `PRAGMA user_version=2` yazar.

Herhangi bir statement başarısız olursa schema `1`, smoke kaydı ve migration
history değişmeden kalır. Gerçek kullanıcı verisi üzerinde migration
çalıştırılmamıştır.

## Ajanda log sözleşmesi

Log alanları:

- UUID `id`;
- `project_id`;
- canonical UTC seconds `observed_at`;
- canonical UTC seconds `created_at` ve `updated_at`;
- sekiz kayıt türünden biri;
- kısa açıklama;
- opsiyonel mahal ve ayrıntılı not;
- optimistic `revision`;
- geleceğe uyumlu nullable archive alanı.

İlk kayıt türleri:

```text
general_note       -> Genel not
manufacturing      -> İmalat
inspection         -> Kontrol
meeting_decision   -> Görüşme/karar
delivery           -> Teslimat
safety             -> İş güvenliği
concrete           -> Beton
issue_delay        -> Sorun/gecikme
```

UI'daki İstanbul wall-clock tarih/saat yalnız
`CseTimeCodec.canonicalFromIstanbulComponents` üzerinden UTC'ye çevrilir.
Storage girdisi naive, offset biçimli, fractional, invalid veya future ise
fail-closed reddedilir.

Create akışı:

```text
immutable CreateAgendaLogCommand
-> UUID/canonical/text validation
-> clock yalnız bir kez
-> future policy
-> transaction
   -> project var mı?
   -> aynı ID aynı command ise idempotent return
   -> field_observations insert
   -> observation_events created insert
-> commit
```

`observed_at` geçmiş olay zamanıdır. `created_at`, command'ın kalıcı CSE giriş
anıdır; geçmiş olay zamanı entry time ile ezilmez.

## Günlük görünüm

Gün sınırı `Europe/Istanbul` başlangıcından ertesi gün başlangıcına kadar
hesaplanır; SQL aralığı `start <= observed_at < end` biçimindedir.

Sıra:

```sql
ORDER BY observed_at ASC, created_at ASC, id ASC
```

Ekran davranışları:

- Bugün;
- önceki gün;
- sonraki gün;
- date picker;
- proje filtresi;
- tür filtresi;
- açıklama/mahal/not/proje üzerinde literal arama;
- saat, tür, açıklama, proje ve mahal kartı;
- boş gün mesajı;
- log detail;
- karttan ve detail'den `Hatırlatıcı oluştur`.

Literal arama `LIKE` kullanmaz. SQLite `instr` ile `%`, `_`, `[` gibi
karakterleri wildcard olarak yorumlamadan arar.

## Log formu güvenliği

- Varsayılan tarih/saat mevcut İstanbul zamanıdır.
- Geçmiş tarih/saat seçilebilir.
- Future veya invalid seçim service katmanında reddedilir.
- Controller ve state validation hatasında temizlenmez.
- Submit başında `_submitting=true` olur ve düğme disable edilir.
- Form state'inde üretilen record/event UUID retry sırasında değişmez.
- Aynı command tekrar edilirse ikinci row veya event eklenmez.
- Başarı sonucu canonical `observed_at` gününe dönülür.
- Proje yoksa form içindeki dar `Yeni proje oluştur` işlemiyle mobil project
  source kaydı açılabilir.

## Bağlı reminder sözleşmesi

Reminder alanları:

- UUID `id`;
- `project_id`;
- `observation_id` source log bağlantısı;
- değiştirilebilir title;
- `action | waiting | recheck` türü;
- `inbox | active | waiting | completed | cancelled` status vocabulary;
- nullable canonical `next_attention_at`;
- revision ve create/update timestamp'leri.

Bu dilimde oluşturma seçenekleri:

| Seçenek | Storage sonucu |
| --- | --- |
| Unutma Kutusu | `status=inbox`, attention `NULL` |
| 15 dakika | clock + 15 dakika |
| 1 saat | clock + 1 saat |
| Bugün çıkmadan | aynı İstanbul günü 18:00 |
| Yarın sabah | sonraki İstanbul günü 09:00 |
| Özel tarih/saat | strict İstanbul wall-clock → UTC |

`waiting` türünde zamanlı kayıt `status=waiting`; diğer zamanlı kayıtlar
`status=active` başlar. Custom veya “bugün çıkmadan” sonucu future değilse
fail-closed reddedilir.

Create transaction sırası:

```text
command validation ve schedule çözümü
-> transaction
   -> project var mı?
   -> source log aynı project içinde var mı?
   -> idempotent retry kontrolü
   -> follow_up_items insert (source link ilk andan itibaren var)
   -> follow_up_events created insert
-> commit
```

Event insert veya başka bir write başarısız olursa reminder row da rollback
olur. Creation event'in kolon ve JSON payload'ı source observation ID taşır.
Bir logdan farklı UUID'lerle birden fazla reminder oluşturulabilir.

## Hatırlatıcı görünümü ve deep-link

Minimum çalışan read-model:

- Unutma Kutusu: `status=inbox`;
- Bugün: açık ve bugünün sonundan önce dikkat isteyen kayıtlar; overdue görünür;
- Yaklaşanlar: bugünün bitiminden sonraki kayıtlar;
- reminder detail;
- reminder detail → source Ajanda detail;
- Ajanda detail → bağlı reminder detail.

Reminder create source log row'unun revision, updated timestamp veya içeriğini
değiştirmez.

## Eşzamanlı SQLite açılışları

`IndexedStack`, Ajanda ve Hatırlatıcı state'lerini aynı shell açılışında
başlatabilir. Android'de aynı database dosyasına iki `singleInstance:false`
açılış yarışı olmaması için aynı `SqliteAgendaApplication` üzerindeki DB
işlemleri bir `Future` kuyruğunda seri çalışır. Her işlem yine kendi kısa DB
bağlantısını açıp kapatır; SQLite transaction atomikliği değişmez.

## Mobil kullanılabilirlik

- 320 px test viewport'unda taşma yoktur.
- Uzun Türkçe project/description/location metni ellipsis veya wrap ile korunur.
- Dropdown'lar `isExpanded` kullanır.
- Ana işlem düğmeleri 48–52 px, minimum kabul 44 px'dir.
- Formlar `ListView` içinde olduğundan klavye ile kaydırılabilir.
- Validation sonrası controller içerikleri korunur.

## Test kanıtı

Focused Flutter testleri şunları kapsar:

- schema `1 → 2`, migration rollback ve smoke korunumu;
- FK, append-only ve hard-delete trigger'ları;
- İstanbul gün sınırı ve deterministic tie-break;
- geçmiş log, observed/created ayrımı;
- future/naive/invalid rejection;
- proje/tür/literal filtreler;
- tek clock okuması ve idempotent retry;
- tüm hızlı reminder seçenekleri ve üç reminder türü;
- source link/event payload;
- forced event failure'da partial reminder yokluğu;
- bir logdan birden fazla reminder;
- source log değişmezliği;
- restart/offline kalıcılık;
- 320 px, uzun Türkçe metin, input preservation ve çift dokunma;
- iki yönlü mobile navigation.

Android emülatör testi gerçek `sqflite` ile project/log/reminder oluşturur,
bootstrap restart yapar, detail verisini ve Ajanda/Hatırlatıcı kartlarını okur.

## Korunan sınırlar

- Python schema `4` değişmez.
- Backup format `1` ve restore allowlist `(2,3,4)` değişmez.
- Günlük Çıktı format `1` değişmez ve mobil reminder kapsamına genişlemez.
- `app/`, `tests/`, `scripts/`, web route/template ve Python requirements
  değiştirilmez.
- Attachment platform portu bağlanmaz.
- OS notification schedule/delivery çağrılmaz.
- Gerçek data root, secret, keystore veya provisioning profile kullanılmaz.
- iOS native archive Windows'ta çalıştırılmaz; statik project compatibility
  doğrulanır.
