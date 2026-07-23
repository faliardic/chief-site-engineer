# CSE Codex Repository Instructions

Bu dosya repository kökünde bütün Codex çalışmalarına uygulanır.

## Zorunlu ön okuma

Her plan, edit, test, build, cihaz işlemi, commit veya push öncesinde şu kaynakları sırayla oku:

1. `docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md`
2. `docs/protocols/CSE_PROJECT_INSTRUCTIONS.md`
3. `docs/protocols/CSE_MINIMUM_SUFFICIENT_VALIDATION_PROTOCOL.md`
4. current GitHub Issue ve bütün scope/izin yorumları
5. `.cse/tasks/<issue_no>_task.md` varsa

Yeni sohbet, handoff veya kaynak-otoritesi işinde ayrıca:

- `docs/protocols/CSE_NEW_CHAT_GITHUB_BOOTSTRAP.md`
- `docs/protocols/CSE_PROJECT_SOURCE_REGISTER.md`

okunur.

## Temel ürün ve geliştirme ilkeleri

- Gereksiz karmaşık yapı kurulmaz.
- Her adım küçük, anlaşılır, test edilebilir ve geri alınabilir olmalıdır.
- Framework, veritabanı veya servis bağımlılığı ancak ihtiyaç netleştiğinde eklenir.
- Kullanıcının ve önceki görevlerin değişiklikleri korunur.
- Kod okunabilir, sade ve proje standartlarına uygun yazılır.
- Yeni davranışlar için uygun seviyede test eklenir.
- Kullanıcıya dönük dokümanlar Türkçe; kod, modül ve fonksiyon adları sade İngilizce tutulur.
- Teknik kararlar `docs/project_decisions.md` içinde kısa maddelerle kaydedilir.
- Yeni teknik terimler gerekiyorsa learning dosyasında açıklanır; kalıcı terim `learning/GLOSSARY.md` içine eklenir.
- Learning belgesi yalnız kısa özet değildir: gerçek kod, çalışma akışı, test amacı, teknik karar ve “Şunu şöyle yaptık ki...” bölümü içerir.

## Ana yürütme kuralı

> Maksimum mümkün doğrulama değil, riski karşılayan minimum yeterli doğrulama uygulanır.

Güvenlik kapıları azaltılmaz; doğrulama yalnız değişen sözleşmeyle orantılı tutulur.

### Varsayılan doğrulama davranışı

- Dar UI, metin, filtre veya read-model değişikliğinde odaklı unit/widget testleri kullan.
- Production kodu değiştiyse etkilenen paket/suite çalıştır; bütün repository testini ancak risk veya Issue gerektiriyorsa ekle.
- Full mobile release gate, AAB/signing, ARM64/16 KiB, background/reboot acceptance, backup/restore veya fiziksel cihaz zincirini yalnız ilgili sözleşme değiştiyse ya da Issue açıkça zorunlu tuttuysa çalıştır.
- Değişmeyen sözleşmeler için son geçerli merged kanıtı yeniden kullan.
- Aynı source revision üzerinde aynı full gate'i ikinci kez çalıştırma.
- Ortam veya kabul otomasyonu hatasında tüm zinciri değil yalnız başarısız aşamayı tekrar et.
- Feature Issue içinde keşfedilen toolchain/release altyapısı sorununu sessizce düzeltme; ayrı Issue olarak raporla. Yalnız mevcut işi gerçekten bloke ediyorsa ve kullanıcı açıkça yetki verirse kapsama al.

## Bütçe ve stop kuralları

- Bir teknik adım: 1 primary Codex run.
- Blocking correction: en fazla 1 correction run.
- Aynı başarısız adım: en fazla 1 düzeltme denemesi.
- Dar UI/read-model işi hedefi 30 dakika, hard stop 45 dakikadır.
- 45 dakika sonunda tamamlanmadıysa yeni çözüm zinciri veya yeni full gate başlatma; exact blocker, tamamlanan kanıt ve kalan tek adımı raporla.
- Kaynak kod değişmeden full gate tekrar başlatılamaz.
- Test veya build kullanıcı mesajıyla kesildiyse yalnız kalan aşamayı sürdür; geçerli kanıtları sıfırdan üretme.

## Issue talimatı zorunlu alanları

Current Issue veya task dosyasında şu alanlar yoksa editten önce netleştir:

- validation class: `docs | narrow-ui | domain | persistence | release-critical`
- değişen sözleşmeler
- izin verilen test/build/gate listesi
- yeniden kullanılacak mevcut kanıtlar
- fiziksel cihaz kabulinin minimum kapsamı
- retry budget
- time budget
- açık kapsam dışı alanlar

## Fiziksel cihaz ilkesi

- Yalnız değişen kullanıcı yolunu doğrula.
- Uninstall, data clear, gerçek içerik okuma veya production package değişikliği current Issue açıkça izin vermedikçe yapılmaz.
- UI/read-model değişikliği backup, reboot veya notification motorunu değiştirmiyorsa bu kapıları yeniden çalıştırma.
- ADB otomasyonu kullanıcıya görünür sonucu kanıtlamak için minimum adımla sınırlı tutulur; koordinat/regex otomasyonu hata verirse bir kez düzelt, sonra kullanıcı ekran doğrulamasına dön.

## Completion evidence

Final rapor şunları açıkça ayırır:

- çalıştırılan odaklı testler;
- çalıştırılmayan geniş gate'ler ve neden gerekmediği;
- yeniden kullanılan merged kanıtlar;
- süre ve tekrar bütçesine uyum;
- kapsam dışı bırakılan altyapı sorunları;
- commit, push, PR ve merge durumu.

Bu kurallar `docs/protocols/CSE_MINIMUM_SUFFICIENT_VALIDATION_PROTOCOL.md` belgesinin kısa repository girişidir. Ayrıntıda o protokol bağlayıcıdır.
