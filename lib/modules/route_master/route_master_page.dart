import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/theme/app_colors.dart';
import '../../app/widgets/sfa_feedback_dialog.dart';
import '../../app/widgets/sfa_ui.dart';
import '../../core/auth/app_roles.dart';
import '../../core/auth/session_service.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../data/models/outlet_model.dart';
import '../../data/repositories/master_repository.dart';

class RouteMasterPage extends StatefulWidget {
  const RouteMasterPage({super.key});

  @override
  State<RouteMasterPage> createState() => _RouteMasterPageState();
}

class _RouteMasterPageState extends State<RouteMasterPage> {
  static const _days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
  final _api = Get.find<ApiClient>();
  final _master = MasterRepository();
  var _records = <Map<String, dynamic>>[];
  var _sales = <Map<String, dynamic>>[];
  var _loading = true;

  AppRole? get _role => Get.find<SessionService>().currentRole.value;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    try {
      final responses = await Future.wait([
        _api.get<List<dynamic>>(ApiEndpoints.routeAssignments),
        if (_role == AppRole.branchManager) _api.get<List<dynamic>>(ApiEndpoints.routeSales),
      ]);
      _records = (responses.first as List<dynamic>)
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
      _sales = responses.length > 1
          ? (responses[1] as List<dynamic>).whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList()
          : <Map<String, dynamic>>[];
    } catch (error) {
      if (mounted) {
        await SfaFeedbackDialog.show(type: SfaFeedbackType.error, title: 'Rute tidak dapat dimuat', message: error.toString());
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _add() async {
    final outlets = await _master.getOutlets(isOnline: true);
    if (!mounted) return;
    if (outlets.isEmpty || (_role == AppRole.branchManager && _sales.isEmpty)) {
      await SfaFeedbackDialog.show(type: SfaFeedbackType.info, title: 'Data master belum lengkap', message: outlets.isEmpty ? 'Tambahkan atau setujui outlet terlebih dahulu.' : 'Belum ada sales aktif pada cabang ini.');
      return;
    }
    OutletModel outlet = outlets.first;
    String? salesId = _role == AppRole.branchManager ? _sales.first['id']?.toString() : null;
    final days = <int>{DateTime.now().weekday};
    final currentWeek = (DateTime.now().day - 1) ~/ 7 + 1;
    final weeks = <int>{currentWeek > 4 ? 4 : currentWeek};
    final saved = await Get.dialog<bool>(
      Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: StatefulBuilder(
          builder: (context, setDialogState) => Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(children: [
                    CircleAvatar(backgroundColor: AppColors.primarySoft, child: Icon(Icons.route_rounded, color: AppColors.primary)),
                    SizedBox(width: 12),
                    Expanded(child: Text('Tambah Master Rute', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
                  ]),
                  const SizedBox(height: 8),
                  const Text('Pilih outlet, sales, lalu centang hari dan minggu kunjungan.'),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: outlet.id,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Outlet'),
                    items: outlets.map((item) => DropdownMenuItem(value: item.id, child: Text('${item.code} • ${item.name}', overflow: TextOverflow.ellipsis))).toList(),
                    onChanged: (value) => setDialogState(() => outlet = outlets.firstWhere((item) => item.id == value)),
                  ),
                  if (_role == AppRole.branchManager) ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: salesId,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Sales'),
                      items: _sales.map((item) => DropdownMenuItem(value: item['id']?.toString(), child: Text('${item['employeeCode'] ?? '-'} • ${item['name'] ?? 'Sales'}', overflow: TextOverflow.ellipsis))).toList(),
                      onChanged: (value) => setDialogState(() => salesId = value),
                    ),
                  ],
                  const SizedBox(height: 20),
                  const Text('Hari kunjungan', style: TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Wrap(spacing: 6, runSpacing: 6, children: List.generate(7, (index) {
                    final day = index + 1;
                    return FilterChip(label: Text(_days[index]), selected: days.contains(day), onSelected: (value) => setDialogState(() => value ? days.add(day) : days.remove(day)));
                  })),
                  const SizedBox(height: 16),
                  const Text('Minggu dalam bulan', style: TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Wrap(spacing: 6, children: List.generate(4, (index) {
                    final week = index + 1;
                    return FilterChip(label: Text('Minggu $week'), selected: weeks.contains(week), onSelected: (value) => setDialogState(() => value ? weeks.add(week) : weeks.remove(week)));
                  })),
                  const SizedBox(height: 24),
                  SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: days.isEmpty || weeks.isEmpty || (_role == AppRole.branchManager && salesId == null) ? null : () => Get.back(result: true), icon: const Icon(Icons.save_rounded), label: Text('Simpan ${days.length * weeks.length} jadwal'))),
                  TextButton(onPressed: () => Get.back(result: false), child: const Center(child: Text('Batal'))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (saved != true) return;
    try {
      for (final day in days) {
        for (final week in weeks) {
          await _api.post(ApiEndpoints.routeAssignments, data: {'outletId': int.parse(outlet.id), if (_role == AppRole.branchManager) 'salesId': int.parse(salesId!), 'dayOfWeek': day, 'weekOfMonth': week, 'isActive': true});
        }
      }
      await _load();
      if (mounted) await SfaFeedbackDialog.show(type: SfaFeedbackType.success, title: 'Master rute disimpan', message: '${days.length * weeks.length} jadwal rute berhasil ditambahkan.');
    } catch (error) {
      if (mounted) await SfaFeedbackDialog.show(type: SfaFeedbackType.error, title: 'Rute gagal disimpan', message: error.toString());
    }
  }

  Future<void> _delete(Map<String, dynamic> item) async {
    try {
      await _api.delete('${ApiEndpoints.routeAssignments}/${item['id']}');
      await _load();
    } catch (error) {
      if (mounted) await SfaFeedbackDialog.show(type: SfaFeedbackType.error, title: 'Rute gagal dihapus', message: error.toString());
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Master Rute Sales', style: TextStyle(fontWeight: FontWeight.w800))),
    floatingActionButton: FloatingActionButton.extended(onPressed: _add, icon: const Icon(Icons.add_rounded), label: const Text('Tambah Rute')),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _records.isEmpty
            ? SfaEmptyState(icon: Icons.route_outlined, title: 'Belum ada rute', description: 'Tambahkan outlet berdasarkan hari dan minggu.', actionLabel: 'Tambah Rute', onAction: _add)
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(padding: const EdgeInsets.all(16), children: [
                  const Text('Jadwal rute cabang', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  const Text('Setiap baris adalah satu kombinasi sales, outlet, hari, dan minggu.'),
                  const SizedBox(height: 12),
                  Card(
                    clipBehavior: Clip.antiAlias,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: const WidgetStatePropertyAll(AppColors.primarySoft),
                        columns: const [
                          DataColumn(label: Text('Sales')),
                          DataColumn(label: Text('Kode outlet')),
                          DataColumn(label: Text('Outlet')),
                          DataColumn(label: Text('Sen')),
                          DataColumn(label: Text('Sel')),
                          DataColumn(label: Text('Rab')),
                          DataColumn(label: Text('Kam')),
                          DataColumn(label: Text('Jum')),
                          DataColumn(label: Text('Sab')),
                          DataColumn(label: Text('Min')),
                          DataColumn(label: Text('M1')),
                          DataColumn(label: Text('M2')),
                          DataColumn(label: Text('M3')),
                          DataColumn(label: Text('M4')),
                          DataColumn(label: Text('')),
                        ],
                        rows: List.generate(_records.length, (index) {
                          final item = _records[index];
                          final outlet = item['outlet'] is Map ? Map<String, dynamic>.from(item['outlet'] as Map) : <String, dynamic>{};
                          final sales = item['sales'] is Map ? Map<String, dynamic>.from(item['sales'] as Map) : <String, dynamic>{};
                          final day = (item['dayOfWeek'] as num?)?.toInt() ?? 1;
                          final week = item['weekOfMonth'];
                          return DataRow(
                            color: index.isOdd ? WidgetStatePropertyAll(AppColors.primarySoft.withValues(alpha: .45)) : null,
                            cells: [
                              DataCell(Text('${sales['employeeCode'] ?? '-'}\n${sales['name'] ?? 'Sales'}')),
                              DataCell(Text(outlet['code']?.toString() ?? '-')),
                              DataCell(SizedBox(width: 150, child: Text(outlet['name']?.toString() ?? 'Outlet', overflow: TextOverflow.ellipsis))),
                              ...List.generate(7, (index) => DataCell(Checkbox(value: day == index + 1, onChanged: null))),
                              ...List.generate(4, (index) => DataCell(Checkbox(value: week == index + 1, onChanged: null))),
                              DataCell(IconButton(onPressed: () => _delete(item), tooltip: 'Hapus jadwal ini', icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger))),
                            ],
                          );
                        }),
                      ),
                    ),
                  ),
                  const SizedBox(height: 88),
                ]),
              ),
  );
}
