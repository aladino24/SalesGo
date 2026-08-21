import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/network/api_client.dart';
import '../../core/network/network_info.dart';
import '../../core/sync/sync_manager.dart';

class OutletTransactionRepository {
  OutletTransactionRepository({ApiClient? apiClient, NetworkInfo? networkInfo, SyncManager? syncManager})
      : _api = apiClient ?? Get.find<ApiClient>(),
        _network = networkInfo ?? Get.find<NetworkInfo>(),
        _sync = syncManager ?? Get.find<SyncManager>();

  static const _boxName = 'outlet_transactions';
  final ApiClient _api;
  final NetworkInfo _network;
  final SyncManager _sync;

  Future<void> submit({required String type, required String endpoint, required String outletId, required Map<String, dynamic> payload}) async {
    final box = await _box;
    const uuid = Uuid();
    final id = uuid.v4();
    final record = {'id': id, 'type': type, 'outletId': outletId, 'status': 'pending_sync', 'createdAt': DateTime.now().toIso8601String(), ...payload};
    await box.put(id, record);
    if (await _network.isConnected) {
      try {
        final response = await _api.post<dynamic>(endpoint, data: record, idempotencyKey: uuid.v4());
        if (response is Map) await box.put(id, {...Map<String, dynamic>.from(response), 'syncedAt': DateTime.now().toIso8601String()});
        return;
      } catch (_) {}
    }
    await _sync.queueItem(type: type, endpoint: endpoint, method: 'POST', payload: record, uuid: id, idempotencyKey: uuid.v4());
  }

  Future<List<Map<String, dynamic>>> history({required String outletId, String? type}) async {
    final box = await _box;
    final local = box.values.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).where((item) => item['outletId'].toString() == outletId && (type == null || item['type'] == type)).toList();
    if (await _network.isConnected) {
      try {
        final response = await _api.get<dynamic>('/outlets/$outletId/transactions');
        final data = response is Map ? response['data'] : null;
        final remote = (data is List ? data : <dynamic>[]).whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList();
        for (final item in remote) { await box.put(item['id'].toString(), item); }
        final remoteIds = remote.map((item) => item['id'].toString()).toSet();
        return _sorted([...remote, ...local.where((item) => !remoteIds.contains(item['id'].toString()))].where((item) => type == null || item['type'] == type).toList());
      } catch (_) {}
    }
    return _sorted(local);
  }

  Future<Box> get _box async => Hive.isBoxOpen(_boxName) ? Hive.box(_boxName) : Hive.openBox(_boxName);
  List<Map<String, dynamic>> _sorted(List<Map<String, dynamic>> items) => items..sort((a, b) => (b['createdAt']?.toString() ?? '').compareTo(a['createdAt']?.toString() ?? ''));
}
