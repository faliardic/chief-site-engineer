import 'dart:async';

import 'package:chief_site_engineer/application/agenda_application.dart';
import 'package:chief_site_engineer/application/concrete_application.dart';
import 'package:chief_site_engineer/core/time/cse_time_codec.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/domain/concrete_models.dart';
import 'package:chief_site_engineer/features/concrete/concrete_pour_detail_page.dart';
import 'package:chief_site_engineer/features/concrete/concrete_pour_form_page.dart';
import 'package:chief_site_engineer/platform/attachment_gateway.dart';
import 'package:flutter/material.dart';

class ConcretePage extends StatefulWidget {
  const ConcretePage({
    required this.concrete,
    required this.agenda,
    required this.attachments,
    this.projectLocations,
    this.initialProjectId,
    this.initialIstanbulDay,
    super.key,
  });

  final ConcreteApplication concrete;
  final AgendaApplication agenda;
  final SafeAttachmentPicker attachments;
  final ProjectLocationApplication? projectLocations;
  final String? initialProjectId;
  final String? initialIstanbulDay;

  @override
  State<ConcretePage> createState() => _ConcretePageState();
}

class _ConcretePageState extends State<ConcretePage> {
  final ScrollController _scrollController = ScrollController();
  final _search = TextEditingController();
  List<MobileProject> _projects = const [];
  List<ConcretePour> _pours = const [];
  MobileProject? _project;
  ConcretePourGroup _group = ConcretePourGroup.today;
  late String _day;
  bool _loading = true;
  String? _error;
  StreamSubscription<void>? _projectSubscription;
  bool _detailNavigationBusy = false;

  @override
  void initState() {
    super.initState();
    _day = _safeInitialDay(widget.initialIstanbulDay);
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
    super.dispose();
  }

  Future<void> _loadProjects() async {
    setState(() => _loading = true);
    try {
      _projects = await widget.agenda.listProjects();
      final preferredProjectId = _project?.id ?? widget.initialProjectId;
      _project = _projects
          .where((project) => project.id == preferredProjectId)
          .firstOrNull;
      _project ??= _projects.firstOrNull;
      await _reload();
    } on Object catch (error) {
      if (mounted) {
        setState(() => _error = _message(error, 'Beton paketleri açılamadı.'));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _reload({double? restoreOffset}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final values = await widget.concrete.listPours(
        ConcretePourQuery(
          group: _group,
          projectId: _project?.id,
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

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _reload,
      child: ListView(
        key: const Key('concrete-page'),
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<MobileProject>(
                  key: const Key('concrete-project-filter'),
                  initialValue: _project,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Proje',
                    border: OutlineInputBorder(),
                  ),
                  items: _projects
                      .map(
                        (item) => DropdownMenuItem(
                          value: item,
                          child: Text(
                            item.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    setState(() => _project = value);
                    _reload();
                  },
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                key: const Key('concrete-day-filter'),
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_today_outlined),
                label: Text(_day),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _search,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              labelText: 'Kod, mahal, blok, kat veya aks ara',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                onPressed: _reload,
                icon: const Icon(Icons.search),
              ),
            ),
            onSubmitted: (_) => _reload(),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegmentedButton<ConcretePourGroup>(
              key: const Key('concrete-group-filter'),
              segments: const [
                ButtonSegment(
                  value: ConcretePourGroup.today,
                  label: Text('Bugün'),
                ),
                ButtonSegment(
                  value: ConcretePourGroup.upcoming,
                  label: Text('Yaklaşan'),
                ),
                ButtonSegment(
                  value: ConcretePourGroup.inProgress,
                  label: Text('Dökümde'),
                ),
                ButtonSegment(
                  value: ConcretePourGroup.followUp,
                  label: Text('Takipte'),
                ),
                ButtonSegment(
                  value: ConcretePourGroup.closed,
                  label: Text('Kapalı'),
                ),
              ],
              selected: {_group},
              onSelectionChanged: (values) {
                setState(() => _group = values.single);
                _reload();
              },
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: _projects.isEmpty ? null : _create,
              icon: const Icon(Icons.add),
              label: const Text('Yeni döküm'),
            ),
          ),
          if (_error case final error?) ...[
            const SizedBox(height: 12),
            Text(
              error,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (!_loading && _pours.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: Text('Bu görünümde Beton paketi yok.')),
            ),
          for (final pour in _pours)
            Card(
              key: Key('concrete-pour-${pour.id}'),
              child: ListTile(
                minVerticalPadding: 12,
                leading: const Icon(Icons.foundation_outlined),
                title: Text('${pour.pourCode} • ${pour.elementLocation}'),
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
          const SizedBox(height: 88),
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
