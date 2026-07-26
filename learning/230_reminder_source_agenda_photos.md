# Issue #230 — Kaynak Ajanda Fotoğrafları Öğrenme Notu

## Amaç

Reminder ile kaynak Ajanda fotoğrafını yeni bir attachment sistemi kurmadan
buluşturduk. Ana fikir, aynı kanıtı ikinci kez saklamak yerine kaynak kaydı
salt-okunur bir projection ile reminder detayına taşımaktır.

## Gerçek kodda ne değişti?

| Katman | Değişiklik | Amaç |
| --- | --- | --- |
| Domain | `ReminderSourceAgendaMedia` | Sıralı, tekilleştirilmiş fail-soft sonuç |
| Application | Ayrı read-only capability | UI ile SQLite arasında test edilebilir sınır |
| Agenda UI | Ortak `AgendaPhotoThumbnail` | Aynı güvenli byte okuma yolunu paylaşmak |
| Reminder UI | Kaynak fotoğraf bölümü | Metadata, integrity ve viewer erişimi |
| Test fake | Capability ve içerik fixture'ı | Başarı/hata/trash senaryolarını izole etmek |

## Neden ayrı capability?

Ana `AgendaApplication` sözleşmesine yeni zorunlu metot eklemek, kaynak
fotoğrafı kullanmayan bütün fake ve consumer'ları gereksiz yere değiştirirdi.
Bu yüzden reminder detayı yalnız destekleyen implementation'da capability
kontrolü yapar:

```dart
if (widget.agenda case final ReminderSourceAgendaMediaApplication media) {
  return media.getReminderSourceAgendaMedia(sourceLogId);
}
return ReminderSourceAgendaMedia.unavailable(sourceLogId: sourceLogId);
```

Bu sınır UI'ın SQLite sorgusu yazmasını engellerken değişikliğin dar kalmasını
sağlar.

## Read-model nasıl çalışıyor?

Application önce kaynak logun varlığını ve archive zamanını okur. Ardından
yalnız `archived_at IS NULL` fotoğrafları `created_at, id` sırasında getirir ve
her satır için mevcut attachment store `inspect` sonucunu kullanır.

```text
source log
→ active photo metadata
→ existing integrity inspection
→ immutable ReminderSourceAgendaMedia
→ reminder detail
```

Domain factory photo ID için first-wins tekilleştirme yapar. Böylece bozuk bir
join veya fixture aynı kimliği iki kez üretse bile kullanıcı duplicate kart
görmez.

## Integrity neden UI'da filtre değildir?

`missing`, `tampered` ve `invalidMime` bir fotoğrafın kanonik attachment
kaydının varlığını ortadan kaldırmaz; kullanıcıya “kanıt yokmuş” izlenimi
vermemelidir. Kart görünür kalır ve viewer mevcut güvenli diagnostic'i gösterir.
Byte okumak için yeni dosya yolu veya bypass eklenmedi:

```dart
AgendaPhotoThumbnail(agenda: agenda, photo: photo)
AgendaPhotoViewerPage(agenda: agenda, photo: photo)
```

İki bileşen de sonunda `readAgendaPhoto(photo.id)` çağırır.

## Fail-soft yaklaşımı

Reminder'ın kendisi authoritative ana detaydır; source medya yardımcı bir
projection'dır. Bu nedenle iki Future birbirine bağlanmadı. Reminder yüklenir,
source medya ayrı bekler. Source sorgusu hata verirse yalnız fotoğraf bölümü
güvenli diagnostic gösterir:

```text
source_agenda_media_unavailable
```

Exception mesajı, dosya yolu veya özel veri ekrana yazılmaz. Diğer fotoğraf ve
source deep-link erişimi mümkün olduğunca korunur.

## Testlerin amacı

- `agenda_application_test.dart`: boş/tek/çoklu sıra, archive, trash,
  integrity, duplicate, read-only revision/event ve fail-soft davranış.
- `reminder_widget_test.dart`: metadata, mevcut viewer, başarılı byte,
  missing/tampered/invalidMime diagnostic, source failure, empty/absent source,
  trash görünürlüğü, deep-link ve 44 px hedef.
- `flutter analyze --no-pub`: capability, model ve widget bağlarının bütün
  mobile kodunda tip/API açısından geçerli olması.

## Şunu şöyle yaptık ki...

- Şunu şöyle yaptık ki aynı fotoğraf iki source-of-truth kazanmasın: byte ve
  metadata'yı reminder'a kopyalamadık.
- Şunu şöyle yaptık ki bozuk attachment sessizce kaybolmasın: integrity sonucu
  ne olursa olsun metadata kartını gösterdik.
- Şunu şöyle yaptık ki tek source hatası reminder'ı düşürmesin: source medya
  Future'ını ana detail yüklemesinden ayırdık.
- Şunu şöyle yaptık ki mevcut güvenlik sözleşmesi delinmesin: thumbnail ve
  viewer için aynı `readAgendaPhoto` yolunu yeniden kullandık.
- Şunu şöyle yaptık ki kapsam büyümesin: capability'yi read-only tuttuk ve
  reminder detayına mutation kontrolü eklemedik.

## Bilinçli olarak yapılmayanlar

Schema/migration, backup, attachment store, platform kodu, photo mutation,
generic attachment v2, PDF/Office/DWG, video/ses, export/paylaşma,
Beton/Puantaj attachment görünürlüğü, build/release ve fiziksel cihaz kabulü bu
adımda değiştirilmedi veya çalıştırılmadı.
