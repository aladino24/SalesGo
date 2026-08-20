import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/theme/app_colors.dart';
import '../../app/widgets/sfa_ui.dart';
import 'monitoring_controller.dart';

class MonitoringPage extends GetView<MonitoringController> {
  const MonitoringPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Monitoring Tim', style: TextStyle(fontWeight: FontWeight.w800))),
        body: SafeArea(child: Obx(() {
          if (!controller.isAllowed) return const SfaEmptyState(icon: Icons.lock_outline_rounded, title: 'Akses terbatas', description: 'Monitoring tim hanya tersedia untuk Supervisor dan Branch Manager.');
          if (controller.isLoading.value && controller.activities.isEmpty) return const Center(child: CircularProgressIndicator());
          return DefaultTabController(
            length: 3,
            child: Column(children: [
              const TabBar(tabs: [Tab(text: 'Aktivitas'), Tab(text: 'Kunjungan'), Tab(text: 'Kinerja')]),
              Expanded(child: TabBarView(children: [
                _ActivityList(items: controller.activities, onRefresh: controller.load),
                _VisitList(items: controller.visits, onRefresh: controller.load),
                _PerformanceList(items: controller.performance, onRefresh: controller.load),
              ])),
            ]),
          );
        })),
      );
}

class _ActivityList extends StatelessWidget {
  const _ActivityList({required this.items, required this.onRefresh});
  final List<Map<String, dynamic>> items; final Future<void> Function() onRefresh;
  @override Widget build(BuildContext context) => _RefreshList(
    items: items, onRefresh: onRefresh, emptyIcon: Icons.history_toggle_off_rounded, emptyTitle: 'Belum ada aktivitas', emptyDescription: 'Aktivitas tim dari server akan tampil di sini.',
    itemBuilder: (item) => ListTile(leading: const CircleAvatar(child: Icon(Icons.person_pin_circle_outlined)), title: Text(item['salesName']?.toString() ?? 'Sales'), subtitle: Text(item['description']?.toString() ?? item['activity']?.toString() ?? 'Aktivitas belum tersedia'), trailing: Text(item['occurredAt']?.toString() ?? '')),
  );
}

class _VisitList extends StatelessWidget {
  const _VisitList({required this.items, required this.onRefresh});
  final List<Map<String, dynamic>> items; final Future<void> Function() onRefresh;
  @override Widget build(BuildContext context) => _RefreshList(
    items: items, onRefresh: onRefresh, emptyIcon: Icons.map_outlined, emptyTitle: 'Belum ada kunjungan', emptyDescription: 'Status kunjungan sales akan tampil di sini.',
    itemBuilder: (item) => ListTile(leading: CircleAvatar(backgroundColor: AppColors.primarySoft, child: const Icon(Icons.location_on_outlined, color: AppColors.primary)), title: Text(item['outletName']?.toString() ?? 'Outlet'), subtitle: Text(item['salesName']?.toString() ?? 'Sales'), trailing: SfaStatusChip(label: item['status']?.toString() ?? '-', color: _statusColor(item['status']?.toString())),),
  );
}

class _PerformanceList extends StatelessWidget {
  const _PerformanceList({required this.items, required this.onRefresh});
  final List<Map<String, dynamic>> items; final Future<void> Function() onRefresh;
  @override Widget build(BuildContext context) => _RefreshList(
    items: items, onRefresh: onRefresh, emptyIcon: Icons.analytics_outlined, emptyTitle: 'Belum ada data kinerja', emptyDescription: 'Omset dan target tim akan tampil di sini.',
    itemBuilder: (item) { final revenue = (item['revenue'] ?? 0).toString(); final target = (item['target'] ?? 0).toString(); return ListTile(leading: const CircleAvatar(child: Icon(Icons.trending_up_rounded)), title: Text(item['salesName']?.toString() ?? 'Sales'), subtitle: Text('Omset Rp $revenue dari target Rp $target'), trailing: Text('${item['visitCount'] ?? 0} visit', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700))); },
  );
}

class _RefreshList extends StatelessWidget {
  const _RefreshList({required this.items, required this.onRefresh, required this.emptyIcon, required this.emptyTitle, required this.emptyDescription, required this.itemBuilder});
  final List<Map<String, dynamic>> items; final Future<void> Function() onRefresh; final IconData emptyIcon; final String emptyTitle, emptyDescription; final Widget Function(Map<String, dynamic>) itemBuilder;
  @override Widget build(BuildContext context) { if (items.isEmpty) return SfaEmptyState(icon: emptyIcon, title: emptyTitle, description: emptyDescription, actionLabel: 'Muat ulang', onAction: onRefresh); return RefreshIndicator(onRefresh: onRefresh, child: ListView.separated(padding: const EdgeInsets.all(16), itemCount: items.length, separatorBuilder: (_, __) => const SizedBox(height: 8), itemBuilder: (_, index) => Card(child: itemBuilder(items[index])))); }
}

Color _statusColor(String? status) => status == 'In Progress' ? AppColors.success : status == 'Cancelled' ? AppColors.danger : AppColors.primary;
