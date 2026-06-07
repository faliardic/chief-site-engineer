# Adim 043 - NonconformityRepository Durum Filtreleme

## Amac

Bu adimda `NonconformityRepository` icine `NonconformityRecord` kayitlarini `status` alanina gore filtreleyen kucuk ve izole bir davranis eklendi.

Eklenen metot:

```text
list_by_status(status)
```

## Davranis

- Verilen `status` degerine sahip kayitlari liste olarak dondurur.
- Eslesen kayit yoksa bos liste dondurur.
- Kayitlarin repository'ye eklenme sirasini korur.
- `add`, `list_all`, `find_by_id` ve duplicate id kontrolu davranislari korunur.

## Neden Gerekli?

Kesin uygunsuzluk / NCR kayitlari sahada farkli durumlarda olabilir:

- Acik
- Devam ediyor
- Kapatildi
- Inceleme bekliyor

Duruma gore filtreleme, bu kayitlari ayri ayri okumak icin temel bir repository davranisidir.

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
