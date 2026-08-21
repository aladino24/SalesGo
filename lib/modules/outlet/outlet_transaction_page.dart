import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/theme/app_colors.dart';
import '../../app/widgets/sfa_feedback_dialog.dart';
import '../../core/location/location_service.dart';
import '../../core/media/image_capture_service.dart';
import '../../core/network/api_endpoints.dart';
import '../../data/models/outlet_model.dart';
import '../../data/repositories/outlet_transaction_repository.dart';

enum OutletTransactionType {
  purchase,
  returnItem,
  gift,
  note,
  receivablePayment,
}

extension OutletTransactionTypeX on OutletTransactionType {
  String get title => switch (this) {
    OutletTransactionType.purchase => 'Pembelian Outlet',
    OutletTransactionType.returnItem => 'Retur Produk',
    OutletTransactionType.gift => 'Pemberian Hadiah',
    OutletTransactionType.note => 'Catatan Outlet',
    OutletTransactionType.receivablePayment => 'Pembayaran Piutang',
  };
  String get endpoint => switch (this) {
    OutletTransactionType.purchase => ApiEndpoints.purchases,
    OutletTransactionType.returnItem => ApiEndpoints.returns,
    OutletTransactionType.gift => ApiEndpoints.gifts,
    OutletTransactionType.note => ApiEndpoints.outletNotes,
    OutletTransactionType.receivablePayment => ApiEndpoints.receivablePayments,
  };
  String get queueType => switch (this) {
    OutletTransactionType.purchase => 'purchase_create',
    OutletTransactionType.returnItem => 'return_create',
    OutletTransactionType.gift => 'gift_create',
    OutletTransactionType.note => 'outlet_note_create',
    OutletTransactionType.receivablePayment => 'receivable_payment_create',
  };
}

class OutletTransactionPage extends StatefulWidget {
  const OutletTransactionPage({
    super.key,
    required this.outlet,
    required this.type,
  });
  final OutletModel outlet;
  final OutletTransactionType type;
  @override
  State<OutletTransactionPage> createState() => _OutletTransactionPageState();
}

class _OutletTransactionPageState extends State<OutletTransactionPage> {
  final _item = TextEditingController(),
      _quantity = TextEditingController(text: '1'),
      _amount = TextEditingController(),
      _notes = TextEditingController(),
      _reason = TextEditingController(),
      _condition = TextEditingController(),
      _invoice = TextEditingController();
  final _repository = OutletTransactionRepository();
  final _camera = ImageCaptureService();
  final _location = LocationService();
  DateTime? _dueDate;
  String? _photoPath;
  bool _saving = false;
  List<Map<String, dynamic>> _payments = [];
  bool get _isReturn => widget.type == OutletTransactionType.returnItem;
  bool get _isReceivable =>
      widget.type == OutletTransactionType.receivablePayment;
  bool get _needsItem =>
      widget.type != OutletTransactionType.note && !_isReceivable;
  @override
  void initState() {
    super.initState();
    if (_isReceivable) _loadPayments();
  }

  @override
  void dispose() {
    for (final controller in [
      _item,
      _quantity,
      _amount,
      _notes,
      _reason,
      _condition,
      _invoice,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadPayments() async {
    _payments = await _repository.history(
      outletId: widget.outlet.id,
      type: 'receivable_payment_create',
    );
    if (mounted) setState(() {});
  }

  Future<void> _capturePhoto() async {
    final image = await _camera.captureOutletPhoto();
    if (image != null && mounted) setState(() => _photoPath = image.path);
  }

  Future<void> _save() async {
    if (_needsItem && _item.text.trim().isEmpty) {
      SfaFeedbackDialog.show(type: SfaFeedbackType.warning, title: 'Data belum lengkap', message: 'Nama produk atau hadiah wajib diisi.');
      return;
    }
    if (_isReturn &&
        (_reason.text.trim().isEmpty ||
            _condition.text.trim().isEmpty ||
            _photoPath == null)) {
      SfaFeedbackDialog.show(type: SfaFeedbackType.warning, title: 'Retur belum lengkap', message: 'Alasan, kondisi barang, dan foto retur wajib diisi.');
      return;
    }
    if (_isReceivable &&
        (_invoice.text.trim().isEmpty ||
            (double.tryParse(_amount.text) ?? 0) <= 0)) {
      SfaFeedbackDialog.show(type: SfaFeedbackType.warning, title: 'Piutang belum lengkap', message: 'Nomor invoice dan nominal pembayaran wajib diisi.');
      return;
    }
    setState(() => _saving = true);
    LocationSnapshot? position;
    try {
      position = await _location.currentLocation();
    } catch (_) {}
    await _repository.submit(
      type: widget.type.queueType,
      endpoint: widget.type.endpoint,
      outletId: widget.outlet.id,
      payload: {
        'outletName': widget.outlet.name,
        'item': _item.text.trim(),
        'quantity': int.tryParse(_quantity.text) ?? 0,
        'amount': double.tryParse(_amount.text) ?? 0,
        'notes': _notes.text.trim(),
        if (_isReturn) ...{
          'returnReason': _reason.text.trim(),
          'itemCondition': _condition.text.trim(),
          'photoPath': _photoPath,
          'approvalStatus': 'Waiting Approval',
        },
        if (_isReceivable) ...{
          'invoiceNumber': _invoice.text.trim(),
          'dueDate': _dueDate?.toUtc().toIso8601String(),
          'isOverdue': _dueDate != null && _dueDate!.isBefore(DateTime.now()),
        },
        if (position != null) 'location': position.toJson(),
      },
    );
    if (!mounted) return;
    setState(() => _saving = false);
    Get.back(result: true);
    await SfaFeedbackDialog.show(type: SfaFeedbackType.success, title: 'Tersimpan', message: '${widget.type.title} tersimpan lokal dan menunggu sync.');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.type.title,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
    ),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.storefront_rounded),
            title: Text(widget.outlet.name),
            subtitle: Text(widget.outlet.address),
          ),
        ),
        const SizedBox(height: 18),
        if (_needsItem) ...[
          TextField(
            controller: _item,
            decoration: InputDecoration(
              labelText: widget.type == OutletTransactionType.gift
                  ? 'Jenis Hadiah'
                  : 'Produk',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _quantity,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Quantity'),
          ),
          const SizedBox(height: 12),
        ],
        if (widget.type != OutletTransactionType.note) ...[
          TextField(
            controller: _amount,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: _isReceivable
                  ? 'Nominal pembayaran'
                  : 'Nominal / Harga',
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (_isReturn) ...[
          TextField(
            controller: _reason,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Alasan retur'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _condition,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Kondisi barang'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _capturePhoto,
            icon: const Icon(Icons.camera_alt_outlined),
            label: Text(
              _photoPath == null ? 'Ambil foto barang' : 'Ganti foto barang',
            ),
          ),
          if (_photoPath != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Image.file(
                File(_photoPath!),
                height: 120,
                fit: BoxFit.cover,
              ),
            ),
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Retur akan diajukan untuk approval.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (_isReceivable) ...[
          TextField(
            controller: _invoice,
            decoration: const InputDecoration(labelText: 'Nomor invoice'),
          ),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Jatuh tempo invoice'),
            subtitle: Text(
              _dueDate == null
                  ? 'Belum dipilih'
                  : '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}${_dueDate!.isBefore(DateTime.now()) ? ' • Overdue' : ''}',
            ),
            trailing: const Icon(Icons.calendar_today_outlined),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                firstDate: DateTime(2020),
                initialDate: _dueDate ?? DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 3650)),
              );
              if (date != null) setState(() => _dueDate = date);
            },
          ),
          if (_payments.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Riwayat pembayaran lokal',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    ..._payments
                        .take(3)
                        .map(
                          (payment) => Padding(
                            padding: const EdgeInsets.only(top: 5),
                            child: Text(
                              '${payment['invoiceNumber'] ?? '-'} • Rp ${payment['amount'] ?? 0}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                  ],
                ),
              ),
            ),
        ],
        TextField(
          controller: _notes,
          maxLines: 4,
          decoration: const InputDecoration(labelText: 'Catatan'),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text('Simpan'),
        ),
      ],
    ),
  );
}
