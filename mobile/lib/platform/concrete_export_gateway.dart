import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:chief_site_engineer/domain/concrete_models.dart';
import 'package:chief_site_engineer/platform/export_gateway.dart';
import 'package:path/path.dart' as path;
import 'package:share_plus/share_plus.dart';

abstract interface class ConcreteExportGateway {
  Future<String> stage(String fileName, Uint8List bytes);
  Future<void> cleanup(String absolutePath);
  Future<void> share(String absolutePath, String summary);
}

class UnavailableConcreteExportGateway implements ConcreteExportGateway {
  const UnavailableConcreteExportGateway();
  @override
  Future<void> cleanup(String absolutePath) async {}
  @override
  Future<void> share(String absolutePath, String summary) {
    throw StateError('concrete export sharing unavailable');
  }

  @override
  Future<String> stage(String fileName, Uint8List bytes) {
    throw StateError('concrete export storage unavailable');
  }
}

class DeviceConcreteExportGateway implements ConcreteExportGateway {
  const DeviceConcreteExportGateway({required this.stager});
  final LocalExportStager stager;

  @override
  Future<String> stage(String fileName, Uint8List bytes) async =>
      (await stager.stage(fileName, bytes)).path;

  @override
  Future<void> cleanup(String absolutePath) async {
    stager.directories.validate();
    final root = path.normalize(
      path.absolute(stager.directories.exportsBackups.path),
    );
    final candidate = path.normalize(path.absolute(absolutePath));
    if (!path.isWithin(root, candidate)) {
      throw StateError('concrete export cleanup escaped root');
    }
    final file = File(candidate);
    if (await file.exists()) await file.delete();
  }

  @override
  Future<void> share(String absolutePath, String summary) async {
    await SharePlus.instance.share(
      ShareParams(
        title: 'Beton Paketi Raporu',
        subject: 'Beton Paketi Raporu',
        text: summary,
        files: [XFile(absolutePath, mimeType: 'text/markdown')],
      ),
    );
  }
}

class ConcretePackageReportFormatter {
  ConcretePackageReportFormatter._();

  static Uint8List markdownBytes(ConcretePourDetail detail) =>
      Uint8List.fromList([
        0xef,
        0xbb,
        0xbf,
        ...utf8.encode('${markdown(detail)}\n'),
      ]);

  static String markdown(ConcretePourDetail detail) {
    final pour = detail.pour;
    final metrics = detail.metrics;
    final lines = <String>[
      '# Beton Paketi — ${_safe(pour.pourCode)}',
      '',
      '- Proje: ${_safe(pour.projectName)}',
      '- Mahal/eleman: ${_safe(pour.elementLocation)}',
      '- Planlanan zaman: ${pour.plannedAt}',
      '- Beton sınıfı: ${_safe(pour.concreteClass)}',
      '- Durum: ${pour.status.label}',
      '- Planlanan metraj: ${pour.plannedVolumeM3.toStringAsFixed(2)} m³',
      '- Sipariş metrajı: ${pour.orderedVolumeM3?.toStringAsFixed(2) ?? '-'} m³',
      '- Gelen metraj: ${metrics.actualDeliveredM3.toStringAsFixed(2)} m³',
      '- Fark: ${metrics.varianceM3.toStringAsFixed(2)} m³',
      '',
      '## Planlama',
      '',
      '- Santral: ${_safe(pour.plantName ?? '-')}',
      '- Laboratuvar: ${_safe(pour.laboratoryName ?? '-')}',
      '- Yapı denetim: ${_safe(pour.inspectionNotifiedPerson ?? '-')}',
      '- Pompa/ekipman: ${_safe(pour.pumpEquipment ?? '-')}',
      '',
      '## Döküm öncesi checklist',
      '',
      for (final item in detail.checks)
        '- ${item.sortOrder}. ${_safe(item.label)} — ${item.status.label}'
            '${item.reason == null ? '' : ' — ${_safe(item.reason!)}'}',
      '',
      '## Mikser / irsaliye zaman çizelgesi',
      '',
      for (final truck in detail.trucks)
        '- #${truck.sequenceNo} ${_safe(truck.vehiclePlate)} / '
            '${_safe(truck.deliveryNoteNumber)} — '
            '${truck.volumeM3.toStringAsFixed(2)} m³ — ${truck.result.label}',
      '',
      '## Kanıt manifesti',
      '',
      for (final item in detail.attachments)
        '- ${item.evidenceType.label} | ${_safe(item.originalFileName)} | '
            '${item.byteSize} byte | `${item.sha256}` | '
            '${_safe(item.relativePath)} | ${item.integrity.label}',
      '',
      '## Numuneler',
      '',
      for (final sample in detail.sampleSets)
        '- ${_safe(sample.sampleCode)} — ${sample.sampleCount} adet — '
            '${sample.status.label} — sonuç: '
            '${sample.expectedResultDates.join(', ')}',
      '',
      '## Takipler ve hatırlatıcılar',
      '',
      for (final item in detail.followUps)
        '- ${_safe(item.label)} — ${item.status.label}'
            '${item.dueAt == null ? '' : ' — ${item.dueAt}'}',
      '',
      '## Event özeti',
      '',
      for (final event in detail.events)
        '- ${event.sequence}. `${event.eventType}` — ${event.occurredAt}',
      '',
      '## JSON-ready özet',
      '',
      '```json',
      const JsonEncoder.withIndent('  ').convert(jsonReady(detail)),
      '```',
    ];
    return lines.join('\n');
  }

  static Map<String, Object?> jsonReady(ConcretePourDetail detail) => {
    'pour_id': detail.pour.id,
    'pour_code': detail.pour.pourCode,
    'project_id': detail.pour.projectId,
    'planned_at': detail.pour.plannedAt,
    'status': detail.pour.status.storageValue,
    'planned_volume_m3': detail.pour.plannedVolumeM3,
    'actual_delivered_m3': detail.metrics.actualDeliveredM3,
    'variance_m3': detail.metrics.varianceM3,
    'trucks': detail.trucks
        .map(
          (truck) => {
            'sequence_no': truck.sequenceNo,
            'delivery_note_number': _csvSafe(truck.deliveryNoteNumber),
            'volume_m3': truck.volumeM3,
            'result': truck.result.storageValue,
          },
        )
        .toList(growable: false),
    'attachment_manifest': detail.attachments
        .map(
          (item) => {
            'logical_name': item.relativePath,
            'type': item.evidenceType.storageValue,
            'size': item.byteSize,
            'sha256': item.sha256,
          },
        )
        .toList(growable: false),
  };

  static String truckCsv(ConcretePourDetail detail) {
    final rows = <List<String>>[
      const ['Sıra', 'Plaka', 'İrsaliye', 'Metraj m3', 'Sonuç'],
      ...detail.trucks.map(
        (truck) => [
          '${truck.sequenceNo}',
          truck.vehiclePlate,
          truck.deliveryNoteNumber,
          truck.volumeM3.toStringAsFixed(2),
          truck.result.label,
        ],
      ),
    ];
    return rows
        .map(
          (row) => row
              .map((cell) => '"${_csvSafe(cell).replaceAll('"', '""')}"')
              .join(','),
        )
        .join('\r\n');
  }

  static String humanSummary(ConcretePourDetail detail) =>
      '${detail.pour.pourCode} • ${detail.pour.elementLocation} • '
      '${detail.metrics.actualDeliveredM3.toStringAsFixed(2)} m³ • '
      '${detail.pour.status.label}';

  static String _safe(String input) =>
      input.replaceAll('\r', ' ').replaceAll('\n', ' ');

  static String _csvSafe(String input) =>
      input.isNotEmpty && '=+-@'.contains(input[0]) ? "'$input" : input;
}
