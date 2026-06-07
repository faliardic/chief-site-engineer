# Adim 044 - NonconformityRepository Sorumlu Filtreleme

## Amac

Bu adimda `NonconformityRepository` icine `NonconformityRecord` kayitlarini `responsible_party` alanina gore filtreleyen kucuk ve izole bir davranis eklendi.

Eklenen metot:

```text
list_by_responsible_party(responsible_party)
```

## Davranis

- Verilen `responsible_party` degerine sahip kayitlari liste olarak dondurur.
- Eslesen kayit yoksa bos liste dondurur.
- Kayitlarin repository'ye eklenme sirasini korur.
- `add`, `list_all`, `find_by_id`, duplicate id kontrolu ve `list_by_status` davranislari korunur.

## Neden Gerekli?

Kesin uygunsuzluk / NCR kayitlari sahada farkli kisi, ekip veya firmalara atanabilir.

Sorumlu tarafa gore filtreleme, belirli bir kisinin veya ekibin uzerindeki NCR kayitlarini gormek icin temel bir repository davranisidir.

## Kapsam Disi Birakilanlar

Bu adimda su mekanizmalar eklenmedi:

- JSON
- SQLite
- API
- GUI
- CLI
- Dosya islemi
- Dashboard
- Otomatik is akisi

Bu davranis veritabani sorgusu degildir. Simdilik sadece bellek icinde Python listesi uzerinde filtreleme yapar.
