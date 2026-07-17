# Issue #167 Öğrenme Notu — Saha Kabul Metrikleri ve Pilot Protokolü

## Bu çalışmada ne yaptık?

Bu Issue'da production kodu veya otomatik ölçüm sistemi yazmadık. CSE'nin
gerçek şantiyede işe yarayıp yaramadığını daha sonra ölçebilmek için:

- aynı anlama gelen ölçümlerin aynı formülle hesaplanmasını;
- 7 ve 30 günlük pilotların tekrarlanabilir adımlarını;
- veri kaybı, takip kaçırma, attachment bütünlüğü ve privacy stop kurallarını;
- gerçek kayıt içeriği toplamayan günlük/summary şablonlarını;
- yetersiz örneklemin yanlışlıkla “başarı” sayılmamasını

tanımladık.

Önemli sınır: Bu dosyanın yazılması pilotun yürütüldüğü anlamına gelmez. Gerçek
pilot için ayrı Issue, owner onayı, exact build ve owner-controlled veri saklama
politikası gerekir.

## Metrik neden yalnız bir sayı değildir?

“Kayıt açmak 20 saniye sürdü” tek başına yeterli değildir. Şunları da bilmek
gerekir:

- Süre ne zaman başladı ve bitti?
- Follow-up mı observation mıydı?
- Deneme başarılı mıydı?
- Hangi denemeler örneğe girdi?
- Başarısız denemeler saklandı mı?
- Hedef, warning ve blocker farkı nedir?
- Ölçüm sırasında gerçek kayıt içeriği toplandı mı?

Bu yüzden her metrik 15 alan taşır:

```text
metric_id
name
purpose
unit
numerator
denominator
data_source
collection_method
sampling_rule
target
warning_threshold
blocker_threshold
privacy_rule
owner
review_cadence
```

`numerator` pay, `denominator` paydadır. Örneğin failure rate:

```text
failure_rate = failed_attempt_count / all_valid_attempt_count * 100
```

Payda sıfırsa sonuç `0%` değildir; `N/A`dır. Çünkü hiç deneme yapılmamış olması,
kusursuz başarı kanıtı değildir.

## Median ve p90 nedir?

**Median**, sıralı değerlerin ortasındaki değerdir. Aşırı büyük tek bir değer
ortalama kadar kolay biçimde median'ı bozmaz.

**p90**, denemelerin yaklaşık yüzde 90'ının altında veya eşit kaldığı sınırı
gösterir. Tipik kullanımı median, kötü ama gerçekçi uç deneyimi p90 gösterir.

Bu protokol nearest-rank p90 kullanır:

```text
rank = ceil(0.90 * n)
p90 = sorted_values[rank - 1]
```

Python ile öğretici hesap:

```python
from math import ceil
from statistics import median


def summarize_seconds(values: list[int]) -> dict[str, float | int]:
    if not values:
        raise ValueError("at least one duration is required")

    ordered = sorted(values)
    p90_rank = ceil(0.90 * len(ordered))
    return {
        "count": len(ordered),
        "median_seconds": median(ordered),
        "p90_seconds": ordered[p90_rank - 1],
    }
```

Satır satır:

1. `ceil`, ondalıklı rank'i bir üst tam sayıya yuvarlar.
2. `statistics.median`, tek/çift örnek sayısını doğru ele alan standart library
   fonksiyonudur.
3. Fonksiyon boş listeyi reddeder; boş ölçümün başarı gibi yorumlanmasını önler.
4. `sorted(values)`, orijinal listeyi mutate etmeden yeni sıralı liste üretir.
5. `len(ordered)`, örnek sayısıdır.
6. Python listeleri sıfırdan başladığı için `p90_rank - 1` kullanılır.
7. Dict count, median ve p90'ı aynı sözleşmede döndürür.

Örnek:

```python
summary = summarize_seconds([12, 18, 20, 25, 70])
assert summary == {
    "count": 5,
    "median_seconds": 20,
    "p90_seconds": 70,
}
```

Bu kod repository'ye production helper olarak eklenmedi. Pilot runner veya
otomatik analytics bu Issue'ın kapsamı değildir; örnek yalnız hesap kuralını
öğretir.

## Başarısız denemeler neden percentile'dan ayrı gösteriliyor?

Kullanıcı doğru kaydı hiç bulamadıysa “bulma süresi” başarı dağılımına keyfî bir
değer eklemek yanıltıcı olur. Fakat failure'ı tamamen silmek de sonucu yapay
olarak iyileştirir.

Bu nedenle her deneme:

```text
duration_seconds + outcome
```

taşır. Median/p90 başarılı denemelerden hesaplanır; failure count/rate aynı
summary'de zorunlu gösterilir. `not_found` ve `wrong_record` gizlenmez.

Öğretici failure rate fonksiyonu:

```python
def failure_rate_percent(outcomes: list[str]) -> float | None:
    valid = [value for value in outcomes if value != "invalid_sample"]
    if not valid:
        return None

    failed = sum(value != "success" for value in valid)
    return failed / len(valid) * 100
```

- Invalid sample, ürün failure'ı değildir; ölçüm bütünlüğü problemidir.
- Valid örnek yoksa `None`, yani `N/A` döner.
- Boolean değerler Python'da `1/0` gibi toplanabildiği için `sum(...)` failure
  sayısını verir.
- Sonuç yüzdeye çevrilir.

## Örnekleme ile census arasındaki fark

**Örnekleme**, ölçüm yükünü azaltmak için olayların belirli bir alt kümesini
seçmektir. Protokol performans için her aktif günde ilk üç capture ve ilk iki
retrieval denemesini alır.

**Census**, kapsam içindeki her olayı saymaktır. Şunlar örneklenmez:

- veri kaybı şüphesi;
- missed follow-up;
- attachment integrity olayı;
- Backup/Restore failure;
- privacy leakage;
- unsafe workaround.

Güvenlik olayını “bugünkü sample kotası doldu” diye dışarıda bırakmak kabul
edilemez.

## Neden 7 ve 30 gün ayrı?

Yedi günlük pilot hızlı öğrenme penceresidir:

- ölçüm yöntemi çalışıyor mu;
- kritik güvenlik sorunu var mı;
- süre için minimum sample oluşuyor mu;
- kullanıcı CSE yerine neden başka araca dönüyor?

Otuz günlük pilot sürdürülebilirliği ölçer:

- dört haftalık trend;
- normal ve yoğun gün farkı;
- tekrar eden friction;
- haftalık Backup freshness;
- en az bir clean restore rehearsal;
- düzeltme sonrası regresyon.

Yedi günlük iyi sonuç, 30 günlük kalıcılık kanıtı değildir. Otuz gün de güvenlik
blocker'ını ortalama içinde eritemez.

## Gerçek kod örneği 1: Mevcut Backup doğrulaması

`app/acceptance/__main__.py` içindeki gerçek kabul akışı:

```python
backup = BackupService(data_root)
backup.create_backup(backup_path)
backup.verify_backup(backup_path)
```

Satır satır:

- `BackupService(data_root)`, hangi source data root'un snapshot alınacağını
  açık dependency olarak alır.
- `create_backup(backup_path)`, yeni Backup artifact'ı üretir.
- `verify_backup(backup_path)`, üretilen artifact'a ayrı verifier uygular.

Pilot protokolü bu iki adımı tek “backup oldu” checkbox'ına indirmez. Üretim
PASS, verifier FAIL olabilir. M06 numerator yalnız ikisi de PASS olduğunda
artar.

## Gerçek kod örneği 2: Clean-target Restore

Aynı acceptance dosyasında Restore:

```python
BackupService(archive_path.parent).restore_backup(archive_path, target_root)
service = _service(target_root)
detail = service.get_observation_detail(handoff["observation_id"])
```

Satır satır:

- `restore_backup`, arşivi açık `target_root` hedefine restore eder.
- Mevcut production sözleşmesi hedefin var olmamasını ister; üzerine yazma yoktur.
- `_service(target_root)`, Restore edilen yeni kökü application service ile
  yeniden açar.
- `get_observation_detail`, yalnız dosyanın açıldığını değil repository/domain
  okumasının çalıştığını kontrol eder.

Pilot M07'nin yalnız “komut exit code 0” dememesinin nedeni budur. Başarılı
rehearsal şu zinciri ister:

```text
Backup verify
-> yeni disposable target
-> Restore
-> repository reopen
-> revision/event kontrolü
-> attachment reconciliation
```

Gerçek data root üzerine Restore kesinlikle yapılmaz.

## Gerçek kod örneği 3: Attachment hash kontrolü

Acceptance akışındaki kontrol:

```python
if attachment.verification.actual_sha256 != handoff["sha256"]:
    raise RuntimeError("restored attachment hash mismatch")
```

- Restore sonrası gerçek byte'lardan hesaplanan SHA-256 alınır.
- Beklenen digest ile exact karşılaştırılır.
- Eşit değilse test açık hata üretir.

Pilot loguna digest değeri yazılmaz. M05 yalnız anonim event ID ve
`hash_mismatch` status code'u taşır. Hash, dosya içeriğini göstermese bile
gereksiz technical identifier'dır ve veri minimizasyonuyla log dışı tutulur.

## Viewer hatası ile bütünlük hatası farklıdır

Bir fotoğraf preview'ının ilk denemede açılmaması şu nedenlerden olabilir:

- geçici browser problemi;
- viewer/media-type problemi;
- dosyanın gerçekten missing olması;
- byte hash'inin değişmesi;
- unsafe path veya symlink.

İlk ikisi UI/viewer friction, diğerleri integrity problemidir. Protokol önce
retry ve mevcut verification/reconciliation sonucuna bakar. Kanıt tamamlanana
kadar olay `suspected` kalır; confirmed olmayan olay ne “yok” sayılır ne de
yanlışlıkla confirmed data corruption yazılır.

## Veri kaybı şüphesinde neden hemen stop var?

Şüpheyi araştırırken normal kullanıma devam etmek:

- yeni mutation'larla kanıtı değiştirebilir;
- mevcut verinin ne zaman bozulduğunu belirsizleştirebilir;
- yanlış artifact paylaşımını büyütebilir.

Bu nedenle akış:

```text
observed signal
-> pilot stop
-> anonymous incident ID
-> yeni mutation/paylaşım yok
-> mümkünse yeni path'e Backup + verifier
-> source ve archive read-only inceleme
-> confirmed veya disproved
-> açık owner restart kararı
```

Hassas kanıt GitHub Issue veya bu repository'ye yüklenmez. GitHub'a yalnız
sanitize edilmiş olay sınıfı ve acceptance sonucu yazılabilir.

## Private/project sınırı ölçümde nasıl korunuyor?

ADR-0001'e göre project bağlantısı scope değildir. Private follow-up projeye
bağlı olabilir ve yine de resmî çıktıya giremez. ADR-0003'e göre Günlük Çıktı,
Backup, Hafızayı İndir ve Proje Paketi farklı ailelerdir.

Pilot logu bu nedenle şunları yazmaz:

```text
source_id
title
search_text
project_name
attachment_path
artifact_payload
```

Yalnız şunları yazabilir:

```text
artifact_event_id
artifact_family
eligibility_evidence = complete | uncertain
leakage_result = PASS | SUSPECTED | CONFIRMED_LEAK
```

Eligibility belirsizse artifact paylaşılmaz. Warning ile private içeriği
paylaşmak fail-closed yaklaşım değildir.

## Günlük şablonun çalışma akışı

```text
Gün kimliğini ve exact build'i yaz
-> açık stop/incident kontrol et
-> ilk 3 capture + ilk 2 retrieval ölç
-> bütün safety/fallback olaylarını census olarak kaydet
-> due follow-up reconciliation yap
-> attachment ve Backup/Restore sonuçlarını ayır
-> measurement completeness hesapla
-> warning/blocker listesi
-> owner CONTINUE veya STOP kararı
-> privacy checklist
```

Inactive gün sahte denemelerle doldurulmaz. `inactive_day` olarak kaydedilir.
Minimum sample oluşmazsa summary `INSUFFICIENT_EVIDENCE` olur.

## Summary karar sırası

Karar sırası özellikle önemlidir:

```text
1. Safety ve privacy blocker var mı?
2. Backup/Restore gate geçti mi?
3. Ölçüm yeterli ve güvenilir mi?
4. Capture/retrieval hedefleri nasıl?
5. Fallback nedenleri ve trendi ne?
6. Owner açıkça devam ediyor mu?
```

Önce performans ortalamasına bakmak yanlış olur. Veri kaybı `1` iken capture
median'ının 10 saniye olması pilotu başarılı yapmaz.

## Test kodu neyi doğruluyor?

Mevcut subprocess kabul testi gerçek interpreter sınırını kullanır:

```python
def test_real_process_a_b_c_restart_export_backup_restore(tmp_path: Path) -> None:
    source = tmp_path / "source"
    handoff = tmp_path / "handoff.json"
    export = tmp_path / "daily.zip"
    backup = tmp_path / "field.csebackup.zip"
    restored = tmp_path / "restored"
```

Satır satır:

- `tmp_path`, gerçek kullanıcı data root'undan izole temporary dizindir.
- `source`, A/B process'lerinin kullandığı source köktür.
- `handoff`, subprocess'ler arasında sentetik kimlik ve beklenen değerleri
  taşır; ürün Proje Paketi değildir.
- `export` ve `backup`, iki ayrı artifact ailesinin test çıktısıdır.
- `restored`, source'tan ayrı clean target'tır.

Test sonra Process A/B/C'yi ayrı Python process'leriyle çağırır ve şunları
kanıtlar:

- kayıt ve attachment restart'tan sağ çıkar;
- revision ve append-only event history korunur;
- Günlük Çıktı ve Backup oluşur;
- Backup verifier geçer;
- Restore yeni hedefte açılır;
- attachment byte/hash ve web detail route çalışır.

Bu executable test pilotun yerine geçmez. Test sentetik ve deterministiktir;
pilot gerçek kullanım sürtünmesi, geri bulma, fallback ve insan güvenini ölçer.

## Bu Issue'da neden yeni Python testi yok?

Davranış değişmedi. Yeni Python testi eklemek telemetry veya pilot runner gibi
uygulanmamış bir davranışı varmış gibi gösterebilirdi. Bunun yerine:

- mevcut full test suite regresyon için çalıştırılır;
- production/test diff'inin boş olması doğrulanır;
- Markdown tabloları ve allowlist kontrol edilir;
- boş şablonlarda gerçek ölçüm bulunmadığı gözlemlenir.

Gerçek pilot runner daha sonra istenirse ayrı production/test Issue'ı ve daha
yüksek riskli model/reasoning seçimi gerekir.

## Teknik karar tablosu

| Karar | Neden | Reddedilen kısa yol | Kanıt |
|---|---|---|---|
| Median + p90 + failure rate birlikte | Tipik, uç ve başarısız deneyimi ayrı gösterir | Yalnız average | Exact formül ve minimum sample |
| Performans sample, safety census | Ölçüm yükünü azaltırken risk saklanmaz | Bütün olayları zamanlamak veya safety'yi örneklemek | Günlük cap + eksiksiz incident sayımı |
| Suspected olayda stop | Kanıt mutation ile bozulmasın | Kanıt çıkana kadar normal kullanıma devam | Incident state ve owner restart gate |
| Backup verify ve Restore ayrı metrik | Artifact bütünlüğü ile yeniden açılabilirlik aynı değildir | Tek “backup başarılı” checkbox'ı | M06 ve M07 ayrı numerator/denominator |
| Gerçek içerik loglama yok | Pilot ölçümü yeni privacy riski üretmesin | Screenshot, source dump, ham mesaj | Anonim event ID ve privacy checklist |
| Minimum sample yoksa insufficient evidence | Sıfır/az veri başarı sayılmasın | `N/A` değerleri PASS yapmak | M10 ve gate kuralları |
| Safety blocker conditional olamaz | Düzeltme planı mevcut ihlali silmez | Blocker + plan = PASS | Yeni revalidation window |
| Pilot bu Issue'da yürütülmedi | Documentation ile saha kanıtı karışmasın | Boş şablonu completion saymak | Açık non-goal ve ayrı executable Issue |

## Şunu şöyle yaptık ki...

Şunu şöyle yaptık ki, kayıt açma ve geri bulma hızını tek bir iyi örnekle değil
median, p90, failure rate ve minimum sample ile birlikte değerlendirdik. Böylece
tipik hız iyi görünürken başarısız veya aşırı yavaş deneyimler saklanmadı.

Şunu şöyle yaptık ki, performance olaylarını sınırlı örnekledik ama veri kaybı,
missed follow-up, attachment, Backup/Restore ve privacy olaylarını eksiksiz
saydık. Böylece ölçüm kullanıcıyı gereksiz yavaşlatmadı ve safety riski sample
dışında kalmadı.

Şunu şöyle yaptık ki, pilot logunu source record veya debug dump yapmadık.
Gerçek metin, kimlik, proje/kişi ve dosya ayrıntısı yerine anonim event ID,
süre, sayaç, kategori ve sonuç kullandık.

Şunu şöyle yaptık ki, Backup verifier PASS ile clean Restore PASS'i ayırdık.
Dosyanın bütünlüğü doğru olsa bile repository reopen veya attachment
reconciliation başarısız olabilir; iki güvence birbirinin yerine geçmez.

Şunu şöyle yaptık ki, Issue #167'de gerçek pilot sonucu yazmadık. Boş protokol
ve şablonların saha kabulüymüş gibi sunulmasını önledik; gerçek karar ayrı
executable pilot Issue'ına kaldı.

## Yeni teknik terimler

Issue allowlist'i `learning/GLOSSARY.md` dosyasını kapsamadığı için global
sözlük değiştirilmedi. Bu not içindeki tanımlar:

- **Metric:** Aynı formül ve veri kaynağıyla tekrarlanabilir ölçüm.
- **Numerator / denominator:** Bir oran veya başarı yüzdesinin payı ve paydası.
- **Median:** Sıralı örneğin ortanca değeri.
- **p90:** Nearest-rank yöntemiyle denemelerin yaklaşık yüzde 90'ını kapsayan
  üst süre sınırı.
- **Sampling:** Olayların önceden tanımlı alt kümesini ölçme.
- **Census:** Kapsamdaki bütün olayları sayma.
- **Baseline:** Sonraki dönemin karşılaştırıldığı ilk ölçüm seviyesi.
- **Warning threshold:** Araştırma veya düzeltme planı gerektiren eşik.
- **Blocker threshold:** Pilotun durmasını veya PASS verilmemesini gerektiren
  eşik.
- **Incident escalation:** Şüpheli olayın stop, kanıt koruma, sınıflandırma ve
  yeniden başlatma kapılarıyla yönetilmesi.
- **Disposable target:** Gerçek data root'tan ayrı, var olmayan ve yalnız
  Restore provası için seçilen hedef.
- **Measurement completeness:** Beklenen zorunlu ölçüm alanlarının zamanında ve
  geçerli doldurulma oranı.
- **Insufficient evidence:** Başarı veya başarısızlık kararı için kanıtın
  yetersiz olması; PASS değildir.

Bu terimler global glossary'ye eklenecekse dosyayı açıkça yetkilendiren ayrı bir
Issue gerekir.
