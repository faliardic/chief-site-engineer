# CSE Evidence Directory — Risk-Based Usage

`.cse` günlük workflow motoru değildir. Yalnız material izlenebilirlik veya kritik provenance gerektiğinde kullanılır.

## Lane kullanımı

### FAST

- `.cse/tasks` oluşturulmaz.
- `.cse/results` oluşturulmaz.
- `.cse/state` güncellenmez.
- Issue/PR/task/result ceremony üretilmez.

Git diff/commit ve owner test sonucu yeterlidir.

### STANDARD

Varsayılan olarak `.cse` dosyası yoktur.

Yalnız uzun resume, bağımsız review veya material cross-module izlenebilirlik gerektiğinde kısa task/result kullanılabilir. Hedef 10–20 satırdır.

### CRITICAL

Task/result provenance kullanılabilir veya Issue tarafından zorunlu tutulabilir.

Örnek konular:

- schema/migration;
- backup/restore;
- identity/revision/transaction/history;
- user data ve destructive işlemler;
- attachment/DWG file integrity;
- security/permission/signing;
- release artifact'i.

## Kaynak sınırı

`.cse/state`, task/result, eski Step/Adım kayıtları veya handoff current GitHub master/Issue/PR gerçeğini override edemez.

Henüz gerçekleşmemiş push, test, temiz worktree veya divergence sonucu yazılmaz. Kayıt yalnız gerçek evidence'a dayanır.

## Adlandırma

Gerektiğinde:

```text
.cse/tasks/<issue_no>_task.md
.cse/results/<issue_no>_result.md
```

FAST için dosya oluşturma amacıyla sahte Issue numarası üretilmez.

## Ana karar

> `.cse` kritik izlenebilirlik aracıdır; her mikro değişiklikte doldurulacak zorunlu form değildir.
