import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'settings_controller.dart';

class SettingsPage extends GetView<SettingsController> {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Account'),
            onTap: controller.showAccount,
          ),
          ListTile(
            leading: const Icon(Icons.sync_rounded),
            title: const Text('Sync Data'),
            onTap: controller.syncData,
          ),
          ListTile(
            leading: const Icon(Icons.brightness_6_rounded),
            title: const Text('Brightness'),
            onTap: controller.changeTheme,
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline_rounded),
            title: const Text('Delete All Data'),
            onTap: controller.deleteAllData,
          ),
          ListTile(
            leading: const Icon(Icons.logout_rounded),
            title: const Text('Logout'),
            onTap: controller.logout,
          ),
        ],
      ),
    );
  }
}
