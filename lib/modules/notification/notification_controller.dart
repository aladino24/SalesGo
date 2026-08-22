import 'package:get/get.dart';

import '../../core/notifications/notification_deep_link_handler.dart';
import '../../data/models/app_notification_model.dart';
import '../../data/repositories/notification_repository.dart';

class NotificationController extends GetxController {
  NotificationController({NotificationRepository? repository, NotificationDeepLinkHandler? deepLinks})
      : _repository = repository ?? NotificationRepository(), _deepLinks = deepLinks ?? Get.find<NotificationDeepLinkHandler>();
  final NotificationRepository _repository;
  final NotificationDeepLinkHandler _deepLinks;
  final notifications = <AppNotificationModel>[].obs;
  final isLoading = false.obs;
  final unreadOnly = false.obs;
  @override void onInit() { super.onInit(); load(); }
  List<AppNotificationModel> get visibleItems => unreadOnly.value ? notifications.where((item) => !item.isRead).toList() : notifications;
  int get unreadCount => notifications.where((item) => !item.isRead).length;
  Future<void> load({bool refresh = true}) async { isLoading.value = true; try { notifications.assignAll(await _repository.getNotifications(refresh: refresh)); } finally { isLoading.value = false; } }
  Future<void> open(AppNotificationModel item) async { await _repository.markRead(item); final index = notifications.indexWhere((value) => value.id == item.id); if (index >= 0) notifications[index] = item.copyWith(isRead: true); if (item.deepLink != null && item.deepLink!.isNotEmpty) await _deepLinks.handle(item.deepLink, arguments: {'notificationTitle': item.title, 'notificationMessage': item.message, 'notificationType': item.type, 'notificationId': item.id}); }
}
