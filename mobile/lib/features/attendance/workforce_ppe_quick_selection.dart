import 'dart:math' as math;

import 'package:chief_site_engineer/core/time/cse_time_codec.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/domain/attendance_models.dart';
import 'package:flutter/material.dart';

const _quickPpeTypes = <_QuickPpeType>[
  _QuickPpeType('helmet', 'Baret'),
  _QuickPpeType('vest', 'Reflektif yelek'),
  _QuickPpeType('shoes', 'İş ayakkabısı'),
  _QuickPpeType('glasses', 'Koruyucu gözlük'),
  _QuickPpeType('gloves', 'İş eldiveni'),
  _QuickPpeType('other', 'Diğer KKD'),
];

Future<bool?> showPpeQuickAssignmentSheet(
  BuildContext context, {
  required WorkforcePpeAssignment? current,
  required Future<void> Function(PpeQuickAssignmentInput input) onSave,
}) => showModalBottomSheet<bool>(
  context: context,
  isScrollControlled: true,
  isDismissible: false,
  enableDrag: false,
  useSafeArea: true,
  showDragHandle: true,
  builder: (context) =>
      _PpeQuickAssignmentSheet(current: current, onSave: onSave),
);

class PpeQuickAssignmentInput {
  const PpeQuickAssignmentInput({
    required this.type,
    required this.brand,
    required this.size,
    required this.serial,
    required this.quantity,
    required this.assigned,
    required this.status,
    required this.returned,
    required this.note,
  });

  final String type;
  final String brand;
  final String size;
  final String serial;
  final int quantity;
  final String assigned;
  final PpeAssignmentStatus status;
  final String returned;
  final String note;
}

class _PpeQuickAssignmentSheet extends StatefulWidget {
  const _PpeQuickAssignmentSheet({required this.current, required this.onSave});

  final WorkforcePpeAssignment? current;
  final Future<void> Function(PpeQuickAssignmentInput input) onSave;

  @override
  State<_PpeQuickAssignmentSheet> createState() =>
      _PpeQuickAssignmentSheetState();
}

class _PpeQuickAssignmentSheetState extends State<_PpeQuickAssignmentSheet> {
  late final TextEditingController _type;
  late final TextEditingController _brand;
  late final TextEditingController _size;
  late final TextEditingController _serial;
  late final TextEditingController _quantity;
  late final TextEditingController _assigned;
  late final TextEditingController _returned;
  late final TextEditingController _note;
  late PpeAssignmentStatus _status;
  late bool _detailsExpanded;
  String? _selectedQuickType;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final current = widget.current;
    _type = TextEditingController(text: current?.ppeType);
    _brand = TextEditingController(text: current?.brandModel);
    _size = TextEditingController(text: current?.size);
    _serial = TextEditingController(text: current?.serialTag);
    _quantity = TextEditingController(text: '${current?.quantity ?? 1}');
    _assigned = TextEditingController(
      text: current?.assignedDate ?? _istanbulToday(),
    );
    _returned = TextEditingController(text: current?.returnedDate);
    _note = TextEditingController(text: current?.note);
    _status = current?.status ?? PpeAssignmentStatus.assigned;
    _detailsExpanded = current != null;
    final matchingType = _quickPpeTypes
        .where((item) => item.key != 'other' && item.label == current?.ppeType)
        .firstOrNull;
    _selectedQuickType =
        matchingType?.key ?? (current == null ? null : 'other');
  }

  @override
  void dispose() {
    for (final controller in [
      _type,
      _brand,
      _size,
      _serial,
      _quantity,
      _assigned,
      _returned,
      _note,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _selectType(_QuickPpeType item) {
    setState(() {
      _selectedQuickType = item.key;
      _error = null;
      if (item.key == 'other') {
        if (_quickPpeTypes.any(
          (candidate) =>
              candidate.key != 'other' && candidate.label == _type.text,
        )) {
          _type.clear();
        }
      } else {
        _type.text = item.label;
      }
    });
  }

  void _changeQuantity(int delta) {
    final current = int.tryParse(_quantity.text) ?? 1;
    final next = math.max(1, current + delta);
    setState(() {
      _quantity.text = '$next';
      _error = null;
    });
  }

  void _typeChanged(String value) {
    final matchingType = _quickPpeTypes
        .where((item) => item.key != 'other' && item.label == value)
        .firstOrNull;
    setState(() {
      _selectedQuickType = matchingType?.key ?? 'other';
      _error = null;
    });
  }

  Future<void> _submit() async {
    if (_saving) return;
    FocusScope.of(context).unfocus();
    final quantity = int.tryParse(_quantity.text);
    if (_type.text.trim().isEmpty) {
      setState(() => _error = 'Önce bir KKD türü seçin veya yazın.');
      return;
    }
    if (quantity == null || quantity < 1) {
      setState(() => _error = 'Adet en az 1 olmalıdır.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSave(
        PpeQuickAssignmentInput(
          type: _type.text,
          brand: _brand.text,
          size: _size.text,
          serial: _serial.text,
          quantity: quantity,
          assigned: _assigned.text,
          status: _status,
          returned: _returned.text,
          note: _note.text,
        ),
      );
      if (mounted) Navigator.pop(context, true);
    } on Object catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = error is AgendaValidationFailure
              ? error.message
              : 'KKD zimmeti kaydedilemedi. Bilgileri kontrol edip yeniden deneyin.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final availableHeight = math
        .max(0.0, media.size.height - media.viewInsets.bottom)
        .toDouble();
    final maxHeight = math
        .min(media.size.height * 0.9, availableHeight)
        .toDouble();
    return PopScope<bool>(
      canPop: !_saving,
      child: AnimatedPadding(
        duration: kThemeAnimationDuration,
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: ListView(
            key: const Key('ppe-quick-sheet-scroll'),
            padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + media.padding.bottom),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.current == null
                          ? 'KKD zimmeti ekle'
                          : 'KKD zimmetini düzenle',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    key: const Key('ppe-sheet-close'),
                    tooltip: 'Vazgeç',
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text('Sahada sık kullanılan KKD türlerinden seçin.'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final item in _quickPpeTypes)
                    Semantics(
                      key: Key('ppe-quick-${item.key}'),
                      button: true,
                      enabled: !_saving,
                      selected: _selectedQuickType == item.key,
                      label: '${item.label} hızlı seçimi',
                      excludeSemantics: true,
                      onTap: _saving ? null : () => _selectType(item),
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(48, 48),
                          backgroundColor: _selectedQuickType == item.key
                              ? Theme.of(context).colorScheme.secondaryContainer
                              : null,
                        ),
                        onPressed: _saving ? null : () => _selectType(item),
                        child: Text(item.label),
                      ),
                    ),
                ],
              ),
              if (_selectedQuickType == 'other') ...[
                const SizedBox(height: 12),
                _field(
                  _type,
                  'KKD türü *',
                  enabled: !_saving,
                  onChanged: _typeChanged,
                  textInputAction: TextInputAction.next,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  IconButton.outlined(
                    key: const Key('ppe-quantity-decrease'),
                    tooltip: 'Adedi azalt',
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    onPressed: _saving ? null : () => _changeQuantity(-1),
                    icon: const Icon(Icons.remove),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _field(
                      _quantity,
                      'Adet *',
                      key: const Key('ppe-quantity-field'),
                      enabled: !_saving,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.outlined(
                    key: const Key('ppe-quantity-increase'),
                    tooltip: 'Adedi artır',
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    onPressed: _saving ? null : () => _changeQuantity(1),
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Semantics(
                  expanded: _detailsExpanded,
                  child: TextButton.icon(
                    key: const Key('ppe-details-toggle'),
                    style: TextButton.styleFrom(
                      minimumSize: const Size(48, 48),
                    ),
                    onPressed: _saving
                        ? null
                        : () => setState(
                            () => _detailsExpanded = !_detailsExpanded,
                          ),
                    icon: Icon(
                      _detailsExpanded ? Icons.expand_less : Icons.expand_more,
                    ),
                    label: const Text('Ayrıntılar'),
                  ),
                ),
              ),
              if (_detailsExpanded) ...[
                if (_selectedQuickType != 'other') ...[
                  _field(
                    _type,
                    'KKD türü *',
                    enabled: !_saving,
                    onChanged: _typeChanged,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 12),
                ],
                _field(
                  _brand,
                  'Marka/model',
                  enabled: !_saving,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                _field(
                  _size,
                  'Beden',
                  enabled: !_saving,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                _field(
                  _serial,
                  'Seri/etiket',
                  enabled: !_saving,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                _field(
                  _assigned,
                  'Zimmet tarihi (YYYY-AA-GG) *',
                  enabled: !_saving,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<PpeAssignmentStatus>(
                  initialValue: _status,
                  isExpanded: true,
                  itemHeight: null,
                  decoration: const InputDecoration(
                    labelText: 'Durum',
                    border: OutlineInputBorder(),
                  ),
                  items: PpeAssignmentStatus.values
                      .map(
                        (item) => DropdownMenuItem(
                          value: item,
                          child: Text(item.label),
                        ),
                      )
                      .toList(),
                  onChanged: _saving
                      ? null
                      : (value) => setState(() => _status = value ?? _status),
                ),
                const SizedBox(height: 12),
                _field(
                  _returned,
                  'İade tarihi (YYYY-AA-GG)',
                  enabled: !_saving,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                _field(_note, 'Not', enabled: !_saving, maxLines: 3),
              ],
              if (_error case final error?) ...[
                const SizedBox(height: 12),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    error,
                    key: const Key('ppe-save-error'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: [
                  TextButton(
                    key: const Key('ppe-cancel'),
                    style: TextButton.styleFrom(
                      minimumSize: const Size(48, 48),
                    ),
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    child: const Text('Vazgeç'),
                  ),
                  FilledButton(
                    key: const Key('ppe-submit'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(48, 48),
                    ),
                    onPressed: _saving ? null : _submit,
                    child: Text(_saving ? 'Kaydediliyor…' : 'Zimmetle'),
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

TextField _field(
  TextEditingController controller,
  String label, {
  Key? key,
  bool enabled = true,
  ValueChanged<String>? onChanged,
  TextInputType? keyboardType,
  TextInputAction? textInputAction,
  int maxLines = 1,
}) => TextField(
  key: key,
  controller: controller,
  enabled: enabled,
  onChanged: onChanged,
  keyboardType: keyboardType,
  textInputAction: textInputAction,
  maxLines: maxLines,
  decoration: InputDecoration(
    labelText: label,
    border: const OutlineInputBorder(),
  ),
);

String _istanbulToday() {
  return CseTimeCodec.istanbulDayKey(
    CseTimeCodec.encodeUtc(DateTime.now().toUtc()),
  );
}

class _QuickPpeType {
  const _QuickPpeType(this.key, this.label);

  final String key;
  final String label;
}
