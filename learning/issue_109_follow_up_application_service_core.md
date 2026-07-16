# Issue 109 - FollowUpApplicationService Çekirdek Akışları

## 1. Amaç ve çözülen saha problemi

Bu adımda Saha Takibi'nin domain kayıtları ile SQLite repository'leri arasına ilk gerçek application-service katmanını koyduk.

Şantiye şefi açısından amaç şudur:

```text
“Bunu unutma” diye birkaç saniyede yakala
-> kaydı daha sonra bul
-> ayrıntılandır
-> ne zaman yeniden karşıma çıkacağını planla
-> gerekirse tekrar Unutma Kutusu'na al
-> kişisel veya proje bağlamını seç
-> bütün gerçek değişikliklerin geçmişini gör
```

Önceki adımlarda `FollowUpItem`, event vocabulary, SQLite tabloları ve repository'ler vardı. Fakat bir kullanıcı işleminin ana kaydı ve event geçmişini birlikte nasıl değiştireceğini koordine eden katman yoktu. `FollowUpApplicationService` bu boşluğu, terminal yaşam döngülerine veya routine/backfill kapsamına girmeden doldurur.

## 2. Command ve query değerleri neden ayrı?

Yeni application değerlerinin özeti:

```python
@dataclass(frozen=True, slots=True)
class CreateFollowUp:
    capture_text: str

@dataclass(frozen=True, slots=True)
class ScheduleFollowUp:
    next_attention_at: str
    target_status: FollowUpStatus

@dataclass(frozen=True, slots=True)
class FollowUpQuery:
    status: FollowUpStatus | None = None
    project_id: str | None = None
    personal_only: bool = False
    observation_id: str | None = None
    view: FollowUpView | None = None
    as_of_utc: str | None = None
```

Satır satır anlamı:

1. `@dataclass(...)` bu küçük değer sınıflarının constructor, karşılaştırma ve okunabilir gösterim davranışını Python'a ürettirir.
2. `frozen=True`, oluşturulmuş bir command veya query alanının sonradan sessizce değiştirilmesini engeller.
3. `slots=True`, alan kümesini sabitler ve yanlışlıkla yeni attribute eklenmesini önler.
4. `CreateFollowUp.capture_text`, hızlı yakalamada kullanıcıdan alınan tek iş içeriğidir.
5. `ScheduleFollowUp`, dikkat anı ile hedef status'u tek değer içinde taşır; böylece `active/waiting + NULL` gibi yarım planlama komutu kurulmaz.
6. `FollowUpQuery`, birden fazla filtrenin aynı kayıt listesi üzerinde compose edilmesini sağlar.
7. `view`, database'e yazılan status değildir. `overdue`, `today`, `upcoming` ve `now` sorgu anında hesaplanır.
8. `as_of_utc`, zamana bağlı test ve sorguların sistem saatine gizlice bağlanmasını engeller.

Bu sınıflar Flask formu, JSON request modeli veya web sayfası değildir. Application use-case girdisini açıkça adlandırır.

## 3. Boundary normalization nasıl çalışıyor?

Hızlı capture anlamı değiştirilmeden kararlılaştırılır:

```python
def __post_init__(self) -> None:
    object.__setattr__(
        self, "capture_text", normalize_capture_text(self.capture_text)
    )
```

Satır satır:

1. Frozen dataclass normal attribute assignment'a izin vermez.
2. `object.__setattr__`, yalnız constructor sonrası doğrulama aşamasında normalize edilmiş değeri güvenli biçimde yerleştirir.
3. `normalize_capture_text(...)`, baş/son whitespace'i kaldırır ve ardışık boşlukları teke indirir.
4. Harf, Türkçe karakter, noktalama veya kullanıcı anlamı değiştirilmez.

Update command için karar biraz farklıdır:

```python
object.__setattr__(self, "title", _normalize_title(self.title))

for field_name in (
    "description",
    "location",
    "related_person",
    "condition_text",
):
    object.__setattr__(
        self,
        field_name,
        _normalize_optional_text(getattr(self, field_name), field_name),
    )
```

- Başlık tek satırlı kısa kullanıcı alanıdır; baş/son ve ardışık whitespace tek boşluğa çevrilir.
- Optional metinler trim edilir.
- Optional metnin trim sonrası sonucu boşsa `None` olur.
- Açıklamadaki iç satır sonları değiştirilmez; yalnız dış boşluk temizlenir.
- `item_type`, `is_important` ve `deadline_at` da command kurulurken enum/bool/canonical UTC sözleşmesine göre doğrulanır.

Bunun no-op açısından önemi şudur: Kullanıcı yalnız `" A Blok "` yerine `"A Blok"` gönderdiğinde gereksiz yeni revision veya event oluşmaz.

## 4. Constructor ve dependency injection

Service constructor'ının çekirdeği:

```python
class FollowUpApplicationService:
    def __init__(
        self,
        database_path: str | Path,
        *,
        uow_factory: Callable[[], SQLiteUnitOfWork] | None = None,
        clock: Callable[[], str] = _utc_now,
        uuid_factory: Callable[[], str] = lambda: str(uuid4()),
        local_actor: str = "local-user",
    ) -> None:
        if not isinstance(local_actor, str) or not local_actor.strip():
            raise ValueError("local_actor must not be empty")
```

Satır satır:

1. `database_path`, varsayılan SQLite Unit of Work'un açacağı database'i gösterir.
2. `*` işaretinden sonraki parametreler keyword ile verilmelidir; yanlış sırada positional bağımlılık gönderme riski azalır.
3. `uow_factory`, testte rollback veya commit failure davranışını kontrollü bir UoW sınıfıyla denemeyi sağlar.
4. `clock`, gerçek sistem saati yerine testte sabit canonical UTC değerleri verebilir.
5. `uuid_factory`, kayıt ve event kimliklerini testte önceden bilinen sırayla verebilir.
6. Varsayılan UUID, `str(uuid4())` ile lowercase canonical biçimdedir.
7. `local_actor`, event geçmişindeki işlemi yapan tek yerel kullanıcı etiketidir; trim sonrası boş olamaz.

Service her clock ve UUID sonucunu ayrıca doğrular:

```python
def _now(self) -> str:
    value = self._clock()
    validate_utc_timestamp(value)
    return value

def _new_id(self) -> str:
    value = self._uuid_factory()
    validate_record_id(value)
    return value
```

Bu kontrol sayesinde test veya gelecekteki bir adapter bozuk `+00:00` timestamp ya da uppercase/non-canonical UUID üretirse veri repository'ye ulaşmadan reddedilir.

## 5. Hızlı create ve atomik event yazımı

Gerçek create akışı:

```python
occurred_at = self._now()
item = create_follow_up_item(
    follow_up_id=self._new_id(),
    capture_text=command.capture_text,
    created_at=occurred_at,
)
event = self._event(
    item,
    sequence=1,
    event_type=FollowUpEventType.CREATED,
    occurred_at=occurred_at,
    payload={"revision": item.revision, "status": item.status.value},
)

with self._uow_factory() as unit_of_work:
    unit_of_work.follow_ups.add(item)
    unit_of_work.follow_up_events.add(event)
    unit_of_work.commit()
```

Satır satır:

1. Saat yalnız bir defa okunur; aggregate ve created event aynı iş anını taşır.
2. Domain factory ilk kaydı `inbox`, projesiz, zamansız, önemsiz ve revision `1` üretir.
3. İlk event sequence her yeni aggregate için `1`dir.
4. Payload, mutation sonrası revision ve status'u taşır.
5. `with` bloğu `BEGIN IMMEDIATE` transaction açar.
6. Önce ana aggregate eklenir.
7. Sonra append-only event eklenir.
8. Tek `commit()` ikisini birlikte kalıcılaştırır.
9. Event insert veya commit hata verirse context manager transaction'ı rollback eder; yalnız aggregate kalmaz.

Bu, “kayıt var ama geçmişi yok” veya “event var ama kayıt yok” biçimindeki yarım durumu engeller.

## 6. Deterministic query composition

Service, repository portunu büyütmeden bütün sorguları aynı deterministic taban listesinde uygular:

```python
with self._uow_factory() as unit_of_work:
    items = tuple(unit_of_work.follow_ups.list_all())

if query.status is not None:
    items = tuple(item for item in items if item.status == query.status)
if query.project_id is not None:
    items = tuple(item for item in items if item.project_id == query.project_id)
if query.personal_only:
    items = tuple(item for item in items if item.project_id is None)
```

Burada önemli ayrıntılar:

- Repository `ORDER BY created_at, id` sonucunu verir.
- List comprehension mevcut sırayı değiştirmez.
- Birden fazla filtre aynı liste üzerinde art arda uygulanır; yani filtreler compose edilir.
- `project_id`, yalnız belirli projeye bağlı kayıtları seçer.
- `personal_only=True`, `project_id IS NULL` anlamındadır.
- Bu iki anlam çeliştiği için aynı query içinde birlikte kullanımları command boundary'sinde reddedilir.
- Observation filtresi exact canonical UUID eşleşmesidir.

Zaman görünümleri mevcut domain helper'larını tekrar kullanır:

```python
if query.view == FollowUpView.NOW:
    items = select_now_attention_items(items, query.as_of_utc)
elif query.view is not None:
    today_local = _istanbul_date(query.as_of_utc)
    expected_group = FollowUpViewGroup(query.view.value)
    items = tuple(
        item
        for item in items
        if classify_follow_up(item, today_local) == expected_group
    )
```

- `now` için yeni status veya kategori yazılmadı.
- “Şimdi ilgilen” mevcut overdue + zamanı gelmiş today + önemli inbox bileşimidir.
- `as_of_utc`, `ZoneInfo("Europe/Istanbul")` ile yerel güne çevrilir.
- Örneğin `2026-07-15T21:30:00Z`, İstanbul'da `2026-07-16 00:30` günüdür.
- Query hiçbir event, backfill veya mutation üretmez.

## 7. Optimistic revision ve gerçek no-op

Mutation'ların ortak sırası şöyledir:

```python
current = unit_of_work.follow_ups.get(follow_up_id)
self._require_current_revision(current, expected_revision)

if not changed_fields:
    return current

occurred_at = self._now()
updated = replace(
    current,
    **values,
    revision=current.revision + 1,
    updated_at=occurred_at,
)
```

Satır satır:

1. Her mutation önce database'deki güncel aggregate'i okur.
2. `expected_revision` güncel değilse `RevisionConflict` hemen yükselir.
3. Stale kontrolü no-op kontrolünden önce gelir. Eski ekran aynı değeri gönderse bile stale yazma sessizce başarılı sayılmaz.
4. Normalize edilmiş değerler güncel alanlarla karşılaştırılır.
5. Gerçek değişiklik yoksa mevcut immutable kayıt döner.
6. No-op sırasında clock veya event UUID bile tüketilmez.
7. Gerçek değişiklikte `replace(...)`, eski nesneyi mutate etmek yerine yeni revision nesnesi üretir.
8. Revision tam bir artar.
9. `updated_at`, enjekte edilmiş clock sonucudur.

Bu sıra concurrency hatalarını görünür, testleri deterministik ve event geçmişini anlamlı tutar.

## 8. Ayrıntı güncelleme allowlist'i

Service yalnız şu alanları command'dan alır:

```python
DETAIL_FIELDS = (
    "condition_text",
    "deadline_at",
    "description",
    "is_important",
    "item_type",
    "location",
    "related_person",
    "title",
)
```

Değişen alanlar bu allowlist üzerinden hesaplanır:

```python
changed_fields = sorted(
    field_name
    for field_name, value in values.items()
    if getattr(current, field_name) != value
)
```

- `sorted(...)`, payload sırasını alfabetik ve deterministik yapar.
- Dict anahtarları allowlist'ten geldiği için aynı alan iki kez bulunamaz.
- `capture_text` listede yoktur; ilk yakalama kanıtı değişmez.
- Status, project, observation, attention, outcome ve created timestamp command yüzeyinde bulunmaz.
- Event bütün entity snapshot'ını değil yalnız `revision` ve `changed_fields` bilgisini taşır.

## 9. Planlama ve Unutma Kutusu geçişi

Planlama command'ı yalnız `active` veya `waiting` hedefini kabul eder.

```python
event_type = (
    FollowUpEventType.SCHEDULED
    if current.status == FollowUpStatus.INBOX
    else FollowUpEventType.RESCHEDULED
)
```

- İlk `inbox -> active/waiting` geçişi `follow_up.scheduled` üretir.
- Zaten planlı kaydın status veya attention değişikliği `follow_up.rescheduled` üretir.
- Aynı status + aynı attention gerçek no-op'tur.
- Terminal kayıt planlanamaz; reopen sonraki ayrı görevdir.
- `deadline_at` schedule tarafından değiştirilmez.

Unutma Kutusu'na taşıma iki alanı birlikte değiştirir:

```python
updated = replace(
    current,
    status=FollowUpStatus.INBOX,
    next_attention_at=None,
    revision=current.revision + 1,
    updated_at=occurred_at,
)
```

- Yalnız `active` veya `waiting` kayıt uygulanabilir.
- Status `inbox` olurken `next_attention_at` aynı atomik mutation içinde temizlenir.
- Gerçek deadline korunur.
- Zaten `inbox + None` kayıt no-op döner.
- Event payload önceki status ve önceki attention değerini saklar.

## 10. Proje bağlantısı ve observation koruması

Proje değişiminde önce gerçek parent kayıt okunur:

```python
if project_id is not None:
    unit_of_work.projects.get(project_id)
```

Bu satır non-null canonical UUID'nin database'de gerçekten var olduğunu doğrular. Yoksa mevcut `RecordNotFound` hatası korunur.

Observation bağlı kayıt için kural:

```python
if current.observation_id is not None:
    if project_id != current.project_id:
        raise InvalidRecordError(
            "observation-linked follow-up project cannot change"
        )
    return current
```

- Aynı proje no-op'tur.
- Null proje reddedilir.
- Farklı proje reddedilir.
- Application kontrolünün yanında mevcut composite foreign key database'te son savunma olarak kalır.
- Observation bağlı olmayan kayıt proje ekleyebilir, değiştirebilir veya `None` ile kaldırabilir.
- Event payload'daki null değer deterministic JSON `null` olur.

## 11. Event sequence neden service içinde hesaplanıyor?

Sequence helper'ı:

```python
history = unit_of_work.follow_up_events.list_for_follow_up(follow_up_id)
return history[-1].sequence + 1 if history else 1
```

Bu iki satırın güvenli olmasının nedeni:

1. `SQLiteUnitOfWork.__enter__()` transaction'ı `BEGIN IMMEDIATE` ile açar.
2. History aynı connection ve aynı transaction içinden okunur.
3. Repository history'yi yalnız `ORDER BY sequence` ile verir.
4. Son kayıt varsa bir sonraki sayı `last + 1` olur.
5. History boşsa ilk sequence `1` olur.
6. Repository'ye `allocate_sequence`, update veya delete API'si eklenmez.
7. Duplicate sequence unique constraint'i son database savunmasıdır.

## 12. Test kodu neyi doğruluyor?

### 12.1 Create ve history testi

Gerçek testten özet:

```python
created = service.create_follow_up(
    CreateFollowUp("  Vinç   bakım belgesini ara  ")
)

assert created.capture_text == "Vinç bakım belgesini ara"
assert created.status == FollowUpStatus.INBOX
history = service.list_history(FOLLOW_UP_ID)
assert history[0].sequence == 1
assert history[0].payload == {"revision": 1, "status": "inbox"}
```

- İlk assertion boundary normalization'ı doğrular.
- İkinci assertion hızlı capture'ın planlanmadan inbox'ta başladığını doğrular.
- History assertion'ları aggregate ile created event'in birlikte kalıcı olduğunu kanıtlar.

### 12.2 İstanbul gün sınırı testi

```python
as_of = "2026-07-15T21:30:00Z"  # İstanbul: 2026-07-16 00:30

assert service.list_follow_ups(
    FollowUpQuery(view="now", as_of_utc=as_of)
) == (overdue, due_today, important_inbox)
```

Bu test:

- UTC gününe göre değil İstanbul yerel gününe göre sınıflandırmayı;
- overdue kaydı;
- bugün olup saati gelmiş kaydı;
- önemli inbox kaydını;
- normal inbox, ileri saat ve terminal kaydın dışarıda kalmasını

aynı senaryoda doğrular.

### 12.3 Exact changed_fields testi

```python
assert history[-1].payload == {
    "changed_fields": [
        "condition_text",
        "deadline_at",
        "description",
        "is_important",
        "item_type",
        "location",
        "related_person",
        "title",
    ],
    "revision": 2,
}
assert "capture_text" not in history[-1].payload["changed_fields"]
```

Bu test bütün allowlist alanlarının gerçekten güncellendiğini, listenin alfabetik olduğunu ve immutable capture kanıtının event'e değişen alan gibi yazılmadığını doğrular.

### 12.4 Rollback testi

```python
monkeypatch.setattr(
    SQLiteFollowUpEventRepository,
    "add",
    lambda *_: (_ for _ in ()).throw(InvalidRecordError("event failed")),
)

with pytest.raises(InvalidRecordError, match="event failed"):
    service.schedule(
        FOLLOW_UP_ID,
        before.revision,
        ScheduleFollowUp(NEXT_AT, FollowUpStatus.WAITING),
    )

assert service.get_follow_up(FOLLOW_UP_ID) == before
assert service.list_history(FOLLOW_UP_ID) == history_before
```

Satır satır:

1. `monkeypatch`, event repository `add` çağrısına kontrollü hata enjekte eder.
2. Service hatayı generic başarı sonucuna dönüştürmez; çağırana geri verir.
3. Schedule önce aggregate update yapmış olsa bile UoW context'i commit görmeden rollback olur.
4. Son iki assertion hem ana aggregate'in hem event geçmişinin işlem öncesiyle aynı kaldığını doğrular.
5. Aynı parametrik test update, schedule, move-to-inbox ve project mutation'larının dördünü de çalıştırır.

### 12.5 No-op ve stale ayrımı

Testler şu iki durumu ayrı tutar:

```text
Güncel revision + aynı normalize edilmiş değer
-> mevcut kayıt, event yok, revision yok

Eski revision + aynı veya farklı değer
-> RevisionConflict, kayıt/event değişmez
```

Bu ayrım, eski bir ekranın farkında olmadan yeni veriyi “zaten aynıydı” diyerek ezmesini engeller.

Focused suite `36 passed` sonucuyla create/read, query, update, schedule, inbox, project, validation, no-op, stale revision, event failure ve commit failure senaryolarını kapsadı. İlgili domain/persistence/UoW/observation testleriyle birlikte `169 passed` sonucu alındı. Full suite ve final publication kanıtı result dosyasında ayrıca kaydedilir.

## 13. Teknik karar tablosu

| Karar | Seçilen yaklaşım | Neden | Eklenmeyen alternatif |
| --- | --- | --- | --- |
| Use-case sınırı | Dar `FollowUpApplicationService` | UI ve persistence ayrımını korur | Generic service framework |
| Command/query | Frozen, slotted dataclass | Immutable ve test edilebilir girdi | Flask formunu service'e geçirmek |
| Saat/kimlik | Constructor injection | Deterministik test ve açık dış bağımlılık | Domain helper içinde sistem saati/UUID |
| Query | `list_all` + sıra koruyan service filtreleri | Küçük veri hacmi, port değişmezliği | Her kombinasyon için yeni repository API |
| Zaman görünümü | Mevcut domain helper'ları | Tek sınıflandırma kuralı | Application içinde ikinci tarih algoritması |
| Sequence | Aynı UoW history sonu + 1 | `BEGIN IMMEDIATE` ile atomik | Repository sequence allocator |
| Mutation | Immutable `replace(...)` + revision + 1 | Eski kaydı mutate etmez | In-place nesne değişikliği |
| No-op | Normalize edilmiş alan karşılaştırması | Gereksiz revision/event yok | Her çağrıda event yazmak |
| Hata | Mevcut açık exception türlerini korumak | Çağıran nedeni ayırt eder | Tek generic service error |
| Proje | Parent lookup + observation guard + mevcut FK | Application ve database savunması | Sessiz project değiştirme |
| Transaction | Aggregate update + event + tek commit | Yarım yazı bırakmaz | Ayrı transaction'lar |

## 14. Kodun çalışma akışı

Create:

```text
CreateFollowUp
-> capture_text normalize
-> canonical clock + UUID
-> create_follow_up_item
-> follow_up.created sequence 1
-> BEGIN IMMEDIATE
-> aggregate insert
-> event insert
-> commit
```

Gerçek mutation:

```text
Command
-> command validation/normalization
-> BEGIN IMMEDIATE
-> aggregate get
-> expected_revision karşılaştır
-> transition/cross-record kontrolü
-> normalize edilmiş no-op kontrolü
-> clock oku
-> immutable next revision oluştur
-> repository update
-> history oku, next sequence hesapla
-> event append
-> tek commit
```

Hata akışı:

```text
Herhangi bir update/event/commit hatası
-> exception yukarı çıkar
-> Unit of Work context exit
-> açık transaction rollback
-> aggregate ve history işlem öncesi durumda
```

Read/query:

```text
FollowUpQuery
-> immutable query validation
-> deterministic repository list_all
-> status/project/personal/observation filtrelerini sırayla uygula
-> gerekiyorsa İstanbul yerel günü belirle
-> mevcut domain view helper'ını uygula
-> tuple döndür
-> mutation/event/backfill yok
```

## 15. Yeni teknik terimler

- **Application Service:** Bir use-case'i domain ve persistence katmanları arasında koordine eden uygulama sınıfı.
- **Unit of Work:** Birden fazla repository yazısını tek transaction'da birlikte commit veya rollback eden sınır.
- **Dependency Injection:** Saat, UUID veya UoW oluşturma davranışını constructor üzerinden dışarıdan verme yaklaşımı.
- **Command:** Bir değişiklik use-case'inin doğrulanmış immutable girdisi.
- **Query:** Kayıt değiştirmeden hangi sonuç kümesinin istendiğini anlatan immutable değer.
- **No-op:** Çağrı geçerli olduğu hâlde normalize edilmiş sonuç mevcut kayıtla aynı olduğu için kalıcı değişiklik üretmeyen işlem.
- **Stale revision:** Çağıranın gördüğü revision'ın database'deki güncel revision'dan eski olması.
- **Atomicity:** İlgili bütün yazıların birlikte kalıcı olması veya hiçbirinin kalıcı olmaması özelliği.

Kalıcı terim olan Application Service, Unit of Work ve Dependency Injection tanımları `learning/GLOSSARY.md` dosyasına da eklendi.

## 16. Şunu şöyle yaptık ki...

Şunu şöyle yaptık ki, şantiye şefi `+ Unutma` ile yakaladığı konuyu birkaç saniyede kalıcılaştırırken kayıt ile olay geçmişi birbirinden kopmasın; daha sonra ayrıntı, plan ve proje bağlamını değiştirdiğinde her gerçek değişiklik tek revision ve tek anlamlı event olarak görülsün.

Şunu şöyle yaptık ki, aynı düğmeye tekrar basılması veya formun aynı normalize edilmiş değerleri göndermesi gereksiz revision/event üretmesin; fakat eski revision ile gelen bir ekran da sessizce başarılı sayılmasın.

Şunu şöyle yaptık ki, `overdue`, `today`, `upcoming` ve “Şimdi ilgilen” için ikinci bir tarih algoritması yazılmasın; domain'de test edilmiş `Europe/Istanbul` kuralları application query'sinde doğrudan yeniden kullanılsın.

Şunu şöyle yaptık ki, event ekleme veya commit başarısız olduğunda kullanıcıya yarım kayıt kalmasın; aggregate mutation ile event append aynı SQLite Unit of Work transaction'ında birlikte rollback olsun.

Şunu şöyle yaptık ki, bu dar görev gerçek saha değerini üretirken terminal yaşam döngülerini, observation dönüşümünü, routine/backfill'i, UI'yi, schema'yı, backup/export'u veya gerçek kullanıcı verisini erken ve kontrolsüz biçimde genişletmesin.
