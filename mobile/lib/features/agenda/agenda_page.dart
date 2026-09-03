import 'dart:async';

import 'package:chief_site_engineer/application/agenda_application.dart';
import 'package:chief_site_engineer/application/concrete_application.dart';
import 'package:chief_site_engineer/core/record_id.dart';
import 'package:chief_site_engineer/core/time/cse_time_codec.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/features/agenda/log_detail_page.dart';
import 'package:chief_site_engineer/features/agenda/log_form_page.dart';
import 'package:chief_site_engineer/features/agenda/project_location_catalog_page.dart';
import 'package:chief_site_engineer/features/owned_text_input_dialog.dart';
import 'package:chief_site_engineer/features/reminders/reminder_detail_page.dart';
import 'package:chief_site_engineer/platform/attachment_gateway.dart';
import 'package:flutter/material.dart';

class AgendaPage extends StatefulWidget {
  const AgendaPage({
    required this.agenda,
    this.projectLocations,
    this.attachments,
    this.concrete,
    this.concreteAttachments,
    this.activeProjectId,
    super.key,
  });

  final AgendaApplication agenda;
  final ProjectLocationApplication? projectLocations;
  final SafeAttachmentPicker? attachments;
  final ConcreteApplication? concrete;
  final SafeAttachmentPicker? concreteAttachments;
  final String? activeProjectId;

  @override
  State<AgendaPage> createState() => _AgendaPageState();
}

class _AgendaPageState extends State<AgendaPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  late String _selectedDay;
  List<MobileProject> _projects = const [];
  List<AgendaLog> _logs = const [];
  Map<String, MobileReminder> _linkedReminders = const {};
  String? _projectId;
  AgendaCategory? _category;
  String _search = '';
  AgendaArchiveFilter _archiveFilter = AgendaArchiveFilter.active;
  AgendaSortOrder _sortOrder = AgendaSortOrder.newestFirst;
  bool _loading = true;
  String? _error;
  StreamSubscription<void>? _projectSubscription;
  bool _detailNavigationBusy = false;
  bool _preservingDetailReload = false;
  int _reloadGeneration = 0;
  String? _preferredProjectId;

  @override
  void initState() {
    super.initState();
    _selectedDay = CseTimeCodec.istanbulDayKey(
      CseTimeCodec.encodeUtc(DateTime.now().toUtc()),
    );
    _projectSubscription = widget.agenda.projectChanges.listen(
      (_) => _reload(),
    );
    _reload();
  }

  @override
  void dispose() {
    _projectSubscription?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _createProject() async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) => const OwnedTextInputDialog(
        title: 'Yeni proje',
        label: 'Proje adı',
        confirmLabel: 'Oluştur',
        inputKey: Key('agenda-project-name'),
        confirmKey: Key('save-agenda-project'),
      ),
    );
    if (name == null) return;
    try {
      final project = await widget.agenda.createProject(
        CreateProjectCommand(id: RecordId.randomUuid(), name: name),
      );
      if (!mounted) return;
      await _reload(preferredProjectId: project.id);
    } on Object catch (error) {
      if (!mounted) return;
      setState(
        () => _error = error is AgendaValidationFailure
            ? error.message
            : 'Proje oluşturulamadı.',
      );
    }
  }

  Future<void> _reload({
    double? restoreOffset,
    String? preferredProjectId,
  }) async {
    if (preferredProjectId != null) {
      _preferredProjectId = preferredProjectId;
    }
    final generation = ++_reloadGeneration;
    final requestedProjectId = _preferredProjectId ?? _projectId;
    setState(() {
      _loading = true;
      _error = null;
      _preservingDetailReload = restoreOffset != null;
    });
    try {
      final projects = await widget.agenda.listProjects();
      if (!mounted || generation != _reloadGeneration) return;
      final selectedProjectId =
          requestedProjectId != null &&
              projects.any((project) => project.id == requestedProjectId)
          ? requestedProjectId
          : null;
      final logs = await widget.agenda.listAgenda(
        AgendaQuery(
          istanbulDay: _selectedDay,
          projectId: selectedProjectId,
          category: _category,
          literalSearch: _search,
          archiveFilter: _archiveFilter,
          sortOrder: _sortOrder,
        ),
      );
      if (!mounted || generation != _reloadGeneration) return;
      final linkedReminders = <String, MobileReminder>{};
      await Future.wait(
        logs.map((log) async {
          try {
            final detail = await widget.agenda.getAgendaLogDetail(log.id);
            for (final reminder in detail.reminders) {
              if (reminder.sourceLogId == log.id) {
                linkedReminders[log.id] = reminder;
                break;
              }
            }
          } on Object {
            // A single detail read must not hide the remaining Agenda cards.
          }
        }),
      );
      if (!mounted || generation != _reloadGeneration) return;
      setState(() {
        _projects = projects;
        _projectId = selectedProjectId;
        if (_preferredProjectId == selectedProjectId) {
          _preferredProjectId = null;
        }
        _logs = logs;
        _linkedReminders = linkedReminders;
        _loading = false;
        _preservingDetailReload = false;
      });
    } on Object {
      if (!mounted || generation != _reloadGeneration) return;
      setState(() {
        _loading = false;
        _preservingDetailReload = false;
        _error = 'Ajanda kayıtları güvenli biçimde okunamadı.';
      });
    }
    if (!mounted || generation != _reloadGeneration) return;
    _restoreScrollOffset(restoreOffset);
  }

  void _moveDay(int delta) {
    setState(() {
      _selectedDay = CseTimeCodec.shiftIstanbulDay(_selectedDay, delta);
    });
    _reload();
  }

  Future<void> _selectDate() async {
    final parts = _selectedDay.split('-').map(int.parse).toList();
    final selected = await showDatePicker(
      context: context,
      initialDate: DateTime(parts[0], parts[1], parts[2]),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (selected == null || !mounted) return;
    setState(() {
      _selectedDay =
          '${selected.year.toString().padLeft(4, '0')}-'
          '${selected.month.toString().padLeft(2, '0')}-'
          '${selected.day.toString().padLeft(2, '0')}';
    });
    _reload();
  }

  Future<void> _openCreateLog() async {
    final requestedProjectId = _projectId ?? widget.activeProjectId;
    final initialProjectId =
        _projects.any(
          (project) => !project.isArchived && project.id == requestedProjectId,
        )
        ? requestedProjectId
        : null;
    if (initialProjectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Önce aktif proje veya Ajanda proje filtresi seçin.'),
        ),
      );
      return;
    }
    final day = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => LogFormPage(
          agenda: widget.agenda,
          projectLocations: widget.projectLocations,
          attachments: widget.attachments,
          concrete: widget.concrete,
          concreteAttachments: widget.concreteAttachments,
          initialProjectId: initialProjectId,
          initialIstanbulDay: _selectedDay,
        ),
      ),
    );
    if (day == null || !mounted) return;
    setState(() => _selectedDay = day);
    await _reload();
  }

  Future<void> _openProjectLocationCatalog() async {
    final projectLocations = widget.projectLocations;
    if (projectLocations == null) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ProjectLocationCatalogPage(
          application: projectLocations,
          initialProjectId: _projectId,
        ),
      ),
    );
  }

  Future<void> _openDetail(AgendaLog log) async {
    if (_detailNavigationBusy) return;
    final restoreOffset = _currentScrollOffset;
    _searchFocusNode.unfocus();
    _detailNavigationBusy = true;
    try {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => LogDetailPage(
            agenda: widget.agenda,
            projectLocations: widget.projectLocations,
            attachments: widget.attachments,
            concrete: widget.concrete,
            concreteAttachments: widget.concreteAttachments,
            logId: log.id,
          ),
        ),
      );
      if (mounted) await _reload(restoreOffset: restoreOffset);
    } finally {
      _detailNavigationBusy = false;
    }
  }

  Future<void> _openLinkedReminder(MobileReminder reminder) async {
    if (_detailNavigationBusy) return;
    final restoreOffset = _currentScrollOffset;
    _searchFocusNode.unfocus();
    _detailNavigationBusy = true;
    try {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => ReminderDetailPage(
            agenda: widget.agenda,
            reminderId: reminder.id,
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

  Future<void> _changeSortOrder(AgendaSortOrder? value) async {
    if (value == null || value == _sortOrder) return;
    setState(() => _sortOrder = value);
    await _reload();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final position = _scrollController.position;
      if ((position.pixels - position.minScrollExtent).abs() > 0.5) {
        _scrollController.jumpTo(position.minScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _reload,
        child: ListView(
          key: const Key('agenda-day-list'),
          controller: _scrollController,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _listIconAction(
                  key: const Key('create-agenda-project'),
                  onPressed: _createProject,
                  icon: const Icon(Icons.create_new_folder_outlined),
                  label: 'Yeni proje oluştur',
                ),
                if (widget.projectLocations != null)
                  _listIconAction(
                    key: const Key('open-project-location-catalog'),
                    onPressed: _openProjectLocationCatalog,
                    icon: const Icon(Icons.account_tree_outlined),
                    label: 'Mahal Kataloğu',
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _listIconAction(
                  key: const Key('previous-day'),
                  onPressed: () => _moveDay(-1),
                  icon: const Icon(Icons.chevron_left),
                  label: 'Önceki gün',
                ),
                _listIconAction(
                  key: const Key('agenda-today'),
                  onPressed: () {
                    setState(() {
                      _selectedDay = CseTimeCodec.istanbulDayKey(
                        CseTimeCodec.encodeUtc(DateTime.now().toUtc()),
                      );
                    });
                    _reload();
                  },
                  icon: const Icon(Icons.today_outlined),
                  label: 'Bugüne git',
                ),
                OutlinedButton.icon(
                  key: const Key('selected-day'),
                  onPressed: _selectDate,
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: Text(_selectedDay),
                ),
                _listIconAction(
                  key: const Key('next-day'),
                  onPressed: () => _moveDay(1),
                  icon: const Icon(Icons.chevron_right),
                  label: 'Sonraki gün',
                ),
              ],
            ),
            const SizedBox(height: 12),
            SegmentedButton<AgendaArchiveFilter>(
              key: const Key('agenda-archive-filter'),
              segments: const [
                ButtonSegment(
                  value: AgendaArchiveFilter.active,
                  icon: Icon(Icons.event_note_outlined),
                  label: Text('Aktif'),
                ),
                ButtonSegment(
                  value: AgendaArchiveFilter.archived,
                  icon: Icon(Icons.archive_outlined),
                  label: Text('Arşivlenenler'),
                ),
              ],
              selected: {_archiveFilter},
              onSelectionChanged: (values) {
                setState(() => _archiveFilter = values.single);
                _reload();
              },
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<AgendaSortOrder>(
              key: const Key('agenda-sort-order'),
              initialValue: _sortOrder,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Sıralama',
                border: OutlineInputBorder(),
              ),
              items: AgendaSortOrder.values
                  .map(
                    (order) => DropdownMenuItem(
                      value: order,
                      child: Text(order.label),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (value) => unawaited(_changeSortOrder(value)),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String?>(
              key: const Key('agenda-project-filter'),
              initialValue: _projectId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Proje filtresi',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('Tüm projeler'),
                ),
                ..._projects.map(
                  (project) => DropdownMenuItem(
                    value: project.id,
                    child: Text(project.name, overflow: TextOverflow.ellipsis),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() => _projectId = value);
                _reload();
              },
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<AgendaCategory?>(
              key: const Key('agenda-category-filter'),
              initialValue: _category,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Tür filtresi',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Tüm türler')),
                ...AgendaCategory.values.map(
                  (category) => DropdownMenuItem(
                    value: category,
                    child: Text(category.label),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() => _category = value);
                _reload();
              },
            ),
            const SizedBox(height: 8),
            TextField(
              key: const Key('agenda-literal-search'),
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                labelText: 'Literal ara',
                hintText: 'Açıklama, mahal, not veya proje',
                border: const OutlineInputBorder(),
                suffixIcon: _listIconAction(
                  key: const Key('agenda-search'),
                  onPressed: _reload,
                  icon: const Icon(Icons.search),
                  label: 'Ara',
                ),
              ),
              textInputAction: TextInputAction.search,
              onChanged: (value) => _search = value,
              onSubmitted: (_) => _reload(),
              onTapOutside: (_) => _searchFocusNode.unfocus(),
            ),
            const SizedBox(height: 12),
            if (_loading && !_preservingDetailReload)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_error != null)
              _MessageCard(icon: Icons.error_outline, message: _error!)
            else if (_logs.isEmpty)
              const _MessageCard(
                icon: Icons.event_available_outlined,
                message: 'Bu günde Ajanda kaydı yok.',
              )
            else
              ..._logs.map((log) {
                final linkedReminder = _linkedReminders[log.id];
                final VoidCallback? openLinkedReminder = linkedReminder == null
                    ? null
                    : () => _openLinkedReminder(linkedReminder);
                return Card(
                  key: Key('agenda-log-${log.id}'),
                  child: InkWell(
                    onTap: () => _openDetail(log),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                CseTimeCodec.istanbulTimeLabel(log.observedAt),
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  log.category.label,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (openLinkedReminder != null)
                                _listIconAction(
                                  key: Key(
                                    'agenda-log-linked-reminder-${log.id}',
                                  ),
                                  label: 'Bağlı hatırlatıcıyı aç',
                                  onPressed: openLinkedReminder,
                                  icon: const Icon(
                                    Icons.notifications_active_outlined,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            log.description,
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            [
                              log.projectName,
                              if (log.displayLocation != null)
                                log.displayLocation!,
                            ].join(' • '),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (log.archivedAt != null) ...[
                            const SizedBox(height: 8),
                            const Row(
                              children: [
                                Icon(Icons.archive_outlined, size: 18),
                                SizedBox(width: 6),
                                Expanded(
                                  child: Text('Arşivde • geri getirilebilir'),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
      floatingActionButton: Semantics(
        container: true,
        button: true,
        enabled: true,
        label: 'Ajanda kaydı ekle',
        excludeSemantics: true,
        onTap: _openCreateLog,
        child: SizedBox.square(
          dimension: 40,
          child: FloatingActionButton.small(
            key: const Key('create-agenda-log'),
            onPressed: _openCreateLog,
            tooltip: 'Ajanda kaydı ekle',
            child: const Icon(Icons.note_add_outlined),
          ),
        ),
      ),
    );
  }
}

Widget _listIconAction({
  Key? key,
  required Widget icon,
  required String label,
  required VoidCallback? onPressed,
}) => Align(
  alignment: AlignmentDirectional.centerStart,
  widthFactor: 1,
  heightFactor: 1,
  child: Semantics(
    container: true,
    label: label,
    button: true,
    enabled: onPressed != null,
    excludeSemantics: true,
    onTap: onPressed,
    child: IconButton.filledTonal(
      key: key,
      tooltip: label,
      style: IconButton.styleFrom(
        minimumSize: const Size.square(40),
        fixedSize: const Size.square(40),
        maximumSize: const Size.square(40),
        iconSize: 20,
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.standard,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: onPressed,
      icon: icon,
    ),
  ),
);

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(icon, size: 44),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
