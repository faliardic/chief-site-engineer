# Adim 106 - CSE Urun Vizyonu ve Saha Hafizasi

## Amac

Bu dokuman CSE'nin kisa ve orta vadeli urun yonunu netlestirir. Hedef, CSE'yi buyuk ve agir bir insaat yonetim platformu olarak degil, santiye sefinin gunluk saha hafizasini guvenilir sekilde tutan sade bir arac olarak konumlandirmaktir.

## Ilk Gercek Rakip

CSE'nin ilk gercek rakibi dev insaat yonetim yazilimlari degildir.

Ilk gercek rakipler sunlardir:

- WhatsApp gruplari
- telefon galerisi
- Excel listeleri
- klasor karmasasi
- defter notlari
- mail ekleri
- "ben bunu bir yere yazmistim" duzeni

Bu nedenle CSE ilk olarak sahadaki daginik kayit aliskanliklarini sade, hizli ve geri cagrilabilir bir duzene tasimalidir.

## CSE'nin Urun Konumu

CSE'nin ana konumu santiye sefinin akilli ajandasi ve saha hafizasidir.

CSE su rolleri tasir:

- hizli saha kayit araci
- fotograf ve dosya kanit arsivi
- takip durumu kayit zemini
- raporlama ve geri cagirma hafizasi
- AI destekli saha yardimcisi icin guvenilir veri zemini

Amac daha fazla modul eklemek degil; santiye sefinin unutmama, kanitlama, takip etme, raporlama ve sonra geri cagirma ihtiyacini sade sekilde cozmektir.

## Guvenilir Veri Omurgasi

CSE once guvenilir veri omurgasini kurar. Bu omurga olmadan raporlama, analiz, devir paketi veya AI destekli yardim saglam olmaz.

Temel veri omurgasi sunlardan olusur:

- tarih
- konum
- kategori
- fotograf/dosya
- sorumlu kisi
- durum
- kapanis kaniti
- audit/gecmis
- iliski ve baglanti

Bu alanlar sahada acilan kaydin daha sonra bulunabilir, kanitlanabilir ve raporlanabilir olmasini saglar.

## Saha Hafizasi

CSE saha hafizasi olarak calismalidir. Bir kayit sadece bugunku not degil, daha sonra bulunacak kanit, takip edilecek is, rapora girecek bilgi veya devirde kullanilacak saha gecmisidir.

Saha hafizasi su sorulara cevap verebilmelidir:

- Ne oldu?
- Nerede oldu?
- Ne zaman oldu?
- Kim sorumlu?
- Hangi fotograf veya dosya kanit?
- Durum ne?
- Nasil kapandi?
- Daha once benzer bir durum var mi?

## AI Katmani

AI ilk katman degildir. AI, guvenilir saha hafizasinin uzerine daha sonra gelecek deger artirici katmandir.

Dogru sira sudur:

1. dogru kayit
2. guvenilir arsiv
3. iliskili veri
4. aranabilir santiye hafizasi
5. AI soru-cevap, rapor, analiz ve hatirlatma

AI ile ileride soru-cevap, gunluk rapor uretimi, haftalik analiz, risk uyarisi, takip hatirlatma, tekrar eden hata analizi, handover/devir paketi, kanit dosyasi hazirlama ve karar destek saglanabilir.

## Saha MVP Ilkesi

CSE yayinlanmak icin acele etmeyecek. Urun kararlari gercek santiye kullanimi ile yonlendirilecektir.

Gelistirme dongusu su sekilde olmalidir:

1. gercek santiye
2. gercek problem
3. kucuk kayit araci
4. sahada test
5. duzeltme
6. yeni ozellik
7. tekrar test

Sahada kayit acmak 20-30 saniyeyi gecmemelidir. Bu sinir, urunun pratikte kullanilip kullanilmayacagini belirleyen ana esiktir.

## Urun Filtresi

Her yeni ozellik icin temel filtre sudur:

```text
Bu ozellik santiye sefinin sahada unutmamasini, kanitlamasini, takip etmesini, raporlamasini veya daha sonra geri cagirmasini kolaylastiriyor mu?
```

Bu soruya guclu bir "evet" verilemiyorsa ozellik ertelenmeli, daraltilmali veya kapsamin disinda tutulmalidir.

## Bu Adimin Siniri

Bu adim sadece dokumantasyon adimidir.

Bu adimda uygulama kodu, test dosyalari, database, API, GUI, CLI, scanner, upload service, AI entegrasyonu, automation, backup/restore veya audit implementasyonu eklenmedi.

Commit atilmadi, push yapilmadi ve `chief-site-engineer_adim_080_guvenli_nokta.zip` dosyasi stage edilmedi.
