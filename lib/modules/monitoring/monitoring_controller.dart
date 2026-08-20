import 'package:get/get.dart';

import '../../core/auth/app_roles.dart';
import '../../core/auth/session_service.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/network/network_info.dart';
import '../../data/repositories/monitoring_repository.dart';

class MonitoringController extends GetxController {
  MonitoringController({MonitoringRepository? repository, NetworkInfo? networkInfo, SessionService? session})
      : _repository = repository ?? MonitoringRepository(),
        _networkInfo = networkInfo ?? Get.find<NetworkInfo>(),
        _session = session ?? Get.find<SessionService>();
  final MonitoringRepository _repository;
  final NetworkInfo _networkInfo;
  final SessionService _session;

  final activities = <Map<String, dynamic>>[].obs;
  final visits = <Map<String, dynamic>>[].obs;
  final performance = <Map<String, dynamic>>[].obs;
  final isLoading = false.obs;
  bool get isAllowed => _session.currentRole.value?.canMonitorTeam ?? false;

  @override void onInit() { super.onInit(); load(); }

  Future<void> load() async {
    if (!isAllowed) return;
    isLoading.value = true;
    try {
      final online = await _networkInfo.isConnected;
      final results = await Future.wait([
        _repository.get(endpoint: ApiEndpoints.monitoringActivities, cacheKey: 'activities', online: online),
        _repository.get(endpoint: ApiEndpoints.monitoringVisits, cacheKey: 'visits', online: online),
        _repository.get(endpoint: ApiEndpoints.monitoringPerformance, cacheKey: 'performance', online: online),
      ]);
      activities.assignAll(_records(results[0], 'activities'));
      visits.assignAll(_records(results[1], 'visits'));
      performance.assignAll(_records(results[2], 'members'));
    } finally { isLoading.value = false; }
  }

  List<Map<String, dynamic>> _records(Map<String, dynamic> response, String key) {
    final list = response[key];
    return list is List ? list.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList() : [];
  }
}
