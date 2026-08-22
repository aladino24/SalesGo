import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/theme/app_colors.dart';
import '../../app/widgets/sfa_ui.dart';
import '../../app/widgets/sfa_feedback_dialog.dart';
import 'report_controller.dart';

class ReportPage extends GetView<ReportController> {
  const ReportPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text(
        'Laporan Cabang',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
      actions: [
        if (controller.isAllowed)
          PopupMenuButton<bool>(
            icon: const Icon(Icons.download_rounded),
            onSelected: (ownOnly) async {
              try {
                final path = await controller.downloadVisitCsv(ownOnly: ownOnly);
                await SfaFeedbackDialog.show(
                  type: SfaFeedbackType.success,
                  title: 'CSV berhasil diunduh',
                  message: 'File disimpan di perangkat. Anda dapat membukanya sekarang atau dari pengelola file.',
                  detail: path,
                  actionLabel: 'Buka CSV',
                  onAction: () => controller.openDownloadedFile(path),
                );
              } catch (error) {
                await SfaFeedbackDialog.show(type: SfaFeedbackType.error, title: 'Unduhan gagal', message: error.toString());
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: true, child: Text('CSV kunjungan saya')),
              PopupMenuItem(value: false, child: Text('CSV kunjungan tim/cabang')),
            ],
          ),
      ],
    ),
    body: SafeArea(
      child: Obx(() {
        if (!controller.isAllowed)
          return const SfaEmptyState(
            icon: Icons.lock_outline_rounded,
            title: 'Akses terbatas',
            description:
                'Laporan cabang hanya tersedia untuk Supervisor dan Branch Manager.',
          );
        final data = controller.report.value;
        final rows = data['rows'];
        final items = rows is List
            ? rows
                  .whereType<Map>()
                  .map((item) => Map<String, dynamic>.from(item))
                  .toList()
            : <Map<String, dynamic>>[];
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'revenue', label: Text('Omset')),
                  ButtonSegment(value: 'visits', label: Text('Visit')),
                  ButtonSegment(
                    value: 'transactions',
                    label: Text('Transaksi'),
                  ),
                ],
                selected: {controller.selectedType.value},
                onSelectionChanged: (value) =>
                    controller.changeType(value.first),
              ),
            ),
            if (controller.isLoading.value && items.isEmpty)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else
              Expanded(
                child: items.isEmpty
                    ? const SfaEmptyState(
                        icon: Icons.description_outlined,
                        title: 'Belum ada laporan',
                        description:
                            'Ringkasan laporan akan tersedia setelah data diterima dari server.',
                      )
                    : RefreshIndicator(
                        onRefresh: controller.load,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          itemCount: items.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (_, index) {
                            final item = items[index];
                            return Card(
                              child: ListTile(
                                leading: const CircleAvatar(
                                  backgroundColor: AppColors.primarySoft,
                                  child: Icon(
                                    Icons.assessment_outlined,
                                    color: AppColors.primary,
                                  ),
                                ),
                                title: Text(
                                  item['label']?.toString() ??
                                      item['salesName']?.toString() ??
                                      '-',
                                ),
                                subtitle: Text(
                                  item['subtitle']?.toString() ??
                                      'Periode berjalan',
                                ),
                                trailing: Text(
                                  (item['value'] ??
                                          item['revenue'] ??
                                          item['count'] ??
                                          0)
                                      .toString(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ),
          ],
        );
      }),
    ),
  );
}
