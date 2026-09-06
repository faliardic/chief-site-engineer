import 'dart:async';
import 'package:chief_site_engineer/application/attendance_application.dart';
import 'package:chief_site_engineer/domain/attendance_models.dart';
import 'package:chief_site_engineer/features/attendance/workforce_person_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_attendance_application.dart';

void main() {
  for (final size in [const Size(320, 360), const Size(390, 844)]) {
    testWidgets('20B read-only archive and event history at $size text 2', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      try {
        final records = [
          ..._coreProfileRecords(),
          _complianceRecord(
            'archive-a',
            source: ComplianceSourceStatus.notApplicable,
            read: ComplianceReadStatus.exception,
            expiry: '2026-06-30',
            revision: 3,
            archivedAt: '2026-07-03T08:00:00Z',
          ),
          _complianceRecord(
            'archive-b',
            source: ComplianceSourceStatus.exception,
            read: ComplianceReadStatus.exception,
            archivedAt: '2026-07-04T08:00:00Z',
          ),
        ];
        final attendance = _Attendance(compliance: records);
        attendance.store.complianceEvents = [
          for (var i = 1; i <= 3; i++)
            WorkforceComplianceEvent(
              id: 'event-$i',
              recordId: 'archive-a',
              memberId: 'person-1',
              projectId: 'project-1',
              sequence: i,
              eventType: [
                'compliance.created',
                'compliance.updated',
                'compliance.archived',
              ][i - 1],
              occurredAt: '2026-07-0${4 - i}T08:00:00Z',
            ),
          const WorkforceComplianceEvent(
            id: 'active-event',
            recordId: 'employment_entry',
            memberId: 'person-1',
            projectId: 'project-1',
            sequence: 1,
            eventType: 'compliance.created',
            occurredAt: '2026-07-01T08:00:00Z',
          ),
        ];
        final events = List<WorkforceComplianceEvent>.of(
          attendance.store.complianceEvents,
        );
        await _pump(tester, attendance, size: size, scale: 2);
        expect(find.text('İSG belgeleri tam'), findsOneWidget);
        await _tab(tester, 'İSG');
        final open = find.byKey(const Key('open-compliance-history'));
        await _revealCompliance(tester, open);
        expect(tester.getSize(open).height, greaterThanOrEqualTo(48));
        expect(
          tester.getSemantics(open),
          matchesSemantics(
            label: 'Geçmiş / Arşiv',
            isButton: true,
            hasTapAction: true,
            hasFocusAction: true,
            hasEnabledState: true,
            isEnabled: true,
            isFocusable: true,
          ),
        );
        // Exercise the accessible action, not just a pointer tap.
        await tester.tap(open);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('compliance-history-page')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('archived-compliance-archive-a')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('archived-compliance-archive-b')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('active-compliance-history-employment_entry')),
          findsOneWidget,
        );
        for (final value in [
          'Belge numarası: BELGE-archive-a',
          'Düzenlenme tarihi: 2026-07-01',
          'Son geçerlilik tarihi: 2026-06-30',
          'Not: Kayıt notu archive-a',
          'Gerekçe: Kullanıcının gerekçesi archive-a',
          'Arşivlenme zamanı: 2026-07-03T08:00:00Z',
        ]) {
          final finder = find.text(value);
          expect(finder, findsWidgets);
          await Scrollable.ensureVisible(
            tester.element(finder.first),
            alignment: 0.5,
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
        final tile = find.byKey(
          const PageStorageKey('compliance-events-archive-a'),
        );
        final title = find.descendant(
          of: tile,
          matching: find.text('Kayıt işlemleri'),
        );
        await Scrollable.ensureVisible(tester.element(title), alignment: 0.5);
        await tester.pumpAndSettle();
        await tester.tap(title);
        await tester.pumpAndSettle();
        for (final label in [
          'İSG kaydı oluşturuldu',
          'İSG kaydı güncellendi',
          'İSG kaydı arşivlendi',
        ]) {
          expect(find.text(label), findsOneWidget);
        }
        final positions = [
          for (var i = 1; i <= 3; i++)
            tester.getTopLeft(find.byKey(Key('compliance-event-event-$i'))).dy,
        ];
        expect(positions[0], lessThan(positions[1]));
        expect(positions[1], lessThan(positions[2]));
        expect(find.textContaining('compliance.'), findsNothing);
        expect(find.textContaining('member_id'), findsNothing);
        expect(find.byType(TextField), findsNothing);
        expect(find.text('Kaydet'), findsNothing);
        expect(find.text('Geri yükle'), findsNWidgets(2));
        expect(find.text('Arşivle'), findsNothing);
        await Scrollable.ensureVisible(tester.element(title), alignment: 0.5);
        await tester.pumpAndSettle();
        await tester.tap(title);
        await tester.pumpAndSettle();
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        await _revealCompliance(tester, open);
        await tester.tap(open);
        await tester.pumpAndSettle();
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        await _tab(tester, 'Profil');
        expect(find.text('İSG belgeleri tam'), findsOneWidget);
        expect(attendance.calls, ['read:person-1']);
        expect(attendance.complianceCommands, isEmpty);
        expect(attendance.ppeCommands, isEmpty);
        expect(attendance.archiveCommand, isNull);
        expect(attendance.store.compliance, records);
        expect(attendance.store.complianceEvents, events);
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    });
  }

  testWidgets('archived compliance restores exact record after confirmation', (
    tester,
  ) async {
    final archived = _complianceRecord(
      'restore-me',
      revision: 3,
      archivedAt: '2026-07-03T08:00:00Z',
    );
    final attendance = _Attendance(compliance: [archived]);
    attendance.store.complianceEvents = const [
      WorkforceComplianceEvent(
        id: 'restore-created',
        recordId: 'restore-me',
        memberId: 'person-1',
        projectId: 'project-1',
        sequence: 1,
        eventType: 'compliance.created',
        occurredAt: '2026-07-01T08:00:00Z',
      ),
      WorkforceComplianceEvent(
        id: 'restore-archived',
        recordId: 'restore-me',
        memberId: 'person-1',
        projectId: 'project-1',
        sequence: 2,
        eventType: 'compliance.archived',
        occurredAt: '2026-07-03T08:00:00Z',
      ),
    ];
    await _pump(tester, attendance, size: const Size(390, 844), scale: 2);
    await _tab(tester, 'İSG');
    final openHistory = find.byKey(const Key('open-compliance-history'));
    await _revealCompliance(tester, openHistory);
    await tester.tap(openHistory);
    await tester.pumpAndSettle();
    final restore = find.byKey(const Key('restore-compliance-restore-me'));
    await tester.ensureVisible(restore);
    await tester.pumpAndSettle();
    expect(tester.getSize(restore).height, greaterThanOrEqualTo(48));
    await tester.tap(restore);
    await tester.pumpAndSettle();
    expect(
      find.text('Bu kayıt aktif İSG kayıtlarına geri dönecek.'),
      findsOneWidget,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Geri yükle'));
    await tester.pumpAndSettle();
    expect(attendance.restoreCommand!.id, archived.id);
    expect(attendance.restoreCommand!.memberId, 'person-1');
    expect(attendance.restoreCommand!.projectId, 'project-1');
    expect(attendance.restoreCommand!.expectedRevision, 3);
    final restored = attendance.store.compliance.single;
    expect(restored.id, archived.id);
    expect(restored.revision, 4);
    expect(restored.archivedAt, isNull);
    expect(
      attendance.store.complianceEvents.last.eventType,
      'compliance.reopened',
    );
    expect(find.byKey(const Key('compliance-restore-me')), findsOneWidget);
    await _revealCompliance(tester, openHistory);
    await tester.tap(openHistory);
    await tester.pumpAndSettle();
    final eventTile = find.byKey(
      const PageStorageKey('compliance-events-restore-me'),
    );
    await tester.ensureVisible(eventTile);
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(of: eventTile, matching: find.text('Kayıt işlemleri')),
    );
    await tester.pumpAndSettle();
    expect(find.text('İSG kaydı geri yüklendi'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    '20B empty and all-archived history stay separate from active checklist',
    (tester) async {
      for (final archivedOnly in [false, true]) {
        final attendance = _Attendance(
          empty: true,
          compliance: [
            if (archivedOnly)
              _complianceRecord(
                'old',
                source: ComplianceSourceStatus.missing,
                read: ComplianceReadStatus.missing,
                archivedAt: '2026-07-02T08:00:00Z',
              ),
          ],
        );
        await tester.pumpWidget(const SizedBox.shrink());
        await _pump(tester, attendance);
        expect(find.text('İSG belgeleri tam'), findsNothing);
        await _tab(tester, 'İSG');
        expect(find.text('Kayıt yok / değerlendirilmedi'), findsWidgets);
        expect(find.byKey(const Key('compliance-record-old')), findsNothing);
        await tester.tap(find.byKey(const Key('open-compliance-history')));
        await tester.pumpAndSettle();
        expect(
          find.text('Aktif kayıtlara ait işlem geçmişi yok.'),
          findsOneWidget,
        );
        if (archivedOnly) {
          expect(
            find.byKey(const Key('archived-compliance-old')),
            findsOneWidget,
          );
        } else {
          expect(find.text('Arşivlenmiş İSG kaydı yok.'), findsOneWidget);
        }
        expect(attendance.calls, ['read:person-1']);
        expect(attendance.archiveCommand, isNull);
        expect(tester.takeException(), isNull);
      }
    },
  );

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
        expect(
          tester.widgetList<Tab>(find.byType(Tab)).map((tab) => tab.text),
          ['Profil', 'Puantaj', 'İSG', 'KKD'],
        );
        expect(
          find.byKey(const Key('workforce-attendance-summary')),
          findsNothing,
        );
        expect(tester.getSize(profile).width, lessThanOrEqualTo(840));
        if (size.width > 900) {
          expect(tester.getCenter(profile).dx, closeTo(size.width / 2, 1));
        }
        for (final value in [
          'Ayşe Çok Uzun Soyadlı Demir Ustası',
          'Uzun İsimli İnşaat ve Taahhüt Firması',
          'Demir donatı ve kalıp ustası',
          '2026-07-01',
          'Gece ekibinde çalışır. Uzun personel notu eksiksiz okunabilir.',
          'Eksik olarak işaretlenmiş kayıt var',
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
        ]) {
          final field = find.text(value);
          await Scrollable.ensureVisible(tester.element(field), alignment: 0.5);
          await tester.pumpAndSettle();
          expect(field.hitTestable(), findsOneWidget);
          expect(tester.takeException(), isNull);
        }
        await _tab(tester, 'Puantaj');
        for (final value in ['Toplam 3.5 kişi-gün', '2026-08-08']) {
          final field = find.text(value);
          await Scrollable.ensureVisible(tester.element(field), alignment: 0.5);
          await tester.pumpAndSettle();
          expect(field.hitTestable(), findsOneWidget);
          expect(tester.takeException(), isNull);
        }
        expect(find.byType(TextField), findsNothing);
        expect(find.byType(FilledButton), findsNothing);
        final history = find.byKey(const Key('workforce-attendance-day-1'));
        expect(tester.widget<ListTile>(history).onTap, isNull);
        expect(
          find.descendant(of: history, matching: find.text('0.5')),
          findsOneWidget,
        );
        expect(find.textContaining('Son kayıt: 2026-08-08'), findsOneWidget);
        await _tab(tester, 'Profil');
        final jump = find.byKey(const Key('profile-open-compliance'));
        await tester.ensureVisible(jump);
        await tester.pumpAndSettle();
        await tester.tap(jump);
        await tester.pumpAndSettle();
        final addOther = find.byKey(const Key('add-compliance-record'));
        await _revealCompliance(tester, addOther);
        expect(addOther, findsOneWidget);
        await _revealCompliance(
          tester,
          find.byKey(const Key('quick-compliance-health_report')),
        );
        await tester.pumpAndSettle();
        expect(find.text('Sağlık raporu'), findsWidgets);
        expect(attendance.calls, ['read:person-1']);
        expect(tester.takeException(), isNull);
        await _tab(tester, 'KKD');
        expect(find.byKey(const Key('add-ppe-assignment')), findsOneWidget);
        await _tab(tester, 'Profil');
        expect(profile, findsOneWidget);
        expect(attendance.calls, ['read:person-1']);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('empty optional values and unrecorded ISG have safe wording', (
    tester,
  ) async {
    final attendance = _Attendance(empty: true);
    await _pump(tester, attendance);
    final profile = find.byKey(const Key('workforce-person-profile'));
    expect(
      find.descendant(of: profile, matching: find.text('Belirtilmedi')),
      findsNWidgets(3),
    );
    expect(find.text('İSG TAM'), findsNothing);
    expect(find.text('İSG EKSİĞİ VAR'), findsNothing);
    expect(find.text('Kayıt yok / değerlendirilmedi'), findsOneWidget);
    expect(find.byKey(const Key('profile-open-compliance')), findsOneWidget);
    expect(find.byKey(const Key('workforce-attendance-summary')), findsNothing);
    expect(find.text('Belirtilmedi'), findsNWidgets(4));
    await _tab(tester, 'Puantaj');
    expect(find.text('Toplam 0.0 kişi-gün'), findsOneWidget);
    expect(find.text('Henüz Puantaj geçmişi yok.'), findsOneWidget);
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

  for (final size in [const Size(320, 640), const Size(390, 844)]) {
    testWidgets('four quick-add cards are accessible at $size text 2', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      try {
        final attendance = _Attendance(empty: true);
        await _pump(tester, attendance, size: size, scale: 2);
        await _tab(tester, 'İSG');
        for (final type in _quickTypes) {
          final card = find.byKey(Key('quick-compliance-${type.storageValue}'));
          await _revealCompliance(tester, card);
          expect(tester.getSize(card).height, greaterThanOrEqualTo(72));
          expect(
            tester.getSemantics(card),
            matchesSemantics(
              label: '${type.label}: + Ekle',
              isButton: true,
              hasTapAction: true,
              hasEnabledState: true,
              isEnabled: true,
              isFocusable: true,
            ),
          );
        }
        final other = find.byKey(const Key('add-compliance-record'));
        await _revealCompliance(tester, other);
        expect(tester.getSize(other).height, greaterThanOrEqualTo(48));
        expect(find.text('Diğer İSG kaydı ekle'), findsOneWidget);
        expect(attendance.calls, ['read:person-1']);
        expect(attendance.store.compliance, isEmpty);
        expect(attendance.complianceCommands, isEmpty);
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    });
  }

  testWidgets('quick-add double tap and retry keep stable identities once', (
    tester,
  ) async {
    final attendance = _Attendance(empty: true)
      ..complianceFailureAfterSave = StateError('response lost');
    await _pump(tester, attendance);
    await _tab(tester, 'İSG');
    final card = find.byKey(const Key('quick-compliance-employment_entry'));
    final onTap = tester.widget<InkWell>(card).onTap!;
    onTap();
    onTap();
    await tester.pumpAndSettle();
    expect(attendance.complianceCommands, hasLength(1));
    expect(attendance.store.compliance, hasLength(1));
    expect(attendance.store.complianceEvents, hasLength(1));
    final first = attendance.complianceCommands.single;
    expect(first.documentType, ComplianceDocumentType.employmentEntry);
    expect(first.sourceStatus, ComplianceSourceStatus.valid);
    expect(first.documentNumber, isNull);
    expect(first.issuedDate, isNull);
    expect(first.expiryDate, isNull);
    expect(first.note, isNull);
    expect(first.reason, isNull);

    await tester.tap(card);
    await tester.pumpAndSettle();
    expect(attendance.complianceCommands, hasLength(2));
    expect(attendance.complianceCommands.last.id, first.id);
    expect(attendance.complianceCommands.last.eventId, first.eventId);
    expect(attendance.store.compliance, hasLength(1));
    expect(attendance.store.complianceEvents, hasLength(1));
    expect(find.text('Kayıt var'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('one and multiple quick-card states open exact detail', (
    tester,
  ) async {
    final one = _complianceRecord(
      'one',
      type: ComplianceDocumentType.healthReport,
    );
    final attendance = _Attendance(compliance: [one]);
    await _pump(tester, attendance);
    await _tab(tester, 'İSG');
    final oneCard = find.byKey(const Key('quick-compliance-health_report'));
    await tester.tap(oneCard);
    await tester.pumpAndSettle();
    expect(find.text('İSG kaydını düzenle'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Vazgeç'));
    await tester.pumpAndSettle();

    final a = _complianceRecord('a');
    final b = _complianceRecord('b');
    final multipleAttendance = _Attendance(compliance: [b, a]);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await _pump(tester, multipleAttendance);
    await _tab(tester, 'İSG');
    final multiple = find.byKey(const Key('quick-compliance-employment_entry'));
    await _revealCompliance(tester, multiple);
    expect(find.text('2 kayıt'), findsOneWidget);
    await tester.tap(multiple);
    await tester.pumpAndSettle();
    final selectA = find.byKey(const Key('quick-compliance-select-a'));
    final selectB = find.byKey(const Key('quick-compliance-select-b'));
    expect(
      tester.getTopLeft(selectA).dy,
      lessThan(tester.getTopLeft(selectB).dy),
    );
    await tester.tap(selectA);
    await tester.pumpAndSettle();
    expect(find.text('İSG kaydını düzenle'), findsOneWidget);
    await _toggleComplianceDetails(tester);
    expect(
      tester.widget<TextField>(_field('Belge numarası')).controller!.text,
      'BELGE-a',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('compliance empty categories open without writing records', (
    tester,
  ) async {
    final attendance = _Attendance(empty: true);
    await _pump(tester, attendance, size: const Size(320, 360), scale: 2);
    final jump = find.byKey(const Key('profile-open-compliance'));
    await tester.ensureVisible(jump);
    await tester.pumpAndSettle();
    expect(tester.getSize(jump).height, greaterThanOrEqualTo(48));
    await tester.tap(jump);
    await tester.pumpAndSettle();
    for (final type in ComplianceDocumentType.values) {
      final category = find.byKey(
        PageStorageKey('compliance-category-${type.storageValue}'),
      );
      final title = find.descendant(
        of: category,
        matching: find.text(type.label),
      );
      await _revealCompliance(tester, title);
      expect(
        find.descendant(
          of: category,
          matching: find.text('Kayıt yok / değerlendirilmedi'),
        ),
        findsOneWidget,
      );
      await tester.tap(title);
      await tester.pumpAndSettle();
      await _revealCompliance(tester, title);
      await tester.tap(title);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
    expect(attendance.calls, ['read:person-1']);
    expect(attendance.store.compliance, isEmpty);
    expect(attendance.complianceCommands, isEmpty);
    expect(attendance.archiveCommand, isNull);
  });

  for (final scenario in [
    (
      ComplianceSourceStatus.missing,
      ComplianceReadStatus.missing,
      null,
      'Eksik olarak işaretlenmiş kayıt var',
      'Eksik olarak işaretlendi',
    ),
    (
      ComplianceSourceStatus.valid,
      ComplianceReadStatus.expired,
      '2026-08-31',
      'Süresi geçmiş kayıt var',
      'Süresi geçmiş',
    ),
    (
      ComplianceSourceStatus.valid,
      ComplianceReadStatus.expiring,
      '2026-09-30',
      'Süresi yaklaşan kayıt var',
      'Süresi yaklaşıyor',
    ),
    (
      ComplianceSourceStatus.valid,
      ComplianceReadStatus.valid,
      null,
      'Mevcut kayıtlarda uyarı yok',
      'Kullanıcı kaydı: geçerli olarak işaretlendi',
    ),
    (
      ComplianceSourceStatus.notApplicable,
      ComplianceReadStatus.exception,
      null,
      'Uygulanamaz olarak işaretlenmiş kayıt: 1',
      'Uygulanamaz olarak işaretlendi',
    ),
    (
      ComplianceSourceStatus.exception,
      ComplianceReadStatus.exception,
      null,
      'İstisna olarak işaretlenmiş kayıt: 1',
      'İstisna olarak işaretlendi',
    ),
  ]) {
    testWidgets(
      'compliance single-record profile and category signal ${scenario.$4}',
      (tester) async {
        final attendance = _Attendance(
          compliance: [
            _complianceRecord(
              'single',
              source: scenario.$1,
              read: scenario.$2,
              expiry: scenario.$3,
            ),
          ],
        );
        await _pump(tester, attendance);
        expect(find.text(scenario.$4), findsOneWidget);
        expect(
          find.text('Mevcut kayıtlarda uyarı yok'),
          scenario.$4 == 'Mevcut kayıtlarda uyarı yok'
              ? findsOneWidget
              : findsNothing,
        );
        expect(
          find.text('Son geçerlilik tarihi girilmemiş kayıt var'),
          findsNothing,
        );
        await _tab(tester, 'İSG');
        await _revealCompliance(tester, find.text(scenario.$5));
        expect(find.text(scenario.$5).hitTestable(), findsOneWidget);
        if (scenario.$1 == ComplianceSourceStatus.valid) {
          await _revealCompliance(
            tester,
            find.text('Kullanıcı kaydı: geçerli olarak işaretlendi'),
          );
          expect(find.text('Geçerli'), findsNothing);
        }
        await _revealCompliance(
          tester,
          find.text('Gerekçe: Kullanıcının gerekçesi single'),
        );
        if (scenario.$3 == null) {
          expect(
            find.descendant(
              of: find.byKey(const Key('compliance-single')),
              matching: find.text('Son geçerlilik tarihi girilmemiş'),
            ),
            findsNothing,
          );
        }
        expect(attendance.calls, ['read:person-1']);
      },
    );
  }

  for (final size in [const Size(320, 640), const Size(390, 500)]) {
    testWidgets(
      'compliance signals metadata and accessible controls at $size text 2',
      (tester) async {
        final semantics = tester.ensureSemantics();
        try {
          final records = [
            _complianceRecord(
              'expired',
              read: ComplianceReadStatus.expired,
              expiry: '2026-08-31',
            ),
            _complianceRecord('valid', expiry: '2027-12-31'),
            _complianceRecord(
              'missing',
              type: ComplianceDocumentType.healthReport,
              source: ComplianceSourceStatus.missing,
              read: ComplianceReadStatus.missing,
            ),
            _complianceRecord(
              'na',
              type: ComplianceDocumentType.basicSafetyTraining,
              source: ComplianceSourceStatus.notApplicable,
              read: ComplianceReadStatus.exception,
            ),
            _complianceRecord(
              'exception',
              type: ComplianceDocumentType.vocationalCertificate,
              source: ComplianceSourceStatus.exception,
              read: ComplianceReadStatus.exception,
            ),
            _complianceRecord('undated', type: ComplianceDocumentType.other),
          ];
          final attendance = _Attendance(compliance: records);
          await _pump(tester, attendance, size: size, scale: 2);
          for (final signal in [
            'Eksik olarak işaretlenmiş kayıt var',
            'Süresi geçmiş kayıt var',
            'Uygulanamaz olarak işaretlenmiş kayıt: 1',
            'İstisna olarak işaretlenmiş kayıt: 1',
            'Aynı türde birden fazla aktif kayıt var',
          ]) {
            final field = find.text(signal);
            await tester.ensureVisible(field);
            await tester.pumpAndSettle();
            expect(field.hitTestable(), findsOneWidget);
            expect(tester.takeException(), isNull);
          }
          expect(find.text('İSG TAM'), findsNothing);
          expect(find.text('İSG EKSİĞİ VAR'), findsNothing);
          expect(
            find.text('Son geçerlilik tarihi girilmemiş kayıt var'),
            findsNothing,
          );
          await _tab(tester, 'İSG');
          final add = find.byKey(const Key('add-compliance-record'));
          await _revealCompliance(tester, add);
          expect(tester.getSize(add).height, greaterThanOrEqualTo(48));
          await _revealCompliance(
            tester,
            find.text('Bu türde birden fazla aktif kayıt var'),
          );
          for (final record in records) {
            final card = find.byKey(Key('compliance-${record.id}'));
            await _revealCompliance(tester, card);
            for (final text in [
              'Belge numarası: ${record.documentNumber}',
              'Düzenlenme tarihi: ${record.issuedDate}',
              if (record.expiryDate != null)
                'Son geçerlilik tarihi: ${record.expiryDate}',
              'Not: ${record.note}',
              'Gerekçe: ${record.reason}',
            ]) {
              final field = find.descendant(
                of: card,
                matching: find.text(text),
              );
              await _revealCompliance(tester, field);
              expect(field.hitTestable(), findsOneWidget);
            }
            if (record.expiryDate == null) {
              expect(
                find.descendant(
                  of: card,
                  matching: find.text('Son geçerlilik tarihi girilmemiş'),
                ),
                findsNothing,
              );
            }
            for (final action in ['edit', 'archive']) {
              final control = find.byKey(
                Key('$action-compliance-${record.id}'),
              );
              await _revealCompliance(tester, control);
              final bounds = tester.getSize(control);
              expect(bounds.height, greaterThanOrEqualTo(48));
              expect(bounds.width, greaterThanOrEqualTo(48));
              final data = tester.getSemantics(control).getSemanticsData();
              expect(data.flagsCollection.isButton, isTrue);
              expect(data.hasAction(SemanticsAction.tap), isTrue);
            }
          }
          expect(attendance.calls, ['read:person-1']);
          expect(attendance.complianceCommands, isEmpty);
          expect(tester.takeException(), isNull);
        } finally {
          semantics.dispose();
        }
      },
    );
  }

  for (final size in [const Size(320, 640), const Size(390, 500)]) {
    testWidgets('compliance selected status is unclipped at $size text 2', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      try {
        final attendance = _Attendance(empty: true);
        await _pump(tester, attendance, size: size, scale: 2);
        await _tab(tester, 'İSG');
        final add = find.byKey(const Key('add-compliance-record'));
        await _revealCompliance(tester, add);
        await tester.tap(add);
        await tester.pumpAndSettle();
        final dropdown = find.byType(
          DropdownButtonFormField<ComplianceSourceStatus>,
        );
        for (final status in ComplianceSourceStatus.values) {
          final menuLabel = status == ComplianceSourceStatus.valid
              ? 'Geçerli (kullanıcı kaydı)'
              : status.label;
          await _selectDialogValue<ComplianceSourceStatus>(tester, menuLabel);
          await _revealDialogControl(tester, dropdown);
          expect(find.text('Kullanıcı durumu'), findsOneWidget);
          final selected = find.byKey(
            Key('compliance-status-selected-${status.storageValue}'),
          );
          expect(selected.hitTestable(), findsOneWidget);
          expect(tester.widget<Text>(selected).data, status.label);
          if (status == ComplianceSourceStatus.valid) {
            expect(find.text('Geçerli (kullanıcı kaydı)'), findsNothing);
          }
          final paragraph = tester.renderObject<RenderParagraph>(
            find.descendant(of: selected, matching: find.byType(RichText)),
          );
          expect(paragraph.textScaler.scale(16), 32);
          expect(
            DefaultTextStyle.of(tester.element(selected)).style.fontSize,
            Theme.of(tester.element(selected)).textTheme.titleMedium!.fontSize,
          );
          expect(paragraph.didExceedMaxLines, isFalse);
          final boxes = paragraph.getBoxesForSelection(
            TextSelection(baseOffset: 0, extentOffset: status.label.length),
          );
          expect(boxes, isNotEmpty);
          for (final box in boxes) {
            expect(box.left, greaterThanOrEqualTo(-0.01));
            expect(box.top, greaterThanOrEqualTo(-0.01));
            // Selection boxes include fractional trailing glyph spacing.
            expect(box.right, lessThanOrEqualTo(paragraph.size.width + 0.1));
            expect(box.bottom, lessThanOrEqualTo(paragraph.size.height + 0.01));
          }
          final fieldBounds = tester.getRect(dropdown);
          final valueBounds = tester.getRect(selected);
          expect(valueBounds.left, greaterThanOrEqualTo(fieldBounds.left));
          expect(valueBounds.top, greaterThanOrEqualTo(fieldBounds.top));
          expect(valueBounds.right, lessThanOrEqualTo(fieldBounds.right));
          expect(valueBounds.bottom, lessThanOrEqualTo(fieldBounds.bottom));
          final data = tester
              .getSemantics(find.byType(DropdownButton<ComplianceSourceStatus>))
              .getSemanticsData();
          expect(data.label, contains('Kullanıcı durumu'));
          expect(data.label, contains('${status.label} (kullanıcı kaydı)'));
          expect(data.flagsCollection.isButton, isTrue);
          expect(data.hasAction(SemanticsAction.tap), isTrue);
          expect(tester.takeException(), isNull);
        }
        expect(attendance.calls, ['read:person-1']);
        expect(attendance.complianceCommands, isEmpty);
        await tester.tap(find.widgetWithText(TextButton, 'Vazgeç'));
        await tester.pumpAndSettle();
        await tester.pump(kThemeAnimationDuration);
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('compliance dialog disclosure retains values at $size text 2', (
      tester,
    ) async {
      final attendance = _Attendance(empty: true);
      await _pump(tester, attendance, size: size, scale: 2);
      await _tab(tester, 'İSG');
      final add = find.byKey(const Key('add-compliance-record'));
      await _revealCompliance(tester, add);
      await tester.tap(add);
      await tester.pumpAndSettle();
      expect(find.text('Belge türü'), findsOneWidget);
      expect(find.text('Kullanıcı durumu'), findsOneWidget);
      expect(find.text('Detaylar'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(attendance.complianceCommands, isEmpty);
      await _selectDialogValue<ComplianceDocumentType>(tester, 'Sağlık raporu');
      await _toggleComplianceDetails(tester);
      final values = [
        ('Belge numarası', 'BELGE-42'),
        ('Düzenlenme tarihi (YYYY-AA-GG)', '2026-07-01'),
        ('Son geçerlilik tarihi (YYYY-AA-GG)', '2027-07-01'),
        ('Not', 'Kullanıcının ayrıntılı notu'),
        ('İstisna/uygulanamaz gerekçesi', 'Saklanan gerekçe'),
      ];
      for (final field in values) {
        await _revealDialogControl(tester, _field(field.$1));
        await tester.enterText(_field(field.$1), field.$2);
        expect(tester.takeException(), isNull);
      }
      await _toggleComplianceDetails(tester);
      expect(find.byType(TextField), findsNothing);
      await _toggleComplianceDetails(tester);
      for (final field in values) {
        expect(
          tester.widget<TextField>(_field(field.$1)).controller!.text,
          field.$2,
        );
      }
      expect(attendance.calls, ['read:person-1']);
      expect(attendance.store.compliance, isEmpty);
      await _toggleComplianceDetails(tester);
      await _saveDialog(tester);
      final command = attendance.complianceCommands.single;
      expect(command.id, isNotEmpty);
      expect(command.eventId, isNotEmpty);
      expect(command.memberId, 'person-1');
      expect(command.expectedRevision, 0);
      expect(command.documentType, ComplianceDocumentType.healthReport);
      expect(command.sourceStatus, ComplianceSourceStatus.valid);
      expect(command.documentNumber, values[0].$2);
      expect(command.issuedDate, values[1].$2);
      expect(command.expiryDate, values[2].$2);
      expect(command.note, values[3].$2);
      expect(command.reason, values[4].$2);
      expect(tester.takeException(), isNull);
    });

    for (final status in [
      ComplianceSourceStatus.notApplicable,
      ComplianceSourceStatus.exception,
    ]) {
      testWidgets(
        'compliance dialog ${status.name} auto-expands on add and edit at $size text 2',
        (tester) async {
          final attendance = _Attendance(empty: true);
          await _pump(tester, attendance, size: size, scale: 2);
          await _tab(tester, 'İSG');
          final add = find.byKey(const Key('add-compliance-record'));
          await _revealCompliance(tester, add);
          await tester.tap(add);
          await tester.pumpAndSettle();
          expect(find.byType(TextField), findsNothing);
          await _selectDialogValue<ComplianceSourceStatus>(
            tester,
            status.label,
          );
          expect(
            find.text('Bu durum için gerekçe zorunludur.'),
            findsOneWidget,
          );
          final reason = _field('İstisna/uygulanamaz gerekçesi');
          await _revealDialogControl(tester, reason);
          await tester.enterText(
            reason,
            'Kullanıcının ${status.label} gerekçesi',
          );
          await _toggleComplianceDetails(tester);
          expect(find.byType(TextField), findsNothing);
          await _selectDialogValue<ComplianceSourceStatus>(
            tester,
            'Geçerli (kullanıcı kaydı)',
          );
          expect(find.byType(TextField), findsNothing);
          await _selectDialogValue<ComplianceSourceStatus>(
            tester,
            status.label,
          );
          expect(
            tester.widget<TextField>(reason).controller!.text,
            'Kullanıcının ${status.label} gerekçesi',
          );
          expect(attendance.calls, ['read:person-1']);
          expect(attendance.complianceCommands, isEmpty);
          await _saveDialog(tester);
          final command = attendance.complianceCommands.single;
          expect(command.sourceStatus, status);
          expect(command.reason, 'Kullanıcının ${status.label} gerekçesi');
          expect(command.expectedRevision, 0);
          final edit = find.byKey(Key('edit-compliance-${command.id}'));
          await _revealCompliance(tester, edit);
          await tester.tap(edit);
          await tester.pumpAndSettle();
          expect(
            find.text('Bu durum için gerekçe zorunludur.'),
            findsOneWidget,
          );
          expect(
            tester.widget<TextField>(reason).controller!.text,
            command.reason,
          );
          await tester.tap(find.widgetWithText(TextButton, 'Vazgeç'));
          await tester.pumpAndSettle();
          await tester.pump(kThemeAnimationDuration);
          expect(attendance.complianceCommands, hasLength(1));
          expect(attendance.archiveCommand, isNull);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  for (final scenario in [
    ('all four valid without details', _coreProfileRecords(), true, <String>[]),
    (
      'expiring core',
      [
        ..._coreProfileRecords().skip(1),
        _complianceRecord(
          'expiring',
          read: ComplianceReadStatus.expiring,
          expiry: '2026-09-30',
        ),
      ],
      true,
      ['Süresi yaklaşan kayıt var'],
    ),
    (
      'missing core sibling',
      [
        ..._coreProfileRecords(),
        _complianceRecord(
          'missing',
          source: ComplianceSourceStatus.missing,
          read: ComplianceReadStatus.missing,
        ),
      ],
      false,
      [
        'Eksik olarak işaretlenmiş kayıt var',
        'Aynı türde birden fazla aktif kayıt var',
      ],
    ),
    (
      'expired core sibling',
      [
        ..._coreProfileRecords(),
        _complianceRecord(
          'expired',
          read: ComplianceReadStatus.expired,
          expiry: '2026-01-01',
        ),
      ],
      false,
      ['Süresi geçmiş kayıt var', 'Aynı türde birden fazla aktif kayıt var'],
    ),
    (
      'not-applicable cannot replace valid core',
      [
        ..._coreProfileRecords().skip(1),
        _complianceRecord(
          'na',
          source: ComplianceSourceStatus.notApplicable,
          read: ComplianceReadStatus.exception,
        ),
      ],
      false,
      ['Uygulanamaz olarak işaretlenmiş kayıt: 1'],
    ),
    (
      'exception cannot replace valid core',
      [
        ..._coreProfileRecords().skip(1),
        _complianceRecord(
          'exception',
          source: ComplianceSourceStatus.exception,
          read: ComplianceReadStatus.exception,
        ),
      ],
      false,
      ['İstisna olarak işaretlenmiş kayıt: 1'],
    ),
    (
      'other cannot replace core',
      [
        ..._coreProfileRecords().skip(1),
        _complianceRecord('other', type: ComplianceDocumentType.other),
      ],
      false,
      <String>[],
    ),
    (
      'other expiry does not block core completeness',
      [
        ..._coreProfileRecords(),
        _complianceRecord(
          'other-expired',
          type: ComplianceDocumentType.other,
          read: ComplianceReadStatus.expired,
          expiry: '2026-01-01',
        ),
      ],
      true,
      ['Süresi geçmiş kayıt var'],
    ),
  ]) {
    testWidgets('core completeness profile ${scenario.$1}', (tester) async {
      final attendance = _Attendance(compliance: scenario.$2);
      await _pump(tester, attendance, size: const Size(320, 640), scale: 2);
      expect(
        find.text('İSG belgeleri tam'),
        scenario.$3 ? findsOneWidget : findsNothing,
      );
      expect(
        find.text('Mevcut kayıtlarda uyarı yok'),
        !scenario.$3 && scenario.$4.isEmpty ? findsOneWidget : findsNothing,
      );
      for (final label in [
        if (scenario.$3) 'İSG belgeleri tam',
        ...scenario.$4,
        'Bu özet yalnız kaydedilen bilgileri gösterir; gereklilikler değerlendirilmedi.',
      ]) {
        final field = find.text(label);
        await tester.ensureVisible(field);
        await tester.pumpAndSettle();
        expect(field.hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
      expect(
        find.text('Son geçerlilik tarihi girilmemiş kayıt var'),
        findsNothing,
      );
      expect(attendance.calls, ['read:person-1']);
      expect(attendance.complianceCommands, isEmpty);
      expect(attendance.store.compliance, orderedEquals(scenario.$2));
    });
  }

  testWidgets(
    'compliance valid without details is neutral in profile and card',
    (tester) async {
      final record = _complianceRecord('without-details', emptyDetails: true);
      final attendance = _Attendance(compliance: [record]);
      await _pump(tester, attendance, scale: 2);
      expect(find.text('Mevcut kayıtlarda uyarı yok'), findsOneWidget);
      expect(find.text('Kayıt yok / değerlendirilmedi'), findsNothing);
      expect(
        find.text('Son geçerlilik tarihi girilmemiş kayıt var'),
        findsNothing,
      );
      expect(find.text('İSG TAM'), findsNothing);
      expect(find.text('İSG EKSİĞİ VAR'), findsNothing);
      await _tab(tester, 'İSG');
      final card = find.byKey(const Key('compliance-without-details'));
      await _revealCompliance(tester, card);
      expect(
        find.descendant(
          of: card,
          matching: find.text('Kullanıcı kaydı: geçerli olarak işaretlendi'),
        ),
        findsOneWidget,
      );
      for (final label in [
        'Son geçerlilik tarihi girilmemiş',
        'Belge numarası:',
        'Düzenlenme tarihi:',
        'Son geçerlilik tarihi:',
        'Not:',
        'Gerekçe:',
        'Süresi geçmiş',
        'Süresi yaklaşıyor',
      ]) {
        expect(
          find.descendant(of: card, matching: find.textContaining(label)),
          findsNothing,
        );
      }
      expect(attendance.store.compliance.single, same(record));
      expect(attendance.calls, ['read:person-1']);
      expect(attendance.complianceCommands, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('compliance dialog common path saves without opening details', (
    tester,
  ) async {
    final attendance = _Attendance(empty: true);
    await _pump(tester, attendance);
    await _tab(tester, 'İSG');
    final add = find.byKey(const Key('add-compliance-record'));
    await _revealCompliance(tester, add);
    await tester.tap(add);
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNothing);
    await _saveDialog(tester);
    final command = attendance.complianceCommands.single;
    expect(command.documentType, ComplianceDocumentType.other);
    expect(command.sourceStatus, ComplianceSourceStatus.valid);
    expect(command.documentNumber, isEmpty);
    expect(command.issuedDate, isEmpty);
    expect(command.expiryDate, isEmpty);
    expect(command.note, isEmpty);
    expect(command.reason, isEmpty);
    expect(command.expectedRevision, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'compliance duplicate edit and archive preserve sibling and optional metadata',
    (tester) async {
      final selected = _complianceRecord(
        'selected',
        expiry: '2027-06-01',
        revision: 7,
      );
      final sibling = _complianceRecord(
        'sibling',
        expiry: '2027-07-01',
        revision: 9,
      );
      final attendance = _Attendance(compliance: [selected, sibling]);
      await _pump(tester, attendance, size: const Size(390, 844), scale: 2);
      await _tab(tester, 'İSG');
      final edit = find.byKey(const Key('edit-compliance-selected'));
      await _revealCompliance(tester, edit);
      await tester.tap(edit);
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsNothing);
      await _toggleComplianceDetails(tester);
      await _toggleComplianceDetails(tester);
      expect(find.byType(TextField), findsNothing);
      await _toggleComplianceDetails(tester);
      for (final field in [
        ('Belge numarası', selected.documentNumber),
        ('Düzenlenme tarihi (YYYY-AA-GG)', selected.issuedDate),
        ('Son geçerlilik tarihi (YYYY-AA-GG)', selected.expiryDate),
        ('Not', selected.note),
        ('İstisna/uygulanamaz gerekçesi', selected.reason),
      ]) {
        expect(
          tester.widget<TextField>(_field(field.$1)).controller!.text,
          field.$2,
        );
      }
      expect(find.text('Geçerli'), findsOneWidget);
      expect(attendance.calls, ['read:person-1']);
      await tester.enterText(_field('Not'), 'Yalnız seçilen kaydın yeni notu');
      await _saveDialog(tester);
      final command = attendance.complianceCommands.single;
      expect(command.id, selected.id);
      expect(command.memberId, selected.memberId);
      expect(command.expectedRevision, 7);
      expect(command.documentType, selected.documentType);
      expect(command.sourceStatus, selected.sourceStatus);
      expect(command.documentNumber, selected.documentNumber);
      expect(command.issuedDate, selected.issuedDate);
      expect(command.expiryDate, selected.expiryDate);
      expect(command.reason, selected.reason);
      expect(command.note, 'Yalnız seçilen kaydın yeni notu');
      expect(
        identical(
          attendance.store.compliance.firstWhere(
            (item) => item.id == sibling.id,
          ),
          sibling,
        ),
        isTrue,
      );
      final archive = find.byKey(const Key('archive-compliance-selected'));
      await _revealCompliance(tester, archive);
      await tester.tap(archive);
      await tester.pumpAndSettle();
      expect(attendance.archiveCommand!.id, selected.id);
      expect(attendance.archiveCommand!.expectedRevision, 8);
      expect(attendance.archiveCommand!.eventId, isNot(command.eventId));
      expect(find.byKey(const Key('compliance-selected')), findsNothing);
      expect(
        identical(
          attendance.store.compliance.firstWhere(
            (item) => item.id == sibling.id,
          ),
          sibling,
        ),
        isTrue,
      );
      await _revealCompliance(
        tester,
        find.byKey(const Key('compliance-sibling')),
      );
      expect(find.text('Bu türde birden fazla aktif kayıt var'), findsNothing);
      expect(attendance.calls, [
        'read:person-1',
        'save-compliance',
        'read:person-1',
        'archive-compliance',
        'read:person-1',
      ]);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'compliance create edit archive and PPE assignment keep commands',
    (tester) async {
      final attendance = _Attendance();
      await _pump(tester, attendance, size: const Size(800, 1000));
      await _tab(tester, 'İSG');
      final add = find.byKey(const Key('add-compliance-record'));
      await _revealCompliance(tester, add);
      await tester.tap(add);
      await tester.pumpAndSettle();
      await _toggleComplianceDetails(tester);
      await tester.enterText(_field('Belge numarası'), 'BELGE-42');
      await _saveDialog(tester);
      final created = attendance.complianceCommands.single;
      expect(created.memberId, 'person-1');
      expect(created.expectedRevision, 0);
      expect(created.documentNumber, 'BELGE-42');
      expect(created.documentType, ComplianceDocumentType.other);
      expect(created.sourceStatus, ComplianceSourceStatus.valid);
      expect(created.eventId, isNotEmpty);
      final createdEdit = find.byKey(Key('edit-compliance-${created.id}'));
      await _revealCompliance(tester, createdEdit);
      await tester.tap(createdEdit);
      await tester.pumpAndSettle();
      await _toggleComplianceDetails(tester);
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
          matching: find.byKey(Key('archive-compliance-${created.id}')),
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

      await _tab(tester, 'KKD');
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

const _quickTypes = [
  ComplianceDocumentType.employmentEntry,
  ComplianceDocumentType.healthReport,
  ComplianceDocumentType.basicSafetyTraining,
  ComplianceDocumentType.vocationalCertificate,
];

Future<void> _toggleComplianceDetails(WidgetTester tester) async {
  final disclosure = find.byKey(const Key('compliance-dialog-details'));
  await _revealDialogControl(tester, disclosure);
  await tester.tap(disclosure);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<void> _selectDialogValue<T>(WidgetTester tester, String label) async {
  final dropdown = find.byType(DropdownButtonFormField<T>);
  await _revealDialogControl(tester, dropdown);
  await tester.tap(dropdown);
  await tester.pumpAndSettle();
  final option = find.text(label).last;
  await tester.ensureVisible(option);
  await tester.pumpAndSettle();
  await tester.tap(option);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<void> _revealDialogControl(WidgetTester tester, Finder control) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  await Scrollable.ensureVisible(tester.element(control), alignment: 0.5);
  await tester.pumpAndSettle();
  expect(control.hitTestable(), findsOneWidget);
  expect(tester.takeException(), isNull);
}

Future<void> _revealCompliance(WidgetTester tester, Finder finder) async {
  final scrollable = find
      .descendant(
        of: find.byKey(const PageStorageKey('workforce-person-compliance')),
        matching: find.byType(Scrollable),
      )
      .first;
  if (finder.evaluate().isEmpty) {
    tester.state<ScrollableState>(scrollable).position.jumpTo(0);
    await tester.pumpAndSettle();
  }
  await tester.scrollUntilVisible(
    finder,
    160,
    maxScrolls: 100,
    scrollable: scrollable,
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

List<WorkforceComplianceRecord> _coreProfileRecords() => [
  for (final type in [
    ComplianceDocumentType.employmentEntry,
    ComplianceDocumentType.healthReport,
    ComplianceDocumentType.basicSafetyTraining,
    ComplianceDocumentType.vocationalCertificate,
  ])
    _complianceRecord(type.storageValue, type: type, emptyDetails: true),
];

WorkforceComplianceRecord _complianceRecord(
  String id, {
  ComplianceDocumentType type = ComplianceDocumentType.employmentEntry,
  ComplianceSourceStatus source = ComplianceSourceStatus.valid,
  ComplianceReadStatus read = ComplianceReadStatus.valid,
  String? expiry,
  int revision = 1,
  bool emptyDetails = false,
  String? archivedAt,
}) => WorkforceComplianceRecord(
  id: id,
  memberId: 'person-1',
  documentType: type,
  documentNumber: emptyDetails ? null : 'BELGE-$id',
  issuedDate: emptyDetails ? null : '2026-07-01',
  expiryDate: expiry,
  sourceStatus: source,
  readStatus: read,
  note: emptyDetails ? null : 'Kayıt notu $id',
  reason: emptyDetails ? null : 'Kullanıcının gerekçesi $id',
  revision: revision,
  createdAt: '2026-07-01T08:00:00Z',
  updatedAt: '2026-07-01T08:00:00Z',
  archivedAt: archivedAt,
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
  _Attendance({
    this.empty = false,
    List<WorkforceComplianceRecord>? compliance,
  }) {
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
          ..compliance =
              compliance ??
              [
                if (!empty)
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
  late final FakeAttendanceApplication store;
  final calls = <String>[];
  final complianceCommands = <SaveComplianceRecordCommand>[];
  final ppeCommands = <SavePpeAssignmentCommand>[];
  ArchiveComplianceRecordCommand? archiveCommand;
  RestoreComplianceRecordCommand? restoreCommand;
  Object? complianceFailureAfterSave;
  Completer<WorkforcePersonDetail>? pending;

  @override
  Future<WorkforcePersonDetail> getPersonDetail(String memberId) async {
    calls.add('read:$memberId');
    if (pending != null) return pending!.future;
    final detail = await store.getPersonDetail(memberId);
    return WorkforcePersonDetail(
      member: detail.member,
      compliance: detail.compliance,
      archivedCompliance: detail.archivedCompliance,
      complianceEvents: detail.complianceEvents,
      ppeAssignments: detail.ppeAssignments,
      missingComplianceCount: detail.missingComplianceCount,
      validComplianceCount: detail.validComplianceCount,
      expiringComplianceCount: detail.expiringComplianceCount,
      expiredComplianceCount: detail.expiredComplianceCount,
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
  ) async {
    calls.add('save-compliance');
    complianceCommands.add(command);
    final saved = await store.saveComplianceRecord(command);
    if (complianceFailureAfterSave case final failure?) {
      complianceFailureAfterSave = null;
      throw failure;
    }
    return saved;
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
  Future<WorkforceComplianceRecord> restoreComplianceRecord(
    RestoreComplianceRecordCommand command,
  ) {
    calls.add('restore-compliance');
    restoreCommand = command;
    return store.restoreComplianceRecord(command);
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
