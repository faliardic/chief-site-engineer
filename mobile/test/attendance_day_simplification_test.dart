import 'dart:async';
import 'dart:ui' show SemanticsAction, Tristate;

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
  of: _key('attendance-add-person'),
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
    const Size(390, 360),
    const Size(800, 900),
    const Size(1440, 900),
  ]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('selected roster and optional detail fit $size text $scale', (
        tester,
      ) async {
        final semantics = tester.ensureSemantics();
        try {
          final attendance = await _fixture();
          await _pump(tester, attendance, size: size, scale: scale);
          expect(_key('attendance-member-person-a'), findsOneWidget);
          expect(_key('attendance-subcontractor-selector'), findsNothing);
          expect(_key('attendance-overtime-person-a'), findsNothing);
          expect(_key('attendance-note-person-a'), findsNothing);
          expect(_key('attendance-result-person-a'), findsOneWidget);
          expect(
            find.byType(DropdownButtonFormField<AttendanceResult?>),
            findsNothing,
          );
          expect(
            find.descendant(
              of: _key('attendance-result-person-a'),
              matching: find.byType(OutlinedButton),
            ),
            findsNWidgets(4),
          );
          for (final result in AttendanceResult.values) {
            final choice = _key('attendance-result-person-a-${result.name}');
            await _reveal(tester, choice);
            expect(choice.hitTestable(), findsOneWidget);
            expect(tester.getSize(choice).width, greaterThanOrEqualTo(48));
            expect(tester.getSize(choice).height, greaterThanOrEqualTo(48));
            final data = tester.getSemantics(choice).getSemanticsData();
            expect(data.label, result.label);
            expect(data.flagsCollection.isButton, isTrue);
            expect(data.flagsCollection.isInMutuallyExclusiveGroup, isTrue);
            expect(data.hasAction(SemanticsAction.tap), isTrue);
            expect(
              data.flagsCollection.isSelected,
              result == AttendanceResult.fullDay
                  ? Tristate.isTrue
                  : Tristate.isFalse,
            );
            expect(tester.takeException(), isNull);
          }
          expect(
            tester.getTopLeft(_key('attendance-member-person-a')).dy,
            lessThan(tester.getTopLeft(_key('attendance-add-person')).dy),
          );
          expect(
            tester.getSize(_key('attendance-member-person-a')).width,
            lessThanOrEqualTo(840),
          );
          await _tap(tester, _key('attendance-bulk-tools'));
          for (final key in [
            'mark-all-full',
            'mark-team-full',
            'attendance-clear-result-person-a',
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
          expect(
            _key('attendance-note-person-a').hitTestable(),
            findsOneWidget,
          );
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
          await _reveal(tester, _addTitle);
          expect(_addTitle.hitTestable(), findsOneWidget);
          expect(_key('attendance-roster-selector'), findsNothing);
          expect(tester.takeException(), isNull);
          expect(attendance.reads, [
            'day:day-a',
            'members:project-a',
            'employers:project-a',
          ]);
        } finally {
          semantics.dispose();
        }
      });
    }
  }

  for (final result in AttendanceResult.values) {
    testWidgets('direct ${result.label} preserves exact roster save command', (
      tester,
    ) async {
      final attendance = await _fixture();
      await _pump(tester, attendance);
      await _tap(tester, _key('attendance-result-person-a-${result.name}'));
      expect(attendance.saveCalls, 0);
      expect(attendance.reads.length, 3);
      expect(attendance.removals, isEmpty);
      await _tap(tester, _key('save-attendance-draft'));
      final command = attendance.lastRosterCommand!;
      expect(command.dayId, 'day-a');
      expect(command.expectedRevision, 7);
      expect(command.eventId, isNotEmpty);
      expect(command.replaceGeneralNote, isTrue);
      expect(command.generalNote, 'Önceki genel not');
      final value = command.values.single;
      expect(value.entryId, 'entry-a');
      expect(value.memberId, 'person-a');
      expect(value.result, result);
      expect(
        value.overtimeMinutes,
        result == AttendanceResult.absent || result == AttendanceResult.leave
            ? 0
            : 30,
      );
      expect(value.shortNote, 'Mevcut not');
      expect(attendance.detail!.entries.single.result, result);
      expect(attendance.detail!.day.revision, 8);
    });
  }

  testWidgets('secondary clear keeps no-result draft and omits it from save', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      final attendance = await _fixture();
      attendance.saveFailure = const AgendaValidationFailure(
        'Sentetik kayıt hatası',
      );
      await _pump(tester, attendance);
      await _tap(tester, _key('attendance-clear-result-person-a'));
      expect(find.text('Kayıt yok'), findsOneWidget);
      expect(
        tester
            .widget<TextButton>(_key('attendance-clear-result-person-a'))
            .onPressed,
        isNull,
      );
      for (final result in AttendanceResult.values) {
        final choice = _key('attendance-result-person-a-${result.name}');
        await _reveal(tester, choice);
        expect(
          tester
              .getSemantics(choice)
              .getSemanticsData()
              .flagsCollection
              .isSelected,
          Tristate.isFalse,
        );
      }
      await _tap(tester, _key('attendance-result-person-a-halfDay'));
      expect(find.text('Kayıt yok'), findsNothing);
      await _tap(tester, _detailsTitle);
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
      await _tap(tester, _key('attendance-clear-result-person-a'));
      await _tap(tester, _key('save-attendance-draft'));
      expect(attendance.lastRosterCommand!.values, isEmpty);
      expect(attendance.lastRosterCommand!.dayId, 'day-a');
      expect(attendance.lastRosterCommand!.expectedRevision, 7);
      expect(attendance.lastRosterCommand!.eventId, isNotEmpty);
      expect(attendance.removals, isEmpty);
      expect(find.text('Kayıt yok'), findsOneWidget);
    } finally {
      semantics.dispose();
    }
  });

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
      await _tap(tester, _key('attendance-result-person-a-halfDay'));
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
    'empty day projects active person directly without creating a record',
    (tester) async {
      final attendance = await _fixture(empty: true);
      await _pump(tester, attendance);
      expect(_key('attendance-member-person-a'), findsOneWidget);
      expect(_key('attendance-roster-selector'), findsNothing);
      expect(find.text('Kayıt yok'), findsOneWidget);
      expect(attendance.saveCalls, 0);
      expect(attendance.removals, isEmpty);
      expect(attendance.bulk, isEmpty);
      await _tap(
        tester,
        _key('attendance-result-person-a-${AttendanceResult.fullDay.name}'),
      );
      expect(attendance.saveCalls, 0);
      await _tap(tester, _key('save-attendance-draft'));
      expect(attendance.lastRosterCommand!.values.single.memberId, 'person-a');
      expect(
        attendance.lastRosterCommand!.values.single.result,
        AttendanceResult.fullDay,
      );
      expect(attendance.removals, isEmpty);
    },
  );

  testWidgets(
    'complete saves the visible draft before transitioning post-save revision',
    (tester) async {
      final attendance = await _fixture();
      await _pump(tester, attendance);
      await _tap(tester, _key('attendance-bulk-tools'));
      await _tap(tester, _key('mark-team-full'));
      await _tap(tester, _key('mark-team-full-team-a'));
      expect(attendance.bulk, isEmpty);
      expect(attendance.saveCalls, 0);
      await _tap(tester, _key('mark-all-full'));
      expect(attendance.bulk, isEmpty);
      expect(attendance.saveCalls, 0);
      await _tap(tester, _detailsTitle);
      await tester.enterText(
        _key('attendance-note-person-a'),
        'Tamamlama öncesi not',
      );
      await tester.enterText(_key('attendance-general-note'), 'Gün sonu notu');
      await _tap(tester, _detailsTitle);

      await _tap(tester, _key('complete-attendance-day'));
      await _tap(tester, _key('confirm-attendance-transition'));

      final save = attendance.lastRosterCommand!;
      final complete = attendance.transitions.single;
      expect(save.expectedRevision, 7);
      expect(save.values.single.shortNote, 'Tamamlama öncesi not');
      expect(save.generalNote, 'Gün sonu notu');
      expect(complete.dayId, 'day-a');
      expect(complete.expectedRevision, 8);
      expect(complete.transition, AttendanceTransition.complete);
      expect(attendance.operations, ['save:7', 'transition:complete:8']);
      expect(attendance.detail!.day.status, AttendanceDayStatus.completed);
      expect(
        attendance.detail!.entries.single.shortNote,
        'Tamamlama öncesi not',
      );
      expect(attendance.detail!.day.generalNote, 'Gün sonu notu');
    },
  );

  testWidgets('save failure blocks completion and keeps the draft editable', (
    tester,
  ) async {
    final attendance = await _fixture();
    attendance.saveFailure = const AgendaValidationFailure(
      'Fazla mesai geçersiz.',
    );
    await _pump(tester, attendance);
    await _tap(tester, _detailsTitle);
    await tester.enterText(
      _key('attendance-note-person-a'),
      'Kaydedilemeyen not',
    );
    await _tap(tester, _detailsTitle);

    await _tap(tester, _key('complete-attendance-day'));
    await _tap(tester, _key('confirm-attendance-transition'));

    expect(attendance.saveCalls, 1);
    expect(attendance.transitions, isEmpty);
    expect(attendance.detail!.day.status, AttendanceDayStatus.draft);
    expect(attendance.detail!.day.revision, 7);
    expect(find.text('Fazla mesai geçersiz.'), findsOneWidget);
    expect(_key('save-attendance-draft').hitTestable(), findsOneWidget);
    await _tap(tester, _detailsTitle);
    expect(
      tester
          .widget<TextField>(_key('attendance-note-person-a'))
          .controller!
          .text,
      'Kaydedilemeyen not',
    );
  });

  testWidgets('completion failure retains the saved draft and draft status', (
    tester,
  ) async {
    final attendance = await _fixture();
    attendance.transitionFailure = const AgendaValidationFailure(
      'Tamamlama şu anda yapılamadı.',
    );
    await _pump(tester, attendance);
    await _tap(tester, _detailsTitle);
    await tester.enterText(_key('attendance-note-person-a'), 'Kaydedilmiş not');
    await _tap(tester, _detailsTitle);

    await _tap(tester, _key('complete-attendance-day'));
    await _tap(tester, _key('confirm-attendance-transition'));

    expect(attendance.saveCalls, 1);
    expect(attendance.transitions.single.expectedRevision, 8);
    expect(attendance.detail!.day.status, AttendanceDayStatus.draft);
    expect(attendance.detail!.day.revision, 8);
    expect(attendance.detail!.entries.single.shortNote, 'Kaydedilmiş not');
    expect(find.text('Tamamlama şu anda yapılamadı.'), findsOneWidget);
    expect(_key('save-attendance-draft').hitTestable(), findsOneWidget);

    attendance.transitionFailure = null;
    await _tap(tester, _key('complete-attendance-day'));
    await _tap(tester, _key('confirm-attendance-transition'));

    expect(attendance.saveCalls, 2);
    expect(attendance.lastRosterCommand!.expectedRevision, 8);
    expect(attendance.transitions.last.expectedRevision, 9);
    expect(attendance.detail!.day.status, AttendanceDayStatus.completed);
  });

  testWidgets(
    'no-work and reopen transition directly without an implicit draft save',
    (tester) async {
      final attendance = await _fixture();
      await _pump(tester, attendance);
      for (final step in [
        ('attendance-no-work', AttendanceTransition.noWork),
        ('reopen-attendance-day', AttendanceTransition.reopen),
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
      expect(attendance.saveCalls, 0);
      expect(attendance.transitions.map((c) => c.dayEventId).toSet().length, 2);
      expect(
        attendance.transitions.map((c) => c.reminderEventId).toSet().length,
        2,
      );
      expect(_key('complete-attendance-day'), findsOneWidget);
    },
  );

  testWidgets(
    'Personel ekle opens the canonical Sicil form without inline creation',
    (tester) async {
      final attendance = await _fixture(empty: true);
      await _pump(tester, attendance);
      await _tap(tester, _key('attendance-add-person'));
      expect(_key('workforce-member-form'), findsOneWidget);
      expect(_key('workforce-subcontractor-context'), findsOneWidget);
      expect(_key('attendance-inline-member-form'), findsNothing);
      expect(attendance.createMemberCalls, 1);
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
    expect(find.text('Puantaj kaydı güncellendi'), findsOneWidget);
    expect(find.textContaining('fixture_event'), findsNothing);
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
        project: const MobileProject(
          id: 'project-a',
          name: 'Aktif proje',
          createdAt: '2026-09-05T08:00:00Z',
          updatedAt: '2026-09-05T08:00:00Z',
          revision: 1,
        ),
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
  final operations = <String>[];
  Object? transitionFailure;
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
  Future<AttendanceDayDetail> saveRoster(SaveAttendanceRosterCommand command) {
    operations.add('save:${command.expectedRevision}');
    return super.saveRoster(command);
  }

  @override
  Future<AttendanceDayDetail> transitionDay(
    TransitionAttendanceDayCommand command,
  ) {
    transitions.add(command);
    operations.add(
      'transition:${command.transition.name}:${command.expectedRevision}',
    );
    final failure = transitionFailure;
    if (failure != null) return Future.error(failure);
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
