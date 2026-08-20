import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/network/network_info.dart';
import '../models/outlet_performance_model.dart';

class OutletDetailRepository {
  OutletDetailRepository({ApiClient? apiClient, NetworkInfo? networkInfo})
      : _api = apiClient ?? Get.find<ApiClient>(),
        _network = networkInfo ?? Get.find<NetworkInfo>();
  final ApiClient _api;
  final NetworkInfo _network;

  Future<OutletPerformanceModel> getPerformance(String outletId) async {
    final box = Hive.isBoxOpen('outlet_performance') ? Hive.box('outlet_performance') : await Hive.openBox('outlet_performance');
    if (await _network.isConnected) {
      try {
        final response = await _api.get<Map<String, dynamic>>('${ApiEndpoints.outlets}/$outletId/performance');
        await box.put(outletId, response);
        return OutletPerformanceModel.fromJson(response);
      } catch (_) {}
    }
    final cached = box.get(outletId);
    return cached is Map ? OutletPerformanceModel.fromJson(Map<String, dynamic>.from(cached)) : const OutletPerformanceModel(target: 0, achievement: 0, topProducts: [], unsoldProducts: [], potentialProducts: []);
  }
}
