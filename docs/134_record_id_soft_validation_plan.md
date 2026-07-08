# Adim 134 - Record ID Soft Validation Plan

## Amac

Bu adimin amaci, Adim 129-133 kararlarina dayanarak record ID soft validation icin ilk plan dokumantasyonunu hazirlamaktir.

Bu adim documentation-only / soft-validation-planning adimidir. Kod, model, test, soft validation helper, hard validation veya runtime davranisi degistirilmedi.

## Arka plan: Adim 129-133 zinciri

Adim 129, projedeki record ID alanlarini ve testlerde gorulen ID orneklerini envanterledi. Bu analiz, tek bir merkezi ID formatinin henuz olmadigini gosterdi.

Adim 130, central record ID contract planini hazirladi ve hard validation icin once sozlesme, mapping, test standardizasyonu ve migration dusuncesi gerektigini belirtti.

Adim 131, record ID constants ve mapping helper katmanini planladi.

Adim 132, `RECORD_ID_PREFIXES`, `TARGET_RECORD_TYPE_TO_ID_FAMILY`, `TARGET_RECORD_TYPE_TO_ID_PREFIXES`, `get_record_id_family_for_target_type` ve `get_allowed_record_id_prefixes_for_target_type` yapilarini ekledi. Bu helperlar sadece bilgi dondurur.

Adim 133, helper API sinirini netlestirdi: helperlar validation fonksiyonu gibi kullanilmayacak, test ornek standardizasyonu ve soft validation ayri adimlarda ele alinacak.

## Soft validation nedir?

Soft validation, veriyi reddetmeden bilgi, uyari veya diagnostic sonucu ureten kontrol katmanidir.

Soft validation su sorulara cevap verebilir:

- `target_record_type` bilinen bir target type mi?
- `target_record_id` bilinen prefix adaylarindan biriyle basliyor mu?
- Kullanilan ID canonical mi, legacy mi, yoksa bilinmeyen bir bicim mi?
- Bu kayit rapor veya kalite kontrol ciktisinda nasil isaretlenmeli?

Soft validation, model olusturmayi engellemez. Amaci uyumsuzluklari gorunur hale getirmektir.

## Hard validation'dan farki

Hard validation veri girisini reddeder. Uyumsuz deger icin hata uretir ve modelin olusmasini engeller.

Soft validation ise veri girisini reddetmez. Uyumsuzluk varsa `info` veya `warning` gibi seviye bilgisiyle raporlar.

Bu projede `AuditEventRecord.target_record_id` icin hard validation simdilik uygulanmayacak. Bunun nedeni legacy ID orneklerinin, genis `project_record` target type degerinin ve explicit ID alani olmayan modellerin henuz tam standardize edilmemis olmasidir.

## Mevcut helper API ile iliskisi

Soft validation ileride Adim 132 helper API'sini bilgi kaynagi olarak kullanabilir:

- `RECORD_ID_PREFIXES` canonical prefix adaylarini gosterir.
- `TARGET_RECORD_TYPE_TO_ID_FAMILY` target type icin beklenen ID ailelerini verir.
- `TARGET_RECORD_TYPE_TO_ID_PREFIXES` target type icin canonical ve legacy prefix adaylarini verir.
- `get_record_id_family_for_target_type` ID family bilgisini dondurur.
- `get_allowed_record_id_prefixes_for_target_type` allowed prefix adaylarini dondurur.

Bu iliski tek yonlu olmalidir. Soft validation helperlari bu bilgiyi okuyabilir, fakat mevcut helper API'si hard validation'a cevrilmemelidir.

## Nerede kullanilabilir?

Soft validation ileride su alanlarda kullanilabilir:

- Audit raporlama.
- Kalite kontrol ciktisi.
- CLI veya export on kontrolu.
- Handover package on kontrolu.
- Test helper veya diagnostic helper.
- Documentation veya developer tooling tarafinda ID sozlesmesi gorunurlugu.

Bu kullanimlarda soft validation bilgi verir, ancak kaydi reddetmez.

## Nerede kullanilmamali?

Soft validation su yerlerde dogrudan veri reddetmek icin kullanilmamalidir:

- `AuditEventRecord.__post_init__` icinde hard validation olarak.
- `AuditEventRecord.target_record_id` prefix veya regex hatasi uretmek icin.
- Mevcut legacy target id orneklerini kirmak icin.
- Constructor davranisini daraltmak icin.
- `FileAttachmentRecord` validation kapsamina karistirmak icin.
- Persistence, repository, API, GUI veya scanner davranisini sessizce degistirmek icin.

Soft validation, hard validation'a gecis icin raporlama zemini olabilir; kendisi bu adimda runtime davranis degisikligi degildir.

## Onerilen diagnostic cikti yapisi

Ileride eklenecek soft validation diagnostic sonucu sozluk veya kucuk bir model olarak tasarlanabilir.

Onerilen alanlar:

```text
target_record_type
target_record_id
expected_family
allowed_prefixes
observed_prefix
severity
message
is_compatible
```

Onerilen severity degerleri:

- `info`: Bilinen ve uyumlu ID ornegi.
- `warning`: Legacy veya bilinmeyen ama henuz reddedilmeyen ID ornegi.

Onerilen temel anlam:

- `is_compatible=True`: ID, bilinen target type ve prefix adaylariyla uyumlu gorunur.
- `is_compatible=False`: ID, soft validation tarafindan uyari gerektirir ama model olusturma engellenmez.

## Legacy ID uyumluluk yaklasimi

Legacy ID ornekleri korunacaktir.

Ornekler:

- `prj-001`
- `log-001`
- `file-att-001`
- `audit-001`
- `NCR-001`
- `REC-1`
- `REC-2026-0007`
- `ATT-2026-0001`

Soft validation bu ornekleri hemen hata haline getirmemelidir. Bazilari `info`, bazilari `warning` olarak raporlanabilir. Hangi ornegin hangi seviyeye girecegi ayri test ve diagnostic tasariminda netlestirilmelidir.

## Planlanan test kategorileri

Bu adimda test yazilmadi. Ileride soft validation implementasyonu yapilirsa su test kategorileri planlanabilir:

- Canonical ID ornegi compatible doner.
- Legacy ID ornegi warning uretir ama reddedilmez.
- Bilinmeyen `target_record_type` temiz hata veya diagnostic uretir.
- Bos `target_record_id` mevcut model validation sorumluluguyla ayri ele alinir.
- `project_record` gibi genis target type degeri birden fazla prefix ailesini destekler.
- Helper mapping testleri ile model validation testleri ayri kalir.
- Hard validation davranisi olusmaz.

## Bu adimda bilincli olarak yapilmayanlar

- `app/models.py` degistirilmedi.
- Test dosyalari degistirilmedi.
- Soft validation helper implementasyonu yapilmadi.
- `AuditEventRecord.target_record_id` hard validation eklenmedi.
- `AuditEventRecord.__post_init__` davranisi degistirilmedi.
- `FileAttachmentRecord` degistirilmedi.
- Podcast 022 olusturulmadi.
- Commit veya push yapilmadi.
- ZIP dosyasi stage edilmedi.

## Sonraki guvenli teknik adim

Adim 135 icin en guvenli teknik adim, record ID soft validation diagnostic helper implementation planini hazirlamak veya record ID test example categories dokumanini daha somut hale getirmektir.

Hard validation, diagnostic cikti ve test standardizasyonu olgunlasmadan uygulanmamalidir.
