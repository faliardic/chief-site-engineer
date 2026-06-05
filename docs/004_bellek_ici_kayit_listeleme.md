# 004 Bellek Ici Kayit Listeleme

## Bellek Ici Kayit Listeleme Nedir?

Bellek ici kayit listeleme, kayitlari veritabanina veya dosyaya yazmadan, program calisirken Python listeleri uzerinde islemektir.

## Bu Adimda Neden Veritabani veya JSON Kullanilmadi?

Bu adimda amac kalici kayit sistemi kurmak degildir. Once kayitlarin nasil listelenecegi, sayilacagi ve filtrelenecegi sade Python fonksiyonlariyla netlestirilir.

## Fonksiyonlar Ne Yapar?

- `list_records`: Verilen kayit listesini oldugu gibi dondurur.
- `count_records`: Listedeki kayit sayisini dondurur.
- `filter_records_by_project_id`: `project_id` alani olan kayitlari verilen proje kimligine gore filtreler.
- `filter_records_by_status`: `status` alani olan kayitlari verilen durum degerine gore filtreler.

## Ileride Hangi Modullere Temel Olacak?

Bu fonksiyonlar ileride kayit listeleme, gunluk rapor ozetleri, arsiv gorunumleri, durum bazli takip ve basit raporlama modullerine temel olacaktir.

## Santiye Sefi Acisindan Ne Ise Yarar?

Santiye sefi tum kayitlari gorebilir, toplam kayit sayisini anlayabilir, belirli bir santiyeye ait kayitlari ayirabilir ve taslak ya da kapali gibi durumlara gore kayitlari filtreleyebilir.
