# Adim 021 - Basit Kontrol Sonucu Kayit Modeli Baslangici

## Amac

Bu adimin amaci, santiyede yapilan kontrollerin basit sonuc bilgisini ileride takip edebilmek icin sade bir veri modeli baslangici olusturmaktir.

Bu adim yalnizca yapilan kontrolun basit sonuc bilgisini temsil eden veri modeli baslangicidir.

## Santiye Acisindan Anlami

Santiye sefi sahada bir kontrol yaptiginda bu kontrolun kisa sonucunu kaybetmeden kayda almak isteyebilir. Sonuc uygun, eksik var, tekrar bakilacak veya bilgi amacli gibi sade ifadelerle tutulabilir.

`CheckResultRecord`, bu kontrol sonucunu sade sekilde kayda almak icin kullanilir. Ancak bu adimda checklist sistemi, denetim formu veya raporlama sistemi kurulmaz.

## CheckResultRecord Modeli

`CheckResultRecord`, yapilan bir kontrolun basit sonuc bilgisini temsil eder.

Bu model kontrol basligini, kontrol alanini, sonucu, kontrol eden kisiyi, kontrol tarihini, durum bilgisini ve notlari tutar.

## Model Alanlari

- `check_title`: Kontrolun kisa basligi.
- `check_area`: Kontrolun ilgili oldugu saha alani veya konu.
- `result`: Kontrolun basit sonucu.
- `checked_by`: Kontrolu yapan veya kaydi olusturan kisi.
- `check_date`: Kontrol tarihi.
- `status`: Kaydin durum bilgisi. Varsayilan deger `recorded`.
- `notes`: Serbest not alani.

## Bu Adimda Bilerek Yapilmayanlar

Bu adim checklist sistemi degildir.

Bu adim denetim formu degildir.

Bu adim uygunsuzluk kaydi, puanlama, onay is akisi veya raporlama sistemi degildir.

Bu adim fotograf/dosya eki sistemi degildir.

Bu adim kontrol maddesi, saha notu, gorev veya gunluk rapor baglantisi kurmaz.

Veritabani, JSON kayit sistemi, API, GUI/web arayuzu, CLI ve Excel/PDF cikti eklenmemistir.

## Ileride Baglanabilecegi Moduller

Bu model ileride kontrol maddesi, checklist, denetim formu, uygunsuzluk adayi, saha notu, gorev adayi veya gunluk rapor kayitlariyla baglanabilir.

Bu baglantilar sonraki adimlarda ihtiyac netlestikce kurulacaktir.

## Kabul Kriterleri

- `CheckResultRecord` basit `@dataclass` modeli olarak eklendi.
- Model kontrol basligi, kontrol alani, sonuc, kontrol eden kisi ve kontrol tarihi bilgisini tutar.
- `status` varsayilan degeri `recorded` olarak tanimlandi.
- `notes` varsayilan degeri `None` olarak tanimlandi.
- Model baska modellerle kod seviyesinde baglanmadi.
- Checklist sistemi, denetim formu, uygunsuzluk kaydi, puanlama, onay is akisi, fotograf/dosya eki veya raporlama sistemi eklenmedi.
