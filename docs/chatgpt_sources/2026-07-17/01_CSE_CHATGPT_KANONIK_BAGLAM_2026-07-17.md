# CSE — ChatGPT İçin Kanonik Güncel Bağlam

**Belge türü:** ChatGPT proje kaynağı / güncel bağlam katmanı  
**Sürüm:** 2026-07-17.1  
**Durum:** Issue #141 tamamlanmış branch ve açık Draft PR #142 gerçeğini yansıtır  
**Repository:** `faliardic/chief-site-engineer`

---

## 1. Kaynak otoritesi

CSE hakkında karar verirken aşağıdaki sıra uygulanır:

1. GitHub `master`, açık/merged PR, Issue ve branch kanıtı
2. `docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md`
3. `docs/protocols/CSE_PROJECT_INSTRUCTIONS.md`
4. O anda tek aktif olan GitHub Issue
5. `.cse/state/project_state.json` ve ilgili `.cse/results/*`
6. `README.md`, `ROADMAP.md`, `CHANGELOG.md`, `docs/project_decisions.md`
7. Tarihsel PDF, ZIP, eski strateji ve handoff kaynakları

GitHub gerçeğiyle çelişen eski yükleme, README snapshot'ı, ZIP veya handoff metni current truth
olarak kullanılamaz.

---

## 2. Güncel repository gerçeği

```text
Repository: faliardic/chief-site-engineer
Default branch: master

Son merged güvenli nokta:
Issue #119
PR #126
Merge commit: 1d4b2b7f9ace5e7d474c4893d24404ceae2faede

Tamamlanmış fakat henüz merge edilmemiş çalışma:
Issue #141
Branch: codex/issue-141-repository-truth-roadmap-sync
Branch commit: ac2942b693e95e0f41a8fa02b76dcd0b31de0aba
Draft PR: #142
PR durumu: open / draft / unmerged

Doğrulama:
983 passed, 7 skipped
compileall: PASS
state JSON: PASS
git diff --check: PASS
production/test/requirements/workflow diff: boş
schema version: 4
backup format version: 1
daily export format version: 1
```

Issue #141 yalnız repository truth, roadmap ve state senkronizasyonudur. Production davranışı
değiştirmemiştir. PR #142 merge edilene kadar merged safe point `1d4b2b7...` olarak kalır.

---

## 3. Ürün kimliği

CHIEF SITE ENGINEER (CSE), yalnız şantiye şefi tarafından kullanılan; not, takip, hatırlatıcı,
hesap, fotoğraf, belge, günlük, arama ve proje hafızasını tek güvenilir akışta birleştirmeyi hedefleyen
local-first ve mobile-first kişisel saha asistanıdır.

```text
Araç bakımından geniş
Kullanıcı modeli bakımından tek sahipli
```

Ana çalışma döngüsü:

```text
Yakala → İşle → Takip et → Doğrula → Günlüğe al
```

CSE büyük kurumsal inşaat platformlarının küçültülmüş kopyası değildir. Uygulamaya yalnız şantiye
şefi girer. Şirket, taşeron, işveren, yapı denetim ve diğer kişiler kullanıcı hesabı değil; kişi, firma,
bildirilen taraf, sorumlu taraf veya belge kaynağı gibi kayıt referanslarıdır.

Ürün filtresi:

> Bu özellik şantiye şefinin sahada unutmamasını, kanıtlamasını, takip etmesini, raporlamasını
> veya daha sonra geri çağırmasını kolaylaştırıyor mu?

---

## 4. Merge edilmiş çalışan kabiliyetler

`master` üzerindeki `1d4b2b7...` güvenli noktası aşağıdaki çalışan omurgayı taşır:

- SQLite persistence ve sürümlü migration runner
- Managed attachment store, güvenli path üretimi ve SHA-256 bütünlük doğrulaması
- Yerel Flask web uygulaması
- Proje oluşturma
- Saha gözlemi oluşturma, listeleme, arama, ayrıntı ve revision kontrollü güncelleme
- Gözlem durum ve bildirim bilgilerinin güncellenmesi
- Revision conflict koruması
- Günlük Markdown/CSV/JSON export paketi
- SQLite snapshot backup, backup verification ve yalnız yeni hedefe izole restore
- Windows tek tık launcher
- Saha Takibi domain kayıtları ve Europe/Istanbul recurrence hesapları
- Schema v4 takip/rutin persistence ve append-only event geçmişi
- Follow-up transactional application service ve yedi günlük idempotent lazy backfill
- Schema 2/3 backup'larını schema 4'e restore etme ve schema 4 round-trip
- Kişisel follow-up/routine verisini resmî günlük export'tan ayıran executable regresyonlar
- `/today` ekranı: Şimdi ilgilen, Gecikenler, Bugün ve Bugünkü rutinler
- Hızlı `+ Unutma`, Unutma Kutusu ve follow-up yaşam döngüsü
- Rutin oluşturma, listeleme, ayrıntı, pasifleştirme ve occurrence işlemleri
- Restart sonrasında aynı SQLite verisi, revision ve event geçmişi kalıcılığı

Bu ürün gerçek kalıcı veri kullanır; yalnız demo/mock değildir.

---

## 5. Henüz uygulanmamış veya tamamlanmamış alanlar

Aşağıdaki başlıklar plan veya backlog'dur; çalışan özellik gibi sunulmaz:

- Tek Hafıza UX için kesin ADR ve bütün kullanıcı yüzeylerinin birleşmesi
- `MemoryIndex / RecordRef` ortak read-model projeksiyonu
- Geriye dönük observation oluşturma kullanıcı akışı
- Archive list/filter, unarchive ve tam arşiv yaşam döngüsü
- İnsan okunabilir Tam Hafıza İndirme paketi
- Mobil runtime
- PWA/offline read cache ve kontrollü offline write/sync
- Notification/background scheduler
- Uygulama kilidi, authentication ve şifreli backup
- 7 günlük ve 30 günlük gerçek saha pilotları
- Tam komuta merkezi
- Doküman/revizyon/çizim merkezi
- Şantiye İş Planı Lite
- İş Paketi Motoru ve Beton İş Paketi
- Saha hesap araçları ve manuel metraj
- PDF-first çizim destekli metraj
- Haricî uygulama ve cihaz paylaşım bağlantıları
- Deterministik full-text arama, semantik arama ve AI
- Owner-only cihaz senkronizasyonu
- Production-ready kabulü

CSE public internet için uygun değildir. Mevcut sürüm authentication, authorization veya TLS
içermez. Field-ready veya production-ready olarak adlandırılamaz.

---

## 6. Tek kullanıcı, Hafıza ve kapsam ayrımı

Güncel ürün yönü tek kullanıcı ve tek Hafıza deneyimidir. Bununla birlikte mevcut kod ve export
güvenliği `private | project` kapsam ayrımını korur.

Doğru yorum:

- Tek kullanıcı: uygulamaya yalnız şantiye şefi girer.
- Tek Hafıza UX: not, takip, rutin, gözlem ve ilerideki kayıtlar ayrı ürün dünyaları gibi
  sunulmamalıdır.
- Ayrı kaynak tablolar korunabilir; büyük ve riskli tek-tablo migration'ı yapılmaz.
- `private | project` bir rol/tenant sistemi değildir; export, rapor, paylaşım ve devir kapsamıdır.
- Private kaydın project/resmî kapsama dönüşümü açık kullanıcı işlemi olmalıdır.
- Mevcut davranış ADR tamamlanmadan sessizce değiştirilmez.
- `field_observations`, `follow_up_items` ve `routine_occurrences` için ortak görünüm
  `MemoryIndex / RecordRef` adlı yeniden üretilebilir read-model üzerinden planlanır.
- Read-model source-of-truth değildir; kaynak tablolar ve append-only event geçmişi kalır.

`CSE derin mevcut durum araştırması.pdf` içindeki “kişisel/resmî ayrımı kaldırılmalı” hükmü,
tek Hafıza UX yönüne ilişkin bir ürün önerisidir. Güncel program bu öneriyi veri kapsamını tamamen
yok etmek şeklinde değil, tek UX + açık `private | project` kapsamı şeklinde düzeltmiştir.

---

## 7. Üç ayrı çıktı sözleşmesi

Aşağıdaki kavramlar birbirinin yerine kullanılamaz:

### Backup
Felaket kurtarma içindir. SQLite, attachment dosyaları, teknik manifest, hash ve restore
sözleşmesini taşır.

### Hafızayı İndir
Kullanıcının bütün hafızasını insan tarafından açılabilir ve makine tarafından doğrulanabilir şekilde
indirmesidir. HTML/Markdown indeks, JSON/CSV veri setleri, event geçmişi, arşiv ve attachment
bağlantıları hedeflenir. Backup'ın yerine geçmez.

### Proje Paketi
Yalnız seçili proje/project scope için paylaşım, raporlama veya kontrollü devir paketidir. Private
kapsam varsayılan olarak dışarıda kalır. Restore amacı taşımaz.

Bu ayrımlar henüz production kodunda tamamlanmış değildir; Issue #128 ve sonraki dar ADR
görevlerinde kesinleştirilecektir.

---

## 8. Veri ve güvenlik ilkeleri

- CSE önce güvenilir veri omurgasını kurar; otomasyon ve AI daha sonra gelir.
- Geliştirme küçük, test edilebilir, geri alınabilir ve commitlenebilir adımlarla ilerler.
- Resmî/project kayıtlar fiziksel silme yerine archive, pasifleştirme, hükümsüz kılma veya yeni
  revision ile değiştirme yaklaşımını izler.
- Kanıt niteliği taşıyan mutation'lar append-only event/audit izi bırakır.
- Attachment binary veritabanına gömülmez; managed store, metadata ve hash ile yönetilir.
- Her attachment metadata kaydı fiziksel dosyayla bütünlük içinde olmalıdır.
- UTC storage ve Europe/Istanbul kullanıcı gösterimi korunur.
- Optimistic revision, stale conflict, gerçek no-op ve transaction rollback davranışı test edilir.
- Sistem kullanıcı onayı olmadan resmî karar, kabul, ret, kapanış, kapsam dönüşümü veya
  otomatik `blocked` üretmez.
- Multi-user, role, tenant, firma portalı, kurumsal collaboration, SaaS/billing ve public internet
  ürün hedefi değildir.
- Tek kullanıcı kararı güvenliği kaldırmaz; app lock, şifreli backup ve owner-only sync sonraki
  güvenlik katmanlarıdır.

---

## 9. Yürütme programı

Bağlayıcı kayıtlar:

```text
Ürün Epic'i: #105
Saha Takibi Epic'i: #97
Uygulanabilir program: #127
Faz Epic'leri: #128–#140
```

Açık Epic'lerin tamamı aynı anda aktif iş değildir. Aynı anda yalnız bir production implementation
görevi yürütülür.

Issue #141, programın ilk dar repository-truth görevidir. Yerel çalışma tamamlanmış ve Draft PR
#142 açılmıştır. PR merge edilmeden sonraki production veya ADR görevi aktif ilan edilmez.

Ayrıntılı sıra `02_CSE_UYGULANABILIR_YOL_HARITASI_2026_2.md` dosyasındadır.

---

## 10. ChatGPT / Codex / GitHub iş bölümü

### ChatGPT
- GitHub durumunu doğrular.
- Küçük Issue oluşturur veya günceller.
- Codex gerekip gerekmediğine karar verir.
- Branch diff ve completion evidence inceler.
- Draft PR açar, review yapar, ready/merge akışını yönetir.
- Yerel dosya ve test yapılmış gibi iddia etmez.

### Codex
- Yalnız resmî `V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer` reposunda çalışır.
- Yerel sync, branch, dosya değişikliği, test, commit ve push işlemlerini yapar.
- Yalnız aktif Issue kapsamına uyar.
- Beklenmeyen yerel değişiklikte durur.
- Varsayılan olarak PR açmaz ve merge yapmaz.

### GitHub
- Remote repository, Issue, PR, review ve merge gerçeğini taşır.
- Branch'in push edilmiş olması merge edilmiş olduğu anlamına gelmez.

### Kullanıcı
- Ürün kapsamının nihai karar sahibidir.
- Güvenli inceleme tamamlandığında merge/ilerleme kararını verir.

---

## 11. Değişmez çalışma disiplini

- Aynı anda yalnız bir aktif production implementation Issue'su
- En fazla bir incelemede PR
- Her teknik iş ayrı dar Issue ve branch
- Branch standardı: `codex/issue-<issue_no>-<slug>`
- Squash merge
- Force push yok
- Otomatik branch silme yok
- Gerçek kullanıcı data root'una açık yetki olmadan erişim yok
- `reports/`, ignored ZIP/cache ve `exports/.gitkeep` korunur
- Her production değişikliği focused test + full suite + compileall + JSON + diff kontrolüyle kapanır
- Bir commit'in kendi SHA'sını yazmak için metadata commit zinciri oluşturulmaz
- Merge edilmemiş çalışma merged safe point olarak gösterilmez

---

## 12. Güncel karar cümlesi

CSE bugün güvenilir SQLite/attachment/revision/event/backup çekirdeği ve ilk PC Saha Takibi
yüzeyi olan gerçek bir Local Field Alpha'dır. Sonraki yatırım sırası; önce repository/ADR zemini,
güvenilir Hafıza yaşam döngüsü ve Tam Hafıza İndirme, sonra mobil saha güvenilirliği; daha sonra
komuta merkezi, dokümanlar, plan, paket, hesap/metraj ve en son kaynaklı AI'dır.
