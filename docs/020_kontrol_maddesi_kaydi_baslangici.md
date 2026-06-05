# Adim 020 - Basit Kontrol Maddesi Kayit Modeli Baslangici

## Amac

Bu adimin amaci, santiyede ileride kontrol listelerine, kalite kontrol formlarina veya denetim maddelerine donusebilecek tekil kontrol maddelerini kayit altina alabilmek icin sade bir veri modeli baslangici olusturmaktir.

Bu adim yalnizca tekil kontrol maddesi varligini temsil eden basit veri modeli baslangicidir.

## Santiye Acisindan Anlami

Santiye sefi sahada kontrol edilmesi gereken tekil maddeleri not etmek isteyebilir. Bu maddeler ileride checklist, denetim formu veya kalite kontrol surecine temel olabilir.

`ChecklistItemRecord`, bu tekil kontrol maddelerini sade sekilde kayda almak icin kullanilir. Ancak bu adimda checklist sistemi veya denetim formu kurulmaz.

## ChecklistItemRecord Modeli

`ChecklistItemRecord`, tekil kontrol maddesine ait temel bilgiyi temsil eder.

Bu model kontrol maddesi basligini, kategorisini, ilgili alanini, kontrol referansini, durum bilgisini ve notlarini tutar.

## Model Alanlari

- `item_title`: Kontrol maddesinin kisa basligi.
- `item_category`: Kontrol maddesi kategorisi.
- `related_area`: Ilgili saha alani, mahal, blok, kat veya konu.
- `check_reference`: Kontrol maddesinin dayandigi referans.
- `status`: Kaydin durum bilgisi. Varsayilan deger `pending`.
- `notes`: Serbest not alani.

## ChecklistItem ile ChecklistItemRecord Ayrimi

Projede eski `ChecklistItem` modeli vardir. Bu model cekirdek veri modeli asamasinda basit checklist ogesi olarak eklenmistir.

`ChecklistItemRecord`, Adim 020 kapsaminda tekil kontrol maddesi kaydini temsil eden daha spesifik bir kayit baslangicidir. Bu adimda eski `ChecklistItem` modeline dokunulmaz ve iki model arasinda kod seviyesinde iliski kurulmaz.

## Bu Adimda Bilerek Yapilmayanlar

Bu adim checklist sistemi degildir.

Bu adim denetim formu degildir.

Bu adim uygunsuzluk kaydi, puanlama, onay is akisi veya raporlama sistemi degildir.

Bu adim saha notu, gorev veya gunluk rapor baglantisi kurmaz.

Veritabani, JSON kayit sistemi, API, GUI/web arayuzu, CLI, fotograf/dosya eki ve Excel/PDF cikti eklenmemistir.

## Ileride Baglanabilecegi Moduller

Bu model ileride checklist, denetim formu, kalite kontrol, saha notu, gorev adayi, uygunsuzluk veya raporlama kayitlariyla baglanabilir.

Bu baglantilar sonraki adimlarda ihtiyac netlestikce kurulacaktir.

## Kabul Kriterleri

- `ChecklistItemRecord` basit `@dataclass` modeli olarak eklendi.
- Model kontrol maddesi basligi, kategori, ilgili alan ve kontrol referansi bilgisini tutar.
- `status` varsayilan degeri `pending` olarak tanimlandi.
- `notes` varsayilan degeri `None` olarak tanimlandi.
- Eski `ChecklistItem` modeline dokunulmadi.
- Model baska modellerle kod seviyesinde baglanmadi.
- Checklist sistemi, denetim formu, uygunsuzluk kaydi, puanlama, onay is akisi, fotograf/dosya eki veya raporlama sistemi eklenmedi.
