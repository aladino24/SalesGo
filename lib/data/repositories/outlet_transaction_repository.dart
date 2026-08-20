import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/sync/sync_manager.dart';

class OutletTransactionRepository {
  static const _boxName = 'outlet_transactions';

  Future<void> submit({
    required String type,
    required String endpoint,
    required String outletId,
    required Map<String, dynamic> payload,
  }) async {
    final box = Hive.isBoxOpen(_boxName)
        ? Hive.box(_boxName)
        : await Hive.openBox(_boxName);
    const uuid = Uuid();
    final id = uuid.v4();
    final record = {
      'id': id,
      'type': type,
      'outletId': outletId,
      'status': 'pending_sync',
      'createdAt': DateTime.now().toIso8601String(),
      ...payload,
    };
    await box.put(id, record);
    await Get.find<SyncManager>().queueItem(
      type: type,
      endpoint: endpoint,
      method: 'POST',
      payload: record,
      uuid: id,
      idempotencyKey: uuid.v4(),
    );
  }

  Future<List<Map<String, dynamic>>> history({required String outletId, String? type}) async {
    final box = Hive.isBoxOpen(_boxName) ? Hive.box(_boxName) : await Hive.openBox(_boxName);
    final records = box.values.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).where((item) => item['outletId'] == outletId && (type == null || item['type'] == type)).toList();
    records.sort((a, b) => (b['createdAt']?.toString() ?? '').compareTo(a['createdAt']?.toString() ?? ''));
    return records;
  }
}
