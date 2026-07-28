import 'dart:convert';
import 'dart:io';

import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/storage/app_directories.dart';
import 'package:path/path.dart' as path;

const issue252SmokeStateMarker = 'CSE_ISSUE252_SMOKE_STATE_V1';

final RegExp _runIdPattern = RegExp(r'^\d{14}$');

String validateIssue252SmokeRunId(String value) {
  if (!_runIdPattern.hasMatch(value)) {
    throw const FormatException(
      'CSE_ISSUE254_RUN_ID must contain exactly 14 digits.',
    );
  }
  return value;
}

String issue252SmokeTitle(String runId) =>
    'ISSUE252-SMOKE-${validateIssue252SmokeRunId(runId)}';

Directory issue252SmokeSupportRoot(String runId) => Directory(
  path.join(
    Directory.systemTemp.path,
    'cse_issue254_physical_smoke',
    validateIssue252SmokeRunId(runId),
  ),
);

File issue252SmokeStateFile(AppDirectories directories) =>
    File(path.join(directories.state.path, 'issue252_smoke_state.json'));

bool isDueWithinOperationWindow({
  required String dueAt,
  required DateTime operationStartedAt,
  required DateTime operationFinishedAt,
  required Duration offset,
}) {
  final due = DateTime.parse(dueAt).toUtc();
  const canonicalSecondTolerance = Duration(seconds: 1);
  return !due.isBefore(
        operationStartedAt
            .toUtc()
            .add(offset)
            .subtract(canonicalSecondTolerance),
      ) &&
      !due.isAfter(
        operationFinishedAt.toUtc().add(offset).add(canonicalSecondTolerance),
      );
}

class Issue252SmokeState {
  const Issue252SmokeState({
    required this.runId,
    required this.reminderId,
    required this.title,
    required this.finalDueAt,
  });

  factory Issue252SmokeState.fromJson(Map<String, Object?> json) {
    if (json['marker'] != issue252SmokeStateMarker) {
      throw const FormatException('Issue 252 smoke state marker is invalid.');
    }
    final runId = json['runId'];
    final reminderId = json['reminderId'];
    final title = json['title'];
    final finalDueAt = json['finalDueAt'];
    if (runId is! String ||
        reminderId is! String ||
        reminderId.isEmpty ||
        title is! String ||
        finalDueAt is! String) {
      throw const FormatException('Issue 252 smoke state is incomplete.');
    }
    validateIssue252SmokeRunId(runId);
    if (title != issue252SmokeTitle(runId)) {
      throw const FormatException('Issue 252 smoke title is inconsistent.');
    }
    final parsedDue = DateTime.tryParse(finalDueAt);
    if (parsedDue == null || !finalDueAt.endsWith('Z')) {
      throw const FormatException('Issue 252 smoke due time is invalid.');
    }
    return Issue252SmokeState(
      runId: runId,
      reminderId: reminderId,
      title: title,
      finalDueAt: finalDueAt,
    );
  }

  final String runId;
  final String reminderId;
  final String title;
  final String finalDueAt;

  Map<String, Object?> toJson() => {
    'marker': issue252SmokeStateMarker,
    'runId': runId,
    'reminderId': reminderId,
    'title': title,
    'finalDueAt': finalDueAt,
  };
}

Future<void> writeIssue252SmokeState(
  File destination,
  Issue252SmokeState state,
) async {
  await destination.parent.create(recursive: true);
  final next = File('${destination.path}.next');
  await next.writeAsString(jsonEncode(state.toJson()), flush: true);
  if (await destination.exists()) {
    throw StateError('Issue 252 smoke state already exists.');
  }
  await next.rename(destination.path);
}

Future<Issue252SmokeState> readIssue252SmokeState(
  File source, {
  required String expectedRunId,
}) async {
  final decoded = jsonDecode(await source.readAsString());
  if (decoded is! Map<String, Object?>) {
    throw const FormatException('Issue 252 smoke state is not an object.');
  }
  final state = Issue252SmokeState.fromJson(decoded);
  if (state.runId != validateIssue252SmokeRunId(expectedRunId)) {
    throw const FormatException('Issue 252 smoke run identity changed.');
  }
  return state;
}

MobileReminder requireUniqueSyntheticReminder(
  Iterable<MobileReminder> reminders, {
  required String title,
}) {
  final matches = reminders
      .where((reminder) => reminder.title == title)
      .toList(growable: false);
  if (matches.length != 1) {
    throw StateError(
      'Expected exactly one synthetic Issue 252 reminder, '
      'found ${matches.length}.',
    );
  }
  return matches.single;
}
