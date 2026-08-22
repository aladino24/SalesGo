import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../app/theme/app_colors.dart';
import '../../app/widgets/sfa_ui.dart';
import '../../core/sync/sync_manager.dart';
import '../../core/localization/app_locale.dart';
import '../../data/datasources/local/visit_local_data_source.dart';

class ActivityPage extends StatefulWidget {
  const ActivityPage({super.key});

  @override
  State<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> {
  late Future<List<_ActivityItem>> _future;
  final _search = TextEditingController();
  var _query = '';

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<void> _refresh() async {
    final future = _load();
    setState(() {
      _future = future;
    });
    await future;
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<List<_ActivityItem>> _load() async {
    final results = <_ActivityItem>[];
    final queueBox = Hive.isBoxOpen('sync_queue_box')
        ? Hive.box('sync_queue_box')
        : await Hive.openBox('sync_queue_box');
    final visitSyncStatus = <String, String>{};
    for (final raw in queueBox.values.whereType<Map>()) {
      final item = Map<String, dynamic>.from(raw);
      final payload = item['payload'];
      if (payload is! Map) continue;
      final visitId = payload['visitId']?.toString();
      if (visitId == null || visitId.isEmpty) continue;
      visitSyncStatus[visitId] = item['status']?.toString() ?? 'pending';
    }
    final journeyBox = Hive.isBoxOpen('journey_activities') ? Hive.box('journey_activities') : await Hive.openBox('journey_activities');
    for (final raw in journeyBox.values.whereType<Map>()) {
      final item = Map<String, dynamic>.from(raw);
      final at = DateTime.tryParse(item['createdAt']?.toString() ?? '');
      if (at != null) results.add(_ActivityItem(title: item['event']?.toString() ?? 'Perjalanan', description: item['description']?.toString() ?? 'Perjalanan sales', queuedAt: at, status: 'Terkirim', sentAt: at, icon: Icons.route_rounded));
    }
    for (final visit in await VisitLocalDataSource().getVisits()) {
      final queueStatus = visitSyncStatus[visit.id];
      final syncState = queueStatus == null && visit.status == 'Planned'
          ? ('Terjadwal', visit.createdAt)
          : switch (queueStatus) {
              'pending' => ('Pending', null),
              'syncing' => ('Mengirim', null),
              'failed' => ('Gagal', null),
              'conflict' => ('Konflik', null),
              'blocked' => ('Diblokir', null),
              _ => ('Terkirim', visit.createdAt),
            };
      results.add(_ActivityItem(title: 'Kunjungan ${visit.status}', description: visit.outletName, queuedAt: visit.createdAt, status: syncState.$1, sentAt: syncState.$2, icon: Icons.location_on_rounded));
    }
    final auditBox = Hive.isBoxOpen('sync_audit_log') ? Hive.box('sync_audit_log') : await Hive.openBox('sync_audit_log');
    final latestAudits = <String, Map<String, dynamic>>{};
    for (final raw in auditBox.values.whereType<Map>()) {
      final item = Map<String, dynamic>.from(raw);
      final key = item['syncItemId']?.toString() ?? item['id']?.toString() ?? '';
      final existing = latestAudits[key];
      final at = DateTime.tryParse(item['createdAt']?.toString() ?? '');
      final existingAt = DateTime.tryParse(existing?['createdAt']?.toString() ?? '');
      if (existing == null || (at != null && (existingAt == null || at.isAfter(existingAt)))) {
        latestAudits[key] = item;
      }
    }
    for (final item in latestAudits.values) {
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
        final allItems = snapshot.data ?? <_ActivityItem>[];
        final items = allItems
            .where(
              (item) =>
                  _query.isEmpty ||
                  item.title.toLowerCase().contains(_query) ||
                  item.description.toLowerCase().contains(_query),
            )
            .toList();
        return Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _search,
              onChanged: (value) =>
                  setState(() => _query = value.trim().toLowerCase()),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search_rounded),
                hintText: 'Cari aktivitas',
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _search.clear();
                          setState(() => _query = '');
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
            ),
          ),
          Expanded(child: RefreshIndicator(
          onRefresh: _refresh,
          child: allItems.isEmpty
              ? ListView(children: const [
                  SizedBox(height: 160),
                  SfaEmptyState(icon: Icons.history_outlined, title: 'Belum ada aktivitas', description: 'Kunjungan, perjalanan, dan proses sinkronisasi akan tampil di sini.'),
                ])
              : items.isEmpty
                  ? ListView(children: const [
                      SizedBox(height: 120),
                      SfaEmptyState(icon: Icons.search_off_rounded, title: 'Aktivitas tidak ditemukan', description: 'Ubah kata kunci atau hapus pencarian untuk melihat seluruh aktivitas.'),
                    ])
                  : ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              if (index == 0) return OutlinedButton.icon(onPressed: () async { await Get.find<SyncManager>().syncNow(force: true); await _refresh(); }, icon: const Icon(Icons.sync_rounded), label: const Text('Coba kirim semua aktivitas pending'));
              final item = items[index - 1];
              final color = switch (item.status) {
                'Terkirim' => AppColors.success,
                'Gagal' || 'Retry' || 'Konflik' || 'Diblokir' => AppColors.danger,
                _ => AppColors.warning,
              };
              return Card(child: ListTile(
                leading: CircleAvatar(backgroundColor: color.withValues(alpha: .12), child: Icon(item.icon, color: color)),
                title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text('${item.description}\nMasuk antrean: ${AppLocale.date('dd MMM y, HH:mm').format(item.queuedAt.toLocal())}${item.sentAt == null ? '' : '\nTerkirim: ${AppLocale.date('dd MMM y, HH:mm').format(item.sentAt!.toLocal())}'}'),
                isThreeLine: true,
                trailing: SfaStatusChip(label: item.status, color: color),
              ));
            },
          ),
        ))]);
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
