import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';

import 'app/bindings/initial_binding.dart';
import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';
import 'app/theme/app_theme.dart';
import 'core/storage/local_storage.dart';
import 'core/storage/sync_storage.dart';
import 'core/auth/session_service.dart';
import 'data/repositories/auth_repository.dart';
import 'core/notifications/push_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (_) {
    // The app remains usable until Firebase project files are installed.
  }
  await LocalStorage.init();
  await SyncStorage.init();
  final sessionService = SessionService();
  await sessionService.loadSession();
  Get.put<SessionService>(sessionService, permanent: true);
  if (sessionService.isAccessTokenExpired && sessionService.refreshToken.value.isNotEmpty) {
    try {
      await sessionService.saveSession(await AuthRepository().refresh(sessionService.refreshToken.value));
    } catch (_) {
      await sessionService.logout();
    }
  }

  runApp(const SalesGoApp());
}

class SalesGoApp extends StatelessWidget {
  const SalesGoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'SalesGo SFA',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      initialRoute: Get.isRegistered<SessionService>() && Get.find<SessionService>().isAuthenticated ? AppRoutes.home : AppRoutes.login,
      getPages: AppPages.pages,
      initialBinding: InitialBinding(),
      debugShowCheckedModeBanner: false,
    );
  }
}
