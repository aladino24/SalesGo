import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../app/widgets/sfa_ui.dart';
import '../../core/storage/sync_storage.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  Future<List<_NotificationItem>> _load() async {
    final items = <_NotificationItem>[];
    final stats = SyncStorage.getSyncStats();
    final pendingSync = (stats['pending'] ?? 0) + (stats['failed'] ?? 0);
    if (pendingSync > 0) items.add(_NotificationItem(icon: Icons.sync_rounded, title: 'Sinkronisasi menunggu', message: '$pendingSync transaksi perlu disinkronkan.', color: Colors.blue));
    final approvalBox = Hive.isBoxOpen('approvals_cache') ? Hive.box('approvals_cache') : await Hive.openBox('approvals_cache');
    final approvals = approvalBox.values.whereType<Map>().where((item) => item['status'] == 'Pending' || item['status'] == 'Waiting Approval').length;
    if (approvals > 0) items.add(_NotificationItem(icon: Icons.approval_rounded, title: 'Approval menunggu tindakan', message: '$approvals approval masih menunggu keputusan.', color: Colors.orange));
    final visitsBox = Hive.isBoxOpen('visits') ? Hive.box('visits') : await Hive.openBox('visits');
    final activeVisits = visitsBox.values.whereType<Map>().where((item) => item['status'] == 'In Progress').toList();
    for (final visit in activeVisits) { items.add(_NotificationItem(icon: Icons.location_on_rounded, title: 'Kunjungan sedang berlangsung', message: 'Check-out ${visit['outletName'] ?? 'outlet'} ketika aktivitas selesai.', color: Colors.green)); }
    return items;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Notifikasi', style: TextStyle(fontWeight: FontWeight.w800))),
    body: FutureBuilder<List<_NotificationItem>>(
      future: _load(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
        final items = snapshot.data ?? [];
        if (items.isEmpty) return const SfaEmptyState(icon: Icons.notifications_none_rounded, title: 'Belum ada notifikasi', description: 'Notifikasi sync, approval, dan kunjungan akan tampil di sini.');
        return ListView.separated(itemCount: items.length, separatorBuilder: (_, __) => const Divider(height: 1), itemBuilder: (_, index) { final item = items[index]; return ListTile(leading: CircleAvatar(backgroundColor: item.color.withValues(alpha: .12), child: Icon(item.icon, color: item.color)), title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Text(item.message)); });
      },
    ),
  );
}

class _NotificationItem {
  const _NotificationItem({required this.icon, required this.title, required this.message, required this.color});
  final IconData icon;
  final String title, message;
  final Color color;
}
