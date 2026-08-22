import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/theme/app_colors.dart';
import '../../app/widgets/sfa_ui.dart';
import '../../core/auth/session_service.dart';
import 'settings_controller.dart';

class SettingsPage extends GetView<SettingsController> {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Get.find<SessionService>();
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'settings'.tr,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Obx(
              () => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 29,
                        backgroundColor: AppColors.primarySoft,
                        child: Icon(
                          Icons.person_rounded,
                          size: 35,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              session.userName.value.isEmpty ? 'user'.tr : session.userName.value,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              session.currentRole.value?.label ?? 'Sales',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'user_code_hint'.tr,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 22),
            const _GroupTitle('account'),
            _SettingTile(
              icon: Icons.person_outline_rounded,
              label: 'my_profile'.tr,
              onTap: controller.showAccount,
            ),
            _SettingTile(
              icon: Icons.lock_outline_rounded,
              label: 'change_password'.tr,
            ),
            _SettingTile(
              icon: Icons.security_outlined,
              label: 'security'.tr,
            ),
            const SizedBox(height: 18),
            const _GroupTitle('application'),
            Obx(() => _SettingTile(
                  icon: Icons.language_rounded,
                  label: 'language'.tr,
                  value: controller.languageCode.value == 'en' ? 'English' : 'Indonesia',
                  onTap: () => _showLanguagePicker(context),
                )),
            _SettingTile(
              icon: Icons.light_mode_outlined,
              label: 'theme'.tr,
              value: 'light'.tr,
              onTap: controller.changeTheme,
            ),
            _SettingTile(
              icon: Icons.info_outline_rounded,
              label: 'app_version'.tr,
              value: '1.0.0 (100)',
            ),
            _SettingTile(
              icon: Icons.sync_rounded,
              label: 'data_sync'.tr,
              onTap: () => Get.toNamed('/sync-activity'),
            ),
            const SizedBox(height: 18),
            const _GroupTitle('offline_data'),
            Obx(
              () => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Column(
                  children: [
                    ListTile(
                      onTap: controller.isDownloadingMasterData.value
                          ? null
                          : controller.downloadLatestMasterData,
                      leading: const Icon(Icons.cloud_sync_outlined, color: AppColors.primary),
                      title: Text(
                        controller.isDownloadingMasterData.value
                            ? 'downloading_latest_data'.tr
                            : 'download_latest_data'.tr,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        controller.lastMasterDownloadAt.value.isEmpty
                            ? 'master_not_downloaded'.tr
                            : '${controller.lastMasterDownloadSummary.value.isEmpty ? 'Master data terakhir diunduh dari server.' : controller.lastMasterDownloadSummary.value} • ${controller.lastMasterDownloadAt.value.replaceFirst('T', ' ').substring(0, 16)}',
                        style: const TextStyle(fontSize: 11),
                      ),
                      trailing: controller.isDownloadingMasterData.value
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                    ),
                    if (controller.isDownloadingMasterData.value)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            LinearProgressIndicator(value: controller.masterDownloadProgress.value),
                            const SizedBox(height: 7),
                            Text(controller.masterDownloadLabel.value, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            const _GroupTitle('backup_restore'),
            Obx(
              () => _SettingTile(
                icon: Icons.cloud_download_outlined,
                label: controller.isRestoringServerState.value
                    ? 'restoring_server_state'.tr
                    : 'restore_server_state'.tr,
                value: controller.lastServerStateRestoreAt.value.isEmpty
                    ? 'never'.tr
                    : 'last_restored'.tr,
                onTap: controller.isRestoringServerState.value
                    ? null
                    : controller.confirmRestoreServerState,
              ),
            ),
            const SizedBox(height: 18),
            const _GroupTitle('others'),
            _SettingTile(
              icon: Icons.help_outline_rounded,
              label: 'help'.tr,
            ),
            _SettingTile(
              icon: Icons.info_outline_rounded,
              label: 'about_app'.tr,
            ),
            Obx(() => _SettingTile(
              icon: Icons.delete_outline_rounded,
              label: controller.isClearingLocalData.value ? 'deleting_local_data'.tr : 'delete_local_data'.tr,
              color: AppColors.danger,
              onTap: controller.isClearingLocalData.value ? null : controller.deleteAllData,
            )),
            _SettingTile(
              icon: Icons.logout_rounded,
              label: 'logout'.tr,
              color: AppColors.danger,
              onTap: controller.logout,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showLanguagePicker(BuildContext context) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('language'.tr, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text('select_language'.tr, style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 12),
              Obx(() => RadioListTile<String>(
                    value: 'id',
                    groupValue: controller.languageCode.value,
                    onChanged: (value) => Navigator.of(sheetContext).pop(value),
                    title: const Text('Indonesia'),
                  )),
              Obx(() => RadioListTile<String>(
                    value: 'en',
                    groupValue: controller.languageCode.value,
                    onChanged: (value) => Navigator.of(sheetContext).pop(value),
                    title: const Text('English'),
                  )),
            ],
          ),
        ),
      ),
    );
    if (selected == null) return;
    await controller.changeLanguage(selected);
  }
}

class _GroupTitle extends StatelessWidget {
  const _GroupTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text.tr,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
    ),
  );
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.icon,
    required this.label,
    this.value,
    this.color = AppColors.textPrimary,
    this.onTap,
  });
  final IconData icon;
  final String label;
  final String? value;
  final Color color;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 8),
    child: ListTile(
      onTap: onTap,
      leading: Icon(icon, color: color, size: 21),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (value != null)
            Text(
              value!,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          const SizedBox(width: 6),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    ),
  );
}
