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
      final members = await _repository.getList(endpoint: ApiEndpoints.monitoringTeam, cacheKey: 'team', online: online);
      activities.assignAll(members.where((item) => item['lastLocation'] is Map).map((item) => {...Map<String, dynamic>.from(item['lastLocation'] as Map), 'salesName': item['name'], 'employeeCode': item['employeeCode']}).toList());
      visits.assignAll(members.where((item) => item['activeVisit'] is Map).map((item) => {...Map<String, dynamic>.from(item['activeVisit'] as Map), 'salesName': item['name'], 'employeeCode': item['employeeCode']}).toList());
      performance.clear();
    } finally { isLoading.value = false; }
  }

}
