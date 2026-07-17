# ADR-0003: Backup, Hafızayı İndir ve Proje Paketi Ayrımı

- **Durum:** Kabul edildi
- **Tarih:** 2026-07-17
- **Issue:** #148
- **Bağlayıcı üst kararlar:** ADR-0001 ve ADR-0002
- **Kapsam:** Dokümantasyon ve mimari karar; implementation değildir

## 1. Bağlam

CSE'de “bir ZIP indir” ifadesi bugün veya gelecekte dört farklı kullanıcı
niyetini anlatabilir:

1. cihaz ya da veri kaybından sonra bütün uygulamayı geri getirmek;
2. şantiye şefinin bütün Hafıza'sını okunabilir kişisel arşiv olarak almak;
3. tek projeden seçilmiş, paylaşılabilir bir teslim çıktısı hazırlamak;
4. belirli bir günün saha gözlemlerini operasyonel çıktı olarak indirmek.

Bu niyetler aynı dosya, aynı manifest veya aynı verifier ile karşılanırsa iki
kritik hata doğar. Birincisi, okunabilir bir export'a restore garantisi
atfedilmesidir. İkincisi, `private` kaydın veya başka projeye ait içeriğin
paylaşılabilir çıktıya sızmasıdır.

Mevcut production davranışı zaten iki ayrı aile taşır:

- Backup format `1`, SQLite snapshot ile yönetilen attachment dosyalarını
  `manifest.json` altında toplar; doğrulama ve yalnız yeni hedefe izole Restore
  uygular.
- Günlük Çıktı format `1`, seçilen Europe/Istanbul gününün observation
  kayıtlarını Markdown, CSV, JSON ve attachment envanteri olarak üretir;
  follow-up ve routine verisi bu çıktıya byte-identical izolasyon testiyle
  girmez.

ADR-0001, Backup'ın bütün kapsamları; Hafızayı İndir'in bütün Hafıza'yı;
Proje Paketi ile resmî çıktının yalnız uygun `project` kapsamını taşıyacağını
kararlaştırmıştır. ADR-0002 ise `MemoryIndex`in yalnız aday inventory/read-model
olduğunu, gerçek içerik ve çıktı uygunluğunun source kayıtlardan yeniden
okunacağını bağlamıştır.

Bu ADR dört çıktı ailesinin amaç, kapsam, manifest, sürüm, bütünlük, gizlilik ve
kullanıcı beklentisini kesinleştirir. Production kodu veya mevcut dosya formatı
değiştirmez.

## 2. Karar özeti

| Aile | Birincil amaç | Veri kapsamı | Restore garantisi | Paylaşım beklentisi |
| --- | --- | --- | --- | --- |
| **Backup** | Felaket kurtarma ve tam geri yükleme | Bütün `private` + `project` kaynaklar, event geçmişleri, archive durumları ve yönetilen attachment'lar | Yalnız desteklenen format/schema sürümlerinde ve başarılı Backup'ı Doğrula sonucuyla | Paylaşılabilir proje çıktısı değildir |
| **Hafızayı İndir** | Owner'ın insan ve makine tarafından okunabilir kişisel arşivi | Bütün kayıt türleri, iki kapsam, proje bağları, archive, event geçmişi ve attachment envanteri/dosyaları | Yok | Owner arşividir; Proje Paketi değildir |
| **Proje Paketi** | Seçilen tek proje için paylaşılabilir teslim/rapor paketi | Yalnız source'tan yeniden doğrulanmış, seçilmiş `scope=project` kayıtlar ve izinli bağımlılıkları | Yok | Tek proje için açık paylaşım sınırıdır |
| **Günlük Çıktı** | Belirli günün kısa dönem operasyonel saha çıktısı | Mevcut v1'de gün filtresine uyan observation kayıtları ve attachment envanteri | Yok | Proje Paketi'nden dar, günlük çalışma çıktısıdır |

Bir artifact aynı anda yalnız bir aileye aittir. Dosya uzantısını, manifest
alanını veya kullanıcı etiketini değiştirerek aileler arasında dönüşüm
yapılamaz.

## 3. Backup sözleşmesi

### 3.1 Amaç ve kapsam

Backup'ın tek birincil amacı felaket kurtarmadır:

```text
doğrulanmış Backup
-> boş ve yeni hedef
-> izole extraction
-> desteklenen migration
-> repository ve attachment doğrulaması
-> atomik aktivasyon
-> Restore edilmiş CSE data root
```

Bağlayıcı kurallar:

- Bütün `private` ve `project` kayıtlar alınır.
- Append-only event geçmişleri ve archive durumları korunur.
- Fiziksel olarak yönetilen bütün attachment'lar metadata ile birlikte alınır.
- Source-of-truth SQLite snapshot zorunludur. Gelecekteki türetilmiş
  `MemoryIndex` aynı database snapshot içinde bulunabilir; fakat Restore
  doğruluğu projection'a güvenmez. Projection yeniden üretilebilir olmalıdır.
- Tarih, proje, kayıt türü, scope veya kullanıcı seçimiyle filtreli/kısmi
  Backup üretilemez.
- Attachment eksik, bozuk veya güvenli path sözleşmesine aykırıysa “uyarıyla
  eksik Backup” üretilmez; işlem fail-closed başarısız olur.
- Backup, Proje Paketi, rapor veya paylaşıma hazır teslim olarak sunulamaz.

### 3.2 Restore garantisinin sınırı

“Restore edilebilir” iddiası ancak şu koşulların tümünde geçerlidir:

1. `backup_format_version` desteklenir.
2. Embedded `schema_version` açık restore allowlist'indedir.
3. Backup'ı Doğrula manifest, entry, SHA-256, SQLite integrity, migration
   zinciri, count ve attachment reconciliation kontrollerini geçer.
4. Restore var olmayan yeni hedefte başlar.
5. Gerekli migration yalnız temporary hedefte tamamlanır.
6. Güncel repository okumaları başarılıdır.
7. Doğrulanmış temporary hedef tek atomik adımla aktive edilir.

Bilinmeyen format/schema, migration gap'i, eksik/ek entry veya reconciliation
hatası restore edilebilir kabul edilmez. Kaynak data root, Backup artifact'ı ve
mevcut hedef bu kontroller sırasında değiştirilmez.

### 3.3 Mevcut v1 manifest

Mevcut Backup format `1` değiştirilmeden şu exact alanları taşır:

```text
backup_format_version
created_at
schema_version
attachment_count
observation_count
event_count
files
attachments
```

`files`, `cse.sqlite3` ile attachment entry'lerinin uncompressed byte içeriği
için lowercase SHA-256 ve `size_bytes` taşır. `manifest.json` kendi checksum
listesine girmez; böylece recursive digest oluşmaz. Archive içinde manifest
dışında manifestte bildirilmeyen entry bulunamaz.

Bu ADR mevcut `backup_format_version=1`, restore edilebilir schema `(2, 3, 4)`,
manifest alanları, count anlamları, ZIP entry adları veya Restore kodunu
değiştirmez.

## 4. Hafızayı İndir sözleşmesi

### 4.1 Amaç ve kapsam

Hafızayı İndir, uygulama database'inin teknik kopyası değil, owner'ın kendi
bilgisine erişebildiği kalıcı ve okunabilir kişisel arşivdir.

Minimum içerik:

- desteklenen bütün source kayıt türleri;
- her kayıt için `record_type`, source kimliği, `scope`, `project_id`, status,
  revision ve archive durumu;
- kaynak içerik ve kayıpsız tür-spesifik alanlar;
- append-only event geçmişi;
- attachment metadata ve bütünlük envanteri;
- fiziksel olarak yönetilen ve bütünlüğü doğrulanmış attachment byte'ları;
- kayıt/event/attachment ilişkisinin makinece çözülebilir anahtarları;
- insan tarafından okunabilir bir index/özet ve makine tarafından okunabilir
  canonical veri.

`MemoryIndex`, kayıtların inventory'sini ve kararlı `RecordRef` kimliklerini
sağlayabilir. İçerik, scope, project, archive, event ve attachment değerleri
paket oluşturulurken source aggregate/repository'den yeniden okunur.

Hafızayı İndir iki kapsamı da taşıdığı için private veridir. UI, dosya
oluşturulmadan önce bunu açıkça söyler. Kayıtları yalnız project, yalnız private,
yalnız açık veya yalnız seçili tür olarak indiren bir işlem bu ailenin “bütün
Hafıza” iddiasını taşıyamaz.

### 4.2 Restore olmayan kişisel arşiv

Hafızayı İndir:

- SQLite data root kopyası olmak zorunda değildir;
- migration çalıştırmaz;
- repository state'ini yeniden kurma sözü vermez;
- revision/event/attachment içeriğini okunabilir ve doğrulanabilir taşır ama
  bunları application database'ine import etmez;
- `Restore` veya “tam yedek” etiketiyle sunulmaz.

Eksik veya bozuk yönetilen attachment “başarılı tam kişisel arşiv” içinde sessiz
uyarıya çevrilmez. Builder fail-closed durur. Ayrı bir diagnostic raporu sorunu
gösterebilir; eksik artifact başarılı Hafızayı İndir sayılmaz.

### 4.3 İlk formatın minimum manifest'i

Hafızayı İndir henüz uygulanmamıştır. İlk implementation
`memory_download_format_version=1` ile başlar ve en az şu alanları taşır:

```text
artifact_family = "memory_download"
memory_download_format_version = 1
created_at
source_schema_version
record_type_counts
scope_counts
project_count
event_count
attachment_count
entries
```

`entries`, manifest dışındaki her payload entry'yi tam bir kez; canonical path,
logical role, media type, uncompressed `size_bytes` ve lowercase SHA-256 ile
listeler. Manifest dışı extra entry, eksik entry, duplicate/case-collision path
ve bilinmeyen logical role reddedilir.

## 5. Proje Paketi sözleşmesi

### 5.1 Amaç ve seçim sınırı

Proje Paketi, tek bir seçilmiş proje için açıkça paylaşılabilir teslim, inceleme
veya rapor artifact'ıdır. Yalnız `project_id` vermek yeterli seçim değildir.

Builder en az şu girdileri açık alır ve manifestte kaydeder:

- tek `selected_project_id`;
- package purpose/profile;
- seçilen source kayıt kimlikleri veya aynı sonucu üreten canonical selection
  snapshot'ı;
- archive dahil etme politikası;
- attachment ve publication seçim politikası;
- builder'ın doğruladığı source revision/fingerprint değerleri.

Her dahil edilen kayıt için package generation anında source yeniden okunur ve
şu guard'ların tümü doğrulanır:

1. `scope == project`;
2. `project_id == selected_project_id`;
3. record type, status ve archive değeri bilinen allowlist'tedir;
4. seçimin revision/fingerprint'i source ile aynıdır;
5. dahil edilen reference izinli ilişki türündedir ve aynı proje içindeki
   `project` kayıtla çözülür;
6. attachment owner kaydı uygundur, path/digest/size geçerlidir ve package
   seçimiyle tutarlıdır;
7. publication/draft/snapshot durumu açık ve source ile tutarlıdır.

Bu guard'lardan biri kanıtlanamıyorsa paket üretilmez. `private` kaydı
“uyarıyla”, redaction'a güvenerek veya yalnız project bağlantısına bakarak
doğrudan dahil etme yoktur. Kullanıcı önce ADR-0001'in açık, revision ve event
üreten `private -> project` dönüşümünü tamamlar; sonra yeni package seçimi yapar.

### 5.2 Archive, status, reference ve publication

- Terminal status archive değildir. Bilinen terminal kayıt, seçimin amacı için
  gerekiyorsa gerçek status etiketiyle pakete girebilir.
- Archive kayıt varsayılan olarak dahil edilmez. `include_archived=true` açık
  seçimi varsa “Tarihsel Ek” olarak ayrı inventory'de görünür; archive durumu
  belirsizse işlem reddedilir.
- Builder relationship graph'ını sınırsız takip etmez. Yalnız formatta
  allowlist edilmiş outbound reference türleri alınır.
- Private, başka projeye ait veya bilinmeyen reference'ın içeriği ve özel
  kimliği pakete yazılmaz. Kayıt o reference olmadan güvenle temsil
  edilemiyorsa bütün package fail-closed durur.
- Published snapshot ile güncel source kayıt birbirine karıştırılmaz. Published
  içerik kendi immutable snapshot'ı olarak; draft/current içerik açık etiketiyle
  taşınır. Publication durumu kanıtlanamıyorsa dahil edilmez.
- Paket üretimi source kapsamını, revision'ı, event geçmişini, archive veya
  publication durumunu değiştirmez.

### 5.3 Attachment kuralları

Attachment bağımsız scope kazanmaz; owner source kaydını izler. Pakete giren
attachment için owner record type/id, selected project, source scope, source
digest, package digest, boyut, media type ve status manifestte bulunur.

Eksik, tampered, unsafe-path, orphan, bilinmeyen status veya başka projeye ait
attachment sessizce atlanmaz. Seçimden açıkça çıkarılabiliyorsa manifest bunu
“seçilmedi” olarak source içeriği sızdırmadan gösterir; kayıt tarafından zorunlu
kanıtsa paket bütünüyle başarısız olur.

### 5.4 İlk formatın minimum manifest'i

Proje Paketi henüz uygulanmamıştır. İlk implementation
`project_package_format_version=1` ile başlar ve en az şu alanları taşır:

```text
artifact_family = "project_package"
project_package_format_version = 1
created_at
selected_project_id
package_purpose
selection_policy
archive_policy
publication_policy
record_type_counts
event_count
attachment_count
entries
```

Her record inventory satırı source revision/fingerprint, scope, project,
status, archive ve publication sonucunu taşır. `entries` checksum sözleşmesi
Hafızayı İndir ile aynı yapısal ilkeleri kullanabilir; fakat manifest şeması ve
verifier aileye özeldir.

## 6. Günlük Çıktı ayrımı

Günlük Çıktı, Proje Paketi'nin küçük adı veya Backup'ın filtreli biçimi değildir.

Mevcut v1 davranışı:

- giriş bir Europe/Istanbul yerel tarihidir;
- o güne uyan observation kayıtları alınır;
- Markdown, CSV, JSON ve attachment envanteri üretilir;
- attachment byte'ları ZIP'e kopyalanmaz;
- follow-up ve routine içerikleri alınmaz;
- entry sırası sabittir ve aynı logical input + aynı manifest değerleri
  byte-identical artifact üretir;
- Restore garantisi yoktur.

Proje Paketi ise seçilmiş tek projenin birden fazla kayıt türünü, daha geniş bir
zaman aralığını ve açık selection/publication politikasını taşıyabilecek
paylaşılabilir teslim ailesidir. Gelecekte günlük snapshot Proje Paketi'ne
referans olabilir; bu, Günlük Çıktı v1'in formatını veya observation/tracking
izolasyonunu değiştirmez.

Mevcut Günlük Çıktı manifest'i exact olarak şunları taşır:

```text
format_version
generated_at
local_date
record_count
warning_count
files
```

Buradaki tarihsel wire anahtarı `format_version=1` değiştirilmez. Bu ADR'deki
canonical sürüm ad alanı **`daily_export_format_version`**'dır. Wire anahtarını
`daily_export_format_version` olarak değiştirmek ancak ayrı bir Günlük Çıktı
format `2` implementation'ı ve backward-compatible reader ile yapılabilir.

## 7. Bağımsız format sürümü ad alanları

Dört bağımsız namespace vardır:

```text
backup_format_version
memory_download_format_version
project_package_format_version
daily_export_format_version
```

Kurallar:

1. Ortak/global `format_version` yoktur.
2. Bir ailedeki version artışı diğer ailelerin version değerini artırmaz.
3. Aynı sayısal değer eşdeğer şema veya verifier anlamına gelmez.
4. Artifact yalnız kendi aile verifier'ına verilir; başka aile verifier'ı yapı
   benzerliğine bakarak kabul edemez.
5. Bilinmeyen major version fail-closed reddedilir; “en yakın sürüm” olarak
   yorumlanmaz.
6. Optional alan eklemek mevcut strict manifest sözleşmesini bozuyorsa format
   version artışı gerekir.
7. Alan anlamı, checksum kapsamı, canonical serialization, path düzeni,
   encryption envelope veya eligibility kuralı değişirse version artışı
   zorunludur.

Mevcut durum:

| Namespace | Durum |
| --- | --- |
| `backup_format_version` | Production v1 mevcut; wire anahtarı aynıdır |
| `memory_download_format_version` | Henüz artifact yok; ilk implementation v1 ile başlar |
| `project_package_format_version` | Henüz artifact yok; ilk implementation v1 ile başlar |
| `daily_export_format_version` | Production v1 mevcut; tarihsel wire anahtarı `format_version` olarak korunur |

## 8. Manifest, checksum ve deterministik paketleme

### 8.1 Ortak güvenlik ilkeleri

Her aile kendi exact manifest şemasına sahip olsa da şu ilkeler ortaktır:

- manifest UTF-8 canonical JSON'dur;
- archive path'leri relative POSIX path'tir; absolute, `..`, backslash, ADS,
  symlink, directory entry ve duplicate/case-collision path reddedilir;
- her payload entry tam bir kez manifestlenir;
- manifestlenmemiş extra entry ve eksik entry reddedilir;
- checksum uncompressed entry byte'ları üzerinde SHA-256'dır;
- boyut uncompressed byte sayısıdır;
- manifest kendi içinde kendi checksum'ını taşımaz;
- checksum karşılaştırması extraction tamamlanmadan/aktivasyondan önce yapılır;
- verifier kaynak kayda veya artifact'a repair yazmaz;
- private metin, dosya adı veya içerik hata/log/debug mesajına varsayılan olarak
  kopyalanmaz.

Future formatlar ZIP bomb/denial-of-service riskine karşı entry sayısı, tekil
entry boyutu, toplam uncompressed boyut ve compression ratio sınırlarını exact
format sözleşmesinde tanımlamak zorundadır. Limit bilinmiyorsa verifier sınırsız
extract etmez.

### 8.2 Deterministik entry sırası

- Backup v1: `manifest.json`, `cse.sqlite3`, sonra attachment path'i artan sıra.
- Günlük Çıktı v1: mevcut sabit `EXPORT_FILES` sırası, sonra
  `export_manifest.json`.
- Hafızayı İndir v1 ve Proje Paketi v1: manifest ilk entry; diğer entry'ler
  Unicode NFC canonical relative path'in UTF-8 byte sırasıyla artan düzeni.

Future formatlarda ZIP timestamp, permission ve platform metadata'sı sabitlenir.
“Deterministik”, aynı logical snapshot ve aynı manifest girdilerinin aynı entry
sırası/canonical payload'ı üretmesidir. `created_at` veya artifact kimliği
farklıysa byte-identical sonuç iddia edilmez. Testler sabit clock/kimlikle tam
byte eşitliğini ayrıca kanıtlar.

## 9. Ayrı verifier sorumlulukları

### 9.1 Backup'ı Doğrula

Backup verifier:

- exact v1 manifest/entry/checksum/path sözleşmesini;
- embedded SQLite `PRAGMA integrity_check` sonucunu;
- exact migration zinciri ve desteklenen schema'yı;
- count değerlerini;
- attachment metadata/path/hash/size reconciliation'ını;
- Restore öncesi ve gerekirse migration sonrası repository okunabilirliğini
  doğrular.

Başarılı sonuç yalnız desteklenen sürüm için Restore güvenlik kapısıdır. Backup
verifier Hafızayı İndir veya Proje Paketi'ni kabul etmez.

### 9.2 Hafızayı İndir bütünlük doğrulaması

Hafızayı İndir verifier:

- aile/version/manifest şemasını;
- exact entry kümesi, sıra, path, size ve checksum'ları;
- record/scope/project/event/attachment inventory count tutarlılığını;
- bütün kayıtların açık `private | project` etiketi taşıdığını;
- bütün source reference'ların package inventory içinde çözülebildiğini
  doğrular.

Bu sonuç “kişisel arşiv bütünlüğü geçerli” demektir; Restore veya import garantisi
değildir.

### 9.3 Proje Paketi doğrulaması

Proje Paketi iki kapı kullanır:

1. **Generation preflight:** live source'tan scope, selected project, revision,
   archive, status, reference, attachment ve publication uygunluğunu yeniden
   okur.
2. **Offline artifact verifier:** manifest/entry/checksum'ı ve package içine
   snapshot edilmiş eligibility kanıtlarının kendi içinde tutarlı olduğunu,
   private/başka proje/bilinmeyen sınıf işareti bulunmadığını doğrular.

Offline verifier live source'un daha sonra değişmediğini kanıtlayamaz ve böyle
bir iddiada bulunmaz. Yeniden üretim veya yeniden yayımlama live preflight'i
tekrar çalıştırır.

### 9.4 Günlük Çıktı doğrulaması

Mevcut v1 builder sabit entry listesini ve manifestteki dört payload checksum'ını
finalize etmeden doğrular. Bu doğrulama Backup Restore güvenliği veya Proje
Paketi privacy uygunluğu anlamına gelmez.

Bütün verifier'lar read-only'dir: source revision/event/scope/publication
değiştirmez, eksik kaydı üretmez, bozuk checksum'ı güncellemez ve artifact'ı
yerinde onarmaz.

## 10. Backward compatibility ve fail-closed davranış

- Backup format `1` ve schema `(2, 3, 4)` desteği korunur. Eski schema yalnız
  isolated temporary Restore hedefinde current schema'ya migrate edilir.
- Backup v1 manifest'i yeni aile ayrımı gerekçesiyle genişletilmez veya yeniden
  yorumlanmaz.
- Günlük Çıktı v1 entry/manifest/observation-only sözleşmesi korunur.
- Hafızayı İndir ve Proje Paketi için tarihsel format yoktur; ilk implementation
  kendi namespace'inde v1 başlatır.
- Gelecekte reader birden fazla version destekliyorsa her version için ayrı
  strict parser/validator kullanır. Parser fallback, alan tahmini veya unknown
  field'i sessiz kabul etme yoktur.
- Bir artifact'ın ailesi kesin belirlenemiyorsa veya discriminator ile dosya
  sözleşmesi çelişiyorsa reddedilir.
- Bir aileden diğerine conversion, source'u yeniden okuyup hedef ailenin bütün
  guard'larını çalıştıran açık yeni üretimdir; manifest rename değildir.

## 11. Encryption ve key recovery yönü

Bugünkü gerçek:

- Backup v1 şifreli değildir.
- Günlük Çıktı v1 şifreli değildir.
- Hafızayı İndir ve Proje Paketi henüz uygulanmamıştır.

Bu ADR mevcut artifact'ları şifrelemez. Gelecekte encryption eklendiğinde yön:

| Aile | Gelecekteki politika |
| --- | --- |
| Backup | Yeni encrypted format/envelope için zorunlu; felaket kurtarma anahtarı üretim anında doğrulanır |
| Hafızayı İndir | Bütün private hafızayı taşıdığı için yeni standart artifact'ta zorunlu encrypted outer envelope |
| Proje Paketi | Teslim kanalına göre opsiyonel; encryption seçimi ve recipient/key yöntemi manifest/envelope sözleşmesinde açık |
| Günlük Çıktı | Mevcut v1 değişmez; future encrypted envelope opsiyonel ve ayrı version/Issue ister |

Encryption outer envelope içindeki canonical manifest/payload anlamını
değiştirmez; algorithm, KDF, nonce, authenticated metadata ve envelope version
ayrı executable sözleşmeyle seçilir.

Key recovery sorumluluğu ayrı implementation Issue'sudur. Minimum yön:

- CSE kayıp anahtarı sessizce yeniden üretebileceğini iddia etmez;
- Backup ve Hafızayı İndir için owner'a recovery material verilir ve artifact
  final olmadan decrypt/verify testi yapılır;
- owner recovery material'ı data root'tan ayrı güvenli yerde saklar;
- Proje Paketi recipient anahtar/parola paylaşımı artifact kanalından ayrı
  yapılır;
- secret, private içerik veya tam dosya adı manifest, log, diagnostic ve hata
  mesajına sızdırılmaz.

## 12. Kullanıcı dili

Bağlayıcı kullanıcı terimleri:

| Terim | Anlam |
| --- | --- |
| **Backup** | Bütün CSE verisini felaket kurtarma için taşıyan artifact |
| **Backup'ı Doğrula** | Backup manifest, bütünlük ve Restore güvenlik kapısı |
| **Restore** | Doğrulanmış Backup'ı yalnız yeni hedefte çalışabilir data root'a dönüştürme |
| **Hafızayı İndir** | Owner'ın bütün Hafıza'sının okunabilir kişisel arşivi |
| **Proje Paketi** | Seçilen tek projenin paylaşılabilir, uygun ve seçilmiş çıktısı |
| **Günlük Çıktı** | Belirli günün dar operasyonel saha çıktısı |
| **Manifest** | Artifact kimliği, kapsamı, entry'leri ve doğrulama metadata'sı |
| **Format Sürümü** | Yalnız ilgili çıktı ailesinin şema/okuyucu sözleşmesi |
| **Bütünlük Doğrulaması** | Entry/path/size/checksum ve aileye özgü tutarlılık kontrolleri |

Yeni UI, ADR ve Issue metinlerinde aşağıdaki karışık terimler kullanılmaz:

- “Devir paketi”;
- “handover backup”;
- “tam proje yedeği”.

Tarihsel belgelerde bu ifadeler bulunabilir; yeni ürün anlamı oluşturmaz.

## 13. Reddedilen alternatifler

### Tek ZIP ve tek global format version

Reddedildi. Restore, kişisel arşiv ve paylaşım uygunluğu aynı güvenlik iddiası
değildir; bir ailenin değişimi diğerlerini gereksiz yere kırar.

### Projeye göre filtrelenmiş Backup

Reddedildi. Eksik felaket kurtarma artifact'ı “Backup” adıyla güvenli değildir.

### Hafızayı İndir'i Restore girdisi yapmak

Reddedildi. Okunabilir veri arşivi, database constraint/migration ve application
state yeniden kurma garantisi taşımaz.

### `project_id` dolu bütün kayıtları Proje Paketi'ne almak

Reddedildi. ADR-0001'e göre project bağlantısı scope değildir; private veri
sızıntısı oluşturur.

### MemoryIndex satırlarını doğrudan resmî payload yapmak

Reddedildi. ADR-0002 read-model'i source of truth değildir ve stale olabilir.

### Private kaydı warning veya otomatik redaction ile dahil etmek

Reddedildi. Warning kalıcı scope dönüşümü değildir; otomatik redaction içerik,
referans ve metadata sızıntısını güvenilir biçimde kanıtlayamaz.

### Bütün ailelerde ortak verifier

Reddedildi. Checksum ortak primitive olabilir; Restore güvenliği, kişisel arşiv
bütünlüğü ve project privacy eligibility farklı sorumluluklardır.

### Bilinmeyen sürümü en yakın parser ile açmak

Reddedildi. Alan anlamı ve privacy guard'ı tahmin edilemez; fail-closed gerekir.

## 14. Executable acceptance matrisi

Sonraki implementation görevleri en az şu kararları test etmelidir:

| Senaryo | Beklenen |
| --- | --- |
| Backup oluştur | Bütün scope, event, archive ve managed attachment'lar; kısmi seçim yok |
| Backup attachment missing/tampered | Artifact final olmaz |
| Backup v1 verify | Exact manifest/entry/checksum/SQLite/count/reconciliation geçer |
| Backup unknown format/schema | Restore öncesi fail-closed |
| Restore mevcut hedefe istenir | Hedef değişmeden reddedilir |
| Restore migration/validation hatası | Partial target aktive olmaz; source/archive değişmez |
| Hafızayı İndir oluştur | Bütün türler ve iki scope açık etiketli; source yeniden okunur |
| Hafızayı İndir attachment eksik | Tam arşiv başarı sayılmaz |
| Hafızayı İndir verify | Manifest/entry/checksum/count/reference geçer; Restore iddiası yok |
| Project-linked private kayıt seçilir | Proje Paketi reddedilir; otomatik scope dönüşümü yok |
| Aynı project ID, farklı scope | Yalnız `scope=project` kabul edilir |
| Farklı projeye ait kayıt/reference/attachment | Proje Paketi fail-closed |
| Archived kayıt varsayılan seçimde | Dışarıda kalır |
| `include_archived=true` | Yalnız doğrulanmış kayıt “Tarihsel Ek” olarak görünür |
| Terminal ama archive olmayan kayıt | Gerçek status etiketiyle seçilebilir; archive sayılmaz |
| Source revision seçimden sonra değişir | Generation preflight stale seçimi reddeder |
| MemoryIndex source ile drift eder | Output source'tan doğrulanmadan üretilmez |
| Proje Paketi artifact verify | Private/başka proje/unknown eligibility işaretinde reddedilir |
| Günlük Çıktı v1 | Mevcut beş entry, manifest ve observation-only içerik korunur |
| Aynı observation verisine private tracking eklenir | Günlük Çıktı byte-identical kalır |
| Yanlış aile verifier'ı çağrılır | Artifact yapısal benzerliğe rağmen reddedilir |
| Duplicate/unsafe/symlink/extra entry | Extraction/aktivasyon öncesi reddedilir |
| Sabit source/clock/id ile iki üretim | Canonical payload ve ZIP byte'ları eşittir |
| Verifier hata verir | Source revision/event/scope/publication ve artifact mutate edilmez |
| Diagnostic/log hata verir | Private içerik, secret ve tam path sızmaz |

## 15. Bu Issue'da uygulanmayanlar

- Production model, service, repository, persistence veya schema;
- migration veya gerçek kullanıcı data backfill'i;
- Backup/daily manifest veya ZIP format değişikliği;
- Hafızayı İndir veya Proje Paketi builder/verifier;
- CLI, web route, template, CSS veya UI;
- `MemoryIndex`, scope field/event veya publication tracking implementation'ı;
- encryption, key generation, escrow, recovery UI veya encrypted envelope;
- import, sync, cloud transfer, auth, role veya tenant;
- yeni executable test.

Her implementation kendi dar Issue'sunda production değişikliği, isolated
fixture, backward compatibility ve privacy regresyon testleriyle yapılacaktır.
