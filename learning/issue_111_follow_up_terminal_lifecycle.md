# Issue 111 - Follow-up Bekleme ve Terminal Yaşam Döngüleri

## 1. Amaç ve saha karşılığı

Issue #109 bir takibi yakalama, ayrıntılandırma ve planlama çekirdeğini kurmuştu. Bu adım takip kaydının sahadaki doğal devamını ekledi:

```text
inbox / active
-> başka kişi veya koşulu bekle
-> sonucu kaydet ya da iptal et
-> gerekirse yeniden aç
```

Bu akış dört application-service method'uyla temsil edilir:

```python
mark_waiting(...)
complete(...)
cancel(...)
reopen(...)
```

Buradaki önemli ayrım şudur: `status`, kaydın şu anki yaşam döngüsü durumudur; `outcome_type` ise yalnız kapanmış kaydın nasıl sonuçlandığını anlatır.

## 2. Yeni immutable komutlar

Beklemeye alma girdisi tek bir değer nesnesinde toplanır:

```python
@dataclass(frozen=True, slots=True)
class MarkWaiting:
    next_attention_at: str
    related_person: str | None = None
    condition_text: str | None = None

    def __post_init__(self) -> None:
        validate_utc_timestamp(self.next_attention_at)
        for field_name in ("related_person", "condition_text"):
            object.__setattr__(
                self,
                field_name,
                _normalize_optional_text(getattr(self, field_name), field_name),
            )
```

Satır satır:

1. `@dataclass` constructor ve karşılaştırma gibi standart davranışları üretir.
2. `frozen=True`, komut oluşturulduktan sonra alanların değiştirilmesini engeller.
3. `slots=True`, yalnız tanımlı alanların bulunmasını sağlar.
4. `next_attention_at`, kayda ne zaman yeniden bakılacağını taşır.
5. `validate_utc_timestamp(...)`, değerin canonical UTC ve `Z` sonlu olmasını doğrular.
6. Döngü iki optional metin alanına aynı kuralı uygular.
7. `getattr(...)`, alanın o anki değerini alan adıyla okur.
8. `_normalize_optional_text(...)`, baş/son boşluğu siler ve tamamen boş metni `None` yapar.
9. Frozen dataclass içinde constructor sonrası güvenli yerleştirme için `object.__setattr__` kullanılır.

Tamamlama komutu sonucu ve notu birlikte taşır:

```python
@dataclass(frozen=True, slots=True)
class CompleteFollowUp:
    outcome_type: FollowUpOutcome
    outcome_note: str | None = None

    def __post_init__(self) -> None:
        outcome_type = _coerce_enum(
            self.outcome_type, FollowUpOutcome, "outcome_type"
        )
        allowed_outcomes = (
            FollowUpOutcome.COMPLETED,
            FollowUpOutcome.NOT_REQUIRED,
        )
        if outcome_type not in allowed_outcomes:
            allowed = tuple(outcome.value for outcome in allowed_outcomes)
            raise ValueError(f"outcome_type must be one of {allowed}")
```

Burada:

1. `_coerce_enum(...)`, string olarak gelen geçerli değeri de `FollowUpOutcome` üyesine çevirir.
2. İzinli küme yalnız `completed` ve `not_required` değerlerinden oluşur.
3. `converted_to_observation`, başka bir application use-case'ine aittir.
4. `cancelled`, `cancel(...)` method'unun açık anlamıdır; complete içinde kabul edilmez.
5. `outcome_note` da trim edilir ve boşsa `None` olur.

## 3. Beklemeye alma geçişi

Kararın kritik bölümü şöyledir:

```python
current = unit_of_work.follow_ups.get(follow_up_id)
self._require_current_revision(current, expected_revision)
if current.status == FollowUpStatus.WAITING:
    if (
        current.next_attention_at == command.next_attention_at
        and current.related_person == command.related_person
        and current.condition_text == command.condition_text
    ):
        return current
    raise InvalidRecordError(
        "waiting follow-up cannot start waiting again with different values"
    )
```

Satır satır:

1. Güncel aggregate aynı Unit of Work içinden okunur.
2. Beklenen revision güncel revision ile karşılaştırılır.
3. Bu stale kontrolü no-op kararından önce yapılır; eski ekran sessizce başarılı sayılmaz.
4. Kayıt zaten waiting ise üç komut alanı ayrı ayrı karşılaştırılır.
5. Üçü de aynıysa mevcut kayıt döner.
6. Bu dönüşten önce clock veya UUID çağrısı yapılmadığı için no-op hiçbir teknik değer tüketmez.
7. Üç değerden biri farklıysa ikinci bir “bekleme başladı” olayı yazmak yerine açık validation hatası üretilir.

Gerçek geçiş `inbox` veya `active` kayıtta şunları değiştirir:

```python
updated = replace(
    current,
    status=FollowUpStatus.WAITING,
    next_attention_at=command.next_attention_at,
    related_person=command.related_person,
    condition_text=command.condition_text,
    revision=current.revision + 1,
    updated_at=occurred_at,
)
```

`replace(...)`, frozen kaydı yerinde değiştirmez; mevcut alanlardan yeni bir `FollowUpItem` üretir. Listede olmayan `deadline_at`, `project_id`, `observation_id`, `capture_text`, title ve diğer ayrıntılar aynen korunur.

## 4. Complete ve cancel neden ayrı method?

Complete geçişi:

```python
updated = replace(
    current,
    status=FollowUpStatus.COMPLETED,
    outcome_type=command.outcome_type,
    outcome_note=command.outcome_note,
    completed_at=occurred_at,
    cancelled_at=None,
    next_attention_at=None,
    revision=current.revision + 1,
    updated_at=occurred_at,
)
```

Önemli satırlar:

1. `status`, terminal `completed` değerine geçer.
2. Sonuç türü command'daki iki izinli değerden biridir.
3. `completed_at` ve `updated_at` aynı clock değerini alır.
4. Ters terminal alanı `cancelled_at` açıkça temizlenir.
5. Terminal kaydın etkin attention taşımaması için `next_attention_at=None` yazılır.
6. `deadline_at` listede bulunmadığından silinmez; tarihsel iş hedefi korunur.

Cancel geçişi aynı transaction kalıbını kullanır fakat anlamını açıkça sabitler:

```python
updated = replace(
    current,
    status=FollowUpStatus.CANCELLED,
    outcome_type=FollowUpOutcome.CANCELLED,
    outcome_note=normalized_note,
    completed_at=None,
    cancelled_at=occurred_at,
    next_attention_at=None,
    revision=current.revision + 1,
    updated_at=occurred_at,
)
```

Bu ayrım yanlış birleşimleri engeller. Örneğin `status=completed` ile `outcome_type=cancelled` üretilemez.

## 5. Yeniden açma

Reopen hedef durumu attention değerinden türetir:

```python
target_status = (
    FollowUpStatus.ACTIVE
    if next_attention_at is not None
    else FollowUpStatus.INBOX
)
updated = replace(
    current,
    status=target_status,
    next_attention_at=next_attention_at,
    outcome_type=None,
    outcome_note=None,
    completed_at=None,
    cancelled_at=None,
    revision=current.revision + 1,
    updated_at=occurred_at,
)
```

Satır satır:

1. Dikkat anı varsa yeniden açılan iş planlıdır ve `active` olur.
2. Dikkat anı yoksa zamanlanmamış açık kayıt `inbox` olur.
3. Outcome türü ve notu ana kayıttan temizlenir.
4. İki terminal timestamp de temizlenir.
5. Önceki sonuç kaybolmaz; `follow_up.reopened` event payload'ındaki `previous_outcome_type` alanında kalır.
6. Deadline, capture ve bağlam alanları korunur.

## 6. Event ve transaction çalışma akışı

Her gerçek mutation aynı sırayı izler:

```text
canonical input validation
-> BEGIN IMMEDIATE Unit of Work
-> aggregate oku
-> stale revision kontrol et
-> status/geçiş veya no-op kararı ver
-> clock'tan occurred_at al
-> yeni revision aggregate üret ve update et
-> history son sequence + 1 hesapla
-> UUID üret ve event'i doğrula
-> append-only event insert et
-> tek commit
```

Bu sıralamanın iki güvenlik sonucu vardır:

- Event UUID doğrulaması, event insert'i veya commit başarısızsa context manager transaction'ı rollback eder. Ana kayıt terminal veya waiting durumda yarım kalmaz.
- Exact waiting no-op, clock/UUID üretiminden önce döndüğü için revision, `updated_at`, event ve enjekte edilen test değerleri değişmez.

Event payload'ları entity'nin tamamını kopyalamaz. Kararı açıklayacak minimum önce/sonra kanıtını taşır:

| İşlem | Önceki kanıt | Yeni kanıt |
| --- | --- | --- |
| `mark_waiting` | `from_status`, `previous_next_attention_at` | dikkat anı, kişi, koşul, revision |
| `complete` | `from_status`, `previous_next_attention_at` | outcome türü/notu, revision |
| `cancel` | `from_status`, `previous_next_attention_at` | cancelled outcome/not, revision |
| `reopen` | `from_status`, `previous_outcome_type` | status, nullable attention, revision |

## 7. Test kodu neyi doğruluyor?

Örnek complete testi şu kalıbı kullanır:

```python
completed = service.complete(
    FOLLOW_UP_ID,
    1,
    CompleteFollowUp(outcome, "  Kontrol edildi  "),
)

assert completed.status is FollowUpStatus.COMPLETED
assert completed.outcome_type is outcome
assert completed.outcome_note == "Kontrol edildi"
assert completed.completed_at == UPDATED_AT
assert completed.next_attention_at is None
assert completed.deadline_at == original.deadline_at
```

Testin satırları:

1. Enjekte edilmiş clock sayesinde kapanış zamanı deterministiktir.
2. Baş/son boşluklu notun normalize edildiği doğrulanır.
3. Status ile outcome birlikteliği doğrulanır.
4. Attention'ın kapatılırken temizlendiği doğrulanır.
5. Deadline'ın yanlışlıkla temizlenmediği doğrulanır.

Rollback matrisi dört işlemi üç hata noktasıyla çaprazlar:

```python
@pytest.mark.parametrize("operation", ["waiting", "complete", "cancel", "reopen"])
@pytest.mark.parametrize("failure", ["uuid", "event_insert", "commit"])
def test_lifecycle_failures_roll_back_aggregate_and_event(...):
    ...
    assert check.get_follow_up(FOLLOW_UP_ID) == original
    assert check.list_history(FOLLOW_UP_ID) == ()
```

Bu 12 senaryo yalnız exception beklemekle kalmaz; işlem sonrası aggregate'in birebir eski kayıt olduğunu ve history'ye event eklenmediğini de denetler.

Focused suite ayrıca şunları kapsar:

- inbox/active kaynaklarından waiting;
- nullable waiting kişi ve koşulu;
- exact waiting no-op, farklı waiting reddi ve stale önceliği;
- üç açık status × iki izinli complete outcome;
- üç açık statustan cancel;
- iki terminal status × attention var/yok reopen;
- terminalde complete/cancel/mark_waiting reddi;
- açık durumda reopen reddi;
- event sequence'in create→waiting→complete→reopen→cancel boyunca `1..5` ilerlemesi.

## 8. Teknik karar tablosu

| Karar | Uygulama | Neden | Sonuç |
| --- | --- | --- | --- |
| Waiting bağlamını tek komutta taşı | `MarkWaiting` | Dikkat, kişi ve koşulu yarım yazmamak | Tek doğrulanmış giriş |
| Completion outcome'u sınırla | `completed/not_required` | Cancel ve observation dönüşüm anlamlarını ayırmak | Geçersiz terminal birleşimi yok |
| Stale'i no-op'tan önce kontrol et | `_require_current_revision` önce | Eski ekranı sessiz başarı saymamak | Çakışma görünür kalır |
| Terminalde attention temizle | `next_attention_at=None` | Kapalı işi aktif dikkat listesine sokmamak | Görünüm tutarlılığı |
| Deadline'ı koru | `replace` listesine alma | İş hedefinin tarihsel kanıtını kaybetmemek | Kapanış sonrası bağlam korunur |
| Reopen hedefini attention'dan türet | None→inbox, timestamp→active | `active + NULL` üretmemek | Domain/database değişmezi korunur |
| Yeni repository primitive ekleme | Mevcut update/history/add | Dar application kapsamı | Schema ve portlar sabit |
| Hataları transaction'a bırak | Tek UoW commit | Yarım terminal kayıt engellemek | Aggregate ve event atomik |

## 9. Şunu şöyle yaptık ki...

- Şunu şöyle yaptık ki waiting komutundaki kişi veya koşul boş bırakılabilsin, ama boş string ile `None` iki farklı anlam gibi saklanmasın: optional metni trim edip boş sonucu `None` yaptık.
- Şunu şöyle yaptık ki eski bir ekran aynı waiting değerlerini gönderdiğinde çakışmayı gizlemesin: revision kontrolünü exact no-op kontrolünden önce yaptık.
- Şunu şöyle yaptık ki tamamlanan veya iptal edilen kayıt dikkat listesinde kalmasın: terminal geçişlerde `next_attention_at` alanını açıkça temizledik.
- Şunu şöyle yaptık ki işin son tarihi kapanıştan sonra da tarihsel bağlam olarak görülebilsin: `deadline_at` alanını bütün dört geçişte koruduk.
- Şunu şöyle yaptık ki yeniden açılan zamanlanmamış kayıt domain kuralını bozmasın: attention yoksa inbox, varsa active seçtik.
- Şunu şöyle yaptık ki event üretimi bozulduğunda ana kayıt yarım değişmesin: aggregate update, event insert ve commit'i aynı mevcut Unit of Work içinde tuttuk.

## 10. Bu adımda özellikle yapılmayanlar

- Follow-up'ı observation'a bağlama veya observation'a dönüştürme uygulanmadı.
- Routine application service ve yedi günlük lazy backfill uygulanmadı.
- Domain entity, SQLite schema v4, migration, mapper, repository portu ve Unit of Work API'si değiştirilmedi.
- Web/UI, requirements, backup/export ve gerçek kullanıcı data root'u değiştirilmedi.

Bu dar sınır, Issue #111'in yalnız waiting ve terminal yaşam döngüsünü güvenli biçimde tamamlamasını sağlar.
