# Issue #275 Sonuç — Ajanda Arama Odağı ve Klavye İzolasyonu

## Sonuç

Issue #275'in dar UI düzeltmesi ve yetkili tablet kabulü PASS'tir. Ajanda arama
metni ve sorgusu canlı route içinde korunurken odak, imleç ve klavye detail
dönüşünde geri yüklenmez. Kullanıcı drag, fling veya yön değiştirme hareketi de
arama alanını kendiliğinden odaklamaz.

Kullanıcının
`https://github.com/faliardic/chief-site-engineer/issues/275#issuecomment-5125519401`
yetkisiyle tablet PASS bu Issue'nun fiziksel tamamlanma kapısıdır. Telefon
promotion ayrı bir talebe kadar ertelenmiştir; telefon install veya smoke
yapılmamış ve bu yönde PASS iddia edilmemiştir.

## Değişiklik

- `AgendaPage`, arama alanının `FocusNode` sahipliğini route-local tutar ve
  `dispose()` içinde serbest bırakır.
- Detail push öncesi arama odağı açıkça kapatılır. Dönüşte mevcut text, literal
  query, filtre, sıralama ve scroll bağlamı korunurken focus/IME kapalı kalır.
- Liste kullanıcı drag'inde `ScrollViewKeyboardDismissBehavior.onDrag`
  uygular; alan dışı tap de yalnız arama odağını kapatır.
- Dört widget regresyonu app-bar back, Android system back, odaklı arama
  alanından başlayan drag ve odaksız drag/fling/yön değiştirme matrisini kapsar.
- Schema, migration, backup, persistence, application query, global router,
  Android native ve paket kimliği değiştirilmedi.

## Doğrulama kanıtı

- Corrected old-source baseline: `20/20 PASS`; düzeltilmemiş eski davranış için
  üç hedef assertion `3/3 expected FAIL`, unrelated failure `0`.
- Focused Agenda widget suite: `24/24 PASS`.
- Agenda application suite: `22/22 PASS`.
- Full Flutter suite: `324/324 PASS`.
- Flutter analyze: `0 issue`.
- Exact disposable APK build: `1 PASS`, retry `0`.
- Checkpoint:
  `48dcae00a89798aba2c1274b5d964e8229448a0a`.
- Exact APK SHA-256:
  `B0CE311E17C045C9B5580F0BB0D70AA33759697FCEA4640D962294E0E48E8190`.
- Tablet: Samsung `SM-X610`, serial `R52W90JFN1M`, `sw853dp`.
- Tablet automated wide smoke: PASS. App-bar/system back, detail mutation,
  odaklı ve odaksız drag, fling/momentum/yön değiştirme, sort, proje/tür/arşiv
  filtreleri, non-zero offset, cold relaunch ve persistence doğrulandı.
- Cleanup: `16/16` sentetik kayıt geri alınabilir arşive taşındı; aktif `0`,
  arşiv `16`; sentetik proje envanter kanıtı için korundu.
- Gerçek kullanıcı kaydı mutation'ı `0`; uninstall/data clear/downgrade/
  hard-delete `0/0/0/0`.
- Schema `10`, backup formatı `1`, migration `0`; korumalı yol mutation'ı `0`.
- Completion cumulative allowlist `9/9`; production scope `1/1`, test scope
  `1/1`; `git diff --check` PASS; Markdown fence/conflict kontrolü `7/7` PASS.

## Minimum yeterli doğrulama

Completion yetkisi mevcut kanıtların yeniden kullanılmasını ve yeni
Flutter/Python test, analyze, build, APK/AAB, ADB, tablet veya telefon çalışması
yapılmamasını emreder. Bu nedenle final belgeler hazırlanırken yürütme zinciri
tekrarlanmadı.

Release AAB/signing, ARM64/16 KiB, backup/restore ve genel background/reboot
zinciri çalıştırılmadı. Değişen sözleşme dar Ajanda UI focus/IME davranışıdır;
schema, backup, native, notification ve persistence sözleşmeleri değişmedi.
Değişmeyen kapılar için son geçerli merged kanıt yeniden kullanıldı.

## Yayın durumu

- Branch: `codex/issue-275-agenda-search-focus-isolation`.
- Pre-completion checkpoint:
  `48dcae00a89798aba2c1274b5d964e8229448a0a`.
- Kapanış commit'i exact
  `Complete Agenda search focus validation` mesajıyla bu sonuç belgesini taşır.
- Normal push sonrasında başlığı `Prevent unintended Agenda search focus` olan
  ve gövdesi `Related to #275` ile başlayan tek Draft PR açılır.
- Completion commit/remote SHA ve Draft PR URL'si, kendine referans veren ikinci
  bir metadata commit'i üretmeden Issue/PR final kanıtında kaydedilir.
- Ready, merge, Issue close, branch delete, D29.3, amend ve force-push
  yapılmaz.

## Kapsam dışı altyapı

Telefon promotion kullanıcı kararıyla ertelenmiştir; bu bir tablet PASS
eksikliği veya otomasyon hatası değildir. Yeni toolchain/release altyapısı
sorunu kapsama alınmamıştır.
