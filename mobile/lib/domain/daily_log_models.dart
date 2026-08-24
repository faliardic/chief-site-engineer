import 'package:chief_site_engineer/core/time/cse_time_codec.dart';

enum DailyLogSourceKind {
  agendaLog('Ajanda'),
  attendanceDay('Puantaj'),
  concretePour('Beton'),
  reminder('Hatırlatıcı'),
  livingPlanItem('7 Günlük Plan işi'),
  livingPlanEvent('7 Günlük Plan olayı');

  const DailyLogSourceKind(this.label);

  final String label;
}

class DailyLogSourceRef {
  const DailyLogSourceRef({required this.kind, required this.sourceId});

  final DailyLogSourceKind kind;
  final String sourceId;
}

class DailyLogProject {
  const DailyLogProject({required this.id, required this.name});

  final String id;
  final String name;
}

class DailyLogEntry {
  DailyLogEntry({
    required this.id,
    required this.text,
    required List<DailyLogSourceRef> sourceRefs,
    this.occurredAt,
  }) : sourceRefs = List.unmodifiable(sourceRefs) {
    if (sourceRefs.isEmpty) {
      throw ArgumentError.value(
        sourceRefs,
        'sourceRefs',
        'Daily Log entries must retain at least one source reference.',
      );
    }
  }

  final String id;
  final String text;
  final String? occurredAt;
  final List<DailyLogSourceRef> sourceRefs;
}

enum DailyLogSectionKind {
  summary('Günün özeti', 'Bu gün için kaynak kaydı yok'),
  attendance('Puantaj', 'Puantaj kaydı yok'),
  livingPlan('İmalat / 7 Günlük Plan', 'İmalat değişikliği yok'),
  concrete('Beton', 'Beton kaydı yok'),
  agenda('Ajanda', 'Ajanda kaydı yok'),
  openFollowUps('Açık takipler', 'Açık takip yok');

  const DailyLogSectionKind(this.title, this.emptyMessage);

  final String title;
  final String emptyMessage;
}

class DailyLogSectionFailure {
  const DailyLogSectionFailure({required this.code, required this.message});

  final String code;
  final String message;
}

class DailyLogSection {
  DailyLogSection.available({
    required this.kind,
    required List<DailyLogEntry> entries,
  }) : entries = List.unmodifiable(entries),
       summaryText = null,
       failure = null;

  DailyLogSection.summary({required String text})
    : kind = DailyLogSectionKind.summary,
      entries = const [],
      summaryText = text,
      failure = null;

  DailyLogSection.unavailable({required this.kind, required this.failure})
    : entries = const [],
      summaryText = null {
    if (kind == DailyLogSectionKind.summary) {
      throw ArgumentError.value(
        kind,
        'kind',
        'The derived summary cannot be a source-unavailable section.',
      );
    }
  }

  final DailyLogSectionKind kind;
  final List<DailyLogEntry> entries;
  final String? summaryText;
  final DailyLogSectionFailure? failure;

  bool get isAvailable => failure == null;
}

class DailyLogDay {
  DailyLogDay({
    required this.projectId,
    required this.projectName,
    required this.localDay,
    required List<DailyLogSection> sections,
  }) : sections = List.unmodifiable(sections) {
    CseTimeCodec.validateIstanbulDay(localDay);
    if (sections.length != DailyLogSectionKind.values.length) {
      throw ArgumentError.value(
        sections,
        'sections',
        'Daily Log must contain every canonical section exactly once.',
      );
    }
    for (var index = 0; index < sections.length; index += 1) {
      if (sections[index].kind != DailyLogSectionKind.values[index]) {
        throw ArgumentError.value(
          sections,
          'sections',
          'Daily Log sections must use canonical deterministic ordering.',
        );
      }
    }
  }

  final String projectId;
  final String projectName;
  final String localDay;
  final List<DailyLogSection> sections;

  DailyLogSection section(DailyLogSectionKind kind) => sections[kind.index];
}

class DailyLogFailure implements Exception {
  const DailyLogFailure(this.code);

  final String code;

  @override
  String toString() => 'DailyLogFailure: $code';
}

String formatDailyLogAsPlainText(DailyLogDay day) {
  final buffer = StringBuffer()
    ..writeln('GÜNLÜK SAHA LOGU')
    ..writeln(
      '${CseTimeCodec.formatIstanbulDay(day.localDay)} · ${day.projectName}',
    );
  for (final section in day.sections) {
    buffer
      ..writeln()
      ..writeln(section.kind.title.toUpperCase());
    final summaryText = section.summaryText;
    final failure = section.failure;
    if (summaryText != null) {
      buffer.writeln('- $summaryText');
      continue;
    }
    if (failure != null) {
      buffer.writeln('- ${failure.message}');
      continue;
    }
    if (section.entries.isEmpty) {
      buffer.writeln('- ${section.kind.emptyMessage}');
      continue;
    }
    for (final entry in section.entries) {
      final occurredAt = entry.occurredAt;
      final timePrefix = occurredAt == null
          ? ''
          : '${CseTimeCodec.istanbulTimeLabel(occurredAt)} ';
      buffer.writeln('- $timePrefix${entry.text}');
    }
  }
  return buffer.toString().trimRight();
}
