# CSE ChatGPT Kaynak Değiştirme Kaydı

**Sürüm:** 2026-07-17.1  
**Amaç:** ChatGPT proje kaynaklarındaki eski ve çelişen CSE belgelerini temiz bir current-source
setiyle değiştirmek.

---

## 1. Önerilen aktif kaynak seti

ChatGPT projesinde aktif ve bağlayıcı kaynak olarak yalnız şu dört yeni Markdown dosyasını kullanın:

1. `01_CSE_CHATGPT_KANONIK_BAGLAM_2026-07-17.md`
2. `02_CSE_UYGULANABILIR_YOL_HARITASI_2026_2.md`
3. `03_CSE_CHATGPT_KAYNAK_DEGISTIRME_KAYDI.md`
4. `04_ISSUE_141_VE_PR_142_DURUM_KANITI.md`

Bunlar güncel GitHub truth, uygulanmış/planlanmış ayrımı, 193 adımlı roadmap ve kaynak
otoritesini birlikte taşır.

---

## 2. Mevcut yüklemeler için karar

| Mevcut dosya | Karar | Gerekçe |
|---|---|---|
| `CHIEF_SITE_ENGINEER_EXE_BIRLESTIRILMIS_PROJE_KAYNAGI(1).md` | Aktif kaynaklardan çıkar | 11 Temmuz snapshot'ıdır; eski kullanıcı/rol/özel alan/handover ve eski safe-point bilgileri taşır. Güncel tracked kaynak 16 Temmuz ve sonrası GitHub gerçeğidir. |
| `CSE_STRATEGIC_PRODUCT_DIRECTION.md` | Aktif kaynaklardan çıkar | Stratejik fikirlerin çoğu yeni kanonik bağlama işlendi; hedef kullanıcı ve saha MVP dili güncellendi. |
| `1. CSE önce güvenilir veri omurgası.txt` | Aktif kaynaklardan çıkar veya yalnız tarihsel tut | Değişmez ilkeler entegre edildi; çok kullanıcılı devir/özel alan maddeleri current tek-sahipli ürün kararıyla birlikte yeniden yorumlandı. |
| `CSE_CHAT_HANDOFF_PROTOCOL_SOURCE_PACKAGE.zip` | Aktif kaynaklardan çıkar | Haziran tarihli handoff snapshot'ı; GitHub-native continuation ve current Issue düzeninin yerine geçemez. ZIP içerikleri kaynak parser'ında da güvenilir current truth değildir. |
| `CSE derin mevcut durum araştırması.pdf` | Aktif current kaynaklardan çıkar; yerel arşivde tut | Değerli 17 Temmuz denetimidir fakat bazı hükümleri öneridir: kişisel/resmî ayrımın tamamen kaldırılması, ZIP eşliği ve o andaki repo snapshot'ı current karar değildir. Önerileri #127 programına işlendi. |
| `Şantiye Şefi İçin Dünya Örneklerine Dayalı Kontrol, Takip ve Arşivleme Sistemi Yol Haritası.pdf` | İsteğe bağlı tarihsel araştırma | Ürün araştırması olarak değerlidir; current status veya uygulama sırası değildir. Aktif kaynakta tutulacaksa yeni kanonik dosyaların altında önceliğe sahiptir. |
| `CHIEF_SITE_ENGINEER_Guncel_Yol_Haritasi_Ozel_Alan_Ekli.pdf` | İsteğe bağlı tarihsel araştırma | Uzun vadeli modül fikirleri içerir; multi-user/özel alan/devir kararları current ürün yönünü yönetmez. |

En temiz kurulum, eski yedi yüklemeyi ChatGPT projesinden kaldırıp yalnız yeni dört Markdown
dosyasını yüklemektir. Araştırma PDF'leri yerel arşivde korunabilir.

---

## 3. Bilinen çelişkilerin kesin çözümü

### Kişisel takip / resmî gözlem

Eski rapor “ayrımı kaldır” der. Güncel çözüm:

```text
Tek Hafıza kullanıcı deneyimi
+ kaynak tabloların korunması
+ private | project çıktı kapsamı
+ açık kullanıcı işlemiyle kapsam dönüşümü
+ ortak MemoryIndex / RecordRef read-model
```

Bu karar henüz ADR ve production implementation olarak tamamlanmamıştır.

### Çoklu kullanıcı, rol, tenant ve SaaS

Eski yol haritalarındaki bu hedefler current ürün kapsamı değildir. CSE yalnız şantiye şefinin
single-owner kişisel saha asistanıdır.

### Devir / handover

Handover başlı başına kurumsal ürün modülü değildir. İlerideki `Proje Paketi`, yalnız seçili project
scope için kontrollü paylaşım/devir çıktısıdır. `Hafızayı İndir` ve `Backup` ayrı kalır.

### Mevcut ürün seviyesi

Eski kaynaklarda persistence, UI veya Saha Takibi eksik yazabilir. Current master bunları içerir.
Buna karşılık mobile/offline/notification/app-lock/plan/package/metraj/AI hâlâ uygulanmamıştır.

### Güncel safe point

- Merged safe point: `1d4b2b7...`
- Issue #141 branch: `ac2942b...`
- Draft PR: `#142`
- PR merge edilmeden `ac2942b...` merged safe point değildir.

### State dosyasındaki pre-commit metadata

`.cse/state/project_state.json` ve `.cse/results/141_result.md` içinde commit/push öncesi olgusal
ifadeler bulunabilir. Metadata churn yasağı nedeniyle final branch SHA ve push sonucu Issue #141
completion comment'inde tutulmuştur. Bu durumda GitHub completion evidence üstündür.

---

## 4. ChatGPT kaynak güncelleme işlemi

1. Eski aktif kaynakları ChatGPT proje kaynaklarından kaldırın.
2. Bu paketi açın.
3. `00_READ_ME_FIRST.md` dosyasını kullanıcı rehberi olarak saklayın.
4. `01`–`04` Markdown dosyalarını ayrı ayrı ChatGPT proje kaynaklarına yükleyin.
5. Kaynak testinde şu soruları sorun:
   - Son merged safe point nedir?
   - Issue #141 merge edildi mi?
   - Şu anda çalışan özellikler hangileri?
   - Private/project ayrımı kaldırıldı mı?
   - Faz 6 başlamış mıdır?
6. Beklenen yanıtlar:
   - Safe point `1d4b2b7...`
   - Issue #141 tamamlanmış branch'tir; PR #142 açık ve unmerged
   - PC Saha Takibi çalışır
   - Private/project kapsamı mevcut davranışta korunur; tek Hafıza ADR'si backlog'dur
   - Faz 6 başlamamıştır

---

## 5. Merge sonrası bakım

PR #142 squash merge edilince:

- merged commit SHA belirlenir;
- `01_CSE_CHATGPT_KANONIK_BAGLAM_2026-07-17.md` içindeki safe point güncellenir;
- `04_ISSUE_141_VE_PR_142_DURUM_KANITI.md` merged duruma çevrilir;
- Issue #141 kapatılır;
- Faz 0'dan seçilen yeni tek aktif Issue kaynaklara eklenir.

Bütün 193 adımlı roadmap dosyasını yalnız phase kapsamı değişirse yeniden üretmek gerekir.
