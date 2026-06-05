# 010 Toplanti Tutanagi ve Aksiyon Kaydi Baslangici

Bu adimin amaci, santiye toplantilari ve bu toplantilardan cikan aksiyonlar icin sade bir veri modeli baslangici yapmaktir.

Bu adim gercek toplanti yonetim sistemi degildir. Tutanaktan otomatik gorev uretme, takvim takibi, bildirim, sorumlu kisiye otomatik atama veya kapatma akisi kurulmaz.

Veritabani, JSON kayit sistemi, API, GUI, Excel/PDF cikti ve takvim entegrasyonu eklenmemistir.

`MeetingRecord`, toplanti bilgisini temsil eder. Toplanti basligi, tarih, yer, organize eden taraf, katilimcilar, gundem, kararlar, notlar ve durum bilgisini tutar.

`MeetingActionRecord`, toplantidan cikan aksiyon veya gorev fikrini temsil eder. Aksiyon basligi, bagli oldugu toplanti basligi, sorumlu kisi, termin tarihi, durum ve not bilgisini tutar.

Bu adimda iki model arasinda kod seviyesinde iliski kurulmaz. `MeetingActionRecord.meeting_title` alani sadece metinsel bir referans olarak tutulur.

Ileride toplanti aksiyonlari issue, task veya punch list moduluyle baglanabilir. Bu baglanti icin once modellerin hangi bilgileri tasiyacagi netlestirilmistir.
