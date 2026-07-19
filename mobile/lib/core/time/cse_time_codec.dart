import 'package:timezone/data/latest.dart' as timezone_data;
import 'package:timezone/timezone.dart' as timezone;

class TimeContractViolation implements Exception {
  const TimeContractViolation(this.message);

  final String message;

  @override
  String toString() => 'TimeContractViolation: $message';
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

  static String _two(int value) => value.toString().padLeft(2, '0');
  static String _four(int value) => value.toString().padLeft(4, '0');
}
