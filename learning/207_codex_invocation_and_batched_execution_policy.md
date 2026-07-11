# Step 207 Learning - Unified Source ve Codex Invocation Policy

## 1. Bu adimda ne yaptik?

Bu adimda urun kodu yazmadik. Projenin kaynak, continuation ve Codex calistirma disiplinini netlestirdik.

Yaptigimiz ana isler:

- Approved unified project source'u tracked repo kaynagina ekledik.
- Source register olusturduk.
- Yeni chat'in GitHub'dan devam etmesini anlatan bootstrap dokumani ekledik.
- ChatGPT'nin Codex gerekip gerekmedigine karar vermesini kalici policy yaptik.
- Gerekirse kullaniciya `Codex çalışmalı` denmesini kural haline getirdik.
- Codex-required ve Codex-not-required isleri ayirdik.
- Batched execution ve metadata churn avoidance kurallarini ekledik.
- Step 206'yi latest safe point, Step 207'yi active unmerged work olarak kaydettik.

## 2. Neden bunu yaptik?

Uygulama acisindan:

Proje artik sadece kod dosyalarindan olusmuyor. Urun amaci, veri ilkeleri, operasyon talimatlari, GitHub Issue'lari, task/result dosyalari ve local execution kanitlari birlikte calisiyor. Bunlarin hangisinin hangi konuda yetkili oldugu acik olmazsa her yeni chat veya her yeni Codex calismasi ayni bilgiyi yeniden kurmaya calisir.

Santiye sefi acisindan:

Bu, santiyede hangi paftanin resmi proje, hangi dokumanin saha talimati, hangi notun gunluk is emri oldugunu ayirmaya benzer. Her sey ayni klasorde dursa bile yetki alanlari farklidir.

## 3. Hangi dosyalara dokunduk?

```text
docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md
docs/protocols/CSE_PROJECT_SOURCE_REGISTER.md
docs/protocols/CSE_NEW_CHAT_GITHUB_BOOTSTRAP.md
docs/protocols/CSE_PROJECT_INSTRUCTIONS.md
docs/reference_sources/
.cse/README.md
.cse/templates/task_template.md
.cse/templates/result_template.md
.cse/tasks/207_task.md
.cse/results/207_result.md
.cse/state/project_state.json
README.md
ROADMAP.md
CHANGELOG.md
docs/project_decisions.md
docs/207_codex_invocation_and_batched_execution_policy.md
learning/207_codex_invocation_and_batched_execution_policy.md
```

Yerel-only mirror:

```text
CSE_GUNCEL_PROJE_TALIMATLARI.md
```

Bu dosya ignored kalir ve commitlenmez.

## 4. Komut ve Policy Bloklari Uzerinden Aciklama

### Fresh-chat read order

```text
1. docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md
2. docs/protocols/CSE_PROJECT_INSTRUCTIONS.md
3. .cse/state/project_state.json
4. latest open GitHub Issue and relevant recent PR/merge state
5. active .cse/tasks/<step>_task.md and relevant .cse/results/<step>_result.md
```

Bu listenin amaci:

Yeni bir chat'in eski ZIP veya hafizaya dayanmak yerine GitHub'daki guncel repo gerceginden baslamasini saglamak.

Satir satir aciklama:

- `CSE_UNIFIED_PROJECT_SOURCE.md`: Urun ne, neden var, hangi ilkelere bagli?
- `CSE_PROJECT_INSTRUCTIONS.md`: Nasil calisiyoruz, Git/Codex safety kurallari ne?
- `.cse/state/project_state.json`: Makine-okunur guncel durum nedir?
- GitHub Issue/PR state: Hangi is aktif, ne merge edildi?
- Task/result: Aktif local execution kapsami ve kaniti nedir?

Sunu soyle yaptik ki:

Yeni chat, "bana ZIP yukle" veya "onceki promptu kopyala" beklemeden GitHub'dan devam edebilsin.

### Codex invocation rule

```text
ChatGPT decides whether Codex is required.
When local execution is needed, ChatGPT says: Codex çalışmalı.
```

Bu policy'nin amaci:

Kullanici, Codex calismasi gerekip gerekmedigini tahmin etmek zorunda kalmasin.

Sunu soyle yaptik ki:

GitHub-native isler ChatGPT tarafinda kalsin, local dosya/test/commit/push gereken islerde Codex devreye girsin.

### Batched execution model

```text
1 technical step = 1 primary Codex run
blocking correction = at most 1 correction run
post-merge sync = batch into the next Codex-required run when safe
```

Bu modelin amaci:

Her kucuk yorum, wording veya non-blocking metadata notu icin yeni Codex calistirmamak.

Sunu soyle yaptik ki:

Proje daha az parcalansin, commit gecmisi daha temiz kalsin ve local execution yalniz gercek ihtiyac oldugunda yapilsin.

## 5. JSON State Ornegi

`.cse/state/project_state.json` icinde Step 207 active work ve Step 206 safe point ayrildi:

```json
{
  "current_safe_point": {
    "step": 206,
    "pull_request": 29,
    "merge_commit": "3b05fae76766cedc8840eea6c0fc2f51440354e4"
  },
  "active_work": {
    "issue": 30,
    "step": 207,
    "branch": "step-207-codex-invocation-policy"
  }
}
```

Bu kodun genel amaci:

Merge edilmis guvenli nokta ile uzerinde calisilan aktif branch'i karistirmamak.

Sunu soyle yaptik ki:

Step 207 henuz merge edilmeden "safe point" gibi gosterilmesin.

## 6. Test / Dogrulama Komutlari

Bu adim documentation/state/protocol adimi olsa bile yerel testler kosulur:

```powershell
python -m pytest
git diff --check
python -m json.tool .cse/state/project_state.json
git diff -- app/models.py tests/test_models.py .github/workflows/pytest.yml
```

Bu komutlar neyi dogrular?

- `python -m pytest`: Uygulama davranisi bozulmadi mi?
- `git diff --check`: Whitespace hatasi var mi?
- `python -m json.tool`: State JSON gecersiz hale gelmis mi?
- Protected path diff: Uygulama modeli, ana test dosyasi veya workflow yetkisiz degismis mi?

## 7. Kodun Calisma Akisi

1. Local `master`, `origin/master` ile `3b05fae...` commit'ine fast-forward edilir.
2. Var olan `step-207-codex-invocation-policy` branch'i checkout edilir.
3. Unified source approved source dosyasindan kopyalanir.
4. Source register ve bootstrap dokumani eklenir.
5. Instructions, `.cse` README ve templates yeni policy ile guncellenir.
6. README, roadmap, changelog, decisions ve state Step 206/207 gercegine eslenir.
7. Root mirror canonical instructions ile eslenir ama commitlenmez.
8. Verification kosulur.
9. Commit ve ordinary push yapilir.
10. Issue #30'a factual completion evidence eklenir.

## 8. Yeni Ogrenilen Kavramlar

```text
Unified project source:
Urun amaci, strateji, veri ilkeleri ve uzun vadeli mimari icin tek ust kaynak.
```

```text
Operational instructions:
Git, GitHub, Codex, safety ve verification gibi calisma kurallarini anlatan kaynak.
```

```text
Bootstrap:
Yeni bir chat'in projeyi nereden ve hangi sirayla okuyarak baslatacagini anlatan baslangic protokolu.
```

```text
Batched execution:
Kucuk local isleri parcalamak yerine uygun oldugunda tek toplu Codex calismasinda yapmak.
```

```text
Metadata churn:
Sadece kayit dosyasi metadata'sini tekrar tekrar guncellemek icin ekstra commit uretme aliskanligi.
```

## 9. "Sunu soyle yaptik ki..." Teknik Karar Tablosu

| Sunu yaptik | Boyle yaptik | Cunku | Boylece |
| --- | --- | --- | --- |
| Unified source ekledik | Approved source'u `docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md` yoluna kopyaladik | Urun kararlarinin tek ust kaynagi olmali | Yeni chat ve reviewer urun gercegini GitHub'dan okur |
| Source register ekledik | Her kaynagin status'unu tabloyla kaydettik | Her kaynak bu ortamda yoktu | Uydurma veya silent rewrite riski azalir |
| Bootstrap dokumani ekledik | `CSE_NEW_CHAT_GITHUB_BOOTSTRAP.md` yazdik | Yeni chat ZIP'e bagli kalmamali | Kullanici `devam` diyerek GitHub'dan surdurebilir |
| Codex invocation policy ekledik | ChatGPT karar verir ve gerekirse `Codex çalışmalı` der | Kullanici tahmin etmek zorunda kalmamali | Local execution sadece gerektiginde baslar |
| Batched execution ekledik | Non-blocking isler sonraki consolidated run'a birikir | Her yorum icin commit/run uretmek yorucu | Proje gecmisi daha sakin ve izlenebilir kalir |

## 10. Bu Adimda Bilincli Olarak Ne Yapmadik?

Production code degistirmedik.

Executable test veya fixture eklemedik.

Workflow davranisi, Actions enablement veya required checks degistirmedik.

API, GUI, CLI, persistence, audit, backup/restore veya migration eklemedik.

Hard validation veya generated `blocked` status eklemedik.

Raw handoff ZIP commit etmedik.

Replacement handoff ZIP olusturmadik.

Field-MVP implementation veya Step 208 baslatmadik.

## 11. Sonraki Adima Baglanti

Step 207 tamamlandiginda proje yeni chatlerde GitHub'dan kendini toparlayabilecek, Codex calistirma ihtiyaci daha net belirlenecek ve local execution daha az parcalanacak.

Bundan sonraki adim ancak ayri Issue ve acik scope ile baslamalidir.
