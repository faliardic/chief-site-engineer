# Adım 105 - Attachment Integrity JSON File Export Helper

## Amaç

Bu adımda `AttachmentIntegrityReport` nesnesini verilen JSON dosya yoluna yazan küçük bir helper fonksiyonu eklendi.

Eklenen helper:

```python
export_attachment_integrity_report_to_json_file(
    report,
    output_path,
    indent=2,
    overwrite=False,
)
```

## JSON String Export ile JSON File Export Farkı

JSON string export, raporu yalnızca metin olarak üretir.

JSON file export ise bu metni fiziksel bir dosyaya yazar.

Bu iki davranışı ayırmak önemlidir. Önce veri formatı doğru mu diye test edilir, sonra bu formatın dosyaya güvenli yazılması ele alınır.

## Overwrite Politikası Neden Gerekir?

Dosyaya yazma işleminde aynı isimde dosya zaten var olabilir.

Varsayılan davranış `overwrite=False` olduğu için mevcut dosyanın üzerine sessizce yazılmaz. Bu, eski raporların yanlışlıkla kaybolmasını engeller.

`overwrite=True` açıkça verilirse dosya üzerine yazılabilir. Bu karar ileride audit event ile ilişkilendirilebilir.

## UTF-8 Encoding Neden Önemlidir?

Attachment integrity raporlarında Türkçe notlar, saha açıklamaları veya kullanıcı metinleri bulunabilir.

UTF-8 encoding, bu karakterlerin dosyada bozulmadan saklanmasını sağlar.

Bu adımda JSON string helper zaten `ensure_ascii=False` kullandığı için Türkçe karakterler okunabilir kalır.

## `tmp_path` ile Dosya Yazma Testi

Testlerde gerçek proje klasörüne dosya yazılmadı.

Pytest'in `tmp_path` fixture'ı kullanıldı. Bu fixture her test için geçici ve güvenli bir klasör verir.

Böylece dosya oluşturma, üzerine yazma ve eksik parent klasörü gibi senaryolar proje dosyalarına zarar vermeden test edilir.

## Bu Adım Neden Scanner Değildir?

Bu helper yalnızca kendisine verilen report nesnesini dosyaya yazar.

Şunları yapmaz:

- Klasör taramaz.
- Attachment metadata aramaz.
- Dosya var mı diye tüm arşivi kontrol etmez.
- Missing/orphan kararı üretmez.
- Backup veya audit davranışı eklemez.

Scanner, ileride ayrı ve daha büyük bir davranış olarak ele alınmalıdır.

## Parent Klasör Neden Otomatik Oluşturulmadı?

Parent klasörün otomatik oluşturulmaması kontrollü bir ilk davranıştır.

Klasör oluşturmak ayrı bir karardır:

- Hangi klasör güvenli?
- Eksik klasör hata mı, yoksa oluşturulacak mı?
- Yetki ve path traversal riskleri nasıl ele alınacak?

Bu adımda parent klasör yoksa `FileNotFoundError` verilir. Böylece yanlış path sessizce yeni klasörler oluşturarak ilerlemez.

## Bu Adımda Yapılmayan İşler

- Scanner yazılmadı.
- Dosya sistemi taraması yapılmadı.
- Backup / restore implement edilmedi.
- Audit event implement edilmedi.
- Upload service eklenmedi.
- Gerçek proje klasörüne test dosyası yazılmadı.
