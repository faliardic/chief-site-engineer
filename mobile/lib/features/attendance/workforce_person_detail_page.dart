import 'package:chief_site_engineer/application/attendance_application.dart';
import 'package:chief_site_engineer/core/record_id.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/domain/attendance_models.dart';
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
    final input = await showDialog<_ComplianceInput>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            current == null ? 'İSG belgesi ekle' : 'İSG belgesini düzenle',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<ComplianceDocumentType>(
                  initialValue: type,
                  isExpanded: true,
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
                  decoration: const InputDecoration(
                    labelText: 'Kullanıcı durumu',
                  ),
                  items: ComplianceSourceStatus.values
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
                _field(number, 'Belge numarası'),
                _gap,
                _field(issued, 'Düzenlenme tarihi (YYYY-AA-GG)'),
                _gap,
                _field(expiry, 'Son geçerlilik tarihi (YYYY-AA-GG)'),
                _gap,
                _field(reason, 'İstisna/uygulanamaz gerekçesi'),
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
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(detail?.member.fullName ?? 'Personel detayı'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Genel / Puantaj'),
              Tab(text: 'İSG belgeleri'),
              Tab(text: 'KKD zimmetleri'),
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
                    _Summary(detail: detail),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _general(detail),
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

  Widget _general(WorkforcePersonDetail detail) => ListView(
    padding: const EdgeInsets.all(12),
    children: [
      _row('Durum', detail.member.isActive ? 'Aktif' : 'Pasif'),
      _row('Taşeron', detail.member.subcontractorName ?? 'Tanımsız'),
      _row('Ekip', detail.member.teamName),
      _row('Meslek/pozisyon', detail.member.roleName),
      if (detail.member.personnelCode != null)
        _row('Personel kodu', detail.member.personnelCode!),
      if (detail.member.phone != null) _row('Telefon', detail.member.phone!),
      if (detail.member.note != null) _row('Not', detail.member.note!),
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
  );

  Widget _compliance(WorkforcePersonDetail detail) => ListView(
    padding: const EdgeInsets.all(12),
    children: [
      FilledButton.icon(
        key: const Key('add-compliance-record'),
        onPressed: _saveCompliance,
        icon: const Icon(Icons.post_add_outlined),
        label: const Text('İSG belgesi ekle'),
      ),
      const SizedBox(height: 8),
      const Text(
        'Bu durumlar yalnız kayıt görünürlüğüdür; hukuki uygunluk veya işe kabul kararı değildir.',
      ),
      for (final item in detail.compliance)
        Card(
          key: Key('compliance-${item.id}'),
          child: ListTile(
            onTap: () => _saveCompliance(item),
            title: Text(item.documentType.label),
            subtitle: Text(
              '${item.readStatus.label}'
              '${item.expiryDate == null ? '' : ' • ${item.expiryDate}'}',
            ),
            trailing: IconButton(
              tooltip: 'Arşivle',
              onPressed: () => _archiveCompliance(item),
              icon: const Icon(Icons.archive_outlined),
            ),
          ),
        ),
    ],
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
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
    child: Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        Chip(label: Text(detail.member.isActive ? 'Aktif' : 'Pasif')),
        Chip(
          label: Text(detail.member.subcontractorName ?? 'Tanımsız taşeron'),
        ),
        Chip(label: Text(detail.member.teamName)),
        Chip(label: Text('İSG eksik ${detail.missingComplianceCount}')),
        Chip(label: Text('geçerli ${detail.validComplianceCount}')),
        Chip(label: Text('yaklaşan ${detail.expiringComplianceCount}')),
        Chip(label: Text('geçmiş ${detail.expiredComplianceCount}')),
        Chip(label: Text('aktif KKD ${detail.activePpeCount}')),
      ],
    ),
  );
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
