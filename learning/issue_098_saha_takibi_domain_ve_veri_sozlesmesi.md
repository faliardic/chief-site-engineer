# Issue 98 - Saha Takibi Domain ve Veri Sözleşmesini Öğrenmek

## 1. Bu adımda ne yaptık?

Bu adımda henüz Python modeli, SQLite tablosu veya web ekranı yazmadık. Önce üç kavramın sınırını netleştirdik:

- `FollowUpItem`: bir kez yapılacak veya beklenecek iş.
- `RoutineTemplate`: tekrar kuralı.
- `RoutineOccurrence`: şablonun belirli bir gündeki bağımsız örneği.

Recurrence, timezone, idempotency, revision, append-only event, migration, backup ve resmî export exclusion kararlarını tek bir uygulanabilir sözleşmede topladık.

Ana teknik belge:

```text
docs/field_tracking_v0_1_contract.md
```

## 2. Neden bunu yaptık?

### Uygulama açısından

“Her iş günü puantajı tamamla” ifadesini tek bir görev satırı olarak saklarsak Pazartesi tamamlandığında Salı görevinin ne olacağı belirsiz kalır. Aynı satırı her gün yeniden açmak geçmiş sonucu değiştirir. Her günü baştan ayrı elle oluşturmak da tekrar kuralını kaybettirir.

Bu nedenle iki şeyi ayırdık:

```text
Tekrar kuralı = RoutineTemplate
Belirli günün sonucu = RoutineOccurrence
```

### Şantiye şefi açısından

Bir kontrol listesi şablonu ile o gün doldurulan kontrol formu aynı belge değildir. Şablon “her iş günü 17.00” der; Pazartesi formu “tamamlandı”, Salı formu “çalışma yoktu” diyebilir. Şablon Perşembe günü 16.30’a alınsa bile Pazartesi formunun üstündeki 17.00 geçmişi değişmemelidir.

## 3. Hangi dosyalara dokunduk?

```text
docs/field_tracking_v0_1_contract.md
docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md
ROADMAP.md
docs/project_decisions.md
learning/issue_098_saha_takibi_domain_ve_veri_sozlesmesi.md
learning/GLOSSARY.md
```

- `docs/field_tracking_v0_1_contract.md`: Bütün domain, recurrence, persistence, backup ve export kararlarının ayrıntılı kaynağıdır.
- `docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md`: Saha Takibi v0.1’i ürünün birinci önceliği olarak kaydeder.
- `ROADMAP.md`: Sözleşme aşamasını ve sonraki küçük implementation görevlerini gösterir.
- `docs/project_decisions.md`: Kalıcı teknik kararları kısa maddelerle taşır.
- Bu learning dosyası: Kararların Python öğrenen biri için nasıl koda dönüşeceğini açıklar.
- `learning/GLOSSARY.md`: Kalıcı teknik terimleri tanımlar.

Production code ve executable test dosyalarına dokunmadık. Aşağıdaki Python, SQL ve test blokları gelecekteki implementation’ın nasıl kurulacağını öğretmek için sözleşme örnekleridir; bu adımda çalışan uygulamaya eklenmemiştir.

## 4. Önce domain ayrımını anlayalım

Planlanan model ilişkisi sade biçimde şöyledir:

```python
@dataclass(frozen=True)
class RoutineTemplate:
    routine_template_id: str
    title: str
    recurrence_type: str
    local_time: str
    timezone: str
    revision: int = 1


@dataclass(frozen=True)
class RoutineOccurrence:
    routine_occurrence_id: str
    routine_template_id: str
    occurrence_local_date: str
    scheduled_local_time: str
    scheduled_at_utc: str
    status: str = "open"
    revision: int = 1
```

Bu kodun amacı:
Tekrar kuralını belirli günün gerçekleşmesinden ayırmak.

Satır satır açıklama:

- `@dataclass(frozen=True)`: Alan taşıyan ve oluşturulduktan sonra doğrudan değiştirilmeyen bir Python nesnesi planlar.
- `class RoutineTemplate`: Tekrar kuralının sınıfını tanımlar.
- `routine_template_id`: Şablonun benzersiz kimliğidir.
- `recurrence_type`: Günlük, iş günü, haftalık veya aylık kuralı taşır.
- `local_time`: Kullanıcının gördüğü `17:00` gibi yerel saattir.
- `timezone`: Yerel saatin hangi zaman bölgesinde yorumlanacağını söyler.
- `class RoutineOccurrence`: Tek bir yerel güne ait bağımsız kaydı tanımlar.
- `routine_template_id`: Occurrence’ın hangi şablondan doğduğunu gösterir.
- `occurrence_local_date`: Pazartesi ile Salı occurrence’ını ayıran yerel tarihtir.
- `scheduled_local_time`: Üretim gününde şablondan alınan saat snapshot’ıdır.
- `scheduled_at_utc`: Aynı planın veritabanındaki kesin UTC karşılığıdır.
- `status`: Bu günün açık mı kapalı mı olduğunu söyler.
- `revision`: Aynı kayıt üstünde çakışan düzenlemeleri fark etmeye yarar.

Sunu şöyle yaptık ki şablon güncellenince geçmiş günlük sonuçlar değişmesin: tekrar kuralını `RoutineTemplate`, her günün durumunu `RoutineOccurrence` içinde ayrı tuttuk.

Şantiye karşılığı:
Standart kontrol formunun boş şablonu ile belirli tarihte imzalanmış formu ayırmak gibidir.

## 5. `FollowUpItem` neden ayrı bir modeldir?

Tek seferlik takip, recurrence kuralına ihtiyaç duymaz.

```python
@dataclass(frozen=True)
class FollowUpItem:
    follow_up_id: str
    capture_text: str
    title: str
    item_type: str
    status: str
    project_id: str
    next_attention_at: str | None = None
    deadline_at: str | None = None
    revision: int = 1
```

Satır satır açıklama:

- `capture_text`: Sahada ilk yazılan özgün cümleyi korur.
- `title`: Listede kısa ve okunur başlıktır.
- `item_type`: İş yapma, birinden bekleme veya tekrar kontrol niyetini taşır.
- `status`: Kaydın yaşam döngüsünü taşır.
- `project_id`: Takibin hangi projeye ait olduğunu kesinleştirir.
- `next_attention_at`: Kaydın ne zaman tekrar öne çıkacağını belirtir.
- `deadline_at`: Gerçek son tarihtir; dikkat zamanıyla aynı değildir.

Sunu şöyle yaptık ki hızlı saha notunun özgün anlamı kaybolmadan sonradan düzenli bir liste başlığı kullanılabilsin: `capture_text` ve `title` alanlarını ayırdık.

Örnek:

```text
capture_text = "B blok perde filizlerini beton öncesi kontrol et."
title = "B blok perde filizi kontrolü"
condition_text = "Beton öncesi"
```

## 6. Stored status ile derived view arasındaki fark

Database’te yaşam döngüsü saklanır:

```python
FOLLOW_UP_STATUSES = (
    "inbox",
    "active",
    "waiting",
    "completed",
    "cancelled",
)
```

Ekran grubu ise zamana bakılarak hesaplanır:

```python
def attention_group(
    status: str,
    next_attention_at: datetime | None,
    deadline_at: datetime | None,
    now: datetime,
) -> str | None:
    if status in {"completed", "cancelled"}:
        return None

    candidates = [
        value for value in (next_attention_at, deadline_at) if value is not None
    ]
    if not candidates:
        return "now"

    attention_at = min(candidates)
    if attention_at < now:
        return "overdue"
    if attention_at.astimezone(ISTANBUL).date() == now.astimezone(ISTANBUL).date():
        return "today"
    return "upcoming"
```

Bu örnek kodda:

- Terminal kayıtlar açık iş ekranına sokulmaz.
- Dikkat ve deadline alanlarından dolu olanların en erkeni seçilir.
- Zaman geçmişse `overdue` hesaplanır.
- Aynı yerel gündeyse `today`, daha sonraysa `upcoming` hesaplanır.
- Hiç zaman yoksa kayıt kullanıcının önündeki plansız iş anlamında `now` olur.

`overdue` database’e yazılsaydı saat ilerlediğinde bütün satırları güncellemek gerekirdi. Türetilmiş değer olarak bırakınca aynı kalıcı veri farklı anda doğru görünümü üretir.

Sunu şöyle yaptık ki zaman ilerlediğinde database’e sahte status mutation’ları yazılmasın: yaşam döngüsü status’unu kalıcı, zaman grubunu hesaplanan değer yaptık.

## 7. Timezone ve UTC neden birlikte gerekir?

Recurrence kararı yerel takvimle verilir. Kalıcı bir an ise UTC tutulur.

```python
from datetime import date, datetime, time, timezone
from zoneinfo import ZoneInfo


ISTANBUL = ZoneInfo("Europe/Istanbul")


def scheduled_utc(local_date: date, local_time: time) -> datetime:
    local_value = datetime.combine(local_date, local_time, tzinfo=ISTANBUL)
    return local_value.astimezone(timezone.utc)
```

Satır satır açıklama:

- `ZoneInfo`: Python’un IANA timezone verisini kullanır.
- `Europe/Istanbul`: Recurrence için seçilen yerel takvim bölgesidir.
- `datetime.combine(...)`: Yerel tarih ve yerel saati tek datetime yapar.
- `tzinfo=ISTANBUL`: `17:00` değerinin İstanbul saati olduğunu belirtir.
- `astimezone(timezone.utc)`: Aynı gerçek anı UTC’ye çevirir.

Sunu şöyle yaptık ki “Pazartesi 17.00” ifadesi hem kullanıcı takviminde doğru gün olarak kalsın hem de veritabanında kesin bir an olsun: yerel tarih/saat snapshot’ı ile UTC karşılığını birlikte saklama kararı aldık.

Neden doğrudan `+03:00` yazmadık?
Timezone bir ürün sözleşmesidir. IANA adı, saat dilimi kurallarını ve gelecekteki değişiklikleri standart bir kaynaktan okur. Sabit offset yalnız bugünkü saat farkını anlatır; takvim bölgesinin kimliğini anlatmaz.

## 8. Idempotency nasıl kurulur?

En önemli SQLite kuralı şöyledir:

```sql
CREATE TABLE routine_occurrences (
    id TEXT PRIMARY KEY,
    routine_template_id TEXT NOT NULL REFERENCES routine_templates(id),
    occurrence_local_date TEXT NOT NULL,
    scheduled_local_time TEXT NOT NULL,
    scheduled_at_utc TEXT NOT NULL,
    status TEXT NOT NULL CHECK(status IN ('open', 'closed')),
    next_attention_at TEXT NOT NULL,
    outcome_type TEXT,
    outcome_note TEXT,
    revision INTEGER NOT NULL DEFAULT 1 CHECK(revision >= 1),
    created_at TEXT NOT NULL,
    completed_at TEXT,
    UNIQUE(routine_template_id, occurrence_local_date)
);
```

Satır satır açıklama:

- `id TEXT PRIMARY KEY`: Occurrence kimliği canonical UUID string olarak tutulur.
- `routine_template_id ... REFERENCES`: Şablon var olmadan occurrence eklenemez.
- `occurrence_local_date`: Recurrence’ın yerel gününü taşır.
- `CHECK(status IN ...)`: Desteklenmeyen status yazılmasını engeller.
- `revision ... CHECK(revision >= 1)`: Revision’ın geçerli aralıkta kalmasını sağlar.
- `UNIQUE(routine_template_id, occurrence_local_date)`: Aynı şablon ve aynı yerel gün için ikinci satırı database seviyesinde reddeder.

Python tarafında önce “var mı?” diye bakmak tek başına yeterli değildir. İki işlem aynı anda “yok” cevabı alabilir. Unique constraint son ve güvenilir kapıdır.

Planlanan insert mantığı:

```sql
INSERT INTO routine_occurrences (...)
VALUES (...)
ON CONFLICT(routine_template_id, occurrence_local_date) DO NOTHING;
```

Insert gerçekten bir satır eklediyse `routine_occurrence.created` event’i yazılır. Conflict olduysa var olan kayıt okunur; yeni event veya revision üretilmez.

Sunu şöyle yaptık ki uygulama aynı gün defalarca açılsa bile puantaj rutini çoğalmasın: idempotency’yi yalnız Python kontrolüne değil database unique constraint’ine bağladık.

## 9. Sınırlı backfill neden yedi gündür?

Seçilen pencere:

```python
from datetime import timedelta


window_start = max(template.start_date, today_local - timedelta(days=6))
window_end = min(today_local, template.end_date or today_local)
```

- `today_local - timedelta(days=6)`: Bugün dahil yedi yerel takvim günü verir.
- `max(...)`: Template daha yeni başladıysa başlangıçtan önce gün üretmez.
- `min(...)`: Template bittiyse bitişten sonra gün üretmez.

Sınırsız backfill neden tehlikelidir?

- Beş yıllık günlük şablon binlerce satırı bir anda oluşturabilir.
- Kullanıcı, geçmişte uygulama yokken yapılmamış görevleri gerçek kayıt sanabilir.
- Startup süresi ve event sayısı gereksiz büyür.

Yedi günlük sınır, birkaç gün kapalı kalan uygulamada yakın geçmişi görünür tutar. Daha eski eksik günler sessizce icat edilmez.

Geçmiş pencere günü ilk oluştuğunda iki olay vardır:

```text
sequence 1: routine_occurrence.created
sequence 2: routine_occurrence.missed
```

Occurrence önce revision `1` ile açılır, sonra aynı transaction içinde `missed` ile revision `2` olur. Kullanıcı daha sonra doğru bilgiyle yeniden açabilir; otomatik missed event’i tarihçeden silinmez.

## 10. Append-only event ve deterministic sıra

Planlanan event tablosunun önemli kısmı:

```sql
CREATE TABLE routine_occurrence_events (
    id TEXT PRIMARY KEY,
    routine_occurrence_id TEXT NOT NULL
        REFERENCES routine_occurrences(id),
    sequence INTEGER NOT NULL CHECK(sequence >= 1),
    event_type TEXT NOT NULL,
    actor TEXT NOT NULL,
    occurred_at TEXT NOT NULL,
    payload_json TEXT NOT NULL,
    UNIQUE(routine_occurrence_id, sequence)
);
```

Okuma:

```sql
SELECT id, event_type, actor, occurred_at, payload_json
FROM routine_occurrence_events
WHERE routine_occurrence_id = ?
ORDER BY sequence;
```

Neden `ORDER BY occurred_at, id` değil?

- İki event aynı timestamp’i taşıyabilir.
- UUID kronolojik sıra anlatmaz.
- Rastgele UUID’ye göre sıralama olayları ters gösterebilir.

Her aggregate için açık `sequence` kullanınca event’in mantıksal sırası kalıcı verinin bir parçası olur.

Sunu şöyle yaptık ki aynı saniyede üretilen `created` ve `missed` olayları her restart ve restore sonrasında aynı sırada okunsun: event tablolarına aggregate içi sequence ekledik.

## 11. Revision ve atomik mutation

Mevcut projede gözlem uygulama servisi ana kayıt ve event’i aynı Unit of Work içinde yazar. Yeni servisler de aynı kalıbı kullanacaktır.

Planlanan akış:

```python
with self._uow_factory() as unit_of_work:
    before = unit_of_work.follow_ups.get(follow_up_id)
    updated = unit_of_work.follow_ups.complete(
        follow_up_id,
        expected_revision,
        outcome_type,
        outcome_note,
        occurred_at,
    )
    unit_of_work.follow_up_events.add(
        self._completed_event(before, updated, occurred_at)
    )
    unit_of_work.commit()
```

Satır satır açıklama:

- `with ...`: Tek database connection ve transaction açar.
- `before`: Mutation öncesi değeri okur.
- `expected_revision`: Kullanıcının gördüğü sürümün hâlâ güncel olup olmadığını kontrol eder.
- `complete(...)`: Ana kaydın terminal alanlarını ve revision’ını değiştirir.
- `events.add(...)`: Aynı işin audit/history olayını ekler.
- `commit()`: İki yazıyı birlikte kalıcı yapar.

Event insert hata verirse context kapanırken transaction rollback olur. Böylece “kayıt tamamlandı ama geçmişte tamamlandı olayı yok” gibi yarım durum oluşmaz.

No-op örneği:

```python
if editable_before == editable_after:
    return current
```

Gerçek değişiklik yoksa revision ve event artırılmaz.

## 12. Backup kararını anlamak

Mevcut backup, SQLite database’in tamamının snapshot’ını alır:

```text
cse.sqlite3
```

Yeni tablolar aynı database içinde olacağı için follow-up ve rutin satırları ayrı bir ZIP entry gerektirmeden taşınır. Snapshot dosyasının SHA-256 digest’i değişirse backup doğrulaması bunu yakalar.

Neden manifest’e hemen yedi yeni count eklemedik?

- Backup formatı `1`.
- Manifest alanları exact set olarak doğrulanıyor.
- Yeni alan eklemek eski okuyucuyu bozar.
- SQLite snapshot digest’i yeni tabloları zaten kapsar.

Bu nedenle mevcut `observation_count` ve `event_count` anlamını değiştirmiyoruz. İleride tracking count’ları gerçekten gerekiyorsa backup format v2 ayrı tasarlanır.

Eski schema version `2` backup restore edildiğinde yeni, boş hedef köke çıkarılacak ve geçici kökte schema version `3` migration’ı çalışacaktır. Eski gözlem verisi korunur; yeni tracking tabloları boş başlar.

## 13. Resmî export exclusion neden test edilmelidir?

Kişisel “Ahmet’ten belge bekleniyor” notu resmî günlük saha gözlem export’una yanlışlıkla girerse veri alanları karışır.

Planlanan regression testi:

```python
def test_tracking_data_is_excluded_from_official_daily_export(tmp_path):
    without_tracking = build_fixture(tmp_path / "without", tracking=False)
    with_tracking = build_fixture(tmp_path / "with", tracking=True)

    first = export_bytes(without_tracking, local_date="2026-07-14")
    second = export_bytes(with_tracking, local_date="2026-07-14")

    assert second == first
    assert b"Puantajı tamamla" not in second
    assert b"Ahmet'ten belge bekleniyor" not in second
```

Bu testin amacı:
Tracking verisi eklenmesinin mevcut resmî export byte’larını bile değiştirmediğini göstermek.

Satır satır açıklama:

- İki eşdeğer data root hazırlanır.
- İkinci köke ek olarak kişisel tracking verisi yazılır.
- Aynı tarih, clock ve artifact kimliğiyle iki export üretilir.
- Byte eşitliği mevcut observation export sözleşmesinin değişmediğini kanıtlar.
- Örnek kişisel metinlerin ZIP içinde bulunmadığı ayrıca doğrulanır.

Sunu şöyle yaptık ki kişisel takip alanı resmî kayıt alanına sessizce sızmasın: export exclusion’ı yalnız dokümantasyon sözü değil, gelecekte byte-level regression testi olacak şekilde tanımladık.

## 14. Puantaj senaryosunun kod çalışma akışı

1. Kullanıcı `weekdays`, `17:00`, `Europe/Istanbul` template’i oluşturur.
2. Application service canonical UUID ve alanları doğrular.
3. Template ile `routine_template.created` aynı transaction’da yazılır.
4. Pazartesi uygulama açılınca yedi günlük pencere hesaplanır.
5. Pazartesi recurrence’a uyduğu için occurrence insert edilir.
6. Unique `(template_id, local_date)` constraint ikinci insert’i engeller.
7. Kullanıcı tamamlayınca occurrence `closed/completed`, revision `2` olur.
8. Salı aynı template için başka local date olduğundan başka occurrence oluşur.
9. Salı `no_work` sonucu Pazartesi satırını değiştirmez.
10. Çarşamba 17.00 geçerse kalıcı status `open` kalır fakat görünüm `overdue` hesaplanır.
11. Çarşamba 18.00’e erteleme yalnız Çarşamba `next_attention_at` değerini değiştirir.
12. Perşembe template saati 16.30 yapılınca yalnız henüz üretilmemiş günler yeni saati alır.
13. Template pasifleştirilince geçmiş occurrence ve event’ler kalır.
14. Backup SQLite snapshot’ı bütün satırlarla taşır.
15. Resmî günlük export bu kişisel rutin tablolarını hiç okumaz.

## 15. Test kodları hangi davranışları doğrulayacak?

### Idempotency testi

```python
def test_same_template_and_local_date_is_idempotent(service):
    first = service.ensure_occurrences(as_of="2026-07-13T14:00:00Z")
    second = service.ensure_occurrences(as_of="2026-07-13T14:01:00Z")

    assert second == first
    assert service.occurrence_count() == 1
    assert service.event_types() == ["routine_occurrence.created"]
```

Bu test aynı gün ikinci açılışın duplicate occurrence veya event üretmediğini doğrular.

### Template değişikliğinin geçmişi bozmama testi

```python
def test_template_time_change_does_not_rewrite_existing_occurrence(service):
    wednesday = service.ensure_for_date("2026-07-15")
    service.update_template_time(expected_revision=1, local_time="16:30")
    thursday = service.ensure_for_date("2026-07-16")

    assert wednesday.scheduled_local_time == "17:00"
    assert thursday.scheduled_local_time == "16:30"
```

Bu test snapshot kararını doğrular: Çarşamba geçmişi sabit kalır, Perşembe yeni template değerini alır.

### Atomiklik testi

```python
def test_event_failure_rolls_back_occurrence_completion(service, monkeypatch):
    occurrence = service.ensure_for_date("2026-07-13")
    monkeypatch.setattr(
        service,
        "_completed_event",
        lambda *_: (_ for _ in ()).throw(RuntimeError("event failed")),
    )

    with pytest.raises(RuntimeError, match="event failed"):
        service.complete_occurrence(
            occurrence.routine_occurrence_id,
            expected_revision=1,
        )

    unchanged = service.get_occurrence(occurrence.routine_occurrence_id)
    assert unchanged.status == "open"
    assert unchanged.revision == 1
```

Bu test event üretimi başarısızsa ana occurrence mutation’ının da rollback olduğunu doğrular.

## 16. Teknik karar tablosu — “Şunu şöyle yaptık ki...”

| Şunu yaptık | Şöyle yaptık | Çünkü | Böylece |
| --- | --- | --- | --- |
| Tekrar kuralını günlük sonuçtan ayırdık | Template ve occurrence modellerini ayrı tanımladık | Bir günün sonucu geleceği değiştirmemeli | Her gün bağımsız kapanır |
| Duplicate occurrence’ı engelledik | `(template_id, local_date)` unique constraint seçtik | Application kontrolünde yarış olabilir | Aynı gün çoklu açılış idempotent olur |
| Yakın geçmişi görünür tuttuk | Bugün dahil yedi günlük lazy backfill seçtik | Sınırsız geçmiş üretimi yanıltıcı ve pahalıdır | Birkaç günlük kapanma güvenli yönetilir |
| Yerel takvim ve kesin anı koruduk | Europe/Istanbul yerel tarih/saat ile UTC snapshot’ı birlikte sakladık | Recurrence yerel, persistence evrensel zamana ihtiyaç duyar | Gün ve an belirsizliği kalmaz |
| Geçmişi append-only yaptık | Aggregate içi event `sequence` kullandık | Timestamp ve UUID kesin sıra vermez | Restart/restore sonrası sıra değişmez |
| Çakışan düzenlemeyi fark ettik | `expected_revision` ve revision artışı tanımladık | Eski ekran yeni veriyi ezmemeli | Stale write reddedilir |
| Backup formatını koruduk | Yeni tabloları SQLite snapshot’a bıraktık, manifest count eklemedik | Exact manifest alanları eski okuyucuyu kırar | Format v1 korunur |
| Kişisel veriyi resmî export’tan ayırdık | Daily export’un yalnız observation akışını okumasını sabitledik | Kişisel not resmî kayda sızmamalı | Veri izolasyonu test edilebilir olur |

## 17. Yeni öğrendiğimiz yazılım kavramları

### Aggregate

Birlikte değiştirilen ve kendi tutarlılık sınırına sahip ana kayıt ve ona bağlı nesneler bütünüdür.

Bu projedeki karşılığı:
Bir `RoutineOccurrence` ve onun append-only event geçmişi aynı mutation sınırındadır.

Şantiye benzetmesi:
Bir günlük kontrol formu ve o forma ait işlem tarihçesi.

### Recurrence

Bir işin hangi yerel günlerde yeniden oluşacağını belirleyen tekrar kuralıdır.

Bu projedeki karşılığı:
`weekdays` kuralı Pazartesi–Cuma occurrence üretir.

### Occurrence

Tekrar kuralının belirli bir yerel tarihte oluşan bağımsız örneğidir.

Bu projedeki karşılığı:
Pazartesi puantaj occurrence’ı ile Salı occurrence’ı farklı kayıtlardır.

### Idempotency

Aynı işlemin tekrarlanmasının ilk başarılı sonuçtan sonra ek yan etki oluşturmamasıdır.

Bu projedeki karşılığı:
Aynı gün `ensure_occurrences` iki kez çalışsa da tek occurrence ve tek created event kalır.

### Backfill

Daha önce oluşması gereken fakat uygulama çalışmadığı için oluşmamış yakın geçmiş kayıtlarını sonradan üretmektir.

Bu projedeki karşılığı:
Uygulama birkaç gün kapalı kaldığında bugün dahil son yedi yerel gün değerlendirilir.

### Snapshot field

Kaynağın belli andaki değerini geçmiş kayıtta sabit tutan alandır.

Bu projedeki karşılığı:
Occurrence içindeki `scheduled_local_time`, template’in üretim anındaki saatidir.

### Optimistic concurrency

Kaydı uzun süre kilitlemek yerine yazma anında beklenen revision ile güncel revision’ı karşılaştıran çakışma yöntemidir.

Bu projedeki karşılığı:
`expected_revision=1` gönderilirken kayıt revision `2` olmuşsa mutation reddedilir.

### Append-only event

Eklenebilen fakat geçmiş satırları güncellenmeyen veya silinmeyen olay kaydıdır.

Bu projedeki karşılığı:
`missed` sonucu sonra düzeltilse bile eski missed event’i kalır.

### Export exclusion

Belirli bir veri alanının başka bir çıktı sözleşmesine varsayılan olarak dahil edilmemesidir.

Bu projedeki karşılığı:
Kişisel takip ve rutin verisi resmî günlük observation export’una girmez.

## 18. Mini sözlük

- **Template:** Tekrar kuralını taşıyan şablon.
- **Occurrence:** Şablonun belirli bir gündeki bağımsız örneği.
- **Local date:** Timezone’a göre kullanıcının takvim günü.
- **UTC:** Dünya çapında ortak zaman referansı.
- **IANA timezone:** `Europe/Istanbul` gibi kurallı zaman bölgesi adı.
- **No-op:** Geçerli çağrı olmasına rağmen veri gerçekten aynı olduğu için hiçbir mutation yapmayan işlem.
- **Revision conflict:** Kullanıcının eski kayıt sürümüyle yazmaya çalışması.
- **Unique constraint:** Aynı anahtar birleşiminin ikinci kez eklenmesini database seviyesinde engelleyen kural.
- **Fail-closed:** Doğrulama belirsiz veya başarısızsa işleme devam etmeme yaklaşımı.
- **Byte-for-byte:** İki dosyanın bütün byte’larının aynı olması.

## 19. Bu adımda bilinçli olarak ne yapmadık?

- Python domain class’larını production code’a eklemedik.
- SQLite schema version’ını yükseltmedik.
- Repository veya application service yazmadık.
- UI, notification veya scheduler eklemedik.
- Resmî tatil hesabı yapmadık.
- Puantajı personel/ücret/bordro modülüne çevirmedik.
- Kişisel tracking export’u üretmedik.
- Mevcut günlük resmî export formatını değiştirmedik.

Bunu bilinçli yaptık; çünkü Issue #98 önce sınırların kesinleşmesini istiyor. Recurrence ve geçmiş kuralları belirsizken production kodu yazmak, daha sonra veri migration’ı ve geriye uyumluluk problemi oluştururdu.

## 20. Sonraki adıma bağlantı

Bir sonraki küçük implementation görevinde önce saf domain record’ları, allowed list sabitleri ve recurrence hesaplayıcısı yazılabilir. Saf hesaplayıcı database’e erişmeden bir template ve tarih aralığından beklenen yerel tarihleri üretmelidir.

Sonra ayrı görevde schema version 3 migration ve repository’ler eklenir. Application service, backup backward restore ve export exclusion testleri de birbirinden ayrılarak ilerler. Böylece her adım küçük, anlaşılır ve `python -m pytest` ile doğrulanabilir kalır.
