import '../../models/outlet_model.dart';
import '../../models/product_model.dart';

class MasterRemoteDataSource {
  Future<List<ProductModel>> getProducts() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));

    return [
      ProductModel(
        id: 'PRD-101',
        name: 'Minuman Soda',
        sku: 'SKU-101',
        category: 'Minuman',
        price: 12000,
        stock: 85,
        imageUrl: '',
      ),
    ];
  }

  Future<List<OutletModel>> getOutlets() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));

    return [
      OutletModel(
        id: 'OUT-101',
        name: 'Outlet Server',
        code: 'S-01',
        address: 'Jl. Raya Pasar Baru',
        type: 'Retail',
        latitude: -6.1944,
        longitude: 106.8229,
        salesResponsible: 'Raka',
        status: 'Active',
      ),
    ];
  }
}
