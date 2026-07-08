# Adim 135 - Record ID Soft Validation Diagnostic Helper Implementation Plan

## Diagnostic helper nedir?

Diagnostic helper, bir degeri reddetmeden inceleyen ve sonucunu okunabilir bir rapor olarak donduren yardimci fonksiyondur.

Bu projede diagnostic helper'in amaci, `target_record_type` ve `target_record_id` ciftine bakip su sorulara cevap vermektir:

- Bu target type bilinen bir kategori mi?
- Bu ID hangi prefix ile basliyor?
- Bu prefix bilinen prefixlerden biri mi?
- Sonuc bilgi mi, uyari mi, yoksa helper giris hatasi mi?

Diagnostic helper kaydi engellemez. Sadece gorunurluk saglar.

## Soft validation ile diagnostic output iliskisi nedir?

Soft validation, veri reddetmeden bilgi veya uyari uretme yaklasimidir.

Diagnostic output ise bu soft validation sonucunun somut halidir.

Ornek diagnostic output:

```text
target_record_type=attachment
target_record_id=file-att-001
observed_prefix=file-att
severity=warning
is_compatible=False
message=Legacy attachment id prefix kullaniliyor.
```

Bu sonuc kaydi reddetmez. Sadece raporda veya kalite kontrol ciktisinda "bu ID legacy gorunuyor" bilgisini verir.

## Neden constructor icinde veri reddetmek yerine once dis QC katmani tercih edilir?

Constructor icinde veri reddetmek hard validation anlamina gelir.

Bu erken yapilirsa `NCR-001`, `REC-1`, `file-att-001` veya `audit-001` gibi mevcut ve anlamli legacy ornekler kirilabilir.

Dis QC katmani ise daha yumusak bir basamaktir. Kayit olusur, ama kalite kontrol raporunda ID'nin canonical, legacy veya bilinmeyen oldugu gorunur.

Bu yaklasim, veri kaybini ve ani test kirilmalarini onler.

## Severity yaklasimi neden onemlidir?

Severity, diagnostic sonucunun onem derecesini anlatir.

Onerilen seviyeler:

- `info`: Uyumlu veya canonical gorunen ID.
- `warning`: Legacy veya supheli ama reddedilmeyen ID.
- `error`: Helper giris hatasi veya diagnostic uretilemeyen durum.

Bu ayrim raporlamayi daha okunur hale getirir. Her sorun ayni sertlikte degildir. Legacy ID uyaridir; constructor tarafinda reddedilen zorunlu alan eksikligi baska bir konudur.

## Bu yaklasim audit/handover guvenilirligine nasil katkı saglar?

Audit ve handover sureclerinde yalnizca kaydin var olmasi yetmez. Kaydin hangi kayda baglandigi ve bu baglantinin ne kadar okunur oldugu da onemlidir.

Diagnostic helper, handover veya audit export oncesinde su sinyalleri verebilir:

- Hangi ID'ler canonical gorunuyor?
- Hangi ID'ler legacy ama kabul edilebilir?
- Hangi ID'ler bilinmeyen prefix tasiyor?
- Hangi target type icin mapping belirsiz?

Bu sinyaller, sahadaki kanit zincirinin kalitesini artirir.

## Bu adimin ana dersi

Guvenilir veri omurgasi kurmak icin her uyumsuzlugu hemen hata yapmak gerekmez.

Once diagnostic uretilir. Sonra ekip gercek veri davranisini gorur. Daha sonra test ornekleri standardize edilir. En son hard validation dusunulur.

Bu sira CSE icin daha guvenlidir: once gorunurluk, sonra standardizasyon, en son sert kural.
