# CSE — Q01–Q26 Yol Haritası Değerlendirme Günlüğü

**Belge türü:** Dönemsel roadmap değerlendirme ve toplantı hafızası  
**Kapsam:** `ROADMAP.md` içindeki ilk genel yayın öncesi Q01–Q26 kuyruğu  
**Yürütme otoritesi:** `ROADMAP.md`  
**Durum / teknik gerçek otoritesi:** current GitHub `master`, açık Issue/PR ve gerçekleşmiş gate kanıtları

## 1. Bu dosyanın görevi

Bu dosya Q01–Q26 yol haritasını **değerlendirmek**, dönemsel toplantı sonuçlarını korumak ve ileride yapılacak planlama tartışmalarına bağlam sağlamak için kullanılır.

Bu dosya ikinci bir roadmap değildir ve kendi başına üretim sırasını değiştirmez.

- `ROADMAP.md`: hangi işin hangi sırada yürütüleceğinin kanonik kaynağıdır.
- `ROADMAP_REVIEW_LOG.md`: neden o sıranın mantıklı veya tartışmalı görüldüğünü, hangi risklerin/kararların öne çıktığını ve önceki toplantılarda ne değerlendirildiğini tutar.
- current GitHub: bir işin gerçekten açık, merge edilmiş, PASS/FAIL/PENDING veya bloke olup olmadığının kaynağıdır.
- `docs/project_decisions.md`: kalıcı teknik/ürün kararları içindir; dönemsel değerlendirme raporlarının yerine kullanılmaz.

## 2. ChatGPT kullanım kuralı

Fatih aşağıdaki türde bir talep verdiğinde ChatGPT bu dosyayı da zorunlu bağlam olarak okur:

- `Q'ları değerlendirelim`
- `önümüzdeki işleri değerlendirelim`
- `roadmap toplantısı yapalım`
- `sıradaki işlerin mantığını değerlendir`
- `yayından önceki işleri yeniden gözden geçir`
- `öncelikleri tekrar değerlendirelim`
- eşdeğer reprioritization / roadmap-review talepleri

Bu durumda değerlendirme sırası:

1. current GitHub `master` + açık Issue/PR/gate durumu;
2. güncel `AGENTS.md`;
3. güncel `ROADMAP.md` Q01–Q26 kuyruğu;
4. bu dosyadaki en yeni ve ilgili değerlendirme raporları;
5. gerekiyorsa V2 Scope, Unified Source ve ilgili Issue/PR kaynakları.

Normal `devam` veya execution talebinde bu dosyadaki öneriler ROADMAP sırasını override etmez.

## 3. Değerlendirme raporu kuralları

Her roadmap toplantısı veya owner tarafından kaydedilmesi istenen değerlendirme ayrı kronolojik kayıt olarak bu dosyanın sonuna eklenir.

Her rapor mümkün olduğunca şunları içerir:

- tarih;
- toplantının amacı;
- değerlendirilen Q maddeleri;
- toplantı anındaki current GitHub gerçeğinin kısa özeti;
- her Q için ürün değeri / release değeri;
- bağımlılık ve teknik risk;
- tahmini kapsam büyüklüğü: `küçük / orta / büyük / kritik`;
- yayın öncesi zorunluluk değerlendirmesi: `V1 blocker / güçlü aday / ertelenebilir / release gate`;
- önerilen sıra veya grup;
- Fatih'in verdiği owner kararları;
- açık sorular;
- ROADMAP truth-sync gerekip gerekmediği.

## 4. Otorite ve supersession kuralı

- Değerlendirme raporları tavsiye ve karar bağlamıdır; tek başına production authority değildir.
- Fatih toplantıda mevcut sırayı değiştirirse, yeni production iş başlamadan önce kabul edilen karar `ROADMAP.md` dosyasına truth-sync edilir.
- Kalıcı ürün kapsamı değişirse gerektiğinde `docs/v2/CSE_V2_SCOPE.md` veya ilgili kalıcı karar kaynağı da güncellenir.
- Bir değerlendirme daha sonra geçersiz kalırsa eski rapor silinmez veya geriye dönük yeniden yazılmaz. Yeni rapor eski raporu açıkça `SUPERSEDED` veya `KISMEN SUPERSEDED` olarak işaret eder.
- Eski rapordaki SHA, Issue/PR veya durum bilgisi güncel gerçek sayılmaz; her yeni toplantıda current GitHub yeniden doğrulanır.
- ChatGPT geçmiş raporlardaki gerekçeleri kullanabilir fakat güncel olmayan durum bilgisini kopyalayamaz.

## 5. Değerlendirme bakış açısı

Q maddeleri değerlendirilirken yalnız “özellik güzel mi?” sorusu sorulmaz. En az şu açılardan düşünülür:

1. **Saha değeri:** Şantiye şefinin gerçek günlük işini ne kadar hızlandırıyor veya güvenli hale getiriyor?
2. **Yayın yeterliliği:** Bu olmadan ilk genel yayın eksik, riskli veya güven vermeyen durumda mı?
3. **Sürtünme:** Kullanıcının tekrar veri girişi, menü arama, gereksiz dokunuş veya bağlam kaybını azaltıyor mu?
4. **Veri riski:** Identity, revision, event/history, attachment, backup/restore veya user-file contract'ına dokunuyor mu?
5. **Kapsam şişmesi:** İlk sürüm için gerekli değerden daha büyük bir sistem mi açıyor?
6. **Test/gate maliyeti:** Manual/device/recovery/privacy/release gate yükü nedir?
7. **Bağımlılık:** Başka bir Q maddesinden önce/sonra yapılması teknik veya ürün açısından daha doğru mu?
8. **Erteleme maliyeti:** Post-release'e bırakılırsa gerçek kullanıcı deneyiminde ne kaybedilir?

## 6. Toplantı raporu şablonu

```markdown
## REVIEW-XXX — <başlık>

**Tarih:** YYYY-MM-DD  
**Amaç:** ...  
**Değerlendirilen Q'lar:** Qxx–Qyy / seçili maddeler

### Current GitHub gerçeği
- master: toplantı sırasında doğrulandı
- açık production Issue/PR: ...
- önemli gate/blocker: ...

### Değerlendirme

#### Qxx — <başlık>
- Saha değeri:
- Yayın öncesi önemi:
- Risk/kapsam:
- Bağımlılık:
- Öneri:

### Toplantı sonucu
- Fatih kararları:
- Öneri olarak kalanlar:
- Ertelenenler:
- Yeni araştırma gerekenler:

### ROADMAP etkisi
- `YOK` veya exact sıra/kapsam değişikliği
- Gerekliyse ROADMAP truth-sync referansı
```

## 7. REVIEW-001 — Değerlendirme sisteminin kurulması

**Tarih:** 2026-09-06  
**Amaç:** Q01–Q26 için dönemsel roadmap değerlendirmelerini tek kalıcı dosyada tutacak sistemi kurmak.  
**Değerlendirilen Q'lar:** Q01–Q26 yapısının tamamı, ancak bu kayıt yeni bir reprioritization toplantısı değildir.

### Current GitHub gerçeği

- ROADMAP Q01–Q26 ilk genel yayın öncesi kanonik yürütme kuyruğudur.
- Bu kayıt oluşturulurken açık production işi PR #715 / Q01 İSG Geçmiş-Arşiv işidir.
- Bu toplantı production sırasını değiştirmez.

### Toplantı sonucu

- Fatih, Q maddelerinin arada sırada ayrıca değerlendirilmesini ve bu değerlendirme raporlarının kalıcı olarak saklanmasını istedi.
- Gelecekte sıradaki işler için değerlendirme istendiğinde ChatGPT yalnız ROADMAP sırasına değil, bu dosyadaki güncel ve ilgili geçmiş değerlendirmelere de bakacak.
- Değerlendirme raporu ile execution authority ayrıldı: rapor öneri bağlamı; kabul edilen sıra değişikliği ROADMAP'e ayrıca işlenir.

### ROADMAP etkisi

`YOK` — Q01–Q26 sırası bu kayıtla değiştirilmedi.
