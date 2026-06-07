# Adım 103 - Attachment Integrity JSON Export

## Amaç

Bu adımda `AttachmentIntegrityReport` nesnesini dosyaya yazmadan JSON string formatına dönüştüren küçük bir helper fonksiyon eklendi.

Eklenen helper:

```python
export_attachment_integrity_report_to_json(report, indent=2)
```

## Serializer ile JSON Export Arasındaki Fark

Serializer, model nesnesini Python dictionary yapısına çevirir.

JSON export ise bu dictionary yapısını JSON string haline getirir.

Bu projede sıra bilinçli olarak küçük tutuldu:

1. Önce model oluşturuldu.
2. Sonra model dictionary formatına serialize edildi.
3. Bu adımda dictionary JSON string haline getirildi.
4. Dosyaya yazma daha sonraya bırakıldı.

## Neden Dosyaya Yazma Sonraya Bırakıldı?

Dosyaya yazma ayrı riskler taşır:

- Dosya yolu seçimi
- Klasör oluşturma
- Var olan dosyanın üzerine yazma riski
- Yetki / izin hataları
- Backup ve audit ihtiyacı

Bu adım yalnızca JSON string üretir. Böylece veri formatı test edilir ama dosya sistemi davranışı henüz eklenmez.

## `json.dumps` Ne İşe Yarar?

`json.dumps`, Python dictionary, liste, string, sayı, boolean ve `None` gibi değerleri JSON string formatına dönüştürür.

Bu adımda `json.dumps` doğrudan dosyaya yazmaz; sadece string üretir.

## `ensure_ascii=False` Ne İşe Yarar?

`ensure_ascii=False`, Türkçe karakterlerin JSON içinde okunabilir kalmasını sağlar.

Örneğin `Şantiye eki doğrulandı.` metni kaçış karakterlerine bozulmadan JSON içinde görülebilir.

## `indent` Ne İşe Yarar?

`indent=2`, JSON çıktısını okunabilir biçimde satırlara böler.

`indent=None`, daha kompakt tek satırlık JSON üretir. Bu, API veya log hattında gerekebilir.

## Scanner, CLI, Audit ve Backup Hattına Katkısı

JSON export helper ileride şu işler için temel sağlar:

- Scanner raporunu API veya CLI çıktısına dönüştürme
- Audit event içine rapor snapshot'ı koyma
- Backup doğrulama raporu üretme
- Debug veya log çıktısı hazırlama

## Bu Adımda Yapılmayan İşler

- JSON dosyası yazılmadı.
- Dosya yolu alınmadı.
- Klasör oluşturulmadı.
- Scanner yazılmadı.
- Dosya sistemi taranmadı.
- Upload service eklenmedi.
- Backup / restore davranışı eklenmedi.
- Audit event implement edilmedi.
