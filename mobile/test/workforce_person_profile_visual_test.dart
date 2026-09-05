import 'dart:async';

import 'package:chief_site_engineer/application/attendance_application.dart';
import 'package:chief_site_engineer/domain/attendance_models.dart';
import 'package:chief_site_engineer/features/attendance/workforce_person_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_attendance_application.dart';

void main() {
  for (final size in [
    const Size(320, 640),
    const Size(390, 844),
    const Size(320, 360),
    const Size(800, 900),
    const Size(1440, 900),
  ]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('profile values and navigation at $size text $scale', (
        tester,
      ) async {
        final attendance = _Attendance();
        await _pump(tester, attendance, size: size, scale: scale);
        final profile = find.byKey(const Key('workforce-person-profile'));
        expect(profile, findsOneWidget);
        expect(tester.getSize(profile).width, lessThanOrEqualTo(840));
        if (size.width > 900) {
          expect(tester.getCenter(profile).dx, closeTo(size.width / 2, 1));
        }
        for (final value in [
          'Ayşe Çok Uzun Soyadlı Demir Ustası',
          'Uzun İsimli İnşaat ve Taahhüt Firması',
          'Demir donatı ve kalıp ustası',
          '2026-07-01',
          '3.5 kişi-gün',
          'Gece ekibinde çalışır. Uzun personel notu eksiksiz okunabilir.',
          'İSG EKSİĞİ VAR',
        ]) {
          final field = find.descendant(
            of: profile,
            matching: find.text(value),
          );
          expect(field, findsOneWidget);
          await Scrollable.ensureVisible(tester.element(field), alignment: 0.5);
          await tester.pumpAndSettle();
          expect(field.hitTestable(), findsOneWidget);
          expect(tester.takeException(), isNull);
        }
        expect(
          find.descendant(of: profile, matching: find.byType(Chip)),
          findsOneWidget,
        );
        expect(find.text('İSG TAM'), findsNothing);
        for (final label in [
          'İSG eksik 1',
          'geçerli 2',
          'yaklaşan 3',
          'geçmiş 4',
          'aktif KKD 0',
        ]) {
          expect(find.text(label), findsNothing);
        }
        expect(find.text('Sağlık raporu'), findsNothing);
        for (final value in [
          'D-01',
          '0555 123 45 67',
          'Şantiye lojmanı',
          'Gece ekibi',
          'Toplam 3.5 kişi-gün',
          '2026-08-08',
        ]) {
          final field = find.text(value);
          await Scrollable.ensureVisible(tester.element(field), alignment: 0.5);
          await tester.pumpAndSettle();
          expect(field.hitTestable(), findsOneWidget);
          expect(tester.takeException(), isNull);
        }
        final history = find.byKey(const Key('workforce-attendance-day-1'));
        expect(
          find.descendant(of: history, matching: find.text('0.5')),
          findsOneWidget,
        );
        expect(find.textContaining('Son kayıt: 2026-08-08'), findsOneWidget);
        final jump = find.byKey(const Key('profile-open-compliance'));
        await tester.ensureVisible(jump);
        await tester.pumpAndSettle();
        await tester.tap(jump);
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('add-compliance-record')), findsOneWidget);
        await tester.scrollUntilVisible(
          find.text('Sağlık raporu'),
          120,
          scrollable: find
              .descendant(
                of: find.byType(ListView),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await tester.pumpAndSettle();
        expect(find.text('Sağlık raporu'), findsOneWidget);
        expect(attendance.calls, ['read:person-1']);
        expect(tester.takeException(), isNull);
        await _tab(tester, 'KKD zimmetleri');
        expect(find.byKey(const Key('add-ppe-assignment')), findsOneWidget);
        await _tab(tester, 'Genel / Puantaj');
        expect(profile, findsOneWidget);
        expect(attendance.calls, ['read:person-1']);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('empty optional values and complete ISG have safe wording', (
    tester,
  ) async {
    final attendance = _Attendance(empty: true, missing: false);
    await _pump(tester, attendance);
    final profile = find.byKey(const Key('workforce-person-profile'));
    expect(
      find.descendant(of: profile, matching: find.text('Belirtilmedi')),
      findsNWidgets(3),
    );
    expect(find.text('İSG TAM'), findsOneWidget);
    expect(find.text('İSG EKSİĞİ VAR'), findsNothing);
    expect(find.byKey(const Key('profile-open-compliance')), findsNothing);
    expect(find.text('0.0 kişi-gün'), findsOneWidget);
    expect(find.text('Henüz Puantaj geçmişi yok.'), findsOneWidget);
    expect(find.text('Belirtilmedi'), findsNWidgets(4));
    expect(attendance.calls, ['read:person-1']);
  });

  testWidgets('loading and failed load remain safe on a short screen', (
    tester,
  ) async {
    final attendance = _Attendance()
      ..pending = Completer<WorkforcePersonDetail>();
    await _pump(
      tester,
      attendance,
      size: const Size(320, 360),
      scale: 2,
      settle: false,
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byKey(const Key('workforce-person-profile')), findsNothing);
    attendance.pending!.completeError(StateError('synthetic load failure'));
    await tester.pumpAndSettle();
    expect(find.text('Personel detayı açılamadı.'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
    expect(attendance.calls, ['read:person-1']);
  });

  testWidgets(
    'compliance create edit archive and PPE assignment keep commands',
    (tester) async {
      final attendance = _Attendance();
      await _pump(tester, attendance, size: const Size(800, 1000));
      await _tab(tester, 'İSG belgeleri');
      await tester.tap(find.byKey(const Key('add-compliance-record')));
      await tester.pumpAndSettle();
      await tester.enterText(_field('Belge numarası'), 'BELGE-42');
      await _saveDialog(tester);
      final created = attendance.complianceCommands.single;
      expect(created.memberId, 'person-1');
      expect(created.expectedRevision, 0);
      expect(created.documentNumber, 'BELGE-42');
      expect(created.documentType, ComplianceDocumentType.employmentEntry);
      expect(created.sourceStatus, ComplianceSourceStatus.valid);
      expect(created.eventId, isNotEmpty);
      await tester.tap(find.byKey(Key('compliance-${created.id}')));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(_field('Belge numarası')).controller!.text,
        'BELGE-42',
      );
      await tester.enterText(_field('Belge numarası'), 'BELGE-43');
      await _saveDialog(tester);
      final edited = attendance.complianceCommands.last;
      expect(edited.id, created.id);
      expect(edited.memberId, created.memberId);
      expect(edited.expectedRevision, 1);
      expect(edited.eventId, isNot(created.eventId));
      expect(edited.documentNumber, 'BELGE-43');
      await tester.tap(
        find.descendant(
          of: find.byKey(Key('compliance-${created.id}')),
          matching: find.byTooltip('Arşivle'),
        ),
      );
      await tester.pumpAndSettle();
      expect(attendance.archiveCommand!.id, created.id);
      expect(attendance.archiveCommand!.expectedRevision, 2);
      expect(attendance.archiveCommand!.eventId, isNot(edited.eventId));
      expect(
        attendance.store.compliance
            .firstWhere((item) => item.id == created.id)
            .archivedAt,
        isNotNull,
      );

      await _tab(tester, 'KKD zimmetleri');
      await tester.tap(find.byKey(const Key('add-ppe-assignment')));
      await tester.pumpAndSettle();
      await tester.enterText(_field('KKD türü *'), 'Baret');
      await _saveDialog(tester);
      final ppe = attendance.ppeCommands.single;
      expect(ppe.memberId, 'person-1');
      expect(ppe.expectedRevision, 0);
      expect(ppe.ppeType, 'Baret');
      expect(ppe.quantity, 1);
      expect(ppe.status, PpeAssignmentStatus.assigned);
      expect(find.text('Baret • 1 adet'), findsOneWidget);
      await tester.tap(find.byKey(Key('ppe-${ppe.id}')));
      await tester.pumpAndSettle();
      await tester.enterText(_field('KKD türü *'), 'Koruyucu baret');
      await _saveDialog(tester);
      final changed = attendance.ppeCommands.last;
      expect(changed.id, ppe.id);
      expect(changed.expectedRevision, 1);
      expect(changed.eventId, isNot(ppe.eventId));
      expect(find.text('Koruyucu baret • 1 adet'), findsOneWidget);
      expect(
        attendance.calls.where((call) => call.startsWith('read:')).length,
        6,
      );
      expect(tester.takeException(), isNull);
    },
  );
}

Finder _field(String label) => find.byWidgetPredicate(
  (widget) => widget is TextField && widget.decoration?.labelText == label,
);

Future<void> _saveDialog(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(FilledButton, 'Kaydet'));
  await tester.pumpAndSettle();
  await tester.pump(kThemeAnimationDuration);
  await tester.pumpAndSettle();
}

Future<void> _tab(WidgetTester tester, String label) async {
  final tab = find.widgetWithText(Tab, label);
  await tester.ensureVisible(tab);
  await tester.pumpAndSettle();
  await tester.tap(tab);
  await tester.pumpAndSettle();
}

Future<void> _pump(
  WidgetTester tester,
  _Attendance attendance, {
  Size size = const Size(390, 844),
  double scale = 1,
  bool settle = true,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: WorkforcePersonDetailPage(
        attendance: attendance,
        memberId: 'person-1',
      ),
    ),
  );
  if (settle) await tester.pumpAndSettle();
}

class _Attendance implements AttendanceApplication {
  _Attendance({this.empty = false, this.missing = true}) {
    store =
        FakeAttendanceApplication(
            members: [
              WorkforceMember(
                id: 'person-1',
                projectId: 'project-1',
                fullName: 'Ayşe Çok Uzun Soyadlı Demir Ustası',
                subcontractorName: empty
                    ? null
                    : 'Uzun İsimli İnşaat ve Taahhüt Firması',
                teamName: empty ? '' : 'Gece ekibi',
                roleName: 'Demir donatı ve kalıp ustası',
                personnelCode: 'D-01',
                phone: '0555 123 45 67',
                address: 'Şantiye lojmanı',
                startedOn: empty ? null : '2026-07-01',
                note: empty
                    ? ' '
                    : 'Gece ekibinde çalışır. Uzun personel notu eksiksiz okunabilir.',
                isActive: true,
                revision: 7,
                createdAt: '2026-07-01',
                updatedAt: '2026-08-08',
                archivedAt: null,
              ),
            ],
          )
          ..compliance = [
            const WorkforceComplianceRecord(
              id: 'health-1',
              memberId: 'person-1',
              documentType: ComplianceDocumentType.healthReport,
              documentNumber: null,
              issuedDate: null,
              expiryDate: null,
              sourceStatus: ComplianceSourceStatus.missing,
              readStatus: ComplianceReadStatus.missing,
              note: null,
              reason: null,
              revision: 1,
              createdAt: '2026-07-01',
              updatedAt: '2026-07-01',
              archivedAt: null,
            ),
          ];
  }
  final bool empty;
  final bool missing;
  late final FakeAttendanceApplication store;
  final calls = <String>[];
  final complianceCommands = <SaveComplianceRecordCommand>[];
  final ppeCommands = <SavePpeAssignmentCommand>[];
  ArchiveComplianceRecordCommand? archiveCommand;
  Completer<WorkforcePersonDetail>? pending;

  @override
  Future<WorkforcePersonDetail> getPersonDetail(String memberId) async {
    calls.add('read:$memberId');
    if (pending != null) return pending!.future;
    final detail = await store.getPersonDetail(memberId);
    return WorkforcePersonDetail(
      member: detail.member,
      compliance: detail.compliance,
      ppeAssignments: detail.ppeAssignments,
      missingComplianceCount: missing ? 1 : 0,
      validComplianceCount: 2,
      expiringComplianceCount: 3,
      expiredComplianceCount: 4,
      activePpeCount: detail.activePpeCount,
      attendanceSummary: empty
          ? const WorkforceAttendanceSummary.empty()
          : const WorkforceAttendanceSummary(
              personDayEquivalentTotal: 3.5,
              recentDays: [
                WorkforceAttendanceDay(
                  attendanceDayId: 'day-1',
                  localDate: '2026-08-08',
                  dayStatus: AttendanceDayStatus.completed,
                  result: AttendanceResult.halfDay,
                ),
              ],
            ),
    );
  }

  @override
  Future<WorkforceComplianceRecord> saveComplianceRecord(
    SaveComplianceRecordCommand command,
  ) {
    calls.add('save-compliance');
    complianceCommands.add(command);
    return store.saveComplianceRecord(command);
  }

  @override
  Future<WorkforceComplianceRecord> archiveComplianceRecord(
    ArchiveComplianceRecordCommand command,
  ) {
    calls.add('archive-compliance');
    archiveCommand = command;
    return store.archiveComplianceRecord(command);
  }

  @override
  Future<WorkforcePpeAssignment> savePpeAssignment(
    SavePpeAssignmentCommand command,
  ) {
    calls.add('save-ppe');
    ppeCommands.add(command);
    return store.savePpeAssignment(command);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Unexpected application call: ${invocation.memberName}');
}
