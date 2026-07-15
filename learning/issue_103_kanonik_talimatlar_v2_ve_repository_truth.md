# Issue 103 - Kanonik Talimatlar v2 ve Repository Truth

## Amaç

Bu adımda production Python kodu yazmadık. Bunun yerine projenin ne olduğunu, bugün gerçekten ne yapabildiğini ve bir sonraki işin ne olduğunu anlatan belgeleri aynı doğrulanmış gerçeğe bağladık.

Bu çalışma önemlidir; çünkü doğru kodun yanında yanlış veya eski bir README varsa geliştirici de kullanıcı da yanlış karar verir. Örneğin SQLite ve Flask uygulaması mevcutken README'nin “gerçek database yok, GUI yok” demesi teknik bir **current-state drift** örneğidir.

## Çözülen saha ve ürün problemi

Şantiye şefi bilgiyi çoğu zaman şu zincirde tekrar tekrar yazar:

```text
Kâğıda kısa not
-> zihinde takip
-> ajandaya yeniden yazma
-> WhatsApp veya fotoğraf arama
-> günlük rapora tekrar yazma
```

CSE'nin güncel ürün döngüsü bunu şu hale getirmeyi hedefler:

```text
Yakala
-> İşle
-> Takip et
-> Doğrula
-> Günlüğe al
```

Buradaki amaç kâğıdı yasaklamak değildir. Amaç, bir kez yakalanan bilgiyi farklı işlerde tekrar yazmadan kullanmaktır.

## Yeni kavramlar

### Repository truth

Repository'nin güncel gerçeği; GitHub `master` HEAD, merged PR, current Issue, branch diff'i ve yerel Git doğrulamasının birlikte gösterdiği durumdur.

README veya state dosyası tek başına repository truth değildir. Çünkü bu belgeler eski kalabilir.

### Current-state drift

Kod ile onu anlatan belgelerin farklı dönemleri göstermesidir.

Örnek:

```text
Kod: SQLite + Flask + backup/restore var
Eski README: database ve GUI yok
```

### Local-first

Ana çalışma verisinin önce kullanıcının yerel cihazında tutulduğu ürün yaklaşımıdır. Bu, otomatik olarak encryption, auth veya başka Windows kullanıcılarına karşı gizlilik sağlandığı anlamına gelmez.

### Loopback

Bilgisayarın yalnız kendisine ulaşan ağ adresidir. CSE'nin varsayılan adresi `127.0.0.1` olduğu için uygulama doğrudan dış ağa açılmaz.

### Read-model / projeksiyon

Kaynak kayıtları değiştirmeden onlardan hesaplanan okuma görünümüdür. Canlı Proje Haritası ana veri kaynağı değil, source record'ların proje bağlamındaki read-model'idir.

### Snapshot

Belirli bir andaki içeriğin sabit kaydıdır. Yayımlanmış günlük, kaynak kayıtların akşam kontrol edilip yayımlandığı snapshot olarak tasarlanır; daha sonra sessizce yeniden yazılmaz.

## Kaynak otoritesini nasıl ayırdık?

Tek bir “her konuda en üstün dosya” sırası yerine bilgi türünü ayırdık:

| Soru | Yetkili kaynak |
| --- | --- |
| CSE neden var ve ürün sırası nedir? | `CSE_UNIFIED_PROJECT_SOURCE.md` |
| Git, Codex ve güvenlik kuralları nedir? | `CSE_PROJECT_INSTRUCTIONS.md` |
| Bu görevde hangi dosyalar değişebilir? | Current GitHub Issue |
| Şu an master hangi commit'te? | GitHub/Git kanıtı |
| Yerel durumun okunabilir aynası nedir? | `.cse/state/project_state.json` |

Bu ayrım iki hatayı önler:

1. Kalıcı talimata her görevde değişen commit ve test sayısı yazılmaz.
2. Eski state veya README, yeni GitHub merge gerçeğinin önüne geçmez.

## Gerçek state örneği

Issue #103 başlangıcında doğrulanan temel state şu yapıya çevrildi:

```json
{
  "current_issue": 103,
  "base_commit": "9b25152ae38b72470e332929cb3a30ff955b75f1",
  "active_work": {
    "issue": 103,
    "branch": "codex/issue-103-canonical-instructions-v2",
    "production_behavior_changed": false,
    "merge_claim": false
  },
  "current_safe_point": {
    "issue": 102,
    "pull_request": 104,
    "merge_commit": "9b25152ae38b72470e332929cb3a30ff955b75f1"
  }
}
```

Satır satır anlamı:

- `current_issue`: Şu anda yürütülen görevi gösterir.
- `base_commit`: Branch'in hangi doğrulanmış `master` commit'inden başladığını gösterir.
- `active_work.issue`: Henüz merge edilmemiş aktif işi safe point'ten ayırır.
- `production_behavior_changed`: Bu görevin Python davranışını değiştirmediğini açıkça yazar.
- `merge_claim`: Branch merge edilmeden `false` kalır.
- `current_safe_point.issue`: Son tamamlanan production görevidir.
- `pull_request`: Bu görevi `master` üzerine alan PR numarasıdır.
- `merge_commit`: GitHub ve yerel Git ile aynı olduğu doğrulanan commit'tir.

Burada önemli Python/JSON fikri şudur: JSON yalnız string taşımıyor; boolean değerler `true` ve `false` olarak gerçek türleriyle tutuluyor. Böylece ileride bir araç `"false"` metnini yanlışlıkla doğru kabul etmez.

## Branch standardı

Yeni işler için:

```text
codex/issue-<issue_no>-<slug>
```

Issue #103 örneği:

```text
codex/issue-103-canonical-instructions-v2
```

Eski `step-NNN-*` branch'leri yeniden adlandırmadık. Çünkü tarihsel Git referanslarını değiştirmek geçmiş kanıtı gereksiz yere zorlaştırır.

## Ürün sırası neden böyle?

| Sıra | Karar | Neden |
| --- | --- | --- |
| 1 | Local Field MVP omurgasını koru | Mevcut gözlem, attachment, export ve backup değeri kaybolmamalı |
| 2 | Domain ve recurrence | Takip kuralları önce saf ve test edilebilir olmalı |
| 3 | SQLite persistence | Restart sonrası veri kalıcılığı gerekir |
| 4 | Transactional service/backfill | Repository primitive'lerini güvenli use-case'e dönüştürür |
| 5 | Backup/export kabulü | Kişisel takip kaybolmamalı ve resmî export'a sızmamalı |
| 6 | Minimum UI | Kullanıcı ancak güvenli alt katman üzerinde çalışmalı |
| 7 | Saha pilotu | Gerçek kullanım sürtünmesi ölçülmeli |
| 8+ | Hesap defteri, günlük, harita | Çekirdek takip sahada doğrulandıktan sonra değer üretir |

## Mevcut test kodu bize neyi kanıtlıyor?

Bu dokümantasyon görevi test davranışını değiştirmedi. Yine de full suite çalıştırılır; çünkü README'de yazdığımız kabiliyetlerin mevcut kodla korunup korunmadığını doğrulamak gerekir.

Örneğin `tests/test_field_web_restart.py` içindeki gerçek test:

```python
def test_launcher_defaults_to_loopback_and_requires_network_opt_in(tmp_path: Path) -> None:
    args = parse_args(["--data-root", str(tmp_path)])
    assert args.host == "127.0.0.1"
    assert args.port == 5000

    with pytest.raises(SystemExit):
        parse_args(["--data-root", str(tmp_path), "--host", "0.0.0.0"])

    allowed = parse_args(
        ["--data-root", str(tmp_path), "--host", "0.0.0.0", "--allow-network"]
    )
    assert allowed.host == "0.0.0.0"
```

Satır satır:

- `tmp_path`, pytest'in test için oluşturduğu geçici klasördür; gerçek kullanıcı verisine dokunulmaz.
- İlk `parse_args(...)` çağrısı yalnız data root verir.
- İlk iki `assert`, varsayılan host'un loopback ve portun 5000 olduğunu kanıtlar.
- `pytest.raises(SystemExit)`, dış ağ adresinin açık izin olmadan reddedilmesini bekler.
- Son çağrı `--allow-network` ekler.
- Son `assert`, açık kullanıcı tercihi verildiğinde dış host'un kabul edildiğini kanıtlar.

Bu test README'deki “varsayılan loopback, dış ağ için açık opt-in gerekir” cümlesinin yalnız doküman iddiası olmadığını gösterir.

## Doğrulama komutları

```powershell
python -m pytest -rs
python -m compileall -q app scripts
python -m json.tool .cse/state/project_state.json > $null
git diff --check
git diff -- app tests .github/workflows requirements.txt
```

Komutların anlamı:

- `pytest -rs`: bütün testleri çalıştırır ve skip nedenlerini özetler.
- `compileall`: Python dosyalarının syntax olarak derlenebildiğini kontrol eder.
- `json.tool`: state dosyasının geçerli JSON olduğunu doğrular.
- `git diff --check`: bozuk whitespace veya conflict marker arar.
- son `git diff`: production, test, workflow ve dependency dosyalarının dokümantasyon görevinde değişmediğini kanıtlar.

## Kod çalışma akışı

```text
GitHub Issue #103 iznini oku
-> origin/master ve expected base SHA'yı eşitle
-> issue branch'ini oluştur
-> kanonik kaynakları ve PR #104 kanıtını oku
-> task kaydını oluştur
-> yalnız yetkili belgeleri/state'i güncelle
-> full suite ve koruma kontrollerini çalıştır
-> result evidence yaz
-> tek commit ve normal push
-> Issue #103 completion comment
```

## Hangi dosyada ne yaptık?

- `CSE_UNIFIED_PROJECT_SOURCE.md`: ürün kimliği, kullanıcı problemi, ürün sırası, hesap defteri, günlük ve Harita kararları.
- `CSE_PROJECT_INSTRUCTIONS.md`: kalıcı politika ile değişken state ayrımı, Issue branch standardı ve current-state doğrulama prosedürü.
- `CSE_NEW_CHAT_GITHUB_BOOTSTRAP.md`: yeni sohbetin stale state yerine GitHub'dan devam etme sırası.
- `README.md`: gerçek Local Field MVP kabiliyetleri, launcher kullanımı ve güvenlik sınırları.
- `ROADMAP.md`: PR #104 sonrası tamamlanan ve bekleyen ürün aşamaları.
- `.cse/state/project_state.json`: safe point ile aktif dokümantasyon işinin ayrılması.
- `CHANGELOG.md` ve `project_decisions.md`: bu adımın tarihsel değişiklik ve kalıcı karar izi.

## Şunu şöyle yaptık ki...

Kalıcı talimatlardan sabit eski commit ve test snapshot'larını çıkardık ki belge birkaç merge sonra yeniden yanlış bir “güncel durum” kaynağına dönüşmesin.

Aktif işi `current_safe_point` içine yazmadık ki merge edilmemiş branch tamamlanmış gibi görünmesin.

README'yi production kabiliyeti varmış gibi abartmadan güncelledik ki kullanıcı hem çalışan local uygulamayı görebilsin hem de auth, notification ve Saha Takibi UI gibi eksikleri açıkça bilsin.

Harita, günlük ve hesap defterini Saha Takibi saha pilotundan sonraya koyduk ki çekirdek “unutmama ve takip” problemi çözülmeden yeni ve dikkat dağıtıcı ürün yüzeyleri başlamasın.

## Bilinçli olarak yapmadıklarımız

- Python production kodunu değiştirmedik.
- Test veya fixture değiştirmedik.
- Schema/migration çalıştırmadık.
- Gerçek kullanıcı data root'una erişmedik.
- Backup/export/ZIP artifact üretmedik.
- `reports/` kullanıcı dosyalarına dokunmadık.
- PR açmadık veya merge yapmadık.
