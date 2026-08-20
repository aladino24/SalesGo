import 'package:get/get.dart';
import 'package:salesgo/core/auth/app_roles.dart';

import '../../core/auth/session_service.dart';
import '../../core/network/network_info.dart';
import '../../data/repositories/monitoring_repository.dart';

class ReportController extends GetxController {
  ReportController({
    MonitoringRepository? repository,
    NetworkInfo? networkInfo,
    SessionService? session,
  }) : _repository = repository ?? MonitoringRepository(),
       _networkInfo = networkInfo ?? Get.find<NetworkInfo>(),
       _session = session ?? Get.find<SessionService>();
  final MonitoringRepository _repository;
  final NetworkInfo _networkInfo;
  final SessionService _session;
  final selectedType = 'revenue'.obs;
  final report = Rx<Map<String, dynamic>>({});
  final isLoading = false.obs;
  bool get isAllowed =>
      _session.currentRole.value?.canViewBranchReports ?? false;
  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> changeType(String type) async {
    selectedType.value = type;
    await load();
  }

  Future<void> load() async {
    if (!isAllowed) return;
    isLoading.value = true;
    try {
      report.value = await _repository.getReport(
        type: selectedType.value,
        online: await _networkInfo.isConnected,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
