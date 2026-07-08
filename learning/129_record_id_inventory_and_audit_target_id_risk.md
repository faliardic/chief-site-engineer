# Adim 129 - Record ID Envanteri ve Audit Target ID Risk Analizi

## Bu adimda ne yaptik?

Bu adimda yeni validation eklemedik. Once projede hangi ID alanlari var, testlerde hangi ID ornekleri kullaniliyor ve `AuditEventRecord.target_record_id` alanina format validation eklemek hangi riskleri dogurur bunu inceledik.

Sonuc olarak, audit target id format validation icin once merkezi bir record ID sozlesmesi gerektigini belgeledik.

## Neden validation eklemeden once ID envanteri cikarilir?

Validation, sistemin "bunu kabul ederim, bunu reddederim" demesidir.

Eger once mevcut ID kullanimi bilinmezse, iyi niyetli bir validation mevcut dogru ornekleri de reddedebilir. Bu da testleri ve proje hafizasini gereksiz yere kirar.

Bu projede ID ornekleri farkli bicimlerde kullaniliyor:

```text
prj-001
log-001
file-att-001
NCR-001
ATT-001
NCR-CAND-REV-001
MAT-DEL-001
```

Bu ornekler bize sunu gosterir:

Tek bir basit regex yazmak kolaydir, fakat dogru validation yazmak icin once alanin gercek kullanim haritasini bilmek gerekir.

## Serbest string ID ile kati format validation arasindaki fark

Serbest string ID yaklasiminda alan herhangi bir metni tutabilir:

```python
target_record_id = "NCR-001"
target_record_id = "file-att-001"
target_record_id = "REC-2026-0007"
```

Avantaji:
Esnektir ve erken asamada kirilma riski azdir.

Dezavantaji:
Yanlis yazilmis ID de kabul edilebilir.

Kati format validation yaklasiminda ise alan sadece belirli bicimleri kabul eder:

```text
<PREFIX>-<YEAR>-<SEQUENCE>
```

Avantaji:
Veri kalitesi artar.

Dezavantaji:
Mevcut ID ornekleri bu formata uymuyorsa sistem gereksiz yere hata verir.

Bu yuzden kati validation icin once merkezi sozlesme gerekir.

## Audit log icin target_record_type + target_record_id iliskisi neden onemli?

Audit log bir olay izidir. Olayin hangi kayda ait oldugunu anlamak icin iki bilgi birlikte gerekir:

```python
target_record_type = "project_record"
target_record_id = "NCR-001"
```

`target_record_type` kaydin ailesini anlatir.

`target_record_id` o aile icindeki belirli kaydi anlatir.

Sadece `target_record_id` olursa `NCR-001` degerinin hangi sistemde veya hangi baglamda yorumlanacagi belirsiz kalabilir.

Sadece `target_record_type` olursa hangi kaydin hedeflendigi bilinmez.

Bu nedenle bu projede once pair validation eklendi: iki alan birlikte dolu veya birlikte bos olmali.

## Bu projede neden kucuk adimla ilerleniyor?

Chief Site Engineer projesi once veri omurgasini saglamlastiriyor.

Bu yaklasimda her yeni kural su sirayla ilerler:

1. Mevcut durum incelenir.
2. Riskler yazilir.
3. Karar dokumante edilir.
4. Sonra kucuk ve testli kod degisikligi yapilir.

Adim 129 bu zincirin "inceleme ve karar hazirligi" bolumudur.

## Bu adimda ne yapmadik?

- `app/models.py` degistirilmedi.
- Test dosyalari degistirilmedi.
- `AuditEventRecord` validation davranisi degistirilmedi.
- `target_record_id` format validation eklenmedi.
- Podcast 021 olusturulmadi.
- Commit veya push yapilmadi.

## Sonraki guvenli teknik adim

Bir sonraki guvenli adim, merkezi record ID sozlesmesi planidir.

Bu plan sunlari netlestirmelidir:

- Hangi model ailesi hangi ID prefixini kullanacak?
- `project_record` gibi genis target type degerleri hangi ID ailelerini kapsayacak?
- Lower-case ID ornekleri korunacak mi, yoksa yeni sozlesme upper-case mi olacak?
- Explicit ID alani olmayan modeller audit hedefi olabilir mi?
- Backward compatibility nasil korunacak?
