import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/features/agenda/agenda_concrete_signal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  bool detects(
    String description, {
    String? notes,
    AgendaCategory category = AgendaCategory.generalNote,
  }) {
    return AgendaConcreteSignalDetector.hasSignal(
      description: description,
      notes: notes,
      category: category,
    );
  }

  test(
    'detects bounded concrete keywords after deterministic normalization',
    () {
      for (final text in [
        'beton',
        'BETONAJ',
        'Beton dökümü',
        'Yarın beton dökülecek.',
        'Beton döküldü!',
      ]) {
        expect(detects(text), isTrue, reason: text);
      }
      expect(
        AgendaConcreteSignalDetector.normalize('  İMALAT: BETON\nDÖKÜMÜ  '),
        'imalat beton dökümü',
      );
    },
  );

  test('does not infer from look-alike technical words', () {
    expect(detects('Betonarme proje kontrolü'), isFalse);
    expect(detects('Betoniyer bakımı'), isFalse);
    expect(detects('Betonarme ve betoniyer kontrolü'), isFalse);
  });

  test('uses detailed notes and explicit concrete category as signals', () {
    expect(
      detects('Günlük saha kaydı', notes: 'Akşam betonaj yapılacak.'),
      isTrue,
    );
    expect(
      detects(
        'Anahtar kelime içermeyen kayıt',
        category: AgendaCategory.concrete,
      ),
      isTrue,
    );
    expect(detects('Anahtar kelime içermeyen kayıt'), isFalse);
  });
}
