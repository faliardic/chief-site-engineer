from datetime import date, datetime

import pytest

from app.attachments import build_attachment_path


def test_build_attachment_path_uses_string_date() -> None:
    path = build_attachment_path(
        project_id="PRJ-001",
        record_type="nonconformity",
        record_id="NCR-00012",
        uploaded_at="2026-06-07",
        file_name="photo_001.jpg",
    )

    assert (
        path
        == "attachments/PRJ-001/nonconformity/2026/06/07/NCR-00012/photo_001.jpg"
    )


def test_build_attachment_path_uses_date_and_datetime_values() -> None:
    path_from_date = build_attachment_path(
        project_id="PRJ-001",
        record_type="concrete",
        record_id="CP-000123",
        uploaded_at=date(2026, 6, 7),
        file_name="slump_test.pdf",
    )
    path_from_datetime = build_attachment_path(
        project_id="PRJ-001",
        record_type="site_note",
        record_id="SN-00045",
        uploaded_at=datetime(2026, 6, 7, 14, 32, 10),
        file_name="site_photo.jpg",
    )

    assert (
        path_from_date
        == "attachments/PRJ-001/concrete/2026/06/07/CP-000123/slump_test.pdf"
    )
    assert (
        path_from_datetime
        == "attachments/PRJ-001/site_note/2026/06/07/SN-00045/site_photo.jpg"
    )


def test_build_attachment_path_strips_file_name_whitespace() -> None:
    path = build_attachment_path(
        project_id="PRJ-001",
        record_type="nonconformity",
        record_id="NCR-00012",
        uploaded_at="2026-06-07",
        file_name=" photo_001.jpg ",
    )

    assert path.endswith("/photo_001.jpg")


def test_build_attachment_path_makes_folder_separators_safe() -> None:
    path = build_attachment_path(
        project_id="PRJ-001",
        record_type="nonconformity",
        record_id="NCR-00012",
        uploaded_at="2026-06-07",
        file_name="photos\\june/photo_001.jpg",
    )

    assert path.endswith("/photos_june_photo_001.jpg")


@pytest.mark.parametrize(
    ("field_name", "kwargs"),
    [
        ("project_id", {"project_id": ""}),
        ("record_type", {"record_type": ""}),
        ("record_id", {"record_id": ""}),
        ("file_name", {"file_name": ""}),
    ],
)
def test_build_attachment_path_rejects_empty_required_values(
    field_name: str,
    kwargs: dict[str, str],
) -> None:
    values = {
        "project_id": "PRJ-001",
        "record_type": "nonconformity",
        "record_id": "NCR-00012",
        "uploaded_at": "2026-06-07",
        "file_name": "photo_001.jpg",
    }
    values.update(kwargs)

    with pytest.raises(ValueError, match=f"{field_name} cannot be empty"):
        build_attachment_path(**values)


def test_build_attachment_path_rejects_invalid_uploaded_at_string() -> None:
    with pytest.raises(ValueError, match="uploaded_at must use YYYY-MM-DD format"):
        build_attachment_path(
            project_id="PRJ-001",
            record_type="nonconformity",
            record_id="NCR-00012",
            uploaded_at="07-06-2026",
            file_name="photo_001.jpg",
        )


def test_build_attachment_path_normalizes_record_type_to_lowercase() -> None:
    path = build_attachment_path(
        project_id="PRJ-001",
        record_type="Nonconformity",
        record_id="NCR-00012",
        uploaded_at="2026-06-07",
        file_name="photo_001.jpg",
    )

    assert "/nonconformity/" in path
