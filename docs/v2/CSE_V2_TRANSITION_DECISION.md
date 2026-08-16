# CSE V1 → V2 Geçiş Kararı

**İlk karar tarihi:** 8 Ağustos 2026
**Güncel yön revizyonu:** 16 Ağustos 2026 / Issue #460
**Aktif ürün Epic'i:** GitHub Issue #385  
**Kanonik V2 kapsamı:** `docs/v2/CSE_V2_SCOPE.md`  
**Kanonik yürütme sırası:** `ROADMAP.md`

## 1. V1 durumu

CSE V1 tamamlanmış ürün fazıdır. Proje sahibi V1'in yaklaşık bir ay gerçek
şantiye kullanımında kullanıldığını bildirmiştir.

Bu karar şu iddiaları üretmez:

- Google Play veya App Store yayını yapılmıştır;
- GitHub Release oluşturulmuştur;
- geçmiş kullanım günlerinin her biri için geriye dönük test/evidence vardır;
- production-ready veya genel kullanıcı yayını tamamlanmıştır.

V1 tarihsel field-used baseline'ı:

```text
7c9f65a811c9f4bca561adab6bd1f8e64e6908cc
```

İlgili final V1 PR:

```text
#382 — Show real backup creation stages
```

Mobil metadata bu geçiş kararında değiştirilmez:

- uygulama sürümü: `0.1.0+1`
- SQLite schema: `10`
- `.csebackup` formatı: `1`
- canonical timezone: `Europe/Istanbul`

Bu değerler V1 tarihsel baseline metadata'sıdır. Güncel merged V2 teknik
baseline; mobile version `0.1.0+1`, SQLite schema `14`, backup format `1` ve
safe merge `447916be0b3ddd2af75b0fe85f8c7f710f29c1cd` değeridir.

## 2. V1 özelliklerinin durumu

V1'in tamamlanması mevcut özelliklerin dondurulması anlamına gelmez.

Ajanda, Hatırlatıcı, Puantaj, Beton Paketi ve Backup/Restore V2 içinde yaşamaya
ve geliştirilmeye devam eder. V1 yalnız tarihsel baseline'dır; V2 aynı ürünün
sonraki geliştirme fazıdır.

## 3. V2 truth-sync

V2 kapsamı ve repository kaynak otoritesi PR #384 ile master'a alınmıştır.

```text
V2 truth-sync merge:
78ad9245331398994ce0f47a5380d65a23189572
```

Bu merge:

- `docs/v2/CSE_V2_SCOPE.md` dosyasını kanonik current execution-scope yaptı;
- `ROADMAP.md` dosyasını 13 maddelik V2 sırasına taşıdı;
- root ve mobil README durumunu V1 field-use / V2 ayrımına hizaladı;
- Orchestrator, Bridge, Work Mode ve eski acceptance harness işlerini aktif
  ürün roadmap blocker'ı olmaktan çıkardı;
- new-chat ve Codex pre-read zincirini V2 kapsamıyla hizaladı.

Issue #460, bu ilk V2 transition kaydını silmeden current direction'ı sahibin
daha sonraki açık kararı ve merged schedule foundation ile eşitler. Items 1–4
complete'tir; PR #444/#446/#448/#456/#459 zinciri Living Plan için read-only
schedule runtime ve immutable persistent snapshot temelini sağlamıştır.

## 4. Aktif V2 paketi

V2 tam olarak şu 13 geliştirme ailesiyle ilerler:

1. Proje ve Mahal omurgası — complete
2. Sicil / Puantaj V2 / Saha Rehberi — complete
3. Attachment / Fotoğraf / Medya V2 — complete
4. Ajanda V2 + Ajanda–Hatırlatıcı kontrollü senkron — complete
5. 7 Günlük Yaşayan İş Programı / İş ve Gün Planı — current, not complete
6. Günlük Log Çıktısı v1
7. İş Zinciri / Bağlı Log v1
8. İstenecek Malzemeler
9. Deterministik kişi/firma/etiket önerileri
10. Telefon görüşmesi sonucu → Ajanda
11. Proje fotoğraf/video albümü
12. Günlük Log Çıktısı v2
13. Mini hesap makinesi

Kritik bağımlılık zinciri:

```text
Proje/Mahal
→ Saha Rehberi
→ Attachment v2
→ Ajanda v2
→ schedule runtime + persistent reference snapshots
→ 7 Günlük Yaşayan İş Programı
→ Günlük Log v1
→ İş Zinciri
→ Günlük Log v2
```

## 5. V2 dışı işler

Aşağıdakiler bu V2 paketine alınmamıştır; fikir veya tarihsel backlog olarak
korunabilir:

- Universal Capture ve Voice Capture
- Asistan Gelen Kutusu ve Open Loop
- Sabah Brifingi / Akşam Kapanışı
- Büyük Resim / Saha Nabzı
- Beton Paketi V2
- Kalite / İSG
- Doküman Hafızası
- kroki / spatial saha görünümü
- gömülü AI
- full-project Gantt editing / Primavera replacement
- approved/contractual baseline ve critical path/float
- resource optimization
- PC sync

Bunlar V2 item'larını bloke etmez.

Actual quantity/progress/reforecast ve project-specific productivity learning
yukarıdaki kategorik V2-dışı listede değildir. İlk usable UI/device pilotundan
sonraki Living Plan evolution'ı olarak current direction içinde kalır; MVP Core
veya ilk UI kapsamında değildir.

## 6. GitHub yürütme kararı

Aktif ürün yürütme Epic'i:

```text
#385 — CSE V2 Epic: 13 maddelik kanonik ürün paketi
```

Eski faz Epic'leri ve tooling blocker'ları current execution roadmap olmaktan
çıkarılmıştır. Tarihsel body, comment, PR ve commit kanıtları silinmez.

Aynı anda yalnız bir production implementation Issue aktiftir.

## 7. Sıradaki production yönü

Güncel canonical faz:

```text
truth-sync complete
→ Living 7-Day Plan MVP Core ready
```

CSE içeride binlerce inşaat aktivitesi ve deterministik bağımlılık taşıyabilir;
şantiye şefi aktiviteyi arayıp birkaç işlemle yakın plana ekler ve yalnız
önündeki yedi günü güncel tutar. Bu living site plan, Primavera klonu veya
approved/contractual baseline değildir.

UI'dan önce yalnız Living Plan'ın kullanıcı kararı/reference-schedule ayrımını,
stable referanslarını, minimum durumlarını ve offline persistence sınırını kuran
tek dar core slice açılabilir. Immediate successor 7-day UI + APK/device
acceptance olmalıdır. Progress/reforecast ve project-specific productivity
learning, gerçek veri üreten usable UI/device pilotundan sonraki Living Plan
evolution'ıdır; MVP Core veya ilk UI kapsamı değildir. Bu evrim bu kararla
başlatılmaz ya da tamamlanmaz ve Items 6–13 yeniden sıralanmaz. İlk UI tek
başına Item 5'i complete yapmaz; final completion sınırı sonraki owner kararı
ve executable evidence'a bağlıdır.

## 8. Kalıcı güvenlik sınırı

V2 geçişi şu V1 veri güvenliği ilkelerini değiştirmez:

- gerçek kullanıcı data root'u açık Issue yetkisi olmadan okunmaz/değiştirilmez;
- migration eski kayıtları sessizce kaybedemez;
- attachment bağlantıları korunur;
- backup compatibility ilgili persistence değişikliğinin kabul kapısıdır;
- append-only event ve optimistic revision sözleşmeleri korunur;
- kullanıcı onayı olmadan resmî karar, otomatik kapatma veya kapsam dönüşümü
  yapılmaz;
- her teknik iş değişen riske uygun minimum yeterli doğrulamayla yürütülür.
