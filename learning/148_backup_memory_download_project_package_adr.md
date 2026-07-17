# Issue #148 Öğrenme Notu: Backup, Hafızayı İndir ve Proje Paketi

## 1. Bu çalışmada ne öğrendik?

Bu görev yeni Python kodu yazmadı. Var olan iki production formatını okuyup
gelecekteki iki çıktı ailesiyle karışmayacak bağlayıcı bir mimari sözleşme
kurdu:

```text
Backup          -> sistemi geri getirmek
Hafızayı İndir  -> sahibin bütün bilgisini okuyabilmesi
Proje Paketi    -> tek projeden güvenli paylaşım yapmak
Günlük Çıktı    -> belirli günün dar operasyonel çıktısı
```

Aynı teknolojiyle, örneğin ZIP ile üretilmeleri aynı ürün anlamına sahip
oldukları anlamına gelmez. Önemli ayrım dosya uzantısı değil, verilen garantidir.

## 2. Önce mevcut kodu nasıl okuduk?

Bu ADR hayalî bir sistem üzerine yazılmadı. Mevcut Backup, Günlük Çıktı, CLI,
web route ve executable testler okunarak bugün gerçekten çalışan sözleşme
çıkarıldı.

### 2.1 Mevcut Backup sabiti

`app/operations/backups.py` içinde:

```python
BACKUP_FORMAT_VERSION = 1
RESTORABLE_SCHEMA_VERSIONS = (2, 3, 4)
```

Satır satır anlamı:

1. `BACKUP_FORMAT_VERSION = 1`, Backup dosyasının kendi format ailesindeki
   sürümünü tanımlar.
2. Bu değer SQLite schema sürümü değildir.
3. `RESTORABLE_SCHEMA_VERSIONS`, format v1 içindeki hangi database
   şemalarının Restore edilebildiğini ayrı bir allowlist ile söyler.
4. Sayıların ayrı tutulması önemlidir: Backup container formatı değişmeden
   eski database schema'sı temporary hedefte migrate edilebilir.

Bu iki değişken bize “format version” ile “database schema version”ın aynı
kavram olmadığını gösterdi.

### 2.2 Backup manifest nasıl kuruluyor?

Mevcut kodun özeti:

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

Satır satır açıklama:

- `backup_format_version`, yalnız Backup okuyucusunun sözleşmesidir.
- `created_at`, artifact'ın üretildiği canonical UTC anıdır.
- `schema_version`, ZIP içindeki `cse.sqlite3` dosyasının migration seviyesidir.
- Üç `*_count` alanı, extracted database ve attachment envanteriyle yeniden
  karşılaştırılabilen doğrulama kanıtıdır.
- `files`, database ve attachment payload'larının SHA-256/byte boyutu
  sözlüğüdür.
- `attachments`, attachment path'lerini deterministic sırada ayrıca görünür
  kılar.

Manifest kendi checksum'ını kendi içinde taşımaz. Aksi halde şu recursive sorun
oluşurdu:

```text
manifest checksum'ı manifestte yazılacak
-> manifest byte'ı değişecek
-> checksum değişecek
-> yeni checksum yazılacak
-> manifest tekrar değişecek
```

Bu nedenle payload'lar manifestlenir; manifest exact schema ve canonical JSON
kurallarıyla doğrulanır.

### 2.3 Backup yalnız dosya hash'i kontrol etmiyor

Mevcut Restore akışı şu koda karşılık gelir:

```python
manifest = self.verify_backup(archive_path)
self._extract_archive_files(bundle, temporary, manifest["files"])
self._validate_restored_database(temporary, manifest, source_schema_version)
if source_schema_version < SCHEMA_VERSION:
    self._migrate_restored_database(temporary / "cse.sqlite3")
self._validate_restored_database(temporary, manifest, SCHEMA_VERSION)
self._validate_current_repositories(temporary / "cse.sqlite3")
self._atomic_move(temporary, target)
```

Çalışma akışı:

```text
ZIP bütünlüğünü doğrula
-> private temporary dizine çıkar
-> eski schema haliyle database/count/attachment doğrula
-> gerekiyorsa yalnız temporary database'i migrate et
-> güncel schema ile tekrar doğrula
-> gerçek repository okumalarını çalıştır
-> ancak hepsi geçerse yeni hedefi atomik aktive et
```

Buradaki en önemli öğrenme şudur: **Restore garantisi SHA-256 kontrolünden daha
geniştir.** Dosya hash'i doğru olsa bile embedded database geçersiz, migration
zinciri eksik veya repository tarafından okunamaz olabilir.

### 2.4 Mevcut Günlük Çıktı manifest'i farklıdır

`app/operations/exports.py` içinde:

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

Bu kodun anlamı:

- Günlük Çıktı v1 tarihsel olarak genel adlı `format_version` wire anahtarını
  kullanır.
- `local_date`, Restore hedefi değil çıktı seçimidir.
- `record_count`, observation sayısıdır; bütün Hafıza sayısı değildir.
- `warning_count`, attachment envanterindeki doğrulama uyarılarını sayar.
- `files`, yalnız dört günlük payload'ın checksum'ını taşır.

Mevcut entry sırası da sabittir:

```python
EXPORT_FILES = (
    "observations.md",
    "observations.csv",
    "observations.json",
    "attachment_manifest.json",
)
```

Builder bu sıraya `export_manifest.json` dosyasını en son ekler. Bu davranış
Backup'ın `manifest -> database -> attachments` sırasından farklıdır.

## 3. Neden dört ayrı format sürümü gerekir?

ADR şu namespace'leri ayırdı:

```text
backup_format_version
memory_download_format_version
project_package_format_version
daily_export_format_version
```

Burada **namespace**, bir adın yalnız kendi bağlamında anlam taşıdığı alan
demektir. Örneğin dört aile de `1` sürümünde olabilir; fakat dört tane `1` aynı
manifesti veya aynı verifier'ı anlatmaz.

| Değişiklik | Hangi sürüm etkilenir? | Diğerleri neden etkilenmez? |
| --- | --- | --- |
| Restore için yeni database container düzeni | Backup | Kişisel arşiv ve proje teslimi Restore yapmaz |
| Hafıza arşivine yeni insan-okur index | Hafızayı İndir | Backup'ın database snapshot'ı aynı kalabilir |
| Proje Paketi publication guard değişimi | Proje Paketi | Owner arşivi sharing eligibility uygulamaz |
| Günlük CSV kolon sözleşmesi değişimi | Günlük Çıktı | Daha geniş Proje Paketi seçimi ayrı sözleşmedir |

Mevcut Günlük Çıktı v1'in wire anahtarını bu dokümantasyon görevinde rename
etmedik. Bunu yapsaydık testler ve eski okuyucular kırılırdı. Bunun yerine:

```text
kavramsal namespace = daily_export_format_version
mevcut v1 wire key  = format_version
gelecekte rename    = ayrı format v2 implementation işi
```

kararını verdik.

## 4. Scope ve project bağlantısı neden yeniden doğrulanır?

ADR-0001'in temel kuralı:

```text
project_id dolu olabilir
scope yine private olabilir
```

Örneğin kişisel bir follow-up belirli şantiyeyle ilişkili olabilir. Bu ilişki,
kaydın paylaşılabilir olduğu anlamına gelmez.

Yanlış yaklaşım:

```python
if record.project_id == selected_project_id:
    package.add(record)
```

Güvenli sözleşmenin düşünsel karşılığı:

```python
source = source_repository.get(record_id)
if source.scope != "project":
    raise ProjectPackageValidationError()
if source.project_id != selected_project_id:
    raise ProjectPackageValidationError()
if source.revision != selected_revision:
    raise ProjectPackageValidationError()
validate_archive_status_references_attachments_and_publication(source)
```

Bu kod uygulanmadı; ADR'deki gelecek implementation sınırını göstermek için
örnektir.

Satır satır:

1. İçerik projection/cache yerine source repository'den yeniden okunur.
2. Scope exact `project` değilse paylaşım reddedilir.
3. Proje kimliği seçilen projeyle aynı değilse reddedilir.
4. Kullanıcının seçtiği revision stale olmuşsa eski seçimle paket üretilmez.
5. Archive, status, reference, attachment ve publication guard'ları ayrıca
   çalışır.

## 5. MemoryIndex neden çıktı payload'ı değildir?

ADR-0002'de `MemoryIndex`, yeniden üretilebilir read-model'dir. Şu işlerde
yararlıdır:

```text
hangi kayıtlar var?
hangi türdeler?
hangi project/scope adayları görünüyor?
kullanıcı hangi kayda deep link ile gidecek?
```

Fakat şu soruların son yetkilisi değildir:

```text
kaydın güncel revision'ı nedir?
scope gerçekten project mi?
attachment gerçekten mevcut ve hash'i doğru mu?
publication snapshot'ı hangisi?
```

Bu nedenle çıktı akışı:

```text
MemoryIndex ile adayları bul
-> source kayıtları yeniden oku
-> source scope/project/revision/archive/status doğrula
-> event/reference/attachment/publication verisini doğrula
-> payload üret
-> artifact verifier çalıştır
-> final dosyayı atomik yayımla
```

şeklinde kararlaştırıldı.

## 6. Üç verifier neden ayrı olmalı?

Ortak primitive'ler vardır: safe path, canonical JSON, SHA-256, exact entry
kümesi. Fakat verifier'ın verdiği güvence farklıdır.

| Verifier | Doğruladığı iddia | Doğrulamadığı iddia |
| --- | --- | --- |
| Backup'ı Doğrula | Bu artifact desteklenen sürümde güvenli Restore adayıdır | Paylaşılabilir proje çıktısıdır |
| Hafızayı İndir doğrulaması | Owner arşivinin manifest/entry/inventory bütünlüğü geçerlidir | Application database'i restore eder |
| Proje Paketi doğrulaması | Tek proje ve sharing guard snapshot'ı kendi içinde tutarlıdır | Bütün owner hafızasını içerir veya live source hiç değişmemiştir |
| Günlük Çıktı doğrulaması | Mevcut günlük payload hash ve entry sırası geçerlidir | Restore veya genel Proje Paketi uygunluğu |

Tek verifier şu tehlikeli kestirmeye yol açardı:

```text
ZIP açılıyor + checksum doğru
-> her amaç için güvenli
```

Oysa doğru sonuç şudur:

```text
ZIP açılıyor + checksum doğru
-> taşıma bütünlüğünün yalnız ilk katmanı geçti
-> aileye özgü semantik guard'lar ayrıca çalışmalı
```

## 7. Manifest entry ve checksum kuralı

Gelecek Hafızayı İndir ve Proje Paketi formatları için her payload entry'nin en
az şu bilgileri taşıması kararlaştırıldı:

```json
{
  "path": "records/observation/20000000-0000-4000-8000-000000000002.json",
  "logical_role": "record",
  "media_type": "application/json",
  "size_bytes": 840,
  "sha256": "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"
}
```

Alanların anlamı:

- `path`: archive içindeki canonical relative POSIX yol;
- `logical_role`: entry'nin record, event, attachment, human index gibi görevi;
- `media_type`: byte içeriğinin biçimi;
- `size_bytes`: sıkıştırılmamış gerçek byte sayısı;
- `sha256`: sıkıştırılmamış byte içeriğinin digest'i.

Checksum ZIP'in sıkıştırılmış blokları üzerinde değil entry açıldığında çıkan
byte'lar üzerinde hesaplanır. Böylece compression implementation değişse bile
payload bütünlüğünün anlamı aynı kalır.

## 8. Deterministik ne demektir?

Deterministik davranış iki seviyeye ayrıldı:

1. Entry ve kayıt sırası her zaman sabit kuralla belirlenir.
2. Clock, artifact ID ve source snapshot dahil bütün girdiler aynıysa artifact
   byte'ları da aynı olmalıdır.

Örnek sıra:

```text
manifest.json
attachments/...
events/...
records/...
```

Gelecek ailelerde manifest ilk entry olur; diğer yollar Unicode NFC sonrası
UTF-8 byte sırasına göre yazılır. ZIP timestamp ve platform permission metadata
değerleri sabitlenir.

Fakat iki gerçek üretimde `created_at` farklıysa manifest byte'ı da farklıdır.
Bu durumda entry sırası deterministik olsa da artifact'ın tamamı byte-identical
olmak zorunda değildir. Test, sabit clock ve sabit kimlik enjekte ederek tam
eşitliği ölçer.

## 9. Mevcut testler bize neyi kanıtlıyor?

### 9.1 Backup manifest ve geriye uyumluluk testi

Mevcut testten sadeleştirilmiş bölüm:

```python
assert RESTORABLE_SCHEMA_VERSIONS == (2, 3, 4)
assert verified["backup_format_version"] == 1
assert verified["schema_version"] == 4
assert set(verified) == BACKUP_MANIFEST_KEYS
assert "follow_up_count" not in verified
assert "routine_count" not in verified
```

Bu test şunları kilitler:

- restore allowlist'i tahminle genişleyemez;
- Backup format v1 olarak kalır;
- manifest exact alan kümesine sahiptir;
- tracking eklendi diye v1 manifest count alanları sessizce genişlemez.

Bu nedenle ADR yazarken mevcut manifest'e `artifact_family` gibi yeni alan
eklemedik. Böyle bir değişiklik production format v2 ve test değişikliği ister.

### 9.2 Günlük Çıktı privacy regresyonu

Mevcut testin temel fikri:

```python
DailyExportService(root_a, **deterministic_export).build_daily_export(
    "2026-07-13", output_a
)
DailyExportService(root_b, **deterministic_export).build_daily_export(
    "2026-07-13", output_b
)

assert output_a.read_bytes() == output_b.read_bytes()
```

`root_a` yalnız resmî observation verisi taşır. `root_b` aynı observation'a ek
olarak private follow-up ve routine verisi taşır. ZIP'ler byte-for-byte aynıysa
private tracking verisinin yalnız görünmemesi değil, manifest/count/hash gibi
yan kanallara da etki etmemesi kanıtlanır.

Test ayrıca private metinleri ve kimlikleri bütün ZIP içeriğinde arar:

```python
assert all(token not in combined_text for token in forbidden_tokens)
```

Bu, basit “JSON listesinde follow-up yok” kontrolünden daha güçlüdür.

### 9.3 Fail-closed Restore testi

Mevcut testler migration veya repository validation hatasında şunu doğrular:

```python
with pytest.raises(BackupValidationError):
    backup.restore_backup(archive, target)

assert not target.exists()
```

Yani hata “yarım başarı” sayılmaz. Kullanıcının yeni hedefinde kısmen migrate
edilmiş data root bırakılmaz. Proje Paketi ve Hafızayı İndir builder'ları için de
aynı finalization ilkesi kararlaştırıldı: bütün kontroller geçmeden final artifact
görünür olmaz.

## 10. Teknik karar tablosu

| Konu | Karar | Neden |
| --- | --- | --- |
| Backup kapsamı | Her şey; filtre yok | Eksik felaket kurtarma yanıltıcıdır |
| Hafızayı İndir kapsamı | Bütün owner hafızası | Veri taşınabilirliği ve okunabilirlik amacı |
| Proje Paketi kapsamı | Tek proje + seçilmiş `scope=project` | Private ve çapraz proje sızıntısını önlemek |
| Günlük Çıktı kapsamı | Mevcut gün/observation hattı | Kısa dönem operasyon çıktısını korumak |
| Format sürümü | Dört bağımsız namespace | Bir aile değişince diğerlerini kırmamak |
| Checksum | SHA-256, uncompressed payload bytes | Compression'dan bağımsız bütünlük |
| Manifest checksum'ı | Kendi listesine girmez | Recursive digest'i önlemek |
| Unknown format | Fail-closed | Şema/privacy anlamı tahmin edilemez |
| Archive | Varsayılan dışarıda; açık tarihsel ek seçimi | Geçmişi sessizce yayımlamamak |
| Terminal status | Archive sayılmaz | Lifecycle ve archive ayrı kavramlardır |
| MemoryIndex | Yalnız aday inventory | Projection source of truth değildir |
| Verifier | Aileye özgü | Verilen güvence aileye göre değişir |
| Source mutation | Yasak | Doğrulama repair/migration işlemi değildir |
| Encryption | Backup/Hafıza gelecek formatta zorunlu; Project/Daily ayrı politika | Veri kapsamı ve paylaşım amacı farklıdır |

## 11. Şunu şöyle yaptık ki...

**Şunu şöyle yaptık ki...** Backup, Hafızayı İndir ve Proje Paketi kullanıcıya
aynı “ZIP indir” eyleminin farklı adları gibi görünmesin; her birinin verdiği
garanti, taşıdığı veri ve başarısızlık davranışı ayrı ve test edilebilir olsun.

- Backup'ı eksiksiz tuttuk ki kullanıcı felaket anında filtrelenmiş bir dosyayı
  tam kurtarma paketi sanmasın.
- Hafızayı İndir'i Restore'dan ayırdık ki okunabilir JSON/Markdown arşive
  database yeniden kurma garantisi verilmesin.
- Proje Paketi'nde source scope ve proje doğrulamasını zorunlu tuttuk ki yalnız
  `project_id` dolu olduğu için private kayıt paylaşılmasın.
- Günlük Çıktı v1'i değiştirmedik ki mevcut entry/manifest sözleşmesi ve
  private tracking izolasyonu bozulmasın.
- Dört version namespace'i ayırdık ki bir ailenin yeni sürümü diğer üç aileyi
  anlamsız yere migrate etmeye zorlamasın.
- Verifier'ları ayırdık ki checksum başarısı yanlışlıkla Restore veya privacy
  uygunluğu gibi yorumlanmasın.
- Unknown ve eksik kanıtta fail-closed seçtik ki sistem güvenlik kararını
  tahminle vermesin.

## 12. Yeni terimler

### Manifest

Artifact'ın hangi aile/sürüme ait olduğunu, hangi entry'leri taşıdığını ve
bütünlüğün nasıl doğrulanacağını açıklayan makine-okur metadata'dır.

### Format Sürümü

Yalnız bir çıktı ailesinin manifest, entry ve reader/verifier sözleşmesinin
sürümüdür. Database schema veya başka çıktı ailesinin sürümü değildir.

### Bütünlük Doğrulaması

Dosyanın yalnız açılmasını değil; exact entry kümesi, safe path, boyut, checksum
ve aileye özgü tutarlılık kurallarını kontrol etmektir.

### Fail-closed

Gerekli kanıt eksik veya belirsiz olduğunda güvenli varsayım yapıp işlemi
reddetmektir. Örneğin scope bilinmiyorsa kaydı Proje Paketi'ne almak yerine
paketi üretmemek.

### Namespace

Aynı görünen ad veya sayının hangi sözleşme içinde anlamlı olduğunu belirleyen
ad alanıdır. `backup_format_version=1` ile
`project_package_format_version=1` aynı format değildir.

Bu terimler kalıcı sözlüğe adaydır; ancak Issue #148 yalnız belirlenmiş sekiz
dosyaya yazma yetkisi verdiği için `learning/GLOSSARY.md` bu görevde
değiştirilmedi.

## 13. Bu görevde özellikle ne yapılmadı?

- Python production kodu değiştirilmedi.
- Test eklenmedi veya değiştirilmedi.
- Backup v1 ve Günlük Çıktı v1 manifest'i değiştirilmedi.
- Hafızayı İndir veya Proje Paketi builder/verifier yazılmadı.
- Schema, migration, repository, route, CLI veya UI eklenmedi.
- Encryption veya key recovery uygulanmadı.
- Gerçek kullanıcı data root'una erişilmedi.

ADR, sonraki dar implementation görevlerinin hangi davranışı executable testle
kanıtlaması gerektiğini belirleyen sözleşme olarak bırakıldı.
