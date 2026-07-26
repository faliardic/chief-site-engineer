import 'package:chief_site_engineer/application/concrete_application.dart';
import 'package:chief_site_engineer/core/record_id.dart';
import 'package:chief_site_engineer/core/time/cse_time_codec.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/domain/concrete_models.dart';
import 'package:chief_site_engineer/features/owned_text_input_dialog.dart';
import 'package:flutter/material.dart';

class ConcretePourFormPage extends StatefulWidget {
  const ConcretePourFormPage({
    required this.concrete,
    required this.projects,
    this.initialProject,
    super.key,
  });

  final ConcreteApplication concrete;
  final List<MobileProject> projects;
  final MobileProject? initialProject;

  @override
  State<ConcretePourFormPage> createState() => _ConcretePourFormPageState();
}

class _ConcretePourFormPageState extends State<ConcretePourFormPage> {
  final _form = GlobalKey<FormState>();
  final _code = TextEditingController();
  final _location = TextEditingController();
  final _volume = TextEditingController();
  final _block = TextEditingController();
  final _floor = TextEditingController();
  final _axis = TextEditingController();
  final _plant = TextEditingController();
  final _slump = TextEditingController();
  final _plantReference = TextEditingController();
  final _laboratory = TextEditingController();
  final _pump = TextEditingController();
  final _inspectionPerson = TextEditingController();
  final _note = TextEditingController();
  late final String _id = RecordId.randomUuid();
  late final String _eventId = RecordId.randomUuid();
  late MobileProject _project;
  late DateTime _planned;
  DateTime? _laboratoryAppointment;
  DateTime? _inspectionNotifiedAt;
  List<ProjectConcreteClass> _classes = const [];
  ProjectConcreteClass? _selectedClass;
  bool _loadingClasses = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _project = widget.initialProject ?? widget.projects.first;
    _planned = DateTime.now().add(const Duration(hours: 1));
    _loadClasses();
  }

  @override
  void dispose() {
    for (final controller in [
      _code,
      _location,
      _volume,
      _block,
      _floor,
      _axis,
      _plant,
      _slump,
      _plantReference,
      _laboratory,
      _pump,
      _inspectionPerson,
      _note,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadClasses() async {
    setState(() => _loadingClasses = true);
    try {
      final values = await widget.concrete.listConcreteClasses(_project.id);
      if (!mounted) return;
      setState(() {
        _classes = values;
        if (_selectedClass?.projectId != _project.id ||
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
    });
    await _loadClasses();
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
          projectId: _project.id,
          displayName: name,
        ),
      );
      if (!mounted) return;
      setState(() {
        _classes = [..._classes, value]
          ..sort((left, right) =>
              left.normalizedName.compareTo(right.normalizedName));
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
    if (selectedClass == null) return;
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
      );
      await widget.concrete.createPour(
        CreateConcretePourCommand(
          id: _id,
          eventId: _eventId,
          projectId: _project.id,
          pourCode: _code.text.trim().isEmpty
              ? 'DOKUM-${_id.substring(0, 8).toUpperCase()}'
              : _code.text,
          elementLocation: _location.text,
          plannedAt: canonical,
          concreteClassId: selectedClass.id,
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
    } on Object catch (error) {
      if (mounted) {
        setState(
          () => _error = error is AgendaValidationFailure
              ? error.message
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
      appBar: AppBar(title: const Text('Yeni Beton paketi')),
      body: SafeArea(
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              DropdownButtonFormField<MobileProject>(
                initialValue: _project,
                decoration: const InputDecoration(
                  labelText: 'Proje',
                  border: OutlineInputBorder(),
                ),
                items: widget.projects
                    .map(
                      (item) =>
                          DropdownMenuItem(value: item, child: Text(item.name)),
                    )
                    .toList(),
                onChanged: _saving
                    ? null
                    : (value) {
                        if (value != null) _changeProject(value);
                      },
              ),
              const SizedBox(height: 12),
              _field(_code, 'Döküm kodu (boşsa otomatik üretilir)'),
              _field(_location, 'Mahal / eleman', required: true),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Planlanan tarih/saat'),
                subtitle: Text(
                  '${_planned.day.toString().padLeft(2, '0')}.${_planned.month.toString().padLeft(2, '0')}.${_planned.year} ${_planned.hour.toString().padLeft(2, '0')}:${_planned.minute.toString().padLeft(2, '0')}',
                ),
                trailing: const Icon(Icons.edit_calendar_outlined),
                onTap: _saving ? null : _pickPlanned,
              ),
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
              _field(
                _volume,
                'Planlanan metraj (m³)',
                required: true,
                decimal: true,
              ),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: const Text('İsteğe bağlı planlama bilgileri'),
                children: [
                  _field(_block, 'Blok'),
                  _field(_floor, 'Kat'),
                  _field(_axis, 'Aks'),
                  _field(_slump, 'Hedef kıvam / slump'),
                  _field(_plant, 'Santral'),
                  _field(_plantReference, 'Santral randevu referansı'),
                  _field(_laboratory, 'Laboratuvar'),
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
                label: const Text('Beton paketini oluştur'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool required = false,
    bool decimal = false,
    int lines = 1,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller,
      maxLines: lines,
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
            (double.tryParse((value ?? '').replaceAll(',', '.')) ?? 0) <= 0) {
          return 'Sıfırdan büyük bir metraj girin.';
        }
        return null;
      },
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
        );

  String _localLabel(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}.'
      '${value.month.toString().padLeft(2, '0')}.${value.year} '
      '${value.hour.toString().padLeft(2, '0')}:'
      '${value.minute.toString().padLeft(2, '0')}';
}
