import 'package:get/get.dart';

import '../../modules/approval/approval_binding.dart';
import '../../modules/approval/approval_page.dart';
import '../../modules/auth/login_binding.dart';
import '../../modules/auth/login_page.dart';
import '../../modules/home/home_binding.dart';
import '../../modules/home/home_page.dart';
import '../../modules/outlet/outlet_binding.dart';
import '../../modules/outlet/outlet_page.dart';
import '../../modules/product/product_binding.dart';
import '../../modules/product/product_page.dart';
import '../../modules/settings/settings_binding.dart';
import '../../modules/settings/settings_page.dart';
import '../../modules/visit/visit_binding.dart';
import '../../modules/visit/visit_page.dart';
import 'app_routes.dart';

class AppPages {
  static final pages = <GetPage<dynamic>>[
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginPage(),
      binding: LoginBinding(),
    ),
    GetPage(
      name: AppRoutes.home,
      page: () => const HomePage(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: AppRoutes.visit,
      page: () => const VisitPage(),
      binding: VisitBinding(),
    ),
    GetPage(
      name: AppRoutes.outlet,
      page: () => const OutletPage(),
      binding: OutletBinding(),
    ),
    GetPage(
      name: AppRoutes.product,
      page: () => const ProductPage(),
      binding: ProductBinding(),
    ),
    GetPage(
      name: AppRoutes.settings,
      page: () => const SettingsPage(),
      binding: SettingsBinding(),
    ),
    GetPage(
      name: AppRoutes.approval,
      page: () => const ApprovalPage(),
      binding: ApprovalBinding(),
    ),
  ];
}
