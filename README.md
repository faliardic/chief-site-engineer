# CHIEF SITE ENGINEER

CHIEF SITE ENGINEER (CSE), yalnız şantiye şefi tarafından kullanılan; not, takip, hatırlatıcı, hesap, fotoğraf, belge, günlük, arama ve proje hafızasını tek güvenilir akışta birleştiren local-first ve mobile-first **kişisel saha asistanı**dır.

```text
Araç bakımından geniş
Kullanıcı modeli bakımından tek sahipli
```

Ana çalışma döngüsü:

```text
Yakala -> İşle -> Takip et -> Doğrula -> Günlüğe al
```

CSE büyük inşaat yönetim platformlarının küçültülmüş kopyası veya kurumsal ortak çalışma platformu değildir. Uygulamaya yalnız şantiye şefi girer. Şirket, taşeron, işveren, yapı denetim ve diğer kişiler sistem kullanıcısı değil; kişi, firma, bildirilen taraf, sorumlu taraf veya belge kaynağı gibi kayıt referanslarıdır.

Ürün filtresi şudur:

> Bu özellik şantiye şefinin sahada unutmamasını, kanıtlamasını, takip etmesini, raporlamasını veya daha sonra geri çağırmasını kolaylaştırıyor mu?

## Mobil uygulama

`mobile/` altında Flutter/Dart tabanlı Android ve iOS uygulaması bulunur.
Telefon ilk mobil sürümde ana veri cihazıdır; günlük kullanım bilgisayar,
Flask sunucusu, LAN veya internet gerektirmez. Issue #180 runtime temelini,
Issue #179 ise ilk gerçek Ajanda ve bağlı hatırlatıcı dikey dilimini sağlar.

Mobil temel şunları içerir:

- Android ve iOS platform projeleri;
- Başlangıç, Hatırlatıcı, Ajanda, Puantaj ve Beton Paketi navigasyon kabuğu;
- Ajanda'da İstanbul gün sınırı, gün navigasyonu, proje/tür/literal filtreler,
  geçmiş log oluşturma, detay ve boş gün görünümü;
- logdan project/source bağlantılı Unutma Kutusu veya zamanlı hatırlatıcı;
- Hatırlatıcı'da Unutma Kutusu, Bugün, Yaklaşanlar ve çift yönlü detay linki;
- cihaz-içi SQLite schema `2`, sürümlü ve atomik migration geçmişi;
- restart sonrasında korunan smoke kayıt;
- UTC seconds storage ve `Europe/Istanbul` sunumu;
- debug/release için ayrı application identity ve veri kökü;
- attachment, notification, permission ve export için güvenli platform portları.

Bu dilim tam reminder yaşam döngüsü, attachment, native notification, Puantaj
veya Beton Paketi özelliklerinin tamamlandığı anlamına gelmez. Cloud sync,
kullanıcı hesabı ve masaüstü verisinin otomatik taşınması yoktur. Mobil
geliştirme ve build komutları
[`mobile/README.md`](mobile/README.md) içindedir.

## Normal kullanım

Windows'ta repository kökündeki `CSE_Baslat.cmd` dosyasına çift tıklayın. Başlatıcı:

- veriyi varsayılan olarak `%LOCALAPPDATA%\ChiefSiteEngineer\data` altında tutar;
- logları `%LOCALAPPDATA%\ChiefSiteEngineer\logs` altında tutar;
- uygun bir local port seçer ve hazır olduğunda tarayıcıyı açar;
- mevcut veri kökünü sessizce taşımaz veya silmez.

Belirli bir veri köküyle çalıştırmak için:

```powershell
CSE_Baslat.cmd --data-root C:\mevcut-cse-data
```

Geliştirici çalıştırması:

```powershell
python -m pip install -r requirements.txt
python -m app.web --data-root C:\cse-data
```

Uygulama varsayılan olarak yalnız `127.0.0.1` loopback adresinde açılır. Loopback dışı kullanım açık `--allow-network` seçimi gerektirir; mevcut MVP authentication, authorization veya TLS içermediği için public internet üzerinde yayınlanmamalıdır.

## Merge edilmiş güncel kabiliyetler

Bu branch'in başladığı son doğrulanmış `master` güvenli noktası:

```text
Issue #180
PR #181
merge commit 0e081f2c8616f990d56c6fe60f746dd4a5bc7f6d
```

Son production kabiliyet dilimi Issue #119 / PR #126 ile merge edilmiştir.
Issue #141–#169 arasındaki Faz 0 işleri repository truth, ADR, envanter, pilot
protokolü ve güvenlik modeli üretmiş; production davranışını değiştirmemiştir.

Local Field MVP bugün şunları sağlar:

- SQLite persistence ve sürümlü migration runner;
- managed attachment store, güvenli path üretimi ve bütünlük doğrulaması;
- local Flask web akışı;
- proje oluşturma;
- saha gözlemi oluşturma, listeleme, arama, ayrıntı görüntüleme ve revision kontrollü güncelleme;
- gözlem durum ve bildirim bilgilerinin güncellenmesi;
- revision conflict koruması;
- günlük Markdown/CSV/JSON export paketi;
- SQLite snapshot tabanlı backup, backup doğrulama ve yalnız yeni hedefe izole restore;
- Windows tek tık launcher;
- Saha Takibi v0.1 domain kayıtları ve saf `Europe/Istanbul` recurrence hesapları;
- SQLite schema 4 içinde Saha Takibi repository ve append-only event persistence altyapısı;
- Saha Takibi transactional application service'leri ve yedi günlük idempotent lazy backfill;
- schema 2/3 backup'larını schema 4'e güvenli restore etme ve schema 4 tracking round-trip doğrulaması;
- kişisel follow-up/routine verisini resmî günlük export'tan ayrı tutan executable izolasyon regresyonu;
- `/today` başlangıç ekranı ile Şimdi ilgilen, Gecikenler, Bugün ve Bugünkü rutinler görünümleri;
- hızlı `+ Unutma`, Unutma Kutusu ve follow-up ayrıntı/yaşam döngüsü işlemleri;
- rutin oluşturma, listeleme, ayrıntı, pasifleştirme ve occurrence sonuçlandırma/erteleme/yeniden açma yüzeyleri;
- restart sonrasında aynı SQLite verisi, revision ve append-only event geçmişi kalıcılığı.

İlk test edilebilir PC Saha Takibi yüzeyi merge edilmiştir. Bağlayıcı yürütme
programı GitHub Issue #127, faz backlog'u Issue #128–#140'tır. Faz 0 closure
Issue #171 / PR #172 ile merge edilmiştir. Faz 1'in ilk dar production işi
Issue #173 olay zamanı sözleşmesi ve salt-okunur migration preflight'ı, Issue
#175 ise geriye dönük observation create sözleşmesini tamamlamıştır. Issue #180
/ PR #181 mobil runtime temelini merge etmiştir. Issue #179 branch'inde mobil
Ajanda günlük logu ve logdan bağlı hatırlatıcı ilk özellik dilimi olarak
uygulanmıştır; attachment, gerçek notification delivery, cloud sync, uygulama
kilidi ve gerçek saha pilotları henüz tamamlanmamıştır.

## Saha Takibi v0.1

Merge edilmiş Saha Takibi çekirdeğinin bağlayıcı davranışları
[Saha Takibi v0.1 sözleşmesinde](docs/field_tracking_v0_1_contract.md) korunur.
Güncel sıradaki ürün işi Issue #173 ile Faz 1 / P1.01'dir.

Kullanıcı yüzeyi:

```text
Saha Takibi
+ Unutma
```

Hızlı yakalamada kullanıcıdan alınan tek zorunlu içerik `Ne unutulmamalı?` metnidir; hedef ortanca yakalama süresi 8 saniyenin altındadır.

Değişmez sınırlar:

- açık konu ya sonuçlandırılır ya da ne zaman yeniden görüneceği bellidir;
- `next_attention_at` gerçek `deadline_at` ile aynı değildir;
- bildirimi kapatmak işi tamamlamaz;
- kişisel takip ile resmî saha gözlemi ayrıdır;
- projeye bağlamak kişisel takibi otomatik resmî yapmaz;
- resmî gözleme dönüşüm açık kullanıcı işlemidir;
- hard delete yoktur;
- geçmiş rutin gerçekleşmeleri template değişikliğiyle yeniden yazılmaz.

Bugünkü local MVP'de uygulama kilidi veya şifreli veri katmanı bulunmadığı için “kişisel” tanımı başka cihaz/işletim sistemi kullanıcılarına karşı cryptographic privacy iddiası değildir. Ayrım bir erişim rolü değil, çıktı kapsamıdır:

```text
Kişisel çalışma verisi
-> resmî export/devir dışında

Proje/resmî kayıt
-> açık kullanıcı işlemiyle günlük, rapor veya devir çıktısına alınabilir
```

Tek kullanıcı kararı güvenliği kaldırmaz. Uzun vadeli güvenlik yönü; uygulama kilidi ve mümkünse cihaz biyometrisi, güvenilen cihazlar, şifreli backup, owner-only telefon-PC senkronizasyonu, güvenli yerel ağ erişimi ve veri sahibinin açık export/devir işlemidir. Public internet, kurumsal identity provider, role-based access veya tenant mimarisi ürün hedefi değildir.

## Operasyon komutları

Günlük export:

```powershell
python -m app.ops export-daily --data-root C:\cse-data --date 2026-07-15 --output C:\exports\daily.zip
```

Backup ve doğrulama:

```powershell
python -m app.ops backup --data-root C:\cse-data --output C:\backups\field.csebackup.zip
python -m app.ops verify-backup --archive C:\backups\field.csebackup.zip
```

İzole restore:

```powershell
python -m app.ops restore --archive C:\backups\field.csebackup.zip --target-root C:\cse-restored
python -m app.web --data-root C:\cse-restored
```

Ayrıntılı kullanım için [Local Field MVP operasyon belgesine](docs/operations/local_field_mvp_v0.1.md) bakın.

## Kurulum ve test

Python 3.12 veya daha yeni bir sürüm önerilir.

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install -r requirements.txt
python -m pytest -rs
```

Issue #171 closure baseline'ında doğrulanan full-suite sonucu:

```text
983 passed, 7 skipped
```

Yedi skip, Windows ortamında symlink oluşturma ayrıcalığı bulunmayan mevcut güvenlik testleridir.

## Faz 0 kanonik karar belgeleri

Faz 0'ın dört ADR'si ayrı sorumluluk taşır ve hiçbiri tek başına production
implementation kanıtı değildir:

- [ADR-0001 — Tek Hafıza ve kayıt kapsamı](docs/adr/ADR-0001-single-memory-and-record-scope.md)
- [ADR-0002 — MemoryIndex / RecordRef read-model](docs/adr/ADR-0002-memory-index-record-ref-read-model.md)
- [ADR-0003 — Backup, Hafızayı İndir ve Proje Paketi ayrımı](docs/adr/ADR-0003-backup-memory-download-project-package.md)
- [ADR-0004 — Owner-only güvenlik ve veri sahipliği tehdit modeli](docs/adr/ADR-0004-owner-only-security-and-data-ownership-threat-model.md)

Faz 0 merged kanıtı, current production ayrımı ve Faz 1 kapısı
[closure doğrulamasında](docs/171_phase_0_closure_validation.md) birlikte
gösterilir.

## Zaman sözleşmesi ve migration preflight

Issue #173 ile yeni kalıcı timestamp üretimi timezone-aware UTC
`YYYY-MM-DDTHH:MM:SSZ`, kullanıcı sunumu ise `Europe/Istanbul` olarak
merkezileştirilmiştir. `observed_at` / `occurred_at` olay anı, `created_at` ilk
kalıcı giriş ve `updated_at` son başarılı mutation anlamındadır. Naive değer
sessizce UTC sayılmaz.

Migration preflight yalnız koddan açıkça verilen `temporary` veya `test` SQLite
dosyasını `mode=ro` + `query_only` ile inceler. Schema 2/3/4 timestamp
kolonlarının count/min/max/mapping/warning/blocker bilgisini JSON-ready ve
veri-minimal raporlar; migration veya row rewrite yapmaz. Aktif data root için
otomatik keşif ya da kullanıcı komutu eklenmemiştir. Ayrıntılar
[Issue #173 sözleşmesindedir](docs/173_time_contract_and_migration_preflight.md).

## Bilinçli sınırlar

Mevcut uygulama:

- local ve tek kullanıcı odaklıdır;
- public internet için uygun değildir;
- mobil özellik dilimlerini, cloud sync veya owner-only cihaz senkronizasyonunu içermez;
- background notification delivery içermez; yalnız güvenli zamanlama portu vardır;
- uygulama kilidi, authentication, authorization veya TLS içermez;
- gerçek saha pilotu ve kabulü tamamlanmadığı için field-ready veya production-ready olarak tanımlanmaz.

`local-first`, `Windows-first` demek değildir. Verinin şantiye şefine ait olduğu ve kendi cihazlarında çalıştığı anlamına gelir. Mobil runtime, offline davranış, notification ve owner-only telefon-PC senkronizasyonu; çok kullanıcılı auth veya cloud collaboration ile aynı uzak hedef değildir.

## Uygulanabilir geliştirme programı

Bağlayıcı ürün Epic'i #105, Saha Takibi Epic'i #97 ve uygulanabilir yürütme programı Issue #127'dir. Faz backlog'u bağımlılık sırasıyla şöyledir:

- Issue #128 — Faz 0: repository truth, ADR'ler ve yürütme zemini;
- Issue #129 — Faz 1: Güvenilir Hafıza yaşam döngüsü ve ortak kayıt görünümü;
- Issue #130 — Faz 2: Tam Hafıza İndirme, doğrulama ve kurtarma standardı;
- Issue #131 — Faz 3: mobil runtime, offline güvenilirlik ve gerçek saha pilotları;
- Issue #132 — Faz 4: şantiye komuta merkezi, ortak timeline ve haftalık özet;
- Issue #133 — Faz 5: doküman, rapor ve çizim merkezi;
- Issue #134 — Faz 6: Şantiye İş Planı Lite ve iki haftalık lookahead;
- Issue #135 — Faz 7: İş Paketi Motoru ve Beton İş Paketi;
- Issue #136 — Faz 8: saha hesap araçları ve yönlendirmeli manuel metraj;
- Issue #137 — Faz 9: PDF-first çizim destekli metraj ve doğrulama;
- Issue #138 — Faz 10: haricî uygulama, cihaz paylaşımı ve güvenli içe aktarma bağlantıları;
- Issue #139 — Faz 11: deterministik arama, semantik geri çağırma ve kaynaklı AI;
- Issue #140 — Faz 12: owner-only güvenlik, bakım, güncelleme ve ürünleştirme.

Bu backlog'un açık olması bütün fazların aynı anda aktif olduğu anlamına gelmez.
Aynı anda yalnız bir production implementation görevi yürütülür. Faz 0 Issue
#171 / PR #172 ile kapanmış, Issue #173 Faz 1 P1.01 olarak başlamıştır. Bu iş
`scope`, archive/unarchive, `MemoryIndex`, Hafıza UI, schema migration veya yeni
artifact ailesi uygulamaz.

## Kaynak otoritesi

- Kalıcı ürün yönü: `docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md`
- Git/GitHub/Codex güvenliği: `docs/protocols/CSE_PROJECT_INSTRUCTIONS.md`
- Aktif görev kapsamı: current GitHub Issue
- Değişken repository durumu: GitHub `master`, PR, Issue ve branch kanıtı
- Yerel factual mirror: `.cse/state/project_state.json`

README, ROADMAP, eski ZIP, handoff veya `.cse/state`, güncel GitHub kanıtıyla çelişirse GitHub repository gerçeğinin yerine geçmez.
