import 'package:get/get.dart';

import '../settings/settings_controller.dart';
import '../visit/visit_controller.dart';
import '../information/information_controller.dart';
import 'home_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HomeController>(() => HomeController());
    Get.lazyPut<VisitController>(() => VisitController());
    Get.lazyPut<SettingsController>(() => SettingsController());
    Get.lazyPut<InformationController>(() => InformationController());
  }
}
