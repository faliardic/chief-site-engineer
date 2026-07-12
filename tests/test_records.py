import pytest

from app.models import (
    DailySiteLog,
    FieldObservationRecord,
    FileAttachmentRecord,
    NonconformityRecord,
    TrackingRecord,
)
from app.records import (
    FieldObservationRepository,
    FileAttachmentRepository,
    NonconformityRepository,
    count_records,
    filter_records_by_project_id,
    filter_records_by_status,
    list_records,
)


class DummyRecord:
    pass


def _field_observation(
    observation_id: str,
    *,
    project_id: str = "prj-001",
    location: str = "A Blok 2. Kat",
    category: str = "quality",
    status: str = "open",
    is_archived: bool = False,
) -> FieldObservationRecord:
    return FieldObservationRecord(
        observation_id=observation_id,
        project_id=project_id,
        observed_at="2026-07-11T18:30:00",
        location=location,
        category=category,
        description=f"Field observation {observation_id}",
        status=status,
        is_archived=is_archived,
    )


def _file_attachment(
    attachment_id: str,
    *,
    related_record_type: str = "nonconformity",
    related_record_id: str = "NCR-001",
    file_name: str = "photo_001.jpg",
    file_path: str = "attachments/PRJ-001/nonconformity/NCR-001/photo_001.jpg",
    file_type: str = "image",
    mime_type: str = "image/jpeg",
    uploaded_at: str | None = "2026-07-11T20:00:00",
    uploaded_by: str | None = "Santiye sefi",
    original_file_name: str | None = "IMG_0001.JPG",
    description: str | None = "Saha kanit fotografi.",
    notes: str | None = "Mevcut metadata aynen korunmali.",
    file_size: int | None = 2048,
) -> FileAttachmentRecord:
    return FileAttachmentRecord(
        attachment_id=attachment_id,
        related_record_type=related_record_type,
        related_record_id=related_record_id,
        file_name=file_name,
        file_path=file_path,
        file_type=file_type,
        mime_type=mime_type,
        uploaded_at=uploaded_at,
        uploaded_by=uploaded_by,
        original_file_name=original_file_name,
        description=description,
        notes=notes,
        file_size=file_size,
    )


def test_file_attachment_repository_starts_empty() -> None:
    repository = FileAttachmentRepository()

    assert repository.list_all() == []
    assert repository.count() == 0
    assert repository.find_by_id("att-missing") is None


def test_file_attachment_repository_adds_and_finds_same_record_object() -> None:
    repository = FileAttachmentRepository()
    record = _file_attachment("att-001")

    repository.add(record)

    assert repository.list_all() == [record]
    assert repository.count() == 1
    assert repository.find_by_id("att-001") is record


def test_file_attachment_repository_preserves_insertion_order_for_distinct_records() -> None:
    repository = FileAttachmentRepository()
    first_record = _file_attachment("att-001")
    second_record = _file_attachment("att-002", file_name="photo_002.jpg")
    third_record = _file_attachment(
        "att-003",
        file_type="pdf",
        mime_type="application/pdf",
    )

    repository.add(first_record)
    repository.add(second_record)
    repository.add(third_record)

    assert repository.list_all() == [first_record, second_record, third_record]
    assert repository.count() == 3


def test_file_attachment_repository_rejects_duplicate_exact_id_without_changing_contents() -> None:
    repository = FileAttachmentRepository()
    first_record = _file_attachment("att-001")
    duplicate_record = _file_attachment("att-001", file_name="duplicate.jpg")

    repository.add(first_record)

    with pytest.raises(ValueError, match="att-001"):
        repository.add(duplicate_record)

    assert repository.list_all() == [first_record]
    assert repository.count() == 1
    assert repository.find_by_id("att-001") is first_record


def test_file_attachment_repository_keeps_case_different_ids_distinct() -> None:
    repository = FileAttachmentRepository()
    lower_case_record = _file_attachment("att-001")
    upper_case_record = _file_attachment("ATT-001", file_name="case-variant.jpg")

    repository.add(lower_case_record)
    repository.add(upper_case_record)

    assert repository.list_all() == [lower_case_record, upper_case_record]
    assert repository.find_by_id("att-001") is lower_case_record
    assert repository.find_by_id("ATT-001") is upper_case_record
    assert repository.count() == 2


def test_file_attachment_repository_list_all_returns_copy() -> None:
    repository = FileAttachmentRepository()
    record = _file_attachment("att-001")
    repository.add(record)

    listed_records = repository.list_all()
    second_listed_records = repository.list_all()
    listed_records.clear()

    assert second_listed_records is not repository.list_all()
    assert repository.list_all() == [record]
    assert repository.count() == 1


def test_file_attachment_repository_does_not_mutate_attachment_metadata_fields() -> None:
    repository = FileAttachmentRepository()
    record = _file_attachment(
        "att-001",
        related_record_type="field_observation",
        related_record_id="obs-001",
        file_name="observation-photo.jpg",
        file_path="attachments/PRJ-001/field_observation/obs-001/observation-photo.jpg",
        file_type="image",
        mime_type="image/jpeg",
        uploaded_at="2026-07-11T21:00:00",
        uploaded_by="Saha muhendisi",
        original_file_name="WhatsApp Image 2026-07-11.jpeg",
        description="Kolon kalip kontrol fotografi.",
        notes="Ek not korunmali.",
        file_size=4096,
    )

    repository.add(record)
    found_record = repository.find_by_id("att-001")
    listed_record = repository.list_all()[0]

    assert found_record is record
    assert listed_record is record
    assert record.attachment_id == "att-001"
    assert record.related_record_type == "field_observation"
    assert record.related_record_id == "obs-001"
    assert record.file_name == "observation-photo.jpg"
    assert (
        record.file_path
        == "attachments/PRJ-001/field_observation/obs-001/observation-photo.jpg"
    )
    assert record.file_type == "image"
    assert record.mime_type == "image/jpeg"
    assert record.uploaded_at == "2026-07-11T21:00:00"
    assert record.uploaded_by == "Saha muhendisi"
    assert record.original_file_name == "WhatsApp Image 2026-07-11.jpeg"
    assert record.description == "Kolon kalip kontrol fotografi."
    assert record.notes == "Ek not korunmali."
    assert record.file_size == 4096


def test_file_attachment_repository_does_not_change_existing_record_repositories() -> None:
    observation_repository = FieldObservationRepository()
    nonconformity_repository = NonconformityRepository()
    observation = _field_observation("obs-001", status="open")
    nonconformity = NonconformityRecord(
        nonconformity_id="NCR-217",
        project_id="prj-001",
        date="2026-07-11",
        title="Mevcut repository regresyon kontrolu",
        description="Step 217 attachment repository eklerken mevcut davranis korunmali.",
    )

    observation_repository.add(observation)
    nonconformity_repository.add(nonconformity)

    assert observation_repository.find_by_id("obs-001") is observation
    assert observation_repository.update_status("obs-001", "tracking") is observation
    assert observation_repository.list_by_status("tracking") == [observation]
    assert nonconformity_repository.find_by_id("NCR-217") is nonconformity
    assert nonconformity_repository.exists("NCR-217") is True
    assert nonconformity_repository.count() == 1


def test_file_attachment_repository_related_record_type_filter_exact_matches_in_order() -> None:
    repository = FileAttachmentRepository()
    first_observation_attachment = _file_attachment(
        "att-001",
        related_record_type="field_observation",
        related_record_id="obs-001",
    )
    nonconformity_attachment = _file_attachment(
        "att-002",
        related_record_type="nonconformity",
        related_record_id="NCR-001",
    )
    second_observation_attachment = _file_attachment(
        "att-003",
        related_record_type="field_observation",
        related_record_id="obs-002",
    )
    case_variant_attachment = _file_attachment(
        "att-004",
        related_record_type="Field_Observation",
        related_record_id="obs-003",
    )
    whitespace_variant_attachment = _file_attachment(
        "att-005",
        related_record_type=" field_observation ",
        related_record_id="obs-004",
    )

    repository.add(first_observation_attachment)
    repository.add(nonconformity_attachment)
    repository.add(second_observation_attachment)
    repository.add(case_variant_attachment)
    repository.add(whitespace_variant_attachment)

    result = repository.list_by_related_record_type("field_observation")

    assert result == [first_observation_attachment, second_observation_attachment]
    assert repository.list_by_related_record_type("unknown") == []
    assert repository.list_by_related_record_type("Field_Observation") == [
        case_variant_attachment
    ]
    assert repository.list_by_related_record_type("field_observation ") == []
    assert repository.list_by_related_record_type(" field_observation ") == [
        whitespace_variant_attachment
    ]


def test_file_attachment_repository_related_record_id_filter_exact_matches_in_order() -> None:
    repository = FileAttachmentRepository()
    first_ncr_attachment = _file_attachment(
        "att-001",
        related_record_id="NCR-001",
    )
    observation_attachment = _file_attachment(
        "att-002",
        related_record_type="field_observation",
        related_record_id="obs-001",
    )
    second_ncr_attachment = _file_attachment(
        "att-003",
        related_record_id="NCR-001",
    )
    case_variant_attachment = _file_attachment(
        "att-004",
        related_record_id="ncr-001",
    )
    whitespace_variant_attachment = _file_attachment(
        "att-005",
        related_record_id=" NCR-001 ",
    )

    repository.add(first_ncr_attachment)
    repository.add(observation_attachment)
    repository.add(second_ncr_attachment)
    repository.add(case_variant_attachment)
    repository.add(whitespace_variant_attachment)

    result = repository.list_by_related_record_id("NCR-001")

    assert result == [first_ncr_attachment, second_ncr_attachment]
    assert repository.list_by_related_record_id("unknown") == []
    assert repository.list_by_related_record_id("ncr-001") == [case_variant_attachment]
    assert repository.list_by_related_record_id("NCR-001 ") == []
    assert repository.list_by_related_record_id(" NCR-001 ") == [
        whitespace_variant_attachment
    ]


def test_file_attachment_repository_related_record_type_and_id_filters_are_independent() -> None:
    repository = FileAttachmentRepository()
    observation_attachment = _file_attachment(
        "att-001",
        related_record_type="field_observation",
        related_record_id="shared-001",
    )
    other_observation_attachment = _file_attachment(
        "att-002",
        related_record_type="field_observation",
        related_record_id="obs-002",
    )
    nonconformity_attachment = _file_attachment(
        "att-003",
        related_record_type="nonconformity",
        related_record_id="shared-001",
    )

    repository.add(observation_attachment)
    repository.add(other_observation_attachment)
    repository.add(nonconformity_attachment)

    assert repository.list_by_related_record_type("field_observation") == [
        observation_attachment,
        other_observation_attachment,
    ]
    assert repository.list_by_related_record_id("shared-001") == [
        observation_attachment,
        nonconformity_attachment,
    ]


def test_file_attachment_repository_related_record_filters_return_empty_for_empty_repository() -> None:
    repository = FileAttachmentRepository()

    assert repository.list_by_related_record_type("field_observation") == []
    assert repository.list_by_related_record_id("obs-001") == []


def test_file_attachment_repository_related_record_filtered_lists_are_copies() -> None:
    repository = FileAttachmentRepository()
    type_match = _file_attachment(
        "att-001",
        related_record_type="field_observation",
        related_record_id="obs-001",
    )
    id_match = _file_attachment(
        "att-002",
        related_record_type="nonconformity",
        related_record_id="obs-001",
    )
    repository.add(type_match)
    repository.add(id_match)

    listed_by_type = repository.list_by_related_record_type("field_observation")
    second_listed_by_type = repository.list_by_related_record_type("field_observation")
    listed_by_id = repository.list_by_related_record_id("obs-001")
    second_listed_by_id = repository.list_by_related_record_id("obs-001")
    listed_by_type.clear()
    listed_by_id.clear()

    assert second_listed_by_type is not repository.list_by_related_record_type(
        "field_observation"
    )
    assert second_listed_by_id is not repository.list_by_related_record_id("obs-001")
    assert repository.list_by_related_record_type("field_observation") == [type_match]
    assert repository.list_by_related_record_id("obs-001") == [type_match, id_match]


def test_file_attachment_repository_related_record_filters_return_same_objects_without_mutating_metadata() -> None:
    repository = FileAttachmentRepository()
    record = _file_attachment(
        "att-001",
        related_record_type="field_observation",
        related_record_id="obs-001",
        file_name="observation-photo.jpg",
        file_path="attachments/PRJ-001/field_observation/obs-001/observation-photo.jpg",
        file_type="image",
        mime_type="image/jpeg",
        uploaded_at="2026-07-11T21:00:00",
        uploaded_by="Saha muhendisi",
        original_file_name="IMG_0001.JPG",
        description="Kolon kalip kontrol fotografi.",
        notes="Ek not korunmali.",
        file_size=4096,
    )

    repository.add(record)
    type_result = repository.list_by_related_record_type("field_observation")
    id_result = repository.list_by_related_record_id("obs-001")

    assert type_result == [record]
    assert id_result == [record]
    assert type_result[0] is record
    assert id_result[0] is record
    assert record.attachment_id == "att-001"
    assert record.related_record_type == "field_observation"
    assert record.related_record_id == "obs-001"
    assert record.file_name == "observation-photo.jpg"
    assert (
        record.file_path
        == "attachments/PRJ-001/field_observation/obs-001/observation-photo.jpg"
    )
    assert record.file_type == "image"
    assert record.mime_type == "image/jpeg"
    assert record.uploaded_at == "2026-07-11T21:00:00"
    assert record.uploaded_by == "Saha muhendisi"
    assert record.original_file_name == "IMG_0001.JPG"
    assert record.description == "Kolon kalip kontrol fotografi."
    assert record.notes == "Ek not korunmali."
    assert record.file_size == 4096


def test_file_attachment_repository_related_record_filters_keep_count_and_order_stable() -> None:
    repository = FileAttachmentRepository()
    first_record = _file_attachment(
        "att-001",
        related_record_type="field_observation",
        related_record_id="obs-001",
    )
    second_record = _file_attachment(
        "att-002",
        related_record_type="nonconformity",
        related_record_id="NCR-001",
    )
    third_record = _file_attachment(
        "att-003",
        related_record_type="field_observation",
        related_record_id="obs-002",
    )

    repository.add(first_record)
    repository.add(second_record)
    repository.add(third_record)
    before_filtering = repository.list_all()

    assert repository.list_by_related_record_type("field_observation") == [
        first_record,
        third_record,
    ]
    assert repository.list_by_related_record_id("NCR-001") == [second_record]
    assert repository.list_all() == before_filtering
    assert repository.list_all() == [first_record, second_record, third_record]
    assert repository.count() == 3


def test_file_attachment_repository_related_record_filters_do_not_change_existing_repository_behaviors() -> None:
    attachment_repository = FileAttachmentRepository()
    observation_repository = FieldObservationRepository()
    nonconformity_repository = NonconformityRepository()
    attachment = _file_attachment(
        "att-001",
        related_record_type="field_observation",
        related_record_id="obs-001",
    )
    observation = _field_observation("obs-001", status="open")
    nonconformity = NonconformityRecord(
        nonconformity_id="NCR-218",
        project_id="prj-001",
        date="2026-07-12",
        title="Related-record filtre regresyon kontrolu",
        description="Step 218 filtreleri mevcut repository davranislarini bozmamali.",
    )

    attachment_repository.add(attachment)
    observation_repository.add(observation)
    nonconformity_repository.add(nonconformity)

    assert attachment_repository.find_by_id("att-001") is attachment
    assert attachment_repository.list_all() == [attachment]
    assert attachment_repository.count() == 1
    assert observation_repository.find_by_id("obs-001") is observation
    assert observation_repository.update_status("obs-001", "tracking") is observation
    assert observation_repository.list_by_status("tracking") == [observation]
    assert nonconformity_repository.find_by_id("NCR-218") is nonconformity
    assert nonconformity_repository.exists("NCR-218") is True
    assert nonconformity_repository.count() == 1


def test_file_attachment_repository_combined_related_record_exact_pair_matches_in_order() -> None:
    repository = FileAttachmentRepository()
    first_match = _file_attachment(
        "att-001",
        related_record_type="field_observation",
        related_record_id="obs-001",
    )
    non_match = _file_attachment(
        "att-002",
        related_record_type="nonconformity",
        related_record_id="NCR-001",
    )
    second_match = _file_attachment(
        "att-003",
        related_record_type="field_observation",
        related_record_id="obs-001",
        file_name="observation-photo-2.jpg",
    )

    repository.add(first_match)
    repository.add(non_match)
    repository.add(second_match)

    result = repository.list_by_related_record("field_observation", "obs-001")

    assert result == [first_match, second_match]


def test_file_attachment_repository_combined_related_record_excludes_same_id_different_type() -> None:
    repository = FileAttachmentRepository()
    field_attachment = _file_attachment(
        "att-001",
        related_record_type="field_observation",
        related_record_id="shared-001",
    )
    nonconformity_attachment = _file_attachment(
        "att-002",
        related_record_type="nonconformity",
        related_record_id="shared-001",
    )

    repository.add(field_attachment)
    repository.add(nonconformity_attachment)

    assert repository.list_by_related_record("field_observation", "shared-001") == [
        field_attachment
    ]


def test_file_attachment_repository_combined_related_record_excludes_same_type_different_id() -> None:
    repository = FileAttachmentRepository()
    matching_attachment = _file_attachment(
        "att-001",
        related_record_type="field_observation",
        related_record_id="obs-001",
    )
    other_observation_attachment = _file_attachment(
        "att-002",
        related_record_type="field_observation",
        related_record_id="obs-002",
    )

    repository.add(matching_attachment)
    repository.add(other_observation_attachment)

    assert repository.list_by_related_record("field_observation", "obs-001") == [
        matching_attachment
    ]


def test_file_attachment_repository_combined_related_record_rejects_case_and_whitespace_different_values() -> None:
    repository = FileAttachmentRepository()
    exact_attachment = _file_attachment(
        "att-001",
        related_record_type="field_observation",
        related_record_id="obs-001",
    )
    case_type_attachment = _file_attachment(
        "att-002",
        related_record_type="Field_Observation",
        related_record_id="obs-001",
    )
    whitespace_type_attachment = _file_attachment(
        "att-003",
        related_record_type=" field_observation ",
        related_record_id="obs-001",
    )
    case_id_attachment = _file_attachment(
        "att-004",
        related_record_type="field_observation",
        related_record_id="OBS-001",
    )
    whitespace_id_attachment = _file_attachment(
        "att-005",
        related_record_type="field_observation",
        related_record_id=" obs-001 ",
    )

    repository.add(exact_attachment)
    repository.add(case_type_attachment)
    repository.add(whitespace_type_attachment)
    repository.add(case_id_attachment)
    repository.add(whitespace_id_attachment)

    assert repository.list_by_related_record("field_observation", "obs-001") == [
        exact_attachment
    ]
    assert repository.list_by_related_record("Field_Observation", "obs-001") == [
        case_type_attachment
    ]
    assert repository.list_by_related_record("field_observation ", "obs-001") == []
    assert repository.list_by_related_record("field_observation", "obs-001 ") == []


def test_file_attachment_repository_combined_related_record_empty_and_unknown_pair_return_empty() -> None:
    empty_repository = FileAttachmentRepository()
    repository = FileAttachmentRepository()
    attachment = _file_attachment(
        "att-001",
        related_record_type="field_observation",
        related_record_id="obs-001",
    )
    repository.add(attachment)

    assert empty_repository.list_by_related_record("field_observation", "obs-001") == []
    assert repository.list_by_related_record("unknown", "obs-001") == []
    assert repository.list_by_related_record("field_observation", "unknown") == []


def test_file_attachment_repository_combined_related_record_returns_new_lists_and_external_mutation_does_not_change_contents() -> None:
    repository = FileAttachmentRepository()
    first_match = _file_attachment(
        "att-001",
        related_record_type="field_observation",
        related_record_id="obs-001",
    )
    second_match = _file_attachment(
        "att-002",
        related_record_type="field_observation",
        related_record_id="obs-001",
    )
    repository.add(first_match)
    repository.add(second_match)

    listed_records = repository.list_by_related_record("field_observation", "obs-001")
    second_listed_records = repository.list_by_related_record(
        "field_observation",
        "obs-001",
    )
    listed_records.clear()

    assert second_listed_records is not repository.list_by_related_record(
        "field_observation",
        "obs-001",
    )
    assert repository.list_by_related_record("field_observation", "obs-001") == [
        first_match,
        second_match,
    ]
    assert repository.count() == 2


def test_file_attachment_repository_combined_related_record_returns_same_objects_without_mutating_metadata() -> None:
    repository = FileAttachmentRepository()
    record = _file_attachment(
        "att-001",
        related_record_type="field_observation",
        related_record_id="obs-001",
        file_name="observation-photo.jpg",
        file_path="attachments/PRJ-001/field_observation/obs-001/observation-photo.jpg",
        file_type="image",
        mime_type="image/jpeg",
        uploaded_at="2026-07-12T10:00:00",
        uploaded_by="Saha muhendisi",
        original_file_name="IMG_2200.JPG",
        description="Step 220 combined filter fotografi.",
        notes="Metadata degismemeli.",
        file_size=5120,
    )

    repository.add(record)
    result = repository.list_by_related_record("field_observation", "obs-001")

    assert result == [record]
    assert result[0] is record
    assert record.attachment_id == "att-001"
    assert record.related_record_type == "field_observation"
    assert record.related_record_id == "obs-001"
    assert record.file_name == "observation-photo.jpg"
    assert (
        record.file_path
        == "attachments/PRJ-001/field_observation/obs-001/observation-photo.jpg"
    )
    assert record.file_type == "image"
    assert record.mime_type == "image/jpeg"
    assert record.uploaded_at == "2026-07-12T10:00:00"
    assert record.uploaded_by == "Saha muhendisi"
    assert record.original_file_name == "IMG_2200.JPG"
    assert record.description == "Step 220 combined filter fotografi."
    assert record.notes == "Metadata degismemeli."
    assert record.file_size == 5120


def test_file_attachment_repository_combined_related_record_keeps_count_and_list_all_order_stable() -> None:
    repository = FileAttachmentRepository()
    first_record = _file_attachment(
        "att-001",
        related_record_type="field_observation",
        related_record_id="obs-001",
    )
    second_record = _file_attachment(
        "att-002",
        related_record_type="nonconformity",
        related_record_id="NCR-001",
    )
    third_record = _file_attachment(
        "att-003",
        related_record_type="field_observation",
        related_record_id="obs-001",
    )

    repository.add(first_record)
    repository.add(second_record)
    repository.add(third_record)
    before_filtering = repository.list_all()

    assert repository.list_by_related_record("field_observation", "obs-001") == [
        first_record,
        third_record,
    ]
    assert repository.list_all() == before_filtering
    assert repository.list_all() == [first_record, second_record, third_record]
    assert repository.count() == 3


def test_file_attachment_repository_combined_related_record_does_not_validate_missing_related_record_existence() -> None:
    repository = FileAttachmentRepository()
    orphan_metadata = _file_attachment(
        "att-001",
        related_record_type="field_observation",
        related_record_id="missing-observation",
    )

    repository.add(orphan_metadata)

    assert repository.list_by_related_record(
        "field_observation",
        "missing-observation",
    ) == [orphan_metadata]


def test_file_attachment_repository_combined_related_record_preserves_existing_filters_and_repository_behaviors() -> None:
    attachment_repository = FileAttachmentRepository()
    observation_repository = FieldObservationRepository()
    nonconformity_repository = NonconformityRepository()
    field_attachment = _file_attachment(
        "att-001",
        related_record_type="field_observation",
        related_record_id="obs-001",
    )
    nonconformity_attachment = _file_attachment(
        "att-002",
        related_record_type="nonconformity",
        related_record_id="obs-001",
    )
    observation = _field_observation("obs-001", status="open")
    nonconformity = NonconformityRecord(
        nonconformity_id="NCR-220",
        project_id="prj-001",
        date="2026-07-12",
        title="Combined related-record regresyon kontrolu",
        description="Step 220 combined filtre mevcut davranislari bozmamali.",
    )

    attachment_repository.add(field_attachment)
    attachment_repository.add(nonconformity_attachment)
    observation_repository.add(observation)
    nonconformity_repository.add(nonconformity)

    assert attachment_repository.list_by_related_record_type("field_observation") == [
        field_attachment
    ]
    assert attachment_repository.list_by_related_record_id("obs-001") == [
        field_attachment,
        nonconformity_attachment,
    ]
    assert attachment_repository.find_by_id("att-001") is field_attachment
    assert attachment_repository.list_all() == [
        field_attachment,
        nonconformity_attachment,
    ]
    assert attachment_repository.count() == 2
    assert observation_repository.find_by_id("obs-001") is observation
    assert observation_repository.update_status("obs-001", "tracking") is observation
    assert observation_repository.list_by_status("tracking") == [observation]
    assert nonconformity_repository.find_by_id("NCR-220") is nonconformity
    assert nonconformity_repository.exists("NCR-220") is True
    assert nonconformity_repository.count() == 1


def test_file_attachment_repository_field_observation_convenience_delegates_to_combined_helper() -> None:
    repository = FileAttachmentRepository()
    delegated_result = [
        _file_attachment(
            "att-delegated",
            related_record_type="field_observation",
            related_record_id="obs-001",
        )
    ]
    captured_arguments: list[tuple[str, str]] = []

    def fake_list_by_related_record(
        related_record_type: str,
        related_record_id: str,
    ) -> list[FileAttachmentRecord]:
        captured_arguments.append((related_record_type, related_record_id))
        return delegated_result

    repository.list_by_related_record = fake_list_by_related_record  # type: ignore[method-assign]

    assert repository.list_for_field_observation("obs-001") is delegated_result
    assert captured_arguments == [("field_observation", "obs-001")]


def test_file_attachment_repository_field_observation_convenience_exact_matches_in_order_and_excludes_partial_matches() -> None:
    repository = FileAttachmentRepository()
    first_field_attachment = _file_attachment(
        "att-001",
        related_record_type="field_observation",
        related_record_id="obs-001",
    )
    same_id_other_type = _file_attachment(
        "att-002",
        related_record_type="nonconformity",
        related_record_id="obs-001",
    )
    same_type_other_id = _file_attachment(
        "att-003",
        related_record_type="field_observation",
        related_record_id="obs-002",
    )
    second_field_attachment = _file_attachment(
        "att-004",
        related_record_type="field_observation",
        related_record_id="obs-001",
    )

    repository.add(first_field_attachment)
    repository.add(same_id_other_type)
    repository.add(same_type_other_id)
    repository.add(second_field_attachment)

    assert repository.list_for_field_observation("obs-001") == [
        first_field_attachment,
        second_field_attachment,
    ]


def test_file_attachment_repository_field_observation_convenience_rejects_case_and_whitespace_different_ids() -> None:
    repository = FileAttachmentRepository()
    exact_attachment = _file_attachment(
        "att-001",
        related_record_type="field_observation",
        related_record_id="obs-001",
    )
    case_variant_attachment = _file_attachment(
        "att-002",
        related_record_type="field_observation",
        related_record_id="OBS-001",
    )
    whitespace_variant_attachment = _file_attachment(
        "att-003",
        related_record_type="field_observation",
        related_record_id=" obs-001 ",
    )

    repository.add(exact_attachment)
    repository.add(case_variant_attachment)
    repository.add(whitespace_variant_attachment)

    assert repository.list_for_field_observation("obs-001") == [exact_attachment]
    assert repository.list_for_field_observation("OBS-001") == [
        case_variant_attachment
    ]
    assert repository.list_for_field_observation("obs-001 ") == []
    assert repository.list_for_field_observation(" obs-001 ") == [
        whitespace_variant_attachment
    ]


def test_file_attachment_repository_field_observation_convenience_empty_and_unknown_id_return_empty() -> None:
    empty_repository = FileAttachmentRepository()
    repository = FileAttachmentRepository()
    attachment = _file_attachment(
        "att-001",
        related_record_type="field_observation",
        related_record_id="obs-001",
    )

    repository.add(attachment)

    assert empty_repository.list_for_field_observation("obs-001") == []
    assert repository.list_for_field_observation("unknown-observation") == []


def test_file_attachment_repository_field_observation_convenience_returns_new_lists_and_external_mutation_does_not_change_contents() -> None:
    repository = FileAttachmentRepository()
    first_attachment = _file_attachment(
        "att-001",
        related_record_type="field_observation",
        related_record_id="obs-001",
    )
    second_attachment = _file_attachment(
        "att-002",
        related_record_type="field_observation",
        related_record_id="obs-001",
    )

    repository.add(first_attachment)
    repository.add(second_attachment)

    listed_records = repository.list_for_field_observation("obs-001")
    second_listed_records = repository.list_for_field_observation("obs-001")
    listed_records.clear()

    assert second_listed_records == [first_attachment, second_attachment]
    assert second_listed_records is not repository.list_for_field_observation(
        "obs-001"
    )
    assert repository.list_for_field_observation("obs-001") == [
        first_attachment,
        second_attachment,
    ]


def test_file_attachment_repository_field_observation_convenience_returns_same_objects_without_mutating_metadata() -> None:
    repository = FileAttachmentRepository()
    record = _file_attachment(
        "att-001",
        related_record_type="field_observation",
        related_record_id="obs-001",
        file_name="field-observation-photo.jpg",
        file_path="attachments/PRJ-001/field_observation/obs-001/field-observation-photo.jpg",
        file_type="image",
        mime_type="image/jpeg",
        uploaded_at="2026-07-13T10:00:00",
        uploaded_by="Saha muhendisi",
        original_file_name="IMG_2230.JPG",
        description="Step 223 convenience lookup fotografi.",
        notes="Metadata degismemeli.",
        file_size=6144,
    )

    repository.add(record)
    result = repository.list_for_field_observation("obs-001")

    assert result == [record]
    assert result[0] is record
    assert record.attachment_id == "att-001"
    assert record.related_record_type == "field_observation"
    assert record.related_record_id == "obs-001"
    assert record.file_name == "field-observation-photo.jpg"
    assert (
        record.file_path
        == "attachments/PRJ-001/field_observation/obs-001/field-observation-photo.jpg"
    )
    assert record.file_type == "image"
    assert record.mime_type == "image/jpeg"
    assert record.uploaded_at == "2026-07-13T10:00:00"
    assert record.uploaded_by == "Saha muhendisi"
    assert record.original_file_name == "IMG_2230.JPG"
    assert record.description == "Step 223 convenience lookup fotografi."
    assert record.notes == "Metadata degismemeli."
    assert record.file_size == 6144


def test_file_attachment_repository_field_observation_convenience_keeps_count_order_and_allows_missing_observation_reference() -> None:
    repository = FileAttachmentRepository()
    orphan_attachment = _file_attachment(
        "att-001",
        related_record_type="field_observation",
        related_record_id="missing-observation",
    )
    nonmatching_attachment = _file_attachment(
        "att-002",
        related_record_type="nonconformity",
        related_record_id="missing-observation",
    )

    repository.add(orphan_attachment)
    repository.add(nonmatching_attachment)
    before_lookup = repository.list_all()

    assert repository.list_for_field_observation("missing-observation") == [
        orphan_attachment
    ]
    assert repository.list_all() == before_lookup
    assert repository.list_all() == [orphan_attachment, nonmatching_attachment]
    assert repository.count() == 2


def test_file_attachment_repository_field_observation_convenience_matches_combined_helper_and_preserves_existing_filters() -> None:
    repository = FileAttachmentRepository()
    field_attachment = _file_attachment(
        "att-001",
        related_record_type="field_observation",
        related_record_id="obs-001",
    )
    nonconformity_attachment = _file_attachment(
        "att-002",
        related_record_type="nonconformity",
        related_record_id="obs-001",
    )
    other_field_attachment = _file_attachment(
        "att-003",
        related_record_type="field_observation",
        related_record_id="obs-002",
    )

    repository.add(field_attachment)
    repository.add(nonconformity_attachment)
    repository.add(other_field_attachment)

    assert repository.list_for_field_observation(
        "obs-001"
    ) == repository.list_by_related_record("field_observation", "obs-001")
    assert repository.list_by_related_record_type("field_observation") == [
        field_attachment,
        other_field_attachment,
    ]
    assert repository.list_by_related_record_id("obs-001") == [
        field_attachment,
        nonconformity_attachment,
    ]
    assert repository.list_by_related_record("field_observation", "obs-002") == [
        other_field_attachment
    ]


def test_list_records_returns_given_list() -> None:
    records = [
        DailySiteLog(log_id="log-001", project_id="prj-001", date="2026-06-05"),
    ]

    result = list_records(records)

    assert result == records


def test_count_records_returns_record_count() -> None:
    records = [
        DailySiteLog(log_id="log-001", project_id="prj-001", date="2026-06-05"),
        DailySiteLog(log_id="log-002", project_id="prj-001", date="2026-06-06"),
    ]

    result = count_records(records)

    assert result == 2


def test_filter_records_by_project_id_returns_matching_records() -> None:
    records = [
        DailySiteLog(log_id="log-001", project_id="prj-001", date="2026-06-05"),
        DailySiteLog(log_id="log-002", project_id="prj-002", date="2026-06-05"),
        TrackingRecord(
            record_id="trk-001",
            project_id="prj-001",
            title="Demir kontrolu",
            description="Donati kontrol edildi.",
            date="2026-06-05",
        ),
    ]

    result = filter_records_by_project_id(records, "prj-001")

    assert len(result) == 2
    assert result[0].project_id == "prj-001"
    assert result[1].project_id == "prj-001"


def test_filter_records_by_project_id_ignores_records_without_project_id() -> None:
    records = [
        DummyRecord(),
        DailySiteLog(log_id="log-001", project_id="prj-001", date="2026-06-05"),
    ]

    result = filter_records_by_project_id(records, "prj-001")

    assert len(result) == 1
    assert result[0].project_id == "prj-001"


def test_filter_records_by_status_returns_matching_records() -> None:
    records = [
        DailySiteLog(log_id="log-001", project_id="prj-001", date="2026-06-05"),
        DailySiteLog(
            log_id="log-002",
            project_id="prj-001",
            date="2026-06-06",
            status="approved",
        ),
        TrackingRecord(
            record_id="trk-001",
            project_id="prj-001",
            title="Beton dokum takibi",
            description="Dokum basladi.",
            date="2026-06-05",
            status="closed",
        ),
    ]

    result = filter_records_by_status(records, "draft")

    assert len(result) == 1
    assert result[0].status == "draft"


def test_filter_records_by_status_ignores_records_without_status() -> None:
    records = [
        DummyRecord(),
        DailySiteLog(log_id="log-001", project_id="prj-001", date="2026-06-05"),
    ]

    result = filter_records_by_status(records, "draft")

    assert len(result) == 1
    assert result[0].status == "draft"


def test_record_helpers_handle_empty_lists() -> None:
    records = []

    assert list_records(records) == []
    assert count_records(records) == 0
    assert filter_records_by_project_id(records, "prj-001") == []
    assert filter_records_by_status(records, "draft") == []


def test_field_observation_repository_starts_empty() -> None:
    repository = FieldObservationRepository()

    assert repository.list_all() == []
    assert repository.count() == 0
    assert repository.find_by_id("obs-missing") is None


def test_field_observation_repository_adds_lists_counts_and_finds_records() -> None:
    repository = FieldObservationRepository()
    first_record = _field_observation("obs-001")
    second_record = _field_observation("obs-002")

    repository.add(first_record)
    repository.add(second_record)

    assert repository.list_all() == [first_record, second_record]
    assert repository.count() == 2
    assert repository.find_by_id("obs-001") == first_record
    assert repository.find_by_id("obs-002") == second_record
    assert repository.find_by_id("obs-999") is None


def test_field_observation_repository_rejects_duplicate_id_and_accepts_different_ids() -> None:
    repository = FieldObservationRepository()
    first_record = _field_observation("obs-001")
    duplicate_record = _field_observation("obs-001")
    different_record = _field_observation("obs-002")

    repository.add(first_record)

    with pytest.raises(ValueError, match="obs-001"):
        repository.add(duplicate_record)

    repository.add(different_record)

    assert repository.list_all() == [first_record, different_record]
    assert repository.count() == 2


def test_field_observation_repository_list_all_returns_copy() -> None:
    repository = FieldObservationRepository()
    record = _field_observation("obs-001")
    repository.add(record)

    listed_records = repository.list_all()
    listed_records.clear()

    assert repository.list_all() == [record]
    assert repository.count() == 1


def test_field_observation_repository_filters_by_project_id_exact_matches_in_order() -> None:
    repository = FieldObservationRepository()

    assert repository.list_by_project_id("prj-001") == []

    first_record = _field_observation("obs-001", project_id="prj-001")
    other_project_record = _field_observation("obs-002", project_id="prj-002")
    second_record = _field_observation("obs-003", project_id="prj-001")
    case_variant_record = _field_observation("obs-004", project_id="PRJ-001")

    repository.add(first_record)
    repository.add(other_project_record)
    repository.add(second_record)
    repository.add(case_variant_record)

    assert repository.list_by_project_id("prj-001") == [first_record, second_record]
    assert repository.list_by_project_id("prj-002") == [other_project_record]
    assert repository.list_by_project_id("PRJ-001") == [case_variant_record]
    assert repository.list_by_project_id(" prj-001 ") == []
    assert repository.list_by_project_id("prj-999") == []


def test_field_observation_repository_filters_by_status_documented_values() -> None:
    repository = FieldObservationRepository()

    assert repository.list_by_status("open") == []

    open_record = _field_observation("obs-001", status="open")
    tracking_record = _field_observation("obs-002", status="tracking")
    closed_record = _field_observation("obs-003", status="closed")
    second_open_record = _field_observation("obs-004", status="open")

    repository.add(open_record)
    repository.add(tracking_record)
    repository.add(closed_record)
    repository.add(second_open_record)

    assert repository.list_by_status("open") == [open_record, second_open_record]
    assert repository.list_by_status("tracking") == [tracking_record]
    assert repository.list_by_status("closed") == [closed_record]
    assert repository.list_by_status("Open") == []
    assert repository.list_by_status(" closed ") == []
    assert repository.list_by_status("review") == []


def test_field_observation_repository_project_and_status_filters_are_independent() -> None:
    repository = FieldObservationRepository()
    project_open_record = _field_observation(
        "obs-001",
        project_id="prj-001",
        status="open",
    )
    project_closed_record = _field_observation(
        "obs-002",
        project_id="prj-001",
        status="closed",
    )
    other_project_open_record = _field_observation(
        "obs-003",
        project_id="prj-002",
        status="open",
    )

    repository.add(project_open_record)
    repository.add(project_closed_record)
    repository.add(other_project_open_record)

    assert repository.list_by_project_id("prj-001") == [
        project_open_record,
        project_closed_record,
    ]
    assert repository.list_by_status("open") == [
        project_open_record,
        other_project_open_record,
    ]


def test_field_observation_repository_filtered_lists_are_copies() -> None:
    repository = FieldObservationRepository()
    first_record = _field_observation("obs-001", project_id="prj-001", status="open")
    second_record = _field_observation("obs-002", project_id="prj-001", status="open")
    other_record = _field_observation("obs-003", project_id="prj-002", status="closed")

    repository.add(first_record)
    repository.add(second_record)
    repository.add(other_record)

    project_records = repository.list_by_project_id("prj-001")
    status_records = repository.list_by_status("open")
    project_records.clear()
    status_records.append(other_record)

    assert repository.list_by_project_id("prj-001") == [first_record, second_record]
    assert repository.list_by_status("open") == [first_record, second_record]
    assert repository.count() == 3


def test_field_observation_repository_filters_include_archived_matching_records() -> None:
    repository = FieldObservationRepository()
    active_record = _field_observation(
        "obs-001",
        project_id="prj-001",
        status="tracking",
    )
    archived_record = _field_observation(
        "obs-002",
        project_id="prj-001",
        status="tracking",
        is_archived=True,
    )

    repository.add(active_record)
    repository.add(archived_record)

    assert repository.list_by_project_id("prj-001") == [active_record, archived_record]
    assert repository.list_by_status("tracking") == [active_record, archived_record]
    assert archived_record.is_archived is True


def test_field_observation_repository_filters_by_location_exact_matches_in_order() -> None:
    repository = FieldObservationRepository()

    assert repository.list_by_location("A Blok 2. Kat") == []

    first_record = _field_observation("obs-001", location="A Blok 2. Kat")
    other_location_record = _field_observation("obs-002", location="B Blok Zemin")
    second_record = _field_observation("obs-003", location="A Blok 2. Kat")
    case_variant_record = _field_observation("obs-004", location="a blok 2. kat")
    whitespace_variant_record = _field_observation(
        "obs-005",
        location=" A Blok 2. Kat ",
    )

    repository.add(first_record)
    repository.add(other_location_record)
    repository.add(second_record)
    repository.add(case_variant_record)
    repository.add(whitespace_variant_record)

    assert repository.list_by_location("A Blok 2. Kat") == [
        first_record,
        second_record,
    ]
    assert repository.list_by_location("B Blok Zemin") == [other_location_record]
    assert repository.list_by_location("a blok 2. kat") == [case_variant_record]
    assert repository.list_by_location(" A Blok 2. Kat ") == [
        whitespace_variant_record,
    ]
    assert repository.list_by_location("C Blok 1. Kat") == []
    assert repository.list_by_location("A BLOK 2. KAT") == []
    assert repository.list_by_location("A Blok 2. Kat ") == []


def test_field_observation_repository_filters_by_category_exact_matches_in_order() -> None:
    repository = FieldObservationRepository()

    assert repository.list_by_category("quality") == []

    first_record = _field_observation("obs-001", category="quality")
    other_category_record = _field_observation("obs-002", category="safety")
    second_record = _field_observation("obs-003", category="quality")
    case_variant_record = _field_observation("obs-004", category="Quality")
    whitespace_variant_record = _field_observation(
        "obs-005",
        category=" quality ",
    )

    repository.add(first_record)
    repository.add(other_category_record)
    repository.add(second_record)
    repository.add(case_variant_record)
    repository.add(whitespace_variant_record)

    assert repository.list_by_category("quality") == [first_record, second_record]
    assert repository.list_by_category("safety") == [other_category_record]
    assert repository.list_by_category("Quality") == [case_variant_record]
    assert repository.list_by_category(" quality ") == [whitespace_variant_record]
    assert repository.list_by_category("coordination") == []
    assert repository.list_by_category("QUALITY") == []
    assert repository.list_by_category("quality ") == []


def test_field_observation_repository_location_category_project_status_filters_are_independent() -> None:
    repository = FieldObservationRepository()
    first_record = _field_observation(
        "obs-001",
        project_id="prj-001",
        location="A Blok 2. Kat",
        category="quality",
        status="open",
    )
    second_record = _field_observation(
        "obs-002",
        project_id="prj-001",
        location="B Blok Zemin",
        category="safety",
        status="tracking",
    )
    third_record = _field_observation(
        "obs-003",
        project_id="prj-002",
        location="A Blok 2. Kat",
        category="safety",
        status="open",
    )

    repository.add(first_record)
    repository.add(second_record)
    repository.add(third_record)

    assert repository.list_by_location("A Blok 2. Kat") == [
        first_record,
        third_record,
    ]
    assert repository.list_by_category("safety") == [second_record, third_record]
    assert repository.list_by_project_id("prj-001") == [first_record, second_record]
    assert repository.list_by_status("open") == [first_record, third_record]


def test_field_observation_repository_location_category_filtered_lists_are_copies() -> None:
    repository = FieldObservationRepository()
    first_record = _field_observation(
        "obs-001",
        location="A Blok 2. Kat",
        category="quality",
    )
    second_record = _field_observation(
        "obs-002",
        location="A Blok 2. Kat",
        category="quality",
    )
    other_record = _field_observation(
        "obs-003",
        location="B Blok Zemin",
        category="safety",
    )

    repository.add(first_record)
    repository.add(second_record)
    repository.add(other_record)

    location_records = repository.list_by_location("A Blok 2. Kat")
    category_records = repository.list_by_category("quality")
    second_location_records = repository.list_by_location("A Blok 2. Kat")
    location_records.clear()
    category_records.append(other_record)

    assert second_location_records is not repository.list_by_location("A Blok 2. Kat")
    assert repository.list_by_location("A Blok 2. Kat") == [
        first_record,
        second_record,
    ]
    assert repository.list_by_category("quality") == [first_record, second_record]
    assert repository.count() == 3


def test_field_observation_repository_location_category_filters_include_archived_records() -> None:
    repository = FieldObservationRepository()
    active_record = _field_observation(
        "obs-001",
        location="A Blok 2. Kat",
        category="quality",
    )
    archived_record = _field_observation(
        "obs-002",
        location="A Blok 2. Kat",
        category="quality",
        is_archived=True,
    )

    repository.add(active_record)
    repository.add(archived_record)

    assert repository.list_by_location("A Blok 2. Kat") == [
        active_record,
        archived_record,
    ]
    assert repository.list_by_category("quality") == [active_record, archived_record]
    assert archived_record.is_archived is True


def test_field_observation_repository_location_category_filters_return_empty_for_empty_repository() -> None:
    repository = FieldObservationRepository()

    assert repository.list_by_location("A Blok 2. Kat") == []
    assert repository.list_by_category("quality") == []


def test_field_observation_repository_location_category_filters_do_not_copy_or_mutate_records() -> None:
    repository = FieldObservationRepository()
    first_record = _field_observation(
        "obs-001",
        location="A Blok 2. Kat",
        category="quality",
        status="tracking",
    )
    second_record = _field_observation(
        "obs-002",
        location="B Blok Zemin",
        category="safety",
        status="closed",
        is_archived=True,
    )
    first_record.reported_to = "Saha ekibi"
    first_record.notes = "Existing note."

    repository.add(first_record)
    repository.add(second_record)

    location_result = repository.list_by_location("A Blok 2. Kat")
    category_result = repository.list_by_category("quality")

    assert location_result == [first_record]
    assert category_result == [first_record]
    assert location_result[0] is first_record
    assert category_result[0] is first_record
    assert repository.count() == 2
    assert repository.list_all() == [first_record, second_record]
    assert first_record.location == "A Blok 2. Kat"
    assert first_record.category == "quality"
    assert first_record.status == "tracking"
    assert first_record.is_archived is False
    assert first_record.reported_to == "Saha ekibi"
    assert first_record.notes == "Existing note."
    assert second_record.status == "closed"
    assert second_record.is_archived is True


def test_field_observation_repository_update_status_returns_none_for_missing_id() -> None:
    repository = FieldObservationRepository()
    record = _field_observation("obs-001", status="open")
    repository.add(record)

    result = repository.update_status("obs-999", "tracking")

    assert result is None
    assert repository.list_all() == [record]
    assert record.status == "open"


def test_field_observation_repository_update_status_from_open_to_tracking() -> None:
    repository = FieldObservationRepository()
    record = _field_observation("obs-001", status="open")
    repository.add(record)

    result = repository.update_status("obs-001", "tracking")

    assert result is record
    assert record.status == "tracking"
    assert repository.find_by_id("obs-001") is record


def test_field_observation_repository_update_status_to_closed_has_no_side_effects() -> None:
    repository = FieldObservationRepository()
    record = _field_observation("obs-001", status="tracking")
    record.reported_at = "2026-07-11T19:00:00"
    record.notes = "Reported to site team."
    repository.add(record)

    result = repository.update_status("obs-001", "closed")

    assert result is record
    assert record.status == "closed"
    assert record.closed_at is None
    assert record.reported_at == "2026-07-11T19:00:00"
    assert record.notes == "Reported to site team."
    assert record.is_archived is False


def test_field_observation_repository_update_status_changes_only_target_record() -> None:
    repository = FieldObservationRepository()
    target_record = _field_observation("obs-001", status="open")
    other_record = _field_observation("obs-002", status="open")

    repository.add(target_record)
    repository.add(other_record)

    result = repository.update_status("obs-001", "tracking")

    assert result is target_record
    assert target_record.status == "tracking"
    assert other_record.status == "open"
    assert repository.list_all() == [target_record, other_record]


def test_field_observation_repository_update_status_is_reflected_in_status_filter() -> None:
    repository = FieldObservationRepository()
    record = _field_observation("obs-001", status="open")
    existing_tracking_record = _field_observation("obs-002", status="tracking")

    repository.add(record)
    repository.add(existing_tracking_record)

    repository.update_status("obs-001", "tracking")

    assert repository.list_by_status("open") == []
    assert repository.list_by_status("tracking") == [record, existing_tracking_record]
    assert repository.count() == 2
    assert repository.list_all() == [record, existing_tracking_record]


def test_field_observation_repository_update_status_allows_archived_record() -> None:
    repository = FieldObservationRepository()
    archived_record = _field_observation(
        "obs-001",
        status="open",
        is_archived=True,
    )
    repository.add(archived_record)

    result = repository.update_status("obs-001", "closed")

    assert result is archived_record
    assert archived_record.status == "closed"
    assert archived_record.is_archived is True
    assert repository.list_by_status("closed") == [archived_record]


def test_field_observation_repository_update_reporting_returns_none_for_missing_id() -> None:
    repository = FieldObservationRepository()
    record = _field_observation("obs-001")
    repository.add(record)

    result = repository.update_reporting(
        "obs-999",
        "Saha ekibi",
        "2026-07-11T20:00:00",
    )

    assert result is None
    assert repository.list_all() == [record]
    assert record.reported_to is None
    assert record.reported_at is None


def test_field_observation_repository_update_reporting_sets_reporting_context() -> None:
    repository = FieldObservationRepository()
    record = _field_observation("obs-001")
    repository.add(record)

    result = repository.update_reporting(
        "obs-001",
        "Kontrol Muhendisi",
        "2026-07-11T20:05:00",
    )

    assert result is record
    assert record.reported_to == "Kontrol Muhendisi"
    assert record.reported_at == "2026-07-11T20:05:00"
    assert repository.find_by_id("obs-001") is record


def test_field_observation_repository_update_reporting_changes_only_reporting_fields() -> None:
    repository = FieldObservationRepository()
    record = _field_observation("obs-001", status="closed", is_archived=True)
    record.closed_at = "2026-07-11T20:10:00"
    record.notes = "Existing official note."
    record.created_by = "fatih"
    repository.add(record)

    result = repository.update_reporting(
        "obs-001",
        "Kalite ekibi",
        "2026-07-11T20:15:00",
    )

    assert result is record
    assert record.reported_to == "Kalite ekibi"
    assert record.reported_at == "2026-07-11T20:15:00"
    assert record.status == "closed"
    assert record.closed_at == "2026-07-11T20:10:00"
    assert record.notes == "Existing official note."
    assert record.created_by == "fatih"
    assert record.is_archived is True


def test_field_observation_repository_update_reporting_changes_only_target_record() -> None:
    repository = FieldObservationRepository()
    target_record = _field_observation("obs-001")
    other_record = _field_observation("obs-002")

    repository.add(target_record)
    repository.add(other_record)

    result = repository.update_reporting(
        "obs-001",
        "Proje muduru",
        "2026-07-11T20:20:00",
    )

    assert result is target_record
    assert target_record.reported_to == "Proje muduru"
    assert target_record.reported_at == "2026-07-11T20:20:00"
    assert other_record.reported_to is None
    assert other_record.reported_at is None
    assert repository.list_all() == [target_record, other_record]


def test_field_observation_repository_update_reporting_preserves_exact_strings() -> None:
    repository = FieldObservationRepository()
    record = _field_observation("obs-001")
    repository.add(record)

    result = repository.update_reporting(
        "obs-001",
        "  Kontrol Ekibi  ",
        " 2026-07-11T20:25:00 ",
    )

    assert result is record
    assert record.reported_to == "  Kontrol Ekibi  "
    assert record.reported_at == " 2026-07-11T20:25:00 "


def test_field_observation_repository_update_reporting_allows_archived_record() -> None:
    repository = FieldObservationRepository()
    archived_record = _field_observation("obs-001", is_archived=True)
    repository.add(archived_record)

    result = repository.update_reporting(
        "obs-001",
        "Arsiv kontrol ekibi",
        "2026-07-11T20:30:00",
    )

    assert result is archived_record
    assert archived_record.reported_to == "Arsiv kontrol ekibi"
    assert archived_record.reported_at == "2026-07-11T20:30:00"
    assert archived_record.is_archived is True


def test_field_observation_repository_update_reporting_keeps_record_count_stable() -> None:
    repository = FieldObservationRepository()
    first_record = _field_observation("obs-001")
    second_record = _field_observation("obs-002")

    repository.add(first_record)
    repository.add(second_record)

    result = repository.update_reporting(
        "obs-001",
        "Saha sefi",
        "2026-07-11T20:35:00",
    )

    assert result is first_record
    assert repository.count() == 2
    assert repository.list_all() == [first_record, second_record]


def test_nonconformity_repository_adds_and_lists_records() -> None:
    repository = NonconformityRepository()
    record = NonconformityRecord(
        nonconformity_id="NCR-001",
        project_id="prj-001",
        date="2026-07-05",
        title="Korkuluk eksigi",
        description="Kuzey cephede korkuluk eksigi tespit edildi.",
    )

    repository.add(record)

    assert repository.list_all() == [record]


def test_nonconformity_repository_finds_by_id_and_returns_none_for_missing_id() -> None:
    repository = NonconformityRepository()
    record = NonconformityRecord(
        nonconformity_id="NCR-002",
        project_id="prj-001",
        date="2026-07-06",
        title="Beton yuzey kusuru",
        description="Perde beton yuzeyinde segregasyon izi goruldu.",
    )

    repository.add(record)

    assert repository.find_by_id("NCR-002") == record
    assert repository.find_by_id("NCR-999") is None


def test_nonconformity_repository_rejects_duplicate_id_and_accepts_different_ids() -> None:
    repository = NonconformityRepository()
    first_record = NonconformityRecord(
        nonconformity_id="NCR-003",
        project_id="prj-001",
        date="2026-07-07",
        title="Merdiven boslugu koruma eksigi",
        description="Merdiven boslugunda gecici koruma eksigi tespit edildi.",
    )
    duplicate_record = NonconformityRecord(
        nonconformity_id="NCR-003",
        project_id="prj-001",
        date="2026-07-08",
        title="Ayni NCR numarasi",
        description="Ayni kimlikle ikinci kayit eklenmemeli.",
    )
    different_record = NonconformityRecord(
        nonconformity_id="NCR-004",
        project_id="prj-001",
        date="2026-07-09",
        title="Iskele baglanti kontrolu",
        description="Iskele baglantisi icin ayri NCR kaydi acildi.",
    )

    repository.add(first_record)

    with pytest.raises(ValueError, match="NCR-003"):
        repository.add(duplicate_record)

    repository.add(different_record)

    assert repository.list_all() == [first_record, different_record]
    assert repository.find_by_id("NCR-004") == different_record


def test_nonconformity_repository_lists_records_by_status() -> None:
    repository = NonconformityRepository()
    open_record = NonconformityRecord(
        nonconformity_id="NCR-005",
        project_id="prj-001",
        date="2026-07-10",
        title="Acil korkuluk kontrolu",
        description="Kuzey cephe korkuluk eksigi acik takipte.",
        status="open",
    )
    closed_record = NonconformityRecord(
        nonconformity_id="NCR-006",
        project_id="prj-001",
        date="2026-07-11",
        title="Kapatilan beton yuzey kusuru",
        description="Beton yuzey kusuru duzeltildi ve kapatildi.",
        status="closed",
    )
    second_open_record = NonconformityRecord(
        nonconformity_id="NCR-007",
        project_id="prj-001",
        date="2026-07-12",
        title="Devam eden izolasyon kontrolu",
        description="Izolasyon detayi icin takip devam ediyor.",
        status="open",
    )

    repository.add(open_record)
    repository.add(closed_record)
    repository.add(second_open_record)

    assert repository.list_by_status("open") == [open_record, second_open_record]
    assert repository.list_by_status("closed") == [closed_record]
    assert repository.list_by_status("in_review") == []


def test_nonconformity_repository_lists_records_by_responsible_party() -> None:
    repository = NonconformityRepository()
    ahmet_record = NonconformityRecord(
        nonconformity_id="NCR-008",
        project_id="prj-001",
        date="2026-07-13",
        title="Korkuluk sorumluluk takibi",
        description="Korkuluk eksigi Ahmet sorumlulugunda takip ediliyor.",
        responsible_party="Ahmet",
    )
    mehmet_record = NonconformityRecord(
        nonconformity_id="NCR-009",
        project_id="prj-001",
        date="2026-07-14",
        title="Beton yuzey sorumluluk takibi",
        description="Beton yuzey kusuru Mehmet sorumlulugunda takip ediliyor.",
        responsible_party="Mehmet",
    )
    second_ahmet_record = NonconformityRecord(
        nonconformity_id="NCR-010",
        project_id="prj-001",
        date="2026-07-15",
        title="Izolasyon sorumluluk takibi",
        description="Izolasyon detayi Ahmet sorumlulugunda takip ediliyor.",
        responsible_party="Ahmet",
    )

    repository.add(ahmet_record)
    repository.add(mehmet_record)
    repository.add(second_ahmet_record)

    assert repository.list_by_responsible_party("Ahmet") == [
        ahmet_record,
        second_ahmet_record,
    ]
    assert repository.list_by_responsible_party("Mehmet") == [mehmet_record]
    assert repository.list_by_responsible_party("Ayse") == []


def test_nonconformity_repository_get_status_summary_counts_records_by_status() -> None:
    repository = NonconformityRepository()
    open_record = NonconformityRecord(
        nonconformity_id="NCR-011",
        project_id="prj-001",
        date="2026-07-16",
        title="Acik korkuluk NCR",
        description="Korkuluk eksigi acik durumda.",
        status="open",
    )
    second_open_record = NonconformityRecord(
        nonconformity_id="NCR-012",
        project_id="prj-001",
        date="2026-07-17",
        title="Acik izolasyon NCR",
        description="Izolasyon detayi acik durumda.",
        status="open",
    )
    closed_record = NonconformityRecord(
        nonconformity_id="NCR-013",
        project_id="prj-001",
        date="2026-07-18",
        title="Kapatilan beton NCR",
        description="Beton yuzey kusuru kapatildi.",
        status="closed",
    )
    in_progress_record = NonconformityRecord(
        nonconformity_id="NCR-014",
        project_id="prj-001",
        date="2026-07-19",
        title="Devam eden iskele NCR",
        description="Iskele baglanti kontrolu devam ediyor.",
        status="in_progress",
    )

    repository.add(open_record)
    repository.add(second_open_record)
    repository.add(closed_record)
    repository.add(in_progress_record)

    assert repository.get_status_summary() == {
        "open": 2,
        "closed": 1,
        "in_progress": 1,
    }
    assert repository.list_all() == [
        open_record,
        second_open_record,
        closed_record,
        in_progress_record,
    ]


def test_nonconformity_repository_get_status_summary_returns_empty_dict_when_empty() -> None:
    repository = NonconformityRepository()

    assert repository.get_status_summary() == {}


def test_nonconformity_repository_get_responsible_party_summary_counts_records() -> None:
    repository = NonconformityRepository()
    first_ahmet_record = NonconformityRecord(
        nonconformity_id="NCR-015",
        project_id="prj-001",
        date="2026-07-20",
        title="Ahmet korkuluk NCR",
        description="Korkuluk eksigi Ahmet sorumlulugunda.",
        responsible_party="Ahmet",
    )
    mehmet_record = NonconformityRecord(
        nonconformity_id="NCR-016",
        project_id="prj-001",
        date="2026-07-21",
        title="Mehmet beton NCR",
        description="Beton yuzey kusuru Mehmet sorumlulugunda.",
        responsible_party="Mehmet",
    )
    second_ahmet_record = NonconformityRecord(
        nonconformity_id="NCR-017",
        project_id="prj-001",
        date="2026-07-22",
        title="Ahmet izolasyon NCR",
        description="Izolasyon detayi Ahmet sorumlulugunda.",
        responsible_party="Ahmet",
    )
    unassigned_record = NonconformityRecord(
        nonconformity_id="NCR-018",
        project_id="prj-001",
        date="2026-07-23",
        title="Atanmamis NCR",
        description="Sorumlu taraf henuz belirlenmedi.",
    )

    repository.add(first_ahmet_record)
    repository.add(mehmet_record)
    repository.add(second_ahmet_record)
    repository.add(unassigned_record)

    assert repository.get_responsible_party_summary() == {
        "Ahmet": 2,
        "Mehmet": 1,
        "unassigned": 1,
    }
    assert repository.list_all() == [
        first_ahmet_record,
        mehmet_record,
        second_ahmet_record,
        unassigned_record,
    ]


def test_nonconformity_repository_get_responsible_party_summary_returns_empty_dict_when_empty() -> None:
    repository = NonconformityRepository()

    assert repository.get_responsible_party_summary() == {}


def test_nonconformity_repository_get_overview_summary_counts_key_totals() -> None:
    repository = NonconformityRepository()
    open_assigned_record = NonconformityRecord(
        nonconformity_id="NCR-019",
        project_id="prj-001",
        date="2026-07-24",
        title="Acik atanmis NCR",
        description="Ahmet sorumlulugunda acik NCR.",
        responsible_party="Ahmet",
        status="open",
    )
    second_open_assigned_record = NonconformityRecord(
        nonconformity_id="NCR-020",
        project_id="prj-001",
        date="2026-07-25",
        title="Ikinci acik atanmis NCR",
        description="Mehmet sorumlulugunda acik NCR.",
        responsible_party="Mehmet",
        status="open",
    )
    closed_assigned_record = NonconformityRecord(
        nonconformity_id="NCR-021",
        project_id="prj-001",
        date="2026-07-26",
        title="Kapali atanmis NCR",
        description="Kapatilan NCR kaydi.",
        responsible_party="Ahmet",
        status="closed",
    )
    in_progress_assigned_record = NonconformityRecord(
        nonconformity_id="NCR-022",
        project_id="prj-001",
        date="2026-07-27",
        title="Devam eden atanmis NCR",
        description="Devam eden NCR kaydi.",
        responsible_party="Kalite ekibi",
        status="in_progress",
    )
    unassigned_record = NonconformityRecord(
        nonconformity_id="NCR-023",
        project_id="prj-001",
        date="2026-07-28",
        title="Atanmamis NCR",
        description="Sorumlu taraf henuz belirlenmedi.",
        status="review",
    )

    repository.add(open_assigned_record)
    repository.add(second_open_assigned_record)
    repository.add(closed_assigned_record)
    repository.add(in_progress_assigned_record)
    repository.add(unassigned_record)

    assert repository.get_overview_summary() == {
        "total": 5,
        "open": 2,
        "closed": 1,
        "assigned": 4,
        "unassigned": 1,
    }
    assert repository.list_all() == [
        open_assigned_record,
        second_open_assigned_record,
        closed_assigned_record,
        in_progress_assigned_record,
        unassigned_record,
    ]


def test_nonconformity_repository_get_overview_summary_returns_zero_counts_when_empty() -> None:
    repository = NonconformityRepository()

    assert repository.get_overview_summary() == {
        "total": 0,
        "open": 0,
        "closed": 0,
        "assigned": 0,
        "unassigned": 0,
    }


def test_nonconformity_repository_update_status_updates_record_and_summaries() -> None:
    repository = NonconformityRepository()
    record = NonconformityRecord(
        nonconformity_id="NCR-024",
        project_id="prj-001",
        date="2026-07-29",
        title="Status guncellenecek NCR",
        description="Bu kaydin durumu repository icinde guncellenecek.",
        status="open",
    )
    closed_record = NonconformityRecord(
        nonconformity_id="NCR-025",
        project_id="prj-001",
        date="2026-07-30",
        title="Kapali referans NCR",
        description="Kapali durumdaki referans kayit.",
        status="closed",
    )

    repository.add(record)
    repository.add(closed_record)

    updated_record = repository.update_status("NCR-024", "in_progress")

    assert updated_record == record
    assert updated_record is record
    assert record.status == "in_progress"
    assert repository.list_all() == [record, closed_record]
    assert repository.list_by_status("open") == []
    assert repository.list_by_status("in_progress") == [record]
    assert repository.get_status_summary() == {
        "in_progress": 1,
        "closed": 1,
    }


def test_nonconformity_repository_update_status_returns_none_for_missing_id() -> None:
    repository = NonconformityRepository()
    record = NonconformityRecord(
        nonconformity_id="NCR-026",
        project_id="prj-001",
        date="2026-07-31",
        title="Degismeyecek NCR",
        description="Eksik id guncellemesi bu kaydi degistirmemeli.",
        status="open",
    )

    repository.add(record)

    result = repository.update_status("NCR-999", "closed")

    assert result is None
    assert record.status == "open"
    assert repository.list_all() == [record]


def test_nonconformity_repository_update_responsible_party_updates_record_and_summaries() -> None:
    repository = NonconformityRepository()
    record = NonconformityRecord(
        nonconformity_id="NCR-027",
        project_id="prj-001",
        date="2026-08-01",
        title="Sorumlusu guncellenecek NCR",
        description="Bu kaydin sorumlu tarafi repository icinde guncellenecek.",
        responsible_party="Ahmet",
        status="open",
    )
    other_record = NonconformityRecord(
        nonconformity_id="NCR-028",
        project_id="prj-001",
        date="2026-08-02",
        title="Referans sorumlu NCR",
        description="Diger sorumlu tarafa ait referans kayit.",
        responsible_party="Mehmet",
        status="closed",
    )

    repository.add(record)
    repository.add(other_record)

    updated_record = repository.update_responsible_party("NCR-027", "Kalite ekibi")

    assert updated_record == record
    assert updated_record is record
    assert record.responsible_party == "Kalite ekibi"
    assert repository.list_all() == [record, other_record]
    assert repository.list_by_responsible_party("Ahmet") == []
    assert repository.list_by_responsible_party("Kalite ekibi") == [record]
    assert repository.get_responsible_party_summary() == {
        "Kalite ekibi": 1,
        "Mehmet": 1,
    }
    assert repository.get_overview_summary() == {
        "total": 2,
        "open": 1,
        "closed": 1,
        "assigned": 2,
        "unassigned": 0,
    }


def test_nonconformity_repository_update_responsible_party_returns_none_for_missing_id_and_allows_none() -> None:
    repository = NonconformityRepository()
    record = NonconformityRecord(
        nonconformity_id="NCR-029",
        project_id="prj-001",
        date="2026-08-03",
        title="Sorumlusu kaldirilacak NCR",
        description="Bu kaydin sorumlu tarafi None olarak guncellenecek.",
        responsible_party="Ahmet",
        status="open",
    )

    repository.add(record)

    missing_result = repository.update_responsible_party("NCR-999", "Mehmet")
    updated_record = repository.update_responsible_party("NCR-029", None)

    assert missing_result is None
    assert updated_record == record
    assert updated_record is record
    assert record.responsible_party is None
    assert repository.list_all() == [record]
    assert repository.list_by_responsible_party("Ahmet") == []
    assert repository.get_responsible_party_summary() == {"unassigned": 1}
    assert repository.get_overview_summary() == {
        "total": 1,
        "open": 1,
        "closed": 0,
        "assigned": 0,
        "unassigned": 1,
    }


def test_nonconformity_repository_exists_returns_boolean_for_record_presence() -> None:
    repository = NonconformityRepository()
    record = NonconformityRecord(
        nonconformity_id="NCR-030",
        project_id="prj-001",
        date="2026-08-04",
        title="Varligi kontrol edilecek NCR",
        description="Bu kayit exists davranisi icin referans olacak.",
    )

    repository.add(record)

    assert repository.exists("NCR-030") is True
    assert repository.exists("NCR-999") is False
    assert repository.find_by_id("NCR-030") == record
    assert repository.list_all() == [record]


def test_nonconformity_repository_count_returns_total_record_count() -> None:
    repository = NonconformityRepository()
    first_record = NonconformityRecord(
        nonconformity_id="NCR-031",
        project_id="prj-001",
        date="2026-08-05",
        title="Ilk sayim NCR",
        description="Toplam sayim icin ilk kayit.",
    )
    second_record = NonconformityRecord(
        nonconformity_id="NCR-032",
        project_id="prj-001",
        date="2026-08-06",
        title="Ikinci sayim NCR",
        description="Toplam sayim icin ikinci kayit.",
    )

    assert repository.count() == 0

    repository.add(first_record)
    repository.add(second_record)

    assert repository.count() == 2
    assert repository.list_all() == [first_record, second_record]


def test_nonconformity_repository_count_by_status_returns_matching_record_count() -> None:
    repository = NonconformityRepository()
    first_open_record = NonconformityRecord(
        nonconformity_id="NCR-033",
        project_id="prj-001",
        date="2026-08-07",
        title="Ilk acik NCR",
        description="Status sayimi icin ilk acik kayit.",
        status="open",
    )
    closed_record = NonconformityRecord(
        nonconformity_id="NCR-034",
        project_id="prj-001",
        date="2026-08-08",
        title="Kapali NCR",
        description="Status sayimi icin kapali kayit.",
        status="closed",
    )
    second_open_record = NonconformityRecord(
        nonconformity_id="NCR-035",
        project_id="prj-001",
        date="2026-08-09",
        title="Ikinci acik NCR",
        description="Status sayimi icin ikinci acik kayit.",
        status="open",
    )

    repository.add(first_open_record)
    repository.add(closed_record)
    repository.add(second_open_record)

    assert repository.count_by_status("open") == 2
    assert repository.count_by_status("closed") == 1
    assert repository.count_by_status("verified") == 0
    assert repository.list_by_status("open") == [first_open_record, second_open_record]
    assert repository.list_all() == [
        first_open_record,
        closed_record,
        second_open_record,
    ]


def test_nonconformity_repository_lists_active_records_in_insert_order() -> None:
    repository = NonconformityRepository()
    first_active_record = NonconformityRecord(
        nonconformity_id="NCR-036",
        project_id="prj-001",
        date="2026-08-10",
        title="Ilk aktif NCR",
        description="Aktif filtreleme icin ilk kayit.",
    )
    archived_record = NonconformityRecord(
        nonconformity_id="NCR-037",
        project_id="prj-001",
        date="2026-08-11",
        title="Arsiv NCR",
        description="Aktif listede yer almamasi gereken kayit.",
        is_archived=True,
    )
    second_active_record = NonconformityRecord(
        nonconformity_id="NCR-038",
        project_id="prj-001",
        date="2026-08-12",
        title="Ikinci aktif NCR",
        description="Aktif filtreleme icin ikinci kayit.",
        is_archived=False,
    )

    repository.add(first_active_record)
    repository.add(archived_record)
    repository.add(second_active_record)

    assert repository.list_active() == [first_active_record, second_active_record]
    assert repository.list_all() == [
        first_active_record,
        archived_record,
        second_active_record,
    ]


def test_nonconformity_repository_lists_archived_records_and_returns_empty_list_when_missing() -> None:
    repository = NonconformityRepository()
    active_record = NonconformityRecord(
        nonconformity_id="NCR-039",
        project_id="prj-001",
        date="2026-08-13",
        title="Aktif NCR",
        description="Arsiv listesinde yer almamasi gereken kayit.",
    )
    first_archived_record = NonconformityRecord(
        nonconformity_id="NCR-040",
        project_id="prj-001",
        date="2026-08-14",
        title="Ilk arsiv NCR",
        description="Arsiv filtreleme icin ilk kayit.",
        is_archived=True,
    )
    second_archived_record = NonconformityRecord(
        nonconformity_id="NCR-041",
        project_id="prj-001",
        date="2026-08-15",
        title="Ikinci arsiv NCR",
        description="Arsiv filtreleme icin ikinci kayit.",
        is_archived=True,
    )
    active_only_repository = NonconformityRepository()

    repository.add(active_record)
    repository.add(first_archived_record)
    repository.add(second_archived_record)
    active_only_repository.add(active_record)

    assert repository.list_archived() == [
        first_archived_record,
        second_archived_record,
    ]
    assert active_only_repository.list_archived() == []
    assert repository.list_all() == [
        active_record,
        first_archived_record,
        second_archived_record,
    ]


def test_nonconformity_repository_archive_marks_record_archived_and_preserves_status_and_order() -> None:
    repository = NonconformityRepository()
    record = NonconformityRecord(
        nonconformity_id="NCR-042",
        project_id="prj-001",
        date="2026-08-16",
        title="Arsivlenecek NCR",
        description="Bu kayit repository icinde arsivlenecek.",
        status="in_progress",
    )
    other_record = NonconformityRecord(
        nonconformity_id="NCR-043",
        project_id="prj-001",
        date="2026-08-17",
        title="Aktif kalacak NCR",
        description="Bu kayit aktif listede kalacak.",
        status="open",
    )

    repository.add(record)
    repository.add(other_record)

    archived_record = repository.archive("NCR-042")

    assert archived_record == record
    assert archived_record is record
    assert record.is_archived is True
    assert record.status == "in_progress"
    assert repository.list_archived() == [record]
    assert repository.list_active() == [other_record]
    assert repository.list_all() == [record, other_record]


def test_nonconformity_repository_archive_returns_none_for_missing_id() -> None:
    repository = NonconformityRepository()
    record = NonconformityRecord(
        nonconformity_id="NCR-044",
        project_id="prj-001",
        date="2026-08-18",
        title="Degismeyecek NCR",
        description="Eksik id arsivleme denemesi bu kaydi degistirmemeli.",
        status="open",
    )

    repository.add(record)

    result = repository.archive("NCR-999")

    assert result is None
    assert record.is_archived is False
    assert record.status == "open"
    assert repository.list_active() == [record]
    assert repository.list_archived() == []
    assert repository.list_all() == [record]


def test_nonconformity_repository_restore_marks_record_active_and_preserves_status_and_order() -> None:
    repository = NonconformityRepository()
    record = NonconformityRecord(
        nonconformity_id="NCR-045",
        project_id="prj-001",
        date="2026-08-19",
        title="Aktife alinacak NCR",
        description="Bu kayit repository icinde arsivden cikarilacak.",
        status="closed",
        is_archived=True,
    )
    other_record = NonconformityRecord(
        nonconformity_id="NCR-046",
        project_id="prj-001",
        date="2026-08-20",
        title="Arsivde kalacak NCR",
        description="Bu kayit arsiv listesinde kalacak.",
        status="open",
        is_archived=True,
    )

    repository.add(record)
    repository.add(other_record)

    restored_record = repository.restore("NCR-045")

    assert restored_record == record
    assert restored_record is record
    assert record.is_archived is False
    assert record.status == "closed"
    assert repository.list_active() == [record]
    assert repository.list_archived() == [other_record]
    assert repository.list_all() == [record, other_record]


def test_nonconformity_repository_restore_returns_none_for_missing_id() -> None:
    repository = NonconformityRepository()
    record = NonconformityRecord(
        nonconformity_id="NCR-047",
        project_id="prj-001",
        date="2026-08-21",
        title="Arsivde kalacak NCR",
        description="Eksik id restore denemesi bu kaydi degistirmemeli.",
        status="closed",
        is_archived=True,
    )

    repository.add(record)

    result = repository.restore("NCR-999")

    assert result is None
    assert record.is_archived is True
    assert record.status == "closed"
    assert repository.list_active() == []
    assert repository.list_archived() == [record]
    assert repository.list_all() == [record]


def test_nonconformity_repository_get_archive_summary_returns_zero_counts_when_empty() -> None:
    repository = NonconformityRepository()

    assert repository.get_archive_summary() == {
        "active": 0,
        "archived": 0,
        "total": 0,
    }


def test_nonconformity_repository_get_archive_summary_counts_active_and_archived_records() -> None:
    repository = NonconformityRepository()
    first_active_record = NonconformityRecord(
        nonconformity_id="NCR-048",
        project_id="prj-001",
        date="2026-08-22",
        title="Ilk aktif NCR",
        description="Arsiv ozeti icin aktif kayit.",
    )
    second_active_record = NonconformityRecord(
        nonconformity_id="NCR-049",
        project_id="prj-001",
        date="2026-08-23",
        title="Ikinci aktif NCR",
        description="Arsiv ozeti icin ikinci aktif kayit.",
    )
    first_archived_record = NonconformityRecord(
        nonconformity_id="NCR-050",
        project_id="prj-001",
        date="2026-08-24",
        title="Ilk arsiv NCR",
        description="Arsiv ozeti icin arsiv kaydi.",
        is_archived=True,
    )
    second_archived_record = NonconformityRecord(
        nonconformity_id="NCR-051",
        project_id="prj-001",
        date="2026-08-25",
        title="Ikinci arsiv NCR",
        description="Arsiv ozeti icin ikinci arsiv kaydi.",
        is_archived=True,
    )

    repository.add(first_active_record)
    repository.add(first_archived_record)
    repository.add(second_active_record)
    repository.add(second_archived_record)

    assert repository.get_archive_summary() == {
        "active": 2,
        "archived": 2,
        "total": 4,
    }
    assert repository.list_all() == [
        first_active_record,
        first_archived_record,
        second_active_record,
        second_archived_record,
    ]


def test_nonconformity_repository_get_archive_summary_updates_after_restore() -> None:
    repository = NonconformityRepository()
    active_record = NonconformityRecord(
        nonconformity_id="NCR-052",
        project_id="prj-001",
        date="2026-08-26",
        title="Aktif NCR",
        description="Restore sonrasi ozet icin aktif kayit.",
    )
    archived_record = NonconformityRecord(
        nonconformity_id="NCR-053",
        project_id="prj-001",
        date="2026-08-27",
        title="Restore edilecek NCR",
        description="Restore sonrasi ozet icin arsiv kaydi.",
        is_archived=True,
    )

    repository.add(active_record)
    repository.add(archived_record)

    assert repository.get_archive_summary() == {
        "active": 1,
        "archived": 1,
        "total": 2,
    }

    restored_record = repository.restore("NCR-053")

    assert restored_record == archived_record
    assert repository.get_archive_summary() == {
        "active": 2,
        "archived": 0,
        "total": 2,
    }
    assert repository.list_all() == [active_record, archived_record]


def test_nonconformity_repository_list_archived_returns_empty_list_when_repository_is_empty() -> None:
    repository = NonconformityRepository()

    assert repository.list_archived() == []


def test_nonconformity_repository_list_archived_returns_empty_list_when_only_active_records_exist() -> None:
    repository = NonconformityRepository()
    first_active_record = NonconformityRecord(
        nonconformity_id="NCR-054",
        project_id="prj-001",
        date="2026-08-28",
        title="Aktif NCR 054",
        description="Arsiv listesinde gorunmemesi gereken aktif kayit.",
    )
    second_active_record = NonconformityRecord(
        nonconformity_id="NCR-055",
        project_id="prj-001",
        date="2026-08-29",
        title="Aktif NCR 055",
        description="Arsiv listesinde gorunmemesi gereken ikinci aktif kayit.",
    )

    repository.add(first_active_record)
    repository.add(second_active_record)

    assert repository.list_archived() == []
    assert repository.list_all() == [first_active_record, second_active_record]


def test_nonconformity_repository_list_archived_excludes_restored_records() -> None:
    repository = NonconformityRepository()
    first_record = NonconformityRecord(
        nonconformity_id="NCR-056",
        project_id="prj-001",
        date="2026-08-30",
        title="Restore edilecek arsiv NCR",
        description="Restore sonrasi arsiv listesinden cikmali.",
    )
    second_record = NonconformityRecord(
        nonconformity_id="NCR-057",
        project_id="prj-001",
        date="2026-08-31",
        title="Arsivde kalacak NCR",
        description="Restore sonrasi arsiv listesinde kalmali.",
    )

    repository.add(first_record)
    repository.add(second_record)
    repository.archive("NCR-056")
    repository.archive("NCR-057")

    assert repository.list_archived() == [first_record, second_record]

    repository.restore("NCR-056")

    assert repository.list_archived() == [second_record]
    assert repository.list_active() == [first_record]
    assert repository.list_all() == [first_record, second_record]


def test_nonconformity_repository_list_active_returns_empty_list_when_repository_is_empty() -> None:
    repository = NonconformityRepository()

    assert repository.list_active() == []


def test_nonconformity_repository_list_active_returns_all_records_when_only_active_records_exist() -> None:
    repository = NonconformityRepository()
    first_record = NonconformityRecord(
        nonconformity_id="NCR-058",
        project_id="prj-001",
        date="2026-09-01",
        title="Aktif NCR 058",
        description="Aktif listede gorunmesi gereken ilk kayit.",
    )
    second_record = NonconformityRecord(
        nonconformity_id="NCR-059",
        project_id="prj-001",
        date="2026-09-02",
        title="Aktif NCR 059",
        description="Aktif listede gorunmesi gereken ikinci kayit.",
    )

    repository.add(first_record)
    repository.add(second_record)

    assert repository.list_active() == [first_record, second_record]
    assert repository.list_archived() == []


def test_nonconformity_repository_list_active_excludes_archived_records() -> None:
    repository = NonconformityRepository()
    first_record = NonconformityRecord(
        nonconformity_id="NCR-060",
        project_id="prj-001",
        date="2026-09-03",
        title="Aktif kalacak NCR",
        description="Aktif listede kalmasi gereken kayit.",
    )
    second_record = NonconformityRecord(
        nonconformity_id="NCR-061",
        project_id="prj-001",
        date="2026-09-04",
        title="Arsivlenecek NCR",
        description="Aktif listeden cikmasi gereken kayit.",
    )

    repository.add(first_record)
    repository.add(second_record)
    repository.archive("NCR-061")

    assert repository.list_active() == [first_record]
    assert repository.list_archived() == [second_record]
    assert repository.list_all() == [first_record, second_record]


def test_nonconformity_repository_list_active_includes_restored_records() -> None:
    repository = NonconformityRepository()
    first_record = NonconformityRecord(
        nonconformity_id="NCR-062",
        project_id="prj-001",
        date="2026-09-05",
        title="Restore edilecek NCR",
        description="Restore sonrasi aktif listeye donmesi gereken kayit.",
    )
    second_record = NonconformityRecord(
        nonconformity_id="NCR-063",
        project_id="prj-001",
        date="2026-09-06",
        title="Aktif kalan NCR",
        description="Aktif listede surekli kalacak kayit.",
    )

    repository.add(first_record)
    repository.add(second_record)
    repository.archive("NCR-062")

    assert repository.list_active() == [second_record]

    repository.restore("NCR-062")

    assert repository.list_active() == [first_record, second_record]
    assert repository.list_archived() == []
    assert repository.list_all() == [first_record, second_record]


def test_nonconformity_repository_list_all_returns_empty_list_when_repository_is_empty() -> None:
    repository = NonconformityRepository()

    assert repository.list_all() == []


def test_nonconformity_repository_list_all_returns_all_active_records() -> None:
    repository = NonconformityRepository()
    first_record = NonconformityRecord(
        nonconformity_id="NCR-064",
        project_id="prj-001",
        date="2026-09-07",
        title="Tum liste aktif NCR 064",
        description="Tum kayit listesinde gorunmesi gereken aktif kayit.",
    )
    second_record = NonconformityRecord(
        nonconformity_id="NCR-065",
        project_id="prj-001",
        date="2026-09-08",
        title="Tum liste aktif NCR 065",
        description="Tum kayit listesinde gorunmesi gereken ikinci aktif kayit.",
    )

    repository.add(first_record)
    repository.add(second_record)

    assert repository.list_all() == [first_record, second_record]
    assert repository.list_active() == [first_record, second_record]
    assert repository.list_archived() == []


def test_nonconformity_repository_list_all_includes_active_and_archived_records() -> None:
    repository = NonconformityRepository()
    first_record = NonconformityRecord(
        nonconformity_id="NCR-066",
        project_id="prj-001",
        date="2026-09-09",
        title="Tum listede aktif NCR",
        description="Tum listede aktif olarak kalacak kayit.",
    )
    second_record = NonconformityRecord(
        nonconformity_id="NCR-067",
        project_id="prj-001",
        date="2026-09-10",
        title="Tum listede arsiv NCR",
        description="Tum listede arsivlenmis olarak kalacak kayit.",
    )

    repository.add(first_record)
    repository.add(second_record)
    repository.archive("NCR-067")

    assert repository.list_all() == [first_record, second_record]
    assert repository.list_active() == [first_record]
    assert repository.list_archived() == [second_record]


def test_nonconformity_repository_list_all_is_unchanged_after_restore() -> None:
    repository = NonconformityRepository()
    first_record = NonconformityRecord(
        nonconformity_id="NCR-068",
        project_id="prj-001",
        date="2026-09-11",
        title="Restore sonrasi tum liste NCR",
        description="Restore edilse de tum listede kalacak kayit.",
    )
    second_record = NonconformityRecord(
        nonconformity_id="NCR-069",
        project_id="prj-001",
        date="2026-09-12",
        title="Tum listede sabit NCR",
        description="Tum listede sirasi korunacak kayit.",
    )

    repository.add(first_record)
    repository.add(second_record)
    repository.archive("NCR-068")

    before_restore = repository.list_all()

    repository.restore("NCR-068")

    assert before_restore == [first_record, second_record]
    assert repository.list_all() == [first_record, second_record]
    assert repository.count() == 2
    assert repository.list_active() == [first_record, second_record]
    assert repository.list_archived() == []


def test_nonconformity_repository_archive_listing_summary_stay_consistent() -> None:
    repository = NonconformityRepository()
    open_record = NonconformityRecord(
        nonconformity_id="NCR-070",
        project_id="prj-001",
        date="2026-09-13",
        title="Acik NCR",
        description="Butunluk testi icin acik kayit.",
        status="open",
    )
    in_progress_record = NonconformityRecord(
        nonconformity_id="NCR-071",
        project_id="prj-001",
        date="2026-09-14",
        title="Devam eden NCR",
        description="Butunluk testi icin devam eden kayit.",
        status="in_progress",
    )
    closed_record = NonconformityRecord(
        nonconformity_id="NCR-072",
        project_id="prj-001",
        date="2026-09-15",
        title="Kapali NCR",
        description="Butunluk testi icin kapali kayit.",
        status="closed",
    )

    repository.add(open_record)
    repository.add(in_progress_record)
    repository.add(closed_record)

    assert [record.nonconformity_id for record in repository.list_all()] == [
        "NCR-070",
        "NCR-071",
        "NCR-072",
    ]
    assert repository.list_active() == [open_record, in_progress_record, closed_record]
    assert repository.list_archived() == []
    assert repository.get_archive_summary() == {
        "active": 3,
        "archived": 0,
        "total": 3,
    }

    repository.archive("NCR-071")
    repository.archive("NCR-072")

    assert [record.title for record in repository.list_all()] == [
        "Acik NCR",
        "Devam eden NCR",
        "Kapali NCR",
    ]
    assert repository.list_active() == [open_record]
    assert repository.list_archived() == [in_progress_record, closed_record]
    assert repository.get_archive_summary() == {
        "active": 1,
        "archived": 2,
        "total": 3,
    }
    assert open_record.status == "open"
    assert in_progress_record.status == "in_progress"
    assert closed_record.status == "closed"

    restored_record = repository.restore("NCR-071")

    assert restored_record == in_progress_record
    assert repository.list_active() == [open_record, in_progress_record]
    assert repository.list_archived() == [closed_record]
    assert repository.list_all() == [open_record, in_progress_record, closed_record]
    assert repository.get_archive_summary() == {
        "active": 2,
        "archived": 1,
        "total": 3,
    }
    assert repository.count() == 3
    assert open_record.status == "open"
    assert in_progress_record.status == "in_progress"
    assert closed_record.status == "closed"


def test_nonconformity_repository_find_by_id_returns_none_when_repository_is_empty() -> None:
    repository = NonconformityRepository()

    assert repository.find_by_id("missing-id") is None


def test_nonconformity_repository_find_by_id_returns_active_record() -> None:
    repository = NonconformityRepository()
    record = NonconformityRecord(
        nonconformity_id="NCR-073",
        project_id="prj-001",
        date="2026-09-16",
        title="Id ile bulunacak aktif NCR",
        description="Aktif kayit id ile bulunmali.",
        status="open",
    )

    repository.add(record)

    result = repository.find_by_id("NCR-073")

    assert result == record
    assert result is record
    assert record.status == "open"
    assert record.is_archived is False


def test_nonconformity_repository_find_by_id_returns_none_for_missing_id_when_records_exist() -> None:
    repository = NonconformityRepository()
    record = NonconformityRecord(
        nonconformity_id="NCR-074",
        project_id="prj-001",
        date="2026-09-17",
        title="Mevcut NCR",
        description="Farkli id arandiginda donmemeli.",
    )

    repository.add(record)

    assert repository.find_by_id("NCR-MISSING") is None
    assert repository.list_all() == [record]


def test_nonconformity_repository_find_by_id_returns_archived_record() -> None:
    repository = NonconformityRepository()
    record = NonconformityRecord(
        nonconformity_id="NCR-075",
        project_id="prj-001",
        date="2026-09-18",
        title="Id ile bulunacak arsiv NCR",
        description="Arsivlenmis kayit id ile bulunmali.",
        status="closed",
    )

    repository.add(record)
    repository.archive("NCR-075")

    result = repository.find_by_id("NCR-075")

    assert result == record
    assert result is record
    assert record.is_archived is True
    assert record.status == "closed"
    assert repository.list_archived() == [record]


def test_nonconformity_repository_find_by_id_returns_restored_record() -> None:
    repository = NonconformityRepository()
    record = NonconformityRecord(
        nonconformity_id="NCR-076",
        project_id="prj-001",
        date="2026-09-19",
        title="Restore sonrasi id ile bulunacak NCR",
        description="Restore edilen kayit id ile bulunmaya devam etmeli.",
        status="in_progress",
    )

    repository.add(record)
    repository.archive("NCR-076")
    repository.restore("NCR-076")

    result = repository.find_by_id("NCR-076")

    assert result == record
    assert result is record
    assert record.is_archived is False
    assert record.status == "in_progress"
    assert repository.list_active() == [record]


def test_nonconformity_repository_list_by_status_returns_empty_list_when_repository_is_empty() -> None:
    repository = NonconformityRepository()

    assert repository.list_by_status("open") == []


def test_nonconformity_repository_list_by_status_returns_matching_records() -> None:
    repository = NonconformityRepository()
    open_record = NonconformityRecord(
        nonconformity_id="NCR-077",
        project_id="prj-001",
        date="2026-09-20",
        title="Status filtresi acik NCR",
        description="Open status ile eslesmesi gereken kayit.",
        status="open",
    )
    closed_record = NonconformityRecord(
        nonconformity_id="NCR-078",
        project_id="prj-001",
        date="2026-09-21",
        title="Status filtresi kapali NCR",
        description="Closed status ile eslesmesi gereken kayit.",
        status="closed",
    )
    second_open_record = NonconformityRecord(
        nonconformity_id="NCR-079",
        project_id="prj-001",
        date="2026-09-22",
        title="Status filtresi ikinci acik NCR",
        description="Open status ile eslesmesi gereken ikinci kayit.",
        status="open",
    )

    repository.add(open_record)
    repository.add(closed_record)
    repository.add(second_open_record)

    assert repository.list_by_status("open") == [open_record, second_open_record]
    assert repository.list_by_status("closed") == [closed_record]
    assert repository.list_all() == [open_record, closed_record, second_open_record]


def test_nonconformity_repository_list_by_status_returns_empty_list_for_missing_status() -> None:
    repository = NonconformityRepository()
    record = NonconformityRecord(
        nonconformity_id="NCR-080",
        project_id="prj-001",
        date="2026-09-23",
        title="Status filtresi mevcut NCR",
        description="Farkli status arandiginda donmemeli.",
        status="open",
    )

    repository.add(record)

    assert repository.list_by_status("verified") == []
    assert record.status == "open"
    assert repository.list_all() == [record]


def test_nonconformity_repository_list_by_status_includes_archived_records() -> None:
    repository = NonconformityRepository()
    record = NonconformityRecord(
        nonconformity_id="NCR-081",
        project_id="prj-001",
        date="2026-09-24",
        title="Arsivli status filtresi NCR",
        description="Arsivlense de status filtresinde gorunmeli.",
        status="closed",
    )

    repository.add(record)
    repository.archive("NCR-081")

    assert repository.list_by_status("closed") == [record]
    assert record.is_archived is True
    assert record.status == "closed"
    assert repository.list_archived() == [record]


def test_nonconformity_repository_list_by_status_includes_restored_records() -> None:
    repository = NonconformityRepository()
    record = NonconformityRecord(
        nonconformity_id="NCR-082",
        project_id="prj-001",
        date="2026-09-25",
        title="Restore sonrasi status filtresi NCR",
        description="Restore sonrasi status filtresinde gorunmeye devam etmeli.",
        status="in_progress",
    )

    repository.add(record)
    repository.archive("NCR-082")
    repository.restore("NCR-082")

    assert repository.list_by_status("in_progress") == [record]
    assert record.is_archived is False
    assert record.status == "in_progress"
    assert repository.list_active() == [record]


def test_nonconformity_repository_list_by_location_returns_empty_list_when_repository_is_empty() -> None:
    repository = NonconformityRepository()

    assert repository.list_by_location("A Blok") == []


def test_nonconformity_repository_list_by_location_returns_matching_records() -> None:
    repository = NonconformityRepository()
    first_a_block_record = NonconformityRecord(
        nonconformity_id="NCR-083",
        project_id="prj-001",
        date="2026-09-26",
        title="A Blok konum filtresi NCR",
        description="A Blok ile eslesmesi gereken kayit.",
        location="A Blok",
    )
    b_block_record = NonconformityRecord(
        nonconformity_id="NCR-084",
        project_id="prj-001",
        date="2026-09-27",
        title="B Blok konum filtresi NCR",
        description="B Blok ile eslesmesi gereken kayit.",
        location="B Blok",
    )
    second_a_block_record = NonconformityRecord(
        nonconformity_id="NCR-085",
        project_id="prj-001",
        date="2026-09-28",
        title="A Blok ikinci konum filtresi NCR",
        description="A Blok ile eslesmesi gereken ikinci kayit.",
        location="A Blok",
    )

    repository.add(first_a_block_record)
    repository.add(b_block_record)
    repository.add(second_a_block_record)

    assert repository.list_by_location("A Blok") == [
        first_a_block_record,
        second_a_block_record,
    ]
    assert repository.list_by_location("B Blok") == [b_block_record]
    assert repository.list_all() == [
        first_a_block_record,
        b_block_record,
        second_a_block_record,
    ]


def test_nonconformity_repository_list_by_location_returns_empty_list_for_missing_location() -> None:
    repository = NonconformityRepository()
    record = NonconformityRecord(
        nonconformity_id="NCR-086",
        project_id="prj-001",
        date="2026-09-29",
        title="Mevcut konum filtresi NCR",
        description="Farkli konum arandiginda donmemeli.",
        location="A Blok",
    )

    repository.add(record)

    assert repository.list_by_location("C Blok") == []
    assert record.location == "A Blok"
    assert repository.list_all() == [record]


def test_nonconformity_repository_list_by_location_includes_archived_records() -> None:
    repository = NonconformityRepository()
    record = NonconformityRecord(
        nonconformity_id="NCR-087",
        project_id="prj-001",
        date="2026-09-30",
        title="Arsivli konum filtresi NCR",
        description="Arsivlense de konum filtresinde gorunmeli.",
        location="A Blok",
        status="closed",
    )

    repository.add(record)
    repository.archive("NCR-087")

    assert repository.list_by_location("A Blok") == [record]
    assert record.is_archived is True
    assert record.location == "A Blok"
    assert repository.list_archived() == [record]


def test_nonconformity_repository_list_by_location_includes_restored_records() -> None:
    repository = NonconformityRepository()
    record = NonconformityRecord(
        nonconformity_id="NCR-088",
        project_id="prj-001",
        date="2026-10-01",
        title="Restore sonrasi konum filtresi NCR",
        description="Restore sonrasi konum filtresinde gorunmeye devam etmeli.",
        location="A Blok",
        status="in_progress",
    )

    repository.add(record)
    repository.archive("NCR-088")
    repository.restore("NCR-088")

    assert repository.list_by_location("A Blok") == [record]
    assert record.is_archived is False
    assert record.location == "A Blok"
    assert repository.list_active() == [record]
