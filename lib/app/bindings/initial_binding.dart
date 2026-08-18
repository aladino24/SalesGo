import 'package:get/get.dart';

import '../../core/auth/session_service.dart';
import '../../core/network/api_client.dart';
import '../../core/network/network_info.dart';
import '../../core/storage/local_storage.dart';
import '../../core/storage/sync_storage.dart';
import '../../core/sync/sync_manager.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // Storage
    Get.put(LocalStorage());
    Get.put(SyncStorage());

    // Network
    Get.put<NetworkInfo>(NetworkInfo());
    Get.put<SessionService>(SessionService());
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
  }
}
