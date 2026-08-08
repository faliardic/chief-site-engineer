# CSE V1 → V2 Geçiş Kararı

**Karar tarihi:** 8 Ağustos 2026  
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

## 4. Aktif V2 paketi

V2 tam olarak şu 13 geliştirme ailesiyle ilerler:

1. Proje ve Mahal omurgası
2. Sicil / Puantaj V2 / Saha Rehberi
3. Attachment / Fotoğraf / Medya V2
4. Ajanda V2 + Ajanda–Hatırlatıcı kontrollü senkron
5. Günlük Log Çıktısı v1
6. İş / Yapılacaklar / Gün Planı
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
→ İş/Yapılacak
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
- Look-ahead / WBS
- PC sync

Bunlar V2 item'larını bloke etmez.

## 6. GitHub yürütme kararı

Aktif ürün yürütme Epic'i:

```text
#385 — CSE V2 Epic: 13 maddelik kanonik ürün paketi
```

Eski faz Epic'leri ve tooling blocker'ları current execution roadmap olmaktan
çıkarılmıştır. Tarihsel body, comment, PR ve commit kanıtları silinmez.

Aynı anda yalnız bir production implementation Issue aktiftir.

## 7. Sıradaki production yönü

V2'nin ilk production geliştirmesi:

```text
V2.1 — Proje ve Mahal omurgası
```

V2.1 önce stable proje/mahal kimliği, migration/compatibility ve mevcut V1
kayıtlarının korunma sınırını kurmalıdır. V2.2 veya sonraki ortak bağlam
özellikleri bu temel kurulmadan production implementation'a başlamaz.

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
