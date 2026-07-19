import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:chief_site_engineer/domain/attendance_models.dart';
import 'package:chief_site_engineer/platform/export_gateway.dart';
import 'package:path/path.dart' as path;
import 'package:share_plus/share_plus.dart';

abstract interface class AttendanceExportGateway {
  Future<String> stage(String fileName, Uint8List bytes);

  Future<void> cleanup(String absolutePath);

  Future<void> share(String absolutePath, String humanSummary);
}

class UnavailableAttendanceExportGateway implements AttendanceExportGateway {
  const UnavailableAttendanceExportGateway();

  @override
  Future<void> cleanup(String absolutePath) async {}

  @override
  Future<void> share(String absolutePath, String humanSummary) {
    throw StateError('attendance export sharing is unavailable');
  }

  @override
  Future<String> stage(String fileName, Uint8List bytes) {
    throw StateError('attendance export storage is unavailable');
  }
}

class DeviceAttendanceExportGateway implements AttendanceExportGateway {
  const DeviceAttendanceExportGateway({
    required this.stager,
    this.sharePort = const FlutterAttendanceSharePort(),
  });

  final LocalExportStager stager;
  final AttendanceSharePort sharePort;

  @override
  Future<String> stage(String fileName, Uint8List bytes) async {
    final file = await stager.stage(fileName, bytes);
    return file.path;
  }

  @override
  Future<void> cleanup(String absolutePath) async {
    stager.directories.validate();
    final exportRoot = path.normalize(
      path.absolute(stager.directories.exportsBackups.path),
    );
    final candidate = path.normalize(path.absolute(absolutePath));
    if (!path.isWithin(exportRoot, candidate)) {
      throw ArgumentError('export cleanup path escaped its root');
    }
    final file = File(candidate);
    if (await file.exists()) await file.delete();
  }

  @override
  Future<void> share(String absolutePath, String humanSummary) {
    return sharePort.share(absolutePath, humanSummary);
  }
}

abstract interface class AttendanceSharePort {
  Future<void> share(String absolutePath, String humanSummary);
}

class FlutterAttendanceSharePort implements AttendanceSharePort {
  const FlutterAttendanceSharePort();

  @override
  Future<void> share(String absolutePath, String humanSummary) async {
    await SharePlus.instance.share(
      ShareParams(
        title: 'Günlük Puantaj',
        subject: 'Günlük Puantaj',
        text: humanSummary,
        files: [XFile(absolutePath, mimeType: 'text/csv')],
      ),
    );
  }
}

class AttendanceCsvFormatter {
  AttendanceCsvFormatter._();

  static Uint8List format(AttendanceDayDetail detail) {
    final rows = <List<String>>[
      const [
        'Proje',
        'Tarih',
        'Ekip/Taşeron',
        'Personel Kodu',
        'Personel Adı',
        'Meslek/Pozisyon',
        'Sonuç',
        'Fazla Mesai Dakika',
        'Fazla Mesai Saat',
        'Not',
      ],
      ...detail.entries.map(
        (entry) => [
          detail.day.projectName,
          detail.day.localDate,
          entry.teamName,
          entry.personnelCode ?? '',
          entry.memberName,
          entry.roleName,
          entry.result.label,
          '${entry.overtimeMinutes}',
          (entry.overtimeMinutes / 60).toStringAsFixed(2),
          entry.shortNote ?? '',
        ],
      ),
    ];
    final csv = rows.map((row) => row.map(_cell).join(',')).join('\r\n');
    return Uint8List.fromList([0xef, 0xbb, 0xbf, ...utf8.encode('$csv\r\n')]);
  }

  static String humanSummary(AttendanceDayDetail detail) {
    final totals = detail.totals;
    final overtimeHours = (totals.overtimeMinutes / 60).toStringAsFixed(2);
    final lines = <String>[
      'Puantaj — ${detail.day.projectName} — ${detail.day.localDate}',
      'Durum: ${detail.day.status.label}',
      'Tam gün: ${totals.fullDayCount}',
      'Yarım gün: ${totals.halfDayCount}',
      'Gelmedi: ${totals.absentCount}',
      'İzinli: ${totals.leaveCount}',
      'Sahada: ${totals.presentCount}',
      'Kişi-gün: ${totals.personDayEquivalent.toStringAsFixed(1)}',
      'Fazla mesai: ${totals.overtimeMinutes} dk ($overtimeHours saat)',
      ...detail.teamSummaries.map(
        (team) =>
            '${team.teamName}: ${team.totals.personDayEquivalent.toStringAsFixed(1)} kişi-gün, '
            '${team.totals.overtimeMinutes} dk fazla mesai',
      ),
    ];
    if (detail.day.generalNote case final note?) {
      lines.add('Not: $note');
    }
    return lines.join('\n');
  }

  static String _cell(String input) {
    final safe = input.isNotEmpty && '=+-@'.contains(input[0])
        ? "'$input"
        : input;
    return '"${safe.replaceAll('"', '""')}"';
  }
}
