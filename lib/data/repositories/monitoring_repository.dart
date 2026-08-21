import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';

class MonitoringRepository {
  MonitoringRepository({ApiClient? apiClient}) : _api = apiClient ?? Get.find<ApiClient>();
  final ApiClient _api;

  Future<Map<String, dynamic>> get({required String endpoint, required String cacheKey, required bool online, Map<String, dynamic>? query}) async {
    final box = Hive.isBoxOpen('monitoring_cache') ? Hive.box('monitoring_cache') : await Hive.openBox('monitoring_cache');
    if (online) {
      try {
        final response = await _api.get<Map<String, dynamic>>(endpoint, queryParameters: query);
        await box.put(cacheKey, response);
        return response;
      } catch (_) {}
    }
    final cached = box.get(cacheKey);
    return cached is Map ? Map<String, dynamic>.from(cached) : <String, dynamic>{};
  }

  Future<List<Map<String, dynamic>>> getList({required String endpoint, required String cacheKey, required bool online, Map<String, dynamic>? query}) async {
    final box = Hive.isBoxOpen('monitoring_cache') ? Hive.box('monitoring_cache') : await Hive.openBox('monitoring_cache');
    if (online) {
      try {
        final response = await _api.get<dynamic>(endpoint, queryParameters: query);
        final list = (response is List ? response : <dynamic>[]).whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList();
        await box.put(cacheKey, list);
        return list;
      } catch (_) {}
    }
    final cached = box.get(cacheKey);
    return cached is List ? cached.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList() : <Map<String, dynamic>>[];
  }

  Future<Map<String, dynamic>> getReport({required String type, required bool online}) => get(
        endpoint: ApiEndpoints.reportsSummary,
        cacheKey: 'report_$type',
        online: online,
        query: {'type': type, 'period': 'current_month'},
      );
}
