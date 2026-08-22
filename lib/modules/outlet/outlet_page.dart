import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

import '../../app/theme/app_colors.dart';
import '../../app/widgets/sfa_open_street_map.dart';
import '../../core/auth/app_roles.dart';
import '../../core/auth/session_service.dart';
import '../../core/location/location_service.dart';
import '../../app/widgets/sfa_ui.dart';
import '../../data/models/outlet_model.dart';
import 'outlet_controller.dart';
import 'outlet_detail_page.dart';
import 'new_outlet_page.dart';

class OutletPage extends GetView<OutletController> {
  const OutletPage({super.key});

  @override
  Widget build(BuildContext context) {
    final role = Get.isRegistered<SessionService>()
        ? Get.find<SessionService>().currentRole.value
        : null;
    final canRequestNewOutlet = role?.canRequestNewOutlet ?? false;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Master Outlet',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      floatingActionButton: canRequestNewOutlet
          ? FloatingActionButton.extended(
              onPressed: () => Get.to(() => const NewOutletPage()),
              icon: const Icon(Icons.add_business_rounded),
              label: const Text('Tambah Outlet'),
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: TextField(
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search_rounded),
                  hintText: 'Cari outlet, kode, alamat...',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) => controller.searchTerm.value = value,
              ),
            ),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                final items = controller.filteredOutlets;
                if (items.isEmpty) {
                  return SfaEmptyState(icon: Icons.storefront_outlined, title: 'Outlet tidak ditemukan', description: controller.searchTerm.value.isEmpty ? 'Belum ada outlet yang tersimpan di perangkat.' : 'Coba gunakan kata kunci pencarian lain.', actionLabel: 'Muat ulang', onAction: controller.loadOutlets);
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final outlet = items[index];
                    return _OutletCard(
                      outlet: outlet,
                      onTap: () => Get.to(() => OutletDetailPage(outlet: outlet)),
                      onShowLocation: () => Get.to(() => OutletLocationMapPage(outlet: outlet)),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _OutletCard extends StatelessWidget {
  const _OutletCard({required this.outlet, required this.onTap, required this.onShowLocation});

  final OutletModel outlet;
  final VoidCallback onTap;
  final VoidCallback onShowLocation;

  Color get _statusColor {
    switch (outlet.status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'inactive':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            outlet.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            outlet.code,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        outlet.status,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.store_rounded,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            outlet.type,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              outlet.address,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'PIC: ${outlet.salesResponsible}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Lihat lokasi toko',
                      onPressed: onShowLocation,
                      icon: const Icon(Icons.map_outlined, color: AppColors.primary),
                    ),
                    Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 20),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class OutletLocationMapPage extends StatefulWidget {
  const OutletLocationMapPage({super.key, required this.outlet});
  final OutletModel outlet;

  @override
  State<OutletLocationMapPage> createState() => _OutletLocationMapPageState();
}

class _OutletLocationMapPageState extends State<OutletLocationMapPage> {
  final _locationService = LocationService();
  LocationSnapshot? _currentLocation;

  @override
  void initState() {
    super.initState();
    _loadCurrentLocation();
  }

  Future<void> _loadCurrentLocation() async {
    try {
      final location = await _locationService.currentLocation();
      if (mounted) setState(() => _currentLocation = location);
    } on LocationFailure {
      // Marker outlet tetap dapat digunakan jika GPS ditolak/tidak tersedia.
    }
  }

  @override
  Widget build(BuildContext context) {
    final outlet = widget.outlet;
    final point = LatLng(outlet.latitude, outlet.longitude);
    final current = _currentLocation == null ? null : LatLng(_currentLocation!.latitude, _currentLocation!.longitude);
    return Scaffold(
      appBar: AppBar(title: const Text('Lokasi Outlet')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Expanded(
            child: SfaOpenStreetMap(
              center: point,
              zoom: 16,
              markers: [
                SfaMapMarker(point: point, label: 'Toko', color: AppColors.primary),
                if (current != null) SfaMapMarker(point: current, label: '', color: AppColors.success, isCurrentLocation: true),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (current == null) const Padding(padding: EdgeInsets.only(bottom: 8), child: Text('Mengambil lokasi Anda…', style: TextStyle(fontSize: 11, color: AppColors.textSecondary))),
          Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.storefront_rounded)),
              title: Text(outlet.name, style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text('${outlet.code}\n${outlet.address}\n${outlet.latitude.toStringAsFixed(6)}, ${outlet.longitude.toStringAsFixed(6)}'),
              isThreeLine: true,
            ),
          ),
        ]),
      ),
    );
  }
}
