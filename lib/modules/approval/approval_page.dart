import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/widgets/sfa_ui.dart';
import 'approval_controller.dart';

class ApprovalPage extends GetView<ApprovalController> {
  const ApprovalPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Approval Center')),
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.approvals.isEmpty) {
            return SfaEmptyState(icon: Icons.approval_outlined, title: 'Tidak ada approval', description: 'Tidak ada item yang menunggu tindakan untuk role Anda.', actionLabel: 'Muat ulang', onAction: controller.loadPendingApprovals);
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: controller.approvals.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = controller.approvals[index];
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
                              onPressed: () => controller.reject(item.id),
                              child: const Text('Reject'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: () => controller.approve(item.id),
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
