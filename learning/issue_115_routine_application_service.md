# Issue 115 - RoutineApplicationService ve Yedi Günlük Lazy Backfill

## 1. Bu adımda ne öğrendik?

Bu adımda daha önce hazırlanmış üç katmanı bir araya getirdik:

```text
Saf domain ve recurrence helper'ları
        +
SQLite repository ve append-only event adapter'ları
        +
Tek transaction açan SQLiteUnitOfWork
        =
RoutineApplicationService
```

Application service yeni bir recurrence algoritması icat etmez. Kullanıcının “rutin oluştur”, “bugüne kadar eksik gerçekleşmeleri hazırla”, “ertele”, “kapat” veya “yeniden aç” niyetini mevcut domain ve persistence primitive'leriyle koordine eder.

Bu ayrım önemlidir:

- Domain katmanı bir tarihin routine'e uyup uymadığını hesaplar.
- Repository katmanı kaydı SQLite'a yazar veya okur.
- Unit of Work bütün yazıları tek transaction'da tutar.
- Application service bu parçaların hangi sırayla çağrılacağını belirler.

## 2. Immutable application değerleri

Template oluşturma girdisi frozen dataclass olarak tanımlandı:

```python
@dataclass(frozen=True, slots=True)
class CreateRoutineTemplate:
    title: str
    recurrence_type: RoutineRecurrenceType
    local_time: str
    start_date: str
    description: str | None = None
    project_id: str | None = None
    weekdays: frozenset[int] = frozenset()
    month_day: int | None = None
    end_date: str | None = None
    is_important: bool = False

    def __post_init__(self) -> None:
        _normalize_template_command(self)
```

Satır satır:

1. `@dataclass` tekrar eden constructor ve karşılaştırma kodunu üretir.
2. `frozen=True`, command oluşturulduktan sonra alanlarının doğrudan değiştirilmesini engeller.
3. `slots=True`, alan kümesini açık tutar ve yanlışlıkla yeni attribute eklenmesini önler.
4. `recurrence_type`, serbest string yerine domain enum'una dönüştürülür.
5. `weekdays`, değiştirilemeyen `frozenset` olarak saklanır.
6. `__post_init__`, nesne kullanıma açılmadan önce bütün alanları normalize eder ve doğrular.

Normalization helper'ının önemli parçası şöyledir:

```python
object.__setattr__(command, "title", _normalize_title(command.title))
object.__setattr__(
    command,
    "description",
    _normalize_optional_text(command.description, "description"),
)
recurrence_type = _coerce_enum(
    command.recurrence_type, RoutineRecurrenceType, "recurrence_type"
)
object.__setattr__(command, "recurrence_type", recurrence_type)
validate_local_time(command.local_time)
validate_local_date(command.start_date)
```

Burada `object.__setattr__` kullanmamızın nedeni dataclass'in frozen olmasıdır. Normal kullanıcı kodu frozen nesneyi değiştiremez; fakat `__post_init__` içinde normalize edilmiş ilk değeri yerleştirmek için bu kontrollü yol kullanılabilir.

Başlık normalization'ı:

```python
def _normalize_title(value: str) -> str:
    if not isinstance(value, str):
        raise ValueError("title must be a string")
    normalized = " ".join(value.split())
    if not normalized:
        raise ValueError("title must not be empty")
    return normalized
```

Örnek:

```text
"  Günlük   saha\nraporu  "
->
"Günlük saha raporu"
```

Bu işlem harfleri, Türkçe karakterleri veya anlamı değiştirmez. Yalnız whitespace'i kararlı hâle getirir.

## 3. Template oluşturma akışı

Production kodundaki create akışının özü:

```python
with self._uow_factory() as unit_of_work:
    if command.project_id is not None:
        unit_of_work.projects.get(command.project_id)
    occurred_at = self._now()
    template = RoutineTemplate(
        routine_template_id=self._new_id(),
        title=command.title,
        recurrence_type=command.recurrence_type,
        local_time=command.local_time,
        start_date=command.start_date,
        created_at=occurred_at,
        updated_at=occurred_at,
        # diğer doğrulanmış command alanları...
    )
    unit_of_work.routine_templates.add(template)
    unit_of_work.routine_template_events.add(created_event)
    unit_of_work.commit()
```

Satır satır çalışma sırası:

1. `with` bloğu bir `SQLiteUnitOfWork` açar.
2. UoW içeride `BEGIN IMMEDIATE` transaction başlatır.
3. Proje kimliği doluysa aynı transaction içindeki project repository ile varlığı doğrulanır.
4. Proje yoksa `RecordNotFound` yükselir; clock ve UUID henüz tüketilmez.
5. Clock canonical UTC zamanı verir.
6. İlk UUID template kimliği olur.
7. Domain constructor recurrence ve yaşam döngüsü değişmezlerini yeniden doğrular.
8. Aggregate revision 1 olarak eklenir.
9. İkinci UUID, sequence 1 `routine_template.created` event kimliği olur.
10. Tek commit aggregate ile event'i birlikte kalıcılaştırır.

Event payload bütün template snapshot'ını kopyalamaz:

```python
payload={
    "local_time": template.local_time,
    "project_id": template.project_id,
    "recurrence_type": template.recurrence_type.value,
    "revision": template.revision,
    "status": template.status.value,
}
```

Bu payload, create işleminin audit için gereken minimum iş anlamını taşır.

## 4. Update ve normalize edilmiş no-op

Template update yalnız açık allowlist alanlarını kullanır:

```python
values = {
    field_name: getattr(command, field_name)
    for field_name in TEMPLATE_UPDATE_FIELDS
}
changed_fields = sorted(
    field_name
    for field_name, value in values.items()
    if getattr(current, field_name) != value
)
if not changed_fields:
    return current
```

Satır satır:

1. `TEMPLATE_UPDATE_FIELDS`, değiştirilebilecek alanları açıkça sınırlar.
2. `timezone`, identity, status, revision ve timestamp alanları bu listede değildir.
3. Command daha önce normalize edildiği için karşılaştırma biçimsel whitespace farkıyla event üretmez.
4. Gerçekten değişen alan adları `sorted(...)` ile alfabetik olur.
5. Liste boşsa mevcut aggregate döner.
6. Bu dönüş `_now()` ve event UUID üretiminden önce olduğu için no-op clock/UUID tüketmez.

Gerçek update:

```python
updated = replace(
    current,
    **values,
    revision=current.revision + 1,
    updated_at=occurred_at,
)
```

`replace(...)`, frozen template'i yerinde değiştirmez. Aynı kimliğe sahip yeni revision nesnesi üretir. Önceden oluşturulmuş occurrence'lar ayrı satırlar olduğu için template update onların schedule snapshot alanlarına dokunmaz.

## 5. Stale-before-no-op neden önemli?

Bütün revision taşıyan mutation'larda sıra şöyledir:

```text
aggregate'i oku
-> expected_revision ile current.revision karşılaştır
-> transition/no-op kararını ver
```

Örnek:

```python
current = unit_of_work.routine_templates.get(routine_template_id)
self._require_current_revision(
    current.routine_template_id,
    current.revision,
    expected_revision,
)
if current.status == RoutineTemplateStatus.INACTIVE:
    return current
```

Kullanıcı eski revision `1` ile daha önce pasifleştirilmiş revision `2` template'e tekrar istek gönderirse işlem “zaten inactive” diyerek sessiz başarı dönmez. Önce `RevisionConflict` verir. Yalnız güncel revision `2` ile yapılan exact retry no-op olabilir.

## 6. Yedi günlük lazy backfill

`ensure_occurrences` canonical UTC anı İstanbul yerel gününe çevirir:

```python
validate_utc_timestamp(as_of_utc)
today_local = _istanbul_date(as_of_utc)
```

Örnek:

```text
as_of_utc = 2026-07-16T09:00:00Z
Europe/Istanbul local day = 2026-07-16
pencere = 2026-07-10 ... 2026-07-16
```

Her template için mevcut saf domain helper'ı çağrılır:

```python
for template in templates:
    for local_date in due_routine_dates(template, today_local):
        ...
```

`due_routine_dates(...)` şu kuralları zaten bilir:

- yalnız son yedi takvim günü;
- daily, weekdays, weekly ve monthly eşleşmesi;
- start/end date clipping;
- monthly 31 değerinin günü olmayan aya kaydırılmaması;
- inactive template'in İstanbul yerel deactivation sınırı.

Application service böylece recurrence hesabını kopyalamaz.

## 7. Existing occurrence neden en başta aranıyor?

```python
try:
    existing = unit_of_work.routine_occurrences.get_by_template_date(
        template.routine_template_id, local_date_text
    )
except RecordNotFound:
    pass
else:
    ensured.append(existing)
    continue
```

Satır satır:

1. Natural key `(routine_template_id, occurrence_local_date)` çiftidir.
2. Kayıt varsa doğrudan return listesine eklenir.
3. `continue`, clock ve UUID üretim bloklarına girilmesini engeller.
4. Yeni revision veya event yazılmaz.
5. İkinci `ensure_occurrences` çağrısı bu nedenle tam idempotent olur.

Repository'nin `add_if_absent` primitive'i ve SQLite unique constraint'i yine son savunmadır. Application pre-check kullanıcı açısından gereksiz clock/UUID tüketimini önler; database constraint ise olası duplicate insert'i fiziksel seviyede engeller.

## 8. Geçmiş gün neden iki event üretir?

Issue sözleşmesi geçmiş eksik occurrence'ın doğrudan closed revision 1 olarak doğmasını istemez. Önce gerçekleşmenin var olduğu, sonra kaçırılmış olarak kapandığı kaydedilir.

İlk kayıt:

```python
candidate = RoutineOccurrence(
    routine_occurrence_id=self._new_id(),
    routine_template_id=template.routine_template_id,
    occurrence_local_date=plan.schedule.occurrence_local_date,
    scheduled_local_time=plan.schedule.scheduled_local_time,
    scheduled_at_utc=plan.schedule.scheduled_at_utc,
    status=RoutineOccurrenceStatus.OPEN,
    next_attention_at=plan.schedule.next_attention_at,
    revision=1,
    created_at=created_at,
)
```

Sonra, tarih bugünden önceyse:

```python
missed = replace(
    stored,
    status=RoutineOccurrenceStatus.CLOSED,
    outcome_type=RoutineOccurrenceOutcome.MISSED,
    outcome_note=None,
    completed_at=missed_at,
    revision=stored.revision + 1,
)
```

Kalıcı sıra:

```text
revision 1 / open
routine_occurrence.created / sequence 1
->
revision 2 / closed + missed
routine_occurrence.missed / sequence 2
->
tek commit
```

Bu yazılardan herhangi biri başarısız olursa UoW context manager transaction'ı rollback eder. Yarım open kayıt veya event'siz missed kayıt kalmaz.

Bugünün occurrence'ı ise yalnız ilk aşamada kalır:

```text
revision 1 / open / created event sequence 1
```

Future occurrence üretilmez.

## 9. Schedule snapshot nasıl korunuyor?

Occurrence oluşturulurken şu alanlar template'ten kopyalanır:

```text
occurrence_local_date
scheduled_local_time
scheduled_at_utc
```

Snooze yalnız dikkat anını değiştirir:

```python
updated = replace(
    current,
    next_attention_at=next_attention_at,
    revision=current.revision + 1,
)
```

Close status/outcome/timestamp yazar fakat schedule alanlarını listelemez. Reopen da outcome alanlarını temizleyip yeni attention yazar; schedule alanları yine korunur.

Repository ayrıca schedule snapshot alanlarını immutable sayar. Application katmanındaki hata bu alanları değiştirmeye çalışsa bile repository ikinci savunma olarak `InvalidRecordError` verir.

## 10. Kullanıcı close sonucu ile otomatik missed ayrımı

Command sınırı:

```python
USER_CLOSE_OUTCOMES = (
    RoutineOccurrenceOutcome.COMPLETED,
    RoutineOccurrenceOutcome.NO_WORK,
    RoutineOccurrenceOutcome.NOT_REQUIRED,
)
```

`RoutineOccurrenceOutcome.MISSED` bu listede yoktur. Bunun anlamı:

- Kullanıcı “tamamlandı” diyebilir.
- Kullanıcı “çalışma yoktu” diyebilir.
- Kullanıcı “gerekli değildi” diyebilir.
- Sistem sınırlı geçmiş backfill sırasında “missed” verebilir.
- Kullanıcı normal close komutuyla yapay bir missed geçmişi yazamaz.

## 11. Occurrence view sorguları neden backfill yapmıyor?

`list_occurrences(...)` yalnız repository kayıtlarını okur ve mevcut saf classifier'ı kullanır:

```python
if classify_routine_occurrence(occurrence, query.as_of_utc) == expected_group
```

Salt-okunur sorgunun `ensure_occurrences(...)` çağırmaması bilinçli karardır. Böylece liste çağrısının gizli mutation yapmadığı anlaşılır. Backfill açık application use-case olarak ayrıca çağrılır.

Closed occurrence için classifier `None` döndürür; bu nedenle closed kayıtlar overdue/today/upcoming gruplarına girmez.

## 12. Test kodu neyi kanıtlıyor?

Odaklı test dosyası:

```text
tests/test_routine_application_service.py
```

Örnek idempotency testi:

```python
first = service.ensure_occurrences(AS_OF_UTC)
calls = (clock.calls, ids.calls)
second = service.ensure_occurrences(AS_OF_UTC)

assert second == first
assert (clock.calls, ids.calls) == calls
```

Bu test yalnız duplicate satır oluşmadığını kontrol etmez. İkinci çağrının clock veya UUID de tüketmediğini kanıtlar.

Geçmiş event sırası testi:

```python
assert [event.sequence for event in history] == [1, 2]
assert [event.event_type for event in history] == [
    RoutineOccurrenceEventType.CREATED,
    RoutineOccurrenceEventType.MISSED,
]
```

Bu test timestamp veya UUID sırasına güvenmez; aggregate event sequence sözleşmesini doğrudan doğrular.

Rollback testi event repository'sine hata enjekte eder:

```python
monkeypatch.setattr(
    SQLiteRoutineOccurrenceEventRepository,
    "add",
    lambda *_: (_ for _ in ()).throw(InvalidRecordError("event failed")),
)
```

Ardından database yeniden açılarak occurrence tablosunun boş olduğu doğrulanır. Bu, bellekte exception görülmesinden daha güçlüdür; gerçek kalıcılık sonucunu kontrol eder.

## 13. Teknik karar tablosu

| Karar | Seçilen yaklaşım | Neden |
| --- | --- | --- |
| Service modülü | `app/application/routines.py` | Follow-up service'i büyütmeden sorumluluğu dar tutar |
| Zaman girdisi | Canonical `as_of_utc` | Test edilebilir ve timezone dönüşümü açık olur |
| Yerel takvim | `Europe/Istanbul` | Domain sözleşmesinin tek v0.1 timezone'u |
| Backfill penceresi | Bugün dahil son 7 yerel gün | Sınırsız geçmiş üretimini engeller |
| Duplicate savunması | Pre-check + `add_if_absent` + unique constraint | Hem yan etki tüketimini hem fiziksel duplicate'i önler |
| Geçmiş kayıt | Open/create sonra closed/missed | Gerçek yaşam döngüsü ve append-only history korunur |
| Event sırası | History son sequence + 1 | UUID/timestamp tie-breaker'a ihtiyaç bırakmaz |
| Update no-op | Normalize edilmiş alan karşılaştırması | Biçimsel fark revision/event üretmez |
| View sorgusu | Salt-okunur | Listelemenin gizli mutation yapmasını engeller |
| Persistence değişikliği | Yok | Mevcut port ve adapter'lar gerekli primitive'leri zaten sunar |

## 14. Kodun çalışma akışı

```text
Create/update/deactivate template
-> command validation
-> BEGIN IMMEDIATE
-> aggregate + revision kontrolü
-> gerçek mutation varsa aggregate update
-> sequence hesapla ve event append et
-> commit veya rollback

ensure_occurrences(as_of_utc)
-> UTC doğrula
-> İstanbul bugünü hesapla
-> bütün template'leri deterministic sırada oku
-> her template için son 7 günlük due dates
-> natural-key existing kontrolü
-> yoksa open revision 1 + created event
-> geçmişse closed/missed revision 2 + missed event
-> tek commit
-> date/template/occurrence sıralı tuple döndür

snooze/close/reopen
-> ID ve command doğrula
-> aggregate oku
-> stale revision kontrolü
-> lifecycle transition/no-op kontrolü
-> schedule snapshot'ı koruyan replace
-> event append
-> commit veya rollback
```

## 15. Şunu şöyle yaptık ki...

Şunu şöyle yaptık ki application service recurrence hesabını, SQL'i ve transaction yönetimini aynı yerde yeniden yazmasın:

- tarih hesabını mevcut saf domain helper'larına bıraktık;
- kalıcılığı mevcut repository adapter'larına bıraktık;
- atomikliği mevcut Unit of Work'e bıraktık;
- service içinde yalnız use-case sırasını ve ürün kararlarını koordine ettik;
- no-op kontrollerini clock/UUID üretiminden önce yaptık;
- geçmiş occurrence'ı iki revision/event olarak fakat tek transaction'da yazdık;
- liste sorgularını mutation'dan ayırdık;
- kullanıcıya açık close sonucu ile otomatik `missed` sonucunu ayırdık;
- schema, migration, mapping, repository portu ve web/UI kapsamını büyütmedik.

Sonuç olarak kullanıcı için günlük puantaj gibi rutinler ayrı gün kayıtlarına dönüşür; uygulama tekrar açıldığında yakın geçmiş kaybolmaz; aynı ensure tekrarlandığında duplicate üretilmez; template değişikliği geçmiş occurrence snapshot'larını bozmaz.

## 16. Doğrulama sonucu

```text
Focused RoutineApplicationService suite: 48 passed
İlgili domain/persistence/UoW/follow-up regresyonu: 224 passed
Tam suite: 948 passed, 7 skipped
```

Yedi skip, Windows ortamında symlink oluşturma ayrıcalığı bulunmayan mevcut attachment testleridir. Routine implementation ile ilgili failure yoktur.
