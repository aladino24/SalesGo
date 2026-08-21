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
      final summary = await _repository.getReport(
        type: selectedType.value,
        online: await _networkInfo.isConnected,
      );
      final byType = summary['byType'];
      final rows = <Map<String, dynamic>>[
        {'label': 'Omset committed', 'subtitle': 'Sales order committed / selesai', 'value': summary['committedRevenue'] ?? 0},
        {'label': 'Order committed', 'subtitle': 'Jumlah order committed / selesai', 'value': summary['committedOrderCount'] ?? 0},
        {'label': 'Seluruh transaksi', 'subtitle': 'Sesuai filter periode', 'value': summary['transactionCount'] ?? 0},
        if (byType is List) ...byType.whereType<Map>().map((item) => {'label': item['type']?.toString().replaceAll('_', ' ') ?? 'Transaksi', 'subtitle': '${item['count'] ?? 0} transaksi', 'value': item['amount'] ?? 0}),
      ];
      report.value = {...summary, 'rows': rows};
    } finally {
      isLoading.value = false;
    }
  }
}
