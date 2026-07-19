# Issue #185 — Mobil Günlük Puantaj İş Akışı

## Amaç ve kaynak sınırı

Bu dilim Release 0.1 mobil uygulamasında proje personelini ve günlük sahadaki
bulunma sonucunu internetsiz kaydeder. Puantaj source-of-truth'u mobil
SQLite'tır; Python/Flask runtime, LAN veya cloud servisi kullanılmaz.

Puantaj bir bordro modülü değildir. Ücret, maaş, SGK, hakediş, personel belgesi,
çoklu kullanıcı ve onay zinciri bu veri modelinde yer almaz.

## Mobil schema 4

Schema `3 → 4` tek SQLite transaction içinde ilerler. Yeni tablolar:

| Tablo | Sorumluluk |
| --- | --- |
| `workforce_members` | Projeye bağlı personel, ekip/taşeron, rol, optional kod ve pasiflik |
| `attendance_days` | Proje + İstanbul yerel günü için tek Puantaj aggregate'i |
| `attendance_entries` | Gün/personel sonucu, fazla mesai, kısa not ve logical removal |
| `attendance_events` | Aggregate içi monoton sequence taşıyan append-only geçmiş |
| `attendance_reminder_settings` | Proje bazlı saat, çalışma günleri ve enable ayarı |
| `attendance_day_reminder_links` | Bir Puantaj günüyle bir reminder arasındaki exact bağ |

`follow_up_items` ve `follow_up_events`, Ajanda source alanlarını koruyarak
optional `attendance_day_id` / `source_attendance_day_id` alır. Bir reminder
aynı anda hem observation hem Puantaj günü kaynağı taşıyamaz. Composite foreign
key, Puantaj günü ile reminder projesinin aynı olmasını database seviyesinde
zorunlu kılar. Notification binding satırları rebuild sırasında eksiksiz
kopyalanır.

Migration'ın herhangi bir SQL adımı başarısız olursa `PRAGMA user_version`,
schema geçmişi ve bütün v3 tabloları birlikte rollback olur.

## Personel

Personel şu alanlarla projeye bağlanır:

- ad soyad;
- ekip/taşeron;
- meslek/pozisyon;
- optional personel kodu;
- active/pasif durumu ve revision.

Personel kodu yalnız aynı proje içinde unique'tir. Düzenleme ve pasifleştirme
`expectedRevision` ile stale yazmayı reddeder. Fiziksel silme yoktur. Pasif
personel yeni günlük seçiminde varsayılan olarak görünmez; eski Puantaj satırı,
adı ve ekip toplamı okunmaya devam eder.

## Günlük aggregate ve sonuçlar

Her `(project_id, local_date)` çifti için en fazla bir `attendance_day` vardır.
Tarih anahtarı `YYYY-MM-DD` biçimindeki `Europe/Istanbul` yerel günüdür; kalıcı
event, created, updated ve reminder zamanları canonical UTC seconds kalır.

Desteklenen kişi sonuçları:

| Sonuç | Kişi-gün | Fazla mesai |
| --- | ---: | --- |
| Tam gün | 1.0 | Sıfır veya pozitif dakika |
| Yarım gün | 0.5 | Sıfır veya pozitif dakika |
| Gelmedi | 0.0 | Zorunlu olarak 0 |
| İzinli | 0.0 | Zorunlu olarak 0 |

Günlük toplamlar kayıtlı satırlardan türetilir; ayrı ve drift edebilecek bir
toplam tablosu tutulmaz. Görünür sıra ekip/taşeron, personel adı ve kayıt
kimliğiyle deterministiktir. `Tümünü tam gün` ve seçili `Ekibi tam gün`
işlemleri tek immutable command, tek transaction ve tek aggregate revision
artışı üretir.

## Yaşam döngüsü ve event geçmişi

Durumlar:

```text
taslak --tamamla--> tamamlandı
taslak --çalışma yok--> çalışma yok
tamamlandı/çalışma yok --düzeltmek için aç--> taslak
```

Yalnız taslak günün girişleri değiştirilebilir. Tamamlandı ve çalışma yok
durumları açık bir reopen olmadan düzenlenemez. Stale revision fail-closed
reddedilir; gerçek no-op revision veya event artırmaz.

Puantaj event vocabulary'si:

```text
attendance_day.created
attendance_entry.upserted
attendance_entry.removed
attendance_day.note_updated
attendance_day.completed
attendance_day.no_work
attendance_day.reopened
attendance_day.csv_exported
attendance_day.reminder_linked
```

Event satırları aggregate içinde unique monoton `sequence` taşır. SQL trigger'ı
event update/delete işlemlerini; diğer trigger'lar aggregate ve personel hard
delete işlemlerini durdurur. Lifecycle row'u, Puantaj event'i ve linked reminder
mutation'ı aynı SQLite transaction'ındadır; ara veya yarım bağlı sonuç kalmaz.

## Puantaj hatırlatıcısı

Her proje için ayar:

- etkin/pasif;
- `Europe/Istanbul` yerel saat, varsayılan `17:00`;
- seçili çalışma günleri, varsayılan Pazartesi–Cumartesi;
- optimistic revision.

Bootstrap ve ayar kaydı bugünden başlayan önümüzdeki 14 yerel gün için
idempotent ensure çalıştırır. Yalnız seçili günlerde bir Puantaj günü, bir
linked reminder ve exact link oluşturulur. Sabit girdilerden üretilen kimlikler
ve unique anahtarlar tekrar çalıştırmada duplicate oluşmasını engeller.

Reminder `project_id` ve `attendance_day_id` değerlerini ilk insert anından
itibaren taşır. Gün tamamlanınca veya çalışma yok seçilince reminder aynı
transaction'da tamamlanır ve pending notification reconciliation ile iptal
edilir. Reopen reminder'ı aynı due anıyla yeniden aktif eder; due geçmişteyse
gecikmiş olarak görünür, gelecekteyse yeniden planlanır. Reminder detayındaki
`Kaynak Puantaj gününe dön` işlemi doğrudan ilgili gün ekranını açar.

Permission reddi veya notification plugin arızası business transaction'ı geri
almaz. SQLite reminder ve exact bağlantı korunur; mevcut safe operational sync
state kullanıcıya teslim problemini gösterir. Exact-alarm izni eklenmemiştir.

## CSV ve özet

CSV sözleşmesi:

- UTF-8 BOM ve CRLF satır sonu;
- sabit kolon sırası ve deterministic entry sırası;
- bütün hücrelerde CSV quote escaping;
- `=`, `+`, `-` veya `@` ile başlayan hücreye apostrof ekleyen formula
  injection koruması;
- dakika ve iki ondalıklı saat fazla mesai gösterimi.

Dosya uygulama içi export staging köküne atomik olarak yazılır. Event yalnız
başarılı stage sonrasında kaydedilir. Event yazılamazsa staged dosya temizlenir;
stage başarısızsa yarım final dosya bırakılmaz. İnsan-okunabilir özet proje,
tarih, durum, sonuç sayıları, kişi-gün, fazla mesai, ekip toplamları ve genel
notu içerir. Paylaşım platform share sheet üzerinden yapılır.

## Mobil yüzey

- Puantaj ana ekranında proje ve bugün/önceki/sonraki/tarih seçimi.
- Personel yönetiminde ekleme, düzenleme, pasifleştirme ve pasifleri gösterme.
- Gün ekranında kişi bazlı sonuç, fazla mesai, kısa not ve genel not.
- Tümünü veya ekip bazında tam gün işaretleme.
- Tamamlama, çalışma yok ve onaylı reopen.
- Günlük ve ekip toplamları, linked reminder ve event geçmişi.
- CSV kaydet/paylaş, insan-okunabilir özeti panoya kopyalama.

Form state'i validation/application hatasında korunur. Submit sırasında çift
dokunma kapanır. Ana işlemler 320–430 px genişlikte yatay taşma üretmez ve
dokunma hedefleri en az 44 px'tir.

## Korunan sınırlar

- Python schema `4`, Backup format `1`, restore allowlist `(2, 3, 4)` ve Günlük
  Çıktı format `1` değişmedi.
- Ajanda, reminder lifecycle, notification reconciliation ve eski mobil schema
  verileri korunur.
- Repository `exports/` çalışma zamanı hedefi değildir ve yalnız `.gitkeep`
  taşır.
- Android release AAB repository signing materyali olmadan unsigned üretilir.
- Native iOS archive Windows üzerinde çalıştırılmaz; tracked iOS uyumluluğu
  statik test edilir.
- Beton Paketi, bordro ve store submission başlatılmadı.
