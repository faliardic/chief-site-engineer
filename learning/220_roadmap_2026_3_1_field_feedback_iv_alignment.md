# Issue #220 — Roadmap Sırasını Kod Yazmadan Güvenle Değiştirmek

## Amaç

Bu adımda production kodu yazmadık. Bunun yerine saha geri bildirimlerini hangi
sırayla production Issue'larına dönüştüreceğimizi kanonik belgeye işledik.

Öğrenme hedefi şudur:

> Bir roadmap değişikliğinin de sözleşme değişikliği olduğunu, fakat bu
> sözleşmenin test ve doğrulama yönteminin production kodundan farklı olduğunu
> görmek.

## Önce hangi kaynakları okuduk?

Zorunlu okuma sırası:

```text
AGENTS.md
→ CSE_UNIFIED_PROJECT_SOURCE.md
→ CSE_PROJECT_INSTRUCTIONS.md
→ CSE_MINIMUM_SUFFICIENT_VALIDATION_PROTOCOL.md
→ GitHub Issue #220
→ .cse/tasks/220_task.md
→ new-chat bootstrap ve source register
```

Burada önemli bir çelişki yakaladık: `.cse/tasks/220_task.md`, güncel GitHub
Issue #220'yi değil tarihsel “Step 220 / Issue #57” işini anlatıyordu.

Kaynak önceliği bize şu kararı verdi:

```text
current GitHub Issue #220
    > stale .cse task/state aynası
```

`>` işareti burada “daha yetkili” anlamındadır. Current Issue exact allowlist'e
`.cse/tasks/220_task.md` dosyasını almadığı için stale dosyayı bu branch'te
düzeltmedik. Böylece iyi niyetli görünen fakat kapsam dışı olan ek değişiklik
yapmadık.

## Başlangıç Git sözleşmesini nasıl doğruladık?

Issue tam olarak şu güvenli noktayı istedi:

```text
master == origin/master == d4ccc480570a971cf014ddbe00122ec6132cad01
tracked working tree == clean
```

Kullanılan doğrulama mantığı:

```powershell
$masterSha = git rev-parse master
$originSha = git rev-parse origin/master
$divergence = git rev-list --left-right --count origin/master...master

if ($masterSha -ne 'd4ccc480570a971cf014ddbe00122ec6132cad01') {
    throw 'Unexpected master SHA.'
}
if ($masterSha -ne $originSha) {
    throw 'master and origin/master differ.'
}
if ($divergence -ne "0`t0") {
    throw 'master divergence is not 0 0.'
}
```

Satır satır:

1. `git rev-parse master`, yerel `master` branch'inin commit kimliğini okur.
2. `git rev-parse origin/master`, son fetch ile bilinen uzak `master` kimliğini
   okur.
3. `git rev-list --left-right --count`, iki branch'te yalnız bir tarafta kalan
   commit sayılarını ölçer.
4. İlk `if`, Issue'nin verdiği exact güvenli commit dışında çalışmayı durdurur.
5. İkinci `if`, aynı görünen branch adlarının farklı commit'lere işaret etmesini
   engeller.
6. Üçüncü `if`, iki yönlü commit farkının `0 0` olduğunu zorunlu kılar.

Untracked `device-backups/` ve `reports/` kullanıcı alanları okunmadı,
silinmedi, taşınmadı veya stage edilmedi. Issue yalnız temiz **tracked** çalışma
ağacı istedi; kullanıcı dosyalarını “temizlemek” güvenli bir işlem değildir.

## Roadmap'te gerçek olarak ne değişti?

### 1. Sürüm başlığı ve tarih

Gerçek Markdown sözleşmesi:

```markdown
# CSE 2026.3.1 — Asistan-Öncelikli Ürün Yol Haritası

**Tarih:** 25 Temmuz 2026
**Güncel saha backlog'u:** #219
**Açık Release 0.1 pilotu:** #193
```

Satır satır:

1. `2026.3.1`, mevcut büyük yönü değiştirmeyen fakat saha geri bildirimiyle
   revize edilen roadmap sürümünü gösterir.
2. Tarih, kararın hangi saha incelemesine dayandığını görünür kılar.
3. `#219`, yeni backlog sırasının kanonik kaynağıdır.
4. `#193`, pilotun kapatılmadığını başlık seviyesinde görünür tutar.

### 2. Faz 0 ile Faz 1 arasındaki yeni kapı

Roadmap'e eklenen ana başlık:

```markdown
## Faz 0.1 — Release 0.1.1: Günlük Güvenilirlik / Sadeleştirme
```

Bu numarayı seçme nedeni:

- Mevcut Faz 0 pilotunu yeniden adlandırmamak.
- Universal Capture olan Faz 1'i ileri taşımadan sırasını korumak.
- Araya giren işin ayrı bir güvenilirlik kapısı olduğunu göstermek.

Roadmap'in ana akışı artık şöyledir:

```text
Faz 0: Release 0.1 saha pilotu
    |
    +-- pilot açık kalır
    |
Faz 0.1: Release 0.1.1 günlük güvenilirlik
    |
    +-- 1. reminder scheduling
    +-- 2. birleşik Bugün
    +-- 3. recoverable trash
    +-- 4. kaynak attachment görünürlüğü
    +-- 5-12. Beton, attachment ve günlük saha araçları
    +-- 13. ertelenmiş hava durumu
    |
Faz 1: Universal Capture
    |
Faz 2: Open Loop
```

### 3. İlk production child

Roadmap'te şu cümle açıkça yer alır:

```markdown
İlk production child #221 Reminder scheduling contract'tır.
```

Bu cümle neden önemlidir?

- “Sıradaki iş hangisi?” sorusunu yoruma bırakmaz.
- Docs branch'inde yanlışlıkla Blok 2 veya attachment refactor'ı başlatılmasını
  engeller.
- Reminder içindeki üç bağlı problemi tek contract altında tutar:
  `Bugün`, gerçek `Tam gün` ve legacy `Bekliyorum` temizliği.

## Üç benzer görünen kavramı nasıl ayırdık?

### Reminder `Bekliyorum`

Mevcut reminder yaşam döngüsündeki legacy status/schedule/filter yüzeyidir.
Release 0.1.1 içinde kaldırılacaktır.

### Open Loop `Beklediklerim`

Bir reminder status'ü değildir. Gelecekte kişi, konu, bekleme başlangıcı, son
görüşme ve sonraki takip gibi bilgileri taşıyan ayrı modeldir.

### `Tam gün`

Belirli bir saati olmayan gerçek takvim günü kaydıdır. 09:00, 18:00 veya 23:59
gibi uydurma bir saat verip “tam gün” denmez.

Bu ayrım şu yanlış tasarımı önler:

```text
Bekliyorum reminder status'ü
    ≠ Beklediklerim Open Loop kaydı

Tam gün
    ≠ gizlenmiş sahte saat
```

## Attachment kararını neden iki aşamaya böldük?

İki ihtiyaç aynı değildir:

```text
Ajanda → reminder kaynak attachment görünürlüğü
    = dar read-model / bağlantı görünürlüğü düzeltmesi

Ortak attachment v2
    = geniş persistence + migration + çoklu medya sözleşmesi
```

Önce mevcut kaynak bağlantısını görünür yapmak daha dar ve düşük risklidir.
Sonra fotoğraf, video, ses ve dosya için ortak attachment/link omurgası ayrı
Issue'da tasarlanabilir.

Değişmez ilke:

```text
1 fiziksel dosya
    +-- Ajanda bağlantısı
    +-- reminder bağlantısı
    +-- Beton bağlantısı
    `-- albüm bağlantısı
```

Burada dört kopya dosya yoktur. Tek managed dosyaya dört kayıt bağlantısı vardır.

## Beton keyword ve AI neden yalnız öneri?

`beton` veya `betonaj` kelimesinin geçmesi, kullanıcının gerçekten Beton Paketi
oluşturmak istediğini kanıtlamaz. Bu nedenle:

```text
kelime sinyali
    → öneri
    → kullanıcı kararı
    → gerekirse Beton paketine deep-link
```

Şu akış yasaktır:

```text
kelime sinyali
    → otomatik Beton kaydı
    → otomatik teknik karar
```

AI için de aynı güvenlik düşüncesi kullanılır. İlk adım uygulama içinden dış AI'ya
kopyalanabilen, kaynakları açık bir prompt export'tur. Gömülü model çağrısı,
otomatik gönderim veya sessiz veri mutasyonu yoktur.

## Hemen / sonraki / ertelenen / kapsam dışı ayrımı

| Grup | Anlam | Örnek |
|---|---|---|
| Hemen | Günlük güvenilirlik ve mevcut saha akışını doğrudan düzelten dar işler | #221, birleşik Bugün, trash/restore |
| Sonraki kontrollü sıra | Daha geniş persistence veya yeni yüzey gerektiren fakat kabul edilmiş işler | attachment v2, albüm, #204 UX, prompt export |
| Ertelenen | Ön koşul tasarımı veya haricî bağımlılığı henüz tamamlanmamış işler | hava servisi, embedded AI, iki yönlü PC sync |
| Kapsam dışı | Ürün ilkelerine aykırı veya bu ürünün hedefi olmayan işler | full ERP, auto hard-delete, duplicate attachment, otonom teknik karar |

“Ertelenen” ile “kapsam dışı” aynı şey değildir. Ertelenen iş doğru ön koşullar
sağlanınca yeniden değerlendirilebilir. Kapsam dışı karar ise bu ürün yönünde
yapılmaması gereken davranışı tanımlar.

## Hangi dosyada ne yaptık?

| Dosya | Değişiklik | Neden |
|---|---|---|
| `ROADMAP.md` | 2026.3.1 başlığı, başlangıç noktası, Faz 0.1, kanonik sıra ve backlog kuyruğu | Ürün uygulama sırasının tek kanonik yüzeyi |
| `CHANGELOG.md` | Issue #220 docs/governance değişiklik özeti | Değişiklik geçmişini görünür tutmak |
| `docs/project_decisions.md` | Kısa kalıcı karar maddeleri | Neden ve yasak sınırlarını kaydetmek |
| `docs/220_roadmap_2026_3_1_field_feedback_iv_alignment.md` | Ayrıntılı karar, kaynak, sıra, validation ve kanıt | Issue'nin inceleme belgesi |
| `learning/220_roadmap_2026_3_1_field_feedback_iv_alignment.md` | Bu öğrenme açıklaması | Python öğrenen kullanıcıya yürütme mantığını göstermek |

`learning/GLOSSARY.md` değiştirilmedi. Bu adımda kullanılan validation class,
evidence reuse, source-of-truth ve read-model gibi kalıcı teknik kavramlar mevcut
protokol ve glossary'de zaten tanımlıdır; yeni kalıcı terim üretilmedi.

## Validation kodu neyi doğruluyor?

Bu işin validation class'ı `docs` olduğu için Python/Flutter test kodu
çalıştırılmaz. Gerçek doğrulama komutları şunlardır:

```powershell
$allowed = @(
    'CHANGELOG.md',
    'ROADMAP.md',
    'docs/220_roadmap_2026_3_1_field_feedback_iv_alignment.md',
    'docs/project_decisions.md',
    'learning/220_roadmap_2026_3_1_field_feedback_iv_alignment.md'
)

$changed = @(git diff --name-only origin/master...HEAD)
$unexpected = @($changed | Where-Object { $_ -notin $allowed })
if ($unexpected.Count -ne 0) {
    throw "Unexpected changed files: $($unexpected -join ', ')"
}
```

Satır satır:

1. `$allowed`, Issue'nin exact changed-file allowlist'idir.
2. `git diff --name-only`, branch'te değişen dosya adlarını okur.
3. `Where-Object`, allowlist dışında kalan dosyaları seçer.
4. Beklenmeyen tek dosya bile varsa doğrulama fail-closed durur.

Whitespace ve patch bütünlüğü:

```powershell
git diff --check
```

Bu komut trailing whitespace ve bozuk patch işaretlerini yakalar.

Production diff boşluğu:

```powershell
git diff --exit-code origin/master...HEAD -- `
    app tests mobile scripts .github requirements.txt pyproject.toml
```

Satır satır:

1. Karşılaştırma tabanı güncel `origin/master`dır.
2. Yalnız production, test, script, workflow ve dependency yolları seçilir.
3. `--exit-code`, bu alanlarda diff varsa başarısız dönüş kodu verir.
4. Çıktının boş olması production koduna dokunulmadığının kanıtıdır.

Markdown başlık ve Issue referans kontrolü, dokümanlarda beklenen başlıkların,
`#193`, `#204`, `#219`, `#220` ve `#221` referanslarının bulunduğunu; yerel
Markdown linklerinin hedeflerinin mevcut olduğunu doğrular.

## Neden full test çalıştırmadık?

Issue'nin açık validation contract'ı şunları yasakladı:

```text
Python/Flutter full suite
flutter analyze
APK/AAB
signing
release gate
notification acceptance
backup/restore
fiziksel cihaz
```

Production davranışı değişmediği için bu kapılar yeni bilgi üretmeyecekti.
Üstelik PR #217, değişmeyen sözleşmeler için merged kanıtın yeniden kullanılmasını
özellikle ister.

Yeniden kullanılan kanıt:

- `d4ccc480...` güvenli master;
- #193 Gün 0 PASS ve kullanıcı tarafından gözlenen veri kaybı `0`;
- PR #217 minimum yeterli doğrulama protokolü;
- PR #218 merged `Yarın` görünümü.

## Teknik karar tablosu

| Karar | Seçim | Neden |
|---|---|---|
| Roadmap sürümü | `2026.3.1` | Büyük ürün yönü korunurken 25 Temmuz saha sırası revize edildi |
| Yeni katman | Faz 0.1 / Release 0.1.1 | Faz 0 pilotu ve Faz 1 Universal Capture adları korunur |
| İlk child | #221 Reminder scheduling | En temel gün/saat ve legacy waiting sözleşmesini önce düzeltir |
| Bugün ana yüzeyi | Birleşik, filtresiz başlangıç | Kullanıcı günlük işi görmek için filtre seçmek zorunda kalmaz |
| Silme | Recoverable trash/restore | Kullanıcı özgürlüğü ile veri güvenliğini birlikte korur |
| Attachment | Tek fiziksel dosya, çoklu link | Depolama ve backup çoğalmasını önler |
| Beton keyword | Öneri/deep-link | Yanlış otomatik kayıt ve teknik karar üretmez |
| AI ilk adımı | Kaynaklı prompt export | Kullanıcı kontrolünü ve kaynak izini korur |
| Hava durumu | Ertelenmiş | Haricî servis, offline ve eşik sözleşmesi henüz tasarlanmadı |
| Validation | `docs` | Yalnız dokümantasyon sırası değişti |
| Glossary | Değişmedi | Yeni kalıcı teknik terim yok |

## Kod/belge çalışma akışı

```text
Issue #220 okunur
    |
    +-- validation class = docs
    +-- exact allowlist belirlenir
    +-- production yolları yasaklanır
    |
Kaynaklar sırayla okunur
    |
    +-- #219 kanonik sıra düzeltmesi alınır
    +-- #193 pilotun açık olduğu doğrulanır
    +-- PR #217 validation bütçesi alınır
    +-- PR #218 güvenli master kanıtı alınır
    |
master == origin/master == d4ccc480 doğrulanır
    |
docs branch oluşturulur
    |
beş allowlist dosyası değiştirilir
    |
changed-file + Markdown + diff-check + production-empty doğrulanır
    |
tek commit → normal push → PR
    |
merge yapılmaz
```

## Şunu şöyle yaptık ki...

Şunu şöyle yaptık ki, gerçek saha pilotunu kapatmadan günlük kullanım
sürtünmelerini Universal Capture'ın önüne ayrı bir Release 0.1.1 kapısı olarak
yerleştirdik; böylece “yeni ve etkileyici özellik” baskısı doğru gün/saat, geri
alınabilir silme ve kaybolmayan attachment bağlantılarının önüne geçmesin.

Reminder `Bekliyorum` ile Open Loop `Beklediklerim` kavramlarını ayırdık ki
legacy bir status geleceğin kişi/taahhüt modelini yanlış biçimde belirlemesin.
Tek fiziksel attachment + çoklu bağlantı ilkesini görünür tuttuk ki Ajanda,
reminder, Beton ve albüm aynı dosyayı çoğaltmasın. AI ve Beton keyword akışını
öneri seviyesinde bıraktık ki uygulama kullanıcı adına sessiz kayıt veya teknik
karar üretmesin.

## Bilerek değiştirmediklerimiz

- Production Dart/Python kodu.
- Test kodu ve test davranışı.
- Schema veya migration.
- Backup formatı ve restore zinciri.
- Notification motoru.
- Issue #216 PowerShell/release altyapısı.
- APK, AAB veya RC artifact'leri.
- Fiziksel cihaz ve gerçek kullanıcı verisi.
- #193 pilot state'i.
- `.cse/tasks/220_task.md` ve `.cse/state/project_state.json` stale aynaları.
- `learning/GLOSSARY.md`.
- Blok 1 veya sonraki production implementation.
