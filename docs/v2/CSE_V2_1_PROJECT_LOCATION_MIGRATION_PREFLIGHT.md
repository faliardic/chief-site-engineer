# CSE V2.1 — Proje / Mahal Stable-ID ve Migration Preflight

**Parent ürün Epic'i:** #385  
**Preflight Issue:** #390  
**V2 maddesi:** V2.1 — Proje ve Mahal omurgası  
**Başlangıç master:** `dbbd0786d853a02e0d8ece2aa6f4e07e0cce4dce`  
**Mobil schema:** `10`  
**Backup formatı:** `1`

## 1. Amaç

Bu belge production migration yazılmadan önce mevcut V1 proje ve konum
sözleşmesini sabitler. Hedef, sahada yaklaşık bir ay kullanılmış V1 verisini
koruyarak stable proje/mahal kimliklerine geçmektir.

V2.1'in amacı eski serbest metinleri yeniden yorumlamak değil, bundan sonraki
kayıtların aynı proje ve mahal kimliğine güvenle bağlanabilmesini sağlamaktır.

## 2. Doğrulanmış current proje modeli

Mobil SQLite `projects` tablosu schema 2'den beri şunları taşır:

- `id TEXT PRIMARY KEY`
- `name TEXT NOT NULL`
- `created_at`
- `updated_at`
- `revision`
- `archived_at`

Current application katmanında proje kimliği UUID olarak doğrulanır. Bu nedenle
V2.1 yeni bir proje ID sistemi kurmaz; mevcut `projects.id` stable identity
olarak korunur.

Current kullanıcı application sınırı:

- `listProjects()`
- `createProject(...)`

`listProjects()` yalnız `archived_at IS NULL` satırlarını gösterir. Current
production yüzeyde proje düzenleme, archive, restore ve project event history
mutation'ları yoktur.

## 3. Doğrulanmış current mahal/konum kullanımı

V1 tek bir stable mahal kimliği kullanmaz.

### Ajanda

`field_observations.location` nullable serbest metindir. Ajanda formu doğrudan
text controller ile bu alanı yazar.

### Hatırlatıcı

`follow_up_items.location` nullable serbest metindir. Reminder kayıtları aynı
metni stable bir location kaydına bağlamaz.

### Beton

Beton paketi mahal bağlamını birden fazla text alanında tutar:

- `element_location` / `elementLocation`
- `block_name` / `blockName`
- `floor_name` / `floorName`
- `axis_name` / `axisName`

Bu alanlar Ajanda `location` metniyle birebir aynı semantiğe sahip değildir.

### Puantaj

Current V1 Puantaj akışında kanonik bir mahal bağı zorunlu değildir. Bu nedenle
V2.1 foundation Puantajı schema migration sırasında zorla mahal kimliğine
bağlamaz. Puantaj için gerçek mahal ihtiyacı V2.2 içinde ayrıca daraltılabilir.

## 4. Ana migration kararı

Existing V1 serbest metinlerinden otomatik `project_locations` kayıtları
üretilmez.

Bunun nedenleri:

1. Aynı metin farklı gerçek mahalleri temsil edebilir.
2. Farklı metinler aynı mahali temsil edebilir.
3. Betonun blok/kat/aks + eleman yapısı tek Ajanda `location` alanına deterministik
   olarak indirgenemez.
4. Yanlış stable-ID bağlantısı, çıplak text kaybından daha zor fark edilen bir
   veri bütünlüğü hatasıdır.
5. Kullanıcı verisi üzerinde fuzzy veya AI eşleştirme migration sorumluluğu
   olmamalıdır.

Schema 10 → 11 migration mevcut text değerlerini değiştirmeden bırakır.

## 5. Stable Mahal Kataloğu adayı

İlk production foundation için `project_locations` tablosu önerilir.

Asgari alanlar:

```text
id
project_id
display_name
normalized_name
parent_location_id
revision
created_at
updated_at
archived_at
```

### Kimlik

- `id`: UUID stable identity.
- `project_id`: mevcut `projects.id`.
- İsim değişikliği ID'yi değiştirmez.

### Ad

- `display_name`: kullanıcının gördüğü ve düzenlediği ad.
- `normalized_name`: duplicate/search desteği için türetilmiş değer.
- `normalized_name` kullanıcıya source-of-truth olarak sunulmaz.

### Üst bağlam

`parent_location_id` opsiyoneldir. Böylece ilk sürüm ağır BIM/WBS modeli
kurmadan hiyerarşi destekleyebilir:

```text
B Blok
└── 3. Kat
    └── 301 Daire
```

V2.1 ilk migration'da zorunlu `block/floor/room` enum'u eklemez. İhtiyaç gerçek
saha kullanımından sonra genişletilebilir.

### Yaşam döngüsü

- physical delete yok;
- archive/restore recoverable;
- revision korunur;
- ileride location event history aynı append-only ürün ilkelerine uyar.

## 6. Legacy snapshot + stable link yaklaşımı

Stable ID eklemek mevcut text snapshot'ı silmek anlamına gelmez.

Planlanan adoption:

### Ajanda

```text
field_observations.location      # mevcut text snapshot, korunur
field_observations.location_id   # yeni nullable stable link
```

### Hatırlatıcı

```text
follow_up_items.location         # mevcut text snapshot, korunur
follow_up_items.location_id      # yeni nullable stable link
```

### Beton

```text
concrete_pours.element_location  # mevcut snapshot, korunur
concrete_pours.block_name        # korunur
concrete_pours.floor_name        # korunur
concrete_pours.axis_name         # korunur
concrete_pours.location_id       # yeni nullable stable link
```

Bu yapı iki ihtiyacı birlikte karşılar:

1. Mahal adı değişse bile source record aynı stable mahal kimliğine bağlı kalır.
2. Tarihsel kaydın sahada girildiği text ifadesi migration sırasında kaybolmaz.

## 7. Schema 11 migration sınırı

İlk production child yalnız foundation kurar.

### Eklenecek

- `project_locations`
- gerekli indeksler ve foreign-key sınırları
- `field_observations.location_id` nullable
- `follow_up_items.location_id` nullable
- `concrete_pours.location_id` nullable

### Mevcut row davranışı

- yeni link alanları `NULL` başlar;
- mevcut kayıt ID'leri değişmez;
- mevcut proje ID'leri değişmez;
- mevcut location/element/block/floor/axis textleri değişmez;
- otomatik katalog kaydı oluşturulmaz;
- otomatik eşleştirme yapılmaz.

### Fresh install

Schema 11 fresh install ile schema 10 → 11 upgrade aynı table/column/index
invariants'ini üretmelidir.

## 8. Backup / restore sınırı

Backup container formatı bu foundation yüzünden otomatik olarak `2` yapılmaz.

İlk hedef:

- `.csebackup` format `1` korunur;
- schema `11` manifestte current schema olarak taşınır;
- desteklenen eski schema 10 backup staging'de schema 11'e migrate edilir;
- restore sonrası row count, IDs, legacy location texts ve attachment bağlantıları
  korunur;
- unsupported newer schema fail-closed kalır;
- downgrade desteklenmez.

Format değişikliği gerçekten gerekirse ayrı Issue ve explicit compatibility
kararı gerekir.

## 9. Proje yaşam döngüsü yönü

`projects.archived_at` current schema'da zaten vardır. V2.1 bunun üzerine güvenli
application/UI lifecycle kuracaktır.

Ayrı child kapsamı:

- proje adı düzenleme;
- archive;
- restore;
- optimistic revision;
- append-only project event history;
- bağlı Ajanda/Hatırlatıcı/Puantaj/Beton kayıtlarını koruma;
- arşivli projeyi yeni saha kayıtlarında varsayılan seçimden çıkarma;
- geçmiş kayıt ve raporlarda proje kimliğini kaybetmeme.

Kalıcı proje silme bu preflight'ın yetkisi değildir. Boş test projesinin kalıcı
silinmesi istenirse mevcut `no_physical_delete` ilkesiyle çatışması ayrı karar
olarak çözülmelidir.

## 10. V2.1 child sırası

1. **V2.1a — schema 11 project_locations foundation + nullable links**
2. **V2.1b — project/location repository ve application contract**
3. **V2.1c — proje edit/archive/restore ve event history**
4. **V2.1d — Mahal Kataloğu yönetim UI**
5. **V2.1e — Ajanda stable mahal selection/adoption**
6. **V2.1f — Hatırlatıcı ve Beton stable mahal adoption**
7. **V2.1g — migration + backup/restore + saha acceptance**

V2.2 production implementation, gerekli V2.1 stable identity foundation merge
edilmeden başlamaz.

## 11. V2.1a acceptance kriterleri

- AppDatabase current schema `11` olur.
- Schema 10 → 11 migration tek transaction'da tamamlanır.
- Migration failure partial schema bırakmaz.
- Existing project, Ajanda, reminder, Puantaj ve Beton kayıt sayıları değişmez.
- Existing record ID'leri değişmez.
- Existing location/text snapshot'ları değişmez.
- Existing attachment rows/files/source links değişmez.
- `project_locations` fresh/upgrade kurulumda aynı sözleşmeye sahiptir.
- Existing rows için yeni location linkleri NULL'dır.
- Foreign-key check PASS.
- Backup format `1` korunuyorsa schema 10 backup → schema 11 restore testi PASS.
- Full mobile regression ve analyze, persistence riskine uygun şekilde çalışır.
- Gerçek kullanıcı data root'u migration testi için kullanılmaz; sentetik schema
  10 fixture kullanılır.

## 12. Stop conditions

Aşağıdaki durumda V2.1a edit başlamadan veya devam etmeden durur:

- başka bir production location field'i keşfedilirse;
- existing row text/ID değerini değiştirmek zorunlu görünürse;
- migration tablo rebuild nedeniyle unrelated V1 contract'ını değiştirmek
  zorunda kalırsa;
- backup format bump gerekliliği kanıtlanırsa;
- foreign-key graph mevcut attachment/source linkini bozuyorsa.

Bu durumlar preflight revizyonu ve ayrı review ister.

## 13. Bilerek kapsam dışı

- fuzzy text matching
- AI ile otomatik mahal çıkarımı
- BIM/spatial map
- WBS/look-ahead
- Puantaj için zorunlu mahal
- Attachment v2
- kişi/firma omurgası
- permanent project delete
- gerçek kullanıcı verisinde toplu otomatik conversion

## 14. Sonuç

V2.1 için en düşük riskli geçiş, mevcut stable proje UUID'lerini koruyup yeni
nullable stable mahal bağlantısını serbest text snapshot'ların yanına eklemektir.

İlk production işi, kullanıcı davranışını genişletmeden schema 11 foundation'ı
kurmalıdır. Katalog oluşturma ve eski textleri stable mahale bağlama, daha
sonraki açık kullanıcı işlemleriyle yapılacaktır.
