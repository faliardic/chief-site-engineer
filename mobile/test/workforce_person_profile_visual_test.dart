import 'dart:async';
import 'dart:ui' show SemanticsAction;

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
      final title = find.text(type.label);
      await _revealCompliance(tester, title);
      final category = find.byKey(
        PageStorageKey('compliance-category-${type.storageValue}'),
      );
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
      'Son geçerlilik tarihi girilmemiş kayıt var',
      'Son geçerlilik tarihi girilmemiş',
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
        expect(find.text('Mevcut kayıtlarda uyarı yok'), findsNothing);
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
            scenario.$1 == ComplianceSourceStatus.valid
                ? findsOneWidget
                : findsNothing,
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
            'Son geçerlilik tarihi girilmemiş kayıt var',
          ]) {
            final field = find.text(signal);
            await tester.ensureVisible(field);
            await tester.pumpAndSettle();
            expect(field.hitTestable(), findsOneWidget);
            expect(tester.takeException(), isNull);
          }
          expect(find.text('İSG TAM'), findsNothing);
          expect(find.text('İSG EKSİĞİ VAR'), findsNothing);
          await _tab(tester, 'İSG');
          final add = find.byKey(const Key('add-compliance-record'));
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
                'Son geçerlilik tarihi: ${record.expiryDate}'
              else if (record.sourceStatus == ComplianceSourceStatus.valid)
                'Son geçerlilik tarihi girilmemiş',
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
            if (record.expiryDate == null &&
                record.sourceStatus != ComplianceSourceStatus.valid) {
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
    testWidgets('compliance dialog disclosure retains values at $size text 2', (
      tester,
    ) async {
      final attendance = _Attendance(empty: true);
      await _pump(tester, attendance, size: size, scale: 2);
      await _tab(tester, 'İSG');
      await tester.tap(find.byKey(const Key('add-compliance-record')));
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
          await tester.tap(find.byKey(const Key('add-compliance-record')));
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

  testWidgets('compliance dialog common path saves without opening details', (
    tester,
  ) async {
    final attendance = _Attendance(empty: true);
    await _pump(tester, attendance);
    await _tab(tester, 'İSG');
    await tester.tap(find.byKey(const Key('add-compliance-record')));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNothing);
    await _saveDialog(tester);
    final command = attendance.complianceCommands.single;
    expect(command.documentType, ComplianceDocumentType.employmentEntry);
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
      expect(find.text('Geçerli (kullanıcı kaydı)'), findsOneWidget);
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
      await tester.tap(find.byKey(const Key('add-compliance-record')));
      await tester.pumpAndSettle();
      await _toggleComplianceDetails(tester);
      await tester.enterText(_field('Belge numarası'), 'BELGE-42');
      await _saveDialog(tester);
      final created = attendance.complianceCommands.single;
      expect(created.memberId, 'person-1');
      expect(created.expectedRevision, 0);
      expect(created.documentNumber, 'BELGE-42');
      expect(created.documentType, ComplianceDocumentType.employmentEntry);
      expect(created.sourceStatus, ComplianceSourceStatus.valid);
      expect(created.eventId, isNotEmpty);
      await tester.tap(find.byKey(Key('edit-compliance-${created.id}')));
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

WorkforceComplianceRecord _complianceRecord(
  String id, {
  ComplianceDocumentType type = ComplianceDocumentType.employmentEntry,
  ComplianceSourceStatus source = ComplianceSourceStatus.valid,
  ComplianceReadStatus read = ComplianceReadStatus.valid,
  String? expiry,
  int revision = 1,
}) => WorkforceComplianceRecord(
  id: id,
  memberId: 'person-1',
  documentType: type,
  documentNumber: 'BELGE-$id',
  issuedDate: '2026-07-01',
  expiryDate: expiry,
  sourceStatus: source,
  readStatus: read,
  note: 'Kayıt notu $id',
  reason: 'Kullanıcının gerekçesi $id',
  revision: revision,
  createdAt: '2026-07-01T08:00:00Z',
  updatedAt: '2026-07-01T08:00:00Z',
  archivedAt: null,
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
