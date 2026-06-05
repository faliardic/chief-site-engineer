# 006 Yapi Denetim Kontrol Cagrilari

## Yapi Denetim Kontrol Cagrisi Nedir?

Yapi denetim kontrol cagrisi, santiye sefinin yapi denetim firmasindan belirli bir saha kontrolu icin talep olusturmasidir. Temel demir kontrolu, kalip kontrolu, beton dokum oncesi kontrol veya numune sureci bu kapsama girebilir.

## Santiye Sefi Neden Kontrol Cagrilarini Duzenli Takip Etmelidir?

Kontrol cagrilari imalatin devam edebilmesi icin kritik esiklerdir. Santiye sefi hangi kontrolun ne zaman talep edildigini, hangi tarihe planlandigini, tamamlanip tamamlanmadigini ve sonucunu duzenli izlemelidir.

## InspectionRequest Modeli Hangi Bilgileri Temsil Eder?

`InspectionRequest`, kontrol cagrisi kimligi, proje kimligi, talep tarihi, kontrol tipi, talep eden kisi, yapi denetim firmasi, iliskili beton dokumu, planlanan kontrol tarihi, tamamlanma tarihi, sonuc, not ve durum bilgisini temsil eder.

## related_pour_id Alani Neden Var?

`related_pour_id`, kontrol cagrisi bir beton dokumuyle iliskiliyse bu baglantiyi kurmak icin vardir. Her kontrol betonla ilgili olmayabilecegi icin bu alan opsiyoneldir.

## Bu Model Beton Dokum Sureciyle Nasil Iliskilendirilebilir?

Beton dokum oncesi kontrol talebi, `ConcretePour` kaydinin `pour_id` degeriyle `InspectionRequest.related_pour_id` alanina baglanabilir. Boylece belirli bir beton dokumu icin hangi denetim cagrilarinin yapildigi izlenebilir.

## Bu Asamada Neden EBIS, Bildirim, Takvim, Veritabani veya JSON Eklenmedi?

Bu adimda amac kontrol cagrisi bilgisinin seklini netlestirmektir. EBIS entegrasyonu, bildirim, takvim, veritabani ve JSON kayit sistemi daha sonra bu veri modeli uzerine kurulabilir.

## Bu Model Ileride Hangi Modullere Temel Olacak?

`InspectionRequest` ileride yapi denetim takip ekrani, kontrol cagrisi hatirlaticilari, beton dokum oncesi kontrol baglantilari, sonuc takibi ve raporlama modullerine temel olacaktir.
