import 'package:chief_site_engineer/domain/attendance_models.dart';
import 'package:chief_site_engineer/features/attendance/workforce_compliance_summary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'empty and archived-only records remain unassessed in all five categories',
    () {
      for (final records in [
        <WorkforceComplianceRecord>[],
        [_record('archived', archivedAt: '2026-09-01T08:00:00Z')],
      ]) {
        final summary = WorkforceComplianceSummary(records);
        expect(summary.signals, [WorkforceComplianceSummary.emptyLabel]);
        expect(
          summary.categories.map((category) => category.type),
          ComplianceDocumentType.values,
        );
        expect(
          summary.categories.every((category) => category.records.isEmpty),
          isTrue,
        );
      }
    },
  );

  test('missing expired expiring are independent recorded signals', () {
    final cases = [
      (
        _record(
          'missing',
          source: ComplianceSourceStatus.missing,
          read: ComplianceReadStatus.missing,
        ),
        'Eksik olarak işaretlenmiş kayıt var',
      ),
      (
        _record(
          'expired',
          read: ComplianceReadStatus.expired,
          expiry: '2026-09-01',
        ),
        'Süresi geçmiş kayıt var',
      ),
      (
        _record(
          'expiring',
          read: ComplianceReadStatus.expiring,
          expiry: '2026-09-30',
        ),
        'Süresi yaklaşan kayıt var',
      ),
    ];
    for (final value in cases) {
      expect(WorkforceComplianceSummary([value.$1]).signals, [value.$2]);
    }
    final mixed = WorkforceComplianceSummary(cases.map((value) => value.$1));
    expect(mixed.signals, containsAll(cases.map((value) => value.$2)));
    expect(mixed.signals, isNot(contains('Mevcut kayıtlarda uyarı yok')));
  });

  test('valid no-expiry and empty details are neutral recorded facts', () {
    for (final record in [
      _record('undated'),
      _record('without-details', emptyDetails: true),
    ]) {
      final summary = WorkforceComplianceSummary([record]);
      expect(record.expiryDate, isNull);
      expect(summary.signals, ['Mevcut kayıtlarda uyarı yok']);
      expect(summary.categories.first.records, [record]);
      expect(WorkforceComplianceSummary.dateWarning(record.readStatus), isNull);
      expect(
        WorkforceComplianceSummary.sourceLabel(record.sourceStatus),
        'Kullanıcı kaydı: geçerli olarak işaretlendi',
      );
    }
  });

  test(
    'source not-applicable and exception remain distinct despite shared read status',
    () {
      final records = [
        _record(
          'na',
          source: ComplianceSourceStatus.notApplicable,
          read: ComplianceReadStatus.exception,
          reason: 'Kullanıcının uygulanamaz gerekçesi',
        ),
        _record(
          'exception',
          source: ComplianceSourceStatus.exception,
          read: ComplianceReadStatus.exception,
          reason: 'Kullanıcının istisna gerekçesi',
        ),
      ];
      final summary = WorkforceComplianceSummary(records);
      expect(
        summary.signals,
        containsAll([
          'Uygulanamaz olarak işaretlenmiş kayıt: 1',
          'İstisna olarak işaretlenmiş kayıt: 1',
        ]),
      );
      expect(summary.categories.first.records, orderedEquals(records));
      expect(summary.categories.first.records.map((item) => item.reason), [
        'Kullanıcının uygulanamaz gerekçesi',
        'Kullanıcının istisna gerekçesi',
      ]);
      expect(
        WorkforceComplianceSummary.sourceLabel(
          ComplianceSourceStatus.notApplicable,
        ),
        'Uygulanamaz olarak işaretlendi',
      );
      expect(
        WorkforceComplianceSummary.sourceLabel(
          ComplianceSourceStatus.exception,
        ),
        'İstisna olarak işaretlendi',
      );
    },
  );

  test(
    'duplicate valid valid and valid expired rows retain identities and all signals in any order',
    () {
      final valid = _record('valid', expiry: '2027-01-01');
      for (final sibling in [
        _record('valid-2', expiry: '2027-02-01'),
        _record(
          'expired',
          read: ComplianceReadStatus.expired,
          expiry: '2026-01-01',
        ),
        _record(
          'missing',
          source: ComplianceSourceStatus.missing,
          read: ComplianceReadStatus.missing,
        ),
        _record(
          'exception',
          source: ComplianceSourceStatus.exception,
          read: ComplianceReadStatus.exception,
        ),
        _record(
          'na',
          source: ComplianceSourceStatus.notApplicable,
          read: ComplianceReadStatus.exception,
        ),
      ]) {
        final records = [valid, sibling];
        final forward = WorkforceComplianceSummary(records);
        final reversed = WorkforceComplianceSummary(records.reversed);
        expect(forward.categories.first.hasMultipleRecords, isTrue);
        expect(forward.categories.first.records, orderedEquals(records));
        expect(
          reversed.categories.first.records,
          orderedEquals(records.reversed),
        );
        expect(forward.signals, reversed.signals);
        expect(
          forward.signals,
          contains('Aynı türde birden fazla aktif kayıt var'),
        );
        expect(
          identical(forward.categories.first.records.first, valid),
          isTrue,
        );
        expect(
          () => forward.categories.first.records.clear(),
          throwsUnsupportedError,
        );
        expect(records, hasLength(2));
      }
    },
  );

  test(
    'helper consumes supplied read status without calculating dates or completeness',
    () {
      // Deliberately unrelated dates establish that this presenter is not a clock.
      final valid = _record('record', expiry: '1900-01-01');
      expect(WorkforceComplianceSummary([valid]).signals, [
        'Mevcut kayıtlarda uyarı yok',
      ]);
      expect(
        WorkforceComplianceSummary.sourceLabel(valid.sourceStatus),
        'Kullanıcı kaydı: geçerli olarak işaretlendi',
      );
      expect(WorkforceComplianceSummary.dateWarning(valid.readStatus), isNull);
      final expired = _record(
        'record-2',
        expiry: '2999-01-01',
        read: ComplianceReadStatus.expired,
      );
      expect(WorkforceComplianceSummary([expired]).signals, [
        'Süresi geçmiş kayıt var',
      ]);
      expect(
        WorkforceComplianceSummary.dateWarning(expired.readStatus),
        'Süresi geçmiş',
      );
      expect(
        WorkforceComplianceSummary.dateWarning(ComplianceReadStatus.expiring),
        'Süresi yaklaşıyor',
      );
    },
  );
}

WorkforceComplianceRecord _record(
  String id, {
  ComplianceSourceStatus source = ComplianceSourceStatus.valid,
  ComplianceReadStatus read = ComplianceReadStatus.valid,
  String? expiry,
  String? reason,
  String? archivedAt,
  bool emptyDetails = false,
}) => WorkforceComplianceRecord(
  id: id,
  memberId: 'person-1',
  documentType: ComplianceDocumentType.employmentEntry,
  documentNumber: emptyDetails ? null : 'Belge $id',
  issuedDate: emptyDetails ? null : '2026-01-01',
  expiryDate: expiry,
  sourceStatus: source,
  readStatus: read,
  note: emptyDetails ? null : 'Not $id',
  reason: reason,
  revision: 7,
  createdAt: '2026-01-01T08:00:00Z',
  updatedAt: '2026-09-01T08:00:00Z',
  archivedAt: archivedAt,
);
