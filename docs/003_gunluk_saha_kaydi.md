# 003 Gunluk Saha Kaydi

## Gunluk Saha Kaydi Nedir?

Gunluk saha kaydi, santiye sefine bir gune ait saha durumunu, yapilan isleri, kontrolleri ve notlari duzenli sekilde tutma imkani veren kayittir.

## Santiye Sefi Gunluk Kayitta Hangi Bilgileri Tutar?

Santiye sefi gunluk kayitta tarih, hava durumu, calisan ekip ozeti, yapilan isler, kontroller, sorunlar, genel notlar ve kaydi olusturan kisi bilgisini tutabilir.

## DailySiteLog Modeli Hangi Alanlardan Olusur?

- `log_id`: Gunluk kaydin benzersiz kimligi.
- `project_id`: Kaydin bagli oldugu santiye kimligi.
- `date`: Kaydin ait oldugu tarih.
- `weather`: Hava durumu bilgisi.
- `workforce_summary`: Sahadaki ekip veya is gucu ozeti.
- `work_performed`: O gun yapilan islerin ozeti.
- `inspections`: Yapilan kontrol veya denetim notlari.
- `issues`: Gorulen sorunlar veya aksakliklar.
- `notes`: Ek notlar.
- `created_by`: Kaydi olusturan kisi.
- `status`: Kaydin durumu; ilk deger `draft` olarak baslar.

## Bu Model Ileride Hangi Modullere Temel Olacak?

`DailySiteLog`, gunluk rapor, saha arsivi, kontrol gecmisi, uygunsuzluk takibi ve disa aktarma modullerine temel olacaktir.

## Neden Bu Asamada Veritabani veya Dosya Kayit Sistemi Eklenmedi?

Bu adimda amac veriyi nereye kaydedecegimizi degil, hangi bilgileri tutacagimizi netlestirmektir. Model sade kalinca sonraki adimlarda veritabani, dosya kaydi veya raporlama ihtiyaci daha saglikli tasarlanabilir.
