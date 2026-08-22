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
        title: const Text(
          'Pengaturan',
          style: TextStyle(fontWeight: FontWeight.w800),
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
                              session.userName.value.isEmpty ? 'Pengguna' : session.userName.value,
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
                            const Text(
                              'Kode pengguna tersedia setelah profil dimuat',
                              style: TextStyle(
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
            const _GroupTitle('Akun'),
            _SettingTile(
              icon: Icons.person_outline_rounded,
              label: 'Profil Saya',
              onTap: controller.showAccount,
            ),
            const _SettingTile(
              icon: Icons.lock_outline_rounded,
              label: 'Ubah Password',
            ),
            const _SettingTile(
              icon: Icons.security_outlined,
              label: 'Keamanan',
            ),
            const SizedBox(height: 18),
            const _GroupTitle('Aplikasi'),
            const _SettingTile(
              icon: Icons.language_rounded,
              label: 'Bahasa',
              value: 'Indonesia',
            ),
            _SettingTile(
              icon: Icons.light_mode_outlined,
              label: 'Tema',
              value: 'Terang',
              onTap: controller.changeTheme,
            ),
            const _SettingTile(
              icon: Icons.info_outline_rounded,
              label: 'Versi Aplikasi',
              value: '1.0.0 (100)',
            ),
            _SettingTile(
              icon: Icons.sync_rounded,
              label: 'Sinkronisasi Data',
              onTap: () => Get.toNamed('/sync-activity'),
            ),
            const SizedBox(height: 18),
            const _GroupTitle('Data Offline'),
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
                            ? 'Mengunduh Data Terbaru...'
                            : 'Download Data Terbaru',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        controller.lastMasterDownloadAt.value.isEmpty
                            ? 'Produk dan outlet belum diperbarui dari server.'
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
            const _GroupTitle('Pencadangan & Pemulihan'),
            Obx(
              () => _SettingTile(
                icon: Icons.cloud_download_outlined,
                label: controller.isRestoringServerState.value
                    ? 'Memulihkan State Server...'
                    : 'Pulihkan State dari Server',
                value: controller.lastServerStateRestoreAt.value.isEmpty
                    ? 'Belum pernah'
                    : 'Terakhir dipulihkan',
                onTap: controller.isRestoringServerState.value
                    ? null
                    : controller.confirmRestoreServerState,
              ),
            ),
            const SizedBox(height: 18),
            const _GroupTitle('Lainnya'),
            const _SettingTile(
              icon: Icons.help_outline_rounded,
              label: 'Bantuan',
            ),
            const _SettingTile(
              icon: Icons.info_outline_rounded,
              label: 'Tentang Aplikasi',
            ),
            Obx(() => _SettingTile(
              icon: Icons.delete_outline_rounded,
              label: controller.isClearingLocalData.value ? 'Menghapus Data Lokal...' : 'Hapus Data Lokal',
              color: AppColors.danger,
              onTap: controller.isClearingLocalData.value ? null : controller.deleteAllData,
            )),
            _SettingTile(
              icon: Icons.logout_rounded,
              label: 'Logout',
              color: AppColors.danger,
              onTap: controller.logout,
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupTitle extends StatelessWidget {
  const _GroupTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
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
