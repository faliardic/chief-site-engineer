import 'dart:async';

import 'package:chief_site_engineer/application/agenda_application.dart';
import 'package:chief_site_engineer/application/concrete_application.dart';
import 'package:chief_site_engineer/core/time/cse_time_codec.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/domain/concrete_models.dart';
import 'package:chief_site_engineer/features/concrete/concrete_pour_detail_page.dart';
import 'package:chief_site_engineer/features/concrete/concrete_pour_form_page.dart';
import 'package:chief_site_engineer/platform/attachment_gateway.dart';
import 'package:chief_site_engineer/features/screen_tool_rail.dart';
import 'package:flutter/material.dart';

class ConcretePage extends StatefulWidget {
  const ConcretePage({
    required this.concrete,
    required this.agenda,
    required this.attachments,
    this.projectLocations,
    this.initialProjectId,
    this.initialIstanbulDay,
    this.onProjectSelected,
    super.key,
  });

  final ConcreteApplication concrete;
  final AgendaApplication agenda;
  final SafeAttachmentPicker attachments;
  final ProjectLocationApplication? projectLocations;
  final String? initialProjectId;
  final String? initialIstanbulDay;
  final ValueChanged<String>? onProjectSelected;

  @override
  State<ConcretePage> createState() => ConcretePageState();
}

class ConcretePageState extends State<ConcretePage> {
  final ScrollController _scrollController = ScrollController();
  final _search = TextEditingController();
  final _searchFocus = FocusNode();
  final _searchFieldKey = GlobalKey();
  List<MobileProject> _projects = const [];
  List<ConcretePour> _pours = const [];
  String? _projectIdToValidate;
  MobileProject? _project;
  ConcretePourGroup _group = ConcretePourGroup.today;
  late String _day;
  bool _loading = true;
  bool _projectDiscoveryFailed = false;
  String? _error;
  StreamSubscription<void>? _projectSubscription;
  bool _detailNavigationBusy = false;

  @override
  void initState() {
    super.initState();
    _day = _safeInitialDay(widget.initialIstanbulDay);
    _projectIdToValidate = widget.initialProjectId;
    _projectSubscription = widget.agenda.projectChanges.listen(
      (_) => _loadProjects(),
    );
    _loadProjects();
  }

  @override
  void dispose() {
    _projectSubscription?.cancel();
    _scrollController.dispose();
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _loadProjects() async {
    final projectIdToValidate = _projectIdToValidate;
    setState(() {
      _projects = const [];
      _pours = const [];
      _project = null;
      _loading = true;
      _projectDiscoveryFailed = false;
      _error = null;
    });
    try {
      final projects = (await widget.agenda.listProjects())
          .where((project) => !project.isArchived)
          .toList(growable: false);
      final selected = projects
          .where((project) => project.id == projectIdToValidate)
          .firstOrNull;
      final project =
          selected ??
          (widget.initialProjectId == null ? projects.firstOrNull : null);
      if (!mounted) return;
      setState(() {
        _projects = projects;
        _project = project;
        if (project != null) _projectIdToValidate = project.id;
        _loading = false;
      });
      if (project != null) await _reload();
    } on Object catch (error) {
      if (mounted) {
        setState(() {
          _projects = const [];
          _pours = const [];
          _project = null;
          _loading = false;
          _projectDiscoveryFailed = true;
          _error = _message(error, 'Beton paketleri açılamadı.');
        });
      }
    }
  }

  Future<void> _reload({double? restoreOffset}) async {
    final project = _project;
    if (project == null) {
      if (mounted) {
        setState(() {
          _pours = const [];
          _loading = false;
        });
      }
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final values = await widget.concrete.listPours(
        ConcretePourQuery(
          group: _group,
          projectId: project.id,
          istanbulDay: _day,
          literalSearch: _search.text,
        ),
      );
      if (mounted) setState(() => _pours = values);
    } on Object catch (error) {
      if (mounted) {
        setState(() => _error = _message(error, 'Liste yenilenemedi.'));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
    _restoreScrollOffset(restoreOffset);
  }

  Future<void> selectProject(String projectId) async {
    if (projectId == _project?.id || _loading) return;
    final project = _projects
        .where((candidate) => candidate.id == projectId)
        .firstOrNull;
    if (project == null) return;
    setState(() {
      _projectIdToValidate = project.id;
      _project = project;
    });
    widget.onProjectSelected?.call(project.id);
    await _reload();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.parse(_day),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      _day =
          '${picked.year.toString().padLeft(4, '0')}-'
          '${picked.month.toString().padLeft(2, '0')}-'
          '${picked.day.toString().padLeft(2, '0')}';
    });
    await _reload();
  }

  Future<void> _create() async {
    if (_projects.isEmpty) return;
    final id = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => ConcretePourFormPage(
          concrete: widget.concrete,
          projects: _projects,
          projectLocations: widget.projectLocations,
          initialProject: _project,
        ),
      ),
    );
    if (id != null && mounted) {
      await _open(id);
      await _reload();
    }
  }

  Future<void> _open(String id) async {
    if (_detailNavigationBusy) return;
    final restoreOffset = _currentScrollOffset;
    _detailNavigationBusy = true;
    try {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => ConcretePourDetailPage(
            concrete: widget.concrete,
            agenda: widget.agenda,
            attachments: widget.attachments,
            projectLocations: widget.projectLocations,
            pourId: id,
          ),
        ),
      );
      if (mounted) await _reload(restoreOffset: restoreOffset);
    } finally {
      _detailNavigationBusy = false;
    }
  }

  double? get _currentScrollOffset =>
      _scrollController.hasClients ? _scrollController.offset : null;

  void _restoreScrollOffset(double? requestedOffset) {
    if (requestedOffset == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final position = _scrollController.position;
      final target = requestedOffset
          .clamp(position.minScrollExtent, position.maxScrollExtent)
          .toDouble();
      if ((position.pixels - target).abs() > 0.5) {
        _scrollController.jumpTo(target);
      }
    });
  }

  Future<void> _revealSearch() async {
    if (_scrollController.hasClients) {
      await _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
    if (!mounted) return;
    _searchFocus.requestFocus();
    await WidgetsBinding.instance.endOfFrame;
    final fieldContext = _searchFieldKey.currentContext;
    if (mounted && fieldContext != null && fieldContext.mounted) {
      await Scrollable.ensureVisible(
        fieldContext,
        duration: const Duration(milliseconds: 200),
      );
    }
  }

  Future<void> _showFilters() async {
    var draft = _group;
    final projectId = _project?.id;
    final selected = await showModalBottomSheet<ConcretePourGroup>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: ListView(
            key: const Key('concrete-filter-sheet'),
            shrinkWrap: true,
            padding: const EdgeInsets.all(16),
            children: [
              Text('Filtreler', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              for (final group in ConcretePourGroup.values)
                ListTile(
                  key: Key('concrete-group-${group.name}'),
                  leading: Icon(
                    draft == group
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                  ),
                  title: Text(_groupLabel(group)),
                  selected: draft == group,
                  onTap: () => setSheetState(() => draft = group),
                ),
              TextButton(
                key: const Key('concrete-clear-filters'),
                onPressed: () =>
                    setSheetState(() => draft = ConcretePourGroup.today),
                child: const Text('Tüm filtreleri temizle'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Vazgeç'),
              ),
              FilledButton(
                key: const Key('concrete-apply-filters'),
                onPressed: () => Navigator.pop(context, draft),
                child: const Text('Uygula'),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted ||
        selected == null ||
        selected == _group ||
        projectId != _project?.id) {
      return;
    }
    setState(() => _group = selected);
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadProjects,
                    child: ListView(
                      key: const Key('concrete-page'),
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: OutlinedButton.icon(
                            key: const Key('concrete-day-filter'),
                            onPressed: _pickDate,
                            icon: const Icon(Icons.calendar_today_outlined),
                            label: Text(_day),
                          ),
                        ),
                        const SizedBox(height: 12),
                        KeyedSubtree(
                          key: _searchFieldKey,
                          child: TextField(
                            key: const Key('concrete-search'),
                            focusNode: _searchFocus,
                            controller: _search,
                            textInputAction: TextInputAction.search,
                            decoration: const InputDecoration(
                              labelText: 'Kod, mahal, blok, kat veya aks ara',
                              border: OutlineInputBorder(),
                            ),
                            onSubmitted: (_) => _reload(),
                          ),
                        ),
                        if (_group != ConcretePourGroup.today) ...[
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: InputChip(
                              key: const Key('concrete-group-summary'),
                              tooltip: _groupLabel(_group),
                              label: Text(
                                _groupLabel(_group),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onDeleted: () {
                                setState(
                                  () => _group = ConcretePourGroup.today,
                                );
                                _reload();
                              },
                            ),
                          ),
                        ],
                        if (_error case final error?) ...[
                          const SizedBox(height: 12),
                          Text(
                            error,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                          if (_projectDiscoveryFailed)
                            OutlinedButton.icon(
                              key: const Key('concrete-project-retry'),
                              onPressed: _loadProjects,
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Projeleri yeniden dene'),
                            ),
                        ],
                        if (_loading)
                          const Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        if (!_loading && _projects.isEmpty)
                          const Card(
                            key: Key('concrete-no-projects'),
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Text('Önce aktif bir proje oluşturun.'),
                            ),
                          )
                        else if (!_loading && _project == null)
                          const Card(
                            key: Key('concrete-project-context-unavailable'),
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Text(
                                'Başlangıç projesi artık kullanılamıyor. Aktif projeyi üst çubuktan seçin.',
                              ),
                            ),
                          )
                        else if (!_loading && _pours.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 32),
                            child: Center(
                              child: Text('Bu görünümde Beton paketi yok.'),
                            ),
                          ),
                        for (final pour in _pours)
                          Card(
                            key: Key('concrete-pour-${pour.id}'),
                            child: ListTile(
                              minVerticalPadding: 12,
                              leading: const Icon(Icons.foundation_outlined),
                              title: Text(
                                '${pour.pourCode} • ${pour.elementLocation}',
                              ),
                              subtitle: Text(
                                '${CseTimeCodec.formatIstanbul(pour.plannedAt)}\n'
                                '${pour.stableLocationName == null ? '' : '${pour.stableLocationName}${pour.stableLocationArchivedAt == null ? '' : ' (Arşivli)'} • '}'
                                '${pour.concreteClass} • ${pour.plannedVolumeM3.toStringAsFixed(2)} m³ • ${pour.status.label}\n'
                                '${pour.pendingCheckCount} checklist • '
                                '${pour.missingEvidenceTruckCount} kanıt • '
                                '${pour.openFollowUpCount} takip açık',
                              ),
                              isThreeLine: true,
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => _open(pour.id),
                            ),
                          ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                ScreenToolRail(
                  actions: [
                    ScreenToolAction(
                      key: const Key('concrete-tool-search'),
                      label: 'Ara',
                      icon: Icons.search,
                      onPressed: _revealSearch,
                    ),
                    ScreenToolAction(
                      key: const Key('concrete-tool-filters'),
                      label: 'Filtreler',
                      icon: Icons.filter_list,
                      onPressed: _showFilters,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const Key('create-concrete-pour'),
                style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
                onPressed: _project == null ? null : _create,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text('Yeni döküm', textAlign: TextAlign.center),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _message(Object error, String fallback) =>
    error is AgendaValidationFailure ? error.message : fallback;

String _safeInitialDay(String? value) {
  if (value != null &&
      RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value) &&
      DateTime.tryParse(value) != null) {
    return value;
  }
  return CseTimeCodec.istanbulDayKey(
    CseTimeCodec.encodeUtc(DateTime.now().toUtc()),
  );
}

String _groupLabel(ConcretePourGroup group) => switch (group) {
  ConcretePourGroup.today => 'Bugün',
  ConcretePourGroup.upcoming => 'Yaklaşan',
  ConcretePourGroup.inProgress => 'Dökümde',
  ConcretePourGroup.followUp => 'Takipte',
  ConcretePourGroup.closed => 'Kapalı',
};
