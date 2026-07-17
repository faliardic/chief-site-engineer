# ADR-0002: MemoryIndex / RecordRef Read-Model Sözleşmesi

- **Durum:** Kabul edildi
- **Tarih:** 2026-07-17
- **Issue:** #147
- **Bağlayıcı üst karar:** ADR-0001 — Tek Hafıza ve Kayıt Kapsamı
- **Kapsam:** Dokümantasyon ve mimari karar; implementation değildir

## 1. Bağlam

CSE bugün üç ayrı ve geçerli kaynak kayıt ailesi taşır:

- `FieldObservationRecord` / `field_observations`;
- `FollowUpItem` / `follow_up_items`;
- `RoutineOccurrence` / `routine_occurrences` ve ona bağlam sağlayan
  `RoutineTemplate`.

Bu kayıtların kimlikleri, alanları, durum sözlükleri ve yaşam döngüleri
birbirinden farklıdır. Bu ayrım doğrudur ve korunacaktır. Buna karşılık
ADR-0001, kullanıcının ayrı kişisel ve resmî uygulama dünyaları yerine tek
**Hafıza** listesi, araması ve timeline'ı görmesini ister.

Ortak görünümü doğrudan üç kaynağa dağılmış özel sorgularla kurmak şu riskleri
doğurur:

- her consumer'ın status, zaman, önem ve kapsam eşlemesini yeniden yazması;
- aynı kaydın farklı yüzeylerde farklı yorumlanması;
- literal arama ve timeline sırasının kararsızlaşması;
- private kayıtların resmî/proje çıktısına yanlışlıkla sızması;
- schema büyüdükçe dashboard, haftalık özet ve diagnostic kodunun domain
  ayrıntılarına bağlanması.

Bütün domain kayıtlarını tek tabloya taşımak ise kaynak yaşam döngülerini,
foreign key'leri, event sözleşmelerini ve geriye uyumluluğu gereksiz yere
birleştirir. Bu nedenle ortak Hafıza için ayrı, yeniden üretilebilir bir okuma
modeli gerekir.

## 2. Karar özeti

`MemoryIndex`, ayrı domain kaynaklarından üretilen `RecordRef` satırlarının
ortak okuma koleksiyonudur.

```text
domain aggregate + append-only event history
                    |
                    v
             deterministic projector
                    |
                    v
          MemoryIndex / RecordRef read-model
                    |
                    v
 Hafıza, arama, timeline, dashboard, özet, diagnostic
```

Bağlayıcı kararlar şunlardır:

1. Kaynak domain satırı ve append-only event geçmişi source of truth'tur.
2. `MemoryIndex` türetilmiş cache/projection'dır; kaynağı onaramaz veya mutate
   edemez ve her zaman yeniden üretilebilir olmalıdır.
3. Bir `RecordRef`in kanonik anahtarı `(record_type, source_id)` çiftidir.
4. Tekil taşıma kimliği `record_ref_id`, bu çiftten deterministik türetilir;
   rastgele surrogate kimlik üretilmez.
5. İlk `record_type` allowlist'i `observation`, `follow_up` ve
   `routine_occurrence` değerleridir.
6. Ortak status dört değere normalize edilir: `open`, `waiting`, `completed`,
   `cancelled`. Kaynak ayrıntısı `status_detail` içinde kayıpsız görünür kalır.
7. Güncelleme stratejisi hybrid'dir: normal source mutation ile projection
   upsert'i aynı transaction'da; doğrulama ve kurtarma için explicit,
   deterministic rebuild/backfill.
8. Drift diagnostic olarak görünürdür; sessiz otomatik repair yapılmaz.
9. `MemoryIndex` kaynak kaydı düzenleme veya resmî çıktı uygunluğu için tek
   başına yetkili değildir. Mutation ve çıktı, kaynak application service ile
   ADR-0001 kapsam kurallarını yeniden doğrular.

## 3. Terminoloji

### `MemoryIndex`

Ortak Hafıza sorgularına uygun, yeniden üretilebilir `RecordRef` koleksiyonudur.
Bu ad bir domain aggregate, audit defteri veya yeni source-of-truth tablo anlamına
gelmez.

### `RecordRef`

Tek bir kaynak domain kaydının ortak okuma görünümüdür. Kaynak metnin veya
attachment'ın kopya sahibi değildir; düzenleme hedefini, ortak filtre alanlarını
ve arama/timeline için türetilmiş metni taşır.

### Projection

Kaynak kayıt ve event geçmişini belirli bir `projection_version` kuralıyla
`RecordRef`e dönüştürme işlemidir.

### Drift

Kaynak truth ile mevcut projection arasında eksik, fazla, eski sürümlü veya alan
değeri farklı satır bulunmasıdır. Drift kaynak kaydın bozuk olduğu anlamına
gelmez; read-model'in stale veya hatalı olabileceğini gösterir.

## 4. Source of truth ve mutation sınırı

Her kayıt türü için source of truth şudur:

| `record_type` | Ana kaynak | Geçmiş kaynağı | Ek projection bağımlılığı |
| --- | --- | --- | --- |
| `observation` | `field_observations` | `observation_events` | Yok |
| `follow_up` | `follow_up_items` | `follow_up_events` | Yok |
| `routine_occurrence` | `routine_occurrences` | `routine_occurrence_events` | Mevcut uyumlulukta `routine_templates` |

Read-model şu işlemleri **yapamaz**:

- source revision artırmak;
- source status, scope, project, title veya tarih alanı değiştirmek;
- eksik event üretmek;
- source kaydı “projection'a göre” düzeltmek;
- source kaydı silmek, arşivlemek, yeniden açmak veya dönüştürmek;
- private kaydı project kapsamına geçirmek;
- attachment, resmî çıktı veya publication kararı vermek.

Drift bulunduğunda read-model yalnız diagnostic üretir veya açık maintenance
komutuyla kendisini yeniden kurar. Source truth'a yazmaz.

## 5. Kimlik sözleşmesi

### 5.1 Kanonik anahtar

Kanonik benzersizlik anahtarı:

```text
(record_type, source_id)
```

- `source_id`, ilgili domain kaydının canonical lowercase UUID kimliğidir.
- Aynı UUID farklı kayıt türlerinde bulunabilir; çakışma sayılmaz.
- Aynı `(record_type, source_id)` için birden fazla aktif `RecordRef` olamaz.
- Idempotent upsert bu anahtarı kullanır.

### 5.2 `record_ref_id`

Tek alan isteyen consumer'lar için kararlı kimlik şu biçimde türetilir:

```text
cse-record-ref/v1/{record_type}/{source_id}
```

Örnek:

```text
cse-record-ref/v1/follow_up/8a197f18-1f3e-47c2-a3cc-e3da173eb66a
```

Kurallar:

- random UUID veya auto-increment surrogate üretilmez;
- değer rebuild, restore ve cihaz değişiminde aynı kalır;
- `record_ref_id` source kimliği değildir ve source tabloya geri yazılmaz;
- benzersizlik yine kanonik composite anahtarla korunur;
- `record_ref_id` materialize edilebilir veya okuma anında hesaplanabilir;
  iki durumda da aynı formül kullanılır;
- `v1` kimlik formatı değişirse eski token'ların çözümleme politikası ayrı ADR
  ve migration ister.

### 5.3 `record_type` allowlist'i

İlk allowlist:

```text
observation
follow_up
routine_occurrence
```

Yeni tür eklemek yalnız string eklemek değildir. Yeni tür için source truth,
ortak alan mapping'i, scope/project, status, search, deep link, rebuild,
gizlilik ve kabul testleri aynı görevde tanımlanmalıdır. Bilinmeyen tür fail-closed
reddedilir; “generic” fallback ile indekslenmez.

## 6. `RecordRef` alan sözleşmesi

| Alan | Tür / null | Kesin anlam |
| --- | --- | --- |
| `record_ref_id` | text, zorunlu | Composite anahtardan türetilen kararlı taşıma kimliği. |
| `record_type` | allowlist text, zorunlu | Kaynak domain türü; scope veya status değildir. |
| `source_id` | canonical UUID, zorunlu | Kaynak aggregate kimliği. |
| `project_id` | canonical UUID, nullable | Kayıt bağlamındaki proje; null geçerlidir ve scope çıkarımı yaptırmaz. |
| `scope` | `private \| project`, zorunlu | ADR-0001 çıktı/paylaşım kapsamı; erişim rolü değildir. |
| `occurred_at` | UTC timestamp, zorunlu | Timeline'daki iş/olay anı; son güncelleme anı değildir. |
| `created_at` | UTC timestamp, zorunlu | Kaynak aggregate'in kalıcı oluşturulma anı. |
| `updated_at` | UTC timestamp, zorunlu | Kaynak aggregate'in son gerçek değişiklik anı. |
| `status` | ortak enum, zorunlu | `open \| waiting \| completed \| cancelled`. |
| `status_detail` | text, zorunlu | Kaynak status/outcome ayrıntısını kayıpsız taşıyan tür-spesifik değer. |
| `importance` | bool, zorunlu | Ortak önemli filtresi; inference/AI sonucu değildir. |
| `archived_at` | UTC timestamp, nullable | Kaynağın açık archive anı; terminal durum archive değildir. |
| `title` | text, zorunlu | Hafıza listesinde gösterilecek deterministic başlık. |
| `search_text` | text, zorunlu | Literal arama için deterministic kaynak alan birleşimi. |
| `detail_path` | text, zorunlu | Source çalışma ekranına relative local deep link. |
| `source_revision` | integer, zorunlu | Ana kaynak aggregate'in optimistic revision değeri. |
| `source_fingerprint` | lowercase SHA-256, zorunlu | Projection girdileri ve bağımlılıklarının canonical fingerprint'i. |
| `projection_version` | integer, zorunlu | Mapping algoritmasının sürümü; schema veya source revision değildir. |

`status_detail`, `detail_path` ve `source_fingerprint` Issue'daki minimum ortak
alan kümesine eklenen zorunlu alanlardır. Ortak status sırasında bilgi kaybını,
source ekrana dönüş belirsizliğini ve template gibi bağımlılıkların gizli drift'ini
önlerler.

### 6.1 Zaman kuralları

- Kalıcı anlar canonical UTC `YYYY-MM-DDTHH:MM:SSZ` biçimindedir.
- Liste/timeline sunumu `Europe/Istanbul` yerel saatine çevrilebilir; storage ve
  tie-breaker UTC/kimlik değerleriyle kalır.
- `occurred_at`, `created_at` ve `updated_at` aynı alan değildir.
- Timeline varsayılan sırası:

```text
occurred_at DESC, record_type_order ASC, source_id ASC
```

`record_type_order`: observation `1`, follow_up `2`, routine_occurrence `3`.
Bu sıra kullanıcı önem sırası değildir; eşit timestamp'te deterministik
tie-breaker'dır.

### 6.2 Metin normalizasyonu

`title` ve her `search_text` parçası projection içinde şu şekilde hazırlanır:

1. Unicode `NFKC` normalization;
2. baş/son whitespace temizliği;
3. ardışık whitespace'in tek boşluğa indirilmesi;
4. boş/null parçanın atılması;
5. aşağıdaki mapping tablosundaki sabit sırayla newline (`\n`) birleşimi.

Harf, Türkçe karakter, noktalama veya anlam yeniden yazılmaz. Kaynak metin
değiştirilmez. Stored `search_text` display-safe metindir; literal query eşlemesi
consumer tarafında aynı Unicode/casefold kuralıyla türetilir. Tokenization,
stemming, fuzzy veya semantic arama bu ADR'nin parçası değildir.

### 6.3 Fingerprint ve projection sürümü

`source_fingerprint`, projection girdilerinin UTF-8, anahtarları sıralı ve
boşluksuz canonical JSON gösteriminin SHA-256 digest'idir. Türetilmiş
`record_ref_id` digest girdisi değildir. Routine occurrence için template'ten
okunan ilgili alanlar ve template revision da girdiye dahildir.

`projection_version` şu değişikliklerde artırılır:

- alan anlamı veya mapping sırası değişirse;
- status normalizasyonu değişirse;
- title/search normalization değişirse;
- scope/project compatibility kuralı source snapshot'a geçerse;
- fingerprint girdisi değişirse.

Yalnız database index'i eklemek veya sorgu performansını değiştirmek projection
sürümünü artırmaz.

## 7. Kayıt türü mapping'leri

### 7.1 Observation

| Ortak alan | Kaynak / kural |
| --- | --- |
| `source_id` | `FieldObservationRecord.observation_id` |
| `project_id` | `project_id` |
| `scope` | Scope alanı uygulanana kadar ADR-0001 compatibility mapping'i: `project`; sonrasında source scope |
| `occurred_at` | `observed_at` |
| `created_at` | `created_at` |
| `updated_at` | `updated_at` |
| `status` | `open -> open`, `tracking -> open`, `closed -> completed` |
| `status_detail` | Kaynak status: `open`, `tracking` veya `closed` |
| `importance` | `false`; mevcut observation kaynağında önem alanı yoktur |
| `archived_at` | `archived_at` |
| `title` | normalize edilmiş `description` |
| `search_text` | `description`, `location`, `category`, `notes`, `reported_to` |
| `detail_path` | `/observations/{source_id}` |
| `source_revision` | `revision` |

Archive edilmiş observation index'te kalır. Varsayılan Hafıza sorgusu onu
gizleyebilir; archive filtresiyle bulunabilir. `closed` terminaldir fakat
`archived_at` olmadan archive sayılmaz.

### 7.2 Follow-up

| Ortak alan | Kaynak / kural |
| --- | --- |
| `source_id` | `FollowUpItem.follow_up_id` |
| `project_id` | `project_id` (nullable) |
| `scope` | Scope alanı uygulanana kadar ADR-0001 compatibility mapping'i: `private`; sonrasında source scope |
| `occurred_at` | `created_at`; mevcut domain'de ayrı yakalama/olay zamanı yoktur |
| `created_at` | `created_at` |
| `updated_at` | `updated_at` |
| `status` | `inbox/active -> open`, `waiting -> waiting`, `completed -> completed`, `cancelled -> cancelled` |
| `status_detail` | Terminal değilse source status; terminalde `{status}:{outcome_type}` |
| `importance` | `is_important` |
| `archived_at` | `NULL`; mevcut follow-up archive alanı yoktur |
| `title` | normalize edilmiş `title` |
| `search_text` | `title`, `capture_text`, `description`, `location`, `related_person`, `condition_text`, `outcome_note` |
| `detail_path` | `/follow-ups/{source_id}` |
| `source_revision` | `revision` |

`project_id` dolu follow-up'ın scope'u otomatik `project` olmaz. Observation'a
bağlı veya `converted_to_observation` sonuçlu eski follow-up da ADR-0001 gereği
source scope migration yapılana kadar `private` kalır.

### 7.3 Routine occurrence

| Ortak alan | Kaynak / kural |
| --- | --- |
| `source_id` | `RoutineOccurrence.routine_occurrence_id` |
| `project_id` | Mevcut uyumlulukta bağlı template'in `project_id` değeri; gelecekte occurrence snapshot alanı |
| `scope` | Mevcut occurrence için ADR-0001 compatibility mapping'i: `private`; gelecekte occurrence source snapshot'ı |
| `occurred_at` | `scheduled_at_utc`; snooze edilen `next_attention_at` timeline olay anını değiştirmez |
| `created_at` | occurrence `created_at` |
| `updated_at` | En büyük event `sequence` değerinin `occurred_at` anı; history yoksa `created_at` |
| `status` | `open -> open`, `closed -> completed` |
| `status_detail` | Açıkken `open`; kapalıyken `closed:{outcome_type}` |
| `importance` | Mevcut uyumlulukta template `is_important`; gelecekte occurrence snapshot alanı |
| `archived_at` | `NULL`; closed occurrence archive değildir |
| `title` | `{template.title} — {occurrence_local_date}` |
| `search_text` | template `title`, template `description`, `occurrence_local_date`, `outcome_type`, `outcome_note` |
| `detail_path` | `/routines/{routine_template_id}#occurrence-{source_id}` |
| `source_revision` | occurrence `revision` |

Bugünkü schema occurrence üzerinde title, project, scope veya importance
snapshot'ı taşımaz. Bu nedenle mevcut projector template'i bir **uyumluluk
bağımlılığı** olarak okur; template revision ve ilgili değerler
`source_fingerprint` içine girer. Template değişikliği source occurrence'ı
mutate etmez fakat projection drift'ini görünür kılar ve ilgili ref'in yeniden
üretilmesini gerektirir.

ADR-0001'in gelecek yönü uygulanınca yeni occurrence üretim anındaki template
scope/project/importance/title bağlamını kendi source snapshot'ında taşımalıdır.
O geçiş `projection_version` artışı ve full rebuild gerektirir. Eski
occurrence'ların project/scope değeri mutable template'ten resmî çıktı kararı
olarak kullanılamaz.

Mevcut routine detail sayfası occurrence satırına kararlı anchor vermiyorsa,
ayrı UI implementation görevi `occurrence-{source_id}` anchor'ını eklemelidir.
Bu ADR template veya route değiştirmez.

## 8. Güncelleme stratejisi: hybrid projection

### 8.1 Normal mutation yolu

Source aggregate mutation'ı, append-only event ve ilgili `RecordRef` upsert'i
aynı SQLite Unit of Work transaction'ında commit edilir:

```text
source aggregate mutation
-> append-only event
-> deterministic RecordRef üret
-> (record_type, source_id) ile idempotent upsert
-> tek commit
```

Bu seçim şu crash sınırını verir:

- commit öncesi crash: source, event ve projection birlikte rollback;
- commit sonrası crash: üçü de görünür;
- retry: aynı composite key ve aynı fingerprint ikinci satır üretmez;
- no-op source command: source revision/event değişmediği için projection yazısı
  da gereksizdir.

Normal transaction'da projection hatası source mutation'ı rollback eder. Bu,
Hafıza'nın sessizce stale kalmasını engeller. Projection availability ileride
source write availability'sini kabul edilemez ölçüde etkilerse farklı async
strateji ayrı ADR ister; bu ADR gizli eventual-consistency kuyruğu tanımlamaz.

Template update'i birden fazla routine occurrence ref'ini etkileyebilir. İlk
implementation etkilenen occurrence ref'lerini source ID sırasıyla aynı
transaction'da deterministic günceller. Kalıcı queue, checkpoint veya
invalidation schema'sı ayrıca yetkilendirilmeden async davranış uygulanamaz.
Bu toplu güncelleme kabul edilemez ölçüde büyürse eventual-consistency ve
checkpoint sınırı ayrı ADR ile değiştirilir; sessizce eklenmez.

### 8.2 Idempotent upsert

Upsert davranışı:

```text
key yok
-> insert

key var ve fingerprint + projection_version aynı
-> no-op

key var ve fingerprint veya projection_version farklı
-> yalnız türetilmiş RecordRef alanlarını replace/update
```

Upsert source revision veya event üretmez. Duplicate key ayrı satıra çevrilmez;
constraint/transaction hatası olarak görünür.

### 8.3 Neden yalnız event replay değil

Mevcut observation event'lerinde aggregate sequence yoktur ve event payload'ları
tam entity snapshot değildir. Tracking event'leri sequence taşısa da her event
tam state'i içermez. Bu nedenle read-model yalnız event replay ile kurulmaz.
Aggregate'in güncel satırı projection girdisidir; append-only history updated-at,
drift ve audit bağlamını tamamlar.

## 9. Rebuild, backfill ve bakım sözleşmesi

### 9.1 Explicit maintenance

Rebuild/backfill yalnız açık maintenance komutuyla, kullanıcının seçtiği veya
uygulamanın açıkça yapılandırdığı **hedef data root** üzerinde çalışır. Gerçek
`CSE_DATA_ROOT` test veya dokümantasyon görevi tarafından otomatik bulunmaz,
açılmaz veya migrate edilmez.

### 9.2 Deterministic tarama sırası

Kaynaklar şu sabit sırayla taranır:

```text
1. observation       -> source_id ASC
2. follow_up         -> source_id ASC
3. routine_occurrence-> source_id ASC
```

Mutable zaman alanları backfill sıra anahtarı değildir. Aynı girdi, aynı
`projection_version` altında byte-equivalent alanlar ve aynı logical sıra üretir.
UI timeline sırası 6.1 bölümündeki ayrı kuraldır.

### 9.3 Shadow generation ve atomik aktivasyon

Full rebuild aktif satırları yerinde silip parça parça doldurmaz:

```text
inactive/shadow generation oluştur
-> bütün source kayıtlarını deterministic project et
-> count, unique key, allowlist, fingerprint ve privacy kontrollerini doğrula
-> tek transaction ile generation'ı active yap
-> eski generation'ı ancak yeni generation active olduktan sonra temizle
```

Implementation fiziksel shadow table yerine eşdeğer generation anahtarı
kullanabilir; görünürlük garantisi aynı olmalıdır.

### 9.4 Başarısızlık ve stale durumu

Maintenance durumu en az şu vocabulary'yi taşır:

```text
ready | stale | rebuilding | failed
```

- Rebuild başarısızsa yarım generation active olmaz.
- Önceki doğrulanmış generation varsa okunabilir kalır fakat durum/stale sürüm
  kullanıcı ve diagnostic için görünürdür.
- Önceki generation yoksa Hafıza “boş” diye yanlış başarı göstermez; unavailable
  / rebuild failed sonucu verir.
- Hata kaydı en az deneme zamanı, hedef projection version, başarısız kayıt
  anahtarı veya güvenli hata kodu ve son başarılı generation bilgisini taşır.
- Diagnostic varsayılan olarak private title/search metnini loglamaz.
- Retry yeni shadow generation ile idempotent başlar; source veriyi değiştirmez.

## 10. Drift diagnostic sözleşmesi

Read-only diagnostic en az şu durumları ayırır:

- source var, `RecordRef` yok;
- `RecordRef` var, source yok (orphan projection);
- duplicate composite key;
- `source_revision` eski;
- `source_fingerprint` farklı;
- `projection_version` eski/bilinmiyor;
- deterministic mapping alanı farklı;
- bilinmeyen `record_type`, status veya scope;
- ADR-0001'e aykırı scope/project/output adayı;
- aktif generation'ın `stale`, `rebuilding` veya `failed` olması.

Diagnostic:

- kaydı reddeden domain validation değildir;
- source veya projection üzerinde sessiz repair yapmaz;
- otomatik `blocked` domain status'u üretmez;
- özet count ve güvenli kimlikleri gösterebilir;
- private `title/search_text` değerini log, telemetry veya debug export'a
  varsayılan olarak koymaz;
- düzeltme gerekiyorsa açık rebuild maintenance işlemini önerir.

## 11. Consumer sınırları

| Consumer | `MemoryIndex` kullanımı | Zorunlu ek sınır |
| --- | --- | --- |
| Hafıza liste/filtre | Ortak type/scope/project/status/archive/importance filtreleri | Mutation deep link ile source application service'e gider |
| Timeline | `occurred_at` ve deterministic tie-breaker | Display timezone Europe/Istanbul |
| Literal arama | `title/search_text` aday seçimi | Sonuç türü, scope ve stale durumu görünür |
| Bugün/dashboard | Ortak inventory ve count | Domain'e özel overdue/attention hesabı gerekiyorsa source service yeniden okunur |
| Haftalık özet | Aday kayıt ve zaman aralığı | Resmî metne girecek kayıt source scope/project'ten yeniden doğrulanır |
| Hafızayı İndir | Bütün hafıza için inventory | Kaynak içerik yeniden okunur; private/project açık etiketlenir |
| Proje Paketi/günlük/rapor | Yalnız aday keşfi | Source `scope=project`, aynı `project_id`, archive/publication ve attachment kuralları fail-closed yeniden doğrulanır |
| Diagnostic | Missing/stale/drift görünürlüğü | Kaynak mutation veya otomatik repair yoktur |

`MemoryIndex` içindeki metin, resmî export payload'ının source'u değildir.
Export service source aggregate/event/attachment kayıtlarını yeniden okur.
Projection stale, failed veya scope bakımından belirsizse private/resmî ayrımı
lehine varsayım yapılmaz; resmî çıktı adayı reddedilir veya insan incelemesine
alınır.

## 12. Gizlilik ve güvenlik

ADR-0001 aynen uygulanır:

- `private`, erişim rolü veya encryption garantisi değil çıktı/paylaşım
  kapsamıdır;
- project bağlantısı scope değildir;
- read-model rebuild scope değiştiremez;
- private kayıt Hafıza içinde owner'a görünür olabilir fakat Proje Paketi,
  günlük veya rapora doğrudan giremez;
- Hafızayı İndir iki scope'u açık etiketlerle taşıyabilir;
- backup felaket kurtarma için bütün scope'ları taşır;
- public/resmî output projection değerine tek başına güvenemez.

Cache, debug dump, temporary shadow generation ve diagnostic çıktısı da private
veridir. Uygulama data root'u dışında açık metin projection kopyası bırakılmaz;
temporary generation başarısızlıkta temizlenir; owner-only cihaz, app lock ve
encryption eksikleri bu ADR ile çözülmüş sayılmaz.

## 13. Reddedilen alternatifler

### Bütün kayıtları tek source tabloya taşımak

Reddedildi. Domain yaşam döngülerini, foreign key'leri ve event sözlüklerini
birbirine karıştırır; migration ve veri kaybı riski üretir.

### Her consumer'ın üç repository'yi ayrı sorgulaması

Reddedildi. Mapping tekrarı ve status/scope/search drift'i üretir.

### Rastgele `record_ref_id`

Reddedildi. Rebuild sırasında kimlik değişir, duplicate ve deep-link drift'i
doğurur. Composite kaynaktan deterministic token yeterlidir.

### `project_id IS NOT NULL` ise `scope=project`

Reddedildi. ADR-0001'i ihlal eder ve private follow-up/routine verisini resmî
çıktıya sızdırabilir.

### Yalnız async event projector

Şimdilik reddedildi. Kalıcı queue/checkpoint/retry/invalidation sözleşmesi yoktur;
observation event'leri sequence ve tam snapshot taşımaz. Hybrid transactional
upsert + explicit rebuild daha küçük ve doğrulanabilirdir.

### Drift bulunduğunda source'u otomatik düzeltmek

Reddedildi. Projection source of truth değildir; otomatik repair audit ve
revision sınırını ihlal eder.

### Terminal kaydı index'ten kaldırmak

Reddedildi. Hafıza ve geçmiş görünürlüğü kaybolur. Terminal status ile archive
ayrı tutulur.

## 14. Implementation ön koşulları ve kabul matrisi

Bu ADR implementation değildir. Sonraki schema/repository/service/UI görevleri
en az şu testleri executable hale getirmelidir:

| Senaryo | Beklenen |
| --- | --- |
| Aynı source iki kez project edilir | Tek composite key; ikinci işlem no-op |
| Aynı UUID iki farklı türde bulunur | İki ayrı ref; kimlik çakışması yok |
| Rebuild iki kez çalışır | Aynı `record_ref_id`, alan, sıra ve fingerprint |
| Source mutation + event + ref başarılı | Tek transaction commit |
| Projection upsert hata verir | Source mutation ve event rollback |
| Commit öncesi crash/retry | Duplicate ref/event yok; source sözleşmesi korunur |
| Eski projection version | Stale diagnostic; açık rebuild gerekir |
| Template başlığı/önemi değişir | İlgili occurrence fingerprint drift'i görünür |
| Private project-linked follow-up | Scope private kalır; resmî output adayı değildir |
| Closed/terminal kayıt | Index'te kalır; archive sayılmaz |
| Archived observation | Index'te `archived_at` ile kalır |
| Bilinmeyen record type/status | Fail-closed; generic ref üretilmez |
| Rebuild ortada hata verir | Partial generation active olmaz |
| Previous generation varken hata | Eski generation stale/failed etiketiyle kalır |
| Hafızayı İndir inventory | İki scope görünür ve etiketli; içerik source'tan okunur |
| Proje Paketi adayı | Source scope/project tekrar doğrulanmadan export edilmez |
| Diagnostic/log | Private title/search metni varsayılan çıktıya sızmaz |
| Literal arama | Normalization deterministic; kaynak metin mutate olmaz |
| Timeline timestamp eşitliği | Record type order + source ID ile kararlı sıra |

Implementation ayrıca fresh/upgrade/restore, gerçek SQLite transaction,
canonical UUID/UTC, uniqueness, restart persistence ve gerçek kullanıcı data
root'una dokunmayan isolated fixture testleri taşımalıdır.

## 15. Sonuçlar

Olumlu sonuçlar:

- Tek Hafıza consumer'ları ortak ve test edilebilir bir sözleşme kullanır.
- Kaynak domain tabloları ve yaşam döngüleri korunur.
- Rebuild, restore ve retry kimlikleri kararlı kalır.
- Scope/project ayrımı projection içinde görünür ve çıktı katmanında yeniden
  doğrulanır.
- Drift gizlenmez; ölçülebilir diagnostic olur.

Maliyetler:

- Source mutation transaction'ı projection upsert sorumluluğu kazanır.
- Routine occurrence'ın mevcut template bağımlılığı fingerprint/invalidation
  takibi gerektirir.
- Full rebuild için shadow generation ve maintenance state gerekir.
- Ortak status yanında kaynak ayrıntısını korumak için `status_detail` gerekir.

## 16. Bu Issue'da uygulanmayanlar

- `MemoryIndex` veya `RecordRef` Python modeli;
- SQLite tablo/index/schema/migration;
- repository port/adaptörü veya Unit of Work değişikliği;
- projector, rebuild CLI, scheduler veya background worker;
- scope field/event/migration/backfill;
- Hafıza UI, template, CSS, anchor veya route;
- search, dashboard, haftalık özet veya output service değişikliği;
- backup/Hafızayı İndir/Proje Paketi formatı;
- test veya production davranışı;
- gerçek kullanıcı verisi migration'ı.

Bu alanların her biri ayrı, yetkili ve testli implementation Issue'su ister.
