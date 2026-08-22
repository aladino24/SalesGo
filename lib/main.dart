import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app/bindings/initial_binding.dart';
import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';
import 'app/theme/app_theme.dart';
import 'core/storage/local_storage.dart';
import 'core/storage/sync_storage.dart';
import 'core/auth/session_service.dart';
import 'core/notifications/push_notification_service.dart';
import 'core/localization/app_locale.dart';
import 'core/localization/app_translations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (_) {
    // The app remains usable until Firebase project files are installed.
  }
  await LocalStorage.init();
  await AppLocale.initialize();
  await SyncStorage.init();
  final sessionService = SessionService();
  await sessionService.loadSession();
  Get.put<SessionService>(sessionService, permanent: true);
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
      translations: AppTranslations(),
      locale: AppLocale.current,
      fallbackLocale: AppLocale.indonesian,
      supportedLocales: AppLocale.supportedLocales,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      initialRoute: Get.isRegistered<SessionService>() && Get.find<SessionService>().isAuthenticated ? AppRoutes.home : AppRoutes.login,
      getPages: AppPages.pages,
      initialBinding: InitialBinding(),
      debugShowCheckedModeBanner: false,
    );
  }
}
