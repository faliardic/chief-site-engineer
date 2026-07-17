# Issue #173 — Olay Zamanı Sözleşmesi ve Migration Preflight

## 1. Amaç ve sınır

Bu çalışma CSE'deki zaman alanlarının anlamını tek sözleşmede toplar ve mevcut
SQLite zaman verisini yalnız açıkça verilen disposable temp/test database
üzerinde inceleyen salt-okunur bir preflight sağlar.

Bu çalışma:

- schema sürümünü artırmaz;
- migration eklemez veya çalıştırmaz;
- satır, timezone veya precision düzeltmez;
- gerçek kullanıcı data root'unu keşfetmez veya açmaz;
- P1.02 geriye dönük observation formunu, archive/unarchive ya da MemoryIndex'i
  başlatmaz.

## 2. Bağlayıcı zaman anlamları

| Anlam | Kaynak alan örnekleri | Kesin sözleşme | Future policy |
|---|---|---|---|
| Olay zamanı | `observed_at`, `occurred_at`, `reported_at` | Olayın sahada veya CSE yaşam döngüsünde gerçekleştiği an | `as_of` sonrasına izin yok |
| İlk kalıcı giriş | `created_at`, `schema_migrations.applied_at` | Kaydın ilgili kalıcı CSE deposuna ilk yazıldığı an | `as_of` sonrasına izin yok |
| Son değişiklik | `updated_at` | Aggregate'in son başarılı gerçek mutation anı | `as_of` sonrasına izin yok |
| Planlanan zaman | `scheduled_at_utc`, `next_attention_at`, `deadline_at` | Gelecek iş, dikkat veya son tarih anı | Gelecek değer geçerli |
| Yaşam döngüsü zamanı | `closed_at`, `completed_at`, `cancelled_at`, `deactivated_at`, `archived_at` | İlgili durum geçişinin başarılı olduğu an | `as_of` sonrasına izin yok |

`occurred_at`, `created_at` ve `updated_at` birbirinin yerine kullanılamaz.
Örneğin observation timeline anı `observed_at`, sisteme ilk giriş anı
`created_at`, daha sonraki başarılı düzeltme anı `updated_at` olur.

## 3. Storage, precision ve sunum

Yeni kalıcı timestamp üretimi:

```text
YYYY-MM-DDTHH:MM:SSZ
```

- Storage timezone-aware UTC'dir.
- Aware `+03:00` gibi değerler yalnız açık normalization helper'ıyla UTC'ye
  çevrilir.
- Naive veya parse edilemeyen değer reddedilir; local timezone ya da UTC
  varsayılmaz.
- Yeni write precision saniyedir. Eski altı basamaklı microsecond UTC değerleri
  read compatibility için parse edilir, preflight'ta warning sayılır ve bu
  Issue'da yeniden yazılmaz.
- Kullanıcı sunumu IANA `Europe/Istanbul` timezone'u ile yapılır. Storage,
  karşılaştırma ve tie-breaker UTC kalır.
- DST davranışı sabit offset varsayımıyla değil `ZoneInfo` ile yürür. Istanbul
  sunum testi yanında generic DST fold testi iki aynı duvar saati değerinin iki
  ayrı UTC anı olduğunu doğrular.

## 4. Canonical production yüzeyi

`app/time_contracts.py` şu dar sorumlulukları taşır:

- `serialize_utc_timestamp`: aware `datetime` -> UTC `Z`;
- `parse_utc_timestamp`: canonical seconds veya legacy six-microsecond UTC;
- `parse_aware_timestamp` / `normalize_utc_timestamp`: explicit offset'i UTC'ye
  normalize etme;
- `utc_now`: injectable aware clock'tan deterministic UTC metni;
- `to_istanbul` / `format_istanbul_timestamp`: Istanbul sunumu;
- `to_timezone`: IANA timezone dönüşümü ve generic DST testi;
- `TimestampRole` / `validate_temporal_policy`: alan anlamına bağlı future
  politikası.

Helper database, filesystem veya CSE data root bilmez. Sistem local timezone'una
bakmaz. `app/persistence/contracts.py` mevcut public import'u korumak için
canonical serializer/parser üzerinde ince compatibility katmanı olarak kalır.

## 5. Repository timestamp call-site envanteri

| Yüzey | Exact path / symbol | Mevcut rol ve Issue #173 sonucu |
|---|---|---|
| Observation application clock | `app/application/observations.py::_utc_now` | Merkezi `utc_now()` kullanır |
| Follow-up application clock / Istanbul date | `app/application/field_tracking.py::_utc_now`, `_istanbul_date` | Merkezi now ve Istanbul conversion kullanır |
| Routine application clock / Istanbul date | `app/application/routines.py::_utc_now`, `_istanbul_date` | Merkezi now ve Istanbul conversion kullanır |
| Domain recurrence | `app/field_tracking.py::ISTANBUL_TIMEZONE`, `plan_routine_occurrence`, attention/date helpers | Tek canonical timezone adını kullanır; saf domain davranışı korunur |
| Persistence validation | `app/persistence/contracts.py::validate_utc_timestamp`, repository `_validate_timestamp` çağrıları | Canonical parser'a delegasyon; naive fail-closed |
| SQLite migration clock | `app/persistence/migrations.py::migrate_database` | Yeni migration metadata write'ı seconds UTC üretir; migration zinciri değişmez |
| SQLite schema | `app/persistence/schema.py::SCHEMA_MIGRATIONS` | v1/v2 observation ailesi, v3 tracking ailesi, v4 event rebuild envanteri; schema değişmez |
| Mapper/repository | `app/persistence/field_tracking_mapping.py`, `repositories.py`, `field_tracking_repositories.py` | Timestamp metnini taşır/doğrular; preflight bunları mutate etmez |
| Backup/Restore | `app/operations/backups.py::BackupService`, restore validation akışı | Manifest clock merkezileşti; format 1 ve restore `(2,3,4)` değişmez |
| Günlük Çıktı | `app/operations/exports.py::DailyExportService`, `_parse_utc` | Canonical parser ve named Istanbul timezone kullanır; format 1 değişmez |
| Web | `app/web/app.py::_utc_now`, `utc_to_istanbul_display`, `utc_to_istanbul_input`, `istanbul_datetime_local_to_utc` | Naive stored değer artık UTC varsayılmaz; güvenli fallback korunur |
| Attachment integrity rapor saatleri | `app/attachment_integrity.py::AttachmentIntegrityResult`, `AttachmentIntegrityReportSummary`, `AttachmentIntegrityReport` | Zaten aware UTC `datetime`; SQLite storage text değildir ve bu görevde davranışı değişmez |

## 6. Preflight timestamp column envanteri

Schema 2, v1 timestamp kolonlarını ve migration metadata'sını taşır:

| Tablo | Kolonlar | Proposed mapping |
|---|---|---|
| `schema_migrations` | `applied_at` | `persistent_entry_time` |
| `projects` | `created_at` | `persistent_entry_time` |
| `field_observations` | `observed_at`, `reported_at` | `event_time` |
| `field_observations` | `created_at` | `persistent_entry_time` |
| `field_observations` | `updated_at` | `last_update_time` |
| `field_observations` | `closed_at`, `archived_at` | `lifecycle_time` |
| `attachments` | `created_at` | `persistent_entry_time` |
| `observation_events` | `occurred_at` | `event_time` |

Schema 3 ve 4 ayrıca şunları taşır:

| Tablo | Kolonlar | Proposed mapping |
|---|---|---|
| `follow_up_items` | `next_attention_at`, `deadline_at` | `scheduled_time` |
| `follow_up_items` | `created_at` / `updated_at` | `persistent_entry_time` / `last_update_time` |
| `follow_up_items` | `completed_at`, `cancelled_at` | `lifecycle_time` |
| `follow_up_events` | `occurred_at` | `event_time` |
| `routine_templates` | `created_at` / `updated_at` | `persistent_entry_time` / `last_update_time` |
| `routine_templates` | `deactivated_at` | `lifecycle_time` |
| `routine_occurrences` | `scheduled_at_utc`, `next_attention_at` | `scheduled_time` |
| `routine_occurrences` | `created_at` | `persistent_entry_time` |
| `routine_occurrences` | `completed_at` | `lifecycle_time` |
| `routine_template_events`, `routine_occurrence_events` | `occurred_at` | `event_time` |

## 7. Salt-okunur preflight sözleşmesi

Çağrı açık database yolu, explicit disposable türü ve sabit `as_of` ister:

```python
report = run_time_migration_preflight(
    temp_database,
    as_of_utc="2026-07-17T20:00:00Z",
    database_kind="temporary",
)
```

Bağlantı SQLite URI `mode=ro` ile açılır ve `PRAGMA query_only = ON` uygulanır.
Fonksiyon schema/migration runner çağırmaz. Her allowlist kolonundan yalnız o
timestamp değeri okunur; başka business content seçilmez.

JSON-ready sonuç:

- `preflight_version`, `database_kind`, `read_only`, `schema_version` ve
  `supported_schema_versions`;
- sabit `as_of_utc` ve genel `status`;
- kolon başına `row`, `null`, `parseable`, `canonical_utc`, `noncanonical_utc`,
  `invalid`, `naive`, `non_utc`, `microsecond`, `future` sayaçları;
- normalize UTC `min_utc` / `max_utc`;
- `proposed_mapping`, `future_allowed`, `present`, `nullable`;
- veri-minimal `findings`.

Raw timestamp, row ID, açıklama, not, kişi, payload, absolute database path veya
başka hassas içerik rapora girmez.

## 8. Finding ve compatibility matrisi

| Durum | Seviye | Sonuç |
|---|---|---|
| Unsupported schema / eksik beklenen kolon | Blocker | İnceleme durur; otomatik migration yok |
| Parse edilemeyen timestamp | Blocker | Raw değer sızdırmadan count raporlanır |
| Naive timestamp | Blocker | Timezone varsayılmaz |
| Historical role için future timestamp | Blocker | Clock/data anlamı insan incelemesi ister |
| Non-UTC explicit offset | Warning | Açık migration planında normalize edilebilir; burada rewrite yok |
| UTC anını canonical olmayan metinle yazma | Warning | `+00:00`/farklı separator sessizce canonical sayılmaz |
| Legacy microsecond precision | Warning | Read-compatible; canonical seconds geçişi ayrı migration ister |
| Scheduled role için future timestamp | Normal | Warning/blocker üretilmez |

| Senaryo | Preflight davranışı | Database etkisi |
|---|---|---|
| Fresh schema 4 temp DB | 26 timestamp kolonunu raporlar | Byte değişmez |
| Restore-compatible schema 2 temp DB | 10 timestamp kolonunu raporlar | Migration yok, byte değişmez |
| Restore-compatible schema 3 temp DB | 26 timestamp kolonunu raporlar | Migration yok, byte değişmez |
| Restore temporary copy | Restore akışından bağımsız, açık çağrıyla kullanılabilir | Kaynak archive/database değişmez |
| Aktif/gerçek data root | Bu Issue kapsamında yasak | Açılmaz |

## 9. Acceptance sonucu

Executable testler UTC round-trip, offset normalization, Istanbul sunumu,
naive/invalid fail-closed, seconds/microseconds precision, past/future policy,
generic DST fold, fixed clock, schema 2/3/4 preflight, byte değişmezliği ve
hassas içerik sızıntısı yokluğunu kapsar. Mevcut Backup/Restore ve Günlük Çıktı
regresyonları da aynı doğrulama setinde çalıştırılır.

Issue #173 bir migration readiness girdisidir; mevcut satırların migration'dan
geçtiği veya gerçek kullanıcı verisinin temiz olduğu iddiası değildir.
