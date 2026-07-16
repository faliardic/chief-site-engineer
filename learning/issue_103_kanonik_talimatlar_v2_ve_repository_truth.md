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

Ana çalışma verisinin veri sahibinin kendi cihazlarında tutulduğu ürün yaklaşımıdır. `Local-first`, `Windows-first` demek değildir: telefon, bilgisayar veya daha sonra seçilecek başka bir owner device aynı kişisel veri sınırında olabilir. Bu yaklaşım otomatik olarak encryption, uygulama kilidi veya başka işletim sistemi kullanıcılarına karşı gizlilik sağlamaz.

### Mobile-first

Saha akışının önce telefon ekranı, dokunma hareketi, bağlantı kesintisi ve birkaç saniyelik kullanım süresi düşünülerek tasarlanmasıdır. Mobile-first, bütün kodun telefonda yazılması değil; ilk gerçek kullanıcı deneyiminin şantiye şefinin sahadaki ana cihazına göre doğrulanmasıdır.

### Single-owner security

Çok kullanıcılı rol matrisi yerine tek veri sahibinin cihaz ve yedek güvenliğini koruyan yaklaşımdır. Uygulama kilidi, mümkünse cihaz biyometrisi, güvenilen cihazlar, şifreli backup, owner-only telefon–PC senkronizasyonu ve güvenli yerel ağ bu sınırın parçalarıdır.

### Deprecation

Bir sınıfı veya API’yi hemen silmeden, yeni geliştirmede tercih edilmeyeceğini ve kontrollü biçimde başka bir yapıya dönüştürüleceğini ilan etmektir. Deprecation fiziksel silme değildir; önce kullanım envanteri, karşılık doğrulaması ve test güvenliği gerekir.

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

## Ürün sırası neden düzeltildi?

İlk commit, minimum hesap ve günlük zaman çizelgesini pilot sonrasına atıyordu. Bu teknik olarak sade görünse de ürün kabul ölçütünü karşılamıyordu: şantiye şefi hesap müsveddesi ve akşam yeniden yazılan günlük için hâlâ kâğıda ihtiyaç duyacaktı.

Epic #105 sırası bu nedenle şöyledir:

| Faz | Karar | Neden |
| --- | --- | --- |
| 0 | Tek kullanıcı yönünü kanonikleştir | Yanlış multi-user/kurumsal varsayımlar sonraki mimariyi yönlendirmesin |
| 1 | Transactional service ve lazy backfill | Repository primitive’lerini atomik use-case akışına dönüştürür |
| 2 | Backup/restore ve export izolasyonu | Kişisel takip kaybolmasın, resmî çıktıya istemeden sızmasın |
| 3 | Mobil runtime ve veri sahipliği ADR | Telefon–PC veri otoritesi koddan önce kesinleşsin |
| 4 | Kâğıdı Bırakma Sürümü | Not, takip, attachment, minimum hesap ve günlük taslağı tek akışta birleşsin |
| 5 | Offline ve bildirim güvenilirliği | Sahada ağ yokken kayıt kaybolmasın ve takip teslim edilsin |
| 6–7 | 7 ve 30 günlük pilotlar | Kâğıda dönüş nedenleri ve gerçek sürtünme ölçülsün |
| 8 | Gelişmiş hesap defteri | Minimum hesap şeridi gerçek kullanım verisiyle büyüsün |
| 9 | Günlük yayın/revizyon zinciri | Düzenlenebilir taslak kontrollü immutable kayda dönüşsün |
| 10 | Canlı Proje Haritası | Kaynak kayıtlar doğrulandıktan sonra read-model değer üretsin |
| 11 | Kanıtlanmış kişisel yardımcılar | Yalnız sahada karşılığı görülen araçlar eklensin |
| 12 | Kişisel AI | AI temiz ve denenmiş kişisel veri omurgasının üstüne gelsin |

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

Nihai düzeltme turu ilk commit’i yeniden yazmadı:

```text
Epic #105 ve Issue #103 nihai yorumunu oku
-> mevcut branch head = 2dd38c... doğrula
-> remote divergence = 0 0 doğrula
-> aynı branch üzerinde yalnız allowlist dosyalarını düzelt
-> full suite + compile + JSON + protected diff kontrolleri
-> tek normal correction commit
-> normal push
-> Issue #103 yeni factual evidence
```

Buradaki “aynı branch” önemlidir. `amend`, `rebase` veya force-push yapılmadığı için ilk commit tarihsel kanıt olarak kalır; yeni karar ikinci normal commit ile görünür olur.

## Hangi dosyada ne yaptık?

- `CSE_UNIFIED_PROJECT_SOURCE.md`: tek kullanıcı ürün kimliği, single-owner security, Epic #105 sırası, Kâğıdı Bırakma kapsamı ve legacy envanter yönü.
- `CSE_PROJECT_INSTRUCTIONS.md`: kalıcı politika ile değişken state ayrımı, tek kullanıcı değişmezi, mobil-first öncelik, Issue branch standardı ve current-state doğrulama prosedürü.
- `CSE_NEW_CHAT_GITHUB_BOOTSTRAP.md`: yeni sohbetin stale state yerine GitHub'dan devam etme sırası.
- `README.md`: gerçek Local Field MVP kabiliyetleri, tek sahipli ürün modeli, launcher kullanımı ve güvenlik sınırları.
- `ROADMAP.md`: Epic #105 Faz 0–12, Faz 4 minimum yüzeyi ve legacy envanter görevi.
- `.cse/state/project_state.json`: safe point ile aktif düzeltme işinin ayrılması ve aynı faz sırasının makinece okunabilir aynası.
- `CHANGELOG.md` ve `project_decisions.md`: bu adımın tarihsel değişiklik ve kalıcı karar izi.

## Gerçek kod envanterini nasıl okuduk?

Bu görev production kodunu değiştirmedi. Fakat legacy yönünü tahminle yazmamak için mevcut sınıfları salt okunur inceledik.

`app/models.py` içindeki eski takip modeli:

```python
@dataclass
class TrackingRecord:
    record_id: str
    project_id: str
    title: str
    description: str
    date: str
    responsible_party: str | None = None
    status: str = "open"
```

Satır satır:

- `@dataclass`, sınıfın alanlardan oluşan sade bir veri taşıyıcısı olduğunu gösterir.
- `record_id` eski modelin kimliğidir.
- `project_id` zorunludur; yeni `FollowUpItem` ise kişisel/projesiz takibi desteklemek için nullable project taşır.
- `responsible_party` bir metindir; bu alan başka bir sistem kullanıcısı veya görev atama hesabı anlamına gelmez.
- `status`, eski serbest metinli yaşam döngüsüdür; yeni takip modelinde enum ve daha sıkı değişmezler vardır.

Yeni aktif takip çekirdeği `app/field_tracking.py` içindedir:

```python
@dataclass(frozen=True, slots=True)
class FollowUpItem:
    follow_up_id: str
    capture_text: str
    title: str
    created_at: str
    updated_at: str
    project_id: str | None = None
    related_person: str | None = None
    next_attention_at: str | None = None
    deadline_at: str | None = None
    revision: int = 1
```

Satır satır teknik fark:

- `frozen=True`, nesne kurulduktan sonra alanların doğrudan değiştirilememesini sağlar.
- `slots=True`, alan sözleşmesini dar ve bellek kullanımını öngörülebilir tutar.
- `capture_text`, `+ Unutma` akışındaki ilk kullanıcı içeriğidir.
- `project_id: str | None`, kişisel takibin projeye bağlanmadan yaşayabilmesini sağlar.
- `related_person`, kayıt bağlamıdır; kullanıcı hesabı değildir.
- `next_attention_at`, konunun tekrar ne zaman görünmesi gerektiğidir.
- `deadline_at`, gerçek son tarihtir; dikkat zamanı ile aynı kavram değildir.
- `revision`, optimistic concurrency kontrolünün temelidir.

Bu yüzden karar “`TrackingRecord` dosyasını hemen sil” olmadı. Doğru karar şudur:

```text
önce kullanım envanteri
-> yeni karşılığı doğrula
-> import/test tüketicilerini bul
-> deprecation planı
-> ayrı yetkili görev
-> ancak kanıt varsa fiziksel temizlik
```

## Attachment örneği neden aynı yaklaşımı gerektiriyor?

Gerçek kodda iki model birlikte bulunuyor:

```python
@dataclass
class AttachmentRecord:
    """Represents the legacy generic attachment reference model."""

@dataclass
class FileAttachmentRecord:
    """Represents the canonical file attachment metadata model."""
```

İlk docstring açıkça `legacy`, ikincisi `canonical` diyor. Buna rağmen import kullanan tarihsel testler veya repository’ler bulunabilir. Bu nedenle sınıf adını görmek silme yetkisi vermez; yalnız envanter için güçlü bir sinyal verir.

## Teknik karar tablosu

| Eski aday | Yön | Bu görevde yapılan |
| --- | --- | --- |
| `TrackingRecord`, `TaskCandidateRecord` | `FollowUpItem` | Sadece envanter/deprecation kararı |
| `AttachmentRecord`, `FileAttachmentRecord` | Kalıcı metadata/store | İki modelin gerçek kod varlığı doğrulandı |
| `DailySiteLog`, `DailyReportRecord` | Gelecekte `DailyLogSnapshot` | Minimum taslak ile immutable yayın ayrıldı |
| Party/contact/supplier modelleri | Tek kişi/kurum referansı | Bunların kullanıcı hesabı olmadığı yazıldı |
| Meeting/RFI/Submittal | Not + takip + beklenen cevap | Ayrı kurumsal workflow hedefi çıkarıldı |
| NCR prototip zinciri | Gözlem + aksiyon + kanıt + sonuç | Silme yapılmadan yeniden değerlendirme yönü |
| `app/records.py` in-memory repository’leri | SQLite karşılığı sonrası deprecation | Production dosyası değiştirilmedi |

## State JSON düzeltmesi

Yeni state aynası ürün yönünü string listelerle açıkça taşır:

```json
{
  "product_identity": "local_first_mobile_first_single_owner_personal_field_assistant",
  "product_owner_user": "site_manager_only",
  "binding_product_roadmap": [
    "phase_0_issue_103_single_owner_direction_correction",
    "phase_1_field_tracking_transactional_service_and_seven_day_lazy_backfill",
    "phase_2_backup_restore_compatibility_and_official_export_isolation",
    "phase_3_mobile_runtime_and_data_ownership_adr",
    "phase_4_mobile_first_paperless_field_slice"
  ]
}
```

Satır satır:

- `product_identity`, ürünün hem local-first hem mobile-first hem de single-owner olduğunu tek değerde görünür yapar.
- `product_owner_user`, tek gerçek kullanıcıyı makinece okunabilir biçimde kaydeder.
- `binding_product_roadmap`, sıra kaymasının README veya ROADMAP içinde sessizce oluşmasını yakalamayı kolaylaştırır.
- Faz 1 ve sonrası listede bulunur ama “tamamlandı” olarak işaretlenmez; bu liste sıra sözleşmesidir, completion iddiası değildir.

## Şunu şöyle yaptık ki...

Kalıcı talimatlardan sabit eski commit ve test snapshot'larını çıkardık ki belge birkaç merge sonra yeniden yanlış bir “güncel durum” kaynağına dönüşmesin.

Aktif işi `current_safe_point` içine yazmadık ki merge edilmemiş branch tamamlanmış gibi görünmesin.

README'yi production kabiliyeti varmış gibi abartmadan güncelledik ki kullanıcı hem çalışan local uygulamayı görebilsin hem de uygulama kilidi, mobil runtime, offline, notification ve Saha Takibi application service/UI gibi eksikleri açıkça bilsin.

Minimum hesap şeridi ile günlük zaman çizelgesini Kâğıdı Bırakma Sürümü’ne aldık ki şantiye şefi takip için telefonu kullanırken hesap ve akşam yeniden yazma için tekrar kâğıda dönmesin.

Gelişmiş hesap defteri, immutable günlük yayın zinciri ve Harita’yı ayrı sonraki fazlarda tuttuk ki ilk mobil pilot gereksiz karmaşıklaşmasın; fakat pilotun kâğıdı gerçekten bırakmaya yetecek minimum bütünlüğü eksilmesin.

Multi-user/role/tenant/SaaS hedeflerini “daha sonra” listesinden tamamen çıkardık ki tek şantiye şefi için tasarlanan veri ve ekranlar gelecekteki hayalî kurumsal kullanıcılar uğruna karmaşıklaşmasın.

Legacy sınıfları silmedik, yalnız envanter/deprecation yönü verdik ki mevcut import, test ve tarihsel veri sözleşmeleri ayrı kanıt olmadan kırılmasın.

## Bilinçli olarak yapmadıklarımız

- Python production kodunu değiştirmedik.
- Test veya fixture değiştirmedik.
- Schema/migration çalıştırmadık.
- Gerçek kullanıcı data root'una erişmedik.
- Backup/export/ZIP artifact üretmedik.
- `reports/` kullanıcı dosyalarına dokunmadık.
- PR açmadık veya merge yapmadık.
