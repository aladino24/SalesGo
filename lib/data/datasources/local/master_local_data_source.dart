import '../../models/outlet_model.dart';
import '../../models/product_model.dart';

class MasterLocalDataSource {
  Future<List<ProductModel>> getProducts() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));

    return [
      ProductModel(
        id: 'PRD-001',
        name: 'Susu Ultra',
        sku: 'SKU-001',
        category: 'Minuman',
        price: 18000,
        stock: 120,
        imageUrl: '',
      ),
      ProductModel(
        id: 'PRD-002',
        name: 'Mie Instan',
        sku: 'SKU-002',
        category: 'Makanan',
        price: 4500,
        stock: 260,
        imageUrl: '',
      ),
    ];
  }

  Future<List<OutletModel>> getOutlets() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));

    return [
      OutletModel(
        id: 'OUT-001',
        name: 'Outlet A',
        code: 'A-01',
        address: 'Jl. Sudirman No. 10',
        type: 'Retail',
        latitude: -6.2088,
        longitude: 106.8456,
        salesResponsible: 'Raka',
        status: 'Active',
      ),
      OutletModel(
        id: 'OUT-002',
        name: 'Outlet B',
        code: 'B-02',
        address: 'Jl. Gatot Subroto No. 20',
        type: 'Modern Trade',
        latitude: -6.2167,
        longitude: 106.8024,
        salesResponsible: 'Raka',
        status: 'Active',
      ),
    ];
  }
}
