# 007 Uygunsuzluk Kayitlari

## Uygunsuzluk Kaydi Nedir?

Uygunsuzluk kaydi, sahada proje, teknik sartname, kalite beklentisi veya is guvenligi acisindan duzeltilmesi gereken bir durumun kaydedilmesidir.

## Santiye Sefi Neden Uygunsuzluklari Duzenli Takip Etmelidir?

Uygunsuzluklar takip edilmezse ayni sorun tekrar edebilir, imalat kalitesi dusebilir veya denetim surecinde gecikme olusabilir. Santiye sefi uygunsuzlugun ne oldugunu, kimin sorumlu oldugunu, hangi duzeltici faaliyetin planlandigini ve kaydin kapanip kapanmadigini izlemelidir.

## NonconformityRecord Modeli Hangi Bilgileri Temsil Eder?

`NonconformityRecord`, uygunsuzluk kimligi, proje kimligi, tarih, baslik, aciklama, konum, kategori, onem seviyesi, sorumlu taraf, duzeltici faaliyet, termin tarihi, kapatma tarihi, iliskili kontrol cagrisi, iliskili beton dokumu, notlar ve durum bilgisini temsil eder.

## severity Alani Neden Var?

`severity`, uygunsuzlugun onem seviyesini belirtir. Bu asamada varsayilan deger `"medium"` olarak tutulur ve enum sistemi eklenmez.

## status Alani Neden Var?

`status`, uygunsuzlugun acik, kapali veya ileride baska bir durumda olup olmadigini izlemek icin vardir. Yeni kayit varsayilan olarak `"open"` baslar.

## corrective_action Alani Neden Var?

`corrective_action`, uygunsuzlugu gidermek icin planlanan duzeltici faaliyeti tutar. Bu alan ilk kayit aninda bilinmeyebilecegi icin opsiyoneldir.

## related_inspection_request_id Alani Neden Var?

Bu alan, uygunsuzluk bir yapi denetim kontrol cagrisi sonucunda ortaya ciktiysa o cagriyla baglanti kurmak icin vardir.

## related_pour_id Alani Neden Var?

Bu alan, uygunsuzluk beton dokum sureciyle ilgiliyse ilgili beton dokumu kaydiyla baglanti kurmak icin vardir.

## Bu Model Yapi Denetim ve Beton Dokum Surecleriyle Nasil Iliskilendirilebilir?

Bir uygunsuzluk, `InspectionRequest` kaydinin sonucu olarak veya `ConcretePour` kaydina bagli bir beton imalati sirasinda olusabilir. Bu nedenle iki iliski alani da opsiyonel tutuldu.

## Bu Asamada Neden Fotograf, Dosya, Tutanak, PDF, Veritabani veya JSON Eklenmedi?

Bu adimda amac uygunsuzluk verisinin seklini netlestirmektir. Fotograf, dosya yukleme, tutanak, PDF/Excel, veritabani ve JSON kayit sistemi daha sonra bu model uzerine kurulabilir.

## Bu Model Ileride Hangi Modullere Temel Olacak?

`NonconformityRecord` ileride uygunsuzluk takip ekrani, duzeltici faaliyet takibi, denetim sonucu izleme, beton dokum baglantili sorun takibi, raporlama ve arsivleme modullerine temel olacaktir.
