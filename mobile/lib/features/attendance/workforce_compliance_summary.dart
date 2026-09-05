import 'package:chief_site_engineer/domain/attendance_models.dart';

/// Presents recorded facts only; dates and applicability are not evaluated here.
class WorkforceComplianceSummary {
  WorkforceComplianceSummary(Iterable<WorkforceComplianceRecord> records)
    : categories = List.unmodifiable([
        for (final type in ComplianceDocumentType.values)
          WorkforceComplianceCategory(
            type,
            records.where(
              (record) =>
                  record.archivedAt == null && record.documentType == type,
            ),
          ),
      ]);

  static const emptyLabel = 'Kayıt yok / değerlendirilmedi';
  static const scopeLabel =
      'Bu özet yalnız kaydedilen bilgileri gösterir; gereklilikler değerlendirilmedi.';
  static const duplicateLabel = 'Bu türde birden fazla aktif kayıt var';
  static const noExpiryLabel = 'Son geçerlilik tarihi girilmemiş';

  final List<WorkforceComplianceCategory> categories;

  List<String> get signals {
    final active = categories.expand((category) => category.records).toList();
    if (active.isEmpty) return const [emptyLabel];
    final notApplicable = active
        .where(
          (record) =>
              record.sourceStatus == ComplianceSourceStatus.notApplicable,
        )
        .length;
    final exceptions = active
        .where(
          (record) => record.sourceStatus == ComplianceSourceStatus.exception,
        )
        .length;
    final messages = [
      if (active.any(
        (record) => record.sourceStatus == ComplianceSourceStatus.missing,
      ))
        'Eksik olarak işaretlenmiş kayıt var',
      if (active.any(
        (record) => record.readStatus == ComplianceReadStatus.expired,
      ))
        'Süresi geçmiş kayıt var',
      if (active.any(
        (record) => record.readStatus == ComplianceReadStatus.expiring,
      ))
        'Süresi yaklaşan kayıt var',
      if (notApplicable > 0)
        'Uygulanamaz olarak işaretlenmiş kayıt: $notApplicable',
      if (exceptions > 0) 'İstisna olarak işaretlenmiş kayıt: $exceptions',
      if (categories.any((category) => category.hasMultipleRecords))
        'Aynı türde birden fazla aktif kayıt var',
      if (active.any(
        (record) =>
            record.sourceStatus == ComplianceSourceStatus.valid &&
            record.expiryDate == null,
      ))
        'Son geçerlilik tarihi girilmemiş kayıt var',
    ];
    return messages.isEmpty ? const ['Mevcut kayıtlarda uyarı yok'] : messages;
  }

  static String sourceLabel(ComplianceSourceStatus status) => switch (status) {
    ComplianceSourceStatus.valid =>
      'Kullanıcı kaydı: geçerli olarak işaretlendi',
    ComplianceSourceStatus.missing => 'Eksik olarak işaretlendi',
    ComplianceSourceStatus.notApplicable => 'Uygulanamaz olarak işaretlendi',
    ComplianceSourceStatus.exception => 'İstisna olarak işaretlendi',
  };

  static String? dateWarning(ComplianceReadStatus status) => switch (status) {
    ComplianceReadStatus.expired => 'Süresi geçmiş',
    ComplianceReadStatus.expiring => 'Süresi yaklaşıyor',
    _ => null,
  };
}

class WorkforceComplianceCategory {
  WorkforceComplianceCategory(
    this.type,
    Iterable<WorkforceComplianceRecord> records,
  ) : records = List.unmodifiable(records);

  final ComplianceDocumentType type;
  final List<WorkforceComplianceRecord> records;
  bool get hasMultipleRecords => records.length > 1;
}
