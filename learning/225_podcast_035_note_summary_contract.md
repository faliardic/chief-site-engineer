# Adim 225 - Podcast 035 Note Summary Contract

## Amac

Step 224'te rolling NotebookLM source icine cumulative step summaries eklemistik. Fakat kullanici yeni podcast note'unun da kendi basina historical context tasimasini istedi.

Step 225 bu nedenle iki is yapar:

1. Podcast 035'i Steps 221-225 icin self-contained note olarak olusturur.
2. Podcast 035 ve sonraki strict notes icin previous-summary section contract'ini executable Python validation ile zorunlu kilar.

Ana karar:

```text
Rolling source cumulative summaries var
VE
latest podcast note kendi prior summaries'ini tasir
```

Bu iki katman birbirinin yerine gecmez.

## Yeni teknik terimler

### Markdown section boundary

`Markdown section boundary`, bir heading'in bittigi yer ile ayni veya daha yuksek seviyedeki sonraki heading'in basladigi yer arasindaki metin siniridir.

Bu adimda aranan section:

```markdown
## 6. Önceki Adımların Ayrı Ayrı Özeti
...
## 7. Birikimli Ürün ve Teknik Durum
```

Validator yalniz bu iki level-2 heading arasindaki `### Adım NNN` basliklarini kabul eder.

### Expected heading range

`Expected heading range`, note'un baslangic adimina gore zorunlu olan prior step numaralari dizisidir.

Podcast 035 icin:

```python
note.step_start == 221
expected_steps = list(range(1, note.step_start))
```

Sonuc:

```text
001, 002, 003, ..., 218, 219, 220
```

### Heading multiplicity

`Heading multiplicity`, ayni step heading'inin kac defa gorundugudur.

Contract her expected heading icin sunu ister:

```text
count == 1
```

`count == 0` missing, `count > 1` duplicate hatasidir.

### Out-of-section heading

`Out-of-section heading`, aranan numarayi tasidigi halde required Markdown section'in disinda kalan heading'dir.

Ornek:

```markdown
## 4. Güncel Adımların Ayrıntılı Anlatımı
### Adım 001 — Yanlis yerde

## 6. Önceki Adımların Ayrı Ayrı Özeti
Adım 001 burada yok.
```

Bu durumda Adim 001 contract'i karsilamaz.

### Self-contained note

`Self-contained note`, baska bir historical note'u veya rolling summary dosyasini okumadan kendi kapsamini ve gerekli prior context'i tasiyan nottur.

Podcast 035:

- Steps 221-225 current-range anlatimini;
- Steps 001-220 ayri historical summaries'ini;
- safe point ve test kanitini;
- deferred scope'u;
- closing engineering question/answer'i

kendi dosyasinda tasir.

## Generator degisikligi

### Section heading pattern

Gercek kod:

```python
SECTION_HEADING_PATTERN = re.compile(
    r"^##(?!#)[ \t]+(?P<title>[^\r\n]+)[ \t]*$",
    re.MULTILINE,
)
```

Satir satir:

1. `^` her satirin basini ifade eder.
2. `##` yalniz level-2 Markdown heading arar.
3. `(?!#)` ucuncu `#` karakterinin gelmesini engeller; yani `###` eslesmez.
4. `[ \t]+` heading isaretinden sonra bosluk veya tab bekler.
5. `(?P<title>...)` heading metnini isimli grup olarak yakalar.
6. `[^\r\n]+` heading'in tek satirda kalmasini saglar.
7. `re.MULTILINE`, `^` ve `$` isaretlerinin her satir icin calismasini saglar.

Neden level-2 siniri kullandik?

Mandatory 12 bolumun her biri `##` heading'dir. Historical step summaries ise section icinde `###` heading'dir. Bu hiyerarsi section body'yi guvenli ayirmamiza izin verir.

### Prior-step heading pattern

Gercek kod:

```python
PRIOR_STEP_HEADING_PATTERN = re.compile(
    r"^###[ \t]+Ad[ıi]m[ \t]+(?P<step>\d{3})(?!\d)"
    r"[ \t]+(?:—|-)[ \t]+[^\r\n]+$",
    re.IGNORECASE | re.MULTILINE,
)
```

Bu pattern su iki bicimi kabul eder:

```markdown
### Adım 001 — Kisa baslik
### Adim 001 - Kisa baslik
```

Uc haneli step number isimli `step` grubuna alinir.

`(?!\d)` dorduncu bir rakamin gelmesini engeller. Boylece `0010` yanlislikla `001` gibi okunmaz.

### Section body bulma helper'i

Gercek kod:

```python
def _find_section_body(text: str, normalized_title: str) -> str:
    headings = list(SECTION_HEADING_PATTERN.finditer(text))
    matching_indexes = [
        index
        for index, heading in enumerate(headings)
        if normalized_title in _normalized_heading(heading.group("title"))
    ]
```

Akis:

1. Note icindeki tum level-2 headings bulunur.
2. Her heading title normalize edilir.
3. Aranan semantic title'i tasiyan heading index'i secilir.
4. Hic eslesme yoksa missing section error verilir.
5. Birden cok eslesme varsa duplicate section error verilir.

Section siniri:

```python
index = matching_indexes[0]
start = headings[index].end()
end = headings[index + 1].start() if index + 1 < len(headings) else len(text)
return text[start:end]
```

- `start`, required heading satirinin bittigi noktadir.
- `end`, sonraki level-2 heading'in basladigi noktadir.
- Slice yalniz required section body'yi dondurur.

Bu tasarim sayesinde section 4 icindeki `### Adım 001` heading'i section 6 icin sayilmaz.

### Expected range hesaplama

Gercek kod:

```python
expected_steps = list(range(1, note.step_start))
expected_set = set(expected_steps)
expected_occurrences = [
    step
    for step in section_steps
    if step in expected_set
]
```

Neden `note.step_end` degil `note.step_start` kullandik?

Previous summaries, current podcast range'den onceki adimlari tasir. Podcast 035 range'i `221-225` oldugu icin prior range `001-220` olur.

Current Steps 221-225 section 6 icinde zorunlu degildir. Bunlar section 4'te ayrintili current-range content olarak anlatilir.

### Duplicate detection ve Counter

Gercek kod:

```python
counts = Counter(expected_occurrences)

duplicates = [
    step
    for step in expected_steps
    if counts[step] > 1
]
```

`Counter`, degerlerin kac defa gorundugunu sayan Python collection sinifidir.

Ornek:

```python
Counter([1, 2, 2, 3])
```

Sonuc mantigi:

```text
1 -> 1 kez
2 -> 2 kez
3 -> 1 kez
```

Bu durumda Adim 002 duplicate error verir.

### Missing detection

Gercek kod:

```python
missing = [
    step
    for step in expected_steps
    if counts[step] == 0
]
```

Expected list `1, 2, 3` ama note `1, 3` tasiyorsa:

```text
Podcast 035 is missing prior-step headings: Adım 002
```

Validator eksik content uydurmaz veya rolling source'tan sessizce tamamlamaz.

### Ascending order validation

Gercek kod:

```python
if expected_occurrences != expected_steps:
    raise PodcastSourceError(
        f"Podcast {note.number:03d} prior-step headings "
        "are out of ascending order"
    )
```

`[1, 3, 2]` tum required headings'i tasir, fakat canonical order'i bozmustur. Liste karsilastirmasi bunu dogrudan yakalar.

### Legacy compatibility

Gercek entegrasyon:

```python
if note.number >= 35:
    _validate_strict_prior_step_summaries(note)
```

Podcast 034 ve onceki notes yalniz legacy required section validation'dan gecer. Yeni prior-step heading contract'i historical files'a geriye donuk uygulanmaz.

Bu, eski note'lari mutate etmeden yeni kalite kuralini ileriye dogru zorunlu kilar.

## Podcast 035 nasil olusturuldu?

Podcast 035 current range'i elle factual olarak yazildi:

```text
Step 221 -> Podcast 034 documentation/podcast closure
Step 222 -> documentation-only convenience lookup boundary
Step 223 -> production helper implementation + tests
Step 224 -> rolling source generator/protocol/tests
Step 225 -> Podcast 035 + strict note contract/tests/state
```

Steps 001-220 summaries ise mevcut canonical helper ile uretildi:

```python
summaries = collect_step_summaries(repo_root, 220)
```

Her summary su formatta note'a eklendi:

```markdown
### Adım 220 — File attachment repository combined related record filter
Tür: uretim kodu ve test. Tamamlanmış adımdır. list_by_related_record(...) exact combined filtresi eklendi.
```

Bu yontem:

- CHANGELOG factual content'ini kullanir;
- ROADMAP/docs title'larini kullanir;
- 220 adimi ascending order tutar;
- invented history yazilmasini onler;
- completed steps'i active work olarak sunmaz.

## Test kodu aciklamasi

### Complete prior headings testi

```python
def test_strict_note_with_complete_prior_step_headings_passes(
    tmp_path: Path,
) -> None:
    note = _strict_note(35, 4, 6, prior_steps=(1, 2, 3))
    root = _write_repo(
        tmp_path,
        notes={"035_adim_004_006_notebooklm_podcast_notu.md": note},
    )
    latest = find_latest_podcast_note(root / "docs/podcast_notes")
    assert latest.step_range == "004-006"
```

Bu fixture'da current range 004-006, prior range 001-003'tur. Uc heading tam ve sirali oldugu icin validation basarili olur.

### Missing testi

```python
note = _strict_note(35, 4, 6, prior_steps=(1, 3))

with pytest.raises(
    PodcastSourceError,
    match="missing prior-step headings: Adım 002",
):
    find_latest_podcast_note(...)
```

Expected Adim 002 yoktur ve error message eksik step'i acikca gosterir.

### Duplicate testi

```python
note = _strict_note(35, 4, 6, prior_steps=(1, 2, 2, 3))
```

`Counter`, Adim 002 count degerini `2` bulur ve duplicate error verir.

### Out-of-order testi

```python
note = _strict_note(35, 4, 6, prior_steps=(1, 3, 2))
```

Headings tamdir ama ascending degildir. Validation liste sirasini reddeder.

### Out-of-section testi

```python
note = _strict_note(
    35,
    4,
    6,
    outside_prior_steps=(1, 2, 3),
)
```

Matching headings section 4 icindedir. Section 6 body bos oldugu icin contract missing error verir.

### Current range required degil testi

```python
note = _strict_note(35, 4, 6, prior_steps=(1, 2, 3))

assert "### Adım 004" not in note
assert "### Adım 005" not in note
assert "### Adım 006" not in note
```

Previous-summary section yalniz prior steps'i tasir.

### Legacy Podcast 034 testi

```python
latest = find_latest_podcast_note(notes_dir)

assert latest.number == 34
assert latest.step_range == "001-003"
```

Legacy fixture prior-step headings tasimadan basarili olur.

### Tracked repository integration testi

```python
note = find_latest_podcast_note(REPO_ROOT / "docs/podcast_notes")
manifest = json.loads(manifest_path.read_text(encoding="utf-8"))

assert note.number == 35
assert note.step_range == "221-225"
assert note.text.rstrip() in rolling_source
assert manifest["previous_step_summary_count"] == 224
```

Bu test yalniz temp fixture'i degil, tracked Podcast 035 ve generated artifacts arasindaki gercek contract'i da dogrular.

### Historical Podcast 034 hash testi

```python
assert hashlib.sha256(podcast_034.read_bytes()).hexdigest().upper() == (
    "AB96737D29F58333FD5FA4AE5687F979D4B8527236F4515FA89CBB8D07DD30C3"
)
```

Bu test Step 225 generator/note calismasinin Podcast 034'u degistirmedigini byte seviyesinde korur.

## Kod calisma akisi

```text
latest podcast filename sec
-> required 12 sections var mi kontrol et
-> Podcast >= 035 mi?
   -> hayir: legacy validation ile devam et
   -> evet: previous-summary level-2 section'i bul
-> section icindeki ### Adım NNN headings'i parse et
-> expected range = 001..step_start-1
-> duplicate var mi?
-> missing var mi?
-> order ascending mi?
-> note valid ise rolling source'u uret
-> manifest latest podcast/range/count alanlarini yaz
```

## Teknik karar tablosu

| Karar | Secilen yaklasim | Neden |
| --- | --- | --- |
| Section bulma | Level-2 Markdown headings | Mandatory 12 bolumun dogal siniri |
| Step heading | Level-3 `### Adım NNN` | Her prior step ayri tanimlanir |
| Expected range | `range(1, note.step_start)` | Current range'den onceki tum steps |
| Duplicate kontrolu | `Counter` | Multiplicity acik ve okunur |
| Missing kontrolu | Expected list + zero count | Eksik step numarasini error'da gosterir |
| Order kontrolu | Liste equality | Ascending contract'i dogrudan test eder |
| Section disi heading | Sayilmaz | Yanlis yerdeki content contract'i karsilamaz |
| Current range | Prior section'da required degil | Current steps section 4'te anlatilir |
| Legacy notes | Podcast <= 034 exempt | Historical file mutation yok |
| Historical content | Canonical summary helper | Invented history yok |

## Sunu soyle yaptik ki...

Sunu soyle yaptik ki, rolling source historical summaries tasisa bile Podcast 035 kendi basina dinlenebilir ve denetlenebilir olsun.

Sunu soyle yaptik ki, `### Adım 001` metni note'un herhangi bir yerinde gorundugunde degil, yalniz dogru previous-summary section'i icinde oldugunda kabul edilsin.

Sunu soyle yaptik ki, 220 basliktan biri eksik, tekrarli veya yanlis siradaysa generator sessizce tahmin etmesin; hangi contract'in bozuldugunu acik error ile gostersin.

Sunu soyle yaptik ki, yeni kalite kuralini Podcast 035'ten ileriye uygulayalim ama Podcast 034 ve eski historical notes byte-for-byte korunsun.

Sunu soyle yaptik ki, Step 225 podcast/protocol/test calismasi ana CSE production behavior gibi anlatilmasin.

## Sonuc

Podcast 035, Steps 221-225 current period anlatimini ve Steps 001-220 icin 220 ayri historical summary'yi kendi dosyasinda tasir.

Rolling source Podcast 035'i full content olarak ekler, Step 224 safe point'e kadar 224 cumulative canonical summary uretir ve manifest bunu count alaninda kaydeder.

Focused generator testleri `24 passed`, full local suite `503 passed` olarak dogrulandi. Bu test basarisi CSE'nin field-ready veya production-ready oldugu anlamina gelmez; strict podcast source contract'inin ve mevcut regression suite'in basarili oldugunu gosterir.
