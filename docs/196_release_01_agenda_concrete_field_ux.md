# Issue #196 — Ajanda ve Beton Saha Akışı

## Amaç ve ürün sınırı

Bu dilim, Release 0.1 gerçek saha kullanımındaki Ajanda kayıt yönetimi ile
Beton belge–mikser sürtünmelerini kapatır. Telefon cihaz-of-truth ve mobil SQLite
source-of-truth olarak kalır. Cloud/OCR, internet tabanlı tarama, çoklu kullanıcı,
fiziksel veri silme ve mağaza gönderimi eklenmez.

## Mobil schema 7

Schema `6 → 7` tek migration transaction'ında ilerler. Mevcut Ajanda, reminder,
notification, Puantaj, sicil/İSG/KKD, Beton, attachment ve event satırları
korunur. Yeni sözleşme:

- `agenda_log_attachments`, Ajanda fotoğrafını exact observation ve project
  kimliğiyle bağlar; MIME, byte size, SHA-256, relative path, revision ve archive
  metadata'sını taşır;
- JPEG/PNG yalnız gerçek içerik imzası doğrulandıktan sonra kabul edilir;
- `concrete_trucks.delivery_note_number` nullable olur; yalnız dolu normalize
  değerler partial unique index ile tekildir;
- truck'a bağlı sample, follow-up ve attachment foreign key grafiği migration
  içinde yeniden kurulur;
- aggregate ve attachment tablolarında fiziksel `DELETE` trigger ile reddedilir;
- schema/event migration hatası sürümü ilerletmeden tam rollback olur.

`.csebackup` formatı `1` değişmez. Restore staging alanı mobil schema `1`–`7`
paketlerini kabul eder ve eski paketleri yalnız staging'de v7'ye yükseltir.

## Ajanda kayıt yaşam döngüsü

Log detayında kullanıcı alanları `Düzenle` ile değiştirilebilir. Immutable command
exact log ID, expected revision ve yeni değerleri taşır. Stale işlem fail-closed
reddedilir; no-op revision/event artırmaz. Başarılı değişiklik
`agenda_log.updated` event'inde güvenli before/after özeti üretir. Bağlı reminder
varsa proje sessizce değiştirilemez ve hiçbir reminder mutation'ı yapılmaz.

`Sil`, fiziksel delete değildir. Açık onay metni “Kayıt arşive taşınacak, geri
getirilebilir” der; kayıt aktif listeden çıkar, `Arşivlenenler` filtresinde
görünür ve `Geri getir` ile döner. `agenda_log.archived` ve
`agenda_log.restored` append-only event'leri yazılır. Bağlı reminder satırı,
durumu ve notification yaşam döngüsü değiştirilmez.

Yazılı reminder düğmesi kaldırılmıştır. Sağ üst AppBar'da en az 44 px alarm
ikonu, `Hatırlatıcı oluştur` semantic label/tooltip'i bulunur. Exact bağlı
reminder varsa ikon onu açar; aynı kaynaktan istemeden duplicate üretmez.

## Ajanda fotoğrafları

Log oluşturma formu ile log detayı kamera veya sistem fotoğraf seçicisini
kullanır. Formdaki seçimler başarılı log transaction'ına kadar source-of-truth
değildir. Cihaz deposu şu sırayı uygular:

1. permission/capability sonucu alınır;
2. JPEG/PNG içerik imzası ve boyut sınırı doğrulanır;
3. byte'lar güvenli staging dosyasına yazılır;
4. SHA-256 tekrar okunup doğrulanır;
5. dosya güvenli relative final konuma atomik taşınır;
6. attachment row, log revision ve append-only event tek DB transaction'ında
   yazılır;
7. DB/event hatasında finalize edilen orphan dosya temizlenir.

Fotoğraf kartına dokununca tam ekran zoom/pan görüntüleyici açılır. MIME, boyut,
hash ve bütünlük bilgisi görünür. Missing/tampered içerik raw exception yerine
güvenli tanı gösterir. Fotoğraf arşivleme row ve dosyayı fiziksel silmez;
`agenda_log.photo_archived` üretir. Aktif ve arşivlenmiş log fotoğrafları backup
ile relative path üzerinden farklı cihaz köküne taşınabilir.

## Beton belge ve mikser akışı

Mikser kartı düzenleme formunu açar. Plaka, zamanlar, irsaliye, hacim, sonuç,
not ve gerekçe optimistic truck/pour revision ile yazılır. No-op event üretmez;
değişiklik `truck.updated` before/after payload'ı ile aynı transaction'dadır.
İrsaliye numarası boş bırakılıp daha sonra eklenebilir. Birden fazla boş değer
çatışmaz; dolu normalize değer duplicate olamaz.

`İrsaliye taraması` kamera veya sistem seçimi sonrası kullanıcı onayıyla
`delivery_note_scan` olarak exact truck ID'ye bağlanır. Bir mikserde birden fazla
scan olabilir. Legacy `delivery_receipt_scan` okunmaya ve kanıt hesabına katılmaya
devam eder. JPEG/PNG uygulama içi zoom/pan ekranında; PDF güvenli cihaz viewer
akışında açılır. Attachment'a dokunmak dosyayı veya truck'ı değiştirmez.

Beton detayında aynı hesap motorundan canlı değerler gösterilir:

- `Hedef` = düzenlenebilir `planned_volume_m3`;
- `Dökülen` = aktif, received/partial mikser hacimlerinin toplamı;
- hedef büyükse `Kalan = hedef - dökülen`;
- dökülen büyükse clamp yerine `Aşılan = dökülen - hedef`.

Görünüm iki ondalık ve Türkçe virgülle deterministiktir. Hedef, expected pour
revision ile artırılıp azaltılabilir. Yeni hedef mevcut dökülenden küçükse açık
uyarı gösterilir; mikser satırları değişmez. No-op event üretmez; değişiklik
before/after hedef değerini taşır.

## Toplu tamamlama

`Tümünü tamamla`, yalnız kullanıcının manuel kapatabildiği pending checklist ve
follow-up maddelerini açık adet/onayla tek transaction'da tamamlar. Laboratuvar
randevusu ve yapı denetim bildirimi source-field görevleri dışarıda kalır.
Her değişen madde deterministik append-only event üretir; linked reminder aynı
transaction'da kapanır. Stale işlem tam rollback olur. Aynı command retry veya
double-tap ikinci event/revision üretmez.

## PDF paylaşma ve kaydetme

Kullanıcının Beton raporu ana çıktısı embedded açık lisanslı Roboto fontlarıyla
üretilen UTF-8 PDF'dir. Rapor proje/kod/mahal/tarih/sınıf/santral/laboratuvar,
canlı m³, checklist/takip özeti, mikser ve irsaliye, numune, attachment sayıları
ve oluşturma zamanını taşır; repository veya absolute app path içermez.

`PDF paylaş` yalnız OS share sheet'i, `Telefona kaydet` Android SAF/iOS belge
kaydetme yüzeyini açar. İki eylem ayrı command'dır. Render → yapısal PDF kontrolü
→ staging → tekrar doğrulama sırası uygulanır. Kullanıcı kaydetmeyi iptal ederse
başarı/event yazılmaz. Share/save/plugin/DB hatasında staged dosya temizlenir.
`report.exported` yalnız dış eylem gerçekten tamamlandıktan sonra eklenir.

## Gerçek cihaz kabul checklist'i

Bu maddeler repository testleriyle otomatik tamamlanmış sayılmaz. Yeni RC gerçek
Android cihazda Issue #193 kapsamında kullanıcı tarafından yürütülmelidir:

- [ ] Kamera ile Ajanda fotoğrafı ekle; thumbnail ve tam ekran zoom/pan aç.
- [ ] Kamera iznini reddet; yazılmış log alanlarının ve mevcut kaydın kaldığını
  doğrula.
- [ ] Mikserden iki irsaliye görüntüsü ekle; ikisini de doğru mikser bağlamında
  aç.
- [ ] Eksik/tamper test fixture'ında crash yerine güvenli tanıyı gözle.
- [ ] Türkçe karakterli Beton PDF'ini paylaş ve alıcı genel PDF viewer'da aç.
- [ ] `Telefona kaydet` ile seçilen konuma yaz; iptalde başarı mesajı/event
  oluşmadığını doğrula.
- [ ] Uygulamayı kapat/aç ve backup→restore yap; Ajanda fotoğrafı ile Beton
  scan'lerinin yeniden açıldığını doğrula.

Durum: **not run**. Codex gerçek cihaz saha kabulü veya store submission iddia
etmez.
