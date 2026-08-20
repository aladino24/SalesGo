import 'package:get/get.dart';
import '../../core/network/network_info.dart';
import '../../data/models/dashboard_model.dart';
import '../../data/repositories/dashboard_repository.dart';

class HomeController extends GetxController {
  HomeController({DashboardRepository? repository, NetworkInfo? networkInfo}) : _repository = repository ?? DashboardRepository(), _networkInfo = networkInfo ?? Get.find<NetworkInfo>();
  final DashboardRepository _repository; final NetworkInfo _networkInfo;
  final RxInt selectedIndex = 0.obs;
  final RxString status = 'offline'.obs;
  final Rx<DashboardModel?> dashboard = Rx<DashboardModel?>(null);
  final RxBool isLoadingDashboard = false.obs;
  @override void onInit() { super.onInit(); refreshDashboard(); }

  void changeTab(int index) => selectedIndex.value = index;

  Future<void> refreshDashboard() async {
    isLoadingDashboard.value = true;
    status.value = 'syncing';
    final online = await _networkInfo.isConnected;
    dashboard.value = await _repository.get(online: online);
    status.value = online ? 'online' : 'offline';
    isLoadingDashboard.value = false;
  }
}
