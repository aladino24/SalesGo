import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import '../auth/session_service.dart';
import '../network/api_endpoints.dart';
import '../sync/sync_manager.dart';
import 'location_service.dart';

/// Pencatatan lokasi foreground setiap tiga menit.
///
/// Ping selalu masuk antrean lokal lebih dahulu agar tetap aman saat offline.
/// SyncManager mengirim ulang antrean yang sama dengan idempotency key stabil.
class LocationTrackingService extends GetxService with WidgetsBindingObserver {
  LocationTrackingService({
    LocationService? locationService,
    SyncManager? syncManager,
    SessionService? session,
  })  : _locationService = locationService ?? LocationService(),
        _syncManager = syncManager ?? Get.find<SyncManager>(),
        _session = session ?? Get.find<SessionService>();

  static const interval = Duration(minutes: 3);

  final LocationService _locationService;
  final SyncManager _syncManager;
  final SessionService _session;
  Timer? _timer;
  bool _isCapturing = false;

  bool get isRunning => _timer != null;

  Future<void> start() async {
    if (!_session.isAuthenticated || isRunning) return;
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(interval, (_) => captureNow());
    await captureNow();
  }

  Future<void> stop() async {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _timer = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(captureNow());
    }
  }

  Future<void> captureNow() async {
    if (!_session.isAuthenticated || _isCapturing) return;
    _isCapturing = true;
    try {
      final location = await _locationService.currentLocation();
      const uuid = Uuid();
      final id = uuid.v4();
      await _syncManager.queueItem(
        type: 'location_ping',
        endpoint: ApiEndpoints.monitoringLocations,
        method: 'POST',
        uuid: id,
        idempotencyKey: id,
        payload: {
          'id': id,
          'location': {
            'latitude': location.latitude,
            'longitude': location.longitude,
            'accuracyMeters': location.accuracy,
          },
          'recordedAt': location.capturedAt.toUtc().toIso8601String(),
          'source': 'foreground',
        },
      );
    } on LocationFailure {
      // GPS/permission dapat belum siap. Tidak menampilkan dialog berulang;
      // pengguna masih dapat mengaktifkan GPS dari flow check-in.
    } finally {
      _isCapturing = false;
    }
  }
}
