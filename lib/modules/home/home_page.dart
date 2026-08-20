import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:salesgo/core/auth/app_roles.dart';

import '../../app/theme/app_colors.dart';
import '../../app/routes/app_routes.dart';
import '../../app/widgets/sfa_ui.dart';
import '../../core/auth/session_service.dart';
import '../../data/models/dashboard_model.dart';
import '../../data/datasources/local/visit_local_data_source.dart';
import '../../data/models/visit_model.dart';
import '../settings/settings_page.dart';
import '../information/information_controller.dart';
import '../../data/models/important_file_model.dart';
import '../../data/models/promotion_model.dart';
import '../visit/visit_page.dart';
import 'home_controller.dart';

class HomePage extends GetView<HomeController> {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) => Obx(
    () => Scaffold(
      body: IndexedStack(
        index: controller.selectedIndex.value,
        children: const [
          _DashboardTab(),
          VisitPage(),
          _MenuTab(),
          _InformationTab(),
          SettingsPage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: controller.selectedIndex.value,
        onDestinationSelected: controller.changeTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_pin_circle_outlined),
            selectedIcon: Icon(Icons.person_pin_circle_rounded),
            label: 'Kunjungan',
          ),
          NavigationDestination(
            icon: Icon(Icons.view_agenda_outlined),
            selectedIcon: Icon(Icons.view_agenda_rounded),
            label: 'Menu',
          ),
          NavigationDestination(
            icon: Icon(Icons.article_outlined),
            selectedIcon: Icon(Icons.article_rounded),
            label: 'Informasi',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Pengaturan',
          ),
        ],
      ),
    ),
  );
}

class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    final session = Get.find<SessionService>();
    final home = Get.find<HomeController>();
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Obx(
                      () => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Selamat pagi,',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            session.userName.value.isEmpty
                                ? 'Andi Pratama'
                                : session.userName.value,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          SfaStatusChip(
                            label: session.currentRole.value?.label ?? 'Sales',
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Get.toNamed(AppRoutes.notifications),
                    icon: Badge(
                      child: const Icon(Icons.notifications_none_rounded),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Obx(() => _SalesSummary(data: home.dashboard.value)),
              const SizedBox(height: 12),
              const Row(
                children: [
                  Expanded(
                    child: _MiniMetric(
                      icon: Icons.flag_rounded,
                      title: 'Target',
                      value: 'Rp 70.000.000',
                      progress: '69,6%',
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: _MiniMetric(
                      icon: Icons.route_rounded,
                      title: 'Kunjungan',
                      value: '32 / 45',
                      progress: '71%',
                      color: AppColors.success,
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: _MiniMetric(
                      icon: Icons.account_balance_wallet_rounded,
                      title: 'Insentif',
                      value: 'Rp 5.250.000',
                      progress: '↑ 6%',
                      color: Color(0xFF7258EF),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const SfaSectionTitle(title: 'Omset 6 Bulan Terakhir'),
              const SizedBox(height: 8),
              const _BarChartCard(),
              const SizedBox(height: 20),
              SfaSectionTitle(
                title: 'Perjalanan Hari Ini',
                actionLabel: 'Lihat Semua',
                onAction: () => Get.toNamed(AppRoutes.journey),
              ),
              const SizedBox(height: 8),
              const _JourneyCard(),
              const SizedBox(height: 20),
              const SfaSectionTitle(
                title: 'Aktivitas Terbaru',
                actionLabel: 'Lihat Semua',
              ),
              const SizedBox(height: 8),
              const _ActivityCard(),
            ],
          ),
        ),
      ),
    );
  }
}

class _SalesSummary extends StatelessWidget {
  const _SalesSummary({this.data});
  final DashboardModel? data;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF3983FF), AppColors.primaryDark],
      ),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Total Omset (Bulan Ini)',
          style: TextStyle(
            color: Colors.white.withValues(alpha: .78),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Rp ${(data?.monthlyRevenue ?? 0).toStringAsFixed(0)}',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 25,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(
              Icons.trending_up_rounded,
              color: Color(0xFF81F5AD),
              size: 16,
            ),
            const SizedBox(width: 5),
            Text(
              '${(data?.revenueGrowth ?? 0).toStringAsFixed(1)}% dari bulan lalu',
              style: TextStyle(
                color: Colors.white.withValues(alpha: .9),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({
    required this.icon,
    required this.title,
    required this.value,
    required this.progress,
    required this.color,
  });
  final IconData icon;
  final String title, value, progress;
  final Color color;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: color),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            progress,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ),
  );
}

class _BarChartCard extends StatelessWidget {
  const _BarChartCard();
  @override
  Widget build(BuildContext context) {
    const bars = [48.0, 72.0, 98.0, 78.0, 86.0, 63.0],
        months = ['Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu'];
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
        child: SizedBox(
          height: 155,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(
              bars.length,
              (index) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: FractionallySizedBox(
                            heightFactor: bars[index] / 100,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: index == 3
                                    ? AppColors.primaryDark
                                    : AppColors.primary.withValues(alpha: .72),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(4),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        months[index],
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _JourneyCard extends StatelessWidget {
  const _JourneyCard();
  @override
  Widget build(BuildContext context) => FutureBuilder<List<VisitModel>>(
    future: VisitLocalDataSource().getVisits(),
    builder: (context, snapshot) {
      final today = DateTime.now();
      final visits = (snapshot.data ?? []).where((visit) { final date = visit.createdAt.toLocal(); return date.year == today.year && date.month == today.month && date.day == today.day; }).toList();
      final completed = visits.where((visit) => visit.status == 'Completed').length;
      final progress = visits.isEmpty ? 0.0 : completed / visits.length;
      return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
        Row(children: [Expanded(child: _JourneyValue(label: 'Rute', value: 'Hari Ini')), Expanded(child: _JourneyValue(label: 'Outlet', value: '${visits.length} Outlet')), Expanded(child: _JourneyValue(label: 'Progress', value: '${(progress * 100).round()}%'))]),
        const SizedBox(height: 14), ClipRRect(borderRadius: BorderRadius.circular(5), child: LinearProgressIndicator(value: progress, minHeight: 8, color: AppColors.primary, backgroundColor: AppColors.primarySoft)),
      ])));
    },
  );
}

class _JourneyValue extends StatelessWidget {
  const _JourneyValue({required this.label, required this.value});
  final String label, value;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
      ),
      const SizedBox(height: 3),
      Text(
        value,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
    ],
  );
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard();
  @override
  Widget build(BuildContext context) => FutureBuilder<List<VisitModel>>(
    future: VisitLocalDataSource().getVisits(),
    builder: (context, snapshot) {
      final visits = (snapshot.data ?? []).take(2).toList();
      if (snapshot.connectionState != ConnectionState.done) return const Card(child: Padding(padding: EdgeInsets.all(16), child: LinearProgressIndicator()));
      if (visits.isEmpty) return const Card(child: ListTile(leading: Icon(Icons.history_outlined), title: Text('Belum ada aktivitas terbaru')));
      return Card(child: Column(children: [for (var index = 0; index < visits.length; index++) ...[if (index > 0) const Divider(height: 1), _ActivityRow(icon: visits[index].status == 'Completed' ? Icons.check_circle_rounded : Icons.location_on_rounded, color: visits[index].status == 'Completed' ? AppColors.success : AppColors.primary, title: visits[index].status, subtitle: visits[index].outletName, time: DateFormat('HH:mm').format(visits[index].createdAt.toLocal()))]]));
    },
  );
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.time,
  });
  final IconData icon;
  final Color color;
  final String title, subtitle, time;
  @override
  Widget build(BuildContext context) => ListTile(
    leading: CircleAvatar(
      backgroundColor: color.withValues(alpha: .12),
      child: Icon(icon, color: color, size: 19),
    ),
    title: Text(
      title,
      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
    ),
    subtitle: Text(
      subtitle,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
    ),
    trailing: Text(
      time,
      style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
    ),
  );
}

class _MenuTab extends StatelessWidget {
  const _MenuTab();
  @override
  Widget build(BuildContext context) {
    final role = Get.find<SessionService>().currentRole.value;
    final canMonitor = role?.canMonitorTeam ?? false;
    return _GridScreen(
      title: 'Menu', subtitle: 'Fitur sesuai peran Anda', sections: [
      _GridSection('Approval', [
        _GridItem(
          Icons.assignment_turned_in_outlined,
          'Approval Order',
          AppColors.primary,
          '8',
        ),
        _GridItem(
          Icons.assignment_return_outlined,
          'Approval Retur',
          Color(0xFF0EA5E9),
          '3',
        ),
        _GridItem(
          Icons.card_giftcard_rounded,
          'Approval Hadiah',
          Color(0xFF7258EF),
          '5',
        ),
        _GridItem(
          Icons.note_alt_outlined,
          'Approval Catatan',
          Color(0xFF7258EF),
          null,
        ),
        _GridItem(
          Icons.luggage_outlined,
          'Approval Perjalanan',
          AppColors.primary,
          null,
        ),
        _GridItem(Icons.sell_outlined, 'Approval Promo', AppColors.navy, '2'),
      ]),
      if (canMonitor) _GridSection('Monitoring', [
        _GridItem(Icons.groups_rounded, 'Monitoring Tim', AppColors.success, null, onTap: () => Get.toNamed(AppRoutes.monitoring)),
        _GridItem(Icons.map_outlined, 'Kunjungan Sales', AppColors.primary, null, onTap: () => Get.toNamed(AppRoutes.monitoring)),
        _GridItem(Icons.analytics_outlined, 'Omset & Target', AppColors.warning, null, onTap: () => Get.toNamed(AppRoutes.monitoring)),
      ]),
      _GridSection('Lainnya', [
        _GridItem(
          Icons.description_outlined,
          'Laporan',
          Color(0xFF7258EF),
          null,
          onTap: canMonitor ? () => Get.toNamed(AppRoutes.reports) : null,
        ),
        _GridItem(
          Icons.storage_outlined,
          'Data Master',
          AppColors.primary,
          null,
        ),
        _GridItem(Icons.sync_rounded, 'Sinkronisasi', Color(0xFF0EA5E9), null),
      ]),
    ]);
  }
}

class _InformationTab extends GetView<InformationController> {
  const _InformationTab();
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text(
        'Informasi',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
      actions: [
        IconButton(onPressed: () {}, icon: const Icon(Icons.search_rounded)),
      ],
    ),
    body: SafeArea(
      child: DefaultTabController(
        length: 4,
        child: Column(
          children: [
            const TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: [Tab(text: 'Promosi'), Tab(text: 'Produk'), Tab(text: 'File Penting'), Tab(text: 'Berita')],
            ),
            Expanded(
              child: Obx(
                () => controller.isLoading.value && controller.promotions.isEmpty && controller.files.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : TabBarView(
                        children: [
                          _PromotionList(items: controller.promotions),
                          const _InformationEmpty(icon: Icons.inventory_2_outlined, title: 'Gunakan menu Produk', description: 'Daftar produk tersedia dari menu utama aplikasi.'),
                          _ImportantFileList(
                            files: controller.files,
                            downloadingIds: controller.downloadingIds,
                            onDownload: controller.downloadFile,
                            onOpen: controller.openFile,
                            onRemoveCache: controller.removeFileCache,
                            cacheUsageBytes: controller.cacheUsageBytes.value,
                            cacheQuotaBytes: controller.cacheQuotaBytes.value,
                          ),
                          const _InformationEmpty(icon: Icons.newspaper_outlined, title: 'Belum ada berita', description: 'Berita terbaru akan tampil setelah tersedia dari server.'),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _PromotionList extends StatelessWidget {
  const _PromotionList({required this.items});
  final List<PromotionModel> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const _InformationEmpty(icon: Icons.local_offer_outlined, title: 'Belum ada promosi', description: 'Promosi yang tersedia akan tersimpan untuk dibuka saat offline.');
    return RefreshIndicator(
      onRefresh: Get.find<InformationController>().refreshData,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, index) {
          final item = items[index];
          final color = item.status.toLowerCase().contains('baru') ? AppColors.warning : AppColors.primary;
          return Card(child: ListTile(
            leading: CircleAvatar(backgroundColor: color.withValues(alpha: .14), child: Icon(Icons.local_offer_rounded, color: color)),
            title: Text(item.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            subtitle: Text('${DateFormat('d MMM y', 'id').format(item.startAt)} - ${DateFormat('d MMM y', 'id').format(item.endAt)}\n${item.description}', maxLines: 3, overflow: TextOverflow.ellipsis),
            isThreeLine: true,
            trailing: SfaStatusChip(label: item.status, color: color),
          ));
        },
      ),
    );
  }
}

class _ImportantFileList extends StatelessWidget {
  const _ImportantFileList({required this.files, required this.downloadingIds, required this.onDownload, required this.onOpen, required this.onRemoveCache, required this.cacheUsageBytes, required this.cacheQuotaBytes});
  final List<ImportantFileModel> files;
  final Set<String> downloadingIds;
  final ValueChanged<ImportantFileModel> onDownload;
  final ValueChanged<ImportantFileModel> onOpen;
  final ValueChanged<ImportantFileModel> onRemoveCache;
  final int cacheUsageBytes, cacheQuotaBytes;

  @override
  Widget build(BuildContext context) {
    if (files.isEmpty) return const _InformationEmpty(icon: Icons.folder_open_outlined, title: 'Belum ada file penting', description: 'File dari server dapat diunduh dan tersedia kembali saat offline.');
    return Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 8), child: _FileCacheSummary(usedBytes: cacheUsageBytes, quotaBytes: cacheQuotaBytes)),
      Expanded(child: RefreshIndicator(
        onRefresh: Get.find<InformationController>().refreshData,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16), itemCount: files.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, index) {
            final file = files[index];
            final downloading = downloadingIds.contains(file.id);
            return Card(child: ListTile(
              leading: CircleAvatar(backgroundColor: AppColors.primarySoft, child: const Icon(Icons.description_outlined, color: AppColors.primary)),
              title: Text(file.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              subtitle: Text('${file.type.toUpperCase()} - ${_formatBytes(file.size)} - v${file.version}\nDiperbarui ${DateFormat('d MMM y, HH:mm', 'id').format(file.updatedAt)}'),
              isThreeLine: true,
              onTap: file.isCached ? () => onOpen(file) : null,
              trailing: downloading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : file.isCached
                      ? PopupMenuButton<String>(
                          onSelected: (action) { if (action == 'open') onOpen(file); if (action == 'remove') onRemoveCache(file); },
                          itemBuilder: (_) => const [PopupMenuItem(value: 'open', child: Text('Buka File')), PopupMenuItem(value: 'remove', child: Text('Hapus Cache'))],
                          child: const SfaStatusChip(label: 'Tersimpan', color: AppColors.success),
                        )
                      : IconButton(onPressed: () => onDownload(file), icon: const Icon(Icons.download_rounded), tooltip: 'Unduh untuk offline'),
            ));
          },
        ),
      )),
    ]);
  }

  String _formatBytes(int bytes) => _formatFileBytes(bytes);
}

class _FileCacheSummary extends StatelessWidget {
  const _FileCacheSummary({required this.usedBytes, required this.quotaBytes});
  final int usedBytes, quotaBytes;
  @override
  Widget build(BuildContext context) {
    final ratio = quotaBytes == 0 ? 0.0 : (usedBytes / quotaBytes).clamp(0, 1).toDouble();
    return Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Penyimpanan File Offline', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      LinearProgressIndicator(value: ratio, minHeight: 7, color: ratio > .9 ? AppColors.danger : AppColors.primary, backgroundColor: AppColors.primarySoft),
      const SizedBox(height: 6),
      Text('${_formatFileBytes(usedBytes)} dari ${_formatFileBytes(quotaBytes)} digunakan', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
    ])));
  }
}

String _formatFileBytes(int bytes) => bytes < 1024 * 1024 ? '${(bytes / 1024).toStringAsFixed(0)} KB' : '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';

class _InformationEmpty extends StatelessWidget {
  const _InformationEmpty({required this.icon, required this.title, required this.description});
  final IconData icon; final String title, description;
  @override Widget build(BuildContext context) => SfaEmptyState(icon: icon, title: title, description: description);
}

class _GridScreen extends StatelessWidget {
  const _GridScreen({
    required this.title,
    required this.subtitle,
    required this.sections,
  });
  final String title, subtitle;
  final List<_GridSection> sections;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
    ),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 22),
          ...sections,
        ],
      ),
    ),
  );
}

class _GridSection extends StatelessWidget {
  const _GridSection(this.title, this.items);
  final String title;
  final List<_GridItem> items;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.05,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          children: items,
        ),
      ],
    ),
  );
}

class _GridItem extends StatelessWidget {
  const _GridItem(this.icon, this.label, this.color, this.badge, {this.onTap});
  final IconData icon;
  final String label;
  final Color color;
  final String? badge;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => SfaIconTile(
    icon: icon,
    label: label,
    color: color,
    badge: badge,
    onTap: onTap,
  );
}
