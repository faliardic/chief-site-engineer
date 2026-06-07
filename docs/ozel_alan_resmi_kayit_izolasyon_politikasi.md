# Ozel Alan ve Resmi Kayit Izolasyon Politikasi

## Temel Karar

Santiye Sefi Ozel Alani kisisel calisma alanidir; resmi proje kaydi degildir.

Bu alan, santiye sefinin taslak notlari, hatirlaticilari, kisisel kontrol listeleri ve resmi kayda donusmemis hazirlik bilgileri icin kullanilir.

Resmi proje kayitlari ise proje hafizasinin parcasidir ve proje organizasyonu icinde kalir.

## Ana Kurallar

Ozel alan kayitlari resmi kayitlardan ayri tutulur.

Private workspace kayitlari `owner_user_id` ile baglanir.

Project role degisimi private workspace ownership degistirmez.

Yeni santiye sefi eski santiye sefinin ozel alanina erisemez.

Proje yoneticisi ozel alan icerigini resmi kayit gibi goremez.

Ozel alan verisi resmi raporlara otomatik girmez.

Ozel notlar audit event, NCR, tutanak veya revizyon yerine gecmez.

Ozel alandan resmi kayda gecis ancak bilincli "resmi kayda aktar" islemiyle olur.

Aktarim olursa resmi alanda yeni ve bagimsiz bir resmi kayit olusur.

Ozel alan kopyasi kisisel veri olarak kalir ve kullanici tarafindan disa aktarilabilir veya silinebilir.

## Resmi Kayda Aktarim

Ozel alandaki bir notun resmi kayda aktarilmasi otomatik olmamalidir.

Aktarim icin kullanici acik bir islem yapmalidir. Bu islem sonunda resmi tarafta yeni kayit olusur.

Orijinal ozel not, kullanicinin private workspace alaninda kalir. Resmi kayit bu notun birebir aynisi olmak zorunda degildir; resmi kayit kendi kimligi, tarihi, sorumlusu ve audit iziyle bagimsiz bir kayittir.

## Santiye Sefi Istifa / Devir Senaryosu

Eski santiye sefinin ozel alani yeni santiye sefine devredilmez.

Eski santiye sefi ozel alanini disa aktarabilmelidir.

Eski santiye sefi ozel alanini silebilmelidir.

Kullanici ayrildiginda private workspace kilitlenebilir.

Belirlenen bekleme suresi sonunda ozel alan verileri silinebilir veya encryption key yok edilerek okunamaz hale getirilebilir.

Yeni santiye sefi projeye atandiginda ona yeni ve bos private workspace acilir.

Devir icin gerekli bilgiler private workspace'te birakilmamalidir. Bu bilgiler explicit handover package veya official record olarak hazirlanmalidir.

## Sifreleme Notu

Private workspace verileri ileride kullanici bazli encryption key ile korunmalidir.

Admin veya yeni santiye sefi eski kullanicinin private icerigini okuyamamali.

Key silme / crypto-shredding ozel alan silme politikasinin guclu secenegi olarak dokumante edilir.

## Izolasyonun Nedeni

Bu ayrim hem proje hafizasini hem de kullanicinin kisisel calisma alanini korur.

Resmi kayitlar denetlenebilir, devredilebilir ve proje icinde kalicidir.

Ozel alan ise kullaniciya ait taslak ve kisisel calisma bilgisidir. Bu iki alanin karismasi hem gizlilik hem de resmi kayit guvenilirligi acisindan risklidir.

## Bu Dokumanin Siniri

Bu dokuman auth, permission, encryption veya data migration implementasyonu eklemez.

Bu dokuman ozel alan ile resmi kayitlar arasindaki izolasyon politikasini tanimlar.
