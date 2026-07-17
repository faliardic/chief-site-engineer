# CSE ChatGPT Kaynak Değiştirme Kaydı

**Sürüm:** 2026-07-17.2  
**Karar:** CSE kaynakları yalnız GitHub repository içinde tutulur; ChatGPT proje kaynakları panelinde dosya saklanmaz.

---

## 1. Yeni kaynak modeli

Bundan sonra ChatGPT CSE bağlamını GitHub üzerinden okur. Kaynak sırası:

1. GitHub `master`, açık/merged PR, Issue ve branch kanıtı
2. O anda tek aktif GitHub Issue
3. `docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md`
4. `docs/protocols/CSE_PROJECT_INSTRUCTIONS.md`
5. `.cse/state/project_state.json` ve ilgili task/result kayıtları
6. `README.md`, `ROADMAP.md`, `CHANGELOG.md`, `docs/project_decisions.md`
7. `docs/chatgpt_sources/` altındaki tarihli bağlam ve yönlendirme kaynakları
8. Tarihsel PDF, ZIP ve eski belgeler

`docs/chatgpt_sources/` dosyaları GitHub current truth’un yerine geçmez; ChatGPT’nin hızlı başlangıç ve kaynak çözümleme katmanıdır.

---

## 2. ChatGPT proje kaynaklarından silinecek dosyalar

Aşağıdaki yüklemeler ChatGPT proje kaynakları panelinden kaldırılır:

- `CHIEF_SITE_ENGINEER_EXE_BIRLESTIRILMIS_PROJE_KAYNAGI(1).md`
- `CSE_STRATEGIC_PRODUCT_DIRECTION.md`
- `1. CSE önce güvenilir veri omurgası.txt`
- `CSE_CHAT_HANDOFF_PROTOCOL_SOURCE_PACKAGE.zip`
- `CSE derin mevcut durum araştırması.pdf`
- `Şantiye Şefi İçin Dünya Örneklerine Dayalı Kontrol, Takip ve Arşivleme Sistemi Yol Haritası.pdf`
- `CHIEF_SITE_ENGINEER_Guncel_Yol_Haritasi_Ozel_Alan_Ekli.pdf`
- Geçici `CSE_CHATGPT_SOURCE_UPDATE_2026-07-17` Markdown/JSON/TXT/ZIP dosyaları

Bu dosyaların yerel arşivde tutulması mümkündür; ChatGPT current source olarak kullanılmazlar.

---

## 3. Bilinen çelişkilerin çözümü

### Kişisel takip / resmî gözlem

Güncel yön:

```text
Tek Hafıza kullanıcı deneyimi
+ kaynak tabloların korunması
+ private | project çıktı kapsamı
+ açık kullanıcı işlemiyle kapsam dönüşümü
+ ortak MemoryIndex / RecordRef read-model
```

Bu karar ADR ve production implementation tamamlanana kadar mevcut davranışı sessizce değiştirmez.

### Çoklu kullanıcı, rol, tenant ve SaaS

Current ürün kapsamı değildir. CSE yalnız şantiye şefinin single-owner kişisel saha asistanıdır.

### Backup / Hafızayı İndir / Proje Paketi

Üç ayrı çıktı sözleşmesidir:

- Backup: felaket kurtarma
- Hafızayı İndir: bütün kişisel hafızanın insan okunur ve doğrulanabilir arşivi
- Proje Paketi: seçili proje/project scope için paylaşım çıktısı

### Güncel güvenli nokta

Bu snapshot hazırlanırken:

- merged safe point `1d4b2b7...` idi;
- Issue #141 branch commit’i `ac2942b...` idi;
- Draft PR #142 açık ve merge edilmemişti.

Değişken durum için current GitHub PR/Issue/master kanıtı her zaman üstündür.

---

## 4. GitHub kaynak bakım kuralı

- Yeni kaynak dosyası doğrudan `master` üzerine yazılmaz.
- Ayrı dar Issue ve branch kullanılır.
- Mevcut açık PR’ın kapsamı sonradan genişletilmez.
- Kaynak güncellemesi production davranışı değiştirmiyorsa dokümantasyon-only olarak açıkça belirtilir.
- Merge edilmemiş branch current merged safe point olarak gösterilmez.
- Aynı bilginin çok sayıda kopyası oluşturulmaz; ayrıntılı roadmap için GitHub Issue #127 ve #128–#140 kayıtları kanoniktir.
- Tarihli bağlam dosyaları stale olduğunda silinmek zorunda değildir; üstlerine yeni tarihli snapshot eklenebilir ve current index güncellenebilir.

---

## 5. Yeni sohbet başlangıcı

Yeni bir CSE sohbetinde ChatGPT:

1. Repository `master` ve açık PR’ları doğrular.
2. Tek aktif Issue’yu belirler.
3. Kanonik protokol dosyalarını okur.
4. Gerekirse en yeni `docs/chatgpt_sources/` tarihli snapshot’ını kullanır.
5. Eski ChatGPT yüklemelerine veya ZIP snapshot’larına dayanmaz.
