import 'package:chief_site_engineer/app.dart';
import 'package:chief_site_engineer/bootstrap/app_bootstrap.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_agenda_application.dart';

void main() {
  testWidgets('mobile shell exposes all release 0.1 navigation entries', (
    tester,
  ) async {
    await tester.pumpWidget(
      CseApp(
        bootstrap: Future<BootstrapResult>.value(
          BootstrapSuccess(
            environmentLabel: 'Geliştirme',
            smokeRecordId: 'mobile-foundation-v1',
            smokeRecordCreatedAt: '2026-07-19T08:00:00Z',
            agenda: FakeAgendaApplication(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Saha hafızanız cihazınızda.'), findsOneWidget);
    for (final label in [
      'Başlangıç',
      'Hatırlatıcı',
      'Ajanda',
      'Puantaj',
      'Beton Paketi',
    ]) {
      expect(find.text(label), findsWidgets);
    }

    await tester.tap(find.text('Ajanda').last);
    await tester.pumpAndSettle();
    expect(find.text('Bu günde Ajanda kaydı yok.'), findsOneWidget);
    expect(find.byKey(const Key('create-agenda-log')), findsOneWidget);
  });

  testWidgets('database bootstrap failure is fail closed and user safe', (
    tester,
  ) async {
    await tester.pumpWidget(
      CseApp(bootstrap: Future<BootstrapResult>.value(BootstrapFailure())),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Yerel veri deposu güvenli biçimde açılamadı.'),
      findsOneWidget,
    );
    expect(find.textContaining('Hiçbir kayıt yazılmadı.'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });
}
