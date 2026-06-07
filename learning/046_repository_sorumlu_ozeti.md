# Adim 046 - Repository Sorumlu Taraf Ozeti Ogrenim Notu

## Repository Icinde Sorumlu Taraf Ozeti

Repository, kayitlari filtrelemenin yaninda kayitlar hakkinda ozet bilgi de uretebilir.

Bu adimda `NonconformityRepository` icine `get_responsible_party_summary` metodu eklendi.

## get_responsible_party_summary Ne Ise Yarar?

`get_responsible_party_summary()`, repository icindeki `NonconformityRecord` kayitlarini `responsible_party` degerlerine gore sayar.

Ornek:

```python
{
    "Ahmet": 2,
    "Mehmet": 1,
    "unassigned": 1,
}
```

Bu sonuc, NCR kayitlarinin hangi kisi, ekip veya firma uzerinde toplandigini gosterir.

## dict Kullanimi ve Sayac Mantigi

Metot bir `dict` kullanir. Anahtar sorumlu taraf adidir, deger ise o sorumlu tarafa ait kayit sayisidir.

```python
summary: dict[str, int] = {}
for record in self._records:
    responsible_party = record.responsible_party or "unassigned"
    summary[responsible_party] = summary.get(responsible_party, 0) + 1
return summary
```

`summary.get(responsible_party, 0)` mevcut sayiyi alir. Sorumlu taraf daha once hic gorulmediyse `0` kabul eder ve uzerine `1` ekler.

## None Degerler Neden unassigned Olarak Sayildi?

`responsible_party` alani `None` olabilir. Bu, kaydin henuz bir kisi, ekip veya firmaya atanmadigini anlatir.

Ozet icinde `None` degerini dogrudan kullanmak yerine `unassigned` anahtari kullanildi. Boylece rapor veya dashboard tarafinda "atanmamis" kayitlar daha okunur hale gelir.

## Bos Repository Icin Neden Bos dict?

Repository icinde kayit yoksa sayilacak sorumlu taraf da yoktur.

Bu durumda `{}` dondurmek dogrudur. Bu, "hic ozet verisi yok" bilgisini sade sekilde verir.

## Neden Dashboard Degil?

Bu adim dashboard eklemez. Ekran, grafik, tablo veya CLI ciktisi uretmez.

Sadece ileride dashboard, rapor veya AI soru-cevap sistemi tarafindan kullanilabilecek bellek ici veri hazirlar.

## Santiye Pratiginde Anlami

NCR kayitlarini kisi, ekip veya firmaya gore saymak sahada sorumluluk dagilimini gormek icin onemlidir.

"Ahmet'in uzerinde kac NCR var?", "Mehmet kac kaydi takip ediyor?", "Henuz atanmis olmayan NCR var mi?" sorulari kalite takibi icin kritik olabilir.

## Testte Ne Kontrol Edildi?

Ilk test, Ahmet, Mehmet ve atanmamis kayitlarin dogru sayildigini dogrular.

Ikinci test, bos repository icin `get_responsible_party_summary()` sonucunun `{}` oldugunu dogrular.

## Kapsam Disi Birakilanlar

- JSON
- SQLite
- API
- GUI
- CLI
- Dashboard
- Dosya islemi
- Otomatik is akisi

## Kisa Ozet

Adim 046 ile `NonconformityRepository` icine sorumlu taraf ozeti ureten bellek ici davranis eklendi.

Bu adim, kesin uygunsuzluk kayitlarinin kisi, ekip, firma veya atanmamis sorumluluk dagilimini ileride dashboard, rapor veya AI cevaplari icin hazir hale getirir.
