# Roadmap

## Güncel Ürün Sırası

0. [x] Tek kullanıcılı kişisel saha asistanı yönünü kanonikleştir — Issue #103.
1. [x] Saha Takibi transactional application service ve 7 günlük lazy backfill. Follow-up çekirdek dilimi Issue #109, waiting/terminal yaşam döngüsü Issue #111, observation link/conversion Issue #112 ve routine/backfill dilimi Issue #115 ile uygulandı.
2. [x] Backup/restore compatibility ve resmî export izolasyonu — Issue #117 ile gerçek schema 2/3→4 restore, schema 4 tracking round-trip ve byte-identical resmî export regresyonları uygulandı.
2A. [x] İlk test edilebilir PC Saha Takibi web yüzeyi — Issue #119 / PR #126 ile merge edildi. Bugün, Unutma Kutusu, hızlı yakalama, follow-up yaşam döngüsü, rutinler, occurrence işlemleri, restart kalıcılığı ve resmî export izolasyonu doğrulandı.
3. [ ] Issue #127 uygulanabilir geliştirme programını bağımlılık sırasıyla yürüt.

Bağlayıcı ürün Epic'i #105, Saha Takibi Epic'i #97 ve uygulanabilir yürütme programı Issue #127'dir. Issue #141 ve #143 repository/workflow truth işlerinden sonra Issue #145 / PR #146 Tek Hafıza ve kayıt kapsamı, Issue #147 / PR #159 `MemoryIndex / RecordRef` read-model, Issue #148 / PR #164 Backup / Hafızayı İndir / Proje Paketi ayrım ADR'si, Issue #165 / PR #166 legacy model envanteri ve Issue #167 / PR #168 saha kabul protokolü merge edilmiştir. Faz 0'ın tek aktif işi Issue #169 owner-only güvenlik ve veri sahipliği tehdit modelidir; production davranışı değiştirmez. Açık faz Epic'leri aynı anda aktif production işleri değildir; aynı anda yalnız bir production implementation görevi yürütülür.

## Issue #127 Faz Haritası

- [ ] Issue #128 — Faz 0: repository truth, ADR'ler ve yürütme zemini.
- [ ] Issue #129 — Faz 1: Güvenilir Hafıza yaşam döngüsü ve ortak kayıt görünümü.
- [ ] Issue #130 — Faz 2: Tam Hafıza İndirme, doğrulama ve kurtarma standardı.
- [ ] Issue #131 — Faz 3: mobil runtime, offline güvenilirlik ve gerçek saha pilotları.
- [ ] Issue #132 — Faz 4: şantiye komuta merkezi, ortak timeline ve haftalık özet.
- [ ] Issue #133 — Faz 5: doküman, rapor ve çizim merkezi.
- [ ] Issue #134 — Faz 6: Şantiye İş Planı Lite ve iki haftalık lookahead.
- [ ] Issue #135 — Faz 7: İş Paketi Motoru ve Beton İş Paketi.
- [ ] Issue #136 — Faz 8: saha hesap araçları ve yönlendirmeli manuel metraj.
- [ ] Issue #137 — Faz 9: PDF-first çizim destekli metraj ve doğrulama.
- [ ] Issue #138 — Faz 10: haricî uygulama, cihaz paylaşımı ve güvenli içe aktarma bağlantıları.
- [ ] Issue #139 — Faz 11: deterministik arama, semantik geri çağırma ve kaynaklı AI.
- [ ] Issue #140 — Faz 12: owner-only güvenlik, bakım, güncelleme ve ürünleştirme.

Issue #141, Faz 0'ın ilk dar repository truth görevi olarak tamamlandı. Issue #145 / PR #146 Tek Hafıza UX ile `private | project` kayıt kapsamını, Issue #147 / PR #159 ortak `MemoryIndex / RecordRef` read-model sözleşmesini, Issue #148 / PR #164 Backup / Hafızayı İndir / Proje Paketi çıktı aileleriyle mevcut Günlük Çıktı sınırını, Issue #165 / PR #166 legacy kaldırma kapılarını, Issue #167 / PR #168 ise gerçek pilotu yürütmeden 7/30 günlük saha kabul sözleşmesini kesinleştirdi. Aktif Issue #169 mevcut MVP'nin owner-only güvenlik ve veri sahipliği sınırlarını, riskleri ve Faz 12 executable kapılarını bağlar.

## Issue 148 - Backup, Hafızayı İndir ve Proje Paketi Ayrım ADR'si

- [x] Backup eksiksiz felaket kurtarma ve yalnız desteklenen format/schema için doğrulanmış Restore ailesi olarak sabitlendi; filtreli/kısmi Backup reddedildi.
- [x] Hafızayı İndir bütün owner hafızasının iki scope, bütün türler, event geçmişi ve attachment inventory/dosyalarını taşıyan okunabilir kişisel arşivi olarak tanımlandı; Restore garantisi verilmedi.
- [x] Proje Paketi yalnız seçilen tek projedeki source'tan yeniden doğrulanmış `scope=project` kayıtlar için paylaşılabilir teslim ailesi olarak sınırlandı.
- [x] Project ID'nin tek başına yetmediği; scope, revision, archive, status, reference, attachment ve publication guard'larının fail-closed çalışacağı kaydedildi.
- [x] Mevcut tarih/observation odaklı Günlük Çıktı v1'in daha geniş seçilmiş Proje Paketi'nden ayrı kaldığı ve private tracking byte-identical izolasyonunun değişmediği kesinleştirildi.
- [x] `backup_format_version`, `memory_download_format_version`, `project_package_format_version` ve `daily_export_format_version` bağımsız namespace'leri kabul edildi; mevcut wire anahtarları değiştirilmedi.
- [x] Manifest minimumları, deterministic entry sırası, uncompressed byte SHA-256/size, strict path/entry doğrulaması ve backward compatibility/fail-closed kuralları tanımlandı.
- [x] Backup, Hafızayı İndir ve Proje Paketi verifier sorumlulukları ayrıldı; source mutation, repair veya scope/publication değişikliği yasaklandı.
- [x] Future encryption yönü ve key recovery sorumluluğu aile bazında kaydedildi; implementation ayrı Issue'ya bırakıldı.
- [x] Production kodu, test, schema, migration, persistence, UI, route, CLI, backup/export formatı ve gerçek kullanıcı verisi değiştirilmedi.

## Issue 147 - MemoryIndex / RecordRef Read-Model ADR'si

- [x] Source of truth domain aggregate + append-only event history olarak korundu; read-model source mutation ve sessiz repair yapamaz.
- [x] Composite `(record_type, source_id)` anahtarı ve deterministic `record_ref_id` formatı kabul edildi.
- [x] İlk type allowlist'i observation, follow-up ve routine occurrence ile sınırlandı.
- [x] Ortak alan sözleşmesi; normalized status + `status_detail`, importance, archive/terminal, title/search text, deep link, source fingerprint ve projection version ile kesinleştirildi.
- [x] Üç kaynak türü için occurred/created/updated zamanları, scope/project, status, önem, archive, title/search ve deep-link mapping'i kaydedildi.
- [x] Transactional source+event+idempotent upsert ile explicit rebuild'i birleştiren hybrid strateji seçildi.
- [x] Deterministic source-ID taraması, shadow generation, atomik aktivasyon ve başarısızlık/stale görünürlüğü tanımlandı.
- [x] Hafıza, literal arama, timeline, dashboard, haftalık özet, Hafızayı İndir inventory ve diagnostic consumer sınırları çizildi.
- [x] Private kayıtların project bağlantısından scope inference yapılmadan, resmî çıktılarda source üzerinden fail-closed yeniden doğrulanması zorunlu tutuldu.
- [x] Production kodu, test, schema, migration, persistence, UI, backup/export formatı ve gerçek kullanıcı verisi değiştirilmedi.

## Issue 145 - Tek Hafıza ve Kayıt Kapsamı ADR'si

- [x] Kullanıcı için ayrı kişisel/resmî uygulama dünyaları yerine tek **Hafıza** deneyimi kararlaştırıldı.
- [x] Kayıt türü, kapsam ve proje bağlantısı birbirinden ayrıldı.
- [x] `private | project` erişim rolü değil resmî/proje çıktısı uygunluğu olarak tanımlandı.
- [x] Mevcut observation `project`; follow-up, routine template ve routine occurrence `private` başlangıç/backfill mapping'i kesinleştirildi.
- [x] Project atama, observation link'i, AI ve routine işleminin sessiz kapsam dönüşümü yapmayacağı kaydedildi.
- [x] `private -> project` için açık kullanıcı işlemi, revision ve append-only event; `project -> private` için kayıt türüne ve publication/reference kanıtına bağlı fail-closed sınır seçildi.
- [x] Backup bütün kapsamları; Hafızayı İndir bütün hafızayı; Proje Paketi/günlük/rapor yalnız ilgili `project` kapsamını taşıyacak şekilde ayrıldı.
- [x] Private kaydın resmî/proje çıktısına doğrudan seçimi yasaklandı; önce denetlenebilir kapsam dönüşümü zorunlu tutuldu.
- [x] Migration, geriye uyumluluk, güvenlik, terminoloji, reddedilen alternatifler ve executable acceptance matrisi `docs/adr/ADR-0001-single-memory-and-record-scope.md` içinde kaydedildi.
- [x] Production kodu, test, schema, migration, template, CSS, backup ve daily export formatı değiştirilmedi.

## Mobil Saha Pilotu Öncesi Minimum Kâğıdı Bırakma Kapsamı

İlk gerçek saha pilotundan önce aynı mobil-first ürün diliminde:

- `+ Yakala` / `+ Unutma`;
- Bugün / Şimdi ilgilen / Geciken;
- Dönüş bekliyorum / tekrar kontrol;
- rutinler;
- fotoğraf veya dosya ekleme;
- minimum hızlı hesap şeridi;
- günlük zaman çizelgesi ve düzenlenebilir taslak;
- arama;
- backup durumu/görünürlüğü.

Gelişmiş hesap defteri ve immutable günlük yayınlama/revizyon zinciri, Issue #127 programındaki ilgili sonraki fazlarda kalır; minimum hesap ve günlük taslağı ise mobil saha pilotu öncesi bütünleşik ürün kabulinin parçasıdır.

## Issue 169 - Owner-only Güvenlik ve Veri Sahipliği Tehdit Modeli

- [x] Mevcut MVP; tek kullanıcı, Windows hesabı dayanaklı, loopback-default,
  auth/app-lock/TLS/encryption içermeyen gerçek posture ile tanımlandı.
- [x] SQLite/event, managed attachment, data root, artifact, scope, browser,
  log, repository/release, pilot ve future MemoryIndex varlıkları CIA,
  source-of-truth ve recovery yolu ile envanterlendi.
- [x] Uygulama/SQLite, attachment, browser/local web, loopback/LAN/public,
  Windows hesabı, removable disk, projection, scope/output, GitHub/update ve
  pilot içerik sınırları on bir trust boundary olarak bağlandı.
- [x] Yirmi bir threat scenario; on yedi zorunlu alan, likelihood/impact,
  `low | medium | high | critical` severity ve safety override ile yazıldı.
- [x] Critical/high riskler current control, açık gap, detection, immediate
  response, future executable Issue anahtarı ve acceptance evidence ile eşlendi.
- [x] Veri sahipliği, output confidentiality, plain Backup/Hafızayı İndir,
  source-vs-projection ve uninstall/update veri koruma sözleşmeleri kaydedildi.
- [x] Confirmed data loss/corruption, privacy leakage, public/LAN exposure,
  verify/Restore, attachment ve release integrity failure stop kriteri oldu.
- [x] App lock/session, encrypted artifact, secure LAN, diagnostics, logs,
  signed update, supply chain ve recovery drill işleri Faz 12 kapılarına ayrıldı.
- [x] Hiçbir auth, encryption, network control, security test veya production
  davranışı uygulanmış gibi gösterilmedi; gerçek network exposure testi yapılmadı.

## Issue 167 - Saha Kabul Metrikleri ve Pilot Protokolü

- [x] Kayıt açma ve doğru kaydı geri bulma süreleri exact başlangıç/bitiş, median, nearest-rank p90, failure rate ve minimum sample ile tanımlandı.
- [x] Veri kaybı, missed follow-up, attachment/hash, Backup verify, clean Restore, haricî araca dönüş, scope/privacy sızıntısı ve ölçüm bütünlüğü metrikleri bağlayıcı alan sözleşmesiyle yazıldı.
- [x] Performance ölçümleri günlük sınırlı sample; safety/privacy/integrity olayları eksiksiz census olarak ayrıldı.
- [x] Gün 0 preflight, 7 ardışık günlük ilk pilot ve 30 ardışık günlük doğrulama pilotu tekrarlanabilir adımlara bağlandı.
- [x] Günlük ve summary şablonları source UUID, gerçek kayıt gövdesi, proje/kişi, attachment path/hash, screenshot ve ham mesaj toplamadan kullanılabilir hazırlandı.
- [x] Suspected veri kaybı/privacy/integrity olayında stop; confirmed safety blocker'da yeni revalidation window ve owner restart kararı zorunlu tutuldu.
- [x] 7 günlük `PASS_TO_30_DAY` ile 30 günlük Faz 1 gate'leri safety-first sırada tanımlandı; `INSUFFICIENT_EVIDENCE` PASS sayılmadı.
- [x] Hedeflerin ilk kabul eşikleri olduğu, Issue #167'nin gerçek pilot yürütmediği ve sonraki executable 7 günlük pilotun ayrı Issue gerektirdiği kaydedildi.

## Issue 165 - Legacy Model Envanteri ve Deprecation Planı

- [x] Repository model, helper, repository, runtime, test, schema/format ve dokümantasyon yüzeyi kanıta dayalı tarandı.
- [x] Her inventory satırı `Aktif çekirdek`, `Dönüştürülecek`, `Legacy / arşivlenecek` veya `Silme adayı` sınıfına bağlandı.
- [x] `app/models.py` dosya olarak topluca etiketlenmedi; aktif `FieldObservationRecord` ile legacy prototip/helper kümeleri symbol/section seviyesinde ayrıldı.
- [x] SQLite migration/restore, Backup v1, Günlük Çıktı v1, managed attachment, launcher/ops/acceptance yüzeyleri compatibility dahil aktif çekirdek kabul edildi.
- [x] Observation/follow-up/routine source/application/web yüzeyleri, ADR-0001/0002 yönüne kontrollü taşınacak çalışan kaynaklar olarak `Dönüştürülecek` sınıfına alındı.
- [x] Eski modeller, in-memory repository'ler, attachment helper'ları, record-ID/export/handover zincirleri ve tarihsel docs/learning kayıtları bağımlılıkları nedeniyle `Legacy / arşivlenecek` sınıfında tutuldu.
- [x] Bütün olası gruplar en az bir runtime, test, fixture, compatibility, provenance veya eksik replacement kapısına takıldığı için doğrulanmış `Silme adayı` sayısı sıfır olarak kaydedildi.
- [x] Deprecation terminolojisi ve executable sonraki Issue sırası belirlendi; fiziksel silme, rename, import taşıma veya test kaldırma yapılmadı.

## Güncel Doğrulanmış Güvenli Nokta

Issue #165, PR #166 ile merge edildi. `master` üzerindeki doğrulanmış merge commit'i:

```text
cb344aded8d0b0d4f5ff340f08393f6dca06971a
```

Issue #165'in local full-suite kanıtı `983 passed, 7 skipped` sonucudur. Issue #167 bu commit'ten başlayan documentation/state-only pilot-protocol işidir; merge edilene kadar current safe point'i ilerletmez.

## Tarihsel Roadmap Kaydı

Aşağıdaki uzun adım günlüğü proje karar geçmişidir. Eski “güncel”, “aktif” veya “henüz yok” ifadeleri yazıldıkları dönemin snapshot'ıdır; bugünkü repository durumunu belirlemez.

Adim 127'de README, ROADMAP, CHANGELOG, proje kararlari, ZIP repo politikasi, satir sonu tercihi, test sonucu ve diff kontrolu guvenli nokta icin guncellendi.

Adim 128'de `FileAttachmentRecord` required metadata validation guclendirildi.

Adim 129-131 araliginda audit `target_record_id` hard validation eklenmeden once record ID envanteri, central record ID contract ve mapping helper planlari hazirlandi.

Adim 132'de hard validation eklenmeden record ID constants ve bilgi donen target type mapping helperlari eklendi.

Adim 133'te bu helper API'sinin validation fonksiyonu gibi kullanilmayacagi ve test ornek standardizasyonunun ayri adimlarla ilerleyecegi dokumante edildi.

Adim 134'te record ID soft validation'in yalnizca diagnostic / uyari katmani olarak planlanacagi ve hard validation'a henuz gecilmeyecegi belgelendi.

Adim 135'te record ID diagnostic helper'in dis kalite kontrol / raporlama katmani icin nasil tasarlanacagi planlandi; constructor veya hard validation kapisi olarak kullanilmayacagi netlestirildi.

Adim 136'da `diagnose_record_id_for_target_type` helper'i eklendi; helper canonical, legacy, prefix disi ve helper giris hatasi durumlari icin diagnostic dict dondurur, fakat veri reddetmez.

Podcast 022'de Adim 132-136 araligi NotebookLM icin ozetlendi; record ID mapping, helper API siniri, soft validation, diagnostic helper ve hard validation ertelemesi dokumante edildi.

Adim 137'de `diagnose_record_id_for_target_type` helper'inin nerede kullanilabilecegi ve nerede kullanilmamasi gerektigi belgelendi; helper'in saf diagnostic fonksiyon olarak kalacagi ve hard validation'a baglanmayacagi netlestirildi.

Adim 138'de tekil diagnostic helper'in ileride read-only toplu `build_record_id_diagnostic_report(...)` benzeri rapor helper'ina nasil donusebilecegi planlandi; kayit reddi, veri degisikligi, migration ve hard validation yine kapsam disinda tutuldu.

Adim 139'da olasi diagnostic report helper icin API boundary, saf Python input yaklasimi, output sozlesmesi ve test example matrix planlandi; helper'in read-only ve hard validation disi kalacagi yinelendi.

Adim 140'da `build_record_id_diagnostic_report(records)` helper'i read-only olarak eklendi; toplu diagnostic summary uretir, kayit reddetmez, veri degistirmez ve hard validation'a baglanmaz.

Adim 141'de `build_record_id_diagnostic_report(records)` helper'inin usage boundary, edge case standartlari, severity yorumlama kurallari ve summary/count okuma sinirlari documentation-only olarak belgelendi.

Adim 142'de diagnostic report ciktisinin ileride JSON-ready dict, Markdown summary, handover QC summary ve admin/debug gorunumlerine nasil ayrik format katmanlariyla sunulabilecegi planlandi; export helper implementasyonu yapilmadi.

Adim 143'te `build_record_id_diagnostic_report(...)` ciktisinin ileride kayit reddetmeyen soft validation report layer icin nasil yorumlanabilecegi planlandi; soft validation helper implementasyonu yapilmadi.

Podcast 023'te Adim 137-141 araligi NotebookLM icin ozetlendi; diagnostic helper usage boundary, diagnostic report helper plani, API boundary/test matrix, read-only report helper implementasyonu ve edge case standardization anlatildi.

Adim 144'te olasi `build_record_id_soft_validation_report(...)` helper'i icin API boundary, diagnostic report dict input sozlesmesi, status seviyeleri ve test matrix documentation-only olarak planlandi.

Adim 145'te `build_record_id_soft_validation_report(diagnostic_report)` helper'i read-only olarak eklendi; diagnostic report dict'i `pass` / `review` / `attention` soft validation report'a cevirir, `blocked` uretmez ve hard validation'a baglanmaz.

Adim 146'da soft validation report helper'inin handover QC, audit QC ve export/backup oncesi yorumlama standardi documentation-only olarak belgelendi; helper davranisi degistirilmedi.

Podcast 024'te Adim 142-146 araligi NotebookLM icin ozetlendi; export/format boundary, soft validation report layer, API boundary/test matrix, read-only helper implementasyonu ve handover QC yorumlama siniri anlatildi.

Adim 147'de diagnostic report ve soft validation report ciktilarinin ileride Markdown, JSON-ready dict ve handover QC summary gibi sunum formatlarina nasil donusturulecegi documentation-only olarak planlandi; format helper implementasyonu yapilmadi.

Adim 148'de diagnostic / soft validation format helper katmani icin API boundary, input/output sozlesmesi ve Markdown, JSON-ready dict, handover QC summary test matrix'i documentation-only olarak planlandi; format helper implementasyonu yapilmadi.

Adim 149'da diagnostic / soft validation format helper katmani read-only olarak eklendi; JSON-ready dict ve Markdown string ciktisi uretir, dosya yazmaz, export yapmaz, blocked status uretmez ve hard validation'a baglanmaz.

Adim 150'de Adim 149 format helper'larinin handover QC icinde nasil okunacagi, Markdown/JSON-ready dict kullanim sinirlari ve devir paketini otomatik bloke etmeyen yorum standardi documentation-only olarak belgelendi.

Adim 151'de Adim 149 format helper ciktilarindan ileride JSON/Markdown dosya yazimi, export ve handover package uretimine gecmeden once export/file writing boundary documentation-only olarak belgelendi; helper davranislari degistirilmedi ve export implementasyonu yapilmadi.

Podcast 025'te Adim 147-151 araligi NotebookLM icin ozetlendi; diagnostic / soft validation format helper plani, API boundary/test matrix, JSON-ready dict ve Markdown formatter implementasyonu, handover QC usage boundary ve export/file writing boundary anlatildi.

Adim 152'de ileride eklenebilecek JSON/Markdown export helper'lari icin API boundary, path safety, overwrite policy, encoding/format beklentileri ve test matrix documentation-only olarak planlandi; export helper implementasyonu yapilmadi ve dosya uretilmedi.

Adim 153'te path safety ve overwrite policy detayli olarak belgelendi; explicit output path, relative/absolute path davranisi, allowed output root, parent directory, path traversal, dosya adi/uzantisi, overwrite=False varsayilani, atomic write prensibi ve handover QC export sinirlari documentation-only olarak netlestirildi. Export helper implementasyonu, hard validation, `blocked` status ve Podcast 026 eklenmedi.

Adim 154'te Adim 155 oncesi export helper test matrix finalization documentation-only olarak tamamlandi; JSON/Markdown export helper beklentileri, path safety, overwrite policy, parent directory, unsupported input, hata davranisi, ZIP/yedek/cache dislama, atomic write prensibi ve handover QC export senaryolari test basliklari netlestirildi. Export helper implementasyonu, JSON/Markdown export dosyasi, hard validation, `blocked` status ve Podcast 026 eklenmedi.

Adim 155'te hazir JSON-ready dict ve Markdown string ciktilarini explicit output path'e yazan `write_json_ready_dict_to_file(...)` ve `write_markdown_text_to_file(...)` helperlari eklendi; `.json` / `.md` uzanti siniri, UTF-8, deterministic JSON, `overwrite=False`, optional `allowed_root`, path traversal reddi, missing parent hata davranisi ve non-export area korumasi testlendi. Database/repository/API/GUI/CLI, backup/restore, audit event uretimi, hard validation, `blocked` status ve Podcast 026 eklenmedi.

Adim 156'da Adim 155 file writing helper'larinin kullanim siniri documentation-only olarak belgelendi; JSON-ready dict ve Markdown akislarinda report -> formatter -> file writer ayrimi, `allowed_root`, explicit output path, `overwrite=False`, parent directory olusturmama, path traversal reddi, `exports/` kullanimi ve handover QC export senaryosu anlatildi. Yeni kod/test/export dosyasi, hard validation, `blocked` status ve Podcast 026 eklenmedi.

Podcast 026'da Adim 152-156 araligi NotebookLM icin ozetlendi; export helper boundary, path safety, overwrite policy, test matrix, read-only file writing helper implementasyonu ve usage documentation anlatildi. Podcast 027 olusturulmadi.

Adim 157'de Adim 155 read-only file writing helper'larinin error/result contract siniri documentation-only olarak planlandi; basarida mevcut `Path` donusunun ve hatada standart Python exception davranisinin korunacagi, gelecekte gerekiyorsa ayri result dict wrapper/helper dusunulebilecegi belgelendi. Result contract implementasyonu, yeni kod/test, JSON/Markdown export dosyasi, hard validation, `blocked` status, backup/restore/API/GUI/CLI ve Podcast 027 eklenmedi.

Adim 158'de Adim 157 result contract planinin ileride nasil uygulanabilecegi documentation-only olarak netlestirildi; mevcut exception tabanli helper davranisinin geriye uyumluluk icin korunmasi, result contract icin ayri wrapper/helper katmani, ortak JSON/Markdown result alanlari, path/input/overwrite/IO hata kodlari ve handover QC gorunurlugu belgelendi. Yeni kod/test, result contract implementasyonu, JSON/Markdown export dosyasi, hard validation, `blocked` status, backup/restore/API/GUI/CLI ve Podcast 027 eklenmedi.

Adim 159'da future export helper result contract implementasyonu oncesi test matrix documentation-only olarak planlandi; basari result alanlari, JSON/Markdown input testleri, path safety, overwrite policy, IO/permission, boundary regression ve handover QC test beklentileri netlestirildi. Yeni kod/test, result contract implementasyonu, JSON/Markdown export dosyasi, hard validation, `blocked` status, backup/restore/API/GUI/CLI ve Podcast 027 eklenmedi.

Adim 170'te export wrapper result contract verisini okuyan summary/report helper katmani eklendi. `build_export_result_summary(...)`, `build_export_result_report(...)` ve `format_export_result_summary_as_markdown(...)` helperlari dosya yazmadan, export helper cagirmadan ve path safety tekrar hesaplamadan mevcut result contract'lari okunabilir ozet ve rapora cevirir. Test kapsami 342'den 352'ye yukseldi; hard validation, `blocked` status, backup/restore/API/GUI/CLI, audit event ve export ciktisi eklenmedi.

Adim 171'de Adim 170 helperlarinin kullanim siniri documentation-only olarak belgelendi. Tekil success/failure result contract yorumlama, coklu report toplama, Markdown metin uretimi, handover QC review yorumu ve admin/debug teknik detay ayrimi anlatildi. Kod/test degistirilmedi; export ciktisi, hard validation, `blocked` status, backup/restore/API/GUI/CLI, audit event, commit ve push eklenmedi.

Adim 172'de export result summary/report helperlari icin edge case standardi documentation-only olarak belgelendi. Empty contract, missing/unknown status, missing path/message/detail, unsupported input, empty report list, mixed result list, duplicate path, non-string field ve Markdown fallback davranislari guvenli diagnostic/review yaklasimiyla standardize edildi. Kod/test degistirilmedi; export ciktisi, hard validation, `blocked` status, backup/restore/API/GUI/CLI, audit event, database/repository davranisi, commit ve push eklenmedi.

Adim 173'te Adim 168-172 export result summary/report helper hatti sonrasi follow-up yonu documentation-only olarak planlandi. Mevcut `build_export_result_summary(...)`, `build_export_result_report(...)` ve `format_export_result_summary_as_markdown(...)` helper davranislari korunarak export result report Markdown formatter plani, JSON-ready formatter boundary, combined handover QC gorunumu, test example standardization, unsupported input handling documentation ve wrapper-summary/report iliskisi olasi takip basliklari olarak belgelendi. Adim 174 icin export result report formatter API boundary / test matrix plan onerildi; Adim 174 baslatilmadi. Kod/test/helper davranisi degisikligi, export ciktisi, hard validation, `blocked` status, backup/restore/API/GUI/CLI, Podcast 029, commit ve push eklenmedi.

Adim 174'te future `format_export_result_report_as_markdown(report)` helper'i icin API boundary ve test matrix documentation-only olarak planlandi. Helper'in `build_export_result_report(...)` ciktisi olan dict'i input olarak alip presentation-safe Markdown string dondurmesi; dosya yazmamasi, export uretmemesi, database/repository erisimi yapmamasi, summary/report sonucunu yeniden hesaplamamasi, input mutate etmemesi ve hard validation veya `blocked` status uretmemesi belgelendi. Empty report, all-success, mixed success/failure, missing optional fields, unknown status, path visibility, error message visibility, input immutability, no recomputation, string output, no file writing, low-level `write_*` ve `try_write_*` davranisini koruma test basliklari planlandi. Adim 175 read-only export result report Markdown formatter implementation olarak onerildi; Adim 175 baslatilmadi. Kod/test/helper davranisi degisikligi, export ciktisi, backup/restore/API/GUI/CLI, Podcast 029, commit ve push eklenmedi.

Adim 175'te `format_export_result_report_as_markdown(report)` helper'i read-only olarak eklendi. Helper `build_export_result_report(...)` ciktisi olan dict'i Markdown string'e cevirir; status, count, success/review gorunurlugu, path, error type, technical detail, next action ve overwrite bilgisini sunar. Summary/report sonucunu yeniden hesaplamaz, input'u mutate etmez, dosya yazmaz, export uretmez, hard validation veya `blocked` status uretmez. Existing `build_export_result_report(...)`, `build_export_result_summary(...)`, `format_export_result_summary_as_markdown(...)`, low-level `write_*` ve `try_write_*` wrapper davranislari korunur. Backup/restore/API/GUI/CLI, audit event, database/repository davranisi, export ciktisi, commit ve push eklenmedi.

Adim 176'da `format_export_result_report_as_markdown(report)` helper'inin usage boundary ve edge case standardi documentation-only olarak belgelendi. Helper'in `build_export_result_report(...)` ciktisi olan dict'i presentation-safe Markdown string'e cevirdigi; dosya yazmadigi, export uretmedigi, input'u mutate etmedigi, report sonucunu yeniden hesaplamadigi ve summary/report/write helper davranislarini degistirmedigi netlestirildi. Success-only, failure-only, mixed report, empty item/count, missing/unknown field ve handover/export QC okuma sekli standardize edildi. Kod/test/helper davranisi, hard validation, `blocked` status, API/GUI/CLI, database/repository, audit, backup/restore, export ciktisi, commit ve push eklenmedi.

Adim 177'de `format_export_result_report_as_markdown(report)` helper'i icin test/example standardi guclendirildi. Success-only, failure-only ve empty zero-count Markdown ornekleri; missing optional field fallback davranisi; additional/raw field presentation boundary ve `build_export_result_report(...)` contract regression testleri eklendi. Formatter davranisi genisletilmedi, `app/models.py` degistirilmedi, dosya yazma/export ciktisi/hard validation/`blocked` status/API/GUI/CLI/database-repository/audit/backup-restore eklenmedi.

Adim 178'de `format_export_result_report_as_markdown(report)` helper'inin handover QC surecinde nasil okunacagi documentation-only olarak planlandi. Formatter ciktisinin devir kalite kontrolunde gorunurluk ve okunabilirlik sagladigi, fakat devir paketini otomatik onaylamadigi veya bloke etmedigi netlestirildi. Success-only, failure-only, mixed, empty/unknown/missing field raporlarin insan incelemesine nasil tasinacagi; export review checklist icindeki yeri; yeni santiye sefi gorunurlugu; eski santiye sefinin ozel alani ile resmi export/handover paketinin ayrimi ve future GUI/API/CLI entegrasyonlarinda formatter'in yalniz presentation layer olarak kalmasi belgelendi. Kod/test/helper davranisi, hard validation, `blocked` status, database/repository, audit, backup/restore, export ciktisi, commit ve push eklenmedi.

Adim 179'da `format_export_result_report_as_markdown(report)` helper'i icin downstream integration boundary documentation-only olarak planlandi. Future GUI/API/CLI, handover QC ekrani ve export review akislari bu formatter'i yalniz read-only presentation layer olarak kullanabilir; ancak entegrasyon bu adimda eklenmedi. Downstream consumer'larin mevcut `build_export_result_report(...)` report dict contract'ina bagli kalmasi, formatter'a raw export writer gibi davranmamasi, report building/presentation/human review/validation/export writing/audit/persistence katmanlarini ayri tutmasi belgelendi. Success gorunurlugu otomatik resmi kabul, failure gorunurlugu otomatik bloklama degildir. Kod/test/helper davranisi, GUI/API/CLI, database/repository, audit, backup/restore, export ciktisi, hard validation, `blocked` status, commit ve push eklenmedi.

Adim 180'de Adim 175-179 export result report formatter fazi documentation-only olarak kapatildi. `format_export_result_report_as_markdown(report)` helper'inin `build_export_result_report(...)` ciktisini read-only presentation-safe Markdown'a cevirdigi; dosya yazmadigi, export uretmedigi, input'u mutate etmedigi, report sonucunu yeniden hesaplamadigi ve build/summary/write/try_write helper davranislarini korudugu ozetlendi. Handover QC usage boundary, downstream integration boundary, success/failure/mixed/empty/missing/unknown field okuma standardi ve ara sonrasi guvenli baslangic kosullari belgelendi. Hard validation, `blocked` status, API/GUI/CLI, database/repository, audit, backup/restore, export ciktisi, kod/test/helper degisikligi, commit ve push eklenmedi. Adim 180 sonrasi yeni teknik adima baslanmamalidir.

Podcast 029'da Adim 167-180 araligi NotebookLM icin ozetlendi; wrapper result contract integration boundary'den export result summary/report helper hattina, report formatter API boundary/implementation/usage/test example standardization'a, handover QC ve downstream integration boundary kararlarina ve Adim 180 faz kapanisina kadar olan hat anlatildi. Adim 181, yeni teknik faz, hard validation, `blocked` status, API/GUI/CLI implementation, database/repository erisimi, audit event, backup/restore ve export ciktisi kapsam disinda tutuldu.

Adim 181'de export result summary/report/formatter hattinin handover QC surecinde read-only review checklist'e nasil donusebilecegi documentation-only olarak planlandi. `build_export_result_summary(...)`, `build_export_result_report(...)` ve `format_export_result_report_as_markdown(report)` ciktilarinin insan incelemesine nasil tasinabilecegi; success/failure/mixed/empty/missing/unknown field okumasi; yeni santiye sefi gorunurlugu; eski santiye sefinin ozel alani ile resmi handover/export paketi ayrimi ve checklist'in resmi kabul, otomatik bloklama, audit event, export generation veya hard validation olmadigi belgelendi. Kod/test/helper davranisi, API/GUI/CLI, database/repository, audit, backup/restore, export ciktisi, commit ve push eklenmedi.

Adim 182'de export / handover QC review checklist icin API boundary ve future test matrix documentation-only olarak netlestirildi. Checklist'in read-only QC katmani oldugu, mevcut `build_export_result_summary(...)`, `build_export_result_report(...)` ve `format_export_result_report_as_markdown(report)` ciktilarini insan incelemesine tasiyabilecegi fakat karar verici, hard validation veya `blocked` uretici olmadigi belgelendi. Future test matrix success-only, failure-only, mixed, empty/zero-count, missing optional field, unknown/additional field, input immutability, no file write/export output ve no hard validation/no blocked regression basliklarini kapsayacak sekilde planlandi. Helper/API/GUI/CLI implementasyonu, database/repository, audit, backup/restore, export ciktisi, kod/test/helper davranisi, commit ve push eklenmedi.

Adim 183'te gelecekte yazilabilecek export / handover QC review checklist helper'i icin implementation plan documentation-only olarak hazirlandi. Olasil `build_export_handover_qc_review_checklist(...)` helper adi, structured input contract, JSON-ready output contract, decision/blocking alanlarindan kacinma, success-only/failure-only/mixed/empty/missing/unknown senaryo beklentileri, input immutability, no side effect ve existing summary/report/formatter/write/try_write helper davranislarini koruma ilkeleri belgelendi. Helper implementasyonu, test, API/GUI/CLI, database/repository, audit, backup/restore, export ciktisi, hard validation, `blocked` status, commit ve push eklenmedi.

Adim 184'te `build_export_handover_qc_review_checklist(summary, report)` helper'i read-only olarak eklendi. Helper mevcut `build_export_result_summary(...)` ve `build_export_result_report(...)` ciktilarini JSON-ready handover QC review checklist dict yapisina cevirir; `checklist_type`, gorunurluk `status`, `summary`, `items`, `review_notes`, `is_read_only`, `is_blocking` ve `requires_human_review` alanlarini dondurur. Success-only, failure-only, mixed, empty/zero-count, missing optional field, unknown/additional field, JSON-ready output, item list, input immutability, no file write/no exports output, no generated `blocked` status, no hard validation ve existing helper regression testleri eklendi. Helper input mutate etmez, dosya yazmaz, export uretmez, database/repository erisimi yapmaz, audit event uretmez, API/GUI/CLI veya backup/restore eklemez, devir paketini otomatik onaylamaz veya bloke etmez.

Adim 185'te `build_export_handover_qc_review_checklist(summary, report)` helper'inin usage boundary ve edge case okuma standardi documentation-only olarak belgelendi. Helper'in `build_export_result_summary(...)` ve `build_export_result_report(...)` dict ciktilarini input olarak alip JSON-ready checklist dict dondurdugu; `checklist_type`, `status`, `summary`, `items`, `review_notes`, `is_read_only`, `is_blocking` ve `requires_human_review` alanlarinin handover QC gorunurlugu icin okunacagi netlestirildi. `is_read_only=True`, `is_blocking=False` ve `requires_human_review` otomatik onay, ret, bloklama, hard validation veya `blocked` status degildir. Success-only, failure-only, mixed, empty/zero-count, missing optional field ve unknown/additional field durumlari insan incelemesine destek olacak sekilde standardize edildi. Kod/test/helper davranisi, API/GUI/CLI, database/repository, audit, backup/restore, export ciktisi, hard validation, `blocked` status, commit ve push eklenmedi.

Adim 186'da `build_export_handover_qc_review_checklist(summary, report)` helper'i icin test/example standardi guclendirildi. Top-level checklist contract, summary alan seti, item alan seti, `review_notes` aciklayici siniri, `requires_human_review` alaninin bloklama anlamina gelmemesi, `is_read_only=True`, `is_blocking=False`, generated `blocked` status uretilmemesi ve `format_export_result_summary_as_markdown(...)` regression davranisi testlerle sabitlendi. Helper davranisi genisletilmedi, `app/models.py` degistirilmedi, dosya yazma/export ciktisi/hard validation/`blocked` status/API/GUI/CLI/database-repository/audit/backup-restore eklenmedi.

Adim 187'de `build_export_handover_qc_review_checklist(summary, report)` ciktisinin downstream formatter ve consumer siniri documentation-only olarak planlandi. Checklist output'unun JSON-ready dict olarak kalacagi, ileride Markdown formatter, handover QC ekrani, export review akisi veya GUI/API/CLI consumer tarafindan yalniz presentation/QC visibility icin okunabilecegi belgelendi. Downstream consumer'lar `is_read_only=True`, `is_blocking=False` ve `requires_human_review` alanlarinin non-blocking anlamini korumali; success gorunurlugunu resmi kabul, failure/mixed gorunurlugu otomatik ret veya bloklama olarak yorumlamamalidir. Formatter/API/GUI/CLI implementation, database/repository, audit, backup/restore, export ciktisi, hard validation, `blocked` status, kod/test/helper davranisi, commit ve push eklenmedi.

Adim 188'de `build_export_handover_qc_review_checklist(summary, report)` ciktisinin ileride Markdown veya presentation formatter ile nasil okunabilir rapora donusturulebilecegi documentation-only olarak planlandi. Future formatter'in checklist JSON-ready dict input alip presentation-safe Markdown/string output dondurebilecegi; dosya yazmayacagi, export uretmeyecegi, input'u mutate etmeyecegi, checklist sonucunu yeniden hesaplamayacagi ve helper davranislarini degistirmeyecegi belgelendi. Success-only, failure-only, mixed, empty/zero-count, missing optional field, unknown/additional field, `review_notes`, `is_read_only=True`, `is_blocking=False` ve `requires_human_review` gorunum sinirlari standardize edildi. Formatter implementation, yeni test, API/GUI/CLI, database/repository, audit, backup/restore, export ciktisi, hard validation, `blocked` status, kod/helper davranisi, commit ve push eklenmedi.

Adim 189'da future `format_export_handover_qc_review_checklist_as_markdown(checklist)` benzeri formatter icin API boundary ve test matrix documentation-only olarak netlestirildi. Formatter'in `build_export_handover_qc_review_checklist(summary, report)` ciktisi olan JSON-ready checklist dict'i input alip presentation-safe Markdown/string dondurmesi; dosya yazmamasi, export uretmemesi, input mutate etmemesi, checklist/summary/report sonucunu yeniden hesaplamamasi ve existing helper davranislarini degistirmemesi belgelendi. Future test matrix success-only, failure-only, mixed, empty/zero-count, missing optional field, unknown/additional field, unsupported input, string output, `is_read_only`, `is_blocking=False`, `requires_human_review`, `review_notes`, item okunabilirligi, no file write/export output, no generated `blocked`, no hard validation ve existing helper regression basliklarini kapsayacak sekilde planlandi. Formatter implementation, yeni test, API/GUI/CLI, database/repository, audit, backup/restore, export ciktisi, hard validation, `blocked` status, kod/helper davranisi, commit ve push eklenmedi.

Adim 190'da `format_export_handover_qc_review_checklist_as_markdown(checklist)` helper'i read-only presentation formatter olarak eklendi. Helper `build_export_handover_qc_review_checklist(summary, report)` ciktisi olan JSON-ready checklist dict'i Markdown string'e cevirir; checklist type, status, summary count'lari, `is_read_only`, `is_blocking`, `requires_human_review`, review notes ve item listesini gorunur kilar. Dosya yazmaz, export uretmez, `exports/` altina cikti birakmaz, input'u mutate etmez, checklist/summary/report sonucunu yeniden hesaplamaz, hard validation veya generated `blocked` status uretmez, otomatik kabul/ret/bloklama yapmaz. Success-only, failure-only, mixed, empty/zero-count, missing optional field, unknown/additional field, unsupported input, no file write/export output, no hard validation ve existing helper regression testleri eklendi. API/GUI/CLI, database/repository, audit, backup/restore, commit ve push eklenmedi.

Adim 191'de `format_export_handover_qc_review_checklist_as_markdown(checklist)` helper'i icin usage documentation, example standardization ve edge case yorumlama standardi documentation-only olarak belgelendi. Formatter'in `build_export_handover_qc_review_checklist(...)` JSON-ready checklist dict'ini presentation-safe Markdown string'e cevirdigi; dosya yazmadigi, export uretmedigi, database/repository erisimi yapmadigi, audit event uretmedigi, checklist/summary/report sonucunu yeniden hesaplamadigi ve input'u mutate etmedigi netlestirildi. `is_blocking` karar mekanizmasi degildir; `requires_human_review` yalniz insan inceleme sinyalidir ve hard validation, otomatik ret/bloklama veya generated `blocked` status anlamina gelmez. Success, failure, mixed, empty, missing field, unknown status ve unsupported input yorumlari handover QC review gorunurlugu icin standardize edildi. Kod/test/helper davranisi, export ciktisi, API/GUI/CLI, database/repository, audit, backup/restore, migration, commit ve push eklenmedi.

Adim 192'de `format_export_handover_qc_review_checklist_as_markdown(checklist)` helper'i icin test examples ve regression boundary standardi documentation-only olarak belgelendi. Success, failure, mixed, empty, missing field, unknown status, unsupported input, no mutation, no file/export output, no hard validation, no generated `blocked` status ve existing helper regression orneklerinin hangi davranislari kilitledigi netlestirildi. Formatter'in checklist/summary/report'u yeniden hesaplamamasi, input dict'i mutate etmemesi, dosya yazmamasi, `exports/` altina cikti uretmemesi, `is_blocking` degerini otomatik karara donusturmemesi ve `requires_human_review` alanini yalniz insan inceleme sinyali olarak tutmasi regression boundary olarak kaydedildi. Bu adim yeni test eklemez; future kod/test adimi gerekirse ayri adim olmali ve Extra High reasoning onerilmelidir. Kod/test/helper davranisi, export ciktisi, API/GUI/CLI, database/repository, audit, backup/restore, migration, commit ve push eklenmedi.

Adim 193'te GitHub-native ChatGPT/Codex handoff protokolu eklendi; `.cse/tasks/`, `.cse/results/`, `.cse/templates/`, `.cse/state/project_state.json` ve emergency/offline ZIP siniri repo-native olarak belgelendi.

Adim 194'te read-only repository status komutu eklendi; branch, HEAD, diff check, exports, ZIP ve opsiyonel pytest durumunu raporlar, varsayilan davranista repo mutasyonu yapmaz.

Adim 195'te explicit post-merge state finalization yolu eklendi; merged PR/issue state'i yalniz acik CLI metadata ile `.cse/state/project_state.json` icine yazilir, GitHub state otomatik tahmin edilmez.

Adim 196'da `.github/workflows/pytest.yml` GitHub Actions workflow'u eklendi; PR-to-master ve push-to-master icin `git diff --check` ve `python -m pytest` kosacak sekilde tasarlandi.

Adim 197'de Step 196 merge sonrasi state semantigi latest merged/finalized checkpoint olarak sabitlendi; GitHub runner'in account billing lock nedeniyle startup oncesinde calismamasi dissal CI execution constraint olarak kaydedildi.

Adim 198'de ana proje dokumantasyonu Adim 197 guvenli noktasina gore yeniden senkronize edildi; CI workflow varligi, billing-lock runner siniri, required status checks durumu, 413 test sayisi ve podcast catch-up maddeleri factually kaydedildi.

Adim 199'da Step 181-192 export/handover QC checklist ve Markdown formatter fazi documentation-only olarak kapatildi. `build_export_handover_qc_review_checklist(summary, report)` ve `format_export_handover_qc_review_checklist_as_markdown(checklist)` stable contract'lari, non-blocking semantics ve downstream consumer boundary'leri belgelendi; helper davranisi, test, workflow, API/GUI/CLI, persistence, audit, backup/restore, migration, hard validation, generated `blocked` status, ZIP ve export ciktisi eklenmedi.

Adim 200'de future handover QC screen ve export review presentation consumer icin documentation-only input boundary, view-model contract, fallback display behavior ve regression/test matrix planlandi. Existing checklist helper ve Markdown formatter davranislari korunur; `is_read_only=True`, `is_blocking=False`, `requires_human_review` insan inceleme sinyali, no generated `blocked` status, no automatic acceptance/rejection/blocking ve official-transferable/private-non-transferable separation semantics tekrar sabitlenir. API/GUI/CLI implementation, persistence, audit, backup/restore, migration, hard validation, test/production/workflow degisikligi, ZIP ve export ciktisi eklenmez.

Adim 201'de Podcast 030 documentation-only olarak hazirlandi ve yalniz Adim 196-200 araligini kapsadi. Not; minimal GitHub Actions `pytest` workflow'u, explicit merged-state finalization, billing lock'un external CI execution constraint olarak siniflandirilmasi, roadmap/current checkpoint resynchronization, handover QC checklist phase closure ve downstream presentation consumer contract/test matrix planini NotebookLM-friendly sekilde ozetler. Production code, tests, workflow, required status checks, API/GUI/CLI, persistence, audit, backup/restore, migration, hard validation, generated `blocked` status, ZIP ve export ciktisi eklenmez.

Adim 202'de future handover QC presentation view-model consumer'lari icin canonical examples ve wording standardization documentation-only olarak hazirlandi. Structured source of truth `build_export_handover_qc_review_checklist(summary, report)` ciktisi olarak korunur; optional Markdown yalniz presentation text olarak kalir ve structured truth olarak parse edilmez. Success-only, failure-only, mixed, empty/zero-count, missing optional fields, unknown status/additional fields ve unsupported input fallback ornekleri; status label, human-review indicator, empty state, missing-field fallback, unknown-status visibility ve item next-action wording'i standardize edilir. `is_read_only=True`, `is_blocking=False`, `requires_human_review` insan inceleme sinyali, no generated `blocked` status, no automatic acceptance/rejection/blocking ve official-transferable/private-non-transferable separation semantics korunur. Production code, tests, workflow, required status checks, API/GUI/CLI, persistence, audit, backup/restore, migration, hard validation, ZIP ve export ciktisi eklenmez.

Adim 203'te Issue #21 uyarinca official local working copy protocol documentation-only olarak sabitlendi. `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer` proje dosyasi olusturma, duzenleme, verification, commit ve push icin primary working copy olarak kaydedilir; GitHub synchronized remote ve review surface olarak kalir. `.cse/README.md`, `.cse/templates/task_template.md` ve `.cse/templates/result_template.md` local-first flow, master sync evidence, local branch creation, physical local file existence, local/remote divergence, result reporting ve post-merge sync boundary icin guncellenir. Branch/pull oncesi local status inspection, fast-forward-only master sync, expected master SHA dogrulama, branch divergence, required local verification, exports cleanliness ve ignored ZIP untouched status raporlamasi standardize edilir. Production code, tests, workflow, required status checks, API/GUI/CLI, persistence, audit, backup/restore, migration, hard validation, generated `blocked` status, export output, ZIP mutasyonu, PR creation ve merge behavior eklenmez.

Adim 211'de Podcast 032 documentation-only olarak hazirlandi ve yalniz Adim 206-210 araligini kapsadi. Not; canonical instruction authority, unified project source, FieldObservationRecord contract/model ve FieldObservationRepository baseline baslangicini NotebookLM-friendly sekilde ozetler. Step 211 PR #39 merge commit `26509f35abb0cb706d2a085715310358cf5d2421` ile latest merged/finalized safe point oldu; Podcast 032 latest completed podcast'e donustu ve sonraki dogal podcast araligi Steps 211-215 olarak kaydedildi.

Adim 212'de `FieldObservationRepository` icin `list_by_project_id(project_id)` ve `list_by_status(status)` read-only filtreleri eklendi. Filtreler exact, case-sensitive, trim/normalize/validate etmeyen string karsilastirmasi yapar; insertion order korunur, eslesmeyen degerler `[]` dondurur, her cagri yeni liste uretir ve archived eslesen kayitlar da dahil edilir. Category/location/reported_to/date-time/text-search/active/archive-only/combined filtreler, lifecycle mutation, persistence, attachment integration, reporting/export, API/GUI/CLI, validation ve Step 213 kapsam disinda tutuldu.

Adim 213'te `FieldObservationRepository.update_status(observation_id, new_status)` explicit status mutation davranisi eklendi. Method existing `find_by_id(...)` lookup'ini kullanir, missing id icin `None` dondurur, bulunan stored record'un yalniz `status` alanini degistirir ve ayni record nesnesini dondurur. `closed_at`, `reported_at`, notes, archive state veya baska alan otomatik degismez; status validation/enum/normalization, transition rule, close/reopen helper, persistence, attachment integration, API/GUI/CLI, audit/history/task/NCR/decision generation ve Step 214 eklenmedi.

Adim 214'te `FieldObservationRepository.update_reporting(observation_id, reported_to, reported_at)` explicit reporting-context enrichment davranisi eklendi. Method existing `find_by_id(...)` lookup'ini kullanir, missing id icin `None` dondurur, bulunan stored record'un yalniz `reported_to` ve `reported_at` alanlarini degistirir ve ayni record nesnesini dondurur. Status otomatik `tracking` yapilmaz; current-time generation, contact lookup/normalization, other field updates, reporting history, audit/task/NCR/notification/decision generation, persistence, attachment integration, API/GUI/CLI ve Step 215 eklenmedi.

Adim 215'te `FieldObservationRepository.list_by_location(location)` ve `FieldObservationRepository.list_by_category(category)` exact read-only filtreleri eklendi. Filtreler case-sensitive string equality kullanir, trim/normalize/parse/map/tokenize/validate yapmaz, insertion order'i korur, her cagri yeni liste dondurur, ayni stored record nesnelerini referansla verir ve archived matching kayitlari dislamaz. Structured location lookup, category constants/enums/vocabulary, combined query/filter object, broader filters, field updates, persistence, attachment integration, export/reporting, API/GUI/CLI, Podcast 033 ve Step 216 eklenmedi.

Adim 216'da Steps 211-215 araligi icin Podcast 033 documentation/state artifact'i hazirlandi. Not; Podcast 032 kapanisi, project/status filtreleri, explicit status update, explicit reporting-context update ve location/category filtrelerini NotebookLM-friendly Turkce kaynak olarak ozetler. Bu adim product behavior, production code, executable tests, persistence, attachment integration, export/reporting consumers, API/GUI/CLI, Podcast 034 veya Step 217 eklemez.

Adim 217'de mevcut `FileAttachmentRecord` metadata nesneleri icin minimal bellek ici `FileAttachmentRepository` baseline'i eklendi. Repository `add`, `list_all`, `count` ve `find_by_id` method'larini saglar; exact/case-sensitive duplicate `attachment_id` reddi yapar, insertion order'i korur, her `list_all()` cagrisi icin yeni liste dondurur ve stored metadata record nesnelerini kopyalamaz veya mutate etmez. Related-record filters, FieldObservation-specific attachment linking, physical file operations, persistence, validation, API/GUI/CLI, audit, Podcast 034 ve Step 218 eklenmedi.

Adim 218'de mevcut `FileAttachmentRecord` metadata nesneleri icin `FileAttachmentRepository.list_by_related_record_type(...)` ve `FileAttachmentRepository.list_by_related_record_id(...)` read-only filtreleri eklendi. Filtreler exact, case-sensitive string equality kullanir, trim/normalize/parse/map/validate yapmaz, insertion order'i korur, her cagri yeni liste dondurur, ayni stored record nesnelerini referansla verir ve metadata'yi mutate etmez. Type ve id filtreleri bagimsizdir; combined type+id filter, FieldObservation-specific attachment lookup/linking, physical file operations, persistence, validation, API/GUI/CLI, audit, Podcast 034 ve Step 219 eklenmedi.

Adim 219'da `FieldObservationRecord` ile mevcut `FileAttachmentRecord` metadata kayitlari arasindaki attachment linking contract documentation-only olarak tanimlandi. Bir attachment metadata kaydi yalniz ayni kayit uzerinde `related_record_type == "field_observation"` ve `related_record_id == FieldObservationRecord.observation_id` exact pair kosulu saglanirsa field observation attachment link'i sayilir. Cardinality, ownership, orphan/existence behavior, independent filter read-boundary riski, future `list_by_related_record(...)` ve `list_for_field_observation(...)` sinirlari ve future test matrix belgelendi. Production code, executable tests, combined filter implementation, convenience lookup, physical file operations, persistence, validation, API/GUI/CLI, audit, Podcast 034 ve Step 220 eklenmedi.

Adim 220'de `FileAttachmentRepository.list_by_related_record(related_record_type, related_record_id)` exact combined filtresi eklendi. Method yalniz bellek ici `_records` listesini okur; ayni `FileAttachmentRecord` uzerinde hem `related_record_type` hem `related_record_id` exact, case-sensitive eslesirse record'u dondurur. Partial matches, unknown pairs ve empty repository icin `[]` dondurur; insertion order'i korur, her cagri yeni liste dondurur, stored record nesnelerini kopyalamaz/mutate etmez ve related record existence validation yapmaz. `list_for_field_observation(...)`, physical file operations, persistence, validation, API/GUI/CLI, audit, Podcast 034 ve Step 221 eklenmedi.

Adim 221'de Steps 216-220 araligi icin Podcast 034 documentation/state artifact'i hazirlandi. Not; Podcast 033 kapanisi sonrasi FileAttachmentRepository baseline, independent related-record filters, Field Observation attachment linking contract ve exact combined related-record lookup hattini NotebookLM-friendly Turkce kaynak olarak ozetler. Bu adim production code, executable tests, repository behavior, FieldObservation-specific convenience lookup, automatic attachment creation/linking, referenced observation existence validation, physical file operations, persistence, API/GUI/CLI, export/report consumers, audit/workflow, Podcast 035 veya Step 222 eklemez.

Adim 222'de future `FileAttachmentRepository.list_for_field_observation(observation_id)` helper'i icin API boundary ve future test matrix documentation-only olarak planlandi. Helper'in ileride uygulanirsa `list_by_related_record("field_observation", observation_id)` ile semantic equivalent kalmasi, tercihen existing combined helper'a delegation yapmasi, exact/case-sensitive davranisi korumasi, metadata veya `FieldObservationRecord` mutate etmemesi, `FieldObservationRepository` sorgulamamasi ve referenced observation existence validation yapmamasi belgelendi. Production code, executable tests, repository methods, model fields/behavior, constants/enums/validation, physical file operations, persistence, API/GUI/CLI, export/report consumers, audit/workflow, Podcast 035 ve Step 223 eklenmedi.

Adim 223'te `FileAttachmentRepository.list_for_field_observation(observation_id)` helper'i eklendi. Method yalniz `return self.list_by_related_record("field_observation", observation_id)` delegasyonu yapar; ikinci bir `_records` filtreleme implementasyonu eklemez. Exact, case-sensitive, non-normalizing, validation-free, insertion-order preserving, new-list, same-object ve metadata non-mutation davranislari existing combined helper uzerinden korunur. Focused testler delegation, exact match, partial match rejection, case/whitespace sensitivity, empty/unknown results, new-list behavior, same-object returns, metadata non-mutation, count/order stability, missing observation existence non-validation, combined helper equivalence ve existing filter regression davranislarini dogrular. Model fields, constants/enums, hard validation, FieldObservationRepository methods, automatic attachment creation/linking, physical file operations, persistence, API/GUI/CLI, export/report consumers, audit/workflow, Podcast 035 ve Step 224 eklenmedi.

Adim 160'da mevcut exception tabanli file-writing helper davranisini bozmadan future result contract wrapper API boundary documentation-only olarak planlandi; `write_*` helperlarin korunmasi, olasi `try_write_*` wrapper isimleri, result alanlari, error mapping, geriye uyumluluk ve handover QC gorunurlugu netlestirildi. Yeni kod/test, wrapper implementasyonu, JSON/Markdown export dosyasi, hard validation, `blocked` status, backup/restore/API/GUI/CLI ve Podcast 027 eklenmedi.

Adim 161'de Adim 160 API boundary'sine bagli future result contract wrapper implementation plan documentation-only olarak netlestirildi; `try_write_json_ready_dict_to_file(...)` ve `try_write_markdown_text_to_file(...)` wrapper davranisi, basari/hata result sozlesmesi, error mapping, overwrite/path safety davranisi, geriye uyumluluk ve handover QC gorunurlugu belgelendi. Yeni kod/test, wrapper implementasyonu, JSON/Markdown export dosyasi, hard validation, `blocked` status, backup/restore/API/GUI/CLI ve Podcast 027 eklenmedi.

Adim 162'de future `try_write_json_ready_dict_to_file(...)` ve `try_write_markdown_text_to_file(...)` wrapperlari icin test matrix finalization documentation-only olarak tamamlandi; basari, JSON/Markdown input, path safety, overwrite, error mapping, schema, regression boundary ve handover QC test beklentileri netlestirildi. Yeni kod/test, wrapper implementasyonu, JSON/Markdown export dosyasi, hard validation, `blocked` status, backup/restore/API/GUI/CLI ve Podcast 027 eklenmedi.

Adim 163'te mevcut exception tabanli `write_json_ready_dict_to_file(...)` ve `write_markdown_text_to_file(...)` helperlari korunarak `try_write_json_ready_dict_to_file(...)` ve `try_write_markdown_text_to_file(...)` result contract wrapperlari eklendi. Wrapperlar basari/hata sonucunu sabit dict schema ile raporlar; path safety ve overwrite kararlarini mevcut helperlardan alir. JSON/Markdown export dosyasi, hard validation, `blocked` status, audit event, backup/restore/API/GUI/CLI ve Podcast 027 eklenmedi.

Adim 164'te Adim 163 wrapperlarinin usage boundary'si documentation-only olarak belgelendi; `write_*` exception helperlari ile `try_*` result wrapperlari arasindaki fark, result contract alanlari, error code yorumlari, overwrite/allowed_root kullanimi ve handover QC yorumu netlestirildi. Kod/test degisikligi, export cikti dosyasi, hard validation, `blocked` status, backup/restore/API/GUI/CLI ve Podcast 027 eklenmedi.

Podcast 027'de Adim 157-161 araligi NotebookLM icin ozetlendi; export helper error/result contract planlari, result dict yaklasimi, exception tabanli `write_*` helperlar ile future `try_*` wrapper katmani ayrimi, test matrix/API boundary/implementation plan hazirligi ve handover QC gorunurlugu anlatildi. Adim 162-164 kapsam disinda tutuldu; kod/test/export dosyasi, hard validation, `blocked` status, backup/restore/API/GUI/CLI, audit event, commit veya push eklenmedi.

Adim 165'te Adim 163 wrapper helperlarinin result contract kullanim ornekleri ve boundary/example standardi documentation-only olarak belgelendi; basarili JSON/Markdown yazimlari, invalid path, overwrite, missing parent, serialization, Markdown input, kullanici mesaji ve handover QC yorumlari aciklandi. Kod/test degisikligi, existing test matrix degisikligi, export cikti dosyasi, hard validation, `blocked` status, backup/restore/API/GUI/CLI ve audit event eklenmedi.

Adim 166'da mevcut export helper result contract wrapper davranisi testlerle gorunur hale getirildi; JSON/Markdown success contract ornekleri, invalid path failure contract, input immutability ve dusuk seviye `write_*` helperlarin exception davranisini korudugu regression kapsami eklendi. Production kodu, helper davranisi, repo icinde export cikti dosyasi, hard validation, `blocked` status, backup/restore/API/GUI/CLI ve audit event eklenmedi.

Podcast 028'de Adim 162-166 araligi NotebookLM icin ozetlendi; wrapper test matrix finalization, `try_write_*` result contract wrapper implementation, usage documentation, usage examples ve wrapper contract test gorunurlugu anlatildi. Adim 167-172 kapsam disinda tutuldu; kod/test/export dosyasi, hard validation, `blocked` status, backup/restore/API/GUI/CLI, audit event, commit veya push eklenmedi.

Adim 167'de Adim 166 testleri sonrasi wrapper result contract davranisinin kullanim ve entegrasyon siniri documentation-only olarak belgelendi; handover QC, admin/debug, guvenli export ozeti ve kullanici mesajlari icin yorumlama siniri aciklandi. Kod/test degisikligi, GUI/API/CLI entegrasyonu, backup/restore, audit event, database/repository davranisi, hard validation, `blocked` status ve repo icinde export cikti dosyasi eklenmedi.

Adim 168'de export helper wrapper result contract ciktisindan ileride okunabilir summary/report layer uretilmesi documentation-only olarak planlandi; olasi helper fikirleri, tartisma seviyesindeki summary alanlari, handover QC/admin-debug yorumlari ve future test matrix basliklari belgelendi. Kod/test degisikligi, helper davranisi degisikligi, export cikti dosyasi, hard validation, `blocked` status, backup/restore/API/GUI/CLI, audit event ve database/repository davranisi eklenmedi.

Adim 169'da future export result summary/report layer icin API boundary ve test matrix documentation-only olarak netlestirildi; input'un yalniz wrapper result contract veya contract listesi olmasi, output'un JSON-ready dict/Markdown/Handover QC summary gibi raporlama amacli kalmasi ve no file writing/no hard validation/no blocked status sinirlari belgelendi. Kod/test degisikligi, helper davranisi degisikligi, export cikti dosyasi, backup/restore/API/GUI/CLI, audit event ve database/repository davranisi eklenmedi.

Adim 101'de proje genel kalite, mimari tutarlilik, dokumantasyon butunlugu, test kapsami, roadmap uyumu ve sonraki 20 adim stratejisi acisindan denetlendi.

Adım 101 dönemindeki tarihsel test snapshot'ı:

```text
471 passed
```

Bu tarihsel noktada proje domain model, bellek içi repository, test, dokümantasyon, learning ve NotebookLM podcast notları çekirdeği seviyesindeydi. Sonraki Local Field MVP ve Saha Takibi çalışmaları bu durumu ilerletmiştir.

Bu tarihsel kayıtta CI durumu:

- CI workflow var: `.github/workflows/pytest.yml`.
- Workflow kodu `git diff --check` ve `python -m pytest` kosacak sekilde tanimli.
- Otomatik GitHub Actions execution, account billing/runner-start kisiti nedeniyle manuel olarak devre disidir.
- Yeni push sonrasinda Actions run olusmamasi beklenen davranistir; bu durum pytest failure veya workflow kodu hatasi olarak yorumlanmaz.
- Required status checks devre disidir ve Step 205 bunlari etkinlestirmez.

## Adım 101 Döneminde Henüz Olmayan Üretim Özellikleri

Asagidaki ozellikler henuz eklenmedi:

- Database yok.
- Gercek upload servisi yok.
- API yok.
- GUI yok.
- Auth / kullanici / rol / yetki sistemi yok.
- Deployment yok.
- JSON veya SQLite persistence yok.
- Gercek dosya kopyalama, silme veya tasima yok.
- Thumbnail, preview, video oynatma veya streaming yok.

Bu sinir bilincli olarak korunuyor. Once model, test, dokumantasyon ve karar hatti netlestiriliyor.

## Tamamlanan Ana Fazlar - Adim 001-080

### Faz 001-020 - Temel Santiye Model Cekirdegi

- [x] Adim 001-004 - Repo disiplini, cekirdek modeller, gunluk saha kaydi ve basit bellek ici listeleme.
- [x] Adim 005-010 - Beton dokum, yapi denetim, uygunsuzluk, ek dosya, malzeme ve toplanti/aksiyon modelleri.
- [x] Adim 011-020 - RFI/submittal, gunluk rapor, proje tarafi, lokasyon, ekip, ekipman, tedarikci, saha notu, gorev adayi ve kontrol maddesi modelleri.

### Faz 021-030 - Uygunsuzluk Adayi Sureci

- [x] Adim 021-025 - Kontrol sonucu, uygunsuzluk adayi, degerlendirme, aksiyon ve takip ozeti modelleri.
- [x] Adim 026 - Mevcut `AttachmentRecord` ile uygunsuzluk adayi ek dosya baglantisi.
- [x] Adim 027-030 - Uygunsuzluk adayi surec gorunumu, durum gecmisi, sorumluluk/atama ve kapanis/sonuc modelleri.

### Faz 031-040 - Kesin Uygunsuzluk / NCR Model Hatti

- [x] Adim 031 - Adim 026-030 NotebookLM podcast notu.
- [x] Adim 032 - Aday kayittan kesin uygunsuzluga donusum modeli.
- [x] Adim 033-034 - `NonconformityRecord` degerlendirme ve alan revizyonu.
- [x] Adim 035-040 - NCR surec gorunumu, durum gecmisi, sorumluluk, duzeltici faaliyet, dogrulama ve kapatma modelleri.

### Faz 041-055 - NonconformityRepository Bellek Ici Davranislari

- [x] Adim 041-045 - NCR repository baslangici, duplicate id kontrolu, status/sorumlu filtreleme ve durum ozeti.
- [x] Adim 046-050 - Sorumlu ozeti, genel ozet, status/sorumlu guncelleme ve kayit var mi kontrolu.
- [x] Adim 051-055 - Kayit sayisi, arsiv alani, aktif/arsiv filtreleri, archive ve restore davranislari.

### Faz 056-060 - NCR Arsiv / Listeleme Tutarliligi

- [x] Adim 056 - NCR arsiv ozeti.
- [x] Adim 057-059 - Arsivlenmis, aktif ve tum kayit listeleme davranislari.
- [x] Adim 060 - Arsiv, restore, listeleme ve ozet butunluk kontrolu.

### Faz 061-070 - Arama / Filtreleme ve Dosya Eki Temeli

- [x] Adim 061-063 - Podcast notu, NCR arsiv/listeleme kullanim ozeti ve arama plani.
- [x] Adim 064-066 - Id, durum ve konuma gore NCR kayit bulma/filtreleme davranislari.
- [x] Adim 067-070 - Dosya/video eki plani, `FileAttachmentRecord`, dosya tipi siniflandirmasi ve iliskili kayit baglantisi.

### Faz 071-080 - FileAttachmentRecord Metadata ve Kapanis

- [x] Adim 071 - Adim 061-070 NotebookLM podcast notu.
- [x] Adim 072-075 - Dosya eki kullanim akisi, ornek senaryolar, saklama/adlandirma standardi ve arsiv guvenligi kararları.
- [x] Adim 076-079 - `original_file_name`, `uploaded_by`, `uploaded_at` ve `notes` metadata netlestirmeleri.
- [x] Adim 080 - File attachment metadata butunluk ozeti ve derin analiz oncesi kapanis.

## Faz 081-090 - Duzeltme, Standart Kilitleme ve Dokumantasyon Esitleme

- [x] Adim 081 - README guncellemesi: Adim 080 guvenli noktasi, 125 test, mevcut kapsam ve olmayan ozellikler.
- [x] Adim 082 - ROADMAP guncellemesi: Adim 080 sonrasi gercek durum ve 081-100 faz plani.
- [x] Adim 083 - Attachment model karari: `FileAttachmentRecord` ana model, `AttachmentRecord` legacy model.
- [x] Adim 084 - `FileAttachmentRecord` alan sozlesmesi: model-level optional, service-level required ayrimi.
- [x] Adim 085 - Canonical attachment path standardi: `attachments/{project_id}/{record_type}/{yyyy}/{mm}/{dd}/{record_id}/{safe_file_name}`.
- [x] Adim 086 - `FileType` ve `AttachmentStatus` hafif enum hazirligi.
- [x] Adim 087 - `FileAttachmentRecord` temel validation testleri ve minimal `ValueError` davranisi.
- [x] Adim 088 - Canonical attachment path helper fonksiyonu.
- [x] Adim 089 - Attachment metadata integrity kurallari ve missing/orphan scanner tasarim zemini.
- [x] Adim 090 - Attachment integrity status sabitleri baslangici.

Bu fazda hedef yeni urun ozelligi eklemek degil; mevcut dokumantasyon ve proje standartlarini kilitlemektir.

## Faz 091-100 - Persistence, Upload, Integrity ve Operasyon Omurgasi

- [x] Adim 091 - Attachment integrity result modeli baslangici.
- [x] Adim 092 - Attachment integrity single-record check helper baslangici.
- [x] Adim 093 - Attachment integrity report summary modeli.
- [x] Adim 094 - Attachment integrity report modeli.
- [x] Adim 095 - Attachment integrity report serializer baslangici.
- [x] Adim 096 - Ana proje ilkeleri, veri silme onleme ve ozel alan izolasyon politika dokumanlari.
- [x] Adim 097 - Adim 071-080 NotebookLM podcast notu.
- [x] Adim 098 - Adim 081-090 NotebookLM podcast notu.
- [x] Adim 099 - Adim 091-096 NotebookLM podcast notu.
- [x] Adim 100 - Guvenli nokta final kalite kontrol ve push hazirligi.

Bu fazda hedef, domain model ve dokumantasyon cekirdeginden kontrollu persistence, upload, integrity, audit ve CI omurgasina gecis icin kucuk ve testli adimlar atmaktir.

## Faz 101-140 - Denetim, Attachment Integrity Export, Scanner, Audit Hazirligi ve ID Kararlari

- [x] Adim 101 - Genel proje denetimi ve mimari saglik raporu.
- [x] Adim 102 - README guncellik duzeltmesi: Adim 100 / 191 test ve yeni kapsam bilgisi.
- [x] Adim 103 - Attachment integrity JSON string export helper.
- [x] Adim 104 - Attachment integrity JSON file export tasarim dokumani.
- [x] Adim 105 - Attachment integrity JSON file export helper ve testleri.
- [x] Adim 106 - CSE urun vizyonu ve saha hafizasi stratejisi.
- [x] Adim 107 - Scanner scope plani.
- [x] Adim 108 - Scanner input modeli / plani.
- [x] Adim 109 - Attachment scanner dry-run helper baslangici.
- [x] Adim 110 - Scanner dry-run testleri / kullanim netlestirmesi.
- [x] Adim 111 - Attachment integrity rapor kullanim ozeti.
- [x] Adim 112 - Audit event model plani.
- [x] Adim 113 - AuditEventRecord baslangic modeli.
- [x] Adim 114 - Audit event validation testleri.
- [x] Adim 115 - Audit event type sozlesmesi dokumantasyonu.
- [x] Adim 116 - Audit event type validation veya sabit sozlesme implementasyonu.
- [x] Adim 117 - Audit event target record iliski kurallari dokumantasyonu.
- [x] Adim 118 - Audit event target record pair validation.
- [x] Adim 119 - Audit event target record type sozlesmesi dokumantasyonu.
- [x] Adim 120 - Audit event target record type sabitleri ve validation.
- [x] Adim 121 - Audit event target record id format tasarimi.
- [x] Adim 122 - Audit event target record id validation tasarimi.
- [x] Adim 123 - Podcast 017: Adim 097-102 NotebookLM podcast notu.
- [x] Podcast 018 - Adim 103-108 NotebookLM podcast notu.
- [x] Podcast 019 - Adim 109-114 NotebookLM podcast notu.
- [x] Podcast 020 - Adim 115-120 NotebookLM podcast notu.
- [x] Adim 127 - Guvenli nokta kalite kontrol, dokumantasyon temizligi, ZIP repo politikasi ve LF satir sonu tercihi.
- [x] Adim 128 - FileAttachmentRecord validation bosluklarini kapatma.
- [x] Adim 129 - Record ID envanteri ve audit target_record_id validation risk analizi; dogrudan validation uygulanmadi.
- [x] Adim 130 - Central record ID contract plan; dogrudan validation uygulanmadi.
- [x] Adim 131 - Record ID constants and mapping helper plan; hard validation uygulanmadi.
- [x] Podcast 021 - Adim 127-131 NotebookLM podcast notu.
- [x] Adim 132 - Record ID constants and mapping helper implementation; hard validation uygulanmadi.
- [x] Adim 133 - Record ID helper API boundary and test example standardization plan; hard validation uygulanmadi.
- [x] Adim 134 - Record ID soft validation plan; hard validation uygulanmadi.
- [x] Adim 135 - Record ID soft validation diagnostic helper implementation plan; hard validation uygulanmadi.
- [x] Adim 136 - Record ID diagnostic helper implementation; veri reddetmeyen diagnostic katmani eklendi, hard validation uygulanmadi.
- [x] Podcast 022 - Adim 132-136 NotebookLM podcast notu; record ID diagnostic hattinin neden hard validation'a baglanmadigi ozetlendi.
- [x] Adim 137 - Record ID diagnostic helper usage boundary plan; helper'in dis QC/raporlama kullanimi ve constructor/hard validation disi siniri belgelendi.
- [x] Adim 138 - Record ID diagnostic report helper plan; ilerideki read-only toplu diagnostic rapor helper'i planlandi, implementasyon yapilmadi.
- [x] Adim 139 - Record ID diagnostic report API boundary and test matrix plan; input/output sozlesmesi ve test kategorileri belgelendi.
- [x] Adim 140 - Read-only record ID diagnostic report helper implementation; toplu diagnostic rapor helper'i eklendi, hard validation uygulanmadi.

Bu fazda hedef, Adim 101 denetim bulgularini kucuk ve test edilebilir parcalara bolerek once dokumantasyon guncelligini, sonra attachment integrity export/scanner hattini, ardindan audit ve private workspace modelleme zeminini guclendirmektir.

## Faz 141-160 - Record ID Diagnostic Usage, Report Sinirlari ve Soft Validation Hazirligi

- [x] Adim 141 - Record ID diagnostic report usage and edge case standardization; `build_record_id_diagnostic_report(records)` helper'inin read-only kullanim siniri, edge case davranislari, severity yorumlama kurallari ve summary/count okuma standardi belgelendi.
- [x] Adim 142 - Diagnostic report export / format boundary plan; JSON-ready dict, Markdown summary, handover QC summary ve admin/debug gorunumleri icin format/export siniri belgelendi, implementasyon yapilmadi.
- [x] Adim 143 - Soft validation report layer plan; diagnostic report ciktisinin pass/review/attention gibi kayit reddetmeyen yorum seviyeleriyle nasil kullanilabilecegi belgelendi, implementasyon yapilmadi.
- [x] Podcast 023 - Adim 137-141 NotebookLM podcast notu; record ID diagnostic report hattinin read-only, edge-case-aware ve hard-validation-disinda kalma kararlarini ozetledi.
- [x] Adim 144 - Soft validation report API boundary and test matrix plan; diagnostic report dict input, pass/review/attention status kurallari ve blocked disi test matrix planlandi.
- [x] Adim 145 - Read-only soft validation report implementation; diagnostic report dict'i pass/review/attention soft validation report'a ceviren helper eklendi, blocked ve hard validation kapsam disinda tutuldu.
- [x] Adim 146 - Soft validation report usage and handover QC interpretation; pass/review/attention anlamlari, handover QC yorumu ve blocked/hard-validation disi kullanim siniri belgelendi.
- [x] Podcast 024 - Adim 142-146 NotebookLM podcast notu; diagnostic report export/format boundary, soft validation report helper ve handover QC yorumlama hatti ozetlendi.
- [x] Adim 147 - Diagnostic / soft validation format helper plan; Markdown, JSON-ready dict ve handover QC summary icin read-only sunum katmani siniri belgelendi, implementasyon yapilmadi.
- [x] Adim 148 - Diagnostic / soft validation format helper API boundary and test matrix plan; Markdown, JSON-ready dict ve handover QC summary icin input/output sozlesmesi ve test kategorileri belgelendi, implementasyon yapilmadi.
- [x] Adim 149 - Read-only diagnostic / soft validation format helper implementation; JSON-ready dict ve Markdown string format helperlari eklendi, dosya uretimi ve hard validation eklenmedi.
- [x] Adim 150 - Handover QC summary usage and format helper boundary; format helper ciktilarinin handover QC icinde gorunurluk amacli okunacagi, kayit reddi veya otomatik bloklama olmayacagi belgelendi.
- [x] Adim 151 - Export file writing boundary plan; JSON/Markdown dosya yazimi, export ve handover package icin ayri risk katmani belgelendi, implementasyon yapilmadi.
- [x] Podcast 025 - Adim 147-151 NotebookLM podcast notu.
- [x] Adim 152 - Export helper API boundary and file writing safety plan; path safety, overwrite policy, encoding ve test matrix planlandi, implementasyon yapilmadi.
- [x] Adim 153 - Path safety and overwrite policy detailed documentation; allowed output root, traversal riskleri, file name/extension sinirlari, parent directory, overwrite=False varsayilani, atomic write prensibi ve handover QC export sinirlari belgelendi, implementasyon yapilmadi.
- [x] Adim 154 - Export helper test matrix finalization; JSON/Markdown export, path safety, overwrite, parent directory, unsupported input, hata davranisi, ZIP/cache dislama ve handover QC export test sinirlari belgelendi, implementasyon yapilmadi.
- [x] Adim 155 - Read-only file writing helper implementation; JSON-ready dict ve Markdown string ciktisini guvenli explicit path'e yazan helperlar eklendi, path/overwrite/allowed-root testleriyle sinirlandi.
- [x] Adim 156 - Export helper usage documentation; read-only file writing helper kullanim sinirlari, JSON/Markdown akis ornekleri, `allowed_root`, overwrite ve handover QC export siniri belgelendi, yeni kod/test/export dosyasi eklenmedi.
- [x] Podcast 026 - Adim 152-156 NotebookLM podcast notu; export/file writing boundary'den usage documentation'a kadar guvenli dosya yazma hattini ozetledi.
- [x] Adim 157 - Export helper error/result contract plan; mevcut `Path` donusu ve standart Python exception davranisi belgelendi, olasi future result dict alanlari planlandi, yeni kod/test/export dosyasi eklenmedi.
- [x] Adim 158 - Export helper result contract implementation plan; future wrapper/helper katmani, ortak result alanlari, hata kodlari ve handover QC gorunurlugu documentation-only olarak planlandi, implementasyon yapilmadi.
- [x] Adim 159 - Export helper result contract test matrix plan; basari, input, path safety, overwrite, IO, regression ve handover QC test beklentileri belgelendi, yeni kod/test/export dosyasi eklenmedi.
- [x] Adim 160 - Export helper result contract API boundary / wrapper plan; mevcut `write_*` helperlari koruyan future `try_write_*` wrapper siniri ve error mapping belgelendi, implementasyon yapilmadi.
- [x] Adim 161 - Export helper result contract wrapper implementation plan; future `try_write_*` wrapper davranisi, result sozlesmesi, error mapping, overwrite/path safety ve handover QC siniri belgelendi, implementasyon yapilmadi.
- [x] Adim 162 - Export helper result contract wrapper test matrix finalization; future `try_write_*` wrapper testleri icin basari, input, path, overwrite, schema, regression ve handover QC beklentileri kesinlestirildi, implementasyon yapilmadi.
- [x] Adim 163 - Export helper result contract wrapper implementation; `try_write_json_ready_dict_to_file(...)` ve `try_write_markdown_text_to_file(...)` wrapperlari, result schema, error mapping, overwrite/path safety testleri ve dokumantasyonu eklendi.
- [x] Adim 164 - Export helper result contract wrapper usage documentation; `write_*` ve `try_*` kullanim ayrimi, result contract yorumlari, overwrite/allowed-root sinirlari ve handover QC gorunurlugu belgelendi, kod/test/export dosyasi eklenmedi.
- [x] Podcast 027 - Adim 157-161 NotebookLM podcast notu; export helper error/result contract planlama hattini, future wrapper ayrimini ve handover QC gorunurlugunu ozetledi.
- [x] Adim 165 - Export helper result contract wrapper usage examples; wrapper result contract ornekleri, boundary/example standardi ve future test example isimleri belgelendi, kod/test/export dosyasi eklenmedi.
- [x] Adim 166 - Export helper result contract wrapper test implementation; mevcut wrapper success/failure contract davranisi ve dusuk seviye helper exception regression testleri eklendi.
- [x] Adim 167 - Export helper result contract wrapper integration boundary; testlerle sabitlenen wrapper sonucunun handover QC/admin-debug/kullanici mesaji yorum siniri belgelendi.
- [x] Adim 168 - Export helper result contract summary/report layer plan; wrapper result contract'tan ileride okunabilir ozet/rapor uretme siniri documentation-only olarak planlandi.
- [x] Adim 169 - Export result summary/report layer API boundary and test matrix plan; input/output siniri ve future test matrix basliklari documentation-only olarak netlestirildi.
- [x] Adim 170 - Export result summary/report helper implementation; wrapper result contract verisini okuyan read-only summary/report helperlari eklendi.
- [x] Adim 171 - Export result summary/report helper usage documentation; helper kullanim siniri ve handover QC review yorumu documentation-only olarak belgelendi.
- [x] Adim 172 - Export result summary/report helper edge case standardization; eksik/unknown/unsupported/mixed input durumlari icin safe review/summary standardi belgelendi.
- [x] Podcast 028 - Adim 162-166 NotebookLM podcast notu; wrapper test matrix, implementation, usage, examples ve test gorunurlugu ozetlendi.
- [x] Adim 173 - Export result summary/report follow-up plan; presentation-safe report formatter ve handover QC takip basliklari documentation-only olarak planlandi.
- [x] Adim 174 - Export result report formatter API boundary and test matrix plan; future report Markdown formatter siniri ve test kategorileri documentation-only olarak planlandi.
- [x] Adim 175 - Read-only export result report markdown formatter implementation; report dict ciktisini Markdown string'e ceviren read-only helper ve testleri eklendi.
- [x] Adim 176 - Export result report markdown formatter usage and edge case standardization; formatter kullanim siniri ve QC okuma standardi documentation-only olarak belgelendi.
- [x] Adim 177 - Export result report formatter test/example standardization; Markdown ornekleri ve formatter boundary regression testleri guclendirildi.
- [x] Adim 178 - Export result report formatter handover QC usage plan; formatter ciktisinin handover review icindeki presentation-layer rolu belgelendi.
- [x] Adim 179 - Export result report formatter downstream integration boundary plan; GUI/API/CLI ve review akislari icin presentation-layer entegrasyon siniri belgelendi.
- [x] Adim 180 - Export result report formatter phase closure and next-step boundary; Adim 175-179 fazi documentation-only olarak kapatildi.
- [x] Podcast 029 - Adim 167-180 NotebookLM podcast notu; wrapper result contract integration boundary'den report formatter phase closure'a kadar olan hat ozetlendi.
- [x] Adim 181 - Export / handover QC review checklist plan; summary/report/formatter ciktilarinin read-only insan inceleme checklist'ine nasil tasinabilecegi belgelendi.
- [x] Adim 182 - Export / handover QC review checklist boundary and test matrix plan; future checklist helper/API siniri ve test senaryolari documentation-only olarak netlestirildi.
- [x] Adim 183 - Export / handover QC review checklist helper implementation plan; future helper adi, input/output contract ve test beklentileri documentation-only olarak planlandi.
- [x] Adim 184 - Export / handover QC review checklist helper implementation; read-only JSON-ready checklist helper ve regression testleri eklendi.

Bu fazda hedef, Adim 140'ta eklenen diagnostic report gorunurlugunu once dokumantasyon ve kullanim standardi ile sabitlemek; sonra rapor format sinirlari, handover QC kullanimi ve soft validation rapor katmanini hard validation'a gecmeden hazirlamaktir.

## CSE Handoff / CI Checkpoint - Adim 193-197

- [x] Adim 193 - GitHub-native ChatGPT/Codex handoff protocol; canonical `.cse/templates/`, task/result/state dosyalari ve ZIP dislama sinirlari netlesti.
- [x] Adim 194 - Read-only CSE status command; git, diff, exports, ZIP ve opsiyonel pytest raporlama komutu eklendi.
- [x] Adim 195 - Explicit post-merge state finalization; merged state yalniz acik CLI metadata ile final hale getiriliyor.
- [x] Adim 196 - GitHub Actions `pytest` workflow; CI workflow var, fakat hosted runner billing lock nedeniyle henuz basarili GitHub `pytest` kosusu uretmedi.
- [x] Adim 197 - Latest merged/finalized checkpoint semantics; Step 196 merge commit `947350ff9348f79965fec282c28e2fa858d7356a` guvenli nokta olarak kaydedildi ve billing lock dissal constraint olarak belgelendi.

## Handover QC Checklist Phase Closure - Adim 181-192 / 199

- [x] Adim 181-183 - Export / handover QC review checklist plan, boundary, test matrix ve implementation plan documentation-only olarak hazirlandi.
- [x] Adim 184 - `build_export_handover_qc_review_checklist(summary, report)` read-only JSON-ready checklist helper olarak eklendi.
- [x] Adim 185-189 - Checklist helper usage, test/example, downstream formatter/consumer boundary ve Markdown formatter API boundary documentation-only olarak netlestirildi.
- [x] Adim 190 - `format_export_handover_qc_review_checklist_as_markdown(checklist)` read-only presentation formatter olarak eklendi.
- [x] Adim 191-192 - Markdown formatter usage, edge case standardization, test example intent ve regression boundary documentation-only olarak sabitlendi.
- [x] Adim 199 - Faz kapatildi; `is_read_only=True`, `is_blocking=False`, `requires_human_review` insan inceleme sinyali, no generated `blocked` status ve no automatic official acceptance/rejection/blocking semantics downstream boundary olarak kaydedildi.

## Downstream Presentation Consumer Planning - Adim 200

- [x] Adim 200 - Future handover QC screen / export review presentation consumer icin input boundary documentation-only olarak tanimlandi.
- [x] Adim 200 - Required field, optional field, fallback display behavior, status visibility, item visibility, review notes ve human-review indicator contract'i implementation-free olarak planlandi.
- [x] Adim 200 - Future regression/test matrix success-only, failure-only, mixed, empty/zero-count, missing required/optional fields, unknown/additional fields/statuses, unsupported input, immutability, no recomputation, no file/export output, no persistence/audit side effect, no hard validation, no generated `blocked`, no automatic acceptance/rejection/blocking ve private/non-transferable exclusion basliklarini kapsayacak sekilde kaydedildi.
- [x] Adim 200 - Step 196-200 NotebookLM podcast note, Step 200 merge edildikten sonraki documentation follow-up olarak kaydedildi; bu adimda podcast notu olusturulmadi.

## Podcast Documentation Follow-up - Adim 201

- [x] Adim 201 - Podcast 030, yalniz Adim 196-200 araligini kapsayacak sekilde `docs/podcast_notes/030_adim_196_200_notebooklm_podcast_notu.md` dosyasinda hazirlandi.
- [x] Adim 201 - Billing lock, GitHub-hosted runner startup oncesinde dissal CI execution constraint olarak anlatildi; pytest failure veya workflow-code defect olarak siniflandirilmaz.
- [x] Adim 201 - `is_read_only=True`, `is_blocking=False`, `requires_human_review` human-review signal only, no generated `blocked` status ve no automatic acceptance/rejection/blocking semantics podcast notunda tekrar korundu.
- [x] Adim 201 - Official-transferable ve private/non-transferable information ayrimi podcast notunda acik tutuldu.

## Canonical Handover QC View-Model Wording - Adim 202

- [x] Adim 202 - Future handover QC presentation view-model icin canonical examples ve wording standardization documentation-only olarak hazirlandi.
- [x] Adim 202 - `build_export_handover_qc_review_checklist(summary, report)` structured source of truth olarak, optional Markdown ise presentation-only output olarak sabitlendi.
- [x] Adim 202 - Success-only, failure-only, mixed, empty/zero-count, missing optional fields, unknown status/additional fields ve unsupported input fallback ornekleri standardize edildi.
- [x] Adim 202 - Status label, human-review indicator, empty state, missing-field fallback, unknown-status visibility ve item next-action wording'i future consumer'lar icin belgelendi.
- [x] Adim 202 - Official-transferable ve private/non-transferable information ayrimi her ornekte korundu.

## Official Local Sync Protocol - Adim 203

- [x] Adim 203 - Official local repository path `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer` primary working copy olarak kaydedildi.
- [x] Adim 203 - Branch/pull oncesi local working tree inspection ve unexpected local changes icin stop-and-report kuralı belgelendi.
- [x] Adim 203 - Fast-forward-only `master` synchronization, expected master SHA, branch creation, divergence, pytest, diff check, protected-path diff, exports ve ZIP reporting protocol'u belgelendi.
- [x] Adim 203 - GitHub-only file creation'in completion sayilmayacagi; commit/push'un local repo uzerinden yapilacagi netlestirildi.
- [x] Adim 203 - `.cse/README.md`, `.cse/templates/task_template.md` ve `.cse/templates/result_template.md` local-first protocol'u future steps icin canonical hale getirecek sekilde guncellendi.
- [x] Adim 203 - Issue #21 kapsaminda Codex'in draft PR acmayacagi ve ChatGPT review/PR acma surecinin ayri kalacagi kaydedildi.

## Handover QC Fixture Assertion Plan - Adim 204

- [x] Adim 204 - Future handover QC presentation view-model icin fixture naming and assertion checklist plan documentation-only olarak hazirlandi.
- [x] Adim 204 - Future fixture names success-only, failure-only, mixed, empty/zero-count, missing optional fields, unknown status/additional fields ve unsupported input fallback case'leri icin ayrildi.
- [x] Adim 204 - Assertion checklist structured source of truth, optional Markdown display-only handling, status label, human-review indicator, read-only/non-blocking notice, fallback wording, transfer boundary, forbidden decision fields, no side effects, input immutability, no recomputation, no generated `blocked` status ve no automatic package decision behavior basliklarini kapsiyor.
- [x] Adim 204 - Executable fixtures, executable tests, production code ve workflow degisikligi bu adimda eklenmedi; future conversion ayri explicit task gerektiriyor.

## Canonical Project Instructions and Repository Truth Sync - Adim 205

- [x] Adim 205 - `docs/protocols/CSE_PROJECT_INSTRUCTIONS.md`, local-only source'tan initially derived canonical dosya olarak tracked hale getirildi; Section 4 authority, Section 17 Step 204/205 truth ve GitHub-centered workflow intentionally adapted edildi.
- [x] Adim 205 - Adaptation sonrasi equal SHA, equal line count veya full text equivalence iddiasi yapilmadi; local-only source byte/hash unchanged kaldi.
- [x] Adim 205 - Kullanici `devam` dediginde ChatGPT GitHub state ve native actions'i yonetecek, Codex yalniz gerekli local project-file/test/commit-push/sync execution icin kullanilacak workflow kaydedildi.
- [x] Adim 205 - README, machine-readable state, roadmap, changelog ve proje kararlari Step 204 merge commit `7e5a06ed3cb62399219f9ad66b6b2b8e6eca77a3` ile yeniden eslendi; PR #26 merge sonrasinda Step 205 guncel guvenli nokta oldu.
- [x] Adim 205 - Workflow varligi, manuel disabled Actions durumu ve disabled required status checks ayri factual alanlar olarak kaydedildi.
- [x] Adim 205 - CSE'nin tested domain/data/documentation core oldugu, field-ready application olmadigi ve eksik production capabilities acik tutuldu.
- [x] Adim 205 - Reliable data backbone first, automation later, AI last ilkesi ve ilk field-MVP yonu korundu.

## Step 206 - Podcast 031 and Instruction Authority Closure

- [x] Adim 206 - Step 205 / PR #26 / Issue #25 / merge commit `92a15f2a55e6bfda42d50b8ef7dea651ff496f62` latest merged/finalized safe point olarak README, state, roadmap, changelog, decisions ve canonical Section 17 icinde eslendi.
- [x] Adim 206 - `docs/protocols/CSE_PROJECT_INSTRUCTIONS.md` tek yetkili operasyon talimat kaynagi oldu; `CSE_GUNCEL_PROJE_TALIMATLARI.md` sadece ignored local mirror olarak tutuldu ve canonical metinle birebir eslendi.
- [x] Adim 206 - Official workspace rule `Set-Location`, exact `git rev-parse --show-toplevel` check, wrong-root stop rule, no automatic `C:` clone/workspace ve GitHub Issue evidence exchange maddeleriyle sertlestirildi.
- [x] Adim 206 - Podcast 031, yalniz Steps 201-205 araligini kapsayacak sekilde eklendi.
- [x] Adim 206 - `docs/podcast_notes/README.md` stale Step 022 current-state metninden arindirilarak durable cadence ve factual Podcast 030/031 state ile guncellendi.
- [x] Adim 206 - Desktop archive repository risk kaydi non-blocking unresolved local archive item olarak belgelendi; Desktop repository'ye dokunulmadi.

## Step 207 - Unified Source and Codex Invocation Policy

- [x] Adim 207 - `docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md` approved merged source'tan tracked ust proje kaynagi olarak eklendi.
- [x] Adim 207 - `docs/protocols/CSE_PROJECT_SOURCE_REGISTER.md` source set, erisim durumu, unavailable sources ve copied reference files icin kayit oldu.
- [x] Adim 207 - `docs/protocols/CSE_NEW_CHAT_GITHUB_BOOTSTRAP.md` yeni chat'in GitHub'dan ZIP/handoff yuklemeden devam etme kuralini kalici hale getirdi.
- [x] Adim 207 - ChatGPT'nin Codex gerekip gerekmedigine karar vermesi, gerekirse `Codex çalışmalı` demesi ve nedenini aciklamasi protokole eklendi.
- [x] Adim 207 - Codex-required / Codex-not-required kategorileri, batched execution, post-merge sync batching ve metadata churn avoidance kalici operasyon kuralina donustu.
- [x] Adim 207 - Her Codex execution icin required source pre-read sirasi instructions, `.cse/README.md`, task template ve result template icinde kalici hale geldi.
- [x] Adim 207 - Step 206 / PR #29 / Issue #28 / merge commit `3b05fae76766cedc8840eea6c0fc2f51440354e4` latest safe point olarak state ve ana dokumanlarda kaydedildi.

## Step 208 - First Field MVP Observation Record Contract

- [x] Adim 208 - `FieldObservationRecord` documentation-level future model contract'i tanimlandi.
- [x] Adim 208 - Required future fields `observation_id`, `project_id`, `observed_at`, `location`, `category`, `description` olarak belirlendi.
- [x] Adim 208 - `status` default `open` ve ilk vocabulary `open`, `tracking`, `closed` olarak kaydedildi.
- [x] Adim 208 - Optional/deferred fields `reported_to`, `reported_at`, `created_by`, `closed_at`, `notes`, `is_archived` olarak belirlendi.
- [x] Adim 208 - Existing model mapping ve gap analysis `SiteProject`, `SiteLocationRecord`, `ContactPersonRecord`, `SiteNoteRecord`, `TrackingRecord`, `FileAttachmentRecord`, `DailySiteLog`, `DailyReportRecord` icin yazildi.
- [x] Adim 208 - Field-MVP implementation baslatilmadan Step 209'un review/merge sonrasi onerilen implementation adimi oldugu kaydedildi.

## Step 209 - Minimal FieldObservationRecord Model

- [x] Adim 209 - Minimal `FieldObservationRecord` dataclass'i mevcut model stiline uygun olarak eklendi.
- [x] Adim 209 - Required fields ve default values Step 208 contract'iyle eslendi.
- [x] Adim 209 - Focused tests minimal construction/default, optional/lifecycle field value holding ve documented status value holding davranisini dogruladi.
- [x] Adim 209 - Validation, repository/persistence, attachment integration, export/reporting, API/GUI/CLI, audit ve additional Field-MVP model eklenmedi.

## Step 210 - FieldObservationRepository Baseline

- [x] Adim 210 - Minimal bellek ici `FieldObservationRepository` baseline'i mevcut repository stiline uygun olarak eklendi.
- [x] Adim 210 - `add`, `list_all`, `count` ve `find_by_id` davranislari eklendi.
- [x] Adim 210 - Duplicate `observation_id` `ValueError` ile reddedildi; farkli `observation_id` kabul edildi.
- [x] Adim 210 - `list_all()` ic koleksiyonu degistirmeyen liste kopyasi dondurur.
- [x] Adim 210 - Filters, lifecycle updates, archive/restore/delete/bulk ops, persistence, attachment linking, export/reporting, API/GUI/CLI, audit, validation ve Podcast 032 eklenmedi.

## Step 211 - Podcast 032 for Steps 206-210

- [x] Adim 211 - `docs/podcast_notes/032_adim_206_210_notebooklm_podcast_notu.md` dosyasi Steps 206-210 icin hazirlandi.
- [x] Adim 211 - Podcast 032, protocol/source/workflow consolidation'dan ilk Field MVP contract/model/repository cekirdegine gecisi anlatti.
- [x] Adim 211 - Repository truth Step 210 / PR #37 / Issue #36 / merge `c7dbd94076f9e23c928f27ea377a97debad6636b` safe point olacak sekilde guncellendi.
- [x] Adim 211 - Production code, tests, workflow, persistence, attachment, filters, lifecycle, export/reporting, API/GUI/CLI, audit ve Step 212 baslatilmadi.

## Step 212 - FieldObservationRepository Project/Status Filters

- [x] Adim 212 - `list_by_project_id(project_id)` exact, case-sensitive project filtresi eklendi.
- [x] Adim 212 - `list_by_status(status)` exact, case-sensitive status filtresi eklendi.
- [x] Adim 212 - Donen filtered listelerin yeni liste oldugu, insertion order'in korundugu ve archived matching kayitlarin dahil edildigi test edildi.
- [x] Adim 212 - Category/location/reported_to/date-time/text-search/active/archive-only/combined filters, lifecycle mutation, persistence, attachment integration, export/reporting, API/GUI/CLI, audit, validation ve Step 213 baslatilmadi.

## Step 213 - FieldObservationRepository Status Update

- [x] Adim 213 - `update_status(observation_id, new_status)` explicit status update method'u eklendi.
- [x] Adim 213 - Missing id icin `None`, found id icin ayni stored record nesnesi donduruldu.
- [x] Adim 213 - Status filtresinin update'i hemen yansittigi ve yeni/duplicate record olusmadigi test edildi.
- [x] Adim 213 - Automatic timestamps, validation, enums, close/reopen workflow, other field updates, archive gating, persistence, attachment integration, API/GUI/CLI, audit ve Step 214 baslatilmadi.

## Step 214 - FieldObservationRepository Reporting Update

- [x] Adim 214 - `update_reporting(observation_id, reported_to, reported_at)` explicit reporting-context update method'u eklendi.
- [x] Adim 214 - Missing id icin `None`, found id icin ayni stored record nesnesi donduruldu.
- [x] Adim 214 - Yalniz `reported_to` ve `reported_at` alanlarinin degistigi; status, closed timestamp, notes, creator ve archive state'in korundugu test edildi.
- [x] Adim 214 - Exact string preservation, archived record allowance ve stable count davranislari test edildi.
- [x] Adim 214 - Automatic status change, timestamp generation, contact lookup/normalization, other field updates, persistence, attachment integration, API/GUI/CLI, audit ve Step 215 baslatilmadi.

## Step 215 - FieldObservationRepository Location/Category Filters

- [x] Adim 215 - `list_by_location(location)` exact, case-sensitive location filtresi eklendi.
- [x] Adim 215 - `list_by_category(category)` exact, case-sensitive category filtresi eklendi.
- [x] Adim 215 - Unknown, case-different ve whitespace-different degerlerin farkli sonuc verdigi test edildi.
- [x] Adim 215 - Location, category, project ve status filtrelerinin birbirinden bagimsiz kaldigi test edildi.
- [x] Adim 215 - Donen listelerin yeni liste oldugu, stored record nesnelerinin kopyalanmadigi/mutate edilmedigi ve archived matching kayitlarin dahil edildigi test edildi.
- [x] Adim 215 - Structured location lookup, category normalization/constants/enums, combined query, broader filters/mutations, persistence, attachment integration, API/GUI/CLI, audit, Podcast 033 ve Step 216 baslatilmadi.

## Step 216 - Podcast 033 for Steps 211-215

- [x] Adim 216 - `docs/podcast_notes/033_adim_211_215_notebooklm_podcast_notu.md` dosyasi Steps 211-215 icin hazirlandi.
- [x] Adim 216 - Podcast 033, Podcast 032 kapanisi -> project/status filtreleri -> explicit status update -> explicit reporting update -> location/category filtreleri hattini anlatti.
- [x] Adim 216 - Step 212-215 davranislari automatic, validated veya persistent davranis gibi sunulmadi.
- [x] Adim 216 - Repository truth Step 215 / PR #47 / Issue #46 / merge `7b3361087cdb51fe1e76caa6f2cd91ff005cdfe2` latest merged safe point olacak sekilde guncellendi.
- [x] Adim 216 - Production code, executable tests, repository behavior, workflow, Podcast 034 ve Step 217 baslatilmadi.

## Step 217 - FileAttachmentRepository Baseline

- [x] Adim 217 - `FileAttachmentRepository` minimal bellek ici metadata repository olarak eklendi.
- [x] Adim 217 - `add`, `list_all`, `count` ve `find_by_id` method'lari uygulandi.
- [x] Adim 217 - Duplicate exact `attachment_id` `ValueError` ile reddedildi; case-different id degerleri distinct kaldi.
- [x] Adim 217 - Insertion order, new-list behavior, same-object return ve metadata non-mutation davranislari test edildi.
- [x] Adim 217 - `docs/217_file_attachment_repository_baseline.md` ve `learning/217_file_attachment_repository_baseline.md` olusturuldu.
- [x] Adim 217 - Related-record filters, FieldObservation-specific attachment lookup/linking, physical file operations, persistence, validation/enums/constants, API/GUI/CLI, audit, Podcast 034 ve Step 218 baslatilmadi.

## Step 218 - FileAttachmentRepository Related-Record Filters

- [x] Adim 218 - `list_by_related_record_type(related_record_type)` exact, case-sensitive related-record type filtresi eklendi.
- [x] Adim 218 - `list_by_related_record_id(related_record_id)` exact, case-sensitive related-record id filtresi eklendi.
- [x] Adim 218 - Unknown, case-different ve whitespace-different degerlerin farkli sonuc verdigi test edildi.
- [x] Adim 218 - Type ve id filtrelerinin birbirinden bagimsiz kaldigi test edildi.
- [x] Adim 218 - Donen listelerin yeni liste oldugu, stored record nesnelerinin kopyalanmadigi/mutate edilmedigi ve repository sirasi/sayisinin korundugu test edildi.
- [x] Adim 218 - `docs/218_file_attachment_repository_related_record_filters.md` ve `learning/218_file_attachment_repository_related_record_filters.md` olusturuldu.
- [x] Adim 218 - Combined filter, FieldObservation-specific attachment lookup/linking, physical file operations, persistence, validation/enums/constants, API/GUI/CLI, audit, Podcast 034 ve Step 219 baslatilmadi.

## Step 219 - Field Observation Attachment Linking Contract

- [x] Adim 219 - Field Observation attachment relationship identity documentation-only olarak tanimlandi.
- [x] Adim 219 - Exact pair kuralı `related_record_type == "field_observation"` ve `related_record_id == FieldObservationRecord.observation_id` olarak kaydedildi.
- [x] Adim 219 - Cardinality, ownership ve orphan/existence behavior sinirlari belgelendi.
- [x] Adim 219 - Bagimsiz Step 218 filtrelerinin safe combined relationship query olmadigi aciklandi.
- [x] Adim 219 - Future `list_by_related_record(...)` ve `list_for_field_observation(...)` boundaries implement edilmeden dokumante edildi.
- [x] Adim 219 - Future test matrix yazildi.
- [x] Adim 219 - Production code, executable tests, combined filter implementation, convenience lookup, physical file operations, persistence, validation/enums/constants, API/GUI/CLI, audit, Podcast 034 ve Step 220 baslatilmadi.

## Step 220 - FileAttachmentRepository Combined Related-Record Filter

- [x] Adim 220 - `list_by_related_record(related_record_type, related_record_id)` exact combined filtresi eklendi.
- [x] Adim 220 - Same id / different type ve same type / different id partial match durumlari dislandi.
- [x] Adim 220 - Case-different ve whitespace-different type/id degerlerinin exact query ile eslesmedigi test edildi.
- [x] Adim 220 - Empty repository, unknown pair, new-list behavior, same-object return, metadata non-mutation ve count/order stability test edildi.
- [x] Adim 220 - Missing related-record existence repository tarafindan validate edilmedi.
- [x] Adim 220 - Existing independent filters, baseline repository methods, `FieldObservationRepository` ve `NonconformityRepository` davranislari korundu.
- [x] Adim 220 - `docs/220_file_attachment_repository_combined_related_record_filter.md` ve `learning/220_file_attachment_repository_combined_related_record_filter.md` olusturuldu.
- [x] Adim 220 - `list_for_field_observation(...)`, physical file operations, persistence, validation/enums/constants, API/GUI/CLI, audit, Podcast 034 ve Step 221 baslatilmadi.

## Step 221 - Podcast 034 for Steps 216-220

- [x] Adim 221 - `docs/podcast_notes/034_adim_216_220_notebooklm_podcast_notu.md` dosyasi Steps 216-220 icin hazirlandi.
- [x] Adim 221 - Podcast 034, observation repository maturity -> attachment metadata repository -> independent relationship lookups -> explicit observation-link contract -> exact combined relationship lookup hattini anlatti.
- [x] Adim 221 - `FieldObservationRecord` ve `FileAttachmentRecord` iliskisinin attachment-owned metadata uzerinden exact, case-sensitive ve zero-to-many olarak okunacagi aciklandi.
- [x] Adim 221 - Combined filter'in partial match reddetme nedeni ve `471 passed` test kaniti kaydedildi.
- [x] Adim 221 - CSE'nin henuz field-ready veya production-ready application olmadigi, hala in-memory test-backed metadata core seviyesinde oldugu vurgulandi.
- [x] Adim 221 - Production code, executable tests, repository behavior, workflow, Podcast 035 ve Step 222 baslatilmadi.

## Step 222 - Field Observation Attachment Convenience Lookup Boundary

- [x] Adim 222 - Future `list_for_field_observation(observation_id)` helper'i icin API boundary documentation-only olarak planlandi.
- [x] Adim 222 - Helper'in `list_by_related_record("field_observation", observation_id)` ile semantic equivalent kalmasi gerektiği kaydedildi.
- [x] Adim 222 - Future implementation icin existing combined helper'a delegation tercih edildi.
- [x] Adim 222 - Exact, case-sensitive, non-normalizing ve validation-free davranis siniri korundu.
- [x] Adim 222 - `FieldObservationRepository` lookup'i, referenced observation existence validation, metadata mutation ve `FieldObservationRecord` mutation kapsam disi tutuldu.
- [x] Adim 222 - Future test matrix 15 baslikla belgelendi.
- [x] Adim 222 - Production code, executable tests, repository behavior, workflow, Podcast 035 ve Step 223 baslatilmadi.

## Step 223 - Field Observation Attachment Convenience Lookup

- [x] Adim 223 - `FileAttachmentRepository.list_for_field_observation(observation_id)` helper'i eklendi.
- [x] Adim 223 - Helper existing `list_by_related_record("field_observation", observation_id)` davranisina delegation yapar.
- [x] Adim 223 - Ikinci `_records` filtering implementation'i eklenmedi.
- [x] Adim 223 - Exact, case-sensitive, non-normalizing ve validation-free davranis combined helper uzerinden korundu.
- [x] Adim 223 - Focused tests delegation, partial match rejection, case/whitespace sensitivity, new-list, same-object, non-mutation, missing existence non-validation ve existing filter regression davranislarini dogruladi.
- [x] Adim 223 - Production scope yalniz `app/records.py` ve `tests/test_records.py` ile sinirli tutuldu; model, workflow, Podcast 035 ve Step 224 baslatilmadi.

## Step 224 - Rolling NotebookLM Podcast Source Protocol

- [x] Adim 224 - `NOTEBOOKLM_INSTRUCTIONS.md` kalici yorumlama ve Turkce podcast sozlesmesi olarak eklendi.
- [x] Adim 224 - Stable `CSE_PODCAST_LATEST_SOURCE.md` yolu ve public raw GitHub URL'si tanimlandi.
- [x] Adim 224 - Latest numbered podcast note, full note content, 001-223 cumulative step summaries, safe point, deferred scope ve metadata deterministic olarak birlestirildi.
- [x] Adim 224 - `CSE_PODCAST_SOURCE_MANIFEST.json` latest podcast/range/path, rolling source, instruction, safe point ve summary count alanlariyla eklendi.
- [x] Adim 224 - Malformed/duplicate/missing source failures, determinism, UTF-8, no historical mutation ve no side effects focused tests ile guvence altina alindi.
- [x] Adim 224 - Focused generator testleri `15 passed`, tam yerel suite `494 passed` olarak dogrulandi.
- [x] Adim 224 - Kalici Codex model/reasoning/secim-gerekcesi politikasi canonical talimat ve state'e eklendi.
- [x] Adim 224 - Podcast 035, NotebookLM API/browser/upload/audio automation, ana urun behavior, workflow, ZIP ve exports mutation eklenmedi.

## Step 225 - Podcast 035 Note Summary Contract

- [x] Adim 225 - `035_adim_221_225_notebooklm_podcast_notu.md` mandatory 12-section structure ile olusturuldu.
- [x] Adim 225 - Note Section 6 icinde Steps 001-220 tam bir kez, ascending order ve ayri heading'lerle tasindi.
- [x] Adim 225 - Strict note validator previous-summary section boundary'sini bulur ve missing, duplicate, out-of-order veya section-disindaki headings'i reddeder.
- [x] Adim 225 - Current-range steps previous-summary section icinde zorunlu tutulmadi; Podcast 034 legacy compatibility korundu.
- [x] Adim 225 - Rolling source latest Podcast 035 / Steps 221-225 ve 224 cumulative canonical summary ile yenilendi.
- [x] Adim 225 - Focused generator tests `24 passed`, full local suite `503 passed` olarak dogrulandi.
- [x] Adim 225 - Main product code, workflow, NotebookLM automation, historical podcast, ZIP ve exports mutation eklenmedi; Step 226 baslatilmadi.

## Step 225 Sonrası Tarihsel Çalışma Önerisi

Bu öneri Step 225 dönemine aittir ve güncel ürün sırasını belirlemez. Transactional service, lazy backfill, backup/export güvenlik kapısı ve ilk test edilebilir PC web yüzeyi sonraki Issue'larla tamamlanmıştır; güncel sonraki ürün yönü üstteki listede yer alan mobil runtime ve veri sahipliği ADR'sidir.

Podcast cadence notu: Podcast 030 Adim 196-200, Podcast 031 Adim 201-205, Podcast 032 Adim 206-210, Podcast 033 Adim 211-215, Podcast 034 Adim 216-220 ve Podcast 035 Adim 221-225 araligini kapsar. Sonraki dogal podcast araligi Steps 226-230 olur.

## Issue 98 - Saha Takibi v0.1 Sözleşme Aşaması

- [x] Mevcut schema v2, migration, repository, Unit of Work, backup/restore ve daily export sınırları incelendi.
- [x] `FollowUpItem`, `RoutineTemplate` ve `RoutineOccurrence` alanları ve yaşam döngüleri kesinleştirildi.
- [x] Hızlı create command’ında yalnız `capture_text` zorunlu; ilk title deterministic normalize edilmiş aynı metin; sonraki title düzenlemesi serbest olarak düzeltildi.
- [x] Follow-up ve routine template projesi nullable yapıldı; projesiz kayıtların kişisel çalışma alanında kalması ve observation bağında project eşleşmesi kesinleştirildi.
- [x] Zamanlanmamış açık kaydın yalnız `inbox` olacağı; `active/waiting` kaydın `next_attention_at` taşımak zorunda olduğu database/application sınırıyla kaydedildi.
- [x] `now` domain kategorisinden çıkarıldı; `overdue/today/upcoming` yalnız planlı kayıtlar, “Şimdi ilgilen” ise overdue + zamanı gelmiş today + önemli inbox UI bileşimi olarak tanımlandı.
- [x] `daily`, `weekdays`, `weekly`, `monthly` recurrence davranışı, Europe/Istanbul yerel tarih temeli ve UTC snapshot kararı kaydedildi.
- [x] Aynı template+yerel tarih unique/idempotency kuralı ve bugün dahil yedi günlük sınırlı lazy backfill seçildi.
- [x] Revision, no-op, deterministic aggregate sequence ve transactional event append sınırı tanımlandı.
- [x] SQLite schema v3 migration planı; mevcut veri ve hard-delete yasağı korunarak yazıldı.
- [x] Backup format v1’i koruma, schema v2 eski backup’ı yeni hedefte migrate etme ve tracking manifest count eklememe kararı verildi.
- [x] Kişisel tracking verisinin günlük resmî observation export’una girmemesi ve byte-level regression sınırı tanımlandı.
- [x] Puantaj iş günü kabul senaryosu restart, snooze, template edit, deactivation ve backup/restore durumlarıyla tamamlandı.
- [x] Production domain kayıtları, hızlı capture normalization, saf recurrence ve görünüm sınıflandırmaları Issue #100 kapsamında executable testlerle uygulandı.
- [x] SQLite schema v3 migration, domain-SQLite mapping, altı repository/event adapter'ı ve Unit of Work bağlantıları Issue #102 kapsamında uygulandı.
- [x] Transactional service/backfill Issue #109, #111, #112 ve #115 ile uygulandı.
- [x] Backup compatibility ve export exclusion Issue #117 ile executable testlerle doğrulandı.
- [x] İlk test edilebilir PC UI Issue #119 branch'inde tamamlandı ve PR incelemesine hazırlandı.

## Issue 100 - Saha Takibi Task 2/5 Domain ve Saf Recurrence

- [x] `FollowUpItem`, `RoutineTemplate`, `RoutineOccurrence` ve üç event ailesi immutable domain kayıtları olarak eklendi.
- [x] Yalnız `capture_text` alanını normalize edip ilk `title` değerini aynı metinden üreten saf hızlı yakalama sınırı eklendi.
- [x] Nullable proje, observation için project zorunluluğu, açık/terminal status ve outcome/timestamp değişmezleri executable validation ile korundu.
- [x] `daily`, `weekdays`, `weekly`, `monthly` yerel tarih eşleşmeleri ve bugün dahil yedi günlük sınırlı pencere saf fonksiyonlarla eklendi.
- [x] `Europe/Istanbul` `ZoneInfo` dönüşümüyle yerel tarih/saat ve canonical UTC snapshot planı eklendi.
- [x] Geçmiş uygun gün için `missed`, bugün için `open` saf occurrence planı eklendi; gelecek gün reddedildi.
- [x] Follow-up `inbox/overdue/today/upcoming`, occurrence `overdue/today/upcoming` ve tekilleştirilmiş “Şimdi ilgilen” bileşimi eklendi; `now` domain kategorisi eklenmedi.
- [x] Domain ve recurrence için kapsamlı focused executable test matrisi eklendi.
- [x] SQLite schema v3, migration, repository ve Unit of Work bağlantıları Issue #102 kapsamında uygulandı.
- [x] Transactional application service ve occurrence ensure/backfill orchestration Issue #109, #111, #112 ve #115 ile uygulandı.
- [x] Backup/restore compatibility ve export exclusion Issue #117; ilk test edilebilir PC UI Issue #119 ile tamamlandı.

## Issue 102 - Saha Takibi Task 3/5 SQLite v3 ve Persistence

- [x] Schema version 3, v1/v2 zincirini değiştirmeyen tek immutable migration olarak eklendi.
- [x] Follow-up, routine template, weekday relation, routine occurrence ve üç append-only event tablosu gerekli foreign key, CHECK, unique ve index kurallarıyla eklendi.
- [x] Observation-project composite foreign key'i, nullable kişisel proje kayıtları ve `active/waiting + NULL next_attention_at` reddi database seviyesinde korundu.
- [x] Üç aggregate ve üç event ailesi için açık domain-SQLite mapper'ları, repository port'ları ve SQLite adapter'ları eklendi.
- [x] Event geçmişleri yalnız aggregate sequence ile deterministik okundu; duplicate sequence ve hard-delete/cascade davranışı reddedildi.
- [x] Routine occurrence insert'i template + yerel tarih anahtarında idempotent primitive olarak eklendi.
- [x] Altı tracking repository'si mevcut SQLite Unit of Work transaction'ına bağlandı; aggregate + event commit/rollback atomikliği kanıtlandı.
- [x] Fresh v3 ile v2→v3 şema eşitliği ve mevcut project/observation/attachment/event satırlarının birebir korunması geçici database testleriyle doğrulandı.
- [x] Transactional application service ve occurrence ensure/backfill orchestration Issue #109, #111, #112 ve #115 ile uygulandı.
- [x] Backup compatibility ve export exclusion Issue #117; ilk test edilebilir PC UI Issue #119 ile tamamlandı.

## Issue 103 - Kanonik Talimatlar v2 ve Repository Truth

- [x] CSE, yalnız şantiye şefinin kullandığı local-first ve mobile-first kişisel saha asistanı olarak tanımlandı.
- [x] Araç bakımından geniş, kullanıcı modeli bakımından tek sahipli ürün değişmezi Epic #105 ile kanonikleştirildi.
- [x] Diğer kişi/firmalar kullanıcı değil kayıt referansı; multi-user/role/tenant/SaaS/kurumsal portal hedefleri kalıcı kapsam dışı yapıldı.
- [x] Single-owner security; uygulama kilidi, güvenilen cihaz, şifreli backup, owner-only sync ve güvenli yerel ağ yönüyle ayrıştırıldı.
- [x] Kalıcı ürün politikası, operasyon talimatı, aktif Issue kapsamı ve değişken GitHub repository durumu ayrı otorite yüzeylerine ayrıldı.
- [x] Eski Step 224/225 current-state metinleri tarihsel bağlama çekildi.
- [x] Local Field MVP kabiliyetleri ve PR #104 sonrası Saha Takibi durumu güncel kanıtla hizalandı.
- [x] Mobil runtime/offline/bildirim pilot önüne; minimum hesap şeridi ve günlük zaman çizelgesi Kâğıdı Bırakma Sürümü içine alındı.
- [x] Gelişmiş hesap defteri, immutable günlük yayın zinciri ve Canlı Proje Haritası pilotlar sonrasındaki ayrı fazlarda tutuldu.
- [x] Legacy model envanteri/deprecation yönü gerçek sınıf adlarıyla yazıldı; fiziksel silme yetkisi verilmedi.
- [x] Production Python, schema, migration, repository, UI ve test davranışı değiştirilmedi.

## Issue 107 - Follow-up Mutation Event Vocabulary ve SQLite v4

- [x] `FollowUpEventType` sonuna `details_updated`, `moved_to_inbox` ve `project_changed` anlamları eklendi; eski sıra ve değerler korundu.
- [x] Gelecek `update_details`, `move_to_inbox` ve `set_project` mutation'larının minimum deterministic payload sözleşmesi yazıldı.
- [x] Schema version 4, v1/v2/v3 statement içeriklerini değiştirmeyen tek immutable migration olarak eklendi.
- [x] Yalnız `follow_up_events` tablosu aynı kolon/constraint/FK sözleşmesi ve genişletilmiş event CHECK list'iyle transaction içinde yeniden kuruldu.
- [x] Mevcut event alanları ve `payload_json` metni birebir korundu; diğer tablolar, no-cascade ve append-only sequence davranışı değişmedi.
- [x] Fresh v4/v3→v4 schema eşitliği, tam rollback, allowed/unknown türler, duplicate sequence, foreign key ve repository round-trip testleri eklendi.
- [x] Mapping/repository API değişikliği gerekmedi; event update/delete/sequence allocator eklenmedi.
- [x] `FollowUpApplicationService` çekirdek optimistic mutation/no-op ve atomik event üretimi Issue #109; waiting/terminal yaşam döngüsü Issue #111 ile uygulandı.
- [x] Rutin application service ve yedi günlük idempotent lazy backfill Issue #115 ile uygulandı.
- [x] Backup backward compatibility ve resmî export izolasyonu Issue #117 ile executable kabul testleriyle tamamlandı.

## Issue 109 - FollowUpApplicationService Çekirdek Akışları

- [x] Hızlı `+ Unutma` create yalnız capture text alır; canonical UUID/UTC teknik değerleri enjekte edilebilir ve ilk `follow_up.created` event'i aynı transaction'da yazılır.
- [x] Get/list/history ile status/project/personal/observation filtreleri repository deterministic sırasını koruyarak compose edilir.
- [x] Inbox/overdue/today/upcoming ve “Şimdi ilgilen” görünümleri mevcut domain helper'ları ve `Europe/Istanbul` gün sınırıyla hesaplanır.
- [x] Ayrıntı update allowlist'i immutable capture/status/project/attention/outcome/created alanlarını korur ve exact alfabetik `changed_fields` event'i üretir.
- [x] İlk planlama ve yeniden planlama `scheduled/rescheduled`; planı kaldırma `moved_to_inbox`; proje değişimi `project_changed` event'ini doğru nullable payload ile üretir.
- [x] Stale revision, gerçek no-op, event failure ve commit failure sınırları aggregate/event geçmişinde yarım yazı bırakmadan test edildi.
- [x] Repository portlarına sequence/update/delete API'si, schema v5/migration, web/UI, backup/export değişikliği eklenmedi.
- [x] Waiting, complete, cancel ve reopen follow-up yaşam döngüleri Issue #111 ile uygulandı.
- [x] Observation bağlama/dönüştürme Issue #112 ile uygulandı.
- [x] Routine application service ile yedi günlük idempotent lazy backfill Issue #115 ile uygulandı.

## Issue 111 - Follow-up Bekleme ve Terminal Yaşam Döngüleri

- [x] `MarkWaiting` ve `CompleteFollowUp` immutable command değerleri canonical UTC ve optional text normalizasyonuyla eklendi.
- [x] Inbox/active → waiting geçişi; exact waiting no-op, farklı ikinci bekleme reddi ve nullable kişi/koşul payload'ı uygulandı.
- [x] Bütün açık durumlardan `completed/not_required` completion ve cancelled outcome'lu cancel geçişleri uygulandı.
- [x] Completed/cancelled kaydın dikkat anına göre inbox/active yeniden açılması ve bütün terminal alanlarının temizlenmesi uygulandı.
- [x] Dört mutation için revision, önceki durum/zaman/sonuç ve yeni değerleri taşıyan append-only event payload'ları eklendi.
- [x] UUID validation, event insert ve commit hatalarında aggregate/event'in birlikte rollback edilmesi focused testlerle doğrulandı.
- [x] Deadline, capture, proje/observation ve diğer ayrıntı koruması; stale-before-no-op ve clock/UUID tüketmeyen exact no-op doğrulandı.
- [x] Schema v4, migration, mapper, repository/UoW portu, observation/routine, web/UI ve backup/export sınırları değiştirilmedi.

## Issue 112 - Follow-up Observation Bağlantısı ve Dönüşüm

- [x] Var olan observation'a açık/terminal follow-up link'i, lifecycle alanlarını değiştirmeden uygulandı.
- [x] Observation project source-of-truth; null project adoption, same project koruması ve different project rejection ile uygulandı.
- [x] Same observation exact no-op ve different existing observation rejection sınırları eklendi.
- [x] Açık inbox/active/waiting kaydın `completed + converted_to_observation` sonucuyla atomik dönüşümü uygulandı.
- [x] Conversion attention'ı temizler, deadline/capture/detail alanlarını korur ve yalnız converted event üretir.
- [x] Exact converted retry no-op; diğer completed outcome ve cancelled conversion reddi uygulandı.
- [x] UUID validation, event insert ve commit hatalarında link/conversion aggregate-event rollback'i test edildi.
- [x] Otomatik observation creation, persistence/schema, observation service, routine/backfill, web/UI ve backup/export kapsamına girilmedi.

## Issue 119 - İlk Test Edilebilir PC Saha Takibi Arayüzü

- [x] `/` başlangıcı `/today` görünümüne yönlendirildi; üst navigasyonda Bugün, Unutma Kutusu, Rutinler ve Gözlemler görünür hale getirildi.
- [x] Observation, follow-up ve routine application service'leri aynı `cse.sqlite3` dosyasına bağlandı; schema sürümü `4` kaldı.
- [x] Bugün görünümü Şimdi ilgilen, Gecikenler, Bugün ve Bugünkü rutinler bölümlerini Europe/Istanbul kullanıcı zamanı ile sunuyor.
- [x] Tek alanlı `+ Unutma` formu normalize edilmiş capture text, PRG redirect, HTML escaping ve immutable ilk yakalama kanıtıyla uygulandı.
- [x] Follow-up detail; ayrıntı, proje, planlama, bekleme, inbox, complete, cancel ve reopen işlemlerini revision korumasıyla sunuyor.
- [x] Rutin list/create/detail/deactivate ile occurrence snooze/close/reopen işlemleri server-rendered formlarla sunuluyor.
- [x] Aynı `/today` yenilemesinin duplicate occurrence/event üretmediği ve restart sonrasında revision/history'nin aynı SQLite'tan okunduğu doğrulandı.
- [x] Mevcut observation, backup ve resmî günlük export akışları korundu; follow-up capture text'i ve routine başlığı resmî export'a sızmadı.
- [x] Web paketi `17 passed`, ilgili regresyonlar `56 passed`, full suite `983 passed, 7 skipped` olarak doğrulandı.
- [x] `SCHEMA_VERSION == 4`; domain/application/persistence/operations protected path diff'i boş; gerçek `CSE_DATA_ROOT` kullanılmadı.
- [x] PC web sürümü PR incelemesine hazırlandı; merge claim, PR oluşturma, mobile/PWA/offline/sync/notification/auth kapsamı eklenmedi.
