import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

import '../../app/theme/app_colors.dart';
import '../../app/widgets/sfa_open_street_map.dart';
import '../../app/widgets/sfa_ui.dart';
import 'monitoring_controller.dart';

class MonitoringPage extends GetView<MonitoringController> {
  const MonitoringPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Monitoring Tim', style: TextStyle(fontWeight: FontWeight.w800))),
        body: SafeArea(child: Obx(() {
          if (!controller.isAllowed) return const SfaEmptyState(icon: Icons.lock_outline_rounded, title: 'Akses terbatas', description: 'Monitoring tim hanya tersedia untuk Supervisor dan Branch Manager.');
          if (controller.isLoading.value && controller.members.isEmpty) return const Center(child: CircularProgressIndicator());
          return DefaultTabController(
            length: 4,
            child: Column(children: [
              const TabBar(isScrollable: true, tabs: [Tab(text: 'Aktivitas'), Tab(text: 'Lacak Lokasi'), Tab(text: 'Kunjungan'), Tab(text: 'Kinerja')]),
              Expanded(child: TabBarView(children: [
                _ActivityList(controller: controller),
                _TrackingTab(controller: controller),
                _VisitList(items: controller.visits, onRefresh: controller.load),
                _PerformanceList(items: controller.performance, onRefresh: controller.load),
              ])),
            ]),
          );
        })),
      );
}

class _MemberPicker extends StatelessWidget {
  const _MemberPicker({required this.members, required this.selectedId, required this.onSelected, this.allowAll = false});
  final List<Map<String, dynamic>> members;
  final String selectedId;
  final ValueChanged<String?> onSelected;
  final bool allowAll;

  @override
  Widget build(BuildContext context) => DropdownMenu<String>(
        width: double.infinity,
        enableFilter: true,
        label: const Text('Cari / pilih anggota tim'),
        initialSelection: selectedId,
        dropdownMenuEntries: [
          if (allowAll) const DropdownMenuEntry(value: '', label: 'Semua anggota tim'),
          ...members.map((member) => DropdownMenuEntry(value: member['id'].toString(), label: '${member['name'] ?? 'Pengguna'} (${member['employeeCode'] ?? '-'})', leadingIcon: const Icon(Icons.person_outline_rounded))),
        ],
        onSelected: onSelected,
      );
}

class _ActivityList extends StatelessWidget {
  const _ActivityList({required this.controller});
  final MonitoringController controller;

  @override
  Widget build(BuildContext context) => Obx(() => Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 4), child: _MemberPicker(members: controller.members, selectedId: controller.selectedActivityMemberId.value, allowAll: true, onSelected: controller.selectActivityMember)),
        Expanded(child: _RefreshList(
          items: controller.activities,
          onRefresh: controller.loadActivities,
          emptyIcon: Icons.history_toggle_off_rounded,
          emptyTitle: 'Belum ada aktivitas',
          emptyDescription: 'Aktivitas anggota tim yang sudah tercatat di server akan muncul di sini.',
          itemBuilder: (item) => ListTile(
            leading: const CircleAvatar(child: Icon(Icons.history_rounded)),
            title: Text(_eventLabel(item['event']?.toString())),
            subtitle: Text('${item['salesName'] ?? 'Pengguna'} • ${_roleLabel(item['role']?.toString())}\n${item['employeeCode'] ?? '-'}'),
            isThreeLine: true,
            trailing: Text(_timeText(item['createdAt']), textAlign: TextAlign.right, style: const TextStyle(fontSize: 11)),
          ),
        )),
      ]));
}

class _TrackingTab extends StatelessWidget {
  const _TrackingTab({required this.controller});
  final MonitoringController controller;

  @override
  Widget build(BuildContext context) => Obx(() {
        final history = controller.locationHistory;
        final member = controller.selectedTrackingMember;
        final route = history.map(_pointOf).whereType<LatLng>().toList();
        final last = route.isNotEmpty ? route.last : _pointOf(member?['lastLocation']);
        return RefreshIndicator(
          onRefresh: controller.load,
          child: ListView(padding: const EdgeInsets.all(16), children: [
            _MemberPicker(members: controller.members, selectedId: controller.selectedTrackingMemberId.value, onSelected: controller.selectTrackingMember),
            const SizedBox(height: 16),
            if (controller.isTrackingLoading.value)
              const SizedBox(height: 280, child: Center(child: CircularProgressIndicator()))
            else if (last == null)
              const SizedBox(height: 260, child: SfaEmptyState(icon: Icons.location_off_outlined, title: 'Belum ada titik lokasi', description: 'Lokasi akan muncul setelah aplikasi mengirim ping GPS.'))
            else ...[
              SizedBox(height: 310, child: SfaOpenStreetMap(center: last, route: route, markers: [SfaMapMarker(point: last, label: '', color: AppColors.success, isCurrentLocation: true)])),
              const SizedBox(height: 12),
              Card(child: ListTile(leading: const CircleAvatar(child: Icon(Icons.person_pin_circle_rounded)), title: Text(member?['name']?.toString() ?? 'Anggota tim'), subtitle: Text('Titik terakhir: ${history.isEmpty ? _timeText(member?['lastLocation']?['recordedAt']) : _timeText(history.last['recordedAt'])}\n${history.length} titik terhubung berdasarkan waktu'), isThreeLine: true)),
            ],
          ]),
        );
      });
}

class _VisitList extends StatelessWidget {
  const _VisitList({required this.items, required this.onRefresh});
  final List<Map<String, dynamic>> items;
  final Future<void> Function() onRefresh;
  @override
  Widget build(BuildContext context) => _RefreshList(items: items, onRefresh: onRefresh, emptyIcon: Icons.map_outlined, emptyTitle: 'Belum ada kunjungan', emptyDescription: 'Status kunjungan anggota tim akan tampil di sini.', itemBuilder: (item) => ListTile(leading: CircleAvatar(backgroundColor: AppColors.primarySoft, child: const Icon(Icons.location_on_outlined, color: AppColors.primary)), title: Text(item['outletName']?.toString() ?? 'Outlet'), subtitle: Text('${item['salesName'] ?? 'Pengguna'} • ${_roleLabel(item['role']?.toString())}'), trailing: const SfaStatusChip(label: 'In Progress', color: AppColors.success)));
}

class _PerformanceList extends StatelessWidget {
  const _PerformanceList({required this.items, required this.onRefresh});
  final List<Map<String, dynamic>> items;
  final Future<void> Function() onRefresh;
  @override
  Widget build(BuildContext context) => _RefreshList(items: items, onRefresh: onRefresh, emptyIcon: Icons.analytics_outlined, emptyTitle: 'Belum ada data kinerja', emptyDescription: 'Omset dan target tim akan tampil di sini.', itemBuilder: (item) => ListTile(title: Text(item['salesName']?.toString() ?? 'Pengguna')));
}

class _RefreshList extends StatelessWidget {
  const _RefreshList({required this.items, required this.onRefresh, required this.emptyIcon, required this.emptyTitle, required this.emptyDescription, required this.itemBuilder});
  final List<Map<String, dynamic>> items;
  final Future<void> Function() onRefresh;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptyDescription;
  final Widget Function(Map<String, dynamic>) itemBuilder;
  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return SfaEmptyState(icon: emptyIcon, title: emptyTitle, description: emptyDescription, actionLabel: 'Muat ulang', onAction: onRefresh);
    return RefreshIndicator(onRefresh: onRefresh, child: ListView.separated(padding: const EdgeInsets.all(16), itemCount: items.length, separatorBuilder: (_, __) => const SizedBox(height: 8), itemBuilder: (_, index) => Card(child: itemBuilder(items[index]))));
  }
}

LatLng? _pointOf(dynamic value) {
  if (value is! Map) return null;
  final latitude = double.tryParse(value['latitude']?.toString() ?? '');
  final longitude = double.tryParse(value['longitude']?.toString() ?? '');
  return latitude == null || longitude == null ? null : LatLng(latitude, longitude);
}

String _timeText(dynamic value) {
  final date = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
  if (date == null) return '-';
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}

String _roleLabel(String? role) => switch (role) {'branchManager' => 'Branch Manager', 'supervisor' => 'Supervisor', _ => 'Sales'};
String _eventLabel(String? event) => (event ?? 'Aktivitas').replaceAll('_', ' ');
