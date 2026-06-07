# Adim 052 - Kesin Uygunsuzluk Arsiv Alani Ogrenim Notu

## Model Icine Boolean Alan Eklemek

Bir dataclass modeline yeni alan eklemek, o modelin temsil ettigi bilgi setini genisletir.

Bu adimda `NonconformityRecord` icine `is_archived` adli boolean alan eklendi.

## is_archived Ne Ise Yarar?

`is_archived`, bir NCR kaydinin arsivlenip arsivlenmedigini temsil eder.

```text
False -> kayit arsivlenmemis
True  -> kayit arsivlenmis
```

Bu alan kaydi silmez, sadece kaydin arsiv durumunu model uzerinde tasir.

## Silme Yerine Arsivleme Yaklasimi

Kalite kayitlari genellikle tamamen silinmemelidir. Bir NCR kapatilmis, gecersiz kalmis veya aktif takipten cikmis olsa bile izlenebilir kalmalidir.

Arsivleme yaklasimi, kaydi sistemden kaldirmadan daha pasif bir durumda tutmaya yardim eder.

## Varsayilan Deger Neden False?

Yeni olusturulan bir NCR kaydi normalde aktif kayit olarak kabul edilir.

Bu nedenle `is_archived` varsayilan degeri `False` secildi. Kaydin arsivli olmasi istenirse acikca `is_archived=True` verilmelidir.

## Neden Repository Archive/Restore Eklenmedi?

Bu adim sadece modelin arsiv durumunu tasiyabilmesini saglar.

Repository icinde arsivleme, arsivden cikarma veya arsivli kayit filtreleme davranislari daha genis is kurallari gerektirir. Bu nedenle bu adimda repository davranisi eklenmedi.

## Santiye Pratiginde Anlami

Santiye kalite kayitlari denetim, geri izleme ve sorumluluk takibi icin saklanir.

Bir NCR kaydi artik aktif olarak takip edilmese bile tamamen silinmemeli; arsivlenmis olarak izlenebilir kalmalidir. Bu, kalite arsivinin guvenilirligini korur.

## Testte Ne Kontrol Edildi?

Mevcut `NonconformityRecord` testinde `is_archived` alaninin varsayilan olarak `False` geldigi dogrulandi.

Ayrica kaydin `is_archived=True` degeriyle olusturulabildigini dogrulayan kucuk bir test eklendi.

## Kapsam Disi Birakilanlar

- Repository archive/restore davranisi
- JSON
- SQLite
- API
- GUI
- CLI
- Dashboard
- Dosya islemi
- Silme
- Otomatik arsivleme
- Otomatik is akisi

## Kisa Ozet

Adim 052 ile `NonconformityRecord` modeli arsiv durumunu tasiyabilecek hale geldi.

Bu adim, ileride silme yerine arsivleme veya pasiflestirme davranislari icin sade bir model temeli hazirlar.
