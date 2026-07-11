# Step 206 Learning - Step 205 Truth, Podcast 031 ve Instruction Authority

## 1. Bu adimda ne yaptik?

Bu adimda urun kodu yazmadik. Bunun yerine proje talimatlari, guncel repo gercegi, podcast notlari ve local calisma protokolu uzerinde temizlik yaptik.

Ana isler:

- `docs/protocols/CSE_PROJECT_INSTRUCTIONS.md` dosyasini tek yetkili proje talimat kaynagi yaptik.
- `CSE_GUNCEL_PROJE_TALIMATLARI.md` dosyasini sadece ignored local mirror olarak tanimladik.
- Step 205 / PR #26 / Issue #25 / merge commit `92a15f2a55e6bfda42d50b8ef7dea651ff496f62` bilgisini guncel guvenli nokta yaptik.
- Step 206'yi aktif documentation/state/protocol isi olarak kaydettik.
- Podcast 031'i yalniz Steps 201-205 icin ekledik.
- Podcast README'sindeki eski Step 022 current-state metnini kaldirdik.
- Official `V:` workspace kontrolunu daha guvenli hale getirdik.

## 2. Neden bunu yaptik?

Uygulama acisindan neden gerekli?

Projede talimatlar iki yerde duruyordu: biri tracked canonical dosya, digeri ignored root dosya. Bu durum "hangi dosya daha yetkili?" sorusunu dogurur. Step 206 bu karisikligi kapatti.

Santiye sefi acisindan neye karsilik geliyor?

Santiyede resmi proje talimati ile sahada dolasan kopya ayni sey degildir. Resmi talimat tek bir yerde durmali, kopyalar sadece okuma kolayligi saglamalidir. Boylece ekip farkli kopyalara bakip farkli kararlar vermez.

## 3. Hangi dosyalara dokunduk?

```text
docs/protocols/CSE_PROJECT_INSTRUCTIONS.md
README.md
.cse/tasks/206_task.md
.cse/results/206_result.md
.cse/state/project_state.json
ROADMAP.md
CHANGELOG.md
docs/project_decisions.md
docs/podcast_notes/031_adim_201_205_notebooklm_podcast_notu.md
docs/podcast_notes/README.md
docs/206_step_205_merged_truth_podcast_031_and_instruction_authority_closure.md
learning/206_step_205_merged_truth_podcast_031_and_instruction_authority_closure.md
```

Yerel-only dosya:

```text
CSE_GUNCEL_PROJE_TALIMATLARI.md
```

Bu dosya commitlenmez. Sadece canonical dosyanin local mirror kopyasi olarak guncellenir.

## 4. Kod / Komut Bloklari Uzerinden Aciklama

### Official workspace kontrolu

Step 206 protokolunde su kontrol zorunlu hale geldi:

```powershell
Set-Location 'V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer'

$expected = (Resolve-Path 'V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer').Path
$actual = (git rev-parse --show-toplevel)

if ((Resolve-Path $actual).Path -ne $expected) {
    throw 'Wrong repository root. Stop without changing anything.'
}
```

Kodun genel amaci:

Codex'in yanlis klasorde Git islemi veya dosya yazimi yapmasini engellemek.

Satir satir aciklama:

- `Set-Location ...`: PowerShell'i resmi proje klasorune goturur.
- `$expected = ...`: Beklenen resmi repo yolunu cozumler.
- `$actual = (git rev-parse --show-toplevel)`: Git'e "bu calisma agacinin en ust klasoru neresi?" diye sorar.
- `if (...)`: Gercek Git root ile beklenen yol ayni mi kontrol eder.
- `throw ...`: Yol farkliysa islemi hata ile durdurur.

Sunu soyle yaptik ki:

Yanlis klasorde branch acma, dosya yazma, commit veya push yapma riski durdurulsun.

Santiye karsiligi:

Yanlis santiyenin dosyasina tutanak yazmamak gibi. Once proje kodu ve klasoru dogrulanir, sonra islem yapilir.

### Machine-readable state ornegi

`.cse/state/project_state.json` icinde guvenli nokta ve aktif is ayri tutulur:

```json
{
  "current_safe_point": {
    "step": 205,
    "pull_request": 26,
    "merge_commit": "92a15f2a55e6bfda42d50b8ef7dea651ff496f62"
  },
  "active_work": {
    "issue": 28,
    "step": 206,
    "branch": "step-206-podcast-031-and-authority-closure"
  }
}
```

Kodun genel amaci:

Son merge edilmis guvenli nokta ile uzerinde calisilan branch'i karistirmamak.

Satir satir aciklama:

- `current_safe_point`: Merge edilmis, test ve review sonrasinda guvenli kabul edilen noktayi tutar.
- `step: 205`: Son guvenli adimin Step 205 oldugunu belirtir.
- `pull_request: 26`: Bu guvenli noktanin PR #26 ile geldigini gosterir.
- `merge_commit`: GitHub squash merge commit kimligini tutar.
- `active_work`: Henuz merge edilmemis mevcut calismayi tutar.
- `issue: 28`: Aktif is GitHub Issue #28'dir.
- `branch`: Yerel/uzak branch adini kaydeder.

Sunu soyle yaptik ki:

Branch uzerindeki aktif calisma, merge edilmis guvenli nokta gibi gosterilmesin.

Santiye karsiligi:

Onaylanmis resmi tutanak ile henuz incelenen taslak tutanagi ayri klasorlerde tutmak gibi.

### Canonical / mirror karari

Talimat yetkisi su sekilde netlestirildi:

```text
Canonical authority:
docs/protocols/CSE_PROJECT_INSTRUCTIONS.md

Optional local mirror:
CSE_GUNCEL_PROJE_TALIMATLARI.md
```

Bu yapida `docs/protocols/CSE_PROJECT_INSTRUCTIONS.md` tek yetkili kaynaktir.

`CSE_GUNCEL_PROJE_TALIMATLARI.md` varsa onun gorevi yalniz local okuma kolayligi saglamaktir. Bu dosya canonical dosyadan farkliysa yetkili olan canonical dosyadir.

Sunu soyle yaptik ki:

Fresh clone, handoff veya yeni Codex calismasi ignored root dosyaya bagimli kalmasin.

## 5. Test / Dogrulama Komutlari Uzerinden Aciklama

Bu adim documentation/state/protocol adimi oldugu halde testler yine kosulur:

```powershell
python -m pytest
git diff --check
git diff -- app/models.py tests/test_models.py .github/workflows/pytest.yml
python -m json.tool .cse/state/project_state.json
```

Bu komutlar neyi dogrular?

- `python -m pytest`: Mevcut Python testlerinin bozulmadigini kontrol eder.
- `git diff --check`: Markdown ve text dosyalarinda whitespace hatasi var mi bakar.
- `git diff -- app/models.py tests/test_models.py .github/workflows/pytest.yml`: Korunan kod/test/workflow dosyalarinda fark olmadigini gosterir.
- `python -m json.tool ...`: JSON dosyasinin gecersiz soz dizimi icermedigini kontrol eder.

Sunu soyle yaptik ki:

Dokumantasyon degisikligi yaparken bile proje sagligi bozulmasin ve machine-readable state gecersiz JSON haline gelmesin.

## 6. Kodun Calisma Akisi

1. Codex resmi `V:` proje yoluna gecer.
2. Git root'un beklenen resmi repo oldugunu dogrular.
3. `master` branch'ini `origin/master` ile fast-forward-only senkronize eder.
4. Step 206 branch'ini olusturur.
5. Yalniz yetkili documentation/state/protocol dosyalarini gunceller.
6. Canonical talimat dosyasini tek authority yapar.
7. Root mirror dosyasini canonical metinle esler, fakat stage/commit etmez.
8. Podcast 031'i ekler.
9. Test, diff, JSON, protected-path, exports, ZIP ve status kontrollerini calistirir.
10. Commit ve ordinary push yaparsa branch divergence `0 0` kanitini Issue #28'e ekler.

## 7. Yeni Ogrenilen Yazilim Kavramlari

```text
Canonical authority:
Bir konuda resmi ve tek yetkili kaynak.

Bu projedeki karsiligi:
docs/protocols/CSE_PROJECT_INSTRUCTIONS.md dosyasi proje talimatlari icin canonical authority oldu.

Santiye benzetmesi:
Onayli proje paftasi gibi. Fotokopiler yardimci olabilir ama resmi karar paftadan verilir.
```

```text
Local mirror:
Yetkili kaynagin yerel okuma kolayligi icin tutulan kopyasi.

Bu projedeki karsiligi:
CSE_GUNCEL_PROJE_TALIMATLARI.md dosyasi ignored local mirror olarak kalir.

Santiye benzetmesi:
Sahada masada duran kopya talimat gibi. Resmi kaynakla ayni olmali, ama resmi kaynak yerine gecmemeli.
```

```text
Text equivalence:
Iki dosyanin metin olarak ayni icerigi tasimasi.

Bu projedeki karsiligi:
Canonical talimat dosyasi ile root mirror dosyasinin birebir ayni metni tasimasi beklenir.

Santiye benzetmesi:
Iki tutanak kopyasinda ayni maddelerin ayni sekilde yazmasi gibi.
```

```text
Divergence:
Yerel branch ile remote branch arasinda ileri/geri commit farki olup olmadigini anlatan Git sonucu.

Bu projedeki karsiligi:
`0 0`, local ve remote branch'in ayni commit'te oldugunu gosterir.

Santiye benzetmesi:
Ofisteki dosya ile sahadaki dosya ayni revizyonda mi diye bakmak gibi.
```

## 8. "Sunu soyle yaptik ki..." Teknik Karar Tablosu

| Sunu yaptik | Boyle yaptik | Cunku | Boylece |
| --- | --- | --- | --- |
| Tek talimat authority belirledik | `docs/protocols/CSE_PROJECT_INSTRUCTIONS.md` dosyasini canonical yaptik | Ignored root dosya fresh clone/handoff icin guvenilir degil | Her ortam ayni tracked talimata bakar |
| Root dosyayi mirror yaptik | `CSE_GUNCEL_PROJE_TALIMATLARI.md` dosyasini ignored local mirror olarak tanimladik | Local okuma kolayligi yararli ama authority karisikligi riskli | Kopya var olabilir ama resmi karar canonical dosyadan gelir |
| Official workspace kontrolunu sertlestirdik | `git rev-parse --show-toplevel` sonucu resmi `V:` yolu ile karsilastirilir | Yanlis klasorde dosya yazmak buyuk risk | Yanlis root'ta islem baslamadan durur |
| Step 205'i safe point yaptik | README/state/roadmap/canonical Section 17 guncellendi | PR #26 merge edildi ve Issue #25 tamamlandi | Dokumantasyon eski Step 204/205 aktif durumunda kalmaz |
| Podcast 031'i ekledik | Steps 201-205 icin tek podcast notu yazdik | Besli podcast cadence bunu gerektirir | Step 201-205 teknik anlatimi arsivlendi |
| Desktop archive riskini sadece kaydettik | Risk docs/state/decision dosyalarinda belirtildi | O repo ayri local archive ve identity kanitlanmadi | Canonical repo temiz kalir, user work mutate edilmez |

## 9. Bu Adimda Bilincli Olarak Ne Yapmadik?

Bu adimda production code yazmadik.

Test dosyasi veya executable fixture eklemedik.

GitHub Actions'i yeniden enable etmedik.

Required status checks acmadik.

API, GUI, CLI, database, persistence, audit, backup/restore veya migration eklemedik.

Hard validation veya generated `blocked` status eklemedik.

ZIP dosyasina dokunmadik.

Desktop archive repository'yi silmedik, tasimadik, uzerine yazmadik veya commit yapmadik.

Step 207 veya field-MVP implementation baslatmadik.

## 10. Mini Sozluk

```text
Canonical:
Bir konuda resmi, esas ve referans kabul edilen kaynak.
```

```text
Mirror:
Esas kaynagin kopyasi. Tek basina yetkili kaynak degildir.
```

```text
SHA-256:
Dosya iceriginden uretilen uzun hash degeri. Icerik degisirse hash de degisir.
```

```text
Fast-forward:
Git'te yerel branch'i remote branch'in daha yeni commit'ine catismasiz ilerletme.
```

```text
Protected path diff:
Bu adimda degismemesi gereken kritik dosyalarda diff olup olmadigini kontrol etme.
```

Bu terimler bu learning dosyasinda aciklandi. Step 206 authorized tracked file listesi `learning/GLOSSARY.md` dosyasini icermedigi icin kalici sozluk dosyasi bu adimda degistirilmedi.

## 11. Sonraki Adima Baglanti

Step 206 tamamlandiktan sonra proje talimat authority'si tek noktada toplanmis, Step 205 safe point'i dokumanlarda final hale gelmis ve Podcast 031 eklenmis olur.

Bundan sonraki adim Step 207 veya ilk field-MVP implementation olacaksa, ayrica acik Issue, branch, task, test ve verification kapsamiyla baslamalidir.
