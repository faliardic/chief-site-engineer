# 013 Proje Tarafi ve Kisi Kaydi Baslangici

Bu adimin amaci, proje tarafi ve iletisim kisisi takibine sade veri modelleriyle baslangic yapmaktir.

Bu adim gercek rehber veya CRM sistemi degildir. Arama, filtreleme, telefon/e-posta dogrulama, kisi/firma eslestirme veya rehber arayuzu kurulmaz.

Veritabani, JSON kayit sistemi, API, GUI ve Excel/PDF cikti eklenmemistir.

`ProjectPartyRecord`, firma, kurum veya proje tarafi bilgisini temsil eder. Taraf adi, taraf tipi, proje rolu, vergi/kimlik numarasi, telefon, e-posta, adres, durum ve not bilgisini tutar.

`ContactPersonRecord`, kisi ve sorumluluk bilgisini temsil eder. Ad soyad, kurum, gorev, telefon, e-posta, sorumluluk alani, durum ve not bilgisini tutar.

Bu adimda iki model arasinda kod seviyesinde iliski kurulmaz.

Ileride bu kayitlar `RFIRecord`, `SubmittalRecord`, `MeetingActionRecord`, `DailyReportRecord`, `MaterialRecord` ve `NonconformityRecord` kayitlarinda sorumlu taraf veya iletisim kisisi olarak kullanilabilir.
