# Issue #145 Sonuç Kaydı — Tek Hafıza ve Kayıt Kapsamı ADR'si

## Sonuç özeti

Kullanıcıya ayrı kişisel ve resmî uygulama dünyaları göstermeden bütün kayıt
türlerini tek **Hafıza** deneyiminde buluşturan; buna karşılık çıktı/paylaşım
güvenliği için `private | project` kapsamını koruyan bağlayıcı ADR hazırlandı.

Çalışma yalnız yetkili documentation/state/task/result dosyalarını değiştirdi.
Production Python, test, schema, migration, UI, template, CSS, requirements,
workflow, backup formatı, daily export formatı ve gerçek kullanıcı verisi
değiştirilmedi.

## Başlangıç repository kanıtı

- Resmî yerel yol: `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer`
- Doğrulanan repository root: `V:/1_PROJECTS/2_ACTIVE/Python/chief-site-engineer`
- Başlangıçta checkout edilmiş branch:
  `codex/issue-141-repository-truth-roadmap-sync`
- `origin/master` fetch sonrasında yerel `master` fast-forward edildi.
- Senkronize local `master`:
  `c449762cbcc5685017d3b2f2d0292a2b039cae53`
- Senkronize `origin/master`:
  `c449762cbcc5685017d3b2f2d0292a2b039cae53`
- Master divergence: `0 0`
- Issue branch'i: `codex/issue-145-single-memory-scope-adr`
- Base commit: `c449762cbcc5685017d3b2f2d0292a2b039cae53`
- Başlangıçta yalnız Issue tarafından korunması istenen untracked `reports/`
  vardı; beklenmeyen tracked veya staged proje değişikliği yoktu.

## Değişen yetkili dosyalar

- `docs/adr/ADR-0001-single-memory-and-record-scope.md`
- `learning/145_single_memory_and_record_scope_adr.md`
- `CHANGELOG.md`
- `ROADMAP.md`
- `docs/project_decisions.md`
- `.cse/state/project_state.json`
- `.cse/tasks/145_task.md`
- `.cse/results/145_result.md`

Yetki listesi dışında proje dosyası değiştirilmedi.

## Kabul edilen bağlayıcı kararlar

### Tek Hafıza

- Observation, follow-up, routine occurrence ve gelecekteki document, plan,
  package/calculation kayıtları ortak Hafıza, arama ve timeline yüzeylerinde
  bulunabilir.
- Kaynak domain tabloları ve yaşam döngüleri tek tabloya birleştirilmez.
- Kayıt türü badge'i, kapsam ve proje bağlantısından ayrı gösterilir.

### `private | project` kapsamı

- Kapsam erişim rolü, tenant, lifecycle status, kayıt türü veya encryption
  garantisi değildir.
- `private`, şefin çalışma hafızasıdır ve resmî/proje çıktısına doğrudan
  giremez.
- `project`, belirli projeye bağlı ve proje çıktısına seçilmeye uygun kayıttır;
  tek başına yayımlanmış veya onaylanmış anlamına gelmez.
- Project bağlantısı, observation link'i, AI, routine işlemi veya read-model
  rebuild kapsamı sessizce değiştiremez.

### Başlangıç/backfill mapping'i

- Mevcut observation kayıtları: `project`.
- Mevcut follow-up kayıtları: `private`.
- Mevcut routine template kayıtları: `private`.
- Mevcut routine occurrence kayıtları: `private`.
- Observation'a bağlı veya `converted_to_observation` sonuçlu eski follow-up da
  private kalır; hedef observation ayrı project kaydıdır.
- Gelecekte routine occurrence, üretim anındaki template kapsamını snapshot
  eder; template dönüşümü geçmiş occurrence'ları yeniden yazmaz.

### Kapsam dönüşümü

- `private -> project` yalnız açık kullanıcı işlemi, zorunlu project bağlantısı,
  güncel revision ve aynı transaction'daki append-only event ile mümkündür.
- Observation, project document/plan/work package ve yayımlanmış çıktı
  snapshot'ları `project -> private` olamaz.
- Follow-up/routine/note/calculation gibi çalışma kayıtları yalnız daha önce
  çıktı/reference olmadığının güvenilir kanıtı ve açık kullanıcı onayı varsa
  private'a dönebilir.
- Bu kanıt üretilemiyorsa işlem fail-closed reddedilir.

### Çıktılar

- Backup felaket kurtarma için bütün private/project veriyi, event geçmişini ve
  attachment'ları içerir.
- Hafızayı İndir bütün hafızayı kayıt türü, kapsam ve project bağlantısı açıkça
  belirtilmiş kişisel arşiv olarak içerir.
- Proje Paketi, günlük ve rapor yalnız seçilen projenin project kapsamlı
  kayıtlarını alır.
- Private kayıt doğrudan resmî/proje çıktısına seçilemez; önce ayrı kapsam
  dönüşümü gerekir.
- Mevcut daily export observation hattı ve tracking izolasyonu değiştirilmedi.

## Yerel doğrulama

- `CSE_DATA_ROOT`: `UNSET`
- `python -m pytest -rs`: `983 passed, 7 skipped in 27.20s`
- Yedi skip: Windows ortamında symlink oluşturma ayrıcalığı bulunmayan mevcut
  attachment güvenlik testleri
- `python -m compileall -q app scripts`: `PASS`
- `python -m json.tool .cse/state/project_state.json > $null`: `PASS`
- `git diff --check`: `PASS`
- `git diff -- app tests requirements.txt pyproject.toml .github/workflows/pytest.yml`:
  boş
- Schema sürümü: `4` (değişmedi)
- Backup format sürümü: `1` (değişmedi)
- Günlük export format sürümü: `1` (değişmedi)

## Korunan yollar ve çıktılar

- `reports/`: untracked kullanıcı dosyaları olarak korundu; okunmadı,
  değiştirilmedi ve stage edilmedi.
- Ignored ZIP: `chief-site-engineer_adim_080_guvenli_nokta.zip` mevcut,
  `326209` byte; değiştirilmedi ve stage edilmedi.
- Ignored cache dosyaları korundu.
- `exports/`: yalnız `.gitkeep` içeriyor.
- Gerçek kullanıcı data root'una erişilmedi.

## Uygulanmayan alanlar

- Scope enum/field, schema, migration veya backfill uygulanmadı.
- Repository/application service ve scope event vocabulary eklenmedi.
- MemoryIndex / RecordRef, Hafıza UI, template veya CSS uygulanmadı.
- Backup, Hafızayı İndir, Proje Paketi veya daily export formatı değiştirilmedi.
- Auth, role, tenant, app lock, encryption veya AI mutation eklenmedi.

## Git ve yayın durumu

Bu result dosyası commit öncesinde olgusal olarak hazırlandı:

- Commit: henüz oluşturulmadı.
- Push: henüz yapılmadı.
- Remote branch divergence: push sonrasında Issue #145 completion comment'inde
  kaydedilecek.
- Pull request: oluşturulmadı; Codex PR açmayacak.
- Merge: yapılmadı ve merge iddiası yok.

Final branch SHA, normal push sonucu ve remote divergence; metadata churn
oluşturmamak için Issue #145 completion evidence yorumunda tutulacaktır.

## Sonraki dar adım

Branch normal push ile yayımlandıktan ve GitHub incelemesi tamamlandıktan sonra
Draft PR akışı ChatGPT/GitHub sorumluluğunda ilerletilir. Faz 0 sırası
`MemoryIndex` / `RecordRef` read-model ADR'si ve ardından Backup / Hafızayı
İndir / Proje Paketi ayrım ADR'si ile devam eder.
