import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('concrete and agenda modal controllers are owned by dialog State', () {
    final concrete = _read(
      'lib/features/concrete/concrete_pour_detail_page.dart',
    );
    final agenda = _read('lib/features/agenda/agenda_page.dart');
    final logForm = _read('lib/features/agenda/log_form_page.dart');
    final ownedDialog = _read('lib/features/owned_text_input_dialog.dart');

    expect(concrete, contains('class _TruckDialog extends StatefulWidget'));
    expect(concrete, contains('class _TruckDialogState extends State'));
    expect(
      _method(
        concrete,
        'Future<void> _editTruck',
        'Future<void> _reopenTruckDraft',
      ),
      isNot(contains('TextEditingController')),
    );
    expect(
      _method(
        concrete,
        'Future<String?> _askText',
        'Future<void> _editTargetVolume',
      ),
      isNot(contains('TextEditingController')),
    );
    expect(
      _method(
        concrete,
        'Future<void> _editTargetVolume',
        'Future<void> _bulkComplete',
      ),
      isNot(contains('TextEditingController')),
    );
    expect(
      _method(agenda, 'Future<void> _createProject', 'Future<void> _reload'),
      contains('OwnedTextInputDialog'),
    );
    expect(
      _method(logForm, 'Future<void> _createProject', 'Future<void> _submit'),
      contains('OwnedTextInputDialog'),
    );
    expect(
      ownedDialog,
      contains('class OwnedTextInputDialog extends StatefulWidget'),
    );
    expect(ownedDialog, contains('_controller.dispose();'));
  });

  test('fatal diagnostic never claims an uncertain mutation wrote nothing', () {
    final app = _read('lib/app.dart');

    expect(app, contains('İşlem sonucu doğrulanamadı.'));
    expect(app, contains('ilgili kaydı kontrol edin'));
    expect(app, isNot(contains('Yeni kayıt yazılmadı.')));
  });
}

String _read(String path) =>
    File(path).readAsStringSync().replaceAll('\r\n', '\n');

String _method(String source, String startMarker, String endMarker) {
  final start = source.indexOf(startMarker);
  final end = source.indexOf(endMarker, start + startMarker.length);
  expect(start, isNonNegative, reason: 'Missing $startMarker');
  expect(end, greaterThan(start), reason: 'Missing $endMarker');
  return source.substring(start, end);
}
