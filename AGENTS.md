# Gelistirme Kurallari

Bu repo, Chief Site Engineer projesinin kademeli gelistirilmesi icindir.

## Temel Ilkeler

- Gereksiz karmasik yapi kurulmaz.
- Her adim kucuk, anlasilir ve test edilebilir olmalidir.
- Framework, veritabani veya servis bagimliligi ancak ihtiyac netlestiginde eklenir.
- Kod okunabilir, sade ve Python standartlarina uygun yazilir.
- Yeni davranislar icin uygun seviyede test eklenir.

## Calisma Akisi

- Degisiklikten once mevcut dosya yapisi kontrol edilir.
- Kullanici tarafindan yapilmis degisiklikler korunur.
- `python -m pytest` basarili olmadan is tamamlanmis sayilmaz.
- Dokumantasyon, kararlar ve ogrenme notlari ilgili dosyalarda guncel tutulur.
- Yeni teknik terim kullandiginda, kullanici Python ogrenen biri oldugu icin terimi learning dosyasinda tanimla ve kalici terimse `learning/GLOSSARY.md` dosyasina ekle.
- Yeni bir gelistirme yaptiginda learning dosyasini sadece kisa ozet seklinde yazma. Kullanici Python ogreniyor. Gercek kod bloklari, satir satir aciklama, test kodu aciklamasi, teknik karar tablosu ve kod calisma akisi kullan. Hangi dosyada ne yaptigini, neden yaptigini, kodun nasil calistigini, testlerin neyi dogruladigini ve yeni terimlerin anlamini detayli sekilde acikla. Her learning dosyasinda "Sunu soyle yaptik ki..." bolumu bulunmali.

## Proje Dili

- Kullaniciya donuk dokumanlar Turkce tutulur.
- Kod, modul ve fonksiyon adlari sade Ingilizce yazilir.
- Teknik kararlar `docs/project_decisions.md` icinde kisa maddelerle kaydedilir.
