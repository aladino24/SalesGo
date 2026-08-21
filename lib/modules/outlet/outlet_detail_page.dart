import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme/app_colors.dart';
import '../../app/widgets/sfa_ui.dart';
import '../../app/widgets/sfa_feedback_dialog.dart';
import '../../data/models/outlet_model.dart';
import '../../data/models/visit_model.dart';
import '../../data/models/outlet_performance_model.dart';
import '../../data/repositories/outlet_detail_repository.dart';
import '../../data/repositories/outlet_transaction_repository.dart';
import '../../data/datasources/local/visit_local_data_source.dart';
import '../../data/repositories/visit_timeline_repository.dart';
import '../sales/sales_order_page.dart';
import '../visit/check_in_page.dart';
import '../visit/check_out_page.dart';
import '../visit/visit_action_page.dart';
import 'outlet_transaction_page.dart';

enum _DetailMenuAction {
  purchase,
  returnItem,
  receivable,
  defer,
  cancel,
  approval,
}

class OutletDetailPage extends StatefulWidget {
  const OutletDetailPage({super.key, required this.outlet});
  final OutletModel outlet;

  @override
  State<OutletDetailPage> createState() => _OutletDetailPageState();
}

class _OutletDetailPageState extends State<OutletDetailPage> {
  String? _activeVisitId;
  OutletModel get outlet => widget.outlet;

  @override
  void initState() {
    super.initState();
    _restoreActiveVisit();
  }

  Future<void> _restoreActiveVisit() async {
    final visit = await VisitLocalDataSource().findActiveVisitForOutlet(
      outletId: outlet.id,
      outletName: outlet.name,
    );
    if (mounted && visit != null) setState(() => _activeVisitId = visit.id);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            outlet.name,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          actions: [
            PopupMenuButton<_DetailMenuAction>(
              onSelected: (action) => _openMenuAction(action),
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: _DetailMenuAction.purchase,
                  child: Text('Pembelian'),
                ),
                PopupMenuItem(
                  value: _DetailMenuAction.returnItem,
                  child: Text('Retur'),
                ),
                PopupMenuItem(
                  value: _DetailMenuAction.receivable,
                  child: Text('Pembayaran Piutang'),
                ),
                PopupMenuDivider(),
                PopupMenuItem(
                  value: _DetailMenuAction.defer,
                  child: Text('Tunda Kunjungan'),
                ),
                PopupMenuItem(
                  value: _DetailMenuAction.cancel,
                  child: Text('Batalkan Kunjungan'),
                ),
                PopupMenuItem(
                  value: _DetailMenuAction.approval,
                  child: Text('Ajukan Approval'),
                ),
              ],
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              _VisitBanner(isCheckedIn: _activeVisitId != null),
              const TabBar(
                tabs: [
                  Tab(text: 'Ringkasan'),
                  Tab(text: 'Order'),
                  Tab(text: 'Aktivitas'),
                  Tab(text: 'Catatan'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _OverviewTab(outlet: outlet),
                    _OutletHistoryTab(outlet: outlet),
                    _ActivityTab(outlet: outlet),
                    const _NotesTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _activeVisitId == null
                      ? null
                      : () async {
                          final route = Get.to<bool>(
                            () => CheckOutPage(
                              outlet: outlet,
                              visitId: _activeVisitId!,
                            ),
                          );
                          if (route == null) return;
                          final completed = await route;
                          if (completed == true && mounted)
                            setState(() => _activeVisitId = null);
                        },
                  child: const Text('Check-out'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: _activeVisitId == null
                      ? () async {
                          final route = Get.to<VisitModel>(
                            () => CheckInPage(outlet: outlet),
                          );
                          if (route == null) return;
                          final visit = await route;
                          if (visit != null &&
                              visit.status == 'In Progress' &&
                              mounted) {
                            setState(() => _activeVisitId = visit.id);
                          }
                        }
                      : null,
                  child: const Text('Check-in'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openMenuAction(_DetailMenuAction action) {
    switch (action) {
      case _DetailMenuAction.purchase:
        Get.to(
          () => OutletTransactionPage(
            outlet: outlet,
            type: OutletTransactionType.purchase,
          ),
        );
        break;
      case _DetailMenuAction.returnItem:
        Get.to(
          () => OutletTransactionPage(
            outlet: outlet,
            type: OutletTransactionType.returnItem,
          ),
        );
        break;
      case _DetailMenuAction.receivable:
        Get.to(
          () => OutletTransactionPage(
            outlet: outlet,
            type: OutletTransactionType.receivablePayment,
          ),
        );
        break;
      case _DetailMenuAction.defer:
        Get.to(
          () => VisitActionPage(outlet: outlet, action: VisitActionType.defer),
        );
        break;
      case _DetailMenuAction.cancel:
        Get.to(
          () => VisitActionPage(outlet: outlet, action: VisitActionType.cancel),
        );
        break;
      case _DetailMenuAction.approval:
        Get.to(
          () =>
              VisitActionPage(outlet: outlet, action: VisitActionType.approval),
        );
        break;
    }
  }
}

class _VisitBanner extends StatelessWidget {
  const _VisitBanner({required this.isCheckedIn});
  final bool isCheckedIn;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(16, 2, 16, 12),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: isCheckedIn ? const Color(0xFFEAFBF0) : AppColors.primarySoft,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      children: [
        Icon(
          isCheckedIn ? Icons.check_circle_rounded : Icons.schedule_rounded,
          color: isCheckedIn ? AppColors.success : AppColors.primary,
          size: 18,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            isCheckedIn ? 'Sedang dalam kunjungan' : 'Belum check-in',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),
        SfaStatusChip(
          label: isCheckedIn ? 'Check-out' : 'Menunggu',
          color: isCheckedIn ? AppColors.success : AppColors.primary,
        ),
      ],
    ),
  );
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.outlet});
  final OutletModel outlet;
  @override
  Widget build(BuildContext context) => FutureBuilder<OutletPerformanceModel>(
    future: OutletDetailRepository().getPerformance(outlet.id),
    builder: (context, snapshot) {
      final performance =
          snapshot.data ??
          const OutletPerformanceModel(
            target: 0,
            achievement: 0,
            topProducts: [],
            unsoldProducts: [],
            potentialProducts: [],
          );
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          const SfaSectionTitle(title: 'Informasi Outlet'),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _InfoRow('Kode', outlet.code),
                  _InfoRow('Pemilik', outlet.ownerName ?? '-'),
                  _InfoRow(
                    'Kontak',
                    outlet.contactName ?? outlet.ownerName ?? '-',
                  ),
                  _InfoRow('Telepon', outlet.phone ?? '-'),
                  _InfoRow('Alamat', outlet.address),
                  _InfoRow('Tipe Outlet', outlet.type),
                  _InfoRow('Sales', outlet.salesResponsible),
                  if ((outlet.phone ?? '').isNotEmpty) ...[
                    const Divider(height: 22),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _callOutlet(outlet.phone!),
                        icon: const Icon(Icons.phone_outlined),
                        label: const Text('Telepon Outlet'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const SfaSectionTitle(
            title: 'Target & Pencapaian',
            actionLabel: 'Bulan Ini',
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: snapshot.connectionState == ConnectionState.waiting
                  ? const LinearProgressIndicator()
                  : Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _TargetValue(
                                'Target',
                                'Rp ${performance.target.toStringAsFixed(0)}',
                              ),
                            ),
                            Expanded(
                              child: _TargetValue(
                                'Pencapaian',
                                'Rp ${performance.achievement.toStringAsFixed(0)}',
                                alignEnd: true,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Text(
                              '${(performance.achievementPercent * 100).toStringAsFixed(1)}%',
                              style: TextStyle(
                                color: Colors.green.shade600,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const Spacer(),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: performance.achievementPercent,
                            minHeight: 8,
                            color: AppColors.success,
                            backgroundColor: AppColors.primarySoft,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 20),
          _ProductInsight(
            title: 'Produk Terlaris',
            products: performance.topProducts,
            icon: Icons.workspace_premium_outlined,
            color: AppColors.success,
          ),
          const SizedBox(height: 10),
          _ProductInsight(
            title: 'Belum Terjual',
            products: performance.unsoldProducts,
            icon: Icons.remove_shopping_cart_outlined,
            color: AppColors.warning,
          ),
          const SizedBox(height: 10),
          _ProductInsight(
            title: 'Potensi Produk',
            products: performance.potentialProducts,
            icon: Icons.lightbulb_outline_rounded,
            color: AppColors.primary,
          ),
          const SizedBox(height: 20),
          const SfaSectionTitle(title: 'Aksi Cepat'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: SfaIconTile(
                  icon: Icons.receipt_long_outlined,
                  label: 'Buat Order',
                  color: AppColors.primary,
                  onTap: () => Get.to(() => SalesOrderPage(outlet: outlet)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SfaIconTile(
                  icon: Icons.note_alt_outlined,
                  label: 'Catatan',
                  color: AppColors.success,
                  onTap: () => Get.to(
                    () => OutletTransactionPage(
                      outlet: outlet,
                      type: OutletTransactionType.note,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SfaIconTile(
                  icon: Icons.card_giftcard_rounded,
                  label: 'Hadiah',
                  color: AppColors.danger,
                  onTap: () => Get.to(
                    () => OutletTransactionPage(
                      outlet: outlet,
                      type: OutletTransactionType.gift,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SfaIconTile(
                  icon: Icons.assignment_return_outlined,
                  label: 'Retur',
                  color: Color(0xFF0EA5E9),
                  onTap: () => Get.to(
                    () => OutletTransactionPage(
                      outlet: outlet,
                      type: OutletTransactionType.returnItem,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    },
  );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);
  final String label, value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 11),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 82,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}

class _TargetValue extends StatelessWidget {
  const _TargetValue(this.label, this.value, {this.alignEnd = false});
  final String label, value;
  final bool alignEnd;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: alignEnd
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
      ),
      const SizedBox(height: 5),
      Text(
        value,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
      ),
    ],
  );
}

class _ProductInsight extends StatelessWidget {
  const _ProductInsight({
    required this.title,
    required this.products,
    required this.icon,
    required this.color,
  });
  final String title;
  final List<String> products;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: .12),
        child: Icon(icon, color: color),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        products.isEmpty ? 'Belum ada data' : products.take(3).join(', '),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    ),
  );
}

Future<void> _callOutlet(String phone) async {
  final uri = Uri(
    scheme: 'tel',
    path: phone.replaceAll(RegExp(r'[^0-9+]'), ''),
  );
  if (!await launchUrl(uri)) {
    SfaFeedbackDialog.show(type: SfaFeedbackType.error, title: 'Tidak dapat menelepon', message: 'Aplikasi telepon tidak tersedia pada perangkat ini.');
  }
}

class _OutletHistoryTab extends StatelessWidget {
  const _OutletHistoryTab({required this.outlet});

  final OutletModel outlet;

  Future<List<Map<String, dynamic>>> _load() async {
    final items = await OutletTransactionRepository().history(outletId: outlet.id);

    final orders = Hive.isBoxOpen('sales_orders')
        ? Hive.box('sales_orders')
        : await Hive.openBox('sales_orders');
    for (final value in orders.values) {
      if (value is Map && value['outletName'] == outlet.name) {
        items.add({
          ...Map<String, dynamic>.from(value),
          'type': 'sales_order_create',
        });
      }
    }

    final visits = Hive.isBoxOpen('visits')
        ? Hive.box('visits')
        : await Hive.openBox('visits');
    for (final value in visits.values) {
      if (value is Map && value['outletName'] == outlet.name) {
        items.add({...Map<String, dynamic>.from(value), 'type': 'visit'});
      }
    }

    items.sort(
      (a, b) => (b['createdAt']?.toString() ?? '').compareTo(
        a['createdAt']?.toString() ?? '',
      ),
    );
    return items;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _load(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return const SfaEmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'Belum ada riwayat',
            description:
                'Visit, order, dan transaksi outlet akan muncul di sini.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, index) {
            final item = items[index];
            final isVisit = item['type'] == 'visit';
            final title = isVisit
                ? 'Visit ${(item['status'] ?? '').toString()}'
                : (item['type'] ?? 'Transaksi').toString().replaceAll('_', ' ');
            final detail =
                item['item'] ??
                item['productName'] ??
                item['outletName'] ??
                'Tidak ada detail';
            final trailing = isVisit
                ? (item['status'] ?? '').toString()
                : 'Rp ${(item['amount'] ?? item['total'] ?? 0).toString()}';

            return Card(
              child: ListTile(
                onTap: () => _showHistoryDetail(item),
                leading: CircleAvatar(
                  child: Icon(
                    isVisit
                        ? Icons.location_on_rounded
                        : Icons.receipt_long_rounded,
                  ),
                ),
                title: Text(title),
                subtitle: Text(detail.toString()),
                trailing: Text(trailing),
              ),
            );
          },
        );
      },
    );
  }
}

void _showHistoryDetail(Map<String, dynamic> item) {
  final details = item.entries
      .where((entry) => entry.value != null && entry.key != 'photoPath')
      .map((entry) => '${entry.key}: ${entry.value}')
      .join('\n');
  Get.bottomSheet(
    SafeArea(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Detail Riwayat',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Text(
              details.isEmpty ? 'Tidak ada detail tambahan.' : details,
              style: const TextStyle(fontSize: 12, height: 1.5),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Get.back(),
                child: const Text('Tutup'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ActivityTab extends StatelessWidget {
  const _ActivityTab({required this.outlet});
  final OutletModel outlet;
  @override
  Widget build(BuildContext context) => FutureBuilder<List<Map<String, dynamic>>>(
    future: VisitTimelineRepository().byOutlet(outlet.id),
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
      final items = snapshot.data ?? [];
      if (items.isEmpty) return const _EmptyTab(icon: Icons.timeline_outlined, title: 'Belum ada aktivitas visit', description: 'Check-in, check-out, tunda, dan batal kunjungan akan muncul di sini.');
      return ListView.separated(padding: const EdgeInsets.all(16), itemCount: items.length, separatorBuilder: (_, __) => const SizedBox(height: 8), itemBuilder: (_, index) {
        final item = items[index]; final location = item['location']; final createdAt = DateTime.tryParse(item['createdAt']?.toString() ?? '')?.toLocal();
        return Card(child: ListTile(leading: CircleAvatar(backgroundColor: AppColors.primarySoft, child: Icon(item['activity'] == 'check_in' ? Icons.login_rounded : item['activity'] == 'check_out' ? Icons.logout_rounded : Icons.event_note_outlined, color: AppColors.primary)), title: Text(item['activity']?.toString().replaceAll('_', ' ') ?? 'Aktivitas', style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Text('${item['description'] ?? '-'}${location is Map ? '\nGPS tercatat' : ''}'), isThreeLine: location is Map, trailing: Text(createdAt == null ? '-' : '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary))));
      });
    },
  );
}

class _NotesTab extends StatelessWidget {
  const _NotesTab();
  @override
  Widget build(BuildContext context) => const _EmptyTab(
    icon: Icons.note_alt_outlined,
    title: 'Belum ada catatan',
    description: 'Tambahkan catatan hasil kunjungan outlet.',
  );
}

class _ActivityItem extends StatelessWidget {
  const _ActivityItem(this.time, this.title, this.icon, this.color);
  final String time, title;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => ListTile(
    leading: CircleAvatar(
      backgroundColor: color.withValues(alpha: .12),
      child: Icon(icon, color: color, size: 19),
    ),
    title: Text(
      title,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
    ),
    trailing: Text(
      time,
      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
    ),
  );
}

class _EmptyTab extends StatelessWidget {
  const _EmptyTab({
    required this.icon,
    required this.title,
    required this.description,
  });
  final IconData icon;
  final String title, description;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 52, color: AppColors.primarySoft),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 5),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    ),
  );
}
