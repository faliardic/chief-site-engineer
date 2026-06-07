# CHIEF SITE ENGINEER

CHIEF SITE ENGINEER, santiye sefi icin kontrol, takip, gunluk kayit, kalite kaydi, uygunsuzluk / NCR izleme, dosya eki metadata ve dokumantasyon disiplini gelistirmek amaciyla kurulan sade bir Python projesidir.

## Guncel Durum

Son guvenli nokta:

```text
Adim 080 - FileAttachmentRecord metadata butunluk ozeti
```

Guncel test sonucu:

```text
125 passed
```

Proje su anda gercek bir urun uygulamasi degil; domain model, bellek ici repository davranislari, testler, karar dokumantasyonu, learning notlari ve NotebookLM podcast notlari ureten bir cekirdek gelistirme alanidir.

## Repo Koku

```text
V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer
```

## Mimari Ozet

Proje su ana parcalardan olusur:

- `app/models.py`: Santiye, kalite, uygunsuzluk, NCR, dosya eki ve yardimci domain modelleri.
- `app/records.py`: Bellek ici kayit listeleme ve `NonconformityRepository` davranislari.
- `app/main.py`: Basit uygulama baslangic mesaji.
- `tests/`: Model ve repository davranislarini dogrulayan pytest testleri.
- `docs/`: Adim bazli karar, kapsam ve kullanim dokumantasyonu.
- `learning/`: Python ve proje ogrenim notlari.
- `docs/podcast_notes/`: NotebookLM podcast kaynak notlari.

## Mevcut Teknik Kapsam

Adim 080 itibariyla proje su alanlarda ilerlemistir:

- Temel santiye domain modelleri.
- Gunluk saha, beton dokum, yapi denetim, malzeme, toplanti, RFI/submittal ve ilgili kayit modelleri.
- Uygunsuzluk adayi sureci.
- Kesin uygunsuzluk / NCR sureci.
- `NonconformityRepository` icin bellek ici ekleme, listeleme, filtreleme, sayma, guncelleme, arsivleme ve restore davranislari.
- `FileAttachmentRecord` ile fotograf, video, PDF, belge, ses ve diger dosya ekleri icin metadata modeli.
- Dosya eki icin `original_file_name`, `uploaded_by`, `uploaded_at`, `notes`, `file_name`, `file_path`, `file_type`, `mime_type`, `file_size`, `related_record_type` ve `related_record_id` karar hatti.
- Dosya eki path standardi: `attachments/{project_id}/{record_type}/{yyyy}/{mm}/{dd}/{record_id}/{safe_file_name}`.
- Dosya eki saklama, adlandirma, arsiv guvenligi, silme/tasima karar dokumantasyonu.
- Adim 001-070 araligi icin NotebookLM podcast notlari.

## Henuz Olmayan Ozellikler

Asagidaki ozellikler henuz eklenmedi:

- Gercek database / SQLite / ORM.
- JSON persistence.
- Gercek dosya yukleme servisi.
- Fiziksel dosya kopyalama, silme veya tasima.
- API.
- GUI.
- CLI.
- Authentication / authorization.
- Kullanici, rol veya yetki sistemi.
- Deployment.
- CI pipeline.
- Thumbnail, preview, video oynatma veya streaming.
- Otomatik audit trail modeli.

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
125 passed
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
- `docs/080_file_attachment_metadata_butunluk_ozeti.md`
- `docs/podcast_notes/`

## Learning Sistemi

Bu proje ayni zamanda Python ve yazilim gelistirme ogrenim arsivi uretir.

`learning/` altindaki dosyalar; dataclass, repository, test, metadata modelleme, karar dokumantasyonu ve proje disiplini gibi konulari adim adim aciklar.

## Sonraki Adim

Adim 081, README dosyasini Adim 080 guvenli noktasindaki gercek repo durumuna gore guncelleme adimidir.

Sonraki teknik calisma, derin analiz sonucuna gore belirlenecektir: mimari, test kapsami, roadmap, learning dosyalari ve sonraki 20 adim stratejisi birlikte degerlendirilecektir.
