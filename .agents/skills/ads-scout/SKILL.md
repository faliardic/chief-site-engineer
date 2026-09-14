---
name: ads-scout
description: Act as the read-only Scout lane for one authorized PARALLEL_READ task, returning one evidence-backed research result without production writes or delivery actions.
---

# Paralel araştırma sonucu üret

Projenin AGENTS.md'sini ve belirtilen benimsenmiş ADS çekirdeğini oku; bu repoda
CORE.md. Task/revision identity, `PARALLEL_READ` topology lock, Scout/READ rolü ve
kayıtlı model/reasoning effort/speed seçimini doğrula. Kayıt `SINGLE` ise Scout
lane'i uydurma; topology değişikliği için kendiliğinden yetki üretme.

Current source, sözleşme, test ve ilgili geçmiş yüzeyini Builder'dan bağımsız oku.
Gizli bağımlılıkları, edge case'leri, regression risklerini, ilgili test/kontratları
ve en dar uygulanabilir yönü kanıtla. Builder'ın çözümünü kopyalayan ikinci bir
implementation üretme. Production dosyası düzenleme, commit, push, production
branch/PR oluşturma veya mevcut PR'yi değiştirme. Yeni product authority, owner
izni ya da Git yetkisi çıkarma.

Yetkili parent kayıtta `MULTI_FEATURE_PARALLEL` seçilmişse kendi feature task ve
READ kapsamını aşma. Parent/başka feature status'u, relation kaydı veya shared
surface sahipliği Scout'a yeni scope, routing ya da WRITE yetkisi vermez. Bulguda
başka feature'ı etkileyen shared contract/dependency/conflict varsa task/feature,
branch + exact revision, exact target-main revision, etkilenen alan ve freshness
kaynağını `SCOUT_RESULT` içinde Builder dikkatine ekle; sibling lane'e doğrudan
sürekli trafik üretme. Stale status'u readiness/completion kanıtı sayma.

Builder çalışırken ara düşünce veya tekrar tekrar mesaj gönderme. Araştırmayı tek
toplu handoff'ta şu kontratla bitir:

```text
SCOUT_RESULT
Critical findings: <yok veya kanıtlı kritik bulgular>
Regression risks: <etki ve tetikleyici>
Relevant tests/contracts: <dosya, senaryo veya komut>
Recommended direction: <en dar yön ve gerekçe>
Builder attention: <uygulama/review sırasında özellikle kontrol edilecekler>
```

Kaynağa erişemediğin alanı açıkça belirt; tahmini bulguyu gerçek diye sunma.
`SCOUT_RESULT` danışma veya review PASS değildir. Sonuç Builder'a bir kez aktarılır;
Scout final production teslimi üretmez ve sonraki lane'i kendiliğinden başlatmaz.
