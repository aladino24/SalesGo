import 'package:get/get.dart';

import 'visit_controller.dart';

class VisitBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<VisitController>(() => VisitController());
  }
}
