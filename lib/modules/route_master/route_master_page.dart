import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../app/theme/app_colors.dart';
import '../../app/widgets/sfa_feedback_dialog.dart';
import '../../app/widgets/sfa_ui.dart';
import '../../core/auth/app_roles.dart';
import '../../core/auth/session_service.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/network/network_info.dart';
import '../../data/models/outlet_model.dart';
import '../../data/repositories/master_repository.dart';

class RouteMasterPage extends StatefulWidget {
  const RouteMasterPage({super.key});

  @override
  State<RouteMasterPage> createState() => _RouteMasterPageState();
}

class _RouteDraft {
  const _RouteDraft({required this.day, required this.week});

  final int day;
  final int week;

  _RouteDraft copyWith({int? day, int? week}) =>
      _RouteDraft(day: day ?? this.day, week: week ?? this.week);
}

class _RouteMasterPageState extends State<RouteMasterPage> {
  static const _days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
  final _api = Get.find<ApiClient>();
  final _master = MasterRepository();
  final _network = Get.find<NetworkInfo>();
  var _records = <Map<String, dynamic>>[];
  var _sales = <Map<String, dynamic>>[];
  var _loading = true;
  final _search = TextEditingController();
  final _tableScroll = ScrollController();
  final _drafts = <String, _RouteDraft>{};
  var _query = '';
  var _page = 0;
  static const _pageSize = 25;
  static const _cacheBoxName = 'route_master_cache';

  AppRole? get _role => Get.find<SessionService>().currentRole.value;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    _tableScroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    var usedCache = false;
    try {
      final cache = await _cache;
      if (!await _network.isConnected) {
        _restoreCache(cache);
        usedCache = true;
        return;
      }
      final assignments = await _api
          .get<List<dynamic>>(ApiEndpoints.routeAssignments)
          .timeout(const Duration(seconds: 12));
      _records = assignments
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
      _drafts.clear();
      _page = 0;
      if (_role == AppRole.branchManager) {
        try {
          final response = await _api
              .get<List<dynamic>>(ApiEndpoints.routeSales)
              .timeout(const Duration(seconds: 8));
          _sales = response.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList();
        } catch (_) {
          // Kompatibel dengan backend yang belum direstart setelah endpoint
          // route-sales ditambahkan: halaman tetap dapat menampilkan rute.
          _sales = _records
              .where((item) => item['sales'] is Map)
              .map((item) => Map<String, dynamic>.from(item['sales'] as Map))
              .fold<Map<String, Map<String, dynamic>>>({}, (result, item) {
                result[item['id']?.toString() ?? ''] = item;
                return result;
              })
          .values
              .toList();
        }
      }
      await cache.put('records', _records);
      await cache.put('sales', _sales);
    } catch (error) {
      final cache = await _cache;
      if (cache.containsKey('records')) {
        _restoreCache(cache);
        usedCache = true;
      } else if (mounted) {
        await SfaFeedbackDialog.show(type: SfaFeedbackType.error, title: 'Rute tidak dapat dimuat', message: error.toString());
      }
    } finally {
      if (mounted) setState(() => _loading = false);
      if (usedCache && mounted) {
        Future<void>.delayed(const Duration(milliseconds: 250), () {
          if (mounted) {
            SfaFeedbackDialog.show(type: SfaFeedbackType.info, title: 'Mode offline', message: 'Menampilkan data master rute terakhir yang tersimpan di perangkat.');
          }
        });
      }
    }
  }

  Future<Box> get _cache async => Hive.isBoxOpen(_cacheBoxName)
      ? Hive.box(_cacheBoxName)
      : Hive.openBox(_cacheBoxName);

  void _restoreCache(Box cache) {
    final records = cache.get('records');
    final sales = cache.get('sales');
    _records = records is List
        ? records.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList()
        : <Map<String, dynamic>>[];
    _sales = sales is List
        ? sales.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList()
        : <Map<String, dynamic>>[];
    _drafts.clear();
    _page = 0;
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
    final conflicts = <Map<String, dynamic>>[];
    for (final day in days) {
      for (final week in weeks) {
        final scheduled = _records.where((item) =>
            item['outletId']?.toString() == outlet.id &&
            (item['dayOfWeek'] as num?)?.toInt() == day &&
            (item['weekOfMonth'] as num?)?.toInt() == week).toList();
        final duplicateForSales = _role == AppRole.branchManager
            ? scheduled.any((item) => item['salesId']?.toString() == salesId)
            : scheduled.isNotEmpty;
        if (duplicateForSales || scheduled.length >= 10) {
          conflicts.addAll(scheduled);
        }
      }
    }
    if (conflicts.isNotEmpty) {
      final conflict = conflicts.first;
      final assignedSales = conflict['sales'] is Map
          ? Map<String, dynamic>.from(conflict['sales'] as Map)
          : <String, dynamic>{};
      await SfaFeedbackDialog.show(
        type: SfaFeedbackType.warning,
        title: 'Jadwal outlet sudah digunakan',
        message: '${outlet.code} sudah memiliki jadwal untuk ${assignedSales['employeeCode'] ?? assignedSales['name'] ?? 'sales'} pada ${_days[((conflict['dayOfWeek'] as num?)?.toInt() ?? 1) - 1]}, minggu ke-${conflict['weekOfMonth']}. Satu sales tidak boleh duplikat dan maksimal 10 sales dapat dijadwalkan pada slot yang sama.',
      );
      return;
    }
    try {
      await _api.post(ApiEndpoints.routeAssignmentsBulk, data: {
        'outletId': int.parse(outlet.id),
        if (_role == AppRole.branchManager) 'salesId': int.parse(salesId!),
        'days': days.toList(),
        'weeks': weeks.toList(),
        'isActive': true,
      });
      await _load();
      if (mounted) await SfaFeedbackDialog.show(type: SfaFeedbackType.success, title: 'Master rute disimpan', message: '${days.length * weeks.length} jadwal rute berhasil ditambahkan.');
    } catch (error) {
      if (mounted) await SfaFeedbackDialog.show(type: SfaFeedbackType.warning, title: 'Rute tidak disimpan', message: error.toString());
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

  _RouteDraft _draftFor(Map<String, dynamic> item) {
    final id = item['id']?.toString() ?? '';
    return _drafts[id] ?? _RouteDraft(
      day: (item['dayOfWeek'] as num?)?.toInt() ?? 1,
      week: (item['weekOfMonth'] as num?)?.toInt() ?? 1,
    );
  }

  void _changeDay(Map<String, dynamic> item, int day) {
    final id = item['id']?.toString() ?? '';
    setState(() => _drafts[id] = _draftFor(item).copyWith(day: day));
  }

  void _changeWeek(Map<String, dynamic> item, int week) {
    final id = item['id']?.toString() ?? '';
    setState(() => _drafts[id] = _draftFor(item).copyWith(week: week));
  }

  bool _isChanged(Map<String, dynamic> item) {
    final draft = _draftFor(item);
    return draft.day != (item['dayOfWeek'] as num?)?.toInt() ||
        draft.week != (item['weekOfMonth'] as num?)?.toInt();
  }

  bool _hasLegacyConflict(Map<String, dynamic> item) =>
      _records.where((other) =>
          other['outletId']?.toString() == item['outletId']?.toString() &&
          other['dayOfWeek'] == item['dayOfWeek'] &&
          other['weekOfMonth'] == item['weekOfMonth']).length >
      10;

  Future<void> _save(Map<String, dynamic> item) async {
    final id = item['id']?.toString() ?? '';
    final draft = _draftFor(item);
    try {
      await _api.patch('${ApiEndpoints.routeAssignments}/$id', data: {
        'dayOfWeek': draft.day,
        'weekOfMonth': draft.week,
      });
      await _load();
    } catch (error) {
      if (mounted) {
        await SfaFeedbackDialog.show(
          type: SfaFeedbackType.error,
          title: 'Perubahan rute gagal disimpan',
          message: error.toString(),
        );
      }
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
                child: Builder(builder: (context) {
                  final records = _records.where((item) {
                    final outlet = item['outlet'] is Map ? Map<String, dynamic>.from(item['outlet'] as Map) : <String, dynamic>{};
                    final sales = item['sales'] is Map ? Map<String, dynamic>.from(item['sales'] as Map) : <String, dynamic>{};
                    final text = '${outlet['code'] ?? ''} ${outlet['name'] ?? ''} ${sales['employeeCode'] ?? ''} ${sales['name'] ?? ''}'.toLowerCase();
                    return _query.isEmpty || text.contains(_query);
                  }).toList();
                  final pageCount = records.isEmpty ? 1 : (records.length / _pageSize).ceil();
                  final page = _page >= pageCount ? pageCount - 1 : _page;
                  final start = page * _pageSize;
                  final visibleRecords = records.skip(start).take(_pageSize).toList();
                  return ListView(padding: const EdgeInsets.all(16), children: [
                    const Text('Jadwal rute cabang', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    const Text('Ubah centang hari atau minggu pada satu baris, kemudian tekan Simpan.'),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _search,
                      onChanged: (value) => setState(() {
                        _query = value.trim().toLowerCase();
                        _page = 0;
                      }),
                      decoration: InputDecoration(
                        hintText: 'Cari kode/nama sales atau outlet',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _query.isEmpty ? null : IconButton(
                          tooltip: 'Hapus pencarian',
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () {
                            _search.clear();
                            setState(() {
                              _query = '';
                              _page = 0;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Row(children: [
                      Icon(Icons.swipe_rounded, size: 18, color: AppColors.textSecondary),
                      SizedBox(width: 6),
                      Text('Geser tabel ke kanan atau kiri untuk melihat seluruh hari, minggu, dan aksi.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ]),
                    const SizedBox(height: 8),
                    if (records.isEmpty)
                      const Padding(padding: EdgeInsets.only(top: 72), child: SfaEmptyState(icon: Icons.search_off_rounded, title: 'Rute tidak ditemukan', description: 'Hapus atau ubah kata kunci pencarian.'))
                    else ...[
                      Row(children: [
                        Expanded(child: Text('Menampilkan ${start + 1}–${start + visibleRecords.length} dari ${records.length} jadwal', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
                        IconButton(tooltip: 'Halaman sebelumnya', onPressed: page == 0 ? null : () => setState(() => _page = page - 1), icon: const Icon(Icons.chevron_left_rounded)),
                        Text('${page + 1}/$pageCount', style: const TextStyle(fontWeight: FontWeight.w700)),
                        IconButton(tooltip: 'Halaman berikutnya', onPressed: page + 1 >= pageCount ? null : () => setState(() => _page = page + 1), icon: const Icon(Icons.chevron_right_rounded)),
                      ]),
                      Card(
                        clipBehavior: Clip.antiAlias,
                        child: Scrollbar(
                          controller: _tableScroll,
                          thumbVisibility: true,
                          child: SingleChildScrollView(
                            controller: _tableScroll,
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              headingRowColor: const WidgetStatePropertyAll(AppColors.primarySoft),
                              columns: const [
                                DataColumn(label: Text('Sales')), DataColumn(label: Text('Kode outlet')), DataColumn(label: Text('Outlet')),
                                DataColumn(label: Text('Sen')), DataColumn(label: Text('Sel')), DataColumn(label: Text('Rab')), DataColumn(label: Text('Kam')), DataColumn(label: Text('Jum')), DataColumn(label: Text('Sab')), DataColumn(label: Text('Min')),
                                DataColumn(label: Text('M1')), DataColumn(label: Text('M2')), DataColumn(label: Text('M3')), DataColumn(label: Text('M4')), DataColumn(label: Text('Aksi')),
                              ],
                              rows: List.generate(visibleRecords.length, (index) {
                                final item = visibleRecords[index];
                                final outlet = item['outlet'] is Map ? Map<String, dynamic>.from(item['outlet'] as Map) : <String, dynamic>{};
                                final sales = item['sales'] is Map ? Map<String, dynamic>.from(item['sales'] as Map) : <String, dynamic>{};
                                final draft = _draftFor(item);
                                final changed = _isChanged(item);
                                final conflict = _hasLegacyConflict(item);
                                return DataRow(color: conflict ? WidgetStatePropertyAll(AppColors.warning.withValues(alpha: .12)) : ((start + index).isOdd ? WidgetStatePropertyAll(AppColors.primarySoft.withValues(alpha: .45)) : null), cells: [
                                  DataCell(Text('${sales['employeeCode'] ?? '-'}\n${sales['name'] ?? 'Sales'}')),
                                  DataCell(Text(outlet['code']?.toString() ?? '-')),
                                  DataCell(SizedBox(width: 150, child: Text(outlet['name']?.toString() ?? 'Outlet', overflow: TextOverflow.ellipsis))),
                                  ...List.generate(7, (day) => DataCell(Checkbox(value: draft.day == day + 1, onChanged: (_) => _changeDay(item, day + 1)))),
                                  ...List.generate(4, (week) => DataCell(Checkbox(value: draft.week == week + 1, onChanged: (_) => _changeWeek(item, week + 1)))),
                                  DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                                    if (conflict) const Tooltip(message: 'Slot ini melebihi batas 10 sales. Pilih hari atau minggu lain, lalu Simpan.', child: Icon(Icons.warning_amber_rounded, color: AppColors.warning)),
                                    if (changed) IconButton(tooltip: 'Simpan perubahan', onPressed: () => _save(item), icon: const Icon(Icons.save_rounded, color: AppColors.primary)),
                                    IconButton(tooltip: 'Hapus jadwal', onPressed: () => _delete(item), icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger)),
                                  ])),
                                ]);
                              }),
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 88),
                  ]);
                }),
              ),
  );
}
