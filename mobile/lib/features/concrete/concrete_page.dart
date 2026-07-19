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
    super.key,
  });

  final ConcreteApplication concrete;
  final AgendaApplication agenda;
  final SafeAttachmentPicker attachments;

  @override
  State<ConcretePage> createState() => _ConcretePageState();
}

class _ConcretePageState extends State<ConcretePage> {
  final _search = TextEditingController();
  List<MobileProject> _projects = const [];
  List<ConcretePour> _pours = const [];
  MobileProject? _project;
  ConcretePourGroup _group = ConcretePourGroup.today;
  late String _day;
  bool _loading = true;
  String? _error;
  StreamSubscription<void>? _projectSubscription;

  @override
  void initState() {
    super.initState();
    _day = CseTimeCodec.istanbulDayKey(
      CseTimeCodec.encodeUtc(DateTime.now().toUtc()),
    );
    _projectSubscription = widget.agenda.projectChanges.listen(
      (_) => _loadProjects(),
    );
    _loadProjects();
  }

  @override
  void dispose() {
    _projectSubscription?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _loadProjects() async {
    setState(() => _loading = true);
    try {
      _projects = await widget.agenda.listProjects();
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

  Future<void> _reload() async {
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
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ConcretePourDetailPage(
          concrete: widget.concrete,
          agenda: widget.agenda,
          attachments: widget.attachments,
          pourId: id,
        ),
      ),
    );
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _reload,
      child: ListView(
        key: const Key('concrete-page'),
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<MobileProject>(
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
              IconButton.filledTonal(
                tooltip: 'Tarih seç',
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_today_outlined),
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
              child: ListTile(
                minVerticalPadding: 12,
                leading: const Icon(Icons.foundation_outlined),
                title: Text('${pour.pourCode} • ${pour.elementLocation}'),
                subtitle: Text(
                  '${CseTimeCodec.formatIstanbul(pour.plannedAt)}\n'
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
