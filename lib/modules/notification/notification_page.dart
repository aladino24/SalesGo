import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/theme/app_colors.dart';
import '../../app/widgets/sfa_ui.dart';
import '../../core/localization/app_locale.dart';
import '../../data/models/app_notification_model.dart';
import 'notification_controller.dart';

class NotificationPage extends GetView<NotificationController> {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Notifikasi', style: TextStyle(fontWeight: FontWeight.w800)),
          actions: [
            Obx(() => controller.unreadCount == 0
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Center(child: SfaStatusChip(label: '${controller.unreadCount} baru', color: AppColors.primary)),
                  )),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
              child: Obx(() => SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: false, label: Text('Semua')),
                      ButtonSegment(value: true, label: Text('Belum dibaca')),
                    ],
                    selected: {controller.unreadOnly.value},
                    onSelectionChanged: (value) => controller.unreadOnly.value = value.first,
                  )),
            ),
            Expanded(child: Obx(() {
              final items = controller.visibleItems;
              if (controller.isLoading.value && controller.notifications.isEmpty) return const Center(child: CircularProgressIndicator());
              if (items.isEmpty) return SfaEmptyState(
                icon: Icons.notifications_none_rounded,
                title: controller.unreadOnly.value ? 'Tidak ada notifikasi baru' : 'Belum ada notifikasi',
                description: 'Approval, kunjungan, sinkronisasi, dan meeting akan muncul di sini.',
                actionLabel: 'Muat Ulang', onAction: controller.load,
              );
              return RefreshIndicator(
                onRefresh: controller.load,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 9),
                  itemBuilder: (_, index) => _NotificationCard(item: items[index], onTap: () => controller.open(items[index])),
                ),
              );
            })),
          ],
        ),
      );
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.item, required this.onTap});
  final AppNotificationModel item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final style = _styleFor(item.type);
    return Material(
      color: item.isRead ? Colors.white : AppColors.primarySoft.withValues(alpha: .55),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap, borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            CircleAvatar(backgroundColor: style.color.withValues(alpha: .14), child: Icon(style.icon, color: style.color)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(item.title, style: TextStyle(fontWeight: item.isRead ? FontWeight.w600 : FontWeight.w800))),
                if (!item.isRead) Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
              ]),
              const SizedBox(height: 4),
              Text(item.message, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              Text(_formatTime(item.createdAt), style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
            ])),
            if (item.deepLink != null && item.deepLink!.isNotEmpty) ...[const SizedBox(width: 4), const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary)],
          ]),
        ),
      ),
    );
  }

  _NotificationStyle _styleFor(String type) {
    switch (type.toLowerCase()) {
      case 'approval': case 'approval_decision': return const _NotificationStyle(Icons.approval_rounded, AppColors.warning);
      case 'visit': return const _NotificationStyle(Icons.location_on_rounded, AppColors.success);
      case 'journey': return const _NotificationStyle(Icons.route_rounded, Color(0xFF7258EF));
      case 'meeting': return const _NotificationStyle(Icons.videocam_rounded, AppColors.primary);
      case 'sync': return const _NotificationStyle(Icons.sync_rounded, AppColors.primary);
      default: return const _NotificationStyle(Icons.notifications_rounded, AppColors.primary);
    }
  }

  String _formatTime(DateTime value) {
    final now = DateTime.now(); final local = value.toLocal(); final diff = now.difference(local);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24 && now.day == local.day) return '${diff.inHours} jam lalu';
    return AppLocale.date('d MMM y, HH:mm').format(local);
  }
}

class _NotificationStyle {
  const _NotificationStyle(this.icon, this.color);
  final IconData icon;
  final Color color;
}
