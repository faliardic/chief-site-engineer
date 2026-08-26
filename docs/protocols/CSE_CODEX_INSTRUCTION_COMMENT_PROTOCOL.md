# CSE Codex Instruction Comment Protocol

**Belge türü:** Kalıcı execution handoff / GitHub comment standardı  
**Geçerlilik tarihi:** 2026-08-26  
**Kapsam:** ChatGPT → Codex execution, correction, review ve resume handoff'ları

Bu belge, CSE geliştirmesinde Codex'e verilecek çalışma talimatlarının yalnız sohbet içinde bırakılmamasını; ilgili GitHub Issue veya PR üzerinde kalıcı, self-contained ve yeniden bulunabilir bir comment olarak yayımlanmasını zorunlu kılar.

## 1. Ana kural

Codex'e yeni bir execution, correction, review veya resume işi verilecekse ChatGPT varsayılan olarak:

1. current GitHub repository truth'u doğrular;
2. gerekli Issue/PR, branch, HEAD, diff, review ve authority kayıtlarını okur;
3. Codex'in çalışacağı eksiksiz talimatı ilgili GitHub Issue veya PR conversation'a tek bir açık comment olarak yazar;
4. comment oluşturulduktan sonra kullanıcıya yalnız comment referans bilgisini verir:
   - Issue/PR numarası;
   - comment ID;
   - doğrudan comment linki;
   - gerekirse tek satırlık `Issue #... comment ...'i uygula` yönlendirmesi.

Uzun Codex talimatının yalnız chat mesajında bırakılması normal çalışma biçimi değildir.

## 2. Canonical handoff yüzeyi

Execution/correction authority için tercih edilen yüzey current feature/correction **Issue**'sudur.

Bağımsız source/diff review sonucu, review blocker'ı veya PR-specific değerlendirme **PR review/comment** yüzeyinde tutulabilir. Ancak bu review yeni bir source correction execution gerektiriyorsa correction authority ve Codex execution instruction current Issue üzerinde kalıcı comment olarak yayımlanır.

GitHub comment bir handoff yüzeyidir; tracked ürün/policy belgelerinin veya Issue body'deki kalıcı scope'un yerine geçmez. Comment, bu kaynaklara referans verir ve current execution için onları somutlaştırır.

## 3. Comment yayımlanmadan önce zorunlu doğrulama

ChatGPT talimat comment'ini hazırlamadan hemen önce en az şunları doğrular:

- current `master` / expected base SHA;
- active Issue ve parent item;
- açık PR ve Draft/Ready/merge durumu;
- exact branch ve current HEAD;
- relevant review blocker veya owner authority comment'leri;
- current changed-path allowlist;
- schema / migration / backup / version / permission gibi değişen sözleşmeler;
- automated validation ve manual test authority;
- Manual Test Register #479 durumu, ilgiliyse;
- Ready/merge/Issue closure yetkisi.

Stale sohbet metni, eski handoff veya önceki HEAD değeri current GitHub gerçeğini override edemez.

## 4. Codex instruction comment zorunlu içeriği

Comment mümkün olduğunca self-contained olmalı ve göreve göre aşağıdaki başlıkları taşımalıdır:

### A. Authority ve başlangıç durumu

- Issue / PR numarası
- owner authority veya review blocker comment ID'leri
- expected base
- exact branch
- expected current HEAD
- Draft/Ready/merge durumu

### B. Okunacak kaynaklar ve sıra

Codex'e hangi GitHub Issue/PR/comment ve tracked dosyaları hangi sırayla okuyacağı açıkça yazılır.

### C. Amaç veya blocker

Teknik hedef kısa ve kesin biçimde yazılır. Correction ise düzeltilen exact invariant / bug belirtilir.

### D. Exact allowlist

- production paths
- evidence paths
- yalnız gerekiyorsa kullanılabilecek conditional paths

Allowlist dışında dosya gerekiyorsa stop-and-report şartı açıkça yazılır.

### E. Required behavior

İş tamamlandığında hangi davranışın doğru olması gerektiği net biçimde tanımlanır.

### F. Değişmemesi gereken contractlar

Göreve uygun olarak örneğin:

- schema
- migration sınıfı
- backup format
- app version
- pubspec/lock
- platform/permission
- stable identity
- transaction/event/history
- Reminder/notification
- V2 item sınırı

korunacak değerler açıkça yazılır.

### G. Validation / test / build authority

Tam olarak hangi komutların çalıştırılabileceği ve hangilerinin yasak olduğu yazılır.

Örnek ayrım:

- format
- `flutter analyze --no-pub`
- `git diff --check`
- source audit
- unit/widget/integration/full tests
- APK/AAB
- emulator/ADB/device

Sayı veya retry budget varsa exact yazılır.

### H. Stop conditions

Örneğin:

- analyzer fail
- allowlist expansion
- schema redesign ihtiyacı
- platform permission ihtiyacı
- destructive işlem
- source truth belirsizliği

olursa Codex'in kendi kendine kapsam genişletmeden duracağı belirtilir.

### I. Publication / merge sınırı

Talimat açıkça şunları sınıflandırır:

- commit yetkisi
- push yetkisi
- Draft PR
- Ready
- merge
- Issue closure
- next V2 item
- release/store

Owner açıkça yetki vermedikçe Ready/merge otomatik yapılmaz.

### J. Final evidence beklentisi

Final Codex çıktısında en az:

- final commit SHA
- changed paths
- validation sonuçları
- schema/backup/version/platform etkisi
- branch/PR durumu
- manual test durumu
- Ready/merge durumu
- `execution_record`
- `review_recommendation`

istenir.

## 5. Kullanıcıya verilecek kısa cevap

Comment başarıyla oluşturulduktan sonra ChatGPT kullanıcıya uzun promptu yeniden yapıştırmak yerine kısa referans verir.

Örnek:

```text
GitHub comment hazır.

Issue: #492
Comment ID: 5427823948
Link: <direct comment link>

Codex'e: “Issue #492 comment 5427823948'i uygula.”
```

Kullanıcı özellikle tam comment içeriğini isterse ayrıca gösterilebilir.

## 6. Fresh-chat davranışı

Yeni bir CSE sohbetinde kullanıcı yalnız:

```text
devam
```

veya:

```text
GitHub'dan devam et
```

yazdığında ChatGPT:

1. `CSE_NEW_CHAT_GITHUB_BOOTSTRAP.md` okuma sırasını uygular;
2. bu `CSE_CODEX_INSTRUCTION_COMMENT_PROTOCOL.md` belgesini zorunlu kaynak olarak okur;
3. current master / Issue / PR / branch / review / Manual Test Register durumunu GitHub'dan çözer;
4. Codex'in sıradaki execution'ı gerekiyorsa talimatı **önce GitHub comment olarak yayımlar**;
5. kullanıcıya comment ID ve link bilgisini verir.

Kullanıcıdan eski uzun promptu, completion bloğunu veya önceki sohbet handoff'unu yeniden taşıması istenmez.

## 7. `Codex nereye bakacak?` ve benzeri istekler

Kullanıcı:

- `Codex nereye bakacak?`
- `Codex'e talimat hazırla`
- `devam et`
- `correction ver`
- `sıradaki işi Codex'e ver`

ve benzeri bir execution handoff istediğinde, current GitHub context yeterliyse varsayılan çıktı **chat-only prompt değil GitHub comment** olmalıdır.

ChatGPT comment'i kendisi oluşturabiliyorsa kullanıcıya kopyala-yapıştır yükü bırakmaz.

## 8. GitHub write kullanılamıyorsa

GitHub comment oluşturma işlemi gerçekten kullanılamıyor veya başarısız oluyorsa ChatGPT:

- comment'in oluşturulduğunu iddia etmez;
- failure'ı açıkça belirtir;
- gerekirse geçici chat taslağını verir;
- sonraki fırsatta GitHub'a persist edilmesi gerektiğini belirtir.

Chat-only taslak kalıcı canonical handoff sayılmaz.

## 9. Correction ve re-review zinciri

Bağımsız review blocker bulursa normal sıra:

```text
independent review
→ blocker evidence
→ owner/correction authority
→ GitHub Codex instruction comment
→ Codex narrow correction
→ source gates
→ correction commit/push
→ independent re-review
→ owner Ready/merge kararı
```

Blocker çözülmeden veya gerekli gate PASS olmadan ChatGPT Ready/merge'e atlamaz.

## 10. Manuel test durumu

Manual testler `PENDING` veya `DEFERRED` ise comment bunu exact durumuyla taşır. Test yapılmadıysa `PASS` yazılmaz.

Owner `devam` diyerek testleri ertelemişse execution comment:

```text
manual_test_status: DEFERRED
```

olarak taşıyabilir; bu source blocker veya correction gate'ini otomatik kaldırmaz.

## 11. Güvenlik

Bu comment standardı mevcut CSE güvenlik sınırlarını genişletmez.

Özellikle:

- direct master technical edit yok;
- force-push yok;
- destructive data operation yok;
- allowlist expansion self-authorized değil;
- schema/backup/version/permission değişikliği ayrı açık authority ister;
- Ready/merge/release/store owner authority ister.

## 12. Başarı ölçütü

Her Codex handoff için hedef:

```text
chat-only long instruction: 0
GitHub-persisted execution comment: 1
comment ID/link returned to owner: 1
fresh-chat rediscovery without pasted handoff: yes
stale HEAD/base silently reused: 0
unauthorized Ready/merge: 0
```

## 13. Ana cümle

> CSE'de Codex'e verilecek yürütme talimatı sohbet içinde kaybolmaz. ChatGPT current GitHub gerçeğini doğrular, eksiksiz instruction'ı ilgili Issue/PR'a comment olarak yazar ve kullanıcıya yalnız comment referansını verir; yeni sohbet de aynı standardı GitHub'dan yeniden öğrenir.
