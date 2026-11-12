import 'dart:async';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:cn_pocket_hr/database/app_database.dart';
import 'package:cn_pocket_hr/models/hr/check_in_check_out_model.dart';
import 'package:cn_pocket_hr/api/api_service.dart';

class OfflineAttendanceService {
  static final OfflineAttendanceService _instance = OfflineAttendanceService._internal();
  factory OfflineAttendanceService() => _instance;
  static OfflineAttendanceService get instance => _instance;

  OfflineAttendanceService._internal() {
    refreshPendingCount();
    _startPeriodicSync();
  }

  final AppDatabase _db = AppDatabase();
  final APIService _api = APIService();

  final ValueNotifier<int> pendingCountNotifier = ValueNotifier<int>(0);
  final ValueNotifier<bool> isSyncingNotifier = ValueNotifier<bool>(false);
  Timer? _periodicSyncTimer;
  bool _isSyncing = false;

  AppDatabase get database => _db;

  void _startPeriodicSync() {
    _periodicSyncTimer?.cancel();
    _periodicSyncTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      if (pendingCountNotifier.value > 0 && !_isSyncing) {
        await syncPending(ignoreMaxAttempts: true);
      }
    });
  }

  Future<int> refreshPendingCount() async {
    final count = await getPendingCount();
    if (pendingCountNotifier.value != count) {
      pendingCountNotifier.value = count;
    }
    return count;
  }

  Future<void> insertPunch(AttendancePunchModel punch) async {
    await _db.into(_db.punches).insertOnConflictUpdate(
          PunchesCompanion.insert(
            attendanceId: punch.attendanceId,
            uid: punch.uid,
            type: punch.type,
            time: punch.time,
            lat: punch.lat,
            lng: punch.lng,
            address: punch.address,
            deviceId: Value(punch.deviceId),
            deviceModel: Value(punch.deviceModel),
            deviceBrand: Value(punch.deviceBrand),
            devicePlatform: Value(punch.devicePlatform),
            deviceVersion: Value(punch.deviceVersion),
            deviceIdentifier: Value(punch.deviceIdentifier),
            deviceIp: Value(punch.deviceIp),
            batteryLevel: Value(punch.batteryLevel),
            tenant: Value(punch.tenant),
            isRemote: Value(punch.isRemote),
            isSynced: Value(punch.isSynced),
            retryCount: Value(punch.retryCount),
            lastSyncAttempt: Value(punch.lastSyncAttempt),
          ),
        );
    await refreshPendingCount();
  }

  Future<List<AttendancePunchModel>> getPendingPunches() async {
    // Order ascending by time and attendanceId to guarantee strict FIFO (First-In, First-Out)
    final query = _db.select(_db.punches)
      ..where((tbl) => tbl.isSynced.equals(0))
      ..orderBy([
        (tbl) => OrderingTerm.asc(tbl.time),
        (tbl) => OrderingTerm.asc(tbl.attendanceId),
      ]);
    final rows = await query.get();
    return rows.map((r) => AttendancePunchModel(
          attendanceId: r.attendanceId,
          uid: r.uid,
          type: r.type,
          time: r.time,
          lat: r.lat,
          lng: r.lng,
          address: r.address,
          deviceId: r.deviceId,
          deviceModel: r.deviceModel,
          deviceBrand: r.deviceBrand,
          devicePlatform: r.devicePlatform,
          deviceVersion: r.deviceVersion,
          deviceIdentifier: r.deviceIdentifier,
          deviceIp: r.deviceIp,
          batteryLevel: r.batteryLevel,
          tenant: r.tenant,
          isRemote: r.isRemote,
          isSynced: r.isSynced,
          retryCount: r.retryCount,
          lastSyncAttempt: r.lastSyncAttempt,
        )).toList();
  }

  Future<void> markSynced(String attendanceId) async {
    await (_db.update(_db.punches)..where((tbl) => tbl.attendanceId.equals(attendanceId)))
        .write(const PunchesCompanion(isSynced: Value(1)));
    await refreshPendingCount();
  }

  Future<void> incrementRetry(String attendanceId) async {
    final query = _db.select(_db.punches)..where((tbl) => tbl.attendanceId.equals(attendanceId));
    final row = await query.getSingleOrNull();
    if (row != null) {
      await (_db.update(_db.punches)..where((tbl) => tbl.attendanceId.equals(attendanceId)))
          .write(PunchesCompanion(retryCount: Value(row.retryCount + 1)));
    }
    await refreshPendingCount();
  }

  Future<void> deletePunch(String attendanceId) async {
    await (_db.delete(_db.punches)..where((tbl) => tbl.attendanceId.equals(attendanceId))).go();
    await refreshPendingCount();
  }

  Future<int> getPendingCount() async {
    try {
      final query = _db.select(_db.punches)..where((tbl) => tbl.isSynced.equals(0));
      final rows = await query.get();
      if (pendingCountNotifier.value != rows.length) {
        pendingCountNotifier.value = rows.length;
      }
      return rows.length;
    } catch (_) {}
    return 0;
  }

  /// Attempt to sync all pending punches. Returns a Map with 'success' and 'failed' counts.
  Future<Map<String, int>> syncPending({int maxAttempts = 10, bool ignoreMaxAttempts = false}) async {
    if (_isSyncing) {
      return {'success': 0, 'failed': 0};
    }
    _isSyncing = true;
    isSyncingNotifier.value = true;
    int success = 0;
    int failed = 0;
    try {
      final pending = await getPendingPunches();
      for (final p in pending) {
        if (!ignoreMaxAttempts && p.retryCount >= maxAttempts) {
          failed++;
          continue;
        }
        try {
          final res = await _api.checkInCheckout(
            p.time,
            p.type,
            latitude: p.lat.toString(),
            longitude: p.lng.toString(),
            address: p.address,
            isRemotePunch: p.isRemote == 1,
          );

          bool apiSuccess = false;
          bool isPermanentFailure = false;

          if (res is Map) {
            final statusCode = res['status'];
            if (statusCode is num) {
              final code = statusCode.toInt();
              if (code >= 200 && code < 300) {
                apiSuccess = true;
              } else if (code == 400 || code == 403 || code == 422) {
                isPermanentFailure = true;
              }
            } else if (res['success'] == true) {
              apiSuccess = true;
            }
          }

          if (apiSuccess) {
            await markSynced(p.attendanceId);
            success++;
          } else if (isPermanentFailure) {
            await markSynced(p.attendanceId);
            failed++;
          } else {
            await incrementRetry(p.attendanceId);
            failed++;
          }
        } catch (_) {
          await incrementRetry(p.attendanceId);
          failed++;
        }
      }
    } finally {
      _isSyncing = false;
      isSyncingNotifier.value = false;
      await refreshPendingCount();
    }
    return {'success': success, 'failed': failed};
  }

  Future<void> clearAllPunches() async {
    await _db.delete(_db.punches).go();
    await refreshPendingCount();
  }

  Future<void> clearSyncedPunches() async {
    await (_db.delete(_db.punches)..where((tbl) => tbl.isSynced.equals(1))).go();
    await refreshPendingCount();
  }
}
