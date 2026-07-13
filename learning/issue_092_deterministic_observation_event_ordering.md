# Issue 92 - Ayni Timestamp Observation Event Siralamasi

## 1. Bu adimda ne yaptik?

Bu adimda ayni gozleme ait olaylar ayni `occurred_at` zamanini tasidiginda olay
gecmisinin rastgele UUID sirasina kaymasini engelledik. Repository sorgusu artik
once olay zamanina, zamanlar esitse SQLite'in eklenme sirasini temsil eden
`rowid` degerine bakiyor.

Ayrica davranisi uc seviyede test ettik:

- repository yeniden acildiginda ayni timestamp sirasi;
- gercek web duzenleme akisinda sabit clock ile timestamp cakismasi;
- SQLite backup/restore sonrasinda ayni event sirasi.

## 2. Neden bunu yaptik?

Uygulama olay zamanini saniye hassasiyetinde kaydediyor. Bir gozlem olusturulup
ayni saniye icinde duzenlenirse iki event ayni timestamp degerini alabilir.
Eski sorgu esitlik halinde UUID metnini siraliyordu. UUID olay zamani degildir;
bu nedenle kullanici bazen "gozlem guncellendi" olayini "gozlem olusturuldu"
olayindan once gorebilirdi.

Santiye sefi acisindan olay gecmisi bir saha tutanaginin kronolojik sayfalari
gibidir. Iki islem ayni dakika veya saniyede yapilsa bile once olusturma, sonra
duzenleme gorunmelidir. Kaydin kimlik numarasinin alfabetik sirasi bu gercek
islem sirasini degistirmemelidir.

## 3. Hangi dosyalara dokunduk?

```text
app/persistence/repositories.py
tests/test_observation_events.py
tests/test_field_web_app.py
tests/test_backup_restore.py
docs/project_decisions.md
learning/GLOSSARY.md
learning/issue_092_deterministic_observation_event_ordering.md
```

- `app/persistence/repositories.py`: Observation event listeleme sorgusunu tutar.
- `tests/test_observation_events.py`: Repository seviyesindeki ekleme ve yeniden
  acma davranisini test eder.
- `tests/test_field_web_app.py`: Web duzenleme akisinin sabit timestamp ile
  deterministik calistigini test eder.
- `tests/test_backup_restore.py`: Event sirasinin yedekleme ve geri yukleme
  sonrasinda korundugunu test eder.
- `docs/project_decisions.md`: Kalici teknik karari kisa maddelerle kaydeder.
- `learning/GLOSSARY.md`: Yeni ve kalici terimleri tanimlar.
- Bu learning dosyasi: Kodun neden ve nasil degistigini ogretici bicimde aciklar.

## 4. Kod bloklari uzerinden aciklama

### Repository sorgusu

```python
rows = self._connection.execute(
    """
    SELECT id, observation_id, event_type, actor, occurred_at, payload_json
    FROM observation_events
    WHERE observation_id = ?
    ORDER BY occurred_at, rowid
    """,
    (observation_id,),
)
```

Bu kodun amaci bir gozlemin event kayitlarini gercek kronolojik sirada okumaktir.

Satir satir aciklama:

- `self._connection.execute(...)`: SQL sorgusunu aktif SQLite baglantisinda
  calistirir.
- `SELECT ...`: Event nesnesini yeniden kurmak icin gerekli sutunlari secer.
- `FROM observation_events`: Verinin observation event tablosundan gelecegini
  soyler.
- `WHERE observation_id = ?`: Yalniz istenen gozleme ait event'leri alir.
- `ORDER BY occurred_at, rowid`: Once gercek olay zamanina gore siralar. Iki
  zaman esitse daha once eklenen SQLite satirini once getirir.
- `(observation_id,)`: SQL parametresini ayri verir; degeri SQL metnine elle
  birlestirmez.

Sunu soyle yaptik ki ayni saniyedeki event'ler UUID alfabetik sirasina gore
degil, repository'ye eklenme sirasina gore gorunsun.

Bu tabloda event'ler append-only'dir: event satiri silinmez veya yeniden
yazilmaz ve insert sirasinda elle `rowid` verilmez. Bu dar sozlesme altinda yeni
satirlarin otomatik rowid degeri eklenme sirasini guvenli bir tie-breaker olarak
temsil eder. `occurred_at` hala ana kronolojik kuraldir; `rowid` yalniz esit
timestamp durumunda devreye girer.

### Web testinde sabit clock

```python
app = create_app(tmp_path)
app.config["CSE_SERVICE"]._clock = lambda: "2026-07-13T09:00:00Z"
client = app.test_client()
```

Bu kodun amaci testte gozlem olusturma ve duzenleme olaylarinin kesin olarak
ayni timestamp degerini almasini saglamaktir.

Satir satir aciklama:

- `create_app(tmp_path)`: Gercek kullanici verisinden tamamen ayri gecici bir
  veri kokunde Flask uygulamasi kurar.
- `app.config["CSE_SERVICE"]`: Web route'larinin kullandigi application service
  nesnesini alir.
- `_clock = lambda: ...`: Test boyunca her saat cagrisina ayni UTC zamanini
  dondurur. Boylece cakisma sansa bagli degil, zorunlu hale gelir.
- `app.test_client()`: Gercek port acmadan HTTP akisini test eden istemciyi
  olusturur.

Sunu soyle yaptik ki flaky test bazen ayni, bazen farkli saniyeye denk gelmesin;
her calismada hatayi olusturan kosulu kesin olarak kursun.

## 5. Test kodlari uzerinden aciklama

### Ters UUID sirasiyla repository ve reopen testi

```python
inserted_events = [
    _event(THIRD_EVENT_ID, occurred_at=T2),
    _event(EVENT_ID, event_type="observation_details_updated", occurred_at=T2),
    _event(
        SECOND_EVENT_ID,
        event_type="observation_status_changed",
        occurred_at=T2,
    ),
]

with SQLiteUnitOfWork(database_path) as unit_of_work:
    for event in inserted_events:
        unit_of_work.events.add(event)
    unit_of_work.commit()

with SQLiteUnitOfWork(database_path) as reopened:
    stored_events = reopened.events.list_for_observation(OBSERVATION_ID)

assert [event.event_id for event in stored_events] == [
    THIRD_EVENT_ID,
    EVENT_ID,
    SECOND_EVENT_ID,
]
```

Bu testin amaci UUID metin sirasi ile eklenme sirasini bilerek farkli yapmaktir.

Satir satir aciklama:

- Uc event ayni `T2` timestamp degerini kullanir.
- Kimlikler `ffffffff...`, `dddddddd...`, `eeeeeeee...` eklenme sirasindadir;
  alfabetik siralari farklidir.
- `for` dongusu event'leri semantik sirayla ekler.
- `commit()` kayitlari kalici SQLite dosyasina yazar.
- Ilk Unit of Work kapandiktan sonra yeni bir Unit of Work acilir. Bu adim
  gercek uygulama yeniden acilmasini temsil eder.
- Son `assert`, okunan kimliklerin ekleme sirasini aynen korudugunu kanitlar.

Eski `ORDER BY occurred_at, id` sorgusu bu testi gecemezdi; cunku kimlikleri
alfabetik siraya dizerdi. Yeni test yalniz sonucu aramak yerine siralama
sozlesmesini dogrudan kontrol eder.

### Backup/restore testi

```python
assert [event.event_type for event in restored.events] == [
    "observation_created",
    "observation_details_updated",
]
assert restored.events[-1].event_type == "observation_details_updated"
```

Bu testte create event ID'si `ffffffff...`, update event ID'si ise
`00000000...` olarak uretilir. Alfabetik UUID sirasi semantik siraya terstir.
SQLite backup alinip yeni veri kokune restore edildikten sonra event tiplerinin
once create, sonra update gelmesi beklenir.

Sunu soyle yaptik ki cozum yalniz acik baglantida degil, gercek backup/restore
akisi sonunda da ayni kronolojik sonucu versin.

## 6. Kodun calisma akisi

1. Application service yeni event'i `observation_events` tablosuna ekler.
2. SQLite normal tablo satirina otomatik bir `rowid` verir.
3. Unit of Work transaction'i commit eder.
4. Detay ekrani event listesini repository'den ister.
5. SQL once `occurred_at` degerlerini karsilastirir.
6. Timestamp'ler farkliysa eski kronolojik davranis aynen devam eder.
7. Timestamp'ler esitse SQL ikinci anahtar olarak `rowid` degerini kullanir.
8. Daha once eklenen event once doner.
9. Uygulama yeniden acildiginda ayni SQLite satirlari ayni sirada okunur.
10. Backup service SQLite backup API ile veritabani snapshot'ini kopyalar;
    restore edilen dosyada repository ayni ordering sozlesmesini uygular.

## 7. Yeni ogrenilen yazilim kavramlari

### SQLite rowid

SQLite'in `WITHOUT ROWID` olmayan normal tablolarda her satira verdigi dahili
tamsayi kimliktir.

Bu projedeki karsiligi: `observation_events` tablosunda event insert sirasini,
ayni timestamp icin ikinci siralama anahtari olarak temsil eder.

Santiye benzetmesi: Ayni saat yazan iki tutanagin evraka giris sira numarasi
gibidir.

### Tie-breaker

Ana karsilastirma esit ciktiginda sirayi belirleyen ikinci kuraldir.

Bu projedeki karsiligi: `occurred_at` esit oldugunda `rowid` kullanilir.

Santiye benzetmesi: Ayni tarihte gelen iki malzeme irsaliyesini kabul sira
numarasiyla ayirmak gibidir.

### Deterministik siralama

Ayni kalici veri okundugunda her seferinde ayni sirayi elde etmektir.

Bu projedeki karsiligi: Restart veya restore event siralamasini degistirmez.

## 8. Sunu soyle yaptik ki... teknik karar tablosu

| Sunu yaptik | Boyle yaptik | Cunku | Boylece |
| --- | --- | --- | --- |
| UUID tie-breaker'i kaldirdik | `ORDER BY occurred_at, rowid` kullandik | UUID olay zamani veya islem sirasi degildir | Ayni timestamp event'leri semantik eklenme sirasinda doner |
| Schema migration eklemedik | Mevcut normal SQLite tablosunun `rowid` degerini kullandik | Mevcut veriyi yeniden yazmak gereksiz risk olurdu | Eski veritabani dosyalari degismeden acilir |
| Cakismayi zorunlu yaptik | Web testine sabit clock verdik | Gercek saat kullanan test bazen saniye sinirini asiyordu | Test her calismada ayni riskli kosulu dogrular |
| Restore sirasini kanitladik | UUID sirasini ters kurup event tiplerini assert ettik | Sadece event sayisini kontrol etmek ordering hatasini gizlerdi | Backup/restore davranisi da regresyona karsi korunur |

## 9. Bu adimda bilincli olarak ne yapmadik?

- Schema migration eklemedik.
- Event timestamp veya UUID degerlerini yeniden yazmadik.
- Event payload ve event type sozlesmelerini degistirmedik.
- Observation revision, status, reporting, archive veya no-op davranislarini
  degistirmedik.
- Attachment dosyalarina veya metadata'sina dokunmadik.
- Gercek `%LOCALAPPDATA%\ChiefSiteEngineer\data` kokunde test veya mutation
  yapmadik; testler yalniz `tmp_path` kullandi.
- Siralama hatasini test assertion'ini gevseterek veya belirli event tipini
  arayarak gizlemedik.

## 10. Mini sozluk

- `rowid`: SQLite normal tablo satirinin otomatik tamsayi kimligi.
- `tie-breaker`: Esit ana degerlerde sirayi belirleyen ikinci kural.
- `append-only`: Yeni kayit eklenen, mevcut kaydin silinip yeniden yazilmadigi
  veri davranisi.
- `reopen`: Veritabani baglantisini kapatip yeni baglantiyla tekrar acma.
- `regresyon testi`: Daha once bulunan bir hatanin geri gelmesini engelleyen test.
- `deterministik`: Ayni girdide her zaman ayni sonucu veren davranis.

## 11. Sonraki adima baglanti

Bu fix merge edildikten sonra Issue #91 post-merge kabul akisi yeniden
calistirilabilir. Orada full suite ve gercek launcher read-only kontrolleri
yeniden yapilarak flaky event ordering blocker'inin kalktigi dogrulanabilir.
