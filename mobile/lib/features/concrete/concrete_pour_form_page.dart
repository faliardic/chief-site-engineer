import 'package:chief_site_engineer/application/agenda_application.dart';
import 'package:chief_site_engineer/application/concrete_application.dart';
import 'package:chief_site_engineer/core/record_id.dart';
import 'package:chief_site_engineer/core/time/cse_time_codec.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/domain/concrete_models.dart';
import 'package:chief_site_engineer/domain/project_location_models.dart';
import 'package:chief_site_engineer/features/owned_text_input_dialog.dart';
import 'package:chief_site_engineer/features/agenda/project_location_catalog_page.dart';
import 'package:flutter/material.dart';

class ConcretePourFormPage extends StatefulWidget {
  const ConcretePourFormPage({
    required this.concrete,
    this.projects = const [],
    this.projectLocations,
    this.initialProject,
    this.initialPour,
    super.key,
  }) : assert(initialPour != null || projects.length > 0);

  final ConcreteApplication concrete;
  final List<MobileProject> projects;
  final ProjectLocationApplication? projectLocations;
  final MobileProject? initialProject;
  final ConcretePour? initialPour;

  @override
  State<ConcretePourFormPage> createState() => _ConcretePourFormPageState();
}

class _ConcretePourFormPageState extends State<ConcretePourFormPage> {
  final _form = GlobalKey<FormState>();
  final _code = TextEditingController();
  final _location = TextEditingController();
  final _volume = TextEditingController();
  final _orderedVolume = TextEditingController();
  final _block = TextEditingController();
  final _floor = TextEditingController();
  final _axis = TextEditingController();
  final _plant = TextEditingController();
  final _plantBranch = TextEditingController();
  final _plantContact = TextEditingController();
  final _slump = TextEditingController();
  final _plantReference = TextEditingController();
  final _laboratory = TextEditingController();
  final _laboratoryContact = TextEditingController();
  final _pump = TextEditingController();
  final _inspectionPerson = TextEditingController();
  final _note = TextEditingController();
  final _sampleException = TextEditingController();
  final _varianceNote = TextEditingController();
  late final String _id = RecordId.randomUuid();
  late final String _eventId = RecordId.randomUuid();
  MobileProject? _project;
  late DateTime _planned;
  DateTime? _laboratoryAppointment;
  DateTime? _inspectionNotifiedAt;
  List<ProjectConcreteClass> _classes = const [];
  List<MobileProjectLocation> _locations = const [];
  String? _locationId;
  bool _loadingLocations = false;
  String? _locationError;
  ProjectConcreteClass? _selectedClass;
  bool _loadingClasses = true;
  bool _saving = false;
  String? _error;

  bool get _isEditing => widget.initialPour != null;
  String get _projectId => widget.initialPour?.projectId ?? _project!.id;

  @override
  void initState() {
    super.initState();
    final pour = widget.initialPour;
    _project = widget.initialProject;
    if (_project == null && pour != null) {
      for (final project in widget.projects) {
        if (project.id == pour.projectId) {
          _project = project;
          break;
        }
      }
    }
    if (pour == null) {
      _project ??= widget.projects.first;
      _planned = DateTime.now().add(const Duration(hours: 1));
      _loadClasses();
    } else {
      _planned = CseTimeCodec.toIstanbul(pour.plannedAt);
      _laboratoryAppointment = _toIstanbulOptional(pour.laboratoryAppointment);
      _inspectionNotifiedAt = _toIstanbulOptional(pour.inspectionNotifiedAt);
      _code.text = pour.pourCode;
      _location.text = pour.elementLocation;
      _locationId = pour.locationId;
      _volume.text = _decimalText(pour.plannedVolumeM3);
      _orderedVolume.text = _decimalText(pour.orderedVolumeM3);
      _block.text = pour.blockName ?? '';
      _floor.text = pour.floorName ?? '';
      _axis.text = pour.axisName ?? '';
      _plant.text = pour.plantName ?? '';
      _plantBranch.text = pour.plantBranch ?? '';
      _plantContact.text = pour.plantContact ?? '';
      _slump.text = pour.targetSlump ?? '';
      _plantReference.text = pour.plantAppointmentReference ?? '';
      _laboratory.text = pour.laboratoryName ?? '';
      _laboratoryContact.text = pour.laboratoryContact ?? '';
      _pump.text = pour.pumpEquipment ?? '';
      _inspectionPerson.text = pour.inspectionNotifiedPerson ?? '';
      _note.text = pour.generalNote ?? '';
      _sampleException.text = pour.sampleExceptionReason ?? '';
      _varianceNote.text = pour.varianceNote ?? '';
      _loadingClasses = false;
    }
    _loadLocations();
  }

  @override
  void dispose() {
    for (final controller in [
      _code,
      _location,
      _volume,
      _orderedVolume,
      _block,
      _floor,
      _axis,
      _plant,
      _plantBranch,
      _plantContact,
      _slump,
      _plantReference,
      _laboratory,
      _laboratoryContact,
      _pump,
      _inspectionPerson,
      _note,
      _sampleException,
      _varianceNote,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadClasses() async {
    setState(() => _loadingClasses = true);
    try {
      final values = await widget.concrete.listConcreteClasses(_projectId);
      if (!mounted) return;
      setState(() {
        _classes = values;
        if (_selectedClass?.projectId != _projectId ||
            !values.any((item) => item.id == _selectedClass?.id)) {
          _selectedClass = null;
        }
        _loadingClasses = false;
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingClasses = false;
        _error = error is AgendaValidationFailure
            ? error.message
            : 'Beton sınıfları yüklenemedi.';
      });
    }
  }

  Future<void> _changeProject(MobileProject value) async {
    setState(() {
      _project = value;
      _selectedClass = null;
      _classes = const [];
      _locations = const [];
      _locationId = null;
    });
    await Future.wait([_loadClasses(), _loadLocations()]);
  }

  Future<void> _loadLocations() async {
    final application = widget.projectLocations;
    if (application == null) return;
    setState(() {
      _loadingLocations = true;
      _locationError = null;
    });
    try {
      final values = await application.listProjectLocations(
        ProjectLocationQuery(projectId: _projectId),
      );
      if (!mounted) return;
      setState(() {
        _locations = values;
        if (!_isEditing && !values.any((item) => item.id == _locationId)) {
          _locationId = null;
        }
        _loadingLocations = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _locations = const [];
        _loadingLocations = false;
        _locationError = 'Mahaller güvenli biçimde okunamadı.';
      });
    }
  }

  Future<void> _openLocationCatalog() async {
    final application = widget.projectLocations;
    if (application == null) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ProjectLocationCatalogPage(
          application: application,
          initialProjectId: _projectId,
        ),
      ),
    );
    if (mounted) await _loadLocations();
  }

  Future<void> _addClass() async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) => const OwnedTextInputDialog(
        title: 'Yeni Beton sınıfı',
        label: 'Sınıf adı',
        confirmLabel: 'Ekle',
        inputKey: Key('new-concrete-class-name'),
        confirmKey: Key('save-concrete-class'),
      ),
    );
    if (name == null) return;
    try {
      final value = await widget.concrete.createConcreteClass(
        CreateProjectConcreteClassCommand(
          id: RecordId.randomUuid(),
          eventId: RecordId.randomUuid(),
          projectId: _projectId,
          displayName: name,
        ),
      );
      if (!mounted) return;
      setState(() {
        _classes = [..._classes, value]
          ..sort(
            (left, right) =>
                left.normalizedName.compareTo(right.normalizedName),
          );
        _selectedClass = value;
        _slump.text = value.defaultTargetSlump ?? '';
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(
        () => _error = error is AgendaValidationFailure
            ? error.message
            : 'Beton sınıfı eklenemedi.',
      );
    }
  }

  Future<void> _pickPlanned() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _planned,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_planned),
    );
    if (time == null) return;
    setState(
      () => _planned = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      ),
    );
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    final selectedClass = _selectedClass;
    if (!_isEditing && selectedClass == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final canonical = CseTimeCodec.canonicalFromIstanbulComponents(
        year: _planned.year,
        month: _planned.month,
        day: _planned.day,
        hour: _planned.hour,
        minute: _planned.minute,
        second: _planned.second,
      );
      if (_isEditing) {
        final pour = widget.initialPour!;
        final detail = await widget.concrete.updatePour(
          UpdateConcretePourCommand(
            id: pour.id,
            eventId: _eventId,
            expectedRevision: pour.revision,
            elementLocation: _location.text,
            locationId: _locationId,
            plannedAt: canonical,
            concreteClass: pour.concreteClass,
            plannedVolumeM3: double.parse(_volume.text.replaceAll(',', '.')),
            orderedVolumeM3: _optionalDecimal(_orderedVolume.text),
            blockName: _block.text,
            floorName: _floor.text,
            axisName: _axis.text,
            targetSlump: _slump.text,
            plantName: _plant.text,
            plantBranch: _plantBranch.text,
            plantContact: _plantContact.text,
            plantAppointmentReference: _plantReference.text,
            pumpEquipment: _pump.text,
            laboratoryName: _laboratory.text,
            laboratoryContact: _laboratoryContact.text,
            laboratoryAppointment: _canonicalOptional(_laboratoryAppointment),
            inspectionNotifiedAt: _canonicalOptional(_inspectionNotifiedAt),
            inspectionNotifiedPerson: _inspectionPerson.text,
            generalNote: _note.text,
            sampleExceptionReason: _sampleException.text,
            varianceNote: _varianceNote.text,
          ),
        );
        if (mounted) Navigator.of(context).pop(detail);
      } else {
        await widget.concrete.createPour(
          CreateConcretePourCommand(
            id: _id,
            eventId: _eventId,
            projectId: _projectId,
            pourCode: _code.text.trim().isEmpty
                ? 'DOKUM-${_id.substring(0, 8).toUpperCase()}'
                : _code.text,
            elementLocation: _location.text,
            locationId: _locationId,
            plannedAt: canonical,
            concreteClassId: selectedClass!.id,
            plannedVolumeM3: double.parse(_volume.text.replaceAll(',', '.')),
            blockName: _block.text,
            floorName: _floor.text,
            axisName: _axis.text,
            plantName: _plant.text,
            targetSlump: _slump.text,
            plantAppointmentReference: _plantReference.text,
            laboratoryName: _laboratory.text,
            laboratoryAppointment: _canonicalOptional(_laboratoryAppointment),
            pumpEquipment: _pump.text,
            inspectionNotifiedAt: _canonicalOptional(_inspectionNotifiedAt),
            inspectionNotifiedPerson: _inspectionPerson.text,
            generalNote: _note.text,
          ),
        );
        if (mounted) Navigator.of(context).pop(_id);
      }
    } on Object catch (error) {
      if (mounted) {
        setState(
          () => _error = error is AgendaValidationFailure
              ? error.message
              : _isEditing
              ? 'Beton paketi güncellenemedi.'
              : 'Beton paketi oluşturulamadı.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Beton paketini düzenle' : 'Yeni Beton paketi',
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_isEditing)
                _readOnlyField(
                  'Proje',
                  widget.initialPour!.projectName,
                  key: const Key('concrete-project-read-only'),
                )
              else
                DropdownButtonFormField<MobileProject>(
                  initialValue: _project,
                  decoration: const InputDecoration(
                    labelText: 'Proje',
                    border: OutlineInputBorder(),
                  ),
                  items: widget.projects
                      .map(
                        (item) => DropdownMenuItem(
                          value: item,
                          child: Text(item.name),
                        ),
                      )
                      .toList(),
                  onChanged: _saving
                      ? null
                      : (value) {
                          if (value != null) _changeProject(value);
                        },
                ),
              const SizedBox(height: 12),
              _field(
                _code,
                _isEditing
                    ? 'Döküm kodu'
                    : 'Döküm kodu (boşsa otomatik üretilir)',
                key: const Key('concrete-pour-code'),
                readOnly: _isEditing,
              ),
              _buildLocationSelector(),
              _field(_location, 'Eleman / yer tarifi', required: true),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Planlanan tarih/saat'),
                subtitle: Text(
                  '${_planned.day.toString().padLeft(2, '0')}.${_planned.month.toString().padLeft(2, '0')}.${_planned.year} ${_planned.hour.toString().padLeft(2, '0')}:${_planned.minute.toString().padLeft(2, '0')}',
                ),
                trailing: const Icon(Icons.edit_calendar_outlined),
                onTap: _saving ? null : _pickPlanned,
              ),
              if (_isEditing)
                _readOnlyField(
                  'Beton sınıfı',
                  widget.initialPour!.concreteClass,
                  key: const Key('concrete-class-read-only'),
                )
              else ...[
                DropdownButtonFormField<ProjectConcreteClass>(
                  key: const Key('concrete-class-selector'),
                  initialValue: _selectedClass,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Beton sınıfı',
                    border: const OutlineInputBorder(),
                    suffixIcon: _loadingClasses
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : null,
                  ),
                  items: _classes
                      .map(
                        (item) => DropdownMenuItem(
                          value: item,
                          child: Text(
                            item.displayName,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: _saving || _loadingClasses
                      ? null
                      : (value) => setState(() {
                          _selectedClass = value;
                          _slump.text = value?.defaultTargetSlump ?? '';
                        }),
                  validator: (value) =>
                      value == null ? 'Beton sınıfı zorunludur.' : null,
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    key: const Key('add-concrete-class'),
                    onPressed: _saving ? null : _addClass,
                    icon: const Icon(Icons.add),
                    label: const Text('Yeni sınıf ekle'),
                  ),
                ),
              ],
              _field(
                _volume,
                'Planlanan metraj (m³)',
                required: true,
                decimal: true,
              ),
              if (_isEditing)
                _field(_orderedVolume, 'Sipariş metrajı (m³)', decimal: true),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: const Text('İsteğe bağlı planlama bilgileri'),
                children: [
                  _field(_block, 'Blok'),
                  _field(_floor, 'Kat'),
                  _field(_axis, 'Aks'),
                  _field(_slump, 'Hedef kıvam / slump'),
                  _field(_plant, 'Santral'),
                  if (_isEditing) _field(_plantBranch, 'Santral şubesi'),
                  if (_isEditing) _field(_plantContact, 'Santral iletişim'),
                  _field(_plantReference, 'Santral randevu referansı'),
                  _field(_laboratory, 'Laboratuvar'),
                  if (_isEditing)
                    _field(_laboratoryContact, 'Laboratuvar iletişim'),
                  _optionalDateTile(
                    'Laboratuvar randevu zamanı',
                    _laboratoryAppointment,
                    (value) => _laboratoryAppointment = value,
                  ),
                  _field(_pump, 'Pompa / ekipman'),
                  _field(
                    _inspectionPerson,
                    'Yapı denetimde haber verilen kişi',
                  ),
                  _optionalDateTile(
                    'Yapı denetim bildirim zamanı',
                    _inspectionNotifiedAt,
                    (value) => _inspectionNotifiedAt = value,
                  ),
                  _field(_note, 'Genel not', lines: 3),
                  if (_isEditing)
                    _field(_sampleException, 'Numune istisna nedeni', lines: 2),
                  if (_isEditing) _field(_varianceNote, 'Sapma notu', lines: 2),
                ],
              ),
              if (_error case final error?)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    error,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(
                  _isEditing
                      ? 'Beton paketini kaydet'
                      : 'Beton paketini oluştur',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationSelector() => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_loadingLocations) const LinearProgressIndicator(),
        DropdownButtonFormField<String>(
          key: const Key('concrete-location-selector'),
          initialValue: _locationId,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Katalog Mahali (opsiyonel)',
            border: OutlineInputBorder(),
          ),
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Text('Mahal seçilmedi'),
            ),
            if (_isEditing &&
                _locationId != null &&
                !_locations.any((item) => item.id == _locationId))
              DropdownMenuItem<String>(
                value: _locationId,
                child: Text(
                  '${widget.initialPour!.stableLocationName ?? 'Kayıtlı mahal'}'
                  '${widget.initialPour!.stableLocationArchivedAt == null ? '' : ' (Arşivli)'}',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ..._concreteLocationOptions(_locations).map(
              (item) => DropdownMenuItem<String>(
                value: item.$1,
                child: Text(item.$2, overflow: TextOverflow.ellipsis),
              ),
            ),
          ],
          onChanged: _loadingLocations
              ? null
              : (value) => setState(() => _locationId = value),
        ),
        if (!_loadingLocations && _locations.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text(
              'Bu projede aktif mahal yok.',
              key: Key('concrete-location-empty'),
            ),
          ),
        if (_locationError != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              _locationError!,
              key: const Key('concrete-location-load-error'),
            ),
          ),
        TextButton.icon(
          key: const Key('open-location-catalog-from-concrete'),
          onPressed: widget.projectLocations == null
              ? null
              : _openLocationCatalog,
          icon: const Icon(Icons.account_tree_outlined),
          label: const Text('Mahal Kataloğu'),
        ),
      ],
    ),
  );

  Widget _field(
    TextEditingController controller,
    String label, {
    Key? key,
    bool required = false,
    bool decimal = false,
    bool readOnly = false,
    int lines = 1,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      key: key,
      controller: controller,
      maxLines: lines,
      readOnly: readOnly,
      keyboardType: decimal
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        if (required && (value == null || value.trim().isEmpty)) {
          return '$label zorunludur.';
        }
        if (decimal &&
            (value ?? '').trim().isNotEmpty &&
            (double.tryParse((value ?? '').replaceAll(',', '.')) ?? 0) <= 0) {
          return 'Sıfırdan büyük bir metraj girin.';
        }
        return null;
      },
    ),
  );

  Widget _readOnlyField(String label, String value, {required Key key}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          key: key,
          initialValue: value,
          readOnly: true,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
        ),
      );

  Widget _optionalDateTile(
    String label,
    DateTime? value,
    void Function(DateTime?) assign,
  ) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(label),
    subtitle: Text(value == null ? 'Eklenmedi' : _localLabel(value)),
    trailing: value == null
        ? const Icon(Icons.add_alarm_outlined)
        : IconButton(
            tooltip: 'Zamanı kaldır',
            onPressed: () => setState(() => assign(null)),
            icon: const Icon(Icons.close),
          ),
    onTap: _saving
        ? null
        : () async {
            final initial = value ?? _planned;
            final date = await showDatePicker(
              context: context,
              initialDate: initial,
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (date == null || !mounted) return;
            final time = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.fromDateTime(initial),
            );
            if (time == null) return;
            setState(
              () => assign(
                DateTime(
                  date.year,
                  date.month,
                  date.day,
                  time.hour,
                  time.minute,
                ),
              ),
            );
          },
  );

  String? _canonicalOptional(DateTime? value) => value == null
      ? null
      : CseTimeCodec.canonicalFromIstanbulComponents(
          year: value.year,
          month: value.month,
          day: value.day,
          hour: value.hour,
          minute: value.minute,
          second: value.second,
        );

  DateTime? _toIstanbulOptional(String? value) =>
      value == null ? null : CseTimeCodec.toIstanbul(value);

  double? _optionalDecimal(String value) {
    final normalized = value.trim();
    return normalized.isEmpty
        ? null
        : double.parse(normalized.replaceAll(',', '.'));
  }

  String _decimalText(double? value) => value == null ? '' : value.toString();

  String _localLabel(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}.'
      '${value.month.toString().padLeft(2, '0')}.${value.year} '
      '${value.hour.toString().padLeft(2, '0')}:'
      '${value.minute.toString().padLeft(2, '0')}';
}

List<(String, String)> _concreteLocationOptions(
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
      .map((item) => (item.id, pathFor(item, <String>{})))
      .toList(growable: false);
}
