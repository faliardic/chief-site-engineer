"""Server-rendered local field interface."""

from collections.abc import Mapping
from datetime import datetime
from pathlib import Path
from uuid import uuid4

from flask import (
    Flask,
    Response,
    abort,
    g,
    has_request_context,
    redirect,
    render_template,
    request,
    jsonify,
    stream_with_context,
    url_for,
    send_file,
)
from werkzeug.utils import secure_filename

from app.application import (
    ApplicationServiceError,
    CloseRoutineOccurrence,
    CompleteFollowUp,
    CreateFollowUp,
    CreateObservation,
    CreateRoutineTemplate,
    FollowUpApplicationService,
    FollowUpQuery,
    FollowUpView,
    MarkWaiting,
    ObservationApplicationService,
    RoutineApplicationService,
    RoutineOccurrenceQuery,
    RoutineOccurrenceView,
    RoutineTemplateQuery,
    ScheduleFollowUp,
    UpdateFollowUp,
    UploadStream,
)
from app.field_tracking import (
    FollowUpItem,
    FollowUpItemType,
    FollowUpOutcome,
    FollowUpStatus,
    RoutineOccurrence,
    RoutineOccurrenceOutcome,
    RoutineOccurrenceStatus,
    RoutineRecurrenceType,
    RoutineTemplate,
    RoutineTemplateStatus,
)
from app.launcher.contracts import (
    APPLICATION_ID,
    APPLICATION_VERSION,
    instance_id_for_data_root,
)
from app.persistence import (
    ArchivedRecordError,
    PersistenceError,
    RecordNotFound,
    RevisionConflict,
    validate_record_id,
    validate_utc_timestamp,
)
from app.operations import BackupService, DailyExportService
from app.storage import ManagedAttachmentStore
from app.storage.paths import validate_canonical_uuid
from app.time_contracts import (
    ISTANBUL_TIMEZONE,
    UTC,
    format_istanbul_timestamp,
    serialize_utc_timestamp,
    to_istanbul,
    utc_now,
)


MAX_UPLOAD_BYTES = 25 * 1024 * 1024
MAX_SEARCH_QUERY_LENGTH = 200
BACKUP_ERROR_MESSAGE = (
    "Yedek oluşturulamadı. Veri ve dosya bütünlüğünü kontrol edip yeniden deneyin."
)
SAFE_PREVIEW_MIME_TYPES = frozenset(
    {"image/gif", "image/jpeg", "image/png", "image/webp"}
)
STATUS_LABELS = {
    "open": "Açık",
    "tracking": "Takipte",
    "closed": "Kapalı",
}
INTEGRITY_LABELS = {
    "valid": "Dosya doğrulandı",
    "missing": "Dosya bulunamadı",
    "corrupt": "Dosya bütünlüğü doğrulanamadı",
    "mismatch": "Dosya bütünlüğü doğrulanamadı",
    "hash_mismatch": "Dosya bütünlüğü doğrulanamadı",
    "size_mismatch": "Dosya bütünlüğü doğrulanamadı",
    "unsafe_path": "Dosya güvenliği doğrulanamadı",
}
EVENT_LABELS = {
    "observation_created": "Gözlem oluşturuldu",
    "observation_details_updated": "Gözlem bilgileri güncellendi",
    "observation_status_changed": "Durum güncellendi",
    "observation_reporting_updated": "Bildirim bilgisi güncellendi",
    "observation_archived": "Gözlem arşivlendi",
}
FOLLOW_UP_STATUS_LABELS = {
    "inbox": "Unutma Kutusu",
    "active": "Aktif",
    "waiting": "Beklemede",
    "completed": "Tamamlandı",
    "cancelled": "İptal edildi",
}
FOLLOW_UP_TYPE_LABELS = {
    "action": "Yapılacak",
    "waiting": "Dönüş bekleniyor",
    "recheck": "Tekrar kontrol",
}
FOLLOW_UP_OUTCOME_LABELS = {
    "completed": "Yapıldı",
    "not_required": "Artık gerekli değil",
    "converted_to_observation": "Resmî gözleme dönüştürüldü",
    "cancelled": "İptal edildi",
}
FOLLOW_UP_EVENT_LABELS = {
    "follow_up.created": "Takip yakalandı",
    "follow_up.scheduled": "Takip planlandı",
    "follow_up.rescheduled": "Takip yeniden planlandı",
    "follow_up.waiting_started": "Beklemeye alındı",
    "follow_up.completed": "Takip tamamlandı",
    "follow_up.cancelled": "Takip iptal edildi",
    "follow_up.reopened": "Takip yeniden açıldı",
    "follow_up.observation_linked": "Gözleme bağlandı",
    "follow_up.converted_to_observation": "Resmî gözleme dönüştürüldü",
    "follow_up.details_updated": "Takip ayrıntıları güncellendi",
    "follow_up.moved_to_inbox": "Unutma Kutusu'na taşındı",
    "follow_up.project_changed": "Proje bağlantısı değişti",
}
ROUTINE_RECURRENCE_LABELS = {
    "daily": "Her gün",
    "weekdays": "Her iş günü",
    "weekly": "Haftanın seçili günleri",
    "monthly": "Ayın belirli günü",
}
ROUTINE_TEMPLATE_STATUS_LABELS = {
    "active": "Aktif",
    "inactive": "Pasif",
}
ROUTINE_OCCURRENCE_STATUS_LABELS = {
    "open": "Açık",
    "closed": "Sonuçlandı",
}
ROUTINE_OUTCOME_LABELS = {
    "completed": "Tamamlandı",
    "no_work": "Çalışma yoktu",
    "not_required": "Gerekli değildi",
    "missed": "Eksik kaldı",
}
ROUTINE_EVENT_LABELS = {
    "routine_template.created": "Rutin oluşturuldu",
    "routine_template.updated": "Rutin güncellendi",
    "routine_template.deactivated": "Rutin pasifleştirildi",
    "routine_occurrence.created": "Günlük gerçekleşme oluşturuldu",
    "routine_occurrence.snoozed": "Gerçekleşme ertelendi",
    "routine_occurrence.completed": "Gerçekleşme tamamlandı",
    "routine_occurrence.no_work": "Çalışma yok sonucu verildi",
    "routine_occurrence.not_required": "Gerekli değil sonucu verildi",
    "routine_occurrence.missed": "Eksik kaldı sonucu verildi",
    "routine_occurrence.reopened": "Gerçekleşme yeniden açıldı",
}
ISO_WEEKDAY_LABELS = {
    1: "Pazartesi",
    2: "Salı",
    3: "Çarşamba",
    4: "Perşembe",
    5: "Cuma",
    6: "Cumartesi",
    7: "Pazar",
}
SAVED_MESSAGES = {
    "created": "Kayıt Unutma Kutusu'na eklendi.",
    "details": "Takip ayrıntıları kaydedildi.",
    "project": "Proje bağlantısı kaydedildi.",
    "scheduled": "Takip planlandı.",
    "waiting": "Takip beklemeye alındı.",
    "inbox": "Takip Unutma Kutusu'na taşındı.",
    "completed": "Takip sonuçlandırıldı.",
    "cancelled": "Takip iptal edildi.",
    "reopened": "Takip yeniden açıldı.",
    "routine_created": "Rutin oluşturuldu.",
    "routine_deactivated": "Rutin pasifleştirildi.",
    "occurrence_snoozed": "Rutin gerçekleşmesi ertelendi.",
    "occurrence_closed": "Rutin gerçekleşmesi sonuçlandırıldı.",
    "occurrence_reopened": "Rutin gerçekleşmesi yeniden açıldı.",
}


def status_label(value: str) -> str:
    """Return a Turkish presentation label without changing stored values."""

    return STATUS_LABELS.get(value, "Durum bilgisi kullanılamıyor")


def integrity_label(value: str) -> str:
    """Return a safe Turkish attachment-integrity label."""

    return INTEGRITY_LABELS.get(value, "Dosya bütünlüğü doğrulanamadı")


def event_label(value: str) -> str:
    """Return a Turkish event label with a non-technical fallback."""

    return EVENT_LABELS.get(value, "Gözlem kaydı güncellendi")


def follow_up_status_label(value: object) -> str:
    return FOLLOW_UP_STATUS_LABELS.get(
        _enum_value(value), "Takip durumu kullanılamıyor"
    )


def follow_up_type_label(value: object) -> str:
    return FOLLOW_UP_TYPE_LABELS.get(
        _enum_value(value), "Takip türü kullanılamıyor"
    )


def follow_up_outcome_label(value: object) -> str:
    if value is None:
        return "-"
    return FOLLOW_UP_OUTCOME_LABELS.get(
        _enum_value(value), "Sonuç bilgisi kullanılamıyor"
    )


def follow_up_event_label(value: object) -> str:
    return FOLLOW_UP_EVENT_LABELS.get(
        _enum_value(value), "Takip kaydı güncellendi"
    )


def routine_recurrence_label(value: object) -> str:
    return ROUTINE_RECURRENCE_LABELS.get(
        _enum_value(value), "Tekrar bilgisi kullanılamıyor"
    )


def routine_template_status_label(value: object) -> str:
    return ROUTINE_TEMPLATE_STATUS_LABELS.get(
        _enum_value(value), "Rutin durumu kullanılamıyor"
    )


def routine_occurrence_status_label(value: object) -> str:
    return ROUTINE_OCCURRENCE_STATUS_LABELS.get(
        _enum_value(value), "Gerçekleşme durumu kullanılamıyor"
    )


def routine_outcome_label(value: object) -> str:
    if value is None:
        return "-"
    return ROUTINE_OUTCOME_LABELS.get(
        _enum_value(value), "Sonuç bilgisi kullanılamıyor"
    )


def routine_event_label(value: object) -> str:
    return ROUTINE_EVENT_LABELS.get(
        _enum_value(value), "Rutin kaydı güncellendi"
    )


def routine_recurrence_summary(template: RoutineTemplate) -> str:
    label = routine_recurrence_label(template.recurrence_type)
    if template.recurrence_type == RoutineRecurrenceType.WEEKLY:
        days = ", ".join(
            ISO_WEEKDAY_LABELS[weekday] for weekday in sorted(template.weekdays)
        )
        return f"{label}: {days}"
    if template.recurrence_type == RoutineRecurrenceType.MONTHLY:
        return f"Her ayın {template.month_day}. günü"
    return label


def event_payload_summary(payload: Mapping[str, object]) -> tuple[str, ...]:
    """Return a small human-readable event summary instead of raw JSON."""

    summary: list[str] = []
    revision = payload.get("revision")
    if isinstance(revision, int):
        summary.append(f"Revizyon {revision}")
    changed_fields = payload.get("changed_fields")
    if isinstance(changed_fields, (list, tuple)):
        field_labels = {
            "condition_text": "koşul",
            "deadline_at": "son tarih",
            "description": "açıklama",
            "is_important": "önem",
            "item_type": "tür",
            "local_time": "saat",
            "location": "konum",
            "month_day": "ayın günü",
            "project_id": "proje",
            "recurrence_type": "tekrar",
            "related_person": "ilgili kişi",
            "start_date": "başlangıç",
            "end_date": "bitiş",
            "title": "başlık",
            "weekdays": "hafta günleri",
        }
        readable = [
            field_labels[field]
            for field in changed_fields
            if isinstance(field, str) and field in field_labels
        ]
        if readable:
            summary.append("Değişen alanlar: " + ", ".join(readable))
    status = payload.get("status")
    if isinstance(status, str):
        status_text = FOLLOW_UP_STATUS_LABELS.get(status)
        status_text = status_text or ROUTINE_TEMPLATE_STATUS_LABELS.get(status)
        status_text = status_text or ROUTINE_OCCURRENCE_STATUS_LABELS.get(status)
        if status_text:
            summary.append(f"Durum: {status_text}")
    outcome = payload.get("outcome_type")
    if isinstance(outcome, str):
        outcome_text = FOLLOW_UP_OUTCOME_LABELS.get(outcome)
        outcome_text = outcome_text or ROUTINE_OUTCOME_LABELS.get(outcome)
        if outcome_text:
            summary.append(f"Sonuç: {outcome_text}")
    attention = payload.get("next_attention_at")
    if isinstance(attention, str):
        summary.append(f"Dikkat zamanı: {utc_to_istanbul_display(attention)}")
    return tuple(summary)


def _enum_value(value: object) -> str:
    raw = getattr(value, "value", value)
    return raw if isinstance(raw, str) else ""


def utc_to_istanbul_display(value: str | None) -> str:
    """Format a stored UTC timestamp for the Europe/Istanbul user surface."""

    if not value:
        return "-"
    try:
        return format_istanbul_timestamp(value, "%d.%m.%Y %H:%M")
    except (TypeError, ValueError):
        return "Zaman bilgisi kullanılamıyor"


def utc_to_istanbul_input(value: str | None) -> str:
    """Format a stored UTC timestamp for an HTML datetime-local input."""

    if not value:
        return ""
    try:
        return format_istanbul_timestamp(value, "%Y-%m-%dT%H:%M")
    except (TypeError, ValueError):
        return ""


def is_safe_image_preview(mime_type: str | None) -> bool:
    """Allow inline previews only for a small passive raster-image set."""

    return mime_type in SAFE_PREVIEW_MIME_TYPES


def istanbul_datetime_local_to_utc(value: str) -> str:
    """Interpret an HTML datetime-local value in Europe/Istanbul."""

    try:
        local = datetime.strptime(value, "%Y-%m-%dT%H:%M").replace(
            tzinfo=ISTANBUL_TIMEZONE
        )
    except (TypeError, ValueError) as exc:
        raise ValueError("Bildirim zamanı geçersiz.") from exc
    return serialize_utc_timestamp(local)


def local_date_display(value: str | None) -> str:
    if not value:
        return "-"
    try:
        return datetime.strptime(value, "%Y-%m-%d").strftime("%d.%m.%Y")
    except (TypeError, ValueError):
        return "Tarih bilgisi kullanılamıyor"


def _utc_now() -> str:
    return utc_now()


def create_app(data_root: str | Path) -> Flask:
    """Create an app bound to one explicit, reusable data root."""

    root = Path(data_root).resolve()
    root.mkdir(parents=True, exist_ok=True)
    app = Flask(__name__)
    app.config.update(
        MAX_CONTENT_LENGTH=MAX_UPLOAD_BYTES,
        CSE_DATA_ROOT=root,
        CSE_INSTANCE_ID=instance_id_for_data_root(root),
        CSE_NOW_UTC_FACTORY=_utc_now,
        CSE_FOLLOW_UP_ID_FACTORY=lambda: str(uuid4()),
        CSE_ROUTINE_ID_FACTORY=lambda: str(uuid4()),
        CSE_EXPORT_SERVICE=DailyExportService(root),
        CSE_BACKUP_SERVICE=BackupService(root),
        CSE_BACKUP_ID_FACTORY=lambda: str(uuid4()),
    )

    def configured_now_utc() -> str:
        request_value = (
            getattr(g, "cse_now_utc", None) if has_request_context() else None
        )
        value = request_value or str(app.config["CSE_NOW_UTC_FACTORY"]())
        validate_utc_timestamp(value)
        return value

    app.config.update(
        CSE_SERVICE=ObservationApplicationService(
            root / "cse.sqlite3",
            ManagedAttachmentStore(root / "attachments"),
        ),
        CSE_FOLLOW_UP_SERVICE=FollowUpApplicationService(
            root / "cse.sqlite3",
            clock=configured_now_utc,
            uuid_factory=lambda: str(app.config["CSE_FOLLOW_UP_ID_FACTORY"]()),
        ),
        CSE_ROUTINE_SERVICE=RoutineApplicationService(
            root / "cse.sqlite3",
            clock=configured_now_utc,
            uuid_factory=lambda: str(app.config["CSE_ROUTINE_ID_FACTORY"]()),
        ),
    )
    app.jinja_env.globals.update(
        event_label=event_label,
        event_payload_summary=event_payload_summary,
        follow_up_event_label=follow_up_event_label,
        follow_up_outcome_label=follow_up_outcome_label,
        follow_up_status_label=follow_up_status_label,
        follow_up_type_label=follow_up_type_label,
        integrity_label=integrity_label,
        iso_weekday_labels=ISO_WEEKDAY_LABELS,
        is_safe_image_preview=is_safe_image_preview,
        local_date_display=local_date_display,
        routine_event_label=routine_event_label,
        routine_occurrence_status_label=routine_occurrence_status_label,
        routine_outcome_label=routine_outcome_label,
        routine_recurrence_label=routine_recurrence_label,
        routine_recurrence_summary=routine_recurrence_summary,
        routine_template_status_label=routine_template_status_label,
        status_label=status_label,
        utc_to_istanbul_display=utc_to_istanbul_display,
        utc_to_istanbul_input=utc_to_istanbul_input,
    )

    def service() -> ObservationApplicationService:
        return app.config["CSE_SERVICE"]

    def follow_up_service() -> FollowUpApplicationService:
        return app.config["CSE_FOLLOW_UP_SERVICE"]

    def routine_service() -> RoutineApplicationService:
        return app.config["CSE_ROUTINE_SERVICE"]

    @app.get("/")
    def index() -> Response:
        return redirect(url_for("today"))

    @app.get("/health")
    def health() -> Response:
        return jsonify(
            application=APPLICATION_ID,
            instance_id=app.config["CSE_INSTANCE_ID"],
            ready=True,
            version=APPLICATION_VERSION,
        )

    def project_context() -> tuple[list[object], dict[str, str]]:
        projects = service().list_projects()
        return projects, {
            project.project_id: project.name for project in projects
        }

    def render_today_page(
        *, error: str | None = None, capture_text: str = ""
    ) -> str:
        now_utc = configured_now_utc()
        g.cse_now_utc = now_utc
        routine_service().ensure_occurrences(now_utc)
        projects, project_names = project_context()
        templates = routine_service().list_templates(RoutineTemplateQuery())
        return render_template(
            "today.html",
            now_utc=now_utc,
            now_follow_ups=follow_up_service().list_follow_ups(
                FollowUpQuery(view=FollowUpView.NOW, as_of_utc=now_utc)
            ),
            overdue_follow_ups=follow_up_service().list_follow_ups(
                FollowUpQuery(view=FollowUpView.OVERDUE, as_of_utc=now_utc)
            ),
            today_follow_ups=follow_up_service().list_follow_ups(
                FollowUpQuery(view=FollowUpView.TODAY, as_of_utc=now_utc)
            ),
            overdue_occurrences=routine_service().list_occurrences(
                RoutineOccurrenceQuery(
                    view=RoutineOccurrenceView.OVERDUE,
                    as_of_utc=now_utc,
                )
            ),
            today_occurrences=routine_service().list_occurrences(
                RoutineOccurrenceQuery(
                    view=RoutineOccurrenceView.TODAY,
                    as_of_utc=now_utc,
                )
            ),
            project_names=project_names,
            template_names={
                template.routine_template_id: template.title
                for template in templates
            },
            capture_text=capture_text,
            error=error,
            success=SAVED_MESSAGES.get(request.args.get("saved", "")),
        )

    def render_follow_up_inbox(
        *, error: str | None = None, capture_text: str = ""
    ) -> str:
        projects, project_names = project_context()
        del projects
        return render_template(
            "follow_ups/inbox.html",
            follow_ups=follow_up_service().list_follow_ups(
                FollowUpQuery(view=FollowUpView.INBOX)
            ),
            project_names=project_names,
            capture_text=capture_text,
            error=error,
            success=SAVED_MESSAGES.get(request.args.get("saved", "")),
        )

    def render_follow_up_detail(
        follow_up_id: str,
        *,
        error: str | None = None,
        form_values: Mapping[str, str] | None = None,
    ) -> str:
        try:
            item = follow_up_service().get_follow_up(follow_up_id)
            history = follow_up_service().list_history(follow_up_id)
        except (RecordNotFound, ValueError):
            abort(404)
        projects, project_names = project_context()
        return render_template(
            "follow_ups/detail.html",
            item=item,
            history=history,
            projects=projects,
            project_names=project_names,
            error=error,
            form_values=form_values or {},
            success=SAVED_MESSAGES.get(request.args.get("saved", "")),
        )

    def find_occurrence(routine_occurrence_id: str) -> RoutineOccurrence:
        validate_record_id(routine_occurrence_id)
        for occurrence in routine_service().list_occurrences(
            RoutineOccurrenceQuery()
        ):
            if occurrence.routine_occurrence_id == routine_occurrence_id:
                return occurrence
        raise RecordNotFound("routine occurrence", routine_occurrence_id)

    def render_routine_detail(
        routine_template_id: str,
        *,
        error: str | None = None,
        form_values: Mapping[str, str] | None = None,
    ) -> str:
        try:
            template = routine_service().get_template(routine_template_id)
            history = routine_service().list_template_history(
                routine_template_id
            )
            occurrences = routine_service().list_occurrences(
                RoutineOccurrenceQuery(
                    routine_template_id=routine_template_id
                )
            )
        except (RecordNotFound, ValueError):
            abort(404)
        projects, project_names = project_context()
        del projects
        return render_template(
            "routines/detail.html",
            template=template,
            history=history,
            occurrences=occurrences,
            project_names=project_names,
            error=error,
            form_values=form_values or {},
            success=SAVED_MESSAGES.get(request.args.get("saved", "")),
        )

    def expected_revision() -> int:
        raw = request.form.get("expected_revision", "")
        try:
            value = int(raw)
        except (TypeError, ValueError) as exc:
            raise ValueError("Revizyon bilgisi geçersiz.") from exc
        if value < 1:
            raise ValueError("Revizyon bilgisi geçersiz.")
        return value

    def checkbox_value(name: str) -> bool:
        raw = request.form.get(name)
        if raw is None:
            return False
        if raw != "1":
            raise ValueError(f"{name} geçersiz")
        return True

    def optional_local_datetime(value: str | None) -> str | None:
        if value is None or not value.strip():
            return None
        return istanbul_datetime_local_to_utc(value)

    def follow_up_error_response(
        follow_up_id: str, error: Exception
    ) -> tuple[str, int]:
        if isinstance(error, RecordNotFound):
            abort(404)
        if isinstance(error, RevisionConflict):
            return (
                render_follow_up_detail(
                    follow_up_id,
                    error=(
                        "Kayıt başka bir işlem tarafından güncellendi. "
                        "Devam etmeden önce sayfayı yenileyin."
                    ),
                    form_values=request.form,
                ),
                409,
            )
        return (
            render_follow_up_detail(
                follow_up_id,
                error=_tracking_error_message(error),
                form_values=request.form,
            ),
            400,
        )

    @app.get("/today")
    def today() -> str:
        return render_today_page()

    @app.post("/follow-ups")
    def follow_up_create() -> Response | tuple[str, int]:
        capture_text = request.form.get("capture_text", "")
        return_to = request.form.get("return_to", "inbox")
        try:
            item = follow_up_service().create_follow_up(
                CreateFollowUp(capture_text)
            )
        except (PersistenceError, ValueError) as exc:
            renderer = (
                render_today_page
                if return_to == "today"
                else render_follow_up_inbox
            )
            return (
                renderer(
                    error=_tracking_error_message(exc),
                    capture_text=capture_text,
                ),
                400,
            )
        return redirect(
            url_for(
                "follow_up_detail",
                follow_up_id=item.follow_up_id,
                saved="created",
            )
        )

    @app.get("/follow-ups/inbox")
    def follow_up_inbox() -> str:
        return render_follow_up_inbox()

    @app.get("/follow-ups/<follow_up_id>")
    def follow_up_detail(follow_up_id: str) -> str:
        return render_follow_up_detail(follow_up_id)

    @app.post("/follow-ups/<follow_up_id>/details")
    def follow_up_details(follow_up_id: str) -> Response | tuple[str, int]:
        try:
            follow_up_service().update_details(
                follow_up_id,
                expected_revision(),
                UpdateFollowUp(
                    title=request.form.get("title", ""),
                    description=request.form.get("description") or None,
                    item_type=FollowUpItemType(
                        request.form.get("item_type", "")
                    ),
                    location=request.form.get("location") or None,
                    related_person=request.form.get("related_person") or None,
                    is_important=checkbox_value("is_important"),
                    condition_text=request.form.get("condition_text") or None,
                    deadline_at=optional_local_datetime(
                        request.form.get("deadline_at")
                    ),
                ),
            )
        except (PersistenceError, ValueError) as exc:
            return follow_up_error_response(follow_up_id, exc)
        return redirect(
            url_for(
                "follow_up_detail",
                follow_up_id=follow_up_id,
                saved="details",
            )
        )

    @app.post("/follow-ups/<follow_up_id>/project")
    def follow_up_project(follow_up_id: str) -> Response | tuple[str, int]:
        try:
            follow_up_service().set_project(
                follow_up_id,
                expected_revision(),
                request.form.get("project_id") or None,
            )
        except (PersistenceError, ValueError) as exc:
            return follow_up_error_response(follow_up_id, exc)
        return redirect(
            url_for(
                "follow_up_detail",
                follow_up_id=follow_up_id,
                saved="project",
            )
        )

    @app.post("/follow-ups/<follow_up_id>/schedule")
    def follow_up_schedule(follow_up_id: str) -> Response | tuple[str, int]:
        try:
            follow_up_service().schedule(
                follow_up_id,
                expected_revision(),
                ScheduleFollowUp(
                    istanbul_datetime_local_to_utc(
                        request.form.get("next_attention_at", "")
                    ),
                    FollowUpStatus(request.form.get("target_status", "")),
                ),
            )
        except (PersistenceError, ValueError) as exc:
            return follow_up_error_response(follow_up_id, exc)
        return redirect(
            url_for(
                "follow_up_detail",
                follow_up_id=follow_up_id,
                saved="scheduled",
            )
        )

    @app.post("/follow-ups/<follow_up_id>/waiting")
    def follow_up_waiting(follow_up_id: str) -> Response | tuple[str, int]:
        try:
            follow_up_service().mark_waiting(
                follow_up_id,
                expected_revision(),
                MarkWaiting(
                    istanbul_datetime_local_to_utc(
                        request.form.get("next_attention_at", "")
                    ),
                    request.form.get("related_person") or None,
                    request.form.get("condition_text") or None,
                ),
            )
        except (PersistenceError, ValueError) as exc:
            return follow_up_error_response(follow_up_id, exc)
        return redirect(
            url_for(
                "follow_up_detail",
                follow_up_id=follow_up_id,
                saved="waiting",
            )
        )

    @app.post("/follow-ups/<follow_up_id>/move-to-inbox")
    def follow_up_move_to_inbox(
        follow_up_id: str,
    ) -> Response | tuple[str, int]:
        try:
            follow_up_service().move_to_inbox(
                follow_up_id, expected_revision()
            )
        except (PersistenceError, ValueError) as exc:
            return follow_up_error_response(follow_up_id, exc)
        return redirect(
            url_for(
                "follow_up_detail",
                follow_up_id=follow_up_id,
                saved="inbox",
            )
        )

    @app.post("/follow-ups/<follow_up_id>/complete")
    def follow_up_complete(follow_up_id: str) -> Response | tuple[str, int]:
        try:
            follow_up_service().complete(
                follow_up_id,
                expected_revision(),
                CompleteFollowUp(
                    FollowUpOutcome(request.form.get("outcome_type", "")),
                    request.form.get("outcome_note") or None,
                ),
            )
        except (PersistenceError, ValueError) as exc:
            return follow_up_error_response(follow_up_id, exc)
        return redirect(
            url_for(
                "follow_up_detail",
                follow_up_id=follow_up_id,
                saved="completed",
            )
        )

    @app.post("/follow-ups/<follow_up_id>/cancel")
    def follow_up_cancel(follow_up_id: str) -> Response | tuple[str, int]:
        try:
            follow_up_service().cancel(
                follow_up_id,
                expected_revision(),
                request.form.get("outcome_note") or None,
            )
        except (PersistenceError, ValueError) as exc:
            return follow_up_error_response(follow_up_id, exc)
        return redirect(
            url_for(
                "follow_up_detail",
                follow_up_id=follow_up_id,
                saved="cancelled",
            )
        )

    @app.post("/follow-ups/<follow_up_id>/reopen")
    def follow_up_reopen(follow_up_id: str) -> Response | tuple[str, int]:
        try:
            follow_up_service().reopen(
                follow_up_id,
                expected_revision(),
                optional_local_datetime(request.form.get("next_attention_at")),
            )
        except (PersistenceError, ValueError) as exc:
            return follow_up_error_response(follow_up_id, exc)
        return redirect(
            url_for(
                "follow_up_detail",
                follow_up_id=follow_up_id,
                saved="reopened",
            )
        )

    @app.get("/routines")
    def routine_list() -> str:
        templates = routine_service().list_templates(RoutineTemplateQuery())
        projects, project_names = project_context()
        del projects
        return render_template(
            "routines/list.html",
            templates=templates,
            project_names=project_names,
            error=None,
            success=SAVED_MESSAGES.get(request.args.get("saved", "")),
        )

    @app.route("/routines/new", methods=["GET", "POST"])
    def routine_new() -> str | Response | tuple[str, int]:
        projects, _project_names = project_context()
        if request.method == "GET":
            now_utc = configured_now_utc()
            start_date = to_istanbul(now_utc).date().isoformat()
            return render_template(
                "routines/new.html",
                projects=projects,
                form_values={"start_date": start_date},
                selected_weekdays=(),
                error=None,
            )

        form_values = request.form
        selected_weekdays = tuple(request.form.getlist("weekdays"))
        try:
            weekdays = frozenset(int(value) for value in selected_weekdays)
            raw_month_day = request.form.get("month_day", "").strip()
            template = routine_service().create_template(
                CreateRoutineTemplate(
                    title=request.form.get("title", ""),
                    description=request.form.get("description") or None,
                    project_id=request.form.get("project_id") or None,
                    recurrence_type=RoutineRecurrenceType(
                        request.form.get("recurrence_type", "")
                    ),
                    local_time=request.form.get("local_time", ""),
                    start_date=request.form.get("start_date", ""),
                    end_date=request.form.get("end_date") or None,
                    weekdays=weekdays,
                    month_day=int(raw_month_day) if raw_month_day else None,
                    is_important=checkbox_value("is_important"),
                )
            )
        except (PersistenceError, ValueError) as exc:
            return (
                render_template(
                    "routines/new.html",
                    projects=projects,
                    form_values=form_values,
                    selected_weekdays=selected_weekdays,
                    error=_tracking_error_message(exc),
                ),
                400,
            )
        return redirect(
            url_for(
                "routine_detail",
                routine_template_id=template.routine_template_id,
                saved="routine_created",
            )
        )

    @app.get("/routines/<routine_template_id>")
    def routine_detail(routine_template_id: str) -> str:
        return render_routine_detail(routine_template_id)

    @app.post("/routines/<routine_template_id>/deactivate")
    def routine_deactivate(
        routine_template_id: str,
    ) -> Response | tuple[str, int]:
        try:
            routine_service().deactivate_template(
                routine_template_id, expected_revision()
            )
        except RecordNotFound:
            abort(404)
        except RevisionConflict:
            return (
                render_routine_detail(
                    routine_template_id,
                    error=(
                        "Kayıt başka bir işlem tarafından güncellendi. "
                        "Devam etmeden önce sayfayı yenileyin."
                    ),
                    form_values=request.form,
                ),
                409,
            )
        except (PersistenceError, ValueError) as exc:
            return (
                render_routine_detail(
                    routine_template_id,
                    error=_tracking_error_message(exc),
                    form_values=request.form,
                ),
                400,
            )
        return redirect(
            url_for(
                "routine_detail",
                routine_template_id=routine_template_id,
                saved="routine_deactivated",
            )
        )

    def occurrence_error_response(
        occurrence: RoutineOccurrence, error: Exception
    ) -> tuple[str, int]:
        if isinstance(error, RevisionConflict):
            message = (
                "Kayıt başka bir işlem tarafından güncellendi. "
                "Devam etmeden önce sayfayı yenileyin."
            )
            status = 409
        else:
            message = _tracking_error_message(error)
            status = 400
        return (
            render_routine_detail(
                occurrence.routine_template_id,
                error=message,
                form_values=request.form,
            ),
            status,
        )

    def occurrence_success_redirect(
        occurrence: RoutineOccurrence, saved: str
    ) -> Response:
        if request.form.get("return_to") == "today":
            return redirect(url_for("today", saved=saved))
        return redirect(
            url_for(
                "routine_detail",
                routine_template_id=occurrence.routine_template_id,
                saved=saved,
            )
        )

    @app.post("/routine-occurrences/<routine_occurrence_id>/snooze")
    def routine_occurrence_snooze(
        routine_occurrence_id: str,
    ) -> Response | tuple[str, int]:
        try:
            current = find_occurrence(routine_occurrence_id)
        except (RecordNotFound, ValueError):
            abort(404)
        try:
            updated = routine_service().snooze_occurrence(
                routine_occurrence_id,
                expected_revision(),
                istanbul_datetime_local_to_utc(
                    request.form.get("next_attention_at", "")
                ),
            )
        except (PersistenceError, ValueError) as exc:
            return occurrence_error_response(current, exc)
        return occurrence_success_redirect(updated, "occurrence_snoozed")

    @app.post("/routine-occurrences/<routine_occurrence_id>/close")
    def routine_occurrence_close(
        routine_occurrence_id: str,
    ) -> Response | tuple[str, int]:
        try:
            current = find_occurrence(routine_occurrence_id)
        except (RecordNotFound, ValueError):
            abort(404)
        try:
            updated = routine_service().close_occurrence(
                routine_occurrence_id,
                expected_revision(),
                CloseRoutineOccurrence(
                    RoutineOccurrenceOutcome(
                        request.form.get("outcome_type", "")
                    ),
                    request.form.get("outcome_note") or None,
                ),
            )
        except (PersistenceError, ValueError) as exc:
            return occurrence_error_response(current, exc)
        return occurrence_success_redirect(updated, "occurrence_closed")

    @app.post("/routine-occurrences/<routine_occurrence_id>/reopen")
    def routine_occurrence_reopen(
        routine_occurrence_id: str,
    ) -> Response | tuple[str, int]:
        try:
            current = find_occurrence(routine_occurrence_id)
        except (RecordNotFound, ValueError):
            abort(404)
        try:
            updated = routine_service().reopen_occurrence(
                routine_occurrence_id,
                expected_revision(),
                istanbul_datetime_local_to_utc(
                    request.form.get("next_attention_at", "")
                ),
            )
        except (PersistenceError, ValueError) as exc:
            return occurrence_error_response(current, exc)
        return occurrence_success_redirect(updated, "occurrence_reopened")

    @app.route("/projects/new", methods=["GET", "POST"])
    def project_new() -> str | Response:
        error = None
        if request.method == "POST":
            try:
                service().create_project(request.form.get("name", ""))
                return redirect(url_for("observation_new"))
            except (PersistenceError, ValueError) as exc:
                error = _safe_error(exc)
        return render_template("projects/new.html", error=error)

    @app.get("/observations")
    def observation_list() -> str | tuple[str, int]:
        projects = service().list_projects()
        project_id = request.args.get("project_id") or None
        status = request.args.get("status") or None
        raw_query = request.args.get("q", "")
        error = None
        response_status = 200
        try:
            observations = service().list_observations(project_id, status, raw_query)
        except ValueError:
            observations = []
            error = (
                f"Arama metni en fazla {MAX_SEARCH_QUERY_LENGTH} karakter olabilir."
            )
            response_status = 400
        rendered = render_template(
            "observations/list.html",
            projects=projects,
            observations=observations,
            selected_project=project_id,
            selected_status=status,
            selected_query=raw_query[:MAX_SEARCH_QUERY_LENGTH],
            filters_active=bool(project_id or status or raw_query.strip()),
            project_names={project.project_id: project.name for project in projects},
            error=error,
        )
        if response_status != 200:
            return rendered, response_status
        return rendered

    @app.route("/observations/new", methods=["GET", "POST"])
    def observation_new() -> str | Response:
        projects = service().list_projects()
        if not projects:
            return redirect(url_for("project_new"))
        error = None
        if request.method == "POST":
            uploaded = request.files.get("upload")
            upload = None
            if uploaded is not None and uploaded.filename:
                upload = UploadStream(uploaded.stream, uploaded.filename)
            try:
                observation = service().create_observation(
                    CreateObservation(
                        project_id=request.form.get("project_id", ""),
                        location=request.form.get("location", ""),
                        category=request.form.get("category", ""),
                        description=request.form.get("description", ""),
                        notes=request.form.get("notes") or None,
                        upload=upload,
                    )
                )
                return redirect(
                    url_for("observation_detail", observation_id=observation.observation_id)
                )
            except (PersistenceError, ApplicationServiceError, ValueError) as exc:
                error = _safe_error(exc)
        return render_template(
            "observations/new.html", projects=projects, error=error
        )

    @app.get("/observations/<observation_id>")
    def observation_detail(observation_id: str) -> str:
        try:
            detail = service().get_observation_detail(observation_id)
        except RecordNotFound:
            abort(404)
        saved_messages = {
            "details": "Gözlem bilgileri kaydedildi.",
            "status": "Durum bilgisi kaydedildi.",
            "reporting": "Bildirim bilgisi kaydedildi.",
        }
        return render_template(
            "observations/detail.html",
            detail=detail,
            error=None,
            success=saved_messages.get(request.args.get("saved", "")),
        )

    @app.route("/observations/<observation_id>/edit", methods=["GET", "POST"])
    def observation_edit(observation_id: str) -> str | Response | tuple[str, int]:
        try:
            detail = service().get_observation_detail(observation_id)
        except RecordNotFound:
            abort(404)
        if detail.observation.is_archived:
            return (
                render_template(
                    "observations/detail.html",
                    detail=detail,
                    error="Arşivlenmiş gözlem düzenlenemez.",
                    success=None,
                ),
                409,
            )

        if request.method == "GET":
            form_values = {
                "location": detail.observation.location,
                "category": detail.observation.category,
                "description": detail.observation.description,
                "notes": detail.observation.notes or "",
            }
            return render_template(
                "observations/edit.html",
                observation=detail.observation,
                form_values=form_values,
                expected_revision=str(detail.observation.revision),
                error=None,
            )

        form_values = {
            "location": request.form.get("location", ""),
            "category": request.form.get("category", ""),
            "description": request.form.get("description", ""),
            "notes": request.form.get("notes", ""),
        }
        expected_revision = request.form.get("expected_revision", "")
        try:
            service().update_observation_details(
                observation_id,
                int(expected_revision),
                form_values["location"],
                form_values["category"],
                form_values["description"],
                form_values["notes"],
            )
        except RevisionConflict:
            current = service().get_observation_detail(observation_id).observation
            return (
                render_template(
                    "observations/edit.html",
                    observation=current,
                    form_values=form_values,
                    expected_revision=expected_revision,
                    error=(
                        "Kayıt başka bir işlem tarafından güncellendi. "
                        "Devam etmeden önce sayfayı yenileyin."
                    ),
                ),
                409,
            )
        except ArchivedRecordError:
            current_detail = service().get_observation_detail(observation_id)
            return (
                render_template(
                    "observations/detail.html",
                    detail=current_detail,
                    error="Arşivlenmiş gözlem düzenlenemez.",
                    success=None,
                ),
                409,
            )
        except (PersistenceError, ValueError) as exc:
            current = service().get_observation_detail(observation_id).observation
            return (
                render_template(
                    "observations/edit.html",
                    observation=current,
                    form_values=form_values,
                    expected_revision=expected_revision,
                    error=_safe_error(exc),
                ),
                400,
            )
        return redirect(
            url_for(
                "observation_detail",
                observation_id=observation_id,
                saved="details",
            )
        )

    @app.post("/observations/<observation_id>/status")
    def observation_status(observation_id: str) -> str | Response:
        try:
            service().update_status(
                observation_id,
                int(request.form.get("expected_revision", "")),
                request.form.get("new_status", ""),
            )
        except RevisionConflict:
            detail = service().get_observation_detail(observation_id)
            return (
                render_template(
                    "observations/detail.html",
                    detail=detail,
                    error="Kayıt başka bir işlem tarafından güncellendi. Sayfayı yenileyin.",
                    success=None,
                ),
                409,
            )
        except (PersistenceError, ValueError) as exc:
            detail = service().get_observation_detail(observation_id)
            return render_template(
                "observations/detail.html",
                detail=detail,
                error=_safe_error(exc),
                success=None,
            ), 400
        return redirect(
            url_for(
                "observation_detail", observation_id=observation_id, saved="status"
            )
        )

    @app.post("/observations/<observation_id>/reporting")
    def observation_reporting(observation_id: str) -> str | Response:
        try:
            reported_at = istanbul_datetime_local_to_utc(
                request.form.get("reported_at", "")
            )
            service().update_reporting(
                observation_id,
                int(request.form.get("expected_revision", "")),
                request.form.get("reported_to", ""),
                reported_at,
            )
        except RevisionConflict:
            detail = service().get_observation_detail(observation_id)
            return render_template(
                "observations/detail.html",
                detail=detail,
                error="Kayıt başka bir işlem tarafından güncellendi. Sayfayı yenileyin.",
                success=None,
            ), 409
        except (PersistenceError, ValueError) as exc:
            detail = service().get_observation_detail(observation_id)
            return render_template(
                "observations/detail.html",
                detail=detail,
                error=_safe_error(exc),
                success=None,
            ), 400
        return redirect(
            url_for(
                "observation_detail",
                observation_id=observation_id,
                saved="reporting",
            )
        )

    @app.get("/attachments/<attachment_id>")
    def attachment_download(attachment_id: str) -> Response:
        try:
            metadata, verification = service().get_attachment(attachment_id)
        except RecordNotFound:
            abort(404)
        if not verification.valid:
            abort(409)
        download_name = secure_filename(metadata.original_name) or "attachment.bin"

        @stream_with_context
        def generate():
            with service().open_attachment(attachment_id) as file_handle:
                while chunk := file_handle.read(1024 * 1024):
                    yield chunk

        response = Response(
            generate(), mimetype=metadata.mime_type or "application/octet-stream"
        )
        disposition = "attachment"
        if request.args.get("view") == "1" and is_safe_image_preview(
            metadata.mime_type
        ):
            disposition = "inline"
        response.headers["Content-Disposition"] = (
            f'{disposition}; filename="{download_name}"'
        )
        response.headers["X-Content-Type-Options"] = "nosniff"
        return response

    @app.post("/backups")
    def backup_create() -> Response | tuple[str, int]:
        artifact = None
        try:
            artifact_id = str(app.config["CSE_BACKUP_ID_FACTORY"]())
            path = _backup_artifact_path(root, artifact_id)
            backup_service = app.config["CSE_BACKUP_SERVICE"]
            artifact = backup_service.create_backup(path)
            backup_service.verify_backup(artifact.path)
        except Exception:
            if artifact is not None:
                try:
                    artifact.path.unlink(missing_ok=True)
                except OSError:
                    pass
            return (
                render_template(
                    "backups/error.html",
                    error=BACKUP_ERROR_MESSAGE,
                ),
                409,
            )
        return redirect(url_for("backup_download", artifact_id=artifact_id))

    @app.get("/backups/<artifact_id>")
    def backup_download(artifact_id: str) -> Response | tuple[str, int]:
        try:
            path = _backup_artifact_path(root, artifact_id)
        except ValueError:
            abort(404)
        if not path.is_file():
            abort(404)
        try:
            app.config["CSE_BACKUP_SERVICE"].verify_backup(path)
            modified = datetime.fromtimestamp(path.stat().st_mtime, UTC)
        except Exception:
            return (
                render_template(
                    "backups/error.html",
                    error=BACKUP_ERROR_MESSAGE,
                ),
                409,
            )
        download_name = (
            f"cse-tam-yedek-{modified:%Y%m%d-%H%M%S}-"
            f"{artifact_id[:8]}.csebackup.zip"
        )
        response = send_file(
            path,
            mimetype="application/zip",
            as_attachment=True,
            download_name=download_name,
        )
        response.headers["X-Content-Type-Options"] = "nosniff"
        return response

    @app.post("/exports/daily")
    def daily_export() -> Response | tuple[str, int]:
        try:
            artifact = app.config["CSE_EXPORT_SERVICE"].build_daily_export(
                request.form.get("local_date", "")
            )
        except Exception:
            return "Günlük çıktı oluşturulamadı.", 400
        return redirect(url_for("export_download", export_id=artifact.artifact_id))

    @app.get("/exports/<export_id>")
    def export_download(export_id: str) -> Response:
        try:
            validate_canonical_uuid(export_id, "export_id")
        except ValueError:
            abort(404)
        path = root / "exports" / f"{export_id}.zip"
        if not path.is_file():
            abort(404)
        return send_file(
            path,
            mimetype="application/zip",
            as_attachment=True,
            download_name=f"cse-daily-{export_id}.zip",
        )

    return app


def _safe_error(error: Exception) -> str:
    if isinstance(error, ApplicationServiceError):
        return "İşlem tamamlanamadı; dosya bütünlük kontrolü gerekebilir."
    return "Girdileri kontrol edip yeniden deneyin."


def _tracking_error_message(error: Exception) -> str:
    """Translate field-tracking failures without exposing internal details."""

    message = str(error).casefold()
    if "capture_text" in message or "title" in message:
        return "Başlık boş bırakılamaz. Yazdığınız metni kontrol edin."
    if "revision" in message or "revizyon" in message:
        return "Sayfadaki revizyon bilgisi geçersiz. Sayfayı yenileyin."
    if "datetime" in message or "timestamp" in message or "zaman" in message:
        return "Tarih ve saati İstanbul yerel saatine göre eksiksiz girin."
    if "end_date" in message:
        return "Bitiş tarihi başlangıç tarihinden önce olamaz."
    if "weekdays" in message or "weekday" in message:
        return "Haftalık rutin için en az bir gün seçin."
    if "month_day" in message:
        return "Aylık rutin için 1 ile 31 arasında bir ay günü girin."
    if "project" in message:
        return "Seçilen proje kullanılamıyor. Proje seçimini kontrol edin."
    if "terminal" in message or "completed" in message or "cancelled" in message:
        return "Sonuçlanmış kayıt için bu işlem yapılamaz. Önce kaydı yeniden açın."
    if "inactive" in message or "deactiv" in message:
        return "Pasif bir rutin için bu işlem yapılamaz."
    if "outcome" in message:
        return "Geçerli bir sonuç seçin."
    if "status" in message:
        return "Geçerli bir durum seçin."
    return "Girdileri kontrol edip yeniden deneyin."


def _backup_artifact_path(root: Path, artifact_id: str) -> Path:
    validate_canonical_uuid(artifact_id, "backup_artifact_id")
    return root / "backups" / f"{artifact_id}.csebackup.zip"
