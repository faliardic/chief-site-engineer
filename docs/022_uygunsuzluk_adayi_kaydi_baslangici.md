# Adim 022 - Basit Uygunsuzluk Adayi Kayit Modeli Baslangici

## Amac

Bu adimin amaci, santiyede ileride uygunsuzluk kaydina donusebilecek gozlem, eksik, hata, risk veya kontrol sonucu notlarini sade bir veri modeliyle temsil etmektir.

Bu adim yalnizca uygunsuzluk adayini kayda almak icin gereken en kucuk veri modeli baslangicidir.

## Santiye Acisindan Anlami

Santiye sefi sahada bir eksik, hata veya risk gordugunde bunun hemen resmi uygunsuzluk kaydina donusmesi gerekmeyebilir. Ancak bu bilginin kaybolmamasi gerekir.

`NonconformityCandidateRecord`, bu erken asama bilgiyi sade sekilde tutar. Bu adim gercek uygunsuzluk yonetimi degildir.

## NonconformityCandidateRecord Modeli

`NonconformityCandidateRecord`, ileride uygunsuzluk kaydina donusebilecek aday bilgiyi temsil eder.

Bu model aday basligini, aday turunu, konumu, gozlenen sorunu, tespit eden kisiyi, tespit tarihini, durum bilgisini ve notlari tutar.

## Model Alanlari

- `candidate_title`: Uygunsuzluk adayinin kisa basligi.
- `candidate_type`: Adayin eksik, hata, risk, gozlem veya kontrol sonucu notu gibi turu.
- `location`: Aday uygunsuzlugun goruldugu saha alani veya konum.
- `observed_issue`: Gozlenen sorun, eksik veya risk aciklamasi.
- `detected_by`: Aday uygunsuzlugu fark eden veya kaydi olusturan kisi.
- `detection_date`: Aday uygunsuzlugun fark edildigi veya kaydedildigi tarih.
- `status`: Kaydin durum bilgisi. Varsayilan deger `open`.
- `notes`: Serbest not alani.

## Varsayilan Degerler

- `status`: Varsayilan olarak `open`.
- `notes`: Varsayilan olarak `None`.

## Bu Adimda Bilerek Yapilmayanlar

Bu adim gercek uygunsuzluk yonetimi degildir.

Bu adim NCR sureci degildir.

Bu adim duzeltici faaliyet, sorumlu atama, termin, onay veya kapatma is akisi degildir.

Bu adim fotograf/dosya eki veya raporlama sistemi degildir.

Bu adim kontrol sonucu, saha notu, gorev veya gunluk rapor baglantisi kurmaz.

Veritabani, JSON kayit sistemi, API, GUI/web arayuzu, CLI ve Excel/PDF cikti eklenmemistir.

## Ileride Baglanabilecegi Moduller

Bu model ileride uygunsuzluk kaydi, kontrol sonucu, saha notu, gorev adayi, gunluk rapor, dosya eki veya duzeltici faaliyet adayi kayitlariyla baglanabilir.

Bu baglantilar sonraki adimlarda ihtiyac netlestikce kurulacaktir.

## Kabul Kriterleri

- `NonconformityCandidateRecord` basit `@dataclass` modeli olarak eklendi.
- Model aday basligi, aday turu, konum, gozlenen sorun, tespit eden kisi ve tespit tarihi bilgisini tutar.
- `status` varsayilan degeri `open` olarak tanimlandi.
- `notes` varsayilan degeri `None` olarak tanimlandi.
- Model baska modellerle kod seviyesinde baglanmadi.
- Uygunsuzluk yonetimi, NCR sureci, duzeltici faaliyet, sorumlu atama, termin, onay/kapatma is akisi, fotograf/dosya eki veya raporlama sistemi eklenmedi.
