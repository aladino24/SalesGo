import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

import '../../app/theme/app_colors.dart';
import '../../app/widgets/sfa_feedback_dialog.dart';
import '../../app/widgets/sfa_open_street_map.dart';
import '../../core/location/location_service.dart';
import '../../data/models/outlet_model.dart';
import '../../data/repositories/ship_to_location_repository.dart';

class NewShipToLocationPage extends StatefulWidget {
  const NewShipToLocationPage({super.key, required this.outlet});

  final OutletModel outlet;

  @override
  State<NewShipToLocationPage> createState() => _NewShipToLocationPageState();
}

class _NewShipToLocationPageState extends State<NewShipToLocationPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _address = TextEditingController();
  final _contact = TextEditingController();
  final _phone = TextEditingController();
  final _notes = TextEditingController();
  LocationSnapshot? _location;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    _contact.text = widget.outlet.contactName ?? widget.outlet.ownerName ?? '';
    _phone.text = widget.outlet.phone ?? '';
  }

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _contact.dispose();
    _phone.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _setLocation(double latitude, double longitude, {double accuracy = 0}) {
    setState(() => _location = LocationSnapshot(
          latitude: latitude,
          longitude: longitude,
          accuracy: accuracy,
          capturedAt: DateTime.now(),
        ));
  }

  Future<void> _useCurrentLocation() async {
    try {
      final snapshot = await LocationService().currentLocation();
      if (mounted) {
        _setLocation(snapshot.latitude, snapshot.longitude,
            accuracy: snapshot.accuracy);
      }
    } on LocationFailure catch (error) {
      if (mounted) {
        await SfaFeedbackDialog.show(
          type: SfaFeedbackType.warning,
          title: 'Lokasi belum tersedia',
          message: error.message,
        );
      }
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_location == null) {
      await SfaFeedbackDialog.show(
        type: SfaFeedbackType.warning,
        title: 'Titik lokasi wajib',
        message: 'Gunakan lokasi Anda atau ketuk peta untuk menentukan lokasi pengiriman.',
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final response = await ShipToLocationRepository().requestLocation(
        outlet: widget.outlet,
        payload: {
          'name': _name.text.trim(),
          'address': _address.text.trim(),
          'contactName': _contact.text.trim(),
          'phone': _phone.text.trim(),
          'notes': _notes.text.trim(),
          'latitude': _location!.latitude,
          'longitude': _location!.longitude,
        },
      );
      if (!mounted) return;
      final requiresApproval = response['approvalRequired'] != false;
      await SfaFeedbackDialog.show(
        type: requiresApproval
            ? SfaFeedbackType.approval
            : SfaFeedbackType.success,
        title: requiresApproval
            ? 'Lokasi dikirim untuk approval'
            : 'Lokasi pengiriman ditambahkan',
        message: requiresApproval
            ? 'Branch Manager akan meninjau alamat dan titik lokasi sebelum dapat digunakan pada order.'
            : 'Lokasi pengiriman langsung aktif dan dapat dipilih pada order berikutnya.',
      );
      if (mounted) Get.back(result: true);
    } catch (error) {
      if (mounted) {
        await SfaFeedbackDialog.show(
          type: SfaFeedbackType.error,
          title: 'Pengajuan belum terkirim',
          message: error.toString().replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final point = LatLng(
      _location?.latitude ?? widget.outlet.latitude,
      _location?.longitude ?? widget.outlet.longitude,
    );
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Tambah Lokasi Pengiriman',
            style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
            children: [
              _Header(outlet: widget.outlet),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Informasi tujuan',
                icon: Icons.local_shipping_outlined,
                child: Column(children: [
                  TextFormField(
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Nama lokasi pengiriman *',
                      hintText: 'Contoh: Gudang Utama Outlet',
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Nama lokasi wajib diisi'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _address,
                    minLines: 2,
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(labelText: 'Alamat lengkap *'),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Alamat wajib diisi'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _contact,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Nama kontak/PIC'),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Nomor telepon'),
                  ),
                ]),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Titik lokasi pengiriman',
                icon: Icons.location_on_outlined,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Ketuk peta untuk meletakkan marker, atau gunakan GPS perangkat.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 260,
                    child: SfaOpenStreetMap(
                      key: ValueKey('${point.latitude}:${point.longitude}'),
                      center: point,
                      zoom: _location == null ? 14 : 16,
                      markers: _location == null
                          ? const []
                          : [SfaMapMarker(point: point, label: 'Kirim', color: AppColors.primary)],
                      onMapTap: (value) => _setLocation(value.latitude, value.longitude),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(children: [
                    OutlinedButton.icon(
                      onPressed: _useCurrentLocation,
                      icon: const Icon(Icons.my_location_rounded),
                      label: const Text('Gunakan lokasi saya'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _location == null
                            ? 'Belum memilih titik lokasi'
                            : '${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}',
                        textAlign: TextAlign.end,
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ),
                  ]),
                ]),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Catatan pengajuan',
                icon: Icons.notes_outlined,
                child: TextField(
                  controller: _notes,
                  minLines: 2,
                  maxLines: 4,
                  maxLength: 500,
                  decoration: const InputDecoration(
                    hintText: 'Contoh: Gudang penerimaan barang di belakang outlet.',
                  ),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _saving ? null : _submit,
                icon: _saving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send_rounded),
                label: Text(_saving ? 'Mengirim...' : 'Kirim pengajuan lokasi'),
              ),
              const SizedBox(height: 10),
              const Text('Sales dan Supervisor memerlukan approval Branch Manager. Branch Manager dapat menambahkan lokasi langsung aktif.', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.outlet});
  final OutletModel outlet;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [AppColors.primary, Color(0xFF4F8CFF)]),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(children: [
          const CircleAvatar(backgroundColor: Colors.white24, child: Icon(Icons.storefront_rounded, color: Colors.white)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(outlet.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
            Text(outlet.code, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ])),
        ]),
      );
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.icon, required this.child});
  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Icon(icon, color: AppColors.primary), const SizedBox(width: 8), Text(title, style: const TextStyle(fontWeight: FontWeight.w800))]),
          const SizedBox(height: 14),
          child,
        ]),
      );
}
