# Issue #119 Öğrenme Notu — İlk Test Edilebilir PC Saha Takibi Arayüzü

## Bu çalışmada ne öğrendik?

Bu geliştirme, daha önce ayrı ayrı var olan domain, persistence ve application service parçalarını Flask web katmanında birleştirdi. Önemli fikir şudur: UI yeni iş kuralları icat etmedi. Kullanıcının form girdisini mevcut command nesnelerine çevirdi, application service'i çağırdı ve sonucu HTML ile gösterdi.

Kullanıcının bilgisayarda deneyebildiği akış:

```text
+ Unutma ile yakala
→ Unutma Kutusu'nda gör
→ ayrıntı/proje/önem düzenle
→ planla veya beklemeye al
→ Bugün ekranında gör
→ tamamla / iptal et / yeniden aç
→ rutin oluştur
→ bugünkü occurrence'ı gör ve sonuçlandır
→ uygulamayı aynı data root ile yeniden aç
→ kayıt ve geçmişi aynı SQLite'tan oku
```

## Hangi dosyada ne yaptık?

| Dosya | Yapılan iş | Neden |
|---|---|---|
| `app/web/app.py` | Üç application service'i bağladı; route, zaman dönüşümü, validation ve redirect akışlarını ekledi | UI'nin mevcut iş kurallarını güvenli biçimde çağırması için |
| `app/web/templates/base.html` | Ana navigasyonu genişletti | Bugün, Unutma Kutusu, Rutinler ve Gözlemler arasında görünür geçiş için |
| `app/web/templates/today.html` | Bugün bölümlerini ve hızlı capture formunu gösterdi | Günlük odağı tek ekranda toplamak için |
| `app/web/templates/follow_ups/*.html` | Inbox, detail, history ve mutation formlarını gösterdi | Follow-up yaşam döngüsünü server-rendered kullanmak için |
| `app/web/templates/routines/*.html` | Rutin list/create/detail ve occurrence formlarını gösterdi | Rutin tanımı ve günlük sonuçlandırma için |
| `app/web/static/app.css` | Grid, kart, badge, focus ve responsive kuralları ekledi | Masaüstü ve dar ekranda erişilebilir temel yüzey için |
| `tests/test_field_tracking_web.py` | Navigation, capture, lifecycle, routine, restart ve export acceptance testlerini ekledi | UI ile application/persistence sınırını executable kanıtlamak için |

## 1. Aynı SQLite dosyasına üç service bağlamak

Gerçek kodun sadeleştirilmemiş ana bölümü:

```python
app.config.update(
    CSE_SERVICE=ObservationApplicationService(
        root / "cse.sqlite3",
        ManagedAttachmentStore(root / "attachments"),
    ),
    CSE_FOLLOW_UP_SERVICE=FollowUpApplicationService(
        root / "cse.sqlite3",
        clock=configured_now_utc,
        uuid_factory=lambda: str(app.config["CSE_FOLLOW_UP_ID_FACTORY"]()),
    ),
    CSE_ROUTINE_SERVICE=RoutineApplicationService(
        root / "cse.sqlite3",
        clock=configured_now_utc,
        uuid_factory=lambda: str(app.config["CSE_ROUTINE_ID_FACTORY"]()),
    ),
)
```

Satır satır düşünelim:

1. `app.config.update(...)`, service nesnelerini Flask uygulamasının açık config alanlarına koyar.
2. `CSE_SERVICE`, mevcut observation service anahtarıdır; eski web route'ları bozulmaz.
3. Üç service de `root / "cse.sqlite3"` kullanır. İkinci bir database oluşmaz.
4. Observation service ayrıca managed attachment klasörünü alır.
5. Follow-up ve routine service `configured_now_utc` saatini alır. Böylece production gerçek zamanı, test ise sabit zamanı kullanabilir.
6. UUID factory de config üzerinden okunur. Testler deterministik kimlik sırası verebilir.

Bu yapı dependency injection örneğidir. Saat ve kimlik üretimi service içinde sabitlenmediği için test tekrarları kararlı olur.

## 2. Bir request içinde tek zaman kullanmak

Bugün sayfasının ana başlangıcı:

```python
def render_today_page(
    *, error: str | None = None, capture_text: str = ""
) -> str:
    now_utc = configured_now_utc()
    g.cse_now_utc = now_utc
    routine_service().ensure_occurrences(now_utc)
```

Satırların görevi:

1. `configured_now_utc()` bir canonical UTC timestamp üretir ve doğrular.
2. `g.cse_now_utc`, bu değeri yalnız mevcut Flask request bağlamında saklar.
3. `ensure_occurrences(now_utc)`, rutin üretimini aynı anla yapar.
4. Sayfanın follow-up ve occurrence sorguları da aynı `now_utc` değerini kullanır.

Neden önemli? Saat tam gün sınırında ilerlerse bir sorgunun “bugün”, diğerinin “yarın” görmesini istemeyiz. Tek request-scoped zaman bu tutarsızlığı önler.

## 3. Hızlı capture ve PRG

Route'un gerçek çekirdeği:

```python
@app.post("/follow-ups")
def follow_up_create() -> Response | tuple[str, int]:
    capture_text = request.form.get("capture_text", "")
    return_to = request.form.get("return_to", "inbox")
    try:
        item = follow_up_service().create_follow_up(
            CreateFollowUp(capture_text)
        )
    except (PersistenceError, ValueError) as exc:
        renderer = (
            render_today_page
            if return_to == "today"
            else render_follow_up_inbox
        )
        return (
            renderer(
                error=_tracking_error_message(exc),
                capture_text=capture_text,
            ),
            400,
        )
    return redirect(
        url_for(
            "follow_up_detail",
            follow_up_id=item.follow_up_id,
            saved="created",
        )
    )
```

Satır satır açıklama:

1. Formdan yalnız `capture_text` ve dönüş hedefi okunur.
2. İş kuralı `CreateFollowUp(capture_text)` command'ına bırakılır.
3. Service normalization, UUID, UTC timestamp, initial title ve created event'i yönetir.
4. Hata olursa raw exception basılmaz; `_tracking_error_message` güvenli Türkçe mesaj üretir.
5. Hatalı metin `capture_text=capture_text` ile forma geri verilir; kullanıcı yazdığını kaybetmez.
6. HTTP 400, formun geçersiz olduğunu teknik olarak da doğru ifade eder.
7. Başarılı POST doğrudan HTML döndürmez; detail GET route'una redirect eder.
8. Tarayıcı refresh yaptığında GET yenilenir. Aynı POST tekrar gönderilmez.

Bu son desen Post/Redirect/Get, yani PRG'dir.

## 4. Europe/Istanbul girdisini UTC'ye çevirmek

```python
def istanbul_datetime_local_to_utc(value: str) -> str:
    """Interpret an HTML datetime-local value in Europe/Istanbul."""

    try:
        local = datetime.strptime(value, "%Y-%m-%dT%H:%M").replace(
            tzinfo=ISTANBUL_TIMEZONE
        )
    except (TypeError, ValueError) as exc:
        raise ValueError("Bildirim zamanı geçersiz.") from exc
    return local.astimezone(timezone.utc).isoformat(timespec="seconds").replace(
        "+00:00", "Z"
    )
```

Çalışma sırası:

1. HTML `datetime-local` girdisi timezone bilgisi taşımaz.
2. `datetime.strptime`, metni `datetime` nesnesine çevirir.
3. `.replace(tzinfo=ISTANBUL_TIMEZONE)`, bu duvar saatinin İstanbul'a ait olduğunu açıklar.
4. Parse hatası kullanıcıya güvenli `ValueError` olarak çevrilir.
5. `.astimezone(timezone.utc)`, aynı anı UTC'ye dönüştürür.
6. `isoformat(...).replace("+00:00", "Z")`, canonical storage metnini üretir.

Örnek:

```text
Kullanıcı girdisi: 2026-07-16T19:00 Europe/Istanbul
Storage değeri:    2026-07-16T16:00:00Z
```

## 5. Optimistic revision ve güvenli hata

```python
def expected_revision() -> int:
    raw = request.form.get("expected_revision", "")
    try:
        value = int(raw)
    except (TypeError, ValueError) as exc:
        raise ValueError("Revizyon bilgisi geçersiz.") from exc
    if value < 1:
        raise ValueError("Revizyon bilgisi geçersiz.")
    return value
```

Bu helper:

1. Hidden form alanını okur.
2. Integer olmayan değeri reddeder.
3. Sıfır veya negatif revision'ı reddeder.
4. Geçerli revision'ı application service'e verir.

Revision conflict olduğunda web katmanı HTTP 409 döndürür:

```python
if isinstance(error, RevisionConflict):
    return (
        render_follow_up_detail(
            follow_up_id,
            error=(
                "Kayıt başka bir işlem tarafından güncellendi. "
                "Devam etmeden önce sayfayı yenileyin."
            ),
            form_values=request.form,
        ),
        409,
    )
```

Burada 409, kullanıcının elindeki form revision'ı ile database revision'ının çakıştığını anlatır. Form değerleri korunur; kullanıcı traceback görmez.

## 6. Routine occurrence mutation akışı

Close route örneği:

```python
@app.post("/routine-occurrences/<routine_occurrence_id>/close")
def routine_occurrence_close(
    routine_occurrence_id: str,
) -> Response | tuple[str, int]:
    try:
        current = find_occurrence(routine_occurrence_id)
    except (RecordNotFound, ValueError):
        abort(404)
    try:
        updated = routine_service().close_occurrence(
            routine_occurrence_id,
            expected_revision(),
            CloseRoutineOccurrence(
                RoutineOccurrenceOutcome(
                    request.form.get("outcome_type", "")
                ),
                request.form.get("outcome_note") or None,
            ),
        )
    except (PersistenceError, ValueError) as exc:
        return occurrence_error_response(current, exc)
    return occurrence_success_redirect(updated, "occurrence_closed")
```

Akış:

1. Önce occurrence bulunur; invalid/missing kimlik 404 olur.
2. `expected_revision()` stale write korumasını sağlar.
3. Form metni enum'a çevrilir. Bilinmeyen outcome validation hatasıdır.
4. Command application service'e verilir.
5. Service aggregate ve append-only event'i transaction içinde yazar.
6. Başarı redirect ile Bugün veya routine detail sayfasına döner.

UI schedule snapshot'ı doğrudan değiştirmez. Bu alanın sahibi application/domain sözleşmesidir.

## 7. Template ve HTML escaping

Jinja template'lerinde değerler `{{ item.capture_text }}` biçiminde gösterilir. Jinja varsayılan autoescape davranışı nedeniyle:

```text
Girdi:   <script>alert(1)</script>
HTML:    &lt;script&gt;alert(1)&lt;/script&gt;
Ekran:   <script>alert(1)</script> metni
Davranış: script çalışmaz
```

UI teknik event adını doğrudan göstermek yerine sunum sözlüğünü kullanır. Böylece storage sözleşmesi değişmeden kullanıcı “Takip yakalandı” gibi bir ifade görür.

## 8. Test kodu neyi doğruluyor?

### Ortak database ve erişilebilirlik testi

```python
expected_database = tmp_path / "cse.sqlite3"
assert app.config["CSE_FOLLOW_UP_SERVICE"].database_path == expected_database
assert app.config["CSE_ROUTINE_SERVICE"].database_path == expected_database
assert app.config["CSE_SERVICE"].database_path == expected_database
assert SCHEMA_VERSION == 4

css = client.get("/static/app.css").get_data(as_text=True)
assert "min-height: 44px" in css
assert "@media (max-width: 640px)" in css
assert ":focus-visible" in css
```

Satırların kanıtı:

1. Üç service aynı temporary SQLite path'ini kullanıyor.
2. Schema yeni UI için yükseltilmemiş; hâlâ `4`.
3. CSS'te 44 px hedef, dar ekran breakpoint'i ve klavye focus kuralı fiziksel olarak var.

### Hızlı capture testi

```python
follow_up_id = _create_follow_up(
    client, "  Kalıp   kotunu <script>alert(1)</script> tekrar kontrol et  "
)
stored = app.config["CSE_FOLLOW_UP_SERVICE"].get_follow_up(follow_up_id)
assert stored.capture_text == "Kalıp kotunu <script>alert(1)</script> tekrar kontrol et"
assert stored.title == stored.capture_text
assert stored.status == FollowUpStatus.INBOX
```

Bu test baş/son whitespace'in ve ardışık boşlukların normalize edildiğini; script metninin data olarak korunduğunu; ilk title ve inbox durumunun doğru olduğunu doğrular.

### Restart ve export acceptance testi

Test aynı `tmp_path` ile iki app oluşturur:

```python
first = _app(tmp_path)
# kayıtlar ve mutation'lar
second = _app(tmp_path)
```

Sonra kalıcılığı kontrol eder:

```python
assert reopened_follow_up.revision == 7
assert len(second.config["CSE_FOLLOW_UP_SERVICE"].list_history(follow_up_id)) == 7
assert reopened_occurrence.status == RoutineOccurrenceStatus.CLOSED
assert reopened_occurrence.outcome_type == RoutineOccurrenceOutcome.NO_WORK
```

Bu assertions yalnız HTML'i değil, yeniden açılan application service'in SQLite'tan okuduğu gerçek aggregate durumunu doğrular.

Export sınırı:

```python
assert "Kabul gözlemi".encode() in exported_content
assert "Kalıp kotunu tekrar kontrol et".encode() not in exported_content
assert "Puantajı tamamla".encode() not in exported_content
```

Burada olumlu ve olumsuz kanıt birlikte kullanılır:

- Observation metni varsa export çalışmıştır.
- Follow-up ve routine metni yoksa kişisel tracking verisi resmî export'a sızmamıştır.

## Teknik karar tablosu

| Konu | Seçilen karar | Seçilmeyen yaklaşım | Gerekçe |
|---|---|---|---|
| UI mimarisi | Flask + Jinja server-rendered HTML | SPA/framework | Mevcut uygulamayla sade entegrasyon ve küçük bağımlılık yüzeyi |
| Veritabanı | Üç service için aynı `cse.sqlite3` | Ayrı tracking database | Transactional omurga ve restart kalıcılığını tek kaynakta tutmak |
| Hızlı capture | Yalnız `capture_text` | Create formunda bütün alanlar | Sahada düşük sürtünmeli yakalama |
| Başarılı form | PRG redirect | POST response HTML | Refresh duplicate mutation riskini azaltmak |
| Zaman girdisi | Europe/Istanbul → UTC | Naive timestamp storage | Kullanıcı yerel zamanı ve canonical storage ayrımı |
| Concurrency | Hidden expected revision + 409 | Last-write-wins | Eski formun yeni veriyi sessizce ezmesini önlemek |
| Rutin üretimi | Request-time idempotent ensure | Background scheduler | İlk PC sürümünde scheduler/notification kapsamını büyütmemek |
| Event gösterimi | Türkçe sunum sözlüğü | Raw enum/event adı | Storage sözleşmesini bozmadan anlaşılır UI |
| Export | Tracking varsayılan olarak hariç | Bütün SQLite verisini export etmek | Kişisel/resmî veri sınırı |
| Responsive tasarım | CSS breakpoint ve tek kolon | Ayrı mobil uygulama | PC diliminde dar ekran temel kullanılabilirliği, mobile runtime'ı ayrı tutmak |

## Kodun çalışma akışı

```text
Tarayıcı formu
  ↓
Flask route
  ↓ form değerini parse et / expected_revision oku
Application command
  ↓
FollowUpApplicationService veya RoutineApplicationService
  ↓ aynı transaction
SQLite aggregate + append-only event
  ↓
Redirect (PRG)
  ↓
GET detail / today
  ↓
Jinja template + Türkçe sunum sözlüğü
  ↓
Kullanıcıya güvenli HTML
```

## Şunu şöyle yaptık ki...

- Şunu şöyle yaptık ki **üç service aynı SQLite dosyasını kullansın**: hepsine `root / "cse.sqlite3"` verdik. Böylece restart sonrasında observation, follow-up ve routine aynı veri kökünden okunuyor.
- Şunu şöyle yaptık ki **testler kararlı olsun**: saat ve UUID factory'lerini Flask config üzerinden enjekte ettik. Böylece test her çalışmada aynı zaman ve kimlik zincirini kurabiliyor.
- Şunu şöyle yaptık ki **refresh duplicate kayıt üretmesin**: başarılı POST sonrasında HTML döndürmek yerine redirect kullandık.
- Şunu şöyle yaptık ki **eski form yeni kaydı ezmesin**: hidden `expected_revision` değerini application service'e verdik ve conflict'i HTTP 409 yaptık.
- Şunu şöyle yaptık ki **kullanıcı yerel saat girsin ama storage canonical kalsın**: `datetime-local` değerini Europe/Istanbul kabul edip UTC `Z` metnine çevirdik.
- Şunu şöyle yaptık ki **kişisel takip resmî çıktıya karışmasın**: export production kodunu genişletmedik ve acceptance testinde takip/rutin metninin ZIP içinde bulunmadığını doğruladık.
- Şunu şöyle yaptık ki **UI anlaşılır ama storage kararlı kalsın**: enum/event değerlerini değiştirmeden Türkçe sunum sözlüğü ekledik.
- Şunu şöyle yaptık ki **dar ekranda yüzey dağılmasın**: 640 px breakpoint altında grid'i tek kolona düşürdük.

## Test sonuçlarını nasıl okumalıyız?

```text
17 passed
```

Yeni Saha Takibi web paketinin kendi kabul matrisidir.

```text
56 passed
```

Mevcut observation web, backup, restore ve daily export regresyonlarının yeni UI ile bozulmadığını gösterir.

```text
983 passed, 7 skipped
```

Repository'nin full suite sonucudur. Yedi skip Windows symlink ayrıcalığı olmadığı için mevcut güvenlik testlerinin kontrollü skip'idir; failure değildir.

## Yeni terimler

Bu çalışmayla kalıcı öğrenme sözlüğüne şu terimler eklendi:

- Post/Redirect/Get (PRG)
- Server-Rendered HTML
- Responsive Tek Kolon
- `:focus-visible`
- Dokunma Hedefi
- Sunum Sözlüğü
- Request-Scoped Canonical Now
- Restart Acceptance
- İlk Test Edilebilir PC Sürümü

Tanımlar `learning/GLOSSARY.md` içindedir.

## Bu sürüm ne değildir?

Bu sürüm:

- mobile runtime değildir;
- PWA değildir;
- offline/sync çözümü değildir;
- notification scheduler değildir;
- auth veya biometric güvenlik katmanı değildir;
- çok kullanıcılı/kurumsal workflow değildir;
- resmî export'a kişisel takip verisi ekleyen bir genişleme değildir.

İlk amaç, şantiye şefinin bilgisayarda gerçek temel akışı test edebilmesidir. Sonraki mobil, offline ve bildirim fazları ayrı karar ve kabul sınırları gerektirir.
