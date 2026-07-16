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

`master` üzerindeki son doğrulanmış güvenli nokta:

```text
Issue #102
PR #104
merge commit 9b25152ae38b72470e332929cb3a30ff955b75f1
```

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
- SQLite schema v3 içinde Saha Takibi repository ve append-only event persistence altyapısı.

Saha Takibi için domain/recurrence ve SQLite persistence tamamlanmıştır. Transactional application service, yedi günlük lazy backfill orchestration, eski backup uyumluluğu kabulü, resmî export izolasyonu regresyonu ve `+ Unutma` / `Bugün` / `Unutma Kutusu` kullanıcı arayüzü henüz tamamlanmamıştır.

## Saha Takibi v0.1

Birinci ürün geliştirme önceliği [Saha Takibi v0.1 sözleşmesidir](docs/field_tracking_v0_1_contract.md).

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

Issue #103 branch'inde doğrulanan full-suite sonucu:

```text
788 passed, 7 skipped in 16.66s
```

Yedi skip, Windows ortamında symlink oluşturma ayrıcalığı bulunmayan mevcut güvenlik testleridir.

## Bilinçli sınırlar

Mevcut uygulama:

- local ve tek kullanıcı odaklıdır;
- public internet için uygun değildir;
- auth, authorization ve TLS içermez;
- mobile runtime, offline çalışma veya owner-only cihaz senkronizasyonu içermez;
- background notification veya scheduler içermez;
- Saha Takibi application service ve UI içermez;
- gerçek saha pilotu ve kabulü tamamlanmadığı için field-ready veya production-ready olarak tanımlanmaz.

`local-first`, `Windows-first` demek değildir. Verinin şantiye şefine ait olduğu ve kendi cihazlarında çalıştığı anlamına gelir. Mobil runtime, offline davranış, notification ve owner-only telefon-PC senkronizasyonu; çok kullanıcılı auth veya cloud collaboration ile aynı uzak hedef değildir.

## Ürün sırası

Bağlayıcı üst yol haritası GitHub Epic #105'tir:

0. Tek kullanıcılı kişisel saha asistanı yönünü kanonikleştir — Issue #103.
1. Saha Takibi transactional application service ve 7 günlük lazy backfill.
2. Backup/restore compatibility ve resmî export izolasyonu.
3. Mobil runtime ve veri sahipliği ADR.
4. Mobil-first Kâğıdı Bırakma Sürümü.
5. Offline ve bildirim güvenilirliği.
6. 7 günlük gerçek saha pilotu.
7. 30 günlük ana uygulama pilotu.
8. Gelişmiş mühendislik hesap defteri.
9. Günlük şantiye logu yayınlama/revizyon zinciri.
10. Canlı Proje Haritası.
11. Gerçek kullanımın kanıtladığı kişisel yardımcı araçlar.
12. Kişisel AI asistanı.

Domain/recurrence ve SQLite persistence tamamlanmıştır; Faz 1 ve sonrası tamamlanmamıştır. Kâğıdı Bırakma Sürümü yalnız `+ Unutma` ekranından ibaret değildir: takip görünümleri, rutinler, attachment, arama ve backup görünürlüğünün yanında minimum hızlı hesap şeridi ile günlük zaman çizelgesi/düzenlenebilir taslak da ilk mobil saha pilotundan önce aynı bütünleşik yüzeyde bulunmalıdır.

## Kaynak otoritesi

- Kalıcı ürün yönü: `docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md`
- Git/GitHub/Codex güvenliği: `docs/protocols/CSE_PROJECT_INSTRUCTIONS.md`
- Aktif görev kapsamı: current GitHub Issue
- Değişken repository durumu: GitHub `master`, PR, Issue ve branch kanıtı
- Yerel factual mirror: `.cse/state/project_state.json`

README, ROADMAP, eski ZIP, handoff veya `.cse/state`, güncel GitHub kanıtıyla çelişirse GitHub repository gerçeğinin yerine geçmez.
