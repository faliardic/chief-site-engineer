# Issue 145 — Tek Hafıza ve Kayıt Kapsamı ADR'si

## Bu adımda ne öğrendik?

Bu adımda production Python kodu yazmadık. Bunun yerine gelecekte yazılacak
scope alanı, Hafıza ekranı, `MemoryIndex`, export ve migration kodlarının aynı
anlamı kullanmasını sağlayan bir mimari karar kaydı hazırladık.

Çözdüğümüz temel çelişki şuydu:

```text
Kullanıcı tek kişi ve bütün kayıtlarını tek yerde bulmak istiyor.
Ama her kayıt proje raporunda paylaşılmamalı.
```

Kararımız:

```text
Tek kullanıcı deneyimi: Hafıza
Paylaşım/çıktı sınırı: private | project
```

Bu iki karar birlikte çalışır. Tek Hafıza bütün kayıtları buldurur; kapsam ise
hangi kaydın hangi çıktıya girebileceğini sınırlar.

## Yeni ve kalıcı kavramlar

### ADR

ADR, “Architecture Decision Record” ifadesinin kısaltmasıdır. Türkçede mimari
karar kaydı diyebiliriz. Yalnız seçilen sonucu değil, problemi, alternatifleri,
neden bazı seçeneklerin reddedildiğini ve kararın sonuçlarını da saklar.

### Hafıza

Observation, follow-up, routine occurrence ve gelecekteki doküman, plan, iş
paketi ve hesap kayıtlarının ortak bulunabilirlik yüzeyidir. Hafıza, bütün
kayıtların tek database tablosunda tutulduğu anlamına gelmez.

### Kayıt türü

Bir kaydın hangi domain davranışına sahip olduğunu gösterir. Örneğin observation
kanıtlı saha gözlemidir; follow-up yeniden dikkat gerektiren konudur; routine
occurrence belirli bir günün rutin sonucudur.

### Kapsam

Bu ADR'de scope kelimesi görev sınırı değil, kayıtların çıktı/paylaşım kapsamıdır:

- `private`: şefin çalışma hafızası;
- `project`: belirli projenin çıktısına seçilmeye uygun kayıt.

Kapsam kullanıcı rolü, tenant, encryption veya lifecycle status değildir.

### Proje bağlantısı

Kaydın hangi projeyle ilişkili olduğunu gösteren referanstır. Projeye bağlı bir
kayıt yine `private` olabilir. Bu nedenle `project_id` ile kapsam aynı alan
değildir.

### Kapsam dönüşümü

Bir kaydın `private -> project` veya izinli durumda `project -> private`
değişmesidir. Açık kullanıcı işlemi, güncel revision ve append-only event
gerektirir.

### Fail-closed

Sistem güvenlik için gerekli kanıtı üretemiyorsa işlemi tahminle kabul etmez,
reddeder. Örneğin bir project kaydın daha önce rapora girip girmediği
kanıtlanamıyorsa `project -> private` dönüşümü reddedilir.

## Mevcut Python kodu bize ne söyledi?

### 1. `project_id` bugün kapsam değildir

`app/field_tracking.py` içindeki gerçek alanlar:

```python
@dataclass(frozen=True, slots=True)
class FollowUpItem:
    follow_up_id: str
    capture_text: str
    title: str
    created_at: str
    updated_at: str
    project_id: str | None = None
    observation_id: str | None = None
```

Satır satır:

- `@dataclass`, alanlardan oluşan sade bir Python kayıt sınıfı üretir.
- `frozen=True`, var olan nesnenin alanlarını yerinde değiştirmek yerine yeni
  revision nesnesi oluşturulmasını teşvik eder.
- `slots=True`, sınıfın taşıyabileceği alanları açık sözleşmeyle sınırlar.
- `follow_up_id`, kaydın değişmez kimliğidir.
- `capture_text`, hızlı `+ Unutma` sırasında ilk yazılan metindir.
- `title`, daha sonra düzenlenebilen görünen başlıktır.
- `project_id: str | None`, proje bağlantısının zorunlu olmadığını gösterir.
- `observation_id: str | None`, follow-up'ın observation ile ilişki
  kurabileceğini gösterir.

Burada `scope` alanı yoktur. `project_id` dolu olduğu için follow-up'ı bugün
`project` saymak, mevcut koda var olmayan bir anlam yüklemek olurdu.

### 2. Project atamak yalnız bağlantıyı değiştiriyor

`app/application/field_tracking.py` içindeki mevcut mutation özeti:

```python
if current.project_id == project_id:
    return current

occurred_at = self._now()
updated = replace(
    current,
    project_id=project_id,
    revision=current.revision + 1,
    updated_at=occurred_at,
)
```

Satır satır:

- İlk `if`, hedef proje zaten aynıysa gerçek no-op döndürür.
- `self._now()`, mutation'ın canonical UTC zamanını üretir.
- `replace(...)`, frozen dataclass'tan yeni değerlerle yeni nesne üretir.
- Yalnız `project_id` değiştirilir.
- `revision`, gerçek değişiklik olduğu için tam bir artar.
- `updated_at`, mutation zamanına eşitlenir.

Kod scope değiştirmiyor; çünkü henüz böyle bir alan ve use-case yok. ADR'nin
“project atamak kapsamı değiştirmez” kararı mevcut davranışla aynıdır.

### 3. Observation link'i de kapsam dönüşümü değildir

Mevcut link kodu:

```python
updated = replace(
    current,
    observation_id=observation.observation_id,
    project_id=observation.project_id,
    revision=current.revision + 1,
    updated_at=occurred_at,
)
```

Satır satır:

- Follow-up var olan observation kimliğini alır.
- Project bağlantısı observation'ın projesiyle eşitlenir.
- Revision artar ve değişiklik zamanı yazılır.
- Scope alanı olmadığı için link işlemi resmî çıktı yetkisi üretmez.

`convert_to_observation` adı ilk bakışta follow-up kaydının observation'a
dönüştüğünü düşündürebilir. Gerçek davranışta ayrı observation zaten vardır;
follow-up ona bağlanıp `converted_to_observation` sonucuyla kapanır. İki kaynak
kaydı tek satır olmaz. Bu yüzden ADR şu mapping'i seçti:

```text
kaynak follow-up -> private kalır
hedef observation -> project olur
```

### 4. Daily export yalnız observation hattını okuyor

`app/operations/exports.py` içindeki gerçek toplama akışı:

```python
with SQLiteUnitOfWork(self.database_path) as unit_of_work:
    projects = {
        project.project_id: project
        for project in unit_of_work.projects.list_all()
    }
    observations = unit_of_work.observations.list_all()
    for observation in observations:
        events = unit_of_work.events.list_for_observation(
            observation.observation_id
        )
        metadata = unit_of_work.attachments.list_for_observation(
            observation.observation_id
        )
```

Satır satır:

- Unit of Work, aynı database okuma sınırını açar.
- Project kayıtları isim ve kimlik eşleştirmesi için okunur.
- Export ana kayıt olarak yalnız observation listesini alır.
- Döngü her observation'ın event geçmişini okur.
- Attachment metadata yine observation üzerinden alınır.
- Follow-up, routine template veya routine occurrence repository'si okunmaz.

Bu nedenle ADR, yeni scope kodu yokken mevcut daily export'u değiştirmedi.
Gelecekte `project` scope eklenmesi, bütün project kapsamlı türlerin kendiliğinden
daily export'a gireceği anlamına gelmez. Her output formatı ayrı executable
sözleşme ister.

### 5. Backup bütün SQLite snapshot'ını taşıyor

`app/operations/backups.py` içindeki temel satır:

```python
def _snapshot_database(self, destination: Path) -> None:
    source = sqlite3.connect(self.database_path)
    target = sqlite3.connect(destination)
    try:
        source.backup(target)
    finally:
        target.close()
        source.close()
```

Satır satır:

- Kaynak SQLite database bağlantısı açılır.
- Backup çalışma alanındaki hedef database bağlantısı açılır.
- `source.backup(target)`, database'in tutarlı online snapshot'ını üretir.
- `finally`, başarı veya hata durumunda iki bağlantının da kapanmasını sağlar.

Snapshot yalnız observation tablosunu seçmez. Aynı SQLite içindeki follow-up,
routine ve event tablolarını da taşır. Bu gerçek, “Backup bütün kapsamları
içerir” kararının bugünkü teknik temelidir.

## Tek Hafıza neden tek tablo değildir?

Domain kayıtlarının farklı yaşam döngüleri vardır:

| Kayıt türü | Örnek yaşam döngüsü |
| --- | --- |
| Observation | `open -> tracking -> closed`, archive |
| Follow-up | `inbox -> active/waiting -> completed/cancelled`, reopen |
| Routine template | `active -> inactive` |
| Routine occurrence | `open -> closed`, snooze/reopen |

Hepsini tek tabloya zorlamak çok sayıda nullable alan, karmaşık validation ve
riskli migration üretirdi. Ortak bulunabilirlik daha sonra read-model ile
çözülebilir:

```text
Kaynak observation ---------\
Kaynak follow-up ------------> yeniden üretilebilir MemoryIndex -> Hafıza UI
Kaynak routine occurrence ---/
```

Kaynak tablolar gerçeği tutar. `MemoryIndex`, arama ve timeline için gerekli
ortak alanları yansıtır; kaynak kaydı sessizce değiştirmez.

## Başlangıç mapping'ini nasıl seçtik?

| Mevcut kayıt | Başlangıç kapsamı | Neden |
| --- | --- | --- |
| Observation | `project` | Project zorunlu ve mevcut daily export kaynağı |
| Follow-up | `private` | Bugünkü sözleşmede kişisel ve daily export dışı |
| Routine template | `private` | Bugünkü sözleşmede kişisel ve daily export dışı |
| Routine occurrence | `private` | Geçmiş occurrence template değişiminden bağımsız |

Önemli örnek:

```text
project_id dolu follow-up
!=
project scope follow-up
```

Migration bir gün scope alanı eklediğinde `project_id IS NOT NULL` tahmini
yapmayacak. Bütün mevcut follow-up ve routine kayıtları `private` backfill
edilecek.

## Kapsam dönüşüm akışı

Gelecekteki `private -> project` use-case'i şu sırayı izlemelidir:

```text
Kullanıcı “Proje kapsamına geçir” der
-> hedef proje görünür ve doğrulanır
-> güncel revision okunur
-> scope + gerekirse project_id aynı transaction'da yazılır
-> revision bir artar
-> scope_changed append-only event'i eklenir
-> commit
```

Project atama, observation link'i veya AI önerisi bu akışı kendiliğinden
başlatamaz.

`project -> private` daha sıkıdır:

```text
Observation / yayımlanmış snapshot / project document
-> her zaman reddet

Çalışma kaydı
-> daha önce çıktıya girmediğini doğrula
-> project bağımlı child/reference olmadığını doğrula
-> kullanıcıdan açık onay al
-> revision + event ile değiştir

Bu kanıt üretilemiyor
-> fail-closed reddet
```

## Çıktıları nasıl ayırdık?

| Çıktı | İçerik | Ana amaç |
| --- | --- | --- |
| Backup | `private` + `project`, bütün database ve attachment'lar | Felaket kurtarma |
| Hafızayı İndir | `private` + `project`, kapsam etiketli okunabilir arşiv | Şefin bütün hafızasını dışarı alma |
| Proje Paketi / günlük / rapor | Yalnız seçilen projenin `project` kayıtları | Güvenli paylaşım |

Private kaydı Proje Paketi'ne “bir kereliğine uyarıyla” eklemeyi reddettik.
Çünkü böyle bir bypass, kapsam event'i üretmeden paylaşım sınırını deler.
Kullanıcı önce kaydı açıkça project kapsamına geçirir, sonra pakette seçer.

## Mevcut test kodu bize neyi kanıtlıyor?

Bu Issue yeni test yazmadı; production davranışı değiştirmedi. Ancak mevcut
regresyon testi kararın geriye uyumluluk temelini gösteriyor:

```python
DailyExportService(root_a, **deterministic_export).build_daily_export(
    "2026-07-13", output_a
)
DailyExportService(root_b, **deterministic_export).build_daily_export(
    "2026-07-13", output_b
)

assert output_a.read_bytes() == output_b.read_bytes()
```

Bu testte:

- `root_a`, yalnız resmî observation fixture'ı taşır.
- `root_b`, aynı observation'a ek olarak private follow-up ve routine verisi
  taşır.
- Saat ve UUID üreticisi deterministic yapılır; böylece rastgele farklar
  karşılaştırmayı bozmaz.
- İki ZIP byte düzeyinde eşit olmalıdır.
- Sonraki assertion'lar takip metni, kimlikleri ve event türlerinin ZIP'e
  sızmadığını ayrıca doğrular.

Backup regresyonu ise takip kayıtlarını, routine occurrence'ları ve event
geçmişlerini restore sonrasında satır satır karşılaştırır:

```python
tracking_before = table_rows(source / "cse.sqlite3", TRACKING_TABLES)
backup.restore_backup(archive, target)

assert table_rows(target / "cse.sqlite3", TRACKING_TABLES) == tracking_before
```

Satır satır:

- İlk satır backup öncesi bütün tracking tablolarını okur.
- Restore yalnız yeni ve boş hedefe yapılır.
- Son assertion restore edilmiş tabloların backup öncesiyle aynı olduğunu
  kanıtlar.

Birlikte okunduğunda iki test şunu gösterir:

```text
Backup private veriyi korur.
Daily export private veriyi paylaşmaz.
```

ADR bu çalışan ayrımı isimlendirdi ve gelecekteki scope migration'ının onu
bozmamasını zorunlu kıldı.

## Gelecekte yazılacak testlerin karar matrisi

| Test girdisi | Beklenen |
| --- | --- |
| Projesiz follow-up create | `private` |
| Follow-up'a project ata | scope yine `private` |
| Private follow-up'ı observation'a bağla | follow-up `private`, observation `project` |
| Açık kullanıcı promotion'ı | `project`, revision +1, tek event |
| Aynı promotion tekrar çağrısı | no-op, yeni event yok |
| Stale revision | conflict |
| AI/link/project atama | scope mutation yok |
| Private kayıt Proje Paketi seçimi | reddedilir |
| Backup | iki kapsam da korunur |
| Observation demotion | reddedilir |
| Guard'sız çalışma kaydı demotion | fail-closed reddedilir |
| Template promotion | eski occurrence'lar değişmez |

## Teknik karar tablosu

| Soru | Seçilen karar | Neden |
| --- | --- | --- |
| Kullanıcı kaç ürün dünyası görür? | Tek Hafıza | Tek şef aynı bilgiyi iki yerde aramasın |
| Domain tabloları birleşir mi? | Hayır | Yaşam döngüleri ve migration güvenliği korunsun |
| Scope rol müdür? | Hayır | Ürün tek kullanıcılıdır |
| Project bağlantısı scope mudur? | Hayır | Projeye bağlı private takip geriye uyumlu kalsın |
| Private kayıt pakete doğrudan eklenir mi? | Hayır | Sessiz/tek seferlik veri sızıntısı olmasın |
| Promotion otomatik olabilir mi? | Hayır | Kullanıcı intent'i ve audit izi korunsun |
| Observation private'a dönebilir mi? | Hayır | Kanıt/proje geçmişi daraltılmasın |
| Çalışma kaydı geri dönebilir mi? | Yalnız kanıtlı ve yayımlanmamışsa | Yanlış sınıflandırma düzeltilebilsin, geçmiş çıktı gizlenmesin |
| Backup private veriyi içerir mi? | Evet | Felaket kurtarmada veri kaybı olmasın |

## Hangi dosyada ne yaptık?

- `docs/adr/ADR-0001-single-memory-and-record-scope.md`: bağlayıcı ürün ve
  veri kararı, mapping, dönüşüm, çıktı ve acceptance matrisleri.
- `learning/145_single_memory_and_record_scope_adr.md`: mevcut Python ve test
  kodu üzerinden kararın öğretici açıklaması.
- `ROADMAP.md`: Issue #145'in Faz 0 içindeki aktif ADR işi ve sınırı.
- `CHANGELOG.md`: documentation/state-only değişiklik kaydı.
- `docs/project_decisions.md`: kısa ve kalıcı karar maddeleri.
- `.cse/state/project_state.json`: aktif Issue, branch, base ve kararın factual
  makinece okunabilir aynası.
- `.cse/tasks/145_task.md`: izinli kapsam ve doğrulama sözleşmesi.
- `.cse/results/145_result.md`: test, diff, korunan yollar ve Git kanıtı.

## Kod çalışma akışı

```text
Issue #145 ve parent Epic'leri oku
-> master = origin/master = beklenen SHA doğrula
-> issue branch'ini tam base commit'ten oluştur
-> mevcut model/application/export/backup davranışını oku
-> proje bağlantısı ile kapsamı ayır
-> ADR ve executable acceptance matrisini yaz
-> roadmap/changelog/decision/state kayıtlarını hizala
-> full suite + compile + JSON + diff kontrollerini çalıştır
-> tek ordinary commit
-> normal push
-> Issue #145 completion evidence
```

## Şunu şöyle yaptık ki...

Tek Hafıza kararını kaynak tabloları birleştirmeden verdik ki kullanıcı bütün
kayıtlarını tek yerde bulabilsin ama observation, follow-up ve routine yaşam
döngüleri sade ve test edilebilir kalsın.

`project_id` ile scope'u ayırdık ki projeye bağlı mevcut kişisel takipler
yanlışlıkla resmî daily export veya Proje Paketi'ne sızmasın.

Private kaydın Proje Paketi'ne doğrudan seçilmesini yasakladık ki tek seferlik
bir uyarı kalıcı paylaşım kararının, revision'ın ve append-only event'in yerini
almasın.

Observation'a bağlı veya observation'a dönüştürülmüş eski follow-up'ı yine
`private` kabul ettik ki bugünkü byte-identical daily export izolasyonu
bozulmasın; project olan kayıt hedef observation olarak ayrı kalsın.

Backup'ı bütün kapsamlarla tanımladık ki cihaz veya database kaybında “private
olduğu için yedeklenmemiş” veri oluşmasın.

`project -> private` dönüşümünü fail-closed yaptık ki daha önce paylaşılmış bir
kayıt yalnız ekrandaki etiketi değiştirilerek geçmiş çıktılardan silinmiş gibi
gösterilmesin.

## Bilinçli olarak yapmadıklarımız

- Python production kodu değiştirmedik.
- Test veya fixture değiştirmedik.
- Scope enum/field eklemedik.
- Schema veya migration yazmadık.
- MemoryIndex uygulamadık.
- UI, template veya CSS değiştirmedik.
- Backup/daily export formatı değiştirmedik.
- Gerçek kullanıcı data root'una erişmedik.
- PR açmadık veya merge yapmadık.
