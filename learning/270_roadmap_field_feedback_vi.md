# Öğrenme Notu — 29 Temmuz Saha Bulgularını Roadmap'e Çevirme

## 1. Saha geri bildirimi tek bir özellik listesi değildir

Aynı günlük raporda hem güvenilirlik hatası hem küçük UX sürtünmesi hem de geniş
ürün fikri bulunabilir. Bunları tek büyük Issue'ya koymak doğrulamayı belirsiz hale
getirir. Bu nedenle önce sınıflandırma yapılmalıdır:

- **P1:** yanlış notification yaşam döngüsü gibi işi unutturabilecek hata;
- **P2:** arama odağı, klavye ve zaman düzenleme sürtünmesi;
- **P3:** Mahal Kataloğu, Beton widget'ı veya geniş İş sistemi.

Roadmap sırası, P1/P2 kapanmadan P3'e geçmeyecek biçimde düzenlenmiştir.

## 2. Görünür hata, alttaki kimlik sözleşmesini işaret eder

“Bir bildirimi tamamlayınca bütün bildirimlerin kaybolması” yalnız UI sorunu
değildir. Muhtemel risk alanları notification ID üretimi, binding saklama,
reconciliation ve toplu iptal çağrılarıdır. Aynı altyapıya açık Beton bildirimi
ve özel ses eklemek, hata çözülmeden riski büyütür.

Bu nedenle bağımlılık şudur:

```text
Tek-kayıt notification kimliği ve yaşam döngüsü
→ Açık Beton persistent bildirimi
→ Beton widget / özel sesler
```

## 3. Doğal dil zamanları kesin sözleşmeye çevrilmelidir

`Yarın sabah` veya `hafta başı` kullanıcı için doğal, yazılım için belirsizdir.
Belirsizlik, işlem öncesi gösterilen exact yerel tarih/saat ile kapatılır:

- `Yarın sabah` → ertesi Europe/Istanbul günü `08:00`;
- `Hafta başına ertele` → sonraki pazartesi `08:00`.

DST, ay/yıl geçişi ve pazartesi günü çağrısı dahil edge-case testleri bu ortak
helper'ın parçası olmalıdır. UI, domain helper ve notification scheduler farklı
yorum üretmemelidir.

## 4. Route state ile focus state aynı şey değildir

Arama metninin detay dönüşünde korunması faydalıdır; ancak focus ve klavyenin de
geri gelmesi ayrı bir davranıştır. Route-local state şu şekilde ayrıştırılmalıdır:

- korunabilir: arama metni, filtre, sıralama, scroll bağlamı;
- otomatik geri gelmemeli: focus, imleç, açık klavye;
- yalnız açık kullanıcı gesture'ı: arama alanına dokunma.

Hızlı liste kaydırmasının search tap olarak algılanmaması gesture sınırının test
edilmesini gerektirir.

## 5. Mahal tekrar kullanılan ortak kimliktir

Her Beton, Ajanda veya İş kaydına serbest mahal metni yazmak tekrar veri girişi ve
isim ayrışması üretir. Mahal Kataloğu stable ID ile ortak bağlam sağlar. Ad değişse
bile tarihsel kayıtların kimliği korunur. Bu temel kurulmadan Beton canlı
operasyonu veya geniş İş sistemi aynı bağlamı güvenilir biçimde paylaşamaz.

## 6. Read-model çoğaltılmaz

Açık Beton için uygulama kartı, Android bildirimi ve widget üç ayrı source-of-truth
olmamalıdır. Tek read-model hedef, dökülen, kalan/aşılan, mikser sayısı ve son
mikser zamanını üretir. Her yüzey bunu okur; kendi sayacını tutmaz.

Bu kural stale widget, yanlış kalan beton ve paket kapandığı halde açık bildirim
gibi ayrışmaları önler.

## 7. Otomatik log, düzenlenebilir ikinci gerçeklik değildir

Yapılacak item durumu source-of-truth'tur. Tamamlama mutation'ı append-only log
oluşturur; kullanıcı logu sonradan değiştirerek item durumunu yeniden yazamaz.
Manuel not/fotoğraf eklenebilir fakat otomatik olayın kaynağı ve zamanı korunur.
Aynı yaklaşım Ajanda değişiklik geçmişinde de kullanılabilir.

## 8. Parola veri yaşam döngüsü politikası değildir

“Şifre sor ve sil” yanlışlıkla veri kaybını tek başına önlemez. Güvenli karar
sırası şöyledir:

1. bağlı veri envanteri;
2. boş/test projesi ile bağlı verili projenin ayrılması;
3. doğrulanmış backup;
4. geri alınamazlık doğrulaması;
5. güvenlik parolası;
6. append-only silme/audit kanıtı.

Bu nedenle ilk implementation yalnız boş/test projesini hard-delete adayı yapar;
bağlı verili proje arşivlenir.

## 9. Medya düzenleme orijinali sessizce yok etmemelidir

Kırpma görünüşte basit bir edit olsa da attachment hash'i, boyutu, backup ve
kaynak kanıtını etkiler. Orijinalin sessizce overwrite edilmesi yerine türev veya
açık kullanıcı tercihi gerekir. Perspektif düzeltme gibi belge işleme özellikleri
ayrı iterasyondur.

## 10. Roadmap sonucu

29 Temmuz raporu yeni bir “özellik paketi”ne çevrilmemiştir. Önce dar güvenilirlik
kapıları, sonra ortak veri kimlikleri, ardından Beton/İş/medya dikeyleri olacak
şekilde sıralanmıştır. Böylece günlük saha geri bildirimi ürün vizyonunu bozmak
yerine onu daha somut ve test edilebilir hale getirir.
