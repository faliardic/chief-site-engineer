import 'package:chief_site_engineer/application/attendance_application.dart';
import 'package:chief_site_engineer/core/record_id.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/domain/attendance_models.dart';
import 'package:chief_site_engineer/features/attendance/workforce_compliance_summary.dart';
import 'package:flutter/material.dart';

class WorkforcePersonDetailPage extends StatefulWidget {
  const WorkforcePersonDetailPage({
    required this.attendance,
    required this.memberId,
    super.key,
  });

  final AttendanceApplication attendance;
  final String memberId;

  @override
  State<WorkforcePersonDetailPage> createState() =>
      _WorkforcePersonDetailPageState();
}

class _WorkforcePersonDetailPageState extends State<WorkforcePersonDetailPage> {
  WorkforcePersonDetail? _detail;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final detail = await widget.attendance.getPersonDetail(widget.memberId);
      if (mounted) setState(() => _detail = detail);
    } on Object catch (error) {
      if (mounted) {
        setState(() => _error = _message(error, 'Personel detayı açılamadı.'));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveCompliance([WorkforceComplianceRecord? current]) async {
    final number = TextEditingController(text: current?.documentNumber);
    final issued = TextEditingController(text: current?.issuedDate);
    final expiry = TextEditingController(text: current?.expiryDate);
    final note = TextEditingController(text: current?.note);
    final reason = TextEditingController(text: current?.reason);
    var type = current?.documentType ?? ComplianceDocumentType.employmentEntry;
    var status = current?.sourceStatus ?? ComplianceSourceStatus.valid;
    var detailsExpanded =
        status == ComplianceSourceStatus.notApplicable ||
        status == ComplianceSourceStatus.exception;
    final input = await showDialog<_ComplianceInput>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            current == null ? 'İSG kaydı ekle' : 'İSG kaydını düzenle',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<ComplianceDocumentType>(
                  initialValue: type,
                  isExpanded: true,
                  itemHeight: null,
                  decoration: const InputDecoration(labelText: 'Belge türü'),
                  items: ComplianceDocumentType.values
                      .map(
                        (item) => DropdownMenuItem(
                          value: item,
                          child: Text(item.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setDialogState(() => type = value ?? type),
                ),
                _gap,
                DropdownButtonFormField<ComplianceSourceStatus>(
                  initialValue: status,
                  isExpanded: true,
                  isDense: false,
                  itemHeight: null,
                  decoration: const InputDecoration(
                    labelText: 'Kullanıcı durumu',
                  ),
                  selectedItemBuilder: (context) => ComplianceSourceStatus
                      .values
                      .map(
                        (item) => Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(
                            item.label,
                            key: Key(
                              'compliance-status-selected-${item.storageValue}',
                            ),
                            semanticsLabel: '${item.label} (kullanıcı kaydı)',
                          ),
                        ),
                      )
                      .toList(),
                  items: ComplianceSourceStatus.values
                      .map(
                        (item) => DropdownMenuItem(
                          value: item,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              item == ComplianceSourceStatus.valid
                                  ? 'Geçerli (kullanıcı kaydı)'
                                  : item.label,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setDialogState(() {
                    status = value ?? status;
                    if (status == ComplianceSourceStatus.notApplicable ||
                        status == ComplianceSourceStatus.exception) {
                      detailsExpanded = true;
                    }
                  }),
                ),
                _gap,
                Semantics(
                  expanded: detailsExpanded,
                  child: TextButton.icon(
                    key: const Key('compliance-dialog-details'),
                    onPressed: () => setDialogState(
                      () => detailsExpanded = !detailsExpanded,
                    ),
                    icon: Icon(
                      detailsExpanded ? Icons.expand_less : Icons.expand_more,
                    ),
                    label: const Text('Detaylar'),
                  ),
                ),
                if (detailsExpanded) ...[
                  _gap,
                  if (status == ComplianceSourceStatus.notApplicable ||
                      status == ComplianceSourceStatus.exception)
                    const Text('Bu durum için gerekçe zorunludur.'),
                  _field(reason, 'İstisna/uygulanamaz gerekçesi'),
                  _gap,
                  _field(number, 'Belge numarası'),
                  _gap,
                  _field(issued, 'Düzenlenme tarihi (YYYY-AA-GG)'),
                  _gap,
                  _field(expiry, 'Son geçerlilik tarihi (YYYY-AA-GG)'),
                  _gap,
                  _field(note, 'Not', maxLines: 3),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(
                context,
                _ComplianceInput(
                  type,
                  status,
                  number.text,
                  issued.text,
                  expiry.text,
                  note.text,
                  reason.text,
                ),
              ),
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
    await Future<void>.delayed(kThemeAnimationDuration);
    number.dispose();
    issued.dispose();
    expiry.dispose();
    note.dispose();
    reason.dispose();
    if (input == null) return;
    try {
      await widget.attendance.saveComplianceRecord(
        SaveComplianceRecordCommand(
          id: current?.id ?? RecordId.randomUuid(),
          eventId: RecordId.randomUuid(),
          memberId: widget.memberId,
          expectedRevision: current?.revision ?? 0,
          documentType: input.type,
          sourceStatus: input.status,
          documentNumber: input.number,
          issuedDate: input.issued,
          expiryDate: input.expiry,
          note: input.note,
          reason: input.reason,
        ),
      );
      await _load();
    } on Object catch (error) {
      if (mounted) {
        setState(() => _error = _message(error, 'İSG belgesi kaydedilemedi.'));
      }
    }
  }

  Future<void> _archiveCompliance(WorkforceComplianceRecord current) async {
    try {
      await widget.attendance.archiveComplianceRecord(
        ArchiveComplianceRecordCommand(
          id: current.id,
          eventId: RecordId.randomUuid(),
          expectedRevision: current.revision,
        ),
      );
      await _load();
    } on Object catch (error) {
      if (mounted) {
        setState(() => _error = _message(error, 'İSG belgesi arşivlenemedi.'));
      }
    }
  }

  Future<void> _savePpe([WorkforcePpeAssignment? current]) async {
    final type = TextEditingController(text: current?.ppeType);
    final brand = TextEditingController(text: current?.brandModel);
    final size = TextEditingController(text: current?.size);
    final serial = TextEditingController(text: current?.serialTag);
    final quantity = TextEditingController(text: '${current?.quantity ?? 1}');
    final assigned = TextEditingController(
      text:
          current?.assignedDate ??
          DateTime.now().toIso8601String().substring(0, 10),
    );
    final returned = TextEditingController(text: current?.returnedDate);
    final note = TextEditingController(text: current?.note);
    var status = current?.status ?? PpeAssignmentStatus.assigned;
    final input = await showDialog<_PpeInput>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            current == null ? 'KKD zimmeti ekle' : 'KKD zimmetini güncelle',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _field(type, 'KKD türü *'),
                _gap,
                _field(brand, 'Marka/model'),
                _gap,
                _field(size, 'Beden'),
                _gap,
                _field(serial, 'Seri/etiket'),
                _gap,
                _field(quantity, 'Adet *'),
                _gap,
                _field(assigned, 'Zimmet tarihi (YYYY-AA-GG) *'),
                _gap,
                DropdownButtonFormField<PpeAssignmentStatus>(
                  initialValue: status,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Durum'),
                  items: PpeAssignmentStatus.values
                      .map(
                        (item) => DropdownMenuItem(
                          value: item,
                          child: Text(item.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setDialogState(() => status = value ?? status),
                ),
                _gap,
                _field(returned, 'İade tarihi (YYYY-AA-GG)'),
                _gap,
                _field(note, 'Not', maxLines: 3),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(
                context,
                _PpeInput(
                  type.text,
                  brand.text,
                  size.text,
                  serial.text,
                  int.tryParse(quantity.text) ?? 0,
                  assigned.text,
                  status,
                  returned.text,
                  note.text,
                ),
              ),
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
    await Future<void>.delayed(kThemeAnimationDuration);
    for (final controller in [
      type,
      brand,
      size,
      serial,
      quantity,
      assigned,
      returned,
      note,
    ]) {
      controller.dispose();
    }
    if (input == null) return;
    try {
      await widget.attendance.savePpeAssignment(
        SavePpeAssignmentCommand(
          id: current?.id ?? RecordId.randomUuid(),
          eventId: RecordId.randomUuid(),
          memberId: widget.memberId,
          expectedRevision: current?.revision ?? 0,
          ppeType: input.type,
          brandModel: input.brand,
          size: input.size,
          serialTag: input.serial,
          quantity: input.quantity,
          assignedDate: input.assigned,
          status: input.status,
          returnedDate: input.returned,
          note: input.note,
        ),
      );
      await _load();
    } on Object catch (error) {
      if (mounted) {
        setState(() => _error = _message(error, 'KKD zimmeti kaydedilemedi.'));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = _detail;
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(detail?.member.fullName ?? 'Personel detayı'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Profil'),
              Tab(text: 'Puantaj'),
              Tab(text: 'İSG'),
              Tab(text: 'KKD'),
            ],
          ),
        ),
        body: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : detail == null
              ? Center(child: Text(_error ?? 'Personel detayı bulunamadı.'))
              : Column(
                  children: [
                    if (_error case final error?)
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          error,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _profile(detail),
                          _attendance(detail),
                          _compliance(detail),
                          _ppe(detail),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _profile(WorkforcePersonDetail detail) => SingleChildScrollView(
    key: const PageStorageKey('workforce-person-general'),
    padding: const EdgeInsets.all(16),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 840),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Summary(detail: detail),
            const SizedBox(height: 16),
            _row(
              'Ekip',
              detail.member.teamName.trim().isEmpty
                  ? 'Belirtilmedi'
                  : detail.member.teamName,
            ),
            if (detail.member.personnelCode != null)
              _row('Personel kodu', detail.member.personnelCode!),
            if (detail.member.phone != null)
              _row('Telefon', detail.member.phone!),
            if (detail.member.address != null)
              _row('Adres', detail.member.address!),
          ],
        ),
      ),
    ),
  );

  Widget _attendance(WorkforcePersonDetail detail) => SingleChildScrollView(
    key: const PageStorageKey('workforce-person-attendance'),
    padding: const EdgeInsets.all(16),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 840),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _attendanceSummary(detail.attendanceSummary),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'Puantaj kayıtları bu personelin değişmeyen kimliği üzerinden tutulur; '
                  'taşeron veya ekip değişikliği geçmiş günleri yeniden yazmaz.',
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _attendanceSummary(WorkforceAttendanceSummary summary) {
    final last = summary.lastAttendance;
    return Card(
      key: const Key('workforce-attendance-summary'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Puantaj özeti',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'Toplam ${summary.personDayEquivalentTotal.toStringAsFixed(1)} kişi-gün',
            ),
            if (last == null)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text('Henüz Puantaj geçmişi yok.'),
              )
            else ...[
              const SizedBox(height: 4),
              Text(
                'Son kayıt: ${last.localDate} • ${last.result.label} • ${last.dayStatus.label}',
              ),
              const Divider(),
              Text('Son günler', style: Theme.of(context).textTheme.labelLarge),
              for (final day in summary.recentDays)
                ListTile(
                  key: Key('workforce-attendance-${day.attendanceDayId}'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(day.localDate),
                  subtitle: Text(
                    '${day.result.label} • ${day.dayStatus.label}',
                  ),
                  trailing: Text(day.personDayEquivalent.toStringAsFixed(1)),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _compliance(WorkforcePersonDetail detail) => ListView(
    key: const PageStorageKey('workforce-person-compliance'),
    padding: const EdgeInsets.all(12),
    children: [
      FilledButton.icon(
        key: const Key('add-compliance-record'),
        style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
        onPressed: _saveCompliance,
        icon: const Icon(Icons.post_add_outlined),
        label: const Text('İSG kaydı ekle'),
      ),
      const SizedBox(height: 8),
      const Text(
        'Bu durumlar yalnız kayıt görünürlüğüdür; hukuki uygunluk veya işe kabul kararı değildir.',
      ),
      const SizedBox(height: 8),
      const Text(
        'Belge türleri takip kategorileridir; zorunlu belge listesi değildir.',
      ),
      for (final category in WorkforceComplianceSummary(
        detail.compliance,
      ).categories)
        Card(
          child: ExpansionTile(
            key: PageStorageKey(
              'compliance-category-${category.type.storageValue}',
            ),
            initiallyExpanded: true,
            maintainState: true,
            title: Text(category.type.label),
            childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (category.records.isEmpty)
                const Text(WorkforceComplianceSummary.emptyLabel),
              if (category.hasMultipleRecords)
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(WorkforceComplianceSummary.duplicateLabel),
                ),
              for (final item in category.records) _complianceRecord(item),
            ],
          ),
        ),
    ],
  );

  Widget _complianceRecord(WorkforceComplianceRecord item) => Card(
    key: Key('compliance-${item.id}'),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            WorkforceComplianceSummary.sourceLabel(item.sourceStatus),
            style: Theme.of(context).textTheme.titleSmall,
          ),
          if (WorkforceComplianceSummary.dateWarning(item.readStatus)
              case final warning?)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(warning),
            ),
          const SizedBox(height: 8),
          if (item.documentNumber case final number?)
            Text('Belge numarası: $number'),
          if (item.issuedDate case final issued?)
            Text('Düzenlenme tarihi: $issued'),
          if (item.expiryDate case final expiry?)
            Text('Son geçerlilik tarihi: $expiry')
          else if (item.sourceStatus == ComplianceSourceStatus.valid)
            const Text(WorkforceComplianceSummary.noExpiryLabel),
          if (item.note case final note?) Text('Not: $note'),
          if (item.reason case final reason?) Text('Gerekçe: $reason'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              TextButton.icon(
                key: Key('edit-compliance-${item.id}'),
                style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                onPressed: () => _saveCompliance(item),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Düzenle'),
              ),
              TextButton.icon(
                key: Key('archive-compliance-${item.id}'),
                style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                onPressed: () => _archiveCompliance(item),
                icon: const Icon(Icons.archive_outlined),
                label: const Text('Arşivle'),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _ppe(WorkforcePersonDetail detail) => ListView(
    padding: const EdgeInsets.all(12),
    children: [
      FilledButton.icon(
        key: const Key('add-ppe-assignment'),
        onPressed: _savePpe,
        icon: const Icon(Icons.health_and_safety_outlined),
        label: const Text('KKD zimmeti ekle'),
      ),
      const SizedBox(height: 8),
      for (final item in detail.ppeAssignments)
        Card(
          key: Key('ppe-${item.id}'),
          child: ListTile(
            onTap: () => _savePpe(item),
            title: Text('${item.ppeType} • ${item.quantity} adet'),
            subtitle: Text('${item.status.label} • ${item.assignedDate}'),
            trailing: const Icon(Icons.chevron_right),
          ),
        ),
    ],
  );

  Widget _row(String label, String value) => Card(
    child: ListTile(title: Text(label), subtitle: Text(value)),
  );
}

class _Summary extends StatelessWidget {
  const _Summary({required this.detail});
  final WorkforcePersonDetail detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final compliance = WorkforceComplianceSummary(detail.compliance);
    return Card(
      key: const Key('workforce-person-profile'),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Personel profili', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Text(detail.member.fullName, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Chip(
                label: Text(detail.member.isActive ? 'Aktif' : 'Pasif'),
              ),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns =
                    constraints.maxWidth >= 600 &&
                        MediaQuery.textScalerOf(context).scale(14) <= 21
                    ? 2
                    : 1;
                final width =
                    (constraints.maxWidth - (columns - 1) * 24) / columns;
                return Wrap(
                  spacing: 24,
                  runSpacing: 20,
                  children: [
                    for (final field in [
                      (
                        'İşveren / firma',
                        _value(detail.member.subcontractorName),
                      ),
                      ('Meslek', _value(detail.member.roleName)),
                      ('Başlangıç tarihi', _value(detail.member.startedOn)),
                    ])
                      SizedBox(
                        width: width,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(field.$1, style: theme.textTheme.labelLarge),
                            const SizedBox(height: 4),
                            Text(field.$2, style: theme.textTheme.bodyLarge),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            Text('Not', style: theme.textTheme.labelLarge),
            const SizedBox(height: 4),
            Text(_value(detail.member.note), style: theme.textTheme.bodyLarge),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(),
            ),
            Text('İSG kayıt durumu', style: theme.textTheme.titleMedium),
            for (final signal in compliance.signals)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(signal),
              ),
            const SizedBox(height: 8),
            const Text(WorkforceComplianceSummary.scopeLabel),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                key: const Key('profile-open-compliance'),
                style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                onPressed: () => DefaultTabController.of(context).animateTo(2),
                child: const Text('İSG ekranına git'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _value(String? value) =>
      value == null || value.trim().isEmpty ? 'Belirtilmedi' : value;
}

const _gap = SizedBox(height: 10);

TextField _field(
  TextEditingController controller,
  String label, {
  int maxLines = 1,
}) => TextField(
  controller: controller,
  maxLines: maxLines,
  decoration: InputDecoration(
    labelText: label,
    border: const OutlineInputBorder(),
  ),
);

class _ComplianceInput {
  const _ComplianceInput(
    this.type,
    this.status,
    this.number,
    this.issued,
    this.expiry,
    this.note,
    this.reason,
  );
  final ComplianceDocumentType type;
  final ComplianceSourceStatus status;
  final String number;
  final String issued;
  final String expiry;
  final String note;
  final String reason;
}

class _PpeInput {
  const _PpeInput(
    this.type,
    this.brand,
    this.size,
    this.serial,
    this.quantity,
    this.assigned,
    this.status,
    this.returned,
    this.note,
  );
  final String type;
  final String brand;
  final String size;
  final String serial;
  final int quantity;
  final String assigned;
  final PpeAssignmentStatus status;
  final String returned;
  final String note;
}

String _message(Object error, String fallback) =>
    error is AgendaValidationFailure ? error.message : fallback;
