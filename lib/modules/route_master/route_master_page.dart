import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/widgets/sfa_ui.dart';
import '../../core/auth/app_roles.dart';
import '../../core/auth/session_service.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../data/repositories/master_repository.dart';

class RouteMasterPage extends StatefulWidget {
  const RouteMasterPage({super.key});

  @override
  State<RouteMasterPage> createState() => _RouteMasterPageState();
}

class _RouteMasterPageState extends State<RouteMasterPage> {
  final _api = Get.find<ApiClient>();
  final _master = MasterRepository();
  var _records = <Map<String, dynamic>>[];
  var _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final response = await _api.get<List<dynamic>>(ApiEndpoints.routeAssignments);
      _records = response.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _add() async {
    final outlets = await _master.getOutlets(isOnline: true);
    if (!mounted || outlets.isEmpty) return;
    String outletId = outlets.first.id;
    var day = 1;
    var week = 1;
    final role = Get.find<SessionService>().currentRole.value;
    final salesOptions = <String, String>{
      for (final record in _records)
        if (record['sales'] is Map && (record['sales'] as Map)['id'] != null)
          (record['sales'] as Map)['id'].toString(): (record['sales'] as Map)['name']?.toString() ?? 'Sales',
    };
    String? selectedSalesId = salesOptions.keys.isEmpty ? null : salesOptions.keys.first;
    final saved = await Get.dialog<bool>(AlertDialog(
      title: const Text('Atur Rute Outlet'),
      content: StatefulBuilder(builder: (context, setDialogState) => SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        DropdownButtonFormField<String>(value: outletId, isExpanded: true, items: outlets.map((outlet) => DropdownMenuItem(value: outlet.id, child: Text('${outlet.code} - ${outlet.name}', overflow: TextOverflow.ellipsis))).toList(), onChanged: (value) => setDialogState(() => outletId = value ?? outletId), decoration: const InputDecoration(labelText: 'Outlet')),
        if (role == AppRole.branchManager) DropdownButtonFormField<String>(value: selectedSalesId, items: salesOptions.entries.map((item) => DropdownMenuItem(value: item.key, child: Text(item.value))).toList(), onChanged: (value) => setDialogState(() => selectedSalesId = value), decoration: const InputDecoration(labelText: 'Sales')),
        DropdownButtonFormField<int>(value: day, items: List.generate(7, (index) => DropdownMenuItem(value: index + 1, child: Text('Hari ${index + 1}'))), onChanged: (value) => setDialogState(() => day = value ?? day), decoration: const InputDecoration(labelText: 'Hari dalam minggu')),
        DropdownButtonFormField<int>(value: week, items: List.generate(4, (index) => DropdownMenuItem(value: index + 1, child: Text('Minggu ${index + 1}'))), onChanged: (value) => setDialogState(() => week = value ?? week), decoration: const InputDecoration(labelText: 'Minggu dalam bulan')),
      ])),
      actions: [TextButton(onPressed: () => Get.back(result: false), child: const Text('Batal')), FilledButton(onPressed: () => Get.back(result: true), child: const Text('Simpan'))],
    ));
    if (saved != true) return;
    if (role == AppRole.branchManager && selectedSalesId == null) {
      throw StateError('Belum ada sales pada master rute. Tambahkan route seed untuk sales terlebih dahulu.');
    }
    await _api.post(ApiEndpoints.routeAssignments, data: {'outletId': int.parse(outletId), if (role == AppRole.branchManager) 'salesId': int.parse(selectedSalesId!), 'dayOfWeek': day, 'weekOfMonth': week, 'isActive': true});
    await _load();
  }

  Future<void> _delete(Map<String, dynamic> item) async {
    await _api.delete('${ApiEndpoints.routeAssignments}/${item['id']}');
    await _load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Master Rute Sales')),
    floatingActionButton: FloatingActionButton.extended(onPressed: _add, icon: const Icon(Icons.add), label: const Text('Tambah Rute')),
    body: _loading ? const Center(child: CircularProgressIndicator()) : _records.isEmpty ? SfaEmptyState(icon: Icons.route_outlined, title: 'Belum ada rute', description: 'Tambahkan outlet berdasarkan hari dan minggu.', actionLabel: 'Tambah Rute', onAction: _add) : RefreshIndicator(onRefresh: _load, child: ListView.separated(padding: const EdgeInsets.all(16), itemCount: _records.length, separatorBuilder: (_, __) => const SizedBox(height: 8), itemBuilder: (_, index) { final item = _records[index]; final outlet = item['outlet'] is Map ? Map<String, dynamic>.from(item['outlet'] as Map) : <String, dynamic>{}; final sales = item['sales'] is Map ? Map<String, dynamic>.from(item['sales'] as Map) : <String, dynamic>{}; return Card(child: ListTile(leading: const CircleAvatar(child: Icon(Icons.storefront_rounded)), title: Text('${outlet['code'] ?? '-'} - ${outlet['name'] ?? 'Outlet'}'), subtitle: Text('${sales['name'] ?? 'Sales'} • Hari ${item['dayOfWeek']} • Minggu ${item['weekOfMonth']}'), trailing: IconButton(onPressed: () => _delete(item), icon: const Icon(Icons.delete_outline_rounded))); })),
  );
}
