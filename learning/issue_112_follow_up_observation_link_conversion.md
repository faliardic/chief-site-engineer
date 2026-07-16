# Issue 112 - Follow-up Observation Bağlantısı ve Resmî Gözleme Dönüşüm

## 1. Amaç ve kişisel/resmî sınır

Bu adım iki benzer görünen fakat ürün anlamı farklı işlemi ayırdı:

```text
link_observation
    = kişisel takip ile mevcut resmî gözlem arasında ilişki kur
    = takip yaşam döngüsünü değiştirme

convert_to_observation
    = kullanıcı açıkça dönüşüm istedi
    = takibi converted_to_observation sonucu ile kapat
```

Yalnız bir observation kimliği bağlamak follow-up'ı resmî kayıt yapmaz. Resmî observation zaten `field_observations` tablosunda bulunur; bu görev yeni observation oluşturmaz ve follow-up metnini observation alanlarına kopyalamaz.

## 2. Link işleminin kodu nasıl çalışıyor?

Method'un ilk sınırı girdileri ve optimistic revision'ı doğrular:

```python
def link_observation(
    self,
    follow_up_id: str,
    expected_revision: int,
    observation_id: str,
) -> FollowUpItem:
    validate_record_id(follow_up_id)
    _validate_expected_revision(expected_revision)
    validate_record_id(observation_id)
    with self._uow_factory() as unit_of_work:
        current = unit_of_work.follow_ups.get(follow_up_id)
        self._require_current_revision(current, expected_revision)
        observation = unit_of_work.observations.get(observation_id)
```

Satır satır:

1. `follow_up_id` canonical UUID olmalıdır.
2. `expected_revision`, bool olmayan ve 1'den küçük olmayan integer olmalıdır.
3. `observation_id` de canonical UUID olarak doğrulanır.
4. `with` bloğu tek `SQLiteUnitOfWork` ve tek `BEGIN IMMEDIATE` transaction açar.
5. Follow-up güncel haliyle aynı transaction içinde okunur.
6. Stale revision, no-op veya ilişki kararından önce reddedilir.
7. Observation aynı Unit of Work repository'sinden okunur; yoksa mevcut `RecordNotFound` yükselir.

Project ve observation çapraz değişmezi ortak helper ile korunur:

```python
@staticmethod
def _require_observation_target(
    item: FollowUpItem,
    observation_id: str,
    observation_project_id: str,
) -> None:
    if (
        item.observation_id is not None
        and item.observation_id != observation_id
    ):
        raise InvalidRecordError(
            "follow-up is already linked to a different observation"
        )
    if (
        item.project_id is not None
        and item.project_id != observation_project_id
    ):
        raise InvalidRecordError(
            "follow-up project must match observation project"
        )
```

Burada iki sessiz veri değişikliği engellenir:

1. Follow-up başka observation'a bağlıysa yeni kimlik eski ilişkiyi değiştiremez.
2. Follow-up başka projeye bağlıysa observation projesine sessizce taşınamaz.
3. Follow-up projesizse ikinci koşul çalışmaz; observation project'i adoption için kullanılabilir.
4. Follow-up aynı projedeyse ilişki kurulabilir.

Exact no-op ve gerçek update bölümü:

```python
if current.observation_id == observation.observation_id:
    return current

occurred_at = self._now()
updated = replace(
    current,
    observation_id=observation.observation_id,
    project_id=observation.project_id,
    revision=current.revision + 1,
    updated_at=occurred_at,
)
```

Satır satır:

1. Helper project eşleşmesini doğruladıktan sonra aynı observation ilişkisi no-op döner.
2. No-op, `_now()` ve `_new_id()` çağrılarından önce olduğu için clock veya UUID tüketmez.
3. Gerçek mutation zamanı enjekte edilen clock'tan alınır.
4. `replace(...)`, frozen aggregate'in yeni revision kopyasını üretir.
5. Observation kimliği ve onun source-of-truth project kimliği birlikte yazılır.
6. Listelenmeyen status, outcome, attention, deadline, capture ve ayrıntı alanları aynen korunur.

## 3. Link event'i neyi kanıtlıyor?

```python
payload={
    "from_project_id": current.project_id,
    "observation_id": stored.observation_id,
    "project_id": stored.project_id,
    "revision": stored.revision,
    "status": stored.status.value,
}
```

Payload bütün entity snapshot'ı değildir. Şunları kanıtlar:

- link öncesi kayıt kişisel miydi veya zaten hangi projedeydi;
- hangi mevcut observation bağlandı;
- observation kaynaklı proje hangisidir;
- lifecycle status'un link sırasında değişmediği;
- mutation sonrası revision.

Nullable `from_project_id`, deterministic JSON içinde `null` kalır.

## 4. Conversion neden ayrı bir method?

Conversion, ilişki kurmanın yanında açık lifecycle kapanışıdır:

```python
updated = replace(
    current,
    status=FollowUpStatus.COMPLETED,
    outcome_type=FollowUpOutcome.CONVERTED_TO_OBSERVATION,
    outcome_note=None,
    completed_at=occurred_at,
    cancelled_at=None,
    next_attention_at=None,
    observation_id=observation.observation_id,
    project_id=observation.project_id,
    revision=current.revision + 1,
    updated_at=occurred_at,
)
```

Satır satır:

1. Açık follow-up terminal `completed` durumuna geçer.
2. Outcome yalnız bu use-case'e ait `converted_to_observation` olur.
3. Bu dönüşümde ayrıca insan notu alınmadığı için `outcome_note=None` yazılır.
4. `completed_at` ve `updated_at` aynı canonical UTC clock değerini alır.
5. Ters terminal alan `cancelled_at` temiz tutulur.
6. Kapanan takip aktif dikkat listesinde kalmasın diye `next_attention_at=None` olur.
7. Observation ve onun project'i aynı mutation içinde bağlanır.
8. Deadline, capture, title, description, tür, konum, kişi, önem ve koşul listede olmadığı için korunur.

Yalnız açık durumlar kabul edilir:

```python
if current.status not in OPEN_STATUSES:
    raise InvalidRecordError(
        "only open follow-up can convert to observation"
    )
```

Bu kural, daha önce `completed`, `not_required` veya `cancelled` sonucu verilmiş kaydın conversion ile geçmişinin yeniden yazılmasını engeller.

## 5. Exact converted retry

Ağ veya kullanıcı tekrar tıklaması aynı isteği yeniden gönderebilir. Service, kendi ürettiği exact terminal sonucu tanır:

```python
if (
    current.status == FollowUpStatus.COMPLETED
    and current.outcome_type
    == FollowUpOutcome.CONVERTED_TO_OBSERVATION
    and current.outcome_note is None
    and current.observation_id == observation.observation_id
    and current.project_id == observation.project_id
    and current.next_attention_at is None
):
    return current
```

Kontrolün anlamı:

1. Kayıt completed olmalıdır.
2. Sonuç gerçekten observation conversion olmalıdır.
3. Hedef observation ve project aynı olmalıdır.
4. Conversion hedefindeki note/attention temizliği korunmuş olmalıdır.
5. Revision kontrolü bu bloktan önce çalıştığı için stale retry sessiz başarı değildir.
6. Exact retry yeni revision, event, clock veya UUID tüketmez.

## 6. Neden conversion sırasında ikinci link event'i yok?

Conversion tek kullanıcı niyetidir:

```text
“Bu kişisel takibi şu mevcut resmî gözleme dönüştür.”
```

Bu tek işlem için hem `observation_linked` hem `converted_to_observation` yazmak, kullanıcı bir kez işlem yaptığı halde iki ayrı iş iddiası üretirdi. Bu nedenle conversion:

```text
aggregate observation/project ilişkisini kurar
-> terminal conversion alanlarını yazar
-> yalnız follow_up.converted_to_observation event'i ekler
```

Observation daha önce link edilmişse de conversion event'i tek başına yeterlidir.

## 7. Transaction ve hata akışı

İki method da aynı atomik akışı izler:

```text
ID validation
-> BEGIN IMMEDIATE Unit of Work
-> follow-up oku
-> stale revision kontrol et
-> observation oku
-> project/observation invariant kontrol et
-> no-op veya transition kararı
-> yeni aggregate revision üret
-> repository update
-> history son sequence + 1
-> event UUID üret ve event doğrula
-> append-only event insert
-> tek commit
```

UUID doğrulaması, event insert'i veya commit başarısızsa `with` bloğu transaction'ı rollback eder. Böylece project/observation link'i veya terminal conversion ana kayıtta yarım kalmaz.

## 8. Test kodu neyi doğruluyor?

Conversion'ın ayrıntı koruma testi gerçek bir aggregate kurar:

```python
converted = service.convert_to_observation(
    FOLLOW_UP_ID, 1, OBSERVATION_ID
)

assert converted.status is FollowUpStatus.COMPLETED
assert converted.outcome_type is FollowUpOutcome.CONVERTED_TO_OBSERVATION
assert converted.next_attention_at is None
assert converted.project_id == PROJECT_ID
assert converted.observation_id == OBSERVATION_ID
assert converted.deadline_at == NEXT_AT
assert converted.description == original.description
assert converted.location == original.location
```

Satırlar sırasıyla terminal sonucu, attention temizliğini, observation-project bağını ve kullanıcı ayrıntılarının kaybolmadığını doğrular.

Rollback testi iki işlem ile üç hata noktasını çaprazlar:

```python
@pytest.mark.parametrize("operation", ["link", "convert"])
@pytest.mark.parametrize("failure", ["uuid", "event_insert", "commit"])
def test_observation_operation_failures_roll_back_aggregate_and_event(...):
    ...
    assert check.get_follow_up(FOLLOW_UP_ID) == original
    assert check.list_history(FOLLOW_UP_ID) == ()
```

Bu altı senaryoda exception tek başına yeterli sayılmaz. Test, follow-up'ın birebir eski kayıt kaldığını, history'nin boş olduğunu ve observation'ın değişmediğini de denetler.

Focused matris ayrıca şunları kapsar:

- beş status için link ve lifecycle alanlarının korunması;
- null project adoption ile same project link;
- same observation exact link no-op;
- different project ve different existing observation reddi;
- missing follow-up/observation ve invalid UUID;
- stale revision'ın missing/no-op kararından önce gelmesi;
- inbox/active/waiting conversion;
- pre-linked same observation conversion;
- exact converted retry;
- completed başka outcome ve cancelled reddi;
- create→link→convert event sequence'i ve conversion'da ek linked event olmaması.

## 9. Teknik karar tablosu

| Karar | Uygulama | Neden | Sonuç |
| --- | --- | --- | --- |
| Observation project'i kaynak kabul et | `observation.project_id` | Çapraz kayıtta iki proje gerçeği üretmemek | Composite FK ile aynı anlam |
| Link ve conversion'ı ayır | İki service method'u | İlişki ile resmî kapanış aynı kullanıcı niyeti değil | Kişisel/resmî sınır görünür |
| Farklı mevcut observation'ı reddet | `InvalidRecordError` | Sessiz relationship replacement yapmamak | Veri geçmişi korunur |
| Same link'i no-op yap | Erken `return current` | Retry'da gereksiz event/revision üretmemek | Deterministik idempotent davranış |
| Conversion'da tek event | Yalnız converted event | Tek kullanıcı işlemine tek audit iddiası | History anlaşılır |
| Observation üretme | Yalnız repository `get` | Kullanıcı onayı ve resmî içerik sınırını korumak | Otomatik resmî kayıt yok |
| Repository portunu büyütme | Mevcut get/update/add/list | Dar application kapsamı | Schema/persistence sabit |
| Bütün yazıları tek UoW'ta tut | Update + event + commit | Yarım link veya terminal kayıt engellemek | Atomik rollback |

## 10. Şunu şöyle yaptık ki...

- Şunu şöyle yaptık ki kişisel takip yalnız proje veya observation bağı kazandığında otomatik resmîleşmesin: link method'unda lifecycle ve outcome alanlarını hiç değiştirmedik.
- Şunu şöyle yaptık ki observation ile follow-up iki farklı proje gerçeği taşımasın: observation project'ini source of truth kabul edip null projeyi atadık, farklı projeyi reddettik.
- Şunu şöyle yaptık ki mevcut observation ilişkisi sessizce başka kayda taşınmasın: farklı observation kimliğinde açık `InvalidRecordError` ürettik.
- Şunu şöyle yaptık ki kullanıcı bir kez conversion yaptığında iki audit olayı görünmesin: aggregate içinde link ve kapanışı birlikte yapıp yalnız converted event yazdık.
- Şunu şöyle yaptık ki tekrar gönderilen exact istek yeni geçmiş üretmesin: stale kontrolünden sonra no-op'u clock/UUID çağrılarından önce döndürdük.
- Şunu şöyle yaptık ki event veya commit hatasında ana kayıt yarım resmîleşmesin: aggregate update ve event insert'i aynı Unit of Work transaction'ında tuttuk.

## 11. Bu adımda özellikle yapılmayanlar

- Yeni observation oluşturulmadı.
- Follow-up metni observation alanlarına otomatik kopyalanmadı.
- `ObservationApplicationService`, observation UI veya web route değiştirilmedi.
- Schema v4, migration, mapper, repository ve Unit of Work portları değiştirilmedi.
- Routine application service, lazy backfill, mobile/offline/notification ve backup/export uygulanmadı.
- Gerçek kullanıcı data root'una erişilmedi.

Bu sınır, kullanıcı onaylı kişisel→resmî dönüşümü açık ve denetlenebilir tutar.
