# Adim 133 - Record ID Helper API Boundary and Test Standardization Plan

## API boundary nedir?

API boundary, bir fonksiyonun veya modulun nerede baslayip nerede bittigini anlatan sinirdir.

Bir helper fonksiyonun adi, dondurdugu veri ve hata davranisi onun API'sidir. Fakat API boundary sadece "ne yapar?" sorusunu degil, "ne yapmaz?" sorusunu da cevaplar.

Bu adimda record ID helper API'si icin sinir sudur:

- Mapping bilgisi dondurur.
- Target type icin ID ailesi ve prefix adaylarini gosterir.
- `target_record_id` degerini kabul veya reddetmez.
- Model validation davranisini degistirmez.

## Helper fonksiyon neden validation fonksiyonu degildir?

Helper fonksiyon bilgi verir. Validation fonksiyonu karar verir.

Bu projedeki helperlar su sorulara cevap verir:

- Bu `target_record_type` hangi ID aileleriyle iliskili olabilir?
- Bu `target_record_type` icin hangi prefix adaylari biliniyor?

Ama su soruya cevap vermez:

- Bu `target_record_id` kabul edilmeli mi, reddedilmeli mi?

Bu ayrim onemlidir. Cunku `project_record` gibi genis target type degerleri birden fazla ID ailesini temsil eder. Bir helperdan gelen prefix listesi dogrudan hard validation'a baglanirsa eski testler veya gercek veriler beklenmeden kirilabilir.

## Test ornekleri neden bir anda degistirilmez?

Test ornekleri sadece veri degildir; gecmis kararlarin ve davranis beklentilerinin izidir.

Ornegin `NCR-001`, `REC-1`, `file-att-001` ve `audit-001` gibi ornekler sistemin uzun sure esnek ID kabul ettigini gosterir.

Bu ornekleri bir anda `NCR-2026-0001` veya `ATT-2026-0001` gibi canonical bicimlere cevirmek, testin neyi korudugunu belirsizlestirir.

Daha guvenli yaklasim sudur:

1. Eski ornekler backward compatibility testi olarak korunur.
2. Yeni helper testlerinde canonical prefix adaylari kullanilir.
3. Model validation testleri ile helper mapping testleri ayrilir.
4. Eski ornekleri kaldirma karari ancak migration ve sozlesme netlesince verilir.

## Soft validation neden hard validation'dan once gelir?

Soft validation, uyari veya bilgi uretir. Hard validation ise hata uretir.

Soft validation kullanildiginda sistem sunu soyleyebilir:

```text
Bu target_record_id bilinen prefixlerden biriyle baslamiyor.
```

Ama kaydi olusturmayi engellemez.

Hard validation ise ayni durumda kaydi reddeder.

Bu yuzden soft validation daha guvenli bir ara adimdir. Once uyumsuzluklar gorunur hale gelir, sonra ekip hangi orneklerin gercekten hatali, hangilerinin legacy ama kabul edilebilir oldugunu ayirabilir.

## Audit log guvenilirligi icin bu ayrim neden onemlidir?

Audit log, sistemde ne oldugunu ve hangi kayitla ilgili oldugunu anlatan kanit zinciridir.

Audit log cok gevsek olursa kayitlar daginik ve zor sorgulanir hale gelir. Cok erken sertlestirilirse de eski veya gecerli kayitlar gereksiz yere reddedilebilir.

Bu yuzden CSE'de sira bilincli olarak boyle kurulur:

1. Record ID envanteri.
2. Central record ID contract.
3. Constants ve mapping helper.
4. API boundary ve test standardizasyon plani.
5. Soft validation plani.
6. Ancak en son hard validation.

Bu sira, hizli ozellik eklemekten cok guvenilir veri omurgasi kurmaya odaklanir.

## Bu adimin ana dersi

Her helper validation degildir.

Bir mapping helper, sisteme "hangi aileler var?" sorusunu cevaplatir. Bir validation helper ise "bu deger gecsin mi, gecmesin mi?" kararini verir.

Bu iki rol karistirilmazsa kod daha guvenli, testler daha anlamli ve audit log daha guvenilir hale gelir.
