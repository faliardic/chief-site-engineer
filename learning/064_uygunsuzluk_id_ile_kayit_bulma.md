# Adim 064 - Uygunsuzluk Id Ile Kayit Bulma

## Bu Adimda Ne Ogrenildi?

Bu adimda repository icinde id ile tek kayit bulma davranisi netlestirildi.

`find_by_id(nonconformity_id)` methodu, verilen id degerine sahip `NonconformityRecord` kaydini dondurur. Kayit yoksa `None` dondurur.

## Method Zaten Var Miydi?

Evet. `find_by_id()` methodu repository icinde zaten bulunuyordu.

Bu nedenle bu adimda ayni method tekrar yazilmadi. Bunun yerine mevcut davranisin aktif, arsivlenmis ve restore edilmis kayitlarda dogru calistigini gosteren ek testler yazildi.

## Read-Only Davranis

`find_by_id()` salt okuma davranisidir. Kayitlari degistirmez.

Bu method:

- Kayit silmez.
- `status` alanini degistirmez.
- `is_archived` alanini degistirmez.
- Otomatik history olusturmaz.
- Otomatik workflow baslatmaz.

## None Donusu Neden Kullanilir?

Aranan id repository icinde yoksa method `None` dondurur.

Bu, Python'da "kayit bulunamadi" durumunu sade ve anlasilir sekilde ifade eder.

## Arsivlenmis Kayitlar Neden Bulunur?

Arsivlenmis kayitlar sistemden silinmez. Bu nedenle id ile arama tum kayit hafizasi uzerinde calismalidir.

Bir kayit `is_archived == True` olsa bile `find_by_id()` ile bulunabilir.

## Restore Sonrasi Davranis

Restore islemi yeni kayit olusturmaz. Sadece mevcut kaydin `is_archived` alanini `False` yapar.

Bu nedenle restore sonrasi ayni id ile arama yine ayni kaydi dondurmelidir.

## Python Ogrenme Acisindan Ders

Bu adim su konulari pekistirir:

- Repository pattern
- Tek kayit arama
- `None` donusu
- Read-only method tasarimi
- Nesne kimliginin korunmasi
- Testle mevcut davranisi netlestirme

## Santiye Pratigindeki Anlami

Santiye sefi veya kalite ekibi bir NCR numarasi bildiginde kayda dogrudan ulasabilmelidir.

Kaydin aktif veya arsivde olmasi bu aramayi engellememelidir. Bu, kalite kayitlarinin izlenebilirligini guclendirir.
