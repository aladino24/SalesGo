import 'package:get/get.dart';

import '../../core/auth/session_service.dart';
import '../../core/network/api_client.dart';
import '../../core/network/network_info.dart';
import '../../core/storage/local_storage.dart';
import '../../core/storage/sync_storage.dart';
import '../../core/sync/sync_manager.dart';
import '../../core/sync/server_state_restore_service.dart';
import '../../core/sync/master_data_download_service.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // Storage
    Get.put(LocalStorage());
    Get.put(SyncStorage());

    // Network
    Get.put<NetworkInfo>(NetworkInfo());
    if (!Get.isRegistered<SessionService>()) {
      Get.put<SessionService>(SessionService(), permanent: true);
    }
    Get.put<ApiClient>(ApiClient(
      sessionService: Get.find<SessionService>(),
    ));

    // Sync
    Get.put<SyncManager>(
      SyncManager(
        networkInfo: Get.find<NetworkInfo>(),
        apiClient: Get.find<ApiClient>(),
      ),
    );
    Get.put<ServerStateRestoreService>(
      ServerStateRestoreService(
        apiClient: Get.find<ApiClient>(),
        networkInfo: Get.find<NetworkInfo>(),
      ),
    );
    Get.put<MasterDataDownloadService>(MasterDataDownloadService());
  }
}
