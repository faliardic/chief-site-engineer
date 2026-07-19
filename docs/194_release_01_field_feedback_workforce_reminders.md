# Issue #194 — Release 0.1 Saha Düzeltmeleri

## Amaç ve sınır

Bu dilim Release 0.1 saha geri bildirimlerinden gelen üç dar ihtiyacı birlikte
çözer: yeni projenin açık mobil ekranlarda hemen görünmesi, Puantaj personelinin
taşeron/ekip siciliyle yönetilmesi ve reminder kartından güvenli `Yarın`
ertelemesi. Beton dökümündeki iki saha koordinasyon görevi de aynı linked
reminder altyapısına alınır.

Telefon ve mobil SQLite source-of-truth olmaya devam eder. Fiziksel silme,
cloud sync, çoklu kullanıcı, ücret/bordro/SGK/hakediş, biyometri, otomatik
hukuki karar, exact alarm ve mağaza gönderimi eklenmez.

## Schema 6 ve legacy veri korunumu

Schema `5 → 6` migration şu kayıtları ekler:

- proje bazlı `subcontractors`;
- taşerona ve aynı projeye bağlı `workforce_teams`;
- personelde exact `subcontractor_id` ve `team_id`;
- append-only `workforce_events`;
- kişi bazlı İSG belge görünürlüğü ve KKD zimmet geçmişi;
- saatlik inexact notification için yalnız `60` değerini kabul eden binding alanı.

Eski serbest metin `team_name`, trim + whitespace collapse + küçük harf
normalization ile deterministik kimliğe çevrilir. Boş değer `Tanımsız ekip`
olur. Migration personel satırını yeniden üretmez; mevcut personel ID'sine
bağlantı kolonlarını yazar. Böylece attendance entry ve append-only Puantaj
event geçmişi aynı kimliklerle kalır. Bütün v6 adımları aynı SQLite migration
transaction'ındadır; enjekte edilen hata tam rollback olur ve sonraki açılışta
güvenli retry yapılabilir.

## Sicil ve Puantaj kullanıcı akışı

Personel ekleme sırası artık taşeron → o taşeronun ekibi → personeldir. Her iki
seçicide de `+ Yeni` akışı vardır; oluşturulan kayıt seçili hale gelir ve form
girdileri validation hatasında korunur. Serbest metin ekip girişi UI'dan
kaldırılmıştır.

Taşeron, ekip ve personel kayıtları normalized duplicate, optimistic revision,
no-op ve logical archive kurallarını aynı application service sınırında uygular.
Aktif personel varken üst kayıt pasifleştirilemez. Reopen üstten alta yapılır.
Günlük Puantaj toplu işlemleri görünür yazı yerine exact `team_id` kullanır.

Personel ayrıntısı üç görünüm sunar:

- Genel/Puantaj: kimlik, iletişim ve günlük geçmiş özeti;
- İSG: belge türü, tarih, eksik/istisna/geçerli/yaklaşan/süresi dolmuş read-model'i;
- KKD: zimmet, iade, kayıp, hasarlı ve logical archive geçmişi.

İSG görünümü kayıt ve hatırlatma desteğidir; işe kabul ya da hukuki uygunluk
kararı değildir.

## Canlı proje kataloğu

Ajanda ana ekranındaki `Yeni proje`, başarılı transaction sonrasında process içi
bir değişiklik sinyali yayınlar. Ajanda, Hatırlatıcı formu, Puantaj ve Beton açık
durumdaysa kataloglarını yeniden SQLite'tan okur ve yeni projeyi restart olmadan
gösterir. Kalıcı kaynak stream değil `projects` tablosudur; restart kalıcılığı
bu nedenle ayrıca test edilir.

Aktif proje adı karşılaştırması baş/son boşluk, ardışık whitespace ve harf
büyüklüğünü normalize eder. Aynı görünen ikinci proje mutation başlamadan
reddedilir.

## Beton saha görevleri ve kodsuz numune seti

Yeni dökümde exact iki linked reminder bulunur:

1. `Laboratuvar randevusunu al/doğrula`
2. `Yapı denetime haber ver`

Her biri ilk anda döküm ve proje bağlantısını taşır; notification 60 dakika
aralıkla inexact tekrarlanır. İlgili Beton alanı doldurulunca görev kapanır,
alan yeniden boşaltılırsa mevcut exact görev güvenli biçimde reopen edilir.
İkinci reminder üretilmez. Permission veya plugin hatası business reminder'ı
geri almaz.

Numune seti formu kullanıcıdan kod istemez. Application service sıralı ve
deterministik `Numune seti N` etiketi üretir. Var olan set güncellenirken mevcut
kod korunur.

## Reminder `Yarın` sözleşmesi

Aktif veya overdue karttaki `Yarın`:

- due varsa onun Europe/Istanbul yerel saatini bir sonraki takvim gününde korur;
- Unutma Kutusu kaydıysa ertesi gün 09:00 Europe/Istanbul seçer;
- sonucu canonical UTC olarak saklar;
- optimistic revision ve append-only event üretir;
- source observation ya da Beton kaydını değiştirmez;
- double-tap sırasında tek mutation çalıştırır.

Saatlik Beton notification'ı `Yarın` sonrasında yeni due zamanına kadar tek
seferlik pending olarak tutulur. Due erişince reconciliation aynı binding'i
60 dakikalık inexact tekrar olarak yeniden kurar. Exact-alarm izni kullanılmaz.

## Backup ve doğrulama sınırı

`.csebackup` formatı `1` değişmez. Restore staging allowlist schema `1`–`6`'dır;
schema `6` fixture'ı taşeron, ekip, personel linki, workforce event, İSG ve KKD
kayıtlarını exact round-trip doğrular. Bilinmeyen gelecek schema fail-closed
reddedilir.

Kabul kapısı Flutter analyze ve bütün testlere ek olarak API 36 emülatör
integration, debug APK, unsigned release AAB, iOS statik doğrulama, Python full
suite/compileall, state JSON, diff/allowlist, secret taraması ve ephemeral-signed
ARM64/16 KiB Android RC üretimini içerir. Gerçek signing materyali kullanılmaz.
