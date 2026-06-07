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
- [x] Adim 034 - NonconformityRecord alan revizyonu
- [x] Adim 035 - Kesin uygunsuzluk surec gorunum modeli baslangici
- [x] Adim 036 - Kesin uygunsuzluk durum gecmisi modeli baslangici
- [x] Adim 037 - Kesin uygunsuzluk sorumluluk / atama modeli baslangici
- [x] Adim 038 - Kesin uygunsuzluk duzeltici faaliyet modeli baslangici
- [x] Adim 039 - Kesin uygunsuzluk duzeltici faaliyet dogrulama modeli baslangici
- [x] Adim 040 - Kesin uygunsuzluk kapatma / sonuc modeli baslangici
- [x] Adim 041 - Kesin uygunsuzluk kayit deposu baslangici
- [x] Adim 042 - NonconformityRepository duplicate id kontrolu
- [x] Adim 043 - NonconformityRepository durum filtreleme
- [x] Adim 044 - NonconformityRepository sorumlu filtreleme
- [x] Adim 045 - NonconformityRepository durum ozeti
- [x] Adim 046 - NonconformityRepository sorumlu taraf ozeti
- [x] Adim 047 - NonconformityRepository genel ozet
- [x] Adim 048 - NonconformityRepository status guncelleme
- [x] Adim 049 - NonconformityRepository sorumlu taraf guncelleme
- [x] Adim 050 - NonconformityRepository kayit var mi kontrolu
- [x] Adim 051 - NonconformityRepository kayit sayisi
- [x] Adim 052 - NonconformityRecord arsiv alani
- [x] Adim 053 - NonconformityRepository aktif / arsiv filtreleme

Adim 021-025 araligi tamamlandi. Bu aralik icin final NotebookLM podcast notu hazirlanacak.

Adim 026'da yeni ek dosya modeli eklenmeden, mevcut `AttachmentRecord` modelinin uygunsuzluk adayi kayitlarina kanit dosyasi baglamak icin kullanilacagi netlestirildi.

Adim 027'de uygunsuzluk adayi surecinin kontrol sonucu, aday kaydi, degerlendirme, aksiyon, takip ozeti ve ek dosya durumunu tek ozet kayitta temsil eden baslangic gorunum modeli eklendi.

Adim 028'de uygunsuzluk adayi durum degisikliklerinin eski durum, yeni durum, sebep, kisi, tarih ve kaynak kayit bilgisiyle temsil edilmesi icin baslangic durum gecmisi modeli eklendi.

Adim 029'da uygunsuzluk adayinin kime atandigini, kim tarafindan atandigini, hedef tarihini, onceligini ve sorumluluk notunu temsil eden baslangic atama modeli eklendi.

Adim 030'da uygunsuzluk adayinin nasil sonuclandigini, kim tarafindan kapatildigini, takip gerektirip gerektirmedigini ve nihai durumunu temsil eden baslangic kapanis modeli eklendi.

Adim 031'de Adim 026-030 araliginin final NotebookLM podcast notu hazirlandi.

Adim 032'de mevcut `NonconformityRecord` modeli yeniden olusturulmadan, aday kaydin kesin uygunsuzluk / NCR kaydina donusum baglantisini temsil eden baslangic model eklendi.

Adim 033'te mevcut `NonconformityRecord` modelinin Adim 021-032 zincirinden sonra yeterliligi degerlendirildi; model degistirilmeden revizyon karar hazirligi raporu hazirlandi.

Adim 034'te mevcut `NonconformityRecord` modeli kontrollu sekilde revize edilerek `nonconformity_type`, `detected_by`, `detection_date` ve `final_status` alanlari eklendi.

Adim 035'te kesin uygunsuzluk / NCR surecini tek bakista temsil eden baslangic gorunum modeli eklendi.

Adim 036'da kesin uygunsuzluk / NCR durum degisikliklerinin eski durum, yeni durum, sebep, kisi, tarih ve kaynak kayit bilgisiyle temsil edilmesi icin baslangic durum gecmisi modeli eklendi.

Adim 037'de kesin uygunsuzluk / NCR kaydinin kisi, ekip, firma veya sorumlu birime atanmasini temsil eden baslangic sorumluluk modeli eklendi.

Adim 038'de kesin uygunsuzluk / NCR kaydi icin planlanan duzeltici faaliyeti temsil eden baslangic veri modeli eklendi.

Adim 039'da kesin uygunsuzluk / NCR duzeltici faaliyetinin sahada kontrol edilip sonucunun kayda alinmasini temsil eden baslangic dogrulama modeli eklendi.

Adim 040'ta kesin uygunsuzluk / NCR kaydinin kapatilma kararini, kapatan kisiyi, kapanis tarihini ve sonucunu temsil eden baslangic kapanis modeli eklendi.

Adim 041'de `NonconformityRecord` kayitlarini bellek icinde eklemek, listelemek ve kimlige gore bulmak icin baslangic repository sinifi eklendi.

Adim 042'de `NonconformityRepository.add` icin ayni `nonconformity_id` degerine sahip ikinci kaydi engelleyen bellek ici duplicate id kontrolu eklendi.

Adim 043'te `NonconformityRepository` icine `status` alanina gore bellek ici filtreleme yapan `list_by_status` davranisi eklendi.

Adim 044'te `NonconformityRepository` icine `responsible_party` alanina gore bellek ici filtreleme yapan `list_by_responsible_party` davranisi eklendi.

Adim 045'te `NonconformityRepository` icine kayitlari `status` degerlerine gore sayan `get_status_summary` davranisi eklendi.

Adim 046'da `NonconformityRepository` icine kayitlari `responsible_party` degerlerine gore sayan `get_responsible_party_summary` davranisi eklendi.

Adim 047'de `NonconformityRepository` icine toplam, acik, kapali, atanmis ve atanmamis kayit sayilarini veren `get_overview_summary` davranisi eklendi.

Adim 048'de `NonconformityRepository` icine mevcut kaydin `status` alanini bellek icinde guncelleyen `update_status` davranisi eklendi.

Adim 049'da `NonconformityRepository` icine mevcut kaydin `responsible_party` alanini bellek icinde guncelleyen `update_responsible_party` davranisi eklendi.

Adim 050'de `NonconformityRepository` icine verilen `nonconformity_id` degerine sahip kaydin var olup olmadigini boolean olarak donduren `exists` davranisi eklendi.

Adim 051'de `NonconformityRepository` icine toplam kayit sayisini veren `count` ve belirli durumdaki kayit sayisini veren `count_by_status` davranislari eklendi.

Adim 052'de `NonconformityRecord` icine kaydin arsivlenip arsivlenmedigini temsil eden `is_archived` boolean alani eklendi.

Adim 053'te `NonconformityRepository` icine `is_archived` alanina gore aktif ve arsiv kayitlari ayiran `list_active` ve `list_archived` davranislari eklendi.

Sonraki kucuk adim onerisi: Adim 054 - NotebookLM podcast notu Adim 036-040
