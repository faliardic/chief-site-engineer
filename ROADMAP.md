# Roadmap

- [x] Adim 001 - Repo ve proje disiplini
- [x] Adim 002 - Cekirdek veri modeli
- [x] Adim 003 - Gunluk saha kaydi modeli
- [x] Adim 004 - Bellek ici basit kayit listeleme
- [x] Adim 005 - Beton dokum ve numune takip baslangici
- [x] Adim 006 - Yapi denetim kontrol cagrilari
- [x] Adim 007 - Uygunsuzluk kayitlari
- [x] Adim 008 - Dosya/ek arsivleme
- [x] Adim 009 - Malzeme giris/kullanim kaydi baslangici
- [x] Adim 010 - Toplanti tutanagi ve aksiyon kaydi baslangici
- [x] Adim 011 - RFI/submittal lite kayit modeli baslangici
- [x] Adim 012 - Gunluk rapor ozet modeli baslangici
- [x] Adim 013 - Basit proje tarafi / kisi kayit modeli baslangici
- [x] Adim 014 - Basit santiye lokasyon / mahal kayit modeli baslangici
- [x] Adim 015 - Basit ekip/iscilik kayit modeli baslangici
- [x] Adim 016 - Basit ekipman/makine kayit modeli baslangici
- [x] Adim 017 - Basit tedarikci kayit modeli baslangici
- [x] Adim 018 - Basit saha notu kayit modeli baslangici
- [x] Adim 019 - Basit gorev adayi kayit modeli baslangici
- [x] Adim 020 - Basit kontrol maddesi kayit modeli baslangici
- [x] Adim 021 - Basit kontrol sonucu kayit modeli baslangici
- [x] Adim 022 - Basit uygunsuzluk adayi kayit modeli baslangici
- [x] Adim 023 - Basit uygunsuzluk adayi degerlendirme kayit modeli baslangici
- [x] Adim 024 - Basit uygunsuzluk adayi aksiyon kayit modeli baslangici
- [x] Adim 025 - Uygunsuzluk adayi takip durumu ozeti baslangici
- [x] Adim 026 - AttachmentRecord ile uygunsuzluk adayi ek dosya baglantisi
- [x] Adim 027 - Uygunsuzluk adayi surec zinciri gorunum modeli baslangici
- [x] Adim 028 - Uygunsuzluk adayi durum gecmisi modeli baslangici
- [x] Adim 029 - Uygunsuzluk adayi sorumluluk / atama modeli baslangici
- [x] Adim 030 - Uygunsuzluk adayi kapanis / sonuc modeli baslangici
- [x] Adim 031 - NotebookLM podcast notu Adim 026-030
- [x] Adim 032 - Uygunsuzluk adayindan kesin uygunsuzluga donusum modeli baslangici
- [x] Adim 033 - NonconformityRecord model degerlendirme raporu

Adim 021-025 araligi tamamlandi. Bu aralik icin final NotebookLM podcast notu hazirlanacak.

Adim 026'da yeni ek dosya modeli eklenmeden, mevcut `AttachmentRecord` modelinin uygunsuzluk adayi kayitlarina kanit dosyasi baglamak icin kullanilacagi netlestirildi.

Adim 027'de uygunsuzluk adayi surecinin kontrol sonucu, aday kaydi, degerlendirme, aksiyon, takip ozeti ve ek dosya durumunu tek ozet kayitta temsil eden baslangic gorunum modeli eklendi.

Adim 028'de uygunsuzluk adayi durum degisikliklerinin eski durum, yeni durum, sebep, kisi, tarih ve kaynak kayit bilgisiyle temsil edilmesi icin baslangic durum gecmisi modeli eklendi.

Adim 029'da uygunsuzluk adayinin kime atandigini, kim tarafindan atandigini, hedef tarihini, onceligini ve sorumluluk notunu temsil eden baslangic atama modeli eklendi.

Adim 030'da uygunsuzluk adayinin nasil sonuclandigini, kim tarafindan kapatildigini, takip gerektirip gerektirmedigini ve nihai durumunu temsil eden baslangic kapanis modeli eklendi.

Adim 031'de Adim 026-030 araliginin final NotebookLM podcast notu hazirlandi.

Adim 032'de mevcut `NonconformityRecord` modeli yeniden olusturulmadan, aday kaydin kesin uygunsuzluk / NCR kaydina donusum baglantisini temsil eden baslangic model eklendi.

Adim 033'te mevcut `NonconformityRecord` modelinin Adim 021-032 zincirinden sonra yeterliligi degerlendirildi; model degistirilmeden revizyon karar hazirligi raporu hazirlandi.

Sonraki kucuk adim onerisi: Adim 034 - Uygunsuzluk adayi surec durum etiketi modeli baslangici
