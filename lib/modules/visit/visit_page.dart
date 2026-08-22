import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

import '../../app/theme/app_colors.dart';
import '../../app/widgets/sfa_open_street_map.dart';
import '../../app/widgets/sfa_ui.dart';
import '../../core/location/location_service.dart';
import '../../core/location/route_estimate_service.dart';
import '../../data/models/outlet_model.dart';
import '../../data/models/visit_model.dart';
import '../outlet/outlet_detail_page.dart';
import 'visit_controller.dart';

class VisitPage extends GetView<VisitController> {
  const VisitPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Kunjungan', style: TextStyle(fontWeight: FontWeight.w800)),
          actions: [
            IconButton(onPressed: () {}, icon: const Icon(Icons.tune_rounded)),
          ],
        ),
        body: SafeArea(
          child: DefaultTabController(
            length: 3,
            child: Column(children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: TabBar(
                  indicatorSize: TabBarIndicatorSize.tab,
                  tabs: [Tab(text: 'Hari Ini'), Tab(text: 'Minggu Ini'), Tab(text: 'Rute')],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: TabBarView(children: [
                  _RouteList(controller: controller),
                  _WeekVisits(controller: controller),
                  _RouteMap(controller: controller),
                ]),
              ),
            ]),
          ),
        ),
      );
}

class _RouteList extends StatelessWidget {
  const _RouteList({required this.controller});
  final VisitController controller;

  @override
  Widget build(BuildContext context) => Obx(() {
        if (controller.isLoading.value) return const Center(child: CircularProgressIndicator());
        final visits = _routeVisits(controller.visits).where((item) => item.isRequired == controller.requiredOnly.value).toList();
        return ListView.separated(
          key: ValueKey(controller.requiredOnly.value),
          padding: const EdgeInsets.fromLTRB(16, 2, 16, 24),
          itemCount: visits.length + 3,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            if (index == 0) return SegmentedButton<bool>(segments: const [ButtonSegment(value: true, label: Text('Wajib')), ButtonSegment(value: false, label: Text('Tidak Wajib'))], selected: {controller.requiredOnly.value}, onSelectionChanged: (value) => controller.selectVisitCategory(value.first));
            if (index == 1) return _RouteSummary(visits: visits);
            if (index == visits.length + 2) {
              return OutlinedButton.icon(
                onPressed: () => _showRouteMap(context),
                icon: const Icon(Icons.alt_route_rounded),
                label: const Text('Lihat Peta Rute'),
              );
            }
            final visit = visits[index - 2];
            return _VisitRouteCard(index: index - 1, visit: visit);
          },
        );
      });
}

List<VisitModel> _routeVisits(List<VisitModel> source) {
  final today = DateTime.now();
  return source.where((item) {
    final date = DateTime.tryParse(item.plannedFor ?? '')?.toLocal() ?? item.createdAt.toLocal();
    return date.year == today.year && date.month == today.month && date.day == today.day;
  }).toList();
}

class _RouteSummary extends StatelessWidget {
  const _RouteSummary({required this.visits});
  final List<VisitModel> visits;
  @override
  Widget build(BuildContext context) {
    final completed = visits.where((item) => item.status == 'Completed').length;
    final inProgress = visits.where((item) => item.status == 'In Progress').length;
    final pending = visits.where((item) => item.status == 'Pending' || item.status == 'Planned').length;
    final cancelled = visits.where((item) => item.status == 'Cancelled' || item.status == 'Failed').length;
    final progress = visits.isEmpty ? 0.0 : completed / visits.length;
    return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Expanded(child: Text('Rute hari ini', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
              SfaStatusChip(label: inProgress > 0 ? 'Berlangsung' : 'Terjadwal', color: AppColors.primary),
            ]),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: _RouteMetric('${visits.length} Outlet')), Expanded(child: _RouteMetric('$completed Selesai')), Text('${(progress * 100).toStringAsFixed(0)}%', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
            ]),
            const SizedBox(height: 5),
            Text('$inProgress dalam proses • $pending menunggu • $cancelled batal/gagal', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
            const SizedBox(height: 10),
            ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: progress, minHeight: 8, color: AppColors.primary, backgroundColor: AppColors.primarySoft)),
          ]),
        ),
      );
  }
}
class _RouteMetric extends StatelessWidget { const _RouteMetric(this.label); final String label; @override Widget build(BuildContext context) => Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)); }

class _VisitRouteCard extends StatelessWidget {
  const _VisitRouteCard({required this.index, required this.visit});
  final int index;
  final VisitModel visit;

  bool get completed => visit.status.toLowerCase() == 'completed';
  @override
  Widget build(BuildContext context) {
    final estimate = Get.find<VisitController>().routeEstimates[visit.id];
    final color = completed ? AppColors.success : AppColors.warning;
    final status = completed ? 'Dikunjungi' : 'Belum';
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Get.to(() => OutletDetailPage(outlet: _outletFor(visit), plannedVisitId: visit.id)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(
              width: 30, height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: color.withValues(alpha: .12), shape: BoxShape.circle),
              child: completed ? Icon(Icons.check_rounded, color: color, size: 18) : Text('$index', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(visit.outletName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(height: 4),
              Text(completed ? 'Check-in 09:15' : 'Belum check-in • ${visit.distanceKm.toStringAsFixed(1)} km', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ])),
            if (estimate != null)
              Padding(
                padding: const EdgeInsets.only(right: 5),
                child: SfaStatusChip(label: '${(estimate.durationSeconds / 60).ceil()} mnt', color: AppColors.primary),
              ),
            SfaStatusChip(label: status, color: color),
            const SizedBox(width: 5), const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
          ]),
        ),
      ),
    );
  }
}

class _WeekVisits extends StatelessWidget {
  const _WeekVisits({required this.controller});
  final VisitController controller;
  @override
  Widget build(BuildContext context) => Obx(() => ListView(
        padding: const EdgeInsets.fromLTRB(16, 2, 16, 24),
        children: [
          _WeekSummary(visits: _routeVisits(controller.visits)), const SizedBox(height: 16),
          ..._routeVisits(controller.visits).map((visit) => Padding(padding: const EdgeInsets.only(bottom: 10), child: _VisitRouteCard(index: _routeVisits(controller.visits).indexOf(visit) + 1, visit: visit))),
        ],
      ));
}
class _WeekSummary extends StatelessWidget { const _WeekSummary({required this.visits}); final List<VisitModel> visits; @override Widget build(BuildContext context) { final completed = visits.where((item) => item.status == 'Completed').length; final pending = visits.where((item) => item.status == 'Pending' || item.status == 'Planned').length; final cancelled = visits.where((item) => item.status == 'Cancelled' || item.status == 'Failed').length; return Card(child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [Expanded(child: _WeekValue('Total', '${visits.length}')), Expanded(child: _WeekValue('Selesai', '$completed')), Expanded(child: _WeekValue('Tertunda', '$pending')), Expanded(child: _WeekValue('Batal/Gagal', '$cancelled'))]))); } }
class _WeekValue extends StatelessWidget { const _WeekValue(this.label, this.value); final String label,value; @override Widget build(BuildContext context) => Column(children: [Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)), const SizedBox(height: 4), Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary))]); }

class _RouteMap extends StatelessWidget {
  const _RouteMap({required this.controller});
  final VisitController controller;
  @override
  Widget build(BuildContext context) => Obx(() {
        final visits = controller.recommendedRoute(_routeVisits(controller.visits));
        final estimates = visits.map((visit) => controller.routeEstimates[visit.id]).whereType<RouteEstimate>().toList();
        final totalDistance = estimates.fold<double>(0, (total, item) => total + item.distanceMeters);
        final totalMinutes = estimates.fold<int>(0, (total, item) => total + (item.durationSeconds / 60).ceil());
        return Padding(padding: const EdgeInsets.fromLTRB(16, 2, 16, 24), child: Column(children: [
          Expanded(child: _MapPlaceholder(visits: visits, currentLocation: controller.currentLocation.value)),
          const SizedBox(height: 14),
          Card(child: ListTile(leading: const CircleAvatar(child: Icon(Icons.alt_route_rounded)), title: const Text('Rute rekomendasi'), subtitle: Text('${visits.length} outlet • ${(totalDistance / 1000).toStringAsFixed(1)} km'), trailing: Text('~$totalMinutes mnt', style: const TextStyle(fontWeight: FontWeight.w800)))),
        ]));
      });
}

class _MapPlaceholder extends StatelessWidget {
  const _MapPlaceholder({required this.visits, this.currentLocation});
  final List<VisitModel> visits;
  final LocationSnapshot? currentLocation;
  @override
  Widget build(BuildContext context) {
    final current = currentLocation == null ? const LatLng(-7.2575, 112.7521) : LatLng(currentLocation!.latitude, currentLocation!.longitude);
    final routeVisits = visits.where((visit) => visit.latitude != null && visit.longitude != null).toList();
    final points = [current, ...routeVisits.map((visit) => LatLng(visit.latitude!, visit.longitude!))];
    return Stack(children: [
      SfaOpenStreetMap(
        center: current,
        route: points,
        markers: [
          SfaMapMarker(point: current, label: '', color: AppColors.success, isCurrentLocation: true),
          ...routeVisits.asMap().entries.map((entry) => SfaMapMarker(point: LatLng(entry.value.latitude!, entry.value.longitude!), label: '${entry.key + 1}', color: entry.value.status == 'Completed' ? AppColors.success : AppColors.primary)),
        ],
      ),
      const Positioned(left: 12, top: 12, child: SfaStatusChip(label: 'Lokasi Anda', color: AppColors.success)),
    ]);
  }
}

OutletModel _outletFor(VisitModel visit) => OutletModel(id: visit.outletId ?? visit.id, name: visit.outletName, code: visit.outletCode ?? '-', address: visit.outletAddress ?? 'Alamat belum tersedia', type: 'Outlet', latitude: visit.latitude ?? 0, longitude: visit.longitude ?? 0, salesResponsible: visit.salesName, status: visit.status);
void _showRouteMap(BuildContext context) => DefaultTabController.of(context).animateTo(2);
