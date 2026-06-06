# Adim 033 - NonconformityRecord Model Degerlendirme Raporu

## Amac

Bu adimin amaci, mevcut `NonconformityRecord` modelinin Adim 021-032 arasinda kurulan uygunsuzluk adayi ve kesin uygunsuzluk donusum zincirinden sonra yeterli olup olmadigini degerlendirmektir.

Bu adimda model degisikligi yapilmadi. Yeni model eklenmedi. Bu rapor, ileride gerekirse `NonconformityRecord` icin bilincli bir revizyon adimi hazirlamak icin olusturuldu.

## Incelenen Kaynaklar

- `app/models.py` icindeki mevcut `NonconformityRecord` modeli.
- `tests/test_models.py` icindeki `test_nonconformity_record_holds_values_and_defaults` testi.
- `docs/project_decisions.md` icindeki Adim 007 uygunsuzluk kayitlari karari.
- Adim 032'de eklenen `NonconformityCandidateConversionRecord` modeli.

## Mevcut NonconformityRecord Alanlari

Mevcut model su alanlari icerir:

- `nonconformity_id`
- `project_id`
- `date`
- `title`
- `description`
- `location`
- `category`
- `severity`
- `responsible_party`
- `corrective_action`
- `due_date`
- `closed_date`
- `related_inspection_request_id`
- `related_pour_id`
- `notes`
- `status`

Mevcut test, zorunlu alanlarin degerlerini ve opsiyonel alanlarin `None` varsayilanlarini dogrular. Ayrica `severity == "medium"` ve `status == "open"` varsayilanlari test edilir.

## Ozellikle Kontrol Edilen Alanlar

| Alan | Mevcut Modelde Var mi? | Degerlendirme |
| --- | --- | --- |
| `source_candidate_id` | Hayir | Aday kayittan kesin uygunsuzluga gecis dogrudan bu modelde tutulmuyor. Adim 032'de bu baglanti `NonconformityCandidateConversionRecord` ile temsil edildi. |
| `severity` | Evet | Mevcut modelde varsayilan degeri `medium`. |
| `responsible_party` | Evet | Mevcut modelde opsiyonel alan olarak var. |
| `final_status` | Hayir | Mevcut model `status` alanini kullaniyor. Kapanis/sonuc tarafinda `final_status`, Adim 030 `NonconformityCandidateClosureRecord` icinde var. |
| `nonconformity_type` | Hayir | Mevcut modelde bunun en yakin karsiligi `category` alanidir. |
| `location` | Evet | Mevcut modelde opsiyonel alan olarak var. |
| `description` | Evet | Mevcut modelde zorunlu alan olarak var. |
| `detected_by` | Hayir | Mevcut modelde tespit eden kisi alani yok. |
| `detection_date` | Hayir | Mevcut modelde `date` alani var; ancak bu alanin tespit tarihi mi, kayit tarihi mi oldugu ayrismiyor. |
| `status` | Evet | Mevcut modelde varsayilan degeri `open`. |

## Adim 032 Donusum Modeliyle Iliski

Adim 032'de eklenen `NonconformityCandidateConversionRecord`, aday kaydin mevcut kesin uygunsuzluk kaydina hangi karar ve gerekceyle baglandigini temsil eder.

Bu nedenle `source_candidate_id` alaninin dogrudan `NonconformityRecord` icine eklenmesi simdilik zorunlu degildir. Adaydan NCR'a gecis su modelle temsil edilebilir:

- `candidate_id`: Aday kaydin kodu.
- `nonconformity_id`: Mevcut kesin uygunsuzluk kaydinin kodu.
- `conversion_decision`: Donusum karari.
- `conversion_reason`: Donusum gerekcesi.
- `converted_by`: Donusumu yapan kisi.
- `conversion_date`: Donusum tarihi.
- `source_closure_id`: Donusum kararinin kaynaklandigi kapanis kaydi.

Bu yapi, aday kayit ile kesin uygunsuzluk kaydini birbirine karistirmadan baglar.

## Bugunku Ihtiyaclara Gore Eksik Olabilecek Alanlar

Mevcut `NonconformityRecord`, Adim 007 icin yeterli bir baslangic modelidir. Ancak Adim 021-032 arasinda olusan aday sureci dikkate alindiginda su alanlar ileride revizyon adayi olabilir:

- `source_candidate_id`: Dogrudan aday kayit referansi istenirse.
- `nonconformity_type`: `category` alanindan daha net bir uygunsuzluk turu ayrimi gerekirse.
- `detected_by`: Kesin uygunsuzlugu kimin tespit ettigi ayrica tutulacaksa.
- `detection_date`: Tespit tarihi ile kayit tarihi ayrilacaksa.
- `final_status`: Kapanis sonrasi nihai durum `status` alanindan ayri tutulacaksa.
- `converted_from_candidate`: Aday kaynakli olup olmadigini boolean olarak gostermek istenirse.
- `conversion_record_id`: Adim 032 donusum kaydina ters referans istenirse.

## Degerlendirme Karari

Bu adimda `NonconformityRecord` degistirilmedi.

Gerekce:

- Model zaten Adim 007'de temel kesin uygunsuzluk kaydi olarak eklenmistir.
- Adim 032, aday kayit ile kesin uygunsuzluk kaydi arasindaki donusumu ayri modelle temsil etmektedir.
- Model revizyonu yapmadan once mevcut alanlar, eksik alanlar ve aday sureciyle iliski netlestirilmelidir.

Sonuc olarak, `NonconformityRecord` bugun icin temel kesin uygunsuzluk kaydi olarak korunabilir. Ancak ileride Adim 021-032 zinciriyle daha dogrudan entegre edilmek istenirse kontrollu bir revizyon adimi planlanmalidir.

## Bu Adimda Ozellikle Eklenmeyenler

Bu adimda `app/models.py` icinde model degisikligi yapilmadi.

Bu adimda yeni model eklenmedi.

Bu adimda test modeli eklenmedi.

Bu adimda veritabani sorgusu eklenmedi.

Bu adimda API eklenmedi.

Bu adimda GUI eklenmedi.

Bu adimda JSON kayit sistemi eklenmedi.

Bu adimda otomatik NCR olusturma eklenmedi.

Bu adimda duzeltici faaliyet sistemi eklenmedi.

Bu adim sadece mevcut `NonconformityRecord` modeli icin degerlendirme ve revizyon karar hazirligidir.
