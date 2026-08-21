import 'package:get/get.dart';

import '../../core/auth/session_service.dart';
import '../../data/repositories/auth_repository.dart';
import '../../app/widgets/sfa_feedback_dialog.dart';
import '../../core/notifications/push_notification_service.dart';
import '../notification/notification_controller.dart';

class LoginController extends GetxController {
  LoginController({SessionService? sessionService, AuthRepository? repository})
      : _sessionService = sessionService ?? Get.find<SessionService>(),
        _repository = repository ?? AuthRepository();

  final SessionService _sessionService;
  final AuthRepository _repository;
  final RxBool isLoading = false.obs;
  final RxString username = ''.obs;
  final RxString password = ''.obs;

  Future<void> login() async {
    if (username.value.trim().isEmpty || password.value.isEmpty) {
      SfaFeedbackDialog.show(type: SfaFeedbackType.warning, title: 'Login belum lengkap', message: 'Username dan password wajib diisi.');
      return;
    }
    isLoading.value = true;
    try {
      final session = await _repository.login(username: username.value.trim(), password: password.value);
      await _sessionService.saveSession(session);
      if (!Get.isRegistered<NotificationController>()) {
        Get.put(NotificationController(), permanent: true);
      } else {
        await Get.find<NotificationController>().load();
      }
      await Get.find<PushNotificationService>().start();
      Get.offAllNamed('/home');
    } catch (_) {
      SfaFeedbackDialog.show(type: SfaFeedbackType.error, title: 'Login gagal', message: 'Tidak dapat masuk. Periksa koneksi atau kredensial Anda.');
    } finally {
      isLoading.value = false;
    }
  }
}
