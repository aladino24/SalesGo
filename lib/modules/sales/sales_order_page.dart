import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import '../../app/theme/app_colors.dart';
import '../../app/widgets/sfa_feedback_dialog.dart';
import '../../core/auth/session_service.dart';
import '../../core/network/api_config.dart';
import '../../core/storage/local_storage.dart';
import '../../data/models/outlet_model.dart';
import '../../data/models/product_model.dart';
import '../../data/models/sales_order_model.dart';
import '../../data/repositories/master_repository.dart';
import '../../data/repositories/sales_order_repository.dart';
import '../../data/repositories/ship_to_location_repository.dart';

class SalesOrderPage extends StatefulWidget {
  const SalesOrderPage({super.key, required this.outlet});
  final OutletModel outlet;

  @override
  State<SalesOrderPage> createState() => _SalesOrderPageState();
}

class _SalesOrderPageState extends State<SalesOrderPage> {
  final _repository = SalesOrderRepository();
  final _master = MasterRepository();
  final _shipToRepository = ShipToLocationRepository();
  final _search = TextEditingController();
  final _cart = <String, _CartLine>{};
  final _selectedVariantByFamily = <String, String>{};
  final _selectedUomByProduct = <String, String>{};
  List<ProductModel> _products = const [];
  List<ShipToLocation> _shipToLocations = const [];
  ShipToLocation? _shipTo;
  bool _loading = true;
  bool _saving = false;
  String _division = '';
  int _minimumUnits = 1;
  int _maximumUnits = 1000;
  double _minimumAmount = 0;
  double _maximumAmount = 0;

  @override
  void initState() {
    super.initState();
    _loadOrderPolicy();
    _loadProducts();
    _loadShipToLocations();
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

  Future<void> _loadShipToLocations() async {
    final locations = await _shipToRepository.forOutlet(widget.outlet);
    if (!mounted) return;
    setState(() {
      _shipToLocations = locations;
      _shipTo = locations.firstWhereOrNull((item) => item.isDefault) ??
          locations.firstOrNull;
    });
  }

  Future<void> _selectShipTo() async {
    if (_shipToLocations.isEmpty) return;
    final selected = await showModalBottomSheet<ShipToLocation>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const ListTile(
              title: Text('Pilih tujuan pengiriman', style: TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text('Barang dikirim ke alamat milik outlet yang dipilih.'),
            ),
            ..._shipToLocations.map(
              (location) => RadioListTile<ShipToLocation>(
                value: location,
                groupValue: _shipTo,
                onChanged: (value) => Navigator.pop(sheetContext, value),
                title: Text(location.name),
                subtitle: Text('${location.code.isEmpty ? 'Alamat utama' : location.code}\n${location.address}'),
                isThreeLine: true,
              ),
            ),
          ],
        ),
      ),
    );
    if (selected != null && mounted) setState(() => _shipTo = selected);
  }

  void _loadOrderPolicy() {
    final raw = LocalStorage.appBox.get('order_policy');
    if (raw is! Map) return;
    final minimum = _integer(raw['minimumUnits'], 1).clamp(1, 100000).toInt();
    final maximum = _integer(raw['maximumUnits'], 1000).clamp(minimum, 100000).toInt();
    if (!mounted) return;
    setState(() {
      _minimumUnits = minimum;
      _maximumUnits = maximum;
      _minimumAmount = _number(raw['minimumAmount']);
      _maximumAmount = _number(raw['maximumAmount']);
    });
  }

  List<ProductModel> get _visibleProducts {
    final query = _search.text.trim().toLowerCase();
    return _products.where((product) {
      final matchesDivision = _division.isEmpty || product.divisionCode == _division;
      final haystack = '${product.name} ${product.brand} ${product.variant} ${product.sku} ${product.barcode}'.toLowerCase();
      return matchesDivision && (query.isEmpty || haystack.contains(query));
    }).toList();
  }

  List<_ProductFamily> get _visibleFamilies {
    final grouped = <String, List<ProductModel>>{};
    for (final product in _visibleProducts) {
      final key = '${product.divisionCode}|${product.category}|${product.brand.isEmpty ? product.name : product.brand}';
      grouped.putIfAbsent(key, () => []).add(product);
    }
    return grouped.entries.map((entry) {
      final items = entry.value..sort((a, b) => '${a.variant} ${a.size}'.compareTo('${b.variant} ${b.size}'));
      return _ProductFamily(key: entry.key, title: items.first.brand.isEmpty ? items.first.name : items.first.brand, products: items);
    }).toList()..sort((a, b) => a.title.compareTo(b.title));
  }

  ProductModel _selectedProduct(_ProductFamily family) {
    final selectedId = _selectedVariantByFamily[family.key];
    return family.products.firstWhereOrNull((item) => item.id == selectedId) ?? family.products.first;
  }

  ProductUomModel _selectedUom(ProductModel product) {
    final selectedId = _selectedUomByProduct[product.id];
    return product.sellableUoms.firstWhereOrNull((item) => item.id == selectedId) ?? product.defaultUom;
  }

  String _cartKey(ProductModel product, ProductUomModel uom) => '${product.id}|${uom.id.isEmpty ? uom.code : uom.id}';
  int _cartQuantity(ProductModel product, ProductUomModel uom) => _cart[_cartKey(product, uom)]?.quantity ?? 0;
  List<_CartLine> get _cartLines => _cart.values.toList()..sort((a, b) => a.product.name.compareTo(b.product.name));
  int get _itemCount => _cart.values.fold(0, (sum, item) => sum + item.quantity);
  int get _totalUnits => _cart.values.fold(0, (sum, item) => sum + item.baseQuantity);
  double get _total => _cart.values.fold(0, (sum, item) => sum + item.subtotal);
  List<String> get _divisions => _products.map((item) => item.divisionCode).where((item) => item.isNotEmpty).toSet().toList()..sort();

  String _divisionLabel(String code) {
    final product = _products.firstWhereOrNull((item) => item.divisionCode == code);
    return product == null || product.divisionName.isEmpty ? 'Divisi $code' : product.divisionName;
  }

  void _changeQuantity(ProductModel product, ProductUomModel uom, int delta) {
    final key = _cartKey(product, uom);
    final next = (_cart[key]?.quantity ?? 0) + delta;
    final nextBaseQuantity = next * uom.conversionToBase;
    final otherBaseQuantity = _cart.entries
        .where((entry) => entry.key != key && entry.value.product.id == product.id)
        .fold(0, (sum, entry) => sum + entry.value.baseQuantity);
    if (delta > 0 && otherBaseQuantity + nextBaseQuantity > product.stock) {
      SfaFeedbackDialog.show(type: SfaFeedbackType.warning, title: 'Stok tidak cukup', message: 'Stok ${product.name} tersedia ${product.stock} satuan dasar. 1 ${uom.code} = ${uom.conversionToBase} satuan dasar.');
      return;
    }
    setState(() {
      if (next <= 0) {
        _cart.remove(key);
      } else {
        _cart[key] = _CartLine(product: product, uom: uom, quantity: next);
      }
    });
  }

  Future<void> _submit() async {
    final selected = _cartLines;
    if (selected.isEmpty) {
      await SfaFeedbackDialog.show(type: SfaFeedbackType.warning, title: 'Cart masih kosong', message: 'Pilih minimal satu produk untuk membuat order.');
      return;
    }
    if (_totalUnits < _minimumUnits || _totalUnits > _maximumUnits) {
      await SfaFeedbackDialog.show(type: SfaFeedbackType.warning, title: 'Jumlah order belum sesuai', message: 'Total pesanan harus $_minimumUnits–$_maximumUnits unit. Saat ini $_totalUnits unit.');
      return;
    }
    if (_total < _minimumAmount || (_maximumAmount > 0 && _total > _maximumAmount)) {
      await SfaFeedbackDialog.show(type: SfaFeedbackType.warning, title: 'Nilai order belum sesuai', message: 'Nominal order belum memenuhi batas yang ditetapkan server.');
      return;
    }
    setState(() => _saving = true);
    try {
      const uuid = Uuid();
      final order = SalesOrderModel(
        id: 'SO-${uuid.v4()}',
        outletId: widget.outlet.id,
        outletName: widget.outlet.name,
        items: selected.map((line) => SalesOrderItem(productId: line.product.id, productName: line.product.name, productUomId: line.uom.id, uomCode: line.uom.code, uomName: line.uom.name, conversionToBase: line.uom.conversionToBase, baseQuantity: line.baseQuantity, quantity: line.quantity, unitPrice: line.uom.price)).toList(),
        total: _total,
        status: 'Pending Sync',
        createdAt: DateTime.now(),
        shipTo: _shipTo,
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
    // Backend mengirim path relatif agar aplikasi dapat tetap memakai host
    // ngrok yang aktif. Bangun URL dari origin, bukan dari path /api/v1,
    // karena endpoint gambar juga menyertakan prefiks /api/v1 sendiri.
    final origin = Uri.parse(baseUrl).origin;
    return '${origin}${product.imageUrl.startsWith('/') ? '' : '/'}${product.imageUrl}';
  }

  @override
  Widget build(BuildContext context) {
    final families = _visibleFamilies;
    return Scaffold(
      appBar: AppBar(title: const Text('Buat Order', style: TextStyle(fontWeight: FontWeight.w800))),
      bottomNavigationBar: _OrderCartBar(itemCount: _itemCount, total: _total, saving: _saving, onPressed: _showCart),
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.primary, Color(0xFF4F8CFF)]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(children: [
                const CircleAvatar(radius: 22, backgroundColor: Colors.white24, child: Icon(Icons.storefront_rounded, color: Colors.white)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Order untuk ${widget.outlet.name}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)), const SizedBox(height: 3), Text(widget.outlet.address, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 11))])),
                const Icon(Icons.shopping_bag_outlined, color: Colors.white70),
              ]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: OutlinedButton.icon(
              onPressed: _selectShipTo,
              icon: const Icon(Icons.local_shipping_outlined),
              label: Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tujuan pengiriman'),
                    Text(
                      _shipTo == null
                          ? 'Memuat alamat pengiriman...'
                          : '${_shipTo!.name} — ${_shipTo!.address}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(controller: _search, onChanged: (_) => setState(() {}), decoration: InputDecoration(hintText: 'Cari nama, brand, SKU, atau barcode', prefixIcon: const Icon(Icons.search_rounded), suffixIcon: _search.text.isEmpty ? null : IconButton(onPressed: () { _search.clear(); setState(() {}); }, icon: const Icon(Icons.close_rounded)))),
          ),
          const SizedBox(height: 10),
          _FilterBar(
            divisions: _divisions,
            divisionLabel: _divisionLabel,
            division: _division,
            onDivision: (value) => setState(() => _division = value),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: _loading && _products.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : families.isEmpty
                    ? const Center(child: Text('Produk tidak ditemukan untuk filter ini.'))
                    : LayoutBuilder(builder: (context, constraints) {
                        final count = constraints.maxWidth >= 900 ? 5 : constraints.maxWidth >= 650 ? 4 : 2;
                        return RefreshIndicator(
                          onRefresh: _loadProducts,
                          child: GridView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: count, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: .48),
                            itemCount: families.length,
                            itemBuilder: (_, index) {
                              final family = families[index];
                              final selected = _selectedProduct(family);
                              final selectedUom = _selectedUom(selected);
                              return _ProductFamilyCard(
                                family: family,
                                product: selected,
                                uom: selectedUom,
                                quantity: _cartQuantity(selected, selectedUom),
                                imageUrl: _imageUrl(selected),
                                cartVariants: family.products.where((item) => _cart.values.any((line) => line.product.id == item.id)).length,
                                onSelected: (product) => setState(() { _selectedVariantByFamily[family.key] = product.id; _selectedUomByProduct.putIfAbsent(product.id, () => product.defaultUom.id); }),
                                onUomSelected: (uom) => setState(() => _selectedUomByProduct[selected.id] = uom.id),
                                onChange: (delta) => _changeQuantity(selected, selectedUom, delta),
                              );
                            },
                          ),
                        );
                      }),
          ),
        ]),
      ),
    );
  }

  Future<void> _showCart() async {
    if (_cartLines.isEmpty) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (_, setSheetState) => _OrderCartSheet(
          items: _cartLines,
          total: _total,
          units: _totalUnits,
          minimumUnits: _minimumUnits,
          maximumUnits: _maximumUnits,
          onChange: (line, delta) {
            _changeQuantity(line.product, line.uom, delta);
            setSheetState(() {});
          },
          onSubmit: () async {
            Navigator.of(sheetContext).pop();
            await _submit();
          },
        ),
      ),
    );
  }

  static int _integer(dynamic value, int fallback) => value is num ? value.toInt() : int.tryParse(value?.toString() ?? '') ?? fallback;
  static double _number(dynamic value) => value is num ? value.toDouble() : double.tryParse(value?.toString() ?? '') ?? 0;
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.divisions, required this.divisionLabel, required this.division, required this.onDivision});
  final List<String> divisions;
  final String Function(String) divisionLabel;
  final String division;
  final ValueChanged<String> onDivision;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 42,
        child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16), children: [
          ChoiceChip(label: const Text('Semua divisi'), selected: division.isEmpty, onSelected: (_) => onDivision('')),
          const SizedBox(width: 7),
          ...divisions.expand((item) => [ChoiceChip(label: Text(divisionLabel(item)), selected: division == item, onSelected: (_) => onDivision(item)), const SizedBox(width: 7)]),
        ]),
      );
}

class _ProductFamily {
  const _ProductFamily({required this.key, required this.title, required this.products});
  final String key, title;
  final List<ProductModel> products;
}

class _CartLine {
  const _CartLine({required this.product, required this.uom, required this.quantity});
  final ProductModel product;
  final ProductUomModel uom;
  final int quantity;
  int get baseQuantity => quantity * uom.conversionToBase;
  double get subtotal => uom.price * quantity;
}

class _ProductFamilyCard extends StatelessWidget {
  const _ProductFamilyCard({required this.family, required this.product, required this.uom, required this.quantity, required this.imageUrl, required this.cartVariants, required this.onSelected, required this.onUomSelected, required this.onChange});
  final _ProductFamily family;
  final ProductModel product;
  final ProductUomModel uom;
  final int quantity;
  final String imageUrl;
  final int cartVariants;
  final ValueChanged<ProductModel> onSelected;
  final ValueChanged<ProductUomModel> onUomSelected;
  final ValueChanged<int> onChange;

  @override
  Widget build(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: Container(width: double.infinity, decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(10)), child: imageUrl.isEmpty ? const Icon(Icons.inventory_2_outlined, size: 42, color: AppColors.primary) : Image.network(imageUrl, headers: {'Authorization': 'Bearer ${Get.find<SessionService>().accessToken.value}', 'ngrok-skip-browser-warning': 'true'}, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported_outlined, color: AppColors.textSecondary)))),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: Text(family.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800))),
              if (cartVariants > 0) Badge(label: Text('$cartVariants'), child: const Icon(Icons.shopping_cart_outlined, size: 16)),
            ]),
            DropdownButtonHideUnderline(
              child: DropdownButton<ProductModel>(
                isExpanded: true,
                isDense: true,
                value: product,
                items: family.products.map((item) => DropdownMenuItem(
                  value: item,
                  child: Text('${item.variant.isEmpty ? item.name : item.variant} - ${item.size}${item.uom.isEmpty ? '' : ' / ${item.uom}'}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11)),
                )).toList(),
                onChanged: (item) { if (item != null) onSelected(item); },
              ),
            ),
            DropdownButtonHideUnderline(
              child: DropdownButton<ProductUomModel>(
                isExpanded: true,
                isDense: true,
                value: uom,
                items: product.sellableUoms.map((item) => DropdownMenuItem(
                  value: item,
                  child: Text('${item.code} • Rp ${item.price.toStringAsFixed(0)}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                )).toList(),
                onChanged: (item) { if (item != null) onUomSelected(item); },
              ),
            ),
            const SizedBox(height: 4),
            Text('${product.size} • 1 ${uom.code} = ${uom.conversionToBase} unit', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10)),
            const SizedBox(height: 4),
            Text('Rp ${uom.price.toStringAsFixed(0)} / ${uom.code}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800)),
            Text('Stok ${product.stock}', style: TextStyle(fontSize: 10, color: product.stock > 0 ? AppColors.success : AppColors.danger)),
            const SizedBox(height: 5),
            if (quantity == 0)
              SizedBox(width: double.infinity, child: FilledButton.tonal(onPressed: product.stock > 0 ? () => onChange(1) : null, child: const Text('Tambah')))
            else
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [IconButton(visualDensity: VisualDensity.compact, onPressed: () => onChange(-1), icon: const Icon(Icons.remove_circle_outline)), Text('$quantity ${uom.code}', style: const TextStyle(fontWeight: FontWeight.w800)), IconButton(visualDensity: VisualDensity.compact, onPressed: (quantity + 1) * uom.conversionToBase <= product.stock ? () => onChange(1) : null, icon: const Icon(Icons.add_circle, color: AppColors.primary))]),
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
            child: saving
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Row(children: [
                    Stack(clipBehavior: Clip.none, children: [
                      const Icon(Icons.shopping_cart_rounded),
                      if (itemCount > 0) Positioned(right: -9, top: -8, child: CircleAvatar(radius: 9, backgroundColor: Colors.white, child: Text('$itemCount', style: const TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w800)))),
                    ]),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [const Text('Lihat Cart', style: TextStyle(fontWeight: FontWeight.w800)), Text('$itemCount unit dipilih', style: const TextStyle(fontSize: 11))])),
                    Text('Rp ${total.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w800)),
                  ]),
          ),
        ),
      );
}

class _OrderCartSheet extends StatelessWidget {
  const _OrderCartSheet({required this.items, required this.total, required this.units, required this.minimumUnits, required this.maximumUnits, required this.onChange, required this.onSubmit});
  final List<_CartLine> items;
  final double total;
  final int units, minimumUnits, maximumUnits;
  final void Function(_CartLine line, int delta) onChange;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .72,
          child: Column(children: [
            const Padding(padding: EdgeInsets.fromLTRB(20, 4, 20, 12), child: Row(children: [Icon(Icons.shopping_cart_checkout_rounded, color: AppColors.primary), SizedBox(width: 10), Text('Rincian Cart', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800))])),
            Expanded(child: ListView.separated(padding: const EdgeInsets.symmetric(horizontal: 16), itemCount: items.length, separatorBuilder: (_, __) => const Divider(height: 1), itemBuilder: (_, index) {
              final line = items[index];
              final product = line.product;
              final quantity = line.quantity;
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 5),
                leading: CircleAvatar(backgroundColor: AppColors.primarySoft, child: Text('${index + 1}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800))),
                title: Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text('Rp ${line.uom.price.toStringAsFixed(0)} / ${line.uom.code} × $quantity\nSubtotal Rp ${line.subtotal.toStringAsFixed(0)} • ${line.baseQuantity} unit dasar'),
                isThreeLine: true,
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [IconButton(onPressed: () => onChange(line, -1), icon: const Icon(Icons.remove_circle_outline)), Text('$quantity', style: const TextStyle(fontWeight: FontWeight.w800)), IconButton(onPressed: (quantity + 1) * line.uom.conversionToBase <= product.stock ? () => onChange(line, 1) : null, icon: const Icon(Icons.add_circle, color: AppColors.primary))]),
              );
            })),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
              decoration: const BoxDecoration(color: Color(0xFFF8FAFF), border: Border(top: BorderSide(color: Color(0xFFE6EBF5)))),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Total unit'), Text('$units unit', style: const TextStyle(fontWeight: FontWeight.w800))]),
                const SizedBox(height: 5),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Total pesanan', style: TextStyle(fontWeight: FontWeight.w700)), Text('Rp ${total.toStringAsFixed(0)}', style: const TextStyle(fontSize: 17, color: AppColors.primary, fontWeight: FontWeight.w800))]),
                const SizedBox(height: 4),
                Align(alignment: Alignment.centerLeft, child: Text('Ketentuan server: $minimumUnits–$maximumUnits unit per order.', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary))),
                const SizedBox(height: 12),
                SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: onSubmit, icon: const Icon(Icons.send_rounded), label: const Text('Simpan Order'))),
              ]),
            ),
          ]),
        ),
      );
}
