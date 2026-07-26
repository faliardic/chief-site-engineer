# Issue #230 — Reminder Detayında Kaynak Ajanda Fotoğrafları

## Amaç

Ajanda kaydından üretilmiş bir reminder açıldığında kaynak kaydın aktif
fotoğrafları aynı detay ekranında salt-okunur gösterilir. Kaynak gerçekliği
Ajanda'da kalır; reminder tablosuna veya state'ine attachment kopyalanmaz.

## Read-model sözleşmesi

`ReminderSourceAgendaMediaApplication`, `sourceLogId` üzerinden ayrı ve
test-edilebilir bir read-model döndürür:

- kaynak log kimliği ve archive zamanı;
- yalnız aktif Ajanda fotoğrafları;
- mevcut attachment store integrity sonucu;
- güvenli, kişisel veri taşımayan unavailable diagnostic'i.

SQLite sorgusu UI'da değildir. Fotoğraflar `created_at ASC, id ASC` sırasındadır.
Domain factory aynı photo ID tekrar ederse ilk kaydı koruyup yalnız bir kez
döndürür. Arşivli kaynak log okunabilir; `archived_at` taşıyan fotoğraf
gösterilmez.

## UI ve viewer

`sourceLogId` olan reminder detayında `Kaynak Ajanda fotoğrafları` bölümü
bulunur. Her satır:

- mevcut güvenli byte okuma yoluyla thumbnail;
- orijinal dosya adı;
- Türkçe integrity etiketi;
- byte boyutu;
- varsa açıklama

gösterir. Satır minimum 44 px dokunma alanıyla mevcut
`AgendaPhotoViewerPage` sayfasını açar. Viewer aynı `AgendaLogPhoto` ve
`readAgendaPhoto(photoId)` sözleşmesini kullanır.

Mevcut `Kaynak Ajanda kaydına dön` düğmesi korunur. Trash reminder detayında
aynı bölüm salt-okunur görünür; restore işlemi source kayıt veya attachment'a
dokunmaz.

## Fail-soft ve integrity

`missing`, `tampered` ve `invalidMime` metadata'sı taşıyan fotoğraf gizlenmez.
Satır integrity durumunu gösterir; açma denemesi mevcut güvenli viewer
diagnostic'ine gider. Tek fotoğrafın okunamaması diğer satırları veya reminder
ana detayını kapatmaz.

Kaynak read-model yüklenemezse reminder başlık, lifecycle ve source deep-link
alanları açık kalır. Fotoğraf bölümü yalnız
`source_agenda_media_unavailable` güvenli kodunu gösterir; exception metni,
absolute path veya kullanıcı verisi UI'a sızdırılmaz.

## Değişmeyen sözleşmeler

- Mobil schema `9` ve backup format `1`;
- attachment store, managed byte yerleşimi ve MIME politikası;
- Android/iOS platform kodu;
- Ajanda photo add/archive ve açıklama düzenleme akışları;
- source log/photo/reminder revision ve append-only event geçmişi.

Reminder içinden fotoğraf ekleme, silme, arşivleme veya düzenleme yoktur.
Generic attachment v2, PDF/Office/DWG, video, ses, export/paylaşma ve
Beton/Puantaj attachment görünürlüğü başlatılmamıştır.

## Doğrulama sınırı

Validation sınıfı `narrow-ui + read-only domain`dir. Agenda source read-model,
reminder detail ve mevcut viewer/integrity davranışı focused testlerle;
mobile tip/API bütünlüğü `flutter analyze --no-pub` ile doğrulanır. Persistence,
backup, release, build ve gerçek cihaz kapıları değişmeyen sözleşmeler için
yeniden çalıştırılmaz.
