# Adim 065 - Uygunsuzluk Duruma Gore Filtreleme

## Bu Adimda Ne Ogrenildi?

Bu adimda repository icinde status degerine gore liste filtreleme davranisi netlestirildi.

`NonconformityRepository` icinde bu davranis `list_by_status(status)` methodu ile temsil edilir.

## Method Zaten Var Miydi?

Evet. `list_by_status(status)` methodu repository icinde zaten bulunuyordu.

Bu nedenle bu adimda `filter_by_status(status)` adinda ikinci bir method eklenmedi. Mevcut adlandirma korundu ve davranis ek testlerle guvence altina alindi.

## Read-Only Davranis

`list_by_status(status)` salt okuma davranisidir.

Bu method:

- Kayit silmez.
- `status` alanini degistirmez.
- `is_archived` alanini degistirmez.
- Otomatik history olusturmaz.
- Otomatik workflow baslatmaz.

## Bos Liste Neden Dogru?

Repository bos olabilir veya aranan status degeriyle eslesen kayit olmayabilir.

Bu durumda methodun bos liste dondurmesi beklenir:

```python
[]
```

Bos liste, "filtreye uyan kayit yok" anlamina gelir.

## Arsivlenmis Kayitlar Neden Dahil?

Status filtreleme tum kayit hafizasi uzerinde calisir. Arsivlenmis kayitlar sistemden silinmedigi icin status eslesmesi varsa filtre sonucunda gorunebilir.

Aktif veya arsiv ayrimi gerekiyorsa ayri olarak `list_active()` veya `list_archived()` kullanilir.

## Python Ogrenme Acisindan Ders

Bu adim su konulari pekistirir:

- Liste filtreleme
- Read-only method tasarimi
- Bos liste donusu
- Mevcut davranisi tekrar yazmadan testle sabitleme
- Status ile arama ve arsiv durumu arasindaki fark

## Santiye Pratigindeki Anlami

Sahada NCR kayitlarini duruma gore ayirmak gunluk takip icin onemlidir.

Acik kayitlar is takibi icin, kapali kayitlar kalite gecmisi icin, devam eden kayitlar ise sorumluluk takibi icin incelenebilir.

Status filtresi bu ayrimi yazilim tarafinda sade ve test edilebilir bir davranisla temsil eder.
