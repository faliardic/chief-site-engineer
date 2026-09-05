import 'dart:async';

import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/domain/attendance_models.dart';
import 'package:chief_site_engineer/features/attendance/attendance_day_page.dart';
import 'package:chief_site_engineer/platform/attendance_export_gateway.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_agenda_application.dart';
import 'support/fake_attendance_application.dart';

Finder _key(String value) => find.byKey(Key(value));
Finder get _addTitle => find.descendant(
  of: _key('attendance-add-people'),
  matching: find.text('Personel ekle'),
);
Finder get _detailsTitle => find.descendant(
  of: _key('attendance-member-details-person-a'),
  matching: find.text('FM ve not'),
);

void main() {
  for (final size in [
    const Size(320, 640),
    const Size(390, 844),
    const Size(320, 360),
    const Size(800, 900),
    const Size(1440, 900),
  ]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('selected roster and optional detail fit $size text $scale', (
        tester,
      ) async {
        final attendance = await _fixture();
        await _pump(tester, attendance, size: size, scale: scale);
        expect(_key('attendance-member-person-a'), findsOneWidget);
        expect(_key('attendance-subcontractor-selector'), findsNothing);
        expect(_key('attendance-overtime-person-a'), findsNothing);
        expect(_key('attendance-note-person-a'), findsNothing);
        expect(_key('attendance-result-person-a'), findsOneWidget);
        expect(
          tester.getTopLeft(_key('attendance-member-person-a')).dy,
          lessThan(tester.getTopLeft(_key('attendance-add-people')).dy),
        );
        expect(
          tester.getSize(_key('attendance-member-person-a')).width,
          lessThanOrEqualTo(840),
        );
        for (final key in [
          'mark-all-full',
          'mark-team-full',
          'remove-attendance-person-a',
          'save-attendance-draft',
          'attendance-no-work',
          'complete-attendance-day',
        ]) {
          await _reveal(tester, _key(key));
          expect(_key(key).hitTestable(), findsOneWidget);
          expect(tester.getSize(_key(key)).height, greaterThanOrEqualTo(48));
          expect(tester.getSize(_key(key)).width, greaterThanOrEqualTo(48));
          expect(tester.takeException(), isNull);
        }
        await _tap(tester, _detailsTitle);
        await _reveal(tester, _key('attendance-note-person-a'));
        expect(_key('attendance-note-person-a').hitTestable(), findsOneWidget);
        expect(
          tester
              .widget<TextField>(_key('attendance-overtime-person-a'))
              .controller!
              .text,
          '30',
        );
        expect(
          tester
              .widget<TextField>(_key('attendance-note-person-a'))
              .controller!
              .text,
          'Mevcut not',
        );
        await _tap(tester, _detailsTitle);
        await _tap(tester, _addTitle);
        expect(find.text('İşveren seç *'), findsOneWidget);
        expect(find.text('Taşeron seç *'), findsNothing);
        await _reveal(tester, _key('attendance-subcontractor-selector'));
        expect(tester.takeException(), isNull);
        expect(attendance.reads, [
          'day:day-a',
          'members:project-a',
          'employers:project-a',
        ]);
      });
    }
  }

  testWidgets(
    'FM note and general note survive collapse rebuild failed save and retry',
    (tester) async {
      final attendance = await _fixture();
      await _pump(tester, attendance);
      await _tap(tester, _detailsTitle);
      final overtime = tester
          .widget<TextField>(_key('attendance-overtime-person-a'))
          .controller!;
      final note = tester
          .widget<TextField>(_key('attendance-note-person-a'))
          .controller!;
      await tester.enterText(_key('attendance-overtime-person-a'), '75');
      await tester.enterText(_key('attendance-note-person-a'), 'Korunan not');
      await _tap(tester, _detailsTitle);
      await _tap(tester, _key('attendance-result-person-a'));
      await tester.tap(find.text('Yarım gün').last);
      await tester.pumpAndSettle();
      await _tap(tester, _detailsTitle);
      expect(
        tester
            .widget<TextField>(_key('attendance-overtime-person-a'))
            .controller,
        same(overtime),
      );
      expect(
        tester.widget<TextField>(_key('attendance-note-person-a')).controller,
        same(note),
      );
      expect(overtime.text, '75');
      expect(note.text, 'Korunan not');
      await _tap(tester, _detailsTitle);
      await tester.enterText(_key('attendance-general-note'), 'Gün notu');
      attendance.saveFailure = const AgendaValidationFailure(
        'Revision değişti; yeniden deneyin.',
      );
      await _tap(tester, _key('save-attendance-draft'));
      final first = attendance.lastRosterCommand!;
      expect(first.expectedRevision, 7);
      expect(first.dayId, 'day-a');
      expect(first.values.single.entryId, 'entry-a');
      expect(first.values.single.memberId, 'person-a');
      expect(first.values.single.result, AttendanceResult.halfDay);
      expect(first.values.single.overtimeMinutes, 75);
      expect(first.values.single.shortNote, 'Korunan not');
      expect(first.generalNote, 'Gün notu');
      expect(first.replaceGeneralNote, isTrue);
      expect(find.text('Revision değişti; yeniden deneyin.'), findsOneWidget);
      expect(overtime.text, '75');
      expect(note.text, 'Korunan not');
      attendance.saveFailure = null;
      await _tap(tester, _key('save-attendance-draft'));
      expect(attendance.lastRosterCommand!.eventId, first.eventId);
      expect(attendance.detail!.day.revision, 8);
      expect(attendance.detail!.entries.single.overtimeMinutes, 75);
      expect(attendance.detail!.entries.single.shortNote, 'Korunan not');
    },
  );

  testWidgets(
    'empty roster employer team candidate selection and draft discard keep identity',
    (tester) async {
      final attendance = await _fixture(empty: true);
      await _pump(tester, attendance);
      expect(find.text('İşveren seç *'), findsOneWidget);
      await _tap(tester, _key('attendance-subcontractor-selector'));
      await tester.tap(find.text('Firma A').last);
      await tester.pumpAndSettle();
      expect(attendance.teamQueries, ['project-a:employer-a']);
      await _tap(tester, _key('attendance-team-filter'));
      await tester.tap(find.text('Ekip A').last);
      await tester.pumpAndSettle();
      await _tap(tester, _key('add-attendance-member-person-a'));
      expect(_key('attendance-member-person-a'), findsOneWidget);
      expect(attendance.saveCalls, 0);
      expect(attendance.removals, isEmpty);
      await _tap(tester, _key('remove-attendance-person-a'));
      expect(_key('attendance-member-person-a'), findsNothing);
      expect(attendance.removals, isEmpty);
      await _tap(tester, _key('add-attendance-member-person-a'));
      await _tap(tester, _key('save-attendance-draft'));
      expect(attendance.lastRosterCommand!.values.single.memberId, 'person-a');
      expect(
        attendance.lastRosterCommand!.values.single.result,
        AttendanceResult.fullDay,
      );
      final entry = attendance.detail!.entries.single;
      await _tap(tester, _key('remove-attendance-person-a'));
      expect(attendance.removals.single.entryId, entry.id);
      expect(attendance.removals.single.expectedRevision, 8);
      expect(attendance.removals.single.dayId, 'day-a');
      expect(attendance.removals.single.eventId, isNotEmpty);
    },
  );

  testWidgets(
    'bulk and transitions keep exact revision event and team commands',
    (tester) async {
      final attendance = await _fixture();
      await _pump(tester, attendance);
      await _tap(tester, _key('mark-team-full'));
      await _tap(tester, _key('mark-team-full-team-a'));
      final team = attendance.bulk.single;
      expect(team.teamId, 'team-a');
      expect(team.expectedRevision, 7);
      expect(team.dayId, 'day-a');
      expect(team.eventId, isNotEmpty);
      await _tap(tester, _key('mark-all-full'));
      expect(attendance.bulk.last.teamId, isNull);
      expect(attendance.bulk.last.expectedRevision, 8);
      expect(attendance.bulk.last.eventId, isNot(team.eventId));
      for (final step in [
        ('complete-attendance-day', AttendanceTransition.complete),
        ('reopen-attendance-day', AttendanceTransition.reopen),
        ('attendance-no-work', AttendanceTransition.noWork),
      ]) {
        final revision = attendance.detail!.day.revision;
        await _tap(tester, _key(step.$1));
        await _tap(tester, _key('confirm-attendance-transition'));
        final command = attendance.transitions.last;
        expect(command.dayId, 'day-a');
        expect(command.expectedRevision, revision);
        expect(command.transition, step.$2);
        expect(command.dayEventId, isNotEmpty);
        expect(command.reminderEventId, isNotEmpty);
      }
      expect(attendance.transitions.map((c) => c.dayEventId).toSet().length, 3);
      expect(
        attendance.transitions.map((c) => c.reminderEventId).toSet().length,
        3,
      );
      expect(_key('reopen-attendance-day'), findsOneWidget);
    },
  );

  testWidgets(
    'inline new member keeps employer team fields and existing warning',
    (tester) async {
      final attendance = await _fixture(empty: true);
      await _pump(tester, attendance);
      await _tap(tester, _key('attendance-subcontractor-selector'));
      await tester.tap(find.text('Firma A').last);
      await tester.pumpAndSettle();
      await _tap(tester, _key('attendance-new-member'));
      expect(find.text('İşveren: Firma A'), findsOneWidget);
      await tester.enterText(
        _key('attendance-inline-member-name'),
        'Yeni Personel',
      );
      await tester.enterText(_key('attendance-inline-member-role'), 'Usta');
      await tester.enterText(_key('attendance-inline-member-phone'), '0555 11');
      await tester.enterText(_key('attendance-inline-member-code'), 'K-02');
      await _tap(tester, _key('save-attendance-inline-member'));
      final command = attendance.lastCreateMemberCommand!;
      expect(command.projectId, 'project-a');
      expect(command.subcontractorId, 'employer-a');
      expect(command.teamId, 'team-a');
      expect(command.fullName, 'Yeni Personel');
      expect(command.roleName, 'Usta');
      expect(command.phone, '0555 11');
      expect(command.personnelCode, 'K-02');
      expect(command.eventId, isNotEmpty);
      expect(_key('attendance-member-${command.id}'), findsOneWidget);
      expect(_key('attendance-new-member-warning'), findsOneWidget);
      expect(find.text('Yeni personel Sicil’e kaydedildi'), findsOneWidget);
      expect(
        find.textContaining('SGK işe giriş ve İSG/OSGB kayıtlarını Sicil’den'),
        findsOneWidget,
      );
      expect(attendance.saveCalls, 0);
    },
  );

  testWidgets(
    'loading and failed day read remain safe on short enlarged screen',
    (tester) async {
      final attendance = await _fixture();
      attendance.pending = Completer<AttendanceDayDetail>();
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 360);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: AttendanceDayPage(
            attendance: attendance,
            agenda: FakeAgendaApplication(),
            dayId: 'day-a',
          ),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      attendance.pending!.completeError(StateError('synthetic load failure'));
      await tester.pumpAndSettle();
      expect(find.text('Puantaj günü açılamadı.'), findsOneWidget);
      expect(attendance.reads, ['day:day-a']);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('CSV share copy and history retain outputs and commands', (
    tester,
  ) async {
    final attendance = await _fixture();
    await _pump(tester, attendance);
    expect(_key('attendance-summary'), findsOneWidget);
    await _tap(tester, _key('save-attendance-csv'));
    await _tap(tester, _key('share-attendance-csv'));
    expect(attendance.exports.map((e) => e.$2), [false, true]);
    expect(attendance.exports.map((e) => e.$1.dayId).toSet(), {'day-a'});
    expect(attendance.exports.map((e) => e.$1.expectedRevision).toSet(), {7});
    expect(
      attendance.exports.first.$1.eventId,
      isNot(attendance.exports.last.$1.eventId),
    );
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await _tap(tester, _key('copy-attendance-summary'));
    expect(copied, AttendanceCsvFormatter.humanSummary(attendance.detail!));
    for (var notice = 0; notice < 3; notice++) {
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    }
    await _tap(
      tester,
      find.descendant(
        of: _key('attendance-event-history'),
        matching: find.text('Değişiklik geçmişi (1)'),
      ),
    );
    expect(find.text('fixture_event'), findsOneWidget);
  });
}

Future<void> _reveal(WidgetTester tester, Finder target) async {
  await tester.pumpAndSettle();
  await Scrollable.ensureVisible(tester.element(target), alignment: 0.5);
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, Finder target) async {
  await _reveal(tester, target);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> _pump(
  WidgetTester tester,
  _Attendance attendance, {
  Size size = const Size(390, 844),
  double scale = 1,
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
      home: AttendanceDayPage(
        attendance: attendance,
        agenda: FakeAgendaApplication(),
        dayId: 'day-a',
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<_Attendance> _fixture({bool empty = false}) async {
  final attendance = _Attendance();
  await attendance.createSubcontractor(
    const CreateSubcontractorCommand(
      id: 'employer-a',
      eventId: 'seed-e',
      projectId: 'project-a',
      name: 'Firma A',
    ),
  );
  await attendance.createTeam(
    const CreateWorkforceTeamCommand(
      id: 'team-a',
      eventId: 'seed-t',
      projectId: 'project-a',
      subcontractorId: 'employer-a',
      name: 'Ekip A',
    ),
  );
  await attendance.createMember(
    const CreateWorkforceMemberCommand(
      id: 'person-a',
      eventId: 'seed-p',
      projectId: 'project-a',
      subcontractorId: 'employer-a',
      teamId: 'team-a',
      fullName: 'Uzun Türkçe Personel Adı Soyadı',
      teamName: 'Ekip A',
      roleName: 'Demir ustası',
    ),
  );
  attendance.detail = AttendanceDayDetail(
    day: const AttendanceDay(
      id: 'day-a',
      projectId: 'project-a',
      projectName: 'Aktif proje',
      localDate: '2026-09-05',
      status: AttendanceDayStatus.draft,
      generalNote: 'Önceki genel not',
      revision: 7,
      createdAt: '2026-09-05T08:00:00Z',
      updatedAt: '2026-09-05T08:00:00Z',
      completedAt: null,
    ),
    entries: empty
        ? const []
        : const [
            AttendanceEntry(
              id: 'entry-a',
              attendanceDayId: 'day-a',
              memberId: 'person-a',
              memberName: 'Uzun Türkçe Personel Adı Soyadı',
              teamName: 'Ekip A',
              teamId: 'team-a',
              roleName: 'Demir ustası',
              personnelCode: null,
              memberIsActive: true,
              result: AttendanceResult.fullDay,
              overtimeMinutes: 30,
              shortNote: 'Mevcut not',
              createdAt: '2026-09-05T08:00:00Z',
              updatedAt: '2026-09-05T08:00:00Z',
            ),
          ],
    events: const [
      AttendanceEvent(
        id: 'event-a',
        attendanceDayId: 'day-a',
        sequence: 1,
        eventType: 'fixture_event',
        occurredAt: '2026-09-05T08:00:00Z',
        payloadJson: '{}',
      ),
    ],
    totals: const AttendanceTotals.zero(),
    teamSummaries: const [],
    linkedReminder: null,
  );
  return attendance;
}

class _Attendance extends FakeAttendanceApplication {
  Completer<AttendanceDayDetail>? pending;
  final reads = <String>[];
  final teamQueries = <String>[];
  final bulk = <MarkAttendanceFullCommand>[];
  final removals = <RemoveAttendanceEntryCommand>[];
  final transitions = <TransitionAttendanceDayCommand>[];
  final exports = <(ExportAttendanceDayCommand, bool)>[];
  @override
  Future<AttendanceDayDetail> getDayDetail(String dayId) async {
    reads.add('day:$dayId');
    if (pending != null) return pending!.future;
    return super.getDayDetail(dayId);
  }

  @override
  Future<List<WorkforceMember>> listMembers(
    String projectId, {
    bool includeInactive = false,
  }) async {
    reads.add('members:$projectId');
    return super.listMembers(projectId, includeInactive: includeInactive);
  }

  @override
  Future<List<Subcontractor>> listSubcontractors(
    String projectId, {
    bool includeArchived = false,
  }) async {
    reads.add('employers:$projectId');
    return super.listSubcontractors(
      projectId,
      includeArchived: includeArchived,
    );
  }

  @override
  Future<List<WorkforceTeam>> listTeams(
    String projectId, {
    String? subcontractorId,
    bool includeArchived = false,
  }) async {
    teamQueries.add('$projectId:$subcontractorId');
    return super.listTeams(
      projectId,
      subcontractorId: subcontractorId,
      includeArchived: includeArchived,
    );
  }

  @override
  Future<WorkforcePersonDetail> getPersonDetail(String memberId) =>
      throw StateError('Unexpected compliance/person detail read');
  @override
  Future<AttendanceDayDetail> markFullDay(MarkAttendanceFullCommand command) {
    bulk.add(command);
    return super.markFullDay(command);
  }

  @override
  Future<AttendanceDayDetail> removeEntry(
    RemoveAttendanceEntryCommand command,
  ) {
    removals.add(command);
    return super.removeEntry(command);
  }

  @override
  Future<AttendanceDayDetail> transitionDay(
    TransitionAttendanceDayCommand command,
  ) {
    transitions.add(command);
    return super.transitionDay(command);
  }

  @override
  Future<AttendanceExportResult> exportDay(
    ExportAttendanceDayCommand command, {
    bool share = false,
  }) {
    exports.add((command, share));
    return super.exportDay(command, share: share);
  }
}
