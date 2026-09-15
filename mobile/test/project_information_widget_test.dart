import 'dart:async';
import 'dart:convert';

import 'package:chief_site_engineer/application/agenda_application.dart';
import 'package:chief_site_engineer/application/project_information_application.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/domain/attendance_models.dart';
import 'package:chief_site_engineer/domain/inventory_models.dart';
import 'package:chief_site_engineer/domain/project_location_models.dart';
import 'package:chief_site_engineer/domain/project_information_models.dart';
import 'package:chief_site_engineer/features/projects/project_information_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _projectA = 'project-a';
const _projectB = 'project-b';
final _now = DateTime.utc(2026, 9, 13, 9);

void main() {
  testWidgets(
    'shows source categories, bounded search, copy/share and block hierarchy',
    (tester) async {
      final source = _FakeProjectInformationSource.standard();
      source.metadataByProject[_projectA] = _metadata(
        _projectA,
        address: 'Merkez Mahallesi 42',
      );
      source.profileByProject[_projectA] = ProjectProfile(
        project: source.projects[_projectA]!,
        fields: [
          ..._emptyProfile(source.projects[_projectA]!).fields,
          for (var index = 0; index < 45; index += 1)
            _profileField(
              'custom-$index',
              label: 'Mekanik not $index',
              value: 'Değer $index',
              sortOrder: 10 + index,
            ),
        ],
      );
      source.inventoryByProject[_projectA] = _inventory(
        blocks: [
          _block('block-a', 'A Blok', state: InventoryBlockState.detached),
        ],
        floors: [_floor('floor-a', 'block-a', 'Zemin Kat', archived: true)],
      );
      source.blockMetadataById['block-a'] = _blockMetadata(
        'block-a',
        totalArea: 640,
        totalAreaUnit: 'm²',
        usageType: 'Konut',
      );
      source.locationsByProject[_projectA] = [
        _location('location-a', 'Mekanik Oda', archived: true),
      ];
      source.floorLocationsByProject[_projectA] = [
        _floorLocation('relation-a', 'floor-a', 'location-a'),
      ];
      final copied = <String>[];
      final shared = <String>[];

      await tester.pumpWidget(
        _testApp(
          source,
          copyText: (text) async => copied.add(text),
          shareText: (text) async => shared.add(text),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tüm proje bilgileri'), findsOneWidget);
      expect(find.text('Proje Bilgileri'), findsOneWidget);
      expect(find.text('Konum ve Adres'), findsOneWidget);
      expect(find.text('Önemli Kişiler'), findsOneWidget);
      expect(
        tester
            .widget<TextField>(
              find.byKey(const Key('project-information-search')),
            )
            .maxLength,
        120,
      );

      await tester.scrollUntilVisible(
        find.byKey(const Key('project-information-section-address')),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Konum ve Adres'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('project-information-copy-address')),
        120,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(
        find.byKey(const ValueKey('project-information-copy-address')),
      );
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey('project-information-share-address')),
      );
      await tester.pump();
      expect(copied, ['Merkez Mahallesi 42']);
      expect(shared, ['Adres: Merkez Mahallesi 42']);
      expect(source.mutationCalls, 0);

      for (final category in const [
        ('official', 'Resmî Bilgiler'),
        ('technical', 'Teknik Bilgiler'),
        ('site', 'Saha Referansları'),
        ('custom', 'Özel Alanlar'),
      ]) {
        await tester.scrollUntilVisible(
          find.byKey(Key('project-information-section-${category.$1}')),
          250,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text(category.$2), findsOneWidget);
      }

      await tester.scrollUntilVisible(
        find.byKey(const Key('project-information-search')),
        -300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.enterText(
        find.byKey(const Key('project-information-search')),
        'mekanik',
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('project-information-search-results')),
        findsOneWidget,
      );
      expect(find.text('İlk 40 eşleşme gösteriliyor.'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('project-information-search')),
        '640',
      );
      await tester.pumpAndSettle();
      expect(find.text('Toplam alan'), findsOneWidget);
      expect(find.text('640 m²'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('project-information-search')),
        '',
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const Key('project-information-section-blocks')),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(
        find.byKey(const Key('project-information-section-blocks')),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('A Blok'),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -80));
      await tester.pumpAndSettle();
      await tester.tap(find.text('A Blok'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Zemin Kat'),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -80));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Zemin Kat'));
      await tester.pumpAndSettle();
      expect(find.text('Krokiden ayrılmış blok'), findsOneWidget);
      expect(find.text('Kat arşivlenmiş'), findsOneWidget);
      expect(find.text('Mekanik Oda'), findsOneWidget);
      expect(find.text('Mahal arşivlenmiş'), findsOneWidget);
    },
  );

  testWidgets('shows empty, partial failure and root error safely', (
    tester,
  ) async {
    final partialSource = _FakeProjectInformationSource.standard()
      ..metadataFailure = StateError('metadata unavailable');
    await tester.pumpWidget(_testApp(partialSource));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('project-information-partial-error')),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('project-information-section-address')),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Bu kaynaktaki bilgiler okunamadı.'), findsOneWidget);
    expect(find.text('Adres henüz girilmedi.'), findsNothing);
    expect(partialSource.mutationCalls, 0);

    final emptySource = _FakeProjectInformationSource.standard();
    await tester.pumpWidget(_testApp(emptySource));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('project-information-section-address')),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Adres henüz girilmedi.'), findsOneWidget);

    final failedSource = _FakeProjectInformationSource.standard()
      ..projectFailure = StateError('project unavailable');
    await tester.pumpWidget(_testApp(failedSource));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('project-information-error')), findsOneWidget);
    expect(
      find.text('Proje bilgileri güvenli biçimde okunamadı.'),
      findsOneWidget,
    );
  });

  testWidgets('project switch never paints a stale snapshot', (tester) async {
    final source = _FakeProjectInformationSource.standard(
      includeProjectB: true,
    );
    final delayedA = Completer<MobileProject>();
    source.projectReads[_projectA] = [delayedA.future];
    final application = ProjectInformationApplication(source: source);
    const pageKey = ValueKey('stable-project-information-page');

    await tester.pumpWidget(
      MaterialApp(
        home: ProjectInformationPage(
          key: pageKey,
          application: application,
          projectId: _projectA,
        ),
      ),
    );
    await tester.pump();
    expect(
      find.byKey(const Key('project-information-loading')),
      findsOneWidget,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ProjectInformationPage(
          key: pageKey,
          application: application,
          projectId: _projectB,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<Text>(
            find.byKey(const Key('project-information-project-name')).first,
          )
          .data,
      'B Projesi',
    );
    expect(find.text('A Projesi'), findsNothing);

    delayedA.complete(source.projects[_projectA]);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<Text>(
            find.byKey(const Key('project-information-project-name')).first,
          )
          .data,
      'B Projesi',
    );
    expect(find.text('A Projesi'), findsNothing);
  });

  testWidgets(
    'a valid exact-project Dashboard seed paints immediately without the '
    'blocking loading surface, then a background revalidation replaces it '
    'with fresh same-project data',
    (tester) async {
      final source = _FakeProjectInformationSource.standard();
      source.metadataByProject[_projectA] = _metadata(
        _projectA,
        address: 'Seed Adresi',
      );
      final application = ProjectInformationApplication(source: source);
      final seedSession = application.createSession();
      final seedResult = await seedSession.loadProject(_projectA);
      seedSession.clearProject();
      final seedSnapshot = (seedResult as ProjectInformationReady).snapshot;

      // Change the source after capturing the seed and block the page's own
      // background revalidation read, so the seed-vs-fresh states can be
      // observed as genuinely distinct, ordered frames rather than both
      // resolving within the same pump.
      source.metadataByProject[_projectA] = _metadata(
        _projectA,
        address: 'Güncel Adresi',
      );
      final delayedA = Completer<MobileProject>();
      source.projectReads[_projectA] = [delayedA.future];

      await tester.pumpWidget(
        MaterialApp(
          home: ProjectInformationPage(
            application: application,
            projectId: _projectA,
            seed: ProjectInformationPresentationSeed(
              projectId: _projectA,
              snapshot: seedSnapshot,
              userEntries: const [],
              pins: const [],
              siteLocation: null,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(
        find.byKey(const Key('project-information-loading')),
        findsNothing,
      );
      expect(_visibleProjectName(tester), 'A Projesi');
      await tester.scrollUntilVisible(
        find.byKey(const Key('project-information-section-address')),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Konum ve Adres'));
      await tester.pumpAndSettle();
      expect(find.text('Seed Adresi'), findsOneWidget);
      expect(find.text('Güncel Adresi'), findsNothing);

      delayedA.complete(source.projects[_projectA]);
      await tester.pumpAndSettle();
      expect(find.text('Güncel Adresi'), findsOneWidget);
      expect(find.text('Seed Adresi'), findsNothing);
      expect(source.mutationCalls, 0);
    },
  );

  testWidgets(
    'a mismatched-project seed is ignored: normal blocking load runs and no '
    'other-project content is ever painted',
    (tester) async {
      final source = _FakeProjectInformationSource.standard(
        includeProjectB: true,
      );
      final application = ProjectInformationApplication(source: source);
      final seedSession = application.createSession();
      final seedResult = await seedSession.loadProject(_projectB);
      seedSession.clearProject();
      final seedSnapshot = (seedResult as ProjectInformationReady).snapshot;
      // Block A's own load so the still-visible loading surface (proving the
      // mismatched seed was ignored and a normal load actually ran) can be
      // observed before it resolves.
      final delayedA = Completer<MobileProject>();
      source.projectReads[_projectA] = [delayedA.future];

      await tester.pumpWidget(
        MaterialApp(
          home: ProjectInformationPage(
            application: application,
            projectId: _projectA,
            seed: ProjectInformationPresentationSeed(
              projectId: _projectB,
              snapshot: seedSnapshot,
              userEntries: const [],
              pins: const [],
              siteLocation: null,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(
        find.byKey(const Key('project-information-loading')),
        findsOneWidget,
      );
      expect(find.text('B Projesi'), findsNothing);

      delayedA.complete(source.projects[_projectA]);
      await tester.pumpAndSettle();
      expect(_visibleProjectName(tester), 'A Projesi');
      expect(find.text('B Projesi'), findsNothing);
    },
  );

  testWidgets(
    'a stale background revalidation started from a seed cannot overwrite a '
    'subsequent real project switch',
    (tester) async {
      final source = _FakeProjectInformationSource.standard(
        includeProjectB: true,
      );
      final delayedA = Completer<MobileProject>();
      final application = ProjectInformationApplication(source: source);
      final seedSession = application.createSession();
      final seedResult = await seedSession.loadProject(_projectA);
      seedSession.clearProject();
      final seedSnapshot = (seedResult as ProjectInformationReady).snapshot;
      // Re-arm the block for the page's own background revalidation.
      source.projectReads[_projectA] = [delayedA.future];
      const pageKey = ValueKey('seeded-project-information-page');

      await tester.pumpWidget(
        MaterialApp(
          home: ProjectInformationPage(
            key: pageKey,
            application: application,
            projectId: _projectA,
            seed: ProjectInformationPresentationSeed(
              projectId: _projectA,
              snapshot: seedSnapshot,
              userEntries: const [],
              pins: const [],
              siteLocation: null,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(
        find.byKey(const Key('project-information-loading')),
        findsNothing,
      );
      expect(_visibleProjectName(tester), 'A Projesi');

      // Real project switch while A's seeded revalidation is still pending.
      await tester.pumpWidget(
        MaterialApp(
          home: ProjectInformationPage(
            key: pageKey,
            application: application,
            projectId: _projectB,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(_visibleProjectName(tester), 'B Projesi');
      expect(find.text('A Projesi'), findsNothing);

      delayedA.complete(source.projects[_projectA]);
      await tester.pumpAndSettle();
      expect(_visibleProjectName(tester), 'B Projesi');
      expect(find.text('A Projesi'), findsNothing);
    },
  );

  testWidgets('archived custom field is explicit and only restore mutates', (
    tester,
  ) async {
    final source = _FakeProjectInformationSource.standard();
    source.profileEventsByProject[_projectA] = [
      _profileEvent(
        id: 'event-create',
        fieldId: 'archived-field',
        sequence: 1,
        type: ProjectProfileEventType.fieldCreated,
        payload: {
          'label': 'Eski not',
          'value': 'Korunan değer',
          'sort_order': 7,
        },
      ),
      _profileEvent(
        id: 'event-archive',
        fieldId: 'archived-field',
        sequence: 2,
        type: ProjectProfileEventType.fieldArchived,
        payload: {
          'was_archived': false,
          'is_archived': true,
          'revision_before': 1,
          'revision_after': 2,
          'sort_order': 7,
        },
      ),
    ];
    final profileApplication = _RestoreProfileApplication(source);

    await tester.pumpWidget(
      _testApp(source, profileApplication: profileApplication),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('project-information-archived-fields')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -80));
    await tester.pumpAndSettle();
    expect(find.text('Arşivlenmiş özel alanlar'), findsOneWidget);
    expect(find.text('1 alan · kayıtlar korunuyor'), findsOneWidget);
    await tester.tap(find.text('Arşivlenmiş özel alanlar'));
    await tester.pumpAndSettle();
    expect(find.text('Eski not'), findsOneWidget);
    expect(find.text('Korunan değer'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('project-information-restore-archived-field')),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -48));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('project-information-restore-archived-field')),
    );
    await tester.pumpAndSettle();

    expect(profileApplication.commands, hasLength(1));
    expect(profileApplication.commands.single.projectId, _projectA);
    expect(profileApplication.commands.single.fieldId, 'archived-field');
    expect(profileApplication.commands.single.archive, isFalse);
    expect(profileApplication.commands.single.expectedRevision, 2);
    expect(
      find.byKey(const Key('project-information-archived-fields')),
      findsNothing,
    );
    expect(source.mutationCalls, 0);
  });

  testWidgets('failed and unresolved sources never look empty or actionable', (
    tester,
  ) async {
    final failedSource = _FakeProjectInformationSource.standard()
      ..partyFailure = StateError('party unavailable')
      ..inventoryFailure = StateError('inventory unavailable');
    await tester.pumpWidget(_testApp(failedSource));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const Key('project-information-search')),
      -300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(
      find.byKey(const Key('project-information-search')),
      'işveren',
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Atama durumu okunamadı; kayıtlar korundu'),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('project-information-copy-party-employer')),
      findsNothing,
    );
    await tester.enterText(
      find.byKey(const Key('project-information-search')),
      'aktif blok sayısı',
    );
    await tester.pumpAndSettle();
    expect(find.text('Okunamadı; kayıtlar korundu'), findsOneWidget);
    expect(
      find.byKey(
        const ValueKey('project-information-copy-derived-active-blocks'),
      ),
      findsNothing,
    );

    final archivedTargetSource = _FakeProjectInformationSource.standard();
    archivedTargetSource.partiesByProject[_projectA] = [
      _party('party-employer', subcontractorId: 'company-employer'),
    ];
    archivedTargetSource.companiesByProject[_projectA] = [
      _company('company-employer', active: false),
    ];
    await tester.pumpWidget(_testApp(archivedTargetSource));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('project-information-search')),
      'işveren',
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('kayıt arşivli'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('project-information-copy-party-employer')),
      findsNothing,
    );

    final unresolvedSource = _FakeProjectInformationSource.standard();
    unresolvedSource.inventoryByProject[_projectA] = _inventory(
      blocks: const [],
      floors: [_floor('orphan-floor', 'missing-block', 'Bağsız Kat')],
    );
    unresolvedSource.locationsByProject[_projectA] = [
      _location('location-a', 'Bağsız Mahal'),
    ];
    unresolvedSource.floorLocationsByProject[_projectA] = [
      _floorLocation('orphan-relation', 'missing-floor', 'location-a'),
    ];
    await tester.pumpWidget(_testApp(unresolvedSource));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('project-information-section-blocks')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await Scrollable.ensureVisible(
      tester.element(
        find.byKey(const Key('project-information-section-blocks')),
      ),
      alignment: 0.5,
      duration: Duration.zero,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bloklar, katlar ve Mahaller'));
    await tester.pumpAndSettle();
    expect(find.text('Çözümlenemeyen yapı kayıtları'), findsOneWidget);
    expect(find.text('Bağsız Kat'), findsOneWidget);
    expect(find.text('Bağlı blok bulunamadı'), findsOneWidget);
    expect(find.text('Bağsız Mahal'), findsOneWidget);
    expect(find.text('Bağlı kat bulunamadı'), findsOneWidget);
  });

  testWidgets('failed floor-location read is not shown as no connection', (
    tester,
  ) async {
    final source = _FakeProjectInformationSource.standard();
    source.inventoryByProject[_projectA] = _inventory(
      blocks: [_block('block-a', 'A Blok')],
      floors: [_floor('floor-a', 'block-a', 'Zemin Kat')],
    );
    source.blockMetadataById['block-a'] = _blockMetadata('block-a');
    source.floorLocationFailure = StateError('relations unavailable');
    await tester.pumpWidget(_testApp(source));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('project-information-search')),
      'zemin kat',
    );
    await tester.pumpAndSettle();
    expect(find.text('Zemin Kat'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('project-information-search')),
      '',
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('project-information-section-blocks')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(
      find.byKey(const Key('project-information-section-blocks')),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('A Blok'),
      150,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -80));
    await tester.pumpAndSettle();
    await tester.tap(find.text('A Blok'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Zemin Kat'),
      150,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -80));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Zemin Kat'));
    await tester.pumpAndSettle();
    expect(
      find.text('Mahal bağlantıları okunamadı. Kayıtlar korundu.'),
      findsOneWidget,
    );
    expect(find.text('Mahal bağlantısı bulunmuyor.'), findsNothing);
  });

  testWidgets('six category actions use typed forms and active-only search', (
    tester,
  ) async {
    final source = _FakeProjectInformationSource.standard();
    final mutations = _InformationMutations()
      ..entries.addAll([
        _userEntry('active-entry', 'Aktif saha kodu', archived: false),
        _userEntry('archived-entry', 'Arşivli saha kodu', archived: true),
      ]);
    await tester.pumpWidget(_testApp(source, mutations: mutations));
    await tester.pumpAndSettle();

    for (final affordance in const [
      ('project', '+ Proje bilgisi ekle'),
      ('address', '+ Konum / adres bilgisi ekle'),
      ('parties', '+ Kişi ekle'),
      ('official', '+ Resmî bilgi ekle'),
      ('technical', '+ Teknik bilgi ekle'),
      ('site', '+ Saha bilgisi ekle'),
    ]) {
      await tester.scrollUntilVisible(
        find.byKey(ValueKey('project-information-add-${affordance.$1}')),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        find.byKey(ValueKey('project-information-add-${affordance.$1}')),
        findsOneWidget,
      );
      expect(find.text(affordance.$2), findsOneWidget);
    }

    await tester.scrollUntilVisible(
      find.byKey(const Key('project-information-add-technical')),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(
      find.byKey(const Key('project-information-add-technical')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('project-information-technical-form')),
      findsOneWidget,
    );
    await tester.enterText(
      find.byKey(const Key('project-information-technical-label')),
      'Beton sınıfı',
    );
    await tester.enterText(
      find.byKey(const Key('project-information-technical-value')),
      '35',
    );
    await tester.enterText(
      find.byKey(const Key('project-information-technical-unit')),
      'MPa',
    );
    await tester.tap(
      find.byKey(const Key('project-information-technical-save')),
    );
    await tester.pumpAndSettle();
    expect(
      mutations.created.single.category,
      ProjectInformationCategory.technical,
    );
    expect(
      mutations.created.single.value.kind,
      ProjectInformationValueKind.number,
    );
    expect(mutations.created.single.unit, 'MPa');

    await tester.scrollUntilVisible(
      find.byKey(const Key('project-information-search')),
      -300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(
      find.byKey(const Key('project-information-search')),
      'saha kodu',
    );
    await tester.pumpAndSettle();
    expect(find.text('Aktif saha kodu'), findsOneWidget);
    expect(find.text('Arşivli saha kodu'), findsNothing);
  });

  testWidgets(
    'contact form writes structured fields without inferred identity',
    (tester) async {
      final source = _FakeProjectInformationSource.standard();
      final mutations = _InformationMutations();
      await tester.pumpWidget(_testApp(source, mutations: mutations));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const Key('project-information-add-parties')),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(
        find.byKey(const Key('project-information-add-parties')),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('project-information-contact-label')),
        'Şantiye şefi',
      );
      await tester.enterText(
        find.byKey(const Key('project-information-contact-name')),
        'Ayşe Kaya',
      );
      await tester.enterText(
        find.byKey(const Key('project-information-contact-phone')),
        '555 111 22 33',
      );
      await tester.enterText(
        find.byKey(const Key('project-information-contact-whatsapp')),
        '555 444 55 66',
      );
      await tester.tap(
        find.byKey(const Key('project-information-contact-save')),
      );
      await tester.pumpAndSettle();

      final command = mutations.created.single;
      expect(command.value.kind, ProjectInformationValueKind.contact);
      expect(command.value.contact!.name, 'Ayşe Kaya');
      expect(command.value.contact!.phone, '555 111 22 33');
      expect(command.value.contact!.whatsAppNumber, '555 444 55 66');
      expect(command.value.contact!.referenceType, isNull);
      expect(command.value.contact!.referenceId, isNull);
      expect(command.note, isNull);
    },
  );

  testWidgets('user entry edit archive restore and pin use current revisions', (
    tester,
  ) async {
    final source = _FakeProjectInformationSource.standard();
    final mutations = _InformationMutations()
      ..entries.add(
        _userEntry(
          'editable-entry',
          'Kapı kodu',
          archived: false,
          category: ProjectInformationCategory.project,
        ),
      );
    await tester.pumpWidget(_testApp(source, mutations: mutations));
    await tester.pumpAndSettle();

    final actions = find.byKey(
      const ValueKey('project-information-actions-user-editable-entry'),
    );
    await tester.tap(actions);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Düzenle'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('project-information-form-value')),
      'B-19',
    );
    await tester.tap(find.byKey(const Key('project-information-form-save')));
    await tester.pumpAndSettle();
    expect(mutations.updated.single.expectedRevision, 1);
    // Drain this mutation's snackbar (pumpAndSettle only waits out pending
    // animation frames, not an idle real Timer) so it can't queue behind
    // and mask a later step's snackbar text.
    await tester.pump(const Duration(seconds: 5));

    await tester.tap(actions);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Arşivle'));
    await tester.pumpAndSettle();
    expect(mutations.archived.single.expectedRevision, 2);
    expect(mutations.archived.single.archived, isTrue);
    await tester.pump(const Duration(seconds: 5));

    final archivedSection = find.byKey(
      const Key('project-information-archived-user-entries'),
    );
    await tester.scrollUntilVisible(
      archivedSection,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(archivedSection);
    await tester.pumpAndSettle();
    final archivedTile = find.byKey(
      const ValueKey('project-information-user-restore-editable-entry'),
    );
    final restoreButton = find.descendant(
      of: archivedTile,
      matching: find.byType(TextButton),
    );
    await tester.ensureVisible(restoreButton);
    await tester.pumpAndSettle();
    await tester.tap(restoreButton);
    await tester.pumpAndSettle();
    expect(mutations.archived.last.expectedRevision, 3);
    expect(mutations.archived.last.archived, isFalse);
    await tester.pump(const Duration(seconds: 5));

    await tester.scrollUntilVisible(
      actions,
      -300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(actions);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hızlı Bilgilere ekle'));
    await tester.pumpAndSettle();
    expect(
      mutations.pinned.single.key.space,
      ProjectInformationKeySpace.userEntry,
    );
    expect(mutations.pinned.single.key.id, 'editable-entry');
    // Drain the "eklendi" snackbar's auto-dismiss timer (pumpAndSettle only
    // waits out pending animation frames, not a real Timer with nothing
    // currently scheduled) so it can't mask the next snackbar's text.
    await tester.pump(const Duration(seconds: 5));

    await tester.tap(actions);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hızlı Bilgilerden kaldır'));
    await tester.pump();
    // Issue #823: pin/unpin must never trigger the blocking full-page load.
    expect(find.byKey(const Key('project-information-loading')), findsNothing);
    expect(mutations.unpinned.single.expectedRevision, 1);
    await tester.pump();
    expect(
      find.text('Kapı kodu Hızlı Bilgilerden kaldırıldı.'),
      findsOneWidget,
    );
    final undoAction = tester.widget<SnackBarAction>(
      find.widgetWithText(SnackBarAction, 'Geri al'),
    );
    // Source entry is untouched by unpin.
    expect(mutations.entries.single.id, 'editable-entry');

    undoAction.onPressed();
    await tester.pump();
    expect(find.byKey(const Key('project-information-loading')), findsNothing);
    await tester.pump(const Duration(seconds: 5));
    expect(mutations.pinned.length, 2);
    expect(mutations.pinned.last.key.id, 'editable-entry');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Issue #823: Undo never overwrites a legitimate concurrent reorder of '
    'the remaining pins',
    (tester) async {
      final source = _FakeProjectInformationSource.standard();
      const otherA = ProjectInformationKey(
        space: ProjectInformationKeySpace.systemValue,
        id: 'other-a',
      );
      const otherB = ProjectInformationKey(
        space: ProjectInformationKeySpace.systemValue,
        id: 'other-b',
      );
      final mutations = _InformationMutations()
        ..entries.add(
          _userEntry(
            'editable-entry',
            'Kapı kodu',
            archived: false,
            category: ProjectInformationCategory.project,
          ),
        )
        ..pins.addAll([
          ProjectInformationPin(
            id: 'pin-other-a',
            projectId: _projectA,
            key: otherA,
            sortOrder: 0,
            revision: 1,
            createdAt: '2026-09-14T09:00:00.000Z',
            updatedAt: '2026-09-14T09:00:00.000Z',
            sourceAvailable: true,
          ),
          ProjectInformationPin(
            id: 'pin-editable',
            projectId: _projectA,
            key: const ProjectInformationKey(
              space: ProjectInformationKeySpace.userEntry,
              id: 'editable-entry',
            ),
            sortOrder: 1,
            revision: 1,
            createdAt: '2026-09-14T09:00:00.000Z',
            updatedAt: '2026-09-14T09:00:00.000Z',
            sourceAvailable: true,
          ),
          ProjectInformationPin(
            id: 'pin-other-b',
            projectId: _projectA,
            key: otherB,
            sortOrder: 2,
            revision: 1,
            createdAt: '2026-09-14T09:00:00.000Z',
            updatedAt: '2026-09-14T09:00:00.000Z',
            sourceAvailable: true,
          ),
        ]);
      await tester.pumpWidget(_testApp(source, mutations: mutations));
      await tester.pumpAndSettle();

      final actions = find.byKey(
        const ValueKey('project-information-actions-user-editable-entry'),
      );
      await tester.tap(actions);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hızlı Bilgilerden kaldır'));
      await tester.pumpAndSettle();
      expect(mutations.unpinned.single.id, 'pin-editable');
      expect(mutations.pins.map((pin) => pin.id).toList(), [
        'pin-other-a',
        'pin-other-b',
      ]);
      final undoAction = tester.widget<SnackBarAction>(
        find.widgetWithText(SnackBarAction, 'Geri al'),
      );
      // Drain the "kaldırıldı" snackbar's auto-dismiss timer — otherwise
      // the Undo-tap's own snackbar just queues behind it and is invisible
      // to a `find.text` check no matter how long we pump.
      // showSnackBar() only queues behind a still-visible snackbar — it does
      // not preempt it — so force the prior "kaldırıldı" snackbar closed
      // immediately rather than depending on its own auto-dismiss timer.
      tester
          .state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger))
          .removeCurrentSnackBar();
      await tester.pump();

      // A legitimate concurrent action reorders the two remaining pins
      // while the Undo snackbar is still showing — this must survive.
      final beforeReorder = {
        for (final pin in mutations.pins) pin.id: pin.revision,
      };
      await mutations.reorderPins(
        ReorderProjectInformationPinsCommand(
          eventId: 'concurrent-reorder',
          projectId: _projectA,
          orderedPinIds: ['pin-other-b', 'pin-other-a'],
          expectedRevisions: beforeReorder,
        ),
      );
      expect(mutations.reordered, hasLength(1));

      undoAction.onPressed();
      // Two chained awaits (setPin, then listPins) run before the snackbar
      // appears; pump repeatedly to let both resolve and the snackbar
      // entrance animation start, then check right away — a later drain
      // would dismiss it before the assertion.
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        find.text(
          'Bilgi geri eklendi; eşzamanlı değişiklik nedeniyle sıra korunamadı.',
        ),
        findsOneWidget,
      );
      await tester.pump(const Duration(seconds: 5));

      // Stage 1 (setPin) still succeeds — the pin itself is restored.
      expect(mutations.pinned.last.key.id, 'editable-entry');
      expect(mutations.pins.map((pin) => pin.id).toSet(), {
        'pin-other-a',
        'pin-other-b',
        'pin-editable',
      });
      // No second, order-restoring reorderPins call was issued — only the
      // one concurrent call above exists.
      expect(mutations.reordered, hasLength(1));
      // The concurrent reorder's relative order survives; the restored pin
      // is appended, not spliced back into its old middle position.
      expect(mutations.pins.map((pin) => pin.id).toList(), [
        'pin-other-b',
        'pin-other-a',
        'pin-editable',
      ]);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Issue #823: a post-restore order-fix failure is reported as partial '
    'success, not total Undo failure, and still revalidates',
    (tester) async {
      final source = _FakeProjectInformationSource.standard();
      final mutations = _InformationMutations()
        ..entries.add(
          _userEntry(
            'editable-entry',
            'Kapı kodu',
            archived: false,
            category: ProjectInformationCategory.project,
          ),
        )
        ..pins.addAll([
          ProjectInformationPin(
            id: 'pin-other-a',
            projectId: _projectA,
            key: const ProjectInformationKey(
              space: ProjectInformationKeySpace.systemValue,
              id: 'other-a',
            ),
            sortOrder: 0,
            revision: 1,
            createdAt: '2026-09-14T09:00:00.000Z',
            updatedAt: '2026-09-14T09:00:00.000Z',
            sourceAvailable: true,
          ),
          ProjectInformationPin(
            id: 'pin-editable',
            projectId: _projectA,
            key: const ProjectInformationKey(
              space: ProjectInformationKeySpace.userEntry,
              id: 'editable-entry',
            ),
            sortOrder: 1,
            revision: 1,
            createdAt: '2026-09-14T09:00:00.000Z',
            updatedAt: '2026-09-14T09:00:00.000Z',
            sourceAvailable: true,
          ),
          // A pin after the removed/middle one — restoring the removed pin
          // at the end (fake `setPin` semantics, matching real behavior)
          // must differ from its original middle position, so a reorder is
          // actually attempted and the injected failure below is exercised.
          ProjectInformationPin(
            id: 'pin-other-b',
            projectId: _projectA,
            key: const ProjectInformationKey(
              space: ProjectInformationKeySpace.systemValue,
              id: 'other-b',
            ),
            sortOrder: 2,
            revision: 1,
            createdAt: '2026-09-14T09:00:00.000Z',
            updatedAt: '2026-09-14T09:00:00.000Z',
            sourceAvailable: true,
          ),
        ]);
      await tester.pumpWidget(_testApp(source, mutations: mutations));
      await tester.pumpAndSettle();

      final actions = find.byKey(
        const ValueKey('project-information-actions-user-editable-entry'),
      );
      await tester.tap(actions);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hızlı Bilgilerden kaldır'));
      await tester.pumpAndSettle();
      final undoAction = tester.widget<SnackBarAction>(
        find.widgetWithText(SnackBarAction, 'Geri al'),
      );
      // showSnackBar() only queues behind a still-visible snackbar — it does
      // not preempt it — so force the prior "kaldırıldı" snackbar closed
      // immediately rather than depending on its own auto-dismiss timer.
      tester
          .state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger))
          .removeCurrentSnackBar();
      await tester.pump();

      // The concurrent state is unchanged (safe to restore order), but the
      // order-restoring reorderPins call itself fails transiently.
      mutations.reorderFailure = const ProjectInformationFailure(
        'synthetic_reorder_failure',
      );

      undoAction.onPressed();
      // Two chained awaits (setPin, then listPins) run before the snackbar
      // appears; pump twice to let both resolve, then check right away —
      // a later drain would dismiss it before the assertion.
      await tester.pump();
      await tester.pump();
      expect(find.text('Bilgi geri eklendi; sıra korunamadı.'), findsOneWidget);
      expect(find.text('Geri alma tamamlanamadı.'), findsNothing);
      await tester.pump(const Duration(seconds: 5));

      // Stage 1 (setPin) succeeded — must never be reported as total
      // Undo failure.
      expect(mutations.pinned.last.key.id, 'editable-entry');
      expect(mutations.pins.map((pin) => pin.id).toSet(), {
        'pin-other-a',
        'pin-other-b',
        'pin-editable',
      });
      expect(mutations.reordered, hasLength(1));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Issue #823: a stale Undo snackbar after a real project switch is a '
    'safe no-op — it never calls setPin against the newly active project',
    (tester) async {
      final source = _FakeProjectInformationSource.standard(
        includeProjectB: true,
      );
      final mutations = _InformationMutations()
        ..entries.add(
          _userEntry(
            'editable-entry',
            'Kapı kodu',
            archived: false,
            category: ProjectInformationCategory.project,
          ),
        )
        ..pins.add(
          ProjectInformationPin(
            id: 'pin-editable',
            projectId: _projectA,
            key: const ProjectInformationKey(
              space: ProjectInformationKeySpace.userEntry,
              id: 'editable-entry',
            ),
            sortOrder: 0,
            revision: 1,
            createdAt: '2026-09-14T09:00:00.000Z',
            updatedAt: '2026-09-14T09:00:00.000Z',
            sourceAvailable: true,
          ),
        );
      final application = ProjectInformationApplication(
        source: source,
        mutations: mutations,
      );
      const pageKey = ValueKey('stable-project-information-page');

      await tester.pumpWidget(
        MaterialApp(
          home: ProjectInformationPage(
            key: pageKey,
            application: application,
            projectId: _projectA,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final actions = find.byKey(
        const ValueKey('project-information-actions-user-editable-entry'),
      );
      await tester.tap(actions);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hızlı Bilgilerden kaldır'));
      await tester.pumpAndSettle();
      expect(mutations.unpinned.single.id, 'pin-editable');
      final undoAction = tester.widget<SnackBarAction>(
        find.widgetWithText(SnackBarAction, 'Geri al'),
      );

      // A real project switch happens on this exact page instance while
      // the Undo snackbar is still showing.
      await tester.pumpWidget(
        MaterialApp(
          home: ProjectInformationPage(
            key: pageKey,
            application: application,
            projectId: _projectB,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<Text>(
              find.byKey(const Key('project-information-project-name')).first,
            )
            .data,
        'B Projesi',
      );

      undoAction.onPressed();
      await tester.pump();
      await tester.pumpAndSettle();

      // The stale Undo must be a safe no-op: no setPin call at all.
      expect(mutations.pinned, isEmpty);
      expect(mutations.pins, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('revision conflict preserves entry and explains refresh', (
    tester,
  ) async {
    final source = _FakeProjectInformationSource.standard();
    final mutations = _InformationMutations()
      ..failUpdates = true
      ..entries.add(
        _userEntry(
          'conflict-entry',
          'Korunan bilgi',
          archived: false,
          category: ProjectInformationCategory.project,
        ),
      );
    await tester.pumpWidget(_testApp(source, mutations: mutations));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(
        const ValueKey('project-information-actions-user-conflict-entry'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Düzenle'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('project-information-form-value')),
      'Kaybolmamalı',
    );
    await tester.tap(find.byKey(const Key('project-information-form-save')));
    await tester.pumpAndSettle();

    expect(
      find.text('Kayıt başka bir işlemde değişti. Güncel halini yeniden açın.'),
      findsOneWidget,
    );
    expect(mutations.updated.single.expectedRevision, 1);
    expect(mutations.entries.single.value.text, 'SR-42');
    expect(mutations.entries.single.revision, 1);
  });

  testWidgets(
    'location entry exposes map/share-location actions with expected URI',
    (tester) async {
      final source = _FakeProjectInformationSource.standard();
      source.metadataByProject[_projectA] = _metadata(
        _projectA,
        address: 'Merkez Mahallesi 42',
      );
      final launches = <Uri>[];
      final shared = <String>[];
      await tester.pumpWidget(
        _testApp(
          source,
          shareText: (text) async => shared.add(text),
          launchUri: (uri) async {
            launches.add(uri);
            return true;
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.byKey(const Key('project-information-section-address')),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Konum ve Adres'));
      await tester.pumpAndSettle();

      final mapButton = find.byKey(
        const ValueKey('project-information-map-address'),
      );
      expect(mapButton, findsOneWidget);
      await tester.tap(mapButton);
      await tester.pumpAndSettle();
      expect(launches, hasLength(1));
      expect(launches.single.host, 'www.google.com');
      expect(launches.single.queryParameters['query'], 'Merkez Mahallesi 42');

      await tester.tap(
        find.byKey(
          const ValueKey('project-information-share-location-address'),
        ),
      );
      await tester.pumpAndSettle();
      expect(shared.single, contains('Merkez Mahallesi 42'));
      expect(shared.single, contains('www.google.com'));
    },
  );

  testWidgets(
    'structured contact entry exposes call/WhatsApp with sanitized numbers',
    (tester) async {
      final source = _FakeProjectInformationSource.standard();
      final mutations = _InformationMutations()
        ..entries.add(
          _userEntry(
            'contact-entry',
            'Saha sorumlusu',
            archived: false,
            category: ProjectInformationCategory.contact,
            value: const ProjectInformationEntryValue.contact(
              ProjectInformationContact(
                name: 'Ahmet Yılmaz',
                phone: '0532 123 45 67',
                whatsAppNumber: '+90 532 123 45 67',
                referenceId: 'internal-record-id-should-not-leak',
              ),
            ),
          ),
        );
      final launches = <Uri>[];
      final copied = <String>[];
      await tester.pumpWidget(
        _testApp(
          source,
          mutations: mutations,
          copyText: (text) async => copied.add(text),
          launchUri: (uri) async {
            launches.add(uri);
            return true;
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.byKey(const Key('project-information-section-parties')),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Önemli Kişiler'));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(
          const ValueKey('project-information-call-user-contact-entry'),
        ),
      );
      await tester.pumpAndSettle();
      expect(launches.single.scheme, 'tel');
      expect(
        launches.single.path,
        '0532123456'
        '7',
      );

      await tester.tap(
        find.byKey(
          const ValueKey('project-information-whatsapp-user-contact-entry'),
        ),
      );
      await tester.pumpAndSettle();
      expect(launches.last.host, 'wa.me');
      expect(launches.last.path, '/905321234567');

      await tester.tap(
        find.byKey(
          const ValueKey('project-information-copy-user-contact-entry'),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        copied.single,
        isNot(contains('internal-record-id-should-not-leak')),
      );
    },
  );

  testWidgets('missing or malformed values hide direct actions safely', (
    tester,
  ) async {
    final source = _FakeProjectInformationSource.standard();
    final mutations = _InformationMutations()
      ..entries.add(
        _userEntry(
          'bad-contact',
          'Belirsiz kişi',
          archived: false,
          category: ProjectInformationCategory.contact,
          value: const ProjectInformationEntryValue.contact(
            ProjectInformationContact(name: 'İsim Yok Numara', phone: 'abc'),
          ),
        ),
      );
    await tester.pumpWidget(_testApp(source, mutations: mutations));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('project-information-map-address')),
      findsNothing,
    );

    await tester.scrollUntilVisible(
      find.byKey(const Key('project-information-section-parties')),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Önemli Kişiler'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('project-information-call-user-bad-contact')),
      findsNothing,
    );
    expect(
      find.byKey(
        const ValueKey('project-information-whatsapp-user-bad-contact'),
      ),
      findsNothing,
    );
  });

  testWidgets('failed launch reports safe human-readable feedback', (
    tester,
  ) async {
    final source = _FakeProjectInformationSource.standard();
    source.metadataByProject[_projectA] = _metadata(
      _projectA,
      address: 'Merkez Mahallesi 42',
    );
    await tester.pumpWidget(_testApp(source, launchUri: (uri) async => false));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const Key('project-information-section-address')),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Konum ve Adres'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('project-information-map-address')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Harita açılamadı.'), findsOneWidget);
  });

  testWidgets(
    'Konum ve Adres header stays on one line at narrow width and high text scale',
    (tester) async {
      final source = _FakeProjectInformationSource.standard();
      source.metadataByProject[_projectA] = _metadata(
        _projectA,
        address: 'Merkez Mahallesi 42',
      );
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_testApp(source, textScale: 1.3));
      await tester.pumpAndSettle();

      expect(find.text('Konum ve Adres'), findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(
        find.byKey(const ValueKey('project-information-add-address')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('project-information-add-address')),
          matching: find.byType(Icon),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('Şantiye konumu row shows unset state and offers Konum seç', (
    tester,
  ) async {
    final source = _FakeProjectInformationSource.standard();
    final mutations = _InformationMutations();
    await tester.pumpWidget(_testApp(source, mutations: mutations));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const Key('project-information-section-address')),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Konum ve Adres'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('project-information-site-location')),
      findsOneWidget,
    );
    expect(find.text('Haritadan seçilmedi.'), findsOneWidget);
    expect(find.text('Konum seç'), findsOneWidget);
    expect(
      find.byKey(const Key('project-information-site-location-map')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('project-information-site-location-clear')),
      findsNothing,
    );
  });

  testWidgets(
    'existing Şantiye konumu exposes Değiştir/Haritada aç/paylaş/kaldır',
    (tester) async {
      final source = _FakeProjectInformationSource.standard();
      final mutations = _InformationMutations()
        ..siteLocation = const ProjectSiteLocation(
          projectId: _projectA,
          latitude: 41.015137,
          longitude: 28.97953,
          revision: 1,
          createdAt: '2026-09-13T09:00:00.000Z',
          updatedAt: '2026-09-13T09:00:00.000Z',
        );
      await tester.pumpWidget(_testApp(source, mutations: mutations));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.byKey(const Key('project-information-section-address')),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Konum ve Adres'));
      await tester.pumpAndSettle();

      expect(find.text('Değiştir'), findsOneWidget);
      expect(find.text('Konum seç'), findsNothing);
      expect(
        find.byKey(const Key('project-information-site-location-map')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('project-information-site-location-share')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('project-information-site-location-clear')),
        findsOneWidget,
      );
    },
  );

  testWidgets('Kaldır clears the site location after explicit confirmation', (
    tester,
  ) async {
    final source = _FakeProjectInformationSource.standard();
    final mutations = _InformationMutations()
      ..siteLocation = const ProjectSiteLocation(
        projectId: _projectA,
        latitude: 41.015137,
        longitude: 28.97953,
        revision: 1,
        createdAt: '2026-09-13T09:00:00.000Z',
        updatedAt: '2026-09-13T09:00:00.000Z',
      );
    await tester.pumpWidget(_testApp(source, mutations: mutations));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const Key('project-information-section-address')),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Konum ve Adres'));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const Key('project-information-site-location-clear')),
    );
    await tester.pumpAndSettle();
    // Cancel first: value must be preserved.
    await tester.tap(find.text('Vazgeç'));
    await tester.pumpAndSettle();
    expect(find.text('Değiştir'), findsOneWidget);
    expect(mutations.siteLocation, isNotNull);

    await tester.tap(
      find.byKey(const Key('project-information-site-location-clear')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('project-information-site-location-confirm-clear')),
    );
    await tester.pumpAndSettle();

    expect(mutations.siteLocation, isNull);
    expect(find.text('Haritadan seçilmedi.'), findsOneWidget);
    expect(find.text('Konum seç'), findsOneWidget);
  });

  testWidgets(
    'project switch clears the previously shown Şantiye konumu before showing '
    'the new project state',
    (tester) async {
      final source = _FakeProjectInformationSource.standard(
        includeProjectB: true,
      );
      final mutations = _InformationMutations()
        ..siteLocation = const ProjectSiteLocation(
          projectId: _projectA,
          latitude: 41.015137,
          longitude: 28.97953,
          revision: 1,
          createdAt: '2026-09-13T09:00:00.000Z',
          updatedAt: '2026-09-13T09:00:00.000Z',
        );
      final application = ProjectInformationApplication(
        source: source,
        mutations: mutations,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: ProjectInformationPage(
            application: application,
            projectId: _projectA,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const Key('project-information-section-address')),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Konum ve Adres'));
      await tester.pumpAndSettle();
      expect(find.text('Değiştir'), findsOneWidget);

      // Project B has no site location for the fake source/mutations.
      await tester.pumpWidget(
        MaterialApp(
          home: ProjectInformationPage(
            application: application,
            projectId: _projectB,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const Key('project-information-section-address')),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Konum ve Adres'));
      await tester.pumpAndSettle();

      // Project B never shows project A's stale location while loading or
      // after load — the row reflects only its own canonical state.
      expect(find.text('Konum seç'), findsOneWidget);
      expect(find.text('Değiştir'), findsNothing);
    },
  );
}

String? _visibleProjectName(WidgetTester tester) => tester
    .widget<Text>(
      find.byKey(const Key('project-information-project-name')).first,
    )
    .data;

Widget _testApp(
  _FakeProjectInformationSource source, {
  ProjectProfileApplication? profileApplication,
  ProjectInformationTextAction? copyText,
  ProjectInformationTextAction? shareText,
  ProjectInformationUriAction? launchUri,
  ProjectInformationMutationApplication? mutations,
  double textScale = 1,
}) => MaterialApp(
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.linear(textScale)),
    child: child!,
  ),
  home: ProjectInformationPage(
    application: ProjectInformationApplication(
      source: source,
      mutations: mutations,
    ),
    projectId: _projectA,
    profileApplication: profileApplication,
    copyText: copyText,
    shareText: shareText,
    launchUri: launchUri,
  ),
);

ProjectInformationEntry _userEntry(
  String id,
  String label, {
  required bool archived,
  ProjectInformationCategory category =
      ProjectInformationCategory.siteReference,
  ProjectInformationEntryValue value = const ProjectInformationEntryValue.text(
    'SR-42',
  ),
}) => ProjectInformationEntry(
  id: id,
  projectId: _projectA,
  category: category,
  label: label,
  value: value,
  revision: 1,
  createdAt: '2026-09-13T09:00:00.000Z',
  updatedAt: '2026-09-13T09:00:00.000Z',
  archivedAt: archived ? '2026-09-13T10:00:00.000Z' : null,
);

class _InformationMutations implements ProjectInformationMutationApplication {
  final List<ProjectInformationEntry> entries = [];
  final List<ProjectInformationPin> pins = [];
  final List<CreateProjectInformationEntryCommand> created = [];
  final List<UpdateProjectInformationEntryCommand> updated = [];
  final List<SetProjectInformationEntryArchiveCommand> archived = [];
  final List<SetProjectInformationPinCommand> pinned = [];
  final List<RemoveProjectInformationPinCommand> unpinned = [];
  bool failUpdates = false;

  @override
  Future<List<ProjectInformationEntry>> listUserEntries(
    String projectId, {
    ProjectInformationArchiveFilter archiveFilter =
        ProjectInformationArchiveFilter.active,
  }) async => entries
      .where((entry) {
        if (entry.projectId != projectId) return false;
        return switch (archiveFilter) {
          ProjectInformationArchiveFilter.active => !entry.isArchived,
          ProjectInformationArchiveFilter.archived => entry.isArchived,
          ProjectInformationArchiveFilter.all => true,
        };
      })
      .toList(growable: false);

  @override
  Future<ProjectInformationEntry> createUserEntry(
    CreateProjectInformationEntryCommand command,
  ) async {
    created.add(command);
    final entry = ProjectInformationEntry(
      id: command.id,
      projectId: command.projectId,
      category: command.category,
      label: command.label,
      value: command.value,
      unit: command.unit,
      note: command.note,
      revision: 1,
      createdAt: '2026-09-13T09:00:00.000Z',
      updatedAt: '2026-09-13T09:00:00.000Z',
    );
    entries.add(entry);
    return entry;
  }

  @override
  Future<ProjectInformationEntry> updateUserEntry(
    UpdateProjectInformationEntryCommand command,
  ) async {
    updated.add(command);
    if (failUpdates) throw const ProjectInformationRevisionConflict();
    final index = entries.indexWhere((entry) => entry.id == command.id);
    final current = entries[index];
    final replacement = ProjectInformationEntry(
      id: current.id,
      projectId: current.projectId,
      category: command.category,
      label: command.label,
      value: command.value,
      unit: command.unit,
      note: command.note,
      revision: current.revision + 1,
      createdAt: current.createdAt,
      updatedAt: '2026-09-13T10:00:00.000Z',
      archivedAt: current.archivedAt,
    );
    entries[index] = replacement;
    return replacement;
  }

  @override
  Future<ProjectInformationEntry> setUserEntryArchived(
    SetProjectInformationEntryArchiveCommand command,
  ) async {
    archived.add(command);
    final index = entries.indexWhere((entry) => entry.id == command.id);
    final current = entries[index];
    final replacement = ProjectInformationEntry(
      id: current.id,
      projectId: current.projectId,
      category: current.category,
      label: current.label,
      value: current.value,
      unit: current.unit,
      note: current.note,
      revision: current.revision + 1,
      createdAt: current.createdAt,
      updatedAt: '2026-09-13T10:00:00.000Z',
      archivedAt: command.archived ? '2026-09-13T10:00:00.000Z' : null,
    );
    entries[index] = replacement;
    return replacement;
  }

  @override
  Future<List<ProjectInformationPin>> listPins(String projectId) async =>
      pins.where((pin) => pin.projectId == projectId).toList(growable: false);

  /// Models the real `SqliteProjectInformationMutationApplication.setPin`
  /// identity contract: restoring a previously-removed pin for the same
  /// `(space, id)` key must reuse the exact same pin id, or it fails with
  /// `pin_identity_mismatch` — a fresh random id is rejected.
  final Map<String, String> _archivedPinIdsByKey = {};

  String _pinKeyString(ProjectInformationKey key) => '${key.space}:${key.id}';

  @override
  Future<ProjectInformationPin> setPin(
    SetProjectInformationPinCommand command,
  ) async {
    pinned.add(command);
    final activeMatch = pins.where(
      (existing) =>
          existing.key.space == command.key.space &&
          existing.key.id == command.key.id,
    );
    if (activeMatch.isNotEmpty) {
      if (activeMatch.single.id != command.id) {
        throw const ProjectInformationFailure('duplicate_active_pin');
      }
      return activeMatch.single;
    }
    final keyString = _pinKeyString(command.key);
    final archivedId = _archivedPinIdsByKey[keyString];
    if (archivedId != null && archivedId != command.id) {
      throw const ProjectInformationFailure('pin_identity_mismatch');
    }
    _archivedPinIdsByKey.remove(keyString);
    final pin = ProjectInformationPin(
      id: command.id,
      projectId: command.projectId,
      key: command.key,
      sortOrder: pins.length,
      revision: 1,
      createdAt: '2026-09-13T10:00:00.000Z',
      updatedAt: '2026-09-13T10:00:00.000Z',
      sourceAvailable: true,
    );
    pins.add(pin);
    return pin;
  }

  @override
  Future<void> removePin(RemoveProjectInformationPinCommand command) async {
    unpinned.add(command);
    final removed = pins.where((pin) => pin.id == command.id);
    if (removed.isNotEmpty) {
      _archivedPinIdsByKey[_pinKeyString(removed.single.key)] =
          removed.single.id;
    }
    pins.removeWhere((pin) => pin.id == command.id);
  }

  final List<ReorderProjectInformationPinsCommand> reordered = [];
  Object? reorderFailure;

  @override
  Future<List<ProjectInformationPin>> reorderPins(
    ReorderProjectInformationPinsCommand command,
  ) async {
    reordered.add(command);
    final failure = reorderFailure;
    if (failure != null) {
      reorderFailure = null;
      throw failure;
    }
    final byId = {for (final pin in pins) pin.id: pin};
    pins
      ..clear()
      ..addAll([
        for (final id in command.orderedPinIds)
          if (byId[id] != null)
            ProjectInformationPin(
              id: byId[id]!.id,
              projectId: byId[id]!.projectId,
              key: byId[id]!.key,
              sortOrder: command.orderedPinIds.indexOf(id),
              revision: byId[id]!.revision + 1,
              createdAt: byId[id]!.createdAt,
              updatedAt: '2026-09-14T10:00:00.000Z',
              sourceAvailable: byId[id]!.sourceAvailable,
            ),
      ]);
    return List.unmodifiable(pins);
  }

  ProjectSiteLocation? siteLocation;

  @override
  Future<ProjectSiteLocation?> getSiteLocation(String projectId) async =>
      siteLocation?.projectId == projectId ? siteLocation : null;

  @override
  Future<ProjectInformationCompanionReads> listCompanionReads(
    String projectId, {
    ProjectInformationArchiveFilter archiveFilter =
        ProjectInformationArchiveFilter.active,
  }) async => ProjectInformationCompanionReads(
    userEntries: await listUserEntries(projectId, archiveFilter: archiveFilter),
    pins: await listPins(projectId),
    siteLocation: await getSiteLocation(projectId),
  );

  @override
  Future<ProjectSiteLocation> setSiteLocation(
    SetProjectSiteLocationCommand command,
  ) async {
    final current = siteLocation?.projectId == command.projectId
        ? siteLocation
        : null;
    if (current?.revision != command.expectedRevision) {
      throw const ProjectInformationRevisionConflict();
    }
    final saved = ProjectSiteLocation(
      projectId: command.projectId,
      latitude: command.latitude,
      longitude: command.longitude,
      revision: (current?.revision ?? 0) + 1,
      createdAt: current?.createdAt ?? '2026-09-13T10:00:00.000Z',
      updatedAt: '2026-09-13T10:00:00.000Z',
    );
    siteLocation = saved;
    return saved;
  }

  @override
  Future<void> clearSiteLocation(
    ClearProjectSiteLocationCommand command,
  ) async {
    final current = siteLocation;
    if (current == null ||
        current.projectId != command.projectId ||
        current.revision != command.expectedRevision) {
      throw const ProjectInformationRevisionConflict();
    }
    siteLocation = null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _RestoreProfileApplication implements ProjectProfileApplication {
  _RestoreProfileApplication(this.source);

  final _FakeProjectInformationSource source;
  final List<MutateProjectProfileFieldArchiveCommand> commands = [];

  @override
  Future<ProjectProfileField> mutateProjectProfileFieldArchive(
    MutateProjectProfileFieldArchiveCommand command,
  ) async {
    commands.add(command);
    final restored = _profileField(
      command.fieldId,
      label: 'Eski not',
      value: 'Korunan değer',
      sortOrder: 7,
      revision: command.expectedRevision + 1,
    );
    source.profileEventsByProject[command.projectId] = [];
    source.profileByProject[command.projectId] = ProjectProfile(
      project: source.projects[command.projectId]!,
      fields: [
        ..._emptyProfile(source.projects[command.projectId]!).fields,
        restored,
      ],
    );
    return restored;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeProjectInformationSource implements ProjectInformationReadSource {
  _FakeProjectInformationSource.standard({bool includeProjectB = false}) {
    _seedProject(_projectA);
    if (includeProjectB) _seedProject(_projectB);
  }

  final Map<String, MobileProject> projects = {};
  final Map<String, List<Future<MobileProject>>> projectReads = {};
  final Map<String, ProjectMetadata> metadataByProject = {};
  final Map<String, ProjectProfile> profileByProject = {};
  final Map<String, List<ProjectProfileEvent>> profileEventsByProject = {};
  final Map<String, List<ProjectPartyAssignment>> partiesByProject = {};
  final Map<String, List<Subcontractor>> companiesByProject = {};
  final Map<String, List<WorkforceMember>> membersByProject = {};
  final Map<String, InventoryPrimarySketchProjection?> inventoryByProject = {};
  final Map<String, InventoryBlockMetadataRecord> blockMetadataById = {};
  final Map<String, List<MobileProjectLocation>> locationsByProject = {};
  final Map<String, List<ProjectFloorLocationRelation>>
  floorLocationsByProject = {};
  Object? projectFailure;
  Object? metadataFailure;
  Object? partyFailure;
  Object? inventoryFailure;
  Object? floorLocationFailure;
  int mutationCalls = 0;

  void _seedProject(String projectId) {
    final project = _project(projectId);
    projects[projectId] = project;
    metadataByProject[projectId] = _metadata(projectId);
    profileByProject[projectId] = _emptyProfile(project);
    partiesByProject[projectId] = [];
    companiesByProject[projectId] = [];
    membersByProject[projectId] = [];
    inventoryByProject[projectId] = null;
    locationsByProject[projectId] = [];
    floorLocationsByProject[projectId] = [];
  }

  @override
  Future<MobileProject> getProject(String projectId) async {
    if (projectFailure != null) throw projectFailure!;
    final queued = projectReads[projectId];
    if (queued != null && queued.isNotEmpty) return queued.removeAt(0);
    return projects[projectId] ?? (throw StateError('missing project'));
  }

  @override
  Future<ProjectMetadata> getProjectMetadata(String projectId) async {
    if (metadataFailure != null) throw metadataFailure!;
    return metadataByProject[projectId] ?? _metadata(projectId);
  }

  @override
  Future<ProjectProfile> getProjectProfile(String projectId) async =>
      profileByProject[projectId] ?? _emptyProfile(projects[projectId]!);

  @override
  Future<List<ProjectProfileEvent>> listProjectProfileEvents(
    String projectId,
  ) async => profileEventsByProject[projectId] ?? const [];

  @override
  Future<List<ProjectPartyAssignment>> listProjectPartyAssignments(
    String projectId,
  ) async {
    if (partyFailure != null) throw partyFailure!;
    return partiesByProject[projectId] ?? const [];
  }

  @override
  Future<List<Subcontractor>> listCompanies(String projectId) async =>
      companiesByProject[projectId] ?? const [];

  @override
  Future<List<WorkforceMember>> listWorkforceMembers(String projectId) async =>
      membersByProject[projectId] ?? const [];

  @override
  Future<InventoryPrimarySketchProjection?> loadInventory(
    String projectId,
  ) async {
    if (inventoryFailure != null) throw inventoryFailure!;
    return inventoryByProject[projectId];
  }

  @override
  Future<InventoryBlockMetadataRecord> loadBlockMetadata({
    required String projectId,
    required String blockId,
  }) async => blockMetadataById[blockId] ?? _blockMetadata(blockId);

  @override
  Future<List<MobileProjectLocation>> listLocations(String projectId) async =>
      locationsByProject[projectId] ?? const [];

  @override
  Future<List<ProjectFloorLocationRelation>> listFloorLocations(
    String projectId,
  ) async {
    if (floorLocationFailure != null) throw floorLocationFailure!;
    return floorLocationsByProject[projectId] ?? const [];
  }
}

MobileProject _project(String id) => MobileProject(
  id: id,
  name: id == _projectA ? 'A Projesi' : 'B Projesi',
  createdAt: '2026-09-13T09:00:00.000Z',
  updatedAt: '2026-09-13T09:00:00.000Z',
  revision: 1,
);

ProjectMetadata _metadata(String projectId, {String? address}) =>
    ProjectMetadata(
      projectId: projectId,
      revision: 1,
      createdAt: '2026-09-13T09:00:00.000Z',
      updatedAt: '2026-09-13T09:00:00.000Z',
      address: address,
    );

ProjectProfile _emptyProfile(MobileProject project) => ProjectProfile(
  project: project,
  fields: ProjectProfileBuiltinField.values
      .map(
        (builtin) => ProjectProfileField(
          id: 'profile-${project.id}-${builtin.storageValue}',
          projectId: project.id,
          label: builtin.label,
          value: '',
          sortOrder: builtin.index,
          revision: 0,
          createdAt: project.createdAt,
          updatedAt: project.updatedAt,
          builtinField: builtin,
        ),
      )
      .toList(growable: false),
);

ProjectProfileField _profileField(
  String id, {
  required String label,
  required String value,
  required int sortOrder,
  int revision = 1,
}) => ProjectProfileField(
  id: id,
  projectId: _projectA,
  label: label,
  value: value,
  sortOrder: sortOrder,
  revision: revision,
  createdAt: '2026-09-13T09:00:00.000Z',
  updatedAt: '2026-09-13T09:00:00.000Z',
  archivedAt: null,
);

ProjectProfileEvent _profileEvent({
  required String id,
  required String fieldId,
  required int sequence,
  required ProjectProfileEventType type,
  required Map<String, Object?> payload,
}) => ProjectProfileEvent(
  id: id,
  projectId: _projectA,
  fieldId: fieldId,
  sequence: sequence,
  eventType: type,
  occurredAt: '2026-09-13T09:0$sequence:00.000Z',
  payloadJson: jsonEncode(payload),
);

ProjectPartyAssignment _party(String id, {required String subcontractorId}) =>
    ProjectPartyAssignment(
      id: id,
      projectId: _projectA,
      role: ProjectPartyRole.employer,
      subcontractorId: subcontractorId,
      workforceMemberId: null,
      revision: 1,
      createdAt: '2026-09-13T09:00:00.000Z',
      updatedAt: '2026-09-13T09:00:00.000Z',
    );

Subcontractor _company(String id, {required bool active}) => Subcontractor(
  id: id,
  projectId: _projectA,
  name: 'İşveren Firma',
  contactName: 'Yetkili',
  phone: '555',
  note: null,
  status: active
      ? WorkforceRecordStatus.active
      : WorkforceRecordStatus.archived,
  activeTeamCount: 0,
  activePersonCount: 0,
  revision: 1,
  createdAt: '2026-09-13T09:00:00.000Z',
  updatedAt: '2026-09-13T09:00:00.000Z',
  archivedAt: active ? null : '2026-09-13T10:00:00.000Z',
);

InventoryPrimarySketchProjection _inventory({
  required List<InventoryBlockRecord> blocks,
  required List<InventoryFloorRecord> floors,
}) => InventoryPrimarySketchProjection(
  sketch: InventorySketchRecord(
    id: 'sketch-a',
    projectId: _projectA,
    displayName: 'Saha krokisi',
    isPrimary: true,
    activeRevisionId: null,
    draftRevisionId: null,
    revision: 1,
    createdAt: _now,
    updatedAt: _now,
    archivedAt: null,
  ),
  activeRevision: null,
  draftRevision: null,
  blocks: blocks,
  floors: floors,
);

InventoryBlockRecord _block(
  String id,
  String name, {
  InventoryBlockState state = InventoryBlockState.active,
}) => InventoryBlockRecord(
  id: id,
  projectId: _projectA,
  displayName: name,
  normalizedName: name.toLowerCase(),
  ordinal: 1,
  state: state,
  revision: 1,
  createdAt: _now,
  updatedAt: _now,
  archivedAt: state == InventoryBlockState.archived ? _now : null,
);

InventoryFloorRecord _floor(
  String id,
  String blockId,
  String name, {
  bool archived = false,
}) => InventoryFloorRecord(
  id: id,
  blockId: blockId,
  projectId: _projectA,
  displayName: name,
  ordinal: 1,
  revision: 1,
  createdAt: _now,
  updatedAt: _now,
  archivedAt: archived ? _now : null,
);

InventoryBlockMetadataRecord _blockMetadata(
  String blockId, {
  double? totalArea,
  String? totalAreaUnit,
  String? usageType,
}) => InventoryBlockMetadataRecord(
  blockId: blockId,
  projectId: _projectA,
  basementCount: null,
  basementClassification: null,
  totalArea: totalArea,
  totalAreaUnit: totalAreaUnit,
  footprintArea: null,
  footprintAreaUnit: null,
  independentUnitCount: null,
  usageType: usageType,
  revision: totalArea != null || usageType != null ? 1 : 0,
  createdAt: _now,
  updatedAt: _now,
);

MobileProjectLocation _location(
  String id,
  String name, {
  bool archived = false,
}) => MobileProjectLocation(
  id: id,
  projectId: _projectA,
  displayName: name,
  parentLocationId: null,
  revision: 1,
  createdAt: '2026-09-13T09:00:00.000Z',
  updatedAt: '2026-09-13T09:00:00.000Z',
  archivedAt: archived ? '2026-09-13T10:00:00.000Z' : null,
);

ProjectFloorLocationRelation _floorLocation(
  String id,
  String floorId,
  String locationId,
) => ProjectFloorLocationRelation(
  id: id,
  projectId: _projectA,
  floorId: floorId,
  locationId: locationId,
  revision: 1,
  createdAt: '2026-09-13T09:00:00.000Z',
  updatedAt: '2026-09-13T09:00:00.000Z',
  archivedAt: null,
);
