# 009 Malzeme Giris/Kullanim Kaydi Baslangici

Bu adimin amaci, malzeme takip sistemine sade bir veri modeliyle baslangic yapmaktir.

Bu adim gercek stok sistemi degildir. Stok dusumu, miktar hesaplama, depo hareketi veya otomatik malzeme takibi kurulmaz.

Veritabani, JSON, API, GUI ve Excel/PDF cikti eklenmemistir.

`MaterialRecord`, ileride malzeme kabul, irsaliye, kullanim yeri ve kanit eki baglantilari icin temel modeldir.

Model; malzeme adi, tedarikci, irsaliye numarasi, miktar, birim, mahal/alan, giris tarihi, kullanim tarihi, durum ve not bilgilerini temsil eder.

`AttachmentRecord` ile ileride irsaliye, fotograf veya kalite belgesi baglantisi kurulabilir. Bu adimda kod seviyesinde `AttachmentRecord` ile bag kurulmaz.
