# CSE Codex Repository Instructions

Bu dosya repository kökünde bütün CSE çalışmalarına uygulanır.

## Zorunlu ön okuma

Her plan, edit, test, build, cihaz işlemi, commit veya push öncesinde şu
kaynakları sırayla oku:

1. `docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md`
2. `docs/protocols/CSE_PROJECT_INSTRUCTIONS.md`
3. `docs/protocols/CSE_MINIMUM_SUFFICIENT_VALIDATION_PROTOCOL.md`
4. Ürün işi ise `docs/v2/CSE_V2_SCOPE.md`
5. `ROADMAP.md`
6. current GitHub Issue ve bütün scope/izin yorumları
7. `.cse/tasks/<issue_no>_task.md` varsa

Yeni sohbet, handoff veya kaynak-otoritesi işinde ayrıca:

- `docs/protocols/CSE_NEW_CHAT_GITHUB_BOOTSTRAP.md`
- `docs/protocols/CSE_PROJECT_SOURCE_REGISTER.md`

okunur.

## Kaynak otoritesi

- Kalıcı ürün amacı ve veri ilkeleri:
  `docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md`
- Güncel V2 kapsamı:
  `docs/v2/CSE_V2_SCOPE.md`
- Güncel yürütme sırası:
  `ROADMAP.md`
- Operasyon ve güvenlik:
  `docs/protocols/CSE_PROJECT_INSTRUCTIONS.md`
- Doğrulama genişliği ve bütçesi:
  `docs/protocols/CSE_MINIMUM_SUFFICIENT_VALIDATION_PROTOCOL.md`
- Aktif teknik kapsam:
  current GitHub Issue

Stale state, README, eski roadmap, Epic, Orchestrator, Bridge, Work Mode, ZIP,
handoff veya sohbet hafızası current GitHub ve V2 kapsam gerçeğini override
edemez.

## Temel ürün ve geliştirme ilkeleri

- Gereksiz karmaşık yapı kurulmaz.
- Her adım küçük, anlaşılır, test edilebilir ve geri alınabilir olmalıdır.
- Aynı anda yalnız bir production implementation Issue'su aktiftir.
- Her production Issue tek V2 maddesine ve dar değişen sözleşmeye bağlıdır.
- Kullanıcının ve önceki görevlerin değişiklikleri korunur.
- Production kodu değiştiyse uygun seviyede test eklenir.
- Gerçek kullanıcı data root'u current Issue açıkça izin vermedikçe okunmaz veya
  değiştirilmez.
- Offline-first, owner-only, append-only event, optimistic revision ve
  recoverable archive ilkeleri korunur.
- Kullanıcı onayı olmadan resmî karar, otomatik kapatma veya private→project
  dönüşümü yapılmaz.
- Yeni teknik terimler gerekiyorsa learning belgesinde açıklanır; kalıcı terim
  `learning/GLOSSARY.md` içine eklenir.

## Ana yürütme kuralı

> Maksimum mümkün doğrulama değil, riski karşılayan minimum yeterli doğrulama
> uygulanır.

Güvenlik kapıları azaltılmaz; doğrulama yalnız değişen sözleşmeyle orantılı
tutulur.

### Varsayılan doğrulama davranışı

- Dar UI, metin, filtre veya read-model değişikliğinde odaklı unit/widget
  testleri kullan.
- Production kodu değiştiyse etkilenen paket/suite'i çalıştır.
- Full mobile release gate, AAB/signing, ARM64/16 KiB, background/reboot,
  backup/restore veya fiziksel cihaz zincirini yalnız ilgili sözleşme değiştiyse
  ya da Issue açıkça zorunlu tuttuysa çalıştır.
- Değişmeyen sözleşmeler için son geçerli merged kanıtı yeniden kullan.
- Aynı source revision üzerinde aynı full gate'i ikinci kez çalıştırma.
- Ortam veya kabul otomasyonu hatasında tüm zinciri değil yalnız başarısız
  aşamayı tekrar et.
- Feature Issue içinde keşfedilen toolchain/release sorununu sessizce kapsamına
  alma; ayrı Issue olarak raporla.

## Bütçe ve stop kuralları

- Bir teknik adım: 1 primary execution.
- Blocking correction: en fazla 1 correction.
- Aynı başarısız aşama: en fazla 1 düzeltme denemesi.
- Dar UI/read-model işi hedefi 30 dakika, hard stop 45 dakikadır.
- Kaynak kod değişmeden full gate tekrar başlatılmaz.
- Test veya build kesildiyse yalnız kalan aşama sürdürülür; geçerli kanıtlar
  sıfırlanmaz.
- P0 veri kaybı, yanlış bağlama veya backup bozulması yeni kapsamdan önce
  çözülür.

## Issue talimatı zorunlu alanları

Current Issue veya task dosyasında şu alanlar bulunmalıdır:

- V2 item ve parent Epic
- validation class: `docs | narrow-ui | domain | persistence | release-critical`
- değişen sözleşmeler
- izin verilen dosya listesi
- focused testler
- izin verilen geniş gate'ler
- yeniden kullanılacak kanıtlar
- schema/migration/backup/attachment/notification etkisi
- minimum fiziksel cihaz kabulü
- retry budget
- time budget
- açık kapsam dışı alanlar
- stop conditions

## Yerel ve Git güvenliği

- Yeni teknik iş doğrudan `master` üzerinde geliştirilmez.
- Branch standardı:
  `codex/issue-<issue_no>-<slug>` veya documentation için
  `docs/issue-<issue_no>-<slug>`.
- Branch değişikliği, pull, edit, commit veya push öncesi tracked, staged,
  untracked ve ignored durum incelenir.
- Beklenmeyen kullanıcı değişikliği varsa reset, clean, stash, silme veya
  üzerine yazma yapılmaz.
- Force-push varsayılan yasaktır.
- Ignored ZIP, device backup, reports ve gerçek kullanıcı alanlarına dokunulmaz.
- Merge kullanıcı onayı gerektirir.
- Merge sonrasında sonraki işe başlamadan local `master` fast-forward edilir.

## Fiziksel cihaz ilkesi

- Yalnız değişen kullanıcı yolunu doğrula.
- Uninstall, data clear, gerçek içerik okuma veya production package mutation
  current Issue açıkça izin vermedikçe yapılmaz.
- UI/read-model değişikliği backup, reboot veya notification motorunu
  değiştirmiyorsa bu kapıları yeniden çalıştırma.
- ADB otomasyonu minimum, veri koruyan ve exact cihazla sınırlı olmalıdır.

## Completion evidence

Final rapor şunları açıkça ayırır:

- çalıştırılan focused testler
- çalıştırılmayan geniş gate'ler ve neden gerekmediği
- yeniden kullanılan merged kanıtlar
- schema/migration/backup/attachment/notification etkisi
- saha kabul sonucu
- süre ve tekrar bütçesi
- kapsam dışı altyapı sorunları
- commit, push, Draft PR, Ready ve merge durumu

Issue #383 truth-sync işi production davranışı değiştirmez. Bu iş merge
edilmeden V2.1 Proje ve Mahal implementation'ı başlatılmaz.
