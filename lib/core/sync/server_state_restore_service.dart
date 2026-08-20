import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../network/api_client.dart';
import '../network/api_endpoints.dart';
import '../network/network_info.dart';

/// Restores the last server-confirmed state after local storage is lost.
///
/// This deliberately never uploads or removes pending queue items. The server
/// snapshot only contains records the backend has already accepted.
class ServerStateRestoreService {
  ServerStateRestoreService({
    ApiClient? apiClient,
    NetworkInfo? networkInfo,
  })  : _apiClient = apiClient ?? Get.find<ApiClient>(),
        _networkInfo = networkInfo ?? Get.find<NetworkInfo>();

  final ApiClient _apiClient;
  final NetworkInfo _networkInfo;

  Future<ServerStateRestoreResult> restore() async {
    if (!await _networkInfo.isConnected) {
      throw StateError('Perangkat harus terhubung ke internet untuk memulihkan data.');
    }

    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.serverState,
    );
    final datasets = response['datasets'];
    if (datasets is! Map) {
      throw const FormatException('Respons state server tidak memiliki datasets.');
    }

    var restoredRecords = 0;
    for (final entry in _boxByDataset.entries) {
      final values = datasets[entry.key];
      if (values is! List) continue;
      restoredRecords += await _replaceBox(entry.value, values);
    }

    final dashboard = response['dashboard'];
    if (dashboard is Map) {
      final box = Hive.isBoxOpen('dashboard_cache')
          ? Hive.box('dashboard_cache')
          : await Hive.openBox('dashboard_cache');
      await box.put('current', Map<String, dynamic>.from(dashboard));
      restoredRecords++;
    }

    final generatedAt = response['generatedAt']?.toString();
    final appBox = Hive.isBoxOpen('app_box')
        ? Hive.box('app_box')
        : await Hive.openBox('app_box');
    await appBox.put('last_server_state_restore_at', DateTime.now().toIso8601String());
    await appBox.put('has_server_state_snapshot', true);
    if (generatedAt != null) {
      await appBox.put('last_server_state_generated_at', generatedAt);
    }

    return ServerStateRestoreResult(
      records: restoredRecords,
      generatedAt: generatedAt,
    );
  }

  static const _boxByDataset = <String, String>{
    'products': 'master_products',
    'outlets': 'master_outlets',
    'visits': 'visits',
    'salesOrders': 'sales_orders',
    'outletTransactions': 'outlet_transactions',
    'visitActions': 'visit_actions',
    'visitTimeline': 'visit_timeline',
    'journeys': 'journeys',
    'deliveryNotes': 'delivery_notes',
    'approvals': 'approvals',
    'promotions': 'promotions',
    'files': 'files',
  };

  Future<int> _replaceBox(String boxName, List<dynamic> values) async {
    final box = Hive.isBoxOpen(boxName) ? Hive.box(boxName) : await Hive.openBox(boxName);
    final records = <dynamic, Map<String, dynamic>>{};
    for (var index = 0; index < values.length; index++) {
      final raw = values[index];
      if (raw is! Map) continue;
      final record = Map<String, dynamic>.from(raw);
      records[record['id']?.toString() ?? '$boxName-$index'] = record;
    }
    await box.clear();
    await box.putAll(records);
    return records.length;
  }
}

class ServerStateRestoreResult {
  const ServerStateRestoreResult({required this.records, this.generatedAt});

  final int records;
  final String? generatedAt;
}
