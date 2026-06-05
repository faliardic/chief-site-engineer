# Adim 019 - Basit Gorev Adayi Kayit Modeli Baslangici

## Amac

Bu adimin amaci, santiyede ileride goreve donusebilecek kucuk aksiyon adaylarini kayit altina alabilmek icin sade bir veri modeli baslangici olusturmaktir.

Bu adim yalnizca goreve donusebilecek aday kaydi temsil eden basit veri modeli baslangicidir.

## Santiye Acisindan Anlami

Santiye sefi sahada bir konunun takip edilmesi gerektigini fark edebilir. Bu konu henuz tam bir gorev, is emri veya is takip kaydi olmayabilir.

`TaskCandidateRecord`, bu tur kucuk aksiyon adaylarini kaybetmeden kayda almak icin kullanilir. Ancak bu adimda gercek gorev yonetimi veya is akisi kurulmaz.

## TaskCandidateRecord Modeli

`TaskCandidateRecord`, ileride goreve donusebilecek bir aksiyon adayina ait temel bilgiyi temsil eder.

Bu model gorev adayinin basligini, turunu, ilgili alanini, kaynagini, hedef tarihini, durum bilgisini ve notlarini tutar.

## Model Alanlari

- `task_title`: Gorev adayinin kisa basligi.
- `task_type`: Gorev adayi turu.
- `related_area`: Ilgili saha alani, mahal, blok, kat veya konu.
- `source`: Gorev adayinin ortaya ciktigi kaynak.
- `target_date`: Hedef tarih veya takip edilmesi dusunulen tarih.
- `status`: Kaydin durum bilgisi. Varsayilan deger `open`.
- `notes`: Serbest not alani.

## Bu Adimda Bilerek Yapilmayanlar

Bu adim gorev yonetimi sistemi degildir.

Bu adim hatirlatici veya bildirim sistemi degildir.

Bu adim takvim, kisi atama, oncelik veya is emri sistemi degildir.

Bu adim saha notu veya gunluk rapor baglantisi kurmaz.

Veritabani, JSON kayit sistemi, API, GUI/web arayuzu, CLI, tamamlandi/ertelendi is akisi ve Excel/PDF cikti eklenmemistir.

## Ileride Baglanabilecegi Moduller

Bu model ileride saha notu, gunluk rapor, toplanti aksiyonu, kisi atama, takvim veya is emri kayitlariyla baglanabilir.

Bu baglantilar sonraki adimlarda ihtiyac netlestikce kurulacaktir.

## Kabul Kriterleri

- `TaskCandidateRecord` basit `@dataclass` modeli olarak eklendi.
- Model gorev basligi, gorev turu, ilgili alan, kaynak ve hedef tarih bilgisini tutar.
- `status` varsayilan degeri `open` olarak tanimlandi.
- `notes` varsayilan degeri `None` olarak tanimlandi.
- Model baska modellerle kod seviyesinde baglanmadi.
- Gorev yonetimi, hatirlatici, bildirim, takvim, kisi atama, oncelik, is emri veya is akisi sistemi eklenmedi.
