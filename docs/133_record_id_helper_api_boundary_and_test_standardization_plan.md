# Adim 133 - Record ID Helper API Boundary and Test Standardization Plan

## Amac

Bu adimin amaci, Adim 132'de eklenen record ID constants ve mapping helper katmaninin API sinirini, kullanim ilkelerini ve test ornek standardizasyon planini belgelemektir.

Bu adim documentation-only / API-boundary-planning adimidir. Kod, test, helper, validation veya runtime davranisi degistirilmedi.

## Arka plan: Adim 129-132 zinciri

Adim 129, projede tek bir record ID formatinin olmadigini ve testlerde lower-case, upper-case, cok parcali prefix, path icine gomulu ID ve opsiyonel baglanti orneklerinin birlikte kullanildigini belgeledi.

Adim 130, merkezi record ID sozlesmesi icin asamali gecis planini yazdi. Bu planda once dokumantasyon, sonra constants/mapping, sonra test ornek standardizasyonu, sonra soft validation ve en son hard validation sirasinin izlenmesi kararlastirildi.

Adim 131, record ID constants ve `target_record_type` / ID ailesi mapping helper katmaninin nasil tasarlanacagini planladi.

Adim 132, bu planin ilk dar kod karsiligini ekledi. Helperlar sadece bilgi dondurur; `AuditEventRecord.target_record_id` formatini zorlamaz.

## Mevcut helper API ozeti

Adim 132 ile eklenen constants ve helperlar:

- `RECORD_ID_PREFIXES`
- `TARGET_RECORD_TYPE_TO_ID_FAMILY`
- `TARGET_RECORD_TYPE_TO_ID_PREFIXES`
- `get_record_id_family_for_target_type`
- `get_allowed_record_id_prefixes_for_target_type`

`RECORD_ID_PREFIXES`, record ID aileleri icin canonical prefix adaylarini tutar.

`TARGET_RECORD_TYPE_TO_ID_FAMILY`, mevcut audit `target_record_type` degerlerini bir veya daha fazla ID ailesine baglar.

`TARGET_RECORD_TYPE_TO_ID_PREFIXES`, target type icin canonical ve legacy prefix adaylarini bilgi olarak listeler.

Helper fonksiyonlar desteklenen target type degerleri icin tuple dondurur. Bilinmeyen target type degerleri icin temiz `ValueError("target_record_type is not supported")` uretir.

## Helper API siniri

Bu helper API'sinin siniri sudur:

- Sadece sozlesme bilgisi dondurur.
- `target_record_id` degerinin formatini kontrol etmez.
- `target_record_id` prefix uyumu icin hata uretmez.
- `AuditEventRecord` constructor davranisini daraltmaz.
- Legacy ID orneklerini kirmamak icin kullanilir.
- Hard validation icin dogrudan model icine baglanmaz.

Bu API bir indeks veya rehber katmandir. Veri kabul/red karari veren runtime validation katmani degildir.

## Kullanilmamasi gereken yerler

Bu helperlar su amaclarla kullanilmamalidir:

- `AuditEventRecord.__post_init__` icinde hard prefix validation yapmak.
- `target_record_id` regex validation uygulamak.
- Mevcut legacy ID orneklerini reddetmek.
- `project_record` gibi genis target type degerlerini tek prefixe zorlamak.
- Explicit ID alani olmayan modeller icin otomatik ID stratejisi varsaymak.
- API, repository, persistence veya scanner davranisini daraltmak.

Helperlar ileride UI, rapor, dokumantasyon, test ornek standardizasyonu veya soft validation hazirligi icin bilgi kaynagi olabilir.

## Test ornek standardizasyon yaklasimi

Test ornekleri tek seferde topluca degistirilmemelidir. Mevcut testler, eski davranisi ve backward compatibility niyetini de temsil eder.

Korunmasi gereken legacy ornekler:

- `prj-001`
- `log-001`
- `file-att-001`
- `audit-001`
- `NCR-001`
- `REC-1`
- `REC-2026-0007`
- `ATT-2026-0001`

Yeni helper veya yeni sozlesme testlerinde canonical prefix adaylari tercih edilebilir:

- `PRJ-2026-0001`
- `ATT-2026-0001`
- `AUD-2026-0001`
- `NCR-2026-0001`
- `MAT-DEL-2026-0001`

Model validation testleri ile helper testleri ayrilmalidir. Model validation testleri `AuditEventRecord` olusturma davranisini kontrol eder. Helper testleri ise mapping bilgisinin dogru donduruldugunu kontrol eder.

## Legacy ID orneklerini koruma karari

Legacy ID ornekleri silinmeyecek veya topluca canonical formata cevrilmeyecek.

Nedenleri:

- Mevcut testler geriye uyumluluk sinyali tasir.
- `project_record` birden fazla kayit ailesini temsil eder.
- Attachment tarafinda canonical ve legacy aileler birlikte vardir.
- Explicit ID alani olmayan modeller icin ID stratejisi henuz tamamlanmamistir.
- Erken toplu degisim, testlerin davranis niyetini belirsizlestirebilir.

Bu nedenle yeni testlerde canonical ornekler artirilabilir, fakat mevcut legacy ornekler bilincli olarak korunmalidir.

## Soft validation / hard validation ayrimi

Soft validation:

- Bilgi, uyari veya rapor sonucu uretir.
- Model olusturmayi engellemez.
- Legacy ID orneklerini kirmadan uyumsuzluklari gorunur hale getirir.
- Ayri bir adimda planlanmalidir.

Hard validation:

- Uyumsuz veri icin hata uretir.
- Mevcut testleri veya eski veri orneklerini kirabilir.
- Migration, test standardizasyonu ve ID sozlesmesi netlesmeden uygulanmamalidir.

Adim 133 karari: Soft validation bile bu adimda uygulanmayacak; yalnizca API siniri ve test standardizasyon plani belgelenecek.

## Onerilen asamali gecis

1. API boundary dokumante edilir.
2. Helper testleri ile model validation testlerinin ayrimi korunur.
3. Yeni test orneklerinde canonical prefix adaylari kullanilmaya baslanir.
4. Legacy ID ornekleri backward compatibility testi olarak korunur.
5. Soft validation davranisi ayri bir dokumantasyon adiminda tasarlanir.
6. Soft validation helperlari ayri bir kod adiminda eklenir.
7. Hard validation ancak migration ve test standardizasyonu tamamlandiktan sonra degerlendirilir.

## Bu adimda bilincli olarak yapilmayanlar

- `app/models.py` degistirilmedi.
- Test dosyalari degistirilmedi.
- `AuditEventRecord.target_record_id` hard validation eklenmedi.
- Soft validation implementasyonu yapilmadi.
- Record ID helper API'si model constructor icine baglanmadi.
- Podcast 022 olusturulmadi.
- Commit veya push yapilmadi.
- ZIP dosyasi stage edilmedi.

## Sonraki guvenli teknik adim

Adim 134 icin en guvenli teknik adim, record ID test example standardization planini daha somut test kategorilerine ayirmak veya soft validation plan dokumantasyonunu hazirlamaktir.

Hard validation hala sonraki bir migration ve sozlesme olgunlasma adimi olarak kalmalidir.
