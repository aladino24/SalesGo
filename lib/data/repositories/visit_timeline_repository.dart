import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/network/api_client.dart';
import '../../core/network/network_info.dart';

class VisitTimelineRepository {
  VisitTimelineRepository({ApiClient? apiClient, NetworkInfo? networkInfo})
      : _api = apiClient ?? Get.find<ApiClient>(),
        _network = networkInfo ?? Get.find<NetworkInfo>();

  static const _boxName = 'visit_timeline';
  final ApiClient _api;
  final NetworkInfo _network;

  Future<void> record({required String outletId, required String activity, required String description, String? visitId, Map<String, dynamic>? location}) async {
    final box = await _box;
    const uuid = Uuid();
    final id = uuid.v4();
    // The server appends its own immutable activity when check-in/out/defer/cancel succeeds.
    // This local record is only a pending/offline display entry, never posted as a duplicate event.
    await box.put(id, {'id': id, 'visitId': visitId, 'outletId': outletId, 'activity': activity, 'description': description, 'location': location, 'createdAt': DateTime.now().toUtc().toIso8601String(), 'status': 'pending_sync'});
  }

  Future<List<Map<String, dynamic>>> byOutlet(String outletId) async {
    final box = await _box;
    final local = box.values.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).where((item) => item['outletId'].toString() == outletId).toList();
    if (await _network.isConnected) {
      try {
        final response = await _api.get<dynamic>('/outlets/$outletId/visit-activities');
        final remote = (response is List ? response : response is Map ? response['data'] : null);
        final entries = (remote is List ? remote : <dynamic>[]).whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList();
        for (final item in entries) { await box.put(item['id'].toString(), item); }
        return _sorted([...entries, ...local.where((item) => !entries.any((remoteItem) => remoteItem['id'].toString() == item['id'].toString()))]);
      } catch (_) {}
    }
    return _sorted(local);
  }

  Future<Box> get _box async => Hive.isBoxOpen(_boxName) ? Hive.box(_boxName) : Hive.openBox(_boxName);
  List<Map<String, dynamic>> _sorted(List<Map<String, dynamic>> items) => items..sort((a, b) => (b['createdAt']?.toString() ?? b['occurredAt']?.toString() ?? '').compareTo(a['createdAt']?.toString() ?? a['occurredAt']?.toString() ?? ''));
}
