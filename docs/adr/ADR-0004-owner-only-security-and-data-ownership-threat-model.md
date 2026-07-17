# ADR-0004: Owner-only Güvenlik ve Veri Sahipliği Tehdit Modeli

- **Durum:** Kabul edildi
- **Tarih:** 2026-07-17
- **Issue:** #169
- **Bağlayıcı üst kararlar:** ADR-0001, ADR-0002 ve ADR-0003
- **Üst program:** Issue #127; Faz 0 Epic #128; gelecek implementation Epic #140
- **Kapsam:** Dokümantasyon ve mimari karar; güvenlik implementation'ı değildir

## 1. Context, amaç ve non-goals

CSE tek gerçek kullanıcısı şantiye şefi olan local-first kişisel saha
asistanıdır. Tek sahipli ürün kararı multi-user rol/tenant sistemini gereksiz
kılar; fakat cihazı, Windows hesabını, yerel ağı, browser'ı, dosya sistemini,
artifact'ları veya software supply chain'i güvenilir yapmaz.

Bu ADR'nin amacı:

- owner'a ait source kayıtları ve dosyaları görünür bir varlık envanterine
  bağlamak;
- uygulama, işletim sistemi, browser, network, artifact ve repository arasındaki
  trust boundary'leri göstermek;
- mevcut kontrolleri yalnız gerçekten çalışan davranışlarla sınırlamak;
- açık riskleri olasılık, etki ve şiddetle sınıflandırmak;
- pilotu veya ürün genişletmeyi durduracak olayları bağlamak;
- Faz 12 ve diğer dar implementation işlerine executable acceptance kapıları
  vermektir.

Bu ADR şunları **uygulamaz**:

- auth, kullanıcı hesabı, rol veya tenant;
- app lock, PIN, OS credential veya biometric;
- session timeout, CSRF token veya brute-force throttling;
- database, Backup ya da Hafızayı İndir encryption'ı;
- TLS, secure LAN mode, device pairing veya firewall kuralı;
- signed update, release verifier veya reproducible distribution;
- malware scanning, cloud sync, device trust veya telemetry;
- production/test/schema/migration/UI/route/CLI değişikliği;
- LAN/public penetration ya da exposure testi.

## 2. Current MVP security posture

### 2.1 Kullanıcıya gösterilecek kısa güvenlik beyanı

> CSE mevcut MVP'de tek kullanıcı ve yerel cihaz odaklıdır; multi-user,
> tenant veya auth sistemi değildir. Varsayılan koruma yerel cihaz ile Windows
> hesabıdır. Uygulama kilidi, güvenli web session'ı ve at-rest encryption henüz
> yoktur. Backup ve mevcut Günlük Çıktı şifreli değildir. Uygulama public
> internete açılmamalı; ayrı erişim kapısı olmadan LAN kullanımı güvenli kabul
> edilmemelidir. `private | project` bir yetkilendirme sistemi değil,
> çıktı/paylaşım sınırıdır. Recovery ancak başarılı Backup doğrulaması ve yeni
> hedefte clean Restore provasıyla kanıtlanabilir.

### 2.2 Doğrulanmış mevcut kontroller

- Windows launcher `127.0.0.1` üzerinde server kurar, port uygunluğunu loopback
  üzerinde dener ve farklı data root instance'ını karıştırmamak için opaque
  instance kimliğini `/health` yanıtında doğrular.
- Geliştirici `app.web` girişi loopback dışı host için açık `--allow-network`
  ister ve auth/TLS bulunmadığı uyarısını verir. Bu bayrak bir güvenlik kapısı
  veya kimlik doğrulama değildir.
- Web upload boyutu `25 MiB` ile sınırlıdır. Attachment final adı kullanıcı
  adından türetilmez; canonical UUID path'i, güvenli suffix, relative-path,
  traversal, symlink, regular-file, SHA-256 ve size kontrolleri uygulanır.
- Attachment okuma ve download öncesinde metadata/path/hash/size bütünlüğü
  doğrulanır; güvenli image MIME allowlist'i ve `nosniff` kullanılır.
- Backup v1 online SQLite snapshot, exact manifest, strict archive entry/path,
  SHA-256/size, duplicate/symlink, SQLite `integrity_check`, migration allowlist,
  repository ve attachment reconciliation kontrolleri uygular.
- Restore mevcut hedefi reddeder, private temporary hedefte doğrular/migrate
  eder ve yalnız başarı sonrası atomik olarak yeni hedefe taşır.
- Günlük Çıktı v1 observation-only kaynağı kullanır; private tracking verisinin
  output byte'larını değiştirmediği executable regresyonla korunur.
- Revision conflict, append-only event geçmişi ve source aggregate'ler veri
  bütünlüğü için mevcut kontrollerdir.

### 2.3 Mevcut olmayan korumalar

- Route'larda login, authorization, app lock, session secret/cookie veya CSRF
  token sözleşmesi yoktur.
- HTTP üzerinde TLS yoktur; LAN modu için client/device pairing yoktur.
- SQLite, attachment, Backup ve mevcut export dosyaları CSE tarafından
  şifrelenmez.
- Windows ACL, BitLocker, ekran kilidi, removable-disk politikası ve endpoint
  protection CSE tarafından kurulmaz veya doğrulanmaz.
- Attachment içeriği malware taramasından geçmez.
- Release/update artifact imzası ve dependency provenance verifier'ı yoktur.
- Otomatik remote telemetry veya cloud security katmanı yoktur.
- Hafızayı İndir ve Proje Paketi henüz uygulanmamıştır.
- MemoryIndex/RecordRef henüz production değildir; ADR-0002 bir gelecek
  sözleşmesidir.

## 3. Asset inventory

`confidentiality`, `integrity` ve `availability` değerleri `low | medium | high |
critical` sözlüğünü kullanır. “Recovery yolu” bir garantiyi değil, uygulanabilir
ve ayrıca doğrulanması gereken yolu gösterir.

| asset_id | Varlık | owner | confidentiality | integrity | availability | source_of_truth | Recovery yolu |
|---|---|---|---|---|---|---|---|
| `A01` | SQLite source database ve append-only event geçmişi | Şantiye şefi | critical | critical | critical | Domain tabloları + event tabloları | Doğrulanmış Backup → yeni hedef clean Restore → repository/history smoke |
| `A02` | Managed attachment dosyaları ve hash metadata'sı | Şantiye şefi | critical | critical | high | Managed file bytes + SQLite attachment metadata | Backup/Restore + reconciliation; source kayıtla owner bağı yeniden doğrulanır |
| `A03` | Canonical `CSE_DATA_ROOT` | Şantiye şefi | critical | critical | critical | Owner'ın açık seçtiği yerel root; varsayılanda `%LOCALAPPDATA%` altı | Doğrulanmış ayrı Backup; yeni root'ta Restore; eski root üzerine yazılmaz |
| `A04` | Local config, launcher state ve uygulama/log yolları | Şantiye şefi | medium | high | high | Açık runtime argümanları ve yerel launcher sözleşmesi | Güvenli config yeniden kurma; data root identity ayrı doğrulanır |
| `A05` | Backup ve Restore artifact'ları | Şantiye şefi | critical | critical | critical | Backup v1 manifest + archive; source değildir fakat recovery girdisidir | Exact verifier; clean Restore rehearsal; artifact kaynağı değiştirmez |
| `A06` | Hafızayı İndir artifact ailesi | Şantiye şefi | critical | high | medium | Gelecekte source'tan üretilen kişisel arşiv; source değildir | Restore garantisi yok; source veya doğrulanmış Backup gerekir |
| `A07` | Proje Paketi ve Günlük Çıktı aileleri | Şantiye şefi; paylaşım sonrası seçilmiş recipient | high | high | medium | Source'tan üretilmiş immutable artifact/snapshot; source değildir | Source'tan yeniden üretim; aileye özgü verifier; private veri eklenmez |
| `A08` | `private \| project` scope ve project eligibility bilgisi | Şantiye şefi | critical | critical | high | Scope uygulanınca source kayıt/event; o zamana kadar ADR-0001 compatibility mapping | Source/event history; projection'dan tahmin veya repair yok |
| `A09` | Local web request/browser state | Şantiye şefi | high | high | medium | Mevcut request ve source application service; kalıcı güvenli session yok | Process'i durdur, browser state'i kapat, source/backup doğrula |
| `A10` | Log, diagnostic ve report çıktıları | Şantiye şefi | high | medium | low | Üreten process; source kayıt değildir | Redacted yeniden üretim; retention/secure deletion ayrı policy ister |
| `A11` | GitHub repository, dependency ve release/update artifact'ları | Repository sahibi | medium | critical | high | Git commit/tag/release ve doğrulanmış build provenance | Güvenilen commit'e dönüş, yeni temiz build, signed/checksummed release kapısı |
| `A12` | Pilot logları ve anonim metrik kayıtları | Şantiye şefi/pilot owner | high | high | medium | Owner-controlled pilot kayıtları; domain source değildir | Minimum sanitize summary; retention sonunda kontrollü imha ayrı pilot Issue'su |
| `A13` | Future MemoryIndex/read-model/cache | Şantiye şefi | high | high | medium | **Source değildir**; A01'den deterministic projection | Source'tan shadow rebuild + validation + atomik activation |

## 4. Trust boundary haritası

```text
GitHub / release / dependency kaynağı
                 |
                 | TB10
                 v
Windows cihaz + owner hesabı ---------------- TB06 ---------------- diğer hesap/oturum
        |
        +-- Browser -------- TB03 -------- local web server
        |                                      |
        |                         TB04 loopback | LAN
        |                         TB05 LAN      | public internet
        |                                      |
        |                         application process
        |                         /       |         \
        |                     TB01     TB02       TB08
        |                       /        |           \
        |                  SQLite    attachments   MemoryIndex
        |                       \        /
        |                        CSE_DATA_ROOT
        |
        +-- TB07 removable disk / Backup hedefi
        +-- TB09 private source / project output / verifier
        +-- TB11 pilot günlükleri / gerçek saha içeriği
```

| boundary_id | Sınır | Güvenilen taraf | Güvenilmeyen varsayım | Zorunlu davranış |
|---|---|---|---|---|
| `TB01` | Uygulama süreci ↔ SQLite/data root | Açık seçilmiş root ve repository contract | Path doğru diye bytes/schema sağlamdır | Schema, transaction, revision, integrity ve backup kontrolleri |
| `TB02` | Uygulama ↔ managed attachment filesystem | Canonical store ve metadata | Dosya adı/path/content güvenlidir | UUID path, traversal/symlink/regular-file/hash/size fail-closed |
| `TB03` | Browser ↔ local web server | Aynı cihazdaki owner niyeti | Her local HTTP request owner'dandır | Bugün kanıtlanamaz; app lock/session/CSRF işi gerekir |
| `TB04` | Loopback ↔ LAN erişimi | Launcher'ın `127.0.0.1` bind'i | Loopback dışı interface de güvenlidir | Loopback default; LAN ayrı security gate olmadan production değil |
| `TB05` | LAN ↔ public internet yanlış yapılandırması | Hiçbiri | Router/firewall public exposure'ı engeller | Public bind/forwarding desteklenmez; görülürse anında stop |
| `TB06` | Owner Windows hesabı ↔ başka kullanıcı/oturum | OS login/ACL varsayımı | Başka local user dosyaları okuyamaz | CSE garantisi yok; OS hardening + app lock/encryption gerekir |
| `TB07` | Cihaz ↔ removable disk/backup hedefi | Owner'ın seçtiği hedef | Disk kaybolmaz, şifreli veya doğrulanmıştır | Plain artifact uyarısı; verify + ayrı fiziksel/şifreli saklama yönü |
| `TB08` | Source kayıt ↔ MemoryIndex/read-model/cache | Source aggregate + event | Projection doğruysa source da doğrudur | Source authoritative; drift diagnostic/rebuild, sessiz repair yok |
| `TB09` | Private kayıt ↔ project output/verifier | Source scope/project/revision | Project ID veya cache eligibility için yeterlidir | Source'tan fail-closed revalidation; private doğrudan çıkamaz |
| `TB10` | Local device ↔ GitHub/release/update | Açık seçilmiş repository/ref | İndirilen code/dependency güvenilirdir | Signed/checksummed provenance ve staged update gelecek kapısı |
| `TB11` | Pilot günlükleri ↔ gerçek saha içeriği | Anonim süre/count/category | Kopyalanan içerik anonim kalır | Gerçek içerik/path/hash/kişi/proje yok; minimum retention |

## 5. Actor ve threat source sınıfları

| actor_id | Aktör/kaynak | Niyet | Erişim örneği | Varsayılan güven |
|---|---|---|---|---|
| `ACT-OWNER-ERROR` | Owner'ın yanlış işlemi | Kötü niyet yok | Yanlış paylaşım, yanlış target, doğrulanmamış Backup | Güvenilmez input; açık confirmation ve fail-closed gerekir |
| `ACT-LOCAL-USER` | Başka Windows kullanıcısı/oturumu | Merak veya kötüye kullanım | Data root, Backup, browser/port erişimi | Güvenilmez |
| `ACT-LAN` | Aynı LAN'daki cihaz/kişi | Yetkisiz okuma/yazma | Non-loopback HTTP endpoint | Güvenilmez |
| `ACT-INTERNET` | Public internet actor'ı | Tarama, veri alma, mutation | Port forwarding/public bind | Tamamen güvenilmez |
| `ACT-WEB` | Malicious webpage/local process | Owner adına request veya port/path kullanımı | CSRF-benzeri POST, local port probing | Güvenilmez |
| `ACT-FILE` | Malicious/bozuk attachment veya archive | Kod çalıştırma, traversal, kaynak tüketimi | Upload, ZIP entry, unsafe filename | Güvenilmez bytes |
| `ACT-MALWARE` | Malware/ransomware | Exfiltration/şifreleme/silme | DB, attachment, Backup ve logs | Tamamen güvenilmez |
| `ACT-SUPPLY` | Compromised dependency/release/repository | Zararlı code dağıtımı | pip package, commit, release artifact | Provenance doğrulanana kadar güvenilmez |
| `ACT-FAILURE` | Disk, güç, process ve filesystem hatası | Niyet yok | Partial write, disk full, corruption | Beklenen failure mode |
| `ACT-STALE` | Stale cache/revision/config | Niyet yok | Yanlış output eligibility veya yanlış root | Source yeniden doğrulanana kadar güvenilmez |

## 6. Risk scoring yöntemi

### 6.1 Olasılık ve etki

| Değer | likelihood | impact |
|---|---|---|
| `1` | Rare: açık yanlış yapılandırma veya sıra dışı olay gerekir | Sınırlı, geri alınabilir operasyon sürtünmesi |
| `2` | Unlikely: normal kullanımda beklenmez ama gerçekçi | Lokal veri/metadata etkisi; doğrulanmış recovery var |
| `3` | Possible: saha/Windows/web kullanımında makul | Önemli confidentiality/integrity/availability etkisi |
| `4` | Likely: ek kontrol olmadan kolay veya tekrarlayan | Veri kaybı, geniş sızıntı ya da recovery kaybı |

`base_score = likelihood × impact` olarak hesaplanır:

| Skor | İlk sınıf |
|---|---|
| `1–3` | `low` |
| `4–7` | `medium` |
| `8–11` | `high` |
| `12–16` | `critical` |

### 6.2 Safety override

Skor düşük olsa bile şu sonuçlardan biri makul ise severity `critical` olur:

- confirmed veri kaybı veya source corruption;
- private/wrong-project leakage;
- unsafe Restore veya recovery başarısızlığı;
- public internet exposure;
- release/update integrity failure ile zararlı code çalışması.

Unauthorized LAN/local access, plain artifact leakage ve malicious attachment
en az `high` kabul edilir. Diagnostic metadata leakage, stale projection drift
ve kullanıcı hatasına açık fakat fail-closed paylaşım `medium` olabilir. Yalnız
confidentiality/integrity etkisi olmayan usability friction `low` olabilir.

Risk değeri “uygulama güvenlidir” sertifikası değildir. Current control sonrası
kalan **residual risk**, executable acceptance geçmeden `accepted` sayılmaz.

## 7. Threat scenario özet matrisi

| threat_id | Kısa senaryo | L | I | severity | blocker_status | Gelecek iş |
|---|---|---:|---:|---|---|---|
| `T01` | Public interface bind/exposure | 2 | 4 | critical | Anında ürün/pilot stop | `SEC-NET-01` |
| `T02` | Yetkisiz LAN erişimi | 3 | 4 | critical | Anında stop | `SEC-NET-01`, `SEC-SESSION-01` |
| `T03` | Başka Windows kullanıcısının dosya erişimi | 2 | 4 | high | Confirmed erişimde blocker | `SEC-OS-01`, `SEC-LOCK-01` |
| `T04` | Cihaz kaybı/çalınması | 2 | 4 | critical | Data exposure/recovery doğrulanana kadar stop | `SEC-LOCK-01`, `SEC-CRYPT-01` |
| `T05` | Plain Backup/Hafızayı İndir sızıntısı | 3 | 4 | critical | Confirmed leakage blocker | `SEC-CRYPT-01`, `SEC-CRYPT-02` |
| `T06` | Private veya wrong-project output leakage | 3 | 4 | critical | Tek confirmed olay blocker | `SEC-SCOPE-01` |
| `T07` | Wrong project ID/stale revision output | 3 | 4 | critical | Paylaşım/generation stop | `SEC-SCOPE-01` |
| `T08` | Malicious attachment/path/symlink/hash | 3 | 4 | high | Integrity/malware olayında blocker | `SEC-FILE-01` |
| `T09` | SQLite corruption/partial write/disk/power | 2 | 4 | critical | Suspected durumda mutation stop | `SEC-HEALTH-01`, `SEC-DRILL-01` |
| `T10` | Restore yanlış/mevcut hedefe | 2 | 4 | critical | Tek unsafe Restore blocker | `SEC-DRILL-01` |
| `T11` | Unknown schema/format sessiz kabul | 2 | 4 | critical | Verifier/Restore stop | `SEC-COMPAT-01` |
| `T12` | Log/diagnostic/report leakage | 3 | 3 | high | Secret/body leakage'te blocker | `SEC-LOG-01` |
| `T13` | Browser session/CSRF-benzeri mutation | 3 | 4 | high | Confirmed unauthorized mutation blocker | `SEC-SESSION-01` |
| `T14` | Local port veya file path kötüye kullanımı | 2 | 3 | high | Source erişimi/mutation varsa blocker | `SEC-SESSION-01`, `SEC-OS-01` |
| `T15` | Malicious/corrupt update artifact | 2 | 4 | critical | Update/release stop | `SEC-UPDATE-01` |
| `T16` | GitHub/dependency compromise | 2 | 4 | critical | Build/release stop | `SEC-SUPPLY-01` |
| `T17` | Private verinin haricî app ile paylaşılması | 3 | 3 | high | Confirmed leakage blocker | `SEC-SHARE-01` |
| `T18` | Pilot loguna gerçek içerik kopyalama | 3 | 3 | high | Pilot stop ve containment | `SEC-PILOT-01` |
| `T19` | Malware/ransomware corruption/exfiltration | 2 | 4 | critical | Cihaz ve pilot stop | `SEC-OS-01`, `SEC-DRILL-01` |
| `T20` | Doğrulanmamış Backup'a güvenme | 3 | 4 | critical | Recovery gate blocker | `SEC-DRILL-01` |
| `T21` | MemoryIndex/cache drift'inin truth sanılması | 3 | 3 | high | Output'ta fail-closed; source etkisinde blocker | `SEC-INDEX-01` |

## 8. Threat scenario ayrıntıları

Her senaryoda `current_control` yalnız bugünkü çalışan kontrolü; `future_mitigation`
ise henüz uygulanmamış işi anlatır.

### T01 — Public interface üzerinde açılma

| Alan | Değer |
|---|---|
| threat_id | `T01_PUBLIC_INTERFACE_EXPOSURE` |
| asset | `A01`, `A02`, `A03`, `A08`, `A09` |
| actor | `ACT-INTERNET`, `ACT-OWNER-ERROR` |
| entry_point | `app.web --host 0.0.0.0 --allow-network`, router port-forwarding, proxy/tunnel |
| precondition | Server loopback dışına bind edilir ve internetten route oluşur |
| likelihood | `2 — unlikely` |
| impact | `4 — catastrophic`; auth'suz okuma/mutation ve private leakage |
| severity | `critical` (safety override) |
| current_control | Launcher exact `127.0.0.1` kullanır; CLI non-loopback için explicit bayrak ve uyarı ister |
| control_gap | `--allow-network` sonrası auth/TLS/access gate yok; firewall/router state'i doğrulanmaz |
| detection | Bind adresi/process/netstat preflight; yalnız loopback synthetic test; public scan yapılmaz |
| immediate_response | Process'i durdur, forwarding/tunnel'ı kapat, cihazı ağdan ayır, artifact paylaşımını ve mutation'ı durdur, incident aç |
| future_mitigation | `SEC-NET-01`: secure LAN/TLS/device-pairing ADR + implementation; public bind hard-fail |
| owner | Owner; network security implementation owner |
| target_phase | Faz 3 secure local runtime ve Faz 12 security acceptance |
| blocker_status | Confirmed public exposure pilotu, release'i ve yeni özellik genişlemesini durdurur |
| acceptance_evidence | Executable bind allowlist; public/non-paired request rejection; auth/TLS negative tests; güvenli default config |

### T02 — Aynı LAN'da yetkisiz erişim

| Alan | Değer |
|---|---|
| threat_id | `T02_UNAUTHORIZED_LAN_ACCESS` |
| asset | `A01`, `A02`, `A08`, `A09` |
| actor | `ACT-LAN` |
| entry_point | Non-loopback HTTP interface |
| precondition | Owner LAN bind'i açar; attacker aynı routable ağdadır |
| likelihood | `3 — possible` |
| impact | `4 — catastrophic` |
| severity | `critical` |
| current_control | Normal launcher loopback-only'dir |
| control_gap | LAN identity, app lock, TLS, pairing, per-request authorization yoktur |
| detection | Access log/redacted security event ve paired-device inventory gelecekte; bugün yalnız process/bind incelemesi |
| immediate_response | LAN server'ı durdur, ağı kes, source revision/event ve son Backup'ı doğrula, credential varmış gibi reset iddiası yapma |
| future_mitigation | `SEC-NET-01` + `SEC-SESSION-01`: pairing, TLS, unlock, CSRF/session ve rate limit |
| owner | Owner; security implementation owner |
| target_phase | Faz 3 ve Faz 12 |
| blocker_status | Tek confirmed unauthorized LAN erişimi blocker |
| acceptance_evidence | Yetkisiz cihaz için bütün read/write route'ları fail-closed; paired owner cihazı için expiry/revocation testleri |

### T03 — Başka Windows kullanıcısının data root veya Backup erişimi

| Alan | Değer |
|---|---|
| threat_id | `T03_OTHER_WINDOWS_USER_FILE_ACCESS` |
| asset | `A01`, `A02`, `A03`, `A05`, `A10` |
| actor | `ACT-LOCAL-USER` |
| entry_point | NTFS path, shared folder, removable disk, açık Windows session |
| precondition | ACL/session/device policy başka hesabın okumaya veya yazmaya izin verir |
| likelihood | `2 — unlikely` |
| impact | `4 — catastrophic` |
| severity | `high` |
| current_control | Varsayılan root owner'ın `%LOCALAPPDATA%` alanındadır; CSE dosya yollarını açık seçer |
| control_gap | ACL/BitLocker/session lock doğrulanmaz; uygulama kilidi ve at-rest encryption yoktur |
| detection | OS audit/ACL preflight gelecekte; bugün owner inspection ve unexpected file/hash değişimi |
| immediate_response | Session/device erişimini kes, dosyaları yerinde repair etme, temiz cihazdan Backup/source integrity değerlendir |
| future_mitigation | `SEC-OS-01` OS hardening checklist + `SEC-LOCK-01` app lock + encryption işleri |
| owner | Owner; Windows packaging/security owner |
| target_phase | Faz 12 P12.02–P12.05 ve P12.11 |
| blocker_status | Confirmed unauthorized access veya mutation blocker |
| acceptance_evidence | ACL/locked-session acceptance, başka hesap negative test, uninstall/update data preservation testi |

### T04 — Cihaz kaybı veya çalınması

| Alan | Değer |
|---|---|
| threat_id | `T04_DEVICE_LOSS_OR_THEFT` |
| asset | `A01`, `A02`, `A03`, `A05`, `A08`, `A10` |
| actor | `ACT-LOCAL-USER`, fiziksel hırsız |
| entry_point | Kayıp Windows cihazı veya removable disk |
| precondition | Device/volume açık veya korunması zayıf; artifact cihazdadır |
| likelihood | `2 — unlikely` |
| impact | `4 — catastrophic` |
| severity | `critical` |
| current_control | Ayrı Backup üretilebilir; bunun dışındaki cihaz güvenliği OS'e bırakılmıştır |
| control_gap | App lock, disk/database/artifact encryption, remote revoke ve device trust yoktur |
| detection | Owner fiziksel kayıp bildirimi; device inventory gelecekte |
| immediate_response | Hesap/cihaz erişimini OS katmanında revoke et, kayıp cihazı güvenilir sayma, ayrı Backup'tan clean Restore planla, leakage incident aç |
| future_mitigation | `SEC-LOCK-01`, `SEC-CRYPT-01/02`, owner-only device trust ADR |
| owner | Owner |
| target_phase | Faz 12 |
| blocker_status | Exposure ve recovery sonucu belirlenene kadar pilot/release stop |
| acceptance_evidence | Locked device threat rehearsal, encrypted artifact wrong-key/tamper testleri, clean-device recovery drill |

### T05 — Şifresiz Backup veya Hafızayı İndir sızıntısı

| Alan | Değer |
|---|---|
| threat_id | `T05_UNENCRYPTED_OWNER_ARTIFACT_LEAK` |
| asset | `A05`, `A06`, `A08` |
| actor | `ACT-LOCAL-USER`, `ACT-OWNER-ERROR`, `ACT-MALWARE` |
| entry_point | E-posta, cloud klasör, removable disk, yanlış paylaşım hedefi |
| precondition | Plain artifact owner kontrolünden çıkar |
| likelihood | `3 — possible` |
| impact | `4 — catastrophic`; iki scope ve attachment içeriği açığa çıkabilir |
| severity | `critical` |
| current_control | ADR-0003 bu artifact'ları paylaşılabilir Proje Paketi saymaz; Backup verifier bütünlüğü doğrular |
| control_gap | Confidentiality encryption yok; verifier sızıntıyı önlemez |
| detection | Artifact inventory ve owner paylaşım kaydı; remote exfiltration telemetry yoktur |
| immediate_response | Paylaşımı/replikasyonu durdur, recipient erişimini revoke etmeye çalış, artifact'ı güvenilir sayma, leakage incident aç |
| future_mitigation | `SEC-CRYPT-01` encrypted artifact ADR; `SEC-CRYPT-02` authenticated encryption + key recovery |
| owner | Owner; Backup security owner |
| target_phase | Faz 12 P12.04–P12.05 |
| blocker_status | Confirmed artifact leakage blocker |
| acceptance_evidence | Wrong key/tamper fail-closed; secret log/history dışı; üretim sonrası decrypt+verify; recovery material rehearsal |

### T06 — Private kaydın Proje Paketi veya Günlük Çıktı'ya sızması

| Alan | Değer |
|---|---|
| threat_id | `T06_PRIVATE_OR_WRONG_PROJECT_OUTPUT_LEAK` |
| asset | `A07`, `A08`, `A01`, `A02` |
| actor | `ACT-OWNER-ERROR`, `ACT-STALE`, implementation defect |
| entry_point | Output selection, builder, verifier, future MemoryIndex aday listesi |
| precondition | Scope/project source'tan fail-closed yeniden doğrulanmaz |
| likelihood | `3 — possible` |
| impact | `4 — catastrophic` |
| severity | `critical` |
| current_control | Günlük Çıktı v1 observation-only; tracking isolation regression; ADR-0001/0003 private inclusion'ı yasaklar |
| control_gap | Source scope alanı ve Proje Paketi builder/verifier henüz uygulanmamıştır |
| detection | Her paylaşılabilir artifact için source eligibility reconciliation; M09 privacy metriği |
| immediate_response | Artifact paylaşımını durdur/revoke et, source'u değiştirme, incident aç, bütün aynı builder artifact'larını şüpheli say |
| future_mitigation | `SEC-SCOPE-01`: scope migration/event + project-output preflight/offline verifier + leakage regressions |
| owner | Output owner; owner |
| target_phase | Faz 1 scope implementation ve Faz 2 artifact implementation |
| blocker_status | Tek confirmed private/wrong-project leakage blocker |
| acceptance_evidence | Private/project-linked, wrong-project, unknown-scope, stale-selection ve attachment/reference negative testleri |

### T07 — Yanlış project ID veya stale revision ile output

| Alan | Değer |
|---|---|
| threat_id | `T07_STALE_OR_WRONG_PROJECT_OUTPUT` |
| asset | `A07`, `A08`, `A13` |
| actor | `ACT-STALE`, `ACT-OWNER-ERROR` |
| entry_point | Cached selection, old revision/fingerprint, project değişikliği |
| precondition | Generation live source'u yeniden okumaz |
| likelihood | `3 — possible` |
| impact | `4 — catastrophic` |
| severity | `critical` |
| current_control | Source revision conflict vardır; ADR-0002/0003 source revalidation'ı bağlar |
| control_gap | Future project package selection snapshot/verifier henüz yoktur |
| detection | Generation preflight source revision/project/scope/fingerprint karşılaştırması |
| immediate_response | Generation/paylaşımı durdur; stale artifact'ı geçersiz işaretle; source'u cache'e göre repair etme |
| future_mitigation | `SEC-SCOPE-01` executable selection snapshot ve fail-closed builder |
| owner | Output owner |
| target_phase | Faz 2 |
| blocker_status | Wrong-project artifact blocker; yalnız stale aday paylaşılmadan yakalanırsa warning |
| acceptance_evidence | Selection sonrası source mutation/project change testleri; output oluşmaması ve source'un değişmemesi |

### T08 — Malicious attachment, traversal, symlink, hash veya filename

| Alan | Değer |
|---|---|
| threat_id | `T08_MALICIOUS_OR_CORRUPT_ATTACHMENT` |
| asset | `A02`, `A03`, `A07` |
| actor | `ACT-FILE`, `ACT-MALWARE` |
| entry_point | Upload stream, source path, managed path, archive entry, browser preview |
| precondition | Güvenilmeyen bytes/file metadata CSE'ye verilir |
| likelihood | `3 — possible` |
| impact | `4 — catastrophic` |
| severity | `high` |
| current_control | 25 MiB upload cap; UUID filename; suffix allowlist/fallback; traversal/symlink/regular-file/hash/size checks; safe preview MIME + nosniff; Backup strict entry validation |
| control_gap | Malware scanner, content signature doğrulaması ve archive resource-limit kontratı yoktur |
| detection | Attachment verify/reconciliation, Backup verify, preview/download failure ve future malware result |
| immediate_response | Dosyayı açma/paylaşma, owner source'u otomatik silme, incident ID ile isolate et; ilgili artifact'ı PASS sayma |
| future_mitigation | `SEC-FILE-01`: malware/content policy, quarantine, decompression/size limits ve safe preview acceptance |
| owner | Attachment owner; security implementation owner |
| target_phase | Faz 5 belge merkezi ve Faz 12 diagnostics/security |
| blocker_status | Confirmed traversal/symlink/hash integrity veya malicious file blocker |
| acceptance_evidence | Traversal/symlink/collision/hash/size/MIME/polyglot/oversize negative fixtures; source ve existing file korunur |

### T09 — SQLite corruption, partial write, disk doluluğu veya güç kesintisi

| Alan | Değer |
|---|---|
| threat_id | `T09_SQLITE_OR_STORAGE_FAILURE` |
| asset | `A01`, `A02`, `A03` |
| actor | `ACT-FAILURE`, `ACT-MALWARE` |
| entry_point | SQLite/file write, fsync, disk volume |
| precondition | Process veya disk write tamamlanamaz ya da bytes dışarıdan bozulur |
| likelihood | `2 — unlikely` |
| impact | `4 — catastrophic` |
| severity | `critical` |
| current_control | SQLite transaction/UoW, revision/event atomicity, attachment stage+fsync+atomic move, Backup integrity check |
| control_gap | Runtime disk health/free-space monitor, scheduled integrity diagnostic ve automatic recovery yoktur |
| detection | SQLite `integrity_check`, repository validation, attachment reconciliation, write error, count/history karşılaştırması |
| immediate_response | Yeni mutation'ı durdur; source'u repair etme; okunabiliyorsa yeni ayrı Backup üret ve verify et; son known-good artifact'ı koru |
| future_mitigation | `SEC-HEALTH-01` read-only health diagnostics + `SEC-DRILL-01` recovery drill/retention |
| owner | Owner; persistence/operations owner |
| target_phase | Faz 12 P12.06–P12.08 ve P12.17 |
| blocker_status | Suspected durumda stop; confirmed corruption/data loss blocker |
| acceptance_evidence | Synthetic corruption/disk-full/write-failure tests; source unchanged; diagnostic redacted; clean Restore PASS |

### T10 — Restore'un yanlış veya mevcut hedefe uygulanması

| Alan | Değer |
|---|---|
| threat_id | `T10_UNSAFE_RESTORE_TARGET` |
| asset | `A01`, `A02`, `A03`, `A05` |
| actor | `ACT-OWNER-ERROR`, `ACT-FAILURE` |
| entry_point | Restore `target_root` seçimi |
| precondition | Target source/existing root ile karışır veya aktivasyon yarıda kalır |
| likelihood | `2 — unlikely` |
| impact | `4 — catastrophic` |
| severity | `critical` |
| current_control | Existing target reddedilir; temporary extraction/migration/validation; success sonrası atomic move; failure cleanup testleri |
| control_gap | UI/CLI source-target identity attestation ve guided rehearsal policy sınırlıdır; encryption yoktur |
| detection | Preflight target existence/separation; post-restore repository/count/history/attachment smoke |
| immediate_response | Restore'u durdur; source, archive ve existing target'ı değiştirme; temporary sonucu active yapma |
| future_mitigation | `SEC-DRILL-01`: guided clean Restore, source/target identity guard, scheduled rehearsal |
| owner | Owner; Backup/Restore owner |
| target_phase | Faz 2 recovery standardı ve Faz 12 drill |
| blocker_status | Tek unsafe/failed Restore blocker |
| acceptance_evidence | Same/existing/nested target negative tests; migration/reopen/reconciliation failure atomicity; source/archive digest korunur |

### T11 — Eski/uyumsuz schema veya formatın sessiz kabulü

| Alan | Değer |
|---|---|
| threat_id | `T11_SILENT_SCHEMA_OR_FORMAT_ACCEPTANCE` |
| asset | `A01`, `A05`, `A06`, `A07` |
| actor | `ACT-FILE`, `ACT-STALE`, implementation defect |
| entry_point | Backup/export/memory/package parser ve migration chain |
| precondition | Unknown version/field/entry en yakın parser ile yorumlanır |
| likelihood | `2 — unlikely` |
| impact | `4 — catastrophic` |
| severity | `critical` |
| current_control | Backup v1 exact fields, schema allowlist `(2,3,4)`, migration gap checks; Günlük Çıktı v1 exact format; ADR-0003 ayrı namespace/fail-closed |
| control_gap | Future Memory Download/Project Package parser'ları henüz yok; downgrade policy yok |
| detection | Exact discriminator/version/schema/entry/parser error ve compatibility matrix |
| immediate_response | Artifact'ı reddet; source veya manifesti otomatik düzeltme; desteklenen producer/reader belirle |
| future_mitigation | `SEC-COMPAT-01`: versioned strict readers, compatibility matrix, downgrade ve migration acceptance |
| owner | Artifact/release owner |
| target_phase | Faz 2 ve Faz 12 P12.09 |
| blocker_status | Verifier/Restore failure veya unknown version blocker |
| acceptance_evidence | Unknown/boolean/gap/mismatch/extra field-entry fixtures; hiçbir partial target/final artifact yok |

### T12 — Log, diagnostic veya report içinde hassas veri sızıntısı

| Alan | Değer |
|---|---|
| threat_id | `T12_LOG_DIAGNOSTIC_REPORT_LEAKAGE` |
| asset | `A10`, `A01`, `A02`, `A08` |
| actor | `ACT-OWNER-ERROR`, implementation defect, `ACT-MALWARE` |
| entry_point | Launcher log, exception text, diagnostic JSON/Markdown, support report |
| precondition | Record body, secret, full path/hash veya private title hata bağlamına kopyalanır |
| likelihood | `3 — possible` |
| impact | `3 — major` |
| severity | `high` |
| current_control | Launcher bazı hataları exception class ile sınırlar ve request logunu susturur; ADR-0002/0003 private metni loglamamayı bağlar |
| control_gap | Merkezi redaction şeması, structured security log ve retention yok; legacy helper'larda path/error alanları bulunur |
| detection | Canary/synthetic sensitive value negative tests; log/report schema allowlist review |
| immediate_response | Log paylaşımını durdur, kopyaları owner-controlled alanda contain et, source'u değiştirme, secret varsa rotate et |
| future_mitigation | `SEC-LOG-01`: structured redacted logging, retention, explicit diagnostic export ve crash privacy |
| owner | Logging/diagnostic owner |
| target_phase | Faz 12 P12.16 |
| blocker_status | Secret/record body/private content confirmed leakage blocker; metadata belirsizliği warning |
| acceptance_evidence | Synthetic PII/body/path/secret hiçbir log, error, report veya command history'de görünmez; retention testi |

### T13 — Browser session veya CSRF-benzeri local web riski

| Alan | Değer |
|---|---|
| threat_id | `T13_LOCAL_WEB_SESSION_OR_CSRF` |
| asset | `A09`, `A01`, `A08` |
| actor | `ACT-WEB`, `ACT-LOCAL-USER` |
| entry_point | Browser'ın local POST route'larına request göndermesi |
| precondition | CSE çalışır; malicious page/process loopback endpoint'e ulaşır |
| likelihood | `3 — possible` |
| impact | `4 — catastrophic` |
| severity | `high` |
| current_control | Loopback bind network yüzeyini daraltır; revision stale write'ı reddedebilir |
| control_gap | Login, app lock, session cookie/expiry, CSRF token, Origin/Host policy ve rate limit sözleşmesi yoktur |
| detection | Append-only event/revision'da beklenmeyen mutation; future auth/security event log |
| immediate_response | Server'ı kapat, browser tab/session'ı kapat, source history ve attachment/backup durumunu incele, otomatik rollback yapma |
| future_mitigation | `SEC-SESSION-01`: app lock, secure session, CSRF/Origin/Host controls, timeout ve brute-force throttling |
| owner | Web/security owner |
| target_phase | Faz 12 P12.02–P12.03 |
| blocker_status | Confirmed unauthorized mutation/read blocker |
| acceptance_evidence | Cross-origin/forged POST/read, expired/locked session ve brute-force negative tests; secret loglanmaz |

### T14 — Başka uygulamanın local portu veya file path'i kötüye kullanması

| Alan | Değer |
|---|---|
| threat_id | `T14_LOCAL_PORT_OR_PATH_CONFUSION` |
| asset | `A03`, `A04`, `A09` |
| actor | `ACT-WEB`, `ACT-LOCAL-USER`, `ACT-STALE` |
| entry_point | Port collision, sahte `/health`, symlink/junction veya yanlış `--data-root` |
| precondition | Instance identity/path sınırı yetersiz veya OS path başka yere yönlenir |
| likelihood | `2 — unlikely` |
| impact | `3 — major` |
| severity | `high` |
| current_control | Launcher `/health` application+instance hash doğrular, foreign portu atlar; paths resolve edilir; attachment store symlink'i reddeder |
| control_gap | Health identity secret değildir; root genelinde junction/ACL/device identity tehdidi tam modellenmemiştir; app lock yoktur |
| detection | Expected instance ID ve selected root preflight; unexpected file/revision/count; OS path inspection |
| immediate_response | Instance'ı durdur; doğru root'u owner ile doğrula; yanlış root'a mutation yapma; source ve Backup'ı ayır |
| future_mitigation | `SEC-SESSION-01` process/session identity + `SEC-OS-01` canonical root/ACL/junction acceptance |
| owner | Launcher/OS owner |
| target_phase | Faz 12 P12.03 ve P12.11 |
| blocker_status | Yanlış root/source erişimi veya unauthorized mutation blocker |
| acceptance_evidence | Foreign service, same/different root, junction/symlink, locked port ve tamper negative tests |

### T15 — Kötü niyetli veya bozulmuş update/release artifact'ı

| Alan | Değer |
|---|---|
| threat_id | `T15_MALICIOUS_OR_CORRUPT_UPDATE` |
| asset | `A11`, `A01`, `A03` |
| actor | `ACT-SUPPLY`, `ACT-FILE` |
| entry_point | İndirilen installer/package/ZIP/update |
| precondition | Artifact provenance ve bütünlüğü doğrulanmadan çalıştırılır |
| likelihood | `2 — unlikely` |
| impact | `4 — catastrophic` |
| severity | `critical` |
| current_control | Git commit geçmişi ve local tests vardır; otomatik updater yoktur |
| control_gap | Signed artifact, trusted publisher, checksum channel, staged install, rollback/health gate yoktur |
| detection | Future signature/checksum/provenance verifier; install sonrası health diagnostic |
| immediate_response | Artifact'ı çalıştırma/update'i durdur, data root'u değiştirme, known-good build/Backup'ı koru, supply incident aç |
| future_mitigation | `SEC-UPDATE-01`: version/release contract, signed/checksummed artifact, preflight Backup, staged install, rollback |
| owner | Release owner |
| target_phase | Faz 12 P12.09–P12.11 |
| blocker_status | Signature/integrity/health failure release blocker |
| acceptance_evidence | Wrong signer/tampered/replay/downgrade/failed migration fixtures; data root korunur; rollback drill PASS |

### T16 — GitHub/source dependency compromise

| Alan | Değer |
|---|---|
| threat_id | `T16_SOURCE_OR_DEPENDENCY_COMPROMISE` |
| asset | `A11`, bütün runtime asset'leri |
| actor | `ACT-SUPPLY` |
| entry_point | Repository credential, malicious commit, PyPI dependency, build environment |
| precondition | Compromised source/dependency trusted build'e girer |
| likelihood | `2 — unlikely` |
| impact | `4 — catastrophic` |
| severity | `critical` |
| current_control | Git history/review, pinned requirements file ve local test disiplini; bunlar provenance imzası değildir |
| control_gap | Dependency lock/hash/SBOM, signature, reproducible build ve credential response policy yoktur |
| detection | Dependency/security inventory, provenance attestation, secret scanning ve commit/release signature gelecekte |
| immediate_response | Build/release/push'u durdur; credential rotate; known-good commit ve temiz environment belirle; artifact'ları şüpheli say |
| future_mitigation | `SEC-SUPPLY-01`: locked hashed dependencies, SBOM/license/security inventory, protected signed release pipeline |
| owner | Repository/release owner |
| target_phase | Faz 12 P12.09–P12.11 |
| blocker_status | Confirmed compromise veya unverifiable release integrity blocker |
| acceptance_evidence | Reproducible clean build, dependency hash mismatch rejection, provenance/signature verification ve incident drill |

### T17 — Owner'ın private veriyi haricî uygulamayla paylaşması

| Alan | Değer |
|---|---|
| threat_id | `T17_ACCIDENTAL_EXTERNAL_SHARING` |
| asset | `A02`, `A05`, `A06`, `A07`, `A08` |
| actor | `ACT-OWNER-ERROR` |
| entry_point | E-posta, WhatsApp, cloud drive, share menu, haricî viewer |
| precondition | Artifact ailesi/kapsamı anlaşılmadan dosya paylaşılır |
| likelihood | `3 — possible` |
| impact | `3 — major` |
| severity | `high` |
| current_control | ADR-0003 aile isimleri ve kapsamları ayrıdır; Backup paylaşım artifact'ı değildir |
| control_gap | Share preflight, recipient confirmation, visible confidentiality label ve encrypted delivery henüz yoktur |
| detection | Owner report; artifact family/recipient event gelecekte; otomatik telemetry yok |
| immediate_response | Gönderimi/replikasyonu durdur, recipient'tan silme iste, leakage incident aç, source'u değiştirme |
| future_mitigation | `SEC-SHARE-01`: family label, explicit share review, recipient/channel/encryption seçimi ve safe-share UX |
| owner | Owner; output UX owner |
| target_phase | Faz 2, Faz 10 ve Faz 12 |
| blocker_status | Confirmed private artifact paylaşımı blocker |
| acceptance_evidence | Backup/Memory Download share warning; private selection rejection; recipient/channel confirmation tests |

### T18 — Pilot loguna gerçek saha içeriği kopyalanması

| Alan | Değer |
|---|---|
| threat_id | `T18_PILOT_LOG_CONTENT_LEAK` |
| asset | `A12`, `A01`, `A02`, `A08` |
| actor | `ACT-OWNER-ERROR` |
| entry_point | Daily/summary pilot log, screenshot, GitHub comment/repository |
| precondition | Ölçüm kanıtı diye gerçek body/path/hash/kişi/proje bilgisi kopyalanır |
| likelihood | `3 — possible` |
| impact | `3 — major` |
| severity | `high` |
| current_control | Issue #167 şablonları yalnız duration/count/category/anon ID/outcome kabul eder; gerçek log commit'i yetkisizdir |
| control_gap | Automated redaction/DLP ve retention uygulaması yoktur |
| detection | Daily validation checklist, repository diff review ve owner review; içerik açığa çıkarılmaz |
| immediate_response | Pilotu durdur, log paylaşımını kes, kopyaları owner-controlled alanda contain et, GitHub'a hassas kanıt ekleme |
| future_mitigation | `SEC-PILOT-01`: pilot storage/retention/access policy ve synthetic redaction acceptance |
| owner | Pilot owner |
| target_phase | Her pilot öncesi; Faz 3 |
| blocker_status | Gerçek içerik/identifier leakage pilot blocker |
| acceptance_evidence | Template validation gerçek body/path/hash/UUID/phone örneklerini reddeder; sanitize summary review PASS |

### T19 — Malware/ransomware database, attachment veya Backup'ı bozar

| Alan | Değer |
|---|---|
| threat_id | `T19_MALWARE_OR_RANSOMWARE` |
| asset | `A01`, `A02`, `A03`, `A05`, `A10` |
| actor | `ACT-MALWARE` |
| entry_point | Device process, malicious file/update, shared/removable disk |
| precondition | Malware owner hesabı veya dosya erişimi kazanır |
| likelihood | `2 — unlikely` |
| impact | `4 — catastrophic` |
| severity | `critical` |
| current_control | Attachment/path/hash kontrolleri ve Backup verifier bozulmayı gösterebilir; prevention garantisi değildir |
| control_gap | Malware scan, immutable/offline Backup policy, rotation ve endpoint health integration yoktur |
| detection | Unexpected hash/integrity/repository failure, OS endpoint signal, Backup verify failure |
| immediate_response | Cihazı ağdan ayır; CSE ve Backup write'larını durdur; aynı cihazdaki artifact'ı güvenilir sayma; temiz ortamda doğrula |
| future_mitigation | `SEC-OS-01`, `SEC-FILE-01`, `SEC-DRILL-01`: endpoint guidance, quarantine, offline rotation ve clean-device drill |
| owner | Owner; OS/security owner |
| target_phase | Faz 12 P12.06, P12.07, P12.17 |
| blocker_status | Suspected malware'de cihaz/pilot stop; confirmed corruption/leakage blocker |
| acceptance_evidence | Synthetic tamper/ransomware drill; offline known-good Backup; clean device Restore; source sayıları/history/hash PASS |

### T20 — Backup hiç doğrulanmadan güvenli sanılır

| Alan | Değer |
|---|---|
| threat_id | `T20_UNVERIFIED_BACKUP_FALSE_CONFIDENCE` |
| asset | `A05`, `A01`, `A02` |
| actor | `ACT-OWNER-ERROR`, `ACT-FAILURE` |
| entry_point | Backup dosyasının varlığını recovery kanıtı saymak |
| precondition | Verify veya clean Restore rehearsal yapılmaz/gecikir |
| likelihood | `3 — possible` |
| impact | `4 — catastrophic` |
| severity | `critical` |
| current_control | `verify-backup` ve isolated Restore vardır; Issue #167 %100 verify + clean Restore gate'i ister |
| control_gap | Scheduled reminder, freshness/rotation görünürlüğü ve enforced rehearsal programı yoktur |
| detection | Son verify/rehearsal zamanı ve sonucu; bugün manuel evidence |
| immediate_response | “Recovery hazır” iddiasını kaldır, yeni Backup üret/doğrula, disposable hedefte clean Restore yapmadan pilot/release gate'i geçme |
| future_mitigation | `SEC-DRILL-01`: backup freshness, rotation/retention ve periyodik clean Restore programı |
| owner | Owner |
| target_phase | Faz 12 P12.06 ve P12.17 |
| blocker_status | Failed verifier/Restore veya gate öncesi kanıt yokluğu blocker |
| acceptance_evidence | Planlı verify %100 PASS; en az bir clean Restore; overdue freshness warning; failure'da PASS üretmeme |

### T21 — MemoryIndex/read-model/cache drift'i source sanılır

| Alan | Değer |
|---|---|
| threat_id | `T21_PROJECTION_DRIFT_AS_TRUTH` |
| asset | `A13`, `A01`, `A08`, `A07` |
| actor | `ACT-STALE`, implementation defect |
| entry_point | Hafıza arama/dashboard/output aday inventory |
| precondition | Missing/stale/unknown projection live source yerine yetkili kabul edilir |
| likelihood | `3 — possible` |
| impact | `3 — major`; kayıt görünmezliği veya scope/output hatası |
| severity | `high` |
| current_control | ADR-0002 source aggregate+event'i truth, projection'ı rebuildable cache olarak tanımlar |
| control_gap | MemoryIndex schema/projector/drift diagnostic henüz uygulanmamıştır |
| detection | Source/ref count, revision, fingerprint, version, scope/project ve generation state diagnostic |
| immediate_response | Resmî output'u durdur; source'u projection'a göre repair etme; last verified generation'ı stale olarak göster |
| future_mitigation | `SEC-INDEX-01`: transactional upsert, shadow rebuild, atomik activation ve redacted drift diagnostic |
| owner | MemoryIndex implementation owner |
| target_phase | Faz 1 ve Faz 12 health diagnostics |
| blocker_status | Private/output etkisi veya source mutation varsa blocker; yalnız stale search sonucu warning/repair gate |
| acceptance_evidence | Missing/orphan/duplicate/fingerprint/version/drift fixtures; partial generation active olmaz; output source'u yeniden okur |

## 9. Mevcut kontroller ve açık gap'lerin yorumu

### 9.1 Güçlü fakat dar mevcut kontroller

Managed attachment ve Backup/Restore katmanları path, checksum, schema ve atomik
hedef davranışında güçlü fail-closed kontroller taşır. Bu kontroller:

- attachment'ın malware içermediğini;
- Backup'ın gizli olduğunu;
- cihazın yetkisiz kişiden korunduğunu;
- local web request'inin owner'dan geldiğini;
- public/LAN erişiminin güvenli olduğunu;
- update artifact'ının güvenilir olduğunu

kanıtlamaz. Integrity ile confidentiality/authenticity aynı iddia değildir.

### 9.2 Risk kabulü

Mevcut MVP yalnız şu geçici koşullarda kullanılabilir kabul edilir:

1. Server launcher'ın loopback-only yolu ile çalışır.
2. Cihaz ve Windows session yalnız owner kontrolündedir.
3. Data root ile plain Backup/export owner-controlled yerel alanda tutulur.
4. Public/LAN bind, port forwarding, tunnel veya paylaşılmış klasör kullanılmaz.
5. Backup düzenli verify edilir; recovery için clean Restore kanıtı aranır.
6. Şüpheli attachment açılmaz/paylaşılmaz.
7. Private/output eligibility belirsizliğinde artifact paylaşılmaz.

Bu, residual riskin kalıcı kabulü değildir. Faz 12 production-readiness kapısı
app lock/session, encryption, diagnostics, update provenance ve recovery drill
kanıtı olmadan geçilemez.

## 10. Veri sahipliği sözleşmesi

1. Bütün source kayıtlar, append-only event geçmişleri ve managed attachment
   dosyaları şantiye şefine aittir.
2. Canonical local data root owner'ın açıkça seçtiği ve koruduğu yerel alandır.
   Varsayılan `%LOCALAPPDATA%` yolu sahipliği veya encryption'ı tek başına
   kanıtlamaz.
3. GitHub repository source code, dokümantasyon ve synthetic fixture içindir;
   kullanıcı verisi, gerçek Backup, gerçek attachment veya pilot içeriği için
   storage alanı değildir.
4. Backup eksiksiz felaket kurtarma artifact'ıdır. Hafızayı İndir owner'ın
   okunabilir kişisel arşividir. Proje Paketi tek projeye ait seçilmiş
   paylaşılabilir artifact'tır. Günlük Çıktı dar günlük operasyon çıktısıdır.
5. Arşivleme silme değildir. Physical delete mevcut ürün davranışı değildir;
   uninstall/update owner verisini sessizce silemez.
6. Owner'ın açık işlemi olmadan `private -> project` dönüşümü, paylaşım,
   telemetry, cloud upload veya external app gönderimi yapılamaz.
7. `private | project` OS erişim kontrolü veya encryption değildir; source
   output eligibility sınırıdır.
8. Diagnostic, crash ve pilot logları data minimization'a tabidir. Varsayılan
   içerik süre/count/category/safe code ile sınırlanır.
9. MemoryIndex, cache, export ve artifact source-of-truth değildir. Source
   domain kayıtları ve event geçmişi yetkilidir.
10. Backup kopyası var diye recovery garantisi verilmez; exact verifier ve
    disposable/new-target clean Restore gerekir.

## 11. Scope/output leakage sonuçları

- Project bağlantısı scope değildir.
- Observation için current compatibility mapping `project`; follow-up/routine
  için `private`dır. Bu mapping source scope implementation'ı varmış gibi
  sunulmaz.
- Private kayıt önce açık, revision/event üreten scope dönüşümü olmadan Proje
  Paketi/günlük/rapora alınamaz.
- MemoryIndex yalnız aday keşfi yapabilir; output builder source scope, project,
  revision, archive, status, reference, attachment ve publication değerlerini
  yeniden doğrular.
- Unknown, stale veya çelişkili eligibility fail-closed reddedilir.
- Confirmed private veya wrong-project leakage tek başına `critical` incident ve
  pilot/ürün blocker'ıdır.

## 12. Backup/Restore ve artifact confidentiality sonuçları

- Backup v1'in strict SHA-256/manifest verifier'ı integrity sağlar; encryption
  veya sender authenticity sağlamaz.
- Restore yalnız var olmayan yeni hedefe yapılır. Source, archive ve existing
  target doğrulama/migration sırasında değiştirilmez.
- Hafızayı İndir iki scope'u ve bütün hafızayı taşıyacağı için future standard
  artifact'ta encrypted envelope zorunlu yön olarak kalır.
- Proje Paketi delivery channel'a göre encryption kullanabilir; private
  eligibility kontrolü encryption'a bırakılamaz.
- Günlük Çıktı v1 plain kalır; future encrypted envelope ayrı version/Issue
  ister.
- Secret/key/passphrase command history, manifest, log, diagnostic veya issue
  yorumuna yazılmaz.

## 13. Local web, loopback/LAN/public sınırları

| Mod | Current karar | Güvenlik durumu |
|---|---|---|
| Launcher `127.0.0.1` | Desteklenen mevcut kullanım | Risk daraltılmıştır; app lock/session/CSRF yokluğu devam eder |
| Developer `localhost`/`::1` | CLI loopback allowlist'inde | Launcher acceptance'ı yalnız `127.0.0.1` için kanıtlıdır; eşdeğer production iddiası yapılmaz |
| LAN host + `--allow-network` | Teknik olarak mümkün ama güvenli production modu değildir | Auth/TLS/pairing olmadan yasak pilot/production yapılandırması |
| `0.0.0.0`, public interface, forwarding/tunnel | Desteklenmez | Anında blocker ve incident |

“Local” sözcüğü “güvenli” demek değildir. Aynı cihazdaki başka process/webpage,
açık Windows session veya yanlış browser davranışı ayrı tehdit kaynağıdır.

## 14. Incident response ve pilot/ürün stop kriterleri

### 14.1 Safety-first incident sırası

1. Yeni mutation, output paylaşımı, update ve pilot işlemini durdur.
2. Public/LAN/malware şüphesinde cihazı veya process'i ilgili ağdan ayır.
3. `SEC-INC-YYYYMMDD-NN` anonim incident ID aç; gerçek body/path/hash/secret
   yazma.
4. Source, Backup, attachment veya artifact'ı yerinde repair/mutate etme.
5. Source okunabiliyorsa mevcut artifact'ın üzerine yazmadan yeni Backup üret;
   verifier başarısızsa PASS sayma.
6. Hassas kanıtı GitHub/repository/pilot loguna koyma; owner-controlled ayrı
   alanda minimum retention ile koru.
7. Olayı `suspected | confirmed | disproved` olarak sınıflandır.
8. Containment, root cause, recovery ve revalidation için ayrı executable Issue
   aç.
9. Restart yalnız owner kararı ve yeni doğrulama penceresinde ilgili acceptance
   PASS sonrası yapılır.

### 14.2 Anında blocker olan olaylar

- confirmed veri kaybı veya source corruption;
- private/project veya wrong-project leakage;
- public internet exposure;
- unauthorized LAN erişimi;
- Backup verifier veya clean Restore failure;
- malicious attachment/path traversal/symlink/hash integrity failure;
- release/update artifact integrity failure;
- kullanıcıyı güvensiz workaround'a zorlayan kritik açık;
- güvenilir güvenlik kararı verilemeyecek ölçüm/kanıt eksikliği.

Blocker varken Faz 1, pilot süresi veya yeni özellik kapsamı otomatik
genişletilmez. Fix planı yazmak aynı incident penceresini PASS yapmaz; yeni
executable revalidation gerekir.

## 15. Gelecek implementation Issue haritası

Bu anahtarlar plan kaydıdır; GitHub Issue açılmış veya implementation yapılmış
anlamına gelmez.

| future_issue_key | Hedef | Target phase | Executable acceptance kapısı |
|---|---|---|---|
| `SEC-NET-01` | Secure LAN ADR + TLS/device pairing; public bind hard-fail | Faz 3 / Faz 12 | Yetkisiz/non-paired client bütün route'larda fail-closed; public bind reddi |
| `SEC-LOCK-01` | App lock/PIN/OS credential/biometric ADR ve recovery | Faz 12 P12.02 | Lock/restart/timeout/recovery; secret plaintext yok |
| `SEC-SESSION-01` | App lock uygulaması, secure session, CSRF/Origin/Host ve throttling | Faz 12 P12.03 | Forged/expired/locked request negative tests; LAN'da zorunlu unlock |
| `SEC-CRYPT-01` | Encrypted Backup/Hafızayı İndir ADR | Faz 12 P12.04 | Algorithm/KDF/envelope/key recovery ve metadata leakage exact sözleşmesi |
| `SEC-CRYPT-02` | Authenticated encryption üretim/verify/Restore | Faz 12 P12.05 | Wrong key/tamper fail-closed; decrypt+verify; atomic output; secret logsuz |
| `SEC-OS-01` | Windows ACL/device hardening, packaging ve uninstall data policy | Faz 12 P12.11 | Başka hesap negative test; update/uninstall data root'u sessiz silmez |
| `SEC-HEALTH-01` | Read-only SQLite/schema/attachment/index/backup health diagnostic | Faz 12 P12.07 | Source mutation yok; redacted sonuç; corruption/drift exact sınıfları |
| `SEC-INDEX-01` | MemoryIndex projection + shadow rebuild/drift diagnostic | Faz 1 / Faz 12 | Partial generation active olmaz; output source'u yeniden doğrular |
| `SEC-SCOPE-01` | Scope source/event ve output eligibility/verifier | Faz 1 / Faz 2 | Private, wrong-project, stale revision/reference/attachment fail-closed |
| `SEC-COMPAT-01` | Version/release compatibility matrix ve strict readers | Faz 2 / Faz 12 P12.09 | Unknown/gap/downgrade/extra entry reddi; partial target yok |
| `SEC-FILE-01` | Attachment content/malware/quarantine/resource-limit policy | Faz 5 / Faz 12 | Malicious/polyglot/oversize fixture karantina; source otomatik silinmez |
| `SEC-LOG-01` | Structured redacted local logs, retention ve explicit diagnostic export | Faz 12 P12.16 | PII/body/path/hash/secret negative tests; retention/owner export |
| `SEC-UPDATE-01` | Signed/checksummed staged update ve rollback | Faz 12 P12.09–P12.11 | Signature/provenance, preflight Backup, migration health ve rollback PASS |
| `SEC-SUPPLY-01` | Dependency hash/SBOM/reproducible build/release provenance | Faz 12 P12.11 | Hash mismatch reddi; clean reproducible build; signed release |
| `SEC-SHARE-01` | Artifact family/scope share preflight ve recipient/channel UX | Faz 2 / Faz 10 | Backup/Memory Download warning; private seçilemez; explicit recipient |
| `SEC-PILOT-01` | Pilot log storage, access, redaction ve retention | Faz 3 pilot öncesi | Gerçek içerik/identifier reddi; sanitize summary; retention kararı |
| `SEC-DRILL-01` | Backup rotation/freshness ve recovery drill programı | Faz 12 P12.06/P12.17 | Planlı verify %100; clean device/target Restore; failed update rollback |

## 16. Açık risk kabulü ve release kapısı

### 16.1 Açık residual riskler

Current MVP'de şu riskler **kabul edilmiş olarak kapatılmaz**, yalnız bilinen
sınır olarak taşınır:

- owner session açıkken local process/browser erişimi;
- cihaz/volume kaybında plain database/artifact exposure;
- LAN kullanımının güvenli olmaması;
- malicious attachment içeriğinin taranmaması;
- unsigned/unverified distribution ve dependency provenance;
- merkezi redaction/retention olmaması;
- recovery'nin manuel verify/rehearsal disiplinine bağlı olması.

### 16.2 Production-readiness için minimum security evidence

`production-ready` değerlendirmesi ancak en az şunlarla yapılabilir:

- current threat model revalidation;
- owner-only app lock ve secure session acceptance;
- encrypted Backup + key recovery + tamper/wrong-key testleri;
- public bind hard-fail ve secure LAN kararı;
- read-only health diagnostics;
- signed/checksummed release/update provenance ve rollback;
- redacted log/diagnostic retention;
- 30 günlük saha kullanımı, data loss `0`, privacy blocker `0`;
- planlı Backup verify ve clean Restore drill PASS;
- açık critical/high security blocker olmaması.

## 17. Reddedilen alternatifler

### “Tek kullanıcıysa auth gerekmez”

Reddedildi. LAN, başka local process, açık Windows session ve cihaz kaybı tek
kullanıcı kararından bağımsızdır.

### “Loopback bütün local web risklerini çözer”

Reddedildi. Loopback network yüzeyini daraltır; owner intent, CSRF, app lock,
session ve local malware kanıtı değildir.

### “Checksum encryption yerine geçer”

Reddedildi. SHA-256 integrity kontrolüdür; confidentiality ve sender
authenticity sağlamaz.

### “Project ID private veriyi güvenli yapar”

Reddedildi. Project bağlantısı scope değildir; source eligibility gerekir.

### “MemoryIndex doğruysa source'u düzelt”

Reddedildi. Projection source-of-truth değildir; yalnız rebuild edilir.

### “Backup dosyası varsa recovery hazırdır”

Reddedildi. Verifier ve clean Restore rehearsal olmadan recovery garantisi yoktur.

### “Güvenlik için telemetry zorunludur”

Reddedildi. Current ürün remote telemetry kullanmaz. Yerel redacted evidence ve
owner-controlled incident akışı önce gelir; future telemetry ancak açık opt-in
ve ayrı privacy sözleşmesiyle değerlendirilebilir.

## 18. Bu ADR'nin uygulamadığı alanlar

- Production code veya test;
- schema, migration, persistence veya MemoryIndex;
- server bind, firewall, route, web template veya CLI;
- app lock, session, CSRF, TLS veya device pairing;
- encrypted artifact, key generation veya recovery material;
- malware scanning/quarantine;
- signed update/release veya dependency lock;
- health diagnostic/repair;
- pilot çalıştırma ya da gerçek güvenlik testi;
- gerçek user data root, Backup, attachment, log veya pilot içeriği.

Bu ADR mevcut MVP'nin sahip olmadığı korumayı varmış gibi göstermez. Her gelecek
mitigation ayrı, dar, yetkili ve executable acceptance taşıyan Issue ister.
