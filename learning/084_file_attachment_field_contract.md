# Adim 084 - FileAttachmentRecord Field Contract

## Amac

Bu adimda `FileAttachmentRecord` icin alan sozlesmesi netlestirildi.

Ozellikle `uploaded_by` ve `uploaded_at` alanlarinin simdilik model seviyesinde opsiyonel kalacagi, fakat ileride upload servisi veya kullanici sistemi geldiginde servis seviyesinde zorunlu hale getirilebilecegi aciklandi.

## Alan Sozlesmesi Nedir?

Alan sozlesmesi, bir model alaninin ne anlama geldigini ve nasil kullanilmasi gerektigini anlatir.

Sadece alanin adi yetmez. Projede su sorular da cevaplanmalidir:

- Bu alan hangi bilgiyi temsil eder?
- Simdilik zorunlu mu, opsiyonel mi?
- Ileride hangi katman bu alani dolduracak?
- Bu alan hangi is akisi icin onemlidir?

## Model Seviyesinde Opsiyonel Olmak

Model seviyesinde opsiyonel olmak, dataclass nesnesi olusturulurken alanin verilmek zorunda olmamasi demektir.

`FileAttachmentRecord.uploaded_by` ve `uploaded_at` alanlari su anda `None` olabilir.

Bunun nedeni, projede henuz gercek upload servisi, kullanici modeli, authentication veya authorization sistemi olmamasidir.

## Servis Seviyesinde Zorunlu Olmak

Servis seviyesinde zorunlu olmak, model alaninin Python dataclass icinde opsiyonel kalmasina ragmen bir servis veya is akisi tarafindan zorunlu tutulmasi demektir.

Ileride dosya upload servisi eklendiginde:

- `uploaded_by` yukleyen kullanicidan veya islem baglamindan alinabilir.
- `uploaded_at` servis tarafindan otomatik uretilebilir.
- Eksik upload metadata varsa servis kaydi reddedebilir.

Bu zorunluluk model alanini degistirmeden servis katmaninda uygulanabilir.

## Neden uploaded_by ve uploaded_at Su Anda Zorunlu Yapilmadi?

Bu alanlar simdi zorunlu yapilsa mevcut basit model testleri ve manuel metadata kullanimi gereksiz yere kirilgan hale gelir.

Projede henuz:

- Kullanici sistemi yok.
- Auth / rol / yetki sistemi yok.
- Gercek upload servisi yok.
- Otomatik tarih uretimi yok.
- Persistence katmani yok.

Bu nedenle alanlar model seviyesinde opsiyonel kalir.

## Upload, Auth ve Audit Hatti Icin Faydasi

Bu karar ilerideki mimariyi kolaylastirir:

- Upload servisi hangi alanlari dolduracagini bilir.
- Auth sistemi geldiginde `uploaded_by` kullanici kimligiyle iliskilendirilebilir.
- Audit hatti dosyanin kim tarafindan ve ne zaman eklendigini izleyebilir.
- Model bugunden bu metadata alanlarini tasidigi icin ileride buyuk kirici refactor gerekmez.

## Bu Adimda Yapilmayanlar

- Model alani eklenmedi.
- Model alani silinmedi.
- Test dosyasi degistirilmedi.
- Upload servisi eklenmedi.
- Auth veya kullanici sistemi eklenmedi.
- Otomatik tarih uretimi eklenmedi.
- Database, API, GUI, CI veya deployment eklenmedi.
