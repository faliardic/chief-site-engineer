from app.models import (
    ArchiveDocument,
    AttachmentRecord,
    CheckResultRecord,
    ChecklistItem,
    ChecklistItemRecord,
    ConcretePour,
    ConcreteSample,
    ContactPersonRecord,
    DailyReportRecord,
    DailySiteLog,
    EquipmentRecord,
    InspectionRequest,
    MaterialRecord,
    MeetingActionRecord,
    MeetingRecord,
    NonconformityCandidateActionRecord,
    NonconformityCandidateAssignmentRecord,
    NonconformityCandidateClosureRecord,
    NonconformityCandidateProcessViewRecord,
    NonconformityCandidateRecord,
    NonconformityCandidateReviewRecord,
    NonconformityCandidateStatusHistoryRecord,
    NonconformityCandidateTrackingSummaryRecord,
    NonconformityRecord,
    ProjectPartyRecord,
    RFIRecord,
    SiteLocationRecord,
    SiteNoteRecord,
    SiteProject,
    SubmittalRecord,
    SupplierRecord,
    TaskCandidateRecord,
    TrackingRecord,
    WorkforceRecord,
)


def test_site_project_holds_values_and_defaults() -> None:
    project = SiteProject(
        project_id="prj-001",
        name="Merkez Santiye",
        location="Istanbul",
    )

    assert project.project_id == "prj-001"
    assert project.name == "Merkez Santiye"
    assert project.location == "Istanbul"
    assert project.employer is None
    assert project.contractor is None
    assert project.building_inspection_company is None
    assert project.start_date is None
    assert project.status == "active"


def test_checklist_item_holds_values_and_defaults() -> None:
    item = ChecklistItem(
        item_id="chk-001",
        title="Kalip kontrolu",
        category="Betonarme",
    )

    assert item.item_id == "chk-001"
    assert item.title == "Kalip kontrolu"
    assert item.category == "Betonarme"
    assert item.description is None
    assert item.required is True
    assert item.status == "pending"


def test_tracking_record_holds_values_and_defaults() -> None:
    record = TrackingRecord(
        record_id="trk-001",
        project_id="prj-001",
        title="Demir teslim takibi",
        description="Teslim edilen donati miktari kontrol edildi.",
        date="2026-06-05",
    )

    assert record.record_id == "trk-001"
    assert record.project_id == "prj-001"
    assert record.title == "Demir teslim takibi"
    assert record.description == "Teslim edilen donati miktari kontrol edildi."
    assert record.date == "2026-06-05"
    assert record.responsible_party is None
    assert record.status == "open"


def test_archive_document_holds_values_and_defaults() -> None:
    document = ArchiveDocument(
        document_id="doc-001",
        project_id="prj-001",
        title="Ruhsat",
        document_type="permit",
    )

    assert document.document_id == "doc-001"
    assert document.project_id == "prj-001"
    assert document.title == "Ruhsat"
    assert document.document_type == "permit"
    assert document.file_path is None
    assert document.date is None
    assert document.notes is None


def test_daily_site_log_holds_values_and_defaults() -> None:
    log = DailySiteLog(
        log_id="log-001",
        project_id="prj-001",
        date="2026-06-05",
    )

    assert log.log_id == "log-001"
    assert log.project_id == "prj-001"
    assert log.date == "2026-06-05"
    assert log.weather is None
    assert log.workforce_summary is None
    assert log.work_performed is None
    assert log.inspections is None
    assert log.issues is None
    assert log.notes is None
    assert log.created_by is None
    assert log.status == "draft"


def test_concrete_pour_holds_values_and_defaults() -> None:
    pour = ConcretePour(
        pour_id="pour-001",
        project_id="prj-001",
        date="2026-06-05",
        location="Temel",
        concrete_class="C30/37",
    )

    assert pour.pour_id == "pour-001"
    assert pour.project_id == "prj-001"
    assert pour.date == "2026-06-05"
    assert pour.location == "Temel"
    assert pour.concrete_class == "C30/37"
    assert pour.volume_m3 is None
    assert pour.supplier is None
    assert pour.truck_count is None
    assert pour.weather is None
    assert pour.notes is None
    assert pour.status == "planned"


def test_concrete_sample_holds_values_and_defaults() -> None:
    sample = ConcreteSample(
        sample_id="sample-001",
        pour_id="pour-001",
        project_id="prj-001",
        sample_date="2026-06-05",
        sample_count=6,
    )

    assert sample.sample_id == "sample-001"
    assert sample.pour_id == "pour-001"
    assert sample.project_id == "prj-001"
    assert sample.sample_date == "2026-06-05"
    assert sample.sample_count == 6
    assert sample.seven_day_test_date is None
    assert sample.twenty_eight_day_test_date is None
    assert sample.seven_day_result_mpa is None
    assert sample.twenty_eight_day_result_mpa is None
    assert sample.laboratory is None
    assert sample.status == "waiting"


def test_inspection_request_holds_values_and_defaults() -> None:
    request = InspectionRequest(
        request_id="insp-001",
        project_id="prj-001",
        requested_date="2026-06-05",
        inspection_type="Temel demir kontrolu",
    )

    assert request.request_id == "insp-001"
    assert request.project_id == "prj-001"
    assert request.requested_date == "2026-06-05"
    assert request.inspection_type == "Temel demir kontrolu"
    assert request.requested_by is None
    assert request.inspection_company is None
    assert request.related_pour_id is None
    assert request.planned_inspection_date is None
    assert request.completed_date is None
    assert request.result is None
    assert request.notes is None
    assert request.status == "requested"


def test_nonconformity_record_holds_values_and_defaults() -> None:
    record = NonconformityRecord(
        nonconformity_id="ncr-001",
        project_id="prj-001",
        date="2026-06-05",
        title="Eksik donati",
        description="Temel bolgesinde ek donati eksik goruldu.",
    )

    assert record.nonconformity_id == "ncr-001"
    assert record.project_id == "prj-001"
    assert record.date == "2026-06-05"
    assert record.title == "Eksik donati"
    assert record.description == "Temel bolgesinde ek donati eksik goruldu."
    assert record.location is None
    assert record.category is None
    assert record.severity == "medium"
    assert record.responsible_party is None
    assert record.corrective_action is None
    assert record.due_date is None
    assert record.closed_date is None
    assert record.related_inspection_request_id is None
    assert record.related_pour_id is None
    assert record.notes is None
    assert record.status == "open"


def test_attachment_record_holds_values_and_defaults() -> None:
    attachment = AttachmentRecord(
        attachment_id="att-001",
        project_id="prj-001",
        title="Temel fotografi",
        file_name="temel-fotografi.jpg",
    )

    assert attachment.attachment_id == "att-001"
    assert attachment.project_id == "prj-001"
    assert attachment.title == "Temel fotografi"
    assert attachment.file_name == "temel-fotografi.jpg"
    assert attachment.file_type is None
    assert attachment.file_path is None
    assert attachment.related_model is None
    assert attachment.related_id is None
    assert attachment.uploaded_by is None
    assert attachment.uploaded_date is None
    assert attachment.notes is None
    assert attachment.status == "active"


def test_attachment_record_can_reference_nonconformity_candidate_record() -> None:
    attachment = AttachmentRecord(
        attachment_id="att-ncr-cand-001",
        project_id="prj-001",
        title="Korkuluk eksigi fotografi",
        file_name="korkuluk-eksigi.jpg",
        file_type="image/jpeg",
        file_path="archive/nonconformity-candidates/korkuluk-eksigi.jpg",
        related_model="NonconformityCandidateRecord",
        related_id="NCR-CAND-001",
        uploaded_by="Santiye sefi",
        uploaded_date="2026-06-12",
        notes="Aday uygunsuzluk icin kanit fotografi.",
        status="active",
    )

    assert attachment.attachment_id == "att-ncr-cand-001"
    assert attachment.project_id == "prj-001"
    assert attachment.title == "Korkuluk eksigi fotografi"
    assert attachment.file_name == "korkuluk-eksigi.jpg"
    assert attachment.file_type == "image/jpeg"
    assert attachment.file_path == "archive/nonconformity-candidates/korkuluk-eksigi.jpg"
    assert attachment.related_model == "NonconformityCandidateRecord"
    assert attachment.related_id == "NCR-CAND-001"
    assert attachment.uploaded_by == "Santiye sefi"
    assert attachment.uploaded_date == "2026-06-12"
    assert attachment.notes == "Aday uygunsuzluk icin kanit fotografi."
    assert attachment.status == "active"


def test_material_record_holds_values_and_defaults() -> None:
    material = MaterialRecord(
        material_name="C30 beton",
        supplier="ABC Beton",
        delivery_note_no="IRS-001",
        quantity=24.5,
        unit="m3",
        area="Temel",
        received_date="2026-06-05",
    )

    assert material.material_name == "C30 beton"
    assert material.supplier == "ABC Beton"
    assert material.delivery_note_no == "IRS-001"
    assert material.quantity == 24.5
    assert material.unit == "m3"
    assert material.area == "Temel"
    assert material.received_date == "2026-06-05"
    assert material.used_date is None
    assert material.notes is None
    assert material.status == "received"


def test_meeting_record_holds_values_and_defaults() -> None:
    meeting = MeetingRecord(
        meeting_title="Haftalik santiye koordinasyon toplantisi",
        meeting_date="2026-06-05",
        location="Santiye ofisi",
        organizer="Santiye sefi",
        participants="Isveren, yuklenici, taseron temsilcileri",
        agenda="Imalat ilerlemesi ve kalite kontrolleri",
    )

    assert meeting.meeting_title == "Haftalik santiye koordinasyon toplantisi"
    assert meeting.meeting_date == "2026-06-05"
    assert meeting.location == "Santiye ofisi"
    assert meeting.organizer == "Santiye sefi"
    assert meeting.participants == "Isveren, yuklenici, taseron temsilcileri"
    assert meeting.agenda == "Imalat ilerlemesi ve kalite kontrolleri"
    assert meeting.decisions is None
    assert meeting.notes is None
    assert meeting.status == "draft"


def test_meeting_action_record_holds_values_and_defaults() -> None:
    action = MeetingActionRecord(
        action_title="Temel izolasyon detayini kontrol et",
        meeting_title="Haftalik santiye koordinasyon toplantisi",
        responsible="Saha muhendisi",
        due_date="2026-06-12",
    )

    assert action.action_title == "Temel izolasyon detayini kontrol et"
    assert action.meeting_title == "Haftalik santiye koordinasyon toplantisi"
    assert action.responsible == "Saha muhendisi"
    assert action.due_date == "2026-06-12"
    assert action.notes is None
    assert action.status == "open"


def test_rfi_record_holds_values_and_defaults() -> None:
    rfi = RFIRecord(
        subject="Temel drenaj detayi",
        question="Drenaj borusu kotu nasil uygulanacak?",
        requested_by="Santiye sefi",
        assigned_to="Proje muellifi",
        request_date="2026-06-05",
        due_date="2026-06-12",
    )

    assert rfi.subject == "Temel drenaj detayi"
    assert rfi.question == "Drenaj borusu kotu nasil uygulanacak?"
    assert rfi.requested_by == "Santiye sefi"
    assert rfi.assigned_to == "Proje muellifi"
    assert rfi.request_date == "2026-06-05"
    assert rfi.due_date == "2026-06-12"
    assert rfi.answer is None
    assert rfi.notes is None
    assert rfi.status == "open"


def test_submittal_record_holds_values_and_defaults() -> None:
    submittal = SubmittalRecord(
        subject="Seramik teknik foyi",
        submitted_by="Yuklenici",
        submitted_to="Isveren temsilcisi",
        submit_date="2026-06-05",
        review_due_date="2026-06-12",
    )

    assert submittal.subject == "Seramik teknik foyi"
    assert submittal.submitted_by == "Yuklenici"
    assert submittal.submitted_to == "Isveren temsilcisi"
    assert submittal.submit_date == "2026-06-05"
    assert submittal.review_due_date == "2026-06-12"
    assert submittal.response is None
    assert submittal.notes is None
    assert submittal.status == "submitted"


def test_daily_report_record_holds_values_and_defaults() -> None:
    report = DailyReportRecord(
        report_date="2026-06-05",
        weather="Gunesli",
        work_summary="Temel izolasyon imalati tamamlandi.",
        manpower_summary="12 isci, 1 formen sahada calisti.",
        equipment_summary="1 ekskavator ve 1 vinc kullanildi.",
        material_summary="Izolasyon membrani sahaya alindi.",
        issue_summary="Kuzey cephede drenaj detayi netlestirilecek.",
        safety_summary="Is guvenligi uygunsuzlugu gorulmedi.",
        prepared_by="Santiye sefi",
    )

    assert report.report_date == "2026-06-05"
    assert report.weather == "Gunesli"
    assert report.work_summary == "Temel izolasyon imalati tamamlandi."
    assert report.manpower_summary == "12 isci, 1 formen sahada calisti."
    assert report.equipment_summary == "1 ekskavator ve 1 vinc kullanildi."
    assert report.material_summary == "Izolasyon membrani sahaya alindi."
    assert report.issue_summary == "Kuzey cephede drenaj detayi netlestirilecek."
    assert report.safety_summary == "Is guvenligi uygunsuzlugu gorulmedi."
    assert report.prepared_by == "Santiye sefi"
    assert report.notes is None
    assert report.status == "draft"


def test_project_party_record_holds_values_and_defaults() -> None:
    party = ProjectPartyRecord(
        party_name="ABC Insaat A.S.",
        party_type="Yuklenici",
        role="Ana yuklenici",
        tax_or_id_no="1234567890",
        phone="+90 212 000 00 00",
        email="info@example.com",
        address="Istanbul",
    )

    assert party.party_name == "ABC Insaat A.S."
    assert party.party_type == "Yuklenici"
    assert party.role == "Ana yuklenici"
    assert party.tax_or_id_no == "1234567890"
    assert party.phone == "+90 212 000 00 00"
    assert party.email == "info@example.com"
    assert party.address == "Istanbul"
    assert party.notes is None
    assert party.status == "active"


def test_contact_person_record_holds_values_and_defaults() -> None:
    person = ContactPersonRecord(
        full_name="Ali Yilmaz",
        organization="ABC Insaat A.S.",
        role="Saha muhendisi",
        phone="+90 532 000 00 00",
        email="ali.yilmaz@example.com",
        responsibility_area="Betonarme imalat",
    )

    assert person.full_name == "Ali Yilmaz"
    assert person.organization == "ABC Insaat A.S."
    assert person.role == "Saha muhendisi"
    assert person.phone == "+90 532 000 00 00"
    assert person.email == "ali.yilmaz@example.com"
    assert person.responsibility_area == "Betonarme imalat"
    assert person.notes is None
    assert person.status == "active"


def test_site_location_record_holds_values_and_defaults() -> None:
    location = SiteLocationRecord(
        location_name="A Blok 3. Kat Kuzey Cephe",
        block="A Blok",
        floor="3. Kat",
        zone="Kuzey cephe",
        axis="A-B / 1-4",
        discipline="Mimari",
        description="Cephe kaplama calisma alani",
    )

    assert location.location_name == "A Blok 3. Kat Kuzey Cephe"
    assert location.block == "A Blok"
    assert location.floor == "3. Kat"
    assert location.zone == "Kuzey cephe"
    assert location.axis == "A-B / 1-4"
    assert location.discipline == "Mimari"
    assert location.description == "Cephe kaplama calisma alani"
    assert location.notes is None
    assert location.status == "active"


def test_workforce_record_holds_values_and_defaults() -> None:
    workforce = WorkforceRecord(
        crew_name="Kalip ekibi",
        crew_type="kalip",
        company="ABC Kalip Tas.",
        worker_count=12,
        work_area="A Blok 2. Kat",
        work_date="2026-06-05",
        task_description="Doseme kalip imalati",
    )

    assert workforce.crew_name == "Kalip ekibi"
    assert workforce.crew_type == "kalip"
    assert workforce.company == "ABC Kalip Tas."
    assert workforce.worker_count == 12
    assert workforce.work_area == "A Blok 2. Kat"
    assert workforce.work_date == "2026-06-05"
    assert workforce.task_description == "Doseme kalip imalati"
    assert workforce.notes is None
    assert workforce.status == "active"


def test_equipment_record_holds_values_and_defaults() -> None:
    equipment = EquipmentRecord(
        equipment_name="Kule vinc",
        equipment_type="vinc",
        owner_company="ABC Makine Kiralama",
        serial_or_plate="KV-34-001",
        work_area="A Blok saha geneli",
        assigned_to="Kalip ekibi",
    )

    assert equipment.equipment_name == "Kule vinc"
    assert equipment.equipment_type == "vinc"
    assert equipment.owner_company == "ABC Makine Kiralama"
    assert equipment.serial_or_plate == "KV-34-001"
    assert equipment.work_area == "A Blok saha geneli"
    assert equipment.assigned_to == "Kalip ekibi"
    assert equipment.notes is None
    assert equipment.status == "available"


def test_supplier_record_holds_values_and_defaults() -> None:
    supplier = SupplierRecord(
        supplier_name="ABC Beton",
        supplier_type="malzeme tedarikcisi",
        contact_person="Ayse Demir",
        phone="+90 212 111 22 33",
        email="ayse.demir@example.com",
        service_area="Hazir beton tedariki",
    )

    assert supplier.supplier_name == "ABC Beton"
    assert supplier.supplier_type == "malzeme tedarikcisi"
    assert supplier.contact_person == "Ayse Demir"
    assert supplier.phone == "+90 212 111 22 33"
    assert supplier.email == "ayse.demir@example.com"
    assert supplier.service_area == "Hazir beton tedariki"
    assert supplier.notes is None
    assert supplier.status == "active"


def test_site_note_record_holds_values_and_defaults() -> None:
    site_note = SiteNoteRecord(
        note_title="Kuzey cephe iskele kontrolu",
        note_type="uyari",
        location="A Blok kuzey cephe",
        related_subject="Iskele guvenligi",
        note_date="2026-06-05",
    )

    assert site_note.note_title == "Kuzey cephe iskele kontrolu"
    assert site_note.note_type == "uyari"
    assert site_note.location == "A Blok kuzey cephe"
    assert site_note.related_subject == "Iskele guvenligi"
    assert site_note.note_date == "2026-06-05"
    assert site_note.notes is None
    assert site_note.status == "open"


def test_task_candidate_record_holds_values_and_defaults() -> None:
    task_candidate = TaskCandidateRecord(
        task_title="Kuzey cephe iskele kontrolu takip et",
        task_type="takip",
        related_area="A Blok kuzey cephe",
        source="Saha notu",
        target_date="2026-06-12",
    )

    assert task_candidate.task_title == "Kuzey cephe iskele kontrolu takip et"
    assert task_candidate.task_type == "takip"
    assert task_candidate.related_area == "A Blok kuzey cephe"
    assert task_candidate.source == "Saha notu"
    assert task_candidate.target_date == "2026-06-12"
    assert task_candidate.notes is None
    assert task_candidate.status == "open"


def test_checklist_item_record_holds_values_and_defaults() -> None:
    checklist_item = ChecklistItemRecord(
        item_title="Kuzey cephe iskele kontrolu",
        item_category="is guvenligi",
        related_area="A Blok kuzey cephe",
        check_reference="Saha gozlemi",
    )

    assert checklist_item.item_title == "Kuzey cephe iskele kontrolu"
    assert checklist_item.item_category == "is guvenligi"
    assert checklist_item.related_area == "A Blok kuzey cephe"
    assert checklist_item.check_reference == "Saha gozlemi"
    assert checklist_item.notes is None
    assert checklist_item.status == "pending"


def test_check_result_record_holds_values_and_defaults() -> None:
    check_result = CheckResultRecord(
        check_title="Kuzey cephe iskele kontrol sonucu",
        check_area="A Blok kuzey cephe",
        result="Uygun",
        checked_by="Santiye sefi",
        check_date="2026-06-05",
    )

    assert check_result.check_title == "Kuzey cephe iskele kontrol sonucu"
    assert check_result.check_area == "A Blok kuzey cephe"
    assert check_result.result == "Uygun"
    assert check_result.checked_by == "Santiye sefi"
    assert check_result.check_date == "2026-06-05"
    assert check_result.notes is None
    assert check_result.status == "recorded"


def test_nonconformity_candidate_record_holds_values_and_defaults() -> None:
    candidate = NonconformityCandidateRecord(
        candidate_title="Kuzey cephe korkuluk eksigi",
        candidate_type="eksik",
        location="A Blok kuzey cephe",
        observed_issue="Korkuluk ara elemani eksik goruldu",
        detected_by="Santiye sefi",
        detection_date="2026-06-05",
    )

    assert candidate.candidate_title == "Kuzey cephe korkuluk eksigi"
    assert candidate.candidate_type == "eksik"
    assert candidate.location == "A Blok kuzey cephe"
    assert candidate.observed_issue == "Korkuluk ara elemani eksik goruldu"
    assert candidate.detected_by == "Santiye sefi"
    assert candidate.detection_date == "2026-06-05"
    assert candidate.notes is None
    assert candidate.status == "open"


def test_nonconformity_candidate_review_record_holds_values_and_defaults() -> None:
    review = NonconformityCandidateReviewRecord(
        candidate_title="Kuzey cephe korkuluk eksigi",
        reviewed_by="Santiye sefi",
        review_date="2026-06-06",
        review_result="takip gerekli",
        decision_reason="Eksik parca guvenlik riski olusturuyor",
        next_action="Korkuluk eksigi icin gorev adayi ac",
    )

    assert review.candidate_title == "Kuzey cephe korkuluk eksigi"
    assert review.reviewed_by == "Santiye sefi"
    assert review.review_date == "2026-06-06"
    assert review.review_result == "takip gerekli"
    assert review.decision_reason == "Eksik parca guvenlik riski olusturuyor"
    assert review.next_action == "Korkuluk eksigi icin gorev adayi ac"
    assert review.status == "reviewed"
    assert review.notes is None


def test_nonconformity_candidate_action_record_holds_values_and_defaults() -> None:
    action = NonconformityCandidateActionRecord(
        candidate_title="Kuzey cephe korkuluk eksigi",
        review_result="takip gerekli",
        action_decision="gorev adayi ac",
        action_owner="Saha ekibi",
        target_date="2026-06-10",
        action_description="Korkuluk ara elemani tamamlanacak",
    )

    assert action.candidate_title == "Kuzey cephe korkuluk eksigi"
    assert action.review_result == "takip gerekli"
    assert action.action_decision == "gorev adayi ac"
    assert action.action_owner == "Saha ekibi"
    assert action.target_date == "2026-06-10"
    assert action.action_description == "Korkuluk ara elemani tamamlanacak"
    assert action.status == "planned"
    assert action.notes is None


def test_nonconformity_candidate_tracking_summary_record_holds_values_and_defaults() -> None:
    summary = NonconformityCandidateTrackingSummaryRecord(
        candidate_title="Kuzey cephe korkuluk eksigi",
        review_result="takip gerekli",
        action_decision="gorev adayi ac",
        action_owner="Saha ekibi",
        tracking_status="aksiyon bekliyor",
        last_update_date="2026-06-11",
        summary_note="Korkuluk eksigi icin saha ekibi aksiyonu bekleniyor",
    )

    assert summary.candidate_title == "Kuzey cephe korkuluk eksigi"
    assert summary.review_result == "takip gerekli"
    assert summary.action_decision == "gorev adayi ac"
    assert summary.action_owner == "Saha ekibi"
    assert summary.tracking_status == "aksiyon bekliyor"
    assert summary.last_update_date == "2026-06-11"
    assert summary.summary_note == "Korkuluk eksigi icin saha ekibi aksiyonu bekleniyor"
    assert summary.status == "active"
    assert summary.notes is None


def test_nonconformity_candidate_process_view_record_holds_values_and_defaults() -> None:
    process_view = NonconformityCandidateProcessViewRecord(
        candidate_id="NCR-CAND-001",
        check_result_id="CHK-RES-001",
        review_id="NCR-CAND-REV-001",
        action_id="NCR-CAND-ACT-001",
        tracking_summary_id="NCR-CAND-TRK-001",
        attachment_count=2,
        current_status="aksiyon bekliyor",
        last_update_date="2026-06-12",
        process_summary="Korkuluk eksigi degerlendirildi ve saha aksiyonu bekleniyor.",
    )

    assert process_view.candidate_id == "NCR-CAND-001"
    assert process_view.check_result_id == "CHK-RES-001"
    assert process_view.review_id == "NCR-CAND-REV-001"
    assert process_view.action_id == "NCR-CAND-ACT-001"
    assert process_view.tracking_summary_id == "NCR-CAND-TRK-001"
    assert process_view.attachment_count == 2
    assert process_view.current_status == "aksiyon bekliyor"
    assert process_view.last_update_date == "2026-06-12"
    assert (
        process_view.process_summary
        == "Korkuluk eksigi degerlendirildi ve saha aksiyonu bekleniyor."
    )
    assert process_view.notes is None


def test_nonconformity_candidate_process_view_record_defaults() -> None:
    process_view = NonconformityCandidateProcessViewRecord(
        candidate_id="NCR-CAND-002",
    )

    assert process_view.candidate_id == "NCR-CAND-002"
    assert process_view.check_result_id is None
    assert process_view.review_id is None
    assert process_view.action_id is None
    assert process_view.tracking_summary_id is None
    assert process_view.attachment_count == 0
    assert process_view.current_status == "open"
    assert process_view.last_update_date is None
    assert process_view.process_summary is None
    assert process_view.notes is None


def test_nonconformity_candidate_status_history_record_holds_values_and_defaults() -> None:
    history = NonconformityCandidateStatusHistoryRecord(
        candidate_id="NCR-CAND-001",
        old_status="open",
        new_status="under_review",
        change_reason="Aday uygunsuzluk degerlendirmeye alindi.",
        changed_by="Santiye sefi",
        change_date="2026-06-13",
        source_record="NonconformityCandidateReviewRecord",
    )

    assert history.candidate_id == "NCR-CAND-001"
    assert history.old_status == "open"
    assert history.new_status == "under_review"
    assert history.change_reason == "Aday uygunsuzluk degerlendirmeye alindi."
    assert history.changed_by == "Santiye sefi"
    assert history.change_date == "2026-06-13"
    assert history.source_record == "NonconformityCandidateReviewRecord"
    assert history.notes is None


def test_nonconformity_candidate_status_history_record_optional_fields_default_to_none() -> None:
    history = NonconformityCandidateStatusHistoryRecord(
        candidate_id="NCR-CAND-002",
        old_status="under_review",
        new_status="action_planned",
        change_reason="Aksiyon karari verildi.",
        changed_by="Saha muhendisi",
        change_date="2026-06-14",
    )

    assert history.candidate_id == "NCR-CAND-002"
    assert history.old_status == "under_review"
    assert history.new_status == "action_planned"
    assert history.change_reason == "Aksiyon karari verildi."
    assert history.changed_by == "Saha muhendisi"
    assert history.change_date == "2026-06-14"
    assert history.source_record is None
    assert history.notes is None


def test_nonconformity_candidate_assignment_record_holds_values_and_defaults() -> None:
    assignment = NonconformityCandidateAssignmentRecord(
        candidate_id="NCR-CAND-001",
        assigned_to="Saha muhendisi",
        assigned_by="Santiye sefi",
        assignment_date="2026-06-15",
        due_date="2026-06-18",
        responsibility_note="Korkuluk eksigi sahada takip edilecek.",
        priority="high",
    )

    assert assignment.candidate_id == "NCR-CAND-001"
    assert assignment.assigned_to == "Saha muhendisi"
    assert assignment.assigned_by == "Santiye sefi"
    assert assignment.assignment_date == "2026-06-15"
    assert assignment.due_date == "2026-06-18"
    assert assignment.responsibility_note == "Korkuluk eksigi sahada takip edilecek."
    assert assignment.priority == "high"
    assert assignment.status == "assigned"
    assert assignment.notes is None


def test_nonconformity_candidate_assignment_record_optional_fields_default() -> None:
    assignment = NonconformityCandidateAssignmentRecord(
        candidate_id="NCR-CAND-002",
        assigned_to="Kalite sorumlusu",
        assigned_by="Santiye sefi",
        assignment_date="2026-06-16",
    )

    assert assignment.candidate_id == "NCR-CAND-002"
    assert assignment.assigned_to == "Kalite sorumlusu"
    assert assignment.assigned_by == "Santiye sefi"
    assert assignment.assignment_date == "2026-06-16"
    assert assignment.due_date is None
    assert assignment.responsibility_note is None
    assert assignment.priority == "normal"
    assert assignment.status == "assigned"
    assert assignment.notes is None


def test_nonconformity_candidate_closure_record_holds_values_and_defaults() -> None:
    closure = NonconformityCandidateClosureRecord(
        candidate_id="NCR-CAND-001",
        closure_decision="takip tamamlandi",
        closure_reason="Korkuluk eksigi sahada giderildi.",
        closed_by="Santiye sefi",
        closure_date="2026-06-19",
        final_status="closed",
        result_note="Yerinde kontrol sonrasi aday kayit kapatildi.",
        requires_follow_up=True,
    )

    assert closure.candidate_id == "NCR-CAND-001"
    assert closure.closure_decision == "takip tamamlandi"
    assert closure.closure_reason == "Korkuluk eksigi sahada giderildi."
    assert closure.closed_by == "Santiye sefi"
    assert closure.closure_date == "2026-06-19"
    assert closure.final_status == "closed"
    assert closure.result_note == "Yerinde kontrol sonrasi aday kayit kapatildi."
    assert closure.requires_follow_up is True
    assert closure.notes is None


def test_nonconformity_candidate_closure_record_optional_fields_default() -> None:
    closure = NonconformityCandidateClosureRecord(
        candidate_id="NCR-CAND-002",
        closure_decision="kesin uygunsuzluga donustur",
        closure_reason="Eksik giderilmedigi icin resmi kayit gerekli.",
        closed_by="Kalite sorumlusu",
        closure_date="2026-06-20",
        final_status="converted_to_ncr",
    )

    assert closure.candidate_id == "NCR-CAND-002"
    assert closure.closure_decision == "kesin uygunsuzluga donustur"
    assert closure.closure_reason == "Eksik giderilmedigi icin resmi kayit gerekli."
    assert closure.closed_by == "Kalite sorumlusu"
    assert closure.closure_date == "2026-06-20"
    assert closure.final_status == "converted_to_ncr"
    assert closure.result_note is None
    assert closure.requires_follow_up is False
    assert closure.notes is None
