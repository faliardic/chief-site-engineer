# Issue #254 — İzole Acceptance Testi Nasıl Tasarlandı?

## Problem

Fiziksel cihaz smoke testi production uygulamasının verisine yaklaşmadan gerçek
UI davranışını kanıtlamalıydı. Aynı zamanda normal launcher'a test entrypoint'i
sızmamalı ve restart kalıcılığı tek process içindeki widget rebuild ile
karıştırılmamalıydı.

Bu nedenle üç sınırı birlikte kurduk:

```text
ayrı applicationId
+ ayrı entrypoint marker
+ ayrı sentetik support root
```

ApplicationId Android sandbox'ını, marker executable target'ı, support root ise
aynı acceptance package içindeki koşuları birbirinden ayırır.

## Gerçek kod: run kimliği ve support root

`integration_test/support/issue252_smoke_acceptance.dart` yalnız 14 haneli bir
run ID kabul eder:

```dart
String validateIssue252SmokeRunId(String value) {
  if (!RegExp(r'^\d{14}$').hasMatch(value)) {
    throw const FormatException(
      'CSE_ISSUE254_RUN_ID must contain exactly 14 digits.',
    );
  }
  return value;
}
```

Kök dizin kullanıcı girdisiyle serbestçe birleşmez. Sayısal kimlik package cache
altında sabit bir namespace'e eklenir:

```dart
Directory issue252SmokeSupportRoot(String runId) => Directory(
  path.join(
    Directory.systemTemp.path,
    'cse_issue254_physical_smoke',
    validateIssue252SmokeRunId(runId),
  ),
);
```

İlk fazda kök zaten varsa test devam etmez. Böylece başka bir koşunun verisini
“boş fixture” diye kullanma riski oluşmaz.

## Gerçek kod: işlem anına göre due doğrulaması

`3 saat ertele`, eski due üzerine üç saat eklemez. Mutation anından yaklaşık üç
saat sonrasını üretir. Test bu nedenle çağrı öncesi ve sonrası UTC zamanını alır:

```dart
final startedAt = DateTime.now().toUtc();
await tapThreeHourAction();
final finishedAt = DateTime.now().toUtc();

expect(
  isDueWithinOperationWindow(
    dueAt: reminder.nextAttentionAt!,
    operationStartedAt: startedAt,
    operationFinishedAt: finishedAt,
    offset: const Duration(hours: 3),
  ),
  isTrue,
);
```

Kanonik timestamp saniyeye kırpıldığı için helper pencerenin iki tarafında
yalnız bir saniye tolerans tanır. Saatlerce geniş tolerans kullanmak gerçek
regresyonu gizlerdi.

## Gerçek kod: restart mührü

İlk process bütün assertion'lar geçmeden state yazmaz:

```dart
await writeIssue252SmokeState(
  stateFile,
  Issue252SmokeState(
    runId: runId,
    reminderId: reminder.id,
    title: title,
    finalDueAt: reminder.nextAttentionAt!,
  ),
);
```

İkinci process state marker'ını, run ID'yi, sentetik başlığı ve canonical due
değerini doğrular. Ardından SQLite'dan aynı ID'yi okuyup exact status/due
karşılaştırması yapar. Bu, widget state'in korunmasını değil kalıcı verinin yeni
process bootstrap'ında okunmasını kanıtlar.

## Entrypoint izolasyonu

Her Dart hedefinin binary marker'ı farklıdır. Builder expected marker'ı ararken
normal marker ve diğer sentetik marker'ları da yasaklar:

```powershell
python scripts/verify_flutter_apk_entrypoint.py `
  --apk $apk `
  --expected-marker CSE_ENTRYPOINT_ISSUE252_SMOKE_ACCEPTANCE_V1 `
  --forbidden-marker CSE_ENTRYPOINT_NORMAL_LIB_MAIN_DART_V1 `
  --forbidden-marker CSE_ENTRYPOINT_BACKGROUND_ACCEPTANCE_V1 `
  --forbidden-marker CSE_ENTRYPOINT_REBOOT_ACCEPTANCE_V1
```

Normal release gate bunun tersini uygular. Böylece yanlış target'la üretilmiş
ama adı doğru bir APK başarı sayılmaz.

## Testlerin amacı

- `background_acceptance_harness_test.dart`: run ID/path, due penceresi,
  restart state ve tek sentetik kayıt şartını test eder.
- `release_static_configuration_test.dart`: normal ve acceptance target/marker/
  applicationId bağlarını source seviyesinde sabitler.
- `test_mobile_release_hardening.py`: PowerShell builder/runner'ın `.acceptance`
  sınırını, process kill yöntemini ve production metadata snapshot alanlarını
  korur.
- Fiziksel `integration_test`: aynı production UI/application koduyla gerçek
  form, detay, scroll materialization, SQLite restart ve trash akışını yürütür.

## Teknik kararlar

| Karar | Neden |
| --- | --- |
| Yeni E2E framework yok | Mevcut Flutter integration ve acceptance artifact zinciri yeterli |
| Tek test, iki process | Rebuild ile gerçek restart kanıtını karıştırmamak |
| Run-ID bazlı support root | Empty synthetic fixture ve koşular arası izolasyon |
| Unavailable notification gateway | Permission mutation yapmadan SQLite/UI sözleşmesini test etmek |
| Key/text finder + `ensureVisible` | Kör koordinat ve viewport bağımlılığından kaçınmak |
| Production metadata pre/post eşitliği | Kayıt veya sandbox içeriği okumadan non-mutation kanıtı |
| Sentetik kaydı trash'e taşıma | Kullanıcı yüzeyini temizlerken hard-delete yapmamak |

## Şunu şöyle yaptık ki...

Şunu ayrı applicationId, marker ve support root ile yaptık ki acceptance testi
gerçek production kodunu çalıştırırken production kullanıcının verisine hiçbir
erişim yolu açmasın.

Şunu iki bağımsız process ile yaptık ki “restart sonrası kaldı” sonucu yalnız
aynı widget ağacının bellekte kalmasına dayanmasın.

Şunu due işlem penceresiyle ölçtük ki `3 saat ertele` davranışı yanlışlıkla eski
due üzerine üç saat eklese test yine de PASS olmasın.

Şunu yalnız sentetik reminder'ı recoverable trash'e taşıyarak bitirdik ki test
ekranı temiz kalsın, fakat fiziksel hard-delete yeni bir veri yaşam döngüsü
kararı yaratmasın.
