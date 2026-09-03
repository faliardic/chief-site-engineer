import 'dart:async';

import 'package:chief_site_engineer/application/material_request_application.dart';
import 'package:chief_site_engineer/core/record_id.dart';
import 'package:chief_site_engineer/core/time/cse_time_codec.dart';
import 'package:chief_site_engineer/domain/material_request_models.dart';
import 'package:flutter/material.dart';

class MaterialRequestsPage extends StatefulWidget {
  const MaterialRequestsPage({
    required this.application,
    this.initialProjectId,
    this.onProjectSelected,
    super.key,
  });

  final MaterialRequestApplicationPort application;
  final String? initialProjectId;
  final ValueChanged<String>? onProjectSelected;

  @override
  State<MaterialRequestsPage> createState() => _MaterialRequestsPageState();
}

class _MaterialRequestsPageState extends State<MaterialRequestsPage> {
  List<MaterialRequestProject> _projects = const [];
  List<MaterialRequest> _requests = const [];
  String? _projectIdToValidate;
  String? _projectId;
  MaterialRequestListKind _kind = MaterialRequestListKind.open;
  bool _loading = true;
  bool _projectDiscoveryFailed = false;
  String? _failure;

  @override
  void initState() {
    super.initState();
    _projectIdToValidate = widget.initialProjectId;
    unawaited(_loadProjects());
  }

  Future<void> _loadProjects() async {
    final projectIdToValidate = _projectIdToValidate;
    setState(() {
      _projects = const [];
      _requests = const [];
      _projectId = null;
      _loading = true;
      _projectDiscoveryFailed = false;
      _failure = null;
    });
    try {
      final projects = await widget.application.listProjects();
      final selected =
          projects.any((project) => project.id == projectIdToValidate)
          ? projectIdToValidate
          : widget.initialProjectId == null && projects.isNotEmpty
          ? projects.first.id
          : null;
      if (!mounted) return;
      setState(() {
        _projects = projects;
        _projectId = selected;
        if (selected != null) {
          _projectIdToValidate = selected;
        }
      });
      await _reload();
    } on MaterialRequestFailure catch (error) {
      if (!mounted) return;
      setState(() {
        _projects = const [];
        _requests = const [];
        _projectId = null;
        _loading = false;
        _projectDiscoveryFailed = true;
        _failure = error.code;
      });
    }
  }

  Future<void> _reload() async {
    final projectId = _projectId;
    if (projectId == null) {
      if (!mounted) return;
      setState(() {
        _requests = const [];
        _loading = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _failure = null;
    });
    try {
      final requests = await widget.application.listMaterialRequests(
        projectId: projectId,
        kind: _kind,
      );
      if (!mounted) return;
      setState(() {
        _requests = requests;
        _loading = false;
      });
    } on MaterialRequestFailure catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failure = error.code;
      });
    }
  }

  Future<void> _selectProject(String? value) async {
    if (value == null || value == _projectId) return;
    setState(() {
      _projectIdToValidate = value;
      _projectId = value;
    });
    widget.onProjectSelected?.call(value);
    await _reload();
  }

  Future<void> _changeKind(Set<MaterialRequestListKind> values) async {
    setState(() => _kind = values.single);
    await _reload();
  }

  Future<void> _openCreate() async {
    final projectId = _projectId;
    if (projectId == null) return;
    try {
      final locations = await widget.application.listLocations(projectId);
      final planItems = await widget.application.listLivingPlanItems(projectId);
      if (!mounted) return;
      final value = await showDialog<_CreateValue>(
        context: context,
        builder: (_) => _CreateMaterialRequestDialog(
          locations: locations,
          planItems: planItems,
        ),
      );
      if (value == null) return;
      await widget.application.createMaterialRequest(
        CreateMaterialRequestCommand(
          requestId: RecordId.randomUuid(),
          eventId: RecordId.randomUuid(),
          projectId: projectId,
          materialName: value.materialName,
          locationId: value.locationId,
          livingPlanItemId: value.livingPlanItemId,
          quantity: value.quantity,
          unit: value.unit,
          neededOn: value.neededOn,
          priority: value.priority,
          description: value.description,
        ),
      );
      await _reload();
    } on MaterialRequestFailure catch (error) {
      _showFailure(error);
    }
  }

  Future<void> _transition(
    MaterialRequest request,
    MaterialRequestStatus status,
  ) async {
    try {
      await widget.application.transitionMaterialRequest(
        TransitionMaterialRequestCommand(
          requestId: request.id,
          eventId: RecordId.randomUuid(),
          expectedRevision: request.revision,
          targetStatus: status,
        ),
      );
      await _reload();
    } on MaterialRequestFailure catch (error) {
      _showFailure(error);
    }
  }

  Future<void> _showDetail(MaterialRequest request) async {
    try {
      final detail = await widget.application.getMaterialRequestDetail(
        request.id,
      );
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (_) => _DetailSheet(detail: detail),
      );
    } on MaterialRequestFailure catch (error) {
      _showFailure(error);
    }
  }

  void _showFailure(MaterialRequestFailure error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('İşlem tamamlanamadı. (${error.code})')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('İstenecek Malzemeler')),
      floatingActionButton: _projectId == null
          ? null
          : FloatingActionButton.extended(
              key: const Key('material-request-create'),
              onPressed: _loading ? null : _openCreate,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Malzeme'),
            ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadProjects,
          child: ListView(
            key: const Key('material-requests-page'),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              const Text(
                'Hangi malzemeyi istemeniz gerektiğini ve güncel durumunu takip edin.',
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                key: ValueKey(
                  'material-request-project-${_projectId ?? 'none'}',
                ),
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
                        child: Text(project.name),
                      ),
                    )
                    .toList(growable: false),
                onChanged: _loading ? null : _selectProject,
              ),
              const SizedBox(height: 12),
              SegmentedButton<MaterialRequestListKind>(
                key: const Key('material-request-list-kind'),
                segments: const [
                  ButtonSegment(
                    value: MaterialRequestListKind.open,
                    icon: Icon(Icons.pending_actions_outlined),
                    label: Text('Açık'),
                  ),
                  ButtonSegment(
                    value: MaterialRequestListKind.history,
                    icon: Icon(Icons.history_rounded),
                    label: Text('Geçmiş'),
                  ),
                ],
                selected: {_kind},
                onSelectionChanged: _loading || _projectId == null
                    ? null
                    : _changeKind,
              ),
              const SizedBox(height: 12),
              if (_loading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_failure case final failure?)
                Column(
                  children: [
                    _MessageCard(
                      icon: Icons.error_outline_rounded,
                      text: 'Malzeme talepleri okunamadı. ($failure)',
                    ),
                    if (_projectDiscoveryFailed) ...[
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        key: const Key('material-request-project-retry'),
                        onPressed: _loadProjects,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Projeleri yeniden dene'),
                      ),
                    ],
                  ],
                )
              else if (_projects.isEmpty)
                const _MessageCard(
                  icon: Icons.apartment_outlined,
                  text: 'Önce aktif bir proje oluşturun.',
                )
              else if (_projectId == null)
                const KeyedSubtree(
                  key: Key('material-request-project-context-unavailable'),
                  child: _MessageCard(
                    icon: Icons.folder_off_outlined,
                    text:
                        'Dashboard projesi artık kullanılamıyor. Devam etmek için bir proje seçin.',
                  ),
                )
              else if (_requests.isEmpty)
                _MessageCard(
                  icon: _kind == MaterialRequestListKind.open
                      ? Icons.inventory_2_outlined
                      : Icons.history_rounded,
                  text: _kind == MaterialRequestListKind.open
                      ? 'Açık malzeme ihtiyacı yok.'
                      : 'Geldi veya iptal edildi kaydı yok.',
                )
              else
                ..._requests.map(
                  (request) => _RequestCard(
                    request: request,
                    onDetail: () => _showDetail(request),
                    onTransition: (status) => _transition(request, status),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.request,
    required this.onDetail,
    required this.onTransition,
  });

  final MaterialRequest request;
  final VoidCallback onDetail;
  final ValueChanged<MaterialRequestStatus> onTransition;

  @override
  Widget build(BuildContext context) {
    final quantity = request.quantity == null
        ? null
        : _quantityLabel(request.quantity!, request.unit!);
    return Card(
      key: ValueKey('material-request-${request.id}'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    request.materialName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Chip(label: Text(request.priority.label)),
              ],
            ),
            Text(request.status.label),
            if (quantity != null) Text(quantity),
            if (request.neededOn case final neededOn?)
              Text(
                'İhtiyaç tarihi: ${CseTimeCodec.formatIstanbulDay(neededOn)}',
              ),
            if (request.locationName case final location?)
              Text('Mahal: $location'),
            if (request.livingPlanActivityName case final activity?)
              Text('Plan işi: $activity'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                TextButton(onPressed: onDetail, child: const Text('Detay')),
                if (request.status == MaterialRequestStatus.needed)
                  FilledButton.tonal(
                    onPressed: () =>
                        onTransition(MaterialRequestStatus.requested),
                    child: const Text('İstendi'),
                  ),
                if (request.status == MaterialRequestStatus.requested)
                  FilledButton.tonal(
                    onPressed: () =>
                        onTransition(MaterialRequestStatus.received),
                    child: const Text('Geldi'),
                  ),
                if (request.status.isOpen)
                  TextButton(
                    onPressed: () =>
                        onTransition(MaterialRequestStatus.cancelled),
                    child: const Text('İptal'),
                  ),
                if (!request.status.isOpen)
                  FilledButton.tonal(
                    onPressed: () => onTransition(MaterialRequestStatus.needed),
                    child: const Text('Yeniden aç'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateMaterialRequestDialog extends StatefulWidget {
  const _CreateMaterialRequestDialog({
    required this.locations,
    required this.planItems,
  });

  final List<MaterialRequestLocationOption> locations;
  final List<MaterialRequestLivingPlanOption> planItems;

  @override
  State<_CreateMaterialRequestDialog> createState() =>
      _CreateMaterialRequestDialogState();
}

class _CreateMaterialRequestDialogState
    extends State<_CreateMaterialRequestDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _quantity = TextEditingController();
  final _unit = TextEditingController();
  final _description = TextEditingController();
  String? _locationId;
  String? _livingPlanItemId;
  String? _neededOn;
  MaterialRequestPriority _priority = MaterialRequestPriority.normal;

  @override
  void dispose() {
    _name.dispose();
    _quantity.dispose();
    _unit.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: DateTime.now(),
    );
    if (selected == null) return;
    final year = selected.year.toString().padLeft(4, '0');
    final month = selected.month.toString().padLeft(2, '0');
    final day = selected.day.toString().padLeft(2, '0');
    setState(() => _neededOn = '$year-$month-$day');
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      _CreateValue(
        materialName: _name.text.trim(),
        locationId: _locationId,
        livingPlanItemId: _livingPlanItemId,
        quantity: _parseQuantity(_quantity.text),
        unit: _emptyToNull(_unit.text),
        neededOn: _neededOn,
        priority: _priority,
        description: _emptyToNull(_description.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Malzeme ihtiyacı'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  key: const Key('material-request-name'),
                  controller: _name,
                  maxLength: 200,
                  decoration: const InputDecoration(labelText: 'Malzeme adı *'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Malzeme adı gerekli.'
                      : null,
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _quantity,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(labelText: 'Miktar'),
                        validator: _validateQuantity,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _unit,
                        maxLength: 40,
                        decoration: const InputDecoration(labelText: 'Birim'),
                      ),
                    ),
                  ],
                ),
                DropdownButtonFormField<MaterialRequestPriority>(
                  initialValue: _priority,
                  decoration: const InputDecoration(labelText: 'Öncelik'),
                  items: MaterialRequestPriority.values
                      .map(
                        (priority) => DropdownMenuItem(
                          value: priority,
                          child: Text(priority.label),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value != null) setState(() => _priority = value);
                  },
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String?>(
                  initialValue: _locationId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Mahal'),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Mahal seçilmedi'),
                    ),
                    ...widget.locations.map(
                      (location) => DropdownMenuItem(
                        value: location.id,
                        child: Text(location.displayName),
                      ),
                    ),
                  ],
                  onChanged: (value) => setState(() => _locationId = value),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String?>(
                  initialValue: _livingPlanItemId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: '7 Günlük Plan işi',
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Plan işi seçilmedi'),
                    ),
                    ...widget.planItems.map(
                      (item) => DropdownMenuItem(
                        value: item.id,
                        child: Text(
                          '${item.activityName} · ${CseTimeCodec.formatIstanbulDay(item.plannedDate)}',
                        ),
                      ),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => _livingPlanItemId = value),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _neededOn == null
                            ? 'İhtiyaç tarihi seçilmedi'
                            : CseTimeCodec.formatIstanbulDay(_neededOn!),
                      ),
                    ),
                    TextButton(
                      onPressed: _pickDate,
                      child: const Text('Tarih seç'),
                    ),
                    if (_neededOn != null)
                      IconButton(
                        tooltip: 'Tarihi kaldır',
                        onPressed: () => setState(() => _neededOn = null),
                        icon: const Icon(Icons.clear_rounded),
                      ),
                  ],
                ),
                TextFormField(
                  controller: _description,
                  maxLength: 1000,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Açıklama'),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Vazgeç'),
        ),
        FilledButton(
          key: const Key('material-request-save'),
          onPressed: _submit,
          child: const Text('Kaydet'),
        ),
      ],
    );
  }

  String? _validateQuantity(String? value) {
    final quantity = value?.trim() ?? '';
    final unit = _unit.text.trim();
    if (quantity.isEmpty && unit.isEmpty) return null;
    if (quantity.isEmpty || unit.isEmpty) {
      return 'Miktar ve birim birlikte girilmeli.';
    }
    final parsed = _parseQuantity(quantity);
    if (parsed == null || !parsed.isFinite || parsed <= 0) {
      return 'Pozitif bir miktar girin.';
    }
    return null;
  }
}

class _CreateValue {
  const _CreateValue({
    required this.materialName,
    required this.locationId,
    required this.livingPlanItemId,
    required this.quantity,
    required this.unit,
    required this.neededOn,
    required this.priority,
    required this.description,
  });

  final String materialName;
  final String? locationId;
  final String? livingPlanItemId;
  final double? quantity;
  final String? unit;
  final String? neededOn;
  final MaterialRequestPriority priority;
  final String? description;
}

class _DetailSheet extends StatelessWidget {
  const _DetailSheet({required this.detail});

  final MaterialRequestDetail detail;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        shrinkWrap: true,
        children: [
          Text(
            detail.request.materialName,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            '${detail.request.status.label} · revizyon ${detail.request.revision}',
          ),
          if (detail.request.description case final description?)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(description),
            ),
          const SizedBox(height: 16),
          Text('Geçmiş', style: Theme.of(context).textTheme.titleMedium),
          ...detail.events.reversed.map(
            (event) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(child: Text(event.sequence.toString())),
              title: Text(event.type.label),
              subtitle: Text(CseTimeCodec.formatIstanbul(event.occurredAtUtc)),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(leading: Icon(icon), title: Text(text)),
    );
  }
}

String? _emptyToNull(String value) {
  final exact = value.trim();
  return exact.isEmpty ? null : exact;
}

double? _parseQuantity(String value) {
  final exact = value.trim();
  if (exact.isEmpty) return null;
  return double.tryParse(exact.replaceAll(',', '.'));
}

String _quantityLabel(double value, String unit) {
  final exact = value.toString();
  final displayValue = exact.endsWith('.0')
      ? exact.substring(0, exact.length - 2)
      : exact;
  return '$displayValue $unit';
}
