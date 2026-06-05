# 011 RFI / Submittal Lite Kaydi Baslangici

Bu adimin amaci, RFI ve Submittal takip yapisina sade veri modelleriyle baslangic yapmaktir.

Bu adim gercek RFI/Submittal yonetim sistemi degildir. Onay, retur, revizyon, otomatik atama veya is akisi kurulmaz.

Veritabani, JSON kayit sistemi, API, GUI, Excel/PDF cikti, e-posta ve bildirim eklenmemistir.

`RFIRecord`, teknik soru ve cevap takibine baslangic modelidir. RFI konusu, soru, soruyu olusturan taraf, cevaplamasi beklenen taraf, soru tarihi, hedef cevap tarihi, cevap, durum ve not bilgisini tutar.

`SubmittalRecord`, teknik gonderim ve onay takibine baslangic modelidir. Gonderim konusu, gonderen taraf, inceleyen/onaylayan taraf, gonderim tarihi, inceleme hedef tarihi, cevap, durum ve not bilgisini tutar.

Bu adimda modeller arasinda kod seviyesinde iliski kurulmaz.

Ileride `AttachmentRecord` ile cizim, fotograf, irsaliye, teknik foy, onay yazisi gibi ekler baglanabilir.

Ileride `SubmittalRecord`, `MaterialRecord` ile malzeme onay surecinde iliskilendirilebilir.
