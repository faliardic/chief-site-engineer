# Adim 047 - Repository Genel Ozet Ogrenim Notu

## Repository Icinde Genel Ozet Uretme

Repository bazen tek tek kayitlari listelemekten daha fazlasini yapar. Kayitlar hakkinda genel sayisal ozet de uretebilir.

Bu adimda `NonconformityRepository` icine `get_overview_summary` metodu eklendi.

## get_overview_summary Ne Ise Yarar?

`get_overview_summary()`, repository icindeki NCR kayitlarinin temel durumunu tek bir sozlukte verir.

Ornek:

```python
{
    "total": 5,
    "open": 2,
    "closed": 1,
    "assigned": 4,
    "unassigned": 1,
}
```

## Alanlarin Anlami

- `total`: Repository icindeki tum kayit sayisi.
- `open`: `status == "open"` olan kayit sayisi.
- `closed`: `status == "closed"` olan kayit sayisi.
- `assigned`: `responsible_party` degeri `None` olmayan kayit sayisi.
- `unassigned`: `responsible_party` degeri `None` olan kayit sayisi.

## dict Kullanimi ve Sayac Mantigi

Metot sabit anahtarlari olan bir `dict` ile baslar:

```python
summary = {
    "total": 0,
    "open": 0,
    "closed": 0,
    "assigned": 0,
    "unassigned": 0,
}
```

Sonra repository icindeki kayitlari gezer ve ilgili sayaclari artirir.

## Bos Repository Icin Neden Tum Degerler 0?

Genel ozet sabit anahtarli bir yapidir. Kayit olmasa bile dashboard, rapor veya AI cevap sistemi ayni anahtarlari bekleyebilir.

Bu nedenle bos repository icin `{}` yerine tum degerleri `0` olan dict dondurmek daha kullanislidir.

## Neden Dashboard Degil?

Bu adim dashboard eklemez. Ekran, grafik, CLI ciktisi veya rapor uretmez.

Sadece ileride dashboard, rapor veya AI soru-cevap sistemi tarafindan kullanilabilecek bellek ici veri hazirlar.

## Santiye Pratiginde Anlami

Gunluk saha yonetiminde kalite ekibi su sorulari hizli gormek ister:

- Toplam kac NCR var?
- Kaci acik?
- Kaci kapandi?
- Kaci bir sorumluya atanmis?
- Kaci henuz atanmamis?

Bu genel ozet, gunluk toplantilar ve kalite takibi icin temel bir pano bilgisidir.

## Testte Ne Kontrol Edildi?

Ilk test, dolu repository icin toplam, acik, kapali, atanmis ve atanmamis sayilarin dogru dondugunu kontrol eder.

Ikinci test, bos repository icin tum degerlerin `0` dondugunu dogrular.

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

Adim 047 ile `NonconformityRepository` icine genel ozet davranisi eklendi.

Bu adim, kesin uygunsuzluk kayitlarinin genel durumunu dashboard, rapor veya AI cevaplari icin hazir hale getiren bellek ici bir temel saglar.
