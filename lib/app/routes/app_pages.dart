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
import '../../modules/journey/journey_page.dart';
import '../../modules/journey/journey_binding.dart';
import '../../modules/notification/notification_page.dart';
import '../../modules/notification/notification_binding.dart';
import '../../modules/monitoring/monitoring_binding.dart';
import '../../modules/monitoring/monitoring_page.dart';
import '../../modules/reports/report_binding.dart';
import '../../modules/reports/report_page.dart';
import '../../modules/meeting/meeting_binding.dart';
import '../../modules/meeting/meeting_page.dart';
import '../../modules/sync_activity/sync_activity_page.dart';
import '../../modules/route_master/route_master_page.dart';
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
    GetPage(name: AppRoutes.journey, page: () => const JourneyPage(), binding: JourneyBinding()),
    GetPage(name: AppRoutes.notifications, page: () => const NotificationPage(), binding: NotificationBinding()),
    GetPage(name: AppRoutes.monitoring, page: () => const MonitoringPage(), binding: MonitoringBinding()),
    GetPage(name: AppRoutes.reports, page: () => const ReportPage(), binding: ReportBinding()),
    GetPage(name: AppRoutes.meetings, page: () => const MeetingPage(), binding: MeetingBinding()),
    GetPage(name: AppRoutes.meetingDetail, page: () => const MeetingDetailPage(), binding: MeetingBinding()),
    GetPage(name: AppRoutes.syncActivity, page: () => const SyncActivityPage()),
    GetPage(name: AppRoutes.routeMaster, page: () => const RouteMasterPage()),
  ];
}
