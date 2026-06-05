# Adim 016 - Basit Ekipman / Makine Kayit Modeli Baslangici

## Amac

Bu adimin amaci, santiyede kullanilan temel ekipman, makine ve araclari ileride takip edebilmek icin sade bir veri modeli baslangici olusturmaktir.

Bu adim yalnizca ekipman/makine varligini temsil eden basit veri modeli baslangicidir.

## Santiye Acisindan Anlami

Santiye sefi, sahada hangi ekipmanin bulundugunu, hangi firmaya ait oldugunu, nerede kullanildigini ve kimin sorumlulugunda oldugunu bilmek ister.

Bu bilgi gunluk rapor, saha koordinasyonu, ekipman planlama ve ileride bakim/yakit gibi daha detayli takipler icin temel olabilir.

## EquipmentRecord Modeli

`EquipmentRecord`, santiyedeki bir ekipman, makine veya arac kaydina ait temel bilgiyi temsil eder.

Bu model ekipman adini, ekipman turunu, sahip firmayi, seri veya plaka bilgisini, calisma alanini, sorumlu kisi/ekip bilgisini, durum bilgisini ve notlari tutar.

## Model Alanlari

- `equipment_name`: Ekipman, makine veya arac adi.
- `equipment_type`: Ekipman turu.
- `owner_company`: Sahip firma, taseron veya kiralama sirketi.
- `serial_or_plate`: Seri numarasi veya plaka bilgisi.
- `work_area`: Ekipmanin kullanildigi veya bulundugu saha alani.
- `assigned_to`: Ekipmandan sorumlu kisi, ekip veya firma.
- `status`: Kaydin durum bilgisi. Varsayilan deger `available`.
- `notes`: Serbest not alani.

## Bu Adimda Bilerek Yapilmayanlar

Bu adim bakim/yakit/zimmet sistemi degildir.

Bakim takibi, yakit takibi, zimmet sistemi, gunluk calisma saati, operator performansi, makine verimlilik hesabi, veritabani, JSON kayit sistemi, API, GUI/web arayuzu, CLI ve Excel/PDF cikti eklenmemistir.

## Ileride Baglanabilecegi Moduller

Bu model ileride gunluk rapor, lokasyon/mahal, ekip/iscilik, bakim, yakit ve saha ilerleme kayitlariyla baglanabilir.

Bu baglantilar sonraki adimlarda ihtiyac netlestikce kurulacaktir.

## Kabul Kriterleri

- `EquipmentRecord` basit `@dataclass` modeli olarak eklendi.
- Model ekipman adini, ekipman turunu, sahip firmayi, seri/plaka bilgisini, calisma alanini ve sorumlu bilgisini tutar.
- `status` varsayilan degeri `available` olarak tanimlandi.
- `notes` varsayilan degeri `None` olarak tanimlandi.
- Model baska modellerle kod seviyesinde baglanmadi.
- Veritabani, JSON, API, GUI, CLI, bakim, yakit, zimmet veya raporlama sistemi eklenmedi.
