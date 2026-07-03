# Adim 112 - Audit Event Model Plani

## Audit Event Neden Gerekir?

Audit event, kanit degeri tasiyan olaylarin izini tutmak icin gerekir. Kim, neyi, ne zaman, hangi gerekceyle ve hangi kayit uzerinde yapti sorularina cevap hazirlar.

## Audit Event ile Resmi Kayit Arasindaki Fark Nedir?

Resmi kayit CSE ana veri hafizasindaki asil kayittir. Audit event ise o kayit uzerinde gerceklesen olayin izidir.

Audit event resmi kaydin yerine gecmez; resmi kaydin gecmisini ve kritik islemlerini izlenebilir kilar.

## Audit Event ile JSON Export Arasindaki Fark Nedir?

JSON export bir rapor veya snapshot ciktisidir. Audit event ise bu exportun veya baska bir kritik islemin olustugunu anlatan olay kaydidir.

JSON export dosyasi veri deposu degildir. Audit event de dosyanin kendisi degil, olay izidir.

## Attachment Integrity Raporu Audit Event ile Nasil Iliskilendirilebilir?

Attachment integrity raporu ileride audit event uretebilecek bir kaynak olabilir. Ornegin integrity kontrolu baslatildi, rapor uretildi veya JSON snapshot export edildi gibi olaylar audit event olarak kaydedilebilir.

Bu adimda bu eventler uretilmez; yalnizca iliski planlanir.

## Bu Adimda Neden Kod Yazilmadi?

Adim 112'nin amaci audit event modelinin sinirlarini planlamaktir. `AuditEventRecord`, audit helper, repository, database, otomatik audit yazimi, scanner baglantisi veya JSON persistence bu adimda eklenmedi.
