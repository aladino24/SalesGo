import 'package:get/get.dart';

import '../../core/network/network_info.dart';
import '../../data/models/important_file_model.dart';
import '../../data/models/promotion_model.dart';
import '../../data/repositories/information_repository.dart';
import '../../app/widgets/sfa_feedback_dialog.dart';

class InformationController extends GetxController {
  InformationController({InformationRepository? repository, NetworkInfo? networkInfo})
      : _repository = repository ?? InformationRepository(),
        _networkInfo = networkInfo ?? Get.find<NetworkInfo>();

  final InformationRepository _repository;
  final NetworkInfo _networkInfo;
  final promotions = <PromotionModel>[].obs;
  final files = <ImportantFileModel>[].obs;
  final downloadingIds = <String>{}.obs;
  final isLoading = false.obs;
  final cacheUsageBytes = 0.obs;
  final cacheQuotaBytes = InformationRepository.cacheQuotaBytes.obs;

  @override
  void onInit() {
    super.onInit();
    refreshData();
  }

  Future<void> refreshData() async {
    isLoading.value = true;
    try {
      final online = await _networkInfo.isConnected;
      promotions.assignAll(await _repository.getPromotions(online: online));
      files.assignAll(await _repository.getFiles(online: online));
      await refreshCacheUsage();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshCacheUsage() async {
    final usage = await _repository.cacheUsage();
    cacheUsageBytes.value = usage.usedBytes;
    cacheQuotaBytes.value = usage.quotaBytes;
  }

  Future<void> downloadFile(ImportantFileModel file) async {
    if (downloadingIds.contains(file.id)) return;
    downloadingIds.add(file.id);
    try {
      final cached = await _repository.download(file);
      final index = files.indexWhere((item) => item.id == cached.id);
      if (index >= 0) files[index] = cached;
      await refreshCacheUsage();
      await SfaFeedbackDialog.show(type: SfaFeedbackType.upload, title: 'File siap offline', message: '${cached.name} tersimpan di perangkat.');
    } on CacheQuotaExceededException {
      SfaFeedbackDialog.show(type: SfaFeedbackType.warning, title: 'Penyimpanan penuh', message: 'Hapus cache file lain sebelum mengunduh file ini.');
    } on FormatException catch (error) {
      SfaFeedbackDialog.show(type: SfaFeedbackType.error, title: 'Unduhan gagal', message: error.message);
    } catch (_) {
      SfaFeedbackDialog.show(type: SfaFeedbackType.error, title: 'Unduhan gagal', message: 'Periksa koneksi dan coba lagi.');
    } finally {
      downloadingIds.remove(file.id);
    }
  }

  Future<void> openFile(ImportantFileModel file) async {
    try {
      await _repository.openCachedFile(file);
    } on StateError catch (error) {
      SfaFeedbackDialog.show(type: SfaFeedbackType.error, title: 'Tidak dapat membuka file', message: error.message);
    } catch (_) {
      SfaFeedbackDialog.show(type: SfaFeedbackType.error, title: 'Tidak dapat membuka file', message: 'Coba unduh ulang file ini.');
    }
  }

  Future<void> removeFileCache(ImportantFileModel file) async {
    await _repository.removeCache(file);
    final index = files.indexWhere((item) => item.id == file.id);
    if (index >= 0) files[index] = file.copyWith(cachePath: '');
    await refreshCacheUsage();
    await SfaFeedbackDialog.show(type: SfaFeedbackType.delete, title: 'Cache dihapus', message: '${file.name} tidak lagi tersedia offline.');
  }
}
