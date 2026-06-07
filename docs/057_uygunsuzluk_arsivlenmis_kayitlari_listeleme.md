# Adim 057 - Uygunsuzluk Arsivlenmis Kayitlari Listeleme

## Amac

Bu adimda `NonconformityRepository` icindeki arsivlenmis NCR kayitlarini listeleyen `list_archived()` davranisi netlestirildi ve ek testlerle guvence altina alindi.

Davranis:

```text
list_archived()
```

## Onemli Not

`list_archived()` metodu onceki adimlarda repository icine eklenmisti. Bu adimda ayni metot tekrar eklenmedi.

Adim 057, bu davranisin bos repository, aktif-only repository, aktif + arsiv karisik repository ve restore sonrasi durumlarda beklenen sonucu verdigini netlestirir.

## Davranis Kurallari

- Sadece `is_archived == True` olan NCR kayitlarini dondurur.
- Aktif kayitlari dondurmez.
- Kayit yoksa bos liste dondurur.
- Arsivlenmis kayit yoksa bos liste dondurur.
- Kayitlari silmez.
- `status` alanini degistirmez.
- Otomatik history veya workflow olusturmaz.

## Restore Sonrasi Beklenti

Bir kayit `restore(nonconformity_id)` ile tekrar aktif hale getirilirse `is_archived` alani `False` olur.

Bu durumda kayit artik `list_archived()` sonucunda yer almamalidir.

## Kapsam Disi Birakilanlar

Bu adimda su mekanizmalar eklenmedi:

- JSON
- SQLite
- API
- GUI
- CLI
- Buyuk refactor
- Kayit silme
- Otomatik history
- Otomatik workflow
- Otomatik status degisimi

Bu adim sadece mevcut bellek ici repository davranisini test ve dokumantasyonla netlestirir.
