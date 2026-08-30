import 'package:get/get.dart';

import '../../core/auth/session_service.dart';
import '../../core/network/api_client.dart';
import '../../core/network/network_info.dart';
import '../../core/notifications/notification_deep_link_handler.dart';
import '../../core/notifications/push_notification_service.dart';
import '../../core/storage/local_storage.dart';
import '../../core/storage/sync_storage.dart';
import '../../core/sync/sync_manager.dart';
import '../../core/sync/server_state_restore_service.dart';
import '../../core/sync/master_data_download_service.dart';
import '../../core/sync/master_auto_download_service.dart';
import '../../core/location/location_tracking_service.dart';
import '../../modules/notification/notification_controller.dart';

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
    Get.put(NotificationDeepLinkHandler(), permanent: true);
    Get.put(PushNotificationService(), permanent: true);
    if (Get.find<SessionService>().isAuthenticated) {
      Get.put(NotificationController(), permanent: true);
      Future<void>.microtask(() => Get.find<PushNotificationService>().start());
    }
    Get.put<ServerStateRestoreService>(
      ServerStateRestoreService(
        apiClient: Get.find<ApiClient>(),
        networkInfo: Get.find<NetworkInfo>(),
      ),
    );
    Get.put<MasterDataDownloadService>(MasterDataDownloadService());
    Get.put(
      MasterAutoDownloadService(
        downloader: Get.find<MasterDataDownloadService>(),
        session: Get.find<SessionService>(),
      ),
      permanent: true,
    );
    Get.put(LocationTrackingService(), permanent: true);
    if (Get.find<SessionService>().isAuthenticated) {
      Future<void>.microtask(() => Get.find<MasterAutoDownloadService>().start(showProgress: true));
      Future<void>.microtask(
        () => Get.find<LocationTrackingService>().start(),
      );
    }
  }
}
