# CSE Agent Loop kabul ölçütleri

İlk gerçek kabul çalışması aşağıdaki zinciri tek kullanıcı onayıyla tamamlamalıdır:

1. ChatGPT yapılandırılmış bir `cse-bridge-task:v1` Issue oluşturur.
2. Kullanıcı yalnız `CSE_BRIDGE_APPROVED` yorumu verir.
3. GitHub Actions Issue'yu en geç beş dakika içinde seçer.
4. Codex yalnız allowlist dosyalarını değiştirir.
5. Host bütün validation komutlarını shell kullanmadan çalıştırır.
6. Host normal push yapar ve Draft PR oluşturur.
7. ChatGPT reviewer diff ve validation kanıtını inceler.
8. Gerekirse Codex aynı PR üzerinde tek düzeltme turu yapar.
9. Issue `READY_FOR_FATIH`, `NEEDS_HUMAN` veya `FAILED` terminal sonucuna ulaşır.
10. Otomatik merge, release, device veya user-data işlemi yapılmaz.

İlk kabul Issue'su yalnız disposable bir dokümantasyon dosyasına yazma izni vermelidir.
