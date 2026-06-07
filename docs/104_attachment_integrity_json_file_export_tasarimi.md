# Adım 104 — Attachment Integrity JSON File Export Tasarımı

## 1. Amaç

Bu doküman, `AttachmentIntegrityReport` bilgisinin ileride güvenli şekilde JSON dosyasına yazılması için tasarım kurallarını tanımlar.

Adım 103'te `export_attachment_integrity_report_to_json(...)` helper fonksiyonu eklendi. Bu helper yalnızca JSON string üretir. JSON file export ise bu stringin güvenli bir dosya yolu, encoding, overwrite politikası ve atomic write yaklaşımıyla fiziksel dosyaya yazılması anlamına gelir.

Bu adım dosyaya yazma implementasyonu değildir. Kod yazmaz, JSON dosyası oluşturmaz, scanner eklemez, backup veya audit davranışı implement etmez. Sadece ileride güvenli dosya export davranışı için kararları netleştirir.

## 2. Mevcut Durum

Mevcut attachment integrity hattında şu parçalar vardır:

- `AttachmentIntegrityReport` modeli vardır.
- `serialize_attachment_integrity_report(...)` fonksiyonu report nesnesini dictionary formatına çevirir.
- `export_attachment_integrity_report_to_json(...)` fonksiyonu report nesnesinden JSON string üretir.
- Datetime alanları ISO 8601 string olarak korunur.
- `None` alanları JSON çıktısında korunur.

Henüz dosya sistemi yazımı yoktur. Export path alma, klasör oluşturma, overwrite kararı, atomic write, audit event, backup ilişkisi ve dosyadan geri doğrulama davranışı bu adımda uygulanmaz.

## 3. JSON File Export İçin Temel Gereksinimler

İleride JSON file export eklendiğinde aşağıdaki gereksinimler korunmalıdır:

- Dosya UTF-8 encoding ile yazılmalıdır.
- JSON üretiminde `ensure_ascii=False` kullanılmalıdır.
- Varsayılan okunabilir çıktı için `indent=2` kullanılmalıdır.
- Dosya adı standardı açık olmalıdır.
- Export timestamp UTC olmalıdır.
- `source` bilgisi korunmalıdır.
- `report.generated_at` değeri değiştirilmeden korunmalıdır.
- `None` alanları çıktıdan atılmamalıdır.
- Export işlemi report nesnesini değiştirmemelidir.
- Export işlemi scanner veya dosya sistemi taraması gibi davranmamalıdır.

## 4. Dosya Adı Standardı Önerisi

Önerilen dosya adı formatı:

```text
attachment_integrity_report_YYYYMMDD_HHMMSS.json
```

Örnek:

```text
attachment_integrity_report_20260607_143210.json
```

Dosya adı kuralları:

- Güvenli karakterler kullanılmalıdır.
- Boşluk kullanılmamalıdır.
- Yerel / Türkçe karakter riskinden kaçınılmalıdır.
- Timestamp UTC olmalıdır.
- Dosya adı raporun içeriğini açıkça anlatmalıdır.
- Aynı saniyede birden fazla export ihtimali varsa ileride ek sıra numarası veya kısa id değerlendirilebilir.

## 5. Export Path Kuralları

Export path dışarıdan açıkça verilmelidir.

Varsayılan olarak proje içinde güvenli bir klasör kullanılabilir:

```text
exports/
```

Alternatif olarak ileride daha özel bir alt klasör düşünülebilir:

```text
exports/attachment_integrity/
```

Path kuralları:

- Path traversal riskine dikkat edilmelidir.
- Kullanıcı girdisiyle gelen path normalize edilmelidir.
- Export path beklenen export kökünün dışına çıkmamalıdır.
- Mevcut dosyanın üzerine yazma davranışı açıkça tanımlanmalıdır.
- Export klasörü yoksa oluşturma davranışı ayrı ve testli bir kararla eklenmelidir.
- Dosya yolu private workspace exportu ile resmi attachment integrity exportunu karıştırmamalıdır.

## 6. Overwrite Politikası

Varsayılan davranış:

```text
overwrite=False
```

Bu politika şu anlama gelir:

- Aynı dosya varsa hata verilmelidir.
- Mevcut rapor dosyasının üzerine sessizce yazılmamalıdır.
- `overwrite=True` açıkça verilirse üzerine yazma yapılabilir.
- Üzerine yazma ileride audit event ile ilişkilendirilmelidir.

Overwrite, özellikle attachment integrity raporlarında dikkatli ele alınmalıdır. Çünkü eski bir scanner raporunun üzerine yazmak, geçmiş kontrol sonucunu kaybetmeye neden olabilir.

## 7. Atomic Write Yaklaşımı

Güvenli file export için atomic write yaklaşımı tercih edilmelidir.

Önerilen akış:

1. JSON string hazırlanır.
2. Hedef dosya yerine geçici dosyaya yazılır.
3. Yazma başarılı olursa geçici dosya hedef dosyaya rename edilir.
4. Hata durumunda geçici dosya temizlenir.

Bu yaklaşımın amacı yarım yazılmış JSON dosyası bırakmamaktır.

Örnek risk:

- Yazma sırasında elektrik kesilirse hedef dosya bozuk kalabilir.
- Disk dolarsa JSON'un sadece bir kısmı yazılabilir.
- İşlem yarıda kalırsa scanner raporu okunamaz hale gelebilir.

Atomic write bu riskleri azaltır.

## 8. JSON Validasyon Yaklaşımı

JSON file export sırasında iki aşamalı doğrulama düşünülmelidir:

1. Yazmadan önce `json.dumps` başarılı olmalıdır.
2. Yazdıktan sonra dosya tekrar okunup `json.loads` ile doğrulanabilir.

Doğrulanması gereken ana yapı:

- `summary` alanı korunmalı.
- `results` listesi korunmalı.
- Datetime alanları ISO 8601 string olarak kalmalı.
- `None` alanları JSON `null` olarak saklanmalı.
- `source` ve `notes` alanları korunmalı.

Bu doğrulama, export dosyasının sadece oluştuğunu değil, okunabilir ve beklenen schema'ya yakın kaldığını gösterir.

## 9. Audit ve Backup İlişkisi

JSON export işlemi ileride audit event üretebilir.

Audit event içinde şu bilgiler yer alabilir:

- Export işlemini kim başlattı?
- Export ne zaman yapıldı?
- Hangi report source bilgisiyle export edildi?
- Export dosya yolu nedir?
- Overwrite yapıldı mı?
- Export başarılı mı, başarısız mı?

Export dosyaları backup politikasına dahil edilebilir. Attachment integrity raporu, scanner sonucunun kanıt değeri taşıyan snapshot çıktısı olabilir.

Ancak export dosyası resmi kayıt yerine geçmez. Export dosyası resmi kayıtların ve metadata kontrollerinin dışa aktarılmış görüntüsüdür. Resmi kayıtların kendisi sistemde korunmaya devam etmelidir.

## 10. Güvenlik Riskleri

JSON file export için önemli riskler:

- Path traversal: Kullanıcı girdisi export kökünün dışına çıkabilir.
- Yanlış dosyanın üzerine yazma: Eski rapor veya başka dosya kaybedilebilir.
- Yarım dosya oluşması: Yazma yarıda kalırsa bozuk JSON kalabilir.
- Hassas metadata sızıntısı: Attachment path, source, notes veya ilgili kayıt id bilgileri dışa çıkabilir.
- Eski şantiye şefinin özel alan verisinin export içine karışması: Private workspace ve resmi attachment integrity raporu ayrımı korunmalıdır.
- Resmi kayıt / private workspace ayrımının bozulması: Export kapsamı açıkça resmi attachment metadata ile sınırlanmalıdır.

Bu riskler nedeniyle file export davranışı küçük, testli ve açık parametrelerle eklenmelidir.

## 11. Bu Adımın Sınırları

Bu adımda yapılmayan işler:

- Kod yazılmadı.
- Dosyaya JSON yazılmadı.
- Export path parametresi eklenmedi.
- Klasör oluşturulmadı.
- Scanner yazılmadı.
- Dosya sistemi taraması yapılmadı.
- Audit event implement edilmedi.
- Backup davranışı eklenmedi.
- Private workspace exportu eklenmedi.
- API, GUI, CLI, auth veya deployment eklenmedi.

Bu doküman yalnızca ileride güvenli JSON file export implementasyonu için tasarım kararlarını tanımlar.
