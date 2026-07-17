# Saha Pilotu Özet Şablonu

> Bu dosya boş 7/30 günlük summary şablonudur. Gerçek saha içeriği, source
> UUID, kişi/proje bilgisi, attachment ayrıntısı veya absolute path içermez.
> Doldurulmuş gerçek summary ancak ayrı pilot Issue'ın açık veri saklama ve
> paylaşım izniyle yönetilir.

Bağlayıcı protokol:
`docs/167_field_acceptance_metrics_and_pilot_protocol.md`

## A. Summary kimliği ve kapsam

| Alan | Değer |
|---|---|
| Pilot Issue | `<issue-number>` |
| Summary type | `<DAY_7 / DAY_30>` |
| Pilot window | `YYYY-MM-DD .. YYYY-MM-DD` |
| Exact build commit | `<40-char-commit-sha>` |
| Schema version | `<integer>` |
| Backup format version | `<integer>` |
| Takvim günü | `<7-or-30>` |
| Aktif gün | `<count>` |
| Inactive gün | `<count>` |
| Protocol version/reference | `<document-commit-or-path>` |
| Pilot gerçek data root üzerinde yürütüldü | `<yes / no>` — path yazmayın |

## B. Preflight sonucu

| Preflight gate | Sonuç | Kanıt notu |
|---|---|---|
| Pilot-ready build owner approval | `<PASS / FAIL>` | `<issue-or-sanitized-evidence>` |
| Exact build/schema | `<PASS / FAIL>` | `<sanitized>` |
| Data-root / disposable-target separation | `<PASS / FAIL>` | `<no-path>` |
| Backup create + verify | `<PASS / FAIL>` | `<operation-id>` |
| Restore rehearsal plan | `<PASS / FAIL>` | `<planned-day-or-N/A>` |
| Empty templates/privacy briefing | `<PASS / FAIL>` | `<sanitized>` |
| Stop authority understood | `<PASS / FAIL>` | `<sanitized>` |

## C. M01 — Kayıt açma özeti

| Segment | valid_n | success_n | failure_n | median_seconds | p90_seconds | failure_rate | low_sample |
|---|---:|---:|---:|---:|---:|---:|---|
| All | `<n>` | `<n>` | `<n>` | `<value>` | `<value>` | `<percent>` | `<yes/no>` |
| Follow-up | `<n>` | `<n>` | `<n>` | `<value-or-N/A>` | `<value-or-N/A>` | `<percent-or-N/A>` | `<yes/no>` |
| Observation | `<n>` | `<n>` | `<n>` | `<value-or-N/A>` | `<value-or-N/A>` | `<percent-or-N/A>` | `<yes/no>` |
| Routine action | `<n>` | `<n>` | `<n>` | `<value-or-N/A>` | `<value-or-N/A>` | `<percent-or-N/A>` | `<yes/no>` |

M01 target sonucu: `<PASS / WARNING / BLOCKER / INSUFFICIENT_EVIDENCE>`

## D. M02 — Geri bulma özeti

| Segment | valid_n | success_n | not_found_or_wrong_n | median_seconds | p90_seconds | success_rate | low_sample |
|---|---:|---:|---:|---:|---:|---:|---|
| All | `<n>` | `<n>` | `<n>` | `<value>` | `<value>` | `<percent>` | `<yes/no>` |
| Project | `<n>` | `<n>` | `<n>` | `<value-or-N/A>` | `<value-or-N/A>` | `<percent-or-N/A>` | `<yes/no>` |
| Type | `<n>` | `<n>` | `<n>` | `<value-or-N/A>` | `<value-or-N/A>` | `<percent-or-N/A>` | `<yes/no>` |
| Date | `<n>` | `<n>` | `<n>` | `<value-or-N/A>` | `<value-or-N/A>` | `<percent-or-N/A>` | `<yes/no>` |
| Open/closed | `<n>` | `<n>` | `<n>` | `<value-or-N/A>` | `<value-or-N/A>` | `<percent-or-N/A>` | `<yes/no>` |

M02 target sonucu: `<PASS / WARNING / BLOCKER / INSUFFICIENT_EVIDENCE>`

## E. Safety, reliability ve privacy metrikleri

| metric_id | numerator | denominator | rate | suspected | confirmed | target_result |
|---|---:|---:|---:|---:|---:|---|
| `M03_CONFIRMED_DATA_LOSS` | `<n>` | `<n>` | `<percent-or-N/A>` | `<n>` | `<n>` | `<PASS/WARNING/BLOCKER>` |
| `M04_MISSED_FOLLOW_UP` — critical | `<n>` | `<n>` | `<percent-or-N/A>` | `<n>` | `<n>` | `<PASS/WARNING/BLOCKER>` |
| `M04_MISSED_FOLLOW_UP` — normal | `<n>` | `<n>` | `<percent-or-N/A>` | `<n>` | `<n>` | `<PASS/WARNING/BLOCKER>` |
| `M05_ATTACHMENT_INTEGRITY_FAILURE` | `<n>` | `<n>` | `<percent-or-N/A>` | `<n>` | `<n>` | `<PASS/WARNING/BLOCKER/LOW_SAMPLE>` |
| `M09_SCOPE_PRIVACY_LEAK` | `<n>` | `<n>` | `<percent-or-N/A>` | `<n>` | `<n>` | `<PASS/WARNING/BLOCKER>` |

Safety event listesinde yalnız anonim incident ID bulunur:

| incident_id | metric_id | severity | evidence_status | containment | final_state |
|---|---|---|---|---|---|
| `<INC-ID>` | `<M03/M04/M05/M09>` | `<critical/normal>` | `<suspected/confirmed/disproved>` | `<sanitized>` | `<open/closed/revalidation-required>` |

## F. Backup ve Restore özeti

| metric_id | planned_n | attempted_n | pass_n | fail_n | pass_rate | gate_result |
|---|---:|---:|---:|---:|---:|---|
| `M06_BACKUP_VERIFY_PASS_RATE` | `<n>` | `<n>` | `<n>` | `<n>` | `<percent>` | `<PASS/WARNING/BLOCKER>` |
| `M07_CLEAN_RESTORE_PASS_RATE` | `<n>` | `<n>` | `<n>` | `<n>` | `<percent-or-N/A>` | `<PASS/WARNING/BLOCKER/N-A-FOR-DAY-7>` |

- En son doğrulanmış Backup freshness: `<hours-or-N/A>`
- Clean target separation confirmed: `<yes/no/N-A>`
- Repository reopen smoke: `<PASS/FAIL/NOT_RUN>`
- Attachment/history reconciliation: `<PASS/FAIL/NOT_RUN>`

Archive/source/target path ve hash yazmayın.

## G. M08 — Haricî araca dönüş özeti

| Alan | Değer |
|---|---:|
| Eligible work event | `<n>` |
| External fallback event | `<n>` |
| Fallback rate | `<percent-or-N/A>` |
| 7-day baseline | `<percent-or-N/A>` |
| Baseline farkı | `<percentage-points-or-N/A>` |
| Unsafe workaround count | `<n>` |

Reason dağılımı:

| rank | reason_code | count | rate | trend | product_decision |
|---:|---|---:|---:|---|---|
| 1 | `<allowed-code>` | `<n>` | `<percent>` | `<up/flat/down/N-A>` | `<fix/accept/defer>` |
| 2 | `<allowed-code>` | `<n>` | `<percent>` | `<up/flat/down/N-A>` | `<fix/accept/defer>` |
| 3 | `<allowed-code>` | `<n>` | `<percent>` | `<up/flat/down/N-A>` | `<fix/accept/defer>` |

Ham mesaj, konuşma veya gerçek not içeriği eklemeyin.

## H. M10 — Ölçüm bütünlüğü ve örnek yeterliliği

| Alan | Değer |
|---|---:|
| Beklenen zorunlu cell | `<n>` |
| Tamamlanan cell | `<n>` |
| Late entry | `<n>` |
| Missing/invalid | `<n>` |
| Completeness | `<percent>` |
| Safety etkili eksik | `<n>` |
| Capture valid sample | `<n>` |
| Retrieval valid sample | `<n>` |
| Active day | `<n>` |
| Minimum sample gate | `<PASS/FAIL>` |

Eksik veya yetersiz kanıt varsa sonuç `INSUFFICIENT_EVIDENCE`; değer tahmini
yapmayın.

## I. Haftalık trend — yalnız 30 günlük summary

| Hafta | active_days | capture_median | capture_p90 | retrieval_median | retrieval_p90 | fallback_rate | warnings | blockers |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| Week 1 | `<n>` | `<s>` | `<s>` | `<s>` | `<s>` | `<percent>` | `<n>` | `<n>` |
| Week 2 | `<n>` | `<s>` | `<s>` | `<s>` | `<s>` | `<percent>` | `<n>` | `<n>` |
| Week 3 | `<n>` | `<s>` | `<s>` | `<s>` | `<s>` | `<percent>` | `<n>` | `<n>` |
| Week 4/final days | `<n>` | `<s>` | `<s>` | `<s>` | `<s>` | `<percent>` | `<n>` | `<n>` |

Yoğun/normal gün karşılaştırması:

| Segment | capture_n | capture_median | retrieval_n | retrieval_median | fallback_rate | interpretation |
|---|---:|---:|---:|---:|---:|---|
| Normal | `<n>` | `<s>` | `<n>` | `<s>` | `<percent>` | `<sanitized-or-low-sample>` |
| Dense | `<n>` | `<s>` | `<n>` | `<s>` | `<percent>` | `<sanitized-or-low-sample>` |

## J. Warning ve düzeltme planları

| warning_id | metric_id | finding | owner | action | target_date | acceptance_check | status |
|---|---|---|---|---|---|---|---|
| `<WARN-ID>` | `<M01..M10>` | `<sanitized>` | `<owner>` | `<fix/accept/defer>` | `YYYY-MM-DD` | `<measurable-check>` | `<open/closed>` |

Performance warning için plan yazılabilir. Confirmed safety/privacy blocker bu
tabloyla PASS'e çevrilemez; ayrı revalidation window gerekir.

## K. Gate kararı

### Day 7 checklist

- [ ] Confirmed data loss `0`.
- [ ] Critical CSE-caused missed follow-up `0`.
- [ ] Confirmed attachment integrity failure `0`.
- [ ] Confirmed private/wrong-project leakage `0`.
- [ ] Gün 0 ve Gün 7 Backup verify PASS.
- [ ] M01/M02 minimum sample ve percentile hesapları mevcut.
- [ ] Açık safety blocker yok.
- [ ] M10 karar kanıtı yeterli.
- [ ] Warning planlarının sahibi/tarihi/acceptance'ı var.
- [ ] Pilot owner 30 günlük devam kararını açıkça verdi.

Day 7 sonucu:
`<PASS_TO_30_DAY / CONDITIONAL / FAIL / INSUFFICIENT_EVIDENCE>`

Owner continuation kararı: `<CONTINUE / DO_NOT_CONTINUE / NOT_DECIDED>`

### Day 30 checklist

- [ ] Confirmed data loss, leakage ve critical missed follow-up `0`.
- [ ] Confirmed attachment integrity failure `0`.
- [ ] Haftalık Backup verify `100% PASS`.
- [ ] En az bir clean restore rehearsal PASS.
- [ ] M01 target veya kabul edilmiş ölçülebilir revalidation planı.
- [ ] M02 target veya kabul edilmiş ölçülebilir revalidation planı.
- [ ] Fallback top-3 için `fix/accept/defer` kararı.
- [ ] Minimum sample ve ölçüm bütünlüğü PASS.
- [ ] Açık blocker yok.
- [ ] Faz 1 kararı pilot owner tarafından açıkça verildi.

Day 30 sonucu:
`<PASS / CONDITIONAL / FAIL / INSUFFICIENT_EVIDENCE>`

Faz 1 önerisi: `<PROCEED / DO_NOT_PROCEED / REVALIDATION_REQUIRED>`

## L. Gizlilik ve paylaşım kapanışı

- [ ] Gerçek kayıt/arama metni yok.
- [ ] Source UUID, kişi/proje bilgisi yok.
- [ ] Fotoğraf, dosya, screenshot, path veya hash yok.
- [ ] Ham haricî mesaj/konuşma yok.
- [ ] Absolute data-root/archive/restore path yok.
- [ ] Yalnız aggregate ölçüm, kategori ve anonim incident ID var.
- [ ] Summary'nin kimle ve hangi amaçla paylaşılacağı owner tarafından onaylandı.
- [ ] Retention/delete kararı ayrı pilot Issue politikasına uygun.

## M. Açık sınır

Bu şablonun repository'deki boş hali pilotun yürütüldüğünü, saha kabulünün
geçildiğini veya Faz 1'in onaylandığını göstermez. Yalnız gerçek ve ayrı pilot
Issue'ında toplanmış, privacy kontrolünden geçmiş kanıt gate kararı üretebilir.
