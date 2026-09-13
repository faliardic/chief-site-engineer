import 'dart:async';

import 'package:chief_site_engineer/application/agenda_application.dart';
import 'package:chief_site_engineer/application/project_information_application.dart';
import 'package:chief_site_engineer/core/record_id.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/domain/attendance_models.dart';
import 'package:chief_site_engineer/domain/inventory_models.dart';
import 'package:chief_site_engineer/domain/project_information_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

typedef ProjectInformationTextAction = Future<void> Function(String text);

class ProjectInformationPage extends StatefulWidget {
  const ProjectInformationPage({
    required this.application,
    required this.projectId,
    this.profileApplication,
    this.copyText,
    this.shareText,
    super.key,
  });

  final ProjectInformationApplication application;
  final String projectId;
  final ProjectProfileApplication? profileApplication;
  final ProjectInformationTextAction? copyText;
  final ProjectInformationTextAction? shareText;

  @override
  State<ProjectInformationPage> createState() => _ProjectInformationPageState();
}

enum _InformationLoadStatus { loading, ready, failed }

class _ProjectInformationPageState extends State<ProjectInformationPage> {
  late ProjectInformationSession _session;
  _InformationLoadStatus _status = _InformationLoadStatus.loading;
  ProjectInformationSnapshot? _snapshot;
  ProjectInformationSourceStatus? _failure;
  final Set<String> _restoringFieldIds = <String>{};
  String _query = '';

  @override
  void initState() {
    super.initState();
    _session = widget.application.createSession();
    unawaited(_load());
  }

  @override
  void didUpdateWidget(ProjectInformationPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.application, widget.application)) {
      _session.clearProject();
      _session = widget.application.createSession();
    }
    if (!identical(oldWidget.application, widget.application) ||
        oldWidget.projectId != widget.projectId) {
      _clearVisibleSnapshot();
      unawaited(_load());
    }
  }

  @override
  void dispose() {
    _session.clearProject();
    super.dispose();
  }

  void _clearVisibleSnapshot() {
    _session.clearProject();
    _snapshot = null;
    _failure = null;
    _status = _InformationLoadStatus.loading;
    _query = '';
  }

  Future<void> _load() async {
    final projectId = widget.projectId;
    if (mounted) {
      setState(() {
        _snapshot = null;
        _failure = null;
        _status = _InformationLoadStatus.loading;
      });
    }
    final result = await _session.loadProject(projectId);
    if (!mounted || widget.projectId != projectId) return;
    switch (result) {
      case ProjectInformationReady():
        if (result.snapshot.projectId != projectId) return;
        setState(() {
          _snapshot = result.snapshot;
          _failure = null;
          _status = _InformationLoadStatus.ready;
        });
      case ProjectInformationLoadFailure():
        setState(() {
          _snapshot = null;
          _failure = result.failure;
          _status = _InformationLoadStatus.failed;
        });
      case ProjectInformationSuperseded():
        break;
    }
  }

  Future<void> _copyEntry(_InformationEntry entry) async {
    try {
      await (widget.copyText ?? _copyText)(entry.value);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${entry.label} panoya kopyalandı.')),
      );
    } on Object {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bilgi panoya kopyalanamadı.')),
      );
    }
  }

  Future<void> _shareEntry(_InformationEntry entry) async {
    try {
      await (widget.shareText ?? _shareText)(entry.shareValue);
    } on Object {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Bilgi paylaşılamadı.')));
    }
  }

  Future<void> _restoreField(ProjectProfileField field) async {
    final application = widget.profileApplication;
    final snapshot = _snapshot;
    if (application == null ||
        snapshot == null ||
        !field.isArchived ||
        _restoringFieldIds.contains(field.id)) {
      return;
    }
    setState(() => _restoringFieldIds.add(field.id));
    try {
      await application.mutateProjectProfileFieldArchive(
        MutateProjectProfileFieldArchiveCommand(
          fieldId: field.id,
          eventId: RecordId.randomUuid(),
          projectId: snapshot.projectId,
          expectedRevision: field.revision,
          archive: false,
        ),
      );
      if (!mounted || widget.projectId != snapshot.projectId) return;
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${field.label} geri yüklendi.')));
    } on Object {
      if (!mounted || widget.projectId != snapshot.projectId) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Arşivlenmiş alan geri yüklenemedi. Kayıt korundu.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _restoringFieldIds.remove(field.id));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Tüm proje bilgileri')),
    body: SafeArea(child: _buildBody()),
  );

  Widget _buildBody() => switch (_status) {
    _InformationLoadStatus.loading => const Center(
      key: Key('project-information-loading'),
      child: CircularProgressIndicator(),
    ),
    _InformationLoadStatus.failed => _InformationState(
      key: const Key('project-information-error'),
      icon: Icons.warning_amber_rounded,
      title: 'Proje bilgileri güvenli biçimde okunamadı.',
      body: _failureMessage(_failure),
      actionLabel: 'Tekrar dene',
      onAction: _load,
    ),
    _InformationLoadStatus.ready => _buildSnapshot(_snapshot!),
  };

  Widget _buildSnapshot(ProjectInformationSnapshot snapshot) {
    final sections = _sections(snapshot);
    final query = _searchKey(_query);
    final results = query.isEmpty
        ? const <_InformationEntry>[]
        : _searchEntries(snapshot)
              .where((entry) => entry.searchKey.contains(query))
              .take(40)
              .toList(growable: false);
    final failedSources = snapshot.sourceStatuses
        .where((status) => status.state == ProjectInformationReadState.failed)
        .toList(growable: false);
    final archivedFields = snapshot.profileFields
        .where((field) => !field.isBuiltIn && field.isArchived)
        .toList(growable: false);

    return ListView(
      key: ValueKey('project-information-${snapshot.projectId}'),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      children: [
        Text(
          snapshot.project.name,
          key: const Key('project-information-project-name'),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('project-information-search'),
          maxLength: 120,
          decoration: const InputDecoration(
            labelText: 'Proje bilgilerinde ara',
            hintText: 'Alan, değer, blok, kat veya Mahal',
            prefixIcon: Icon(Icons.search_rounded),
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => setState(() => _query = value),
        ),
        if (failedSources.isNotEmpty) ...[
          const SizedBox(height: 4),
          _PartialFailureNotice(failedSources: failedSources),
        ],
        const SizedBox(height: 8),
        if (query.isNotEmpty)
          _buildSearchResults(results)
        else ...[
          for (final section in sections) _buildSection(snapshot, section),
          _buildBlockHierarchy(snapshot),
          _buildArchivedFields(archivedFields),
        ],
      ],
    );
  }

  Widget _buildSearchResults(List<_InformationEntry> results) {
    if (results.isEmpty) {
      return const _InformationState(
        key: Key('project-information-search-empty'),
        icon: Icons.search_off_rounded,
        title: 'Eşleşen proje bilgisi bulunamadı.',
        body:
            'Arama yalnız seçili projenin mevcut bilgi snapshot’ında çalışır.',
      );
    }
    return Card(
      key: const Key('project-information-search-results'),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.manage_search_rounded),
            title: const Text('Arama sonuçları'),
            subtitle: Text(
              results.length == 40
                  ? 'İlk 40 eşleşme gösteriliyor.'
                  : '${results.length} eşleşme',
            ),
          ),
          for (final entry in results) _entryTile(entry),
        ],
      ),
    );
  }

  Widget _buildSection(
    ProjectInformationSnapshot snapshot,
    _InformationSection section,
  ) {
    final status = section.source == null
        ? null
        : snapshot.statusFor(section.source!);
    return Card(
      key: ValueKey('project-information-section-${section.key}'),
      child: ExpansionTile(
        initiallyExpanded: section.initiallyExpanded,
        leading: Icon(section.icon),
        title: Text(section.title),
        subtitle: status?.state == ProjectInformationReadState.failed
            ? const Text('Bu kaynaktaki bilgiler okunamadı.')
            : section.entries.isEmpty
            ? Text(section.emptyMessage)
            : null,
        children: section.entries.isEmpty
            ? [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      status?.state == ProjectInformationReadState.failed
                          ? 'Kayıtlar değiştirilmedi. Daha sonra tekrar deneyin.'
                          : section.emptyMessage,
                    ),
                  ),
                ),
              ]
            : [for (final entry in section.entries) _entryTile(entry)],
      ),
    );
  }

  Widget _entryTile(_InformationEntry entry) => ListTile(
    key: ValueKey('project-information-entry-${entry.key}'),
    title: Text(entry.label),
    subtitle: Text(entry.value),
    trailing: entry.actionable
        ? Wrap(
            spacing: 0,
            children: [
              IconButton(
                key: ValueKey('project-information-copy-${entry.key}'),
                tooltip: '${entry.label} kopyala',
                onPressed: () => unawaited(_copyEntry(entry)),
                icon: const Icon(Icons.copy_rounded),
              ),
              IconButton(
                key: ValueKey('project-information-share-${entry.key}'),
                tooltip: '${entry.label} paylaş',
                onPressed: () => unawaited(_shareEntry(entry)),
                icon: const Icon(Icons.share_outlined),
              ),
            ],
          )
        : null,
  );

  Widget _buildBlockHierarchy(ProjectInformationSnapshot snapshot) {
    final inventoryStatus = snapshot.statusFor(
      ProjectInformationSource.inventory,
    );
    final floorLocationsFailed =
        snapshot.statusFor(ProjectInformationSource.floorLocations).state ==
        ProjectInformationReadState.failed;
    final hasUnresolved =
        snapshot.unresolvedFloors.isNotEmpty ||
        snapshot.unresolvedFloorLocations.isNotEmpty;
    return Card(
      key: const Key('project-information-section-blocks'),
      child: ExpansionTile(
        leading: const Icon(Icons.account_tree_outlined),
        title: const Text('Bloklar, katlar ve Mahaller'),
        subtitle: inventoryStatus.state == ProjectInformationReadState.failed
            ? const Text('Proje yapısı okunamadı.')
            : snapshot.blocks.isEmpty && !hasUnresolved
            ? const Text('Henüz blok ve kat bilgisi bulunmuyor.')
            : Text(
                '${snapshot.blocks.length} blok'
                '${hasUnresolved ? ' · çözümlenemeyen kayıt var' : ''}',
              ),
        children: inventoryStatus.state == ProjectInformationReadState.failed
            ? const [
                Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Blok, kat ve Mahal kayıtları değiştirilmedi. Daha sonra tekrar deneyin.',
                    ),
                  ),
                ),
              ]
            : [
                if (snapshot.blocks.isEmpty && !hasUnresolved)
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Henüz blok ve kat bilgisi bulunmuyor.'),
                    ),
                  ),
                for (final block in snapshot.blocks)
                  _BlockTile(
                    block: block,
                    floorLocationsFailed: floorLocationsFailed,
                  ),
                if (hasUnresolved) ..._unresolvedHierarchyTiles(snapshot),
              ],
      ),
    );
  }

  Widget _buildArchivedFields(List<ProjectProfileField> fields) {
    if (fields.isEmpty) return const SizedBox.shrink();
    return Card(
      key: const Key('project-information-archived-fields'),
      child: ExpansionTile(
        leading: const Icon(Icons.archive_outlined),
        title: const Text('Arşivlenmiş özel alanlar'),
        subtitle: Text('${fields.length} alan · kayıtlar korunuyor'),
        children: [
          for (final field in fields)
            ListTile(
              key: ValueKey('project-information-archived-${field.id}'),
              title: Text(field.label),
              subtitle: Text(
                field.value.isEmpty ? 'Değer girilmemiş' : field.value,
              ),
              trailing: TextButton.icon(
                key: ValueKey('project-information-restore-${field.id}'),
                onPressed:
                    widget.profileApplication == null ||
                        _restoringFieldIds.contains(field.id)
                    ? null
                    : () => unawaited(_restoreField(field)),
                icon: _restoringFieldIds.contains(field.id)
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.unarchive_outlined),
                label: const Text('Geri yükle'),
              ),
            ),
        ],
      ),
    );
  }
}

class _BlockTile extends StatelessWidget {
  const _BlockTile({required this.block, required this.floorLocationsFailed});

  final ProjectInformationBlock block;
  final bool floorLocationsFailed;

  @override
  Widget build(BuildContext context) => ExpansionTile(
    key: ValueKey('project-information-block-${block.block.id}'),
    leading: const Icon(Icons.domain_outlined),
    title: Text(block.block.displayName),
    subtitle: Text(_blockStateLabel(block.block.state)),
    childrenPadding: const EdgeInsets.only(left: 12),
    children: [
      if (block.metadata.state == ProjectInformationBlockMetadataState.failed)
        const ListTile(
          leading: Icon(Icons.warning_amber_rounded),
          title: Text('Blok ayrıntıları okunamadı.'),
          subtitle: Text('Kayıtlar değiştirilmedi.'),
        )
      else if (block.metadata.state ==
          ProjectInformationBlockMetadataState.empty)
        const ListTile(title: Text('Blok ayrıntısı henüz girilmedi.'))
      else
        ..._blockMetadataTiles(block.metadata.value!),
      if (block.floors.isEmpty)
        const ListTile(title: Text('Bu blokta kat kaydı bulunmuyor.'))
      else
        for (final floor in block.floors)
          ExpansionTile(
            key: ValueKey('project-information-floor-${floor.floor.id}'),
            leading: const Icon(Icons.layers_outlined),
            title: Text(floor.floor.displayName),
            subtitle: floor.floor.archivedAt == null
                ? Text(
                    floorLocationsFailed
                        ? 'Mahal bağlantıları okunamadı'
                        : '${floor.locations.length} Mahal bağlantısı',
                  )
                : const Text('Kat arşivlenmiş'),
            children: floor.locations.isEmpty
                ? [
                    ListTile(
                      title: Text(
                        floorLocationsFailed
                            ? 'Mahal bağlantıları okunamadı. Kayıtlar korundu.'
                            : 'Mahal bağlantısı bulunmuyor.',
                      ),
                    ),
                  ]
                : [
                    for (final item in floor.locations)
                      ListTile(
                        key: ValueKey(
                          'project-information-location-${item.relation.id}',
                        ),
                        leading: const Icon(Icons.place_outlined),
                        title: Text(
                          item.location?.displayName ?? 'Mahal bulunamadı',
                        ),
                        subtitle: Text(_floorLocationStateLabel(item.state)),
                      ),
                  ],
          ),
    ],
  );
}

class _PartialFailureNotice extends StatelessWidget {
  const _PartialFailureNotice({required this.failedSources});

  final List<ProjectInformationSourceStatus> failedSources;

  @override
  Widget build(BuildContext context) => Card(
    key: const Key('project-information-partial-error'),
    color: Theme.of(context).colorScheme.errorContainer,
    child: ListTile(
      leading: Icon(
        Icons.warning_amber_rounded,
        color: Theme.of(context).colorScheme.onErrorContainer,
      ),
      title: const Text('Bazı proje bilgileri okunamadı.'),
      subtitle: Text(
        '${failedSources.map((status) => _sourceLabel(status.source)).join(', ')}. '
        'Görünen kayıtlar salt okunur snapshot’tır; hiçbir kayıt değiştirilmedi.',
      ),
    ),
  );
}

class _InformationState extends StatelessWidget {
  const _InformationState({
    required this.icon,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final IconData icon;
  final String title;
  final String body;
  final String? actionLabel;
  final FutureOr<void> Function()? onAction;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(body, textAlign: TextAlign.center),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => Future<void>.sync(onAction!),
              icon: const Icon(Icons.refresh_rounded),
              label: Text(actionLabel!),
            ),
          ],
        ],
      ),
    ),
  );
}

class _InformationSection {
  const _InformationSection({
    required this.key,
    required this.title,
    required this.icon,
    required this.emptyMessage,
    required this.entries,
    this.source,
    this.initiallyExpanded = false,
  });

  final String key;
  final String title;
  final IconData icon;
  final String emptyMessage;
  final List<_InformationEntry> entries;
  final ProjectInformationSource? source;
  final bool initiallyExpanded;
}

class _InformationEntry {
  const _InformationEntry({
    required this.key,
    required this.category,
    required this.label,
    required this.value,
    this.actionable = true,
  });

  final String key;
  final String category;
  final String label;
  final String value;
  final bool actionable;

  String get shareValue => '$label: $value';

  String get searchKey => _searchKey('$category $label $value');
}

List<_InformationSection> _sections(ProjectInformationSnapshot snapshot) {
  final metadata = snapshot.metadata;
  final activeFields = snapshot.profileFields
      .where((field) => !field.isArchived)
      .toList(growable: false);
  ProjectProfileField? builtin(ProjectProfileBuiltinField kind) {
    for (final field in activeFields) {
      if (field.builtinField == kind && field.value.trim().isNotEmpty) {
        return field;
      }
    }
    return null;
  }

  final projectEntries = <_InformationEntry>[
    _InformationEntry(
      key: 'project-name',
      category: 'Proje Bilgileri',
      label: 'Proje adı',
      value: snapshot.project.name,
    ),
    if (_value(metadata?.projectStartDate) case final value?)
      _InformationEntry(
        key: 'project-start-date',
        category: 'Proje Bilgileri',
        label: 'Başlangıç tarihi',
        value: value,
      ),
    if (_value(metadata?.targetFinishDate) case final value?)
      _InformationEntry(
        key: 'target-finish-date',
        category: 'Proje Bilgileri',
        label: 'Hedef bitiş',
        value: value,
      ),
  ];
  final addressEntries = <_InformationEntry>[
    if (_value(metadata?.address) case final value?)
      _InformationEntry(
        key: 'address',
        category: 'Konum ve Adres',
        label: 'Adres',
        value: value,
      ),
  ];
  final officialEntries = <_InformationEntry>[
    if (builtin(ProjectProfileBuiltinField.yibfNumber) case final field?)
      _fieldEntry('official-yibf', 'Resmî Bilgiler', field),
    if (_value(metadata?.permitNumber) case final value?)
      _InformationEntry(
        key: 'permit-number',
        category: 'Resmî Bilgiler',
        label: 'Ruhsat no',
        value: value,
      ),
    if (_value(metadata?.permitDate) case final value?)
      _InformationEntry(
        key: 'permit-date',
        category: 'Resmî Bilgiler',
        label: 'Ruhsat tarihi',
        value: value,
      ),
    if (_value(metadata?.cadastralBlock) case final value?)
      _InformationEntry(
        key: 'cadastral-block',
        category: 'Resmî Bilgiler',
        label: 'Ada',
        value: value,
      ),
    if (_value(metadata?.cadastralParcel) case final value?)
      _InformationEntry(
        key: 'cadastral-parcel',
        category: 'Resmî Bilgiler',
        label: 'Parsel',
        value: value,
      ),
  ];
  final technicalEntries = <_InformationEntry>[
    if (builtin(ProjectProfileBuiltinField.totalArea) case final field?)
      _fieldEntry('technical-total-area', 'Teknik Bilgiler', field),
    if (builtin(ProjectProfileBuiltinField.totalFloors) case final field?)
      _fieldEntry('technical-total-floors', 'Teknik Bilgiler', field),
    if (_value(metadata?.usageType) case final value?)
      _InformationEntry(
        key: 'usage-type',
        category: 'Teknik Bilgiler',
        label: 'Kullanım türü',
        value: value,
      ),
    if (_value(metadata?.structuralSystem) case final value?)
      _InformationEntry(
        key: 'structural-system',
        category: 'Teknik Bilgiler',
        label: 'Taşıyıcı sistem',
        value: value,
      ),
    _InformationEntry(
      key: 'derived-active-blocks',
      category: 'Teknik Bilgiler',
      label: 'Aktif blok sayısı',
      value:
          snapshot.statusFor(ProjectInformationSource.inventory).state ==
              ProjectInformationReadState.failed
          ? 'Okunamadı; kayıtlar korundu'
          : '${snapshot.derivedInventoryTotals.activeBlockCount} (türetilmiş)',
      actionable:
          snapshot.statusFor(ProjectInformationSource.inventory).state !=
          ProjectInformationReadState.failed,
    ),
    _InformationEntry(
      key: 'derived-active-floors',
      category: 'Teknik Bilgiler',
      label: 'Aktif kat sayısı',
      value:
          snapshot.statusFor(ProjectInformationSource.inventory).state ==
              ProjectInformationReadState.failed
          ? 'Okunamadı; kayıtlar korundu'
          : '${snapshot.derivedInventoryTotals.activeFloorCount} (türetilmiş)',
      actionable:
          snapshot.statusFor(ProjectInformationSource.inventory).state !=
          ProjectInformationReadState.failed,
    ),
  ];
  final partyEntries = [
    for (final role in ProjectPartyRole.values) _partyEntry(snapshot, role),
  ];
  final customEntries = activeFields
      .where((field) => !field.isBuiltIn)
      .map((field) => _fieldEntry('custom-${field.id}', 'Özel Alanlar', field))
      .toList(growable: false);

  return [
    _InformationSection(
      key: 'project',
      title: 'Proje Bilgileri',
      icon: Icons.apartment_rounded,
      emptyMessage: 'Henüz proje bilgisi bulunmuyor.',
      entries: projectEntries,
      initiallyExpanded: true,
    ),
    _InformationSection(
      key: 'address',
      title: 'Konum ve Adres',
      icon: Icons.location_on_outlined,
      emptyMessage: 'Adres henüz girilmedi.',
      entries: addressEntries,
      source: ProjectInformationSource.metadata,
    ),
    _InformationSection(
      key: 'parties',
      title: 'Önemli Kişiler',
      icon: Icons.groups_outlined,
      emptyMessage: 'Henüz taraf ataması bulunmuyor.',
      entries: partyEntries,
      source: ProjectInformationSource.parties,
    ),
    _InformationSection(
      key: 'official',
      title: 'Resmî Bilgiler',
      icon: Icons.assignment_outlined,
      emptyMessage: 'Resmî bilgiler henüz girilmedi.',
      entries: officialEntries,
    ),
    _InformationSection(
      key: 'technical',
      title: 'Teknik Bilgiler',
      icon: Icons.engineering_outlined,
      emptyMessage: 'Teknik bilgiler henüz girilmedi.',
      entries: technicalEntries,
    ),
    const _InformationSection(
      key: 'site',
      title: 'Saha Bilgileri',
      icon: Icons.home_work_outlined,
      emptyMessage: 'Bu dilimde ayrı bir saha bilgisi kaynağı bulunmuyor.',
      entries: [],
    ),
    _InformationSection(
      key: 'custom',
      title: 'Özel Alanlar',
      icon: Icons.tune_rounded,
      emptyMessage: 'Aktif özel alan bulunmuyor.',
      entries: customEntries,
      source: ProjectInformationSource.profile,
    ),
  ];
}

List<_InformationEntry> _searchEntries(ProjectInformationSnapshot snapshot) {
  final entries = [
    for (final section in _sections(snapshot)) ...section.entries,
  ];
  for (final block in snapshot.blocks) {
    entries.add(
      _InformationEntry(
        key: 'search-block-${block.block.id}',
        category: 'Bloklar',
        label: 'Blok',
        value:
            '${block.block.displayName} · ${_blockStateLabel(block.block.state)}',
        actionable: false,
      ),
    );
    final metadata = block.metadata.value;
    if (metadata != null) {
      for (final entry in _blockMetadataEntries(metadata)) {
        entries.add(
          _InformationEntry(
            key: 'search-block-metadata-${block.block.id}-${entry.$1}',
            category: block.block.displayName,
            label: entry.$1,
            value: entry.$2,
            actionable: false,
          ),
        );
      }
    }
    for (final floor in block.floors) {
      entries.add(
        _InformationEntry(
          key: 'search-floor-${floor.floor.id}',
          category: block.block.displayName,
          label: 'Kat',
          value: floor.floor.displayName,
          actionable: false,
        ),
      );
      for (final location in floor.locations) {
        entries.add(
          _InformationEntry(
            key: 'search-location-${location.relation.id}',
            category: '${block.block.displayName} ${floor.floor.displayName}',
            label: 'Mahal',
            value:
                '${location.location?.displayName ?? 'Bulunamadı'} · '
                '${_floorLocationStateLabel(location.state)}',
            actionable: false,
          ),
        );
      }
    }
  }
  return entries;
}

_InformationEntry _partyEntry(
  ProjectInformationSnapshot snapshot,
  ProjectPartyRole role,
) {
  final label = _partyRoleLabel(role);
  if (snapshot.statusFor(ProjectInformationSource.parties).state ==
      ProjectInformationReadState.failed) {
    return _InformationEntry(
      key: 'party-${role.storageValue}',
      category: 'Önemli Kişiler',
      label: label,
      value: 'Atama durumu okunamadı; kayıtlar korundu',
      actionable: false,
    );
  }
  ProjectInformationParty? party;
  for (final candidate in snapshot.parties) {
    if (candidate.assignment.role == role && !candidate.assignment.isArchived) {
      party = candidate;
      break;
    }
  }
  party ??= snapshot.parties.cast<ProjectInformationParty?>().firstWhere(
    (candidate) => candidate?.assignment.role == role,
    orElse: () => null,
  );
  if (party == null) {
    return _InformationEntry(
      key: 'party-${role.storageValue}',
      category: 'Önemli Kişiler',
      label: label,
      value: 'Atanmamış',
      actionable: false,
    );
  }
  final archivedAssignment = party.assignment.isArchived;
  final value = switch (party.targetState) {
    ProjectInformationPartyTargetState.resolvedActive =>
      party.company == null
          ? _memberValue(party.workforceMember!)
          : _companyValue(party.company!),
    ProjectInformationPartyTargetState.resolvedArchived =>
      '${party.company == null ? _memberValue(party.workforceMember!) : _companyValue(party.company!)} · kayıt arşivli',
    ProjectInformationPartyTargetState.missing => 'Bağlı kayıt bulunamadı',
    ProjectInformationPartyTargetState.sourceUnavailable =>
      'Bağlı kayıt kaynağı okunamadı',
    ProjectInformationPartyTargetState.invalidAssignment =>
      'Atama güvenli biçimde çözümlenemedi',
  };
  return _InformationEntry(
    key: 'party-${role.storageValue}',
    category: 'Önemli Kişiler',
    label: label,
    value: archivedAssignment ? '$value · atama arşivli' : value,
    actionable:
        !archivedAssignment &&
        party.targetState == ProjectInformationPartyTargetState.resolvedActive,
  );
}

List<Widget> _unresolvedHierarchyTiles(ProjectInformationSnapshot snapshot) => [
  const Divider(),
  const ListTile(
    leading: Icon(Icons.warning_amber_rounded),
    title: Text('Çözümlenemeyen yapı kayıtları'),
    subtitle: Text('Kayıtlar silinmedi; bağlı kaynak bulunamadı.'),
  ),
  for (final floor in snapshot.unresolvedFloors)
    ListTile(
      key: ValueKey('project-information-unresolved-floor-${floor.id}'),
      title: Text(floor.displayName),
      subtitle: Text(
        floor.archivedAt == null
            ? 'Bağlı blok bulunamadı'
            : 'Bağlı blok bulunamadı · kat arşivlenmiş',
      ),
    ),
  for (final item in snapshot.unresolvedFloorLocations)
    ListTile(
      key: ValueKey(
        'project-information-unresolved-location-${item.relation.id}',
      ),
      title: Text(item.location?.displayName ?? 'Mahal bağlantısı'),
      subtitle: Text(_unresolvedFloorLocationLabel(item.reason)),
    ),
];

_InformationEntry _fieldEntry(
  String key,
  String category,
  ProjectProfileField field,
) => _InformationEntry(
  key: key,
  category: category,
  label: field.label,
  value: field.value.trim(),
);

List<Widget> _blockMetadataTiles(InventoryBlockMetadataRecord metadata) {
  final entries = _blockMetadataEntries(metadata);
  if (entries.isEmpty) {
    return const [ListTile(title: Text('Blok ayrıntısı henüz girilmedi.'))];
  }
  return [
    for (final entry in entries)
      ListTile(dense: true, title: Text(entry.$1), subtitle: Text(entry.$2)),
  ];
}

List<(String, String)> _blockMetadataEntries(
  InventoryBlockMetadataRecord metadata,
) {
  final entries = <(String, String)>[
    if (metadata.basementCount != null)
      ('Bodrum kat', '${metadata.basementCount}'),
    if (_value(metadata.basementClassification) case final value?)
      ('Bodrum sınıfı', value),
    if (metadata.totalArea != null)
      (
        'Toplam alan',
        '${_formatNumber(metadata.totalArea!)} ${metadata.totalAreaUnit ?? ''}'
            .trim(),
      ),
    if (metadata.footprintArea != null)
      (
        'Oturum alanı',
        '${_formatNumber(metadata.footprintArea!)} ${metadata.footprintAreaUnit ?? ''}'
            .trim(),
      ),
    if (metadata.independentUnitCount != null)
      ('Bağımsız bölüm', '${metadata.independentUnitCount}'),
    if (_value(metadata.usageType) case final value?) ('Kullanım türü', value),
  ];
  return entries;
}

String _companyValue(Subcontractor company) {
  final parts = <String>[company.name];
  if (_value(company.contactName) case final value?) parts.add(value);
  if (_value(company.phone) case final value?) parts.add(value);
  return parts.join(' · ');
}

String _memberValue(WorkforceMember member) {
  final parts = <String>[member.fullName];
  if (_value(member.roleName) case final value?) parts.add(value);
  if (_value(member.phone) case final value?) parts.add(value);
  return parts.join(' · ');
}

String? _value(String? value) {
  final normalized = value?.trim();
  return normalized == null || normalized.isEmpty ? null : normalized;
}

String _formatNumber(double value) => value == value.roundToDouble()
    ? value.toStringAsFixed(0)
    : value.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '');

String _searchKey(String value) => value
    .replaceAll('İ', 'i')
    .replaceAll('I', 'i')
    .toLowerCase()
    .replaceAll('ı', 'i')
    .replaceAll('ş', 's')
    .replaceAll('ğ', 'g')
    .replaceAll('ü', 'u')
    .replaceAll('ö', 'o')
    .replaceAll('ç', 'c')
    .trim();

String _failureMessage(ProjectInformationSourceStatus? failure) {
  if (failure?.errorCode == 'project_information_project_archived') {
    return 'Bu proje arşivlenmiş. Başka bir aktif proje seçin.';
  }
  if (failure?.errorCode == 'project_information_project_changed_during_read') {
    return 'Proje okuma sırasında değişti. Güncel bilgileri yeniden yükleyin.';
  }
  return 'Kayıtlar değiştirilmedi. Bağlantıyı veya proje seçimini kontrol edip yeniden deneyin.';
}

String _sourceLabel(ProjectInformationSource source) => switch (source) {
  ProjectInformationSource.project => 'Proje',
  ProjectInformationSource.metadata => 'Proje ayrıntıları',
  ProjectInformationSource.profile => 'Profil alanları',
  ProjectInformationSource.parties => 'Önemli kişiler',
  ProjectInformationSource.companies => 'Firmalar',
  ProjectInformationSource.workforceMembers => 'Personel',
  ProjectInformationSource.inventory => 'Blok ve katlar',
  ProjectInformationSource.blockMetadata => 'Blok ayrıntıları',
  ProjectInformationSource.locations => 'Mahaller',
  ProjectInformationSource.floorLocations => 'Kat–Mahal bağlantıları',
};

String _partyRoleLabel(ProjectPartyRole role) => switch (role) {
  ProjectPartyRole.employer => 'İşveren',
  ProjectPartyRole.mainContractor => 'Ana yüklenici',
  ProjectPartyRole.buildingInspection => 'Yapı denetim',
  ProjectPartyRole.siteChief => 'Şantiye şefi',
};

String _blockStateLabel(InventoryBlockState state) => switch (state) {
  InventoryBlockState.active => 'Aktif blok',
  InventoryBlockState.detached => 'Krokiden ayrılmış blok',
  InventoryBlockState.archived => 'Arşivlenmiş blok',
};

String _floorLocationStateLabel(ProjectInformationFloorLocationState state) =>
    switch (state) {
      ProjectInformationFloorLocationState.resolvedActive => 'Aktif Mahal',
      ProjectInformationFloorLocationState.archivedRelation =>
        'Kat bağlantısı arşivlenmiş',
      ProjectInformationFloorLocationState.archivedLocation =>
        'Mahal arşivlenmiş',
      ProjectInformationFloorLocationState.missingLocation =>
        'Mahal kaydı bulunamadı',
      ProjectInformationFloorLocationState.sourceUnavailable =>
        'Mahal kaynağı okunamadı',
    };

String _unresolvedFloorLocationLabel(
  ProjectInformationUnresolvedFloorLocationReason reason,
) => switch (reason) {
  ProjectInformationUnresolvedFloorLocationReason.missingFloor =>
    'Bağlı kat bulunamadı',
  ProjectInformationUnresolvedFloorLocationReason.missingLocation =>
    'Bağlı Mahal bulunamadı',
  ProjectInformationUnresolvedFloorLocationReason.floorSourceUnavailable =>
    'Kat kaynağı okunamadı; kayıt korundu',
  ProjectInformationUnresolvedFloorLocationReason.locationSourceUnavailable =>
    'Mahal kaynağı okunamadı; kayıt korundu',
};

Future<void> _copyText(String text) =>
    Clipboard.setData(ClipboardData(text: text));

Future<void> _shareText(String text) async {
  await SharePlus.instance.share(
    ShareParams(title: 'Proje bilgisi', subject: 'Proje bilgisi', text: text),
  );
}
