import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

import '../../app/theme/app_colors.dart';
import '../../app/widgets/sfa_ui.dart';
import '../../core/sync/sync_manager.dart';
import '../../data/datasources/local/visit_local_data_source.dart';

class ActivityPage extends StatefulWidget {
  const ActivityPage({super.key});

  @override
  State<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> {
  late Future<List<_ActivityItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<void> _refresh() async => setState(() => _future = _load());

  Future<List<_ActivityItem>> _load() async {
    final results = <_ActivityItem>[];
    final journeyBox = Hive.isBoxOpen('journey_activities') ? Hive.box('journey_activities') : await Hive.openBox('journey_activities');
    for (final raw in journeyBox.values.whereType<Map>()) {
      final item = Map<String, dynamic>.from(raw);
      final at = DateTime.tryParse(item['createdAt']?.toString() ?? '');
      if (at != null) results.add(_ActivityItem(title: item['event']?.toString() ?? 'Perjalanan', description: item['description']?.toString() ?? 'Perjalanan sales', queuedAt: at, status: 'Terkirim', sentAt: at, icon: Icons.route_rounded));
    }
    for (final visit in await VisitLocalDataSource().getVisits()) {
      results.add(_ActivityItem(title: 'Kunjungan ${visit.status}', description: visit.outletName, queuedAt: visit.createdAt, status: visit.status == 'In Progress' || visit.status == 'Completed' ? 'Terkirim' : 'Pending', sentAt: visit.status == 'In Progress' || visit.status == 'Completed' ? visit.createdAt : null, icon: Icons.location_on_rounded));
    }
    final auditBox = Hive.isBoxOpen('sync_audit_log') ? Hive.box('sync_audit_log') : await Hive.openBox('sync_audit_log');
    for (final raw in auditBox.values.whereType<Map>()) {
      final item = Map<String, dynamic>.from(raw);
      final at = DateTime.tryParse(item['createdAt']?.toString() ?? '');
      if (at == null) continue;
      final event = item['event']?.toString() ?? '';
      final status = event == 'sync_succeeded' ? 'Terkirim' : event.contains('retry') || event.contains('conflict') ? 'Retry' : 'Pending';
      results.add(_ActivityItem(title: item['type']?.toString().replaceAll('_', ' ') ?? 'Sinkronisasi', description: item['message']?.toString() ?? 'Data antrean server', queuedAt: at, status: status, sentAt: status == 'Terkirim' ? at : null, icon: Icons.cloud_sync_rounded));
    }
    results.sort((a, b) => b.queuedAt.compareTo(a.queuedAt));
    return results;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Semua Aktivitas')),
    body: FutureBuilder<List<_ActivityItem>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
        final items = snapshot.data ?? [];
        if (items.isEmpty) return const SfaEmptyState(icon: Icons.history_outlined, title: 'Belum ada aktivitas', description: 'Kunjungan, perjalanan, dan proses sinkronisasi akan tampil di sini.');
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              if (index == 0) return OutlinedButton.icon(onPressed: () async { await Get.find<SyncManager>().syncNow(force: true); await _refresh(); }, icon: const Icon(Icons.sync_rounded), label: const Text('Coba kirim semua aktivitas pending'));
              final item = items[index - 1];
              final color = item.status == 'Terkirim' ? AppColors.success : item.status == 'Retry' ? AppColors.danger : AppColors.warning;
              return Card(child: ListTile(
                leading: CircleAvatar(backgroundColor: color.withValues(alpha: .12), child: Icon(item.icon, color: color)),
                title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text('${item.description}\nMasuk antrean: ${DateFormat('dd MMM y, HH:mm', 'id').format(item.queuedAt.toLocal())}${item.sentAt == null ? '' : '\nTerkirim: ${DateFormat('dd MMM y, HH:mm', 'id').format(item.sentAt!.toLocal())}'}'),
                isThreeLine: true,
                trailing: SfaStatusChip(label: item.status, color: color),
              ));
            },
          ),
        );
      },
    ),
  );
}

class _ActivityItem {
  const _ActivityItem({required this.title, required this.description, required this.queuedAt, required this.status, required this.sentAt, required this.icon});
  final String title;
  final String description;
  final DateTime queuedAt;
  final String status;
  final DateTime? sentAt;
  final IconData icon;
}
