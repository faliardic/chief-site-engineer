# Adim 113 - AuditEventRecord Baslangic Modeli

## Ne Yaptik?

`AuditEventRecord` adinda yeni bir dataclass modeli ekledik.

Bu model bir olay izini temsil eder. Ornegin ileride bir kayit olusturuldugunda, guncellendiginde, arsivlendiginde veya bir rapor export edildiginde bu olay audit event olarak anlatilabilir.

## Neden Sadece Model Ekledik?

Bu adimda amac davranis yazmak degil, veri seklini netlestirmekti.

Bu nedenle repository, database, otomatik audit yazimi, JSON log dosyasi veya scanner baglantisi eklemedik.

## Dataclass Bize Ne Sagladi?

Dataclass ile alanlari sade sekilde tanimladik:

```python
event = AuditEventRecord(
    event_id="audit-001",
    project_id="prj-001",
    event_type="record_updated",
    actor="Santiye sefi",
    occurred_at="2026-06-23T10:30:00",
)
```

Bu kullanimda zorunlu alanlar verilir. Hedef kayit, gerekce, eski/yeni deger, kaynak ve not alanlari verilmezse `None` kalir.

## Ne Ogreniyoruz?

Buyuk bir audit sistemi bir anda kurulmak zorunda degildir.

Once olay kaydinin hangi alanlardan olusacagi netlestirilir. Sonra validation, event type sabitleri, repository, persistence ve otomatik olay uretimi gibi davranislar ayri ve testli adimlarda eklenebilir.

## Bu Adimin Siniri

Bu adim:

- audit modeli ekler
- temel model testleri ekler
- dokumantasyon ve learning kaydi ekler

Bu adim:

- audit log yazmaz
- dosya olusturmaz
- database kullanmaz
- scanner davranisi degistirmez
- resmi kayitlari otomatik guncellemez
