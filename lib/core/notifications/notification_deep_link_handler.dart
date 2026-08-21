import 'package:get/get.dart';

import '../../app/routes/app_routes.dart';

/// Opens only known internal routes supplied by the backend notification payload.
class NotificationDeepLinkHandler {
  static const _allowedRoutes = <String>{
    AppRoutes.approval,
    AppRoutes.journey,
    AppRoutes.outlet,
    AppRoutes.notifications,
  };

  Future<bool> handle(String? value) async {
    if (value == null || value.trim().isEmpty) return false;
    final uri = Uri.tryParse(value.trim());
    if (uri == null) return false;
    final route = uri.path.isNotEmpty ? uri.path : '/${uri.host}';
    if (!_allowedRoutes.contains(route)) return false;

    await Get.toNamed(route, arguments: uri.queryParameters);
    return true;
  }
}
