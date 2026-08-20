import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import '../../app/theme/app_colors.dart';
import '../../app/widgets/sfa_ui.dart';
import '../../data/datasources/local/master_local_data_source.dart';
import '../../data/models/outlet_model.dart';
import '../../data/models/product_model.dart';
import '../../data/models/sales_order_model.dart';
import '../../data/repositories/sales_order_repository.dart';

class SalesOrderPage extends StatefulWidget {
  const SalesOrderPage({super.key, required this.outlet});
  final OutletModel outlet;
  @override State<SalesOrderPage> createState() => _SalesOrderPageState();
}

class _SalesOrderPageState extends State<SalesOrderPage> {
  final _repository = SalesOrderRepository();
  final _master = MasterLocalDataSource();
  final _discount = TextEditingController(text: '0');
  final _cart = <SalesOrderItem>[];
  List<ProductModel> _products = [];
  bool _loading = true, _saving = false;
  double get _subtotal => _cart.fold(0, (sum, item) => sum + item.unitPrice * item.quantity);
  double get _lineDiscount => _cart.fold(0, (sum, item) => sum + item.discount);
  double get _discountValue => double.tryParse(_discount.text) ?? 0;
  double get _total => (_subtotal - _lineDiscount - _discountValue).clamp(0, double.infinity).toDouble();

  @override void initState() { super.initState(); _loadProducts(); }
  @override void dispose() { _discount.dispose(); super.dispose(); }
  Future<void> _loadProducts() async { _products = await _master.getProducts(); if (mounted) setState(() => _loading = false); }

  Future<void> _addProduct() async {
    if (_products.isEmpty) { Get.snackbar('Produk belum tersedia', 'Unduh data master produk terlebih dahulu.'); return; }
    final selected = await Get.bottomSheet<ProductModel>(Material(color: Colors.white, borderRadius: const BorderRadius.vertical(top: Radius.circular(20)), child: SafeArea(child: SizedBox(height: 480, child: Column(children: [const ListTile(title: Text('Pilih Produk', style: TextStyle(fontWeight: FontWeight.w800))), Expanded(child: ListView.separated(itemCount: _products.length, separatorBuilder: (_, __) => const Divider(height: 1), itemBuilder: (_, index) { final product = _products[index]; return ListTile(enabled: product.stock > 0, title: Text(product.name), subtitle: Text('Stok ${product.stock} • Rp ${product.price.toStringAsFixed(0)}'), trailing: const Icon(Icons.add_circle_outline), onTap: () => Get.back(result: product)); }))]))));
    if (selected == null) return;
    final quantity = TextEditingController(text: '1');
    final lineDiscount = TextEditingController(text: '0');
    final accepted = await Get.dialog<bool>(AlertDialog(title: Text(selected.name), content: Column(mainAxisSize: MainAxisSize.min, children: [Text('Stok tersedia: ${selected.stock}'), TextField(controller: quantity, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Jumlah')), TextField(controller: lineDiscount, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Diskon item (Rp)'))]), actions: [TextButton(onPressed: () => Get.back(result: false), child: const Text('Batal')), FilledButton(onPressed: () => Get.back(result: true), child: const Text('Tambahkan'))]));
    final qty = int.tryParse(quantity.text) ?? 0;
    if (accepted == true && qty > 0 && qty <= selected.stock) {
      setState(() => _cart.add(SalesOrderItem(productId: selected.id, productName: selected.name, quantity: qty, unitPrice: selected.price, discount: double.tryParse(lineDiscount.text) ?? 0)));
    } else if (accepted == true) { Get.snackbar('Jumlah tidak valid', 'Jumlah maksimal adalah stok tersedia (${selected.stock}).'); }
    quantity.dispose(); lineDiscount.dispose();
  }

  Future<void> _submit() async {
    if (_cart.isEmpty) { Get.snackbar('Cart kosong', 'Tambahkan minimal satu produk.'); return; }
    setState(() => _saving = true);
    const uuid = Uuid();
    final order = SalesOrderModel(id: 'SO-${uuid.v4()}', outletName: widget.outlet.name, items: _cart, total: _total, discount: _lineDiscount + _discountValue, status: 'Pending Sync', createdAt: DateTime.now());
    await _repository.create(order);
    if (!mounted) return;
    setState(() => _saving = false);
    Get.back(result: order);
    Get.snackbar('Order disimpan', 'Cart ${_cart.length} produk tersimpan lokal dan akan disinkronkan.', snackPosition: SnackPosition.BOTTOM);
  }

  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Buat Order', style: TextStyle(fontWeight: FontWeight.w800))),
    bottomNavigationBar: SafeArea(child: Padding(padding: const EdgeInsets.all(16), child: FilledButton(onPressed: _saving ? null : _submit, child: _saving ? const CircularProgressIndicator(color: Colors.white) : Text('Simpan Order • Rp ${_total.toStringAsFixed(0)}')))),
    body: _loading ? const Center(child: CircularProgressIndicator()) : ListView(padding: const EdgeInsets.all(16), children: [
      Card(child: ListTile(leading: const CircleAvatar(child: Icon(Icons.storefront_rounded)), title: Text(widget.outlet.name, style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Text(widget.outlet.address))),
      const SizedBox(height: 18), Row(children: [const Expanded(child: Text('Cart Produk', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16))), TextButton.icon(onPressed: _addProduct, icon: const Icon(Icons.add), label: const Text('Tambah'))]),
      if (_cart.isEmpty) const SfaEmptyState(icon: Icons.shopping_cart_outlined, title: 'Cart masih kosong', description: 'Pilih produk dari master data untuk membuat order.') else ..._cart.asMap().entries.map((entry) { final item = entry.value; return Card(child: ListTile(title: Text(item.productName), subtitle: Text('${item.quantity} × Rp ${item.unitPrice.toStringAsFixed(0)}${item.discount > 0 ? ' • diskon Rp ${item.discount.toStringAsFixed(0)}' : ''}'), trailing: IconButton(icon: const Icon(Icons.delete_outline, color: AppColors.danger), onPressed: () => setState(() => _cart.removeAt(entry.key)))); }),
      const SizedBox(height: 12), TextField(controller: _discount, keyboardType: TextInputType.number, onChanged: (_) => setState(() {}), decoration: const InputDecoration(labelText: 'Diskon order (Rp)', prefixIcon: Icon(Icons.discount_outlined))),
      const SizedBox(height: 14), Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [ _summary('Subtotal', _subtotal), _summary('Diskon', _lineDiscount + _discountValue), const Divider(), _summary('Total', _total, prominent: true) ]))),
    ]),
  );
  Widget _summary(String label, double value, {bool prominent = false}) => Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Row(children: [Text(label, style: TextStyle(fontWeight: prominent ? FontWeight.w800 : FontWeight.w500)), const Spacer(), Text('Rp ${value.toStringAsFixed(0)}', style: TextStyle(color: prominent ? AppColors.primary : AppColors.textPrimary, fontWeight: prominent ? FontWeight.w800 : FontWeight.w500))]));
}
