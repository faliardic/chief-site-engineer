# Adim 060 - Uygunsuzluk Arsiv Listeleme Butunluk Kontrolu

## Bu Adimda Ne Ogrenildi?

Bu adimda tek tek calisan repository davranislarinin birlikte calistiginda da tutarli kalmasi gerektigi ogrenildi.

Bir methodun kendi testi gecmesi onemlidir. Ancak `archive`, `restore`, `list_active`, `list_archived`, `list_all` ve `get_archive_summary` gibi birbirine bagli davranislar icin butunlesik test de gerekir.

## Butunluk Testi Nedir?

Butunluk testi, birden fazla davranisin ayni senaryo icinde birlikte dogru calistigini kontrol eder.

Bu adimda test sunu yapar:

- Kayitlari ekler.
- Baslangic listelerini ve ozeti kontrol eder.
- Bazi kayitlari arsivler.
- Aktif liste, arsiv liste, tum liste ve ozetin uyumlu kalip kalmadigini kontrol eder.
- Arsivlenmis bir kaydi restore eder.
- Restore sonrasi ayni uyumu tekrar kontrol eder.

## Neden Yeni Method Eklenmedi?

Bu adimin amaci yeni davranis eklemek degildi. Gerekli methodlar zaten vardi.

Bu nedenle `app/records.py` dosyasina dokunulmadan test ve dokumantasyon eklendi.

Bu yaklasim, gereksiz kod tekrarini ve buyuk refactor riskini azaltir.

## Listeleme Davranislari Arasindaki Iliski

`list_all()` tum kayitlari dondurur.

`list_active()` sadece `is_archived == False` olan kayitlari dondurur.

`list_archived()` sadece `is_archived == True` olan kayitlari dondurur.

`get_archive_summary()` ise aktif, arsivlenmis ve toplam kayit sayilarini verir.

Bu sonuclar birbiriyle uyumlu olmalidir. Ornegin toplam sayi, aktif ve arsivlenmis sayilarinin toplamina esit olmalidir.

## Status Neden Degismemeli?

Arsivleme ve restore, kaydin takip grubunu degistirir. Bu islemler kaydin kalite durumunu otomatik olarak degistirmez.

Bir kaydin `status` degeri `open`, `in_progress` veya `closed` olabilir. `archive()` ve `restore()` bu degeri korur.

Bu ayrim ileride otomatik history veya workflow eklenirse daha da onemli hale gelir.

## Neden JSON veya Veritabani Degil?

Bu adim hala bellek ici repository seviyesindedir. JSON, SQLite, API veya GUI eklenmedi.

Amac, kalici kayit sistemine gecmeden once Python davranislarinin dogru ve testli oldugundan emin olmaktir.

## Santiye Pratigindeki Anlami

Santiye kalite yonetiminde bir NCR kaydi arsive alinsa bile tamamen kaybolmamalidir. Gerekirse tekrar aktif takibe alinabilmelidir.

Aktif liste, arsiv liste, tum liste ve ozet sayilari ayni gercegi farkli acilardan gostermelidir. Bu adim, sistemin bu tutarliligi korudugunu kanitlar.

## Testin Kazandirdigi Guvence

Bu adimla su guvenceler saglandi:

- Kayitlar arsivlenirken silinmez.
- Restore edilen kayit aktif listeye geri doner.
- Arsiv listesi restore sonrasi guncellenir.
- Tum liste toplam kayit hafizasini korur.
- Arsiv ozeti listeleme sonuclariyla uyumlu kalir.
- Status degerleri otomatik degismez.
