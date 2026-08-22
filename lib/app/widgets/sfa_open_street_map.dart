import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../theme/app_colors.dart';

class SfaMapMarker {
  const SfaMapMarker({
    required this.point,
    required this.label,
    required this.color,
    this.isCurrentLocation = false,
    this.onTap,
  });

  final LatLng point;
  final String label;
  final Color color;
  final bool isCurrentLocation;
  final VoidCallback? onTap;
}

class SfaOpenStreetMap extends StatelessWidget {
  const SfaOpenStreetMap({
    super.key,
    required this.center,
    required this.markers,
    this.route = const [],
    this.zoom = 14.5,
    this.onMapTap,
  });

  final LatLng center;
  final List<SfaMapMarker> markers;
  final List<LatLng> route;
  final double zoom;
  final ValueChanged<LatLng>? onMapTap;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: center,
              initialZoom: zoom,
              onTap: onMapTap == null ? null : (_, point) => onMapTap!(point),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.salesgo',
              ),
              if (route.length > 1)
                PolylineLayer(
                  polylines: [
                    Polyline(points: route, strokeWidth: 4, color: AppColors.primary),
                  ],
                ),
              MarkerLayer(
                markers: markers
                    .map((marker) => Marker(
                          point: marker.point,
                          width: marker.isCurrentLocation ? 44 : 34,
                          height: marker.isCurrentLocation ? 44 : 34,
                          child: _MapMarker(marker: marker),
                        ))
                    .toList(),
              ),
            ],
          ),
          const Positioned(
            right: 6,
            bottom: 5,
            child: DecoratedBox(
              decoration: BoxDecoration(color: Colors.white70, borderRadius: BorderRadius.all(Radius.circular(4))),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                child: Text('© OpenStreetMap contributors', style: TextStyle(fontSize: 8, color: AppColors.textSecondary)),
              ),
            ),
          ),
        ]),
      );
}

class _MapMarker extends StatelessWidget {
  const _MapMarker({required this.marker});
  final SfaMapMarker marker;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: marker.onTap,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(color: marker.color, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 5)]),
          child: marker.isCurrentLocation
              ? const Icon(Icons.my_location_rounded, color: Colors.white, size: 19)
              : Text(marker.label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
        ),
      );
}
