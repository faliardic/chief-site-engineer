# Adim 108 - Attachment Integrity Scanner Input Modeli Plani

## Amac

Bu dokuman gelecekte kodlanabilecek attachment integrity scanner input modelinin kapsam ve alan sozlesmesini tarif eder.

Input modeli, scanner'in hangi metadata kayitlarini, hangi attachment root altinda, hangi guvenlik sinirlariyla ve hangi dry-run secenekleriyle kontrol edecegini anlatan parametre yapisi olacaktir. Bu adimda kod, dataclass, scanner helper veya test eklenmez.

## Input Modelinin Rolu

Input modeli scanner'a verilecek calisma istegini temsil eder.

Bu model:

- dosya taramasi yapmaz
- dosya okumaz
- dosya silmez
- dosya tasimaz
- metadata degistirmez
- scanner sonucu uretmez
- yalnizca scanner'a verilecek parametrelerin sozlesmesini tarif eder

Bu ayrim, scanner davranisi ile scanner'a verilen istek bilgisini birbirinden ayirir.

## Olasi Alanlar

Gelecekteki input modelinde su alanlar dusunulebilir:

- `attachment_records`
- `attachment_root`
- `include_orphan_check`
- `allowed_record_types`
- `checked_by`
- `source`
- `notes`
- `created_at` / `requested_at`

Alan anlamlari:

- `attachment_records`: Scanner'in kontrol edecegi `FileAttachmentRecord` metadata kayitlari.
- `attachment_root`: Scanner'in dosya sistemi kontrolunu sinirlayacagi acik kok klasor.
- `include_orphan_check`: Metadata karsiligi olmayan orphan dosyalarin aranip aranmayacagini belirleyen secenek.
- `allowed_record_types`: Istenirse sadece belirli kayit tiplerinin kontrol edilmesini saglayan filtre.
- `checked_by`: Kontrolu isteyen veya calistiran kullanici/rol bilgisi. Auth sistemi olmadigi icin ilk asamada serbest metadata olabilir.
- `source`: Kontrolun manuel, test, rapor, bakim veya ileride baska bir kaynaktan geldigini anlatan kisa bilgi.
- `notes`: Scanner calistirma nedeni, kapsam aciklamasi veya sinirlama notlari.
- `created_at` / `requested_at`: Input isteginin ne zaman olusturuldugunu gosteren zaman bilgisi.

Bu liste kesin implementasyon karari degildir. Gelecekteki model ve test adiminda daraltilabilir.

## Zorunlu ve Opsiyonel Alan Ayrimi

Ilk tasarimda zorunlu olmasi muhtemel alanlar:

- `attachment_records`
- `attachment_root`

Opsiyonel olmasi muhtemel alanlar:

- `include_orphan_check`
- `allowed_record_types`
- `checked_by`
- `source`
- `notes`
- `created_at` / `requested_at`

Bu ayrim kesin uygulama karari degildir. Gelecekteki dataclass veya model adiminda validasyon kurallariyla birlikte tekrar netlestirilmelidir.

## Attachment Root ve Path Guvenligi

Input modeli, scanner'in root disina cikmasini engelleyecek tasarimin baslangic noktasi olmalidir.

Guvenlik kararlari:

- `attachment_root` acikca verilmelidir
- root disina cikan path'ler scanner tarafindan kabul edilmemelidir
- absolute path davranisi ayrica tasarlanmadan serbest birakilmamalidir
- relative path traversal riski ayrica test edilmelidir
- orphan check yapilacaksa yalnizca root altinda yapilmalidir

Input modeli tek basina guvenlik kontrolu uygulamaz; ancak scanner'in guvenli calismasi icin gerekli parametre sinirlarini tanimlar.

## Orphan Check Yaklasimi

Orphan dosya kontrolu metadata kayitlari disinda dosya sistemi icindeki dosyalara bakmayi gerektirebilecegi icin daha riskli bir alandir.

Ilk yaklasim:

- orphan check varsayilan olarak kapali olabilir
- acilirsa yalnizca `attachment_root` altinda calismalidir
- orphan check hicbir dosyayi silmemeli, tasimamali veya karantinaya almamalidir
- sadece rapor uretmelidir

Bu davranis, ilk scanner hattinin dry-run ve raporlama sinirini korur.

## Dry-run Scanner ile Iliski

Input modeli, Adim 107'de belirlenen dry-run scanner yaklasimini besleyecek yapidir.

Gelecekte input modeli su ciktilara zemin hazirlar:

- `AttachmentIntegrityResult` listesi
- `AttachmentIntegrityReport`
- JSON export ile rapor dosyasi

Bu adimda output modeli, serializer, JSON export veya scanner kodu yazilmaz. Mevcut raporlama hatti yalnizca tasarim baglami olarak kullanilir.

## Ilk Implementasyon Siniri

Gelecekteki ilk kod adimi icin onerilen sinir:

- sadece input model tasarimi veya dataclass baslangici
- dosya sistemi taramasi yok
- scanner helper yok
- orphan dosya arama yok
- path normalize/check helper yok
- audit event yok
- backup yok
- upload service yok

Bu sinir, scanner hattinin once parametre sozlesmesini netlestirmesini ve davranis karmasikligini erken buyutmemesini saglar.

## Bu Adimin Siniri

Bu adim sadece dokumantasyon adimidir.

Bu adimda uygulama kodu degisikligi, dataclass ekleme, scanner implementasyonu, test dosyasi degisikligi, dosya sistemi taramasi, klasor traversal, gercek dosya okuma, gercek dosya silme, gercek dosya tasima, metadata guncelleme, upload service, backup/restore, audit event implementasyonu, database, API, GUI, CLI, AI entegrasyonu, automation veya refactor yapilmadi.

Commit atilmadi, push yapilmadi ve `chief-site-engineer_adim_080_guvenli_nokta.zip` dosyasi stage edilmedi.
