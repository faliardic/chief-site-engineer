import 'dart:async';

import 'package:chief_site_engineer/application/mobile_backup_application.dart';
import 'package:chief_site_engineer/domain/mobile_backup_models.dart';
import 'package:chief_site_engineer/features/memory/memory_backup_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _manifest = MobileBackupManifest(
  formatVersion: 1,
  appVersion: '0.1.0',
  buildNumber: '1',
  mobileSchemaVersion: 5,
  createdAtUtc: '2026-07-19T09:30:00Z',
  database: BackupManifestFile(
    logicalPath: 'database.sqlite3',
    byteSize: 2048,
    sha256: 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
  ),
  attachments: [],
);

void main() {
  testWidgets('320 px backup form preserves invalid input', (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final backup = _FakeBackupApplication()
      ..createFailure = const MobileBackupFailure(
        'password_confirmation_mismatch',
        'Parola doğrulaması eşleşmiyor.',
      );
    await tester.pumpWidget(
      MaterialApp(home: MemoryBackupPage(backup: backup)),
    );

    await tester.enterText(
      find.byKey(const Key('backup-password')),
      'guvenli-parola',
    );
    await tester.enterText(
      find.byKey(const Key('backup-password-confirmation')),
      'farkli-parola',
    );
    await tester.tap(find.byKey(const Key('create-backup')));
    await tester.pump();

    expect(find.text('Parola doğrulaması eşleşmiyor.'), findsOneWidget);
    expect(find.text('guvenli-parola'), findsOneWidget);
    expect(find.text('farkli-parola'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('double tap starts only one backup and enables explicit share', (
    tester,
  ) async {
    final backup = _FakeBackupApplication();
    final gate = Completer<MobileBackupCreationResult>();
    backup.createGate = gate;
    await tester.pumpWidget(
      MaterialApp(home: MemoryBackupPage(backup: backup)),
    );
    await tester.enterText(
      find.byKey(const Key('backup-password')),
      'guvenli-parola',
    );
    await tester.enterText(
      find.byKey(const Key('backup-password-confirmation')),
      'guvenli-parola',
    );

    await tester.tap(find.byKey(const Key('create-backup')));
    await tester.tap(find.byKey(const Key('create-backup')));
    await tester.pump();
    expect(backup.createCalls, 1);
    gate.complete(_creationResult);
    await tester.pumpAndSettle();
    expect(find.text('Yedek güvenle oluşturuldu.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('share-backup')));
    await tester.pumpAndSettle();
    expect(backup.sharedPath, '/safe/generated.csebackup');
  });

  testWidgets(
    'restore requires preflight, acknowledgement and second confirm',
    (tester) async {
      tester.view.physicalSize = const Size(390, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final backup = _FakeBackupApplication()..pickedPackage = _pickedPackage;
      await tester.pumpWidget(
        MaterialApp(home: MemoryBackupPage(backup: backup)),
      );

      await tester.ensureVisible(find.byKey(const Key('pick-backup')));
      await tester.tap(find.byKey(const Key('pick-backup')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('restore-password')));
      await tester.enterText(
        find.byKey(const Key('restore-password')),
        'guvenli-parola',
      );
      await tester.ensureVisible(find.byKey(const Key('preflight-backup')));
      await tester.tap(find.byKey(const Key('preflight-backup')));
      await tester.pumpAndSettle();
      expect(backup.preflightCalls, 1);
      expect(find.text('Ön kontrol özeti'), findsOneWidget);

      await tester.ensureVisible(
        find.byKey(const Key('replacement-acknowledgement')),
      );
      await tester.tap(find.byKey(const Key('replacement-acknowledgement')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('restore-backup')));
      await tester.tap(find.byKey(const Key('restore-backup')));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Tam geri yükleme'),
        ),
        findsOneWidget,
      );
      expect(backup.restoreCalls, 0);
      await tester.tap(find.byKey(const Key('restore-cancel')));
      await tester.pumpAndSettle();
      expect(backup.restoreCalls, 0);

      await tester.tap(find.byKey(const Key('restore-backup')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('restore-confirm')));
      await tester.pumpAndSettle();
      expect(backup.restoreCalls, 1);
      expect(find.textContaining('Geri yükleme tamamlandı'), findsOneWidget);
    },
  );

  testWidgets(
    'picker cancel keeps current and dispose cleans abandoned import',
    (tester) async {
      final backup = _FakeBackupApplication()..pickedPackage = _pickedPackage;
      await tester.pumpWidget(
        MaterialApp(home: MemoryBackupPage(backup: backup)),
      );

      await tester.tap(find.byKey(const Key('pick-backup')));
      await tester.pumpAndSettle();
      expect(find.text('Bir .csebackup dosyası seçildi.'), findsOneWidget);

      backup.pickedPackage = null;
      await tester.tap(find.byKey(const Key('pick-backup')));
      await tester.pumpAndSettle();
      expect(find.text('Bir .csebackup dosyası seçildi.'), findsOneWidget);
      expect(backup.discarded, isEmpty);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      expect(backup.discarded, [_pickedPackage]);
    },
  );
}

const _summary = MobileBackupSummary(
  createdAtUtc: '2026-07-19T09:30:00Z',
  fileName: 'generated.csebackup',
  packageByteSize: 4096,
  databaseByteSize: 2048,
  attachmentCount: 0,
  attachmentByteSize: 0,
  mobileSchemaVersion: 5,
);

const _creationResult = MobileBackupCreationResult(
  absolutePath: '/safe/generated.csebackup',
  packageSha256:
      'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
  summary: _summary,
);

const _pickedPackage = PickedBackupPackage(
  stablePath: '/safe/incoming/import-1.csebackup',
  originalFileName: 'input.csebackup',
  byteSize: 4096,
  sha256: 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
  importOperationId: 'import-1',
);

class _FakeBackupApplication implements MobileBackupApplication {
  Object? createFailure;
  Completer<MobileBackupCreationResult>? createGate;
  int createCalls = 0;
  int preflightCalls = 0;
  int restoreCalls = 0;
  PickedBackupPackage? pickedPackage;
  String? sharedPath;
  final discarded = <PickedBackupPackage>[];

  @override
  Future<MobileBackupCreationResult> createBackup(
    CreateMobileBackupCommand command,
  ) async {
    createCalls += 1;
    if (createFailure case final failure?) throw failure;
    return createGate?.future ?? Future.value(_creationResult);
  }

  @override
  Future<MobileBackupSummary?> lastSuccessfulBackup() async => null;

  @override
  Future<PickedBackupPackage?> pickBackupPackage([
    PickedBackupPackage? currentPackage,
  ]) async => pickedPackage;

  @override
  Future<void> discardBackupPackage(PickedBackupPackage package) async {
    discarded.add(package);
  }

  @override
  Future<MobileBackupPreflight> preflightBackup(
    PickedBackupPackage package,
    String password,
  ) async {
    preflightCalls += 1;
    return MobileBackupPreflight(
      package: package,
      manifest: _manifest,
      migratedSchemaVersion: 5,
    );
  }

  @override
  Future<MobileRestoreResult> restoreBackup(
    RestoreMobileBackupCommand command,
  ) async {
    restoreCalls += 1;
    return const MobileRestoreResult(
      restoredManifest: _manifest,
      safetyBackupPath: '/safe/safety.csebackup',
      activeSchemaVersion: 5,
    );
  }

  @override
  Future<void> shareBackup(String absolutePath) async {
    sharedPath = absolutePath;
  }
}
