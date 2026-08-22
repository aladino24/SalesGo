import 'package:get/get.dart';

import '../network/api_client.dart';
import '../network/api_endpoints.dart';
import 'location_service.dart';

class RouteEstimate {
  const RouteEstimate({required this.distanceMeters, required this.durationSeconds, required this.isEstimated});
  final double distanceMeters;
  final int durationSeconds;
  final bool isEstimated;
}

class RouteEstimateService {
  RouteEstimateService({ApiClient? apiClient, LocationService? locationService})
      : _api = apiClient ?? Get.find<ApiClient>(),
        _location = locationService ?? LocationService();
  final ApiClient _api;
  final LocationService _location;

  Future<RouteEstimate> estimate({required LocationSnapshot origin, required double destinationLatitude, required double destinationLongitude}) async {
    try {
      final response = await _api.post<Map<String, dynamic>>(ApiEndpoints.routeEstimate, data: {
        'origin': {'latitude': origin.latitude, 'longitude': origin.longitude},
        'destination': {'latitude': destinationLatitude, 'longitude': destinationLongitude},
      });
      final distance = ((response['distanceMeters'] as num?)?.toDouble()) ?? ((response['distanceKm'] as num?)?.toDouble() ?? 0) * 1000;
      final duration = ((response['durationSeconds'] as num?)?.toInt()) ?? ((response['durationMinutes'] as num?)?.toInt() ?? 0) * 60;
      if (distance != null && duration != null) return RouteEstimate(distanceMeters: distance, durationSeconds: duration, isEstimated: false);
    } catch (_) {
      // Offline or unavailable routing provider: use straight-line fallback.
    }
    final distance = _location.distanceInMeters(fromLatitude: origin.latitude, fromLongitude: origin.longitude, toLatitude: destinationLatitude, toLongitude: destinationLongitude);
    return RouteEstimate(distanceMeters: distance, durationSeconds: (distance / 6.94).round(), isEstimated: true);
  }
}
