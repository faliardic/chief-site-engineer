# Adim 018 - Basit Saha Notu Kayit Modeli Baslangici

## Revizyon Sebebi

Onceki Adim 018 onerisi iletisim kisisi kaydi uzerineydi. Ancak `ContactPersonRecord` mevcut oldugu icin Adim 018 saha notu kapsamina revize edilmistir.

Bu revizyon, ayni isimle ikinci model eklememek ve proje kapsamini kucuk tutmak icin yapildi.

## Amac

Bu adimin amaci, santiye sefinin sahada gordugu kucuk notlari, gozlemleri, uyarilari, hatirlatmalari ve serbest aciklamalari ileride takip edebilmek icin sade bir veri modeli baslangici olusturmaktir.

Bu adim yalnizca saha notu varligini temsil eden basit veri modeli baslangicidir.

## Santiye Acisindan Anlami

Santiye sefi sahada gezerken kucuk ama kaybolmamasi gereken notlar alabilir. Ornegin bir bolgede temizlik ihtiyaci, bir ekipmana dikkat edilmesi, bir imalatin kontrol edilmesi veya bir konu hakkinda hatirlatma yazilabilir.

Bu notlar ileride gorev, gunluk rapor, denetim veya uygunsuzluk sureclerine temel olabilir. Ancak bu adimda bu surecler kurulmaz.

## SiteNoteRecord Modeli

`SiteNoteRecord`, santiyedeki kisa saha notu, gozlem, uyari veya hatirlatma kaydina ait temel bilgiyi temsil eder.

Bu model not basligini, not turunu, konumu, ilgili konuyu, not tarihini, durum bilgisini ve serbest notlari tutar.

## Model Alanlari

- `note_title`: Saha notunun kisa basligi.
- `note_type`: Not turu.
- `location`: Notun ilgili oldugu saha konumu.
- `related_subject`: Notun ilgili oldugu konu.
- `note_date`: Notun alindigi veya gozlemin yapildigi tarih.
- `status`: Kaydin durum bilgisi. Varsayilan deger `open`.
- `notes`: Serbest not alani.

## Bu Adimda Bilerek Yapilmayanlar

Bu adim gorev yonetimi degildir.

Bu adim hatirlatici veya bildirim sistemi degildir.

Bu adim gunluk rapor, denetim formu veya uygunsuzluk kaydi sistemi degildir.

Bu adim fotograf/dosya eki sistemi degildir.

Veritabani, JSON kayit sistemi, API, GUI/web arayuzu, CLI, takvim baglantisi, kisi atama sistemi, oncelik sistemi ve Excel/PDF cikti eklenmemistir.

## Ileride Baglanabilecegi Moduller

Bu model ileride gunluk rapor, gorev adayi, lokasyon, denetim, uygunsuzluk veya dosya eki kayitlariyla baglanabilir.

Bu baglantilar sonraki adimlarda ihtiyac netlestikce kurulacaktir.

## Kabul Kriterleri

- `SiteNoteRecord` basit `@dataclass` modeli olarak eklendi.
- Model not basligi, not turu, konum, ilgili konu ve not tarihi bilgisini tutar.
- `status` varsayilan degeri `open` olarak tanimlandi.
- `notes` varsayilan degeri `None` olarak tanimlandi.
- Model baska modellerle kod seviyesinde baglanmadi.
- Gorev yonetimi, hatirlatici, bildirim, gunluk rapor, denetim, uygunsuzluk, fotograf/dosya eki, takvim, kisi atama veya oncelik sistemi eklenmedi.
