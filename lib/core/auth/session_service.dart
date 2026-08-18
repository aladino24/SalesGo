import 'package:get/get.dart';

import '../storage/local_storage.dart';
import 'app_roles.dart';

class SessionService extends GetxService {
  static const _keyUserRole = 'user_role';
  static const _keyUserName = 'user_name';

  final Rx<AppRole?> currentRole = Rx<AppRole?>(null);
  final RxString userName = ''.obs;

  Future<void> loginAs(AppRole role, String name) async {
    currentRole.value = role;
    userName.value = name;
    await LocalStorage.saveSession(_keyUserRole, role.name);
    await LocalStorage.saveSession(_keyUserName, name);
  }

  Future<void> loadSession() async {
    final savedRole = await LocalStorage.readSession(_keyUserRole);
    final savedName = await LocalStorage.readSession(_keyUserName);

    if (savedRole != null) {
      currentRole.value = AppRole.values.firstWhere(
        (role) => role.name == savedRole,
        orElse: () => AppRole.sales,
      );
    }

    userName.value = savedName ?? 'Sales';
  }

  Future<void> logout() async {
    currentRole.value = null;
    userName.value = '';
    await LocalStorage.deleteSession(_keyUserRole);
    await LocalStorage.deleteSession(_keyUserName);
  }
}
