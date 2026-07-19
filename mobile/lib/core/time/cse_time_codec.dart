import 'package:timezone/data/latest.dart' as timezone_data;
import 'package:timezone/timezone.dart' as timezone;

class TimeContractViolation implements Exception {
  const TimeContractViolation(this.message);

  final String message;

  @override
  String toString() => 'TimeContractViolation: $message';
}

class CanonicalDayBounds {
  const CanonicalDayBounds({required this.start, required this.endExclusive});

  final String start;
  final String endExclusive;
}

class CseTimeCodec {
  CseTimeCodec._();

  static const istanbulTimezoneName = 'Europe/Istanbul';
  static final RegExp _canonicalUtcPattern = RegExp(
    r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$',
  );
  static final RegExp _awareInputPattern = RegExp(
    r'^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})'
    r'(?:\.(\d{1,6}))?(Z|[+-]\d{2}:\d{2})$',
  );
  static final RegExp _istanbulLocalPattern = RegExp(
    r'^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2})(?::(\d{2}))?$',
  );
  static final RegExp _dayPattern = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');
  static bool _initialized = false;

  static void initialize() {
    if (_initialized) {
      return;
    }
    timezone_data.initializeTimeZones();
    _initialized = true;
  }

  static String encodeUtc(DateTime value) {
    if (!value.isUtc) {
      throw const TimeContractViolation('timestamp must be aware UTC');
    }
    final seconds = DateTime.utc(
      value.year,
      value.month,
      value.day,
      value.hour,
      value.minute,
      value.second,
    );
    return '${_four(seconds.year)}-${_two(seconds.month)}-${_two(seconds.day)}'
        'T${_two(seconds.hour)}:${_two(seconds.minute)}:${_two(seconds.second)}Z';
  }

  static DateTime decodeCanonicalUtc(String value) {
    if (!_canonicalUtcPattern.hasMatch(value)) {
      throw const TimeContractViolation(
        'timestamp must be canonical UTC seconds ending in Z',
      );
    }
    final parsed = DateTime.tryParse(value);
    if (parsed == null || !parsed.isUtc || encodeUtc(parsed) != value) {
      throw const TimeContractViolation(
        'timestamp must be canonical UTC seconds ending in Z',
      );
    }
    return parsed;
  }

  static String normalizeAware(String value) {
    final match = _awareInputPattern.firstMatch(value);
    if (value != value.trim() || match == null) {
      throw const TimeContractViolation(
        'timestamp must include an explicit timezone offset',
      );
    }
    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);
    final hour = int.parse(match.group(4)!);
    final minute = int.parse(match.group(5)!);
    final second = int.parse(match.group(6)!);
    final wallClock = DateTime.utc(year, month, day, hour, minute, second);
    if (wallClock.year != year ||
        wallClock.month != month ||
        wallClock.day != day ||
        wallClock.hour != hour ||
        wallClock.minute != minute ||
        wallClock.second != second) {
      throw const TimeContractViolation('timestamp contains an invalid date');
    }
    final offset = match.group(8)!;
    if (offset != 'Z') {
      final offsetHour = int.parse(offset.substring(1, 3));
      final offsetMinute = int.parse(offset.substring(4, 6));
      if (offsetHour > 23 || offsetMinute > 59) {
        throw const TimeContractViolation(
          'timestamp contains an invalid offset',
        );
      }
    }
    final parsed = DateTime.tryParse(value);
    if (parsed == null || !parsed.isUtc) {
      throw const TimeContractViolation(
        'timestamp must include an explicit timezone offset',
      );
    }
    return encodeUtc(parsed);
  }

  static DateTime toIstanbul(String canonicalUtc) {
    initialize();
    return timezone.TZDateTime.from(
      decodeCanonicalUtc(canonicalUtc),
      timezone.getLocation(istanbulTimezoneName),
    );
  }

  static String formatIstanbul(String canonicalUtc) {
    final local = toIstanbul(canonicalUtc);
    return '${_two(local.day)}.${_two(local.month)}.${_four(local.year)} '
        '${_two(local.hour)}:${_two(local.minute)}:${_two(local.second)}';
  }

  static String canonicalFromIstanbulLocal(String value) {
    initialize();
    final match = _istanbulLocalPattern.firstMatch(value);
    if (value != value.trim() || match == null) {
      throw const TimeContractViolation(
        'Istanbul local timestamp must be YYYY-MM-DDTHH:mm[:ss]',
      );
    }
    return canonicalFromIstanbulComponents(
      year: int.parse(match.group(1)!),
      month: int.parse(match.group(2)!),
      day: int.parse(match.group(3)!),
      hour: int.parse(match.group(4)!),
      minute: int.parse(match.group(5)!),
      second: int.parse(match.group(6) ?? '0'),
    );
  }

  static String canonicalFromIstanbulComponents({
    required int year,
    required int month,
    required int day,
    required int hour,
    required int minute,
    int second = 0,
  }) {
    initialize();
    _validateComponents(year, month, day, hour, minute, second);
    final local = timezone.TZDateTime(
      timezone.getLocation(istanbulTimezoneName),
      year,
      month,
      day,
      hour,
      minute,
      second,
    );
    if (local.year != year ||
        local.month != month ||
        local.day != day ||
        local.hour != hour ||
        local.minute != minute ||
        local.second != second) {
      throw const TimeContractViolation('Istanbul timestamp is invalid');
    }
    return encodeUtc(local.toUtc());
  }

  static CanonicalDayBounds istanbulDayBounds(String dayKey) {
    initialize();
    final components = _parseDay(dayKey);
    final location = timezone.getLocation(istanbulTimezoneName);
    final start = timezone.TZDateTime(
      location,
      components.$1,
      components.$2,
      components.$3,
    );
    final end = timezone.TZDateTime(
      location,
      components.$1,
      components.$2,
      components.$3 + 1,
    );
    return CanonicalDayBounds(
      start: encodeUtc(start.toUtc()),
      endExclusive: encodeUtc(end.toUtc()),
    );
  }

  static String istanbulDayKey(String canonicalUtc) {
    final local = toIstanbul(canonicalUtc);
    return '${_four(local.year)}-${_two(local.month)}-${_two(local.day)}';
  }

  static String istanbulTimeLabel(String canonicalUtc) {
    final local = toIstanbul(canonicalUtc);
    return '${_two(local.hour)}:${_two(local.minute)}';
  }

  static String shiftIstanbulDay(String dayKey, int dayDelta) {
    initialize();
    final components = _parseDay(dayKey);
    final shifted = timezone.TZDateTime(
      timezone.getLocation(istanbulTimezoneName),
      components.$1,
      components.$2,
      components.$3 + dayDelta,
    );
    return '${_four(shifted.year)}-${_two(shifted.month)}-'
        '${_two(shifted.day)}';
  }

  static (int, int, int) _parseDay(String value) {
    final match = _dayPattern.firstMatch(value);
    if (value != value.trim() || match == null) {
      throw const TimeContractViolation('day must be YYYY-MM-DD');
    }
    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);
    _validateComponents(year, month, day, 0, 0, 0);
    return (year, month, day);
  }

  static void _validateComponents(
    int year,
    int month,
    int day,
    int hour,
    int minute,
    int second,
  ) {
    final wallClock = DateTime.utc(year, month, day, hour, minute, second);
    if (wallClock.year != year ||
        wallClock.month != month ||
        wallClock.day != day ||
        wallClock.hour != hour ||
        wallClock.minute != minute ||
        wallClock.second != second) {
      throw const TimeContractViolation('timestamp contains an invalid date');
    }
  }

  static String _two(int value) => value.toString().padLeft(2, '0');
  static String _four(int value) => value.toString().padLeft(4, '0');
}
