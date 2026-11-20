import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

class Punches extends Table {
  TextColumn get attendanceId => text()();
  TextColumn get uid => text()();
  TextColumn get type => text()(); // checkin / checkout
  TextColumn get time => text()(); // ISO string
  RealColumn get lat => real()();
  RealColumn get lng => real()();
  TextColumn get address => text()();

  TextColumn get deviceId => text().withDefault(const Constant(''))();
  TextColumn get deviceModel => text().withDefault(const Constant(''))();
  TextColumn get deviceBrand => text().withDefault(const Constant(''))();
  TextColumn get devicePlatform => text().withDefault(const Constant(''))();
  TextColumn get deviceVersion => text().withDefault(const Constant(''))();
  TextColumn get deviceIdentifier => text().withDefault(const Constant(''))();
  TextColumn get deviceIp => text().withDefault(const Constant(''))();
  IntColumn get batteryLevel => integer().withDefault(const Constant(0))();

  TextColumn get tenant => text().withDefault(const Constant(''))();
  IntColumn get isRemote => integer().withDefault(const Constant(0))();
  IntColumn get isSynced => integer().withDefault(const Constant(0))();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get lastSyncAttempt => text().nullable()();

  @override
  Set<Column> get primaryKey => {attendanceId};
}

@DriftDatabase(tables: [Punches])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _ensureGeoMetaColumns();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await _ensureGeoMetaColumns();
          }
        },
      );

  Future<void> _ensureGeoMetaColumns() async {
    try {
      await customStatement(
          'ALTER TABLE punches ADD COLUMN location_accuracy REAL');
    } catch (_) {}
    try {
      await customStatement('ALTER TABLE punches ADD COLUMN distance REAL');
    } catch (_) {}
  }

  Future<void> updatePunchGeoMeta(
    String attendanceId, {
    double? locationAccuracy,
    double? distance,
  }) async {
    await _ensureGeoMetaColumns();
    await customUpdate(
      'UPDATE punches SET location_accuracy = ?, distance = ? WHERE attendance_id = ?',
      variables: [
        Variable<double>(locationAccuracy),
        Variable<double>(distance),
        Variable.withString(attendanceId),
      ],
      updates: {punches},
    );
  }

  Future<Map<String, Map<String, double?>>> getPendingGeoMeta() async {
    await _ensureGeoMetaColumns();
    final rows = await customSelect(
      'SELECT attendance_id, location_accuracy, distance FROM punches WHERE is_synced = 0',
      readsFrom: {punches},
    ).get();
    final result = <String, Map<String, double?>>{};
    for (final row in rows) {
      final id = row.read<String>('attendance_id');
      result[id] = {
        'location_accuracy': row.readNullable<double>('location_accuracy'),
        'distance': row.readNullable<double>('distance'),
      };
    }
    return result;
  }

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'pocket_hr_attendance_db');
  }
}
