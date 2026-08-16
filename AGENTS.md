# CSE Codex Repository Instructions

Bu dosya repository kökünde bütün CSE çalışmalarına uygulanır.

## Zorunlu ön okuma

Her plan, edit, test, build, cihaz işlemi, commit veya push öncesinde şu
kaynakları sırayla oku:

1. `docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md`
2. `docs/protocols/CSE_PROJECT_INSTRUCTIONS.md`
3. `docs/protocols/CSE_MODEL_REASONING_ROUTING_POLICY.md`
4. `docs/protocols/CSE_MINIMUM_SUFFICIENT_VALIDATION_PROTOCOL.md`
5. Ürün işi ise `docs/v2/CSE_V2_SCOPE.md`
6. `ROADMAP.md`
7. current GitHub Issue ve bütün scope/izin yorumları
8. `.cse/tasks/<issue_no>_task.md` varsa

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
- Model, reasoning, execution mode ve orchestration seçimi:
  `docs/protocols/CSE_MODEL_REASONING_ROUTING_POLICY.md`
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
- Framework, veritabanı veya servis bağımlılığı ancak ihtiyaç netleştiğinde
  eklenir.
- Kullanıcının ve önceki görevlerin değişiklikleri korunur.
- Kod okunabilir, sade ve proje standartlarına uygun yazılır.
- Production kodu değiştiyse uygun seviyede test eklenir.
- Kullanıcıya dönük dokümanlar Türkçe; kod, modül ve fonksiyon adları sade
  İngilizce tutulur.
- Teknik kararlar `docs/project_decisions.md` içinde kısa ve olgusal maddelerle
  kaydedilir.
- Gerçek kullanıcı data root'u current Issue açıkça izin vermedikçe okunmaz veya
  değiştirilmez.
- Offline-first, owner-only, append-only event, optimistic revision ve
  recoverable archive ilkeleri korunur.
- Kullanıcı onayı olmadan resmî karar, otomatik kapatma veya private→project
  dönüşümü yapılmaz.
- Yeni teknik terimler ilk geçtiği learning belgesinde açıklanır; kalıcı terim
  `learning/GLOSSARY.md` içine eklenir.
- Learning belgesi yalnız kısa özet değildir. Gerçek uygulama kodu, test amacı,
  çalışma akışı, teknik karar ve “Şunu şöyle yaptık ki...” açıklaması içerir.

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
- 45 dakika sonunda iş tamamlanmadıysa yeni çözüm zinciri veya yeni full gate
  başlatma; exact blocker, tamamlanan kanıt ve kalan tek adımı raporla.
- Kaynak kod değişmeden full gate tekrar başlatılmaz.
- Test veya build kesildiyse yalnız kalan aşama sürdürülür; geçerli kanıtlar
  sıfırlanmaz.
- P0 veri kaybı, yanlış bağlama veya backup bozulması yeni kapsamdan önce
  çözülür.

## Issue talimatı zorunlu alanları

Current Issue veya task dosyasında şu alanlar bulunmalıdır:

- V2 item ve parent Epic
- `CSE-MRP-1.0` policy version ve task risk (`R0..R4`)
- ChatGPT/orchestrator model ve reasoning seçimi
- Codex/executor model ve reasoning seçimi
- execution mode (`standard | pro`) ve orchestration (`single-agent | Ultra`)
- seçim nedeni, allowed fallback, review floor ve fail-closed-if-mismatch
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
- Koordinat veya selector otomasyonu hata verirse bir kez düzelt; ikinci aynı
  başarısızlıkta kör otomasyonu genişletme ve açık kullanıcı ekran doğrulamasına
  dön.

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
- `execution_record` YAML bloğu
- `review_recommendation` YAML bloğu

Runtime actual model veya reasoning görünmüyorsa tahmin edilmez;
`actual_model: unknown`, `actual_reasoning_effort: unknown`,
`mismatch_detected: null` ve `runtime_verification_status: unverified` yazılır.
`mismatch_detected: false` yalnız iki actual değer de görünür ve requested
değerlerle exact eşitse kullanılabilir.

## Güncel V2 yürütme özeti

Güncel ürün kapsamını `docs/v2/CSE_V2_SCOPE.md`, yürütme sırasını `ROADMAP.md`,
görev yetkisini current GitHub Issue ve tüm kapsam/izin yorumları, repository
gerçeğini current `master` belirler. Revised V2 paketi şudur:

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

Güncel güvenli teknik zemin `447916be0b3ddd2af75b0fe85f8c7f710f29c1cd`,
SQLite schema `14` ve backup format `1`dir. Living Plan UI/APK/device acceptance
henüz yoktur; Item 5 complete değildir. Issue #383 ve eski V2.1 ön kapısı
tarihsel repository truth-sync bağlamıdır; güncel işi yönlendiren aktif gate
değildir.
