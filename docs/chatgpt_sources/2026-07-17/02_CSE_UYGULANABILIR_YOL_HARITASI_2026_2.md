# CSE 2026.2 — Uygulanabilir Geliştirme ve Güncelleme Yol Haritası

**Kanonik yürütme programı:** GitHub Issue #127  
**Faz backlog’u:** GitHub Issue #128–#140  
**Toplam ayrıntılı adım:** 193  
**Sürüm:** 2026-07-17.1

Bu dosya 193 adımı GitHub dışında ikinci kez kopyalayan bağımsız bir backlog değildir. Güncel kapsam, checklist, bağımlılık ve kapanış kapıları ilgili GitHub Issue’larında tutulur. Bu dosyanın görevi ChatGPT ve yeni sohbetler için faz haritasını ve yürütme sırasını göstermektir.

## Yürütme kuralları

- Aynı anda yalnız bir aktif production implementation Issue’su yürütülür.
- En fazla bir incelemede PR bulunur.
- Her teknik iş ayrı dar Issue, branch, test ve completion evidence ile kapanır.
- Merge edilmemiş branch veya Draft PR, merged güvenli nokta olarak gösterilmez.
- Gerçek kullanıcı data root’una açık yetki olmadan erişilmez.
- Migration ve recovery işleri eski şema/backup uyumluluğunu executable testlerle kanıtlar.
- AI, deterministik arama ve exact source linki tamamlanmadan başlamaz.

## Güncel durum

```text
Son merged güvenli nokta:
Issue #119 / PR #126
1d4b2b7f9ace5e7d474c4893d24404ceae2faede

Repository truth senkronizasyonu:
Issue #141
Branch commit ac2942b693e95e0f41a8fa02b76dcd0b31de0aba
Draft PR #142 açık ve merge edilmedi

Kaynakları GitHub’a taşıma:
Issue #143
Branch codex/issue-143-chatgpt-github-sources
```

## Faz haritası

### Faz 0 — Repository truth, ADR’ler ve yürütme zemini — Issue #128

Repository gerçekliği, Tek Hafıza UX ve `private | project` kapsamı, `MemoryIndex / RecordRef`, Backup / Hafızayı İndir / Proje Paketi ayrımı, legacy envanteri, pilot ölçütleri ve owner-only tehdit modeli.

### Faz 1 — Güvenilir Hafıza yaşam döngüsü — Issue #129

Olay zamanı ile giriş zamanının ayrılması, geriye dönük kayıt, archive list/filter, unarchive, archive event geçmişi, attachment/revision bütünlüğü, ortak Hafıza indeksi, birleşik literal arama ve timeline.

### Faz 2 — Tam Hafıza İndirme ve kurtarma — Issue #130

Full Memory Package sözleşmesi, JSON/CSV/Markdown veri setleri, offline `index.html`, manifest/checksum, verifier, web/CLI üretim, eski backup compatibility, saldırı regresyonları ve clean restore.

### Faz 3 — Mobil runtime ve saha pilotları — Issue #131

Cihaz-of-truth ADR’si, güvenli LAN erişimi, mobil hızlı kayıt, kamera attachment, PWA, offline read cache, kontrollü outbox/sync, conflict görünürlüğü, notification, 7 günlük ve 30 günlük gerçek saha pilotları.

### Faz 4 — Şantiye komuta merkezi — Issue #132

Bugün, geciken, önemli ve son kayıtlar; observation/follow-up/routine ortak timeline; proje/kapsam/durum filtreleri; hızlı işlemler; haftalık özet ve 30 saniyelik sabah kabul senaryosu.

### Faz 5 — Doküman, rapor ve çizim merkezi — Issue #133

`Document`, `DocumentRevision`, `EntityLink`; managed ingestion; PDF/fotoğraf preview; current/superseded revision; kayıt/doküman bağlantısı; dış DWG açma; rapor builder ve Proje Paketi.

### Faz 6 — Şantiye İş Planı Lite — Issue #134

WBS-lite, plan revision, bağımlılık/cycle koruması, milestone, ilerleme, planlanan-gerçekleşen farkı, iki haftalık lookahead, make-ready notları, Gantt-lite ve CSV aktarımı.

### Faz 7 — İş Paketi Motoru ve Beton İş Paketi — Issue #135

Versioned paket şablonu, paket örneği, adım yaşam döngüsü, kanıt gereksinimleri, insan inceleme sinyali, plan/doküman entegrasyonu ve gerçek beton dökümünün pre/during/post akışı.

### Faz 8 — Saha hesap araçları ve manuel metraj — Issue #136

CalculationRecord, güvenli birim registry ve hesap motoru, kaydedilebilir işlem şeridi, temel saha hesapları, donatı yaklaşık ağırlığı, QuantityItem ve yönlendirmeli manuel metraj.

### Faz 9 — PDF-first çizim destekli metraj — Issue #137

PDF ölçüm ADR’si, kalibrasyon, document-coordinate geometry, uzunluk/alan/adet, explicit doğrulama, revision değişimi sinyali, overlay/export ve dar DWG metadata prototipi.

### Faz 10 — Haricî uygulama ve cihaz paylaşımı — Issue #138

Web Share API, record deep-link, güvenli dosya içe aktarma, PWA share target, WhatsApp konuşma açma/paylaşma yardımcı akışı, scope/gizlilik uyarıları ve dış action history.

### Faz 11 — Deterministik arama ve kaynaklı AI — Issue #139

FTS5 preflight, deterministik full-text index ve ranking, rebuild/drift diagnostic, doküman text extraction sınırı, evaluation dataset, semantic/hybrid search, kaynaklı soru-cevap ve AI insan-onayı kapıları.

### Faz 12 — Owner-only güvenlik ve ürünleştirme — Issue #140

App lock, güvenli session, şifreli backup, retention, health diagnostics, rebuild/repair sınırı, version/release/update, paket dağıtımı, owner-only sync, conflict review, performans/pil bütçesi ve recovery drill.

## Faz geçiş kapıları

- Güvenilir Hafıza yaşam döngüsü ve Tam Hafıza İndirme bitmeden dashboard, plan veya paket production işi başlamaz.
- Clean restore veri kayıpsız kanıtlanmadan mobil saha pilotu başlamaz.
- 7 günlük pilotta veri kaybı sıfır olmadan 30 günlük pilot veya ağır yeni modül başlamaz.
- Doküman revision omurgası olmadan çizim destekli metraj başlamaz.
- Paket motoru olmadan Beton İş Paketi özel kodu başlamaz.
- Deterministik arama ve exact source linki olmadan AI başlamaz.

## Global Definition of Done

- Değişiklik küçük, tek amaçlı ve geri alınabilir.
- Production davranışı değişirse focused test ve full suite çalışır.
- `python -m compileall -q app scripts`, state JSON ve `git diff --check` geçer.
- Attachment ve backup bütünlüğü korunur.
- Kullanıcı zamanı Europe/Istanbul, storage canonical UTC’dir.
- Revision, stale conflict ve gerçek no-op test edilir.
- Task/result/state olgusaldır.
- Draft PR → review → ready → kullanıcı onayı → squash merge akışı uygulanır.

Ayrıntılı checklist ve güncel durum için doğrudan GitHub Issue #127 ile #128–#140 kayıtları okunmalıdır.
