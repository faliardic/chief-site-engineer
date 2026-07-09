# Adim 153 - Path Safety and Overwrite Policy Detailed Documentation

Bu adimda Adim 152'de planlanan export helper file writing safety siniri daha detayli belgelendi.

Bu adim documentation-only adimidir.

Kod veya test davranisi degistirilmedi.

Export / file writing helper implementasyonu yapilmadi.

JSON veya Markdown export dosyasi uretilmedi.

Hard validation eklenmedi.

`blocked` status uretilmedi.

Podcast 026 bu adimda olusturulmadi.

## Path safety amaci

Path safety, ileride dosya yazan export helper eklenirse yazma hedefinin beklenen ve izinli alanda kalmasini saglayan guvenlik siniridir.

Dosya yazimi kalici etki yaratir. Yanlis path secimi:

- Proje dosyalarini ezebilir.
- Repo disina cikabilir.
- Kullaniciya ait baska dosyalara yazabilir.
- `.git`, `.env`, cache veya database gibi hassas alanlari etkileyebilir.
- Handover veya audit ciktisini backup / restore davranisiyla karistirabilir.

Bu nedenle export helper eklenmeden once path safety prensipleri yazili hale getirilmelidir.

## Explicit output path gerekliligi

Gelecekteki export helper implicit, tahmini veya yan etkili dosya yolu secmemelidir.

Output path acikca verilmelidir.

Bu yaklasim:

- Kullanici veya cagirici kodun yazma hedefini bilmesini saglar.
- Testlerde hedef path'in dogrudan denetlenmesini kolaylastirir.
- Helper'in kendi kendine dosya adi veya klasor secerek beklenmeyen cikti uretmesini engeller.
- Format helper ile file-writing helper sorumluluklarini ayri tutar.

Export helper, verilen hazir JSON-ready dict veya Markdown string ciktisini guvenli hedefe yazma sorumlulugunu tasiyabilir. Diagnostic report'u yeniden hesaplamamali, soft validation status'u yeniden hesaplamamali ve format helper davranisini degistirmemelidir.

## Relative path davranisi

Relative path kullanimi ileride desteklenecekse siniri net olmalidir.

Guvenli prensip:

- Relative path izinli export kokune gore cozumlenmelidir.
- Relative path calisma dizinine, test kosucusunun baslatildigi klasore veya rastgele process state'e bagli yorumlanmamalidir.
- Cozumlenmis absolute hedef izinli export kokunun icinde kalmalidir.
- `reports/output.md` gibi normal alt path'ler izinli olabilir.
- `../outside.md` gibi ust klasore cikmaya calisan path'ler reddedilmelidir.

Relative path desteklenirse testler hem normal alt path hem de traversal denemelerini kapsamalidir.

## Absolute path davranisi

Absolute path kullanimi daha risklidir.

Iki guvenli yaklasimdan biri secilmelidir:

- Absolute path tamamen reddedilir ve sadece izinli export kokune gore relative path kabul edilir.
- Absolute path kabul edilir, fakat cozumlenmis hedefin izinli export kokunun icinde kaldigi dogrulanir.

Hangi yaklasim secilirse secilsin davranis belirsiz kalmamalidir.

Windows ortaminda `C:\...`, `V:\...`, UNC path ve drive-relative path benzeri varyasyonlar dikkate alinmalidir. Absolute path, izinli export kokune denk gelmiyorsa yazma yapilmamalidir.

## Parent directory davranisi

Parent directory yoksa davranis acik olmalidir.

Olasiliklar:

- Varsayilan olarak eksik parent directory hata kabul edilir.
- `create_parents=True` gibi explicit parametre ile parent directory olusturulabilir.
- Parent directory yalniz izinli export koku altindaysa olusturulabilir.

Guvenli varsayilan, otomatik klasor olusturmayi sinirli tutmaktir.

Eger ileride parent directory olusturma desteklenirse:

- Sadece izinli export koku altinda olmalidir.
- `.git`, `.env`, cache, pycache, database veya backup klasorleri altinda olusturma yapilmamalidir.
- Olusturma islemi export helper'in audit/log sonucunda gorunur hale getirilebilir.

## Path traversal riskleri

Path traversal, bir dosya yolunun beklenen klasorden cikmak icin kullanilmasidir.

Ornek riskler:

- `../secret.txt`
- `..\\secret.txt`
- `reports/../../outside.md`
- Mixed separator kullanimlari.
- URL-encoded veya benzeri encoded traversal denemeleri.
- Dosya adinin icine path separator yerlestirilmesi.

Bu adimda implementasyon yoktur, fakat prensip sudur:

- Path once normalize edilmeli ve canonical / resolved hedef olarak dusunulmelidir.
- Cozumlenmis hedef izinli export kokunun disina cikiyorsa reddedilmelidir.
- Sadece string prefix kontrolu yeterli kabul edilmemelidir.
- `..` segmenti, mixed separator ve encoded traversal benzeri riskler test matrix'te ele alinmalidir.

## Allowed output root yaklasimi

Gelecekte export helper yazma alanini izinli bir export kokune baglamalidir.

Olasil izinli kok:

- Proje icindeki `exports/` klasoru.
- Cagirici tarafindan explicit verilen ve uygulama tarafindan onaylanan export root.

Allowed output root yaklasimi:

- Yazma hedefinin nerede olabilecegini sinirlar.
- Backup, source code, cache ve database alanlarini disarida tutar.
- Handover QC export ciktisini proje dosyalariyla karistirmadan konumlandirir.

Allowed root disina cikma basarili bir export degil, hata/diagnostic result konusu olmalidir.

## Export kapsami disinda kalacak alanlar

Gelecekteki export helper su alanlara yazmamalidir:

- `.git`
- `.env` veya environment dosyalari
- `.pytest_cache`
- `__pycache__`
- Database dosyalari veya database klasorleri
- Backup / restore klasorleri
- ZIP veya yedek dosya alanlari
- Kaynak kod klasorleri

ZIP/yedek dosyalar export kapsamina alinmamalidir.

Export helper, `chief-site-engineer_adim_080_guvenli_nokta.zip` gibi ignored yedekleri stage etmemeli, uretmemeli veya export paketi parcasi gibi kullanmamalidir.

## Dosya uzantisi siniri

Gelecekteki export helper icin uzanti siniri dar tutulmalidir.

Planlanan prensip:

- JSON export icin hedef dosya uzantisi `.json` olmalidir.
- Markdown export icin hedef dosya uzantisi `.md` olmalidir.

Bu sinir:

- Yanlis formatta dosya uretimini azaltir.
- Handover ve audit ciktisinin okunabilir olmasini saglar.
- Binary, script veya config dosyasi gibi riskli hedeflere yazma ihtimalini dusurur.

Uzanti kontrolu hard validation olarak kayit reddi anlamina gelmez. Sadece export helper'in file-writing siniri icin planlanan guvenlik kuralidir.

## Dosya adi guvenligi

Dosya adi guvenligi path safety'nin ayri bir parcasidir.

Gelecekte su durumlar ele alinmalidir:

- Bos dosya adi kabul edilmemelidir.
- Dosya adi path separator icermemelidir.
- Cok uzun dosya adi icin okunur hata veya diagnostic result dusunulmelidir.
- Ozel karakterler normalize edilmeli veya dar bir izinli karakter setiyle sinirlanmalidir.
- Windows reserved names riski ele alinmalidir.

Windows reserved names ornekleri:

- `CON`
- `PRN`
- `AUX`
- `NUL`
- `COM1`
- `LPT1`

Bu adimda herhangi bir sanitizer veya validation fonksiyonu eklenmedi.

## Overwrite policy

Gelecekte dosya yazimi eklenirse guvenli varsayilan `overwrite=False` olmalidir.

Prensip:

- Mevcut dosya varsa varsayilan davranis yazmamak olmalidir.
- Explicit `overwrite=True` verilmedikce dosyanin uzerine yazilmamalidir.
- `overwrite=True` davranisi ayri test edilmelidir.
- Overwrite sessiz olmamalidir.

Bu policy, handover raporu, audit QC ciktisi veya onceki export dosyasinin yanlislikla ezilmesini engeller.

Overwrite sirasinda ileride audit/log davranisi dusunulebilir:

- Hangi dosya hedeflendi?
- Dosya daha once var miydi?
- Overwrite explicit miydi?
- Yazma basarili oldu mu?

Bu adimda audit event olusturma veya logging implementasyonu yapilmadi.

## Atomic write prensibi

Gelecekte file-writing helper eklenirse atomic write dusunulebilir.

Prensip:

- Once ayni izinli kok altinda temporary file yazilir.
- Yazim tamamlanip flush/close edildikten sonra hedef dosyaya replace yapilir.
- Hata durumunda yarim dosya hedef adiyla birakilmaz.

Bu adimda temporary file, replace veya atomic write implementasyonu yapilmadi.

Atomic write planinin da path safety sinirlerine uymasi gerekir. Temporary file izinli export kokunun disinda olusturulmamalidir.

## Hata davranisi

Gelecekte export helper iki sekilden biriyle hata raporlayabilir:

- Exception firlatmak.
- Diagnostic result dict dondurmek.

Exception yaklasimi cagirici kodun hatayi yakalamasini gerektirir.

Diagnostic result yaklasimi `status`, `ok`, `path`, `message`, `reason` gibi alanlarla okunur sonuc verebilir.

Hangi model secilirse secilsin:

- Hata kayit reddi anlamina gelmemelidir.
- Hard validation tetiklememelidir.
- `blocked` status uretmemelidir.
- Diagnostic / soft validation helper sonucunu degistirmemelidir.

Export helper uygulama icinde guvenli rapor dondururse bu rapor file-writing sonucunu anlatmali, veri kalitesi karari gibi kullanilmamalidir.

## Format helper ile file-writing helper ayrimi

Read-only format helper:

- Python dict veya Markdown string dondurur.
- Dosya yazmaz.
- Export yapmaz.
- Backup / restore davranisi ustlenmez.
- Diagnostic veya soft validation sonucu yeniden hesaplamaz.

File-writing export helper:

- Ileride yalniz hazir JSON-ready dict veya Markdown string alabilir.
- Explicit output path ister.
- Path safety, overwrite, extension, encoding ve hata davranisi tasir.
- Kalici dosya ciktisi urettigi icin ayri test matrix ister.

Bu iki katman birlestirilmemelidir.

## Handover QC export senaryosu

Handover QC export ileride yeni santiye sefine gorunurluk saglayabilir.

Uygun kullanim:

- Warning/error kayitlarini gorunur yapmak.
- Review/attention gerektiren kayitlari listelemek.
- Handover on kontrol notunu okunur dosyaya tasimak.
- Explicit handover icerigini izinli export kokune yazmak.

Uygun olmayan kullanim:

- Devir paketini otomatik bloke etmek.
- Kayit reddetmek.
- Eski santiye sefinin ozel alanini devretmek.
- Backup / restore motoru gibi davranmak.
- Database veya repository yazmak.
- Audit event olusturmak.

Handover QC export ciktisi karar degil, gorunurluk aracidir.

## Hard validation siniri

Bu adim hard validation degildir.

`target_record_id` hard validation eklenmedi.

`AuditEventRecord.__post_init__` degistirilmedi.

`FileAttachmentRecord` davranisi degistirilmedi.

Gelecekteki export helper, path hatasini dosya yazimi hatasi olarak ele alabilir; fakat bu durum domain kaydinin reddi, audit event'in gecersiz sayilmasi veya handover paketinin otomatik bloke edilmesi anlamina gelmemelidir.

## `blocked` status siniri

Bu adimda `blocked` status uretilmedi.

Gelecekteki file-writing helper da `blocked` status uretmemelidir.

Handover QC ve soft validation hattinda mevcut karar korunur:

- `pass` gorunur risk olmadigini anlatir.
- `review` manuel gozden gecirme sinyalidir.
- `attention` manuel inceleme sinyalidir.
- `blocked` otomatik engelleme anlami dogurabilecegi icin kapsam disidir.

## Mutlak kararlar

- Export / file writing helper implementasyonu yapilmadi.
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

Adim 153, export helper yazimindan once path safety ve overwrite policy konusunu ayrintili hale getirdi.

Bu belge, ileride file-writing helper implementasyonu baslamadan once relative/absolute path, allowed output root, traversal riski, parent directory, dosya adi, extension, overwrite ve hata davranisi kararlarinin test edilebilir bir zemine oturmasini saglar.
