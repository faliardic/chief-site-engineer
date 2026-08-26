import 'dart:typed_data';

import 'package:chief_site_engineer/application/agenda_application.dart';
import 'package:chief_site_engineer/application/attachment_catalog_application.dart';
import 'package:chief_site_engineer/application/concrete_application.dart';
import 'package:chief_site_engineer/core/time/cse_time_codec.dart';
import 'package:chief_site_engineer/domain/attachment_models.dart';
import 'package:chief_site_engineer/features/agenda/log_detail_page.dart';
import 'package:chief_site_engineer/features/concrete/concrete_pour_detail_page.dart';
import 'package:chief_site_engineer/platform/attachment_gateway.dart';
import 'package:flutter/material.dart';

class ProjectMediaAlbumPage extends StatefulWidget {
  const ProjectMediaAlbumPage({
    required this.catalog,
    required this.agenda,
    this.concrete,
    this.attachments,
    this.projectLocations,
    super.key,
  });

  final AttachmentCatalogApplication catalog;
  final AgendaApplication agenda;
  final ConcreteApplication? concrete;
  final SafeAttachmentPicker? attachments;
  final ProjectLocationApplication? projectLocations;

  @override
  State<ProjectMediaAlbumPage> createState() => _ProjectMediaAlbumPageState();
}

class _ProjectMediaAlbumPageState extends State<ProjectMediaAlbumPage> {
  static const _allContexts = 'all';
  static const _noContext = 'none';

  late Future<_AlbumView> _view;
  String? _selectedProjectId;
  _AlbumMediaFilter _mediaFilter = _AlbumMediaFilter.all;
  AttachmentCatalogSourceType? _sourceFilter;
  String _contextFilter = _allContexts;
  DateTimeRange? _dateRange;
  bool _openingMedia = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _view = _load(_selectedProjectId);
  }

  Future<_AlbumView> _load(String? requestedProjectId) async {
    final projects = await widget.catalog.listProjects();
    var selectedProjectId = requestedProjectId;
    if (selectedProjectId != null &&
        !projects.any((project) => project.id == selectedProjectId)) {
      selectedProjectId = null;
    }
    if (selectedProjectId == null && projects.isNotEmpty) {
      selectedProjectId = projects.first.id;
    }
    final items = selectedProjectId == null
        ? const <ProjectAttachmentCatalogItem>[]
        : await widget.catalog.listProjectAttachments(selectedProjectId);
    return _AlbumView(
      projects: projects,
      selectedProjectId: selectedProjectId,
      items: items.where((item) => item.isAlbumMedia).toList(growable: false),
    );
  }

  void _selectProject(String? projectId) {
    if (projectId == null || projectId == _selectedProjectId) return;
    setState(() {
      _selectedProjectId = projectId;
      _mediaFilter = _AlbumMediaFilter.all;
      _sourceFilter = null;
      _contextFilter = _allContexts;
      _dateRange = null;
      _reload();
    });
  }

  Future<void> _refresh() async {
    setState(_reload);
    await _view;
  }

  Future<void> _pickDateRange() async {
    final selected = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: _dateRange,
      helpText: 'CSE’ye eklenme tarihi',
      saveText: 'Uygula',
    );
    if (selected != null && mounted) {
      setState(() => _dateRange = selected);
    }
  }

  List<ProjectAttachmentCatalogItem> _filteredItems(
    List<ProjectAttachmentCatalogItem> items,
    String effectiveContextFilter,
  ) => items
      .where((item) {
        if (!_mediaFilter.matches(item)) return false;
        if (_sourceFilter != null &&
            !item.links.any((link) => link.sourceType == _sourceFilter)) {
          return false;
        }
        if (!_matchesContext(item, effectiveContextFilter)) return false;
        return _matchesDate(item);
      })
      .toList(growable: false);

  bool _matchesContext(
    ProjectAttachmentCatalogItem item,
    String effectiveContextFilter,
  ) {
    if (effectiveContextFilter == _allContexts) return true;
    if (effectiveContextFilter == _noContext) {
      return item.links.every(
        (link) =>
            link.stableLocationId == null &&
            (link.contextType == null || link.contextId == null),
      );
    }
    return item.links.any(
      (link) =>
          _stableLocationFilterKey(link) == effectiveContextFilter ||
          _linkContextFilterKey(link) == effectiveContextFilter,
    );
  }

  bool _matchesDate(ProjectAttachmentCatalogItem item) {
    final range = _dateRange;
    if (range == null) return true;
    final addedAt = _istanbulTime(item.createdAt);
    if (addedAt == null) return false;
    final day = DateTime(addedAt.year, addedAt.month, addedAt.day);
    final start = DateTime(
      range.start.year,
      range.start.month,
      range.start.day,
    );
    final end = DateTime(range.end.year, range.end.month, range.end.day);
    return !day.isBefore(start) && !day.isAfter(end);
  }

  List<_ContextFilterOption> _contextOptions(
    List<ProjectAttachmentCatalogItem> items,
  ) {
    final options = <String, String>{};
    var hasNoContext = false;
    for (final item in items) {
      var itemHasContext = false;
      for (final link in item.links) {
        final stableLocationKey = _stableLocationFilterKey(link);
        final stableLocationName = link.stableLocationName;
        if (stableLocationKey != null && stableLocationName != null) {
          options[stableLocationKey] = 'Mahal • $stableLocationName';
          itemHasContext = true;
        }
        final contextKey = _linkContextFilterKey(link);
        if (contextKey != null) {
          options[contextKey] = link.contextLabel == null
              ? 'Bağlam kayıt okunamadı'
              : 'Bağlam • ${link.contextLabel}';
          itemHasContext = true;
        }
      }
      if (!itemHasContext) hasNoContext = true;
    }
    final result =
        options.entries
            .map(
              (entry) => _ContextFilterOption(
                storageValue: entry.key,
                label: entry.value,
              ),
            )
            .toList(growable: true)
          ..sort((left, right) => left.label.compareTo(right.label));
    if (hasNoContext) {
      result.add(
        const _ContextFilterOption(
          storageValue: _noContext,
          label: 'Mahal/bağlam bilgisi yok',
        ),
      );
    }
    return result;
  }

  Future<void> _previewOrOpen(ProjectAttachmentCatalogItem item) async {
    if (_openingMedia || item.integrity != ManagedAttachmentIntegrity.healthy) {
      return;
    }
    final catalog = widget.catalog;
    if (catalog is! AttachmentCatalogMediaAccess) {
      _showMessage('Medya erişimi bu oturumda kullanılamıyor.');
      return;
    }
    final mediaAccess = catalog as AttachmentCatalogMediaAccess;
    if (item.supportsInlinePreview) {
      final content = mediaAccess.readAttachment(item);
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(item.displayFileName),
          content: SizedBox(
            width: 640,
            height: 480,
            child: FutureBuilder<ManagedAttachmentContent>(
              future: content,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError || !snapshot.hasData) {
                  return const _AlbumMessage(
                    icon: Icons.warning_amber_rounded,
                    message: 'Medya güvenli biçimde önizlenemedi.',
                  );
                }
                final bytes = snapshot.requireData.bytes;
                final imageBytes = bytes is Uint8List
                    ? bytes
                    : Uint8List.fromList(bytes);
                return InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4,
                  child: Center(
                    child: Image.memory(
                      imageBytes,
                      fit: BoxFit.contain,
                      semanticLabel: item.displayFileName,
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Kapat'),
            ),
          ],
        ),
      );
      return;
    }
    setState(() => _openingMedia = true);
    try {
      await mediaAccess.openAttachment(item);
    } on Object {
      if (mounted) {
        _showMessage('Medya güvenli biçimde açılamadı.');
      }
    } finally {
      if (mounted) setState(() => _openingMedia = false);
    }
  }

  Future<void> _openSource(AttachmentCatalogLink link) async {
    if (!link.sourceAvailable) return;
    try {
      switch (link.sourceType) {
        case AttachmentCatalogSourceType.agendaObservation:
          await Navigator.of(context).push<void>(
            MaterialPageRoute(
              builder: (_) => LogDetailPage(
                agenda: widget.agenda,
                projectLocations: widget.projectLocations,
                attachments: widget.attachments,
                concrete: widget.concrete,
                concreteAttachments: widget.attachments,
                logId: link.sourceId,
              ),
            ),
          );
          break;
        case AttachmentCatalogSourceType.concretePour:
          final concrete = widget.concrete;
          final attachments = widget.attachments;
          if (concrete == null || attachments == null) {
            _showMessage('Beton kaynağı bu oturumda açılamıyor.');
            return;
          }
          await Navigator.of(context).push<void>(
            MaterialPageRoute(
              builder: (_) => ConcretePourDetailPage(
                concrete: concrete,
                agenda: widget.agenda,
                attachments: attachments,
                projectLocations: widget.projectLocations,
                pourId: link.sourceId,
              ),
            ),
          );
          break;
      }
      if (mounted) setState(_reload);
    } on Object {
      if (mounted) {
        _showMessage('Kaynak kayıt güvenli biçimde açılamadı.');
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Proje Albümü'),
        actions: [
          IconButton(
            key: const Key('refresh-project-media-album'),
            tooltip: 'Albümü yenile',
            onPressed: () => setState(_reload),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: FutureBuilder<_AlbumView>(
        future: _view,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const _AlbumMessage(
              key: Key('project-media-album-error'),
              icon: Icons.warning_amber_rounded,
              message: 'Proje albümü güvenli biçimde açılamadı.',
            );
          }
          final view = snapshot.requireData;
          final contextOptions = _contextOptions(view.items);
          final effectiveContextFilter =
              contextOptions.any(
                (option) => option.storageValue == _contextFilter,
              )
              ? _contextFilter
              : _allContexts;
          final visibleItems = _filteredItems(
            view.items,
            effectiveContextFilter,
          );
          final projectBytes = _totalBytes(view.items);
          final visibleBytes = _totalBytes(visibleItems);
          return RefreshIndicator(
            onRefresh: _refresh,
            child: CustomScrollView(
              key: const Key('project-media-album-list'),
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: _filters(
                      view,
                      contextOptions,
                      effectiveContextFilter,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    child: _AlbumSummary(
                      projectCount: view.items.length,
                      projectBytes: projectBytes,
                      visibleCount: visibleItems.length,
                      visibleBytes: visibleBytes,
                    ),
                  ),
                ),
                if (view.projects.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _AlbumMessage(
                      icon: Icons.folder_off_outlined,
                      message: 'Aktif proje bulunamadı.',
                    ),
                  )
                else if (view.items.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _AlbumMessage(
                      key: Key('project-media-album-empty'),
                      icon: Icons.photo_library_outlined,
                      message: 'Bu projede fotoğraf veya video yok.',
                    ),
                  )
                else if (visibleItems.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _AlbumMessage(
                      key: Key('project-media-album-filter-empty'),
                      icon: Icons.filter_alt_off_outlined,
                      message: 'Bu filtrelerle eşleşen medya yok.',
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                    sliver: SliverList.builder(
                      itemCount: visibleItems.length,
                      itemBuilder: (context, index) =>
                          _mediaCard(visibleItems[index]),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _filters(
    _AlbumView view,
    List<_ContextFilterOption> contextOptions,
    String effectiveContextFilter,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          key: ValueKey('album-project-${view.selectedProjectId}'),
          initialValue: view.selectedProjectId,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Proje',
            border: OutlineInputBorder(),
          ),
          items: view.projects
              .map(
                (project) => DropdownMenuItem(
                  value: project.id,
                  child: Text(project.name),
                ),
              )
              .toList(growable: false),
          onChanged: view.projects.isEmpty ? null : _selectProject,
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: DropdownButtonFormField<_AlbumMediaFilter>(
                key: ValueKey('album-media-${_mediaFilter.name}'),
                initialValue: _mediaFilter,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Medya türü',
                  border: OutlineInputBorder(),
                ),
                items: _AlbumMediaFilter.values
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(value.label),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  if (value != null) setState(() => _mediaFilter = value);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                key: ValueKey(
                  'album-source-${_sourceFilter?.storageValue ?? 'all'}',
                ),
                initialValue: _sourceFilter?.storageValue ?? 'all',
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Kaynak',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(value: 'all', child: Text('Tümü')),
                  ...AttachmentCatalogSourceType.values.map(
                    (value) => DropdownMenuItem(
                      value: value.storageValue,
                      child: Text(value.label),
                    ),
                  ),
                ],
                onChanged: (value) => setState(() {
                  _sourceFilter = value == null || value == 'all'
                      ? null
                      : AttachmentCatalogSourceType.fromStorage(value);
                }),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          key: ValueKey('album-context-$effectiveContextFilter'),
          initialValue: effectiveContextFilter,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Mahal / bağlam',
            border: OutlineInputBorder(),
          ),
          items: [
            const DropdownMenuItem(value: _allContexts, child: Text('Tümü')),
            ...contextOptions.map(
              (option) => DropdownMenuItem(
                value: option.storageValue,
                child: Text(option.label),
              ),
            ),
          ],
          onChanged: (value) =>
              setState(() => _contextFilter = value ?? _allContexts),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                key: const Key('project-media-date-filter'),
                onPressed: _pickDateRange,
                icon: const Icon(Icons.date_range_outlined),
                label: Text(_dateRangeLabel(context)),
              ),
            ),
            if (_dateRange != null) ...[
              const SizedBox(width: 8),
              IconButton(
                key: const Key('clear-project-media-date-filter'),
                tooltip: 'Tarih filtresini temizle',
                onPressed: () => setState(() => _dateRange = null),
                icon: const Icon(Icons.clear_rounded),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _mediaCard(ProjectAttachmentCatalogItem item) {
    final healthy = item.integrity == ManagedAttachmentIntegrity.healthy;
    return Card(
      key: Key('project-media-item-${item.physicalAttachmentId}'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Icon(
                    healthy
                        ? item.isVideo
                              ? Icons.play_circle_outline_rounded
                              : Icons.photo_outlined
                        : Icons.warning_amber_rounded,
                    size: 36,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.displayFileName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_mediaLabel(item)} • ${_formatBytes(item.byteSize)}\n'
                        'CSE’ye eklenme: ${_formatIstanbul(item.createdAt)}\n'
                        '${_integrityLabel(item.integrity)}',
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  key: Key('project-media-open-${item.physicalAttachmentId}'),
                  onPressed: healthy && !_openingMedia
                      ? () => _previewOrOpen(item)
                      : null,
                  icon: Icon(
                    item.supportsInlinePreview
                        ? Icons.visibility_outlined
                        : Icons.open_in_new_rounded,
                  ),
                  label: Text(item.supportsInlinePreview ? 'Önizle' : 'Aç'),
                ),
              ],
            ),
            const Divider(height: 24),
            Text(
              'Kaynaklar • ${item.links.length}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            for (final link in item.links) _sourceTile(link),
          ],
        ),
      ),
    );
  }

  Widget _sourceTile(AttachmentCatalogLink link) {
    final canOpen =
        link.sourceAvailable &&
        (link.sourceType != AttachmentCatalogSourceType.concretePour ||
            (widget.concrete != null && widget.attachments != null));
    final details = <String>[
      _roleLabel(link.role),
      link.isActive ? 'Aktif bağ' : 'Arşivli bağ',
      if (!link.sourceAvailable)
        'Kaynak kayıt okunamadı • ${link.sourceId}'
      else if (link.isSourceArchived)
        'Arşivli kaynak',
      if (link.stableLocationName case final location?) 'Mahal: $location',
      if (link.contextType != null && link.contextId != null)
        link.contextLabel == null
            ? 'Bağlam kayıt okunamadı • ${link.contextId}'
            : 'Bağlam: ${link.contextLabel}',
      if (link.description case final description?)
        if (description.trim().isNotEmpty) 'Açıklama: ${description.trim()}',
    ];
    return ListTile(
      key: Key('project-media-link-${link.id}'),
      contentPadding: EdgeInsets.zero,
      minVerticalPadding: 8,
      leading: Icon(
        !link.sourceAvailable
            ? Icons.link_off_rounded
            : link.isActive && !link.isSourceArchived
            ? Icons.link_rounded
            : Icons.history_rounded,
      ),
      title: Text(link.sourceLabel),
      subtitle: Text(details.join('\n')),
      trailing: canOpen ? const Icon(Icons.chevron_right_rounded) : null,
      onTap: canOpen ? () => _openSource(link) : null,
    );
  }

  String _dateRangeLabel(BuildContext context) {
    final range = _dateRange;
    if (range == null) return 'CSE’ye eklenme tarihi';
    final localizations = MaterialLocalizations.of(context);
    return '${localizations.formatCompactDate(range.start)} – '
        '${localizations.formatCompactDate(range.end)}';
  }
}

class _AlbumView {
  const _AlbumView({
    required this.projects,
    required this.selectedProjectId,
    required this.items,
  });

  final List<AttachmentCatalogProject> projects;
  final String? selectedProjectId;
  final List<ProjectAttachmentCatalogItem> items;
}

enum _AlbumMediaFilter {
  all('Tümü'),
  photo('Fotoğraf'),
  video('Video');

  const _AlbumMediaFilter(this.label);

  final String label;

  bool matches(ProjectAttachmentCatalogItem item) => switch (this) {
    _AlbumMediaFilter.all => true,
    _AlbumMediaFilter.photo => item.isImage,
    _AlbumMediaFilter.video => item.isVideo,
  };
}

class _ContextFilterOption {
  const _ContextFilterOption({required this.storageValue, required this.label});

  final String storageValue;
  final String label;
}

class _AlbumSummary extends StatelessWidget {
  const _AlbumSummary({
    required this.projectCount,
    required this.projectBytes,
    required this.visibleCount,
    required this.visibleBytes,
  });

  final int projectCount;
  final int projectBytes;
  final int visibleCount;
  final int visibleBytes;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: const Key('project-media-summary'),
      child: ListTile(
        leading: const Icon(Icons.storage_outlined),
        title: Text(
          'Proje medyası: $projectCount dosya • ${_formatBytes(projectBytes)}',
        ),
        subtitle: Text(
          'Görünen: $visibleCount dosya • ${_formatBytes(visibleBytes)}\n'
          'Toplam distinct fiziksel medyadır; yedek paket boyutu değildir.',
        ),
        isThreeLine: true,
      ),
    );
  }
}

class _AlbumMessage extends StatelessWidget {
  const _AlbumMessage({required this.icon, required this.message, super.key});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

String? _stableLocationFilterKey(AttachmentCatalogLink link) =>
    link.stableLocationId == null ? null : 'location:${link.stableLocationId}';

String? _linkContextFilterKey(AttachmentCatalogLink link) =>
    link.contextType == null || link.contextId == null
    ? null
    : 'context:${link.contextType}:${link.contextId}';

DateTime? _istanbulTime(String value) {
  try {
    return CseTimeCodec.toIstanbul(value);
  } on Object {
    return null;
  }
}

String _formatIstanbul(String value) {
  try {
    return CseTimeCodec.formatIstanbul(value);
  } on Object {
    return 'Zaman okunamadı';
  }
}

int _totalBytes(Iterable<ProjectAttachmentCatalogItem> items) =>
    items.fold(0, (total, item) => total + item.byteSize);

String _formatBytes(int value) {
  if (value < 1024) return '$value byte';
  if (value < 1024 * 1024) return '${(value / 1024).toStringAsFixed(1)} KiB';
  return '${(value / (1024 * 1024)).toStringAsFixed(1)} MiB';
}

String _mediaLabel(ProjectAttachmentCatalogItem item) =>
    item.isVideo ? 'Video' : 'Fotoğraf';

String _integrityLabel(ManagedAttachmentIntegrity value) => switch (value) {
  ManagedAttachmentIntegrity.healthy => 'Sağlıklı',
  ManagedAttachmentIntegrity.missingFile => 'Dosya eksik • açılamaz',
  ManagedAttachmentIntegrity.sizeMismatch => 'Boyut uyuşmuyor • açılamaz',
  ManagedAttachmentIntegrity.hashMismatch => 'Hash uyuşmuyor • açılamaz',
  ManagedAttachmentIntegrity.mimeMismatch => 'Dosya türü uyuşmuyor • açılamaz',
  ManagedAttachmentIntegrity.unsafePath => 'Güvensiz yol • açılamaz',
};

String _roleLabel(String value) => switch (value) {
  'site_photo' => 'Saha fotoğrafı',
  'delivery_receipt_scan' => 'Teslim belgesi',
  'delivery_note_scan' => 'İrsaliye taraması',
  'mixer_photo' => 'Mikser fotoğrafı',
  'sample_photo' => 'Numune fotoğrafı',
  'laboratory_delivery_document' => 'Laboratuvar teslim belgesi',
  'result_document' => 'Sonuç belgesi',
  'other' => 'Diğer',
  _ => value,
};
