# Adim 224 - Rolling NotebookLM Podcast Source Protokolu

## Bu adimda ne yaptik?

NotebookLM icin her yeni podcast notunu tek tek kaynak olarak ekleme ve her bolumde ayni talimati yeniden yapistirma ihtiyacini repository tarafinda kaldirdik.

Uc kalici dosya kurduk:

```text
docs/notebooklm/NOTEBOOKLM_INSTRUCTIONS.md
docs/notebooklm/CSE_PODCAST_LATEST_SOURCE.md
docs/notebooklm/CSE_PODCAST_SOURCE_MANIFEST.json
```

Bir de bu dosyalari repository truth'tan yeniden uretebilen Python generator ekledik:

```text
scripts/build_notebooklm_podcast_source.py
```

Bu adim ana CSE urunune yeni saha davranisi eklemez. Database, upload, API, GUI veya NotebookLM otomasyonu yapmaz. Yaptigi is, podcast bilgisinin ayni dosya yolunda guncel ve testli kalmasini saglamaktir.

## Yeni teknik terimler

### Rolling source

`Rolling source`, dosya yolu degismeden icerigi yeni duruma gore yenilenen kaynaktir.

Bu projedeki rolling source:

```text
docs/notebooklm/CSE_PODCAST_LATEST_SOURCE.md
```

Podcast 035 ileride olusturuldugunda NotebookLM'e yeni bir dosya yolu vermek yerine ayni rolling source yeniden uretilir.

### Stable URL

`Stable URL`, icerik degisse bile adresi degismeyen web baglantisidir.

```text
https://raw.githubusercontent.com/faliardic/chief-site-engineer/master/docs/notebooklm/CSE_PODCAST_LATEST_SOURCE.md
```

Bu URL ancak ilgili degisiklik `master` branch'ine merge edildiginde yeni icerigi gosterir. NotebookLM'in kaydedilmis website source'u otomatik yenileyip yenilemedigi repository tarafindan kontrol edilemez.

### Deterministic generator

`Deterministic generator`, ayni girdilerle her calistiginda byte-for-byte ayni ciktiyi ureten programdir.

Bu nedenle generator metadata icine current timestamp yazmaz. Timestamp yazsaydik kaynaklar degismese bile her calismada cikti degisirdi.

### Manifest

`Manifest`, uretilen artifact'in hangi girdiye, araliga ve sayima ait oldugunu makine-okunabilir alanlarla kaydeden kucuk envanter dosyasidir.

Ornek:

```json
{
  "latest_podcast": 34,
  "latest_step_range": "216-220",
  "previous_step_summary_count": 223
}
```

### Side effect

`Side effect`, bir fonksiyonun dondurdugu deger disinda dosya, network, global state veya baska bir sistem uzerinde yaptigi degisikliktir.

Bu generator icin izinli side effect yalniz iki dosyayi yazmaktir:

```text
docs/notebooklm/CSE_PODCAST_LATEST_SOURCE.md
docs/notebooklm/CSE_PODCAST_SOURCE_MANIFEST.json
```

Historical podcast notlari, ZIP, `exports/` veya repository disi dosyalar degistirilmez.

### UTF-8

`UTF-8`, Turkce dahil Unicode karakterleri byte olarak saklayan yaygin text encoding bicimidir.

Kodda acikca sunu kullandik:

```python
path.read_text(encoding="utf-8")
path.write_text(text, encoding="utf-8", newline="\n")
```

Bu sayede `santiye`, `güvenli`, `ölçüm`, `ş` ve `ı` gibi karakterler kaybolmaz.

## Generator kodunun ana parcalari

### 1. Podcast dosya adi sozlesmesi

Gercek kod:

```python
NOTE_PATTERN = re.compile(
    r"^(?P<podcast>\d{3})_adim_(?P<start>\d{3})_(?P<end>\d{3})_"
    r"notebooklm_podcast_notu\.md$"
)
```

Satir satir anlamı:

1. `^` eslesmenin dosya adinin basindan baslamasini ister.
2. `(?P<podcast>\d{3})` uc haneli podcast numarasini isimli grup olarak yakalar.
3. `_adim_` sabit dosya adi parcasidir.
4. `(?P<start>\d{3})` ilk adim numarasini yakalar.
5. `(?P<end>\d{3})` son adim numarasini yakalar.
6. `notebooklm_podcast_notu` dosyanin turunu belirtir.
7. `\.md$` dosya adinin `.md` ile bitmesini zorunlu tutar.

Bu pattern su dosyayi kabul eder:

```text
034_adim_216_220_notebooklm_podcast_notu.md
```

Su dosyayi reddeder:

```text
035_adim_bad_notebooklm_podcast_notu.md
```

### 2. Latest podcast secimi

Gercek kodun ozeti:

```python
notes = []

for path in sorted(notes_dir.glob("*.md")):
    if not path.name.endswith("_notebooklm_podcast_notu.md"):
        continue

    match = NOTE_PATTERN.fullmatch(path.name)
    if match is None:
        raise PodcastSourceError(...)

    notes.append(PodcastNote(...))

latest = max(notes, key=lambda note: note.number)
```

Akis:

1. `glob("*.md")` podcast klasorundeki Markdown dosyalarini bulur.
2. `README.md` gibi podcast notu olmayan dosyalar atlanir.
3. Podcast notuna benzeyen ama sozlesmeye uymayan dosya sessizce atlanmaz; acik hata verir.
4. Her gecerli dosya `PodcastNote` nesnesine donusturulur.
5. `max(..., key=lambda note: note.number)` en yuksek podcast numarasini secer.

Neden dosya tarihini kullanmadik?

Dosya sistemi tarihi kopyalama, checkout veya arsiv acma sirasinda degisebilir. Numarali dosya adi projenin explicit contract'idir.

### 3. Duplicate podcast numarasi kontrolu

Gercek davranis:

```python
if number in numbers:
    raise PodcastSourceError(
        "Duplicate podcast number "
        f"{number:03d}: {numbers[number].name}, {path.name}"
    )
```

Ayni podcast numarasi iki farkli range ile bulunursa hangisinin latest oldugunu tahmin etmiyoruz. Hata verip insani duzeltmeye yonlendiriyoruz.

### 4. Legacy ve yeni note contract ayrimi

Podcast 034, Step 224'ten once olusturuldu. Historical note'u degistirmek yasak oldugu icin iki validation seviyesi kullandik:

```python
required = (
    STRICT_REQUIRED_SECTIONS if note.number >= 35 else LEGACY_REQUIRED_SECTIONS
)
```

- Podcast 001-034: eski not yapisindaki temel semantic bolumler aranir.
- Podcast 035 ve sonrasi: yeni 12 bolumlu contract zorunludur.

Bu karar backward compatibility saglar. Eski kayit korunur, yeni kalite kurali ileriye dogru zorunlu olur.

### 5. Turkce baslik normalizasyonu

Gercek kod:

```python
def _normalized_heading(value: str) -> str:
    turkish_i_normalized = value.casefold().replace("ı", "i")
    decomposed = unicodedata.normalize("NFKD", turkish_i_normalized)
    without_marks = "".join(
        character
        for character in decomposed
        if not unicodedata.combining(character)
    )
    return re.sub(r"[^a-z0-9']+", " ", without_marks).strip()
```

Satir satir:

1. `casefold()` buyuk/kucuk harf karsilastirmasini daha guclu hale getirir.
2. Turkce dotless `ı`, ASCII `i` ile eslestirilir.
3. `NFKD`, aksanli karakterleri harf ve combining mark parcalarina ayirir.
4. Combining mark'lar cikarilir.
5. Noktalama ve fazla bosluklar tek bosluga donusturulur.

Boylece `Kullanım Talimatı` basligi `kullanim talimati` contract'i ile guvenli bicimde karsilastirilir. Original note metni degismez; normalizasyon yalniz validation icindir.

### 6. Canonical step summary toplama

Generator `.cse/state/project_state.json` icindeki current safe point adimini okur:

```python
safe_step = state["current_safe_point"]["step"]
summaries = collect_step_summaries(repo_root, safe_step)
```

Step 224 sirasinda safe point Step 223 oldugu icin su aralik zorunludur:

```text
001, 002, 003, ..., 222, 223
```

Bir adim `CHANGELOG.md` icinde yoksa generator eksik tarihi uydurmaz:

```python
if missing:
    raise PodcastSourceError(
        f"Canonical step summaries are missing: {formatted}"
    )
```

Her ozet su formatta uretilir:

```markdown
### Adım 223 — Field observation attachment convenience lookup
Tür: uretim kodu ve test. Tamamlanmış adımdır. `FileAttachmentRepository.list_for_field_observation(...)` helper'i eklendi.
```

`Tamamlanmış adımdır` ifadesi historical changelog icindeki eski `active work` metinlerinin bugunku durum gibi okunmasini engeller.

### 7. Deterministic manifest yazimi

Gercek kod:

```python
manifest_path.write_text(
    json.dumps(
        manifest,
        ensure_ascii=False,
        indent=2,
        sort_keys=True,
    ) + "\n",
    encoding="utf-8",
    newline="\n",
)
```

- `ensure_ascii=False`: Turkce karakterleri `\uXXXX` kacislarina zorlamaz.
- `indent=2`: JSON'u okunur yapar.
- `sort_keys=True`: key sirasini her calismada ayni tutar.
- Sondaki `\n`: text dosyasini standart newline ile bitirir.
- `newline="\n"`: Windows ortaminda bile deterministic LF uretir.

## Kod calisma akisi

```text
repo root
-> permanent instruction dosyasini oku
-> podcast notlarini tara
-> filename/range/duplicate validation yap
-> en yuksek podcast numarasini sec
-> legacy veya strict section contract'i dogrula
-> project_state safe point'ini oku
-> CHANGELOG icinden 001-safe_step ozetlerini topla
-> ROADMAP/docs ile kisa basliklari zenginlestir
-> rolling Markdown source'u yaz
-> deterministic JSON manifest'i yaz
```

Komut:

```powershell
python scripts/build_notebooklm_podcast_source.py
```

## Test kodu nasil calisiyor?

### Latest note testi

```python
def test_latest_numbered_podcast_note_is_selected(tmp_path: Path) -> None:
    notes = {
        "035_adim_001_002_notebooklm_podcast_notu.md": old_note,
        "036_adim_001_003_notebooklm_podcast_notu.md": new_note,
    }
    root = _write_repo(tmp_path, notes=notes)
    note = find_latest_podcast_note(root / "docs/podcast_notes")
    assert note.number == 36
```

Aciklama:

1. `tmp_path` gercek repodan izole gecici klasor verir.
2. Iki podcast fixture'i yazilir.
3. Secici fonksiyon cagrilir.
4. En yuksek numaranin `36` oldugu dogrulanir.

### Determinism testi

```python
output_path, manifest_path = build_source(root)
first = (output_path.read_bytes(), manifest_path.read_bytes())

build_source(root)

assert (output_path.read_bytes(), manifest_path.read_bytes()) == first
```

Ilk ve ikinci calisma byte seviyesinde karsilastirilir. Yalniz gorunen metnin benzemesi degil, dosyanin tamamen ayni olmasi beklenir.

### Historical note immutability testi

```python
before = note_path.read_bytes()
build_source(root)
assert note_path.read_bytes() == before
```

Bu test generator'un latest note'u okurken onu yeniden yazmadigini kanitlar.

### Network ve filesystem boundary testi

```python
monkeypatch.setattr(socket, "socket", fail_network)
before = sentinel.read_bytes()

build_source(root)

assert sentinel.read_bytes() == before
assert not list(root.glob("*.zip"))
assert not (root / "exports").exists()
```

Network socket acilmaya calisilirsa test hemen hata verir. Sentinel dosyasi, ZIP ve exports kontrolleri authorized outputs disinda side effect olmadigini dogrular.

## Teknik karar tablosu

| Karar | Secilen yaklasim | Neden |
| --- | --- | --- |
| Latest podcast secimi | En yuksek filename podcast numarasi | Dosya tarihinden daha explicit ve deterministic |
| Step history | `CHANGELOG.md` 001-safe_step | Her canonical adimi ayri tasiyor |
| Yeni basliklar | `ROADMAP.md` ve `docs/NNN_*.md` | Daha okunur kisa baslik verir |
| Eski note validation | Legacy semantic sections | Historical note mutation yasagini korur |
| Yeni note validation | 12 required section | Gelecek podcast kalitesini contract'a baglar |
| Encoding | UTF-8 + LF | Turkce ve cross-platform deterministic output |
| Metadata zamani | Timestamp yok | Ayni input ile ayni output |
| NotebookLM entegrasyonu | Stable public URL | API/browser/credential kapsamina girmeden tek kaynak |
| Auto refresh iddiasi | Yapilmadi | Kullanici hesabinda dogrulanmamis davranis |

## Sunu soyle yaptik ki...

Sunu soyle yaptik ki, NotebookLM tarafinda her bolum icin yeni dosya ve yeni talimat eklemek yerine repository tek bir guncel kaynak uretsin.

Sunu soyle yaptik ki, generator eski podcast notlarini degistirmesin; Podcast 034 backward-compatible okunsun ama Podcast 035 ve sonrasi daha guclu bolum sozlesmesine uysun.

Sunu soyle yaptik ki, adim gecmisinde bosluk veya duplicate podcast numarasi varsa sistem tahmin uretmesin; acik ve test edilebilir hata versin.

Sunu soyle yaptik ki, test sayisi urun hazirligi gibi sunulmasin; rolling source field-ready ve production-ready sinirini acikca korusun.

## Sonuc

Adim 224 sonunda CSE, Podcast 034'u latest note olarak tutan, Steps 001-223 icin 223 ayri historical summary ureten, Step 223 safe point ve `479 passed` baseline kanitini tasiyan, UTF-8 ve deterministic rolling NotebookLM source protokolune sahip oldu. Generator focused testleri `15 passed`, tam yerel suite `494 passed` olarak dogrulandi.

Bu sonuc NotebookLM API otomasyonu degildir. Repository stable URL ve current content'i saglar; NotebookLM refresh davranisi kullanici hesabinda ayrica gozlemlenir.
