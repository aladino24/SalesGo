import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/auth/app_roles.dart';
import '../../core/auth/session_service.dart';
import '../settings/settings_page.dart';
import '../visit/visit_page.dart';
import 'home_controller.dart';

class HomePage extends GetView<HomeController> {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        backgroundColor: const Color(0xFFF5F7FB),
        body: IndexedStack(
          index: controller.selectedIndex.value,
          children: const [
            _HomeTab(),
            VisitPage(),
            _PromotionTab(),
            SettingsPage(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: controller.selectedIndex.value,
          onDestinationSelected: controller.changeTab,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_rounded), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.route_rounded), label: 'Kunjungan'),
            NavigationDestination(icon: Icon(Icons.local_offer_rounded), label: 'Promosi'),
            NavigationDestination(icon: Icon(Icons.settings_rounded), label: 'Setting'),
          ],
        ),
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    final session = Get.find<SessionService>();
    final canViewApproval =
        session.currentRole.value == AppRole.supervisor ||
        session.currentRole.value == AppRole.branchManager;

    final challengeCards = [
      {
        'title': 'Omset Hari Ini',
        'current': 'Rp 12.5 Juta',
        'target': 'Rp 15 Juta',
        'progress': 0.85,
        'icon': Icons.trending_up_rounded,
        'color': const Color(0xFF4F46E5),
        'bgGradient': [const Color(0xFF6366F1), const Color(0xFF4F46E5)],
      },
      {
        'title': 'Target Bulan',
        'current': 'Rp 375 Juta',
        'target': 'Rp 500 Juta',
        'progress': 0.75,
        'icon': Icons.assessment_rounded,
        'color': const Color(0xFF0EA5E9),
        'bgGradient': [const Color(0xFF38BDF8), const Color(0xFF0EA5E9)],
      },
      {
        'title': 'Insentif',
        'current': 'Rp 12.5 Juta',
        'target': 'Rp 18.4 Juta',
        'progress': 0.68,
        'icon': Icons.savings_rounded,
        'color': const Color(0xFF10B981),
        'bgGradient': [const Color(0xFF34D399), const Color(0xFF10B981)],
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Home',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            onPressed: Get.find<HomeController>().refreshDashboard,
            icon: const Icon(Icons.sync_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Obx(
                () => _HeaderCard(
                  name: session.userName.value.isNotEmpty ? session.userName.value : 'Sales',
                  role: session.currentRole.value?.label ?? 'Sales',
                  isOnline: Get.find<HomeController>().status.value != 'offline',
                ),
              ),
              const SizedBox(height: 16),
              _SectionHeader(title: 'Challenge Bulan Ini'),
              const SizedBox(height: 12),
              ...challengeCards.map((card) => _ChallengeCard(
                title: card['title'] as String,
                current: card['current'] as String,
                target: card['target'] as String,
                progress: card['progress'] as double,
                icon: card['icon'] as IconData,
                accentColor: card['color'] as Color,
                gradientColors: card['bgGradient'] as List<Color>,
              )),
              const SizedBox(height: 20),
              _SectionHeader(title: 'Sales Trend'),
              const SizedBox(height: 8),
              const _SalesBarChart(),
              const SizedBox(height: 16),
              _SectionHeader(title: 'Quick Actions'),
              const SizedBox(height: 8),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.15,
                children: [
                  _QuickActionCard(
                    icon: Icons.store_rounded,
                    label: 'Outlet',
                    color: const Color(0xFF4F46E5),
                    onTap: () => Get.toNamed('/outlet'),
                  ),
                  _QuickActionCard(
                    icon: Icons.inventory_2_rounded,
                    label: 'Produk',
                    color: const Color(0xFF0EA5E9),
                    onTap: () => Get.toNamed('/product'),
                  ),
                  _QuickActionCard(
                    icon: Icons.route_rounded,
                    label: 'Kunjungan',
                    color: const Color(0xFF10B981),
                    onTap: () => Get.toNamed('/visit'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _SectionHeader(title: 'Today\'s Activity'),
              const SizedBox(height: 8),
              const _ActivityTimeline(
                activities: [
                  _ActivityItem(
                    time: '08:10',
                    title: 'Mulai perjalanan',
                    icon: Icons.play_circle_filled_rounded,
                    color: Color(0xFF4F46E5),
                  ),
                  _ActivityItem(
                    time: '08:45',
                    title: 'Check-in Outlet A',
                    icon: Icons.location_on_rounded,
                    color: Color(0xFF0EA5E9),
                  ),
                  _ActivityItem(
                    time: '09:30',
                    title: 'Membuat Sales Order',
                    icon: Icons.receipt_long_rounded,
                    color: Color(0xFFF59E0B),
                  ),
                  _ActivityItem(
                    time: '10:15',
                    title: 'Checkout Outlet A',
                    icon: Icons.check_circle_rounded,
                    color: Color(0xFF10B981),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _SectionHeader(title: 'Meeting Online'),
              const SizedBox(height: 8),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.videocam_rounded, color: Color(0xFF4F46E5)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Daily sync meeting',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '08:30 - 09:00 | Join meeting',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      FilledButton(
                        onPressed: () {},
                        child: const Text('Join'),
                      ),
                    ],
                  ),
                ),
              ),
              if (canViewApproval) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => Get.toNamed('/approval'),
                    icon: const Icon(Icons.approval_rounded),
                    label: const Text('Approval Center'),
                  ),
                )
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PromotionTab extends StatelessWidget {
  const _PromotionTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Promosi',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.local_offer_rounded,
                size: 64,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                'Promosi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Fitur promosi segera hadir',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.name,
    required this.role,
    required this.isOnline,
  });

  final String name;
  final String role;
  final bool isOnline;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1D4ED8), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selamat pagi,',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      name,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isOnline
                      ? Colors.green.withValues(alpha: 0.15)
                      : Colors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  children: [
                    Icon(
                      isOnline ? Icons.cloud_done_rounded : Icons.signal_wifi_off_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isOnline ? 'Online' : 'Offline',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.badge_rounded, color: Colors.white70, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Role: $role',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  const _ChallengeCard({
    required this.title,
    required this.current,
    required this.target,
    required this.progress,
    required this.icon,
    required this.accentColor,
    required this.gradientColors,
  });

  final String title;
  final String current;
  final String target;
  final double progress;
  final IconData icon;
  final Color accentColor;
  final List<Color> gradientColors;

  String get _progressPercentage => '${(progress * 100).toStringAsFixed(0)}%';
  
  String get _achievementStatus {
    if (progress >= 1.0) return '🏆 Target Tercapai!';
    if (progress >= 0.8) return '⭐ Hampir Selesai';
    if (progress >= 0.6) return '🚀 Keep Going';
    return '💪 Mulai Gerak';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              left: -50,
              bottom: -50,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _achievementStatus,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          icon,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      children: [
                        Container(
                          height: 10,
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                        Container(
                          height: 10,
                          width: double.infinity * progress,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withValues(alpha: 0.9),
                                Colors.white,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pencapaian',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            current,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Progress',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _progressPercentage,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Target',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            target,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SalesBarChart extends StatelessWidget {
  const _SalesBarChart();

  @override
  Widget build(BuildContext context) {
    final values = [0.42, 0.58, 0.68, 0.56, 0.9, 0.72, 0.86];
    final labels = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Penjualan 7 Hari',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  '+18.2%',
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 200,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(values.length, (index) {
                  final value = values[index];
                  final height = 40 + (value * 120);

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            height: height,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF60A5FA),
                                  const Color(0xFF4F46E5),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            labels[index],
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _ActivityItem {
  const _ActivityItem({
    required this.time,
    required this.title,
    required this.icon,
    required this.color,
  });

  final String time;
  final String title;
  final IconData icon;
  final Color color;
}

class _ActivityTimeline extends StatelessWidget {
  const _ActivityTimeline({required this.activities});

  final List<_ActivityItem> activities;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          children: List.generate(activities.length, (index) {
            final activity = activities[index];
            final isLast = index == activities.length - 1;

            return Column(
              children: [
                SizedBox(
                  height: 70,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          if (index > 0)
                            Container(
                              width: 2,
                              height: 12,
                              color: activities[index - 1].color,
                            )
                          else
                            const SizedBox(height: 0),
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: activity.color.withValues(alpha: 0.15),
                              border: Border.all(
                                color: activity.color,
                                width: 2,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              activity.icon,
                              color: activity.color,
                              size: 20,
                            ),
                          ),
                          if (!isLast)
                            Container(
                              width: 2,
                              height: 18,
                              color: activity.color.withValues(alpha: 0.4),
                            )
                          else
                            const SizedBox(height: 0),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                activity.time,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: activity.color,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                activity.title,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isLast) const SizedBox(height: 4),
              ],
            );
          }),
        ),
      ),
    );
  }
}
