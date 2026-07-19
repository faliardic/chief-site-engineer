import 'package:chief_site_engineer/application/agenda_application.dart';
import 'package:chief_site_engineer/core/time/cse_time_codec.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/features/agenda/log_detail_page.dart';
import 'package:chief_site_engineer/features/agenda/log_form_page.dart';
import 'package:chief_site_engineer/features/reminders/reminder_form_page.dart';
import 'package:flutter/material.dart';

class AgendaPage extends StatefulWidget {
  const AgendaPage({required this.agenda, super.key});

  final AgendaApplication agenda;

  @override
  State<AgendaPage> createState() => _AgendaPageState();
}

class _AgendaPageState extends State<AgendaPage> {
  late String _selectedDay;
  List<MobileProject> _projects = const [];
  List<AgendaLog> _logs = const [];
  String? _projectId;
  AgendaCategory? _category;
  String _search = '';
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedDay = CseTimeCodec.istanbulDayKey(
      CseTimeCodec.encodeUtc(DateTime.now().toUtc()),
    );
    _reload();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final projects = await widget.agenda.listProjects();
      final logs = await widget.agenda.listAgenda(
        AgendaQuery(
          istanbulDay: _selectedDay,
          projectId: _projectId,
          category: _category,
          literalSearch: _search,
        ),
      );
      if (!mounted) return;
      setState(() {
        _projects = projects;
        _logs = logs;
        _loading = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Ajanda kayıtları güvenli biçimde okunamadı.';
      });
    }
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
    final day = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => LogFormPage(agenda: widget.agenda)),
    );
    if (day == null || !mounted) return;
    setState(() => _selectedDay = day);
    await _reload();
  }

  Future<void> _openDetail(AgendaLog log) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => LogDetailPage(agenda: widget.agenda, logId: log.id),
      ),
    );
    if (mounted) await _reload();
  }

  Future<void> _openReminder(AgendaLog log) async {
    final created = await Navigator.of(context).push<MobileReminder>(
      MaterialPageRoute(
        builder: (_) => ReminderFormPage(agenda: widget.agenda, log: log),
      ),
    );
    if (created != null && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Hatırlatıcı oluşturuldu.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _reload,
        child: ListView(
          key: const Key('agenda-day-list'),
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                IconButton.filledTonal(
                  key: const Key('previous-day'),
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  onPressed: () => _moveDay(-1),
                  icon: const Icon(Icons.chevron_left),
                  tooltip: 'Önceki gün',
                ),
                FilledButton.tonal(
                  onPressed: () {
                    setState(() {
                      _selectedDay = CseTimeCodec.istanbulDayKey(
                        CseTimeCodec.encodeUtc(DateTime.now().toUtc()),
                      );
                    });
                    _reload();
                  },
                  child: const Text('Bugün'),
                ),
                OutlinedButton.icon(
                  key: const Key('selected-day'),
                  onPressed: _selectDate,
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: Text(_selectedDay),
                ),
                IconButton.filledTonal(
                  key: const Key('next-day'),
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  onPressed: () => _moveDay(1),
                  icon: const Icon(Icons.chevron_right),
                  tooltip: 'Sonraki gün',
                ),
              ],
            ),
            const SizedBox(height: 12),
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
              decoration: InputDecoration(
                labelText: 'Literal ara',
                hintText: 'Açıklama, mahal, not veya proje',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  onPressed: _reload,
                  icon: const Icon(Icons.search),
                  tooltip: 'Ara',
                ),
              ),
              textInputAction: TextInputAction.search,
              onChanged: (value) => _search = value,
              onSubmitted: (_) => _reload(),
            ),
            const SizedBox(height: 12),
            if (_loading)
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
              ..._logs.map(
                (log) => Card(
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
                              if (log.location != null) log.location!,
                            ].join(' • '),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: OutlinedButton.icon(
                              onPressed: () => _openReminder(log),
                              icon: const Icon(Icons.add_alert_outlined),
                              label: const Text('Hatırlatıcı oluştur'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('create-agenda-log'),
        onPressed: _openCreateLog,
        icon: const Icon(Icons.add),
        label: const Text('Log ekle'),
      ),
    );
  }
}

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
