# Adim 154 - Export Helper Test Matrix Finalization

Bu adimda Adim 155'te ele alinabilecek read-only file writing helper implementation oncesinde export helper test matrix'i netlestirildi.

Bu adim documentation-only adimidir.

Kod veya test davranisi degistirilmedi.

Export / file writing helper implementasyonu yapilmadi.

JSON veya Markdown export dosyasi uretilmedi.

Backup / restore davranisi eklenmedi.

Hard validation eklenmedi.

`blocked` status uretilmedi.

Podcast 026 bu adimda olusturulmadi.

## Export helper amaci

Gelecekteki export helper'in amaci, onceden hazirlanmis JSON-ready dict veya Markdown string ciktisini guvenli ve test edilebilir sekilde dosyaya yazmak olabilir.

Export helper:

- Rapor hesaplama katmani degildir.
- Formatter katmani degildir.
- Validation kapisi degildir.
- Backup / restore motoru degildir.
- Handover karar motoru degildir.

Export helper yalniz file-writing sorumlulugunu tasimalidir.

## Format helper ile file-writing export helper ayrimi

Format helper:

- JSON-ready Python dict dondurur.
- Markdown string dondurur.
- Dosya yazmaz.
- Output path bilmez.
- Overwrite karari vermez.
- Diagnostic veya soft validation sonucu yeniden hesaplamaz.

File-writing export helper:

- Hazir JSON-ready dict veya Markdown string alabilir.
- Explicit output path ister.
- Path safety uygular.
- Uzanti ve encoding sinirlarini uygular.
- Overwrite policy uygular.
- Yazma sonucunu exception veya diagnostic result ile raporlayabilir.

Bu iki katman ayni helper icinde karistirilmamalidir.

## JSON export helper testleri

Gelecekte JSON export helper eklenirse test matrix en az su davranislari kapsamalidir:

- JSON-ready dict input alir.
- `.json` uzantili dosyaya yazar.
- Output dosyasi UTF-8 encoding ile yazilir.
- Pretty / indent davranisi net ve deterministik olur.
- Dosya icerigi tekrar okunup JSON olarak dogrulanabilir.
- Input dict mutate edilmez.
- JSON-ready input yeniden hesaplanmaz.
- Diagnostic report yeniden hesaplanmaz.
- Soft validation sonucu degistirilmez.
- Format helper davranisi degistirilmez.
- Python object, dataclass veya unserializable object dogrudan kabul edilmez.
- Unsupported input kayit reddi veya hard validation anlamina gelmez.

Olasil test beklentileri:

- Basit dict yazildiginda dosya icindeki JSON ayni alanlari tasir.
- Nested list/dict degerleri korunur.
- UTF-8 karakterler bozulmadan okunabilir.
- Non-serializable object iceren input guvenli hata veya diagnostic result uretir.
- Yazma basarisiz olursa input dict aynen kalir.

## Markdown export helper testleri

Gelecekte Markdown export helper eklenirse test matrix en az su davranislari kapsamalidir:

- Markdown string input alir.
- `.md` uzantili dosyaya yazar.
- Output dosyasi UTF-8 encoding ile yazilir.
- Markdown icerigi yeniden formatlanmaz.
- Var olan formatter ciktisi degistirilmez.
- Diagnostic veya soft validation sonucu yeniden hesaplanmaz.
- Non-string input reddedilir veya guvenli diagnostic result dondurur.
- Bos string davranisi acikca test edilir.

Olasil test beklentileri:

- Heading, bullet ve code fence gibi Markdown icerikleri aynen korunur.
- Yeni satirlar helper tarafindan rastgele degistirilmez.
- UTF-8 karakterler bozulmadan okunur.
- Non-string input dosya uretmeden guvenli hata verir.

## Path safety testleri

Path safety testleri export helper'in en kritik test grubudur.

Test matrix su senaryolari acikca kapsamalidir:

- Explicit output path zorunludur.
- Bos path kabul edilmez.
- Path traversal reddedilir.
- `..` iceren path reddedilir.
- Mixed separator davranisi ele alinir.
- Relative path davranisi acikca testlenir.
- Absolute path davranisi acikca testlenir.
- Cozumlenmis hedef izinli export root disina cikamaz.
- `.git` altina yazma reddedilir.
- `.env` veya environment dosyalarina yazma reddedilir.
- Cache alanlarina yazma reddedilir.
- `__pycache__` alanlarina yazma reddedilir.
- Database alanlarina yazma reddedilir.
- Backup alanlarina yazma reddedilir.
- ZIP veya yedek alanlarina yazma reddedilir.
- Windows reserved names riski test notu olarak ele alinir.

Relative path testlerinde normal alt path ornekleri izinli export root altinda cozumlenmelidir.

Absolute path testlerinde secilecek politika net olmalidir:

- Absolute path tamamen reddedilebilir.
- Veya sadece allowed output root altinda kalan absolute path kabul edilebilir.

Hangi politika secilirse secilsin testler bu davranisi sabitlemelidir.

## Overwrite policy testleri

Overwrite policy icin guvenli varsayilan `overwrite=False` olmalidir.

Test matrix su senaryolari kapsamalidir:

- Varsayilan `overwrite=False` olur.
- Hedef dosya yoksa yazma basarili olabilir.
- Hedef dosya varsa `overwrite=False` ile yazma yapilmaz.
- `overwrite=False` iken mevcut dosya icerigi degismedigi dogrulanir.
- Explicit `overwrite=True` verilirse uzerine yazma davranisi testlenir.
- `overwrite=True` iken yalniz hedef dosyanin degistigi dogrulanir.
- Overwrite davranisi sessiz olmamalidir.
- Overwrite basarisi veya reddi okunur hata/sonuc olarak raporlanmalidir.

Bu testler yanlislikla eski handover veya audit QC dosyasinin ezilmesini engellemek icin gereklidir.

## Parent directory davranisi testleri

Parent directory davranisi belirsiz kalmamalidir.

Test matrix su senaryolari kapsamalidir:

- Parent directory mevcutsa yazma davranisi testlenir.
- Parent directory yoksa varsayilan davranis net test edilir.
- Otomatik klasor olusturma desteklenmeyecekse hata davranisi test edilir.
- Otomatik klasor olusturma desteklenecekse explicit parametre gerekir.
- Otomatik klasor olusturma yalniz izinli export root altinda olabilir.
- Izinli root disinda parent olusturulmamalidir.
- `.git`, `.env`, cache, pycache, database, backup ve ZIP/yedek alanlarinda parent olusturulmamalidir.

Parent directory olusturma, path safety kontrolunden sonra ele alinmalidir.

## Unsupported input testleri

Unsupported veya riskli input senaryolari test matrix'te acikca gorunmelidir:

- Bos path.
- Bos filename.
- Klasor path'i.
- Yanlis uzanti.
- Cok uzun filename.
- Path separator iceren filename.
- Windows reserved names riski.
- `None` input.
- JSON export icin bos dict.
- Markdown export icin bos string.
- JSON export icin dataclass input.
- JSON export icin Python object input.
- JSON export icin unserializable object input.
- Markdown export icin non-string input.

Bos dict ve bos string, secilecek helper sozlesmesine gore kabul edilebilir veya okunur diagnostic result dondurebilir. Ancak davranis testle sabitlenmelidir.

## Hata davranisi testleri

Gelecekte helper exception veya diagnostic result yaklasimlarindan birini kullanabilir.

Test matrix hata davranisini su acilardan sabitlemelidir:

- Hata durumunda yarim veya beklenmeyen dosya birakilmamasi.
- Hata durumunda input verinin mutate edilmemesi.
- Hata durumunda diagnostic / soft validation sonucu degistirilmemesi.
- Izin hatasi simulasyonu.
- Hedef dosya kilitli veya erisilemez senaryosu, prensip duzeyinde.
- Yanlis uzanti hatasi.
- Path traversal hatasi.
- Existing file + `overwrite=False` hatasi.
- Unsupported input hatasi.

Hata davranisi kayit reddi, hard validation veya `blocked` status anlami tasimamalidir.

## ZIP / yedek / cache dislama testleri

Future export helper testleri ZIP, yedek ve cache alanlarini disarida tutmalidir.

Test matrix su sinirlari kapsamalidir:

- `chief-site-engineer_adim_080_guvenli_nokta.zip` export girdisi veya hedefi gibi kullanilmaz.
- ZIP/yedek dosyalari stage edilmez.
- Cache klasorlerine yazilmaz.
- `.pytest_cache` export alani degildir.
- `__pycache__` export alani degildir.
- Backup / restore klasorleri export hedefi degildir.

Bu adimda ZIP, yedek veya cache dosyalari stage edilmedi.

## Atomic write ileride ele alinacak mi?

Atomic write ileride ele alinabilir.

Olasil prensip:

- Once temporary file yazilir.
- Yazim tamamlaninca hedef dosyaya replace edilir.
- Hata durumunda hedef dosya yarim kalmaz.
- Temporary file da allowed output root disinda olusturulmaz.

Adim 154'te atomic write implementasyonu yapilmadi.

Adim 155'te implementation dusunulurse atomic write ya ilk kapsam disinda net birakilmali ya da ayri testlerle guvence altina alinmalidir.

## Handover QC export senaryosu

Handover QC export ileride yeni santiye sefine gorunurluk saglayabilir.

Test matrix su davranislari kapsamalidir:

- Handover Markdown ciktisi `.md` dosyasina yazilabilir.
- Handover JSON ciktisi `.json` dosyasina yazilabilir.
- Handover output path explicit olur.
- Handover dosyasi allowed output root disina yazilmaz.
- Handover dosyasi existing file ise `overwrite=False` ile korunur.
- Handover export warning/error veya review/attention bilgisini yalniz gorunurluk olarak tasir.
- Handover export devir paketini otomatik bloke etmez.
- Handover export kayit reddetmez.
- Handover export eski santiye sefinin ozel alanini devretmez.

Yanlis dosyaya yazma, santiye hafizasi acisindan risklidir. Yeni santiye sefi yanlis veya eski ciktida calisirsa eksik inceleme, yanlis karar veya geriye donuk iz surme kaybi olusabilir.

## Hard validation degildir

Bu test matrix hard validation plani degildir.

`target_record_id` hard validation eklenmeyecek.

`AuditEventRecord.__post_init__` degistirilmeyecek.

`FileAttachmentRecord` davranisi degistirilmeyecek.

Export helper path, extension veya overwrite hatasi verebilir; bu hata domain kaydinin reddedilmesi anlamina gelmez.

## `blocked` status uretilmeyecektir

Gelecekteki export helper `blocked` status uretmemelidir.

File-writing sonucu basarisiz olabilir, fakat bu:

- Devir paketini otomatik bloke etmez.
- Kayit reddi uretmez.
- Soft validation status sozlesmesini degistirmez.
- Hard validation tetiklemez.

Mevcut soft validation dili korunur:

- `pass`
- `review`
- `attention`

`blocked` kapsam disidir.

## Mutlak kararlar

- Export / file writing helper implementasyonu yapilmadi.
- Test dosyasi eklenmedi veya degistirilmedi.
- JSON veya Markdown export dosyasi uretilmedi.
- Backup / restore davranisi eklenmedi.
- Database / repository / API / GUI / CLI eklenmedi.
- Hard validation eklenmedi.
- `AuditEventRecord.__post_init__` degistirilmedi.
- `FileAttachmentRecord` davranisi degistirilmedi.
- `blocked` status eklenmedi.
- Podcast 026 olusturulmadi.
- ZIP, yedek veya cache dosyalari stage edilmemelidir.

## Sonuc

Adim 154, Adim 155 oncesinde export helper test matrix'ini netlestirdi.

Bu belge, file-writing helper implementasyonuna gecilirse JSON, Markdown, path safety, overwrite, parent directory, unsupported input, hata davranisi, ZIP/cache dislama ve handover QC export sinirlarinin test edilebilir olmasini saglar.
