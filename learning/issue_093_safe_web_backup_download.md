# Issue 93 - Güvenli Tek Tık Web Yedeği

## 1. Bu adımda ne yaptık?

Gözlem listesine kullanıcının klasör, dosya adı veya filesystem yolu girmeden
tam veri yedeği oluşturabileceği bir yüzey ekledik. Kullanıcı yalnız
`Yedek oluştur ve indir` düğmesine basar. Uygulama mevcut `BackupService`
üzerinden SQLite snapshot'ı ve attachment dosyalarını içeren doğrulanmış bir
`.csebackup.zip` artifact üretir.

Yeni bir backup motoru yazmadık. Mevcut güvenlik sözleşmesini web katmanına
bağladık:

- sunucu canonical UUID artifact kimliği üretir;
- çıktı yalnız `CSE_DATA_ROOT/backups/` altında oluşturulur;
- `BackupService.create_backup(...)` archive'ı oluşturur ve doğrular;
- download route dosyayı sunmadan önce `verify_backup(...)` çağrısını tekrarlar;
- eksik, bozuk veya unsafe attachment durumunda indirme verilmez;
- teknik exception, traceback ve mutlak path kullanıcıya gösterilmez;
- aynı artifact adı varsa mevcut dosyanın üzerine yazılmaz.

## 2. Neden managed backup artifact seçtik?

Issue iki saklama seçeneği veriyordu: kalıcı managed artifact veya indirme
sonrası silinen geçici artifact. Windows'ta açık bir dosyayı silmek veya stream
tamamlandığı anı güvenilir biçimde yakalamak ek yaşam döngüsü ve dosya kilidi
karmaşıklığı doğurur. Bu görev retention veya otomatik silme görevi değildir.

Bu nedenle en küçük ve güvenilir çözüm olarak şunu seçtik:

```text
CSE_DATA_ROOT/
  cse.sqlite3
  attachments/
  exports/
  backups/
    <canonical-uuid>.csebackup.zip
```

`backups/` klasörü yeni backup'ın içine recursive olarak girmez. Mevcut
`BackupService` klasör ağacını genel amaçlı taramaz. Yalnız şunları arşivler:

1. SQLite online snapshot;
2. snapshot içindeki attachment metadata satırları;
3. bu satırların canonical path ile işaret ettiği doğrulanmış dosyalar.

Sunu soyle yaptik ki Windows indirme stream'i devam ederken dosyayı silmeye
çalışmayalım ve sessiz retention davranışı eklemeyelim.

## 3. Hangi dosyalarda ne değişti?

```text
app/web/app.py
app/web/templates/observations/list.html
app/web/templates/backups/error.html
app/web/static/app.css
tests/test_web_backup.py
docs/project_decisions.md
learning/GLOSSARY.md
learning/issue_093_safe_web_backup_download.md
```

- `app/web/app.py`: Backup service bağlantısı, POST oluşturma route'u, güvenli
  download route'u ve artifact path helper'ı eklendi.
- `app/web/templates/observations/list.html`: Kullanıcının göreceği tam yedek
  açıklaması ve tek düğmeli POST formu eklendi.
- `app/web/templates/backups/error.html`: Teknik ayrıntı sızdırmayan Türkçe
  hata yüzeyi eklendi.
- `app/web/static/app.css`: Backup alanını gözlem kartlarından ayıran küçük
  görsel panel eklendi.
- `tests/test_web_backup.py`: Başarı, fail-closed, traversal, no-overwrite,
  restart ve kaynak immutability testleri eklendi.
- `docs/project_decisions.md`: Kalıcı artifact saklama kararı kaydedildi.
- `learning/GLOSSARY.md`: Yeni kalıcı terimler tanımlandı.

## 4. Uygulama bağlantısı

`create_app(...)` artık mevcut data root için bir backup service kurar:

```python
app.config.update(
    CSE_DATA_ROOT=root,
    CSE_BACKUP_SERVICE=BackupService(root),
    CSE_BACKUP_ID_FACTORY=lambda: str(uuid4()),
)
```

Satır satır açıklama:

- `CSE_DATA_ROOT=root`: Uygulamanın tek izinli kaynak veri kökünü tutar.
- `BackupService(root)`: Mevcut snapshot, attachment doğrulama, manifest ve ZIP
  doğrulama motorunu aynı köke bağlar.
- `CSE_BACKUP_ID_FACTORY`: Her yeni web artifact için sunucu tarafında UUID
  üretir.
- Formdan path, klasör veya dosya adı okunmaz. Böylece kullanıcı girdisi
  filesystem hedefi olamaz.

Testte ID factory'nin config içinde olması aynı isim çakışmasını bilinçli
olarak kurmamızı sağlar. Production varsayılanı her çağrıda yeni UUID'dir.

## 5. POST backup akışı

Ana route özeti şöyledir:

```python
@app.post("/backups")
def backup_create() -> Response | tuple[str, int]:
    artifact = None
    try:
        artifact_id = str(app.config["CSE_BACKUP_ID_FACTORY"]())
        path = _backup_artifact_path(root, artifact_id)
        backup_service = app.config["CSE_BACKUP_SERVICE"]
        artifact = backup_service.create_backup(path)
        backup_service.verify_backup(artifact.path)
    except Exception:
        if artifact is not None:
            artifact.path.unlink(missing_ok=True)
        return render_template(
            "backups/error.html",
            error=BACKUP_ERROR_MESSAGE,
        ), 409
    return redirect(url_for("backup_download", artifact_id=artifact_id))
```

Satır satır çalışma mantığı:

1. Route yalnız POST kabul eder. GET isteği backup üretmez.
2. `artifact_id` kullanıcıdan değil, uygulama config'indeki factory'den gelir.
3. `_backup_artifact_path(...)` ID'nin canonical UUID olduğunu doğrular.
4. Hedef yalnız managed `backups/` klasörü altında hesaplanır.
5. `create_backup(...)` SQLite online snapshot alır.
6. Snapshot schema version ve kayıt sayıları okunur.
7. Her attachment metadata/path/hash/size bakımından doğrulanır.
8. Manifest ve ZIP oluşturulur.
9. Service archive'ı kendi içinde doğrular ve atomik olarak final ada taşır.
10. Web katmanı `verify_backup(...)` ile final artifact'i yeniden doğrular.
11. Başarıda kullanıcı güvenli artifact ID route'una yönlendirilir.
12. Hata halinde exception metni response'a yazılmaz; yalnız sabit Türkçe mesaj
    gösterilir.

Web sınırındaki geniş `except Exception` bilinçlidir. Alt katman exception'ı
log/debug bağlamında teknik olabilir; HTTP kullanıcı yüzeyi ise mutlak path,
SQLite ayrıntısı veya traceback göstermemelidir. Bu blok veri düzeltmez ve
başarısız yedeği sunmaz.

Sunu soyle yaptik ki alt katmanda hangi güvenlik veya I/O hatası oluşursa
oluşsun kullanıcı doğrulanmamış dosya indirmesin.

## 6. Artifact path helper'ı

```python
def _backup_artifact_path(root: Path, artifact_id: str) -> Path:
    validate_canonical_uuid(artifact_id, "backup_artifact_id")
    return root / "backups" / f"{artifact_id}.csebackup.zip"
```

- `validate_canonical_uuid(...)`: Kısa, fazla karakterli, slash içeren veya
  UUID olmayan değerleri reddeder.
- `root / "backups"`: Çıktının izinli managed klasörünü sabitler.
- Dosya adı yalnız doğrulanmış ID ve sabit uzantıdan oluşur.
- Kullanıcı `../`, drive harfi veya UNC path veremez; helper bu değerleri path
  olarak yorumlamaz.

Bu helper hem POST hem GET route tarafından kullanılır. Üretim ve indirme aynı
path sözleşmesine bağlıdır.

## 7. Download route ve yeniden doğrulama

```python
@app.get("/backups/<artifact_id>")
def backup_download(artifact_id: str) -> Response | tuple[str, int]:
    try:
        path = _backup_artifact_path(root, artifact_id)
    except ValueError:
        abort(404)
    if not path.is_file():
        abort(404)
    try:
        app.config["CSE_BACKUP_SERVICE"].verify_backup(path)
        modified = datetime.fromtimestamp(path.stat().st_mtime, timezone.utc)
    except (BackupValidationError, OSError):
        return render_template(
            "backups/error.html",
            error=BACKUP_ERROR_MESSAGE,
        ), 409
```

Bu kod iki farklı hata sınıfını kullanıcı açısından ayırır:

- ID geçersiz veya artifact yok: `404`;
- artifact var fakat bütünlüğü doğrulanamıyor: güvenli Türkçe `409`.

Dosya adı şuna benzer:

```text
cse-tam-yedek-20260714-203000-a1b2c3d4.csebackup.zip
```

İsimde mutlak path yoktur. UTC tarih/saat kullanıcı için anlaşılır bir bağlam,
UUID'nin ilk sekiz karakteri ise iki yakın indirmeyi ayıran kısa bir iz sağlar.

## 8. Neden aynı dosyanın üzerine yazılmıyor?

BackupService hedefi hazırlarken mevcut `exclusive_output_path(...)`
sözleşmesini kullanır:

```python
def exclusive_output_path(path: str | Path) -> Path:
    output = Path(path).resolve()
    if output.exists():
        raise FileExistsError(...)
    output.parent.mkdir(parents=True, exist_ok=True)
    return output
```

Bu davranışın anlamı:

- hedef yoksa managed klasör oluşturulabilir;
- hedef varsa overwrite yapılmaz;
- çakışma web sınırında güvenli hata olur;
- eski artifact byte'ları değişmez.

Test, ID factory'yi ilk artifact ID'sine sabitler ve ikinci POST'u yapar. Sonra
ilk dosyanın SHA-256/size değerlerinin aynı kaldığını doğrular.

## 9. Test kodu: kaynak dosyalar değişmiyor

Başarı testindeki temel kontrol şöyledir:

```python
database_before = _digest_file(database)
attachment_before = _digest_file(attachment_path)

created = client.post("/backups")
download = client.get(created.headers["Location"])

assert _digest_file(database) == database_before
assert _digest_file(attachment_path) == attachment_before
```

- Önce gerçek test SQLite dosyasının hash ve boyutu alınır.
- Attachment dosyasının hash ve boyutu alınır.
- POST backup oluşturur.
- GET doğrulanmış artifact'i indirir.
- Son hash/size değerleri başlangıçla birebir karşılaştırılır.

Backup source dosyalarını taşımak, yeniden yazmak veya normalize etmek yerine
okur. SQLite için online backup API ayrı snapshot dosyasına yazar.

## 10. Test kodu: manifest ve ZIP sözleşmesi

```python
manifest = app.config["CSE_BACKUP_SERVICE"].verify_backup(artifact_path)
assert manifest["schema_version"] == SCHEMA_VERSION
assert manifest["observation_count"] == 1
assert manifest["event_count"] == 1
assert manifest["attachment_count"] == 1

with zipfile.ZipFile(io.BytesIO(download.data)) as bundle:
    for name, expected in manifest["files"].items():
        assert _digest_bytes(bundle.read(name)) == expected
```

Bu test yalnız `.zip` uzantısına bakmaz. Archive'ın mevcut service tarafından
doğrulanabildiğini, schema sürümünü, observation/event/attachment sayılarını ve
manifestteki her dosyanın SHA-256/size sözleşmesini kontrol eder.

Attachment bulunmayan data root ayrı testte `attachment_count == 0` ve yalnız
`cse.sqlite3` file manifesti ile doğrulanır.

## 11. Test kodu: fail-closed attachment durumları

Test üç hata biçimini parametreyle kurar:

```python
@pytest.mark.parametrize("failure", ["missing", "tampered", "unsafe"])
def test_missing_tampered_or_unsafe_attachment_fails_closed(...):
    ...
```

- `missing`: Metadata vardır, fiziksel dosya silinmiştir.
- `tampered`: Dosya byte'ları metadata hash/size değerinden farklıdır.
- `unsafe`: SQLite metadata içindeki relative path canonical klasör sınırının
  dışına çıkarılmıştır.

Her senaryoda beklenen sonuç:

```python
assert response.status_code == 409
assert "Yedek oluşturulamadı".encode() in response.data
assert b"Traceback" not in response.data
assert list(backups.iterdir()) == []
```

Yani doğrulanmamış ZIP indirilmez, teknik hata sızmaz ve yarım/final archive
bırakılmaz. Backup işlemi bozuk kaynağı otomatik düzeltmeye de çalışmaz.

## 12. Invalid ID ve traversal testleri

```python
assert client.get("/backups/not-a-uuid").status_code == 404
assert client.get("/backups/%2e%2e%2fcse.sqlite3").status_code == 404
```

İlk istek UUID sözleşmesini bozar. İkinci istek URL-encoded `../` ile route
sınırından çıkmayı dener. İkisi de dosya okumadan reddedilir.

Ayrıca POST'a sahte `output_path` ve `file_name` form alanları gönderilir.
Route bu alanları okumaz; dosyayı yine managed `backups/` yoluna yazar. Bu,
HTML formu değiştirilse bile kullanıcı kontrollü filesystem yolu oluşmadığını
kanıtlar.

## 13. Restart kalıcılığı

Başarı testinde aynı `tmp_path` ile ikinci Flask app instance açılır:

```python
reopened = create_app(tmp_path)
reopened_detail = reopened.config["CSE_SERVICE"].get_observation_detail(
    observation_id
)
assert reopened_detail.observation.description == "Yedeklenecek gözlem"
assert len(reopened_detail.attachments) == 1
```

Bu kontrol backup üretiminin observation verisini veya attachment ilişkisini
değiştirmediğini uygulama restart benzetimiyle doğrular.

## 14. Kodun uçtan uca çalışma akışı

1. Kullanıcı gözlem listesinde tam veri yedeği açıklamasını görür.
2. Düğme `/backups` adresine POST gönderir.
3. Sunucu yeni canonical UUID üretir.
4. Helper managed artifact yolunu kurar.
5. BackupService SQLite online snapshot alır.
6. Snapshot schema ve kayıt sayıları okunur.
7. Attachment metadata/path/hash/size doğrulanır.
8. Manifest ve ZIP geçici çalışma klasöründe yazılır.
9. Service geçici ZIP'i doğrular.
10. Doğrulanmış dosya exclusive final ada atomik taşınır.
11. Web katmanı final artifact'i yeniden doğrular.
12. Tarayıcı artifact ID download route'una yönlendirilir.
13. Download route UUID, dosya varlığı ve ZIP bütünlüğünü yeniden kontrol eder.
14. Güvenli `.csebackup.zip` indirme adıyla response döner.
15. Managed artifact kullanıcı açıkça silmediği sürece saklanır; bu görev
    retention veya otomatik cleanup eklemez.

## 15. Teknik karar tablosu

| Karar | Seçim | Neden | Güvenlik sonucu |
| --- | --- | --- | --- |
| Artifact saklama | `CSE_DATA_ROOT/backups/` | Windows stream sonrası cleanup/kilit yarışını önler | İndirme kalıcı ve öngörülebilir olur |
| Dosya kimliği | Canonical UUID | Kullanıcı path'i kabul edilmez | Traversal ve tahmin edilebilir ad riski azalır |
| Üretim motoru | Mevcut `BackupService` | Snapshot/hash/manifest doğrulaması zaten var | İkinci, farklı bir backup motoru oluşmaz |
| Download kontrolü | Her GET'te `verify_backup` | Artifact üretimden sonra bozulmuş olabilir | Bozuk archive sunulmaz |
| Çakışma | Exclusive output | Sessiz overwrite veri kaybıdır | Mevcut backup korunur |
| Hata mesajı | Sabit Türkçe mesaj | Teknik exception path içerebilir | Traceback ve mutlak path sızmaz |
| Cleanup | Yalnız başarısız yeni artifact | Retention kapsam dışıdır | Başarısız çıktı kalmaz, başarılı yedek silinmez |

## 16. Bu adımda bilinçli olarak ne yapmadık?

- Restore UI eklemedik.
- Mevcut data root üzerine restore yapmadık.
- Backup upload formu eklemedik.
- Zamanlanmış veya background backup eklemedik.
- Cloud sync, şifreleme, auth veya çok kullanıcı davranışı eklemedik.
- Otomatik retention veya başarılı yedek silme eklemedik.
- Daily export akışını yeniden tasarlamadık.
- BackupService manifest veya restore sözleşmesini değiştirmedik.
- Kullanıcıdan klasör, dosya adı ya da path almadık.

## 17. Mini sözlük

- `managed backup artifact`: Uygulamanın kontrol ettiği güvenli klasörde
  saklanan yedek çıktısı.
- `artifact kimliği`: Dosya yolunu kullanıcıdan almadan çıktıyı bulduran UUID.
- `fail-closed`: Doğrulama tamamlanmıyorsa güvenli biçimde işlemi reddetmek.
- `exclusive output`: Var olan hedefin üzerine yazmayan çıktı sözleşmesi.
- `path traversal`: `../` gibi parçalarla izinli klasörün dışına çıkma denemesi.
- `immutable source`: Backup sırasında byte'ları değiştirilmemesi gereken kaynak
  SQLite ve attachment dosyaları.

## 18. Sunu soyle yaptik ki...

Sunu soyle yaptik ki kullanıcı tek düğmeyle gerçek bir tam yedek indirebilsin,
ama web formu hiçbir zaman filesystem yolu seçme aracına dönüşmesin.

Sunu soyle yaptik ki backup motoru başarı demeden ve download route artifact'i
yeniden doğrulamadan tarayıcıya hiçbir archive sunulmasın.

Sunu soyle yaptik ki Windows dosya kilidi yüzünden indirme sonrası cleanup
yarışı oluşmasın; başarılı artifact managed klasörde kalsın ve otomatik
retention bu küçük göreve gizlice eklenmesin.

Sunu soyle yaptik ki eksik, değiştirilmiş veya unsafe attachment otomatik
düzeltilmesin; yedekleme fail-closed dursun ve kullanıcı yalnız güvenli Türkçe
mesaj görsün.
