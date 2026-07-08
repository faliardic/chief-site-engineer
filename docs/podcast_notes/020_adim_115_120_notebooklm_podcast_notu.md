# Podcast 020 - Adim 115-120 NotebookLM Podcast Notu

## 1. Bolumun Ana Temasi

Bu bolumun ana temasi, `AuditEventRecord` modelinin olay turu ve hedef kayit sozlesmelerini adim adim daha kontrollu hale getirmesidir.

Podcast 019'da audit event hatti baslangic modeli ve required field validation seviyesine gelmisti. Podcast 020'de bu temel uzerine once `event_type` icin adlandirma sozlesmesi kurulur, sonra desteklenen event type listesi koda baglanir. Ardindan `target_record_type` ve `target_record_id` alanlarinin birlikte nasil kullanilacagi dokumante edilir ve pair validation ile tek tarafli referans riski kapatilir.

Bu araligin ikinci yarisi target record type tarafini olgunlastirir. `target_record_type` once serbest aciklama alani olmaktan cikarilip makine-okunabilir sozlesmeye baglanir, sonra `AUDIT_TARGET_RECORD_TYPES` ve `AUDIT_TARGET_RECORD_TYPE_SET` ile allowed-list validation seviyesine tasinir.

Bu aralik, CSE'nin olay izini serbest metin karmasasindan cikarmaya ve ileride raporlanabilir, filtrelenebilir, guvenilir bir audit dili kurmaya odaklanir.

## 2. Bu Aralikta CSE Ne Kazandi?

CSE bu aralikta alti onemli kazanim elde etti.

Ilk kazanim, `AuditEventRecord.event_type` alaninin serbest aciklama alani olmaktan cikarilmasidir. Event type degerleri `domain.action` biciminde, kucuk harfli, bosluksuz ve makine tarafindan okunabilir degerler olarak planlandi.

Ikinci kazanim, event type sozlesmesinin `AUDIT_EVENT_TYPES` tuple'i ve `AUDIT_EVENT_TYPE_SET` frozenset'i ile koda baglanmasidir. Boylece desteklenmeyen event type degerleri model olusturulurken reddedilir.

Ucuncu kazanim, `target_record_type` ve `target_record_id` alanlari icin iliski kurallarinin yazili hale gelmesidir. Bu alanlar bir audit event'in hangi kayitla ilgili oldugunu anlatir; aciklama, gerekce veya snapshot alani degildir.

Dorduncu kazanim, pair validation ile tek tarafli target record referanslarinin engellenmesidir. Sadece type veya sadece id ile eksik audit hedefi olusturulamaz.

Besinci kazanim, `target_record_type` icin ilk resmi type sozlesmesidir. Bu sozlesme target type degerlerini serbest metin yerine desteklenen makine-okunabilir kategori degerleri olarak konumlandirir.

Altinci kazanim, target type sozlesmesinin `AUDIT_TARGET_RECORD_TYPES` ve `AUDIT_TARGET_RECORD_TYPE_SET` ile koda baglanmasidir. Bos veya whitespace target reference degerleri de bu adimda reddedilir.

## 3. Adim Adim Gelisim Ozeti

### Adim 115 - Audit Event Type Sozlesmesi

Bu adimda `AuditEventRecord.event_type` alani icin ilk resmi sozlesme dokumante edildi.

Event type degerlerinin kucuk harfli, Turkce karakter icermeyen, bosluksuz ve nokta ayrimli stringler olarak yazilmasi planlandi. Onerilen bicim `domain.action` olarak belirlendi.

Ilk domain adaylari `record`, `attachment`, `integrity`, `json`, `backup`, `restore`, `handover` ve `audit` olarak gruplandi. Ilk event type adaylari kayit olaylari, attachment olaylari, attachment integrity olaylari, JSON export olaylari, backup/restore olaylari, handover olaylari ve audit sistem olaylari olarak listelendi.

Bu adim onemlidir cunku `event_type` serbest metin gibi kullanilirsa filtreleme, raporlama, audit trail inceleme ve ilerideki validation davranislari tutarsiz hale gelir. Insan tarafindan okunabilir aciklama gerekiyorsa `reason` veya `notes`; once/sonra bilgisi gerekiyorsa `old_value` ve `new_value` kullanilmalidir.

Bu adim documentation-only tutuldu. Uygulama kodu, test kodu, validation, enum, sabit liste, repository, database, JSON persistence veya otomatik audit event uretimi eklenmedi.

### Adim 116 - Audit Event Type Sabitleri ve Validation

Bu adimda Adim 115'te dokumante edilen event type sozlesmesi dar kapsamli olarak koda baglandi.

`AUDIT_EVENT_TYPES`, desteklenen event type degerlerinin sirali tuple listesi olarak eklendi. `AUDIT_EVENT_TYPE_SET`, bu tuple'dan uretilen frozenset yapisi olarak membership kontrolu icin kullanildi.

`AuditEventRecord.__post_init__` icinde mevcut required field validation korundu. Ek olarak, `event_type` dolu oldugu halde `AUDIT_EVENT_TYPE_SET` icinde degilse `ValueError("event_type is not supported")` yukseltir.

Bu adimda `event_type is required` ile `event_type is not supported` hata ayrimi bilincli olarak korundu. Bos, whitespace veya `None` event type required hatasidir; dolu ama desteklenmeyen event type unsupported hatasidir.

Testler `AUDIT_EVENT_TYPES` listesinin ilk sozlesme degerlerini icerdigini, `AUDIT_EVENT_TYPE_SET` ile uyumlu oldugunu, duplicate deger olmadigini, desteklenen event type ile model olusabildigini ve desteklenmeyen event type degerinin reddedildigini dogruladi.

Bu adimda database, repository, migration, JSON import/export, audit event persistence, otomatik audit event uretimi, decorator, middleware, auth/user/role sistemi, scanner baglantisi, attachment integrity kodu degisikligi, API, GUI, CLI veya yeni dependency eklenmedi.

### Adim 117 - Audit Event Target Record Iliski Kurallari

Bu adimda `AuditEventRecord.target_record_type` ve `target_record_id` alanlari icin ilk iliski sozlesmesi dokumante edildi.

`target_record_type`, audit olayinin hangi tur kayitla iliskili oldugunu belirtir. `target_record_id`, bu kayit turu icindeki somut kimligi anlatir. Bu iki alan birlikte kullanildiginda audit event belirli bir kayitla iliskilidir.

Iki alan birlikte `None` ise olay genel proje, sistem veya surec olayi olabilir. Sadece `target_record_type` doluysa hangi kayda bakilacagi bilinmez; sadece `target_record_id` doluysa kimligin hangi kayit turune ait oldugu bilinmez.

Bu adim onemlidir cunku target record alanlari serbest aciklama, gerekce, onceki/yeni deger veya tam kayit snapshot'i tasimamalidir. `event_type` ne oldugunu, target record alanlari hangi kayitla ilgili oldugunu, `reason` neden oldugunu ve `notes` ek insan baglamini anlatir.

Bu adim documentation-only tutuldu. Uygulama kodu, test kodu, validation, enum, sabit liste, repository, database, JSON persistence veya otomatik audit event uretimi eklenmedi.

### Adim 118 - Audit Event Target Record Pair Validation

Bu adimda Adim 117'de dokumante edilen target record iliski kuralinin ilk kod karsiligi eklendi.

`AuditEventRecord.__post_init__` icinde `target_record_type` ve `target_record_id` birlikte kontrol edilir. Iki alan birlikte `None` ise gecerlidir. Iki alan birlikte `None` degilse gecerlidir. Sadece biri `None` ise `ValueError("target_record_type and target_record_id must be provided together")` yukseltir.

Bu adimda validation yalnizca `None` bazlidir. `target_record_type=""` ve `target_record_id=""` birlikte verildiginde bu adimda gecici olarak kabul edilebilir; cunku bos string ve whitespace validation daha sonraki icerik validation konusudur.

Testler `target_record_type` tek basina verilemez ve `target_record_id` tek basina verilemez davranislarini dogruladi. Mevcut testler iki alanin birlikte `None` kalabildigini, birlikte dolu olabildigini ve opsiyonel bos string davranisinin bu asamada bozulmadigini korudu.

Bu adimda target type constants, target type enum, target type allowed-list validation, target record id format validation, bos string/whitespace target reference validation, database, repository, migration, foreign key implementasyonu, JSON import/export, audit persistence, otomatik audit uretimi, scanner baglantisi, API, GUI veya CLI eklenmedi.

### Adim 119 - Audit Event Target Record Type Sozlesmesi

Bu adimda `AuditEventRecord.target_record_type` alani icin ilk resmi type sozlesmesi dokumante edildi.

Amac, Adim 117 ve Adim 118'de netlesen target record iliskisinden sonra ileride kodlanabilecek target record type sabitleri ve allowed-list validation icin guvenli bir sozlesme zemini olusturmaktir.

`target_record_type`, audit olayinin hangi tur kayitla ilgili oldugunu anlatan kisa ve makine-okunabilir kategori degeridir. Olayin ne oldugunu, neden yapildigini, insan notunu, onceki/yeni degeri, tam kayit icerigini veya snapshot'i tasimaz.

Ilk target record type adaylari `project`, `project_record`, `attachment`, `attachment_metadata`, `attachment_integrity_report`, `json_export`, `backup_package`, `restore_operation`, `handover_package` ve `audit_event` olarak dokumante edildi.

Bu adim documentation-only tutuldu. Target type constants, target type enum, target type allowed-list validation, `AuditEventRecord.__post_init__` degisikligi, test degisikligi, target record id format validation, bos string/whitespace validation, database iliski modeli, repository, migration, JSON schema, API, GUI veya CLI davranisi eklenmedi.

### Adim 120 - Audit Event Target Record Type Sabitleri ve Validation

Bu adimda Adim 119'da dokumante edilen target record type sozlesmesi dar kapsamli olarak koda baglandi.

`AUDIT_TARGET_RECORD_TYPES`, desteklenen target record type degerlerinin sirali tuple sozlesmesi olarak eklendi. `AUDIT_TARGET_RECORD_TYPE_SET`, bu tuple'dan uretilen frozenset yapisi olarak membership kontrolu icin kullanildi.

`AuditEventRecord.__post_init__` icinde mevcut validation sirasi korundu ve target reference icerik validation'i eklendi. Iki target alan birlikte `None` ise gecerlidir. Sadece biri `None` ise pair validation mesaji korunur. Ikisi birlikte verildiyse `target_record_type` ve `target_record_id` bos string veya whitespace olamaz. Ayrica `target_record_type`, `AUDIT_TARGET_RECORD_TYPE_SET` icinde olmalidir.

Bu adim pair validation ile allowed-list validation ayrimini korur. Pair validation iki alanin birlikte kullanilip kullanilmadigini; allowed-list validation ise `target_record_type` degerinin desteklenen sozlukte olup olmadigini kontrol eder.

Testlerde target type sabit listesinin ilk sozlesme degerlerini icerdigi, target type set'in tuple ile uyumlu oldugu, duplicate olmadigi, desteklenen target type degerinin kabul edildigi, desteklenmeyen target type degerinin reddedildigi ve bos/whitespace target reference degerlerinin reddedildigi dogrulandi. Final test sonucu kaynakta `243 passed` olarak kaydedildi.

Bu adimda target record id format validation, target record id prefix validation, target record existence kontrolu, foreign key implementasyonu, database, repository, migration, JSON export/import, audit event persistence, otomatik audit uretimi, enum class, alias sistemi, config dosyasi, API, GUI veya CLI eklenmedi.

## 4. Teknik Kararlar

- `event_type` degerleri serbest metin degil, `domain.action` biciminde makine-okunabilir sozlesme degeri olarak planlandi.
- Event type aciklama, gerekce veya once/sonra deger alani yerine kullanilmadi; `reason`, `notes`, `old_value` ve `new_value` ayrimi korundu.
- `AUDIT_EVENT_TYPES` okunabilir ve sirali tuple sozlesmesi olarak eklendi.
- `AUDIT_EVENT_TYPE_SET`, event type membership kontrolu icin `frozenset` olarak kullanildi.
- Enum yerine tuple/frozenset tercih edildi; bu asamada sade, okunabilir ve geri alinabilir yapi yeterli goruldu.
- Required field validation ile event type allowed-list validation ayrimi korundu.
- Target record iliskisi `target_record_type` ve `target_record_id` ciftiyle temsil edildi.
- Pair validation, tek tarafli target record referanslarini reddedecek sekilde eklendi.
- Pair validation ile target type allowed-list validation ayri karar hatlari olarak tutuldu.
- `target_record_type` icin makine-okunabilir allowed type sozlesmesi dokumante edildi.
- `AUDIT_TARGET_RECORD_TYPES` ve `AUDIT_TARGET_RECORD_TYPE_SET` ile target type allowed-list validation eklendi.
- Bos veya whitespace target reference degerleri Adim 120'de reddedildi.
- Target record id format validation, prefix validation ve varlik kontrolu sonraki adimlara birakildi.
- Persistence, repository, otomatik audit uretimi, scanner baglantisi ve JSON audit persistence bu aralikta eklenmedi.

## 5. Veri Omurgasi Acisindan Anlami

Adim 115-120, CSE veri omurgasinda audit event kayitlarinin daha tutarli, filtrelenebilir ve raporlanabilir hale gelmesine hizmet eder.

Olay turunun kontrollu olmasi onemlidir cunku ayni olay farkli serbest metinlerle yazilirsa sistem bunu ayni kategori olarak guvenilir sekilde goremez. `record.updated`, `attachment.linked` veya `integrity.report_generated` gibi sabit event type degerleri, audit trail incelemesi ve raporlama icin ortak dil saglar.

Target record iliskisi olay izinin guvenilirligini artirir. Bir audit event yalnizca "ne oldu?" sorusuna degil, "hangi tur kayitla ve hangi kimlikle ilgili oldu?" sorusuna da cevap verebilir.

Pair validation eksik baglanti riskini azaltir. Sadece type veya sadece id ile olusan yarim referanslar, ileride rapor ve sorgularda belirsizlik uretir. Bu adimlar o belirsizligi erken seviyede engeller.

Target type allowed-list validation veri kalitesini artirir. `attachment`, `backup_package`, `handover_package` gibi desteklenen degerler disinda serbest metin kabul edilmediginde audit event kayitlari daha temiz kalir.

AI ozelligi bu aralikta yoktur. Ancak ileride AI katmani eklenecekse, guvenilir cevap verebilmesi icin olay turu ve hedef kayit referanslarinin tutarli olmasi gerekir. Bu sozlesmeler, gelecekteki yorumlama katmaninin uzerine dayanabilecegi temiz veri zeminini guclendirir.

## 6. Santiye Sefi Kullanimi Acisindan Anlami

Santiye sefi acisindan bu araligin anlami, ileride "hangi olay, hangi kayitla ilgiliydi?" sorusuna daha guvenilir cevap verilebilmesidir.

Olay turlerinin serbest metin olmamasi raporlamayi guclendirir. Herkes ayni olayi farkli cumlelerle yazarsa sahadaki gecmis izlenemez hale gelir. Sabit event type degerleri, sahadaki olaylari ortak bir dile tasir.

`target_record_type` ve `target_record_id` ayrimi dosya ve kayit karmasasini azaltir. Bir attachment olayi attachment kaydina, bir integrity raporu integrity report kaydina, bir backup olayi backup package referansina baglanabilir.

Pair validation eksik baglanti riskini azaltir. Sadece "attachment" yazip hangi attachment oldugunu belirtmeyen ya da sadece id yazip bunun hangi kayit turune ait oldugunu belirtmeyen olaylar reddedilir.

Bu yapi WhatsApp, galeri, klasor daginikligi ve sozlu takip zayifligini azaltmaya hizmet eder. CSE, sahadaki olaylari rastgele notlardan daha disiplinli bir olay-kayit iliskisine tasimaya baslar.

## 7. Ogrenme Notlari

Bu araligin ilk ogrenmesi, audit event icin serbest metin rahatliginin uzun vadede veri kalitesini bozabilecegidir. Kisa ve makine-okunabilir sozlesmeler, ileride filtreleme ve raporlama icin daha guvenilir temel olusturur.

Ikinci ogrenme, validation davranisinin tek adimda her seyi kapsamak zorunda olmadigidir. Required field validation, event type validation, pair validation ve target type allowed-list validation ayri adimlarda eklenerek hata mesajlari ve kapsam daha anlasilir tutuldu.

Ucuncu ogrenme, tuple/frozenset gibi sade yapilarin erken sozlesme asamasinda yeterli olabilecegidir. Enum veya daha buyuk type sistemi gerekmeden merkezi liste ve membership kontrolu saglanabildi.

Dorduncu ogrenme, pair validation ile allowed-list validation'in farkli problemleri cozdogudur. Pair validation iliski eksik mi diye bakar; allowed-list validation deger desteklenen sozlukte mi diye bakar.

Besinci ogrenme, target record id formatinin aceleye getirilmemesidir. Target type sozlesmesi koda baglandi, fakat id format/prefix/varlik kontrolu ayri tasarim konusu olarak sonraki adimlara birakildi.

## 8. Riskler ve Bilincli Sinirlar

Bu aralikta her sey otomatiklestirilmedi. Audit event type ve target record type validation eklense bile otomatik audit event uretimi eklenmedi.

Database, repository, migration, foreign key implementasyonu, JSON audit persistence, scanner baglantisi, auth/user/role sistemi, middleware, decorator, API, GUI, CLI veya AI entegrasyonu eklenmedi.

Scanner ile audit event arasinda otomatik baglanti kurulmadi. Attachment integrity kodu bu aralikta buyutulmedi.

Target record id format validation, prefix validation, UUID validation, ISO tarih validation, target record existence kontrolu, `old_value` / `new_value` validation ve opsiyonel alanlarin genel validation'i sonraki adimlara birakildi.

Bu aralikta ZIP veya yedek dosyalar repo kapsaminda islenmedi. ZIP acma, tasima, silme, stage etme veya yeniden uretme davranisi yoktur.

Bu sinirlar, CSE'nin audit dilini guclendirirken persistence, otomasyon ve dosya sistemi etkilerini kontrollu sekilde ertelemesini saglar.

## 9. Onceki Podcast ile Baglanti

Podcast 019, Adim 109-114 araliginda scanner dry-run helper baslangicini, attachment integrity rapor kullanim ozetini, audit event model planini, `AuditEventRecord` baslangic modelini ve required field validation davranisini ele almisti.

Podcast 020 bu modelin uzerine sozlesme ve validation katmanlari ekler. Once event type dilini netlestirir, sonra target record iliskisini daha guvenli hale getirir.

Bu nedenle Podcast 019 "audit event veri seklinin dogusu" ise, Podcast 020 "audit event dilinin ve hedef kayit baglantisinin disipline edilmesi" bolumudur.

## 10. Sonraki Podcast'e Kopru

Sonraki podcast icin dogal aralik Adim 121-122 hattidir.

Bu aralikta `target_record_id` icin format tasarimi ve validation tasarimi ele alinabilir. Podcast 020'de target record type sozlesmesi koda baglandi; Podcast 021 ise target record id tarafindaki bicim ve validation kararlarini anlatmak icin uygun devam noktasi olur.

Podcast 021, hedef kayit turu sozlesmesinden hedef kayit kimligi sozlesmesine gecisi tamamlayacak kisa ama kritik bir kopru olabilir.

## 11. NotebookLM Icin Kisa Yayin Ozeti

Bu bolum, CSE'nin Adim 115-120 arasinda `AuditEventRecord` icin event type ve target record sozlesmelerini nasil olgunlastirdigini anlatir.

Adim 115, `event_type` alaninin `domain.action` biciminde makine-okunabilir bir sozlesme degeri olmasini dokumante eder. Adim 116, bu sozlesmeyi `AUDIT_EVENT_TYPES` ve `AUDIT_EVENT_TYPE_SET` ile koda baglar ve desteklenmeyen event type degerlerini reddeder.

Adim 117, `target_record_type` ve `target_record_id` alanlarinin birlikte nasil kullanilacagini dokumante eder. Adim 118, pair validation ile tek tarafli target record referanslarini reddeder.

Adim 119, `target_record_type` icin ilk type sozlesmesini yazar. Adim 120, `AUDIT_TARGET_RECORD_TYPES` ve `AUDIT_TARGET_RECORD_TYPE_SET` ile target type allowed-list validation ekler; bos veya whitespace target reference degerlerini de reddeder.

Bu podcastin ana fikri sudur: CSE, audit event kayitlarini serbest metin ve eksik referans karmasasindan cikarip kontrollu olay turu ve hedef kayit sozlesmelerine tasir.
