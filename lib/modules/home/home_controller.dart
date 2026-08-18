import 'package:get/get.dart';

class HomeController extends GetxController {
  final RxInt selectedIndex = 0.obs;
  final RxString status = 'offline'.obs;

  void changeTab(int index) => selectedIndex.value = index;

  void refreshDashboard() {
    status.value = 'syncing';
    Future.delayed(const Duration(milliseconds: 700), () {
      status.value = 'online';
    });
  }
}
