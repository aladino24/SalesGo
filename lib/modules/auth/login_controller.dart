import 'package:get/get.dart';

import '../../core/auth/app_roles.dart';
import '../../core/auth/session_service.dart';

class LoginController extends GetxController {
  LoginController({SessionService? sessionService}) : _sessionService = sessionService ?? Get.find<SessionService>();

  final SessionService _sessionService;
  final RxBool isLoading = false.obs;
  final RxString username = ''.obs;
  final RxString password = ''.obs;

  Future<void> login() async {
    isLoading.value = true;
    await Future<void>.delayed(const Duration(milliseconds: 700));

    final role = username.value.toLowerCase().contains('supervisor')
        ? AppRole.supervisor
        : username.value.toLowerCase().contains('manager')
            ? AppRole.branchManager
            : username.value.toLowerCase().contains('key')
                ? AppRole.keyAccountManager
                : AppRole.sales;

    await _sessionService.loginAs(role, username.value.isEmpty ? 'Sales' : username.value);
    isLoading.value = false;
    Get.offAllNamed('/home');
  }
}
