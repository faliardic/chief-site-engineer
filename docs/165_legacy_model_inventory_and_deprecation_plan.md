# Legacy Model Envanteri ve Deprecation Planı

## 1. Kapsam ve yöntem

Bu belge Issue #165 için repository'deki model, helper, repository, runtime,
test, schema/format ve dokümantasyon yüzeylerini read-only olarak inceler.
Amaç kod silmek değil, sonraki dar Issue'ların hangi kanıtla neyi koruyacağını,
dönüştüreceğini, arşivleyeceğini veya ancak hangi kapılardan sonra
silebileceğini belirlemektir.

İnceleme başlangıç noktası `4d31200753d8c24cefbce949849be67d1683b887`
commit'idir. Sınıflandırma bir dosyanın yaşına veya adına göre değil; production
import/call site, test/fixture bağı, schema/migration, backup/export/restore,
kanonik doküman ve uygulanmış replacement kanıtlarının birlikte okunmasıyla
yapılmıştır.

Dört sınıfın exact anlamı:

| Sınıf | Bu belgedeki anlamı |
|---|---|
| Aktif çekirdek | Mevcut runtime, veri güvenliği, uyumluluk veya kabul zincirinin çalışan parçası; korunur. |
| Dönüştürülecek | Mevcut çalışan kaynak korunurken ADR-0001/0002/0003 yönüne ayrı migration/refactor Issue'larıyla taşınacak yüzey. |
| Legacy / arşivlenecek | Bugünkü kanonik ürün yolunun parçası olmayan; fakat test, compatibility veya provenance bağı nedeniyle henüz kaldırılamayan yüzey. |
| Silme adayı | Bütün kaldırma kapıları executable kanıtla geçmiş yüzey. Bu envanterde bu sınıfa giren somut bir symbol/path yoktur. |

Bu karar production davranışı, schema, migration, route, CLI, Backup veya
Günlük Çıktı wire formatını değiştirmez. ADR-0001, ADR-0002 ve ADR-0003 aynen
kalır.

## 2. Repository yüzey haritası

İnceleme anında repository yüzeyi 39 `app/**/*.py`, 29 `tests/**/*.py`, 175
numaralı `docs/` belgesi, 189 numaralı `learning/` belgesi, 52 görev kaydı ve
51 sonuç kaydı içerir. Sayılar tek başına sınıflandırma değildir; tarihsel
yüzeyin büyüklüğünü ve fiziksel silmenin neden ayrı iş olması gerektiğini
gösterir.

| Yüzey | Mevcut rol | Başlıca kanıt |
|---|---|---|
| `app/field_tracking.py` | Follow-up ve routine domain kayıtları/olayları | application, persistence ve test importları |
| `app/application/` | Observation, follow-up ve routine command/query sınırı | web, acceptance ve davranış testleri |
| `app/persistence/` | SQLite schema v4, migration 1-4, repository, mapper ve UoW | runtime ve restore/migration testleri |
| `app/storage/` | Yönetilen attachment path/store ve reconciliation | observation, backup/export ve testler |
| `app/operations/` | Backup v1 ve Günlük Çıktı v1 | ops/web/acceptance ve exact-format testleri |
| `app/web/`, `app/launcher/`, `app/ops/` | Mevcut yerel web, başlatıcı ve bakım CLI'ı | README, launcher ve web/ops testleri |
| `app/acceptance/` | Subprocess uçtan uca kabul koşusu | gerçek application/backup/export/restore/web kullanımı |
| `app/models.py` | Bir aktif observation modeli ile çok sayıda önceki model/helper katmanının karışımı | symbol bazlı import ve test taraması |
| `app/records.py` | Önceki in-memory repository katmanı | yalnız test/doğrudan doküman bağı |
| `app/attachment_integrity.py`, `app/attachments.py` | Önceki attachment doğrulama/path yaklaşımı | doğrudan test bağı; yeni store ile aynı kontrat değil |
| `scripts/` | State status/finalize ile tarihsel podcast source üretimi | test ve provenance dokümanları |
| Kanonik protokoller ve ADR'ler | Güncel ürün/architecture otoritesi | unified source, instructions, ADR-0001/0002/0003 |
| Numaralı docs/learning, tamamlanmış `.cse` kayıtları | Karar ve öğrenme provenance'ı | kanonik kaynaklarca “tarihsel/destekleyici” tanımı |

## 3. Kanıt yaklaşımı

Her inventory satırında şu kanıt soruları uygulandı:

1. Symbol/path başka bir production modülünden import veya çağrılıyor mu?
2. Test, fixture, smoke veya acceptance koşusu doğrudan buna bağlı mı?
3. SQLite schema/migration ya da eski backup/export/restore/parser biçimi buna
   bağlı mı?
4. Güncel kanonik protokol veya ADR bu yüzeyi source/replacement olarak tanıyor
   mu?
5. Replacement yalnız tasarım kararı mı, yoksa çalışan ve executable kabulü
   olan bir uygulama mı?
6. Kaldırma, eski veriyi açmayı, restore etmeyi, export byte'larını veya karar
   provenance'ını bozabilir mi?

Kanıt kaynakları:

- `rg` ile symbol, import, route, terminology ve test referansı taraması;
- `app/persistence/schema.py` ve migration/restore testlerinin okunması;
- `app/operations/backups.py` ile `app/operations/exports.py` consumer ve
  exact-format testlerinin okunması;
- unified source, canonical instructions, ADR-0001, ADR-0002 ve ADR-0003'ün
  authority/replacement sınırları;
- README, ROADMAP, CHANGELOG, karar kayıtları ve `.cse/state` için “ayna,
  otorite değil” ayrımı.

Bir replacement'ın ADR'de tanımlanmış olması “mevcut replacement” sayılmaz.
Örneğin `MemoryIndex` kararlaştırılmıştır ama henüz production uygulaması
değildir. Bu ayrım erken silmeyi önler.

## 4. Dört sınıflı inventory

Aşağıdaki her satır Issue #165'in zorunlu alanlarını taşır. `—` değeri
“bulunamadı/uygulanmadı” anlamındadır; kanıt atlanmış anlamına gelmez.

### Aktif çekirdek

| symbol_or_path | kind | classification | runtime_references | test_references | schema_or_format_dependency | canonical_document_dependency | current_replacement | future_action | removal_gate | risk_if_removed | notes |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Unified source, canonical instructions, `docs/adr/ADR-0001*`, `ADR-0002*`, `ADR-0003*` | Kanonik protokol/ADR | Aktif çekirdek | Sonraki Issue'ların bağlayıcı tasarım sınırı | Doküman-only görevlerde acceptance kaynağı | Scope, read-model ve çıktı ailelerinin future kontratı | GitHub Epic/Issue truth'uyla birlikte en yüksek repository authority | Yok | Yalnız yeni açık ADR/Issue ile supersede et | Yeni kanonik karar, bağlantı ve migration planı | Ürün yönü ve privacy sınırı belirsizleşir | Numaralı eski belgeler bunları override edemez |
| `app/persistence/**` | Schema, migration, repository, mapper, UoW | Aktif çekirdek | Bütün application ve operations zinciri | Persistence, migration, application, web, backup/restore testleri | Schema v4; immutable v1-v4 migration; schema 2/3 restore desteği | ADR'ler source tabloları korur | Yok | Scope ve projection için append-only yeni migration'lar | Bütün canlı consumer'lar taşınmış; desteklenen eski DB/backup restore süresi bitmiş; migration fixtures emekli | Veri kaybı, açılamayan DB/backup, atomicity bozulması | Eski migration “kullanılmıyor” diye silinemez |
| `app/storage/**` | Managed attachment store/path/reconciliation | Aktif çekirdek | Observation, backup, daily export ve web attachment akışı | Attachment, backup, export, web ve restart testleri | Backup/export file inventory ve restore reconciliation | ADR-0003 attachment bütünlüğü | Yok | Scope-aware consumer doğrulamalarında kaynak store olarak kal | Yeni store'a tam veri migration'ı ve backup/restore/export compatibility | Yetim/kayıp dosya veya private veri sızıntısı | UUID tabanlı managed path kanoniktir |
| `app/operations/backups.py` | Felaket kurtarma artifact servisi | Aktif çekirdek | Ops CLI, web, acceptance | Backup, restore, attachment, schema compatibility testleri | Backup format v1 ve restore desteği | ADR-0003 Backup ailesi | Yok | Mevcut v1'i koru; yeni sürümü ayrı format/version ile ekle | Destek süresi, migration ve gerçek v1 fixture restore kabulü sona ermeden yok | Kullanıcının kurtarma zinciri kırılır | Kısmi/project export replacement değildir |
| `app/operations/exports.py` | Günlük Çıktı artifact servisi | Aktif çekirdek | Ops CLI, web, acceptance | Exact manifest/entry, privacy ve byte davranışı testleri | Günlük Çıktı v1 `format_version` wire kontratı | ADR-0003 ayrı Günlük Çıktı ailesi | Yok | V1'i byte-compatible koru; yeni aileleri ayrı uygula | Consumer/parser dönemi kapanmış, fixture ve compatibility kararı belgelenmiş | Dış tüketici kırılması veya private veri karışması | Proje Paketi'nin eski adı değildir |
| `app/launcher/**`, `CSE_Baslat.cmd` | Yerel başlatıcı | Aktif çekirdek | Kullanıcının ana başlatma yolu, `app.web` | Launcher testleri | Data-root ve loopback başlatma davranışı | README operasyon akışı | Yok | Mobil/runtime işi gelene kadar koru | Replacement launcher kurulmuş ve kullanıcı kabulü tamamlanmış | Uygulama başlatılamaz | Root komut dosyası kullanıcı yüzeyidir |
| `app/ops/**` | Bakım CLI'ı | Aktif çekirdek | Backup/verify/restore/export operasyonları | Ops CLI testleri | Backup/export argüman ve exit-code kontratları | README ve operations docs | Yok | Çıktı ailesi komutlarını aile bazında açık tut | Yeni CLI/API feature parity, docs ve exit-code kabulü | Kurtarma/bakım erişimi kaybolur | Kullanıcıya dönük operasyon yüzeyi |
| `app/acceptance/**` | Uçtan uca kabul runner'ı | Aktif çekirdek | Production servislerini subprocess içinde çalıştırır | Acceptance testi bunu çağırır | Backup/export/restore ve route sözleşmelerini birlikte doğrular | Release/Issue completion evidence | Yok | Yeni feature'lar geldikçe acceptance'ı genişlet | Eşdeğer E2E harness bütün senaryoları devralmış | Entegrasyon regresyonları görünmez olur | İç `handoff_path` adı ürün “Proje Paketi” anlamına gelmez |
| README'nin güncel operasyon bölümleri; ROADMAP/CHANGELOG/karar/state'in en üst güncel kesitleri | Güncel doküman/ayna | Aktif çekirdek | Kullanıcı ve geliştirici yönlendirmesi | Doküman kabul kontrolü | Mevcut komut/format/schema görünürlüğü | Kanonik protokollere tabidir; onları override etmez | Yok | Issue kapanışlarında senkron tut | Yeni canonical entry point ve archive index'i | Yanlış çalışma/yanlış aktif Issue algısı | `.cse/state` fact mirror'dır, authority değildir |

### Dönüştürülecek

| symbol_or_path | kind | classification | runtime_references | test_references | schema_or_format_dependency | canonical_document_dependency | current_replacement | future_action | removal_gate | risk_if_removed | notes |
|---|---|---|---|---|---|---|---|---|---|---|---|
| `app/models.py::FieldObservationRecord` | Observation source modeli | Dönüştürülecek | `app.application.observations`, persistence mapper/repository, `app.records` | Model, application, persistence, web, export testleri | `field_observations` source tablosu; export/backup kaynak içeriği | ADR-0001 scope, ADR-0002 RecordRef mapping | Yok | Explicit scope/revision/projection mutation sınırlarını ayrı Issue'da ekle | Yeni source modeli/migration tüm consumer ve eski DB/backup kabulünü geçirir | Observation okuma/yazma ve resmî çıktı kırılır | `app/models.py` dosyasının tamamı legacy değildir |
| `app/field_tracking.py` | Follow-up/routine domain source kayıtları ve olayları | Dönüştürülecek | Application ve persistence | Domain, application, web, backup/export izolasyon testleri | Schema v4 follow-up/routine tabloları ve event history | ADR-0001 compatibility scope; ADR-0002 projection mapping | Yok | Scope snapshot/event ve transactional projection hook'larını ayrı Issue'larda ekle | Replacement aggregate + migration + history + behavior parity | Kişisel takip/rutin hafızası ve event geçmişi kaybolur | Kaynak aggregate'ler tek MemoryIndex tablosuna taşınmaz |
| `app/application/{observations,field_tracking,routines}.py` | Mutation/query servisleri | Dönüştürülecek | Web ve acceptance | Yoğun davranış/rollback/no-op testleri | UoW transaction ve append-only event sınırı | ADR-0001/0002 transactional scope/projection gereksinimi | Yok | Source+event+RecordRef'i aynı transaction'a bağlayan dar değişiklikler | Yeni servisler parity, rollback, stale/no-op ve privacy kabulünü geçirir | Atomicity, revision ve lifecycle davranışı bozulur | Mutation yine source application service'e gider |
| `app/web/**` içindeki observation/follow-up/routine sayfaları ve route'ları | Yerel web UX | Dönüştürülecek | `app.launcher`; kullanıcı runtime'ı | Web, launcher ve acceptance testleri | Mevcut route/deep-link kontratları | ADR-0001 Tek Hafıza; ADR-0002 consumer sınırı | Yok | Mevcut CRUD'ları koruyarak ortak Hafıza liste/search/timeline ekle | Tek Hafıza feature parity, deep-link ve lifecycle kabulü | Kullanıcı mevcut kayıtlarına erişemez | Route silme bu Issue'ın işi değildir |
| `scripts/cse_status.py` | Repository state/status ve finalize aracı | Dönüştürülecek | Manuel maintenance; `.cse` workflow | `tests/test_cse_status.py` | `.cse/state` JSON alanları ve task/result biçimleri | GitHub truth, state yalnız ayna ilkesi | Yok | Read-only diagnosis ile explicit state mutation sorumluluklarını ayır | Yeni araç fixture'ları, exit codes ve state compatibility'yi devralır | Yanlış active issue/safe point raporu | “handoff” kelimesi tarihsel workflow adıdır |

### Legacy / arşivlenecek

| symbol_or_path | kind | classification | runtime_references | test_references | schema_or_format_dependency | canonical_document_dependency | current_replacement | future_action | removal_gate | risk_if_removed | notes |
|---|---|---|---|---|---|---|---|---|---|---|---|
| `app/models.py::{SiteProject, ChecklistItem, TrackingRecord, DailySiteLog, ConcretePour, ConcreteSample, InspectionRequest, NonconformityRecord, MaterialRecord, MeetingRecord, MeetingActionRecord, RFIRecord, SubmittalRecord, DailyReportRecord, ProjectPartyRecord, ContactPersonRecord, SiteLocationRecord, WorkforceRecord, EquipmentRecord, SupplierRecord, SiteNoteRecord, TaskCandidateRecord, ChecklistItemRecord, CheckResultRecord}` | İlk dönem domain/prototip dataclass'ları | Legacy / arşivlenecek | Başka production module call site'ı yok; bazıları `app.records` tarafından kullanılır | `tests/test_models.py`; ilgili kayıtlar `tests/test_records.py` | Eski JSON/example/docs beklentileri; canlı SQLite schema source'u değiller | Numaralı tarihsel docs/learning | Follow-up için `FollowUpItem`; observation için `FieldObservationRecord`; diğerlerinde tam replacement yok | Kullanım bazında küçük migration/retirement Issue'larına böl | Bütün direct imports/tests/fixtures/docs bağı kaldırılmış; gerekli replacement executable; eski veri/parser etkisi açıklanmış | Tarihsel örnek/test kaybı veya eksik replacement yüzünden özellik kaybı | Tek seferde toplu silinmez |
| `app/models.py` NCR candidate/process/history/action/closure sınıfları | Önceki NCR workflow modeli | Legacy / arşivlenecek | Production call site yok | `tests/test_models.py` | Olası serialized örnek/provenance; canlı schema'ya bağlı değil | Eski NCR docs/learning | Uygulanmış güncel NCR source modeli yok | Gelecek observation/action/evidence/outcome tasarımında açıkça map veya retire et | Feature kararı + veri/fixture taraması + executable replacement kabulü | NCR ayrıntı ve audit niyeti kaybolabilir | İsim benzerliği replacement kanıtı değildir |
| `app/models.py::{AttachmentRecord, FileAttachmentRecord, FileType, AttachmentStatus}` | Önceki attachment metadata modeli | Legacy / arşivlenecek | `FileAttachmentRecord`, legacy helper/repository zincirinde kullanılır | Model, records, attachment-integrity testleri | Eski metadata/JSON beklentileri | Tarihsel attachment docs | `app.storage.ManagedAttachmentStore` yalnız mevcut çalışma replacement'ı; exact legacy kontrat replacement'ı değil | Compatibility mapper gerekip gerekmediğini ayrı Issue'da kanıtla | Direct test/import ve eski serialized örnek yok; managed-store migration kabulü var | Attachment metadata veya restore/export ilişkisi kaybı | Store var diye sınıflar hemen silinemez |
| `app/records.py` | In-memory generic/attachment/observation/NCR repository'leri | Legacy / arşivlenecek | Başka production module importu yok | `tests/test_records.py` doğrudan ve geniş davranış bağı | Canlı SQLite değil; fixture davranış kontratı | Tarihsel repository docs/learning | Observation/attachment için SQLite katmanı; NCR için tam replacement yok | Repository ailesi bazında test/provenance retirement Issue'ı | Bütün consumer/test bağı kaldırılmış; NCR gap'i çözülmüş; serialized fixture etkisi yok | Sessiz feature/test coverage kaybı | “In-memory” olması silme izni değildir |
| `app/attachment_integrity.py`, `app/attachments.py` | Önceki attachment integrity export ve canonical path helper'ları | Legacy / arşivlenecek | Production import yok | `tests/test_attachment_integrity.py`, `tests/test_attachment_paths.py` | Eski path/export biçimi olabilir; managed path ile birebir aynı değil | Tarihsel attachment dokümanları | `app/storage/**` mevcut runtime replacement'ı | Eski path/veri örnekleri ve export consumer'ları için compatibility kararı | Test/fixture/docs/parser bağı yok; gerçek örnek migration/reconciliation kabulü var | Eski attachment'ların bulunamaması veya yanlış eşlenmesi | İki path kuralı sessizce karıştırılmaz |
| `app/models.py` record-ID diagnostic, soft-validation, JSON/Markdown formatter/writer zinciri | Önceki diagnostic/export helper ailesi | Legacy / arşivlenecek | Dosya içi helper çağrıları dışında production consumer yok | `tests/test_models.py` içinde geniş direct behavior/regression bağı | Önceki JSON/Markdown çıktı örnekleri | Tarihsel diagnostic docs/learning | ADR-0002 drift diagnostics tasarımı var ama uygulanmış replacement yok | RecordRef diagnostic implementation sonrası explicit mapping/retirement | Yeni diagnostic executable; eski consumer/fixture yok; output compatibility kararı var | Diagnostic görünürlüğü veya parser beklentisi kaybı | `blocked` üretmemesi testlerle sabit; hard validation değildir |
| `app/models.py` generic file writer ve export-result summary/report formatter zinciri | Önceki presentation/export yardımcıları | Legacy / arşivlenecek | Production consumer yok | `tests/test_models.py` direct regression bağı | JSON/Markdown dosya/output örnekleri | Tarihsel export docs/learning | Günlük Çıktı servisi aynı generic kontratın replacement'ı değildir | Artifact ailesi sahipliği belirlenerek retire veya ayrı adapter'a taşı | Direct tests/fixtures/docs ve parser tüketimi yok; family-specific replacement var | Mevcut örnek/consumer kırılması veya ailelerin yeniden karışması | Generic writer yeni artifact ailelerinde tekrar kullanılmamalı |
| `app/models.py` handover QC checklist/formatter zinciri ile `handover.package_*` audit sabitleri | Eski devir/handover sunum sözlüğü | Legacy / arşivlenecek | Production consumer yok | `tests/test_models.py` doğrudan geniş davranış bağı | Önceki JSON/Markdown checklist örnekleri | Tarihsel handover docs; ADR-0003 yeni terimi reddeder | Uygulanmış Proje Paketi verifier'ı yok | Eski zinciri Proje Paketi diye rename etmeden, yeni family verifier'ını ayrı uygula; sonra retire et | Proje Paketi executable acceptance; eski imports/tests/fixtures yok; backward-compat kararı | Yanlış güvence vererek Backup/Proje Paketi sınırını bozma | Rename, güvenli migration değildir |
| `app/models.py::AuditEventRecord` ve target-type/record-ID sabitleri | Önceki generic audit modeli | Legacy / arşivlenecek | Production consumer yok | `tests/test_models.py` | Eski target ID vocabulary/örnekleri | Tarihsel audit docs | Follow-up/routine append-only event tabloları yalnız kısmi replacement | Ortak audit ihtiyacını gelecek source/event tasarımında yeniden değerlendir | Bütün eski target consumer/test/data taranmış; replacement kapsamı tamam | Provenance/audit örnekleri kaybolur | Legacy ID kabulü özellikle test edilir |
| `app/main.py` | İlk smoke entry point'i | Legacy / arşivlenecek | Gerçek launcher bunu kullanmıyor | `tests/test_smoke.py` | Yok | Eski başlangıç docs/learning | `app.launcher` + `CSE_Baslat.cmd` | Smoke testini gerçek launcher health contract'ına taşıyan ayrı küçük Issue | Import/test/docs bağı yok; packaging entry point taranmış | Paket smoke sinyali kaybolur | Küçük olması doğrudan silme izni vermez |
| `scripts/build_notebooklm_podcast_source.py` ve üretilmiş podcast/source provenance'ı | Tarihsel doküman birleştirme aracı | Legacy / arşivlenecek | Production runtime yok | Script testleri | Üretilmiş manifest/source formatı | Kanonik protokoller learning/podcast'ı current authority saymaz | Yok | Son snapshot/checksum ve archive index'iyle dondur veya açıkça retire et | Test/docs/workflow bağı yok; son provenance snapshot erişilebilir | Öğrenme/karar kökeni izlenemez | Üretilmiş metin ürün davranışını override edemez |
| Numaralı `docs/**`, `learning/**`, tamamlanmış `.cse/tasks/**` ve `.cse/results/**`; ROADMAP/CHANGELOG/decision geçmiş bölümleri | Tarihsel karar/öğrenme/task provenance'ı | Legacy / arşivlenecek | Runtime consumer değil | Bazı script/docs kontrolleri referans verebilir | Eski komut, schema, format ve acceptance kanıtları içerir | Unified source/instructions bunları supporting/historical sayar | Kanonik ADR/Issue'lar current karar replacement'ıdır; tarih replacement'ı değildir | Immutable archive index, superseded işareti ve link doğrulaması tasarla | Referans grafiği çıkarılmış; kanonik kararlar korunmuş; yasal/öğrenme ihtiyacı değerlendirilmiş | Karar kökeni, regresyon nedeni ve eğitim içeriği kaybolur | Toplu “eski docs temizliği” yapılmaz |
| `multi-user`, “özel alan”, `handover/devir paketi`, `blocked`, hard-validation ve generic export-helper sözlüğü | Eski/yanıltıcı terminoloji | Legacy / arşivlenecek | Aktif runtime'da `blocked` domain status veya hard validation yok; handover zinciri legacy model helper'larında | Eski davranışı sabitleyen testler vardır | Eski output örnekleri ve audit vocabulary | ADR-0001 owner-only/private-project; ADR-0003 Proje Paketi dili | Yeni kanonik terimler dokümanda mevcut; bazı runtime replacements henüz yok | Önce current yüzeylerden kaldır; historical metni provenance etiketiyle koru; parser/fixture etkisini test et | Current kullanıcı/runtime vocabulary'si temiz; parser/test compatibility kararı verilmiş | Tarihsel alıntı ile aktif ürün sözlüğü karışabilir veya consumer kırılabilir | Teknik `handoff_path` gibi ürün dışı isimler ayrı refactor konusu olabilir |

### Silme adayı

Bu incelemede **doğrulanmış silme adayı sayısı sıfırdır**. Dolayısıyla bir
symbol/path'i yapay biçimde bu sınıfa atayan inventory satırı yoktur. Aşağıdaki
kapı tablosu, en yakın görünen legacy grupların neden henüz aday olmadığını
gösterir:

| İncelenen grup | Geçemediği kapı |
|---|---|
| `app/main.py` | `tests/test_smoke.py` doğrudan import eder. |
| `app/records.py` | `tests/test_records.py` geniş davranış sözleşmesine bağlıdır; NCR replacement'ı eksiktir. |
| Eski attachment helper'ları | Direct test ve olası path/serialized compatibility kararı vardır. |
| Record-ID/export/handover helper zincirleri | `tests/test_models.py` yüzlerce doğrudan regression beklentisi taşır; replacement uygulanmamıştır. |
| Eski migration/restore yüzeyleri | Schema 2/3 → 4 ve Backup v1 restore desteği executable kabulün parçasıdır. |
| Tarihsel docs/learning/task/result | Provenance ve bazı script/reference bağları çıkarılmadan toplu silinemez. |

## 5. Aktif çekirdek

Aktif çekirdeğin merkezi source domain + append-only event + SQLite UoW
zinciridir. Observation, follow-up ve routine mutation'ları application service
üzerinden olur; persistence katmanı transaction ve migration sürekliliğini
sağlar. Managed attachment store, Backup v1 ve Günlük Çıktı v1 bu source
verilerden beslenen ayrı güvenlik/uyumluluk yüzeyleridir.

“Aktif” yalnız son kullanıcı route'u demek değildir. `app/acceptance`, eski
schema restore migration'ları ve exact artifact testleri de production
güvenilirliğinin executable parçasıdır. Bu nedenle çağrı sayısı düşük olan bir
migration veya verifier otomatik olarak legacy sayılmaz.

## 6. Dönüştürülecek yüzeyler ve replacement planları

| Kaynak | Hedef yön | Ayrı executable işin minimum kabulü |
|---|---|---|
| Observation/follow-up/routine source kayıtları | ADR-0001 explicit `private / project` scope | Backfill, revision/event, fail-closed dönüşüm ve restore testleri |
| Application mutation servisleri | ADR-0002 source+event+RecordRef aynı transaction | Commit/rollback, stale/no-op, idempotent upsert ve rebuild parity testleri |
| Ayrı web listeleri | Tek Hafıza consumer'ı | Mevcut CRUD/deep-link korunarak ortak liste, filter, literal search ve timeline |
| Current source tablolar | Rebuild edilebilir MemoryIndex projection | Source-of-truth değişmeden deterministic shadow rebuild ve drift diagnostics |
| `scripts/cse_status.py` | Otorite sınırı açık maintenance araçları | GitHub truth/state mirror ayrımı, backward-compatible read ve açık mutation komutu |

Replacement planı “eski sınıfı yeni ada çevir” değildir. Özellikle legacy
handover QC helper'ı Proje Paketi verifier'ına rename edilemez; ADR-0003'ün
scope, source revalidation, manifest ve privacy kapıları yeni family-specific
implementation ister.

## 7. Legacy provenance politikası

Legacy kod ve dokümanlar üç aşamalı politika izler:

1. **İşaretle:** Current authority ile historical/supporting içerik ayrılır;
   kanonik link eklenir.
2. **Dondur:** Davranış veya format gerekliyse fixture/checksum ve son destek
   sınırı kaydedilir. Tarihsel içerik sessizce yeniden yazılmaz.
3. **Arşivle:** Import/call/test/reference grafiği boşaldıktan ve replacement
   acceptance tamamlandıktan sonra ayrı Issue ile taşıma/silme değerlendirilir.

Learning ve podcast içeriği ürün davranışının current authority'si değildir;
fakat kararların nasıl oluştuğunu açıklayan provenance olabilir. Bu nedenle
“kanonik değil” sonucu “değersiz ve silinebilir” sonucuna çevrilmez.

## 8. Silme adayları ve kapılar

Bir symbol/path ancak aşağıdaki kapıların **tamamını** executable kanıtla
geçerse Silme adayı olabilir:

- production import/call site sıfır;
- test, fixture, smoke ve acceptance bağı sıfır;
- CLI, web, launcher ve runtime bağı sıfır;
- schema, migration ve restore bağı sıfır;
- Backup/export/parser ve backward-compatibility bağı sıfır;
- current canonical docs bağı sıfır;
- çalışan replacement ve kabul testleri mevcut;
- eski veri/backup/fixture üzerinde restore/backward-compatibility etkisi
  açıklanmış;
- removal diff'i ayrı Issue'da, delete/rename listesi ve rollback planıyla
  incelenmiş.

Kapılardan biri “bilinmiyor” ise sonuç fail-closed biçimde Legacy /
arşivlenecek kalır. Issue #165 hiçbir delete, rename veya move yetkisi vermez.

## 9. Schema, Backup, export ve restore riskleri

| Risk yüzeyi | Neden kritik | Deprecation guard |
|---|---|---|
| Migration v1-v4 | Eski SQLite verisini güncel şemaya taşır | Historical migration statement'larını değiştirme/silme; eski fixture migration testi |
| Schema 2/3 restore | Desteklenen eski Backup'ların açılmasını sağlar | Restore support policy bitmeden parser/migration kaldırma |
| Backup v1 | Kullanıcının felaket kurtarma kontratı | Exact manifest, checksum, attachment ve repository verification |
| Günlük Çıktı v1 | Mevcut dış artifact kontratı | `format_version` dahil wire key/entry davranışını koruma |
| Attachment path/inventory | DB ile dosya byte'larını bağlar | Reconciliation ve gerçek eski örnek migration'ı olmadan helper/path kaldırmama |
| Legacy JSON/Markdown helper'ları | Test veya bilinmeyen offline consumer olabilir | Call graph yanında fixture/parser ve docs örneği taraması |
| Gelecek Proje Paketi | Legacy handover helper'ıyla yanlış eşlenebilir | Ayrı namespace, source revalidation ve family-specific verifier |

En büyük hata, “runtime importu yok” kanıtını “uyumluluk bağı yok” diye
yorumlamaktır. Restore parser'ı veya migration yalnız eski veri geldiğinde
çalışabilir; yine de aktif çekirdektir.

## 10. Terminoloji deprecation planı

| Deprecated/ambiguous terim | Kanonik karşılık veya politika | Uygulama sırası |
|---|---|---|
| multi-user / ekip tenant yönü | Owner-only, yerel tek kullanıcı | Önce current docs/UI; tarihsel alıntılar işaretli kalır |
| özel alan | `private` kayıt kapsamı; erişim rolü değildir | ADR-0001 mapping'i uygulandığında source/UI dilini eşle |
| resmî kayıt dünyası | Tek Hafıza içindeki `project` kapsamı | Ayrı uygulama dünyası kurma; filtre/etiket olarak göster |
| handover/devir paketi | Proje Paketi | Legacy helper'ı rename etme; ADR-0003 verifier'ını yeni uygula |
| handover backup / tam proje yedeği | Backup veya Proje Paketi amaca göre | Artifact family adı ve garantisini açık göster |
| `blocked` status | Aktif domain status değildir | Eski soft-validation test/provenance'ında kalabilir; yeni output üretme |
| hard validation | Fail-closed eligibility/verifier veya açık validation | Hangi sınırın mutation mı artifact kabulü mü olduğunu adlandır |
| generic export helper | Günlük Çıktı / Hafızayı İndir / Proje Paketi family-specific servisleri | Ortak writer'ı family guarantee gibi sunma |

Tarihsel belgede geçen deprecated kelime geçmişi doğru aktarıyorsa topluca
değiştirilmez. Current kullanıcı metni ve yeni kod vocabulary'si kanonik dili
kullanır; provenance metni “tarihsel” etiketiyle korunur.

## 11. Neden fiziksel silme yapılmıyor?

Bu Issue'ın ürünü kod değişikliği değil, güvenli karar girdisidir. Doğrudan
test bağı olan bir sınıfı silmek testleri de silerek yeşil hale getirilebilecek
yanlış bir değişikliktir; bu replacement kabulü sağlamaz. Benzer şekilde eski
migration veya format parser'ını silmek güncel testlerin çoğunda görünmeyip
gerçek kullanıcı restore'unda veri kaybı yaratabilir.

Fiziksel silme ayrıca review yüzeyini büyütür ve inventory kararıyla davranış
değişikliğini aynı commit'e karıştırır. Bu nedenle Issue #165 yalnız yetkili
Markdown/state/task/result dosyalarını değiştirir.

## 12. Executable sonraki Issue'lar

Önerilen işler bağımlılık sırasındadır; her biri ayrı kapsam ve acceptance
taşır:

1. **Legacy import/reference scanner:** Inventory satırlarını CI'da read-only
   üreten symbol/test/docs/schema-format referans raporu.
2. **Scope source + migration:** ADR-0001 alanları, backfill, event/revision ve
   eski DB/Backup restore kabulü.
3. **MemoryIndex projection:** ADR-0002 schema, transactional upsert, shadow
   rebuild, drift diagnostic ve consumer contract testleri.
4. **Tek Hafıza web dilimi:** Ortak liste/search/timeline; mevcut lifecycle ve
   deep-link parity.
5. **Artifact family implementation'ları:** Hafızayı İndir ve Proje Paketi için
   ADR-0003'e özgü ayrı builder/verifier ve privacy fixture'ları.
6. **Legacy handover/export helper retirement:** Yeni family acceptance sonrası
   direct imports/tests/fixtures envanteri ve compatibility kararı.
7. **In-memory model/repository retirement:** Feature bazında; önce NCR gap'i ve
   eski serialized örnekler açıklanır.
8. **Attachment legacy compatibility audit:** Eski path/metadata örnekleri,
   migration/reconciliation ve rollback acceptance.
9. **Historical docs archive index:** Kanonik/superseded/provenance link grafiği;
   toplu silme olmadan dondurma politikası.
10. **Gerçek deletion Issue'ı:** Yalnız bütün kapıları geçen açık allowlist,
    delete/rename listesi, restore/compatibility kanıtı ve rollback planı.

## 13. Belirsizlikler ve açık sorular

- Repository dışında eski JSON/Markdown helper çıktılarını tüketen kişisel bir
  script var mı? Repo taraması bunu kanıtlayamaz.
- Eski attachment path'leriyle üretilmiş gerçek kullanıcı verisi var mı?
  `CSE_DATA_ROOT` bu Issue'da kasıtlı olarak okunmadı.
- Legacy NCR modelinin gelecekteki ürün karşılığı observation/action/evidence
  bileşimi mi, yoksa ayrı aggregate mi olacak?
- Backup v1 ve Günlük Çıktı v1 için zaman bazlı destek sonu olacak mı, yoksa
  süresiz reader desteği mi korunacak?
- Numaralı docs/learning için fiziksel archive dizini gerekli mi, yoksa index ve
  immutable provenance etiketi yeterli mi?
- `scripts/cse_status.py --finalize-state` uzun vadede tutulacak mı, yoksa state
  yalnız otomatik GitHub mirror'ından mı üretilecek?
- Teknik test/IPC bağlamındaki `handoff_path` gibi adlar kullanıcı terminolojisi
  migration'ına dahil edilmeli mi?

Bu soruların hiçbiri Issue #165'te tahminle kapatılmaz. İlgili executable Issue,
repo dışı consumer veya gerçek veri incelemesi için ayrıca açık yetki almalıdır.
