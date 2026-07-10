# Learning 179 - Export Result Report Formatter Downstream Integration Boundary Plan

Bu adimda `format_export_result_report_as_markdown(report)` helper'inin ileride GUI, API, CLI, handover QC ekrani veya export review akisinda nasil sinirlandirilmasi gerektigini documentation-only olarak planladik.

## Ana karar

Formatter presentation layer'dir.

Formatter mevcut report dict'ini Markdown metnine cevirir.

Formatter karar, validation, bloklama, audit, persistence veya export writing katmani degildir.

## Entegrasyon eklenmedi

Bu adimda:

- GUI eklenmedi
- API endpoint eklenmedi
- CLI komutu eklenmedi
- handover QC ekrani eklenmedi
- export review workflow eklenmedi
- yeni helper eklenmedi
- yeni test eklenmedi

Sadece gelecekteki downstream kullanim siniri belgelendi.

## Gelecekte nasil kullanilabilir?

Gelecekte bir GUI, API veya CLI gelirse formatter ciktisini yalniz read-only sunum olarak gosterebilir.

Ornekler:

- handover QC ekraninda Markdown gorunumu
- export review checklist icinde okunabilir rapor
- CLI'da operator summary
- API response icinde read-only formatted presentation

Bu entegrasyonlar ayri adim, ayri test ve ayri dokumantasyon gerektirir.

## Nasil kullanilmamali?

Downstream consumer formatter'a ham export writer gibi davranmamalidir.

Formatter:

- dosya yazmaz
- export uretmez
- database/repository erisimi yapmaz
- audit event uretmez
- backup/restore yapmaz
- hard validation degildir
- otomatik onay mekanizmasi degildir
- otomatik bloklama mekanizmasi degildir
- `blocked` status uretmez

## Report dict contract

Downstream consumer mevcut `build_export_result_report(...)` report dict contract'ina bagli kalmalidir.

Formatter eksik field tamamlamak, count yeniden hesaplamak, path safety calistirmak veya raw result contract'i yeniden yorumlamak icin kullanilmamalidir.

Unknown, missing veya additional field durumlari presentation boundary icinde kalir.

## Handover QC ve export review ayrimi

Handover QC ekrani ileride formatter ciktisini gosterebilir.

Export review checklist ileride formatter ciktisini okunabilir gorunum olarak kullanabilir.

Ancak karar insan review veya ayri business workflow tarafindan verilmelidir.

Formatter success gorunurlugu saglar ama resmi kabul yerine gecmez.

Formatter failure gorunurlugu saglar ama otomatik bloklama yapmaz.

## Hard validation

Hard validation gerekiyorsa daha sonra ayri bir katman olarak tasarlanmalidir.

Bu katman formatter text'ine gizli sekilde baglanmamalidir.

Ayrica kendi input/output contract'i, testleri, dokumantasyonu ve karar kurallari olmalidir.
