# CSE Ana Proje Ilkeleri

Bu dokuman, CHIEF SITE ENGINEER projesinin uzun vadeli gelisim ilkelerini tanimlar. Amac, projenin buyurken saha gerceginden kopmamasini, resmi kayitlarin izlenebilir kalmasini ve ozel alan ile resmi proje hafizasinin karismamasini saglamaktir.

## Once Veri Omurgasi, Sonra Otomasyon, En Son AI

CSE once saglam veri omurgasi kurar. Kayitlar, modeller, metadata, dosya referanslari, audit izi ve backup stratejisi netlesmeden otomasyon veya AI davranislari ana sistem gibi davranamaz.

Otomasyon, dogru veri uzerinde anlamlidir. AI ise ancak guvenilir kayit, guvenilir dosya referansi ve guvenilir denetim izi uzerine eklenmelidir.

## Kucuk ve Guvenilir Saha Hafizasi

CSE'nin hedefi ilk asamada buyuk bir platform olmak degildir. Hedef, santiye sefinin gunluk kayit, kalite kontrol, uygunsuzluk, dosya eki ve karar hafizasini kucuk ama guvenilir parcalarla tutmaktir.

Her yeni ozellik once basit model, test ve dokumantasyon seviyesinde netlesmelidir.

## Resmi Kayit ve Ozel Alan Ayrimi

Resmi proje kayitlari ile Santiye Sefi Ozel Alani ayridir.

Resmi kayitlar proje hafizasidir. Ozel alan ise santiye sefinin kisisel calisma alani, hatirlaticilari ve taslak notlari icindir.

Ozel alan icerigi otomatik olarak resmi kayit sayilmaz. Resmi kayda aktarim ancak bilincli ve acik bir islemle yapilmalidir.

## Resmi Kayitlar Fiziksel Olarak Silinmez

Kanıt niteligindeki resmi kayitlar fiziksel olarak silinmemelidir. Yanlis kayitlar silinmek yerine arsivlenir, hukumden dusurulur, revize edilir veya yeni kayitla superseded hale getirilir.

Bu ilke NCR, tutanak, kalite kontrol kaydi, attachment metadata, audit event ve proje kararlari icin gecerlidir.

## Kanit Zinciri ve Audit Izi

Bir kaydin kim tarafindan, ne zaman, hangi nedenle olusturuldugu veya degistirildigi izlenebilir olmalidir.

Audit izi ileride su sorulara cevap vermelidir:

- Kaydi kim olusturdu?
- Kayit ne zaman degisti?
- Degisiklik nedeni neydi?
- Kayit hukumden dusuruldu mu?
- Bir kayit baska bir kaydin yerine mi gecti?
- Dosya eki kayboldu, tasindi veya karantinaya alindi mi?

## Metadata ve Dosya Butunlugu

Dosya ekleri icin metadata ile fiziksel dosya arasindaki bag korunmalidir. Metadata bir dosyaya isaret ediyorsa dosyanin varligi, path standardi, okunabilirligi ve iliskili ana kaydi kontrol edilebilir olmalidir.

Attachment integrity hatti bu nedenle dosya varligi, missing file, orphan file, invalid path, duplicate metadata ve unreadable file durumlarini ayri ele alir.

## Medya Dosyalari Veritabanina Gomulmez

Fotograf, video, PDF, belge ve ses dosyalari veritabanina blob olarak gomulmemelidir.

Model dosyanin kendisini degil; dosya yolu, dosya tipi, MIME tipi, dosya boyutu, yukleyen kisi, yukleme zamani, orijinal dosya adi ve not gibi metadata bilgilerini tutar.

Video gibi buyuk medya dosyalari icin bu ayrim ozellikle onemlidir.

## Codex Gorevleri Kucuk ve Test Edilebilir Parcalara Bolunur

Her Codex adimi tek bir amaca odaklanmalidir.

Yeni model, repository davranisi, helper, dokumantasyon veya test genisletmesi kucuk parcalar halinde yapilmalidir.

Buyuk refactor, migration, upload service, API, GUI veya AI entegrasyonu tek adimda eklenmemelidir.

## Sahada Hizli Veri Girisi

CSE uzun formlar yerine sahada hizli veri girisini hedefler.

Santiye sefi icin onemli olan, kaydi gereksiz alanlara bogulmadan dogru zamanda ve dogru baglamla tutabilmektir. Daha ayrintili raporlar, mevcut sade kayitlardan uretilebilir.

## Offline, Backup, Restore ve Encryption Erken Tasarim Ilkesidir

CSE sahada internetin zayif veya kesintili olabilecegini kabul eder.

Offline calisma, backup, restore ve encryption konulari sonradan yamanan ozellikler olmamalidir. Daha erken mimari kararlar bu ihtimalleri bozmadan tasarlanmalidir.

Ozel alan verileri icin kullanici bazli encryption ve gerekirse key silme / crypto-shredding yaklasimi ileride degerlendirilmelidir.

## Bu Dokumanin Siniri

Bu dokuman kod yazmaz.

Veritabani migration, auth, permission, encryption, backup veya AI implementasyonu eklemez.

Bu dokuman CSE'nin uzun vadeli mimari pusulasini tanimlar.
