# CHIEF SITE ENGINEER

Santiye sefi icin kontrol, takip, gunluk kayit, arsiv ve ileride raporlama sistemi kurmak icin gelistirilen sade Python projesi.

## Guncel Repo Koku

```text
V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer
```

## Tamamlanan Adimlar

- Adim 001 - Repo ve proje disiplini
- Adim 002 - Cekirdek veri modeli
- Adim 003 - Gunluk saha kaydi modeli
- Adim 004 - Bellek ici basit kayit listeleme

## Mevcut Modeller

- `SiteProject`
- `ChecklistItem`
- `TrackingRecord`
- `ArchiveDocument`
- `DailySiteLog`

## Mevcut Yardimci Fonksiyonlar

- `list_records`
- `count_records`
- `filter_records_by_project_id`
- `filter_records_by_status`

## Learning Sistemi

Bu proje ayni zamanda Python ve yazilim gelistirme ogrenim arsivi uretir. `learning/` dosyalari kisa not olarak degil, gercek kod bloklari uzerinden aciklanan ders dosyalari olarak yazilir.

## Kurulum

Python 3.11+ onerilir.

```bash
python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install -r requirements.txt
```

## Calistirma

```bash
python -m app.main
```

## Test

```bat
cd /d V:\1_PROJECTS\2_ACTIVE\Python\chief-site-engineer
python -m pytest
```

Guncel test sonucu:

```text
13 passed
```

## Sonraki Onerilen Adim

Adim 005 - Beton dokum ve numune takip baslangici icin hazirlik veya once Git ilk commit duzeni.
