# Podcast 022 - Adim 132-136 NotebookLM Podcast Notu

## 1. Baslik

Podcast 022, CSE'nin record ID hattinda hard validation'a kosmadan once merkezi sozlesme, mapping helper, API siniri, soft validation plani ve diagnostic helper implementasyonu ile nasil guvenli bir veri omurgasi kurdugunu anlatir.

Bu bolumun basligi: Record ID omurgasi, diagnostic katmani ve guvenli validation ertelemesi.

## 2. Kapsanan adimlar

- Adim 132 - Record ID constants and mapping helper implementation.
- Adim 133 - Record ID helper API boundary ve test example standardization plan.
- Adim 134 - Record ID soft validation plan.
- Adim 135 - Record ID soft validation diagnostic helper implementation plan.
- Adim 136 - Record ID diagnostic helper implementation.

## 3. Bu bolumun ana fikri

Bu bolumun ana fikri, record ID alaninda guvenilirlik ile geriye uyumluluk arasindaki dengeyi korumaktir.

CSE'de `target_record_id` tek bir basit format degildir. Proje, uygunsuzluk, aday uygunsuzluk, malzeme teslimi, gunluk log, saha notu, attachment, audit event, export, backup ve handover gibi farkli kayit aileleri vardir. Testlerde de canonical ve legacy ID ornekleri birlikte yasar.

Bu nedenle Adim 132-136 araligi, "hemen reddet" yaklasimi yerine "once merkezi bilgi, sonra gorunurluk, en son gerekirse hard validation" yaklasimini izler.

## 4. Neden dogrudan hard validation'a gecilmedi?

Dogudan hard validation'a gecilmedi, cunku mevcut veri ve test ornekleri tek formatta degildir.

`NCR-001`, `REC-2026-0007`, `ATT-2026-0001`, `file-att-001`, `audit-001`, `MAT-DEL-001`, `NCR-CAND-001` gibi ornekler ayni proje icinde farkli donemlerin ve farkli kayit ailelerinin izlerini tasir.

Erken bir regex veya prefix reddi, gercek ve anlamli legacy kayitlari kirabilir. Daha da onemlisi, `project_record` gibi genis target type degerleri tek prefixe indirgenemez. Bu target type birden fazla kayit ailesini temsil edebilir.

Bu yuzden hard validation hala ertelenmistir. Erteleme belirsizlik degil, bilincli bir veri guvenligi kararidir.

## 5. Adim adim ozet

### Adim 132 - Record ID constants and mapping helper implementation

Adim 132'de record ID hattinin ilk dar kod katmani eklendi.

`RECORD_ID_PREFIXES`, `TARGET_RECORD_TYPE_TO_ID_FAMILY` ve `TARGET_RECORD_TYPE_TO_ID_PREFIXES` merkezi bilgi tablolari olarak tanimlandi.

`get_record_id_family_for_target_type` ve `get_allowed_record_id_prefixes_for_target_type` helper fonksiyonlari eklendi. Bu helperlar validation kapisi degildir. Sadece hangi target type icin hangi ID ailesinin ve prefixlerin beklenebilecegini soyler.

Bilinmeyen target type degerleri helper seviyesinde temiz hata alir, fakat `AuditEventRecord.target_record_id` icin hard validation eklenmez.

### Adim 133 - Helper API boundary ve test example standardization plan

Adim 133, helper API sinirini netlestirdi.

Bu adimda su karar onemlidir: Mapping helperlari constructor davranisini daraltmaz. Yani bu fonksiyonlar "bu ID kabul edilir mi, reddedilir mi?" sorusunun runtime kapisi degildir.

Test ornekleri de iki ayri kategori olarak dusunulmelidir:

- Mapping helper testleri.
- Model validation testleri.

Bu ayrim, helper katmaninin yanlislikla hard validation gibi kullanilmasini engeller.

### Adim 134 - Record ID soft validation plan

Adim 134, hard validation yerine once soft validation dusuncesini planladi.

Soft validation, kaydi reddetmeden bilgi veya uyari uretir. Bir ID canonical gorunebilir, legacy gorunebilir ya da prefix disi gorunebilir. Bu bilgi raporda kullanilir, fakat constructor davranisini daraltmaz.

Bu yaklasim audit raporlama, kalite kontrol ciktisi, export on kontrolu ve handover package on kontrolu icin daha guvenlidir.

### Adim 135 - Diagnostic helper implementation plan

Adim 135, soft validation fikrini somut diagnostic helper planina indirdi.

Planlanan cikti alanlari sunlardi:

- `target_record_type`
- `target_record_id`
- `expected_family`
- `allowed_prefixes`
- `observed_prefix`
- `is_compatible`
- `severity`
- `message`

Bu alanlar, bir record ID'nin neden canonical, legacy, prefix disi veya helper seviyesinde hatali gorundugunu aciklamaya yarar.

### Adim 136 - Record ID diagnostic helper implementation

Adim 136'da `diagnose_record_id_for_target_type(target_record_type, target_record_id)` helper fonksiyonu eklendi.

Helper mevcut mapping katmanini kullanir. Allowed prefixleri uzunluktan kisaya dener. Boylece `NCR-CAND`, `NCR-CA`, `MAT-DEL`, `CHK-RES`, `JSON-EXP` ve `file-att` gibi cok parcali prefixler ilk tireden yanlis bolunmez.

Severity yaklasimi soyledir:

- `info`: Canonical prefix ile uyumlu gorunen ID.
- `warning`: Legacy prefix ile uyumlu gorunen ID veya prefix disi ama reddedilmeyen ID.
- `error`: Bilinmeyen target type veya bos/gecersiz target ID gibi helper seviyesinde diagnostic uretilemeyen giris.

Bu helper veri reddetmez. Diagnostic dict dondurur.

## 6. Merkezi sozlesme ve mapping helper neden once geldi?

Merkezi sozlesme ve mapping helper once geldi, cunku validation ancak neyin beklendigini bildigimizde guvenli olur.

Bir ID'nin sadece metinsel olarak "tireli" olup olmadigini kontrol etmek yeterli degildir. Hangi target type hangi ID ailesine baglanabilir, hangi prefix canonicaldir, hangi prefix legacy olarak kabul edilebilir, bunlar onceden acik olmalidir.

Mapping helper katmani bu bilgiyi merkezi hale getirir. Boylece ileride raporlama, diagnostic veya test standardizasyonu ayni sozlesmeye bakabilir.

## 7. Helper API neden constructor davranisini daraltmiyor?

Helper API constructor davranisini daraltmiyor, cunku helperin rolu bilgi vermektir.

`AuditEventRecord` zaten target pair davranisini ve desteklenen `target_record_type` listesini kontrol eder. Fakat `target_record_id` formatini prefix bazli reddetmez.

Bu ayrim korunmazsa, bilgi helperi sessizce validation kapisina donusebilir. Bu da legacy ID orneklerini ve mevcut test davranisini kirabilir.

Bu bolumdeki ana ilke sudur: Helperlar once gorunurluk saglar; veri reddetme karari ayri ve daha gec bir mimari karardir.

## 8. Diagnostic helper neden dis kalite kontrol katmani?

Diagnostic helper dis kalite kontrol katmani olarak tasarlandi, cunku en guvenli ilk kullanim yeri raporlama ve gorunurluktur.

Bir handover on kontrolu, audit raporu veya QC ciktisi su sorulari sorabilir:

- Bu ID canonical prefix tasiyor mu?
- Bu ID legacy ama bilinen bir prefix mi?
- Bu ID target type icin beklenen prefixlerin disinda mi?
- Target type mapping'i bilinmiyor mu?

Bu sorularin cevabi kaydi reddetmeden uretilebilir. Boylece veri kaybi veya ani constructor kirilmasi olmadan kalite sinyali elde edilir.

## 9. Legacy ID ornekleri neden korunuyor?

Legacy ID ornekleri korunuyor, cunku proje gecmisindeki anlamli kayit baglantilarini temsil ederler.

`file-att-001` gibi bir ID yeni canonical formata tam uymasa da attachment gecmisini anlatabilir. `REC-1` veya `REC-2026-0007` gibi generic record ID'leri de audit hedef baglantilarinda degerli olabilir.

Bu ornekleri reddetmek, veri omurgasini guclendirmek yerine kanit zincirini zayiflatabilir.

Bu yuzden diagnostic helper legacy ID'leri `warning` olarak raporlar, fakat reddetmez.

## 10. AuditEventRecord.__post_init__ icine neden baglanmadi?

Diagnostic helper `AuditEventRecord.__post_init__` icine baglanmadi, cunku bu baglanti helperi fiilen runtime validation kapisina cevirirdi.

`__post_init__` icindeki her yeni red kosulu constructor davranisini daraltir. Bu adimda hedef constructor davranisini degistirmek degil, dis kalite kontrol icin bilgi uretmektir.

Bu ayrim, Adim 132-136 hattinin en kritik guvenlik siniridir.

## 11. target_record_id hard validation neden hala ertelendi?

`target_record_id` hard validation hala ertelendi, cunku diagnostic cikti daha yeni olgunlasmaya basladi.

Hard validation dusunulmeden once su konular daha uzun sure gozlemlenmelidir:

- Canonical prefixler gercek veriyle yeterince uyumlu mu?
- Legacy prefixler hangi raporlarda warning olarak gorunmeli?
- `project_record` gibi genis target type degerleri hangi ID ailelerini kapsamali?
- Test ornekleri canonical ve legacy kategorilerinde nasil standardize edilmeli?

Bu bolum hard validation onermiyor. Sadece hard validation'in neden bu asamada bilincli olarak uygulanmadigini aciklar.

## 12. Guvenilir veri omurgasina katkisi

Adim 132-136 araligi, CSE'nin veri omurgasina bes katki saglar.

Ilk olarak, record ID prefix bilgisi merkezi hale geldi.

Ikinci olarak, helper API ile model validation arasindaki sinir netlesti.

Ucuncu olarak, soft validation ve diagnostic output kavramlari ayrildi.

Dorduncu olarak, legacy ID ornekleri korunarak geriye uyumluluk saglandi.

Besinci olarak, audit, QC, export ve handover gibi dis katmanlar icin kullanilabilecek okunur diagnostic veri uretildi.

## 13. NotebookLM icin konusma akisi onerisi

1. Bolumu "neden hemen hard validation yapmadik?" sorusuyla ac.
2. Record ID orneklerinin tek formatta olmadigini anlat.
3. Adim 132'de mapping helper katmaninin merkezi sozlesme bilgisini koda tasidigini ozetle.
4. Adim 133'te helper API'nin validation kapisi olmadigini vurgula.
5. Adim 134-135'te soft validation ve diagnostic output fikrinin nasil olgunlastigini anlat.
6. Adim 136'da helperin nasil dict dondurdugunu, ama veri reddetmedigini acikla.
7. Kapanista legacy ID'leri korumanin kanit zinciri ve handover kalitesi icin neden onemli oldugunu vurgula.

## 14. One cikarilacak kavramlar

- Record ID sozlesmesi.
- ID ailesi.
- Canonical prefix.
- Legacy prefix.
- Target record type mapping.
- Helper API boundary.
- Soft validation.
- Diagnostic output.
- `info`, `warning`, `error` severity ayrimi.
- Geriye uyumluluk.
- Audit target record iliskisi.
- Handover on kontrolu.
- Hard validation ertelemesi.

## 15. Kapanis ozeti

Adim 132-136 araligi, CSE'nin record ID hattini acele sert kurallarla degil, kontrollu bilgi katmanlariyla guclendirdigi bir araliktir.

Once merkezi prefix ve ID ailesi mapping'i kuruldu. Sonra helper API'nin constructor davranisini daraltmayacagi netlestirildi. Ardindan soft validation ve diagnostic output planlandi. Son olarak, veri reddetmeyen `diagnose_record_id_for_target_type` helper'i eklendi.

Bu bolumun ana mesaji sudur: Guvenilir veri omurgasi, her uyumsuzlugu hemen hata yapmakla degil, once gorunur kilmakla baslar.
