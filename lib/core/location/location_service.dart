import 'package:geolocator/geolocator.dart';

class LocationSnapshot {
  const LocationSnapshot({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.capturedAt,
  });
  final double latitude, longitude, accuracy;
  final DateTime capturedAt;

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'accuracy': accuracy,
    'capturedAt': capturedAt.toIso8601String(),
  };
}

class LocationService {
  Future<LocationSnapshot> currentLocation() async {
    if (!await Geolocator.isLocationServiceEnabled())
      throw const LocationFailure(
        'GPS tidak aktif. Aktifkan layanan lokasi lalu coba lagi.',
      );
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied)
      permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied)
      throw const LocationFailure('Izin lokasi diperlukan untuk check-in.');
    if (permission == LocationPermission.deniedForever)
      throw const LocationFailure(
        'Izin lokasi ditolak permanen. Aktifkan dari Pengaturan perangkat.',
      );
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
    return LocationSnapshot(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      capturedAt: position.timestamp ?? DateTime.now(),
    );
  }

  double distanceInMeters({
    required double fromLatitude,
    required double fromLongitude,
    required double toLatitude,
    required double toLongitude,
  }) => Geolocator.distanceBetween(
    fromLatitude,
    fromLongitude,
    toLatitude,
    toLongitude,
  );
}

class LocationFailure implements Exception {
  const LocationFailure(this.message);
  final String message;
  @override
  String toString() => message;
}
