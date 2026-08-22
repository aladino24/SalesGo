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
      // Cache selalu dipasang lebih dulu. Koneksi Wi-Fi/seluler dapat terlihat
      // aktif walau API/ngrok tidak dapat dijangkau; daftar master tidak boleh
      // menjadi kosong selama menunggu timeout jaringan.
      outlets.assignAll(await _repository.getOutlets(isOnline: false));
      final online = await _networkInfo.isConnected;
      if (online) {
        outlets.assignAll(await _repository.getOutlets(isOnline: true));
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshFromCache() async {
    outlets.assignAll(await _repository.getOutlets(isOnline: false));
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
