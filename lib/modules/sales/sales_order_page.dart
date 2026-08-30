import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import '../../app/theme/app_colors.dart';
import '../../app/widgets/sfa_feedback_dialog.dart';
import '../../core/auth/session_service.dart';
import '../../core/network/api_config.dart';
import '../../data/models/outlet_model.dart';
import '../../data/models/product_model.dart';
import '../../data/models/sales_order_model.dart';
import '../../data/repositories/master_repository.dart';
import '../../data/repositories/sales_order_repository.dart';

class SalesOrderPage extends StatefulWidget {
  const SalesOrderPage({super.key, required this.outlet});
  final OutletModel outlet;

  @override
  State<SalesOrderPage> createState() => _SalesOrderPageState();
}

class _SalesOrderPageState extends State<SalesOrderPage> {
  final _repository = SalesOrderRepository();
  final _master = MasterRepository();
  final _search = TextEditingController();
  final _cart = <String, int>{};
  List<ProductModel> _products = const [];
  bool _loading = true;
  bool _saving = false;
  String _division = '';
  String _category = '';

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() => _loading = true);
    try {
      // Katalog cache tetap tampil lebih dahulu. MasterRepository akan
      // mengganti cache ketika server dapat diakses.
      final cached = await _master.getProducts(isOnline: false);
      if (mounted && cached.isNotEmpty) setState(() => _products = cached);
      final fresh = await _master.getProducts(isOnline: true);
      if (mounted) setState(() => _products = fresh);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<ProductModel> get _visibleProducts {
    final query = _search.text.trim().toLowerCase();
    return _products.where((product) {
      final matchesDivision = _division.isEmpty || product.divisionCode == _division;
      final matchesCategory = _category.isEmpty || product.category == _category;
      final haystack = '${product.name} ${product.brand} ${product.variant} ${product.sku} ${product.barcode}'.toLowerCase();
      return matchesDivision && matchesCategory && (query.isEmpty || haystack.contains(query));
    }).toList();
  }

  List<ProductModel> get _cartProducts => _products.where((item) => (_cart[item.id] ?? 0) > 0).toList();
  int get _itemCount => _cart.values.fold(0, (sum, item) => sum + item);
  double get _total => _cartProducts.fold(0, (sum, product) => sum + product.price * (_cart[product.id] ?? 0));
  List<String> get _divisions => _products.map((item) => item.divisionCode).where((item) => item.isNotEmpty).toSet().toList()..sort();
  List<String> get _categories => _products.where((item) => _division.isEmpty || item.divisionCode == _division).map((item) => item.category).where((item) => item.isNotEmpty).toSet().toList()..sort();

  void _changeQuantity(ProductModel product, int delta) {
    final next = (_cart[product.id] ?? 0) + delta;
    if (delta > 0 && next > product.stock) {
      SfaFeedbackDialog.show(type: SfaFeedbackType.warning, title: 'Stok tidak cukup', message: 'Stok ${product.name} tersedia ${product.stock} ${product.uom.isEmpty ? 'unit' : product.uom}.');
      return;
    }
    setState(() {
      if (next <= 0) {
        _cart.remove(product.id);
      } else {
        _cart[product.id] = next;
      }
    });
  }

  Future<void> _submit() async {
    final selected = _cartProducts;
    if (selected.isEmpty) {
      await SfaFeedbackDialog.show(type: SfaFeedbackType.warning, title: 'Cart masih kosong', message: 'Pilih minimal satu produk untuk membuat order.');
      return;
    }
    setState(() => _saving = true);
    try {
      const uuid = Uuid();
      final order = SalesOrderModel(
        id: 'SO-${uuid.v4()}',
        outletId: widget.outlet.id,
        outletName: widget.outlet.name,
        items: selected.map((product) => SalesOrderItem(productId: product.id, productName: product.name, quantity: _cart[product.id]!, unitPrice: product.price)).toList(),
        total: _total,
        status: 'Pending Sync',
        createdAt: DateTime.now(),
      );
      await _repository.create(order);
      if (!mounted) return;
      await SfaFeedbackDialog.show(type: SfaFeedbackType.success, title: 'Order disimpan', message: '${order.items.length} produk tersimpan lokal dan akan disinkronkan otomatis.');
      if (mounted) Get.back(result: order);
    } catch (error) {
      if (mounted) await SfaFeedbackDialog.show(type: SfaFeedbackType.error, title: 'Order belum tersimpan', message: error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _imageUrl(ProductModel product) {
    if (product.imageUrl.isEmpty) return '';
    if (product.imageUrl.startsWith('http')) return product.imageUrl;
    return Uri.parse(baseUrl).resolve(product.imageUrl).toString();
  }

  @override
  Widget build(BuildContext context) {
    final products = _visibleProducts;
    return Scaffold(
      appBar: AppBar(title: const Text('Buat Order', style: TextStyle(fontWeight: FontWeight.w800))),
      bottomNavigationBar: _OrderCartBar(itemCount: _itemCount, total: _total, saving: _saving, onPressed: _submit),
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Card(child: ListTile(leading: const CircleAvatar(child: Icon(Icons.storefront_rounded)), title: Text(widget.outlet.name, style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Text(widget.outlet.address, maxLines: 1, overflow: TextOverflow.ellipsis))),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(controller: _search, onChanged: (_) => setState(() {}), decoration: InputDecoration(hintText: 'Cari nama, brand, SKU, atau barcode', prefixIcon: const Icon(Icons.search_rounded), suffixIcon: _search.text.isEmpty ? null : IconButton(onPressed: () { _search.clear(); setState(() {}); }, icon: const Icon(Icons.close_rounded)))),
          ),
          const SizedBox(height: 10),
          _FilterBar(
            divisions: _divisions,
            categories: _categories,
            division: _division,
            category: _category,
            onDivision: (value) => setState(() { _division = value; _category = ''; }),
            onCategory: (value) => setState(() => _category = value),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: _loading && _products.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : products.isEmpty
                    ? const Center(child: Text('Produk tidak ditemukan untuk filter ini.'))
                    : LayoutBuilder(builder: (context, constraints) {
                        final count = constraints.maxWidth >= 900 ? 5 : constraints.maxWidth >= 650 ? 4 : 2;
                        return RefreshIndicator(
                          onRefresh: _loadProducts,
                          child: GridView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: count, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: .57),
                            itemCount: products.length,
                            itemBuilder: (_, index) => _ProductCard(product: products[index], quantity: _cart[products[index].id] ?? 0, imageUrl: _imageUrl(products[index]), onChange: (delta) => _changeQuantity(products[index], delta)),
                          ),
                        );
                      }),
          ),
        ]),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.divisions, required this.categories, required this.division, required this.category, required this.onDivision, required this.onCategory});
  final List<String> divisions, categories;
  final String division, category;
  final ValueChanged<String> onDivision, onCategory;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 42,
        child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16), children: [
          ChoiceChip(label: const Text('Semua divisi'), selected: division.isEmpty, onSelected: (_) => onDivision('')),
          const SizedBox(width: 7),
          ...divisions.expand((item) => [ChoiceChip(label: Text(item), selected: division == item, onSelected: (_) => onDivision(item)), const SizedBox(width: 7)]),
          if (categories.isNotEmpty) const VerticalDivider(width: 20),
          ...categories.expand((item) => [FilterChip(label: Text(item), selected: category == item, onSelected: (selected) => onCategory(selected ? item : '')), const SizedBox(width: 7)]),
        ]),
      );
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product, required this.quantity, required this.imageUrl, required this.onChange});
  final ProductModel product;
  final int quantity;
  final String imageUrl;
  final ValueChanged<int> onChange;

  @override
  Widget build(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: Container(width: double.infinity, decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(10)), child: imageUrl.isEmpty ? const Icon(Icons.inventory_2_outlined, size: 42, color: AppColors.primary) : Image.network(imageUrl, headers: {'Authorization': 'Bearer ${Get.find<SessionService>().accessToken.value}'}, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported_outlined, color: AppColors.textSecondary)))),
            const SizedBox(height: 8),
            Text(product.brand.isEmpty ? product.name : product.brand, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
            Text(product.variant.isEmpty ? product.name : product.variant, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            Text('${product.size}${product.uom.isEmpty ? '' : ' • ${product.uom}'}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10)),
            const SizedBox(height: 4),
            Text('Rp ${product.price.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800)),
            Text('Stok ${product.stock}', style: TextStyle(fontSize: 10, color: product.stock > 0 ? AppColors.success : AppColors.danger)),
            const SizedBox(height: 5),
            if (quantity == 0)
              SizedBox(width: double.infinity, child: FilledButton.tonal(onPressed: product.stock > 0 ? () => onChange(1) : null, child: const Text('Tambah')))
            else
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [IconButton(visualDensity: VisualDensity.compact, onPressed: () => onChange(-1), icon: const Icon(Icons.remove_circle_outline)), Text('$quantity', style: const TextStyle(fontWeight: FontWeight.w800)), IconButton(visualDensity: VisualDensity.compact, onPressed: quantity < product.stock ? () => onChange(1) : null, icon: const Icon(Icons.add_circle, color: AppColors.primary))]),
          ]),
        ),
      );
}

class _OrderCartBar extends StatelessWidget {
  const _OrderCartBar({required this.itemCount, required this.total, required this.saving, required this.onPressed});
  final int itemCount;
  final double total;
  final bool saving;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
          child: FilledButton(
            onPressed: saving || itemCount == 0 ? null : onPressed,
            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15)),
            child: saving ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Cart ($itemCount)'), Text('Buat Order • Rp ${total.toStringAsFixed(0)}')]),
          ),
        ),
      );
}
