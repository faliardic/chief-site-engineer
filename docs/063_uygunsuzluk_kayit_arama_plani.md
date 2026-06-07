# Adım 063 — Uygunsuzluk Kayıt Arama Planı

## Kısa Amaç

NCR kayıtları arttıkça yalnızca tüm kayıt listesine bakmak yeterli olmayacaktır. Şantiye şefi zamanla aktif kayıtları, arşivlenmiş kayıtları, belirli bir konumdaki sorunları, belirli durumdaki uygunsuzlukları veya başlık/açıklama içinde geçen ifadeleri hızlıca aramak isteyecektir.

Bu adım uygulama kodu eklemez. Amaç, sonraki küçük teknik adımlar için uygulanabilir bir arama ve filtreleme planı hazırlamaktır.

Arama davranışları önce bellek içi repository seviyesinde olgunlaştırılacak, daha sonra gerekirse kalıcı kayıt, API veya arayüz katmanlarına taşınacaktır.

## Mevcut Temel

Adım 056-062 sonunda NCR repository tarafında şu temel davranışlar netleşmiştir:

- `list_all()`
- `list_active()`
- `list_archived()`
- `get_archive_summary()`
- `archive(nonconformity_id)`
- `restore(nonconformity_id)`

Bunlara ek olarak repository içinde daha önce eklenmiş bazı arama/filtreleme yapıtaşları da vardır:

- `find_by_id(nonconformity_id)`
- `list_by_status(status)`
- `list_by_responsible_party(responsible_party)`

Bu nedenle sonraki adımlarda mevcut davranışlar varsa tekrar yazılmayacak; gerekirse test ve dokümantasyonla netleştirilecektir.

## İleride Ele Alınabilecek Arama / Filtreleme Davranışları

`find_by_id(nonconformity_id)`: Tek bir NCR kaydını kimliğine göre bulmak için kullanılır. Mevcutsa davranışı test ve dokümantasyonla sabitlenebilir.

`filter_by_status(status)` veya mevcut adlandırmayla `list_by_status(status)`: Belirli durumdaki NCR kayıtlarını listelemek için kullanılır.

`filter_by_location(location)`: Belirli bir blok, kat, mahal veya saha konumundaki NCR kayıtlarını ayırmak için planlanabilir.

`search_by_title(query)`: NCR başlığı içinde geçen ifadeye göre basit metin araması yapabilir.

`search_by_description(query)`: NCR açıklaması içinde geçen ifadeye göre basit metin araması yapabilir.

`filter_by_archived(is_archived)`: Aktif/arşiv ayrımını tek parametreli bir filtre olarak ifade edebilir. Ancak mevcut `list_active()` ve `list_archived()` davranışları bu ihtiyacın büyük bölümünü zaten karşılar.

`filter_by_date_range(start_date, end_date)`: Belirli tarih aralığındaki NCR kayıtlarını listelemek için ileride planlanabilir. Bu adımda sadece plan seviyesindedir.

`filter_by_responsible_party(responsible_party)`: Sorumlu kişi, ekip veya firma bazlı kayıtları ayırmak için kullanılabilir. Mevcut alan ve mevcut repository davranışıyla uyumlu ilerlenmelidir.

## Küçük Adımlara Bölme Önerisi

Adım 064: `find_by_id` davranışının mevcut durumunu incele ve gerekiyorsa test/dokümantasyonla netleştir.

Adım 065: `list_by_status` veya `filter_by_status` davranışını mevcut adlandırma ile uyumlu şekilde netleştir.

Adım 066: `filter_by_location(location)` davranışını planla veya uygula; önce `NonconformityRecord` içinde uygun alanın mevcut olup olmadığını kontrol et.

Adım 067: Başlık ve/veya açıklama üzerinde basit metin arama davranışını ele al.

Adım 068: Arama ve listeleme davranışlarının birlikte tutarlı çalıştığını gösteren bütünlük testi hazırla.

Adım 069: NCR arama/filtreleme kullanım özeti hazırla.

Adım 070: Adım 061-070 aralığı için NotebookLM podcast notu hazırlığı veya uygun aralık kapanışı yap.

## Davranış İlkeleri

- Arama davranışları kayıtları değiştirmemeli.
- Filtreleme davranışları kayıt silmemeli.
- Listeleme ve arama metotları read-only kalmalı.
- Arşivlenmiş kayıtlar dışlanacaksa bu method adında veya parametrede açıkça belli olmalı.
- Varsayılan davranışlar izlenebilirliği bozmayacak şekilde tasarlanmalı.
- Büyük query engine, database, API veya GUI eklenmemeli.
- Önce bellek içi repository davranışları olgunlaştırılmalı.
- Mevcut method varsa aynı davranış farklı adla tekrar eklenmemeli.
- Testler küçük, okunabilir ve tek davranışı doğrulayacak şekilde yazılmalı.

## Şantiye Şefi Açısından Anlamı

Bu plan, ileride şu sorulara hızlı cevap verecek altyapının hazırlanmasını hedefler:

- "Bu uygunsuzluk nerede olmuştu?"
- "Açık uygunsuzluklar neler?"
- "Şu bloktaki kalite sorunları neler?"
- "Daha önce bu tip sorun yaşandı mı?"
- "Arşivlenmiş ama tekrar bakmam gereken kayıt var mı?"
- "Belirli bir sorumlu tarafta kaç NCR birikmiş?"

Bu soruların her biri sahada zaman kazandırır. Kayıt arama yeteneği, NCR sistemini sadece arşiv tutan bir yapıdan karar destek aracına doğru taşır.

## Python Öğrenme Açısından Anlamı

Bu plan Python öğrenme açısından şu konuları öne çıkarır:

- Fonksiyon sorumluluğu
- Liste filtreleme
- String arama
- Saf / read-only davranış
- Test odaklı geliştirme
- Küçük adımlarla repository yeteneği büyütme
- Mevcut kodu tekrar yazmadan davranışı netleştirme

Önemli ders şudur: Arama davranışları önce basit ve test edilebilir Python listesi işlemleri olarak kurulabilir. Daha sonra aynı iş kuralları veritabanı, API veya arayüz tarafına taşınabilir.

## Kapsam Dışı

Bu adımda uygulama kodu değiştirilmedi.

Bu adımda test dosyaları değiştirilmedi.

Bu adımda şu mekanizmalar eklenmedi:

- Yeni Python davranışı
- JSON
- SQLite
- API
- GUI
- CLI
- Büyük arama motoru
- Query sistemi
- Otomatik workflow
