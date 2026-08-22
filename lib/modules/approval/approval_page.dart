import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

import '../../app/theme/app_colors.dart';
import '../../app/widgets/sfa_open_street_map.dart';
import '../../app/widgets/sfa_ui.dart';
import '../../core/auth/session_service.dart';
import '../../core/network/api_config.dart';
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

  void _openDetail(ApprovalModel item) {
    final outlet = item.outlet;
    if (outlet == null) return;
    final latitude = (outlet['latitude'] as num?)?.toDouble() ?? 0;
    final longitude = (outlet['longitude'] as num?)?.toDouble() ?? 0;
    final attachmentId = outlet['photoAttachmentId']?.toString();
    final photoUrl = attachmentId == null || attachmentId.isEmpty
        ? outlet['photoUrl']?.toString()
        : '$baseUrl/attachments/$attachmentId/content';
    final token = Get.find<SessionService>().accessToken.value;
    Get.bottomSheet(
      SafeArea(child: Container(
        constraints: BoxConstraints(maxHeight: Get.height * .88),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: ListView(children: [
          Center(child: Container(width: 42, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(4)))),
          const SizedBox(height: 16), Text(outlet['name']?.toString() ?? 'Outlet', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4), Text(outlet['code']?.toString() ?? '-', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          if (photoUrl != null && photoUrl.isNotEmpty) ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.network(photoUrl, height: 190, width: double.infinity, fit: BoxFit.cover, headers: {'Authorization': 'Bearer $token'}, errorBuilder: (_, __, ___) => _PhotoPlaceholder())),
          if (photoUrl == null || photoUrl.isEmpty) const _PhotoPlaceholder(),
          const SizedBox(height: 18), const Text('Ringkasan pengajuan', style: TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 8),
          _DetailRow('Diajukan oleh', '${item.requestedBy}${item.requestedByRole == null ? '' : ' • ${item.requestedByRole}'}'),
          _DetailRow('Tipe outlet', outlet['type']?.toString() ?? '-'), _DetailRow('Pemilik', outlet['ownerName']?.toString() ?? '-'), _DetailRow('Kontak', outlet['contactName']?.toString() ?? '-'), _DetailRow('Telepon', outlet['phone']?.toString() ?? '-'), _DetailRow('Alamat', outlet['address']?.toString() ?? '-'),
          const SizedBox(height: 16), const Text('Titik lokasi outlet', style: TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 8),
          SizedBox(height: 180, child: SfaOpenStreetMap(center: LatLng(latitude, longitude), zoom: 16, markers: [SfaMapMarker(point: LatLng(latitude, longitude), label: 'Outlet', color: AppColors.primary)])),
          const SizedBox(height: 8), Text('${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ]),
      )),
      isScrollControlled: true,
    );
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
                      Text('Diajukan oleh: ${item.requestedBy}${item.requestedByRole == null ? '' : ' • ${item.requestedByRole}'}'),
                      if (item.outlet != null) ...[
                        const SizedBox(height: 8),
                        TextButton.icon(onPressed: () => _openDetail(item), icon: const Icon(Icons.visibility_outlined), label: const Text('Lihat ringkasan & lokasi')),
                      ] else
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

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder();

  @override
  Widget build(BuildContext context) => Container(height: 150, color: AppColors.primarySoft, alignment: Alignment.center, child: const Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.storefront_outlined, color: AppColors.primary, size: 38), SizedBox(height: 8), Text('Foto toko belum dapat dimuat', style: TextStyle(fontSize: 12, color: AppColors.textSecondary))]));
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);
  final String label, value;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [SizedBox(width: 106, child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))), Expanded(child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)))]));
}
