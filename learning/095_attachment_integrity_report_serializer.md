# Adim 095 - Attachment Integrity Report Serializer

## Serializer Nedir?

Serializer, bir model nesnesini daha genel ve tasinabilir bir veri yapisina donusturen yardimci fonksiyondur.

Bu adimda `AttachmentIntegrityResult`, `AttachmentIntegrityReportSummary` ve `AttachmentIntegrityReport` modelleri dictionary formatina cevrildi.

## Model Nesnesi ile Dictionary / JSON'a Hazir Veri Arasindaki Fark

Model nesnesi Python icinde davranis ve veri tasiyan dataclass yapisidir.

Dictionary ise API, CLI, log, audit veya raporlama katmanlarina daha kolay aktarilabilecek sade anahtar/deger yapisidir.

Bu adimda uretilen dict verisi JSON'a hazir olabilir, ancak dosyaya yazilmaz.

## Neden Once Dict Serializer Yaziyoruz?

Dosyaya yazma, API cevabi veya CLI raporu gibi cikis kanallari farkli olabilir.

Once ortak dict serializer yazmak, bu farkli cikis kanallarinin ayni veri formatini kullanmasini saglar.

Dosya yazma davranisi daha sonra ayrica ve kontrollu bir adimda ele alinabilir.

## Datetime Alanlari Neden ISO 8601 String Olur?

`datetime` nesneleri Python icinde anlamlidir, fakat API, CLI veya log ciktisinda metne donusmeleri gerekir.

ISO 8601 formati hem insan tarafindan okunabilir hem de makineler tarafindan kolay parse edilebilir.

Bu nedenle `checked_at` ve `generated_at` alanlari `isoformat()` ile stringe cevrilir.

## None Alanlarini Korumak Neden Faydalidir?

`None` alanlarini dict icinde korumak, alanin bilincli olarak bos oldugunu gosterir.

API, CLI ve debug ciktisinda alanin hic gelmemesi ile `None` gelmesi farkli anlam tasiyabilir.

Bu adimda alanlar dict disina atilmaz; rapor formati acik ve sabit kalir.

## Bu Adim Neden Scanner veya File Export Degildir?

Bu adim dosya sistemi taramasi yapmaz.

Scanner yazmaz.

JSON dosyasi olusturmaz.

`json.dump` veya fiziksel dosya yazma davranisi eklemez.

Bu adim yalnizca mevcut attachment integrity modellerini standart dictionary formatina cevirir.
