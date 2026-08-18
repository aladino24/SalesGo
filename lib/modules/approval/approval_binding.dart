import 'package:get/get.dart';

import '../../core/auth/session_service.dart';
import 'approval_controller.dart';

class ApprovalBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SessionService>(() => SessionService());
    Get.lazyPut<ApprovalController>(() => ApprovalController());
  }
}
