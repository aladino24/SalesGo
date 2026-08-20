import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/sync/sync_manager.dart';

class VisitTimelineRepository {
  static const _boxName = 'visit_timeline';
  Future<void> record({required String outletId, required String activity, required String description, String? visitId, Map<String, dynamic>? location}) async {
    final box = Hive.isBoxOpen(_boxName) ? Hive.box(_boxName) : await Hive.openBox(_boxName);
    const uuid = Uuid(); final id = uuid.v4();
    final item = {'id': id, 'visitId': visitId, 'outletId': outletId, 'activity': activity, 'description': description, 'location': location, 'createdAt': DateTime.now().toUtc().toIso8601String(), 'status': 'pending_sync'};
    await box.put(id, item);
    await Get.find<SyncManager>().queueItem(type: 'visit_timeline_create', endpoint: ApiEndpoints.visitActivities, method: 'POST', payload: item, uuid: id, idempotencyKey: uuid.v4());
  }
  Future<List<Map<String, dynamic>>> byOutlet(String outletId) async {
    final box = Hive.isBoxOpen(_boxName) ? Hive.box(_boxName) : await Hive.openBox(_boxName);
    final items = box.values.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).where((item) => item['outletId'] == outletId).toList();
    items.sort((a, b) => (b['createdAt']?.toString() ?? '').compareTo(a['createdAt']?.toString() ?? ''));
    return items;
  }
}
