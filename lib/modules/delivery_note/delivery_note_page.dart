import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../../app/theme/app_colors.dart';
import '../../app/widgets/sfa_ui.dart';
import '../../app/widgets/sfa_feedback_dialog.dart';
import '../../data/models/delivery_note_model.dart';
import '../../data/repositories/delivery_note_repository.dart';
import '../../data/repositories/master_repository.dart';
import '../../core/network/network_info.dart';

class DeliveryNotePage extends StatefulWidget {
  const DeliveryNotePage({super.key});
  @override
  State<DeliveryNotePage> createState() => _DeliveryNotePageState();
}

class _DeliveryNotePageState extends State<DeliveryNotePage> {
  final _repository = DeliveryNoteRepository();
  List<DeliveryNoteModel> _items = [];
  bool _loading = true;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _items = await _repository.all();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _create() async {
    final number = TextEditingController();
    final destination = TextEditingController();
    final products = await MasterRepository().getProducts(isOnline: await Get.find<NetworkInfo>().isConnected);
    if (products.isEmpty) {
      await SfaFeedbackDialog.show(type: SfaFeedbackType.warning, title: 'Produk belum tersedia', message: 'Unduh data master produk terlebih dahulu sebelum membuat surat jalan.');
      number.dispose();
      destination.dispose();
      return;
    }
    String productId = products.first.id;
    final result = await Get.dialog<bool>(
      StatefulBuilder(builder: (context, setDialogState) => AlertDialog(
        title: const Text('Buat Surat Jalan'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: number,
                decoration: const InputDecoration(
                  labelText: 'Nomor surat jalan',
                ),
              ),
              TextField(
                controller: destination,
                decoration: const InputDecoration(labelText: 'Tujuan / Outlet'),
              ),
              DropdownButtonFormField<String>(
                value: productId,
                decoration: const InputDecoration(labelText: 'Produk'),
                items: products.map((item) => DropdownMenuItem(value: item.id, child: Text(item.name))).toList(),
                onChanged: (value) => setDialogState(() => productId = value ?? productId),
              ),
            ],
          ),
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
      )),
    );
    if (result == true &&
        number.text.trim().isNotEmpty &&
        destination.text.trim().isNotEmpty) {
      const uuid = Uuid();
      await _repository.create(
        DeliveryNoteModel(
          id: uuid.v4(),
          number: number.text.trim(),
          destination: destination.text.trim(),
          items: [
            {
              'productId': productId,
              'quantity': 1,
            },
          ],
          status: 'Draft',
          approvalStatus: 'Waiting Approval',
          createdAt: DateTime.now(),
        ),
      );
      await _load();
      await SfaFeedbackDialog.show(type: SfaFeedbackType.success, title: 'Surat jalan dibuat', message: 'Data dikirim ke server atau masuk antrean sync saat offline.');
    }
    number.dispose();
    destination.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text(
        'Surat Jalan',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _create,
      icon: const Icon(Icons.add),
      label: const Text('Buat'),
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _items.isEmpty
        ? SfaEmptyState(
            icon: Icons.local_shipping_outlined,
            title: 'Belum ada surat jalan',
            description:
                'Buat surat jalan untuk membawa barang dalam perjalanan.',
            actionLabel: 'Buat Surat Jalan',
            onAction: _create,
          )
        : RefreshIndicator(
            onRefresh: _load,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, index) {
                final item = _items[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.number,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            SfaStatusChip(
                              label: item.status,
                              color: item.status == 'Completed'
                                  ? AppColors.success
                                  : AppColors.primary,
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(item.destination),
                        const SizedBox(height: 5),
                        Text(
                          '${item.items.length} barang • Approval: ${item.approvalStatus}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (item.status == 'Draft')
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: () => _change(item, 'Submitted'),
                              child: const Text('Ajukan Approval'),
                            ),
                          )
                        else if (item.status == 'Approved')
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () => _change(item, 'Completed'),
                              child: const Text('Tandai Digunakan'),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
  );
  Future<void> _change(DeliveryNoteModel item, String status) async {
    await _repository.changeStatus(item, status);
    await _load();
  }
}
