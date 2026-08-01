# CSE Development Orchestrator Güvenlik Sınırı

## 1. Güvenlik hedefi

Orchestrator geliştirme işini hızlandırırken CSE'nin kullanıcı-verisi, Git,
approval ve provenance kapılarını zayıflatamaz. Hız veya otomasyon, daha geniş
okuma/yazma yetkisi için gerekçe değildir.

O0 yalnız bu sınırı belgeler; executable security mechanism oluşturmaz.

## 2. Varlık sınıfları

| Sınıf | Örnek | Varsayılan |
| --- | --- | --- |
| Tracked project source | `docs/`, `app/`, `mobile/`, `tests/` | Yalnız current Issue read/write allowlist'i |
| Git metadata | branch, SHA, index, tracked diff | `SAFE_READ`; mutation ayrı approval |
| GitHub metadata | Issue, yorum, branch/PR durumu | Read-only; write ayrı `PUBLISH` approval |
| Runtime metadata | manifest, event, hash, sayaç | Repository dışı runtime-owned root |
| Artifact | APK, AAB, report, test output | Ayrı build/evidence scope'u |
| Device surface | exact serial/package/sentetik kayıt | Ayrı `DEVICE` profile ve approval |
| Gerçek kullanıcı verisi | data root, app-private DB, kayıt içeriği | Yasak |
| Secret | API key, token, signing credential | Plaintext erişim/loglama yasak |

## 3. Korunan kullanıcı alanları

Orchestrator aşağıdaki alanları varsayılan olarak okuyamaz, listeleyemez,
arayamaz, değiştiremez veya silemez:

- gerçek kullanıcı data root'u;
- `device-backups/`;
- `reports/`;
- `exports/` içindeki kullanıcı çıktıları;
- ignored ZIP, cache ve generated kullanıcı alanları;
- app-private tablet/telefon veritabanı ve dosyaları;
- gerçek kullanıcı kayıtları;
- credential veya secret depoları.

Repository-wide `rglob`, broad UI hierarchy, broad logcat veya
`git status --ignored --untracked-files=all` güvenli observer davranışı değildir.
O1 yalnız exact tracked yollar ve açıkça yetkili metadata hedefleriyle çalışır.

## 4. Veri-minimal kanıt

Kanıtta bulunabilecek alanlar:

- stable record türü, sentetik işaret ve sayım;
- source/tree/artifact SHA-256;
- command/action fingerprint;
- exit code ve duration;
- PASS/FAIL/BLOCKED sınıfı;
- blocker code;
- bounded UI match count ve geçerli bounds sonucu;
- sanitized stdout/stderr hashleri.

Kanıtta bulunamayacak alanlar:

- gerçek kayıt başlığı veya içeriği;
- raw database row;
- broad UI XML/dump;
- broad screenshot/video;
- backup içeriği;
- secret/token/key;
- kullanıcı dosya yolu veya içerik özeti.

Sanitization sonradan raw veriyi silme işlemi değildir. Raw veri baştan
toplanmamalıdır.

## 5. Secret sınırı

O0–O8 içinde OpenAI API key yoktur. O9 değerlendirmesinde dahi şu invariant'lar
korunur:

- secret repository'ye yazılmaz;
- GitHub Issue/yorumuna yazılmaz;
- environment dump'a alınmaz;
- event payload, manifest, stdout/stderr veya evidence içine konmaz;
- hash üretmek için bile secret value uygulama katmanına taşınmaz;
- log redaction tek güvenlik katmanı sayılmaz.

Future credential backend ayrı karar kapısıdır. Runtime yalnız opaque credential
reference kullanmalıdır; plaintext saklama O0 tarafından onaylanmaz.

## 6. Runtime-owned path

Önerilen kök:

```text
%LOCALAPPDATA%\CSE-Orchestrator\
```

Alt alanlar:

| Yol | İçerik | Yasak içerik |
| --- | --- | --- |
| `state/` | SQLite event indexi ve projection | secret, kullanıcı content'i |
| `runs/` | run manifestleri | raw stdout/stderr |
| `logs/` | sanitized output ve hash | broad logs, secret |
| `approvals/` | fingerprint/consumption/expiry | raw credential |
| `evidence/` | veri-minimal sonuç | kullanıcı artifact'i |
| `worktrees/metadata/` | worktree ID, path fingerprint, lifecycle | source kopyası envanteri |

Runtime cleanup O0 kapsamı dışındadır. Gelecek cleanup yalnız exact
runtime-owned resolved path, prefix kontrolü, lifecycle state ve ayrı approval
ile tasarlanabilir.

## 7. Capability isolation

### 7.1 Code profile

İzin verilen:

- current Issue'daki exact tracked source/read allowlist'i;
- exact worktree write allowlist'i;
- Git metadata ve read-only GitHub Issue;
- yetkili focused validation.

Yasak:

- protected/ignored kullanıcı alanları;
- device veya publish action;
- secret/network genişlemesi;
- otomatik scope artışı;
- stage/commit izni olmadan index mutation.

### 7.2 Device profile

İzin verilen:

- exact serial, model, package ve artifact provenance;
- yalnız benzersiz sentetik kullanıcı yolu;
- bounded, target-specific UI observation;
- repository dışı sanitized evidence.

Yasak:

- gerçek kullanıcı kaydı open/mutation;
- app-private DB/shared-preferences okuma;
- broad UI/log dump;
- target drift;
- uninstall, data clear, downgrade veya hard-delete;
- repository source write.

### 7.3 Publish profile

İzin verilen:

- exact branch/commit ve remote metadata;
- ayrı approval ile bounded push/PR operation;
- publish evidence.

Yasak:

- source edit;
- device action;
- force-push;
- approval oluşturma;
- Fatih adına merge/release kararı;
- remote target drift.

Profiller aynı process içinde ambient yetkilerle birleşmemelidir. Her process
yalnız gerekli capability'yi alır; profile transition yeni admission ve approval
gerektirir.

## 8. Network sınırı

- Local Git ve tracked-file gözlemi ağ gerektirmez.
- Canlı GitHub SHA/Issue read'i yalnız read-only endpoint kullanır.
- GitHub write, artifact upload, push veya external API ayrı profile ve
  approval olmadan kapalıdır.
- O0–O4 OpenAI API çağırmaz.
- Network failure cached veriyi canlı gerçek gibi kabul ettirmez; run
  `BLOCKED` veya `PREFLIGHT_BLOCKED` olur.

## 9. Fail-closed olayları

Aşağıdaki koşullarda action başlamaz veya devam etmez:

- source/base/branch/tree farkı;
- approval fingerprint uyuşmazlığı;
- allowlist dışı read/write/action ihtiyacı;
- budget veya hard-stop tükenmesi;
- provenance belirsizliği;
- exact cihaz/target doğrulanamaması;
- gerçek kullanıcı verisi riski;
- secret erişimi ihtiyacı;
- raw evidence toplamadan ilerleyememe;
- capability process sınırının ihlali.

Fail-closed duruş otomatik reset, fetch, stash, clean, retry, kullanıcı verisi
inceleme veya scope genişletmeyle aşılmaz.

## 10. Kalıcı insan kontrolü

Orchestrator hiçbir fazda şunları kendi adına kararlaştıramaz:

- ürün amacı ve öncelik;
- scope/allowlist/bütçe genişlemesi;
- gerçek kullanıcı verisi erişimi;
- security gate bypass;
- correction kabulü;
- merge/release kabulü;
- destructive recovery;
- legal/technical acceptance.

Gelecekte mekanik action runner eklense bile bu kararlar Fatih'in açık,
source-bound ve tek kullanımlık approval'ına bağlı kalır.

## 11. Mevcut CSE araçlarıyla sınır

Mevcut `scripts/cse_status.py` varsayılanında ignored/untracked, ZIP ve export
alanlarını tarar. Bu davranış O1'in güvenli observer'ı değildir. O1 exact
tracked-only collector geliştirene kadar script otomatik Orchestrator
preflight'inde çağrılmaz.

Mevcut release scriptleri generated alanları temizleyebilir, artifact üretir ve
cihaz kurulumuna gidebilir. Bu araçlar yalnız release-critical Issue ve ayrı
approval altında kalır; Orchestrator safe-read profile'ında çağrılamaz.

## 12. O0 güvenlik sonucu

- Korunan kullanıcı alanları okunmadı.
- Secret veya API key oluşturulmadı.
- Runtime state oluşturulmadı.
- GitHub, build veya cihaz mutation'ı yapılmadı.
- Sınırlar implementation'dan önce kanonik olarak belgelendi.
