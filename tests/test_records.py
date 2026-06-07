import pytest

from app.models import DailySiteLog, NonconformityRecord, TrackingRecord
from app.records import (
    NonconformityRepository,
    count_records,
    filter_records_by_project_id,
    filter_records_by_status,
    list_records,
)


class DummyRecord:
    pass


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
