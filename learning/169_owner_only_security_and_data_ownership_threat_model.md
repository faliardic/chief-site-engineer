# Issue #169 Öğrenme Notu — Owner-only Güvenlik ve Veri Sahipliği

## 1. Bu çalışmada ne yaptık?

Bu Issue'da güvenlik özelliği yazmadık. Mevcut CSE kodunun gerçekten koruduğu
alanlarla henüz korumadığı alanları ayıran bir **tehdit modeli** oluşturduk.

Ana soru şuydu:

```text
Hangi değerli şeyi koruyoruz?
-> Hangi güven sınırından geçiyor?
-> Kim veya ne yanlış davranabilir?
-> Bugünkü kod neyi gerçekten engelliyor?
-> Hangi açık ayrı implementation gerektiriyor?
-> Hangi olay pilotu hemen durdurur?
```

Bu yaklaşım önemlidir; çünkü “local”, “tek kullanıcı” veya “hash var” demek
uygulamanın her bakımdan güvenli olduğu anlamına gelmez.

## 2. Yeni terimler

### Asset — varlık

Korunması gereken şeydir. SQLite database, attachment dosyası, Backup,
`private | project` bilgisi ve pilot logu birer asset'tir.

### Threat actor — tehdit aktörü

Zarar verebilecek kişi, process veya failure kaynağıdır. Aktörün kötü niyetli
olması şart değildir. Disk dolması ve owner'ın yanlış dosyayı paylaşması da
tehdit kaynağıdır.

### Trust boundary — güven sınırı

Bir taraftaki varsayımların diğer tarafta otomatik geçerli olmadığı geçiştir.
Örneğin browser ile local web server arasındaki sınırda “request geldi, demek ki
owner istedi” varsayımı güvenli değildir.

### Confidentiality, integrity, availability — CIA

- **Confidentiality:** Bilgiyi yalnız izinli tarafın görebilmesi.
- **Integrity:** Bilginin yetkisiz veya fark edilmeden değişmemesi.
- **Availability:** Bilginin gerektiğinde erişilebilir olması.

### Mitigation — azaltıcı kontrol

Tehdidin olasılığını veya etkisini azaltan kontroldür. Loopback bind, path
validation ve Backup verifier mitigation örnekleridir.

### Residual risk — kalan risk

Mevcut kontrol çalıştıktan sonra hâlâ kalan risktir. Launcher loopback'e bind
etse bile aynı cihazdaki malicious process ve CSRF-benzeri request riski tamamen
yok olmaz.

### Fail-closed

Güvenlik kanıtı yoksa işlemin güvenli varsayımla devam etmemesidir. Scope
belirsizse Proje Paketi üretmemek fail-closed davranıştır.

### Attack surface — saldırı yüzeyi

Güvenilmeyen input'un sisteme ulaşabildiği bütün noktalardır: HTTP route,
upload, archive entry, local path, update artifact ve dependency gibi.

Bu terimler bu learning dosyasında tanımlandı. Issue #169 allowlist'i
`learning/GLOSSARY.md` dosyasını içermediği için glossary değiştirilmedi.

## 3. Owner-only ile multi-user arasındaki fark

CSE'nin tek gerçek kullanıcısı şantiye şefidir. Bu ürün kararı şu gereksiz
yapıları dışarıda bırakır:

- tenant;
- firma üyeliği;
- rol matrisi;
- ekip hesabı;
- kurumsal onay zinciri.

Fakat şu güvenlik sorunlarını kaldırmaz:

- açık Windows session'ı;
- başka local process;
- aynı LAN'daki cihaz;
- public interface yanlış yapılandırması;
- cihaz kaybı;
- plain Backup sızıntısı;
- malicious attachment veya update.

Kısacası:

```text
Tek sahipli ürün
!=
korumasız ürün
```

## 4. Gerçek kod: loopback sınırı

Mevcut ortak launcher sözleşmesinde şu sabit bulunuyor:

```python
# app/launcher/contracts.py
LOOPBACK_HOST = "127.0.0.1"
```

Windows launcher server'ı bu sabitle açıyor:

```python
# app/launcher/windows.py
server = factory(LOOPBACK_HOST, port, application)
```

Satır satır anlamı:

1. `LOOPBACK_HOST`, server'ın normal launcher yolunda yalnız aynı cihazdan
   erişilebilen IPv4 loopback interface'ine bağlanmasını hedefler.
2. `factory(...)`, bu host ile seçilen portta WSGI server oluşturur.
3. `0.0.0.0` kullanılmadığı için launcher bütün network interface'lerini
   dinlemez.
4. Bu kontrol network yüzeyini daraltır.
5. Bu kontrol login, app lock, CSRF token, TLS veya Windows dosya encryption'ı
   oluşturmaz.

Developer entry point farklı host seçimine izin verir ama açık bir bayrak ister:

```python
# app/web/__main__.py
LOOPBACK_HOSTS = frozenset({"127.0.0.1", "localhost", "::1"})

parser.add_argument("--host", default="127.0.0.1")
parser.add_argument("--allow-network", action="store_true")

if args.host not in LOOPBACK_HOSTS and not args.allow_network:
    parser.error("loopback disi host icin --allow-network zorunludur")
```

Satır satır:

1. `LOOPBACK_HOSTS`, hangi host metinlerinin loopback kabul edildiğini listeler.
2. `--host` verilmezse `127.0.0.1` seçilir.
3. `--allow-network` varsayılan olarak `False` olur.
4. Host allowlist dışında ve bayrak kapalıysa CLI başlamaz.
5. Bayrak açılırsa server başlayabilir; bayrak kullanıcı kimliği doğrulamaz.

Bu nedenle ADR'deki karar şöyledir:

```text
loopback default = mevcut daraltıcı kontrol
LAN mode = güvenli production modu değil
public exposure = critical blocker
```

## 5. Gerçek kod: web session boşluğu

Application factory şu biçimde Flask uygulaması oluşturur:

```python
# app/web/app.py
app = Flask(__name__)
app.config.update(
    MAX_CONTENT_LENGTH=MAX_UPLOAD_BYTES,
    CSE_DATA_ROOT=root,
    CSE_INSTANCE_ID=instance_id_for_data_root(root),
)
```

Burada gerçekten olanlar:

- upload için maksimum request boyutu tanımlanır;
- uygulama açık bir data root'a bağlanır;
- data root'tan opaque instance identity türetilir.

Burada görünmeyen ve repository taramasında bulunmayanlar:

- `secret_key`;
- login/session cookie;
- CSRF token;
- session timeout;
- Origin/Host authorization;
- brute-force throttling.

Bu yüzden `CSE_INSTANCE_ID` bir secret veya authentication token gibi
yorumlanamaz. Launcher'ın doğru CSE instance'ını ayırt etmesine yardım eder;
request sahibini doğrulamaz.

## 6. Gerçek kod: managed attachment güvenliği

Kullanıcı dosya adı final path'i doğrudan belirlemez:

```python
# app/storage/paths.py
def build_attachment_relative_path(
    observation_id: str,
    attachment_id: str,
    original_name: str,
) -> str:
    validate_canonical_uuid(observation_id, "observation_id")
    validate_canonical_uuid(attachment_id, "attachment_id")
    suffix = safe_attachment_suffix(original_name)
    return f"attachments/{observation_id}/{attachment_id}{suffix}"
```

Satır satır:

1. Observation kimliği canonical UUID olmak zorundadır.
2. Attachment kimliği de canonical UUID olmak zorundadır.
3. Orijinal adın yalnız kısa, lowercase ve allowlist'e uyan suffix'i alınır.
4. Güvensiz suffix `.bin` fallback'ine döner.
5. Final basename attachment UUID'sidir; `../../secret.txt` gibi kullanıcı adı
   path'i yönetemez.

Relative path validator da traversal segmentlerini reddeder:

```python
def validate_posix_relative_path(value: str) -> PurePosixPath:
    if not isinstance(value, str) or not value:
        raise ValueError("path must be a non-empty POSIX relative path")
    if "\\" in value:
        raise ValueError("path must use POSIX separators only")
    raw_parts = value.split("/")
    if any(part in {"", ".", ".."} for part in raw_parts):
        raise ValueError("path cannot contain empty, dot or traversal segments")
```

Bu kontrolün akışı:

```text
input path
-> string ve boş değil mi?
-> backslash var mı?
-> boş / . / .. segment var mı?
-> relative POSIX path olarak kabul et veya reddet
```

Managed store ayrıca:

- source symlink'i reddeder;
- managed root ve path component'lerinde symlink'i reddeder;
- stream sırasında SHA-256 ve size hesaplar;
- finalize öncesi tekrar hash/size doğrular;
- mevcut staging/final dosyanın üzerine yazmaz;
- download/open öncesi metadata-path-hash-size doğrular;
- reconciliation'da orphan, missing, mismatch ve unsafe file'ı ayırır.

Fakat hash kontrolü dosyanın malware içermediğini söylemez. Hash yalnız
beklenen bytes ile mevcut bytes'ın aynı olup olmadığını söyler.

## 7. Gerçek kod: fail-closed Backup ve Restore

Restore başlangıcındaki kritik guard:

```python
# app/operations/backups.py
target = Path(target_root).resolve()
if target.exists():
    raise BackupValidationError("restore target must not exist")
manifest = self.verify_backup(archive_path)
```

Satır satır:

1. Hedef canonical path'e resolve edilir.
2. Hedef zaten varsa Restore reddedilir.
3. Böylece çalışan data root veya mevcut klasör üzerine yazma yapılmaz.
4. Extraction başlamadan önce Backup verifier çalışır.

Verifier'ın database kontrolü:

```python
integrity = connection.execute("PRAGMA integrity_check").fetchone()[0]
if integrity != "ok":
    raise BackupValidationError("restored database integrity check failed")
```

1. SQLite kendi yapısal integrity kontrolünü çalıştırır.
2. Sonuç exact `ok` değilse devam edilmez.
3. Hatalı database “uyarıyla Restore” edilmez.

Restore akışı bütünüyle şöyledir:

```text
Backup verifier
-> private temporary root
-> checksum'lı extraction
-> SQLite/schema/count/attachment doğrulaması
-> gerekirse temporary migration
-> current repository reopen
-> atomik olarak yeni hedefe taşı
```

Bu akış integrity ve recovery için güçlüdür. Backup ZIP'i plain olduğu için
confidentiality sağlamaz.

## 8. Risk puanını Python ile hesaplama

ADR, basit ve tekrar üretilebilir bir ilk puan kullanır:

```python
SEVERITY_BY_SCORE = {
    range(1, 4): "low",
    range(4, 8): "medium",
    range(8, 12): "high",
    range(12, 17): "critical",
}


def base_severity(likelihood: int, impact: int) -> str:
    if likelihood not in range(1, 5):
        raise ValueError("likelihood must be between 1 and 4")
    if impact not in range(1, 5):
        raise ValueError("impact must be between 1 and 4")

    score = likelihood * impact
    for score_range, severity in SEVERITY_BY_SCORE.items():
        if score in score_range:
            return severity
    raise AssertionError("score mapping must be complete")
```

Satır satır:

1. `SEVERITY_BY_SCORE`, skor aralıklarını canonical severity sözcüklerine bağlar.
2. `base_severity` iki integer alır.
3. Olasılık `1..4` değilse yanlış input hemen reddedilir.
4. Etki `1..4` değilse aynı şekilde reddedilir.
5. `score`, iki değerin çarpımıdır.
6. Döngü skorun bulunduğu aralığı arar.
7. Bulunca ilgili severity döner.
8. Mapping eksik yazılmışsa son `AssertionError` programcı hatasını görünür yapar.

Örnek:

```python
assert base_severity(2, 2) == "medium"   # skor 4
assert base_severity(3, 4) == "critical" # skor 12
```

Fakat tehdit modelinde semantik safety override da vardır:

```python
CRITICAL_OUTCOMES = {
    "data_loss",
    "source_corruption",
    "private_leakage",
    "unsafe_restore",
    "public_exposure",
    "recovery_failure",
}


def final_severity(
    likelihood: int,
    impact: int,
    possible_outcomes: set[str],
) -> str:
    if possible_outcomes & CRITICAL_OUTCOMES:
        return "critical"
    return base_severity(likelihood, impact)
```

Burada `&` iki set'in kesişimini hesaplar. En az bir kritik outcome varsa skor
düşük bile olsa sonuç `critical` olur. Böylece nadir görülen private leakage
“olasılığı düşük” denilerek küçültülemez.

Bu kod öğretici örnektir; Issue #169 production Python'a eklemedi.

## 9. Test kodu nasıl düşünülmeli?

Gelecek security implementation testleri yalnız “başarılı kullanım” testinden
oluşmamalıdır. Negative test güvenilmeyen input'un reddedildiğini kanıtlar.

Öğretici bir test örneği:

```python
import pytest


def test_risk_inputs_outside_allowlist_fail_closed() -> None:
    with pytest.raises(ValueError, match="likelihood"):
        base_severity(0, 4)

    with pytest.raises(ValueError, match="impact"):
        base_severity(4, 5)
```

Satır satır:

1. `pytest` exception assertion için içe aktarılır.
2. Test adı beklenen güvenlik davranışını söyler: allowlist dışı input reddedilir.
3. İlk context manager `ValueError` bekler.
4. `match`, hatanın doğru nedenden geldiğini kontrol eder.
5. `0` geçersiz likelihood olduğu için fonksiyon devam edemez.
6. İkinci örnekte impact `5` olduğu için aynı fail-closed davranış beklenir.

## 10. Repository'deki mevcut güvenlik testleri neyi kanıtlıyor?

### Launcher testleri

`tests/test_windows_launcher.py` içinde:

- default data/log root'un `%LOCALAPPDATA%` altında olduğu;
- `/health` yanıtının minimal identity/readiness taşıdığı;
- başka service'in CSE sanılmadığı;
- farklı data root instance'ının karıştırılmadığı;
- subprocess launcher'ın localhost'ta başladığı

doğrulanır.

Bu testler auth veya LAN security kanıtı değildir.

### Managed attachment testleri

`tests/test_managed_attachment_store.py` şu negative durumları test eder:

- unsafe original filename;
- source symlink;
- symlink root/staging/final component;
- existing destination overwrite;
- copy/fsync/finalize failure;
- missing, size mismatch, hash mismatch ve unsafe path;
- unsafe path üzerinden open/read.

Bu testler malware classification kanıtı değildir.

### Backup/Restore testleri

`tests/test_backup_restore.py` içinde:

- online snapshot/verify/Restore/reopen;
- schema 2/3 → 4 isolated migration;
- unknown schema, migration gap ve manifest mismatch reddi;
- corrupt/extra/missing/unsafe/symlink/duplicate archive entry reddi;
- existing target'ın korunması;
- partial Restore'un active olmaması;
- source ve archive digest'inin korunması

kanıtlanır.

Bu testler Backup confidentiality veya key recovery kanıtı değildir.

### Output privacy testi

`tests/test_daily_export.py` içindeki
`test_official_daily_export_is_byte_identical_with_private_tracking_data`
private follow-up/routine eklense bile mevcut resmî günlük ZIP'inin aynı
kaldığını doğrular.

Bu güçlü bir current isolation kanıtıdır. Future Proje Paketi veya source scope
alanı uygulanmış demek değildir.

## 11. Teknik karar tablosu

| Karar | Neden | Reddedilen kısa yol | Gelecek kanıt |
|---|---|---|---|
| Launcher loopback mevcut daraltıcı kontrol sayıldı | Gerçek kod/test kanıtı var | “Local her durumda güvenli” | Secure LAN negative/positive acceptance |
| `--allow-network` güvenlik özelliği sayılmadı | Bayrak kimlik/TLS sağlamaz | Bayrağı açınca LAN production kabulü | Pairing, TLS, lock ve authorization |
| Hash integrity olarak sınıflandı | Bytes değişimini gösterir | Hash'i malware/encryption sanmak | Malware/quarantine ve encrypted artifact testleri |
| Backup recovery ile paylaşım ayrıldı | Bütün scope'ları ve private içeriği taşır | Backup'ı Proje Paketi gibi göndermek | Encrypted Backup + share warning |
| Scope yetkilendirme sayılmadı | ADR-0001 output eligibility'dir | `private` başka Windows user'dan gizlidir demek | App lock/OS/encryption kabulü |
| Source aggregate/event truth kaldı | Projection stale/rebuildable olabilir | Cache'i source'a yazmak | Drift diagnostic + shadow rebuild |
| Safety outcome severity override aldı | Düşük olasılık kritik sonucu küçültmemeli | Yalnız matematik skoruna güvenmek | Incident/recovery revalidation |
| Security işi Faz 12'ye haritalandı | Bugünkü Issue implementation değil | Belgede yazınca koruma var sanmak | Her mitigation için executable Issue |

## 12. Kod ve güvenlik karar akışı

```text
Güvenilmeyen input/olay
        |
        v
Hangi asset etkileniyor?
        |
        v
Hangi trust boundary geçiliyor?
        |
        v
Bugünkü executable control var mı?
   |                      |
  evet                   hayır
   |                      |
Control sonucu PASS?      Gap'i açık yaz
   |                      |
  hayır                   v
   +---------------> severity + blocker kararı
                          |
                          v
                 immediate containment
                          |
                          v
                 future executable Issue
                          |
                          v
                 acceptance kanıtı PASS
```

Önemli nokta: Future mitigation satırı bugünkü riski “çözülmüş” yapmaz.

## 13. Incident anında neden hemen repair etmiyoruz?

Şüpheli corruption veya leakage anında source'u değiştirmek kanıtı ve recovery
seçeneklerini bozabilir.

Doğru ilk sıra:

```text
mutation/paylaşım/update durdur
-> gerekiyorsa network izolasyonu
-> anonim incident ID
-> source/artifact yerinde repair yok
-> yeni ayrı Backup + verifier (okunabiliyorsa)
-> owner-controlled hassas kanıt
-> root cause ve clean recovery Issue'su
-> yeni revalidation penceresi
```

Backup verifier başarısızsa o dosya “en azından bir yedeğimiz var” diye PASS
sayılmaz.

## 14. Şunu şöyle yaptık ki...

Şunu şöyle yaptık ki mevcut loopback, attachment ve Backup kontrollerinin
değerini kaybetmeden sınırlarını da dürüstçe gösterelim: her threat scenario'da
`current_control` ile `control_gap` alanlarını ayrı yazdık.

Şunu şöyle yaptık ki düşük olasılıklı ama yıkıcı veri kaybı veya private
leakage küçümsenmesin: çarpım skoruna ek olarak semantic critical override
tanımladık.

Şunu şöyle yaptık ki `private | project` yanlış bir auth iddiasına dönüşmesin:
scope'u yalnız output/share eligibility olarak tuttuk; Windows hesabı, app lock
ve encryption'ı ayrı implementation işlerine bıraktık.

Şunu şöyle yaptık ki gelecek Faz 12 listesi soyut temenni olarak kalmasın: her
işe negative/positive executable acceptance kapısı ekledik.

Şunu şöyle yaptık ki tehdit modelini yazarken gerçek kullanıcı verisine risk
oluşmasın: public/LAN server açmadık, `CSE_DATA_ROOT` kullanmadık, gerçek Backup,
attachment, log veya pilot içeriği okumadık.

## 15. Sonuç

Issue #169'un ana dersi şudur:

```text
Güvenlik iddiası
=
gerçek çalışan kontrol
+ açık gap
+ detection
+ containment
+ executable acceptance
```

Belgeye “encryption”, “app lock” veya “secure session” yazmak bunları uygulamaz.
Mevcut CSE bugün loopback, path/hash, transaction ve verified Restore alanlarında
somut kontrollere sahiptir; owner access, artifact confidentiality, LAN,
session ve software supply chain alanlarında ise açık implementation borcu
taşır.
