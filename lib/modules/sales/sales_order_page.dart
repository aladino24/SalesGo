import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';


import '../../app/theme/app_colors.dart';
import '../../data/models/outlet_model.dart';
import '../../data/models/sales_order_model.dart';
import '../../data/repositories/sales_order_repository.dart';

class SalesOrderPage extends StatefulWidget {
  const SalesOrderPage({super.key, required this.outlet});
  final OutletModel outlet;
  @override
  State<SalesOrderPage> createState() => _SalesOrderPageState();
}

class _SalesOrderPageState extends State<SalesOrderPage> {
  final _product = TextEditingController(),
      _quantity = TextEditingController(text: '1'),
      _price = TextEditingController(text: '0');
  final _repository = SalesOrderRepository();
  bool saving = false;
  double get total =>
      (double.tryParse(_price.text) ?? 0) * (int.tryParse(_quantity.text) ?? 0);
  @override
  void dispose() {
    _product.dispose();
    _quantity.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final quantity = int.tryParse(_quantity.text) ?? 0;
    final price = double.tryParse(_price.text) ?? 0;
    if (_product.text.trim().isEmpty || quantity < 1 || price <= 0) {
      Get.snackbar(
        'Order belum lengkap',
        'Isi produk, quantity, dan harga yang valid.',
      );
      return;
    }
    setState(() => saving = true);
    const uuid = Uuid();
    final order = SalesOrderModel(
      id: 'SO-${uuid.v4()}',
      outletName: widget.outlet.name,
      total: total,
      status: 'Pending Sync',
      createdAt: DateTime.now(),
    );
    await _repository.create(
      order,
      productName: _product.text.trim(),
      quantity: quantity,
      unitPrice: price,
    );
    if (!mounted) return;
    setState(() => saving = false);
    Get.back(result: order);
    Get.snackbar(
      'Order disimpan',
      'Order tersimpan lokal dan akan disinkronkan otomatis.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text(
        'Buat Order',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
    ),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.storefront_rounded),
              ),
              title: Text(
                widget.outlet.name,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(widget.outlet.address),
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _product,
            decoration: const InputDecoration(
              labelText: 'Produk',
              prefixIcon: Icon(Icons.inventory_2_rounded),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _quantity,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(labelText: 'Quantity'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _price,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(labelText: 'Harga Satuan'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text(
                    'Total Order',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  Text(
                    'Rp ${total.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: saving ? null : _submit,
            child: saving
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Simpan Order'),
          ),
        ],
      ),
    ),
  );
}
