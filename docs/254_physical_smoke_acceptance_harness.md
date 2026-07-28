# Issue #254 — İzole Fiziksel Smoke Acceptance Harness

## Amaç

Bu harness, Issue #252'de birleşen Hatırlatıcı akışını fiziksel Android cihazda
gerçek Flutter UI ve application katmanı üzerinden tekrar edilebilir biçimde
doğrular. Production `.debug` uygulamasını açmaz; kayıtlarını, sandbox'ını veya
UI ağacını okumaz.

Yeni bir otomasyon framework'ü eklenmedi. Mevcut bileşenler kullanılır:

- Flutter `integration_test`;
- `CSE_ACCEPTANCE_HARNESS=true` applicationId ayrımı;
- APK kernel marker verifier;
- sentetik acceptance artifact builder;
- production field artifact release gate.

## Kimlik ve veri izolasyonu

| Yüzey | ApplicationId | Entrypoint marker |
| --- | --- | --- |
| Normal field debug | `com.faliardic.chiefsiteengineer.debug` | `CSE_ENTRYPOINT_NORMAL_LIB_MAIN_DART_V1` |
| Background acceptance | `com.faliardic.chiefsiteengineer.acceptance` | `CSE_ENTRYPOINT_BACKGROUND_ACCEPTANCE_V1` |
| Reboot acceptance | `com.faliardic.chiefsiteengineer.acceptance` | `CSE_ENTRYPOINT_REBOOT_ACCEPTANCE_V1` |
| Issue #252 physical smoke | `com.faliardic.chiefsiteengineer.acceptance` | `CSE_ENTRYPOINT_ISSUE252_SMOKE_ACCEPTANCE_V1` |

Physical-smoke verisi `Directory.systemTemp` altında
`cse_issue254_physical_smoke/<14-haneli-run-id>` support root'una yazılır.
İlk fazda bu kök mevcutsa test fail-closed durur. Formda oluşturulan tek kayıt:

```text
ISSUE252-SMOKE-<run-id>
```

Kayıt proje, kişi, telefon, Ajanda, Puantaj veya Beton kaydına bağlanmaz.

## İki fazlı akış

Birinci process:

1. `Bugün | Yarın | Diğer` metinlerini key/text finder ile doğrular.
2. Hatırlatıcı formunda `3 saat` seçimini, ardından create için `2 saat`
   seçimini yapar.
3. Sentetik reminder due değerini işlem penceresi +2 saat olarak doğrular.
4. Detayda `Yarına ertele`, `2 saat ertele`, `3 saat ertele` metinlerini
   doğrular ve eylemleri sırayla çalıştırır.
5. Son due değerinin önceki due değil, üç-saat mutation işlem penceresi +3 saat
   olduğunu doğrular.
6. Reminder ID ve son canonical due değerini acceptance state mührüne yazar.

Runner HOME'a dönüp yalnız acceptance package için normal Android process kill
uygular. İkinci process aynı run ID ile:

1. aynı reminder kimliğini yeniden okur;
2. active status ve son due değerinin birebir korunduğunu doğrular;
3. production UI detayından yalnız sentetik kaydı Geri Dönüşüm Kutusu'na taşır;
4. trash projection'ında aynı kimliği doğrular.

Koordinat, OCR, screenshot ve Android UI dump kullanılmaz. Flutter widget
key/text finder ve `ensureVisible` materialization yolu kullanılır.

## Artifact fail-closed sözleşmesi

`scripts/build_mobile_acceptance_apks.ps1` üç sentetik APK'yı ayrı target ve
marker'la üretir. Her artifact:

- normal launcher marker'ını reddeder;
- diğer acceptance marker'larını reddeder;
- applicationId tam olarak `.acceptance` değilse durur.

`scripts/release_gate.ps1` normal `lib/main.dart` field APK'sında yeni
physical-smoke marker'ını hem shared output hem kopyalanmış sidecar üzerinde
reddeder.

## Fiziksel runner

`scripts/run_issue252_physical_smoke_acceptance.ps1` yalnız seçili fiziksel
cihazda çalışır. Ön koşul olarak normal field artifact'ında `.debug`
applicationId ve normal marker'ı doğrular. Physical smoke öncesi ve sonrası
production package için yalnız şu metadata eşitliği aranır:

- code path;
- version code/name ve first/last install time;
- data directory metadata yolu;
- credential/device-encrypted data inode'ları;
- process ID.

Production APK cihazdan çekilmez, production data directory gezilmez ve kayıt
count/içeriği okunmaz. Yalnız acceptance package code path'indeki `base.apk`
marker/hash kanıtı için `mobile/build/release_gate` altına çekilir.

## Doğrulama

Zorunlu kapılar:

- focused harness/helper ve static configuration Flutter testleri;
- focused Python release-hardening testleri;
- `flutter test --no-pub`;
- `flutter analyze --no-pub`;
- normal field/release gate'in değişen marker sözleşmesiyle orantılı koşusu;
- sentetik acceptance artifact build'i;
- iki fazlı fiziksel smoke;
- `git diff --check`, exact allowlist ve protected-path kontrolleri.

Issue #207 background/reboot, Issue #212/#214 field artifact ve Issue #252
production behavior kanıtları; ilgili production sözleşmeleri değişmediği için
yeniden kullanılır.
