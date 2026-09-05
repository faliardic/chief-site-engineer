import 'dart:async';

import 'package:chief_site_engineer/application/agenda_application.dart';
import 'package:chief_site_engineer/application/context_suggestion_application.dart';
import 'package:chief_site_engineer/core/record_id.dart';
import 'package:chief_site_engineer/core/time/cse_time_codec.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/domain/context_suggestion_models.dart';
import 'package:chief_site_engineer/domain/project_location_models.dart';
import 'package:chief_site_engineer/features/agenda/project_location_catalog_page.dart';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';

class ReminderFormPage extends StatefulWidget {
  const ReminderFormPage({
    required this.agenda,
    this.contextSuggestions,
    this.projectLocations,
    this.log,
    this.preferredProjectId,
    this.initialSchedule = ReminderScheduleKind.in15Minutes,
    super.key,
  });

  final AgendaApplication agenda;
  final ContextSuggestionApplication? contextSuggestions;
  final ProjectLocationApplication? projectLocations;
  final AgendaLog? log;
  final String? preferredProjectId;
  final ReminderScheduleKind initialSchedule;

  @override
  State<ReminderFormPage> createState() => _ReminderFormPageState();
}

class _ReminderFormPageState extends State<ReminderFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  final _description = TextEditingController();
  final _location = TextEditingController();
  final _relatedPerson = TextEditingController();
  final _condition = TextEditingController();
  late final String _recordId;
  late final String _eventId;
  List<MobileProject> _projects = const [];
  List<MobileProjectLocation> _locations = const [];
  String? _projectId;
  String? _locationId;
  bool _loadingLocations = false;
  String? _locationError;
  int _projectLoadGeneration = 0;
  int _locationLoadGeneration = 0;
  List<ContextSuggestion> _contextSuggestions = const [];
  Timer? _suggestionDebounce;
  int _suggestionLoadGeneration = 0;
  ReminderKind _kind = ReminderKind.action;
  late ReminderScheduleKind _schedule;
  String? _quickSchedulePreviewAt;
  late DateTime _customDate;
  TimeOfDay _customTime = const TimeOfDay(hour: 9, minute: 0);
  bool _allDay = false;
  bool _isImportant = false;
  bool _hasDeadline = false;
  late DateTime _deadlineDate;
  TimeOfDay _deadlineTime = const TimeOfDay(hour: 17, minute: 0);
  bool _submitting = false;
  bool _allowPop = false;
  bool _exitDialogOpen = false;
  bool _loadingProjects = true;
  String? _error;
  StreamSubscription<void>? _projectSubscription;
  late String _baselineTitle;
  late String _baselineDescription;
  late String _baselineLocation;
  late String _baselineRelatedPerson;
  late String _baselineCondition;
  String? _baselineProjectId;
  String? _baselineLocationId;
  late ReminderKind _baselineKind;
  late ReminderScheduleKind _baselineSchedule;
  String? _baselineQuickSchedulePreviewAt;
  late DateTime _baselineCustomDate;
  late TimeOfDay _baselineCustomTime;
  late bool _baselineAllDay;
  late bool _baselineImportant;
  late bool _baselineHasDeadline;
  late DateTime _baselineDeadlineDate;
  late TimeOfDay _baselineDeadlineTime;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.log?.description ?? '');
    _projectId = widget.log?.projectId ?? widget.preferredProjectId;
    _schedule = widget.initialSchedule;
    _locationId = widget.log?.locationId;
    if (_locationId == null) _location.text = widget.log?.location ?? '';
    _recordId = RecordId.randomUuid();
    _eventId = RecordId.randomUuid();
    final local = CseTimeCodec.toIstanbul(
      CseTimeCodec.encodeUtc(clock.now().toUtc()),
    );
    _customDate = DateTime(local.year, local.month, local.day + 1);
    _deadlineDate = _customDate;
    _captureInitialBaseline();
    _projectSubscription = widget.agenda.projectChanges.listen(
      (_) => unawaited(_handleProjectChanges()),
    );
    _loadProjects().then((_) async {
      if (!mounted) return;
      await _loadLocations();
      _scheduleSuggestionLoad();
    });
  }

  Future<void> _handleProjectChanges() async {
    await _loadProjects();
    if (!mounted) return;
    await _loadLocations();
    _scheduleSuggestionLoad();
  }

  Future<void> _loadProjects() async {
    final generation = ++_projectLoadGeneration;
    if (mounted) setState(() => _loadingProjects = true);
    try {
      final projects = (await widget.agenda.listProjects())
          .where((project) => !project.isArchived)
          .toList(growable: false);
      if (!mounted || generation != _projectLoadGeneration) return;
      final selected =
          widget.log == null &&
              !projects.any((project) => project.id == _projectId)
          ? null
          : _projectId;
      final projectWasDirty = _projectId != _baselineProjectId;
      final locationWasDirty =
          _locationId != _baselineLocationId ||
          _location.text != _baselineLocation;
      setState(() {
        _projects = projects;
        _projectId = selected;
        if (!projectWasDirty) _baselineProjectId = selected;
        if (selected == null) {
          _locationId = null;
          _location.clear();
          if (!locationWasDirty) {
            _baselineLocationId = null;
            _baselineLocation = '';
          }
        }
        _loadingProjects = false;
      });
    } on Object {
      // Standalone capture remains available without a project.
      if (!mounted || generation != _projectLoadGeneration) return;
      final projectWasDirty = _projectId != _baselineProjectId;
      final locationWasDirty =
          _locationId != _baselineLocationId ||
          _location.text != _baselineLocation;
      setState(() {
        _projects = const [];
        if (widget.log == null) {
          _projectId = null;
          _locationId = null;
          _location.clear();
          if (!projectWasDirty) _baselineProjectId = null;
          if (!locationWasDirty) {
            _baselineLocationId = null;
            _baselineLocation = '';
          }
        }
        _loadingProjects = false;
      });
    }
  }

  Future<void> _loadLocations() async {
    final application = widget.projectLocations;
    final projectId = widget.log?.projectId ?? _projectId;
    if (application == null) return;
    final generation = ++_locationLoadGeneration;
    setState(() {
      _loadingLocations = projectId != null;
      _locationError = null;
      if (projectId == null) _locations = const [];
    });
    if (projectId == null) return;
    try {
      final values = await application.listProjectLocations(
        ProjectLocationQuery(projectId: projectId),
      );
      if (!mounted || generation != _locationLoadGeneration) return;
      final canKeepSourceArchived =
          _locationId != null &&
          widget.log?.locationId == _locationId &&
          widget.log?.stableLocationName != null;
      final locationWasDirty = _locationId != _baselineLocationId;
      setState(() {
        _locations = values;
        if (!values.any((item) => item.id == _locationId) &&
            !canKeepSourceArchived) {
          _locationId = null;
          if (!locationWasDirty) _baselineLocationId = null;
        }
        _loadingLocations = false;
      });
    } on Object {
      if (!mounted || generation != _locationLoadGeneration) return;
      setState(() {
        _locations = const [];
        _loadingLocations = false;
        _locationError = 'Mahaller güvenli biçimde okunamadı.';
      });
    }
  }

  Future<void> _selectProject(String? projectId) async {
    if (projectId == _projectId) return;
    _suggestionDebounce?.cancel();
    _suggestionLoadGeneration += 1;
    setState(() {
      _projectId = projectId;
      _locationId = null;
      _location.clear();
      _contextSuggestions = const [];
    });
    await _loadLocations();
    _scheduleSuggestionLoad();
  }

  void _scheduleSuggestionLoad([String? rawQuery]) {
    _suggestionDebounce?.cancel();
    final generation = ++_suggestionLoadGeneration;
    final application = widget.contextSuggestions;
    final projectId = widget.log?.projectId ?? _projectId;
    if (application == null || projectId == null) {
      if (mounted && _contextSuggestions.isNotEmpty) {
        setState(() => _contextSuggestions = const []);
      }
      return;
    }
    final query = rawQuery ?? _relatedPerson.text;
    _suggestionDebounce = Timer(const Duration(milliseconds: 200), () async {
      try {
        final suggestions = await application.suggestPeopleAndCompanies(
          ContextSuggestionQuery(projectId: projectId, query: query),
        );
        if (!mounted || generation != _suggestionLoadGeneration) return;
        setState(() => _contextSuggestions = suggestions);
      } on Object {
        if (!mounted || generation != _suggestionLoadGeneration) return;
        setState(() => _contextSuggestions = const []);
      }
    });
  }

  void _selectContextSuggestion(ContextSuggestion suggestion) {
    setState(() {
      _relatedPerson.text = suggestion.displayValue;
      _relatedPerson.selection = TextSelection.collapsed(
        offset: suggestion.displayValue.length,
      );
    });
    _scheduleSuggestionLoad(suggestion.displayValue);
  }

  Future<void> _openLocationCatalog() async {
    final application = widget.projectLocations;
    final projectId = widget.log?.projectId ?? _projectId;
    if (application == null || projectId == null) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ProjectLocationCatalogPage(
          application: application,
          initialProjectId: projectId,
        ),
      ),
    );
    if (mounted) await _loadLocations();
  }

  @override
  void dispose() {
    _projectSubscription?.cancel();
    _suggestionDebounce?.cancel();
    _title.dispose();
    _description.dispose();
    _location.dispose();
    _relatedPerson.dispose();
    _condition.dispose();
    super.dispose();
  }

  void _captureInitialBaseline() {
    _baselineTitle = _title.text;
    _baselineDescription = _description.text;
    _baselineLocation = _location.text;
    _baselineRelatedPerson = _relatedPerson.text;
    _baselineCondition = _condition.text;
    _baselineProjectId = _projectId;
    _baselineLocationId = _locationId;
    _baselineKind = _kind;
    _baselineSchedule = _schedule;
    _baselineQuickSchedulePreviewAt = _quickSchedulePreviewAt;
    _baselineCustomDate = _customDate;
    _baselineCustomTime = _customTime;
    _baselineAllDay = _allDay;
    _baselineImportant = _isImportant;
    _baselineHasDeadline = _hasDeadline;
    _baselineDeadlineDate = _deadlineDate;
    _baselineDeadlineTime = _deadlineTime;
  }

  bool get _isDirty {
    final customDateChanged =
        (_schedule == ReminderScheduleKind.custom ||
            _allDay ||
            _baselineSchedule == ReminderScheduleKind.custom ||
            _baselineAllDay) &&
        _customDate != _baselineCustomDate;
    final customTimeChanged =
        ((_schedule == ReminderScheduleKind.custom && !_allDay) ||
            (_baselineSchedule == ReminderScheduleKind.custom &&
                !_baselineAllDay)) &&
        _customTime != _baselineCustomTime;
    final deadlineChanged =
        (_hasDeadline || _baselineHasDeadline) &&
        (_deadlineDate != _baselineDeadlineDate ||
            _deadlineTime != _baselineDeadlineTime);
    return _title.text != _baselineTitle ||
        _description.text != _baselineDescription ||
        _location.text != _baselineLocation ||
        _relatedPerson.text != _baselineRelatedPerson ||
        _condition.text != _baselineCondition ||
        _projectId != _baselineProjectId ||
        _locationId != _baselineLocationId ||
        _kind != _baselineKind ||
        _schedule != _baselineSchedule ||
        _quickSchedulePreviewAt != _baselineQuickSchedulePreviewAt ||
        customDateChanged ||
        customTimeChanged ||
        _allDay != _baselineAllDay ||
        _isImportant != _baselineImportant ||
        _hasDeadline != _baselineHasDeadline ||
        deadlineChanged;
  }

  void _rebuildForUserEdit(String _) {
    if (mounted) setState(() {});
  }

  Future<void> _handlePopAttempt(Object? result) async {
    if (_submitting || !_isDirty || _exitDialogOpen) return;
    _exitDialogOpen = true;
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: const Key('unsaved-changes-dialog'),
        title: const Text('Kaydedilmemiş değişiklikler'),
        content: const Text(
          'Yaptığınız değişiklikler kaydedilmedi. Formdan çıkmak istiyor musunuz?',
        ),
        actions: [
          TextButton(
            key: const Key('stay-on-form'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Formda kal'),
          ),
          TextButton(
            key: const Key('discard-form'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Kaydetmeden çık'),
          ),
        ],
      ),
    );
    _exitDialogOpen = false;
    if (!mounted || discard != true) return;
    await _popWithGuardBypass(result);
  }

  Future<void> _popWithGuardBypass(Object? result) async {
    if (!mounted) return;
    setState(() => _allowPop = true);
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) Navigator.of(context).pop(result);
  }

  Future<void> _submit() async {
    if (_submitting || _loadingProjects || !_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final custom = !_allDay
          ? _schedule == ReminderScheduleKind.custom
                ? CseTimeCodec.canonicalFromIstanbulComponents(
                    year: _customDate.year,
                    month: _customDate.month,
                    day: _customDate.day,
                    hour: _customTime.hour,
                    minute: _customTime.minute,
                  )
                : _quickSchedulePreviewAt
          : null;
      final deadline = _hasDeadline
          ? CseTimeCodec.canonicalFromIstanbulComponents(
              year: _deadlineDate.year,
              month: _deadlineDate.month,
              day: _deadlineDate.day,
              hour: _deadlineTime.hour,
              minute: _deadlineTime.minute,
            )
          : null;
      final reminder = await widget.agenda.createReminder(
        CreateReminderCommand(
          id: _recordId,
          eventId: _eventId,
          projectId: widget.log?.projectId ?? _projectId,
          sourceLogId: widget.log?.id,
          captureText: _title.text,
          title: _title.text,
          description: _description.text,
          kind: _kind,
          schedule: _schedule,
          locationId: _locationId,
          location: _location.text,
          relatedPerson: _relatedPerson.text,
          isImportant: _isImportant,
          deadlineAt: deadline,
          conditionText: _condition.text,
          customAttentionAt: custom,
          allDayLocalDate: _allDay
              ? '${_customDate.year.toString().padLeft(4, '0')}-'
                    '${_customDate.month.toString().padLeft(2, '0')}-'
                    '${_customDate.day.toString().padLeft(2, '0')}'
              : null,
        ),
      );
      var deliveryVerified = reminder.nextAttentionAt == null;
      if (!deliveryVerified) {
        try {
          final detail = await widget.agenda.getReminderLifecycleDetail(
            reminder.id,
          );
          deliveryVerified =
              detail.notification.syncState == NotificationSyncState.scheduled;
        } on Object {
          deliveryVerified = false;
        }
      }
      if (!deliveryVerified && mounted) {
        setState(() => _submitting = false);
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            key: const Key('reminder-delivery-warning'),
            title: const Text('Kayıt oluşturuldu'),
            content: const Text(
              'Hatırlatıcı kaydı korundu ancak arka plan bildirimi '
              'doğrulanamadı. Kayıt detayındaki teslimat tanısını ve sistem '
              'ayarlarını kontrol edin.',
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Anladım'),
              ),
            ],
          ),
        );
      }
      await _popWithGuardBypass(reminder);
    } on AgendaValidationFailure catch (error) {
      if (mounted) {
        setState(() => _error = error.message);
      }
    } on TimeContractViolation {
      if (mounted) {
        setState(() => _error = 'Hatırlatıcı tarih/saat değeri geçersiz.');
      }
    } on Object {
      if (mounted) {
        setState(() => _error = 'Hatırlatıcı güvenli biçimde oluşturulamadı.');
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _selectAllDay(int dayDelta) {
    final local = CseTimeCodec.toIstanbul(
      CseTimeCodec.encodeUtc(clock.now().toUtc()),
    );
    setState(() {
      _customDate = DateTime(local.year, local.month, local.day + dayDelta);
      _schedule = ReminderScheduleKind.custom;
      _quickSchedulePreviewAt = null;
      _allDay = true;
    });
  }

  void _selectSchedule(ReminderScheduleKind schedule) {
    final nowUtc = clock.now().toUtc();
    setState(() {
      _schedule = schedule;
      _quickSchedulePreviewAt = resolveReminderExactQuickScheduleAt(
        schedule,
        nowUtc,
      );
      _allDay = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      canPop: _allowPop || (!_submitting && !_isDirty),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) unawaited(_handlePopAttempt(result));
      },
      child: _buildForm(),
    );
  }

  Widget _buildForm() {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.log != null
              ? 'Hatırlatıcı oluştur'
              : widget.initialSchedule == ReminderScheduleKind.inbox
              ? 'Unutma Kutusu'
              : 'Yeni hatırlatıcı',
        ),
      ),
      body: Form(
        key: _formKey,
        child: SafeArea(
          key: const Key('reminder-form-viewport'),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: SingleChildScrollView(
                      key: const Key('reminder-form-scroll'),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _formGroup(
                            'Hatırlatıcı',
                            const Key('reminder-capture-group'),
                            [
                              if (widget.log != null)
                                Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Text(
                                      'Kaynak: ${widget.log!.description}',
                                      maxLines: 4,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              if (_error != null)
                                Card(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.errorContainer,
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Text(
                                      _error!,
                                      key: const Key('reminder-form-error'),
                                    ),
                                  ),
                                ),
                              TextFormField(
                                key: const Key('reminder-title'),
                                controller: _title,
                                maxLength: 500,
                                minLines: 2,
                                maxLines: 5,
                                decoration: const InputDecoration(
                                  labelText: 'Hatırlatıcı metni',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) =>
                                    value == null || value.trim().isEmpty
                                    ? 'Hatırlatıcı metni zorunludur.'
                                    : null,
                                onChanged: _rebuildForUserEdit,
                              ),
                              if (_loadingProjects)
                                const LinearProgressIndicator(),
                              if (widget.log == null &&
                                  _projects.isNotEmpty) ...[
                                DropdownButtonFormField<String?>(
                                  key: const Key('reminder-project'),
                                  initialValue: _projectId,
                                  isExpanded: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Proje (opsiyonel)',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: [
                                    const DropdownMenuItem<String?>(
                                      value: null,
                                      child: Text('Kişisel / projesiz'),
                                    ),
                                    ..._projects.map(
                                      (project) => DropdownMenuItem<String?>(
                                        value: project.id,
                                        child: Text(project.name),
                                      ),
                                    ),
                                  ],
                                  onChanged: _selectProject,
                                ),
                                const SizedBox(height: 12),
                              ],
                            ],
                          ),
                          const SizedBox(height: 24),
                          _formGroup('Zaman', const Key('reminder-time-group'), [
                            DropdownButtonFormField<ReminderScheduleKind>(
                              key: const Key('reminder-schedule'),
                              initialValue: _schedule,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Ne zaman?',
                                border: OutlineInputBorder(),
                              ),
                              items: ReminderScheduleKind.values
                                  .map(
                                    (schedule) => DropdownMenuItem(
                                      value: schedule,
                                      child: Text(schedule.label),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) => _selectSchedule(value!),
                            ),
                            if (_quickSchedulePreviewAt
                                case final preview?) ...[
                              const SizedBox(height: 8),
                              Text(
                                '${_schedule.label} — '
                                '${formatReminderExactSchedule(preview)}',
                                key: const Key('reminder-schedule-preview'),
                              ),
                            ],
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _ReminderFormIconAction(
                                  actionKey: const Key('reminder-today'),
                                  label: 'Bugün',
                                  onPressed: () => _selectAllDay(0),
                                  icon: const Icon(Icons.today_outlined),
                                ),
                                _ReminderFormIconAction(
                                  actionKey: const Key(
                                    'reminder-all-day-tomorrow',
                                  ),
                                  label: 'Yarın • Tam gün',
                                  onPressed: () => _selectAllDay(1),
                                  icon: const Icon(Icons.event_outlined),
                                ),
                              ],
                            ),
                            SwitchListTile(
                              key: const Key('reminder-all-day'),
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Tam gün'),
                              subtitle: const Text(
                                'Saatli bildirim kurulmaz; seçilen gün Bugün’de görünür.',
                              ),
                              value: _allDay,
                              onChanged: (value) => setState(() {
                                _allDay = value;
                                if (value) {
                                  final local = CseTimeCodec.toIstanbul(
                                    CseTimeCodec.encodeUtc(clock.now().toUtc()),
                                  );
                                  _customDate = DateTime(
                                    local.year,
                                    local.month,
                                    local.day,
                                  );
                                  _schedule = ReminderScheduleKind.custom;
                                  _quickSchedulePreviewAt = null;
                                }
                              }),
                            ),
                            if (_schedule == ReminderScheduleKind.custom ||
                                _allDay) ...[
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  OutlinedButton.icon(
                                    key: const Key('reminder-custom-date'),
                                    onPressed: () async {
                                      final value = await showDatePicker(
                                        context: context,
                                        initialDate: _customDate,
                                        firstDate: DateTime(2000),
                                        lastDate: DateTime(2100),
                                      );
                                      if (value != null) {
                                        setState(() => _customDate = value);
                                      }
                                    },
                                    icon: const Icon(
                                      Icons.calendar_today_outlined,
                                    ),
                                    label: Text(
                                      '${_customDate.day.toString().padLeft(2, '0')}.'
                                      '${_customDate.month.toString().padLeft(2, '0')}.${_customDate.year}',
                                    ),
                                  ),
                                  if (!_allDay)
                                    OutlinedButton.icon(
                                      key: const Key('reminder-custom-time'),
                                      onPressed: () async {
                                        final value = await showTimePicker(
                                          context: context,
                                          initialTime: _customTime,
                                        );
                                        if (value != null) {
                                          setState(() => _customTime = value);
                                        }
                                      },
                                      icon: const Icon(Icons.schedule),
                                      label: Text(_customTime.format(context)),
                                    ),
                                ],
                              ),
                            ],
                          ]),
                          const SizedBox(height: 24),
                          ExpansionTile(
                            key: const Key('reminder-optional-details'),
                            tilePadding: EdgeInsets.zero,
                            title: const Text('İsteğe bağlı ayrıntılar'),
                            children: [
                              DropdownButtonFormField<ReminderKind>(
                                key: const Key('reminder-kind'),
                                initialValue: _kind,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: 'Tür',
                                  border: OutlineInputBorder(),
                                ),
                                items: ReminderKind.values
                                    .map(
                                      (kind) => DropdownMenuItem(
                                        value: kind,
                                        child: Text(kind.label),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) =>
                                    setState(() => _kind = value!),
                              ),
                              const SizedBox(height: 12),

                              TextField(
                                key: const Key('reminder-description'),
                                controller: _description,
                                minLines: 2,
                                maxLines: 4,
                                decoration: const InputDecoration(
                                  labelText: 'Açıklama',
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: _rebuildForUserEdit,
                              ),
                              const SizedBox(height: 12),
                              if ((widget.log?.projectId ?? _projectId) == null)
                                TextField(
                                  key: const Key('reminder-location'),
                                  controller: _location,
                                  decoration: const InputDecoration(
                                    labelText: 'Mahál',
                                    border: OutlineInputBorder(),
                                  ),
                                  onChanged: _rebuildForUserEdit,
                                )
                              else
                                _buildStableLocationField(),
                              const SizedBox(height: 12),
                              TextField(
                                key: const Key('reminder-related-person'),
                                controller: _relatedPerson,
                                onChanged: (value) {
                                  _rebuildForUserEdit(value);
                                  _scheduleSuggestionLoad(value);
                                },
                                decoration: const InputDecoration(
                                  labelText: 'İlgili kişi / Firma',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              if (_contextSuggestions.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Öneriler',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.labelLarge,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Column(
                                  key: const Key(
                                    'reminder-context-suggestions',
                                  ),
                                  children: [
                                    for (final suggestion
                                        in _contextSuggestions)
                                      Card(
                                        margin: const EdgeInsets.only(
                                          bottom: 6,
                                        ),
                                        child: ListTile(
                                          key: ValueKey(
                                            'reminder-context-suggestion-'
                                            '${suggestion.sourceType.name}-'
                                            '${suggestion.sourceId ?? suggestion.displayValue}',
                                          ),
                                          dense: true,
                                          leading: Icon(
                                            suggestion.kind ==
                                                    ContextSuggestionKind.person
                                                ? Icons.person_outline
                                                : Icons.business_outlined,
                                          ),
                                          title: Text(suggestion.displayValue),
                                          subtitle: Text(
                                            _contextSuggestionSourceLabel(
                                              suggestion,
                                            ),
                                          ),
                                          onTap: () => _selectContextSuggestion(
                                            suggestion,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 12),
                              TextField(
                                key: const Key('reminder-condition'),
                                controller: _condition,
                                minLines: 2,
                                maxLines: 4,
                                decoration: const InputDecoration(
                                  labelText: 'Koşul/not',
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: _rebuildForUserEdit,
                              ),
                              SwitchListTile(
                                key: const Key('reminder-important'),
                                contentPadding: EdgeInsets.zero,
                                title: const Text('Önemli'),
                                value: _isImportant,
                                onChanged: (value) =>
                                    setState(() => _isImportant = value),
                              ),
                              SwitchListTile(
                                key: const Key('reminder-has-deadline'),
                                contentPadding: EdgeInsets.zero,
                                title: const Text('Gerçek son tarih ekle'),
                                value: _hasDeadline,
                                onChanged: (value) =>
                                    setState(() => _hasDeadline = value),
                              ),
                              if (_hasDeadline)
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    OutlinedButton.icon(
                                      key: const Key('reminder-deadline-date'),
                                      onPressed: () async {
                                        final value = await showDatePicker(
                                          context: context,
                                          initialDate: _deadlineDate,
                                          firstDate: DateTime(2000),
                                          lastDate: DateTime(2100),
                                        );
                                        if (value != null) {
                                          setState(() => _deadlineDate = value);
                                        }
                                      },
                                      icon: const Icon(
                                        Icons.event_available_outlined,
                                      ),
                                      label: Text(
                                        '${_deadlineDate.day.toString().padLeft(2, '0')}.'
                                        '${_deadlineDate.month.toString().padLeft(2, '0')}.'
                                        '${_deadlineDate.year}',
                                      ),
                                    ),
                                    OutlinedButton.icon(
                                      key: const Key('reminder-deadline-time'),
                                      onPressed: () async {
                                        final value = await showTimePicker(
                                          context: context,
                                          initialTime: _deadlineTime,
                                        );
                                        if (value != null) {
                                          setState(() => _deadlineTime = value);
                                        }
                                      },
                                      icon: const Icon(Icons.schedule),
                                      label: Text(
                                        _deadlineTime.format(context),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: Semantics(
                        label: _submitting ? 'Kaydediliyor…' : 'Kaydet',
                        button: true,
                        enabled: !_submitting && !_loadingProjects,
                        excludeSemantics: true,
                        onTap: _submitting || _loadingProjects ? null : _submit,
                        child: FilledButton.icon(
                          key: const Key('submit-reminder'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 48),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          onPressed: _submitting || _loadingProjects
                              ? null
                              : _submit,
                          icon: _submitting
                              ? const SizedBox.square(
                                  dimension: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.save_outlined),
                          label: Text(_submitting ? 'Kaydediliyor…' : 'Kaydet'),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _formGroup(String title, Key key, List<Widget> children) => Material(
    key: key,
    color: Theme.of(context).colorScheme.surfaceContainerLow,
    borderRadius: BorderRadius.circular(16),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    ),
  );

  Widget _buildStableLocationField() {
    final options = _reminderLocationOptions(_locations);
    final source = widget.log;
    if (_locationId != null &&
        !options.any((item) => item.id == _locationId) &&
        source?.locationId == _locationId &&
        source?.stableLocationName != null) {
      options.add(
        _ReminderLocationOption(
          id: _locationId!,
          label: '${source!.stableLocationName!} (Arşivli)',
          archived: true,
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_loadingLocations) const LinearProgressIndicator(),
        DropdownButtonFormField<String>(
          key: const Key('reminder-location-selector'),
          initialValue: _locationId,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Mahal (opsiyonel)',
            border: OutlineInputBorder(),
          ),
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Text('Mahal seçilmedi'),
            ),
            ...options.map(
              (item) => DropdownMenuItem<String>(
                value: item.id,
                child: Text(item.label, overflow: TextOverflow.ellipsis),
              ),
            ),
          ],
          onChanged: _loadingLocations
              ? null
              : (value) => setState(() {
                  _locationId = value;
                  if (value == null) _location.clear();
                }),
        ),
        if (!_loadingLocations &&
            options.where((item) => !item.archived).isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text(
              'Bu projede aktif mahal yok. Mahal Kataloğu’ndan ekleyebilirsiniz.',
              key: Key('reminder-location-empty'),
            ),
          ),
        if (_locationError != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              _locationError!,
              key: const Key('reminder-location-load-error'),
            ),
          ),
        if (source?.locationId == null &&
            (source?.location?.trim().isNotEmpty ?? false))
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'Eski serbest mahal: ${source!.location}',
              key: const Key('reminder-legacy-location-context'),
            ),
          ),
        if (options.any((item) => item.id == _locationId && item.archived))
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text(
              'Arşivli mahal bağlantısı korunuyor.',
              key: Key('reminder-archived-location-context'),
            ),
          ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: _ReminderFormIconAction(
            actionKey: const Key('open-location-catalog-from-reminder'),
            label: 'Mahal Kataloğu',
            onPressed: _openLocationCatalog,
            icon: const Icon(Icons.account_tree_outlined),
          ),
        ),
      ],
    );
  }
}

class _ReminderFormIconAction extends StatelessWidget {
  const _ReminderFormIconAction({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.actionKey,
  });

  final Key? actionKey;
  final Widget icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final style = IconButton.styleFrom(
      minimumSize: const Size.square(48),
      fixedSize: const Size.square(48),
      maximumSize: const Size.square(48),
      iconSize: 20,
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.standard,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
    final button = IconButton.outlined(
      key: actionKey,
      tooltip: label,
      style: style,
      onPressed: onPressed,
      icon: icon,
    );
    return Semantics(
      label: label,
      button: true,
      enabled: onPressed != null,
      excludeSemantics: true,
      child: button,
    );
  }
}

String _contextSuggestionSourceLabel(ContextSuggestion suggestion) {
  final base = switch (suggestion.sourceType) {
    ContextSuggestionSourceType.workforceMember => 'Saha Rehberi • aktif kişi',
    ContextSuggestionSourceType.subcontractor => 'Firma / İşveren • aktif',
    ContextSuggestionSourceType.historicalRelatedPerson =>
      'Bu projedeki önceki kullanım',
  };
  if (suggestion.sourceType ==
          ContextSuggestionSourceType.historicalRelatedPerson ||
      suggestion.historicalUsageCount == 0) {
    return base;
  }
  return '$base • önceki kullanım';
}

class _ReminderLocationOption {
  const _ReminderLocationOption({
    required this.id,
    required this.label,
    this.archived = false,
  });

  final String id;
  final String label;
  final bool archived;
}

List<_ReminderLocationOption> _reminderLocationOptions(
  List<MobileProjectLocation> locations,
) {
  final byId = {for (final item in locations) item.id: item};
  String pathFor(MobileProjectLocation item, Set<String> visiting) {
    if (!visiting.add(item.id)) return item.displayName;
    final parent = item.parentLocationId == null
        ? null
        : byId[item.parentLocationId];
    final value = parent == null
        ? item.displayName
        : '${pathFor(parent, visiting)} › ${item.displayName}';
    visiting.remove(item.id);
    return value;
  }

  return locations
      .map(
        (item) => _ReminderLocationOption(
          id: item.id,
          label: pathFor(item, <String>{}),
        ),
      )
      .toList(growable: true);
}
