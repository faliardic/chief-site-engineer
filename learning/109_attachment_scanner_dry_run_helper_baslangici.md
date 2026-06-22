# Adim 109 - Attachment Scanner Dry-run Helper Baslangici

Bu adimda `build_attachment_integrity_results_dry_run` helper fonksiyonu eklendi.

## Helper Ne Yapar?

Helper, verilen `FileAttachmentRecord` metadata kayitlarini ve path -> exists map bilgisini kullanarak `AttachmentIntegrityResult` sonuclari uretir.

Her kayit icin mevcut `build_attachment_integrity_result` helper'i kullanilir. Boylece status, severity ve recommended action kararlari onceki tekil helper hattiyla uyumlu kalir.

## Neden Gercek Dosya Sistemi Taramaz?

Bu adim scanner'in ilk kod baslangicidir, tam scanner degildir.

Helper:

- `Path.exists()` cagirmaz
- klasor gezmez
- orphan dosya aramaz
- root/path guvenlik kontrolu yapmaz
- dosya veya metadata degistirmez

File existence bilgisi disaridan kontrollu map ile verilir. Bu sayede davranis test edilebilir ve dosya sistemi riski buyutulmez.

## Neden Dry-run?

Dry-run yaklasimi once tespit ve raporlama davranisini guvenli hale getirir. Helper hicbir dosyayi silmez, tasimaz, kopyalamaz veya karantinaya almaz.

## Hangi Testler Eklendi?

Testler su davranislari dogrular:

- var olan dosya icin `OK`
- olmayan dosya icin `MISSING_FILE`
- path map icinde olmayan kayit icin `MISSING_FILE`
- birden fazla kayit icin birden fazla sonuc
- `checked_at` verilirse tum sonuclarda ayni zaman
- gercek dosya olusturmadan path map ile calisma
- input record nesnelerini mutate etmeme
- bos input icin bos tuple

## Kapsam Disi Birakilanlar

Bu adimda orphan scan, duplicate metadata tespiti, unreadable file tespiti, invalid path normalizasyonu, root disi path kontrolu, upload service, backup/restore, audit event, database, API, GUI, CLI veya AI entegrasyonu eklenmedi.
