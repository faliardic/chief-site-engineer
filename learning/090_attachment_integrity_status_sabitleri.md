# Adim 090 - Attachment Integrity Status Sabitleri

## Status Sabiti Nedir?

Status sabiti, sistem icinde ayni anlama gelen durum kodunu tek isimle ve tek degerle temsil eden merkezi bir tanimdir.

Bu adimda attachment metadata butunlugu icin `OK`, `MISSING_FILE`, `ORPHAN_FILE`, `INVALID_PATH`, `DUPLICATE_METADATA` ve `UNREADABLE_FILE` sabitleri olusturuldu.

## Neden Stringleri Dagitmadan Kullaniyoruz?

Ayni string degeri kodun farkli yerlerine elle yazmak hata riskini artirir.

Ornegin bir yerde `MISSING_FILE`, baska bir yerde yanlislikla `MISSINGFILES` yazilirse scanner, rapor veya audit hatti bu durumu ayni kod olarak anlayamaz.

Merkezi sabit kullanildiginda durum kodlari tek yerden okunur, test edilir ve ileride degistirilmesi gerekirse daha kontrollu degistirilir.

## Scanner, Raporlama, Test ve Audit Icin Onemi

Ileride missing/orphan scanner bu sabitleri kullanarak bulgularini siniflandirabilir.

Raporlama hatti ayni status kodlarini kullanarak kullaniciya tutarli sonuc gosterebilir.

Testler bu sabitlerin dogru degerleri tasidigini ve dogru koleksiyonlarda yer aldigini kontrol eder.

Audit event hatti ileride kritik durumlari kaydederken ayni status sozlugune dayanabilir.

## STATUS, ERROR ve WARNING Ayrimi

`ATTACHMENT_INTEGRITY_STATUSES`, bilinen tum attachment integrity durumlarini toplar.

`ATTACHMENT_INTEGRITY_ERROR_STATUSES`, kritik veya hata kabul edilen durumlari toplar:

- `MISSING_FILE`
- `INVALID_PATH`
- `DUPLICATE_METADATA`
- `UNREADABLE_FILE`

`ATTACHMENT_INTEGRITY_WARNING_STATUSES`, inceleme gerektiren ama dogrudan kritik hata olarak baslamayan durumlari toplar:

- `ORPHAN_FILE`

`OK`, hata veya uyari koleksiyonuna girmez; cunku sorun olmayan durumu temsil eder.

## Bu Adim Neden Scanner Implementasyonu Degildir?

Bu adim dosya sistemi taramasi yapmaz.

Metadata kaydi okumaz.

Fiziksel dosya var mi diye kontrol etmez.

Upload service, backup logic veya audit event implementasyonu eklemez.

Bu adim yalnizca ileride scanner, rapor, backup dogrulama ve audit hatti tarafindan kullanilabilecek ortak status sozlugunu hazirlar.
