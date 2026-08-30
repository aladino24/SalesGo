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

  void _openPhotoOverlay({
    required String photoUrl,
    required String token,
    required String outletName,
  }) {
    Get.dialog(
      Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 4,
                  child: Image.network(
                    photoUrl,
                    fit: BoxFit.contain,
                    headers: {'Authorization': 'Bearer $token', 'ngrok-skip-browser-warning': 'true'},
                    loadingBuilder: (context, child, progress) => progress == null
                        ? child
                        : const Center(
                            child: CircularProgressIndicator(color: Colors.white),
                          ),
                    errorBuilder: (_, __, ___) => const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.broken_image_outlined, color: Colors.white, size: 48),
                        SizedBox(height: 12),
                        Text('Foto toko tidak dapat dimuat', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: IconButton.filled(
                  onPressed: Get.back,
                  icon: const Icon(Icons.close),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black54,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              Positioned(
                left: 20,
                right: 20,
                bottom: 18,
                child: Text(
                  outletName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierColor: Colors.black87,
    );
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
          if (photoUrl != null && photoUrl.isNotEmpty) InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _openPhotoOverlay(
              photoUrl: photoUrl,
              token: token,
              outletName: outlet['name']?.toString() ?? 'Foto outlet',
            ),
            child: Stack(
              children: [
                ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.network(photoUrl, height: 190, width: double.infinity, fit: BoxFit.cover, headers: {'Authorization': 'Bearer $token', 'ngrok-skip-browser-warning': 'true'}, errorBuilder: (_, __, ___) => _PhotoPlaceholder())),
                const Positioned(
                  right: 10,
                  bottom: 10,
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.all(Radius.circular(12))),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.zoom_in_rounded, size: 16, color: Colors.white),
                        SizedBox(width: 4),
                        Text('Lihat foto', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                      ]),
                    ),
                  ),
                ),
              ],
            ),
          ),
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

  String _approvalTitle(ApprovalModel item) => switch (item.type) {
        'new_outlet' => 'Approval Outlet Baru',
        'visit_out_of_radius' => 'Override Check-in Luar Radius',
        'delivery_note' => 'Approval Surat Jalan',
        'journey_out_of_town' => 'Approval Perjalanan Luar Kota',
        _ => item.type.replaceAll('_', ' '),
      };

  IconData _approvalIcon(ApprovalModel item) => switch (item.type) {
        'new_outlet' => Icons.storefront_outlined,
        'visit_out_of_radius' => Icons.location_off_outlined,
        'delivery_note' => Icons.local_shipping_outlined,
        'journey_out_of_town' => Icons.route_outlined,
        _ => Icons.approval_outlined,
      };

  void _openVisitOverrideDetail(ApprovalModel item) {
    final visit = item.visit;
    // `outlet` dapat tidak ada pada payload lama. Jangan melakukan chained
    // null-aware index terhadap dynamic karena dapat diparse Dart sebagai
    // ekspresi kondisi, bukan akses Map.
    final nestedOutlet = visit == null ? null : visit['outlet'];
    final outlet = nestedOutlet is Map
        ? Map<String, dynamic>.from(nestedOutlet)
        : const <String, dynamic>{};
    final outletName = (visit == null ? null : visit['outletName'])?.toString() ??
        outlet['name']?.toString() ??
        'Outlet kunjungan';
    final outletCode =
        (visit == null ? null : visit['outletCode'])?.toString() ??
        outlet['code']?.toString() ??
        '-';
    final distance =
        visit == null ? null : visit['distanceMeters'] ?? visit['distanceKm'];
    final attachmentId =
        (visit == null ? null : visit['photoAttachmentId'])?.toString();
    final photoUrl = attachmentId == null || attachmentId.isEmpty
        ? (visit == null ? null : visit['photoUrl'])?.toString()
        : '$baseUrl/attachments/$attachmentId/content';
    final token = Get.find<SessionService>().accessToken.value;
    Get.bottomSheet(
      SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 42, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(4)))),
              const SizedBox(height: 18),
              const Row(children: [
                CircleAvatar(backgroundColor: Color(0xFFFFF3DD), child: Icon(Icons.location_off_outlined, color: AppColors.warning)),
                SizedBox(width: 12),
                Expanded(child: Text('Override Check-in Luar Radius', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
              ]),
              const SizedBox(height: 18),
              _DetailRow('Outlet', outletName),
              _DetailRow('Kode outlet', outletCode),
              _DetailRow('Diajukan oleh', '${item.requestedBy}${item.requestedByRole == null ? '' : ' • ${item.requestedByRole}'}'),
              _DetailRow('Alasan override', item.reason.isEmpty ? '-' : item.reason),
              if (distance != null) _DetailRow('Jarak saat check-in', '$distance meter'),
              _DetailRow('ID kunjungan', item.entityId),
              if (photoUrl != null && photoUrl.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('Foto verifikasi outlet', style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => _openPhotoOverlay(photoUrl: photoUrl, token: token, outletName: outletName),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(photoUrl, height: 180, width: double.infinity, fit: BoxFit.cover, headers: {'Authorization': 'Bearer $token', 'ngrok-skip-browser-warning': 'true'}, errorBuilder: (_, __, ___) => const _PhotoPlaceholder()),
                  ),
                ),
                const SizedBox(height: 4),
                const Text('Ketuk foto untuk melihat detail.', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
              const SizedBox(height: 8),
              const Text('Setujui hanya bila alasan dan kunjungan tersebut dapat dipertanggungjawabkan.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Persetujuan', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(
        child: Obx(() {
          final arguments = Get.arguments;
          final focusedApprovalId = arguments is Map
              ? arguments['approvalId']?.toString()
              : null;
          final notificationTitle = arguments is Map
              ? arguments['notificationTitle']?.toString()
              : null;
          final notificationMessage = arguments is Map
              ? arguments['notificationMessage']?.toString()
              : null;
          final approvals = focusedApprovalId == null || focusedApprovalId.isEmpty
              ? controller.approvals
              : controller.approvals
                  .where((item) => item.id == focusedApprovalId)
                  .toList();
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          if (approvals.isEmpty) {
            return SfaEmptyState(icon: Icons.approval_outlined, title: focusedApprovalId == null ? 'Tidak ada approval' : 'Approval tidak tersedia', description: focusedApprovalId == null ? 'Tidak ada item yang menunggu tindakan untuk role Anda.' : 'Approval dari notifikasi ini sudah diproses atau tidak tersedia lagi.', actionLabel: 'Muat ulang', onAction: controller.loadPendingApprovals);
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
            itemCount: approvals.length + 1,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              if (index == 0) {
                final outletCount = approvals
                    .where((item) => item.type == 'new_outlet')
                    .length;
                final overrideCount = approvals
                    .where((item) => item.type == 'visit_out_of_radius')
                    .length;
                final subtitle = [
                  if (outletCount > 0) '$outletCount outlet baru',
                  if (overrideCount > 0) '$overrideCount override check-in',
                ].join(' • ');
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
                      Text(notificationTitle?.isNotEmpty == true ? notificationTitle! : 'Menunggu keputusan', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      Text(notificationMessage?.isNotEmpty == true ? notificationMessage! : (subtitle.isEmpty ? '${approvals.length} pengajuan menunggu' : subtitle), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                    ])),
                  ]),
                );
              }
              final item = approvals[index - 1];
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
                      Text(
                        _approvalTitle(item),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('Diajukan oleh: ${item.requestedBy}${item.requestedByRole == null ? '' : ' • ${item.requestedByRole}'}'),
                      if (item.outlet != null) ...[
                        const SizedBox(height: 8),
                        TextButton.icon(onPressed: () => _openDetail(item), icon: const Icon(Icons.visibility_outlined), label: const Text('Lihat ringkasan & lokasi')),
                      ] else if (item.type == 'visit_out_of_radius') ...[
                        const SizedBox(height: 8),
                        Text('Alasan: ${item.reason.isEmpty ? '-' : item.reason}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        TextButton.icon(onPressed: () => _openVisitOverrideDetail(item), icon: const Icon(Icons.visibility_outlined), label: const Text('Lihat detail override')),
                      ] else
                        Text('Alasan: ${item.reason}'),
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
