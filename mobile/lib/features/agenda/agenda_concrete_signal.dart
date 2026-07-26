import 'package:chief_site_engineer/domain/agenda_models.dart';

abstract final class AgendaConcreteSignalDetector {
  static const _keywords = {'beton', 'betonaj'};

  static bool hasSignal({
    required String description,
    String? notes,
    required AgendaCategory category,
  }) {
    if (category == AgendaCategory.concrete) return true;
    return _containsKeyword(description) || _containsKeyword(notes ?? '');
  }

  static bool _containsKeyword(String value) {
    final normalized = normalize(value);
    if (normalized.isEmpty) return false;
    return normalized.split(' ').any(_keywords.contains);
  }

  static String normalize(String value) {
    return value
        .replaceAll('İ', 'i')
        .replaceAll('I', 'ı')
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9çğıöşü]+'), ' ')
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');
  }
}
