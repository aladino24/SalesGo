import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import '../auth/session_service.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';
import '../storage/local_storage.dart';
import '../../modules/notification/notification_controller.dart';
import '../../app/widgets/sfa_feedback_dialog.dart';
import 'notification_deep_link_handler.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class PushNotificationService extends GetxService {
  PushNotificationService({
    FirebaseMessaging? messaging,
    ApiClient? apiClient,
    SessionService? sessionService,
    NotificationDeepLinkHandler? deepLinks,
  })  : _messaging = messaging ??
            (Firebase.apps.isNotEmpty ? FirebaseMessaging.instance : null),
        _api = apiClient ?? Get.find<ApiClient>(),
        _session = sessionService ?? Get.find<SessionService>(),
        _deepLinks = deepLinks ?? Get.find<NotificationDeepLinkHandler>();

  static const _deviceIdKey = 'push_device_id';

  final FirebaseMessaging? _messaging;
  final ApiClient _api;
  final SessionService _session;
  final NotificationDeepLinkHandler _deepLinks;
  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _openedAppSubscription;
  StreamSubscription<RemoteMessage>? _foregroundMessageSubscription;
  bool _started = false;

  Future<void> start() async {
    final messaging = _messaging;
    if (_started || !_session.isAuthenticated || messaging == null) return;
    _started = true;
    try {
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        _started = false;
        return;
      }
      if (Platform.isIOS) {
        final apnsToken = await messaging.getAPNSToken();
        if (apnsToken == null) {
          _started = false;
          return;
        }
        await messaging.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
      }
      await _registerToken(await messaging.getToken());
      _tokenRefreshSubscription = messaging.onTokenRefresh.listen(_registerToken);
      _openedAppSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
        _openMessage,
      );
      _foregroundMessageSubscription = FirebaseMessaging.onMessage.listen((message) async {
        if (Get.isRegistered<NotificationController>()) {
          await Get.find<NotificationController>().load();
        }
        // Android tidak menampilkan system notification saat aplikasi berada
        // di foreground. Tampilkan dialog aplikasi agar BM/SPV tetap langsung
        // mengetahui approval baru, lalu buka deep link saat tombol ditekan.
        final title = message.notification?.title ??
            message.data['title']?.toString() ??
            'Notifikasi baru';
        final body = message.notification?.body ??
            message.data['message']?.toString() ??
            'Ada pembaruan yang perlu diperhatikan.';
        if (!(Get.isDialogOpen ?? false)) {
          await SfaFeedbackDialog.show(
            type: SfaFeedbackType.info,
            title: title,
            message: body,
            actionLabel: 'Lihat detail',
            onAction: () {
              _openMessage(message);
            },
          );
        }
      });
      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) await _openMessage(initialMessage);
    } catch (_) {
      // Firebase configuration or network may not be available yet.
      _started = false;
    }
  }

  Future<void> stop() async {
    final id = LocalStorage.appBox.get(_deviceIdKey)?.toString();
    if (id != null && id.isNotEmpty && _session.isAuthenticated) {
      try {
        await _api.delete<void>(
          '${ApiEndpoints.notificationDevices}/$id',
          idempotencyKey: const Uuid().v4(),
        );
      } catch (_) {}
    }
    await LocalStorage.appBox.delete(_deviceIdKey);
    await _tokenRefreshSubscription?.cancel();
    await _openedAppSubscription?.cancel();
    await _foregroundMessageSubscription?.cancel();
    _tokenRefreshSubscription = null;
    _openedAppSubscription = null;
    _foregroundMessageSubscription = null;
    _started = false;
  }

  Future<void> _registerToken(String? token) async {
    if (token == null || token.isEmpty || !_session.isAuthenticated) return;
    final response = await _api.post<Map<String, dynamic>>(
      ApiEndpoints.notificationDevices,
      data: {
        'token': token,
        'platform': Platform.isIOS ? 'ios' : 'android',
      },
      idempotencyKey: const Uuid().v4(),
    );
    final id = response['id']?.toString();
    if (id != null && id.isNotEmpty) await LocalStorage.appBox.put(_deviceIdKey, id);
  }

  Future<void> _openMessage(RemoteMessage message) =>
      _deepLinks.handle(message.data['deepLink']?.toString());
}
