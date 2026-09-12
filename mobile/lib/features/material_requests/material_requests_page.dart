import 'dart:async';

import 'package:chief_site_engineer/application/material_request_application.dart';
import 'package:chief_site_engineer/core/record_id.dart';
import 'package:chief_site_engineer/core/time/cse_time_codec.dart';
import 'package:chief_site_engineer/domain/material_request_models.dart';
import 'package:flutter/material.dart';

const _minimumTouchTargetStyle = ButtonStyle(
  minimumSize: WidgetStatePropertyAll(Size(48, 48)),
);

class MaterialRequestsPage extends StatefulWidget {
  const MaterialRequestsPage({
    required this.application,
    this.initialProjectId,
    this.onProjectSelected,
    super.key,
  });

  final MaterialRequestApplicationPort application;
  final String? initialProjectId;
  // Kept for source compatibility with older route callers. Materials now
  // consumes the shared Dashboard context and never changes it locally.
  final ValueChanged<String>? onProjectSelected;

  @override
  State<MaterialRequestsPage> createState() => _MaterialRequestsPageState();
}

class _MaterialRequestsPageState extends State<MaterialRequestsPage> {
  List<MaterialRequest> _requests = const [];
  MaterialRequestProject? _project;
  String? _contextProjectId;
  MaterialRequestListKind _kind = MaterialRequestListKind.open;
  bool _loading = true;
  bool _refreshing = false;
  bool _contextValid = false;
  bool _projectDiscoveryFailed = false;
  bool _projectMissing = false;
  bool _openingCreate = false;
  String? _failure;
  final Set<String> _transitioning = {};

  @override
  void initState() {
    super.initState();
    _contextProjectId = widget.initialProjectId;
    unawaited(_loadProjects());
  }

  @override
  void didUpdateWidget(covariant MaterialRequestsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialProjectId == widget.initialProjectId) return;
    _contextProjectId = widget.initialProjectId;
    _project = null;
    _requests = const [];
    _contextValid = false;
    unawaited(_loadProjects());
  }

  bool get _canMutate =>
      _contextValid && !_loading && !_refreshing && _failure == null;

  Future<void> _loadProjects() async {
    final projectIdToValidate = _contextProjectId;
    if (projectIdToValidate == null) {
      if (!mounted) return;
      setState(() {
        _project = null;
        _requests = const [];
        _contextValid = false;
        _loading = false;
        _refreshing = false;
        _projectDiscoveryFailed = false;
        _projectMissing = false;
        _failure = null;
      });
      return;
    }
    final hasPriorContent = _project != null || _requests.isNotEmpty;
    setState(() {
      _loading = !hasPriorContent;
      _refreshing = hasPriorContent;
      _projectDiscoveryFailed = false;
      _projectMissing = false;
      _failure = null;
    });
    try {
      final projects = await widget.application.listProjects();
      MaterialRequestProject? selected;
      for (final project in projects) {
        if (project.id == projectIdToValidate) {
          selected = project;
          break;
        }
      }
      if (!mounted) return;
      if (selected == null) {
        setState(() {
          _contextValid = false;
          _loading = false;
          _refreshing = false;
          _projectMissing = true;
        });
        return;
      }
      setState(() {
        _project = selected;
        _contextValid = true;
      });
      await _reload();
    } on MaterialRequestFailure catch (error) {
      if (!mounted) return;
      setState(() {
        _contextValid = false;
        _loading = false;
        _refreshing = false;
        _projectDiscoveryFailed = true;
        _failure = error.code;
      });
    }
  }

  Future<void> _reload() async {
    final projectId = _project?.id;
    if (!_contextValid || projectId == null) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _refreshing = false;
      });
      return;
    }
    final hasPriorContent = _requests.isNotEmpty;
    setState(() {
      _loading = !hasPriorContent;
      _refreshing = hasPriorContent;
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
        _refreshing = false;
      });
    } on MaterialRequestFailure catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _refreshing = false;
        _failure = error.code;
      });
    }
  }

  Future<void> _changeKind(Set<MaterialRequestListKind> values) async {
    if (values.isEmpty || values.single == _kind) return;
    setState(() {
      _kind = values.single;
      _requests = const [];
      _failure = null;
    });
    await _reload();
  }

  Future<void> _openCreate() async {
    final projectId = _project?.id;
    if (!_canMutate || projectId == null || _openingCreate) return;
    setState(() => _openingCreate = true);
    try {
      final locations = await widget.application.listLocations(projectId);
      final planItems = await widget.application.listLivingPlanItems(projectId);
      if (!mounted) return;
      final created = await showDialog<bool>(
        context: context,
        builder: (_) => _CreateMaterialRequestDialog(
          locations: locations,
          planItems: planItems,
          onSubmit: (value) => widget.application.createMaterialRequest(
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
          ),
        ),
      );
      if (created == true) await _reload();
    } on MaterialRequestFailure catch (error) {
      _showFailure(error);
    } finally {
      if (mounted) setState(() => _openingCreate = false);
    }
  }

  Future<void> _transition(
    MaterialRequest request,
    MaterialRequestStatus status,
  ) async {
    if (!_canMutate || !_transitioning.add(request.id)) return;
    setState(() {});
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
    } finally {
      if (mounted) {
        setState(() => _transitioning.remove(request.id));
      }
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
      SnackBar(
        content: Text(
          'İşlem tamamlanamadı. İçerik korunuyor; tekrar deneyin. '
          '(${error.code})',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final project = _project;
    final compactStateControls =
        MediaQuery.sizeOf(context).width < 360 ||
        MediaQuery.textScalerOf(context).scale(1) > 1.3;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'İstenecek Malzemeler',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            key: const Key('material-request-refresh'),
            tooltip: 'Malzemeleri yenile',
            onPressed: _loading || _refreshing ? null : _loadProjects,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: !_contextValid
          ? null
          : FloatingActionButton.extended(
              key: const Key('material-request-create'),
              tooltip: 'Yeni malzeme ihtiyacı ekle',
              onPressed: _canMutate && !_openingCreate ? _openCreate : null,
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
              if (_contextValid && project != null) ...[
                const SizedBox(height: 12),
                _ProjectContext(project: project),
              ],
              const SizedBox(height: 12),
              SegmentedButton<MaterialRequestListKind>(
                key: const Key('material-request-list-kind'),
                style: _minimumTouchTargetStyle,
                segments: [
                  ButtonSegment(
                    value: MaterialRequestListKind.open,
                    icon: compactStateControls
                        ? null
                        : const Icon(Icons.pending_actions_outlined),
                    label: Semantics(
                      selected: _kind == MaterialRequestListKind.open,
                      child: const Text('Açık'),
                    ),
                  ),
                  ButtonSegment(
                    value: MaterialRequestListKind.history,
                    icon: compactStateControls
                        ? null
                        : const Icon(Icons.history_rounded),
                    label: Semantics(
                      selected: _kind == MaterialRequestListKind.history,
                      child: const Text('Geçmiş'),
                    ),
                  ),
                ],
                selected: {_kind},
                onSelectionChanged: !_canMutate ? null : _changeKind,
              ),
              const SizedBox(height: 12),
              if (_refreshing) ...[
                const LinearProgressIndicator(
                  key: Key('material-request-refresh-progress'),
                ),
                const SizedBox(height: 12),
              ],
              if (_loading && _requests.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                )
              else ...[
                if (!_contextValid)
                  KeyedSubtree(
                    key: Key('material-request-project-context-unavailable'),
                    child: _MessageCard(
                      icon: _projectDiscoveryFailed
                          ? Icons.cloud_off_outlined
                          : Icons.folder_off_outlined,
                      text: _projectDiscoveryFailed
                          ? 'Proje bilgisi doğrulanamadı. Hiçbir değişiklik '
                                'yapılmadı; tekrar deneyin veya Dashboard’a dönün.'
                          : _projectMissing
                          ? 'Dashboard’dan gelen proje artık kullanılamıyor. '
                                'Dashboard’a dönüp aktif projeyi kontrol edin.'
                          : 'Aktif proje bulunamadı. Dashboard’a dönüp bir '
                                'proje seçin.',
                      action: _contextProjectId == null
                          ? null
                          : OutlinedButton.icon(
                              key: const Key('material-request-project-retry'),
                              style: _minimumTouchTargetStyle,
                              onPressed: _loadProjects,
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Tekrar dene'),
                            ),
                    ),
                  ),
                if (_contextValid && _failure != null)
                  _MessageCard(
                    icon: Icons.error_outline_rounded,
                    text: _requests.isEmpty
                        ? 'Malzeme talepleri okunamadı. Tekrar deneyin. '
                              '($_failure)'
                        : 'Malzeme talepleri yenilenemedi. Önceki içerik '
                              'korunuyor; tekrar deneyin. ($_failure)',
                    action: OutlinedButton.icon(
                      key: const Key('material-request-list-retry'),
                      style: _minimumTouchTargetStyle,
                      onPressed: _loadProjects,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Tekrar dene'),
                    ),
                  ),
                if (_contextValid && _failure == null && _requests.isEmpty)
                  _MessageCard(
                    key: ValueKey(
                      _kind == MaterialRequestListKind.open
                          ? 'material-request-open-empty'
                          : 'material-request-history-empty',
                    ),
                    icon: _kind == MaterialRequestListKind.open
                        ? Icons.inventory_2_outlined
                        : Icons.history_rounded,
                    text: _kind == MaterialRequestListKind.open
                        ? 'Açık malzeme ihtiyacı yok.'
                        : 'Geldi veya iptal edildi kaydı yok.',
                  ),
                if (_requests.isNotEmpty) ...[
                  if (!_contextValid || _failure != null)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Son güvenli içerik yalnızca görüntüleniyor.',
                      ),
                    ),
                  ..._requests.map(
                    (request) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _RequestCard(
                        request: request,
                        onDetail: () => _showDetail(request),
                        onTransition: (status) => _transition(request, status),
                        mutationsEnabled:
                            _canMutate && !_transitioning.contains(request.id),
                        transitionInProgress: _transitioning.contains(
                          request.id,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ProjectContext extends StatelessWidget {
  const _ProjectContext({required this.project});

  final MaterialRequestProject project;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Aktif proje: ${project.name}',
      readOnly: true,
      child: InputDecorator(
        key: const Key('material-request-project-context'),
        decoration: const InputDecoration(
          labelText: 'Aktif proje',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.folder_outlined),
        ),
        child: Text(project.name, maxLines: 2, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.request,
    required this.onDetail,
    required this.onTransition,
    required this.mutationsEnabled,
    required this.transitionInProgress,
  });

  final MaterialRequest request;
  final VoidCallback onDetail;
  final ValueChanged<MaterialRequestStatus> onTransition;
  final bool mutationsEnabled;
  final bool transitionInProgress;

  @override
  Widget build(BuildContext context) {
    final quantity = request.quantity == null
        ? null
        : _quantityLabel(request.quantity!, request.unit!);
    return Semantics(
      container: true,
      label:
          '${request.materialName}, ${request.status.label}, '
          '${request.priority.label} öncelik',
      child: Card(
        key: ValueKey('material-request-${request.id}'),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                request.materialName,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  Chip(
                    avatar: const Icon(Icons.sync_alt_rounded, size: 18),
                    label: Text(request.status.label),
                    visualDensity: VisualDensity.compact,
                  ),
                  Chip(
                    avatar: const Icon(Icons.flag_outlined, size: 18),
                    label: Text(request.priority.label),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              if (quantity != null) Text('Miktar: $quantity'),
              if (request.neededOn case final neededOn?)
                Text(
                  'İhtiyaç tarihi: ${CseTimeCodec.formatIstanbulDay(neededOn)}',
                ),
              if (request.locationName case final location?)
                Text('Mahal: $location'),
              if (request.livingPlanActivityName case final activity?)
                Text('Plan işi: $activity'),
              const SizedBox(height: 4),
              if (transitionInProgress)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text('Durum güncelleniyor…'),
                    ],
                  ),
                ),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  TextButton(
                    style: _minimumTouchTargetStyle,
                    onPressed: onDetail,
                    child: const Text('Detayı aç'),
                  ),
                  if (request.status == MaterialRequestStatus.needed)
                    FilledButton.tonal(
                      style: _minimumTouchTargetStyle,
                      onPressed: mutationsEnabled
                          ? () => onTransition(MaterialRequestStatus.requested)
                          : null,
                      child: const Text('İstendi yap'),
                    ),
                  if (request.status == MaterialRequestStatus.requested)
                    FilledButton.tonal(
                      style: _minimumTouchTargetStyle,
                      onPressed: mutationsEnabled
                          ? () => onTransition(MaterialRequestStatus.received)
                          : null,
                      child: const Text('Geldi yap'),
                    ),
                  if (request.status.isOpen)
                    TextButton(
                      style: _minimumTouchTargetStyle,
                      onPressed: mutationsEnabled
                          ? () => onTransition(MaterialRequestStatus.cancelled)
                          : null,
                      child: const Text('İptal et'),
                    ),
                  if (!request.status.isOpen)
                    FilledButton.tonal(
                      style: _minimumTouchTargetStyle,
                      onPressed: mutationsEnabled
                          ? () => onTransition(MaterialRequestStatus.needed)
                          : null,
                      child: const Text('Yeniden aç'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreateMaterialRequestDialog extends StatefulWidget {
  const _CreateMaterialRequestDialog({
    required this.locations,
    required this.planItems,
    required this.onSubmit,
  });

  final List<MaterialRequestLocationOption> locations;
  final List<MaterialRequestLivingPlanOption> planItems;
  final Future<MaterialRequest> Function(_CreateValue value) onSubmit;

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
  bool _submitting = false;
  String? _failure;

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

  Future<void> _submit() async {
    if (_submitting) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _failure = null;
    });
    try {
      await widget.onSubmit(
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
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on MaterialRequestFailure catch (error) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _failure = error.code;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: const Key('material-request-create-dialog'),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
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
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Yalnızca malzeme adı zorunludur.'),
                ),
                ExpansionTile(
                  key: const Key('material-request-optional-details'),
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: const EdgeInsets.only(bottom: 4),
                  maintainState: true,
                  title: const Text('İsteğe bağlı ayrıntılar'),
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final quantityField = TextFormField(
                          controller: _quantity,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Miktar',
                          ),
                          validator: _validateQuantity,
                        );
                        final unitField = TextFormField(
                          controller: _unit,
                          maxLength: 40,
                          decoration: const InputDecoration(labelText: 'Birim'),
                        );
                        final textScale = MediaQuery.textScalerOf(
                          context,
                        ).scale(1);
                        if (constraints.maxWidth < 400 || textScale > 1.3) {
                          return Column(
                            children: [
                              quantityField,
                              const SizedBox(height: 8),
                              unitField,
                            ],
                          );
                        }
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: quantityField),
                            const SizedBox(width: 12),
                            Expanded(child: unitField),
                          ],
                        );
                      },
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
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            _neededOn == null
                                ? 'İhtiyaç tarihi seçilmedi'
                                : CseTimeCodec.formatIstanbulDay(_neededOn!),
                          ),
                          TextButton(
                            style: _minimumTouchTargetStyle,
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
                    ),
                    TextFormField(
                      controller: _description,
                      maxLength: 1000,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Açıklama'),
                    ),
                  ],
                ),
                if (_failure != null)
                  Semantics(
                    liveRegion: true,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Kaydedilemedi. Taslağınız korunuyor; tekrar deneyin. '
                        '($_failure)',
                        key: const Key('material-request-create-error'),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          style: _minimumTouchTargetStyle,
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Vazgeç'),
        ),
        FilledButton(
          key: const Key('material-request-save'),
          style: _minimumTouchTargetStyle,
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Kaydet'),
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
  const _MessageCard({
    required this.icon,
    required this.text,
    this.action,
    super.key,
  });

  final IconData icon;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(leading: Icon(icon), title: Text(text)),
          if (action case final action?)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Align(alignment: Alignment.centerLeft, child: action),
            ),
        ],
      ),
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
