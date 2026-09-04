import 'package:chief_site_engineer/app.dart';
import 'package:chief_site_engineer/bootstrap/app_bootstrap.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'shared buttons render at least 48 dp at normal and large text scales',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final semantics = tester.ensureSemantics();

      await tester.pumpWidget(
        CseApp(bootstrap: Future<BootstrapResult>.value(BootstrapFailure())),
      );
      await tester.pumpAndSettle();
      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      final themes = <ThemeData>[app.theme!, app.darkTheme!];

      for (final theme in themes) {
        for (final textScale in <double>[1, 1.6]) {
          await tester.pumpWidget(
            MaterialApp(
              theme: theme,
              home: MediaQuery(
                data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
                child: Scaffold(
                  body: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FilledButton(
                        key: const Key('accessible-filled-button'),
                        onPressed: () {},
                        child: const Text('Kaydet'),
                      ),
                      TextButton(
                        key: const Key('accessible-text-button'),
                        onPressed: () {},
                        child: const Text('Tamam'),
                      ),
                      IconButton(
                        key: const Key('accessible-icon-button'),
                        tooltip: 'Yenile',
                        onPressed: () {},
                        icon: const Icon(Icons.refresh),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          for (final key in <String>[
            'accessible-filled-button',
            'accessible-text-button',
            'accessible-icon-button',
          ]) {
            final finder = find.byKey(Key(key));
            final renderedSize = tester.getSize(finder);
            expect(renderedSize.width, greaterThanOrEqualTo(48));
            expect(renderedSize.height, greaterThanOrEqualTo(48));

            final semanticsRect = tester.getSemantics(finder).rect;
            expect(semanticsRect.width, renderedSize.width);
            expect(semanticsRect.height, renderedSize.height);
          }

          expect(tester.takeException(), isNull);
        }
      }

      semantics.dispose();
    },
  );
}
