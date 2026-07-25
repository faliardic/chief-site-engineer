# Issue #220 — Roadmap 2026.3.1 Saha Geri Bildirimleri IV Hizalaması

## Amaç

25 Temmuz 2026 saha geri bildirimlerini [ROADMAP.md](../ROADMAP.md) içinde
kanonikleştirmek ve Release 0.1 pilotu ile Universal Capture arasına dar bir
**Release 0.1.1 Günlük Güvenilirlik / Sadeleştirme** sırası yerleştirmek.

Bu belge yalnız docs/governance kararıdır. Production Dart/Python kodu, schema,
migration, backup formatı, notification motoru, release artifact'i ve kullanıcı
verisi değişmez.

## Yetkili kaynaklar ve başlangıç gerçeği

Kaynaklar aşağıdaki otorite sırasıyla yorumlandı:

1. `AGENTS.md` ve kanonik proje protokolleri;
2. GitHub Issue #220 validation/scope contract'ı;
3. parent backlog #219 ve kanonik sıra düzeltme yorumu;
4. ürün Epic'i #105 ve execution Epic'i #127;
5. açık release gate #193;
6. önceki saha backlog'u #203;
7. PR #217 minimum yeterli doğrulama protokolü;
8. PR #218 `Yarın` görünümü.

Başlangıç noktası:

```text
master        = d4ccc480570a971cf014ddbe00122ec6132cad01
origin/master = d4ccc480570a971cf014ddbe00122ec6132cad01
divergence    = 0 0
```

Bu commit PR #218 squash merge'idir ve PR #217 protokolünü de içerir. #193 Gün 0
veri korunumu PASS kanıtı geçerlidir; yedi günlük pilot açık kalır.

## Release 0.1 ile Release 0.1.1 ayrımı

| Hat | Durum | Amaç | Bu branch'in etkisi |
|---|---|---|---|
| Release 0.1 / #193 | Açık pilot | Mevcut `0.1.0` çekirdeğini gerçek saha kullanımında kanıtlamak | Pilot kapanmaz, cihaz veya artifact işlemi yapılmaz |
| Release 0.1.1 | Yeni kanonik sıra | Günlük güvenilirlik, sadeleştirme ve kayıt bağlantısı sürtünmelerini kapatmak | Yalnız roadmap ve yönetişim belgeleri güncellenir |
| Release 0.2 / Faz 1 | Bekleyen production sırası | Universal Capture ve Assistant Inbox | Release 0.1.1 kapılarının arkasında korunur |

Release 0.1.1, pilotu geriye dönük olarak başarısız veya tamamlanmış saymaz.
Pilot sürerken bulunan ürün sürtünmelerini ayrı child Issue'lara böler.

## Kanonik Release 0.1.1 sırası

| Sıra | Dikey blok | Değişmez sözleşme |
|---:|---|---|
| 1 | Reminder scheduling contract | Hızlı `Bugün`; sahte saat olmayan gerçek `Tam gün`; legacy reminder `Bekliyorum` yüzeyinin kayıpsız kaldırılması |
| 2 | Birleşik ve sade Bugün | Geciken, saatli bugün ve tam gün birlikte; filtre önkoşulu yok; saatsiz iş için ayarlanabilir varsayılan `18:00` eşiği; doğru Bugün/Yarın etiketi |
| 3 | Reminder trash/restore | Recoverable archive/trash ve restore; ilk sürümde otomatik hard-delete yok |
| 4 | Ajanda → reminder attachment görünürlüğü | Kaynak Ajanda attachment'ı reminder detayından görünür; generic refactor öncesi dar read-model düzeltmesi |
| 5 | Beton sınıfı ve zaman çizgisi | Katalog; başlat/bitir; gerçek zamanlar; tek bağlı Ajanda logu; Beton source-of-truth |
| 6 | Beton keyword önerisi/deep-link | Yalnız öneri; otomatik Beton kaydı, paket veya teknik karar yok |
| 7 | Ortak attachment v2 | Tek fiziksel dosya + çoklu kayıt bağlantısı; çoklu fotoğraf/video/ses/dosya |
| 8 | Proje fotoğraf/video albümü | Kaynak bağlantısı korunur; duplicate fiziksel dosya yok |
| 9 | Taşeron/personel/Puantaj UX | #204 ile aynı kimlik omurgası; taşeron → personel seçimi ve inline kayıt |
| 10 | İstenecek Malzemeler | Basit ihtiyaç listesi; tam satın alma/ERP değil |
| 11 | Kaynaklı AI prompt export | Deterministik kaynaklı metin; embedded AI, otomatik gönderim ve sessiz mutation yok |
| 12 | Mini hesap makinesi | Temel işlem ve kontrollü sonuç aktarımı; ileri mühendislik hesabı değil |
| 13 | Hava durumu uyarıları | Haricî servis, konum, cache/offline fallback, eşik ve tercih tasarımından sonra; ertelenmiş |

İlk production child [Issue #221](https://github.com/faliardic/chief-site-engineer/issues/221)
Reminder scheduling contract'tır. Bu branch herhangi bir child implementation
başlatmaz.

## İçerik sözleşmeleri

### Reminder ve Bugün

- Reminder içindeki legacy `Bekliyorum` tür/schedule/status/filtre yüzeyi
  kaldırılır.
- Legacy kayıtlar kaybolmaz; sonraki implementation Issue'sunda normal aktif
  reminder'a kayıpsız dönüştürülür.
- Gelecekteki `Beklediklerim`, reminder status'ü değildir; Faz 2 Open Loop
  modelinde kişi/konu/takip geçmişi taşıyan ayrı kayıttır.
- `Tam gün`, 09:00 veya başka bir sahte saatle temsil edilmez.
- `Bugün` ana yüzeyi kullanıcının önce bir filtre seçmesini gerektirmez.
- Saatsiz bugünkü işin varsayılan gecikme eşiği `18:00` olur ve proje ayarıyla
  değiştirilebilir.

### Geri alınabilir kullanıcı işlemleri

- Kullanıcının “Sil” eylemi ilk aşamada recoverable archive/trash üretir.
- Restore bulunur; notification binding iptal ve yeniden üretim yaşam döngüsü
  child implementation'da açıkça tasarlanır.
- İlk sürüm otomatik hard-delete veya görünmez kalıcı temizlik yapmaz.

### Attachment bütünlüğü

- Ajanda → reminder kaynak bağı önce dar görünürlük düzeltmesiyle ele alınır.
- Ortak attachment v2 daha sonra geniş persistence/migration işi olarak ayrı
  doğrulanır.
- Aynı fiziksel dosya Ajanda, reminder, Beton ve albüm için tekrar kopyalanmaz.
- Tek attachment kaydı birden çok kayıt bağlantısı taşıyabilir.
- Hash, MIME, boyut, güvenli managed path, archive ve backup/restore zinciri
  korunur.

### Beton, AI ve hava durumu sınırı

- Beton sınıfı/zaman çizgisi gerçek Beton kaydından beslenir; tek bağlı Ajanda
  logu oluşturulur veya güncellenir, mükerrer log üretilmez.
- Beton kelime sinyali yalnız öneri ve deep-link üretir; teknik karar vermez.
- AI'nın ilk adımı kaynaklı prompt export'tur. Gömülü model, otomatik gönderim,
  kaynak göstermeyen rapor veya sessiz veri değişikliği yoktur.
- Hava durumu haricî servis, konum, cache/offline fallback, kullanıcı eşikleri
  ve notification tercihi tasarlanmadan production sırasına alınmaz.

## Hemen / sonraki / ertelenen / kapsam dışı

### Hemen

1. #193 pilotu mevcut kanıtla açık tutmak.
2. #221 Reminder scheduling contract.
3. Birleşik Bugün.
4. Reminder trash/restore.
5. Ajanda → reminder attachment görünürlüğü.
6. Beton sınıfı/zaman çizgisi ve keyword önerisi.

### Sonraki kontrollü sıra

1. Ortak attachment v2.
2. Proje fotoğraf/video albümü.
3. #204 taşeron/personel/Puantaj UX.
4. İstenecek Malzemeler.
5. Kaynaklı AI prompt export.
6. Mini hesap makinesi.
7. Ardından Universal Capture, Voice Capture/Assistant Inbox ve Open Loop.

### Ertelenen

- Hava durumu servisi ve proaktif uyarılar.
- Embedded/doğrudan AI.
- Tam satın alma/ERP.
- Gelişmiş video işleme ve otomatik medya analizi.
- Nihai ürün hedefi olan güvenli, salt-okunur gömülü DWG/Office/proje dokümanı
  viewer.
- İki yönlü PC sync.
- PDF metraj ve ileri mühendislik hesapları.

### Kapsam dışı / yasak

- Reminder `Bekliyorum` durumunu gelecekte yeniden canlandırmak.
- Otomatik hard-delete veya görünmez kayıt kapatma.
- Beton keyword'den otomatik Beton creation, paket veya teknik karar.
- Duplicate fiziksel attachment.
- Kaynaksız AI raporu veya kullanıcı onayı olmadan veri mutasyonu.
- Full ERP, multi-user/tenant/SaaS veya teknik kabul motoru.
- BIM/DWG/Office düzenleme, authoring veya teknik karar motoru.

## Faz geçişi

```text
Release 0.1 pilotu (#193, açık)
    |
    +-- Gün 0 PASS kanıtı korunur
    +-- yedi günlük saha kabulü kendi Issue'sunda sürer

Release 0.1.1 günlük güvenilirlik
    |
    +-- #221 Reminder scheduling contract
    +-- birleşik Bugün
    +-- recoverable trash
    +-- kaynak attachment görünürlüğü
    +-- Beton günlük akışı
    +-- ortak attachment ve saha araçları
    |
    `-- doğrulanmış child Issue kapıları
            |
            `-- Faz 1 Universal Capture
                    `-- Voice Capture / Assistant Inbox
                            `-- Faz 2 Open Loop
```

Hava durumu kanonik sırada son adaydır; dış servis ve eşik tasarımı nedeniyle
ertelenmiş kalması, Release 0.1.1'in diğer dar günlük güvenilirlik kapılarını
sessizce genişletmez.

## Validation contract

| Alan | Karar |
|---|---|
| Validation class | `docs` |
| Değişen sözleşme | Yalnız kanonik roadmap ve dokümantasyon sırası |
| Exact allowlist | `ROADMAP.md`, `CHANGELOG.md`, `docs/project_decisions.md`, bu belge ve eş learning belgesi |
| Opsiyonel dosya | Yalnız yeni kalıcı terim gerekirse `learning/GLOSSARY.md`; gerekmedi |
| İzinli kontroller | Changed-file allowlist, `git diff --check`, Markdown başlık/bağlantı/Issue referansı, production diff boşluğu |
| Çalıştırılmayanlar | Python/Flutter full suite, analyze, APK/AAB, signing, release gate, notification acceptance, backup/restore, fiziksel cihaz |
| Retry budget | 1 primary run; yalnız gerçek docs blocker varsa 1 correction run |
| Time budget | Hedef 30 dakika; hard stop 45 dakika |

## Yeniden kullanılan kanıt

- **Güvenli master:** `d4ccc480570a971cf014ddbe00122ec6132cad01`.
  Yalnız dokümantasyon sırası değiştiği için production davranış kanıtı geçerlidir.
- **#193 Gün 0 PASS:** mevcut Ajanda, Puantaj ve Beton kayıtları görünür; kullanıcı
  tarafından gözlenen veri kaybı `0`. Bu branch cihaz veya veriye dokunmaz.
- **PR #217:** docs validation class, evidence reuse, retry ve time budget
  sözleşmesinin kanonik kaynağıdır.
- **PR #218:** `Yarın` görünümünün merged davranış kanıtıdır. Bu branch reminder
  query/UI/notification davranışını değiştirmez.

## Kabul

- [x] #219 yorumundaki kanonik sıra ROADMAP içinde aynen görünür.
- [x] Release 0.1 pilotu ve Release 0.1.1 işleri ayrıdır.
- [x] İlk production child #221 Reminder scheduling contract'tır.
- [x] Universal Capture/Voice Capture/Open Loop sırası korunmuştur.
- [x] Yasaklar ve ertelenen alanlar görünürdür.
- [x] Production kodu, kullanıcı verisi ve release altyapısı kapsam dışındadır.
