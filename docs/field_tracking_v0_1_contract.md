# Saha Takibi v0.1 Domain ve Veri Sözleşmesi

## 1. Belgenin amacı ve kapsamı

Bu belge, GitHub Issue #98 kapsamında Saha Takibi v0.1 için uygulanacak domain ve veri sınırını kesinleştirir. Bu aşama production kodu, migration, UI veya scheduler eklemez. Sonraki implementation görevleri bu sözleşmeyi doğrudan testlere ve koda çevirecektir.

Sözleşme üç ana kaydı kapsar:

1. `FollowUpItem`: tek seferlik kişisel takip kaydı.
2. `RoutineTemplate`: tekrar kuralını taşıyan rutin şablonu.
3. `RoutineOccurrence`: belirli bir yerel gün için oluşan, şablondan bağımsız yaşam döngüsüne sahip rutin gerçekleşmesi.

Puantaj bu belgede personel hesabı veya bordro modülü değildir. Yalnızca “Her iş günü saat 17.00’de puantajı tamamla” rutinini doğrulayan kabul örneğidir.

## 2. Mevcut sistemden alınan sınırlar

Issue #98 başlamadan önceki güvenli nokta `9b631fef4f3c4a290daa3b8d651d4fc9af0e0361` olarak doğrulanmıştır.

| Mevcut yapı | Doğrulanan gerçek | Yeni sözleşmeye etkisi |
| --- | --- | --- |
| SQLite schema | `SCHEMA_VERSION = 2` | İlk implementation migration’ı sürüm 3 olmalıdır. |
| Migration runner | Bütün bekleyen migration’ları tek `BEGIN IMMEDIATE` transaction içinde uygular ve bilinmeyen sürümü reddeder | Yeni tablolar aynı fail-closed davranışla eklenmelidir. |
| Kimlik | Persistence katmanı canonical UUID string ister | Bütün yeni entity ve event kimlikleri küçük harfli canonical UUID olacaktır. |
| Zaman | Kalıcı anlar UTC, ISO 8601 ve `Z` son ekiyle tutulur | Yerel recurrence alanları ayrıca saklanacak; gerçek anlar UTC olacaktır. |
| Revision | Observation mutation’ları optimistic revision kullanır | Üç yeni ana kayıt da revision `1` ile başlayacaktır. |
| No-op | Gerçek değişiklik yoksa revision ve event artmaz | Yeni service ve repository mutation’ları da aynı davranışı koruyacaktır. |
| Event | Observation mutation + event aynı Unit of Work içindedir | Yeni mutation ve event append atomik olacaktır. |
| Backup | SQLite online snapshot ve attachment dosyaları arşivlenir | Yeni tablolar snapshot ile otomatik taşınacaktır. |
| Günlük export | Yalnız project, observation, observation event ve observation attachment verisini okur | Kişisel takip ve rutin tabloları varsayılan resmî export’a eklenmeyecektir. |

## 3. Ortak veri kuralları

### 3.1 Kimlik

- `follow_up_id`, `routine_template_id`, `routine_occurrence_id` ve bütün event kimlikleri canonical UUID string’dir.
- Kimlikler oluşturulduktan sonra değişmez.
- Büyük harf, süslü parantez veya canonical olmayan UUID yazımı reddedilir.
- Kullanıcıya görünen başlık kimlik yerine geçmez.

### 3.2 Zaman

- Bir anı gösteren bütün alanlar canonical UTC `YYYY-MM-DDTHH:MM:SSZ` biçiminde saklanır.
- Recurrence hesabının takvim temeli IANA timezone adı `Europe/Istanbul` ve yerel tarihtir.
- Template üzerindeki `local_time` `HH:MM` biçimindedir.
- Yerel tarihler `YYYY-MM-DD` biçimindedir.
- UTC zaman, `zoneinfo.ZoneInfo("Europe/Istanbul")` kullanılarak occurrence üretilirken hesaplanır; sabit `+03:00` değeri domain kuralı olarak kodlanmaz.
- Occurrence içine yazılan yerel tarih, yerel saat ve UTC karşılığı snapshot’tır. Sonraki template veya timezone veritabanı güncellemeleri geçmiş occurrence’ı yeniden hesaplamaz.

### 3.3 Metin ve önem

- Zorunlu metinler trim sonrası boş olamaz.
- Kullanıcının yazdığı metin saklanır; otomatik sınıflandırma, yeniden yazma veya kişi eşleştirme yapılmaz.
- İlk sürümde önem alanı `is_important: bool` olarak tutulur. Çok seviyeli priority sözlüğü eklenmez.

### 3.4 Revision ve no-op

- Yeni kayıt `revision = 1` ile başlar.
- Mutation çağrısı `expected_revision` taşır.
- Beklenen revision güncel değilse `RevisionConflict` eşdeğeri hata verilir; ana kayıt ve event geçmişi değişmez.
- Normalize edilmiş yeni değer mevcut değerle aynıysa işlem no-op’tur: revision, `updated_at` ve event sayısı değişmez.
- Başarılı gerçek değişiklik revision’ı tam bir artırır.

### 3.5 Silme

- Yeni tablolarda hard delete application/repository API’si bulunmaz.
- Follow-up kapanışı `completed` veya `cancelled` ile yapılır.
- Template `inactive` yapılır.
- Occurrence sonuçlandırılır; geçmiş kayıt fiziksel olarak silinmez.

## 4. `FollowUpItem` sözleşmesi

### 4.1 Alanlar

| Alan | Tür / null | Kural |
| --- | --- | --- |
| `follow_up_id` | UUID, zorunlu | Değişmez kimlik. |
| `capture_text` | text, zorunlu | Hızlı yakalamada girilen özgün metin; sonradan düzenlenen başlıktan ayrıdır. |
| `title` | text, zorunlu | Listede görünen kısa başlık. İlk oluşturma sırasında açıkça verilir; otomatik AI özeti yoktur. |
| `description` | text, nullable | Ayrıntılı açıklama. |
| `item_type` | enum, zorunlu | `action`, `waiting`, `recheck`. |
| `status` | enum, zorunlu | `inbox`, `active`, `waiting`, `completed`, `cancelled`. |
| `project_id` | UUID, zorunlu | Var olan `projects.id` kaydına foreign key. |
| `observation_id` | UUID, nullable | Var olan `field_observations.id` kaydına isteğe bağlı bağlantı. |
| `location` | text, nullable | İlk sürümde serbest metin; ayrı location migration’ı yoktur. |
| `related_person` | text, nullable | İlk sürümde serbest metin; contact foreign key zorunlu değildir. |
| `is_important` | bool, zorunlu | Varsayılan `false`. |
| `next_attention_at` | UTC timestamp, nullable | Kaydın yeniden öne çıkacağı an. |
| `deadline_at` | UTC timestamp, nullable | Gerçek son tarih; `next_attention_at` ile aynı şey değildir. |
| `condition_text` | text, nullable | “Belge gelince”, “beton öncesi” gibi koşul. |
| `outcome_type` | enum, nullable | `completed`, `not_required`, `converted_to_observation`, `cancelled`. Yalnız terminal durumda doludur. |
| `outcome_note` | text, nullable | Sonucun insan tarafından yazılan açıklaması. |
| `revision` | integer, zorunlu | `>= 1`, optimistic concurrency sayacı. |
| `created_at` | UTC timestamp, zorunlu | Değişmez oluşturma zamanı. |
| `updated_at` | UTC timestamp, zorunlu | Son gerçek mutation zamanı. |
| `completed_at` | UTC timestamp, nullable | Yalnız `completed` durumda doludur. |
| `cancelled_at` | UTC timestamp, nullable | Yalnız `cancelled` durumda doludur. |

### 4.2 Yaşam döngüsü

- Yeni kayıt hızlı yakalamada varsayılan olarak `inbox` durumunda başlar.
- Planlanan ve sahiplenilen kayıt `active` olabilir.
- Başka kişiden veya koşuldan cevap bekleyen kayıt `waiting` olabilir.
- `item_type` ile `status` aynı kavram değildir. Örneğin `waiting` türünde yakalanan kayıt önce `inbox`, sonra `waiting` durumunda olabilir.
- `completed` ve `cancelled` terminal durumlardır; yeniden açma bunları `active` durumuna getirir.
- `completed` durumda `completed_at` ve `outcome_type` zorunludur; `cancelled_at` boş olmalıdır.
- `cancelled` durumda `cancelled_at` ve `outcome_type = cancelled` zorunludur; `completed_at` boş olmalıdır.
- Terminal olmayan durumda iki kapanış zamanı ile iki outcome alanı boş olmalıdır.
- Yeniden açma kapanış zamanlarını ve outcome alanlarını ana kayıttan temizler; önceki sonuç append-only event içinde korunur.
- `waiting` durumunda kişi veya koşul girilmesi tavsiye edilir fakat hızlı saha akışını engelleyen database constraint yapılmaz.

### 4.3 Planlama ve görünüm

- İlk planlama `follow_up.scheduled`, mevcut planın değişmesi `follow_up.rescheduled` event’i üretir.
- `next_attention_at` ile `deadline_at` için zorunlu sıralama constraint’i yoktur. Kullanıcı, deadline yaklaşmadan önce veya özel durumda sonra dikkat zamanı seçebilir.
- Açık kayıt için etkin dikkat anı, dolu alanlar arasındaki en erken `next_attention_at` veya `deadline_at` değeridir.
- `overdue`: etkin dikkat anı geçmiş olan açık kayıt.
- `now`: dikkat/deadline zamanı olmayan açık kayıt.
- `today`: etkin dikkat anı gelecekte ve Europe/Istanbul yerel tarihi bugün olan açık kayıt.
- `upcoming`: etkin dikkat anı bugünden sonra olan açık kayıt.
- Terminal kayıtlar bu dört açık iş grubuna girmez.
- Bu değerler database status alanına yazılmaz; sorgu zamanı türetilir.

## 5. `RoutineTemplate` sözleşmesi

### 5.1 Alanlar

| Alan | Tür / null | Kural |
| --- | --- | --- |
| `routine_template_id` | UUID, zorunlu | Değişmez kimlik. |
| `title` | text, zorunlu | Örnek: `Puantajı tamamla`. |
| `description` | text, nullable | Rutin ayrıntısı. |
| `project_id` | UUID, zorunlu | `projects.id` foreign key. |
| `recurrence_type` | enum, zorunlu | `daily`, `weekdays`, `weekly`, `monthly`. |
| `local_time` | `HH:MM`, zorunlu | Planlanan yerel saat. |
| `timezone` | IANA name, zorunlu | v0.1’de yalnız `Europe/Istanbul`. |
| `weekdays` | ISO weekday set | Yalnız `weekly` için en az bir `1..7`; `weekdays` türünde Pazartesi–Cuma örtüktür. |
| `month_day` | integer, nullable | Yalnız `monthly` için `1..31`. |
| `start_date` | local date, zorunlu | Recurrence başlangıcı, dahil. |
| `end_date` | local date, nullable | Recurrence sonu, dahil; başlangıçtan önce olamaz. |
| `status` | enum, zorunlu | `active`, `inactive`. |
| `is_important` | bool, zorunlu | Varsayılan `false`. |
| `revision` | integer, zorunlu | `>= 1`. |
| `created_at` | UTC timestamp, zorunlu | Değişmez. |
| `updated_at` | UTC timestamp, zorunlu | Son gerçek değişiklik. |
| `deactivated_at` | UTC timestamp, nullable | Yalnız `inactive` durumda dolu. |

### 5.2 Recurrence türleri

- `daily`: başlangıç/bitiş aralığındaki her yerel takvim günü.
- `weekdays`: Pazartesi–Cuma. Resmî tatil, yarım gün, vardiya veya şirket takvimi otomasyonu yoktur.
- `weekly`: `weekdays` setinde seçilen ISO günleri; Pazartesi `1`, Pazar `7`.
- `monthly`: ay içinde `month_day` mevcutsa oluşur. Örneğin 31 seçimi Şubat’ta occurrence üretmez ve ayın son gününe kaydırılmaz.
- Template status `inactive` olduğunda yeni günler için occurrence üretilmez; geçmiş occurrence kayıtları kalır.
- Template değişikliği yalnız henüz üretilmemiş occurrence’ları etkiler.

### 5.3 Hafta günlerinin kalıcı gösterimi

`weekly` seçimleri ayrı `routine_template_weekdays` tablosunda tutulacaktır. JSON text veya virgüllü string kullanılmayacaktır.

```sql
CREATE TABLE routine_template_weekdays (
    routine_template_id TEXT NOT NULL
        REFERENCES routine_templates(id),
    iso_weekday INTEGER NOT NULL CHECK(iso_weekday BETWEEN 1 AND 7),
    PRIMARY KEY (routine_template_id, iso_weekday)
);
```

Bir `weekly` template için en az bir satır bulunması, template ve weekday satırlarını aynı transaction’da yazan application service tarafından doğrulanır. Diğer recurrence türlerinde bu tabloda satır bulunmaz.

## 6. `RoutineOccurrence` sözleşmesi

### 6.1 Alanlar

| Alan | Tür / null | Kural |
| --- | --- | --- |
| `routine_occurrence_id` | UUID, zorunlu | Değişmez occurrence kimliği. |
| `routine_template_id` | UUID, zorunlu | `routine_templates.id` foreign key. |
| `occurrence_local_date` | local date, zorunlu | Recurrence kararının yerel günü. |
| `scheduled_local_time` | `HH:MM`, zorunlu | Üretim anındaki template saatinin snapshot’ı. |
| `scheduled_at_utc` | UTC timestamp, zorunlu | Yerel tarih+saat+timezone dönüşümünün snapshot’ı. |
| `status` | enum, zorunlu | `open`, `closed`. |
| `next_attention_at` | UTC timestamp, zorunlu | Başlangıçta `scheduled_at_utc`; ertelemede yalnız bu occurrence için değişir. |
| `outcome_type` | enum, nullable | `completed`, `no_work`, `not_required`, `missed`. Yalnız `closed` durumda dolu. |
| `outcome_note` | text, nullable | Sonuç açıklaması. |
| `revision` | integer, zorunlu | `>= 1`. |
| `created_at` | UTC timestamp, zorunlu | Occurrence’ın kalıcı oluşturulma anı. |
| `completed_at` | UTC timestamp, nullable | Bütün kapanış sonuçlarında dolan terminal zaman; alan adı mevcut kabul diliyle korunur. |

### 6.2 Değişmezler

1. `(routine_template_id, occurrence_local_date)` benzersizdir.
2. Aynı üretim isteğinin tekrarı var olan occurrence’ı döndürür; yeni occurrence, revision veya event oluşturmaz.
3. `open` durumda outcome ve `completed_at` boştur.
4. `closed` durumda outcome ve `completed_at` zorunludur.
5. Tamamlama veya `no_work` sonucu gelecekteki günlere etki etmez.
6. Erteleme yalnız `next_attention_at` alanını değiştirir; template ve diğer occurrence’lar değişmez.
7. Yeniden açma status’u `open` yapar, outcome alanlarını temizler ve `next_attention_at` için kullanıcıdan yeni değer alır. Eski sonuç event geçmişinde kalır.
8. Geçmiş occurrence template değişikliğinden veya pasifleştirmeden etkilenmez.
9. Occurrence fiziksel olarak silinmez ve ertesi güne taşınmaz.

### 6.3 Görünüm grupları

- `overdue`: açık occurrence için `next_attention_at < now`.
- `today`: açık occurrence’ın `next_attention_at` yerel tarihi bugün ve zamanı henüz gelmemiş.
- `upcoming`: açık occurrence’ın dikkat tarihi bugünden sonra.
- Occurrence’ın zorunlu bir dikkat anı olduğu için normal üretimde `now` grubuna düşen zamansız occurrence yoktur.
- Bu gruplar kalıcı status değildir.

## 7. Lazy ve sınırlı backfill politikası

### 7.1 Seçilen pencere

Uygulama açıldığında veya rutin görünümü istendiğinde `ensure_occurrences(today_local)` çalışır.

- Otomatik pencere, bugün dahil son **7 Europe/Istanbul yerel takvim günüdür**: `today - 6 gün` ile `today` arası.
- Pencere template `start_date` ve varsa `end_date` ile daraltılır.
- Gelecek gün occurrence’ı önceden üretilmez.
- Template başlangıcından bugüne sınırsız üretim yapılmaz.
- Yedi günden eski eksik günler sonradan sessizce icat edilmez. Daha geniş, kullanıcı onaylı geçmiş üretimi v0.1 kapsamı dışındadır.

### 7.2 Geçmiş gün sonucu

- Penceredeki geçmiş ve recurrence’a uyan bir gün için occurrence yoksa occurrence önce `open`, revision `1` olarak oluşturulur.
- Aynı transaction içinde `missed` sonucu ile kapatılır ve revision `2` olur.
- Event sırası `routine_occurrence.created`, ardından `routine_occurrence.missed` olur.
- Bugünün occurrence’ı `open`, revision `1` kalır.
- Kullanıcı geçmişte işin aslında tamamlandığını biliyorsa occurrence’ı yeniden açıp doğru sonuçla kapatabilir; önceki otomatik `missed` olayı silinmez.

### 7.3 Pasifleştirme sınırı

- Inactive template için pasifleştirme yerel tarihinden sonraki günlere occurrence üretilmez.
- Pasifleştirme yerel günü, daha önce üretilmemişse otomatik üretilmez; pasifleştirme anında var olan occurrence korunur.
- Sınırlı pencere içinde pasifleştirme yerel tarihinden önce kalan uygun eksik günler backfill edilebilir.

### 7.4 Idempotent üretim akışı

```text
Europe/Istanbul bugünü belirle
-> 7 günlük pencereyi template tarihleriyle kesiştir
-> recurrence'a uyan yerel tarihleri sırala
-> her tarih için INSERT ... ON CONFLICT DO NOTHING
-> yalnız gerçekten insert edilen satır için created event ekle
-> geçmiş günse aynı transaction içinde missed sonucu ve event ekle
-> commit
-> var olan veya yeni occurrence listesini yerel tarihe göre döndür
```

Database unique constraint son savunmadır. Application-level “önce var mı?” kontrolü tek başına idempotency garantisi sayılmaz.

## 8. Append-only event sözleşmesi

### 8.1 Event alanları

Üç ayrı event tablosu kullanılacaktır:

- `follow_up_events`
- `routine_template_events`
- `routine_occurrence_events`

Her event şu alanları taşır:

| Alan | Kural |
| --- | --- |
| `id` | Canonical UUID. |
| aggregate foreign key | İlgili follow-up, template veya occurrence kimliği. |
| `sequence` | Aggregate içinde `1` ile başlayan ve tam bir artan integer. |
| `event_type` | Aşağıdaki allowed list değerlerinden biri. |
| `actor` | Kullanıcı veya otomatik işlem aktörü; nullable değildir. |
| `occurred_at` | Canonical UTC timestamp. |
| `payload_json` | Deterministic, object biçiminde JSON. |

`UNIQUE(aggregate_id, sequence)` uygulanır. Okuma sırası yalnız `ORDER BY sequence` ile belirlenir; timestamp, UUID veya SQLite `rowid` tie-breaker olarak kullanılmaz. Sıra numarası aynı `BEGIN IMMEDIATE` transaction içinde son sıradan bir artırılarak atanır.

Repository’lerde event update/delete method’u bulunmaz. Ana kayıt mutation’ı ve event insert’i aynı Unit of Work commit’inde başarılı olur veya birlikte rollback edilir.

### 8.2 Follow-up event türleri

```text
follow_up.created
follow_up.scheduled
follow_up.rescheduled
follow_up.waiting_started
follow_up.completed
follow_up.cancelled
follow_up.reopened
follow_up.observation_linked
follow_up.converted_to_observation
```

İlk oluşturma dikkat zamanı taşıyorsa önce `follow_up.created`, sonra `follow_up.scheduled` yazılır. Resmî gözleme dönüştürme, oluşturulan observation kimliğini payload içinde taşır ve follow-up’ı `outcome_type = converted_to_observation` ile tamamlar.

### 8.3 Rutin event türleri

```text
routine_template.created
routine_template.updated
routine_template.deactivated
routine_occurrence.created
routine_occurrence.snoozed
routine_occurrence.completed
routine_occurrence.no_work
routine_occurrence.not_required
routine_occurrence.missed
routine_occurrence.reopened
```

Event payload’ı en az mutation sonrası `revision` değerini ve değişen alanların önce/sonra değerlerini taşır. Hassas olmayan kullanıcı notu gerekiyorsa açıkça ilgili event’e eklenir; bütün entity snapshot’ı her event’e kopyalanmaz.

## 9. SQLite migration planı

İlk implementation adımı `SCHEMA_VERSION` değerini `2`den `3`e çıkaran tek immutable migration ekleyecektir.

### 9.1 Yeni tablolar

```text
follow_up_items
follow_up_events
routine_templates
routine_template_weekdays
routine_occurrences
routine_template_events
routine_occurrence_events
```

### 9.2 Ana constraint ve index’ler

- Bütün ana ve event ID alanları primary key’dir.
- Project, observation, template ve aggregate ilişkileri foreign key’dir; `ON DELETE CASCADE` kullanılmaz.
- `routine_occurrences(routine_template_id, occurrence_local_date)` unique constraint taşır.
- Her event tablosu `(aggregate_id, sequence)` unique constraint taşır.
- Enum alanları SQLite `CHECK` ile allowed list’e sınırlandırılır.
- Boolean alanları `CHECK(value IN (0, 1))` kullanır.
- Revision alanları `CHECK(revision >= 1)` kullanır.
- Template tarih aralığı `end_date IS NULL OR end_date >= start_date` constraint’i taşır.
- Status ile outcome/timestamp birlikteliği database `CHECK` ve application validation ile birlikte korunur.
- Listeleme için follow-up `(status, next_attention_at)`, template `(status, project_id)` ve occurrence `(routine_template_id, occurrence_local_date)` index’leri eklenir.

### 9.3 Güvenli upgrade

- Mevcut `projects`, `field_observations`, `attachments` ve `observation_events` tablolarında ALTER/DELETE/UPDATE yapılmaz.
- Migration’ın herhangi bir statement’ı başarısızsa sürüm kaydı dahil bütün migration rollback olur.
- Bilinmeyen veya sırası bozuk migration sürümü mevcut fail-closed davranışla reddedilir.
- Fresh database ve sürüm 2’den upgrade aynı sürüm 3 şemasını üretmelidir.
- Migration testi, upgrade öncesi observation/project/attachment/event satırlarını ve payload değerlerini upgrade sonrası birebir karşılaştırmalıdır.

## 10. Repository ve application service sınırı

### 10.1 Repository port’ları

```text
FollowUpRepositoryPort
FollowUpEventRepositoryPort
RoutineTemplateRepositoryPort
RoutineTemplateEventRepositoryPort
RoutineOccurrenceRepositoryPort
RoutineOccurrenceEventRepositoryPort
```

Her ana repository `add`, `get` ve gerekli deterministic list/query method’larını taşır. Mutation method’ları `expected_revision` ister. Event repository’leri yalnız `add` ve aggregate için `list` sunar.

### 10.2 Application service’ler

```text
FollowUpApplicationService
RoutineApplicationService
```

`FollowUpApplicationService` oluşturma, planlama/yeniden planlama, beklemeye alma, tamamlama, iptal, yeniden açma, observation bağlama ve resmî gözleme dönüştürme use-case’lerini koordine eder.

`RoutineApplicationService` template oluşturma/güncelleme/pasifleştirme, occurrence ensure/backfill, erteleme, sonuçlandırma ve yeniden açma use-case’lerini koordine eder.

Gelecek service API yüzeyi aşağıdaki isim ve sorumluluklarla sınırlıdır:

```python
class FollowUpApplicationService:
    def create_follow_up(self, command: CreateFollowUp) -> FollowUpItem: ...
    def get_follow_up(self, follow_up_id: str) -> FollowUpItem: ...
    def list_follow_ups(self, query: FollowUpQuery) -> tuple[FollowUpItem, ...]: ...
    def update_details(
        self, follow_up_id: str, expected_revision: int, command: UpdateFollowUp
    ) -> FollowUpItem: ...
    def schedule(
        self, follow_up_id: str, expected_revision: int, command: ScheduleFollowUp
    ) -> FollowUpItem: ...
    def mark_waiting(
        self, follow_up_id: str, expected_revision: int, command: MarkWaiting
    ) -> FollowUpItem: ...
    def complete(
        self, follow_up_id: str, expected_revision: int, command: CompleteFollowUp
    ) -> FollowUpItem: ...
    def cancel(
        self, follow_up_id: str, expected_revision: int, outcome_note: str | None
    ) -> FollowUpItem: ...
    def reopen(
        self, follow_up_id: str, expected_revision: int, next_attention_at: str | None
    ) -> FollowUpItem: ...
    def link_observation(
        self, follow_up_id: str, expected_revision: int, observation_id: str
    ) -> FollowUpItem: ...
    def convert_to_observation(
        self, follow_up_id: str, expected_revision: int, observation_id: str
    ) -> FollowUpItem: ...
    def list_history(self, follow_up_id: str) -> tuple[FollowUpEvent, ...]: ...


class RoutineApplicationService:
    def create_template(self, command: CreateRoutineTemplate) -> RoutineTemplate: ...
    def get_template(self, routine_template_id: str) -> RoutineTemplate: ...
    def list_templates(self, project_id: str, status: str | None = None) -> tuple[RoutineTemplate, ...]: ...
    def update_template(
        self,
        routine_template_id: str,
        expected_revision: int,
        command: UpdateRoutineTemplate,
    ) -> RoutineTemplate: ...
    def deactivate_template(
        self, routine_template_id: str, expected_revision: int
    ) -> RoutineTemplate: ...
    def ensure_occurrences(self, as_of_utc: str) -> tuple[RoutineOccurrence, ...]: ...
    def list_occurrences(self, query: RoutineOccurrenceQuery) -> tuple[RoutineOccurrence, ...]: ...
    def snooze_occurrence(
        self, routine_occurrence_id: str, expected_revision: int, next_attention_at: str
    ) -> RoutineOccurrence: ...
    def close_occurrence(
        self, routine_occurrence_id: str, expected_revision: int, command: CloseOccurrence
    ) -> RoutineOccurrence: ...
    def reopen_occurrence(
        self, routine_occurrence_id: str, expected_revision: int, next_attention_at: str
    ) -> RoutineOccurrence: ...
    def list_template_history(
        self, routine_template_id: str
    ) -> tuple[RoutineTemplateEvent, ...]: ...
    def list_occurrence_history(
        self, routine_occurrence_id: str
    ) -> tuple[RoutineOccurrenceEvent, ...]: ...
```

Buradaki command/query sınıfları transport veya UI modeli değildir; use-case girdilerini isimlendiren immutable application değerleridir. `convert_to_observation` var olan ve ayrıca oluşturulmuş bir observation kimliğini bağlar; bu sözleşme otomatik observation üretmez.

Service davranışı:

1. Komut girdisini doğrular.
2. Tek Unit of Work açar.
3. Güncel aggregate ve revision’ı okur.
4. Gerçek değişiklik yoksa event eklemeden mevcut kaydı döndürür.
5. Ana kaydı değiştirir ve event’i append eder.
6. Tek commit yapar.

Event insert başarısızsa ana mutation; ana mutation başarısızsa event insert kalıcı olmaz.

## 11. Backup ve restore kararı

### 11.1 Yeni tabloların taşınması

Mevcut `BackupService` SQLite online snapshot’ın tamamını `cse.sqlite3` olarak arşivler. Yeni takip tabloları aynı database içinde olacağı için ek dosya listesi gerektirmeden backup’a dahil olur.

### 11.2 Manifest count kararı

v0.1’de manifest’e follow-up/template/occurrence/event count alanları eklenmeyecektir.

Gerekçeler:

- Mevcut backup format sürümü `1` ve manifest alan kümesi exact doğrulanır.
- Yeni count alanı aynı format sürümünde eski okuyucuyu kırar.
- SQLite snapshot dosyasının SHA-256 digest’i bütün yeni tablo içeriklerini zaten kapsar.
- Restore sonrasında `PRAGMA integrity_check`, migration seti ve repository-level kabul testleri ek güvence sağlar.

Mevcut `observation_count` ve `event_count` alanlarının anlamı değişmez; bunlar yalnız observation omurgasını saymaya devam eder. Tracking count ihtiyacı doğarsa ayrı backup format v2 tasarımı yapılır.

### 11.3 Backward compatibility

- Yeni backup’lar backup format `1`, schema version `3` taşır.
- Uygulama schema version `2` taşıyan eski format `1` backup’ı doğrulayıp yalnız yeni ve var olmayan hedef köke çıkarabilmelidir.
- Eski snapshot önce kendi manifest observation/attachment/event sayılarıyla doğrulanır, sonra geçici restore kökünde normal migration runner ile sürüm 3’e yükseltilir.
- Bu yükseltmede yeni tracking tabloları boş oluşur; eski observation ve attachment verisi değişmez.
- Schema version `1`, bilinmeyen ileri sürüm veya format version `1` dışı archive otomatik kabul edilmez.
- Aktif gerçek `CSE_DATA_ROOT` veya var olan herhangi bir hedef üzerine restore yapılmaz. Mevcut `target.exists()` reddi korunur.

## 12. Resmî günlük export exclusion

Saha Takibi kişisel çalışma alanıdır. Varsayılan günlük resmî export aşağıdakileri içermez:

- follow-up alanları veya metinleri,
- routine template alanları,
- occurrence sonuçları,
- tracking event’leri,
- tracking count’ları,
- tracking kimlikleri.

`DailyExportService` yalnız mevcut observation/project/attachment/event akışını okumaya devam eder. `format_version`, ZIP entry adları, `record_count` anlamı ve observation manifesti değişmez.

Gelecek regression testi aynı observation fixture ve deterministic clock/UUID ile iki veri kökü kurmalıdır: birinde tracking verisi bulunur, diğerinde bulunmaz. Üretilen resmî günlük export ZIP’leri byte-for-byte aynı olmalıdır. Ayrıca bütün ZIP entry’lerinde tracking kimliği ve örnek takip metni aranıp bulunmadığı doğrulanmalıdır.

Kişisel takip çıktısı ileride açık kullanıcı seçimiyle, ayrı service, ayrı dosya adı ve ayrı manifest sözleşmesiyle tasarlanabilir. Bu görev o export’u tanımlamaz veya üretmez.

## 13. Puantaj kabul senaryosu

Template:

```text
Başlık: Puantajı tamamla
Tekrar: weekdays
Saat: 17:00
Timezone: Europe/Istanbul
Proje: 63516-2'nin canonical project UUID karşılığı
```

| Adım | Beklenen kalıcı davranış |
| --- | --- |
| Pazartesi ilk açılış | Pazartesi occurrence’ı `open`, revision `1`; `next_attention_at` 17:00 yerel saatin UTC karşılığıdır. |
| Pazartesi ikinci açılış | Unique constraint nedeniyle aynı occurrence döner; yeni event yoktur. |
| Pazartesi tamamlama | Status `closed`, outcome `completed`, revision `2`, completed event. |
| Salı açılış | Farklı local date ile ayrı occurrence oluşur. |
| Salı çalışma yok | Status `closed`, outcome `no_work`; Pazartesi değişmez. |
| Çarşamba 17:00 sonrası | Açık occurrence’ın dikkat anı geçtiği için görünümü `overdue` olur; status yine `open` kalır. |
| Çarşamba 18:00’e erteleme | Yalnız Çarşamba `next_attention_at` ve revision değişir; template ile diğer günler değişmez. |
| Perşembe template 16:30 | Henüz üretilmemiş günler 16:30 kullanır; Pazartesi–Çarşamba snapshot’ları değişmez. |
| Template pasifleştirme | Gelecek gün occurrence üretilmez; bütün geçmiş occurrence ve event’ler kalır. |
| Restart | Unique constraint ve kalıcı satırlar aynı sonuçları döndürür. |
| Backup/restore | Schema 3 snapshot bütün template/occurrence/outcome/event verisini korur. |
| Günlük resmî export | Puantaj rutini ve sonuçları export’a girmez. |

## 14. Uygulama görevleri için test matrisi

### 14.1 Domain ve repository

- Canonical/non-canonical UUID kabul ve ret testleri.
- Her enum allowed list ve unsupported değer testleri.
- Terminal status/outcome/timestamp birlikteliği.
- Revision artışı, stale conflict ve no-op kararlılığı.
- Archived/deactivated/closed kayıtların izin verilen mutation sınırı.
- Hard delete API’sinin bulunmaması.

### 14.2 Recurrence

- Daily, weekdays, weekly ve monthly eşleşmeleri.
- Cumartesi/Pazar weekdays dışlaması.
- Aylık 29/30/31 ve olmayan günlerin kaydırılmaması.
- Start/end date dahil sınırları.
- Europe/Istanbul yerel tarih ve UTC snapshot dönüşümü.
- Aynı gün çoklu ensure idempotency.
- Bugün dahil yedi günlük pencere ve sekizinci günün üretilmemesi.
- Geçmiş otomatik `missed`, bugünün açık kalması.
- Ertelemenin yalnız tek occurrence’ı değiştirmesi.
- Template güncellemesi ve pasifleştirmesinin geçmişi değiştirmemesi.

### 14.3 Event ve transaction

- Aggregate sequence `1..n` deterministic sıralaması.
- Aynı timestamp ve ters UUID değerlerinde sequence sırasının korunması.
- Ana mutation başarısızlığında event rollback.
- Event append başarısızlığında ana kayıt rollback.
- No-op ve idempotent ensure sırasında event oluşmaması.
- Reopen sonrasında eski outcome event’inin korunması.

### 14.4 Migration, backup ve export

- Fresh schema 3 ve schema 2 -> 3 upgrade eşitliği.
- Existing observation/project/attachment/event fixture’larının birebir korunması.
- Migration hata anında tam rollback.
- Schema 3 backup/restore round-trip ve tracking count içerik karşılaştırması.
- Schema 2 eski backup’ın yeni, boş hedefe restore+migrate edilmesi.
- Var olan/aktif target root restore reddi.
- Tracking verili ve verisiz resmî günlük export’un byte-for-byte eşitliği.

## 15. Bilinçli olarak kapsam dışında bırakılanlar

- Web UI ve `+ Unutma` formu.
- Background scheduler, Windows notification ve uygulama kapalıyken çalışan servis.
- PWA/mobil, WhatsApp veya e-posta.
- AI sınıflandırma, başlık üretme veya önem tahmini.
- Takım görevlendirme, yetki ve çok kullanıcılı sahiplik.
- Resmî tatil takvimi, vardiya ve geofence.
- Otomatik resmî gözlem oluşturma.
- Personel bazlı puantaj, saat, ücret veya bordro hesabı.
- Kişisel takip export implementasyonu.

## 16. Sonraki implementation sırası

Bu sözleşmeden sonra işler küçük ve test edilebilir görevler olarak ayrılmalıdır:

1. Domain record/validation sabitleri ve saf recurrence hesaplayıcısı.
2. SQLite schema v3 migration ve repository/event port/adaptörleri.
3. Transactional application service ve sınırlı idempotent occurrence üretimi.
4. Backup schema 2 backward restore ve schema 3 round-trip testleri.
5. Resmî daily export exclusion regression testi.
6. Bunlar doğrulandıktan sonra minimum Saha Takibi UI’si.

İlk beş adım tamamlanmadan notification, background scheduler veya geniş UI başlatılmaz.
