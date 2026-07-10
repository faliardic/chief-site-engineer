# Learning 171 - Export Result Summary/Report Helper Usage Documentation

Bu adimda Adim 170'te eklenen export result summary/report helperlarinin nasil kullanilacagini belgeledik. Kod veya test degistirmedik.

## Helperlar ne icin var?

Uc helper var:

```python
build_export_result_summary(result_contract)
build_export_result_report(result_contracts)
format_export_result_summary_as_markdown(summary)
```

Bu helperlar export wrapper sonucunu okunabilir hale getirir. Wrapper sonucunun kendisi teknik bir dict olabilir; summary/report katmani bu dict'i handover QC, admin/debug veya dokumantasyon katmanlari icin daha rahat okunur hale getirir.

## Neyi yapmazlar?

Bu helperlar read-only yorumlama katmanidir.

Yapmadiklari seyler:

- dosya yazmak
- export helper cagirmak
- path safety kararini tekrar hesaplamak
- wrapper result contract'i mutate etmek
- low-level `write_*` helperlarin yerine gecmek
- hard validation yapmak
- `blocked` status uretmek

## Basarili result nasil okunur?

`success=True` olan bir wrapper sonucu `build_export_result_summary(...)` ile okunabilir summary'ye cevrilebilir. Bu summary "export uretildi" bilgisini ve path bilgisini gorunur kilar.

Bu islem yeni dosya uretmez; sadece mevcut result contract'in soyledigini raporlar.

## Failure result nasil okunur?

`success=False` olan bir wrapper sonucu review/attention gerektiren export sonucu olarak okunur. Ornegin hedef dosya zaten varsa, parent klasor eksikse veya uzanti hataliysa helper bunu kisa ve guvenli kullanici mesajina cevirebilir.

Bu failure sonucu:

- devir paketini otomatik bloke etmez
- kayitlari gecersiz yapmaz
- hard validation anlamina gelmez
- audit event uretmez

## Report ne zaman kullanilir?

Birden fazla export sonucu varsa `build_export_result_report(...)` kullanilir. Bu helper success, review ve unknown sayilarini toplar ve item siralamasini korur.

Bu sayede JSON ve Markdown export denemeleri gibi birden fazla sonucu tek yerde gormek mumkun olur.

## Markdown formatter ne saglar?

`format_export_result_summary_as_markdown(...)` summary veya report dict'ini Markdown metnine cevirir. Bu metin ust katmanlarda okunabilir not olarak kullanilabilir.

Formatter dosya yazmaz. `.md` dosyasi olusturmak halen ayri export/write helper sorumlulugudur.

## Sonuc

Adim 171, Adim 170 helperlarinin kullanim sinirini netlestirdi. Helperlar yorumlama ve raporlama icindir; export, validation, backup/restore, API, GUI, CLI veya database/repository davranisi baslatmaz.
