# Öğrenme Notu — 29 Temmuz Saha Bulgularını Roadmap'e Çevirme

## 1. Amaç

Bu adımın amacı 29 Temmuz 2026 günlük saha raporundaki 19 bulguyu tek bir büyük
özellik paketi gibi ele almak değil, her bulguyu riskine ve bağımlılığına göre
kanonik roadmap içinde doğru yere yerleştirmektir.

Sonuç üç katmanlıdır:

```text
P1 güvenilirlik hatası
→ P2 günlük sürtünme
→ P3 ortak veri omurgası ve dikey özellikler
```

Bu adım production kodu uygulamaz. Hangi production işinin neden önce gelmesi
gerektiğini, hangi sözleşmelerin daha sonra ayrı Issue'larda değişeceğini ve
hangi mevcut kanıtın korunacağını öğretir.

## 2. Günlük saha raporu roadmap'e nasıl çevrilir?

İlk işlem, kullanıcı cümlelerini doğrudan çözüm adlarına çevirmek değildir.
Önce her cümledeki kayıp türü bulunur:

1. Kullanıcı işi unutabilir veya aktif takip görünmez olabilir mi?
2. İş yapılabiliyor fakat gereksiz dokunma, odak veya zaman sürtünmesi var mı?
3. İstek ortak kimlik, veri modeli veya yeni dikey özellik mi gerektiriyor?
4. Başka bir güvenilirlik sözleşmesine bağımlı mı?
5. Mevcut source-of-truth'u çoğaltma veya geçmişi sessizce değiştirme riski var mı?

Bu soruların cevabı bulguyu P1, P2 veya P3'e ve D29.1–D29.5 bloklarından birine
yerleştirir. Saha cümlesi korunur; fakat implementation sınırı test edilebilir bir
sözleşmeye çevrilir.

## 3. Hata ile özellik isteği nasıl ayrılır?

Bir davranış mevcut kullanıcı sözleşmesini bozuyorsa hatadır. Örneğin bir
Hatırlatıcıyı tamamlamak diğer aktif bildirimleri de kaldırıyorsa kullanıcı
özellikle istediği takip görünürlüğünü kaybeder. Bu yeni özellik değil, P1
güvenilirlik hatasıdır.

Bir davranış çalışıyor fakat günlük işi yavaşlatıyorsa P2 sürtünmedir:

- detay dönüşünde klavyenin açılması;
- hızlı scroll'un search tap gibi algılanması;
- `Yarın sabah` tarihinin belirsiz olması;
- Hatırlatıcıyı erkene almak için tam forma girme zorunluluğu;
- backup sırasında uygulamanın donmuş gibi görünmesi.

Yeni ortak varlık veya geniş operasyon yüzeyi gerektiren işler P3'tür:

- stable-ID Mahal Kataloğu;
- Beton canlı operasyonu ve widget;
- İş/Yapılacaklar/otomatik log;
- Ortak Attachment fotoğraf kırpma;
- özel bildirim sesleri.

## 4. P1 neden P2 ve P3'ün önüne geçer?

P1 hata, kullanıcının “takip bende” güvenini bozar. P2 işleri sürtünmeyi azaltır;
P3 işleri ürün kapsamını büyütür. Güvenilir olmayan notification yaşam döngüsünün
üzerine Beton persistent notification veya özel ses eklemek aynı hatalı temeli
daha fazla yüzeye yayar.

Bu nedenle sıra şöyledir:

```text
D29.1 / Issue #272
→ D29.2 ve D29.3 günlük sürtünmeleri
→ D29.4 ve D29.5
→ Proje/Mahal, Beton, İş ve Attachment dikeyleri
```

P1'in önce gelmesi “daha önemli görünüyor” gibi öznel bir karar değildir. Sonraki
özelliklerin kullandığı platform kimliği ve yaşam döngüsü sözleşmesi burada
doğrulanacaktır.

## 5. Dependency-first sıralama

Roadmap, ekranların çekiciliğine göre değil kaynak sözleşmelerine göre sıralanır.

```text
Reminder UUID ↔ platform notification ID
→ tek-kayıt cancel/reconcile güvenilirliği
→ Açık Beton notification
→ Beton widget ve özel sesler
```

```text
Proje yaşam döngüsü
→ stable-ID Mahal Kataloğu
→ Beton, İş, Ajanda, Hatırlatıcı ve fotoğraf bağlantıları
```

```text
Yapılacak source state
→ atomik mutation
→ append-only otomatik İş logu
→ tarihsel İş/Ajanda görünümü
```

Bu sıra, sonradan yapılacak migration ve ilişki düzeltmelerini azaltır. Aynı
mahalin her modülde ayrı string olarak tutulması veya widget'ın ayrı sayaç
tutması gibi kısa vadeli çözümleri engeller.

## 6. Görünür notification ile pending native schedule aynı şey değildir

Bir one-time notification zamanı geldiğinde platform onu kullanıcıya teslim
edebilir. Teslim edilen bildirim panelde hâlâ görünürken native pending schedule
listesinden çıkmış olabilir.

Bu nedenle:

```text
pending listesinde yok
≠ terminal reminder
≠ görünür notification yok
≠ cancel edilmesi güvenli
```

`pendingNotificationRequests()` gelecekte teslim edilmeyi bekleyen native
schedule'ları anlatır. Uygulamanın domain kaydı ise reminder'ın aktif, ertelenmiş,
tamamlanmış veya iptal edilmiş olup olmadığını anlatır. Bu iki bilgi aynı
source-of-truth değildir.

Current repository'deki gerçek gateway kodu pending native istekleri şöyle okur:

```dart
@override
Future<List<PendingReminderNotification>> pendingNotifications() async {
  await initialize();
  final pending = await _plugin.pendingNotificationRequests();
  // Native pending schedule'lar logical reminder kimliklerine dönüştürülür.
}
```

Current reconciliation kodunda da schedule doğrulaması pending liste üzerinden
yapılır:

```dart
final pendingIsCurrent =
    validPendingIds.contains(binding.platformNotificationId) &&
    binding.scheduledFor == scheduledFor &&
    binding.safeErrorCode == null;
```

Bu kod parçaları Issue #272'nin çözümü değildir; read-only incelemede görülen
mevcut çalışma akışıdır. Issue #272, teslim edilmiş aktif one-time notification
ile terminal notification ayrımını sentetik baseline ve odaklı testlerle
kanıtlamadan production editine geçmeyecektir.

## 7. App, notification ve widget için neden tek read-model gerekir?

Açık Beton operasyonu üç yüzeyde görünebilir:

- uygulama içi canlı kart;
- Android notification;
- widget.

Bu üç yüzey kendi hedef/dökülen/kalan beton veya mikser sayısını saklarsa üç ayrı
gerçeklik oluşur. Paket kapandığında biri kapanıp diğeri açık kalabilir; mikser
sayısı veya kalan beton ayrışabilir.

Doğru yön:

```text
Beton source records
→ tek operation read-model
→ app kartı
→ notification
→ widget
```

Yüzeyler state sahibi değil, aynı read-model'in farklı sunumlarıdır. Hızlı eylem
doğru paket/revision kimliğiyle source mutation'ı açar; yüzey kendi sayacını
değiştirip source'u geride bırakmaz.

## 8. Parola neden veri güvenliği değildir?

Parola, işlemi kimin başlattığını doğrulamaya yardımcı olabilir; fakat yanlış
hedefin, eksik envanterin veya geri alınamaz veri kaybının önüne tek başına
geçmez.

Bağlı verili bir projeyi güvenli silme kararı için birlikte gerekir:

1. bağlı kayıt, medya ve event envanteri;
2. doğrulanmış backup;
3. geri alınamazlık onayı;
4. güvenlik parolası.

İlk implementation sınırı bu yüzden fail-closed'dur:

- boş/test ve bağlı verisi `0` proje ileride hard-delete adayı olabilir;
- bağlı verili proje arşivlenir;
- otomatik cascade hard-delete yapılmaz.

Arşivleme veri yaşam döngüsü kararıdır. Parola ise bu kararın yerine geçmeyen bir
güvenlik kapısıdır.

## 9. Neden stale/conflicted branch merge edilmedi?

Eski Draft PR #271 şu eski base üzerinde hazırlanmıştı:

```text
1179870a7c69d1e3f090e5fc61da9c7bbfc42879
```

Bu sırada PR #269 `ROADMAP.md` dosyasını değiştirerek master'a birleşti ve current
master şu oldu:

```text
438f0222f1a82c9dfa7ab53550d2b151daadaf18
```

Eski PR'ı merge etmek veya eski `ROADMAP.md` dosyasını kopyalamak, Issue #268'in
tamamlanma kaydını ve yeni Ajanda sıralama sözleşmesini geri alabilirdi. Rebase
ve force-push ise eski review geçmişini ve branch kimliğini yeniden yazardı.

Bu nedenle eski branch yalnız read-only karşılaştırma kaynağı olarak kullanıldı.
Commit cherry-pick edilmedi, branch merge edilmedi ve force-push yapılmadı.

## 10. Neden current master üzerine targeted rebuild yapıldı?

Current master, değişken repository gerçeğinin otoritesidir. Targeted rebuild şu
akışla yapıldı:

```text
current master ROADMAP
→ #268 / PR #269 completed gerçeğini koru
→ eski PR'deki D29 fikirlerini read-only karşılaştır
→ stale durum ve test sayılarını reddet
→ yalnız gerekli metadata, durum ve roadmap bloklarını ekle
→ fazları ve yatay kuralları koru
```

Bu yöntem mass rewrite yapmaz. Mevcut ürün vizyonu, fazlar, başarı ölçütleri ve
kapsam dışı sınırlar korunur; yalnız stale durumlar düzeltilir ve 29 Temmuz
katmanı uygun bölümlere yerleştirilir.

## 11. Testlerin ve dokümantasyon kontrollerinin amacı

Bu adım production davranışını değiştirmediği için Flutter/Python testleri,
analyze, build, APK/AAB ve fiziksel cihaz kapıları çalıştırılmaz. Bunlar değişen
sözleşme için yeni kanıt üretmez; yalnız süre ve ortam riski ekler.

Documentation validation şu riskleri karşılar:

- `git diff --check`: whitespace ve patch bütünlüğü;
- exact `3/3` allowlist: kapsam dışı dosya değişikliği;
- production/test diff `0`: runtime'a sızma;
- schema/migration diff `0`: veri sözleşmesine sızma;
- başlık/code-fence kontrolü: Markdown yapısının bozulması;
- conflict marker/tab/trailing whitespace `0`: conflict kalıntısı;
- 19/19 eşleme: günlük raporda bulgu kaybı;
- #268 completed ve #272 next-production kontrolleri: stale roadmap durumu.

PR #269'un static, focused, full suite, analyze, schema, backup ve Python
kanıtları değişmeyen production sözleşmeleri için yeniden kullanılır.

## 12. Teknik kararlar

- D29.1 / Issue #272 sıradaki tek production işidir.
- `pendingNotificationRequests()` tek başına reminder terminal durumu değildir.
- Route-local arama metni, focus/klavye durumuyla aynı şey değildir.
- Mahal serbest string değil stable kimliktir.
- Uygulama kartı, notification ve widget tek Beton read-model'ini kullanır.
- Yapılacak durumu source-of-truth; otomatik İş logu append-only olay kanıtıdır.
- Bağlı verili proje ilk implementation'da silinmez, arşivlenir.
- Fotoğraf kırpma orijinal physical attachment'ı sessizce ezmez.
- Özel sesler D29.1 ve kullanıcı asset'lerini bekler.
- Conflicted PR #271 içeriği yalnız read-only kaynak olarak kullanılır.

## 13. Şunu şöyle yaptık ki...

- Saha bulgularını P1/P2/P3'e ayırdık ki güvenilirlik hatası geniş özelliklerin
  arkasında kalmasın.
- D29.1'i #272 ile exact sıradaki iş yaptık ki tek-kayıt notification kimliği
  Beton notification ve özel seslerden önce güvenilir olsun.
- Pending native schedule ile görünür notification'ı ayırdık ki teslim edilmiş
  aktif bildirim yanlışlıkla terminal sayılmasın.
- Mahal'i stable ID olarak sıraladık ki Ajanda, Hatırlatıcı, Beton, İş ve
  fotoğraflar aynı bağlamı tekrar string üretmeden paylaşsın.
- Beton yüzeylerini tek read-model'e bağladık ki app, notification ve widget
  birbirinden kopmasın.
- Proje silmeyi fail-closed tuttuk ki parola veri envanteri ve backup'ın yerine
  geçmesin.
- Eski PR'ı merge etmedik ki PR #269 ile gelen current master gerçeği geri
  alınmasın.
- Runtime test çalıştırmadık ki documentation-only değişiklik riskiyle orantılı
  minimum yeterli doğrulama uygulansın.
