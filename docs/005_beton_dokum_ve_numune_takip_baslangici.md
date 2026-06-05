# 005 Beton Dokum ve Numune Takip Baslangici

## Beton Dokum Takibi Nedir?

Beton dokum takibi, santiyede planlanan veya yapilan beton imalatlarinin tarih, konum, beton sinifi, miktar, tedarikci ve durum bilgileriyle izlenmesidir.

## Beton Numune Takibi Nedir?

Beton numune takibi, beton dokumunden alinan numunelerin sayisini, laboratuvar bilgisini, 7 gunluk ve 28 gunluk test tarihlerini ve sonuc bilgilerini takip etmektir.

## Santiye Sefi Neden Bu Bilgileri Duzenli Tutmalidir?

Beton imalatlari tasiyici sistem guvenligi acisindan kritiktir. Santiye sefi hangi bolgeye hangi betonun dokuldugunu, hangi numunelerin alindigini ve test sonuclarinin ne durumda oldugunu duzenli takip etmelidir.

## ConcretePour Modeli Hangi Bilgileri Temsil Eder?

`ConcretePour`, bir beton dokumunu temsil eder. Temel, perde, kolon, kiris veya doseme gibi imalatlar bu modelle izlenebilir. Model; dokum kimligi, proje kimligi, tarih, konum, beton sinifi, hacim, tedarikci, mikser sayisi, hava durumu, not ve durum alanlarini icerir.

## ConcreteSample Modeli Hangi Bilgileri Temsil Eder?

`ConcreteSample`, bir beton dokumunden alinan numune grubunu temsil eder. Model; numune kimligi, dokum kimligi, proje kimligi, numune tarihi, numune sayisi, 7 ve 28 gunluk test tarihleri, test sonuclari, laboratuvar ve durum alanlarini icerir.

## 7 Gunluk ve 28 Gunluk Numune Sonuclari Neden Onemlidir?

7 gunluk test sonucu betonun erken dayanimi hakkinda fikir verir. 28 gunluk test sonucu ise betonun nihai basinc dayanimi kontrolu icin temel kabul edilir. Bu nedenle iki test tarihi ve sonucu da takip edilmelidir.

## Bu Asamada Neden EBIS, Veritabani, JSON veya Rapor Sistemi Eklenmedi?

Bu adimda amac entegrasyon veya kalici kayit sistemi kurmak degildir. Once beton dokum ve numune takibi icin hangi bilgilerin tutulacagi sade veri modelleriyle netlestirilir.

## Bu Modeller Ileride Hangi Modullere Temel Olacak?

`ConcretePour` ve `ConcreteSample` ileride beton takip ekrani, numune hatirlaticilari, laboratuvar sonuc takibi, EBIS entegrasyonu, raporlama ve arsivleme modullerine temel olacaktir.
