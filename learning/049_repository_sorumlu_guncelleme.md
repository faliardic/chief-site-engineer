# Adim 049 - Repository Sorumlu Taraf Guncelleme Ogrenim Notu

## Repository Icinde Sorumlu Taraf Guncelleme

Repository icinde bir kaydin sadece durumu degil, sorumlu taraf bilgisi de degisebilir.

Bu adimda `NonconformityRepository` icine `update_responsible_party` metodu eklendi.

## update_responsible_party Ne Ise Yarar?

`update_responsible_party(nonconformity_id, responsible_party)`, verilen NCR kimligine sahip kaydi bulur ve kaydin `responsible_party` alanini yeni degerle gunceller.

Kayit bulunursa guncellenen kayit dondurulur. Kayit bulunamazsa `None` dondurulur.

## Bulunmayan Kayit Icin Neden None?

Repository icinde aranan `nonconformity_id` yoksa guncellenecek kayit da yoktur.

Bu durumda `None` dondurmek, `find_by_id` ve `update_status` davranislariyla tutarlidir. Cagiran kod, "kayit bulunamadi" bilgisini sade sekilde anlayabilir.

## responsible_party Neden str veya None Olabilir?

Bir NCR kaydinin sorumlusu belli ise `responsible_party` alani kisi, ekip, firma veya birim adini temsil eden `str` deger tasir.

Sorumlu henuz belirlenmemisse veya sorumluluk gecici olarak kaldirilmissa bu alan `None` olabilir.

## None Neden unassigned Olarak Yorumlanir?

Ozetlerde `None` degeri dogrudan raporlamak yerine `unassigned` anahtari kullanilir.

Bu, sorumlu tarafi henuz atanmamis kayitlari okunabilir ve sayilabilir hale getirir.

## Neden Otomatik NonconformityAssignmentRecord Olusturulmadi?

Bu adim sadece repository icindeki mevcut kaydin sorumlu taraf alanini gunceller.

Otomatik `NonconformityAssignmentRecord` olusturmak daha genis is kurallari gerektirir: atayan kisi, atama tarihi, sorumluluk kapsami ve hedef tarih gibi bilgiler gerekir. Bu nedenle bu adimda otomatik atama gecmisi uretilmedi.

## Neden JSON veya SQLite Guncellemesi Degil?

Bu adimda JSON, SQLite veya baska bir kalici saklama katmani eklenmedi.

Guncelleme sadece Python nesnesi uzerinde, bellek icinde yapilir.

## Santiye Pratiginde Anlami

Sahada bir NCR kaydinin sorumlusu degisebilir. Ornegin ilk sorumluluk saha ekibindeyken, daha sonra taseron firmaya veya kalite ekibine devredilebilir.

Bu davranis, NCR kaydinin guncel sorumlusunu repository icinde takip etmeye baslar. Ancak resmi atama gecmisi veya onay akisi kurmaz.

## Testte Ne Kontrol Edildi?

Ilk test, mevcut kaydin `responsible_party` alaninin guncellendigini ve yeni degerin filtre/ozet davranislarina yansidigini dogrular.

Ikinci test, olmayan `nonconformity_id` icin `None` dondugunu ve kaydin sorumlu tarafinin `None` yapilabildigini dogrular.

## Kapsam Disi Birakilanlar

- JSON
- SQLite
- API
- GUI
- CLI
- Dashboard
- Dosya islemi
- Otomatik is akisi
- Otomatik assignment history kaydi

## Kisa Ozet

Adim 049 ile `NonconformityRepository` icine bellek ici sorumlu taraf guncelleme davranisi eklendi.

Bu adim, kesin uygunsuzluk kayitlarinin guncel sorumluluk bilgisini takip edebilmek icin kucuk ama gerekli bir temel saglar.
