# CHIEF SITE ENGINEER

CHIEF SITE ENGINEER, santiye sefi icin kontrol, takip, gunluk kayit, kalite kaydi, uygunsuzluk / NCR izleme, dosya eki metadata, attachment integrity ve dokumantasyon disiplini gelistirmek amaciyla kurulan sade bir Python projesidir.

Proje su anda gercek bir urun uygulamasi degil; domain model, bellek ici repository davranislari, testler, karar dokumantasyonu, learning notlari ve NotebookLM podcast notlari ureten bir cekirdek gelistirme alanidir.

## Guncel Durum

Son guvenli nokta:

```text
Adim 219 - Field Observation attachment linking contract
PR #56 merge commit: 4d006a2f49f10792a74dca068ea415ba37200797
```

Guncel test sonucu:

```text
471 passed
```

Mevcut calisma durumu:

```text
Adim 220 - FileAttachmentRepository combined related-record filter
```

Adim 219, PR #56 ile squash merge edildi ve master uzerindeki guncel guvenli nokta oldu. Adim 220, mevcut `FileAttachmentRecord` metadata nesneleri icin exact combined `related_record_type` + `related_record_id` filtresini ekleyen aktif unmerged isidir.

## Repo Koku

```text
V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer
```

## Mimari Ozet

Proje su ana parcalardan olusur:

- `app/models.py`: Santiye, kalite, uygunsuzluk, NCR, dosya eki ve yardimci domain modelleri.
- `app/records.py`: Bellek ici kayit listeleme, `FileAttachmentRepository`, `FieldObservationRepository` ve `NonconformityRepository` davranislari.
- `app/attachments.py`: Canonical attachment path helper fonksiyonu.
- `app/attachment_integrity.py`: Attachment integrity status sabitleri, result/report modelleri, helper ve serializer fonksiyonlari.
- `app/main.py`: Basit uygulama baslangic mesaji.
- `tests/`: Model, repository, attachment path ve attachment integrity davranislarini dogrulayan pytest testleri.
- `docs/`: Adim bazli karar, kapsam, politika, denetim ve kullanim dokumantasyonu.
- `learning/`: Python ve proje ogrenim notlari.
- `docs/podcast_notes/`: NotebookLM podcast kaynak notlari.
- `docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md`: Urun amaci, strateji, veri ilkeleri, urun katmanlari, roadmap ve uzun vadeli mimari icin birlesik ust kaynak.
- `docs/protocols/CSE_PROJECT_INSTRUCTIONS.md`: Git/GitHub/Codex operasyon, safety, verification ve execution protocol kaynagi.
- `docs/protocols/CSE_NEW_CHAT_GITHUB_BOOTSTRAP.md`: Yeni chat'in GitHub'dan ZIP/handoff yuklemeden nasil devam edecegini anlatan bootstrap kaynagi.

## Mevcut Teknik Kapsam

Adim 205 itibariyla proje su alanlarda ilerlemistir:

- Temel santiye domain modelleri.
- Gunluk saha, beton dokum, yapi denetim, malzeme, toplanti, RFI/submittal ve ilgili kayit modelleri.
- Uygunsuzluk adayi ve kesin uygunsuzluk / NCR surecleri.
- `NonconformityRepository` icin bellek ici ekleme, listeleme, filtreleme, sayma, guncelleme, arsivleme ve restore davranislari.
- `FileAttachmentRecord` ile fotograf, video, PDF, belge, ses ve diger dosya ekleri icin metadata modeli.
- Dosya eki icin `original_file_name`, `uploaded_by`, `uploaded_at`, `notes`, `file_name`, `file_path`, `file_type`, `mime_type`, `file_size`, `related_record_type` ve `related_record_id` karar hatti.
- Dosya eki path standardi: `attachments/{project_id}/{record_type}/{yyyy}/{mm}/{dd}/{record_id}/{safe_file_name}`.
- Canonical attachment path helper fonksiyonu.
- Attachment metadata integrity kurallari.
- Attachment integrity status constants.
- `AttachmentIntegrityResult`.
- Single-record attachment integrity helper.
- `AttachmentIntegrityReportSummary`.
- `AttachmentIntegrityReport`.
- Attachment integrity report serializer fonksiyonlari.
- Attachment integrity JSON string ve JSON file export helper fonksiyonlari.
- Attachment scanner dry-run helper baslangici.
- `AuditEventRecord` modeli, event type validation, target record pair validation ve target record type sozlesmesi.
- Audit target record id format ve validation tasarimi dokumantasyonu.
- Dosya eki saklama, adlandirma, arsiv guvenligi, silme/tasima karar dokumantasyonu.
- Minimal `FieldObservationRecord` dataclass ve focused value/default testleri.
- Minimal bellek ici `FieldObservationRepository` baseline'i; add/list/count/find ve duplicate `observation_id` reddi.
- Minimal bellek ici `FileAttachmentRepository` baseline'i; add/list/count/find, duplicate `attachment_id` reddi, read-only exact `related_record_type` / `related_record_id` filtreleri ve exact combined `list_by_related_record(...)` filtresi.
- Field Observation attachment linking contract: `related_record_type == "field_observation"` ve `related_record_id == FieldObservationRecord.observation_id` exact pair iliskisi documentation-only olarak tanimlandi.
- `FieldObservationRepository` icin read-only exact `project_id` ve `status` filtreleri.
- `FieldObservationRepository` icin read-only exact `location` ve `category` filtreleri.
- `FieldObservationRepository` icin explicit `update_status(observation_id, new_status)` davranisi.
- `FieldObservationRepository` icin explicit `update_reporting(observation_id, reported_to, reported_at)` davranisi.
- CSE ana proje ilkeleri ve veri koruma politikasi.
- Resmi kayit / Santiye Sefi Ozel Alani izolasyon politikasi.
- Santiye sefi devir ve ozel alan politikasi.
- Adim 001-120 araligi icin NotebookLM podcast notlari.
- GitHub-centered Issue/Branch/Task/Result workflow ve resmi `V:` local repository execution protokolu.
- Tracked canonical proje talimatlari: `docs/protocols/CSE_PROJECT_INSTRUCTIONS.md`.

## CSE Politika Dokumanlari

Onemli politika dokumanlari:

- `docs/cse_ana_proje_ilkeleri.md`: CSE'nin once veri omurgasi, sonra otomasyon, en son AI yaklasimini ve genel mimari pusulasini tanimlar.
- `docs/veri_silme_onleme_politikasi.md`: Resmi proje kayitlarinin fiziksel olarak silinmemesi ilkesini aciklar.
- `docs/ozel_alan_resmi_kayit_izolasyon_politikasi.md`: Santiye Sefi Ozel Alani ile resmi proje kayitlari arasindaki siniri tanimlar.
- `docs/santiye_sefi_devir_ve_ozel_alan_politikasi.md`: Santiye sefi degisimi, istifa ve devir senaryolarinda ozel alanin nasil korunacagini aciklar.

Temel kararlar:

- Resmi kayitlar fiziksel olarak silinmez.
- Hard delete yerine archive, void, superseded veya soft-delete yaklasimlari tercih edilir.
- Santiye Sefi Ozel Alani kullaniciya aittir.
- Yeni santiye sefi eski santiye sefinin ozel alanina erisemez.
- Devir yalnizca explicit handover package veya resmi kayit uzerinden yapilir.
- Fotograf, video, PDF, belge ve ses dosyalari veritabanina gomulmez; dosya yolu / referans ve metadata ile izlenir.

## NotebookLM Podcast Notlari

Podcast notlari `docs/podcast_notes/` altindadir.

Son eklenen podcast notlari:

- `docs/podcast_notes/027_adim_157_161_notebooklm_podcast_notu.md`
- `docs/podcast_notes/028_adim_162_166_notebooklm_podcast_notu.md`
- `docs/podcast_notes/029_adim_167_180_notebooklm_podcast_notu.md`
- `docs/podcast_notes/030_adim_196_200_notebooklm_podcast_notu.md`
- `docs/podcast_notes/031_adim_201_205_notebooklm_podcast_notu.md`
- `docs/podcast_notes/032_adim_206_210_notebooklm_podcast_notu.md`
- `docs/podcast_notes/033_adim_211_215_notebooklm_podcast_notu.md`

Podcast 033, latest completed podcast olarak Steps 211-215 araligini kapsar. Sonraki dogal podcast araligi Steps 216-220 olur.

## Kalite Kontrol ve CI Durumu

- Guncel merged safe point test tabani `461 passed` olarak dogrulanir; Step 220 branch'inde local test seviyesi `471 passed` olarak dogrulanir.
- `.github/workflows/pytest.yml` GitHub Actions workflow'u repoda bulunur.
- Otomatik Actions calismasi account billing/runner-start kisiti nedeniyle manuel olarak devre disidir.
- Required status checks etkin degildir.
- Guvenlik kaniti yerel pytest, `git diff --check`, protected-path diff ve Git divergence kontrolleriyle uretilir.
- ZIP dosyalari repo kapsamindan dislanir ve local emergency/offline artifact olarak dokunulmadan korunur.
- `.gitattributes` Python, Markdown ve text dosyalari icin LF satir sonu tercihini korur.

## Henuz Olmayan Ozellikler

Asagidaki ozellikler henuz eklenmedi:

- Gercek database / SQLite / ORM.
- JSON persistence.
- Gercek dosya yukleme servisi.
- Fiziksel dosya kopyalama, silme veya tasima.
- Gercek attachment scanner.
- API.
- GUI.
- CLI.
- Authentication / authorization.
- Kullanici, rol veya yetki sistemi.
- Deployment.
- Tam backup/restore akisi.
- Thumbnail, preview, video oynatma veya streaming.
- Otomatik audit trail uretimi.

Bu sinir bilincli olarak korunuyor. Proje kucuk, testli ve izlenebilir adimlarla buyutuluyor.

## Kurulum

Python 3.11+ onerilir.

```bash
python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install -r requirements.txt
```

## Test

Repo kokunde:

```bash
python -m pytest
```

Beklenen guncel sonuc:

```text
471 passed
```

## Basit Calistirma

`app/main.py` su anda sadece basit bir baslangic mesaji dondurur:

```bash
python -m app.main
```

Bu komut tam bir CLI veya urun uygulamasi anlamina gelmez.

## Dokumantasyon

Onemli dokumantasyon dosyalari:

- `CHANGELOG.md`
- `ROADMAP.md`
- `docs/project_decisions.md`
- `docs/protocols/CSE_UNIFIED_PROJECT_SOURCE.md`
- `docs/protocols/CSE_PROJECT_INSTRUCTIONS.md`
- `docs/protocols/CSE_PROJECT_SOURCE_REGISTER.md`
- `docs/protocols/CSE_NEW_CHAT_GITHUB_BOOTSTRAP.md`
- `docs/100_guvenli_nokta_final_kalite_kontrol.md`
- `docs/101_genel_proje_denetimi_ve_mimari_saglik_raporu.md`
- `docs/117_audit_event_target_record_iliski_kurallari.md`
- `docs/118_audit_event_target_record_pair_validation.md`
- `docs/119_audit_event_target_record_type_sozlesmesi.md`
- `docs/120_audit_event_target_record_type_validation.md`
- `docs/121_audit_event_target_record_id_format_tasarimi.md`
- `docs/122_audit_event_target_record_id_validation_tasarimi.md`
- `docs/080_file_attachment_metadata_butunluk_ozeti.md`
- `docs/089_attachment_metadata_integrity_kurallari.md`
- `docs/podcast_notes/`

## Learning Sistemi

Bu proje ayni zamanda Python ve yazilim gelistirme ogrenim arsivi uretir.

`learning/` altindaki dosyalar; dataclass, repository, test, metadata modelleme, attachment integrity, karar dokumantasyonu ve proje disiplini gibi konulari adim adim aciklar.

## Sonraki Urun Yonu

Adim 220 branch calismasi boyunca ilk urun yonu, veri omurgasini guvenilir tutan dar bir saha MVP'sidir:

- hizli observation kaydi,
- attachment,
- location,
- status tracking,
- reported-to,
- daily export,
- weekly summary.

CSE halen testli domain/data/dokumantasyon cekirdegidir; field-ready application degildir. Urun ilkesi guvenilir veri omurgasi once, otomasyon sonra, AI en son olarak korunur. `FieldObservationRecord`, minimal bellek ici `FieldObservationRepository` baseline'i, observation repository icinde read-only exact filtreler, explicit status/reporting update davranislari ve minimal bellek ici `FileAttachmentRepository` metadata baseline'i implement edilmis durumdadir. Attachment repository artik `related_record_type`, `related_record_id` ve exact combined related-record pair icin read-only filtreler saglar. Field Observation attachment linking contract documentation-only olarak tanimlanmistir; persistence, broader filters/mutations, automatic lifecycle rules, contact normalization, implemented observation-specific attachment lookup, Field Observation convenience lookup, physical file operations, export/reporting, API/GUI/CLI, audit ve ek validation henuz eklenmemistir. Step 220 merge edildikten sonra Podcast 034 icin dogal aralik Steps 216-220 olur.
