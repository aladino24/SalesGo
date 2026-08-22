import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import '../../app/widgets/sfa_ui.dart';
import '../../app/widgets/sfa_feedback_dialog.dart';
import '../../app/routes/app_routes.dart';
import '../../data/models/journey_model.dart';
import '../visit/visit_controller.dart';
import 'journey_controller.dart';

class JourneyPage extends GetView<JourneyController> {
  const JourneyPage({super.key});

  Future<void> _createJourney(BuildContext context, bool outOfTown) async {
    final destination = TextEditingController();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(
        start: DateTime.now(),
        end: DateTime.now(),
      ),
      helpText: 'Pilih rentang perjalanan',
    );
    if (range == null) {
      destination.dispose();
      return;
    }
    final result = await Get.dialog<bool>(
      AlertDialog(
        title: Text(
          outOfTown ? 'Perjalanan Luar Kota' : 'Perjalanan Dalam Kota',
        ),
        content: TextField(
          controller: destination,
          decoration: const InputDecoration(labelText: 'Tujuan perjalanan'),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (result == true && destination.text.trim().isNotEmpty) {
      const uuid = Uuid();
      final now = DateTime.now();
      try {
        await controller.create(JourneyModel(
          id: uuid.v4(), type: outOfTown ? 'out_of_town' : 'in_city',
          destination: destination.text.trim(), startAt: range.start, endAt: outOfTown ? range.end : range.start,
          status: 'Planned', createdAt: now,
        ));
      } catch (error) {
        await SfaFeedbackDialog.show(
          type: SfaFeedbackType.error,
          title: 'Perjalanan belum dibuat',
          message: error.toString().replaceFirst('Exception: ', ''),
        );
      }
    }
    destination.dispose();
  }

  Future<void> _startJourney(JourneyModel item) async {
    try {
      await controller.start(item);
      if (Get.isRegistered<VisitController>()) await Get.find<VisitController>().loadVisits();
      await Get.dialog(AlertDialog(
        title: const Text('Perjalanan dimulai'),
        content: const Text('Rencana kunjungan telah diunduh dan disimpan untuk digunakan offline.'),
        actions: [FilledButton(onPressed: () => Get.offNamed(AppRoutes.visit), child: const Text('Lihat Kunjungan'))],
      ));
    } catch (error) {
      await SfaFeedbackDialog.show(
        type: SfaFeedbackType.error,
        title: 'Perjalanan belum dapat dimulai',
        message: error.toString().replaceFirst('Bad state: ', ''),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text(
        'Perjalanan Sales',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () => _createJourney(context, false),
      icon: const Icon(Icons.add),
      label: const Text('Buat perjalanan'),
    ),
    body: Obx(() {
      if (controller.isLoading.value && controller.journeys.isEmpty)
        return const Center(child: CircularProgressIndicator());
      if (controller.journeys.isEmpty) {
        return SfaEmptyState(
          icon: Icons.route_outlined,
          title: 'Belum ada perjalanan',
          description:
              'Buat perjalanan dalam atau luar kota. Data akan dimuat dari server saat online.',
          actionLabel: 'Buat perjalanan',
          onAction: () => _createJourney(context, false),
        );
      }
      return RefreshIndicator(
        onRefresh: controller.load,
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: controller.journeys.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, index) {
            final item = controller.journeys[index];
            final period =
                '${item.startAt.day.toString().padLeft(2, '0')}/${item.startAt.month.toString().padLeft(2, '0')}/${item.startAt.year} - ${item.endAt.day.toString().padLeft(2, '0')}/${item.endAt.month.toString().padLeft(2, '0')}/${item.endAt.year}';
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(child: Icon(Icons.route_rounded)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.destination,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                item.type == 'out_of_town'
                                    ? 'Perjalanan luar kota'
                                    : 'Perjalanan dalam kota',
                                style: const TextStyle(fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        SfaStatusChip(label: item.status),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primaryContainer.withValues(alpha: .35),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.date_range_outlined, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Periode perjalanan\n$period',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (item.approvalStatus != 'Not Required')
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Approval: ${item.approvalStatus}',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                    const SizedBox(height: 12),
                    if (item.status == 'Planned')
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed:
                              item.type == 'out_of_town' &&
                                  item.approvalStatus != 'Approved'
                              ? null
                              : () => _startJourney(item),
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: const Text('Mulai Perjalanan'),
                        ),
                      ),
                    if (item.status == 'Active')
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              controller.changeStatus(item, 'Completed'),
                          icon: const Icon(Icons.stop_circle_outlined),
                          label: const Text('Akhiri Perjalanan'),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    }),
  );
}
