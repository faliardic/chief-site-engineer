# Adim 092 - Attachment Integrity Single Record Helper

## Tekil Integrity Helper Nedir?

Tekil integrity helper, tek bir attachment metadata kaydi ve tek bir dosya varligi bilgisi uzerinden sonuc ureten karar fonksiyonudur.

Bu adimda `build_attachment_integrity_result` helper fonksiyonu eklendi. Fonksiyon kendisine verilen metadata ve dosya durumu bilgilerine bakarak `AttachmentIntegrityResult` dondurur.

## Neden Toplu Scanner'dan Once Tek Kayit Karar Fonksiyonu Yazilir?

Toplu scanner daha sonra birden fazla metadata ve dosya uzerinde calisacak.

Ancak toplu scanner'in her kayit icin hangi sonucu uretmesi gerektigi once tek kayit seviyesinde net olmalidir.

Bu ayrim testleri sade tutar. Scanner yazildiginda klasor gezme veya dosya listesi yonetimi ile karar mantigi birbirine karismaz.

## Status, Severity ve Recommended Action Birlikte Nasil Calisir?

`status_code`, bulunan durumu teknik olarak adlandirir. Ornegin `MISSING_FILE` veya `ORPHAN_FILE`.

`severity`, bu durumun onem seviyesini belirtir. Ornegin `ERROR`, `WARNING` veya `OK`.

`recommended_action`, bu durumda ne yapilmasi gerektigine dair kisa ve makine-dostu bir oneridir.

Ornek:

```text
status_code = MISSING_FILE
severity = ERROR
recommended_action = restore_from_backup_or_review_audit_trail
```

## Neden Dosya Sistemi Taramasi Bu Adimda Yapilmiyor?

Bu adim `os.walk`, `glob`, klasor gezme veya fiziksel dosya okuma islemi yapmaz.

Fonksiyon yalnizca kendisine verilen `metadata_exists`, `file_exists`, `path_is_valid`, `duplicate_metadata` ve `file_is_readable` bilgilerine gore karar verir.

Boylece karar mantigi dosya sistemi davranisindan bagimsiz ve kolay test edilebilir kalir.

## Oncelik Sirasi Neden Onemlidir?

Ayni kayit birden fazla sorun isareti tasiyabilir.

Ornegin hem duplicate metadata hem de invalid path varsa once duplicate metadata raporlanir. Bu nedenle helper icinde karar sirasi net tutulur:

1. `DUPLICATE_METADATA`
2. `INVALID_PATH`
3. `MISSING_FILE` veya `ORPHAN_FILE`
4. `UNREADABLE_FILE`
5. `OK`

Bu sira, scanner raporunun tutarli ve tahmin edilebilir olmasini saglar.

## Bu Adimda Yapilmayan Isler

- Toplu scanner yazilmadi.
- Dosya sistemi taramasi yapilmadi.
- Klasor gezme yapilmadi.
- Upload service eklenmedi.
- Backup logic eklenmedi.
- Audit event implement edilmedi.
