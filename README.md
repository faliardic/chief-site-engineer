# CHIEF SITE ENGINEER

CHIEF SITE ENGINEER (CSE), aktif şantiye şefinin kâğıt müsvedde, ajanda, WhatsApp, telefon galerisi, Excel, klasör ve kişisel hafıza arasında dağılan bilgiyi tek güvenilir saha hafızasında yönetmesine yardım eden local-first bir **Saha Komuta Sistemi**dir.

Ana çalışma döngüsü:

```text
Yakala -> İşle -> Takip et -> Doğrula -> Günlüğe al
```

CSE büyük inşaat yönetim platformlarının küçültülmüş kopyası değildir. Ürün filtresi şudur:

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

Auth olmadığı için bugünkü “kişisel” tanımı başka Windows kullanıcılarına karşı cryptographic privacy iddiası değildir. Yalnız resmî proje kayıtları ve resmî exportlardan ayrılmış kullanıcı çalışma verisini ifade eder.

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
788 passed, 7 skipped in 14.84s
```

Yedi skip, Windows ortamında symlink oluşturma ayrıcalığı bulunmayan mevcut güvenlik testleridir.

## Bilinçli sınırlar

Mevcut uygulama:

- local ve tek kullanıcı odaklıdır;
- public internet için uygun değildir;
- auth, authorization ve TLS içermez;
- cloud sync, PWA veya offline multi-device sync içermez;
- background notification veya scheduler içermez;
- Saha Takibi application service ve UI içermez;
- gerçek saha pilotu ve kabulü tamamlanmadığı için field-ready veya production-ready olarak tanımlanmaz.

## Ürün sırası

Yakın ürün yönü:

1. Local Field MVP omurgasını koru.
2. Saha Takibi domain ve recurrence — tamamlandı.
3. Saha Takibi SQLite persistence — PR #104 ile tamamlandı.
4. Transactional application service ve lazy backfill.
5. Backup/restore compatibility ve resmî export izolasyonu.
6. Minimum `+ Unutma` / `Bugün` / `Unutma Kutusu` UI.
7. Gerçek saha pilotu.
8. Kayıtlı mühendislik hesap defteri.
9. Günlük şantiye logu kontrol/yayınlama zinciri.
10. Canlı Proje Haritası read-model ve navigasyon yüzeyi.
11. Offline/PWA, auth, multi-user, cloud ve AI — daha sonra.

## Kaynak otoritesi

- Kalıcı ürün yönü: `docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md`
- Git/GitHub/Codex güvenliği: `docs/protocols/CSE_PROJECT_INSTRUCTIONS.md`
- Aktif görev kapsamı: current GitHub Issue
- Değişken repository durumu: GitHub `master`, PR, Issue ve branch kanıtı
- Yerel factual mirror: `.cse/state/project_state.json`

README, ROADMAP, eski ZIP, handoff veya `.cse/state`, güncel GitHub kanıtıyla çelişirse GitHub repository gerçeğinin yerine geçmez.
