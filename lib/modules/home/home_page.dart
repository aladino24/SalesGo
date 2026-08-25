import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:salesgo/core/auth/app_roles.dart';
import 'package:salesgo/modules/settings/settings_controller.dart';

import '../../app/theme/app_colors.dart';
import '../../app/routes/app_routes.dart';
import '../../app/widgets/sfa_ui.dart';
import '../../core/auth/session_service.dart';
import '../../core/localization/app_locale.dart';
import '../../data/models/dashboard_model.dart';
import '../../data/datasources/local/visit_local_data_source.dart';
import '../../data/models/visit_model.dart';
import '../settings/settings_page.dart';
import '../information/information_controller.dart';
import '../../data/models/important_file_model.dart';
import '../../data/models/promotion_model.dart';
import '../visit/visit_page.dart';
import '../visit/visit_controller.dart';
import '../notification/notification_controller.dart';
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
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'home'.tr,
          ),
          NavigationDestination(
            icon: Icon(Icons.person_pin_circle_outlined),
            selectedIcon: Icon(Icons.person_pin_circle_rounded),
            label: 'visits'.tr,
          ),
          NavigationDestination(
            icon: Icon(Icons.view_agenda_outlined),
            selectedIcon: Icon(Icons.view_agenda_rounded),
            label: 'menu'.tr,
          ),
          NavigationDestination(
            icon: Icon(Icons.article_outlined),
            selectedIcon: Icon(Icons.article_rounded),
            label: 'information'.tr,
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'settings'.tr,
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
    final notifications = Get.find<NotificationController>();
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
                            session.userName.value.isEmpty ? 'Pengguna' : session.userName.value,
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
                  Obx(() => IconButton(
                    onPressed: () => Get.toNamed(AppRoutes.notifications),
                    icon: Badge(
                      isLabelVisible: notifications.unreadCount > 0,
                      label: Text(notifications.unreadCount > 99 ? '99+' : '${notifications.unreadCount}'),
                      child: const Icon(Icons.notifications_none_rounded),
                    ),
                  )),
                ],
              ),
              const SizedBox(height: 18),
              Obx(() => _SalesSummary(data: home.dashboard.value)),
              const SizedBox(height: 12),
              Obx(() => Row(
                children: [
                  Expanded(
                    child: _MiniMetric(
                      icon: Icons.flag_rounded,
                      title: 'Target',
                      value: 'Rp ${(home.dashboard.value?.monthlyTarget ?? 0).toStringAsFixed(0)}',
                      progress: '${_achievement(home.dashboard.value)}%',
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: _MiniMetric(
                      icon: Icons.route_rounded,
                      title: 'Kunjungan',
                      value: '${home.dashboard.value?.visitedOutlets ?? 0} / ${home.dashboard.value?.totalOutlets ?? 0}',
                      progress: 'Bulan ini',
                      color: AppColors.success,
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: _MiniMetric(
                      icon: Icons.account_balance_wallet_rounded,
                      title: 'Insentif',
                      value: 'Rp ${(home.dashboard.value?.incentive ?? 0).toStringAsFixed(0)}',
                      progress: '${(home.dashboard.value?.revenueGrowth ?? 0).toStringAsFixed(1)}%',
                      color: Color(0xFF7258EF),
                    ),
                  ),
                ],
              )),
              const SizedBox(height: 20),
              const SfaSectionTitle(title: 'Omset 6 Bulan Terakhir'),
              const SizedBox(height: 8),
              Obx(() => _BarChartCard(data: home.dashboard.value?.chart ?? const [])),
              const SizedBox(height: 20),
              SfaSectionTitle(
                title: 'Perjalanan Hari Ini',
                actionLabel: 'Lihat Semua',
                onAction: () => Get.toNamed(AppRoutes.journey),
              ),
              const SizedBox(height: 8),
              const _JourneyCard(),
              const SizedBox(height: 20),
              SfaSectionTitle(
                title: 'Aktivitas Terbaru',
                actionLabel: 'Lihat Semua',
                onAction: () => Get.toNamed(AppRoutes.activities),
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

String _achievement(DashboardModel? data) {
  final target = data?.monthlyTarget ?? 0;
  if (target <= 0) return '0.0';
  return (((data?.monthlyRevenue ?? 0) / target) * 100).toStringAsFixed(1);
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
  const _BarChartCard({required this.data});
  final List<Map<String, dynamic>> data;
  @override
  Widget build(BuildContext context) {
    final points = data.length > 7 ? data.sublist(data.length - 7) : data;
    if (points.isEmpty) return const SfaEmptyState(icon: Icons.bar_chart_outlined, title: 'Belum ada omset', description: 'Grafik akan muncul setelah transaksi committed diterima server.');
    final maximum = points.map((item) => (item['revenue'] as num? ?? 0).toDouble()).fold(0.0, (a, b) => a > b ? a : b);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
        child: SizedBox(
          height: 155,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(
              points.length,
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
                            heightFactor: maximum == 0 ? 0 : ((points[index]['revenue'] as num? ?? 0).toDouble() / maximum),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: .72),
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
                        points[index]['date']?.toString().substring(5) ?? '-',
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

class _JourneyCard extends GetView<VisitController> {
  const _JourneyCard();
  @override
  Widget build(BuildContext context) => Obx(
    () {
      // Kartu beranda hanya merepresentasikan rute wajib dari journey aktif,
      // bukan seluruh visit wajib lama yang kebetulan memiliki tanggal sama.
      final outlets = <String, VisitModel>{};
      for (final visit in controller.requiredTodayVisits) {
        final key = visit.outletId ?? visit.outletCode ?? visit.outletName;
        final current = outlets[key];
        if (current == null ||
            (current.status != 'Completed' && visit.status == 'Completed')) {
          outlets[key] = visit;
        }
      }
      final visits = outlets.values.toList();
      final completed = visits
          .where((visit) => visit.status == 'Completed')
          .length;
      final progress = visits.isEmpty ? 0.0 : completed / visits.length;
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _JourneyValue(label: 'Rute', value: 'Hari Ini'),
                  ),
                  Expanded(
                    child: _JourneyValue(
                      label: 'Outlet',
                      value: '${visits.length} Outlet',
                    ),
                  ),
                  Expanded(
                    child: _JourneyValue(
                      label: 'Progress',
                      value: '${(progress * 100).round()}%',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  color: AppColors.primary,
                  backgroundColor: AppColors.primarySoft,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Get.toNamed(AppRoutes.journey),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Mulai Perjalanan'),
                ),
              ),
            ],
          ),
        ),
      );
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

class _ActivityCard extends StatefulWidget {
  const _ActivityCard();

  @override
  State<_ActivityCard> createState() => _ActivityCardState();
}

class _ActivityCardState extends State<_ActivityCard> {
  late final Future<List<Box>> _boxes;

  @override
  void initState() {
    super.initState();
    _boxes = _openActivityBoxes();
  }

  Future<List<Box>> _openActivityBoxes() async => [
        Hive.isBoxOpen('journey_activities')
            ? Hive.box('journey_activities')
            : await Hive.openBox('journey_activities'),
        Hive.isBoxOpen('visits')
            ? Hive.box('visits')
            : await Hive.openBox('visits'),
        Hive.isBoxOpen('sync_audit_log')
            ? Hive.box('sync_audit_log')
            : await Hive.openBox('sync_audit_log'),
      ];

  @override
  Widget build(BuildContext context) => FutureBuilder<List<Box>>(
    future: _boxes,
    builder: (context, boxesSnapshot) {
      if (!boxesSnapshot.hasData) {
        return const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: LinearProgressIndicator(),
          ),
        );
      }
      final boxes = boxesSnapshot.data!;
      return ValueListenableBuilder<Box>(
        valueListenable: boxes[0].listenable(),
        builder: (_, __, ___) => ValueListenableBuilder<Box>(
          valueListenable: boxes[1].listenable(),
          builder: (_, __, ___) => ValueListenableBuilder<Box>(
            valueListenable: boxes[2].listenable(),
            builder: (_, __, ___) => _buildActivities(),
          ),
        ),
      );
    },
  );

  Widget _buildActivities() => FutureBuilder<List<_HomeActivity>>(
    future: _loadActivities(),
    builder: (context, snapshot) {
      final activities = (snapshot.data ?? []).take(3).toList();
      if (snapshot.connectionState != ConnectionState.done)
        return const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: LinearProgressIndicator(),
          ),
        );
      if (activities.isEmpty)
        return const Card(
          child: ListTile(
            leading: Icon(Icons.history_outlined),
            title: Text('Belum ada aktivitas terbaru'),
          ),
        );
      return Card(
        child: Column(
          children: [
            for (var index = 0; index < activities.length; index++) ...[
              if (index > 0) const Divider(height: 1),
              _ActivityRow(
                icon: activities[index].icon,
                color: activities[index].color,
                title: activities[index].title,
                subtitle: activities[index].subtitle,
                time: DateFormat(
                  'HH:mm',
                ).format(activities[index].createdAt.toLocal()),
              ),
            ],
          ],
        ),
      );
    },
  );
}

Future<List<_HomeActivity>> _loadActivities() async {
  final result = <_HomeActivity>[];
  final journeyBox = Hive.isBoxOpen('journey_activities')
      ? Hive.box('journey_activities')
      : await Hive.openBox('journey_activities');
  for (final raw in journeyBox.values.whereType<Map>()) {
    final item = Map<String, dynamic>.from(raw);
    final started = item['event']?.toString() == 'Perjalanan dimulai';
    final createdAt = DateTime.tryParse(item['createdAt']?.toString() ?? '');
    if (createdAt != null) {
      result.add(_HomeActivity(
        title: item['event']?.toString() ?? 'Perjalanan',
        subtitle: item['description']?.toString() ?? 'Perjalanan Sales',
        createdAt: createdAt,
        icon: started ? Icons.play_circle_fill_rounded : Icons.stop_circle_rounded,
        color: started ? AppColors.primary : AppColors.success,
      ));
    }
  }
  for (final visit in await VisitLocalDataSource().getVisits()) {
    result.add(_HomeActivity(
      title: visit.status,
      subtitle: visit.outletName,
      createdAt: visit.createdAt,
      icon: visit.status == 'Completed' ? Icons.check_circle_rounded : Icons.location_on_rounded,
      color: visit.status == 'Completed' ? AppColors.success : AppColors.primary,
    ));
  }
  final auditBox = Hive.isBoxOpen('sync_audit_log')
      ? Hive.box('sync_audit_log')
      : await Hive.openBox('sync_audit_log');
  final latestAudits = <String, Map<String, dynamic>>{};
  for (final raw in auditBox.values.whereType<Map>()) {
    final item = Map<String, dynamic>.from(raw);
    final key = item['syncItemId']?.toString() ?? item['id']?.toString() ?? '';
    final current = latestAudits[key];
    final createdAt = DateTime.tryParse(item['createdAt']?.toString() ?? '');
    final currentAt = DateTime.tryParse(current?['createdAt']?.toString() ?? '');
    if (current == null ||
        (createdAt != null && (currentAt == null || createdAt.isAfter(currentAt)))) {
      latestAudits[key] = item;
    }
  }
  for (final item in latestAudits.values) {
    final createdAt = DateTime.tryParse(item['createdAt']?.toString() ?? '');
    if (createdAt == null) continue;
    final event = item['event']?.toString() ?? '';
    result.add(_HomeActivity(
      title: event == 'sync_succeeded' ? 'Sinkronisasi berhasil' : 'Sinkronisasi pending',
      subtitle: item['message']?.toString() ??
          item['type']?.toString().replaceAll('_', ' ') ??
          'Aktivitas antrean server',
      createdAt: createdAt,
      icon: event == 'sync_succeeded'
          ? Icons.cloud_done_rounded
          : Icons.cloud_upload_outlined,
      color: event == 'sync_succeeded' ? AppColors.success : AppColors.warning,
    ));
  }
  result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return result;
}

class _HomeActivity {
  const _HomeActivity({required this.title, required this.subtitle, required this.createdAt, required this.icon, required this.color});
  final String title;
  final String subtitle;
  final DateTime createdAt;
  final IconData icon;
  final Color color;
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
      title: 'Menu',
      subtitle: '${role?.label ?? 'Pengguna'} • fitur sesuai peran Anda',
      sections: [
        if (role?.canApproveTransaction ?? false) _GridSection('Approval', [
          _GridItem(
            Icons.assignment_turned_in_outlined,
            'Approval Order',
            AppColors.primary,
            null,
            onTap: () => Get.toNamed(AppRoutes.approval),
          ),
          _GridItem(
            Icons.assignment_return_outlined,
            'Approval Retur',
            Color(0xFF0EA5E9),
            null,
            onTap: () => Get.toNamed(AppRoutes.approval),
          ),
          _GridItem(
            Icons.card_giftcard_rounded,
            'Approval Hadiah',
            Color(0xFF7258EF),
            null,
            onTap: () => Get.toNamed(AppRoutes.approval),
          ),
          _GridItem(
            Icons.note_alt_outlined,
            'Approval Catatan',
            Color(0xFF7258EF),
            null,
            onTap: () => Get.toNamed(AppRoutes.approval),
          ),
          _GridItem(
            Icons.luggage_outlined,
            'Approval Perjalanan',
            AppColors.primary,
            null,
            onTap: () => Get.toNamed(AppRoutes.approval),
          ),
          _GridItem(
            Icons.sell_outlined,
            'Approval Promo',
            AppColors.navy,
            null,
            onTap: () => Get.toNamed(AppRoutes.approval),
          ),
        ]),
        if (canMonitor)
          _GridSection('Monitoring', [
            _GridItem(
              Icons.groups_rounded,
              'Monitoring Tim',
              AppColors.success,
              null,
              onTap: () => Get.toNamed(AppRoutes.monitoring),
            ),
            _GridItem(
              Icons.map_outlined,
              'Kunjungan Sales',
              AppColors.primary,
              null,
              onTap: () => Get.toNamed(AppRoutes.monitoring),
            ),
            _GridItem(
              Icons.analytics_outlined,
              'Omset & Target',
              AppColors.warning,
              null,
              onTap: () => Get.toNamed(AppRoutes.monitoring),
            ),
            _GridItem(
              Icons.route_rounded,
              'Master Rute',
              Color(0xFF7258EF),
              null,
              onTap: () => Get.toNamed(AppRoutes.routeMaster),
            ),
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
            onTap: () => _showMasterDataPicker(),
          ),
          _GridItem(
            Icons.sync_rounded,
            'Sinkronisasi',
            Color(0xFF0EA5E9),
            null,
            onTap: () => Get.find<SettingsController>().syncData(),
          ),
          _GridItem(
            Icons.videocam_outlined,
            'Meeting Online',
            Color(0xFF7258EF),
            null,
            onTap: () => Get.toNamed(AppRoutes.meetings),
          ),
        ]),
      ],
    );
  }

  void _showMasterDataPicker() {
    Get.bottomSheet(
      SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Data Master',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.inventory_2_outlined),
                ),
                title: const Text('Produk'),
                subtitle: const Text('Lihat stok dan harga produk'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Get.back();
                  Get.toNamed(AppRoutes.product);
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.storefront_outlined),
                ),
                title: const Text('Outlet'),
                subtitle: const Text('Lihat outlet yang ditugaskan'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Get.back();
                  Get.toNamed(AppRoutes.outlet);
                },
              ),
            ],
          ),
        ),
      ),
    );
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
              tabs: [
                Tab(text: 'Promosi'),
                Tab(text: 'Produk'),
                Tab(text: 'File Penting'),
                Tab(text: 'Berita'),
              ],
            ),
            Expanded(
              child: Obx(
                () =>
                    controller.isLoading.value &&
                        controller.promotions.isEmpty &&
                        controller.files.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : TabBarView(
                        children: [
                          _PromotionList(items: controller.promotions),
                          const _InformationEmpty(
                            icon: Icons.inventory_2_outlined,
                            title: 'Gunakan menu Produk',
                            description:
                                'Daftar produk tersedia dari menu utama aplikasi.',
                          ),
                          _ImportantFileList(
                            files: controller.files,
                            downloadingIds: controller.downloadingIds,
                            onDownload: controller.downloadFile,
                            onOpen: controller.openFile,
                            onRemoveCache: controller.removeFileCache,
                            cacheUsageBytes: controller.cacheUsageBytes.value,
                            cacheQuotaBytes: controller.cacheQuotaBytes.value,
                          ),
                          const _InformationEmpty(
                            icon: Icons.newspaper_outlined,
                            title: 'Belum ada berita',
                            description:
                                'Berita terbaru akan tampil setelah tersedia dari server.',
                          ),
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
    if (items.isEmpty)
      return const _InformationEmpty(
        icon: Icons.local_offer_outlined,
        title: 'Belum ada promosi',
        description:
            'Promosi yang tersedia akan tersimpan untuk dibuka saat offline.',
      );
    return RefreshIndicator(
      onRefresh: Get.find<InformationController>().refreshData,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, index) {
          final item = items[index];
          final color = item.status.toLowerCase().contains('baru')
              ? AppColors.warning
              : AppColors.primary;
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: color.withValues(alpha: .14),
                child: Icon(Icons.local_offer_rounded, color: color),
              ),
              title: Text(
                item.title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: Text(
                '${AppLocale.date('d MMM y').format(item.startAt)} - ${AppLocale.date('d MMM y').format(item.endAt)}\n${item.description}',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              isThreeLine: true,
              trailing: SfaStatusChip(label: item.status, color: color),
            ),
          );
        },
      ),
    );
  }
}

class _ImportantFileList extends StatelessWidget {
  const _ImportantFileList({
    required this.files,
    required this.downloadingIds,
    required this.onDownload,
    required this.onOpen,
    required this.onRemoveCache,
    required this.cacheUsageBytes,
    required this.cacheQuotaBytes,
  });
  final List<ImportantFileModel> files;
  final Set<String> downloadingIds;
  final ValueChanged<ImportantFileModel> onDownload;
  final ValueChanged<ImportantFileModel> onOpen;
  final ValueChanged<ImportantFileModel> onRemoveCache;
  final int cacheUsageBytes, cacheQuotaBytes;

  @override
  Widget build(BuildContext context) {
    if (files.isEmpty)
      return const _InformationEmpty(
        icon: Icons.folder_open_outlined,
        title: 'Belum ada file penting',
        description:
            'File dari server dapat diunduh dan tersedia kembali saat offline.',
      );
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: _FileCacheSummary(
            usedBytes: cacheUsageBytes,
            quotaBytes: cacheQuotaBytes,
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: Get.find<InformationController>().refreshData,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              itemCount: files.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, index) {
                final file = files[index];
                final downloading = downloadingIds.contains(file.id);
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primarySoft,
                      child: const Icon(
                        Icons.description_outlined,
                        color: AppColors.primary,
                      ),
                    ),
                    title: Text(
                      file.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      '${file.type.toUpperCase()} - ${_formatBytes(file.size)} - v${file.version}\nDiperbarui ${AppLocale.date('d MMM y, HH:mm').format(file.updatedAt)}',
                    ),
                    isThreeLine: true,
                    onTap: file.isCached ? () => onOpen(file) : null,
                    trailing: downloading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : file.isCached
                        ? PopupMenuButton<String>(
                            onSelected: (action) {
                              if (action == 'open') onOpen(file);
                              if (action == 'remove') onRemoveCache(file);
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                value: 'open',
                                child: Text('Buka File'),
                              ),
                              PopupMenuItem(
                                value: 'remove',
                                child: Text('Hapus Cache'),
                              ),
                            ],
                            child: const SfaStatusChip(
                              label: 'Tersimpan',
                              color: AppColors.success,
                            ),
                          )
                        : IconButton(
                            onPressed: () => onDownload(file),
                            icon: const Icon(Icons.download_rounded),
                            tooltip: 'Unduh untuk offline',
                          ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  String _formatBytes(int bytes) => _formatFileBytes(bytes);
}

class _FileCacheSummary extends StatelessWidget {
  const _FileCacheSummary({required this.usedBytes, required this.quotaBytes});
  final int usedBytes, quotaBytes;
  @override
  Widget build(BuildContext context) {
    final ratio = quotaBytes == 0
        ? 0.0
        : (usedBytes / quotaBytes).clamp(0, 1).toDouble();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Penyimpanan File Offline',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: ratio,
              minHeight: 7,
              color: ratio > .9 ? AppColors.danger : AppColors.primary,
              backgroundColor: AppColors.primarySoft,
            ),
            const SizedBox(height: 6),
            Text(
              '${_formatFileBytes(usedBytes)} dari ${_formatFileBytes(quotaBytes)} digunakan',
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatFileBytes(int bytes) => bytes < 1024 * 1024
    ? '${(bytes / 1024).toStringAsFixed(0)} KB'
    : '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';

class _InformationEmpty extends StatelessWidget {
  const _InformationEmpty({
    required this.icon,
    required this.title,
    required this.description,
  });
  final IconData icon;
  final String title, description;
  @override
  Widget build(BuildContext context) =>
      SfaEmptyState(icon: icon, title: title, description: description);
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
    backgroundColor: const Color(0xFFF7F9FE),
    body: Stack(children: [
      Container(
        height: 188,
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFF3983FF), AppColors.primaryDark]),
          borderRadius: BorderRadius.vertical(bottom: Radius.elliptical(220, 42)),
        ),
      ),
      SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Row(children: [Icon(Icons.grid_view_rounded, color: Colors.white), SizedBox(width: 8), Text('SalesGo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700))]),
              const SizedBox(height: 16),
              Text(title, style: const TextStyle(fontSize: 26, color: Colors.white, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: .82))),
            ]),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 22, 16, 28),
              children: sections,
            ),
          ),
        ]),
      ),
    ]),
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
        Row(children: [Container(width: 4, height: 18, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(4))), const SizedBox(width: 8), Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800))]),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.0,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
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
