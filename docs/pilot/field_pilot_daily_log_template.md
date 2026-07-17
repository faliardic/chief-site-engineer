# Saha Pilotu Günlük Log Şablonu

> Bu dosya yalnız boş şablondur. Issue #167 gerçek pilot yürütmez. Doldurulmuş
> gerçek pilot logunu repository'ye commit etmeyin. Gerçek kayıt metni, source
> UUID, proje/kişi adı, fotoğraf, dosya adı/path/hash, screenshot veya ham mesaj
> eklemeyin.

Bağlayıcı protokol:
`docs/167_field_acceptance_metrics_and_pilot_protocol.md`

## A. Gün kimliği

| Alan | Değer |
|---|---|
| Pilot Issue | `<issue-number>` |
| Pilot window | `<7-day-or-30-day>` |
| pilot_day_id | `PILOT-D<NN>` |
| Takvim tarihi | `YYYY-MM-DD` |
| Gün numarası | `<01..07-or-01..30>` |
| Gün tipi | `<normal / dense / inactive>` |
| Aktif gün | `<yes / no>` |
| Exact build commit | `<40-char-commit-sha>` |
| Schema version | `<integer>` |
| Backup format version | `<integer>` |
| Beklenen data root doğrulandı | `<yes / no>` — path yazmayın |
| Açık stop/incident ile başlandı mı? | `<no / yes: INC-ID>` |

## B. Gün başlangıcı checklist

- [ ] Ayrı pilot Issue ve owner-approved pilot-ready build kanıtı mevcut.
- [ ] Exact build/schema kontrol edildi.
- [ ] Beklenen owner-controlled data root seçildi; disposable restore root ile
  karışmadı.
- [ ] Önceki açık incident ve stop durumu kontrol edildi.
- [ ] CSE ana/today/health yüzeyi erişilebilir.
- [ ] Kronometre veya açık timestamp yöntemi hazır.
- [ ] Bu şablona gerçek saha içeriği kopyalanmayacağı doğrulandı.

Başlangıç kararı: `<PROCEED / STOP / INACTIVE_DAY>`

Inactive day nedeni: `<no-eligible-work / planned-day-off / stop-active / other-sanitized / N/A>`

## C. M01 — Kayıt açma denemeleri

Günde ilk üç doğal eligible denemeyi yazın. Sayaç doldurmak için sahte source
kayıt üretmeyin.

| event_id | record_type_or_scenario | started_at_local | ended_at_local | duration_seconds | outcome | reason_code |
|---|---|---|---|---:|---|---|
| `EVT-D<NN>-<NNN>` | `<follow_up / observation / routine_action>` | `HH:MM:SS` | `HH:MM:SS` | `<integer>` | `<success / failed / abandoned / invalid_sample>` | `<code-or-N/A>` |
|  |  |  |  |  |  |  |
|  |  |  |  |  |  |  |

Günlük capture özeti:

| Alan | Değer |
|---|---:|
| Valid attempt | `<count>` |
| Success | `<count>` |
| Failure/abandoned | `<count>` |
| Invalid sample | `<count>` |

## D. M02 — Geri bulma denemeleri

Günde ilk iki doğal retrieval ihtiyacını yazın. Arama metni veya hedef kayıt
içeriğini yazmayın.

| event_id | scenario | started_at_local | ended_at_local | duration_seconds | outcome | reason_code |
|---|---|---|---|---:|---|---|
| `EVT-D<NN>-<NNN>` | `<project / type / date / open_closed>` | `HH:MM:SS` | `HH:MM:SS` | `<integer>` | `<success / not_found / wrong_record / abandoned / invalid_sample>` | `<code-or-N/A>` |
|  |  |  |  |  |  |  |

Günlük retrieval özeti:

| Alan | Değer |
|---|---:|
| Valid attempt | `<count>` |
| Success | `<count>` |
| Not found/wrong record | `<count>` |
| Invalid sample | `<count>` |

## E. M03 — Veri kaybı / corruption olayları

| event_or_incident_id | evidence_status | outcome_class | severity | stop_applied | sanitized_note |
|---|---|---|---|---|---|
| `<EVT-or-INC-ID>` | `<observed / suspected / confirmed / disproved>` | `<missing / corrupt / restore_mismatch / N/A>` | `<critical / normal>` | `<yes / no>` | `<no-content-note>` |

Bugün confirmed data loss count: `<integer>`

## F. M04 — Kaçırılan takip reconciliation

| Alan | Değer |
|---|---:|
| Due follow-up/routine action | `<count>` |
| Zamanında görünür ve işlenebilir | `<count>` |
| CSE kaynaklı normal missed | `<count>` |
| CSE kaynaklı critical missed | `<count>` |
| Hiç kaydedilmemiş iş | `<count>` |
| User-choice / diğer | `<count>` |

Olaylar:

| event_or_incident_id | severity | reason_code | evidence_status | stop_applied |
|---|---|---|---|---|
| `<EVT-or-INC-ID>` | `<critical / normal>` | `<not_recorded / user_choice / cse_visibility / cse_integrity / unknown>` | `<observed / suspected / confirmed / disproved>` | `<yes / no>` |

## G. M05 — Attachment / hash olayları

| Alan | Değer |
|---|---:|
| Bugün oluşturulan managed attachment | `<count>` |
| Doğrulanan attachment | `<count>` |
| Valid | `<count>` |
| Transient viewer/UI error | `<count>` |
| Confirmed integrity failure | `<count>` |

| event_or_incident_id | status_code | evidence_status | stop_applied |
|---|---|---|---|
| `<EVT-or-INC-ID>` | `<valid / viewer_transient / missing / hash_mismatch / size_mismatch / unsafe_path / orphan / unreadable>` | `<observed / suspected / confirmed / disproved>` | `<yes / no>` |

Dosya adı, path, hash veya içerik yazmayın.

## H. M06/M07 — Backup ve Restore

Bugün planlı değilse `N/A` yazın; PASS tahmin etmeyin.

| operation_id | operation | supported_version | started | result | target_separation_confirmed | sanitized_error_code |
|---|---|---|---|---|---|---|
| `<OP-D<NN>-<NNN>>` | `<backup_create / backup_verify / clean_restore / restore_smoke>` | `<version-or-N/A>` | `<yes / no>` | `<PASS / FAIL / NOT_RUN>` | `<yes / no / N/A>` | `<code-or-N/A>` |

Backup freshness: `<age-hours-or-N/A>`

Absolute source/archive/target path yazmayın.

## I. M08 — Kâğıt / haricî araç dönüşü

| event_id | external_tool_category | reason_code | late_report | safe_workaround |
|---|---|---|---|---|
| `EVT-D<NN>-<NNN>` | `<paper / self_message / notes_app / spreadsheet / other>` | `<speed / connectivity / ui_friction / missing_feature / trust / device_or_battery / document_viewing / habit / other_sanitized>` | `<yes / no>` | `<yes / no>` |

| Alan | Değer |
|---|---:|
| Eligible work event | `<count>` |
| External fallback event | `<count>` |
| Günlük fallback rate | `<percent-or-N/A>` |

Ham mesaj, konuşma veya gerçek not içeriği yazmayın.

## J. M09 — Scope/privacy artifact kontrolü

| artifact_event_id | artifact_family | eligibility_evidence | leakage_result | shared | stop_applied |
|---|---|---|---|---|---|
| `<EVT-ID>` | `<daily_export / future_project_package / other-approved>` | `<complete / uncertain>` | `<PASS / SUSPECTED / CONFIRMED_LEAK>` | `<yes / no>` | `<yes / no>` |

İncelenen artifact count: `<integer>`
Confirmed private/wrong-project leakage count: `<integer>`

Artifact payload veya source kimliği yazmayın. Eligibility belirsizse
artifact'ı paylaşmayın.

## K. M10 — Ölçüm bütünlüğü

| Alan | Değer |
|---|---:|
| Beklenen zorunlu metric cell | `<count>` |
| Zamanında tamamlanan cell | `<count>` |
| Late entry | `<count>` |
| Missing/invalid cell | `<count>` |
| Completeness | `<percent>` |
| Safety kararını etkileyen eksik | `<count>` |

Eksik alanları gerçek içerik kopyalayarak veya tahmin ederek doldurmayın.

## L. Warning, blocker ve incident listesi

| id | type | metric_id | evidence_status | owner_action | target_date | pilot_state |
|---|---|---|---|---|---|---|
| `<WARN-or-INC-ID>` | `<warning / blocker>` | `<M01..M10>` | `<observed / suspected / confirmed / disproved>` | `<sanitized-action>` | `YYYY-MM-DD` | `<running / stopped / resume-approved>` |

## M. Gün sonu değerlendirmesi

- Bugünün en önemli sanitize edilmiş sürtünme kodu: `<reason-code-or-N/A>`
- Gerçek içerik içermeyen kısa değerlendirme: `<max-2-sentences>`
- Açık safety şüphesi: `<none / INC-ID>`
- Due reconciliation tamamlandı: `<yes / no>`
- Attachment reconciliation tamamlandı: `<yes / no / N/A>`
- Ölçüm checklist tamamlandı: `<yes / no>`
- Ertesi gün kararı: `<CONTINUE / STOP / INACTIVE>`
- Kararı veren pilot owner: `<owner-confirmed / not-confirmed>`

## N. Gizlilik kapanış checklist

- [ ] Gerçek kayıt gövdesi veya arama metni yok.
- [ ] Source UUID, gerçek project/person bilgisi yok.
- [ ] Fotoğraf, dosya, screenshot, dosya adı/path/hash yok.
- [ ] Ham haricî mesaj/konuşma yok.
- [ ] Absolute data-root/archive/restore path yok.
- [ ] Yalnız anonim kimlik, sayaç, süre, kategori ve sonuç var.
- [ ] Doldurulmuş gerçek log repository/GitHub'a eklenmedi.
