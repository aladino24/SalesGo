import 'package:hive_flutter/hive_flutter.dart';

import '../../data/models/sync_item_model.dart';

class SyncStorage {
  static const _boxName = 'sync_queue_box';
  static const _lastSyncKey = 'last_sync';
  static const _auditBoxName = 'sync_audit_log';

  static Future<void> init() async {
    await Hive.openBox(_boxName);
    await Hive.openBox(_auditBoxName);
  }

  static Box get box => Hive.box(_boxName);

  /// Add a new sync item to the queue
  static Future<void> addItem(SyncItem item) async {
    await box.put(item.id, item.toJson());
  }

  /// Get all pending items (status = pending or failed)
  static List<SyncItem> pendingItems({bool force = false}) {
    final items = <SyncItem>[];
    for (final key in box.keys) {
      if (key == _lastSyncKey) continue;

      final data = box.get(key) as Map?;
      if (data != null) {
        final item = SyncItem.fromJson(Map<String, dynamic>.from(data));
        final canRetry = force || item.nextAttemptAt == null || !item.nextAttemptAt!.isAfter(DateTime.now());
        if ((item.status == 'pending' || item.status == 'failed') && canRetry) {
          items.add(item);
        }
      }
    }
    items.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return items;
  }

  /// Get a specific sync item by ID
  static SyncItem? getItem(String id) {
    final data = box.get(id) as Map?;
    if (data != null) {
      return SyncItem.fromJson(Map<String, dynamic>.from(data));
    }
    return null;
  }

  /// Update sync item status
  static Future<void> updateItemStatus(String id, String status, {String? error, DateTime? nextAttemptAt, Map<String, dynamic>? conflict, bool incrementAttempt = false}) async {
    final item = getItem(id);
    if (item != null) {
      final updated = item.copyWith(
        status: status,
        lastAttemptAt: DateTime.now(),
        attemptCount: item.attemptCount + (incrementAttempt ? 1 : 0),
        error: error,
        nextAttemptAt: nextAttemptAt,
        conflict: conflict,
      );
      await box.put(id, updated.toJson());
    }
  }

  static Future<void> updateItemPayload(String id, Map<String, dynamic> payload) async {
    final item = getItem(id);
    if (item != null) await box.put(id, item.copyWith(payload: payload).toJson());
  }

  static Future<void> addAudit({required SyncItem item, required String event, String? message, Map<String, dynamic>? details}) async {
    final audit = Hive.box(_auditBoxName);
    final id = '${DateTime.now().microsecondsSinceEpoch}-${item.id}';
    await audit.put(id, {'id': id, 'syncItemId': item.id, 'uuid': item.uuid, 'type': item.type, 'event': event, 'message': message, 'details': details, 'createdAt': DateTime.now().toUtc().toIso8601String()});
  }

  /// Mark sync item as synced and remove from queue
  static Future<void> removeItem(String id) async {
    await box.delete(id);
  }

  /// Get last sync time
  static DateTime? get lastSync {
    final value = box.get(_lastSyncKey);
    if (value != null) {
      return DateTime.parse(value as String);
    }
    return null;
  }

  /// Update last sync time
  static Future<void> updateLastSync() async {
    await box.put(_lastSyncKey, DateTime.now().toIso8601String());
  }

  /// Clear all sync items (use with caution)
  static Future<void> clearAll() async {
    await box.clear();
  }

  /// Get sync stats
  static Map<String, int> getSyncStats() {
    int pending = 0, syncing = 0, success = 0, failed = 0, conflict = 0, blocked = 0;

    for (final key in box.keys) {
      if (key == _lastSyncKey) continue;

      final data = box.get(key) as Map?;
      if (data != null) {
        final status = data['status'] as String?;
        switch (status) {
          case 'pending':
            pending++;
          case 'syncing':
            syncing++;
          case 'success':
            success++;
          case 'failed':
            failed++;
          case 'conflict':
            conflict++;
          case 'blocked':
            blocked++;
        }
      }
    }

    return {
      'pending': pending,
      'syncing': syncing,
      'success': success,
      'failed': failed,
      'conflict': conflict,
      'blocked': blocked,
    };
  }
}
