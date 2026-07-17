# Issue 171 Öğrenme Notu: Faz Kapanışı Kanıtla Nasıl Yapılır?

## 1. Bu çalışmada ne öğrendik?

Bir geliştirme fazını kapatmak, checklist kutularını işaretlemek değildir. Üç
farklı gerçeğin aynı anda uyuştuğunu kanıtlamaktır:

```text
GitHub merged gerçeği
        +
repository içindeki çalışan kod/test gerçeği
        +
kanonik doküman ve state anlatımı
        =
kanıta dayalı closure
```

Issue #171 yeni production özelliği eklemedi. Faz 0'ın karar üretme amacının
tamamlandığını; uygulanmamış kararların ise uygulanmış gibi gösterilmediğini
doğruladı.

## 2. Yeni terimler

### Closure gate

Bir fazın kapanıp sonraki faza geçebilmesi için zorunlu kanıt kümesidir. Test
sonucu, merged commit, compatibility ve açık blocker durumu bu kapının
parçalarıdır.

### Source of truth

Bir bilgi için son sözü söyleyen kaynaktır. CSE'de kayıt içeriği için source
domain satırı ve append-only event geçmişi; değişken repository durumu için
GitHub `master` source of truth'tur.

### Drift

İki yüzeyin zamanla farklı gerçekleri anlatmasıdır. Örneğin kod schema 4 iken
bir protokolün hâlâ schema 3 demesi dokümantasyon drift'idir.

### Projection

Kaynak veriden yeniden üretilebilen okuma görünümüdür. Gelecekteki
`MemoryIndex`, source kayıt değildir; projection'dır.

### Preflight

Değişiklik uygulanmadan önce yapılan uygunluk ve risk kontrolüdür. Migration
preflight, eski satırların anlamını ve upgrade riskini gerçek veriyi değiştirmeden
inceler.

### Backward compatibility

Yeni sürümün desteklenen eski veri veya artifact'ları güvenle okuyabilmesidir.
CSE restore yolu schema 2 ve 3 Backup'larını temporary hedefte schema 4'e
taşıyabilir.

Bu terimler bu learning dosyasında tanımlandı. Issue #171 allowlist'i
`learning/GLOSSARY.md` dosyasını içermediği için glossary değiştirilmedi.

## 3. Repository gerçeğini koddan okuma

### 3.1 Schema sürümü

Current production kodu:

```python
SCHEMA_VERSION = 4


@dataclass(frozen=True)
class Migration:
    version: int
    statements: tuple[str, ...]
```

Satır satır:

1. `SCHEMA_VERSION = 4`, uygulamanın current SQLite şemasını bildirir.
2. `@dataclass(frozen=True)`, migration tanımının oluşturulduktan sonra
   değiştirilememesini sağlar.
3. `version`, migration sıra numarasıdır.
4. `statements`, aynı migration'a ait sıralı SQL komutlarını taşır.

Closure belgesi “schema 3” diyorsa test geçse bile doküman yanlıştır. Bu yüzden
repository truth doğrudan sabitten okunur.

### 3.2 Backup compatibility

Current production kodu:

```python
BACKUP_FORMAT_VERSION = 1
RESTORABLE_SCHEMA_VERSIONS = (2, 3, 4)
SHA256_PATTERN = re.compile(r"^[0-9a-f]{64}$")
```

Satır satır:

1. Backup artifact sözleşmesinin format sürümü `1`dir.
2. Restore yalnız schema 2, 3 veya 4 için açık allowlist kullanır.
3. SHA-256 metni tam 64 lowercase hexadecimal karakter olmalıdır.

Bu üç sayı aynı şeyi anlatmaz. Backup format sürümü ZIP/manifest sözleşmesini,
schema sürümü embedded SQLite yapısını anlatır.

Backup manifest'i de koddaki gerçek alanlardan okunur:

```python
manifest = {
    "backup_format_version": BACKUP_FORMAT_VERSION,
    "created_at": self._clock(),
    "schema_version": schema_version,
    "attachment_count": len(metadata),
    "observation_count": observation_count,
    "event_count": event_count,
    "files": files,
    "attachments": attachments_manifest,
}
```

Burada:

- format ile schema ayrı alanlardır;
- count'lar doğrulama kanıtıdır;
- `files` checksum/size inventory'sidir;
- `attachments` yönetilen attachment listesidir.

ADR-0003 yeni artifact aileleri tanımlasa da bu mevcut manifest'e sessiz alan
ekleme yetkisi vermez.

### 3.3 Günlük Çıktı formatı

```python
manifest = {
    "format_version": 1,
    "generated_at": self._clock(),
    "local_date": selected_date.isoformat(),
    "record_count": len(records),
    "warning_count": warning_count,
    "files": {name: digest_bytes(payloads[name]) for name in EXPORT_FILES},
}
```

Satır satır:

1. Tarihsel wire anahtarı `format_version` olarak kalır.
2. `generated_at` artifact üretim zamanıdır.
3. `local_date`, hangi Europe/Istanbul iş gününün seçildiğini taşır.
4. `record_count`, current v1'de observation sayısıdır.
5. `warning_count`, attachment doğrulama uyarılarını sayar.
6. `files`, her payload için digest üretir.

Closure sırasında bu alanlara bakarak “Günlük Çıktı” ile “Proje Paketi”nin aynı
artifact olmadığını kanıtlarız.

## 4. Çalışan web yüzeyini karar belgelerinden ayırma

Current app construction kodu:

```python
app.config.update(
    CSE_SERVICE=ObservationApplicationService(
        root / "cse.sqlite3",
        ManagedAttachmentStore(root / "attachments"),
    ),
    CSE_FOLLOW_UP_SERVICE=FollowUpApplicationService(
        root / "cse.sqlite3",
        clock=configured_now_utc,
        uuid_factory=lambda: str(app.config["CSE_FOLLOW_UP_ID_FACTORY"]()),
    ),
    CSE_ROUTINE_SERVICE=RoutineApplicationService(
        root / "cse.sqlite3",
        clock=configured_now_utc,
        uuid_factory=lambda: str(app.config["CSE_ROUTINE_ID_FACTORY"]()),
    ),
)
```

Bu blok bize şunları kanıtlar:

- observation service production'da bağlıdır;
- follow-up service production'da bağlıdır;
- routine service production'da bağlıdır;
- üçü de aynı explicit data root içindeki SQLite omurgasını kullanır;
- takip ve rutin kimlikleri factory üzerinden üretilir;
- zaman current configured UTC clock'tan gelir.

Buna karşılık bu blokta `MemoryIndex`, app lock, offline sync veya encryption
yoktur. ADR'de tanımlanmış olmaları bu kodda çalıştıkları anlamına gelmez.

## 5. Test kodu neyi doğruluyor?

### 5.1 Schema ve fiziksel silme sınırı

Repository'deki gerçek regresyon testi:

```python
def test_schema_version_and_forbidden_repository_apis_remain_unchanged() -> None:
    from app.persistence import SCHEMA_VERSION

    assert SCHEMA_VERSION == 4
    assert not hasattr(SQLiteRoutineOccurrenceRepository, "delete")
    assert not hasattr(SQLiteRoutineOccurrenceEventRepository, "update")
    assert not hasattr(SQLiteRoutineOccurrenceEventRepository, "delete")
    assert not hasattr(SQLiteRoutineOccurrenceEventRepository, "allocate_sequence")
```

Açıklama:

1. Test schema'nın beklenmedik biçimde ilerlemediğini kilitler.
2. Routine occurrence repository'de fiziksel `delete` API'si olmamasını
   doğrular.
3. Append-only event repository'de `update` ve `delete` olmamasını doğrular.
4. Sequence'ın repository tarafından gizlice üretilmediğini kontrol eder.

Bu test, legacy planındaki “fiziksel silme yok” kararını tek başına bütün repo
için kanıtlamaz; fakat current routine persistence sınırında executable
kanıttır.

### 5.2 Backup test fixture'ı

```python
BACKUP_MANIFEST_KEYS = {
    "backup_format_version",
    "created_at",
    "schema_version",
    "attachment_count",
    "observation_count",
    "event_count",
    "files",
    "attachments",
}
```

Bu exact set, ADR yazıldı diye manifest'e yeni alan eklenemeyeceğini test
yüzeyinde görünür yapar. Format değişecekse ayrı version ve reader gerekir.

### 5.3 Private tracking export izolasyonu

Daily export test fixture'ı özel bir sentinel kullanır:

```python
follow_up = follow_service.create_follow_up(
    CreateFollowUp("EXPORT-SIZINTI-TAKIP-METNI-117")
)
```

Test daha sonra export byte'larında bu sentinel'ın bulunmadığını doğrular. Bu
yöntem önemlidir: “private kayıt eklenmiyor” sadece yorumla değil, sızarsa kolay
yakalanacak benzersiz veriyle regression test edilir.

## 6. Closure matrisi nasıl okunur?

Issue #171 matrisi şu on alanı kullanır:

```text
requirement_id
source_of_truth
supporting_issue
supporting_pr
merged_commit
canonical_document
repository_evidence
status
open_gap
next_action
```

Örnek düşünme sırası:

```text
R03 MemoryIndex kararı
-> source truth: domain aggregate + event history
-> merged evidence: Issue #147 / PR #159 / merge commit
-> canonical doc: ADR-0002
-> repository check: MemoryIndex schema yok
-> status: karar PASS, implementation yok
-> next action: Issue #129 P1.10+
```

Burada “implementation yok”, Faz 0 failure değildir. Faz 0'ın işi karar
sözleşmesini tamamlamaktır. Ama doküman yanlışlıkla “MemoryIndex çalışıyor”
deseydi repository truth çelişkisi oluşur ve closure `FAIL` olurdu.

## 7. Teknik karar tablosu

| Karar | Neden | Reddedilen kısa yol | Kanıt |
|---|---|---|---|
| Closure sonucu `PASS` | Bütün Faz 0 kararları merged ve blocker yok | Açık future gap'i otomatik failure saymak | 12 satırlı closure matrisi |
| P0.10 açık kalır | Branch henüz merge edilmedi | Local commit'i merged saymak | GitHub Issue #128 checklist sınırı |
| P1.01 tek aday | Issue #129 bağımlılık sırasının ilk maddesi | Archive veya MemoryIndex'e atlamak | Issue #129 sıralı adımlar |
| ADR linkleri beş yüzeyde | Kararlar current kanonik kaynaklardan bulunabilir olmalı | Yalnız ADR klasörüne güvenmek | Exact path taraması |
| State current merge'i gösterir | `.cse/state` ikincil factual mirror'dır | #169 pre-push snapshot'ını current saymak | `master=3024ea45...` |
| Legacy silme yok | Zero-reference ve replacement kanıtı yok | Eski adı olan dosyayı silmek | Issue #165 inventory |
| Pilot tamamlandı denmez | Protokol yürütme değildir | Boş template'i saha kanıtı saymak | Issue #167 sınırı |
| Security uygulandı denmez | Threat model control implementation değildir | Loopback'i auth saymak | ADR-0004 current posture |

## 8. Kod ve karar çalışma akışı

```text
GitHub Issue/PR merge commitlerini oku
-> master SHA'yı doğrula
-> production sabitlerini ve route/service yüzeyini read-only incele
-> testlerin hangi davranışı kilitlediğini belirle
-> kanonik doküman anlatımıyla karşılaştır
-> drift'i yalnız yetkili doküman/state dosyalarında düzelt
-> full suite + compileall + JSON + diff kontrollerini çalıştır
-> protected path diff boşsa closure sonucunu doğrula
-> Issue #127/#128 olgusal hizalama
-> tek commit + normal push + completion evidence
```

Her okta bir fail-closed nokta vardır. Örneğin `master` SHA beklenenden
farklıysa edit başlamaz; protected path diff doluysa commit yapılmaz; test
failure varsa closure `PASS` kalamaz.

## 9. Faz 1 zaman sözleşmesi neden ilk aday?

Observation tablosu şu üç zamanı zaten ayırır:

```text
observed_at  -> olayın sahada gerçekleştiği zaman
created_at   -> kaydın sisteme girildiği zaman
updated_at   -> son değişiklik zamanı
```

Fakat kullanıcı geçmiş tarihli observation oluşturacaksa UI/application
contract, migration ve event payload bu anlamı aynı şekilde taşımalıdır.
Önce P1.01 sözleşmesi kurulmadan P1.02 create command veya P1.03 form yapılırsa
şu riskler doğar:

- eski kayıtların `observed_at` anlamı yanlış yorumlanır;
- local `datetime-local` değeri UTC'ye hatalı çevrilir;
- DST sınırında saat kayar;
- created time kullanıcı girdisiyle ezilir;
- migration gerçek geçmişi yeniden yazar.

Bu nedenle P1.01 önce envanter, semantik ve isolated preflight yapar; gerçek
data root'u üzerinde otomatik rewrite yapmaz.

## 10. Şunu şöyle yaptık ki...

Şunu şöyle yaptık ki Faz 0 kapanışı “dokümanlar tamam görünüyor” yorumuna değil,
merged commit + production sabiti + executable test + canonical link zincirine
dayansın. ADR kararlarını çalışan özelliklerden ayrı sütunlarda gösterdik ki
`scope`, `MemoryIndex`, Hafızayı İndir, Proje Paketi veya güvenlik özellikleri
erken tamamlanmış sanılmasın. Drift'i yalnız Issue #171 allowlist'indeki current
yüzeylerde düzelttik ki tarihsel provenance ve kullanıcı dosyaları korunsun.
Son olarak P1.01'i tek aday seçtik ki Faz 1, zaman ve migration anlamını
kesinleştirmeden daha bağımlı archive veya birleşik Hafıza işlerine atlamasın.

## 11. Kısa kontrol listesi

Bir sonraki closure çalışmasında şu soruları sor:

1. Merged commit gerçekten default branch'te mi?
2. Dokümandaki sürüm sayısı current production sabitiyle aynı mı?
3. ADR “karar” mı, “uygulama” mı?
4. Test hangi exact invariant'ı kilitliyor?
5. Açık gap current faz blocker'ı mı, sonraki faz işi mi?
6. Gerçek kullanıcı verisine dokunmadan kanıt üretilebiliyor mu?
7. Sonraki tek iş bağımlılık sırasının gerçekten ilk maddesi mi?
