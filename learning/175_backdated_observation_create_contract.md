# Issue #175 Öğrenme Notu — Olay Zamanı ile Giriş Zamanını Ayırmak

## Amaç

Bu adımda Python'da immutable bir command nesnesinin application service'e
nasıl verildiğini, tek clock okumasının neden önemli olduğunu ve validation'ın
dosya/database yan etkilerinden önce nasıl fail-closed çalıştırıldığını
öğreniyoruz.

Saha problemi şudur: Sabah 08:00'de görülen bir kalıp problemi saat 14:00'te
CSE'ye yazılabilir. İki zaman da gerçektir ama aynı anlama gelmez:

- `observed_at = 08:00`: olay sahada ne zaman yaşandı?
- `created_at = 14:00`: kayıt CSE'ye ne zaman girdi?

Bu ayrım kaybolursa geriye dönük kayıt Ajanda'da yanlış sıraya yerleşir ve
audit izi, kullanıcının olayı ne zaman kaydettiğini gösteremez.

## Gerçek kod 1: immutable command nesnesi

`app/application/observations.py` içindeki command:

```python
@dataclass(frozen=True, slots=True)
class CreateObservation:
    project_id: str
    location: str
    category: str
    description: str
    notes: str | None = None
    upload: UploadStream | None = None
    observed_at: str | None = None
```

Satır satır:

1. `@dataclass`, constructor ve alan erişimi gibi tekrar eden Python kodunu
   üretir.
2. `frozen=True`, nesne oluşturulduktan sonra alanların değiştirilmesini
   engeller.
3. `slots=True`, command'ın yalnız tanımlı alanları taşımasını sağlar.
4. İlk dört alan create işleminin zorunlu saha girdileridir.
5. `notes` ve `upload` opsiyoneldir; eski kullanıcı akışını korur.
6. `observed_at` opsiyoneldir; eski çağrılar bu alanı vermek zorunda değildir.

Command neden ayrı nesnedir? Altı-yedi positional parametre kullanıldığında
hangi string'in hangi anlama geldiğini çağrı noktasında görmek zordur. Named
alan taşıyan command hem okunur hem de tek yerde doğrulanabilir olur:

```python
command = CreateObservation(
    project_id=project_id,
    location="A Blok",
    category="quality",
    description="Kalıp kontrolü",
    observed_at="2026-07-12T07:15:00Z",
)
```

## Gerçek kod 2: yeni write için strict timestamp

```python
def _validate_canonical_utc_seconds(value: object, field_name: str) -> str:
    if not isinstance(value, str):
        raise ValueError(f"{field_name} must be a string")
    try:
        parsed = parse_utc_timestamp(value)
    except ValueError as exc:
        raise ValueError(f"{field_name}: {exc}") from exc
    if serialize_utc_timestamp(parsed) != value:
        raise ValueError(f"{field_name} must use canonical UTC seconds")
    return value
```

Satır satır:

1. Önce değer gerçekten `str` mi kontrol edilir.
2. Merkezi parser yalnız `Z` ile biten canonical UTC metnini parse eder.
3. Parser hatası alan adı eklenerek yeniden yükseltilir.
4. Parse edilen değer seconds precision ile tekrar serialize edilir.
5. Yeniden üretilen metin girdiye eşit değilse yeni write reddedilir.
6. Başarılı durumda orijinal canonical string geri döner.

Issue #173 eski altı basamaklı microsecond timestamp'leri okuyabilmek için
read compatibility sağlar. Fakat eski değeri okuyabilmek, yeni command'ın aynı
legacy precision ile yazmasına izin vermek demek değildir. Bu nedenle
`2026-07-13T09:00:00.000001Z` yeni create girdisinde reddedilir.

## Gerçek kod 3: tek clock ve future policy

```python
created_at = self._now()
observed_at = command.observed_at or created_at
validate_temporal_policy(
    observed_at,
    role=TimestampRole.EVENT_TIME,
    as_of_utc=created_at,
)
```

Satır satır:

1. Service clock yalnız bir kez okunur ve `created_at` snapshot'ı oluşur.
2. Kullanıcı olay zamanı vermediyse `observed_at` aynı snapshot olur.
3. Kullanıcı explicit değer verdiyse bu geçmiş olay zamanı korunur.
4. `TimestampRole.EVENT_TIME`, gelecekte henüz yaşanmamış bir olayı tarihsel
   gerçek gibi yazmayı reddeder.
5. Karşılaştırmanın `as_of` değeri aynı create giriş zamanıdır.

Clock iki kez okunsaydı şu tür anlamsız ayrımlar oluşabilirdi:

```text
created_at = 09:00:00
updated_at = 09:00:01
event.occurred_at = 09:00:02
```

İlk create revision'ında bu üç alan aynı application işlemini anlatır. Tek
snapshot kullanmak davranışı deterministik yapar.

## Gerçek kod 4: record, event ve attachment eşlemesi

```python
observation = FieldObservationRecord(
    observed_at=observed_at,
    created_at=created_at,
    updated_at=created_at,
    # diğer alanlar
)

event_payload = {
    "attachment_ids": attachment_ids,
    "created_at": created_at,
    "observed_at": observed_at,
    "revision": observation.revision,
    "status": observation.status,
}
```

- Record `observed_at`, Ajanda sıralamasının gelecekteki ana zamanını taşır.
- Record `created_at`, kalıcı giriş zamanıdır.
- İlk `updated_at`, aynı revision'ın create snapshot'ıdır.
- Event'in kendi `occurred_at` değeri de `created_at` olur.
- Payload iki zamanı birlikte taşıdığı için fark geriye izlenebilir kalır.
- Attachment metadata `created_at`, fotoğrafın sahada çekildiği zaman iddiası
  değildir; dosya metadata'sının CSE'ye giriş zamanıdır.

## Validation neden staging'den önce?

Attachment staging gerçek bir dosya yazar. Future veya bozuk olay zamanı daha
sonra reddedilirse gereksiz cleanup gerekir ve hata anında stale dosya riski
artar. Akış bu yüzden şöyledir:

```text
command alan doğrulaması
-> clock doğrulaması
-> event-time future policy
-> UUID
-> attachment staging
-> Unit of Work transaction
-> finalize
-> commit
```

İlk üç aşamada hata olursa filesystem ve SQLite mutation başlamamıştır.

## Test kodu 1: clock gerçekten bir kez mi okunuyor?

```python
clock_calls = 0

def clock() -> str:
    nonlocal clock_calls
    clock_calls += 1
    if clock_calls > 1:
        raise AssertionError("create clock was read more than once")
    return "2026-07-13T09:30:00Z"
```

- Sayaç test fonksiyonunun dış scope'unda tutulur.
- `nonlocal`, iç fonksiyonun aynı sayacı artırmasını sağlar.
- İkinci okuma olursa test hemen başarısız olur.
- Sabit UTC değer, testin gerçek sistem saatine bağlı kalmasını engeller.

Test sonunda şu ilişki doğrulanır:

```python
assert observation.created_at == observation.updated_at
assert observation.created_at == observation.observed_at
assert detail.events[0].occurred_at == observation.created_at
```

Bu test omitted `observed_at` davranışını kanıtlar.

## Test kodu 2: invalid future command yan etki üretmiyor mu?

```python
def forbidden(*_args: object, **_kwargs: object) -> object:
    raise AssertionError("mutation boundary must not be reached")

monkeypatch.setattr(store, "stage_stream", forbidden)

service = ObservationApplicationService(
    database_path,
    store,
    uow_factory=forbidden,
    clock=lambda: "2026-07-13T09:00:00Z",
    uuid_factory=forbidden,
)
```

Bu testte UUID, staging veya Unit of Work sınırına gelinirse `forbidden`
bilerek test hatası üretir. Future `observed_at` için beklenen hata
`ValueError` olduğundan testin geçmesi validation'ın bütün mutation
sınırlarından önce tamamlandığını gösterir. Ayrıca database dosyasının hiç
oluşmadığı ve staging klasöründe stale dosya kalmadığı kontrol edilir.

## Test kodu 3: restart neden önemli?

Test create işleminden sonra yeni bir `ObservationApplicationService` nesnesi
oluşturur:

```python
reopened = ObservationApplicationService(
    tmp_path / "cse.sqlite3",
    ManagedAttachmentStore(tmp_path / "attachments"),
)
detail = reopened.get_observation_detail(observation_id)
```

Bu, ilk Python nesnesinin belleğindeki değerleri değil SQLite'tan yeniden
okunan record/event/attachment değerlerini sınar. Böylece geriye dönük zamanın
yalnız dönüş değerinde değil kalıcı storage içinde korunduğu kanıtlanır.

## Teknik karar tablosu

| Karar | Seçim | Neden |
|---|---|---|
| Create girdisi | Frozen command object | Alan anlamı açık, immutable ve tek yerde doğrulanabilir |
| Explicit olay zamanı | Optional canonical UTC seconds | Eski çağrı uyumu ve yeni geriye dönük kayıt birlikte korunur |
| Omitted olay zamanı | Tek clock snapshot'ı | Mevcut kullanıcı davranışı değişmez |
| Future policy | `TimestampRole.EVENT_TIME` | Henüz yaşanmamış olay tarihsel gerçek yazılmaz |
| Event `occurred_at` | Entry time | Event create mutation'ın ne zaman olduğunu gösterir |
| Event payload | Hem `observed_at` hem `created_at` | Ajanda ve audit tüketicileri anlamı kaybetmez |
| Attachment zamanı | Entry time | Metadata'nın CSE'ye girişini gösterir |
| Validation sırası | Staging ve UoW'dan önce | Invalid command yan etki üretmez |
| Schema | 4 olarak kaldı | Gerekli kolonlar zaten var |
| Web formu | Değişmedi | P1.03 ayrı dikey görevdir |

## Kod çalışma akışı

```text
Web / acceptance / CLI
-> CreateObservation(..., observed_at=None)
-> command structural validation
-> ObservationApplicationService.create_observation
-> one canonical clock read
-> observed_at fallback veya explicit past value
-> EVENT_TIME future validation
-> optional attachment staging
-> observation + attachment metadata + created event
-> attachment finalize
-> SQLite commit
-> restart sonrası aynı iki zamanın geri okunması
```

Explicit backdated application çağrısı yalnız command içindeki
`observed_at` değerini farklı verir. Yeni web alanı bu adımda yoktur.

## Yeni terimler

- **Command Object:** Bir kullanım senaryosunun girdilerini tek nesnede taşıyan
  değer nesnesi.
- **Event Time:** Olayın gerçekten yaşandığı an.
- **Entry Time:** Kaydın sisteme kalıcı giriş anı.
- **Single Clock Read:** Bir işlemde tek zaman snapshot'ı üretme yaklaşımı.

Kalıcı tanımlar `learning/GLOSSARY.md` dosyasına da eklendi.

## Bilinçli olarak eklenmeyenler

- Web formunda tarih/saat alanı
- Ajanda görünümü veya timeline projection
- Schema migration ve row rewrite
- Repository API değişikliği
- Archive/unarchive, scope veya MemoryIndex
- Backup/Günlük Çıktı format değişikliği
- Mobile/offline/notification/security davranışı
- Gerçek kullanıcı data root'u üzerinde çalışma

## Şunu şöyle yaptık ki...

Şunu şöyle yaptık ki, şantiye şefi geçmişte yaşanmış bir olayı sonradan
kaydettiğinde olayın gerçek zamanı kaybolmasın; buna karşılık CSE'ye giriş,
audit event'i ve attachment metadata'sı yanlışlıkla geçmişe taşınmasın. Tek
clock snapshot'ı kullandık ki aynı create işleminin teknik zamanları birbirinden
sapmasın. Temporal validation'ı staging ve database'den önce çalıştırdık ki
geçersiz command hiçbir dosya veya kalıcı kayıt yan etkisi üretmesin. Web
formunu bu adımda büyütmedik ki application contract ayrı ve test edilebilir
kalsın; kullanıcı yüzeyi sonraki açık Issue'da güvenle eklenebilsin.
