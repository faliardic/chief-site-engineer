# Local Field MVP v0.1 Operasyonları

## Kurulum ve yerel uygulama

```powershell
python -m pip install -r requirements.txt
python -m app.web --data-root C:\cse-data
```

Uygulama varsayılan olarak yalnız `127.0.0.1` üzerinde açılır. Loopback dışı
bir adres için `--allow-network` açıkça verilmelidir. Bu MVP authentication,
authorization, TLS veya production WSGI sunucusu içermez; public internet için
uygun değildir.

## Günlük çıktı

```powershell
python -m app.ops export-daily --data-root C:\cse-data --date 2026-07-13 --output C:\exports\daily.zip
```

Tarih Europe/Istanbul yerel takvim günüdür. ZIP Markdown, CSV, JSON ve attachment
bütünlük manifestlerini içerir; attachment binary dosyalarını içermez.

## Backup ve doğrulama

```powershell
python -m app.ops backup --data-root C:\cse-data --output C:\backups\field.csebackup.zip
python -m app.ops verify-backup --archive C:\backups\field.csebackup.zip
```

Backup SQLite online snapshot kullanır ve yalnız bütünlük doğrulaması `valid`
olan attachment dosyalarıyla tamamlanır. Kaynak data root değiştirilmez.

## Restore

```powershell
python -m app.ops restore --archive C:\backups\field.csebackup.zip --target-root C:\cse-restored
python -m app.web --data-root C:\cse-restored
```

Restore hedefi mevcut olmamalıdır. İşlem mevcut veya dolu bir dizinin üzerine
yazmaz; arşiv, SQLite ve attachment reconciliation doğrulanmadan hedef root final
adıyla görünür olmaz.
