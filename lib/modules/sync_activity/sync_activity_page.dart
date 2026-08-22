import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

import '../../app/theme/app_colors.dart';
import '../../app/widgets/sfa_ui.dart';
import '../../core/sync/sync_manager.dart';

class SyncActivityPage extends StatelessWidget {
  const SyncActivityPage({super.key});

  Future<List<Map<String, dynamic>>> _load() async {
    final box = Hive.isBoxOpen('sync_audit_log')
        ? Hive.box('sync_audit_log')
        : await Hive.openBox('sync_audit_log');
    final records = box.values
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
    records.sort((a, b) => (b['createdAt']?.toString() ?? '')
        .compareTo(a['createdAt']?.toString() ?? ''));
    return records;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Aktivitas Sinkronisasi')),
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: _load(),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            final records = snapshot.data ?? [];
            if (records.isEmpty) {
              return const SfaEmptyState(
                icon: Icons.sync_outlined,
                title: 'Belum ada aktivitas sync',
                description: 'Upload dan pengiriman data akan tampil di sini.',
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: records.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return FilledButton.icon(
                    onPressed: () async {
                      await Get.find<SyncManager>().syncNow(force: true);
                      Get.forceAppUpdate();
                    },
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Coba Sinkronkan Sekarang'),
                  );
                }
                final item = records[index - 1];
                final event = item['event']?.toString() ?? 'pending';
                final sent = event == 'sync_succeeded';
                final failed = event.contains('retry') ||
                    event.contains('blocked') ||
                    event.contains('conflict');
                final color = sent
                    ? AppColors.success
                    : failed
                        ? AppColors.danger
                        : AppColors.warning;
                final time = DateTime.tryParse(item['createdAt']?.toString() ?? '');
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: color.withValues(alpha: .12),
                      child: Icon(
                        sent
                            ? Icons.cloud_done_rounded
                            : failed
                                ? Icons.sync_problem_rounded
                                : Icons.schedule_rounded,
                        color: color,
                      ),
                    ),
                    title: Text(
                      sent
                          ? 'Terkirim ke server'
                          : failed
                              ? 'Menunggu retry'
                              : 'Pending sinkronisasi',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      '${item['type'] ?? 'Aktivitas'}${item['message'] == null ? '' : '\n${item['message']}'}',
                    ),
                    isThreeLine: item['message'] != null,
                    trailing: Text(
                      time == null
                          ? '-'
                          : DateFormat('dd MMM HH:mm', 'id').format(time.toLocal()),
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                );
              },
            );
          },
        ),
      );
}
