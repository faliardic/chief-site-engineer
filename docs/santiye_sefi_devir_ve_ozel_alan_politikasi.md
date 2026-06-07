# Santiye Sefi Devir ve Ozel Alan Politikasi

## Amac

Bu dokuman, santiye sefinin gorevden ayrilmasi, istifa etmesi, projeden alinmasi veya yeni santiye sefinin atanmasi durumunda ozel alan ile resmi proje kayitlari arasindaki siniri tanimlar.

Temel ilke sudur: Resmi proje kayitlari projede kalir; eski santiye sefinin ozel alani yeni santiye sefine devredilmez.

## Senaryo: Santiye Sefi Gorevden Ayrilir

Santiye sefi gorevden ayrildiginda resmi proje kayitlari korunur.

NCR, tutanak, kalite kontrol, attachment metadata, audit event ve proje kararlari proje hafizasinda kalir.

Eski santiye sefinin ozel alani ise otomatik olarak yeni kullaniciya acilmaz.

## Senaryo: Santiye Sefi Istifa Eder

Istifa durumunda eski kullanici kendi private workspace verisini disa aktarabilmelidir.

Bu dis aktarim kisisel calisma notlari icindir; resmi proje devri yerine gecmez.

Resmi proje devri icin gerekli bilgiler ayrica official record veya explicit handover package olarak hazirlanmalidir.

## Senaryo: Santiye Sefi Projeden Alinir

Santiye sefi projeden alindiginda proje role erisimi kapatilabilir.

Bu islem private workspace ownership bilgisini otomatik degistirmez.

Ozel alan kilitlenebilir; ancak yeni santiye sefi eski ozel alani okuyamaz.

## Senaryo: Yeni Santiye Sefi Atanir

Yeni santiye sefi projeye atandiginda ona yeni ve bos private workspace acilir.

Yeni kullanici resmi proje kayitlarina yetkisi kapsaminda erisebilir; fakat eski kullanicinin ozel alanina erisemez.

## Senaryo: Eski Santiye Sefi Ozel Alanini Disa Aktarir

Eski santiye sefi ozel alanini kendi kisisel arsivi icin disa aktarabilir.

Bu export resmi proje kaydi olarak kabul edilmez.

Export edilen veri, kullanicinin kisisel sorumlulugunda degerlendirilir.

## Senaryo: Eski Santiye Sefi Ozel Alanini Siler

Eski santiye sefi ozel alanini silebilir.

Bu silme resmi proje kayitlarini etkilemez.

Ozel alan silme politikasinda ileride encryption key silme / crypto-shredding yaklasimi kullanilabilir.

## Senaryo: Eski Santiye Sefi Islem Yapmadan Ayrilir

Kullanici islem yapmadan ayrilirse private workspace kilitlenebilir.

Belirlenen bekleme suresi sonunda ozel alan verileri silinebilir veya encryption key yok edilerek okunamaz hale getirilebilir.

Bu durum resmi proje kayitlarini etkilemez.

## Senaryo: Devir Icin Gerekli Bilgi Resmi Kayda Aktarilir

Devir icin gerekli bilgiler private workspace icinde birakilmamalidir.

Gerekli bilgi resmi devir paketi, tutanak, gorev kaydi, NCR notu, proje karari veya benzeri official record olarak olusturulmalidir.

Bu aktarim bilincli ve acik bir islemle yapilir.

## Kararlar

Yeni santiye sefi eski ozel alana erisemez.

Eski ozel alan program devriyle birlikte devredilmez.

Resmi proje kayitlari projede kalir.

Ozel alan ile resmi kayit arasinda otomatik veri karismasi olmaz.

Handover sadece acikca olusturulmus resmi devir paketi uzerinden yapilir.

## Bu Dokumanin Siniri

Bu dokuman auth, permission, encryption, export veya data deletion implementasyonu eklemez.

Bu dokuman devir senaryolari icin politika ve karar cercevesi tanimlar.
