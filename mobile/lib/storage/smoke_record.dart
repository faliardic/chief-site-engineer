import 'package:chief_site_engineer/core/time/cse_time_codec.dart';
import 'package:chief_site_engineer/storage/app_database.dart';

class SmokeRecord {
  const SmokeRecord({
    required this.id,
    required this.value,
    required this.createdAt,
  });

  final String id;
  final String value;
  final String createdAt;
}

class SmokeRecordRepository {
  SmokeRecordRepository({required this.database, required this.clock});

  static const foundationRecordId = 'mobile-foundation-v1';
  static const foundationRecordValue = 'ready';

  final AppDatabase database;
  final UtcClock clock;

  Future<SmokeRecord> ensureFoundationRecord() async {
    return database.database.transaction((transaction) async {
      final rows = await transaction.query(
        'smoke_records',
        where: 'id = ?',
        whereArgs: [foundationRecordId],
        limit: 1,
      );
      if (rows.isNotEmpty) {
        return _fromRow(rows.single);
      }
      final record = SmokeRecord(
        id: foundationRecordId,
        value: foundationRecordValue,
        createdAt: CseTimeCodec.encodeUtc(clock()),
      );
      await transaction.insert('smoke_records', {
        'id': record.id,
        'value': record.value,
        'created_at': record.createdAt,
      });
      return record;
    });
  }

  SmokeRecord _fromRow(Map<String, Object?> row) {
    final createdAt = row['created_at']! as String;
    CseTimeCodec.decodeCanonicalUtc(createdAt);
    return SmokeRecord(
      id: row['id']! as String,
      value: row['value']! as String,
      createdAt: createdAt,
    );
  }
}
