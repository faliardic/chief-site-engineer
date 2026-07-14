# Issue 100 - Saha Takibi Domain Kayıtları ve Saf Recurrence

## 1. Bu adımda ne yaptık?

Issue #98’de yazılan sözleşmeyi ilk kez çalışan Python koduna çevirdik. Bu adımda yalnız domain kayıtları, validation ve saf hesaplar eklendi.

Değişen ana dosyalar:

```text
app/field_tracking.py
tests/test_field_tracking.py
requirements.txt
CHANGELOG.md
ROADMAP.md
docs/project_decisions.md
learning/GLOSSARY.md
learning/issue_100_saha_takibi_domain_ve_saf_recurrence.md
```

Yeni production modülü şu parçaları taşır:

```text
FollowUpItem
FollowUpEvent
RoutineTemplate
RoutineTemplateEvent
RoutineOccurrence
RoutineOccurrenceEvent
RoutineOccurrenceSchedule
RoutineOccurrencePlan
```

Ayrıca şu saf API’ler eklendi:

```python
normalize_capture_text(value)
create_follow_up_item(...)
matches_routine_date(template, local_date)
due_routine_dates(template, today_local, window_days=7)
build_occurrence_schedule(template, local_date)
plan_routine_occurrence(template, local_date, today_local)
classify_follow_up(item, today_local)
is_now_attention_item(item, now_utc)
select_now_attention_items(items, now_utc)
classify_routine_occurrence(occurrence, now_utc)
```

Bu görev SQLite’a tablo eklemedi, repository veya application service yazmadı ve gerçek kullanıcı data root’una hiçbir kayıt üretmedi.

## 2. Neden ayrı `app/field_tracking.py` modülü kullandık?

Mevcut `app/models.py` uzun süredir çok sayıda eski model ve yardımcı taşıyor. Yeni Saha Takibi alanını aynı dosyanın sonuna eklemek, recurrence kuralları ile eski kayıtları birbirine karıştıracaktı.

Karar:

```text
Eski genel modeller       -> app/models.py
Saha Takibi domain alanı  -> app/field_tracking.py
```

Bu yeni bir framework veya katman değildir. Yalnız aynı ürün alanına ait kayıt ve saf fonksiyonları okunabilir bir dosyada toplar.

## 3. Immutable domain kaydı nasıl çalışır?

Gerçek kodun sadeleştirilmiş biçimi:

```python
@dataclass(frozen=True, slots=True)
class FollowUpItem:
    follow_up_id: str
    capture_text: str
    title: str
    created_at: str
    updated_at: str
    status: FollowUpStatus = FollowUpStatus.INBOX
    project_id: str | None = None
    next_attention_at: str | None = None
    revision: int = 1
```

Satır satır açıklama:

- `@dataclass`: Constructor, karşılaştırma ve temsil gibi tekrar eden kayıt kodunu Python üretir.
- `frozen=True`: Nesne oluştuktan sonra `item.title = ...` gibi doğrudan atamalar engellenir.
- `slots=True`: Alan kümesini sabitler ve yanlışlıkla yeni attribute eklenmesini önler.
- `follow_up_id`: Mevcut canonical UUID helper’ıyla doğrulanan değişmez kimliktir.
- `capture_text`: Kullanıcının ilk yakalama anlamını koruyan normalize edilmiş metindir.
- `title`: İlk create sırasında capture ile aynıdır; ileride yeni revision nesnesinde değişebilir.
- `project_id`: `None` olabilir; bu kayıt kişisel çalışma alanında kalır.
- `next_attention_at`: `inbox` için boş olabilir; `active` ve `waiting` için zorunludur.
- `revision`: En az `1` olan optimistic concurrency sayacıdır.

Buradaki immutable yaklaşım “kayıt asla değişmez” anlamına gelmez. Sonraki application service görevi güncellemede yeni alan değerleri ve artırılmış revision ile yeni bir domain nesnesi oluşturacaktır.

## 4. Hızlı `+ Unutma` normalizasyonu

Gerçek yardımcı küçüktür:

```python
def normalize_capture_text(value: str) -> str:
    if not isinstance(value, str):
        raise ValueError("capture_text must be a string")
    normalized = " ".join(value.split())
    if not normalized:
        raise ValueError("capture_text must not be empty")
    return normalized
```

Satır satır:

1. Girdi string değilse erken hata verilir.
2. `value.split()` baş/son whitespace’i kaldırır ve kelimeleri bütün whitespace sınırlarından ayırır.
3. `" ".join(...)` parçaları tek normal boşlukla birleştirir.
4. Hiç parça kalmadıysa kullanıcı yalnız boşluk yazmıştır; kayıt reddedilir.
5. Harf, Türkçe karakter, noktalama ve büyük/küçük harf dönüştürülmez.

Factory aynı normalize edilmiş değeri iki alana yazar:

```python
normalized = normalize_capture_text(capture_text)
return FollowUpItem(
    follow_up_id=follow_up_id,
    capture_text=normalized,
    title=normalized,
    created_at=created_at,
    updated_at=created_at,
)
```

Burada AI, özetleme veya otomatik sınıflandırma yoktur. `follow_up_id` ve `created_at` kullanıcı içeriği değil, dış application sınırının teknik girdileridir.

## 5. Follow-up yaşam döngüsü validation’ı

Temel açık kayıt kuralı:

```python
if self.status in (FollowUpStatus.ACTIVE, FollowUpStatus.WAITING):
    if self.next_attention_at is None:
        raise ValueError(
            "active and waiting follow-ups require next_attention_at"
        )
```

Bu kontrolün sonucu:

| Status | `next_attention_at = None` | Açıklama |
| --- | --- | --- |
| `inbox` | Kabul | Görünür Unutma Kutusu kaydı |
| `active` | Ret | Planlı açık iş zaman taşımak zorunda |
| `waiting` | Ret | Yeniden bakma zamanı zorunlu |
| `completed` | Duruma bağlı | Terminal outcome/timestamp kuralları ayrıca çalışır |
| `cancelled` | Duruma bağlı | Cancel outcome/timestamp kuralları ayrıca çalışır |

Terminal durumda outcome ve kapanış zamanı birlikte doğrulanır. Terminal olmayan durumda outcome alanlarının dolu olması reddedilir. Böylece örneğin `status="active"` ile `completed_at` aynı kayıtta sessizce bulunamaz.

Observation için domain’in bildiği yerel sınır şudur:

```python
if self.observation_id is not None and self.project_id is None:
    raise ValueError("observation_id requires project_id")
```

Bu modül observation aggregate’ini yüklemez. İki project kimliğinin gerçekten eşit olduğunu kontrol etmek, sonraki application/repository görevinin cross-aggregate validation sorumluluğudur.

## 6. Recurrence eşleşmesi

Recurrence hesabı string tarihleri birbirleriyle karşılaştırmaz. Template içindeki `YYYY-MM-DD` değerleri `date` nesnesine çevrilir; hesap `date.isoweekday()` ve `date.day` kullanır.

Gerçek karar akışı:

```python
if template.recurrence_type == RoutineRecurrenceType.DAILY:
    return True
if template.recurrence_type == RoutineRecurrenceType.WEEKDAYS:
    return local_date.isoweekday() <= 5
if template.recurrence_type == RoutineRecurrenceType.WEEKLY:
    return local_date.isoweekday() in template.weekdays
return local_date.day == template.month_day
```

Anlamları:

- `daily`: Tarih aralığındaki her gün.
- `weekdays`: ISO Pazartesi `1` ile Cuma `5` arası.
- `weekly`: Kullanıcının seçtiği immutable `frozenset` içindeki ISO günleri.
- `monthly`: Yerel gün numarası `month_day` ile aynıysa eşleşir.

Monthly kuralında “31 yoksa ayın son gününe taşı” davranışı yazılmadı. Fonksiyon yalnız gerçekten var olan `date` nesnesinin gününü karşılaştırdığı için Şubat otomatik kaydırma üretmez.

## 7. Bugün dahil yedi günlük pencere

Gerçek başlangıç hesabı:

```python
first_day = today_local - timedelta(days=window_days - 1)
```

Varsayılan `window_days=7` için:

```text
ilk gün = bugün - 6 gün
son gün = bugün
```

Fonksiyon bu aralıkta ileri doğru yürür ve yalnız `matches_routine_date(...)` sonucu doğru olan tarihleri tuple içine alır. Bu nedenle:

- sekizinci gün otomatik dışarıda kalır;
- gelecek gün üretilmez;
- template başlangıç ve bitiş sınırı dahil uygulanır;
- sonuç eski tarihten bugüne deterministic sıralıdır;
- `window_days < 1` reddedilir.

## 8. Europe/Istanbul ve UTC snapshot

Schedule hesabının özü:

```python
local_timestamp = datetime.combine(
    local_date,
    local_clock,
    tzinfo=ZoneInfo(template.timezone),
)
scheduled_at_utc = serialize_utc_timestamp(local_timestamp)
```

Satır satır:

- `datetime.combine`: Yerel tarih ile yerel saati tek datetime yapar.
- `ZoneInfo(template.timezone)`: Bu datetime’ın `Europe/Istanbul` takviminde yorumlandığını söyler.
- `serialize_utc_timestamp`: Mevcut ortak helper ile anı UTC’ye çevirip canonical `Z` string üretir.

Örnek:

```text
Yerel: 2026-07-14 17:00 Europe/Istanbul
UTC:   2026-07-14T14:00:00Z
```

Kod içinde sabit `+03:00` kullanılmadı. Windows çoğu zaman sistem IANA timezone veritabanı sağlamadığı için `requirements.txt` dosyasına `tzdata` eklendi. `ZoneInfo` yine IANA adını kullanır; veri kaynağı taşınabilir olur.

`RoutineOccurrenceSchedule` şu snapshot’ları birlikte taşır:

```text
occurrence_local_date
scheduled_local_time
scheduled_at_utc
next_attention_at
```

İlk planda `next_attention_at == scheduled_at_utc` zorunludur. Daha sonraki snooze mutation’ı bu görevde yoktur.

## 9. Geçmiş gün ve bugün planı

Saf plan fonksiyonu persistence yapmaz:

```python
if local_date < today_local:
    return RoutineOccurrencePlan(
        schedule=schedule,
        status=RoutineOccurrenceStatus.CLOSED,
        outcome_type=RoutineOccurrenceOutcome.MISSED,
    )
return RoutineOccurrencePlan(
    schedule=schedule,
    status=RoutineOccurrenceStatus.OPEN,
    outcome_type=None,
)
```

Önemli sınır:

- Geçmiş uygun gün plan sonucu `missed` olur.
- Bugünün uygun günü `open` olur.
- Gelecek gün reddedilir.
- Bu fonksiyon occurrence UUID veya event UUID üretmez.
- Contract’taki “önce created, sonra missed event” transaction davranışı sonraki application service görevidir.

## 10. Görünüm sınıflandırması

Follow-up için etkin dikkat anı:

```text
min(next_attention_at, deadline_at)  # deadline varsa
```

Sonra UTC anı Europe/Istanbul yerel tarihine çevrilir:

```text
yerel tarih < bugün  -> overdue
yerel tarih = bugün  -> today
yerel tarih > bugün  -> upcoming
status = inbox       -> inbox
```

`now` adlı enum veya domain kategorisi yoktur.

“Şimdi ilgilen” predicate’i üç koşuldan birini arar:

```text
overdue
 bugün ve effective_attention_at <= now
 important inbox
```

`select_now_attention_items` girdiyi sırayla gezer, `follow_up_id` için bir `seen_ids` seti tutar ve aynı kaydı yalnız bir kez döndürür. Bu bir UI query composition’dır; yeni status değildir.

Occurrence sınıflandırması yalnız `open` kayıt için `next_attention_at` üzerinden yapılır. Kapanmış occurrence hiçbir açık görünüm grubuna girmez.

## 11. Event kayıtları ve deterministic payload

Üç event ailesinin ayrı enum’u vardır:

```text
FollowUpEventType
RoutineTemplateEventType
RoutineOccurrenceEventType
```

Her event şunları doğrular:

- event ve aggregate kimliği canonical UUID;
- `sequence >= 1`;
- event type kendi allowed list’inde;
- actor boş değil;
- `occurred_at` canonical UTC `Z`;
- payload bir JSON object;
- payload içinde `revision >= 1`;
- JSON key sırası deterministic.

Deterministic çıktı örneği:

```python
event.payload_json
# {"a":{"ş":"değer"},"revision":1,"z":2}
```

Repository sequence’in bir önceki event’ten tam bir büyük olmasını ve unique constraint’i sonraki görevde yönetecek. Domain kaydı bu görevde yalnız tek event’in `sequence >= 1` sınırını doğrular.

## 12. Test kodunu okuyalım

Hızlı yakalama testi:

```python
def test_quick_capture_factory_needs_only_capture_as_user_content() -> None:
    item = create_follow_up_item(
        follow_up_id=FOLLOW_UP_ID,
        capture_text="  Pompa   gelmeden hortumu kontrol et  ",
        created_at=CREATED_AT,
    )

    assert item.capture_text == "Pompa gelmeden hortumu kontrol et"
    assert item.title == item.capture_text
    assert item.status == "inbox"
    assert item.project_id is None
    assert item.next_attention_at is None
```

Test neyi kanıtlar?

1. Kullanıcı içerik alanı yalnız capture metnidir.
2. Whitespace deterministic normalize edilir.
3. İlk title aynı değerdir.
4. Kayıt projectless kişisel inbox olarak başlar.
5. İlk kayıt zamanlanmamıştır.

Yedi günlük pencere testi:

```python
due = due_routine_dates(template, date(2026, 7, 14))
assert due == tuple(date(2026, 7, day) for day in range(8, 15))
assert date(2026, 7, 7) not in due
```

Bu test bugün dahil yedi günü, sekizinci günün dışlanmasını, sıralamayı ve geleceğin üretilmemesini aynı örnekte doğrular.

Timezone testi:

```python
schedule = build_occurrence_schedule(template, date(2026, 7, 14))
assert schedule.scheduled_local_time == "17:00"
assert schedule.scheduled_at_utc == "2026-07-14T14:00:00Z"
```

Bu test yalnız UTC sonucunu değil, kullanıcıya gösterilecek yerel snapshot’ın da korunduğunu kanıtlar.

## 13. Teknik karar tablosu

| Konu | Seçilen çözüm | Neden |
| --- | --- | --- |
| Dosya yerleşimi | `app/field_tracking.py` | Büyük `app/models.py` dosyasını daha da büyütmemek |
| Kayıt tipi | Frozen/slots dataclass | Doğrulanmış domain snapshot’larını doğrudan mutation’dan korumak |
| UUID/UTC | Mevcut helper’ları reuse | Aynı canonical kuralın ikinci kopyasını oluşturmamak |
| Capture title | Normalize capture ile birebir | Hızlı akış ve AI’sız determinism |
| Tarih hesabı | `date`, `time`, `datetime` | String sıralamasına dayanmamak |
| Timezone | IANA `ZoneInfo` + `tzdata` | Windows dahil taşınabilir doğru timezone verisi |
| Pencere | Bugün dahil son 7 gün | Sınırsız geçmiş üretimini engellemek |
| Aylık eksik gün | Üretme, kaydırma yok | Kullanıcının seçmediği güne görev taşımamak |
| Şimdi ilgilen | Saf union/predicate | `now` adlı kalıcı kategori oluşturmamak |
| Persistence | Bu görevde yok | Task 2/5 kapsamını küçük ve test edilebilir tutmak |

## 14. Kod çalışma akışı

```text
Kullanıcı capture metni
-> normalize_capture_text
-> create_follow_up_item
-> doğrulanmış personal inbox FollowUpItem

RoutineTemplate + today_local
-> due_routine_dates
-> matches_routine_date
-> eski tarihten bugüne uygun date tuple
-> build_occurrence_schedule
-> Europe/Istanbul local snapshot + canonical UTC snapshot
-> plan_routine_occurrence
-> geçmişte missed / bugün open saf plan

FollowUpItem veya RoutineOccurrence + açık now/today girdisi
-> effective attention
-> Europe/Istanbul yerel tarih
-> derived view group veya Şimdi ilgilen predicate sonucu
```

Akışta database açma, dosya yazma, sistem saatini okuma veya UUID üretme adımı yoktur.

## 15. Şunu şöyle yaptık ki...

- Capture whitespace’ini boundary’de normalize ettik ki aynı anlam farklı boşluklarla kararsız title üretmesin.
- Kayıtları frozen dataclass yaptık ki ileride revision ve event akışı atlanarak sessiz in-place mutation yapılması zorlaşsın.
- `today` ve `now` değerlerini fonksiyon argümanı yaptık ki testler sistem saatine bağlı ve kararsız olmasın.
- Recurrence’ı saf fonksiyon yaptık ki SQLite veya UI beklemeden bütün takvim kenarları test edilebilsin.
- `ZoneInfo("Europe/Istanbul")` ve `tzdata` kullandık ki sabit offset kuralı yazmadan Windows’ta da aynı IANA davranışı çalışsın.
- Yedi günlük pencereyi fonksiyon içinde sınırladık ki uygulama uzun süre kapalı kaldığında sınırsız geçmiş kayıt planlamasın.
- Event payload’ını mevcut deterministic serializer’dan geçirdik ki JSON key sırası ve geçersiz değer reddi observation omurgasıyla aynı olsun.
- “Şimdi ilgilen”i predicate ve tekilleştirilmiş seçim olarak yazdık ki `now` yanlışlıkla yeni status veya domain kategorisine dönüşmesin.

## 16. Bu görevde bilinçli olarak ne yapmadık?

```text
SQLite schema version değişikliği
migration
repository veya adapter
Unit of Work
application service
database ensure/backfill
web UI veya + Unutma ekranı
scheduler veya notification
backup/restore
export
gerçek kullanıcı data root’una yazma
```

Bu parçalar sonraki görevlerde domain API’lerini kullanacak. Task 2/5’in amacı önce davranışı bellekte, deterministic ve executable hale getirmekti.

## 17. Yeni terimler

- **Value Object:** Kimliğinden çok doğrulanmış değerleriyle anlam kazanan küçük nesne.
- **Frozen Dataclass:** Oluşturulduktan sonra alan atamasını engelleyen dataclass.
- **ZoneInfo:** IANA timezone adıyla tarih/saat dönüşümü yapan standart Python sınıfı.
- **tzdata:** Sistem timezone verisi yoksa `ZoneInfo` için veri sağlayan paket.
- **Predicate:** Bir kaydın koşula uyup uymadığını `True/False` döndüren fonksiyon.
- **Snapshot:** Kaynak daha sonra değişse de üretim anındaki değeri koruyan alan grubu.
- **Derived View:** Database’e yazılmayıp güncel alanlardan hesaplanan görünüm kategorisi.
