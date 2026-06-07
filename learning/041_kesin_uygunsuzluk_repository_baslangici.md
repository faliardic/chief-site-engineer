# Adim 041 - NonconformityRepository Baslangici Ogrenim Notu

## Repository Kavrami

Repository, model nesnelerini eklemek, listelemek ve aramak icin kullanilan kayit yonetimi sinifidir.

Bu adimda `NonconformityRecord` kayitlari icin `NonconformityRepository` eklendi.

## Model Ile Repository Arasindaki Fark

Model, tek bir kaydin hangi alanlara sahip oldugunu anlatir.

Repository, birden fazla kaydin nasil tutulacagini ve nasil bulunacagini anlatir.

Ornegin:

- `NonconformityRecord`: Bir NCR kaydinin veri seklidir.
- `NonconformityRepository`: NCR kayitlarini bellek icinde yoneten siniftir.

## Bellek Ici Kayit Yonetimi Nedir?

Bellek ici kayit yonetimi, kayitlarin program calisirken RAM icinde tutulmasidir.

Bu yaklasimda kayitlar dosyaya, JSON'a veya veritabanina yazilmaz. Program kapandiginda bellek icindeki liste de kaybolur.

Bu, ogrenme ve baslangic mimarisi icin guvenli bir ara adimdir.

## Eklenen Davranislar

```python
repository = NonconformityRepository()
repository.add(record)
repository.list_all()
repository.find_by_id("NCR-001")
```

- `add(record)`: Kayit ekler.
- `list_all()`: Tum kayitlari listeler.
- `find_by_id(...)`: Kimlige gore kayit arar.
- Kayit bulunamazsa `None` dondurur.

## Neden JSON, SQLite, API veya GUI Eklenmedi?

Bu adimda amac sadece repository davranisini baslatmaktir.

JSON veya SQLite kalici saklama kararlari gerektirir. API ve GUI ise kullanici veya dis sistem etkilesimi ekler. Bu kararlar daha genis kapsamli oldugu icin bu adimda bilincli olarak disarida birakildi.

## Santiye Pratiginde Anlami

Bir kayit modelini tanimlamak, o kaydin nasil saklanip bulunacagini cozmez.

Sahada NCR formunu tasarlamak bir seydir; acilan NCR formlarini duzenli bir klasorde tutmak, aramak ve listelemek baska bir seydir.

`NonconformityRepository`, bu ikinci fikrin yazilim tarafindaki baslangicidir.

## Testte Ne Kontrol Edildi?

Ilk test repository'nin kayit ekleyip listeleyebildigini dogrular.

Ikinci test, `find_by_id` metodunun mevcut kaydi buldugunu ve olmayan kimlik icin `None` dondurdugunu dogrular.

## Kapsam Disi Birakilanlar

- JSON
- SQLite
- API
- GUI
- CLI
- Dosya islemi
- Otomatik is akisi

## Kisa Ozet

Adim 041 ile kesin uygunsuzluk kayitlari icin bellek ici repository baslangici eklendi.

Bu adim, "NCR kayitlarini sadece tanimlamak degil, bellek icinde eklemek, listelemek ve bulmak" fikrini baslatir.
