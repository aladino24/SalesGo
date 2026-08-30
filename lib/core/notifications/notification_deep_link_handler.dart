import 'package:get/get.dart';

import '../../app/routes/app_routes.dart';
import '../../modules/visit/visit_controller.dart';

/// Opens only known internal routes supplied by the backend notification payload.
class NotificationDeepLinkHandler {
  static const _allowedRoutes = <String>{
    AppRoutes.approval,
    AppRoutes.visit,
    AppRoutes.journey,
    AppRoutes.outlet,
    AppRoutes.notifications,
  };

  Future<bool> handle(
    String? value, {
    Map<String, dynamic>? arguments,
  }) async {
    if (value == null || value.trim().isEmpty) return false;
    final uri = Uri.tryParse(value.trim());
    if (uri == null) return false;
    final route = uri.path.isNotEmpty ? uri.path : '/${uri.host}';
    if (!_allowedRoutes.contains(route)) return false;

    final routeArguments = {
      ...uri.queryParameters,
      ...?arguments,
    };
    if (route == AppRoutes.visit) {
      // Keputusan approval dapat terjadi saat aplikasi tidak aktif. Muat ulang
      // snapshot visit terlebih dahulu agar VisitPage langsung mengunci ke
      // detail outlet yang sudah disetujui.
      final visits = Get.isRegistered<VisitController>()
          ? Get.find<VisitController>()
          : Get.put(VisitController());
      await visits.refreshFromServer();
    }
    await Get.toNamed(route, arguments: routeArguments);
    return true;
  }
}
