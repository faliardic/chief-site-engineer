import 'package:chief_site_engineer/application/agenda_application.dart';
import 'package:chief_site_engineer/application/concrete_application.dart';
import 'package:chief_site_engineer/core/record_id.dart';
import 'package:chief_site_engineer/core/time/cse_time_codec.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/domain/project_location_models.dart';
import 'package:chief_site_engineer/features/agenda/agenda_concrete_signal.dart';
import 'package:chief_site_engineer/features/agenda/agenda_concrete_suggestion_card.dart';
import 'package:chief_site_engineer/features/agenda/project_location_catalog_page.dart';
import 'package:chief_site_engineer/features/concrete/concrete_destination_page.dart';
import 'package:chief_site_engineer/features/owned_text_input_dialog.dart';
import 'package:chief_site_engineer/platform/attachment_gateway.dart';
import 'package:flutter/material.dart';

class LogFormPage extends StatefulWidget {
  const LogFormPage({
    required this.agenda,
    this.projectLocations,
    this.attachments,
    this.concrete,
    this.concreteAttachments,
    this.existing,
    this.initialProjectId,
    this.initialIstanbulDay,
    super.key,
  });

  final AgendaApplication agenda;
  final ProjectLocationApplication? projectLocations;
  final SafeAttachmentPicker? attachments;
  final ConcreteApplication? concrete;
  final SafeAttachmentPicker? concreteAttachments;
  final AgendaLog? existing;
  final String? initialProjectId;
  final String? initialIstanbulDay;

  @override
  State<LogFormPage> createState() => _LogFormPageState();
}

class _LogFormPageState extends State<LogFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _categoryFieldKey = GlobalKey<FormFieldState<AgendaCategory>>();
  final _description = TextEditingController();
  final _location = TextEditingController();
  final _notes = TextEditingController();
  late final String _recordId;
  late final String _eventId;
  late DateTime _date;
  late TimeOfDay _time;
  List<MobileProject> _projects = const [];
  List<MobileProjectLocation> _locations = const [];
  String? _projectId;
  String? _locationId;
  AgendaCategory _category = AgendaCategory.generalNote;
  bool _loadingProjects = true;
  bool _loadingLocations = false;
  bool _submitting = false;
  String? _error;
  String? _locationError;
  int _locationLoadGeneration = 0;
  final List<(SelectedAttachment, String, String, String)> _pendingPhotos = [];

  @override
  void initState() {
    super.initState();
    _recordId = widget.existing?.id ?? RecordId.randomUuid();
    _eventId = RecordId.randomUuid();
    final current = widget.existing;
    final nowLocal = CseTimeCodec.toIstanbul(
      current?.observedAt ?? CseTimeCodec.encodeUtc(DateTime.now().toUtc()),
    );
    final initialDay = current == null
        ? DateTime.tryParse(widget.initialIstanbulDay ?? '')
        : null;
    _date = initialDay == null
        ? DateTime(nowLocal.year, nowLocal.month, nowLocal.day)
        : DateTime(initialDay.year, initialDay.month, initialDay.day);
    _time = TimeOfDay(hour: nowLocal.hour, minute: nowLocal.minute);
    _projectId = current?.projectId ?? widget.initialProjectId;
    _locationId = current?.locationId;
    if (current != null) {
      _category = current.category;
      _description.text = current.description;
      _location.text = current.location ?? '';
      _notes.text = current.notes ?? '';
    }
    _description.addListener(_onSignalInputChanged);
    _notes.addListener(_onSignalInputChanged);
    _loadProjects();
  }

  @override
  void dispose() {
    _description.removeListener(_onSignalInputChanged);
    _notes.removeListener(_onSignalInputChanged);
    _description.dispose();
    _location.dispose();
    _notes.dispose();
    super.dispose();
  }

  bool get _hasConcreteSignal => AgendaConcreteSignalDetector.hasSignal(
    description: _description.text,
    notes: _notes.text,
    category: _category,
  );

  String get _selectedIstanbulDay =>
      '${_date.year.toString().padLeft(4, '0')}-'
      '${_date.month.toString().padLeft(2, '0')}-'
      '${_date.day.toString().padLeft(2, '0')}';

  bool get _canOpenConcrete =>
      widget.concrete != null &&
      widget.concreteAttachments != null &&
      _projectId != null;

  void _onSignalInputChanged() {
    if (mounted) setState(() {});
  }

  void _selectConcreteCategory() {
    _categoryFieldKey.currentState?.didChange(AgendaCategory.concrete);
    setState(() => _category = AgendaCategory.concrete);
  }

  Future<void> _openConcrete() async {
    final concrete = widget.concrete;
    final attachments = widget.concreteAttachments;
    final projectId = _projectId;
    if (concrete == null || attachments == null || projectId == null) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ConcreteDestinationPage(
          concrete: concrete,
          agenda: widget.agenda,
          attachments: attachments,
          initialProjectId: projectId,
          initialIstanbulDay: _selectedIstanbulDay,
        ),
      ),
    );
  }

  Future<void> _loadProjects() async {
    try {
      final projects = await widget.agenda.listProjects();
      if (!mounted) return;
      setState(() {
        _projects = projects;
        _projectId ??= projects.isEmpty ? null : projects.first.id;
        _loadingProjects = false;
      });
      await _loadLocations();
    } on Object {
      if (!mounted) return;
      setState(() {
        _loadingProjects = false;
        _error = 'Projeler okunamadı.';
      });
    }
  }

  Future<void> _createProject() async {
    final projectId = RecordId.randomUuid();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => const OwnedTextInputDialog(
        title: 'Yeni proje',
        label: 'Proje adı',
        confirmLabel: 'Oluştur',
        inputKey: Key('new-project-name'),
        maxLength: 160,
      ),
    );
    if (name == null || !mounted) return;
    try {
      final project = await widget.agenda.createProject(
        CreateProjectCommand(id: projectId, name: name),
      );
      await _loadProjects();
      if (mounted) {
        setState(() => _projectId = project.id);
        await _loadLocations();
      }
    } on AgendaValidationFailure catch (error) {
      if (mounted) setState(() => _error = error.message);
    }
  }

  Future<void> _loadLocations() async {
    final application = widget.projectLocations;
    if (application == null) return;
    final projectId = _projectId;
    final generation = ++_locationLoadGeneration;
    setState(() {
      _loadingLocations = projectId != null;
      _locationError = null;
      if (projectId == null) _locations = const [];
    });
    if (projectId == null) return;
    try {
      final locations = await application.listProjectLocations(
        ProjectLocationQuery(projectId: projectId),
      );
      if (!mounted || generation != _locationLoadGeneration) return;
      final linkedExisting = widget.existing;
      final canKeepArchivedLink =
          _locationId != null &&
          linkedExisting?.locationId == _locationId &&
          linkedExisting?.projectId == projectId &&
          linkedExisting?.stableLocationName != null;
      final selectionIsActive = locations.any(
        (location) => location.id == _locationId,
      );
      setState(() {
        _locations = locations;
        if (!selectionIsActive && !canKeepArchivedLink) {
          _locationId = null;
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
    setState(() {
      _projectId = projectId;
      if (_locationId != null) {
        _locationId = null;
        _location.clear();
      }
    });
    await _loadLocations();
  }

  void _selectLocation(String? locationId) {
    setState(() {
      _locationId = locationId;
      if (locationId == null && widget.existing?.locationId != null) {
        _location.clear();
      }
    });
  }

  Future<void> _openLocationCatalog() async {
    final application = widget.projectLocations;
    final projectId = _projectId;
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

  Future<void> _submit() async {
    if (_submitting || !_formKey.currentState!.validate()) return;
    if (_projectId == null) {
      setState(() => _error = 'Önce bir proje oluşturup seçin.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final observedAt = CseTimeCodec.canonicalFromIstanbulComponents(
        year: _date.year,
        month: _date.month,
        day: _date.day,
        hour: _time.hour,
        minute: _time.minute,
      );
      final existing = widget.existing;
      final created = existing == null
          ? await widget.agenda.createAgendaLog(
              CreateAgendaLogCommand(
                id: _recordId,
                eventId: _eventId,
                projectId: _projectId!,
                observedAt: observedAt,
                category: _category,
                description: _description.text,
                location: _location.text,
                locationId: _locationId,
                notes: _notes.text,
                photos: _pendingPhotos
                    .map(
                      (item) => AgendaPhotoDraft(
                        id: item.$2,
                        eventId: item.$3,
                        originalFileName: item.$1.name,
                        bytes: item.$1.bytes,
                        capturedAt: item.$4,
                      ),
                    )
                    .toList(growable: false),
              ),
            )
          : await widget.agenda.updateAgendaLog(
              UpdateAgendaLogCommand(
                id: existing.id,
                eventId: _eventId,
                expectedRevision: existing.revision,
                projectId: _projectId!,
                observedAt: observedAt,
                category: _category,
                description: _description.text,
                location: _location.text,
                locationId: _locationId,
                notes: _notes.text,
              ),
            );
      if (!mounted) return;
      Navigator.pop(context, CseTimeCodec.istanbulDayKey(created.observedAt));
    } on AgendaValidationFailure catch (error) {
      if (mounted) setState(() => _error = error.message);
    } on TimeContractViolation {
      if (mounted) setState(() => _error = 'Olay tarih/saat değeri geçersiz.');
    } on Object {
      if (mounted) {
        setState(() => _error = 'Log güvenli biçimde kaydedilemedi.');
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _pickPhoto() async {
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
    final result = await picker.pick(source);
    if (!mounted) return;
    if (result.$1 != AttachmentPickOutcome.selected || result.$2 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Fotoğraf eklenmedi; form girdileri ve log kaydı korundu.',
          ),
        ),
      );
      return;
    }
    setState(() {
      _pendingPhotos.add((
        result.$2!,
        RecordId.randomUuid(),
        RecordId.randomUuid(),
        CseTimeCodec.encodeUtc(DateTime.now().toUtc()),
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existing == null
              ? 'Yeni Ajanda logu'
              : 'Ajanda logunu düzenle',
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_error != null)
              Card(
                color: Theme.of(context).colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(_error!, key: const Key('log-form-error')),
                ),
              ),
            if (_loadingProjects)
              const LinearProgressIndicator()
            else ...[
              DropdownButtonFormField<String>(
                key: const Key('log-project'),
                initialValue: _projectId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Proje',
                  border: OutlineInputBorder(),
                ),
                items: _projects
                    .map(
                      (project) => DropdownMenuItem(
                        value: project.id,
                        child: Text(
                          project.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: _selectProject,
                validator: (value) =>
                    value == null ? 'Proje zorunludur.' : null,
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  key: const Key('create-project'),
                  onPressed: _createProject,
                  icon: const Icon(Icons.add_business_outlined),
                  label: const Text('Yeni proje oluştur'),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  key: const Key('log-date'),
                  onPressed: () async {
                    final value = await showDatePicker(
                      context: context,
                      initialDate: _date,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (value != null) {
                      setState(() => _date = value);
                    }
                  },
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text(
                    '${_date.day.toString().padLeft(2, '0')}.'
                    '${_date.month.toString().padLeft(2, '0')}.${_date.year}',
                  ),
                ),
                OutlinedButton.icon(
                  key: const Key('log-time'),
                  onPressed: () async {
                    final value = await showTimePicker(
                      context: context,
                      initialTime: _time,
                    );
                    if (value != null) setState(() => _time = value);
                  },
                  icon: const Icon(Icons.schedule),
                  label: Text(_time.format(context)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            KeyedSubtree(
              key: const Key('log-category'),
              child: DropdownButtonFormField<AgendaCategory>(
                key: _categoryFieldKey,
                initialValue: _category,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Kayıt türü',
                  border: OutlineInputBorder(),
                ),
                items: AgendaCategory.values
                    .map(
                      (category) => DropdownMenuItem(
                        value: category,
                        child: Text(category.label),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _category = value!),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('log-description'),
              controller: _description,
              maxLength: 500,
              minLines: 2,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Kısa açıklama',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Kısa açıklama zorunludur.'
                  : null,
            ),
            if (widget.existing == null && widget.attachments != null) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                key: const Key('log-add-photo'),
                onPressed: _submitting ? null : _pickPhoto,
                icon: const Icon(Icons.add_a_photo_outlined),
                label: const Text('Fotoğraf ekle'),
              ),
              for (var index = 0; index < _pendingPhotos.length; index += 1)
                ListTile(
                  key: Key('pending-log-photo-$index'),
                  leading: const Icon(Icons.photo_outlined),
                  title: Text(_pendingPhotos[index].$1.name),
                  subtitle: const Text('Log kaydıyla birlikte eklenecek'),
                  trailing: IconButton(
                    tooltip: 'Seçimden kaldır',
                    onPressed: () =>
                        setState(() => _pendingPhotos.removeAt(index)),
                    icon: const Icon(Icons.close),
                  ),
                ),
            ],
            if (widget.projectLocations == null)
              TextFormField(
                key: const Key('log-location'),
                controller: _location,
                maxLength: 200,
                decoration: const InputDecoration(
                  labelText: 'Mahal (opsiyonel)',
                  border: OutlineInputBorder(),
                ),
              )
            else
              _buildStableLocationField(),
            const SizedBox(height: 8),
            TextFormField(
              key: const Key('log-notes'),
              controller: _notes,
              maxLength: 4000,
              minLines: 3,
              maxLines: 8,
              decoration: const InputDecoration(
                labelText: 'Ayrıntılı not (opsiyonel)',
                border: OutlineInputBorder(),
              ),
            ),
            if (widget.existing == null && _hasConcreteSignal) ...[
              const SizedBox(height: 12),
              AgendaConcreteSuggestionCard(
                key: const Key('agenda-concrete-form-suggestion'),
                message: 'Bu kayıt Beton işiyle ilgili görünüyor.',
                onSelectConcreteCategory: _category == AgendaCategory.concrete
                    ? null
                    : _selectConcreteCategory,
                onOpenConcrete: _canOpenConcrete ? _openConcrete : null,
                selectCategoryKey: const Key('agenda-concrete-select-category'),
                openConcreteKey: const Key('agenda-concrete-form-open'),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                key: const Key('submit-log'),
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(
                  _submitting
                      ? 'Kaydediliyor…'
                      : widget.existing == null
                      ? 'Logu kaydet'
                      : 'Değişiklikleri kaydet',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStableLocationField() {
    final options = _buildLocationOptions(_locations);
    final existing = widget.existing;
    final hasActiveSelection = options.any(
      (option) => option.id == _locationId,
    );
    if (_locationId != null &&
        !hasActiveSelection &&
        existing?.locationId == _locationId &&
        existing?.stableLocationName != null) {
      options.add(
        _LocationOption(
          id: _locationId!,
          label: '${existing!.stableLocationName!} (Arşivli)',
          archived: true,
        ),
      );
    }
    final legacyLocation = existing?.locationId == null
        ? existing?.location?.trim()
        : null;
    final selectedArchived = options.any(
      (option) => option.id == _locationId && option.archived,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_loadingLocations) const LinearProgressIndicator(),
        KeyedSubtree(
          key: ValueKey(
            'stable-location-${_projectId ?? 'none'}-'
            '${_locationId ?? 'none'}-${options.length}',
          ),
          child: DropdownButtonFormField<String>(
            key: const Key('log-location-selector'),
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
                (option) => DropdownMenuItem<String>(
                  value: option.id,
                  child: Text(option.label, overflow: TextOverflow.ellipsis),
                ),
              ),
            ],
            onChanged: _loadingLocations ? null : _selectLocation,
          ),
        ),
        if (!_loadingLocations &&
            options.where((item) => !item.archived).isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text(
              'Bu projede aktif mahal yok. Mahal Kataloğu’ndan ekleyebilirsiniz.',
              key: Key('log-location-empty'),
            ),
          ),
        if (_locationError != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _locationError!,
                    key: const Key('log-location-load-error'),
                  ),
                ),
                TextButton(
                  key: const Key('retry-log-locations'),
                  onPressed: _loadLocations,
                  child: const Text('Yeniden dene'),
                ),
              ],
            ),
          ),
        if (legacyLocation != null && legacyLocation.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'Eski serbest mahal: $legacyLocation',
              key: const Key('legacy-location-context'),
            ),
          ),
        if (selectedArchived)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text(
              'Arşivli mahal bağlantısı korunuyor.',
              key: Key('archived-location-context'),
            ),
          ),
        const SizedBox(height: 8),
        SizedBox(
          height: 48,
          child: OutlinedButton.icon(
            key: const Key('open-location-catalog-from-log'),
            onPressed: _projectId == null ? null : _openLocationCatalog,
            icon: const Icon(Icons.account_tree_outlined),
            label: const Text('Mahal Kataloğu'),
          ),
        ),
      ],
    );
  }
}

class _LocationOption {
  const _LocationOption({
    required this.id,
    required this.label,
    this.archived = false,
  });

  final String id;
  final String label;
  final bool archived;
}

List<_LocationOption> _buildLocationOptions(
  List<MobileProjectLocation> locations,
) {
  final byId = {for (final location in locations) location.id: location};
  final cache = <String, String>{};

  String pathFor(MobileProjectLocation location, Set<String> visiting) {
    final cached = cache[location.id];
    if (cached != null) return cached;
    if (!visiting.add(location.id)) return location.displayName;
    final parent = location.parentLocationId == null
        ? null
        : byId[location.parentLocationId];
    final path = parent == null
        ? location.displayName
        : '${pathFor(parent, visiting)} › ${location.displayName}';
    visiting.remove(location.id);
    cache[location.id] = path;
    return path;
  }

  return locations
      .map(
        (location) => _LocationOption(
          id: location.id,
          label: pathFor(location, <String>{}),
        ),
      )
      .toList(growable: true);
}
