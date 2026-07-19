# Issue #173 Öğrenme Notu — Zaman Sözleşmesi ve Salt-Okunur Preflight

## Bu çalışmada ne yaptık?

CSE'nin farklı katmanlarında tekrar edilen UTC üretme, parse etme ve Istanbul'a
çevirme kodunu tek küçük modülde topladık. Sonra yalnız açıkça verilen test veya
geçici SQLite dosyasındaki timestamp kolonlarını sayan bir preflight yazdık.

Buradaki önemli ayrım şudur:

```text
preflight = riskleri gör
migration = veriyi değiştir
```

Issue #173 yalnız ilkini yapar. Gerçek kullanıcı verisi açılmadı ve hiçbir satır
yeniden yazılmadı.

## Üç temel zaman neden ayrı?

Bir saha gözlemini dün 14:00'te gördüğünü, bugün 09:00'da CSE'ye yazdığını ve
09:10'da açıklamasını düzelttiğini düşün:

```text
observed_at = dün 14:00       # sahadaki olay
created_at  = bugün 09:00     # CSE'ye ilk kalıcı giriş
updated_at  = bugün 09:10     # son başarılı değişiklik
```

Hepsini `created_at` kabul edersek timeline sahadaki gerçeği göstermez. Hepsini
`observed_at` kabul edersek kaydın sisteme ne zaman girdiğini ve ne zaman
değiştiğini kaybederiz.

## Timezone-aware ve naive nedir?

Timezone-aware bir `datetime`, UTC offset'ini bilir:

```python
from datetime import datetime, timedelta, timezone

istanbul = datetime(
    2026, 7, 17, 22, 15,
    tzinfo=timezone(timedelta(hours=3)),
)
```

Satır satır:

1. `datetime(...)` takvim tarihini ve duvar saatini oluşturur.
2. `timedelta(hours=3)` UTC'den üç saat ileriyi ifade eder.
3. `timezone(...)` bu offset'i timezone nesnesine dönüştürür.
4. `tzinfo=...` değeri timestamp'i aware yapar.

Naive örnekte `tzinfo` yoktur:

```python
naive = datetime(2026, 7, 17, 22, 15)
```

Bu değer Istanbul mu, UTC mi, başka bir yer mi söylemez. Sessizce UTC varsaymak
olayı üç saat kaydırabilir. Bu yüzden serializer naive değeri reddeder.

## Gerçek kod 1: deterministic UTC serialization

`app/time_contracts.py` içindeki çekirdek:

```python
def serialize_utc_timestamp(value, *, precision="seconds"):
    if value.tzinfo is None or value.utcoffset() is None:
        raise ValueError("timestamp must be timezone-aware")

    utc_value = value.astimezone(UTC)
    if precision == "seconds":
        utc_value = utc_value.replace(microsecond=0)
    return utc_value.isoformat(timespec=precision).replace("+00:00", "Z")
```

Satır satır:

1. Fonksiyon bir `datetime` ve açık precision politikası alır.
2. `tzinfo` veya `utcoffset()` yoksa anlamı belirsiz değer fail-closed olur.
3. `astimezone(UTC)` aware offset'i aynı anı koruyarak UTC'ye çevirir.
4. Seconds politikası microsecond kısmını deterministik biçimde kaldırır.
5. `isoformat(timespec=...)` biçimi açıkça seçer.
6. `+00:00` yerine `Z`, CSE storage wire biçimini üretir.

Gerçek test:

```python
value = datetime(2026, 7, 17, 19, 15, 0, 123456, tzinfo=timezone.utc)

assert serialize_utc_timestamp(value) == "2026-07-17T19:15:00Z"
assert serialize_utc_timestamp(
    value, precision="microseconds"
) == "2026-07-17T19:15:00.123456Z"
```

İlk assert yeni production write politikasını, ikinci assert explicit legacy
precision davranışını sabitler.

## Gerçek kod 2: fixed clock

Gerçek saate doğrudan bağlı test bazen saniye sınırında değişebilir. `utc_now`
bu yüzden clock dependency alır:

```python
fixed = datetime(
    2026, 7, 17, 22, 15,
    tzinfo=timezone(timedelta(hours=3)),
)

assert utc_now(clock=lambda: fixed) == "2026-07-17T19:15:00Z"
```

- `lambda: fixed` her çağrıda aynı anı döndürür.
- Helper timezone-aware `+03:00` değeri UTC'ye normalize eder.
- Test işletim sisteminin saati veya local timezone'undan etkilenmez.

## Future policy nasıl çalışır?

Aynı future değeri alan anlamına göre geçerli veya hatalı olabilir:

```python
validate_temporal_policy(
    "2026-07-18T08:00:00Z",
    role=TimestampRole.SCHEDULED_TIME,
    as_of_utc="2026-07-17T20:00:00Z",
)
```

Bu geçerlidir; yarınki deadline gelecekte olmalıdır. Aynı değer
`EVENT_TIME`, `PERSISTENT_ENTRY_TIME` veya `LAST_UPDATE_TIME` olsaydı preflight
blocker üretirdi. Çünkü henüz gerçekleşmemiş bir olayı gerçekleşmiş gerçek gibi
yorumlamak güvenli değildir.

## DST fold neden test edildi?

Istanbul güncel olarak sabit UTC+03 kullansa da ortak timezone helper'ı sabit
offset mantığına bağlanmamalıdır. Bazı IANA bölgelerinde saat geri alınırken
aynı duvar saati iki kez yaşanır:

```python
first = to_timezone("2026-11-01T05:30:00Z", "America/New_York")
second = to_timezone("2026-11-01T06:30:00Z", "America/New_York")

assert first.strftime("%H:%M") == second.strftime("%H:%M")
assert first.utcoffset() != second.utcoffset()
assert (first.fold, second.fold) == (0, 1)
```

İki sonuç da `01:30` görünür; fakat UTC offset ve `fold` farklıdır. UTC storage
iki olayı karıştırmadan saklar.

## Gerçek kod 3: read-only SQLite bağlantısı

Preflight database'i şöyle açar:

```python
path = Path(database_path).resolve(strict=True)
uri = f"{path.as_uri()}?mode=ro"
connection = sqlite3.connect(uri, uri=True)
connection.execute("PRAGMA query_only = ON")
```

Satır satır:

1. `resolve(strict=True)` çağıranın verdiği dosyanın gerçekten var olduğunu
   doğrular; otomatik data-root aramaz.
2. `as_uri()` Windows path'ini güvenli SQLite file URI'ına çevirir.
3. `mode=ro` bağlantıyı filesystem seviyesinde salt-okunur açar.
4. `uri=True`, SQLite'a string'in URI seçenekleri taşıdığını söyler.
5. `query_only`, bağlantı içindeki yanlışlıkla write denemesini ikinci kez
   engeller.

Migration runner, `CREATE`, `UPDATE`, `INSERT` veya `DELETE` çağrılmaz.

## Preflight sayacı nasıl üretiliyor?

Her allowlist timestamp kolonu tek başına seçilir. Business metni seçilmez:

```python
values = connection.execute(
    f'SELECT "{column}" AS value FROM "{table}"'
)

for row in values:
    value = row["value"]
    # Yalnız sınıflandır ve count artır; raw değeri report'a koyma.
```

Sınıflar:

| Sayaç | Anlam |
|---|---|
| `row_count` | Tablodaki satır sayısı |
| `null_count` | Bu kolonda değer olmayan satır |
| `parseable_count` | ISO parser'ın anlayabildiği değer |
| `canonical_utc_count` | CSE UTC seconds veya legacy six-microsecond biçimi |
| `noncanonical_utc_count` | UTC anını taşıyan fakat CSE `Z` wire biçimine uymayan değer |
| `invalid_count` | Parse edilemeyen değer |
| `naive_count` | Offset taşımayan tarih/saat |
| `non_utc_count` | Explicit fakat UTC olmayan offset |
| `microsecond_count` | Fractional second taşıyan değer |
| `future_count` | Sabit `as_of` anından sonraki aware değer |

Min/max yalnız parse edilebilen aware anlardan normalize UTC olarak üretilir.
Invalid raw değer, row ID ve diğer kolonlar report'a girmez.

## Test kodu neyi doğruluyor?

`tests/test_time_preflight.py` schema 2, 3 ve 4'ü yalnız `tmp_path` altında
oluşturur. Her sürüm için:

```python
before_bytes = database.read_bytes()
report = run_time_migration_preflight(
    database,
    as_of_utc=AS_OF,
    database_kind="test",
)
assert database.read_bytes() == before_bytes
```

- İlk satır database byte'larını snapshot alır.
- Preflight açık test path'i ve sabit `as_of` ile çalışır.
- Son assert tek byte değişmediğini kanıtlar.
- Directory entry listesi de karşılaştırılarak journal/WAL yan artifact'ı
  oluşmadığı doğrulanır.
- Ayrı risk fixture'ı naive, non-UTC, microsecond, invalid ve future değerleri
  sayar.
- Fixture'a hassas görünümlü metin konur; JSON report'ta bu metin ve database
  path'i bulunmadığı doğrulanır.

Mevcut `test_backup_restore.py`, schema 2/3 restore compatibility ile schema 4
round-trip'ı; `test_daily_export.py` UTC observation'ın Istanbul yerel tarihine
göre seçilmesini doğrulamaya devam eder. Böylece merkezi helper değişikliği
artifact formatlarını sessizce bozmaz.

## Teknik karar tablosu

| Karar | Seçim | Neden |
|---|---|---|
| Yeni write precision | Seconds | ADR-0002 biçimi ve deterministic sıralama |
| Eski microsecond okuma | Kabul + warning | Geriye uyumluluk; bu Issue rewrite yapmaz |
| Naive değer | Blocker | Timezone tahmini veri anlamını değiştirir |
| Non-UTC aware değer | Normalize helper var, preflight warning | Dönüşüm mümkün ama sessiz migration yasak |
| Istanbul sunumu | `ZoneInfo("Europe/Istanbul")` | Named timezone ve DST tarihçesi |
| Future schedule | Geçerli | Deadline/attention doğal olarak gelecekte olabilir |
| Future historical fact | Blocker | Olay/entry/update gerçekleşmiş gerçek olmalıdır |
| Preflight bağlantısı | `mode=ro` + `query_only` | Defense in depth salt-okunur garanti |
| Rapor içeriği | Count, mapping, min/max, safe finding | Hassas business content sızıntısını önler |
| Schema | 4 olarak kaldı | Bu görev migration değil readiness çalışmasıdır |

## Kod çalışma akışı

```text
Explicit temp/test database path + fixed as_of
-> path ve database_kind doğrulaması
-> SQLite mode=ro + query_only
-> schema_migrations üzerinden version okuma
-> schema 2/3/4 allowlist timestamp kolonlarını tek tek okuma
-> parse / naive / offset / precision / future sınıflandırması
-> role tabanlı warning ve blocker üretimi
-> raw değer içermeyen JSON-ready report
-> connection close
-> database byte ve directory değişmezlik testi
```

## Şunu şöyle yaptık ki...

Şunu şöyle yaptık ki, zaman dönüşümü tek yerde açık ve test edilebilir olsun;
naive değerler sessizce UTC sayılmasın; gelecekteki deadline ile gelecekte
görünen tarihsel olay aynı muameleye maruz kalmasın; migration öncesi riskler
görülebilsin ama bu inceleme hiçbir kullanıcı satırını değiştirmesin. Böylece
P1.02 ve sonraki migration işi, varsayıma değil sayılabilir ve veri-minimal
kanıta dayanabilecek.
