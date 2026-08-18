import 'package:get/get.dart';

import '../../core/network/network_info.dart';
import '../../data/models/outlet_model.dart';
import '../../data/repositories/master_repository.dart';

class OutletController extends GetxController {
  OutletController({
    MasterRepository? repository,
    NetworkInfo? networkInfo,
  })  : _repository = repository ?? MasterRepository(),
        _networkInfo = networkInfo ?? Get.find<NetworkInfo>();

  final MasterRepository _repository;
  final NetworkInfo _networkInfo;

  final RxList<OutletModel> outlets = <OutletModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString searchTerm = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadOutlets();
  }

  Future<void> loadOutlets() async {
    isLoading.value = true;
    try {
      final online = await _networkInfo.isConnected;
      final data = await _repository.getOutlets(isOnline: online);
      outlets.assignAll(data);
    } finally {
      isLoading.value = false;
    }
  }

  List<OutletModel> get filteredOutlets {
    final query = searchTerm.value.trim().toLowerCase();
    if (query.isEmpty) {
      return outlets;
    }

    return outlets.where((outlet) {
      return outlet.name.toLowerCase().contains(query) ||
          outlet.code.toLowerCase().contains(query) ||
          outlet.address.toLowerCase().contains(query) ||
          outlet.salesResponsible.toLowerCase().contains(query);
    }).toList();
  }
}
