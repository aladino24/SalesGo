import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import '../../app/widgets/sfa_ui.dart';
import '../../data/models/journey_model.dart';
import 'journey_controller.dart';

class JourneyPage extends GetView<JourneyController> {
  const JourneyPage({super.key});

  Future<void> _createJourney(BuildContext context, bool outOfTown) async {
    final destination = TextEditingController();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(start: DateTime.now(), end: DateTime.now()),
      helpText: 'Pilih rentang perjalanan',
    );
    if (range == null) {
      destination.dispose();
      return;
    }
    final result = await Get.dialog<bool>(AlertDialog(
      title: Text(outOfTown ? 'Perjalanan Luar Kota' : 'Perjalanan Dalam Kota'),
      content: TextField(
        controller: destination,
        decoration: const InputDecoration(labelText: 'Tujuan perjalanan'),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(result: false), child: const Text('Batal')),
        FilledButton(onPressed: () => Get.back(result: true), child: const Text('Simpan')),
      ],
    ));
    if (result == true && destination.text.trim().isNotEmpty) {
      const uuid = Uuid();
      final now = DateTime.now();
      await controller.create(JourneyModel(
        id: uuid.v4(), type: outOfTown ? 'out_of_town' : 'in_city',
        destination: destination.text.trim(), startAt: range.start, endAt: outOfTown ? range.end : range.start,
        status: 'Planned', createdAt: now,
      ));
    }
    destination.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Perjalanan Sales', style: TextStyle(fontWeight: FontWeight.w800))),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () => _createJourney(context, false), icon: const Icon(Icons.add), label: const Text('Buat perjalanan'),
    ),
    body: Obx(() {
      if (controller.isLoading.value && controller.journeys.isEmpty) return const Center(child: CircularProgressIndicator());
      if (controller.journeys.isEmpty) {
        return SfaEmptyState(
          icon: Icons.route_outlined, title: 'Belum ada perjalanan',
          description: 'Buat perjalanan dalam atau luar kota. Data akan dimuat dari server saat online.',
          actionLabel: 'Buat perjalanan', onAction: () => _createJourney(context, false),
        );
      }
      return RefreshIndicator(
        onRefresh: controller.load,
        child: ListView.separated(
          padding: const EdgeInsets.all(16), itemCount: controller.journeys.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, index) {
            final item = controller.journeys[index];
            return Card(child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.route_rounded)),
              title: Text(item.destination, style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text('${item.type == 'out_of_town' ? 'Luar kota' : 'Dalam kota'} • ${item.approvalStatus}'),
              trailing: SizedBox(
                width: 82,
                child: item.status == 'Planned'
                    ? FilledButton(
                        onPressed: item.type == 'out_of_town' && item.approvalStatus != 'Approved' ? null : () => controller.start(item),
                        child: const Text('Mulai'),
                      )
                    : item.status == 'Active'
                        ? FilledButton(onPressed: () => controller.changeStatus(item, 'Completed'), child: const Text('Selesai'))
                        : Center(child: SfaStatusChip(label: item.status)),
              ),
            ));
          },
        ),
      );
    }),
  );
}
