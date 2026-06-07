# Adim 042 - NonconformityRepository Duplicate Id Kontrolu

## Amac

Bu adimda `NonconformityRepository` icine ayni `nonconformity_id` degerine sahip ikinci bir `NonconformityRecord` eklenmesini engelleyen bellek ici kontrol eklendi.

## Davranis

- `add(record)` cagrildiginda repository icinde ayni `nonconformity_id` aranir.
- Ayni kimlik varsa `ValueError` yukseltir.
- Farkli kimlige sahip kayitlar normal sekilde eklenir.
- `list_all` ve `find_by_id` davranislari korunur.

## Neden Gerekli?

Kesin uygunsuzluk / NCR kayitlari kimlikleriyle takip edilir. Ayni NCR numarasinin iki farkli kayit icin kullanilmasi sahada karisikliga neden olur.

Bu nedenle duplicate id kontrolu repository seviyesinde baslatildi.

## Kapsam Disi Birakilanlar

Bu adimda su mekanizmalar eklenmedi:

- JSON
- SQLite
- API
- GUI
- CLI
- Dosya islemi
- Otomatik is akisi

Bu kontrol veritabani unique constraint degildir. Simdilik sadece bellek icinde Python kontroludur.
