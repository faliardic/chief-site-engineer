import 'dart:async';

import 'package:chief_site_engineer/application/agenda_application.dart';
import 'package:chief_site_engineer/application/context_suggestion_application.dart';
import 'package:chief_site_engineer/core/record_id.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/domain/context_suggestion_models.dart';
import 'package:chief_site_engineer/domain/project_location_models.dart';
import 'package:flutter/material.dart';

class PhoneCallResultPage extends StatefulWidget {
  const PhoneCallResultPage({
    required this.agenda,
    this.contextSuggestions,
    this.projectLocations,
    this.initialProjectId,
    this.onProjectSelected,
    super.key,
  });

  final AgendaApplication agenda;
  final ContextSuggestionApplication? contextSuggestions;
  final ProjectLocationApplication? projectLocations;
  final String? initialProjectId;
  final ValueChanged<String>? onProjectSelected;

  @override
  State<PhoneCallResultPage> createState() => _PhoneCallResultPageState();
}

class _PhoneCallResultPageState extends State<PhoneCallResultPage> {
  final _formKey = GlobalKey<FormState>();
  final _party = TextEditingController();
  final _result = TextEditingController();
  final _notes = TextEditingController();
  late final String _logId;
  late final String _eventId;
  StreamSubscription<void>? _projectSubscription;
  Timer? _suggestionDebounce;
  List<MobileProject> _projects = const [];
  List<MobileProjectLocation> _locations = const [];
  List<ContextSuggestion> _suggestions = const [];
  ContextSuggestion? _selectedSuggestion;
  String? _projectIdToValidate;
  String? _projectId;
  String? _locationId;
  String? _projectError;
  String? _locationError;
  String? _error;
  bool _loadingProjects = true;
  bool _loadingLocations = false;
  bool _suggestionsUnavailable = false;
  bool _submitting = false;
  bool _settingPartyFromSuggestion = false;
  int _projectLoadGeneration = 0;
  int _locationLoadGeneration = 0;
  int _suggestionLoadGeneration = 0;

  @override
  void initState() {
    super.initState();
    _logId = RecordId.randomUuid();
    _eventId = RecordId.randomUuid();
    _projectIdToValidate = widget.initialProjectId;
    _party.addListener(_partyChanged);
    _projectSubscription = widget.agenda.projectChanges.listen(
      (_) => _loadProjects(),
    );
    _loadProjects();
  }

  @override
  void dispose() {
    _projectSubscription?.cancel();
    _suggestionDebounce?.cancel();
    _party
      ..removeListener(_partyChanged)
      ..dispose();
    _result.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _loadProjects() async {
    final generation = ++_projectLoadGeneration;
    final projectIdToValidate = _projectIdToValidate;
    if (mounted) {
      setState(() {
        _loadingProjects = true;
        _projectError = null;
      });
    }
    try {
      final projects = (await widget.agenda.listProjects())
          .where((project) => !project.isArchived)
          .toList(growable: false);
      if (!mounted || generation != _projectLoadGeneration) return;
      final selected =
          projects.any((project) => project.id == projectIdToValidate)
          ? projectIdToValidate
          : widget.initialProjectId == null && projects.isNotEmpty
          ? projects.first.id
          : null;
      final projectChanged = selected != _projectId;
      if (projectChanged) {
        _invalidateProjectBoundState();
        _setPartyText('');
      }
      setState(() {
        _projects = projects;
        _projectId = selected;
        if (selected != null) _projectIdToValidate = selected;
        _loadingProjects = false;
        if (projectChanged) {
          _locationId = null;
          _selectedSuggestion = null;
          _suggestions = const [];
          _suggestionsUnavailable = false;
        }
      });
      await _loadLocations();
      _scheduleSuggestionLoad();
    } on Object {
      if (!mounted || generation != _projectLoadGeneration) return;
      _invalidateProjectBoundState();
      setState(() {
        _projects = const [];
        _projectId = null;
        _locations = const [];
        _locationId = null;
        _selectedSuggestion = null;
        _suggestions = const [];
        _suggestionsUnavailable = false;
        _setPartyText('');
        _loadingProjects = false;
        _projectError = 'Projeler güvenli biçimde okunamadı.';
      });
    }
  }

  Future<void> _selectProject(String? projectId) async {
    if (projectId == null ||
        projectId == _projectId ||
        !_projects.any((project) => project.id == projectId)) {
      return;
    }
    _invalidateProjectBoundState();
    setState(() {
      _projectIdToValidate = projectId;
      _projectId = projectId;
      _locationId = null;
      _locations = const [];
      _selectedSuggestion = null;
      _suggestions = const [];
      _suggestionsUnavailable = false;
      _setPartyText('');
    });
    widget.onProjectSelected?.call(projectId);
    await _loadLocations();
    _scheduleSuggestionLoad();
  }

  void _invalidateProjectBoundState() {
    _suggestionDebounce?.cancel();
    _suggestionLoadGeneration += 1;
    _locationLoadGeneration += 1;
  }

  Future<void> _loadLocations() async {
    final application = widget.projectLocations;
    final projectId = _projectId;
    final generation = ++_locationLoadGeneration;
    if (application == null || projectId == null) {
      if (mounted) {
        setState(() {
          _locations = const [];
          _locationId = null;
          _loadingLocations = false;
          _locationError = null;
        });
      }
      return;
    }
    setState(() {
      _loadingLocations = true;
      _locationError = null;
    });
    try {
      final locations = await application.listProjectLocations(
        ProjectLocationQuery(projectId: projectId),
      );
      if (!mounted ||
          generation != _locationLoadGeneration ||
          projectId != _projectId) {
        return;
      }
      setState(() {
        _locations = locations;
        if (!locations.any((location) => location.id == _locationId)) {
          _locationId = null;
        }
        _loadingLocations = false;
      });
    } on Object {
      if (!mounted ||
          generation != _locationLoadGeneration ||
          projectId != _projectId) {
        return;
      }
      setState(() {
        _locations = const [];
        _locationId = null;
        _loadingLocations = false;
        _locationError =
            'Mahaller güvenli biçimde okunamadı; mahal seçmeden devam edebilirsiniz.';
      });
    }
  }

  void _partyChanged() {
    if (_settingPartyFromSuggestion) return;
    setState(() {
      _selectedSuggestion = null;
      _suggestions = const [];
      _suggestionsUnavailable = false;
    });
    _scheduleSuggestionLoad();
  }

  void _scheduleSuggestionLoad() {
    _suggestionDebounce?.cancel();
    final generation = ++_suggestionLoadGeneration;
    final application = widget.contextSuggestions;
    final projectId = _projectId;
    if (application == null || projectId == null) {
      if (mounted && (_suggestions.isNotEmpty || _suggestionsUnavailable)) {
        setState(() {
          _suggestions = const [];
          _suggestionsUnavailable = false;
        });
      }
      return;
    }
    final query = _party.text;
    _suggestionDebounce = Timer(const Duration(milliseconds: 200), () async {
      try {
        final suggestions = await application.suggestPeopleAndCompanies(
          ContextSuggestionQuery(projectId: projectId, query: query),
        );
        if (!mounted ||
            generation != _suggestionLoadGeneration ||
            projectId != _projectId) {
          return;
        }
        setState(() {
          _suggestions = suggestions;
          _suggestionsUnavailable = false;
        });
      } on Object {
        if (!mounted ||
            generation != _suggestionLoadGeneration ||
            projectId != _projectId) {
          return;
        }
        setState(() {
          _suggestions = const [];
          _suggestionsUnavailable = true;
        });
      }
    });
  }

  void _selectSuggestion(ContextSuggestion suggestion) {
    if (suggestion.projectId != _projectId) return;
    _selectedSuggestion =
        suggestion.sourceType ==
            ContextSuggestionSourceType.historicalRelatedPerson
        ? null
        : suggestion;
    _setPartyText(suggestion.displayValue);
    setState(() {
      _suggestions = const [];
      _suggestionsUnavailable = false;
    });
  }

  void _setPartyText(String value) {
    _settingPartyFromSuggestion = true;
    _party.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
    _settingPartyFromSuggestion = false;
  }

  Future<void> _submit() async {
    if (_submitting || !_formKey.currentState!.validate()) return;
    final AgendaPhoneCallCaptureApplication? capture =
        widget.agenda is AgendaPhoneCallCaptureApplication
        ? widget.agenda as AgendaPhoneCallCaptureApplication
        : null;
    if (capture == null) {
      setState(() {
        _error = 'Görüşme sonucu bu uygulama oturumunda kaydedilemiyor.';
      });
      return;
    }
    final projectId = _projectId;
    if (projectId == null) return;
    final selected = _selectedSuggestion;
    final partyText = _party.text.trim();
    final partyKind = partyText.isEmpty
        ? null
        : selected == null
        ? AgendaPhoneCallPartyKind.freeText
        : selected.kind == ContextSuggestionKind.person
        ? AgendaPhoneCallPartyKind.person
        : AgendaPhoneCallPartyKind.company;
    final partySourceId = selected?.sourceId;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final log = await capture.createPhoneCallAgendaLog(
        CreatePhoneCallAgendaLogCommand(
          id: _logId,
          eventId: _eventId,
          projectId: projectId,
          result: _result.text,
          locationId: _locationId,
          notes: _notes.text,
          partyKind: partyKind,
          partySourceId: partySourceId,
          partyDisplayText: partyText,
        ),
      );
      if (mounted) Navigator.pop(context, log.id);
    } on AgendaValidationFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    } on Object {
      if (mounted) {
        setState(() {
          _error = 'Görüşme sonucu güvenli biçimde kaydedilemedi.';
        });
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Görüşme sonucu')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_error case final error?)
              Card(
                color: Theme.of(context).colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(error, key: const Key('phone-call-result-error')),
                ),
              ),
            DropdownButtonFormField<String>(
              key: ValueKey('phone-call-project-${_projectId ?? 'none'}'),
              initialValue: _projectId,
              decoration: const InputDecoration(
                labelText: 'Proje',
                border: OutlineInputBorder(),
              ),
              items: _projects
                  .map(
                    (project) => DropdownMenuItem(
                      value: project.id,
                      child: Text(project.name),
                    ),
                  )
                  .toList(growable: false),
              onChanged: _loadingProjects || _submitting
                  ? null
                  : _selectProject,
              validator: (value) =>
                  value == null ? 'Proje seçimi zorunludur.' : null,
            ),
            if (_loadingProjects) const LinearProgressIndicator(),
            if (_projectError case final error?)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  error,
                  key: const Key('phone-call-project-error'),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            if (_projectError != null)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  key: const Key('phone-call-project-retry'),
                  onPressed: _loadingProjects ? null : _loadProjects,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Projeleri yeniden dene'),
                ),
              ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('phone-call-party'),
              controller: _party,
              enabled: _projectId != null && !_submitting,
              maxLength: 200,
              decoration: const InputDecoration(
                labelText: 'Görüşülen taraf (isteğe bağlı)',
                hintText: 'Kişi, firma veya serbest metin',
                border: OutlineInputBorder(),
              ),
            ),
            if (_selectedSuggestion case final selected?)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '${selected.kind == ContextSuggestionKind.person ? 'Kişi' : 'Firma'} kaydı seçildi.',
                  key: const Key('phone-call-canonical-party'),
                ),
              ),
            if (_suggestions.isNotEmpty)
              Wrap(
                key: const Key('phone-call-party-suggestions'),
                spacing: 8,
                runSpacing: 8,
                children: _suggestions
                    .map(
                      (suggestion) => ActionChip(
                        key: Key(
                          'phone-call-suggestion-'
                          '${suggestion.sourceId ?? suggestion.displayValue}',
                        ),
                        avatar: Icon(
                          suggestion.kind == ContextSuggestionKind.person
                              ? Icons.person_outline
                              : Icons.business_outlined,
                          size: 18,
                        ),
                        label: Text(suggestion.displayValue),
                        onPressed: _submitting
                            ? null
                            : () => _selectSuggestion(suggestion),
                      ),
                    )
                    .toList(growable: false),
              ),
            if (_suggestionsUnavailable)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  'Öneriler şu anda okunamadı; serbest metinle devam edebilirsiniz.',
                  key: Key('phone-call-suggestions-unavailable'),
                ),
              ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              key: ValueKey(
                'phone-call-location-${_projectId ?? 'none'}-'
                '${_locationId ?? 'none'}',
              ),
              initialValue: _locationId,
              decoration: const InputDecoration(
                labelText: 'Mahal (isteğe bağlı)',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(
                  value: '',
                  child: Text('Mahal seçilmedi'),
                ),
                ..._locations.map(
                  (location) => DropdownMenuItem(
                    value: location.id,
                    child: Text(location.displayName),
                  ),
                ),
              ],
              onChanged: _projectId == null || _loadingLocations || _submitting
                  ? null
                  : (value) => setState(
                      () => _locationId = value == null || value.isEmpty
                          ? null
                          : value,
                    ),
            ),
            if (_loadingLocations) const LinearProgressIndicator(),
            if (_locationError case final error?)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(error, key: const Key('phone-call-location-error')),
              ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('phone-call-result'),
              controller: _result,
              enabled: !_submitting,
              minLines: 3,
              maxLines: 7,
              maxLength: 500,
              decoration: const InputDecoration(
                labelText: 'Görüşme sonucu',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Görüşme sonucu zorunludur.'
                  : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              key: const Key('phone-call-notes'),
              controller: _notes,
              enabled: !_submitting,
              minLines: 2,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Not (isteğe bağlı)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              key: const Key('save-phone-call-result'),
              onPressed:
                  _submitting ||
                      _loadingProjects ||
                      _projectError != null ||
                      _projectId == null
                  ? null
                  : _submit,
              icon: const Icon(Icons.save_outlined),
              label: Text(_submitting ? 'Kaydediliyor…' : 'Kaydet'),
            ),
            const SizedBox(height: 12),
            const Text(
              'Hatırlatıcı gerekiyorsa kayıt detayından ayrıca oluşturulur.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
