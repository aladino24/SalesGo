import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/theme/app_colors.dart';
import '../../app/widgets/sfa_feedback_dialog.dart';
import '../../core/auth/app_roles.dart';
import '../../core/auth/session_service.dart';
import '../../data/models/outlet_model.dart';
import '../../data/models/promotion_model.dart';
import '../../data/repositories/information_repository.dart';
import '../../data/repositories/master_repository.dart';
import '../../data/repositories/promotion_control_repository.dart';

class PromotionControlPage extends StatefulWidget {
  const PromotionControlPage({super.key});

  @override
  State<PromotionControlPage> createState() => _PromotionControlPageState();
}

class _PromotionControlPageState extends State<PromotionControlPage> {
  final _repository = PromotionControlRepository();
  final _master = MasterRepository();
  final _information = InformationRepository();
  final _form = GlobalKey<FormState>();
  final _reason = TextEditingController();
  final _value = TextEditingController();
  final _quantity = TextEditingController();
  final _potentialRevenue = TextEditingController();
  List<OutletModel> _outlets = const [];
  List<PromotionModel> _promotions = const [];
  Map<String, dynamic>? _dashboard;
  OutletModel? _outlet;
  PromotionModel? _promotion;
  String _type = 'Percentage';
  DateTimeRange _range = DateTimeRange(start: DateTime.now(), end: DateTime.now().add(const Duration(days: 7)));
  bool _loading = true;
  bool _sending = false;

  bool get _canMonitor {
    final role = Get.find<SessionService>().currentRole.value;
    return role == AppRole.supervisor || role == AppRole.branchManager || role == AppRole.marketing || role == AppRole.it;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _reason.dispose();
    _value.dispose();
    _quantity.dispose();
    _potentialRevenue.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final outlets = await _master.getOutlets(isOnline: true);
      final promotions = await _information.getPromotions(online: true);
      Map<String, dynamic>? dashboard;
      if (_canMonitor) dashboard = await _repository.dashboard();
      if (mounted) setState(() { _outlets = outlets.where((item) => item.status == 'Active').toList(); _promotions = promotions; _dashboard = dashboard; });
    } catch (_) {
      if (mounted) {
        final outlets = await _master.getOutlets(isOnline: false);
        final promotions = await _information.getPromotions(online: false);
        setState(() { _outlets = outlets; _promotions = promotions; });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (!(_form.currentState?.validate() ?? false) || _outlet == null) {
      if (_outlet == null) await SfaFeedbackDialog.show(type: SfaFeedbackType.warning, title: 'Outlet diperlukan', message: 'Pilih outlet untuk pengajuan promosi khusus.');
      return;
    }
    setState(() => _sending = true);
    try {
      await _repository.requestSpecial(outletId: _outlet!.id, promotionId: _promotion?.id, type: _type, reason: _reason.text.trim(), value: double.tryParse(_value.text.replaceAll(',', '.')), quantity: int.tryParse(_quantity.text), potentialRevenue: double.tryParse(_potentialRevenue.text.replaceAll(',', '.')), startsAt: _range.start, endsAt: _range.end);
      if (!mounted) return;
      await SfaFeedbackDialog.show(type: SfaFeedbackType.approval, title: 'Pengajuan dikirim', message: 'Pengajuan promosi khusus menunggu persetujuan Branch Manager.');
      if (mounted) Get.back();
    } catch (error) {
      if (mounted) await SfaFeedbackDialog.show(type: SfaFeedbackType.error, title: 'Pengajuan belum terkirim', message: error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Kontrol Promosi')),
    body: _loading ? const Center(child: CircularProgressIndicator()) : RefreshIndicator(
      onRefresh: _load,
      child: ListView(padding: const EdgeInsets.all(16), children: [
        if (_canMonitor) _DashboardCard(data: _dashboard),
        if (_canMonitor) const SizedBox(height: 16),
        const Text('Pengajuan Promosi Khusus', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        const Text('Ajukan penawaran di luar program standar. Nilai final tetap ditinjau dan dihitung server.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        const SizedBox(height: 14),
        Form(key: _form, child: Column(children: [
          DropdownButtonFormField<OutletModel>(value: _outlet, isExpanded: true, decoration: const InputDecoration(labelText: 'Outlet'), items: _outlets.map((item) => DropdownMenuItem(value: item, child: Text('${item.code} — ${item.name}', overflow: TextOverflow.ellipsis))).toList(), onChanged: (item) => setState(() => _outlet = item), validator: (value) => value == null ? 'Pilih outlet' : null),
          const SizedBox(height: 12),
          DropdownButtonFormField<PromotionModel?>(value: _promotion, isExpanded: true, decoration: const InputDecoration(labelText: 'Program acuan (opsional)'), items: [const DropdownMenuItem<PromotionModel?>(value: null, child: Text('Tanpa program acuan')), ..._promotions.map((item) => DropdownMenuItem<PromotionModel?>(value: item, child: Text(item.title, overflow: TextOverflow.ellipsis)))], onChanged: (item) => setState(() => _promotion = item)),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(value: _type, decoration: const InputDecoration(labelText: 'Keuntungan yang diminta'), items: const [DropdownMenuItem(value: 'Percentage', child: Text('Potongan persentase')), DropdownMenuItem(value: 'Fixed', child: Text('Potongan nominal')), DropdownMenuItem(value: 'Bonus', child: Text('Bonus produk')), DropdownMenuItem(value: 'Bundle', child: Text('Paket khusus')), DropdownMenuItem(value: 'Gift', child: Text('Hadiah'))], onChanged: (item) => setState(() => _type = item ?? _type)),
          const SizedBox(height: 12),
          TextFormField(controller: _value, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Nilai keuntungan (opsional)', hintText: 'Contoh: 5 atau 100000')),
          const SizedBox(height: 12),
          TextFormField(controller: _quantity, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Jumlah produk (opsional)')),
          const SizedBox(height: 12),
          TextFormField(controller: _potentialRevenue, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Potensi omzet (opsional)')),
          const SizedBox(height: 12),
          TextFormField(controller: _reason, maxLines: 3, decoration: const InputDecoration(labelText: 'Alasan pengajuan'), validator: (value) => (value?.trim().length ?? 0) < 10 ? 'Isi alasan minimal 10 karakter' : null),
          const SizedBox(height: 12),
          ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.date_range_rounded, color: AppColors.primary), title: const Text('Periode penggunaan'), subtitle: Text('${_range.start.toLocal().toString().substring(0, 10)} s.d. ${_range.end.toLocal().toString().substring(0, 10)}'), onTap: () async { final picked = await showDateRangePicker(context: context, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)), initialDateRange: _range); if (picked != null) setState(() => _range = picked); }),
          const SizedBox(height: 18),
          SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: _sending ? null : _submit, icon: _sending ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.send_rounded), label: const Text('Kirim untuk Persetujuan'))),
        ])),
      ]),
    ),
  );
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({required this.data});
  final Map<String, dynamic>? data;
  double _number(dynamic value) => value is num ? value.toDouble() : double.tryParse(value?.toString() ?? '') ?? 0;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.primary, Color(0xFF4F8CFF)]), borderRadius: BorderRadius.circular(18)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Ringkasan Promosi Cabang', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
      const SizedBox(height: 12),
      Wrap(spacing: 16, runSpacing: 10, children: [
        _metric('Program aktif', '${data?['activePrograms'] ?? 0}'), _metric('Outlet terlibat', '${data?['participatingOutlets'] ?? 0}'), _metric('Manfaat dipakai', 'Rp ${_number(data?['consumedBenefits']).toStringAsFixed(0)}'), _metric('Menunggu approval', '${data?['pendingSpecialRequests'] ?? 0}'),
      ]),
      const SizedBox(height: 9),
      Text('Kuota dan anggaran resmi divalidasi server saat order disimpan.', style: TextStyle(color: Colors.white.withValues(alpha: .8), fontSize: 11)),
    ]),
  );
  Widget _metric(String label, String value) => SizedBox(width: 132, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)), Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10))]));
}
