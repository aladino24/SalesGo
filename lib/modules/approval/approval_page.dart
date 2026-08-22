import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/theme/app_colors.dart';
import '../../app/widgets/sfa_ui.dart';
import 'approval_controller.dart';
import 'approval_model.dart';

class ApprovalPage extends GetView<ApprovalController> {
  const ApprovalPage({super.key});

  Future<void> _decide(ApprovalModel item, bool approved) async {
    final comment = TextEditingController();
    try {
      if (!approved) {
        final confirmed = await Get.dialog<bool>(
          AlertDialog(
            title: const Text('Tolak pengajuan'),
            content: TextField(
              controller: comment,
              minLines: 2,
              maxLines: 4,
              maxLength: 500,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Alasan penolakan *',
                hintText: 'Jelaskan alasan agar pemohon dapat menindaklanjuti.',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                child: const Text('Batal'),
              ),
              FilledButton(
                onPressed: () => Get.back(result: true),
                child: const Text('Tolak'),
              ),
            ],
          ),
        );
        if (confirmed != true || comment.text.trim().isEmpty) return;
      }
      await controller.decide(
        item.id,
        approved: approved,
        comment: comment.text.trim().isEmpty ? null : comment.text.trim(),
      );
    } finally {
      comment.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Approval Outlet', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.approvals.isEmpty) {
            return SfaEmptyState(icon: Icons.approval_outlined, title: 'Tidak ada approval', description: 'Tidak ada item yang menunggu tindakan untuk role Anda.', actionLabel: 'Muat ulang', onAction: controller.loadPendingApprovals);
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
            itemCount: controller.approvals.length + 1,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              if (index == 0) {
                final outletCount = controller.approvals
                    .where((item) => item.type == 'new_outlet')
                    .length;
                return Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      colors: [AppColors.primaryDark, AppColors.primary],
                    ),
                  ),
                  child: Row(children: [
                    const CircleAvatar(
                      backgroundColor: Colors.white24,
                      child: Icon(Icons.approval_rounded, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Menunggu keputusan', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      Text('$outletCount pengajuan outlet baru', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17)),
                    ])),
                  ]),
                );
              }
              final item = controller.approvals[index - 1];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${item.type} • ${item.entityId}',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Chip(label: Text(item.status)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Requested by: ${item.requestedBy}'),
                      const SizedBox(height: 4),
                      Text('Reason: ${item.reason}'),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _decide(item, false),
                              child: const Text('Reject'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: () => _decide(item, true),
                              child: const Text('Approve'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
