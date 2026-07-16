# Issue 117 Result — Backup/Restore Uyumluluğu ve Resmî Export İzolasyonu

## Sonuç

Issue #117'nin production ve executable regression kapsamı, Epic #105 ile Saha Takibi Epic #97 sınırlarına bağlı olarak `27b5c460b9af3092ebe228d7c92a7f0aae22fcdc` güvenli başlangıç noktasından uygulandı.

Resmî yerel repository:

```text
V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer
```

Çalışma branch'i:

```text
codex/issue-117-backup-restore-export-isolation
```

Başlangıç doğrulaması:

```text
local master  = 27b5c460b9af3092ebe228d7c92a7f0aae22fcdc
origin/master = 27b5c460b9af3092ebe228d7c92a7f0aae22fcdc
divergence    = 0 0
```

## Uygulanan production davranışı

- `RESTORABLE_SCHEMA_VERSIONS = (2, 3, 4)` tek restore allowlist kaynağı olarak eklendi.
- Manifest `schema_version` değeri yalnız bool olmayan integer ve allowlist üyesiyse kabul edilir.
- `verify_backup`, mevcut duplicate/unsafe path/symlink/unmanifested entry/digest kontrollerini koruyup embedded database ve attachment dosyalarını private temporary kökte doğrular.
- Verify database bağlantısı SQLite URI `mode=ro` ile salt-okunur açılır; verify sırasında migration çalıştırılmaz.
- `PRAGMA integrity_check`, exact `[1..manifest_schema]` migration listesi, observation/event/attachment count ve attachment reconciliation zorunlu kapıdır.
- Restore yalnız var olmayan target için archive verify → temporary extraction → pre-migration doğrulama → gerekiyorsa temporary database migration → schema 4 post-validation → repository okumaları → tek atomic move sırasını uygular.
- Schema 2 restore temporary database üzerinde v3 ve v4'ü, schema 3 restore yalnız v4'ü uygular; schema 4 migrate edilmeden post-validation'a geçer.
- Post-validation project, observation, attachment, follow-up, routine template, occurrence ve bütün event repository okumalarını yapar.
- Pre-migration, migration veya post-validation hatasında target görünür olmaz; restore temporary root temizlenir.
- Kaynak archive/database, aktif data root ve var olan target üzerinde in-place migration yapılmaz.

## Format sözleşmesi

Aşağıdakiler değişmedi:

```text
BACKUP_FORMAT_VERSION = 1
daily export format_version = 1
backup manifest exact field set
daily export manifest exact field set
ZIP entry adları
observation_count anlamı
event_count anlamı
record_count anlamı
```

Backup manifest'e tracking count alanı eklenmedi. Tracking verisi SQLite snapshot digest'i ve restore sonrası repository/application kabul testleriyle korunur.

## Test fixture ve kabul kanıtı

### Schema 2 → 4

- Fixture gerçekten yalnız `SCHEMA_MIGRATIONS[:2]` ile oluşturuldu.
- Final migration listesi `[1, 2, 3, 4]` oldu.
- Project, observation, attachment ve observation-event satırları/payload text'i korundu.
- Yedi tracking tablosu boş oluştu.
- Attachment hash/size/path reconciliation geçti.
- Observation application service ve web detail route restored root üzerinde açıldı.
- Source database ve archive digest'i değişmedi.

### Schema 3 → 4

- Fixture gerçekten yalnız `SCHEMA_MIGRATIONS[:3]` ile oluşturuldu.
- Yalnız v4 migration uygulandı ve final liste `[1, 2, 3, 4]` oldu.
- Follow-up, routine template, occurrence ve üç event tablosunun satırları birebir korundu.
- Legacy follow-up `payload_json` metni boşluklarıyla birlikte byte-for-byte korundu.
- Güncel repository'ler bütün restored tracking kayıtlarını okudu.
- Source archive digest'i değişmedi.

### Schema 4 round-trip

Gerçek application service fixture'ı şunları içerdi:

- normal observation ve attachment;
- follow-up create + details update + explicit observation conversion;
- routine template;
- geçmiş `missed` occurrence;
- bugünkü open occurrence;
- snooze + close + reopen geçmişi.

Backup → verify → yeni root restore sonrasında aggregate alanları, revision'lar, natural key, occurrence schedule snapshot'ları, event sequence ve `payload_json` satırları aynı kaldı. Follow-up ve routine application service sorguları aynı sonuçları döndürdü. Restored root'tan alınan ikinci backup yine format version `1` ve exact manifest key setini kullandı.

### Hata atomikliği

- Pre-migration observation count mismatch target oluşturmadı.
- Gerçek bozuk migration statement transaction rollback yaptı; target ve temporary root bırakmadı.
- Enjekte edilen post-migration repository validation hatası target ve temporary root bırakmadı.
- Existing target marker içeriği değişmedi.
- Schema `1`, `0`, negatif, bool, future `5`, manifest/DB mismatch ve migration gap fail-closed reddedildi.
- Verify temporary kökü her başarılı doğrulama sonunda temizlendi.

### Resmî export izolasyonu

Root A ve Root B aynı project/observation/attachment/observation-event verisini taşıdı. Root B ayrıca yoğun follow-up/routine/occurrence ve tracking-event geçmişi ile observation'a converted follow-up taşıdı.

Aynı deterministic clock ve UUID ile üretilen iki resmî günlük export ZIP'i:

```text
byte-for-byte aynı
```

Exact ZIP entry seti, manifest alanları, format version, record/warning count, file digest'leri ve bütün Markdown/CSV/JSON/attachment manifest içerikleri aynı kaldı. Tracking metni, routine başlığı, tracking UUID'leri, outcome, tracking event türleri ve tracking count adları hiçbir entry'de bulunmadı.

Test gerçek sızıntı bulmadığı için `app/operations/exports.py` değiştirilmedi.

## Değişen dosyalar

```text
.cse/tasks/117_task.md
.cse/results/117_result.md
.cse/state/project_state.json
app/operations/backups.py
tests/test_backup_restore.py
tests/test_daily_export.py
CHANGELOG.md
ROADMAP.md
docs/project_decisions.md
learning/GLOSSARY.md
learning/issue_117_backup_restore_export_isolation.md
```

## Test kanıtı

Focused backup/export paketi:

```text
python -m pytest -rs tests/test_backup_restore.py tests/test_daily_export.py
39 passed in 3.12s
```

İlgili migration/persistence/UoW/application-service regresyon paketi:

```text
python -m pytest -rs tests/test_persistence_migrations.py tests/test_field_tracking_persistence.py tests/test_follow_up_application_service.py tests/test_routine_application_service.py tests/test_sqlite_unit_of_work.py tests/test_observation_application_service.py
214 passed in 4.35s
```

Tam regresyon paketi:

```text
python -m pytest -rs
966 passed, 7 skipped in 20.72s
```

Yedi skip Windows ortamında symlink oluşturma ayrıcalığı bulunmayan mevcut attachment testleridir; Issue #117 kapsamıyla ilgili failure yoktur.

## Yapısal doğrulama

```text
python -m compileall -q app scripts                       PASS
python -m json.tool .cse/state/project_state.json         PASS
git diff --check                                          PASS
SCHEMA_VERSION                                            4
CSE_DATA_ROOT                                             unset
exports                                                   yalnız .gitkeep
origin/master...HEAD                                      0 0 (commit öncesi)
```

Base ile protected path diff'i yoktur:

```text
app/persistence/schema.py
app/persistence/migrations.py
app/persistence/field_tracking_mapping.py
app/persistence/field_tracking_repositories.py
app/persistence/unit_of_work.py
app/application/field_tracking.py
app/application/routines.py
app/application/observations.py
app/operations/exports.py
app/web/
requirements.txt
.github/workflows/
```

Doğrulanan güncel SHA-256 değerleri:

```text
app/persistence/schema.py
AE2C3A6A1221719F561FB3761C06CB44FA9673665800F6938B1AE15F58BE63EC

app/persistence/migrations.py
DB6EE7933F2ECFA2BF66CA9CED6F8CAA3518642F739A258DA91660AC416A3DE7

app/operations/exports.py
B05CA59C4707DCB55D99A1C745E010C398020F12CB18B7697A807DAB6DD41D58

exports/.gitkeep
01BA4719C80B6FE911B091A7C05124B64EEECE964E09C058EF8F9805DACA546B
```

## Korunan kullanıcı dosyaları

Başlangıçtaki Issue #115 evidence hash'leriyle aynı kaldı:

```text
reports/claude_CSE_Degerlendirme_Raporu.docx
3B2DB82D556D7D4591B049BCD95B03A7E2973EA43822CE2C60DC660B38899A13

reports/CSE_BAGIMSIZ_TEKNIK_URUN_DENETIM_RAPORU_2026-07-12.md
F8D3CBB2111EC7BBD12EEF673720EA3E54B2558E7545817D3E72DF18C083A1A9

chief-site-engineer_adim_080_guvenli_nokta.zip
E96CAA2115B98C54A5B030DAB265DC62AFD509BB4F6E59E2694AF0C89165C653
```

`reports/` untracked kullanıcı içeriği olarak korunmuş, ignored ZIP/cache ve `exports/.gitkeep` değiştirilmemiştir.

## Kapsam dışında kalanlar

- Backup format v2 ve manifest tracking count alanları
- Kişisel tracking export'u
- Schema v5 veya mevcut migration metni değişikliği
- Web/UI, scheduler/notification, mobile/PWA/offline/sync/auth
- Application service, repository port veya UoW genişletmesi
- Legacy cleanup ve gerçek kullanıcı data root'u

## Yayın kaydı

Commit, normal push, final local/remote branch SHA ve divergence kanıtı oluşturulan commit SHA'sı ile GitHub Issue #117 completion yorumunda olgusal olarak kaydedilecektir. Codex PR açmayacak; merge veya branch silme yapılmayacaktır.

Bir sonraki dar ürün adımı Epic #105 Faz 3'teki mobil runtime ve veri sahipliği ADR'sidir; bu görev o fazı başlatmamıştır.
