enum ContextSuggestionKind { person, company }

enum ContextSuggestionSourceType {
  workforceMember,
  subcontractor,
  historicalRelatedPerson,
}

enum ContextSuggestionReasonCode {
  activeDirectoryPerson,
  activeDirectoryCompany,
  previousProjectUsage,
}

enum ContextSuggestionMatchQuality { exact, prefix, substring, all }

class ContextSuggestionQuery {
  const ContextSuggestionQuery({
    required this.projectId,
    this.query = '',
    this.limit = 6,
  });

  final String projectId;
  final String query;
  final int limit;
}

class ContextSuggestion {
  const ContextSuggestion({
    required this.kind,
    required this.displayValue,
    required this.sourceType,
    required this.sourceId,
    required this.projectId,
    required this.reasonCode,
    required this.matchQuality,
    required this.historicalUsageCount,
    required this.historicalLastUsedAt,
  }) : assert(
         sourceType == ContextSuggestionSourceType.historicalRelatedPerson
             ? sourceId == null
             : sourceId != null,
       );

  final ContextSuggestionKind kind;
  final String displayValue;
  final ContextSuggestionSourceType sourceType;
  final String? sourceId;
  final String projectId;
  final ContextSuggestionReasonCode reasonCode;
  final ContextSuggestionMatchQuality matchQuality;
  final int historicalUsageCount;
  final String? historicalLastUsedAt;
}

class ContextSuggestionFailure implements Exception {
  const ContextSuggestionFailure(this.code);

  final String code;

  @override
  String toString() => code;
}
