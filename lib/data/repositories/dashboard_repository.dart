import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../models/dashboard_model.dart';
class DashboardRepository { DashboardRepository({ApiClient? apiClient}) : _api = apiClient ?? Get.find<ApiClient>(); final ApiClient _api; static const _box = 'dashboard_cache'; static const _key = 'current'; Future<DashboardModel> get({required bool online}) async { final box = Hive.isBoxOpen(_box) ? Hive.box(_box) : await Hive.openBox(_box); if (online) { try { final data = await _api.get<Map<String,dynamic>>(ApiEndpoints.dashboard); await box.put(_key, data); return DashboardModel.fromJson(data); } catch (_) {} } final cached = box.get(_key); if (cached is Map) return DashboardModel.fromJson(Map<String,dynamic>.from(cached)); return const DashboardModel(monthlyRevenue: 0, monthlyTarget: 0, visitedOutlets: 0, totalOutlets: 0, incentive: 0, revenueGrowth: 0); } }
