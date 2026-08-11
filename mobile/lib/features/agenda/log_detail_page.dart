import 'dart:convert';

import 'package:chief_site_engineer/application/agenda_application.dart';
import 'package:chief_site_engineer/application/attachment_catalog_application.dart';
import 'package:chief_site_engineer/application/concrete_application.dart';
import 'package:chief_site_engineer/core/record_id.dart';
import 'package:chief_site_engineer/core/time/cse_time_codec.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/domain/attachment_models.dart';
import 'package:chief_site_engineer/features/agenda/agenda_concrete_signal.dart';
import 'package:chief_site_engineer/features/agenda/agenda_concrete_suggestion_card.dart';
import 'package:chief_site_engineer/features/agenda/agenda_photo_viewer_page.dart';
import 'package:chief_site_engineer/features/agenda/log_form_page.dart';
import 'package:chief_site_engineer/features/attachments/attachment_catalog_page.dart';
import 'package:chief_site_engineer/features/concrete/concrete_destination_page.dart';
import 'package:chief_site_engineer/features/concrete/concrete_pour_detail_page.dart';
import 'package:chief_site_engineer/features/reminders/reminder_detail_page.dart';
import 'package:chief_site_engineer/features/reminders/reminder_form_page.dart';
import 'package:chief_site_engineer/platform/attachment_gateway.dart';
import 'package:flutter/material.dart';

class LogDetailPage extends StatefulWidget {
  const LogDetailPage({
    required this.agenda,
    required this.logId,
    this.projectLocations,
    this.attachments,
    this.concrete,
    this.concreteAttachments,
    super.key,
  });

  final AgendaApplication agenda;
  final ProjectLocationApplication? projectLocations;
  final String logId;
  final SafeAttachmentPicker? attachments;
  final ConcreteApplication? concrete;
  final SafeAttachmentPicker? concreteAttachments;

  @override
  State<LogDetailPage> createState() => _LogDetailPageState();
}

class _LogDetailPageState extends State<LogDetailPage> {
  late Future<AgendaLogDetail> _detail;
  bool _mutating = false;
  String? _error;

  AttachmentCatalogApplication? get _attachmentCatalog =>
      widget.agenda is AttachmentCatalogHost
      ? (widget.agenda as AttachmentCatalogHost).attachmentCatalog
      : null;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _detail = widget.agenda.getAgendaLogDetail(widget.logId);
  }

  Future<void> _createReminder(AgendaLog log) async {
    await Navigator.of(context).push<MobileReminder>(
      MaterialPageRoute(
        builder: (_) => ReminderFormPage(
          agenda: widget.agenda,
          projectLocations: widget.projectLocations,
          log: log,
        ),
      ),
    );
    if (mounted) setState(_reload);
  }

  Future<void> _openManagedConcrete(String pourId) async {
    final concrete = widget.concrete;
    final attachments = widget.concreteAttachments;
    if (concrete == null || attachments == null) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ConcretePourDetailPage(
          concrete: concrete,
          agenda: widget.agenda,
          attachments: attachments,
          projectLocations: widget.projectLocations,
          pourId: pourId,
        ),
      ),
    );
    if (mounted) setState(_reload);
  }

  Future<void> _openConcreteList(AgendaLog log) async {
    final concrete = widget.concrete;
    final attachments = widget.concreteAttachments;
    if (concrete == null || attachments == null) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ConcreteDestinationPage(
          concrete: concrete,
          agenda: widget.agenda,
          attachments: attachments,
          projectLocations: widget.projectLocations,
          initialProjectId: log.projectId,
          initialIstanbulDay: CseTimeCodec.istanbulDayKey(log.observedAt),
        ),
      ),
    );
  }

  Future<void> _edit(AgendaLog log) async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => LogFormPage(
          agenda: widget.agenda,
          projectLocations: widget.projectLocations,
          attachments: widget.attachments,
          concrete: widget.concrete,
          concreteAttachments: widget.concreteAttachments,
          existing: log,
        ),
      ),
    );
    if (result != null && mounted) setState(_reload);
  }

  Future<void> _mutateArchive(AgendaLog log) async {
    if (log.archivedAt == null) {
      final accepted = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Ajanda kaydını sil'),
          content: const Text(
            'Kayıt arşive taşınacak, geri getirilebilir. Bağlı '
            'hatırlatıcıların yaşam döngüsü değişmeyecek.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              key: const Key('confirm-archive-log'),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Arşive taşı'),
            ),
          ],
        ),
      );
      if (accepted != true) return;
    }
    await _run(
      () => widget.agenda.mutateAgendaLogArchive(
        MutateAgendaLogArchiveCommand(
          id: log.id,
          eventId: RecordId.randomUuid(),
          expectedRevision: log.revision,
          archive: log.archivedAt == null,
        ),
      ),
    );
  }

  Future<void> _addPhoto(AgendaLog log) async {
    final picker = widget.attachments;
    if (picker == null) return;
    final source = await showModalBottomSheet<AttachmentSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Kamera'),
              onTap: () => Navigator.pop(context, AttachmentSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Sistem fotoğraf seçici'),
              onTap: () =>
                  Navigator.pop(context, AttachmentSource.photoLibrary),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final selected = await picker.pickMany(source);
    if (!mounted) return;
    if (selected.$1 != AttachmentPickOutcome.selected || selected.$2.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fotoğraf eklenmedi; Ajanda kaydı değişmedi.'),
        ),
      );
      return;
    }
    final capturedAt = CseTimeCodec.encodeUtc(DateTime.now().toUtc());
    final photos = selected.$2
        .map(
          (item) => AgendaPhotoDraft(
            id: RecordId.randomUuid(),
            eventId: RecordId.randomUuid(),
            originalFileName: item.name,
            bytes: item.bytes,
            capturedAt: capturedAt,
          ),
        )
        .toList(growable: false);
    await _run(() {
      final agenda = widget.agenda;
      if (agenda case final AgendaPhotoBatchApplication batchAgenda) {
        return batchAgenda.attachAgendaPhotos(
          AttachAgendaPhotosCommand(
            logId: log.id,
            expectedLogRevision: log.revision,
            photos: photos,
          ),
        );
      }
      if (photos.length == 1) {
        final photo = photos.single;
        return agenda.attachAgendaPhoto(
          AttachAgendaPhotoCommand(
            logId: log.id,
            id: photo.id,
            eventId: photo.eventId,
            expectedLogRevision: log.revision,
            originalFileName: photo.originalFileName,
            bytes: photo.bytes,
            capturedAt: photo.capturedAt,
          ),
        );
      }
      throw const AgendaValidationFailure(
        'Çoklu fotoğraf ekleme bu uygulama oturumunda kullanılamıyor.',
      );
    });
  }

  Future<void> _archivePhoto(AgendaLog log, AgendaLogPhoto photo) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fotoğrafı arşivle'),
        content: const Text(
          'Fotoğraf fiziksel olarak silinmeyecek; event geçmişi korunacak.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Arşivle'),
          ),
        ],
      ),
    );
    if (accepted != true) return;
    await _run(
      () => widget.agenda.archiveAgendaPhoto(
        ArchiveAgendaPhotoCommand(
          logId: log.id,
          photoId: photo.id,
          eventId: RecordId.randomUuid(),
          expectedLogRevision: log.revision,
          expectedPhotoRevision: photo.revision,
        ),
      ),
    );
  }

  Future<void> _linkExistingPhoto(AgendaLog log) async {
    final catalog = _attachmentCatalog;
    final agenda = widget.agenda;
    if (catalog == null || agenda is! AgendaExistingAttachmentApplication) {
      return;
    }
    final existingAgenda = agenda as AgendaExistingAttachmentApplication;
    final selected = await Navigator.of(context)
        .push<ProjectAttachmentCatalogItem>(
          MaterialPageRoute(
            builder: (_) => AttachmentCatalogPage(
              catalog: catalog,
              initialProjectId: log.projectId,
              selectionSourceType:
                  AttachmentCatalogSourceType.agendaObservation,
              selectionSourceId: log.id,
              allowedMimeTypes: const {'image/jpeg', 'image/png', 'image/heic'},
              title: 'Mevcut fotoğrafı bağla',
            ),
          ),
        );
    if (selected == null || !mounted) return;
    await _run(
      () => existingAgenda.linkExistingAgendaPhoto(
        LinkExistingAgendaPhotoCommand(
          logId: log.id,
          physicalAttachmentId: selected.physicalAttachmentId,
          linkId: RecordId.randomUuid(),
          eventId: RecordId.randomUuid(),
          expectedLogRevision: log.revision,
        ),
      ),
    );
  }

  Future<void> _run(Future<Object?> Function() action) async {
    if (_mutating) return;
    setState(() {
      _mutating = true;
      _error = null;
    });
    try {
      await action();
      if (mounted) setState(_reload);
    } on AgendaValidationFailure catch (error) {
      if (mounted) setState(() => _error = error.message);
    } on Object {
      if (mounted) {
        setState(() => _error = 'İşlem güvenli biçimde tamamlanamadı.');
      }
    } finally {
      if (mounted) setState(() => _mutating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AgendaLogDetail>(
      future: _detail,
      builder: (context, snapshot) {
        final detail = snapshot.data;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Ajanda kaydı'),
            actions: [
              if (detail != null && detail.managedConcretePourId == null)
                Semantics(
                  button: true,
                  label: 'Hatırlatıcı oluştur',
                  child: IconButton(
                    key: const Key('detail-reminder-action'),
                    tooltip: 'Hatırlatıcı oluştur',
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    onPressed: _mutating || detail.log.archivedAt != null
                        ? null
                        : () => _createReminder(detail.log),
                    icon: const Icon(Icons.add_alarm_outlined),
                  ),
                ),
            ],
          ),
          body: _body(snapshot),
        );
      },
    );
  }

  Widget _body(AsyncSnapshot<AgendaLogDetail> snapshot) {
    if (snapshot.connectionState != ConnectionState.done) {
      return const Center(child: CircularProgressIndicator());
    }
    if (snapshot.hasError || !snapshot.hasData) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Ajanda kaydı güvenli biçimde okunamadı.'),
        ),
      );
    }
    final detail = snapshot.requireData;
    final log = detail.log;
    final history = _agendaUpdateHistory(detail.events);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_mutating) const LinearProgressIndicator(),
        if (_error case final error?)
          Card(
            color: Theme.of(context).colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(error),
            ),
          ),
        if (log.archivedAt != null)
          const Card(
            child: ListTile(
              leading: Icon(Icons.archive_outlined),
              title: Text('Bu kayıt arşivde'),
              subtitle: Text('Bağlı hatırlatıcılar değiştirilmedi.'),
            ),
          ),
        if (detail.managedConcretePourId case final pourId?)
          Card(
            key: const Key('managed-concrete-agenda'),
            child: ListTile(
              leading: const Icon(Icons.lock_outline),
              title: const Text('Beton paketi tarafından yönetiliyor'),
              subtitle: const Text(
                'Ana metin ve arşiv durumu Beton paketinden yönetilir.',
              ),
              trailing:
                  widget.concrete != null && widget.concreteAttachments != null
                  ? const Icon(Icons.chevron_right)
                  : null,
              onTap:
                  widget.concrete != null && widget.concreteAttachments != null
                  ? () => _openManagedConcrete(pourId)
                  : null,
            ),
          ),
        if (detail.managedConcretePourId == null &&
            AgendaConcreteSignalDetector.hasSignal(
              description: log.description,
              notes: log.notes,
              category: log.category,
            ))
          AgendaConcreteSuggestionCard(
            key: const Key('agenda-concrete-detail-suggestion'),
            message: 'Bu kayıt Beton işiyle ilgili olabilir.',
            onOpenConcrete:
                widget.concrete != null && widget.concreteAttachments != null
                ? () => _openConcreteList(log)
                : null,
            openConcreteKey: const Key('agenda-concrete-detail-open'),
          ),
        Text(
          log.category.label,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(log.description, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),
        _DetailRow(label: 'Proje', value: log.projectName),
        _DetailRow(
          label: 'Olay zamanı',
          value: CseTimeCodec.formatIstanbul(log.observedAt),
        ),
        _DetailRow(
          label: 'CSE’ye giriş',
          value: CseTimeCodec.formatIstanbul(log.createdAt),
        ),
        if (log.displayLocation != null)
          _DetailRow(label: 'Mahal', value: log.displayLocation!),
        if (log.stableLocationArchivedAt != null)
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text(
              'Arşivli mahal',
              key: Key('archived-stable-location-indicator'),
            ),
          ),
        if (log.notes != null)
          _DetailRow(label: 'Ayrıntılı not', value: log.notes!),
        const SizedBox(height: 12),
        if (detail.managedConcretePourId == null)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (log.archivedAt == null)
                OutlinedButton.icon(
                  key: const Key('edit-agenda-log'),
                  onPressed: _mutating ? null : () => _edit(log),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Düzenle'),
                ),
              FilledButton.tonalIcon(
                key: Key(
                  log.archivedAt == null
                      ? 'archive-agenda-log'
                      : 'restore-agenda-log',
                ),
                onPressed: _mutating ? null : () => _mutateArchive(log),
                icon: Icon(
                  log.archivedAt == null
                      ? Icons.delete_outline
                      : Icons.restore_outlined,
                ),
                label: Text(log.archivedAt == null ? 'Sil' : 'Geri getir'),
              ),
            ],
          ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: Text(
                'Fotoğraflar',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            if (log.archivedAt == null && widget.attachments != null)
              IconButton.filledTonal(
                key: const Key('detail-add-agenda-photo'),
                tooltip: 'Fotoğraf ekle',
                onPressed: _mutating ? null : () => _addPhoto(log),
                icon: const Icon(Icons.add_a_photo_outlined),
              ),
            if (log.archivedAt == null &&
                _attachmentCatalog != null &&
                widget.agenda is AgendaExistingAttachmentApplication)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: IconButton.filledTonal(
                  key: const Key('detail-link-existing-agenda-photo'),
                  tooltip: 'Mevcut fotoğrafı bağla',
                  onPressed: _mutating ? null : () => _linkExistingPhoto(log),
                  icon: const Icon(Icons.add_link_rounded),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (detail.photos.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Bu kayda bağlı fotoğraf yok.'),
            ),
          )
        else
          ...detail.photos.map(
            (photo) => Card(
              child: ListTile(
                key: Key('agenda-photo-${photo.id}'),
                minVerticalPadding: 10,
                leading: SizedBox.square(
                  dimension: 56,
                  child: AgendaPhotoThumbnail(
                    agenda: widget.agenda,
                    photo: photo,
                  ),
                ),
                title: Text(photo.originalFileName),
                subtitle: Text(
                  '${photo.integrity.label} • ${photo.byteSize} byte\n'
                  '${photo.sha256.substring(0, 12)}…',
                ),
                isThreeLine: true,
                onTap: () => Navigator.of(context).push<void>(
                  MaterialPageRoute(
                    builder: (_) => AgendaPhotoViewerPage(
                      agenda: widget.agenda,
                      photo: photo,
                    ),
                  ),
                ),
                trailing: log.archivedAt == null
                    ? IconButton(
                        tooltip: 'Fotoğrafı arşivle',
                        onPressed: _mutating
                            ? null
                            : () => _archivePhoto(log, photo),
                        icon: const Icon(Icons.archive_outlined),
                      )
                    : null,
              ),
            ),
          ),
        const SizedBox(height: 24),
        Text(
          'Bağlı hatırlatıcılar',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        if (detail.reminders.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Bu kayda bağlı aktif hatırlatıcı yok.'),
            ),
          )
        else
          ...detail.reminders.map(
            (reminder) => Card(
              child: ListTile(
                key: Key('linked-reminder-${reminder.id}'),
                minVerticalPadding: 12,
                title: Text(
                  reminder.title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '${reminder.kind.label} • ${reminder.status.label}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  await Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) => ReminderDetailPage(
                        agenda: widget.agenda,
                        projectLocations: widget.projectLocations,
                        reminderId: reminder.id,
                      ),
                    ),
                  );
                  if (mounted) setState(_reload);
                },
              ),
            ),
          ),
        if (detail.trashedReminders.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            'Çöpteki bağlı hatırlatıcılar',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          ...detail.trashedReminders.map(
            (reminder) => Card(
              child: ListTile(
                key: Key('trashed-linked-reminder-${reminder.id}'),
                minVerticalPadding: 12,
                leading: const Icon(Icons.delete_outline),
                title: Text(
                  reminder.title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '${reminder.kind.label} • ${reminder.status.label} • Çöpte',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  await Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) => ReminderDetailPage(
                        agenda: widget.agenda,
                        projectLocations: widget.projectLocations,
                        reminderId: reminder.id,
                      ),
                    ),
                  );
                  if (mounted) setState(_reload);
                },
              ),
            ),
          ),
        ],
        if (history.isNotEmpty) ...[
          const SizedBox(height: 24),
          _AgendaHistorySection(entries: history),
        ],
      ],
    );
  }
}

const _agendaUpdateFieldLabels = <String, String>{
  'observed_at': 'Olay zamanı',
  'category': 'Tür',
  'description': 'Açıklama',
  'location': 'Mahal',
  'notes': 'Ayrıntılı not',
  'project_id': 'Proje kimliği',
};

List<_AgendaHistoryEntry> _agendaUpdateHistory(
  Iterable<AppendOnlyEvent> events,
) {
  final updates = events
      .where((event) => event.eventType == 'agenda_log.updated')
      .toList(growable: false);
  return updates.reversed.map(_agendaUpdateEntry).toList(growable: false);
}

_AgendaHistoryEntry _agendaUpdateEntry(AppendOnlyEvent event) {
  try {
    final payload = jsonDecode(event.payloadJson);
    if (payload is! Map<String, dynamic>) {
      return _AgendaHistoryEntry.malformed(event);
    }
    final before = payload['before'];
    final after = payload['after'];
    if (before is! Map<String, dynamic> || after is! Map<String, dynamic>) {
      return _AgendaHistoryEntry.malformed(event);
    }
    return _AgendaHistoryEntry(
      event: event,
      changes: [
        for (final field in _agendaUpdateFieldLabels.entries)
          if (before[field.key] != after[field.key])
            _AgendaHistoryChange(
              label: field.value,
              before: _agendaHistoryValue(field.key, before[field.key]),
              after: _agendaHistoryValue(field.key, after[field.key]),
            ),
      ],
    );
  } on FormatException {
    return _AgendaHistoryEntry.malformed(event);
  }
}

String _agendaHistoryValue(String field, Object? value) {
  if (field == 'observed_at') {
    if (value is! String) return 'Okunamadı';
    try {
      return CseTimeCodec.formatIstanbul(value);
    } on TimeContractViolation {
      return 'Okunamadı';
    }
  }
  if (field == 'category') {
    if (value is! String) return 'Okunamadı';
    try {
      return AgendaCategory.fromStorage(value).label;
    } on AgendaValidationFailure {
      return 'Okunamadı';
    }
  }
  if (field == 'project_id') {
    return value is String && RecordId.isUuid(value) ? value : '—';
  }
  return value is String && value.trim().isNotEmpty ? value : '—';
}

String _agendaHistoryOccurredAt(String value) {
  try {
    return CseTimeCodec.formatIstanbul(value);
  } on TimeContractViolation {
    return 'Zaman okunamadı';
  }
}

class _AgendaHistoryEntry {
  const _AgendaHistoryEntry({required this.event, required this.changes})
    : malformed = false;

  const _AgendaHistoryEntry.malformed(this.event)
    : changes = const [],
      malformed = true;

  final AppendOnlyEvent event;
  final List<_AgendaHistoryChange> changes;
  final bool malformed;
}

class _AgendaHistoryChange {
  const _AgendaHistoryChange({
    required this.label,
    required this.before,
    required this.after,
  });

  final String label;
  final String before;
  final String after;
}

class _AgendaHistorySection extends StatelessWidget {
  const _AgendaHistorySection({required this.entries});

  final List<_AgendaHistoryEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('agenda-change-history-section'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Değişiklik geçmişi',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        for (final entry in entries)
          Card(
            key: Key('agenda-change-history-${entry.event.id}'),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _agendaHistoryOccurredAt(entry.event.occurredAt),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (entry.malformed)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text('Değişiklik ayrıntısı okunamadı.'),
                    )
                  else
                    for (final change in entry.changes) ...[
                      const SizedBox(height: 12),
                      Text(
                        change.label,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 2),
                      Text('Önce: ${change.before}'),
                      Text('Sonra: ${change.after}'),
                    ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 2),
          SelectableText(value),
        ],
      ),
    );
  }
}
