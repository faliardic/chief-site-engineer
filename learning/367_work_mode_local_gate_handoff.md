# Issue 367 — Work Mode / yerel gate handoff

## Amaç

Bu adımda iki otomasyon katmanının aynı GitHub Issue üzerinde yarışmasını
önledik. Work Mode; Issue, PR, uzaktan kod ve test işlerini yönetir. Windows’taki
`CSE Codex Loop` ise yalnız açıkça yerel yürütmeye devredilmiş işi kabul eder.

## Yeni terim: local gate handoff

`local gate handoff`, Work Mode’un bir CSE görevini Windows, Flutter, ADB, APK,
fiziksel cihaz veya resmî yerel checkout gerektirdiği için yerel yürütücüye
makinece okunabilir biçimde devretmesidir. Exact işaret:

```text
CSE_BRIDGE_APPROVED
CSE_LOCAL_GATE_REQUEST
```

İki satır da en son trusted-owner approval yorumunda bulunmalıdır.

## Gerçek uygulama kodu

```python
def local_gate_ready(issue, comments):
    if not task_ready(issue, comments):
        return False
    # En son güvenilir approval yorumunu bul.
    # Yalnız bu yorum local gate satırını taşıyorsa kabul et.
```

Şunu böyle yaptık ki eski bir local-gate yorumundan sonra eklenen genel bir
approval, Windows scheduler’ı yanlışlıkla yeniden çalıştırmasın. En son approval
yorumunun kendisi handoff işaretini taşımalıdır.

Otomatik seçim artık yalnız bu yardımcıyı kullanır:

```python
if isinstance(number, int) and local_gate_ready(
    issue, github.comments(number)
):
    candidates.append(number)
```

Explicit `--issue-number` yolu da `process_issue(...)` içinde aynı kontrolü
geçer. Böylece operatör veya başka bir script Issue numarası vererek mimari
sınırı aşamaz.

## Test kodu ve amacı

```python
def test_generic_approval_without_local_gate_is_idle(self):
    ...
    self.assertIsNone(select_local_gate_issue(generic))
```

Bu test yalnız `CSE_BRIDGE_APPROVED` bulunan Issue’nun IDLE kaldığını kanıtlar.
Diğer regresyon testleri:

- en son approval local gate taşıyorsa seçim;
- eski local gate sonrasında yeni genel approval varsa ret;
- explicit Issue numarasıyla bypass denemesinde `task_not_ready`;
- RUNNING sonrasında yeni, exact local-gate reapproval ile kontrollü devam.

## Teknik karar tablosu

| Karar | Neden |
| --- | --- |
| Work Mode birincil koordinatör | GitHub işini kullanıcı taşıması olmadan yapabilir |
| Yerel loop yalnız exact handoff | Aynı Issue üzerinde çift yürütmeyi önler |
| Handoff en son approval’da | Eski yetkinin yanlışlıkla yeniden kullanılmasını önler |
| Existing `task_ready` korunur | Terminal, pause ve owner güvenliği zayıflamaz |
| Explicit Issue aynı kapıya bağlı | Manuel bypass oluşmaz |

## Kod çalışma akışı

```text
Work Mode Issue’yu değerlendirir
-> uzaktan yapılabiliyorsa Work Mode tamamlar
-> yerel gereksinim varsa exact iki satırlı trusted approval yazar
-> Windows scheduler en küçük hazır local-gate Issue’yu seçer
-> mevcut scope / validation / review / publication kapıları çalışır
-> terminal kanıt GitHub’a döner
```

Bu adım Platform API, API anahtarı, production/mobile kodu, installer, Flutter,
ADB veya cihaz işlemi eklemez.
