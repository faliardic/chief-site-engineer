# Adim 017 - Basit Tedarikci Kayit Modeli Baslangici

## Revizyon Sebebi

Onceki Adim 017 onerisi malzeme kaydi uzerineydi. Ancak `MaterialRecord` mevcut oldugu icin Adim 017 tedarikci kapsamina revize edilmistir.

Bu revizyon, ayni isimle ikinci model eklememek ve proje kapsamini kucuk tutmak icin yapildi.

## Amac

Bu adimin amaci, santiyedeki tedarikci, hizmet saglayici, ekipman kiralama firmasi ve taseron gibi firmalari ileride takip edebilmek icin sade bir veri modeli baslangici olusturmaktir.

Bu adim yalnizca tedarikci/firma varligini temsil eden basit veri modeli baslangicidir.

## Santiye Acisindan Anlami

Santiye sefi, hangi firmanin hangi malzeme, ekipman veya hizmeti sagladigini ve kimle iletisim kurulacagini bilmek ister.

Bu bilgi ileride satin alma, sozlesme, odeme veya performans sureclerine temel olabilir. Ancak bu adimda bu surecler kurulmaz.

## SupplierRecord Modeli

`SupplierRecord`, santiyedeki bir tedarikci veya hizmet saglayici firma kaydina ait temel bilgiyi temsil eder.

Bu model firma adini, firma turunu, iletisim kisisi bilgisini, telefon, e-posta, hizmet alani, durum bilgisi ve notlari tutar.

## Model Alanlari

- `supplier_name`: Tedarikci veya hizmet saglayici firma adi.
- `supplier_type`: Firma turu.
- `contact_person`: Firma tarafinda iletisim kurulacak kisi.
- `phone`: Telefon bilgisi.
- `email`: E-posta bilgisi.
- `service_area`: Saglanan hizmet, malzeme, ekipman veya is kapsami.
- `status`: Kaydin durum bilgisi. Varsayilan deger `active`.
- `notes`: Serbest not alani.

## Bu Adimda Bilerek Yapilmayanlar

Bu adim satin alma sistemi degildir.

Bu adim sozlesme, odeme, fatura, irsaliye veya cari hesap sistemi degildir.

Veritabani, JSON kayit sistemi, API, GUI/web arayuzu, CLI, tedarikci performans puani, malzeme baglantisi, ekipman baglantisi, taseron sozlesme yonetimi ve Excel/PDF cikti eklenmemistir.

## Ileride Baglanabilecegi Moduller

Bu model ileride malzeme, ekipman, proje tarafi, iletisim kisisi, satin alma, sozlesme ve odeme kayitlariyla baglanabilir.

Bu baglantilar sonraki adimlarda ihtiyac netlestikce kurulacaktir.

## Kabul Kriterleri

- `SupplierRecord` basit `@dataclass` modeli olarak eklendi.
- Model tedarikci adini, turunu, iletisim kisisi, telefon, e-posta ve hizmet alani bilgisini tutar.
- `status` varsayilan degeri `active` olarak tanimlandi.
- `notes` varsayilan degeri `None` olarak tanimlandi.
- Model baska modellerle kod seviyesinde baglanmadi.
- Satin alma, sozlesme, fatura, irsaliye, odeme, cari hesap veya tedarikci performans sistemi eklenmedi.
