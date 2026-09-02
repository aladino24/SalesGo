import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import '../../app/theme/app_colors.dart';
import '../../app/widgets/sfa_feedback_dialog.dart';
import '../../core/location/location_service.dart';
import '../../core/media/image_capture_service.dart';
import '../../core/network/network_info.dart';
import '../../data/models/outlet_model.dart';
import '../../data/repositories/payment_repository.dart';

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key, required this.outlet});
  final OutletModel outlet;

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final _repository = PaymentRepository();
  final _amount = TextEditingController();
  final _notes = TextEditingController();
  final _reference = TextEditingController();
  final _selected = <String, bool>{};
  Map<String, dynamic> _data = const {};
  bool _loading = true;
  bool _sending = false;
  String _method = 'Cash';
  String? _proofPath;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _amount.dispose();
    _notes.dispose();
    _reference.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _data = await _repository.summary(widget.outlet.id);
    } catch (_) {
      _data = const {};
    }
    if (mounted) setState(() => _loading = false);
  }

  List<Map<String, dynamic>> get _invoices =>
      (_data['invoices'] as List? ?? const [])
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
  double get _amountValue =>
      double.tryParse(_amount.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
  List<Map<String, dynamic>> _autoAllocations(double amount) {
    var remaining = amount;
    final values = <Map<String, dynamic>>[];
    for (final invoice in _invoices.where(
      (item) => _selected[item['id']?.toString()] == true,
    )) {
      if (remaining <= 0) break;
      final outstanding = _number(invoice['outstandingAmount']);
      final used = remaining < outstanding ? remaining : outstanding;
      values.add({
        'invoiceId': int.tryParse(invoice['id'].toString()) ?? invoice['id'],
        'amount': used,
      });
      remaining -= used;
    }
    return values;
  }

  Future<void> _captureProof() async {
    final photo = await ImageCaptureService().captureOutletPhoto();
    if (photo != null && mounted) setState(() => _proofPath = photo.path);
  }

  Future<void> _submit() async {
    final amount = _amountValue;
    if (amount <= 0) {
      await SfaFeedbackDialog.show(
        type: SfaFeedbackType.warning,
        title: 'Jumlah belum valid',
        message: 'Jumlah pembayaran harus lebih dari Rp0.',
      );
      return;
    }
    final allocations = _autoAllocations(amount);
    if (allocations.isEmpty) {
      await SfaFeedbackDialog.show(
        type: SfaFeedbackType.warning,
        title: 'Faktur belum dipilih',
        message: 'Pilih minimal satu faktur untuk dialokasikan.',
      );
      return;
    }
    final online = await Get.find<NetworkInfo>().isConnected;
    if (!online && _method != 'Cash') {
      await SfaFeedbackDialog.show(
        type: SfaFeedbackType.warning,
        title: 'Metode belum tersedia offline',
        message: 'Saat offline hanya pembayaran tunai yang dapat dicatat.',
      );
      return;
    }
    if (_method == 'Transfer' && _proofPath == null) {
      await SfaFeedbackDialog.show(
        type: SfaFeedbackType.warning,
        title: 'Bukti transfer wajib',
        message: 'Ambil foto bukti transfer sebelum mengirim pembayaran.',
      );
      return;
    }
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Tinjau Pembayaran'),
        content: Text(
          'Outlet: ${widget.outlet.name}\nJumlah: Rp ${amount.toStringAsFixed(0)}\nDialokasikan ke ${allocations.length} faktur\nMetode: ${_method == 'Cash' ? 'Tunai' : 'Transfer'}\n\nData tidak dapat diedit setelah dikirim.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Kembali'),
          ),
          FilledButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Kirim Pembayaran'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _sending = true);
    try {
      const uuid = Uuid();
      Map<String, dynamic>? location;
      try {
        final snapshot = await LocationService().currentLocation();
        location = {
          'latitude': snapshot.latitude,
          'longitude': snapshot.longitude,
          'accuracyMeters': snapshot.accuracy,
        };
      } catch (_) {
        // Check-in sebelumnya sudah menjadi prasyarat server. Bila GPS baru
        // saja tidak tersedia, pembayaran tetap dapat diantrekan dan server
        // tetap memiliki lokasi kunjungan aktif sebagai konteks audit.
      }
      await _repository.create({
        'id': uuid.v4(),
        'outletId': int.tryParse(widget.outlet.id) ?? widget.outlet.id,
        'amount': amount,
        'components': [
          {
            'method': _method,
            'amount': amount,
            if (_reference.text.trim().isNotEmpty)
              'referenceNumber': _reference.text.trim(),
            if (_proofPath != null) 'attachmentLocalPaths': [_proofPath],
          },
        ],
        'allocations': allocations,
        'notes': _notes.text.trim(),
        'confirmed': true,
        if (location != null) 'location': location,
      });
      if (!mounted) return;
      await SfaFeedbackDialog.show(
        type: SfaFeedbackType.success,
        title: 'Pembayaran dicatat',
        message: online
            ? 'Pembayaran sudah masuk antrean verifikasi.'
            : 'Pembayaran tersimpan di perangkat dan akan dikirim saat internet tersedia.',
      );
      if (mounted) Get.back(result: true);
    } catch (_) {
      if (mounted) {
        await SfaFeedbackDialog.show(
          type: SfaFeedbackType.error,
          title: 'Pembayaran belum tersimpan',
          message: 'Periksa data pembayaran lalu coba kembali.',
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = _data['summary'] is Map
        ? Map<String, dynamic>.from(_data['summary'] as Map)
        : const <String, dynamic>{};
    final outlet = _data['outlet'] is Map
        ? Map<String, dynamic>.from(_data['outlet'] as Map)
        : const <String, dynamic>{};
    return Scaffold(
      appBar: AppBar(title: const Text('Piutang & Pembayaran')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, Color(0xFF4F8CFF)],
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          outlet['name']?.toString() ?? widget.outlet.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                          ),
                        ),
                        Text(
                          outlet['code']?.toString() ?? widget.outlet.code,
                          style: const TextStyle(color: Colors.white70),
                        ),
                        if ((outlet['ownerName']?.toString() ?? '').isNotEmpty)
                          Text(
                            'PIC: ${outlet['ownerName']}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        if ((outlet['address']?.toString() ?? '').isNotEmpty)
                          Text(
                            outlet['address'].toString(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white70),
                          ),
                        const SizedBox(height: 12),
                        Text(
                          'Total Piutang  Rp ${_number(summary['outstandingAmount']).toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Lewat jatuh tempo  Rp ${_number(summary['overdueAmount']).toStringAsFixed(0)}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        Text(
                          'Status kredit: ${summary['creditStatus'] ?? 'Aktif'} • ${summary['openInvoices'] ?? 0} faktur terbuka',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Pilih Faktur',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  ..._invoices.map((invoice) {
                    final id = invoice['id'].toString();
                    return Card(
                      child: CheckboxListTile(
                        value: _selected[id] ?? false,
                        onChanged: (value) =>
                            setState(() => _selected[id] = value ?? false),
                        title: Text(
                          invoice['invoiceNumber']?.toString() ?? '-',
                        ),
                        subtitle: Text(
                          'Jatuh tempo ${invoice['dueDate'] ?? '-'} • Sisa Rp ${_number(invoice['outstandingAmount']).toStringAsFixed(0)}\n${invoice['status'] ?? ''}',
                        ),
                        isThreeLine: true,
                      ),
                    );
                  }),
                  if (_invoices.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(
                        child: Text(
                          'Tidak ada faktur pada cache perangkat. Unduh data terbaru saat online.',
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _amount,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Jumlah Pembayaran',
                      prefixText: 'Rp ',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: _method,
                    decoration: const InputDecoration(
                      labelText: 'Metode Pembayaran',
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Cash', child: Text('Tunai')),
                      DropdownMenuItem(
                        value: 'Transfer',
                        child: Text('Transfer Bank'),
                      ),
                    ],
                    onChanged: (value) =>
                        setState(() => _method = value ?? 'Cash'),
                  ),
                  if (_method == 'Transfer') ...[
                    const SizedBox(height: 10),
                    TextField(
                      controller: _reference,
                      decoration: const InputDecoration(
                        labelText: 'Nomor Referensi Transfer',
                      ),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        _proofPath == null
                            ? Icons.camera_alt_outlined
                            : Icons.check_circle,
                        color: _proofPath == null
                            ? AppColors.primary
                            : AppColors.success,
                      ),
                      title: Text(
                        _proofPath == null
                            ? 'Ambil Foto Bukti Transfer'
                            : 'Bukti transfer siap',
                      ),
                      onTap: _captureProof,
                    ),
                  ],
                  const SizedBox(height: 10),
                  TextField(
                    controller: _notes,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Catatan (opsional)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Alokasi otomatis: Rp ${_autoAllocations(_amountValue).fold<double>(0, (sum, item) => sum + _number(item['amount'])).toStringAsFixed(0)}',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _sending ? null : _submit,
                    icon: _sending
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.payments_rounded),
                    label: const Text('Kirim Pembayaran'),
                  ),
                ],
              ),
            ),
    );
  }

  static double _number(dynamic value) => value is num
      ? value.toDouble()
      : double.tryParse(value?.toString() ?? '') ?? 0;
}
