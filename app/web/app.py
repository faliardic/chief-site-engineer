"""Server-rendered local field interface."""

from datetime import datetime, timedelta, timezone
from pathlib import Path

from flask import (
    Flask,
    Response,
    abort,
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
    ObservationApplicationService,
    UploadStream,
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
)
from app.operations import DailyExportService
from app.storage import ManagedAttachmentStore
from app.storage.paths import validate_canonical_uuid


MAX_UPLOAD_BYTES = 25 * 1024 * 1024
MAX_SEARCH_QUERY_LENGTH = 200
ISTANBUL_TIMEZONE = timezone(timedelta(hours=3), name="Europe/Istanbul")
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


def status_label(value: str) -> str:
    """Return a Turkish presentation label without changing stored values."""

    return STATUS_LABELS.get(value, "Durum bilgisi kullanılamıyor")


def integrity_label(value: str) -> str:
    """Return a safe Turkish attachment-integrity label."""

    return INTEGRITY_LABELS.get(value, "Dosya bütünlüğü doğrulanamadı")


def event_label(value: str) -> str:
    """Return a Turkish event label with a non-technical fallback."""

    return EVENT_LABELS.get(value, "Gözlem kaydı güncellendi")


def utc_to_istanbul_display(value: str | None) -> str:
    """Format a stored UTC timestamp for the Europe/Istanbul user surface."""

    if not value:
        return "-"
    try:
        parsed = datetime.fromisoformat(value.replace("Z", "+00:00"))
        if parsed.tzinfo is None:
            parsed = parsed.replace(tzinfo=timezone.utc)
    except (TypeError, ValueError):
        return "Zaman bilgisi kullanılamıyor"
    return parsed.astimezone(ISTANBUL_TIMEZONE).strftime("%d.%m.%Y %H:%M")


def utc_to_istanbul_input(value: str | None) -> str:
    """Format a stored UTC timestamp for an HTML datetime-local input."""

    if not value:
        return ""
    try:
        parsed = datetime.fromisoformat(value.replace("Z", "+00:00"))
        if parsed.tzinfo is None:
            parsed = parsed.replace(tzinfo=timezone.utc)
    except (TypeError, ValueError):
        return ""
    return parsed.astimezone(ISTANBUL_TIMEZONE).strftime("%Y-%m-%dT%H:%M")


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
    return local.astimezone(timezone.utc).isoformat(timespec="seconds").replace(
        "+00:00", "Z"
    )


def create_app(data_root: str | Path) -> Flask:
    """Create an app bound to one explicit, reusable data root."""

    root = Path(data_root).resolve()
    root.mkdir(parents=True, exist_ok=True)
    app = Flask(__name__)
    app.config.update(
        MAX_CONTENT_LENGTH=MAX_UPLOAD_BYTES,
        CSE_DATA_ROOT=root,
        CSE_INSTANCE_ID=instance_id_for_data_root(root),
        CSE_SERVICE=ObservationApplicationService(
            root / "cse.sqlite3",
            ManagedAttachmentStore(root / "attachments"),
        ),
        CSE_EXPORT_SERVICE=DailyExportService(root),
    )
    app.jinja_env.globals.update(
        event_label=event_label,
        integrity_label=integrity_label,
        is_safe_image_preview=is_safe_image_preview,
        status_label=status_label,
        utc_to_istanbul_display=utc_to_istanbul_display,
        utc_to_istanbul_input=utc_to_istanbul_input,
    )

    def service() -> ObservationApplicationService:
        return app.config["CSE_SERVICE"]

    @app.get("/")
    def index() -> Response:
        return redirect(url_for("observation_list"))

    @app.get("/health")
    def health() -> Response:
        return jsonify(
            application=APPLICATION_ID,
            instance_id=app.config["CSE_INSTANCE_ID"],
            ready=True,
            version=APPLICATION_VERSION,
        )

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
                    request.form.get("project_id", ""),
                    request.form.get("location", ""),
                    request.form.get("category", ""),
                    request.form.get("description", ""),
                    request.form.get("notes") or None,
                    upload,
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
