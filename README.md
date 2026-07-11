# CHIEF SITE ENGINEER

CHIEF SITE ENGINEER, santiye sefi icin kontrol, takip, gunluk kayit, kalite kaydi, uygunsuzluk / NCR izleme, dosya eki metadata, attachment integrity ve dokumantasyon disiplini gelistirmek amaciyla kurulan sade bir Python projesidir.

Proje su anda gercek bir urun uygulamasi degil; domain model, bellek ici repository davranislari, testler, karar dokumantasyonu, learning notlari ve NotebookLM podcast notlari ureten bir cekirdek gelistirme alanidir.

## Guncel Durum

Son guvenli nokta:

```text
Adim 205 - Canonical project instructions and repository truth synchronization
PR #26 merge commit: 92a15f2a55e6bfda42d50b8ef7dea651ff496f62
```

Guncel test sonucu:

```text
413 passed
```

Mevcut calisma durumu:

```text
Adim 206 - Step 205 merged truth, Podcast 031, and instruction authority closure
```

Adim 205, PR #26 ile squash merge edildi ve master uzerindeki guncel guvenli nokta oldu. Adim 206, Step 205 merge gercegini README/state/roadmap/changelog/karar/protokol kayitlarinda final hale getirir, Podcast 031'i olusturur ve talimat yetkisini tracked canonical dosyada birlestirir.

## Repo Koku

```text
V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer
```

## Mimari Ozet

Proje su ana parcalardan olusur:

- `app/models.py`: Santiye, kalite, uygunsuzluk, NCR, dosya eki ve yardimci domain modelleri.
- `app/records.py`: Bellek ici kayit listeleme ve `NonconformityRepository` davranislari.
- `app/attachments.py`: Canonical attachment path helper fonksiyonu.
- `app/attachment_integrity.py`: Attachment integrity status sabitleri, result/report modelleri, helper ve serializer fonksiyonlari.
- `app/main.py`: Basit uygulama baslangic mesaji.
- `tests/`: Model, repository, attachment path ve attachment integrity davranislarini dogrulayan pytest testleri.
- `docs/`: Adim bazli karar, kapsam, politika, denetim ve kullanim dokumantasyonu.
- `learning/`: Python ve proje ogrenim notlari.
- `docs/podcast_notes/`: NotebookLM podcast kaynak notlari.

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

Bu notlar, export/result/handover QC hattini, official local sync protokolunu, canonical instruction workflow'unu ve CSE veri koruma / ozel alan politikalarini podcast anlatimina uygun sekilde ozetler.

## Kalite Kontrol ve CI Durumu

- Guncel yerel test tabani `413 passed` olarak dogrulanir.
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
413 passed
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
- `docs/protocols/CSE_PROJECT_INSTRUCTIONS.md`
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

Adim 205 repository truth synchronization merge edildikten sonra ilk urun yonu, veri omurgasini guvenilir tutan dar bir saha MVP'sidir:

- hizli observation kaydi,
- attachment,
- location,
- status tracking,
- reported-to,
- daily export,
- weekly summary.

CSE halen testli domain/data/dokumantasyon cekirdegidir; field-ready application degildir. Urun ilkesi guvenilir veri omurgasi once, otomasyon sonra, AI en son olarak korunur. Adim 206, bu urun implementation'ini baslatmaz; yalniz Step 205 truth, Podcast 031 ve instruction authority closure kayitlarini tamamlar.
