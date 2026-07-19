# Issue #175 — Geriye Dönük Observation Create Contract

## Amaç

Bu adım, bir saha olayının gerçekleştiği zaman ile kaydın CSE'ye girildiği
zamanı observation create akışında birbirinden ayırır. Şantiye şefi öğleden
sonra sabah yaşanan bir olayı kaydettiğinde olay Ajanda'da sabah saatine ait
olabilmeli; audit ve attachment kayıtları ise CSE'ye gerçek giriş anını
göstermelidir.

## Application command

Create girdileri frozen command nesnesinde toplanır:

```python
CreateObservation(
    project_id=project_id,
    location="A Blok",
    category="quality",
    description="Sabah kalıp kontrolü",
    notes=None,
    upload=None,
    observed_at="2026-07-12T07:15:00Z",
)
```

`observed_at` opsiyoneldir. Verilmezse create işleminin tek clock değeri hem
olay zamanı hem giriş zamanı olur. Verilirse yalnız canonical UTC seconds
biçimi kabul edilir:

```text
YYYY-MM-DDTHH:MM:SSZ
```

Naive değer, `+00:00` offset metni, invalid tarih, fractional seconds veya
giriş zamanından sonraki future event time reddedilir.

## Zaman rolleri

| Alan | Rol | Kaynak |
|---|---|---|
| `observation.observed_at` | Sahadaki olay zamanı | Explicit değer veya omitted ise clock |
| `observation.created_at` | CSE'ye giriş zamanı | Tek clock okuması |
| `observation.updated_at` | İlk revision güncelleme zamanı | Tek clock okuması |
| Created event `occurred_at` | Create işleminin gerçekleştiği giriş zamanı | Tek clock okuması |
| Attachment `created_at` | Metadata giriş zamanı | Tek clock okuması |

Explicit geçmiş zaman, `TimestampRole.EVENT_TIME` politikasıyla giriş zamanına
göre doğrulanır. Geçmiş ve aynı an geçerlidir; gelecek olay zamanı geçersizdir.

## Fail-closed sıra

Create akışı aşağıdaki sırayı korur:

```text
CreateObservation doğrulaması
-> service clock tek okuma ve canonical seconds doğrulaması
-> EVENT_TIME future policy
-> UUID üretimi
-> varsa attachment staging
-> observation + metadata + event aynı Unit of Work
-> attachment finalize
-> database commit
```

Temporal validation başarısızsa UUID, staging, Unit of Work, observation row,
attachment metadata veya event mutation başlamaz.

## Created event payload

Created event artık ayrımı açıkça taşır:

```json
{
  "attachment_ids": ["bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb"],
  "created_at": "2026-07-13T09:00:00Z",
  "observed_at": "2026-07-12T07:15:00Z",
  "revision": 1,
  "status": "open"
}
```

Event `occurred_at` değeri `2026-07-13T09:00:00Z` olur. Böylece event'in ne
zaman yazıldığı ile kayda konu olayın ne zaman yaşandığı karıştırılmaz.

## Compatibility

- Web create formuna yeni alan eklenmedi.
- Acceptance ve operasyon CLI çağrıları explicit `observed_at` vermeden aynı
  davranışı sürdürür.
- `FieldObservationRecord`, SQLite kolonları ve repository sözleşmesi
  değiştirilmedi.
- Schema version `4` kaldı.
- Restore allowlist `(2, 3, 4)` kaldı.
- Backup format `1` ve Günlük Çıktı format `1` kaldı.
- Existing finalize, rollback, staging cleanup ve orphan reconciliation
  davranışları korundu.

## Executable kanıt

`tests/test_observation_application_service.py` şunları doğrular:

- command frozen davranışı;
- explicit geçmiş olay zamanının restart sonrasında korunması;
- omitted olay zamanının tek clock değeri olması;
- created event payload ve `occurred_at` ayrımı;
- attachment metadata giriş zamanı;
- future event time için mutation öncesi fail-closed davranış;
- naive, invalid, offset biçimli ve microsecond write reddi;
- event add, finalize, commit ve cleanup hata sınırlarının korunması.

Web, acceptance, CLI, Backup/Restore ve Günlük Çıktı regresyonları mevcut
kullanıcı ve artifact davranışının değişmediğini kanıtlar.

## Kapsam dışı

Bu adım yeni Ajanda ekranı, web tarih alanı, route, schema migration, row
rewrite, repository API, archive/unarchive, scope, MemoryIndex,
mobile/offline/notification veya security davranışı eklemez. Gerçek kullanıcı
data root'u okunmaz.
