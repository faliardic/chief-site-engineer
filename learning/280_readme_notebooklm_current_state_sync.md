# Issue #280 Öğrenim Notu — İki Dönemli Deterministik Podcast Kaynağı

## Ne yaptık?

Projenin eski podcast geçmişi “Adım” numarasıyla, yeni geliştirme günlüğü ise
GitHub Issue numarasıyla ilerliyor. Bu iki kimliği aynı kesintisiz sayı dizisi
gibi yorumlamak sahte tamamlanmış işler üretirdi. Generatorü iki açık range
türüyle çalışacak şekilde düzenledik:

```text
035_adim_221_225_notebooklm_podcast_notu.md
036_issue_227_277_notebooklm_podcast_notu.md
```

`adim`, legacy ve kesintisiz canonical geçmişi; `issue`, yalnız gerçek
CHANGELOG Issue bölümlerini ifade eder.

## Gerçek kod akışı

Dosya adı regex'i range türünü yakalar:

```python
NOTE_PATTERN = re.compile(
    r"^(?P<podcast>\d{3})_(?P<range_kind>adim|issue)_"
    r"(?P<start>\d{3})_(?P<end>\d{3})_notebooklm_podcast_notu\.md$"
)
```

En yeni not seçilirken podcast numarası global unique kalır. Yani Podcast 036
için hem `adim` hem `issue` dosyası varsa generator fail-closed durur.

Legacy adımlar mevcut strict sözleşmeyi korur:

```python
if note.number >= 35 and note.range_kind == "adim":
    _validate_strict_prior_step_summaries(note)
```

Issue aralığı ise gerçek CHANGELOG başlıklarından gelir:

```python
summaries = collect_issue_summaries(repo_root, 227, 277)
```

Fonksiyon #228 gibi eksik bir numarayı hata veya sentetik iş yapmaz. Yalnız
`## Issue #NNN - ...` başlığı bulunan bölümleri toplar, Issue numarasına göre
sıralar ve duplicate canonical bölüm görürse reddeder.

## Çalışma akışı

```text
Podcast dosyalarını tara
→ en yüksek global podcast numarasını seç
→ range türü ve strict bölümleri doğrula
→ legacy Adım 001–225 özetlerini topla
→ issue range ise gerçek CHANGELOG Issue bölümlerini topla
→ küçük project_state safe point'ini doğrula
→ rolling Markdown + sort edilmiş JSON manifest üret
→ ikinci çalıştırmada byte eşitliğini doğrula
```

Generator ağ kullanmaz. NotebookLM API'sine bağlanmaz, credential istemez,
browser açmaz ve Audio Overview üretmez. Ürettiği iki dosya repository içinde
aynı girdiden aynı byte'ları verir.

## Testlerin amacı

Focused testler şu riskleri kapatır:

- legacy `adim` dosyaları hâlâ seçilip doğrulanabiliyor;
- `adim` → `issue` geçişinde en yeni podcast doğru seçiliyor;
- aynı podcast numarası iki range türünde kullanılamıyor;
- Issue numarası boşlukları kabul ediliyor ve uydurulmuyor;
- manifest range türü, safe point ve summary sayılarını doğru taşıyor;
- iki generator çalıştırması byte-for-byte aynı;
- ağ ve output dışı filesystem side effect oluşmuyor;
- Türkçe UTF-8 metin korunuyor;
- tracked Podcast 034 hash'i ve Podcast 035 prior-step yapısı değişmiyor.

Full Python suite, generator değişikliğinin repository'nin diğer Python
sözleşmelerini bozmadığını kontrol eder. Mobil production yolu değişmediği için
Flutter/build/device testi bu Issue'nun riskine ek kanıt sağlamaz.

## Teknik karar

Canonical state 85 KB'lık tarihsel çalışma günlüğü olmamalıdır. State küçük,
insan-okunabilir ve makine tarafından doğrulanabilir olmalıdır:

- son merged safe point;
- legacy son adım;
- duraklatılmış aktif iş;
- blocked Draft PR;
- mobil schema/backup/timezone;
- olgunluk sınırı.

Tarihsel ayrıntı CHANGELOG, Issue ve result belgelerinde kalır. Böylece README
ve NotebookLM generatorü “hangi gerçek şimdi üstündür?” sorusuna tek ve küçük
bir state üzerinden cevap verir.

## Şunu şöyle yaptık ki...

Issue aralığını kesintisiz liste yapmak yerine CHANGELOG başlıklarını seçtik ki
GitHub'da hiç açılmamış ya da bu ürün dilimine ait olmayan numaralar tamamlanmış
iş gibi görünmesin.

Legacy strict validator'ı kaldırmadık; yalnız `issue` range'inde
uygulamadık ki Podcast 001–035'in geriye dönük kalite sözleşmesi korunurken yeni
döneme 226 adet sahte “önceki Issue” zorunluluğu eklenmesin.

State'te Issue #279 ile PR #259'u safe point'ten ayrı tuttuk ki birleşmemiş branch
ve altyapı çalışmaları README/podcast anlatısında uygulanmış mobil davranışa
dönüşmesin.

Tablet PASS'i doğru dar Issue kanıtı olarak yazdık, telefon promotion veya
production readiness iddiasına çevirmedik ki cihaz kabulünün kapsamı büyümesin.
