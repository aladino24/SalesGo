import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app/bindings/initial_binding.dart';
import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';
import 'app/theme/app_theme.dart';
import 'core/storage/local_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await LocalStorage.init();

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
      initialRoute: AppRoutes.login,
      getPages: AppPages.pages,
      initialBinding: InitialBinding(),
      debugShowCheckedModeBanner: false,
    );
  }
}
