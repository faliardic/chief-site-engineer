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
from app.persistence import PersistenceError, RecordNotFound, RevisionConflict
from app.operations import DailyExportService
from app.storage import ManagedAttachmentStore
from app.storage.paths import validate_canonical_uuid


MAX_UPLOAD_BYTES = 25 * 1024 * 1024
ISTANBUL_TIMEZONE = timezone(timedelta(hours=3), name="Europe/Istanbul")


def istanbul_datetime_local_to_utc(value: str) -> str:
    """Interpret an HTML datetime-local value in Europe/Istanbul."""

    try:
        local = datetime.strptime(value, "%Y-%m-%dT%H:%M").replace(
            tzinfo=ISTANBUL_TIMEZONE
        )
    except (TypeError, ValueError) as exc:
        raise ValueError("Bildirim zamani gecersiz.") from exc
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
        CSE_SERVICE=ObservationApplicationService(
            root / "cse.sqlite3",
            ManagedAttachmentStore(root / "attachments"),
        ),
        CSE_EXPORT_SERVICE=DailyExportService(root),
    )

    def service() -> ObservationApplicationService:
        return app.config["CSE_SERVICE"]

    @app.get("/")
    def index() -> Response:
        return redirect(url_for("observation_list"))

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
    def observation_list() -> str:
        projects = service().list_projects()
        project_id = request.args.get("project_id") or None
        status = request.args.get("status") or None
        observations = service().list_observations(project_id, status)
        return render_template(
            "observations/list.html",
            projects=projects,
            observations=observations,
            selected_project=project_id,
            selected_status=status,
        )

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
        return render_template("observations/detail.html", detail=detail, error=None)

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
                    error="Kayit baska bir islem tarafindan guncellendi. Sayfayi yenileyin.",
                ),
                409,
            )
        except (PersistenceError, ValueError) as exc:
            detail = service().get_observation_detail(observation_id)
            return render_template(
                "observations/detail.html", detail=detail, error=_safe_error(exc)
            ), 400
        return redirect(url_for("observation_detail", observation_id=observation_id))

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
                error="Kayit baska bir islem tarafindan guncellendi. Sayfayi yenileyin.",
            ), 409
        except (PersistenceError, ValueError) as exc:
            detail = service().get_observation_detail(observation_id)
            return render_template(
                "observations/detail.html", detail=detail, error=_safe_error(exc)
            ), 400
        return redirect(url_for("observation_detail", observation_id=observation_id))

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
        response.headers["Content-Disposition"] = (
            f'attachment; filename="{download_name}"'
        )
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
        return "Islem tamamlanamadi; dosya butunluk kontrolu gerekebilir."
    return "Girdileri kontrol edip yeniden deneyin."
