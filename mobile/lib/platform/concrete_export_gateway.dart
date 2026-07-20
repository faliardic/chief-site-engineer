import 'dart:convert';
import 'dart:io';

import 'package:chief_site_engineer/core/time/cse_time_codec.dart';
import 'package:chief_site_engineer/domain/concrete_models.dart';
import 'package:chief_site_engineer/platform/export_gateway.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

abstract interface class ConcreteExportGateway {
  Future<Uint8List> renderPdf(ConcretePourDetail detail, String generatedAt);

  Future<String> stage(String fileName, Uint8List bytes);
  Future<void> verify(String absolutePath);
  Future<void> cleanup(String absolutePath);
  Future<void> share(String absolutePath, String summary);
  Future<bool> save(String fileName, String absolutePath);
}

class UnavailableConcreteExportGateway implements ConcreteExportGateway {
  const UnavailableConcreteExportGateway();

  @override
  Future<void> cleanup(String absolutePath) async {}

  @override
  Future<Uint8List> renderPdf(ConcretePourDetail detail, String generatedAt) =>
      throw StateError('concrete PDF rendering unavailable');

  @override
  Future<bool> save(String fileName, String absolutePath) {
    throw StateError('concrete export storage unavailable');
  }

  @override
  Future<void> share(String absolutePath, String summary) {
    throw StateError('concrete export sharing unavailable');
  }

  @override
  Future<String> stage(String fileName, Uint8List bytes) {
    throw StateError('concrete export storage unavailable');
  }

  @override
  Future<void> verify(String absolutePath) {
    throw StateError('concrete PDF verification unavailable');
  }
}

class DeviceConcreteExportGateway implements ConcreteExportGateway {
  const DeviceConcreteExportGateway({required this.stager});

  final LocalExportStager stager;

  @override
  Future<Uint8List> renderPdf(
    ConcretePourDetail detail,
    String generatedAt,
  ) async {
    final regular = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
    final bold = await rootBundle.load('assets/fonts/Roboto-Bold.ttf');
    return ConcretePackageReportFormatter.pdfBytes(
      detail,
      generatedAt: generatedAt,
      regularFont: regular,
      boldFont: bold,
    );
  }

  @override
  Future<String> stage(String fileName, Uint8List bytes) async =>
      (await stager.stage(fileName, bytes)).path;

  @override
  Future<void> verify(String absolutePath) async {
    final file = _checkedStagedFile(absolutePath);
    if (!await file.exists()) throw StateError('staged PDF is missing');
    final bytes = await file.readAsBytes();
    if (!ConcretePackageReportFormatter.isStructurallyValidPdf(bytes)) {
      throw StateError('staged PDF verification failed');
    }
  }

  @override
  Future<void> cleanup(String absolutePath) async {
    final file = _checkedStagedFile(absolutePath);
    if (await file.exists()) await file.delete();
  }

  @override
  Future<void> share(String absolutePath, String summary) async {
    final file = _checkedStagedFile(absolutePath);
    if (!await file.exists()) throw StateError('concrete PDF is missing');
    await SharePlus.instance.share(
      ShareParams(
        title: 'Beton Paketi PDF Raporu',
        subject: 'Beton Paketi PDF Raporu',
        text: summary,
        files: [XFile(file.path, mimeType: 'application/pdf')],
      ),
    );
  }

  @override
  Future<bool> save(String fileName, String absolutePath) async {
    final file = _checkedStagedFile(absolutePath);
    if (!await file.exists()) throw StateError('concrete PDF is missing');
    final selected = await FilePicker.platform.saveFile(
      dialogTitle: 'Beton PDF raporunu kaydet',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      bytes: await file.readAsBytes(),
    );
    return selected != null && selected.trim().isNotEmpty;
  }

  File _checkedStagedFile(String absolutePath) {
    stager.directories.validate();
    final root = path.normalize(
      path.absolute(stager.directories.exportsBackups.path),
    );
    final candidate = path.normalize(path.absolute(absolutePath));
    if (!path.isWithin(root, candidate)) {
      throw StateError('concrete export path escaped root');
    }
    return File(candidate);
  }
}

class ConcretePackageReportFormatter {
  ConcretePackageReportFormatter._();

  static Future<Uint8List> pdfBytes(
    ConcretePourDetail detail, {
    required String generatedAt,
    required ByteData regularFont,
    required ByteData boldFont,
  }) async {
    final normal = pw.Font.ttf(regularFont);
    final bold = pw.Font.ttf(boldFont);
    final document = pw.Document(
      version: PdfVersion.pdf_1_5,
      compress: true,
      title: 'Beton Paketi ${detail.pour.pourCode}',
      author: 'Chief Site Engineer',
      creator: 'Chief Site Engineer Mobile',
    );
    final theme = pw.ThemeData.withFont(base: normal, bold: bold);
    final pour = detail.pour;
    final metrics = detail.metrics;
    final targetDifference = metrics.isTargetExceeded
        ? 'Aşılan: ${formatM3(metrics.excessM3)} m³'
        : 'Kalan: ${formatM3(metrics.remainingM3)} m³';
    final pendingChecks = detail.checks
        .where((item) => item.status == ConcreteCheckStatus.pending)
        .length;
    final pendingFollowUps = detail.followUps
        .where((item) => item.status == ConcreteFollowUpStatus.pending)
        .length;
    final deliveryScans = detail.attachments
        .where(
          (item) =>
              item.evidenceType == ConcreteEvidenceType.deliveryNoteScan ||
              item.evidenceType == ConcreteEvidenceType.deliveryReceiptScan,
        )
        .length;
    final mixerPhotos = detail.attachments
        .where((item) => item.evidenceType == ConcreteEvidenceType.mixerPhoto)
        .length;

    document.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          theme: theme,
        ),
        header: (context) => pw.Container(
          padding: const pw.EdgeInsets.only(bottom: 8),
          decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey400)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'BETON PAKETİ RAPORU',
                style: pw.TextStyle(font: bold, fontSize: 14),
              ),
              pw.Text(pour.pourCode),
            ],
          ),
        ),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Sayfa ${context.pageNumber}/${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
          ),
        ),
        build: (context) => [
          pw.SizedBox(height: 12),
          _pdfSectionTitle('Paket bilgileri', bold),
          _pdfKeyValues([
            ['Proje', _safe(pour.projectName)],
            ['Beton kodu', _safe(pour.pourCode)],
            ['Eleman / mahal', _safe(pour.elementLocation)],
            ['Planlanan tarih', CseTimeCodec.formatIstanbul(pour.plannedAt)],
            ['Beton sınıfı', _safe(pour.concreteClass)],
            ['Santral', _safe(pour.plantName ?? '—')],
            ['Laboratuvar', _safe(pour.laboratoryName ?? '—')],
            ['Durum', pour.status.label],
          ], bold),
          pw.SizedBox(height: 10),
          _pdfSectionTitle('Canlı metraj', bold),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            color: PdfColors.grey100,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Hedef: ${formatM3(pour.plannedVolumeM3)} m³'),
                pw.Text('Dökülen: ${formatM3(metrics.actualDeliveredM3)} m³'),
                pw.Text(targetDifference, style: pw.TextStyle(font: bold)),
              ],
            ),
          ),
          pw.SizedBox(height: 10),
          _pdfSectionTitle('Checklist ve takip özeti', bold),
          pw.Text(
            'Checklist: ${detail.checks.length - pendingChecks} tamam/sonuçlandırılmış, '
            '$pendingChecks açık • Takip: '
            '${detail.followUps.length - pendingFollowUps} tamam/sonuçlandırılmış, '
            '$pendingFollowUps açık',
          ),
          pw.SizedBox(height: 10),
          _pdfSectionTitle('Mikserler', bold),
          if (detail.trucks.isEmpty)
            pw.Text('Mikser kaydı yok.')
          else
            pw.TableHelper.fromTextArray(
              headers: const [
                'Sıra',
                'Plaka',
                'İrsaliye',
                'Geliş',
                'Boşaltma',
                'm³',
                'Sonuç',
              ],
              data: detail.trucks
                  .map(
                    (truck) => [
                      '${truck.sequenceNo}',
                      _safe(truck.vehiclePlate),
                      _safe(truck.deliveryNoteNumber ?? '—'),
                      truck.arrivedAt == null
                          ? '—'
                          : CseTimeCodec.formatIstanbul(truck.arrivedAt!),
                      truck.unloadingEndedAt == null
                          ? '—'
                          : CseTimeCodec.formatIstanbul(
                              truck.unloadingEndedAt!,
                            ),
                      formatM3(truck.volumeM3),
                      truck.result.label,
                    ],
                  )
                  .toList(growable: false),
              headerStyle: pw.TextStyle(font: bold, fontSize: 8),
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellAlignment: pw.Alignment.centerLeft,
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey300,
              ),
            ),
          pw.SizedBox(height: 10),
          _pdfSectionTitle('Numune setleri', bold),
          if (detail.sampleSets.isEmpty)
            pw.Text('Numune seti yok.')
          else
            ...detail.sampleSets.map(
              (sample) => pw.Bullet(
                text:
                    '${_safe(sample.sampleCode)} — ${sample.sampleCount} adet — '
                    '${sample.status.label}',
              ),
            ),
          pw.SizedBox(height: 10),
          _pdfSectionTitle('Belge ve fotoğraf özeti', bold),
          pw.Text(
            'Toplam attachment: ${detail.attachments.length} • '
            'İrsaliye taraması: $deliveryScans • Mikser fotoğrafı: $mixerPhotos',
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            'Oluşturulma zamanı: ${CseTimeCodec.formatIstanbul(generatedAt)}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
        ],
      ),
    );
    return Uint8List.fromList(await document.save());
  }

  static pw.Widget _pdfSectionTitle(String value, pw.Font bold) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 5),
    child: pw.Text(value, style: pw.TextStyle(font: bold, fontSize: 12)),
  );

  static pw.Widget _pdfKeyValues(List<List<String>> rows, pw.Font bold) =>
      pw.Table(
        columnWidths: const {
          0: pw.FixedColumnWidth(120),
          1: pw.FlexColumnWidth(),
        },
        children: rows
            .map(
              (row) => pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 2),
                    child: pw.Text(row[0], style: pw.TextStyle(font: bold)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 2),
                    child: pw.Text(row[1]),
                  ),
                ],
              ),
            )
            .toList(growable: false),
      );

  static bool isStructurallyValidPdf(List<int> bytes) {
    if (bytes.length < 20) return false;
    final header = ascii.decode(bytes.take(5).toList(), allowInvalid: true);
    final tailStart = bytes.length > 64 ? bytes.length - 64 : 0;
    final tail = ascii.decode(bytes.sublist(tailStart), allowInvalid: true);
    return header == '%PDF-' && tail.contains('%%EOF');
  }

  static String formatM3(double value) =>
      value.toStringAsFixed(2).replaceAll('.', ',');

  static String truckCsv(ConcretePourDetail detail) {
    final rows = <List<String>>[
      const ['Sıra', 'Plaka', 'İrsaliye', 'Metraj m3', 'Sonuç'],
      ...detail.trucks.map(
        (truck) => [
          '${truck.sequenceNo}',
          truck.vehiclePlate,
          truck.deliveryNoteNumber ?? '—',
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
      '${formatM3(detail.metrics.actualDeliveredM3)} m³ • '
      '${detail.pour.status.label}';

  static String _safe(String input) =>
      input.replaceAll('\r', ' ').replaceAll('\n', ' ');

  static String _csvSafe(String input) =>
      input.isNotEmpty && '=+-@'.contains(input[0]) ? "'$input" : input;
}
