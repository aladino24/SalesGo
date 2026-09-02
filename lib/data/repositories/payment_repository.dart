import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/network/network_info.dart';
import '../../core/sync/sync_manager.dart';

class PaymentRepository {
  PaymentRepository({ApiClient? apiClient, NetworkInfo? networkInfo})
      : _api = apiClient ?? Get.find<ApiClient>(),
        _network = networkInfo ?? Get.find<NetworkInfo>();

  final ApiClient _api;
  final NetworkInfo _network;

  Future<Box> _box(String name) => Hive.isBoxOpen(name) ? Future.value(Hive.box(name)) : Hive.openBox(name);

  Future<Map<String, dynamic>> summary(String outletId) async {
    final box = await _box('payment_receivables_cache');
    final cached = box.get(outletId);
    if (await _network.isConnected) {
      try {
        final response = await _api.get<Map<String, dynamic>>(ApiEndpoints.outletPaymentSummary(outletId));
        final safe = Map<String, dynamic>.from(response);
        await box.put(outletId, safe);
        return safe;
      } catch (_) {
        if (cached is Map) return Map<String, dynamic>.from(cached);
        rethrow;
      }
    }
    if (cached is Map) return Map<String, dynamic>.from(cached);
    return const {'summary': <String, dynamic>{}, 'invoices': <dynamic>[]};
  }

  Future<void> create(Map<String, dynamic> payment) async {
    final id = payment['id']?.toString() ?? const Uuid().v4();
    final record = Map<String, dynamic>.from(payment)..['id'] = id..['status'] = 'PENDING_SYNC'..['createdAt'] = DateTime.now().toIso8601String();
    await (await _box('payments_local')).put(id, record);
    await Get.find<SyncManager>().queueItem(
      type: 'payment_create',
      endpoint: ApiEndpoints.payments,
      method: 'POST',
      uuid: id,
      idempotencyKey: const Uuid().v4(),
      payload: record,
    );
  }

  Future<List<Map<String, dynamic>>> history({String? outletId}) async {
    final box = await _box('payments_local');
    final values = box.values.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).where((item) => outletId == null || item['outletId']?.toString() == outletId).toList();
    values.sort((a, b) => (b['createdAt']?.toString() ?? '').compareTo(a['createdAt']?.toString() ?? ''));
    return values;
  }
}
