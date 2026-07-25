import 'package:chief_site_engineer/core/time/cse_time_codec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(CseTimeCodec.initialize);

  test('matches Python UTC and Europe Istanbul contract fixtures', () {
    const canonical = '2026-07-12T18:30:00Z';

    expect(CseTimeCodec.normalizeAware('2026-07-12T21:30:00+03:00'), canonical);
    expect(CseTimeCodec.formatIstanbul(canonical), '12.07.2026 21:30:00');
    expect(
      CseTimeCodec.formatIstanbul('2026-01-13T12:30:00Z'),
      '13.01.2026 15:30:00',
    );
  });

  test('serializes deterministic seconds and rejects a local DateTime', () {
    expect(
      CseTimeCodec.encodeUtc(DateTime.utc(2026, 7, 19, 8, 9, 10, 999, 999)),
      '2026-07-19T08:09:10Z',
    );
    expect(
      () => CseTimeCodec.encodeUtc(DateTime(2026, 7, 19, 11, 9, 10)),
      throwsA(isA<TimeContractViolation>()),
    );
  });

  test(
    'canonical reads reject naive, offset, invalid and fractional values',
    () {
      for (final value in [
        '2026-07-12T18:30:00',
        '2026-07-12T21:30:00+03:00',
        '2026-07-12T18:30:00.000001Z',
        '2026-02-30T18:30:00Z',
        'not-a-timestamp',
      ]) {
        expect(
          () => CseTimeCodec.decodeCanonicalUtc(value),
          throwsA(isA<TimeContractViolation>()),
          reason: value,
        );
      }
    },
  );

  test('normalization rejects inputs without an explicit timezone', () {
    for (final value in [
      '2026-07-12T21:30:00',
      ' 2026-07-12T21:30:00+03:00',
      '2026-07-12 21:30:00+03:00',
      '2026-02-30T21:30:00+03:00',
      '2026-07-12T21:30:00+24:00',
    ]) {
      expect(
        () => CseTimeCodec.normalizeAware(value),
        throwsA(isA<TimeContractViolation>()),
      );
    }
  });

  test('strict Istanbul local input maps to canonical UTC seconds', () {
    expect(
      CseTimeCodec.canonicalFromIstanbulLocal('2026-07-19T00:00'),
      '2026-07-18T21:00:00Z',
    );
    expect(
      CseTimeCodec.canonicalFromIstanbulLocal('2026-07-19T23:59:58'),
      '2026-07-19T20:59:58Z',
    );
    for (final value in [
      '2026-02-30T10:00',
      '2026-07-19 10:00',
      '2026-07-19T24:00',
      '2026-07-19T10:00+03:00',
      ' 2026-07-19T10:00',
    ]) {
      expect(
        () => CseTimeCodec.canonicalFromIstanbulLocal(value),
        throwsA(isA<TimeContractViolation>()),
        reason: value,
      );
    }
  });

  test('Istanbul day bounds are inclusive start and exclusive next start', () {
    final bounds = CseTimeCodec.istanbulDayBounds('2026-07-19');

    expect(bounds.start, '2026-07-18T21:00:00Z');
    expect(bounds.endExclusive, '2026-07-19T21:00:00Z');
    expect(CseTimeCodec.shiftIstanbulDay('2026-07-19', -1), '2026-07-18');
    expect(CseTimeCodec.shiftIstanbulDay('2026-07-19', 1), '2026-07-20');
  });

  test('all-day codec validates and formats calendar boundaries', () {
    expect(CseTimeCodec.validateIstanbulDay('2026-12-31'), '2026-12-31');
    expect(CseTimeCodec.formatIstanbulDay('2027-01-01'), '01.01.2027');
    expect(CseTimeCodec.shiftIstanbulDay('2026-12-31', 1), '2027-01-01');
    expect(CseTimeCodec.shiftIstanbulDay('2028-02-28', 1), '2028-02-29');
    for (final value in [
      '2026-2-03',
      '2026-02-30',
      '2026-13-01',
      ' 2026-07-19',
    ]) {
      expect(
        () => CseTimeCodec.validateIstanbulDay(value),
        throwsA(isA<TimeContractViolation>()),
        reason: value,
      );
    }
  });
}
