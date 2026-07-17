# Saha Kabul Metrikleri ve Pilot Protokolü

## 1. Amaç, kapsam ve non-goals

Bu protokol, CSE'nin gerçek şantiye kullanımında hızlı, bulunabilir ve güvenilir
bir kişisel saha asistanı olup olmadığını ölçülebilir kanıta bağlar. Gün 0
preflight, art arda 7 takvim günlük ilk pilot ve art arda 30 takvim günlük
doğrulama pilotu için aynı metrik sözlüğünü, örnekleme kuralını, stop
kriterlerini ve karar kapılarını tanımlar.

Bu belge:

- pilotu **yürütmez**;
- gerçek saha verisi veya gerçek ölçüm sonucu içermez;
- hedefleri production garantisi olarak sunmaz;
- telemetry, analytics, otomatik timer, background job veya cloud gönderimi
  uygulamaz;
- production/test/schema/migration/persistence/UI/route/CLI ve artifact
  formatlarını değiştirmez;
- ADR-0001, ADR-0002 ve ADR-0003'ü değiştirmez.

Hedefler ilk kabul eşikleridir. Gerçek pilot yalnız ayrı executable Issue,
doğru build, açık kullanıcı onayı ve owner-controlled veri köküyle başlatılır.

## 2. Protokol rolleri ve temel kayıt modeli

CSE tek sahipli üründür. Pilot rolleri yeni kullanıcı hesabı veya yetki modeli
değildir:

| Rol | Sorumluluk |
|---|---|
| Pilot owner | Şantiye şefi; denemeyi yapar, stop kararını uygular ve devam kararını açıkça verir. |
| Pilot reviewer | Owner'ın kendisi veya yalnız anonim metrik özetini inceleyen kişi; gerçek kayıt içeriğine erişim verilmez. |
| Incident reviewer | Yalnız blocker triage için owner tarafından açıkça seçilen kişi; hassas kanıt pilot loguna veya GitHub'a konmaz. |

Her günlük log bir `pilot_day_id` taşır: `PILOT-D{NN}`. Her deneme/olay yalnız
pilot-local anonim `event_id` ile kaydedilir: `EVT-D{NN}-{NNN}`. Source UUID,
kayıt metni, kişi/proje adı veya attachment dosya adı pilot loguna yazılmaz.

### 2.1 Ortak deneme alanları

Süre veya olay satırlarında yalnız gerektiği kadar şu alanlar kullanılır:

```text
event_id
pilot_day_id
metric_id
record_type_or_scenario
started_at_local
ended_at_local
duration_seconds
outcome
reason_code
severity
evidence_status
notes_sanitized
```

`notes_sanitized` zorunlu değildir ve gerçek içerik içeremez. Timestamp saniye
hassasiyetinde tutulur; daha hassas kullanıcı davranış izi toplanmaz.

## 3. Metrik hesaplama kuralları

### 3.1 Süre

```text
duration_seconds = ended_at_local - started_at_local
```

- Negatif süre geçersiz ölçümdür.
- Başlangıç veya bitiş anı yoksa süre tahmin edilmez; satır `invalid_sample`
  olur ve ölçüm bütünlüğü metriğine yansır.
- Süreler en yakın tam saniyeye yuvarlanır.
- Kullanıcının kronometreyi başlatma/durdurma hareketi ölçüme dahil edilir;
  gizli otomatik instrumentation yoktur.

### 3.2 Median ve p90

Başarılı süreler küçükten büyüğe sıralanır.

- Median: tek sayıda ortadaki değer; çift sayıda ortadaki iki değerin aritmetik
  ortalaması.
- p90: nearest-rank yöntemi; sıralı listenin `ceil(0.90 * n)` konumundaki
  değeri.
- `n < 5` ise p90 hesaplanabilir ama karar için `low_sample` etiketi taşır.
- Başarısız denemeler percentile listesinden çıkarılıp saklanmazlık yapılmaz;
  süreleri, sayıları ve failure rate'i ayrı ve zorunlu raporlanır.

```text
failure_rate = failed_attempt_count / all_valid_attempt_count * 100
```

### 3.3 Count ve rate

Rate hesaplarında payda sıfırsa sonuç `N/A` olur; `0%` yazılmaz. Zorunlu bir
metrikte payda sıfır olması `insufficient_evidence` üretir. Safety metrikleri
örneklenmez: bütün şüpheli ve confirmed olaylar sayılır.

### 3.4 Kanıt durumları

```text
observed -> suspected -> confirmed | disproved
```

- `observed`: ilk sinyal.
- `suspected`: source/fixture/operasyon kanıtı henüz tamamlanmamış olay.
- `confirmed`: tekrar üretim veya source/restore/integrity karşılaştırmasıyla
  doğrulanan olay.
- `disproved`: incelemeyle ürün hatası olmadığı kanıtlanan olay.

Şüpheli safety olayı “kanıt yok” denilerek sıfır sayılmaz; triage bitene kadar
pilot durur.

## 4. Metrik sözlüğü

### M01 — Kayıt açma süresi

| Alan | Tanım |
|---|---|
| metric_id | `M01_CAPTURE_DURATION` |
| name | Kayıt açma süresi |
| purpose | Follow-up, observation veya due routine action'ının sahada yeterince hızlı tamamlanabildiğini ölçmek. |
| unit | Saniye; ayrıca success/failure sayısı ve oranı |
| numerator | Her valid denemede `success_or_stop_at - user_intent_at` saniyesi; failure rate için failed attempt sayısı |
| denominator | Zamanlanmış bütün valid capture denemeleri; failure rate için aynı kümenin toplamı |
| data_source | Manuel stopwatch veya açık başlangıç/bitiş timestamp'i; başarı ekranı/redirect gözlemi |
| collection_method | Kullanıcı niyeti oluştuğunda başlat; kayıt başarıyla görünür olduğunda veya kullanıcı vazgeçtiğinde durdur; sonucu kodla |
| sampling_rule | Her aktif günde ilk üç uygun capture denemesi; safety/failure olayları sampling dışında ayrıca eksiksiz kaydedilir |
| target | 7 günlük baseline sonrası 30 günlük pilotta median `<=30 sn`, p90 `<=60 sn`, failure rate `<=5%` |
| warning_threshold | Median `>30 sn` veya p90 `>60 sn` veya failure rate `>5%`; tek günlük örnekle değil haftalık pencerede değerlendirilir |
| blocker_threshold | Median `>60 sn`, p90 `>120 sn` veya failure rate `>20%` iki aktif günde tekrarlanır; ya da güvenli kayıt yapılamaz |
| privacy_rule | Capture text, proje/kişi/konum, source ID ve ekran görüntüsü loglanmaz; yalnız tür, süre ve outcome |
| owner | Pilot owner |
| review_cadence | Gün sonu; Gün 7; 30 günlük pilotta haftalık ve final |

Başlangıç `user_intent_at`, kullanıcının “bunu CSE'ye kaydedeceğim” kararını
verdiği andır. Bitiş, source kaydın başarı sayfasında/listede görünmesidir.
Yanlış kayıt türü açılması veya kayıt tamamlanamaması failure'dır.

Unified source'taki hızlı `+ Unutma` için median `<8 sn` ürün yönü korunur.
Buradaki bütün capture türlerini kapsayan median `<=30 sn` / p90 `<=60 sn`
değerleri ilk saha kabul kapısıdır; `<8 sn` yönünü supersede eden production
garantisi değildir. Follow-up segmenti summary'de ayrıca gösterilir.

### M02 — Geri bulma süresi

| Alan | Tanım |
|---|---|
| metric_id | `M02_RETRIEVAL_DURATION` |
| name | Doğru kaydı geri bulma süresi |
| purpose | Kullanıcının proje, tür, tarih ve durum bağlamında hedef kayda hızlı ve doğru dönebildiğini ölçmek. |
| unit | Saniye; ayrıca success/failure sayısı ve oranı |
| numerator | Her valid denemede `correct_record_opened_or_stop_at - search_intent_at` saniyesi; failure rate için yanlış/bulunamayan deneme sayısı |
| denominator | Bütün valid retrieval denemeleri |
| data_source | Manuel stopwatch/açık timestamp ve kullanıcı tarafından doğru kayıt doğrulaması |
| collection_method | Senaryo kartını seç, arama/listeleme niyetinde başlat, doğru detail açıldığında veya arama bırakıldığında durdur |
| sampling_rule | Her aktif günde ilk iki doğal geri bulma ihtiyacı; haftalık rotasyonda proje, tür, tarih ve açık/kapalı senaryoları |
| target | Median `<=20 sn`, p90 `<=45 sn`, success rate `>=95%` |
| warning_threshold | Median `>20 sn`, p90 `>45 sn` veya success rate `<95%` |
| blocker_threshold | Median `>45 sn`, p90 `>120 sn` veya success rate `<80%` iki aktif günde tekrarlanır; doğru kayıt güvenle ayırt edilemez |
| privacy_rule | Arama metni ve kayıt içeriği yazılmaz; yalnız scenario code, süre ve outcome |
| owner | Pilot owner |
| review_cadence | Gün sonu; Gün 7; haftalık ve Gün 30 |

Doğru kayıt bulunamazsa duration yine yazılır ve outcome `not_found` olur.
Yanlış kaydın açılıp doğru sanılması `wrong_record` failure'ıdır ve safety triage
gerektirebilir.

İlk 7 gün M02 için de baseline penceresidir; aynı formül ve scenario kodları
30 günlük karşılaştırmada değiştirilmez.

### M03 — Veri kaybı

| Alan | Tanım |
|---|---|
| metric_id | `M03_CONFIRMED_DATA_LOSS` |
| name | Confirmed veri kaybı veya source corruption |
| purpose | Başarıyla kaydedildiği doğrulanan source kayıt/event'in sonradan bulunamaması, bozulması veya restore sonrası eksilmesini yakalamak. |
| unit | Confirmed olay sayısı; ayrıca incident rate |
| numerator | Confirmed missing/corrupt/source-restore mismatch olayları |
| denominator | Pilot sırasında başarıyla kaydedildiği doğrulanan kayıtlar ve rehearsal'da beklenen source öğeleri |
| data_source | Source detail/list görünürlüğü, append-only history, Backup verify ve clean-target restore karşılaştırması |
| collection_method | Şüphede pilotu durdur; yeni immutable incident ID aç; source/backup/restore kanıtını owner-controlled alanda incele; sonucu confirmed/disproved yap |
| sampling_rule | Census; bütün şüpheli olaylar, bütün restore rehearsal mismatch'leri |
| target | `0` confirmed olay |
| warning_threshold | Tek `suspected` olay; triage tamamlanana kadar ölçüm sonucu açık kalır |
| blocker_threshold | `>=1` confirmed veri kaybı veya source corruption |
| privacy_rule | Pilot logunda içerik/source UUID/path yok; yalnız incident ID, sınıf ve kanıt durumu; hassas kanıt repo/GitHub dışı owner alanında |
| owner | Pilot owner; gerekirse incident reviewer |
| review_cadence | Olay anında; her gün sonu; Backup/Restore sonrası; final |

Restore sonucu eksikse “eski kayıt zaten yoktu” tahmini yapılmaz. Pre-restore
inventory ve post-restore doğrulama uyuşmadan PASS verilmez.

### M04 — Kaçırılan takip

| Alan | Tanım |
|---|---|
| metric_id | `M04_MISSED_FOLLOW_UP` |
| name | Kaçırılan takip |
| purpose | Kaydedilmiş bir follow-up/routine action'ın CSE nedeniyle zamanında görünür veya işlenebilir olmamasını ölçmek. |
| unit | Olay sayısı ve due-item başına oran; `critical` / `normal` boyutu |
| numerator | CSE kaynaklı confirmed missed follow-up sayısı |
| denominator | Pilot döneminde attention/deadline/due olan kaydedilmiş follow-up ve routine action sayısı |
| data_source | Bugün/Geciken/Dönüş bekliyorum/routine görünümü, source lifecycle/history ve gün sonu reconciliation |
| collection_method | Due inventory ile gün içinde görünür/işlenmiş inventory'yi karşılaştır; `not_recorded`, `user_choice`, `cse_visibility`, `cse_integrity` neden kodunu ayır |
| sampling_rule | Census; bütün due kayıtlar ve bildirilen kaçırmalar |
| target | CSE kaynaklı critical `0`; normal `0` hedef, her normal olay için düzeltme kararı |
| warning_threshold | Bir normal suspected/confirmed CSE kaynaklı olay veya neden sınıfı belirsiz olay |
| blocker_threshold | Bir critical CSE kaynaklı olay; ya da aynı normal CSE nedeni iki kez tekrarlanır |
| privacy_rule | Takip metni, kişi ve proje yazılmaz; yalnız anonim event ID, severity ve reason code |
| owner | Pilot owner |
| review_cadence | Gün sonu due reconciliation; olay anında; haftalık/final |

Kullanıcının hiç CSE'ye kaydetmediği iş `not_recorded` olarak ayrı tutulur;
CSE kaynaklı missed follow-up payına eklenmez ama kâğıda/haricî araca dönüş
analizine girebilir.

`critical`, kaçırılması iş güvenliği, geri döndürülemez kalite/kanıt kaybı veya
zorunlu zaman kapısı açısından ciddi sonuç doğurabilecek takip demektir.
Mümkünse severity due olmadan önce owner tarafından seçilir; sonuç kötü çıktı
diye sonradan düşürülmez. Pilot logu severity gerekçesindeki gerçek içeriği
taşımaz.

### M05 — Attachment / hash bütünlüğü

| Alan | Tanım |
|---|---|
| metric_id | `M05_ATTACHMENT_INTEGRITY_FAILURE` |
| name | Managed attachment bütünlük hatası |
| purpose | Missing file, hash mismatch, size mismatch, unsafe path, orphan veya açılamayan managed byte olaylarını ölçmek. |
| unit | Confirmed olay sayısı ve doğrulanan attachment başına oran |
| numerator | Confirmed `missing`, `hash_mismatch`, `size_mismatch`, `unsafe_path`, `orphan` veya unreadable-byte olayları |
| denominator | Pilot sırasında doğrulanan managed attachment sayısı |
| data_source | Mevcut attachment detail verification, reconciliation sonucu, Backup verify ve restore sonrası byte/hash kontrolü |
| collection_method | Attachment açma/viewer hatasını önce retry et; byte verification/reconciliation ile gerçek bütünlük hatasından ayır |
| sampling_rule | Oluşturulan bütün attachment'lar en az bir kez; şüpheli olayların tamamı; Backup/Restore inventory'sinin tamamı |
| target | `0` confirmed integrity failure |
| warning_threshold | Tek transient viewer/UI error veya tek suspected integrity olayı |
| blocker_threshold | Tek confirmed integrity failure; aynı transient viewer nedeni üç kez tekrarlanırsa kullanım blocker'ı |
| privacy_rule | Dosya adı, path, hash değeri ve içerik loga yazılmaz; yalnız anonim attachment event ID ve status code |
| owner | Pilot owner |
| review_cadence | Upload/açma anı; gün sonu; Backup/Restore sonrası; final |

Viewer'ın geçici açılamaması gerçek byte hatası değildir. `hash_mismatch` veya
`missing` gibi store/reconciliation kanıtı olmadan integrity failure confirmed
sayılmaz; şüphe yine triage bitene kadar açık kalır.

### M06 — Backup doğrulama başarısı

| Alan | Tanım |
|---|---|
| metric_id | `M06_BACKUP_VERIFY_PASS_RATE` |
| name | Backup üretimi ve Backup'ı Doğrula başarısı |
| purpose | Desteklenen format/schema'da felaket kurtarma artifact'ının exact verifier kapısını geçtiğini kanıtlamak. |
| unit | PASS yüzdesi ve attempt count |
| numerator | Başarıyla oluşturulup `verify-backup` PASS alan planlı Backup sayısı |
| denominator | Başlatılan planlı Backup verify attempt sayısı |
| data_source | Mevcut `app.ops backup` ve `app.ops verify-backup` exit/result bilgisi |
| collection_method | Yeni output path kullan; üretim ve verifier adımlarını ayrı outcome olarak kaydet; artifact içeriğini pilot loguna kopyalama |
| sampling_rule | Gün 0 preflight ve Gün 7 gate'te en az birer verify; 30 günde haftalık en az bir verify ve final verify |
| target | `100% PASS`; 30 günlük pilotta son doğrulanmış Backup yaşı `<=7 gün` |
| warning_threshold | Planlı attempt'in zamanında yürütülmemesi veya doğrulanmış Backup yaşının `>7 gün` olması |
| blocker_threshold | Tek verifier failure, Backup üretim failure'ı veya mevcut artifact'ın üzerine yazma ihtiyacı |
| privacy_rule | Archive path/adı, manifest içeriği ve private veri loglanmaz; yalnız attempt ID, format/schema etiketi ve PASS/FAIL |
| owner | Pilot owner |
| review_cadence | Her planlı Backup'ta; haftalık; gate öncesi |

Backup verify PASS, Restore PASS değildir; iki metrik birbirinin yerine
kullanılmaz.

### M07 — Clean restore rehearsal başarısı

| Alan | Tanım |
|---|---|
| metric_id | `M07_CLEAN_RESTORE_PASS_RATE` |
| name | Disposable clean-target Restore rehearsal başarısı |
| purpose | Doğrulanmış Backup'ın source'a veya mevcut data root'a dokunmadan yeni hedefte açılabildiğini ve temel kayıt/attachment/history'nin korunduğunu ölçmek. |
| unit | PASS yüzdesi ve rehearsal count |
| numerator | Verify + yeni hedef Restore + repository/attachment/history smoke kontrollerini geçen rehearsal sayısı |
| denominator | Başlatılan planlı clean restore rehearsal sayısı |
| data_source | Mevcut `app.ops restore`, yeni hedef, app reopen ve sanitize edilmiş count/status karşılaştırması |
| collection_method | Var olmayan disposable target seç; önce Backup verify; restore et; source'u değiştirmeden smoke/reconciliation yap; hedefi production olarak aktive etme |
| sampling_rule | Gün 0'da plan ve disposable root doğrulaması; 30 günlük pilotta en az bir tam rehearsal; ayrıca restore-affecting incident sonrası |
| target | `100% PASS`; 30 günlük gate için en az `1` PASS |
| warning_threshold | Planlı rehearsal'ın ertelenmesi, yeterli disk/target kanıtı olmaması veya incomplete smoke check |
| blocker_threshold | Tek restore, migration, repository reopen, count/history veya attachment reconciliation failure'ı |
| privacy_rule | Source/target absolute path, kayıt içeriği ve hash loglanmaz; yalnız rehearsal ID, supported version ve kontrol sonucu |
| owner | Pilot owner; gerekirse incident reviewer |
| review_cadence | Rehearsal anında; Gün 30 gate öncesi |

Restore hiçbir zaman gerçek data root'un üzerine çalıştırılmaz. Disposable hedef
varsa yeni hedef seçilir; mevcut hedefi temizlemek bu protokolün parçası değildir.

### M08 — Kâğıda veya haricî araca dönüş

| Alan | Tanım |
|---|---|
| metric_id | `M08_EXTERNAL_FALLBACK_RATE` |
| name | Kâğıda / haricî araca dönüş oranı ve nedeni |
| purpose | Kullanıcının CSE yerine kâğıt, kendine mesaj, not uygulaması veya Excel seçtiği sürtünmeleri ölçmek. |
| unit | Olay sayısı, eligible work event başına yüzde ve reason-code dağılımı |
| numerator | CSE yerine veya CSE'ye ek olarak haricî araç kullanılan olay sayısı |
| denominator | Pilot sırasında capture/retrieval/follow-up için oluşan eligible work event sayısı |
| data_source | Günlük anonim self-report ve reason code |
| collection_method | Olay anında veya gün sonunda yalnız araç kategorisi ve birincil neden kodunu kaydet; ham mesaj/içerik toplama |
| sampling_rule | Census self-report; unutulan olay gün sonunda `late_report` etiketiyle eklenir |
| target | 7 günde baseline; 30 günde oran 7 günlük baseline'ı aşmaz veya sapma için kabul edilmiş ürün kararı vardır |
| warning_threshold | 30 günlük haftalık oran baseline'dan `>5` yüzde puan yüksek; aynı neden üç aktif günde görülür |
| blocker_threshold | Güvenli olmayan workaround; ya da oran iki ardışık haftada `>25%` ve kabul edilmiş düzeltme planı yok |
| privacy_rule | Ham mesaj, konuşma, not, kişi/proje ve belge içeriği kaydedilmez |
| owner | Pilot owner |
| review_cadence | Gün sonu; haftalık top-3 reason; Gün 7/Gün 30 |

Allowed reason codes:

```text
speed
connectivity
ui_friction
missing_feature
trust
device_or_battery
document_viewing
habit
other_sanitized
```

`other_sanitized` yalnız hassas içerik taşımayan kısa kategori notu alabilir.

`eligible work event`, kullanıcının capture, retrieval veya due follow-up/routine
işini CSE ile yapma fırsatının gerçekten oluştuğu olaydır. İş fırsatı yokken
payda büyütülmez; sonradan bildirilen fırsat `late_report` olarak işaretlenir.

### M09 — Private/project sızıntısı

| Alan | Tanım |
|---|---|
| metric_id | `M09_SCOPE_PRIVACY_LEAK` |
| name | Private/project çıktı sızıntısı |
| purpose | Private kayıt veya başka projeye ait içeriğin paylaşılabilir proje/günlük çıktısına girmediğini doğrulamak. |
| unit | Confirmed olay sayısı ve incelenen artifact başına oran |
| numerator | Confirmed private, wrong-project veya unknown-scope leakage olayı |
| denominator | Pilot sırasında üretilip incelenen paylaşılabilir Günlük Çıktı/artifact sayısı |
| data_source | Artifact inventory/manifest ve source scope/project'in owner tarafından fail-closed karşılaştırılması |
| collection_method | Gerçek içerik kopyalamadan allowed record type/scope/project sonucu kontrol edilir; belirsizlikte artifact paylaşılmaz |
| sampling_rule | Census; bütün paylaşılabilir artifact'lar paylaşım öncesi |
| target | `0` leakage |
| warning_threshold | Tek scope/project kanıtı belirsiz artifact; paylaşım durdurulur |
| blocker_threshold | Tek confirmed private veya wrong-project leakage |
| privacy_rule | Pilot logunda artifact payload, source UUID, title veya path bulunmaz; yalnız artifact event ID ve eligibility sonucu |
| owner | Pilot owner |
| review_cadence | Her artifact öncesi; olay anında; gate'lerde |

ADR-0001/0003 gereği project bağlantısı scope yerine geçmez. Mevcut Günlük
Çıktı observation-only sınırı korunur; gelecekteki Proje Paketi uygulanmış gibi
varsayılmaz.

Source scope alanı henüz uygulanmamış build'de eligibility, ADR-0001'in
compatibility mapping'iyle değerlendirilir: observation `project`, follow-up ve
routine `private`. `project_id IS NOT NULL` üzerinden scope tahmini yapılmaz.

### M10 — Ölçüm bütünlüğü

| Alan | Tanım |
|---|---|
| metric_id | `M10_MEASUREMENT_COMPLETENESS` |
| name | Pilot ölçüm bütünlüğü |
| purpose | Başarı kararının eksik veya sonradan tahmin edilmiş veriyle verilmesini önlemek. |
| unit | Zorunlu hücre tamamlama yüzdesi; invalid/missing sample sayısı |
| numerator | Zamanında ve kurala uygun doldurulmuş zorunlu metric cells |
| denominator | Örnekleme planına göre beklenen zorunlu metric cells |
| data_source | Günlük log validation checklist ve summary reconciliation |
| collection_method | Gün sonunda boş/invalid alanları işaretle; bilinmeyen değeri tahmin etme; geç eklemeyi `late_entry` yap |
| sampling_rule | Bütün pilot günleri ve bütün zorunlu metrikler |
| target | `100%`; safety olay ve gate kanıtlarında eksik alan `0` |
| warning_threshold | `<100%` ve `>=95%`; eksik alanların karar etkisi açıklanır |
| blocker_threshold | `<90%`, safety kanıtı eksikliği veya median/p90 için minimum örneğin sağlanmaması |
| privacy_rule | Eksikliği tamamlamak için gerçek içerik kopyalanmaz veya source log export edilmez |
| owner | Pilot owner |
| review_cadence | Gün sonu, haftalık, gate öncesi |

`90–95%` aralığı otomatik PASS değildir. Eksik veri safety veya privacy
sonucunu etkiliyorsa oran ne olursa olsun `insufficient_evidence` olur.

## 5. Örnekleme ve ölçüm yöntemi

### 5.1 Aktif gün

Aktif pilot günü, CSE'de en az bir doğal eligible iş olayı bulunan ve gün sonu
review'i tamamlanan gündür. İş olmayan gün sıfır uydurma denemeyle doldurulmaz;
`inactive_day` ve nedeni kaydedilir.

`normal | dense` etiketi gün başında beklenen iş yüküne göre owner tarafından
seçilir; günün metric sonucu görüldükten sonra değiştirilmez. Beklenmeyen saha
yoğunluğu etiketi değiştirdiyse eski/yeni etiket ve sanitize edilmiş neden
audit notunda korunur.

### 5.2 Yedi günlük minimum örnek

- 7 ardışık takvim günü, en az 5 aktif gün;
- en az 10 valid capture denemesi;
- en az 8 valid retrieval denemesi;
- capture içinde doğal olarak oluştuysa follow-up ve observation; due routine
  yoksa routine örneği `not_applicable`;
- retrieval rotasyonunda mümkün olan proje, tür, tarih ve açık/kapalı boyutları;
- pilotta oluşturulan bütün attachment'lar doğrulanır; en az 3 attachment yoksa
  M05 performansı `low_sample`, safety olayları yine geçerlidir;
- Gün 0 ve Gün 7'de en az birer Backup verify PASS.

Minimum karşılanmazsa sonuç `INSUFFICIENT_EVIDENCE` olur; kullanıcıyı sırf
sayacı doldurmak için sahte production kayıt oluşturmaya zorlamaz.

### 5.3 Otuz günlük minimum örnek

- 30 ardışık takvim günü, en az 20 aktif gün ve dört haftalık review;
- en az 40 valid capture denemesi;
- en az 24 valid retrieval denemesi;
- mümkün olan bütün capture türleri ve retrieval senaryoları;
- bütün gerçek attachment doğrulamaları; `n < 10` ise M05 `low_sample`;
- haftalık Backup verify ve en az bir clean restore rehearsal PASS;
- yoğun gün/normal gün etiketi ve kayıt türü kullanım dağılımı;
- dış araç fallback rate ve her hafta top-3 reason.

### 5.4 Ölçüm yükünü sınırlama

Performans için günde en fazla üç capture ve iki retrieval zamanlanır. Safety,
privacy, integrity, missed follow-up ve fallback olayları bu cap'e tabi değildir.
Stopwatch ölçümü işi tehlikeli hale getiriyorsa ölçüm bırakılır, iş güvenliği
öncelenir ve satır `unsafe_to_measure` olur.

## 6. Başlangıç hedefleri, warning ve blocker eşikleri

| Sınıf | Target | Warning | Blocker |
|---|---|---|---|
| Hız/kullanılabilirlik | M01/M02 target ve minimum sample | Target sapması veya low sample | Tekrarlayan aşırı süre/failure ya da güvenli kullanımın imkânsızlığı |
| Veri güvenliği | Veri kaybı `0` | Suspected olay | Confirmed olay `>=1` |
| Takip güvenilirliği | Critical missed `0` | Normal/suspected olay | Critical bir olay veya tekrarlayan aynı CSE nedeni |
| Attachment | Confirmed failure `0` | Transient/suspected olay | Confirmed integrity failure |
| Backup/Restore | Planlı işlemlerde `100% PASS` | Gecikmiş/incomplete prova | Verifier veya Restore failure |
| Privacy | Leakage `0` | Eligibility belirsizliği | Confirmed private/wrong-project leakage |
| Ölçüm | Complete ve minimum sample | Küçük eksik/late entry | Güvenilmez veya yetersiz karar kanıtı |

Performance warning, safety blocker ile aynı değildir. Safety blocker varken
ortalama sürelerin iyi olması pilotu başarılı yapamaz.

## 7. Gün 0 preflight

Pilot owner aşağıdakileri sırasıyla tamamlar:

1. Pilotun ayrı executable Issue numarası ve izin kapsamını kaydeder.
2. Pilot öncesi minimum ürün diliminin ayrı kabul kanıtını ve owner'ın build
   readiness onayını doğrular. Bu protokol current `master`ı kendiliğinden
   pilot-ready ilan etmez.
3. Çalışan exact commit/build ve `schema_version` değerini kaydeder.
4. `backup_format_version` ve desteklenen restore schema bilgisini kaydeder;
   uygulanmamış formatları varmış gibi yazmaz.
5. Gerçek pilot data root ile disposable restore root'un farklı olduğunu path'i
   loga kopyalamadan `separation_confirmed=yes` olarak doğrular.
6. `CSE_DATA_ROOT` veya seçilmiş root'un owner tarafından bilinçli seçildiğini,
   eski root'un sessiz taşınmadığını doğrular.
7. Yeni path'e Backup üretir ve Backup'ı Doğrula PASS alır.
8. 30 günlük pilotta kullanılacak clean restore rehearsal günü, disk alanı ve
   var olmayan hedef kuralını planlar.
9. Günlük ve summary şablonlarının boş/sentetik olduğunu doğrular.
10. Stopwatch/timestamp yöntemini bir sentetik denemeyle öğretir; bu deneme pilot
   metriğine girmez.
11. Stop kriterlerini, incident ID kullanımını ve hassas kanıtın GitHub/repo'ya
    konmayacağını owner'a açıklar.
12. Public internet, telemetry ve cloud gönderimi olmadığını doğrular.
13. Preflight checklist tamamlanmadan Gün 1'i başlatmaz.

## 8. Yedi günlük pilot protokolü

### Her gün başlangıcı

1. Gün kimliği, takvim tarihi ve `normal | dense | inactive` gün tipi seçilir.
2. Önceki açık incident/warning kontrol edilir; stop varsa pilot başlamaz.
3. CSE'nin beklenen data root/build ile açıldığı, `/today` veya ana health
   yüzeyinin erişilebilir olduğu doğrulanır.

### Gün içinde

1. İlk üç doğal capture ve ilk iki retrieval denemesi ölçülür.
2. Bütün failure, missed follow-up, attachment, privacy ve fallback olayları
   anonim event ID ile kaydedilir.
3. Şüpheli veri kaybı/integrity/privacy olayında normal pilot işlemi durdurulur.
4. Gerçek saha içeriği veya ekran görüntüsü günlük şablona yapıştırılmaz.

### Gün sonu

1. Due takip/routine inventory ile görünür/işlenmiş sonuç reconcile edilir.
2. Attachment olayları transient veya integrity olarak ayrılır.
3. Haricî araç fallback sayısı ve reason code dağılımı tamamlanır.
4. Eksik/invalid/late ölçümler M10'a yazılır; tahminle doldurulmaz.
5. Açık warning/blocker ve kısa sanitize edilmiş değerlendirme yazılır.
6. Stop yoksa ertesi güne devam kararı kaydedilir.

### Gün 7 değerlendirmesi

1. M01/M02 median, p90, success/failure rate ve sample dağılımı hesaplanır.
2. M03–M10 count/rate, suspected/confirmed ve trend sonuçları çıkarılır.
3. Fallback top-3 nedeni ve tekrarlayan friction'lar belirlenir.
4. Gün 7 Backup verify PASS doğrulanır.
5. Bütün blocker'lar ve çözüm sahipleri listelenir.
6. Sonuç yalnız `PASS_TO_30_DAY`, `CONDITIONAL`, `FAIL` veya
   `INSUFFICIENT_EVIDENCE` olabilir.
7. 30 günlük devam kararı pilot owner tarafından açıkça yazılır; otomatik
   çıkarılmaz.

## 9. Otuz günlük pilot protokolü

Yedi günlük günlük disiplin sürer; ek olarak:

- her hafta sample count, median/p90, failure ve safety metrik trendi çıkarılır;
- normal ve dense gün sonuçları ayrı gösterilir; örnek azsa fark iddiası yoktur;
- observation/follow-up/routine action kullanım dağılımı yalnız count olarak
  raporlanır;
- Backup freshness ve haftalık verifier PASS kaydedilir;
- planlanan haftada en az bir clean restore rehearsal tamamlanır;
- fallback rate ve top-3 reason haftadan haftaya karşılaştırılır;
- düzeltme planı uygulanırsa başlangıç tarihi yazılır; önce/sonra örnekleri
  karıştırılmadan ayrı gösterilir;
- yeni özellik kapsamı sırf pilot devam ediyor diye genişletilmez.

Gün 30'da summary template kullanılır, safety gate'leri önce değerlendirilir,
sonra performans ve fallback sonuçları incelenir.

## 10. Günlük log ve özet şablonları

Bağlayıcı boş şablonlar:

- `docs/pilot/field_pilot_daily_log_template.md`
- `docs/pilot/field_pilot_summary_template.md`

Şablonlar source record değildir; Backup, Hafızayı İndir veya Proje Paketi
yerine geçmez. Doldurulmuş gerçek pilot loglarının bu repository'ye commit
edilmesi bu Issue tarafından yetkilendirilmez. Ayrı pilot Issue veri saklama
yolunu ve retention süresini açıkça seçmelidir.

## 11. Stop kriterleri ve incident escalation

### 11.1 Anında stop

Aşağıdakilerden biri observed/suspected olduğunda yeni pilot işlemi durur:

- veri kaybı veya source corruption;
- private/project veya wrong-project sızıntısı;
- Backup verifier veya clean Restore failure;
- confirmed attachment/hash/path bütünlüğü hatası;
- critical missed follow-up;
- kullanıcıyı güvenli olmayan workaround'a zorlayan durum;
- safety kararını etkileyen ölçüm eksikliği.

### 11.2 Escalation adımları

1. Yeni mutation ve artifact paylaşımını durdur.
2. `INC-YYYYMMDD-NN` biçiminde incident ID aç; gerçek içerik yazma.
3. Kaynak okunabiliyorsa mevcut artifact'ın üzerine yazmadan yeni Backup üret
   ve verifier sonucunu ayrı kaydet. Verifier başarısızsa artifact'ı PASS sayma.
4. Source, mevcut Backup ve gerçek data root'u mutate/repair etme.
5. Hassas kanıtı repo, GitHub Issue veya pilot loguna koyma; owner-controlled
   ayrı alanda koru.
6. Olayı `suspected`, `confirmed` veya `disproved` olarak sınıflandır.
7. Root cause, containment, recovery ve tekrar başlatma acceptance'ı için ayrı
   executable Issue aç; hassas olmayan özet kullan.
8. Pilot ancak owner açık restart kararı ve ilgili safety kontrolü PASS sonrası
   devam eder.

Confirmed safety blocker düzeltme planı yazıldı diye aynı pilot penceresinde
PASS'e çevrilmez. Düzeltme sonrası yeni ve ayrıştırılmış bir doğrulama penceresi
gerekir.

## 12. Gizlilik ve veri minimizasyonu

Pilot loglarında bulunamaz:

- gerçek kayıt gövdesi veya arama metni;
- fotoğraf, dosya, screenshot veya attachment adı/path/hash;
- kişi, telefon, e-posta, firma veya proje hassas bilgisi;
- source UUID, absolute data-root path veya secret;
- WhatsApp/not uygulaması ham mesajı veya konuşma içeriği.

Tutulabilecek minimumlar:

- süre ve sayaç;
- kayıt türü/senaryo kategorisi;
- anonim pilot event/incident kimliği;
- reason/severity/evidence status;
- PASS/FAIL ve sanitize edilmiş kısa not.

Pilot logu `private` içeriği güvenli hale getiren cryptographic sınır değildir.
Dosya owner-controlled tutulur, retention ayrı pilot Issue'da belirlenir ve
paylaşım minimum summary ile sınırlanır. Telemetry/analytics/cloud yoktur.

## 13. Başarı ve Faz 1'e geçiş kapıları

### 13.1 Yedi günlük geçiş kapısı

`PASS_TO_30_DAY` için tümü zorunludur:

- M03 confirmed veri kaybı `0`;
- M04 critical CSE kaynaklı missed follow-up `0`;
- M05 confirmed attachment integrity failure `0`;
- M09 confirmed leakage `0`;
- Gün 0 ve Gün 7 Backup verify PASS;
- M01/M02 minimum sample ve hesaplanabilir median/p90;
- açık safety blocker yok;
- warning'ların sahibi, hedef tarihi ve kabul yöntemi var;
- M10 karar kanıtı yeterli;
- owner'ın açık 30 günlük devam kararı var.

Safety gate geçer fakat yalnız performance warning varsa `CONDITIONAL`
verilebilir. Safety blocker, failed Backup verify veya eksik safety kanıtı
`CONDITIONAL` olamaz.

### 13.2 Otuz günlük kapanış kapısı

Faz 1'e geçiş önerisi için tümü zorunludur:

- confirmed veri kaybı, private leakage ve critical missed follow-up `0`;
- attachment confirmed integrity failure `0`;
- haftalık Backup verify sonuçları `100% PASS`;
- en az bir clean restore rehearsal PASS;
- M01 median `<=30 sn`, p90 `<=60 sn`, failure rate `<=5%` veya sapma için
  owner tarafından kabul edilmiş, ölçülebilir yeniden doğrulama planı;
- M02 median `<=20 sn`, p90 `<=45 sn`, success rate `>=95%` veya aynı nitelikte
  yeniden doğrulama planı;
- fallback top-3 nedeni ve her biri için `fix | accept | defer` ürün kararı;
- minimum sample ve M10 ölçüm bütünlüğü;
- açık blocker olmaması;
- owner'ın ölçülebilir kanıta dayalı Faz 1 geçiş kararı.

Bir performance düzeltme planı Faz 1 önerisini `CONDITIONAL` yapabilir; safety
ve privacy sapması yapamaz. `INSUFFICIENT_EVIDENCE`, PASS değildir.

## 14. Pilotun yürütülmediği açık sınır ve sonraki Issue

Issue #167 yalnız protokol ve boş şablonları üretir. Şu bilgiler bu repository
değişikliğinde yoktur ve varmış gibi iddia edilemez:

- gerçek pilot başlangıç/bitiş tarihi;
- gerçek build üzerinde Gün 0 PASS;
- gerçek capture/retrieval süreleri;
- gerçek Backup/Restore pilot sonucu;
- gerçek fallback veya incident listesi;
- Faz 1'e geçiş onayı.

Sonraki executable Issue önerisi:

```text
Başlık: Run isolated 7-day field acceptance pilot
Ön koşul: Pilot öncesi minimum ürün dilimi ve owner-approved build
Kapsam: Gün 0 + 7 ardışık gün; bu protokolün boş şablonlarının owner-controlled kopyaları
Zorunlu: exact build/schema, data-root ayrımı, retention, stop authority, daily review
Yasak: gerçek içerikleri GitHub/repository'ye koyma; scope/format/production davranışını pilot içinde değiştirme
Çıktı: sanitize edilmiş 7 günlük summary ve açık 30 günlük devam kararı
```

30 günlük pilot, yalnız 7 günlük gate sonucu ve owner'ın açık kararıyla ayrı
Issue olarak açılır. Bu belge tek başına saha kabulü veya Faz 1 geçişi değildir.
