import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/sync/sync_manager.dart';
import '../../core/location/location_service.dart';
import 'visit_timeline_repository.dart';

class VisitActionRepository {
  static const _boxName = 'visit_actions';
  Future<void> submit({required String type, required String endpoint, required String outletId, required String reason, String? followUpAt}) async {
    final box = Hive.isBoxOpen(_boxName) ? Hive.box(_boxName) : await Hive.openBox(_boxName);
    const uuid = Uuid();
    final id = uuid.v4();
    LocationSnapshot? location;
    try { location = await LocationService().currentLocation(); } catch (_) {}
    final record = {'id': id, 'outletId': outletId, 'type': type, 'reason': reason, 'followUpAt': followUpAt, 'location': location?.toJson(), 'status': 'pending_sync', 'createdAt': DateTime.now().toIso8601String()};
    await box.put(id, record);
    await Get.find<SyncManager>().queueItem(type: 'visit_$type', endpoint: endpoint, method: 'POST', payload: record, uuid: id, idempotencyKey: uuid.v4());
    await VisitTimelineRepository().record(outletId: outletId, activity: type, description: reason, location: location?.toJson());
  }
}
