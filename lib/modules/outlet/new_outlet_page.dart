import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

import '../../app/theme/app_colors.dart';
import '../../app/widgets/sfa_open_street_map.dart';
import '../../core/location/location_service.dart';
import '../../core/network/api_client.dart';

class NewOutletPage extends StatefulWidget {
  const NewOutletPage({super.key});

  @override
  State<NewOutletPage> createState() => _NewOutletPageState();
}

class _NewOutletPageState extends State<NewOutletPage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _address = TextEditingController();
  final _owner = TextEditingController();
  final _contact = TextEditingController();
  final _phone = TextEditingController();
  final _latitude = TextEditingController();
  final _longitude = TextEditingController();
  int _step = 0;
  String _type = 'Grosir';
  LocationSnapshot? _location;
  bool _saving = false;
  String? _submittedCode;

  @override
  void dispose() {
    for (final item in [_name, _address, _owner, _contact, _phone, _latitude, _longitude]) {
      item.dispose();
    }
    super.dispose();
  }

  void _setPoint(double latitude, double longitude, {double accuracy = 0}) {
    setState(() {
      _location = LocationSnapshot(latitude: latitude, longitude: longitude, accuracy: accuracy, capturedAt: DateTime.now());
      _latitude.text = latitude.toStringAsFixed(6);
      _longitude.text = longitude.toStringAsFixed(6);
    });
  }

  Future<void> _useCurrentLocation() async {
    try {
      final point = await LocationService().currentLocation();
      if (mounted) _setPoint(point.latitude, point.longitude, accuracy: point.accuracy);
    } on LocationFailure catch (error) {
      if (mounted) await _message('GPS tidak tersedia', error.message, Icons.gps_off_rounded, AppColors.danger);
    }
  }

  Future<void> _applyCoordinates() async {
    final lat = double.tryParse(_latitude.text.trim().replaceAll(',', '.'));
    final lng = double.tryParse(_longitude.text.trim().replaceAll(',', '.'));
    if (lat == null || lng == null || lat < -90 || lat > 90 || lng < -180 || lng > 180) {
      await _message('Koordinat tidak valid', 'Latitude harus -90 s.d. 90 dan longitude -180 s.d. 180.', Icons.error_outline_rounded, AppColors.danger);
      return;
    }
    _setPoint(lat, lng);
  }

  Future<void> _next() async {
    if (_step == 0 && !(_form.currentState?.validate() ?? false)) return;
    if (_step == 1 && _location == null) {
      await _message('Titik lokasi wajib', 'Gunakan lokasi saya, masukkan koordinat, atau ketuk peta untuk membuat marker outlet.', Icons.location_off_rounded, AppColors.warning);
      return;
    }
    if (_step == 2) return _submit();
    setState(() => _step += 1);
  }

  Future<void> _submit() async {
    if (_location == null) return;
    setState(() => _saving = true);
    try {
      final response = await Get.find<ApiClient>().post<Map<String, dynamic>>('/outlets', data: {
        'name': _name.text.trim(), 'address': _address.text.trim(), 'type': _type,
        'ownerName': _owner.text.trim(), 'contactName': _contact.text.trim(), 'phone': _phone.text.trim(),
        'latitude': _location!.latitude, 'longitude': _location!.longitude,
      });
      if (mounted) setState(() { _submittedCode = response['code']?.toString(); _step = 3; });
    } catch (error) {
      if (mounted) await _message('Pengajuan gagal', error.toString().replaceFirst('Exception: ', ''), Icons.error_outline_rounded, AppColors.danger);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _message(String title, String body, IconData icon, Color color) => Get.dialog<void>(AlertDialog(
    content: Column(mainAxisSize: MainAxisSize.min, children: [
      CircleAvatar(radius: 28, backgroundColor: color.withValues(alpha: .12), child: Icon(icon, color: color, size: 32)),
      const SizedBox(height: 13), Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
      const SizedBox(height: 7), Text(body, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
    ]),
    actions: [SizedBox(width: double.infinity, child: FilledButton(onPressed: () => Get.back(), child: const Text('Mengerti')))],
  ));

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      title: const Text('Tambah Outlet Baru', style: TextStyle(fontWeight: FontWeight.w800)),
      leading: IconButton(onPressed: () => _step == 0 ? Get.back() : setState(() => _step -= 1), icon: const Icon(Icons.arrow_back_rounded)),
    ),
    body: SafeArea(child: AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: _step == 3 ? _SuccessStep(name: _name.text, code: _submittedCode ?? '-', onDone: () => Get.back()) : ListView(
        key: ValueKey(_step), padding: const EdgeInsets.fromLTRB(16, 8, 16, 28), children: [
          _ProgressHeader(activeStep: _step), const SizedBox(height: 24),
          if (_step == 0) _InformationStep(formKey: _form, name: _name, address: _address, owner: _owner, contact: _contact, phone: _phone, type: _type, onTypeChanged: (value) => setState(() => _type = value ?? _type)),
          if (_step == 1) _LocationStep(location: _location, latitude: _latitude, longitude: _longitude, onCurrentLocation: _useCurrentLocation, onApplyCoordinates: _applyCoordinates, onMapTap: (point) => _setPoint(point.latitude, point.longitude)),
          if (_step == 2) _ReviewStep(name: _name.text, address: _address.text, owner: _owner.text, contact: _contact.text, phone: _phone.text, type: _type, location: _location!),
          const SizedBox(height: 26), Row(children: [
            if (_step > 0) Expanded(child: OutlinedButton(onPressed: () => setState(() => _step -= 1), child: const Text('Kembali'))),
            if (_step > 0) const SizedBox(width: 12),
            Expanded(child: FilledButton.icon(onPressed: _saving ? null : _next, icon: Icon(_step == 2 ? Icons.send_rounded : Icons.arrow_forward_rounded), label: Text(_saving ? 'Mengirim...' : _step == 2 ? 'Kirim untuk Approval' : 'Lanjutkan'))),
          ]),
        ],
      ),
    )),
  );
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.activeStep});
  final int activeStep;
  @override
  Widget build(BuildContext context) {
    const labels = ['Informasi', 'Lokasi', 'Review'];
    return Row(children: List.generate(3, (index) {
      final done = index < activeStep; final active = index == activeStep;
      return Expanded(child: Column(children: [
        Row(children: [Expanded(child: Container(height: 2, color: index == 0 ? Colors.transparent : (index <= activeStep ? AppColors.primary : AppColors.border))), CircleAvatar(radius: 13, backgroundColor: done || active ? AppColors.primary : AppColors.border, child: done ? const Icon(Icons.check_rounded, color: Colors.white, size: 16) : Text('${index + 1}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: active ? Colors.white : AppColors.textSecondary))), Expanded(child: Container(height: 2, color: index == 2 ? Colors.transparent : (index < activeStep ? AppColors.primary : AppColors.border)))]),
        const SizedBox(height: 7), Text(labels[index], style: TextStyle(fontSize: 11, color: done || active ? AppColors.primary : AppColors.textSecondary, fontWeight: active ? FontWeight.w800 : FontWeight.w500)),
      ]));
    }));
  }
}

class _InformationStep extends StatelessWidget {
  const _InformationStep({required this.formKey, required this.name, required this.address, required this.owner, required this.contact, required this.phone, required this.type, required this.onTypeChanged});
  final GlobalKey<FormState> formKey; final TextEditingController name, address, owner, contact, phone; final String type; final ValueChanged<String?> onTypeChanged;
  @override
  Widget build(BuildContext context) => Form(key: formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('Informasi Outlet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)), const SizedBox(height: 4), const Text('Lengkapi data dasar outlet sebelum menentukan lokasi.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)), const SizedBox(height: 18),
    _FormCard(children: [
      TextFormField(controller: name, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Nama Outlet *', prefixIcon: Icon(Icons.storefront_outlined)), validator: (value) => value == null || value.trim().isEmpty ? 'Nama outlet wajib diisi' : null), const SizedBox(height: 14),
      DropdownButtonFormField<String>(value: type, decoration: const InputDecoration(labelText: 'Tipe Outlet *', prefixIcon: Icon(Icons.category_outlined)), items: const ['Grosir', 'Retail', 'Distributor'].map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(), onChanged: onTypeChanged), const SizedBox(height: 14),
      const TextField(enabled: false, decoration: InputDecoration(labelText: 'Kode Outlet (otomatis)', hintText: 'Dibuat setelah pengajuan disimpan', prefixIcon: Icon(Icons.tag_rounded))), const SizedBox(height: 14),
      TextField(controller: owner, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Pemilik Outlet', prefixIcon: Icon(Icons.person_outline_rounded))), const SizedBox(height: 14),
      TextField(controller: contact, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Nama Kontak', prefixIcon: Icon(Icons.badge_outlined))), const SizedBox(height: 14),
      TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'No. Telepon', prefixIcon: Icon(Icons.phone_outlined))), const SizedBox(height: 14),
      TextFormField(controller: address, minLines: 2, maxLines: 3, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(labelText: 'Alamat Lengkap *', prefixIcon: Icon(Icons.location_on_outlined)), validator: (value) => value == null || value.trim().isEmpty ? 'Alamat wajib diisi' : null),
    ]),
  ]));
}

class _LocationStep extends StatelessWidget {
  const _LocationStep({required this.location, required this.latitude, required this.longitude, required this.onCurrentLocation, required this.onApplyCoordinates, required this.onMapTap});
  final LocationSnapshot? location; final TextEditingController latitude, longitude; final VoidCallback onCurrentLocation, onApplyCoordinates; final ValueChanged<LatLng> onMapTap;
  @override
  Widget build(BuildContext context) {
    final point = LatLng(location?.latitude ?? -7.2575, location?.longitude ?? 112.7521);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Pilih Titik Lokasi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)), const SizedBox(height: 4), const Text('Ketuk peta untuk menyesuaikan titik outlet atau gunakan lokasi Anda.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)), const SizedBox(height: 16),
      SizedBox(height: 300, child: SfaOpenStreetMap(key: ValueKey('${point.latitude},${point.longitude}'), center: point, zoom: location == null ? 12.5 : 16, markers: location == null ? const [] : [SfaMapMarker(point: point, label: 'Outlet', color: AppColors.primary)], onMapTap: onMapTap)), const SizedBox(height: 14),
      _FormCard(children: [
        Row(children: [const Expanded(child: Text('Titik lokasi outlet', style: TextStyle(fontWeight: FontWeight.w800))), OutlinedButton.icon(onPressed: onCurrentLocation, icon: const Icon(Icons.my_location_rounded, size: 17), label: const Text('Lokasi saya'))]), const SizedBox(height: 10),
        Row(children: [Expanded(child: TextField(controller: latitude, keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true), decoration: const InputDecoration(labelText: 'Latitude'))), const SizedBox(width: 10), Expanded(child: TextField(controller: longitude, keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true), decoration: const InputDecoration(labelText: 'Longitude')))]),
        Align(alignment: Alignment.centerRight, child: TextButton.icon(onPressed: onApplyCoordinates, icon: const Icon(Icons.pin_drop_outlined), label: const Text('Terapkan koordinat'))),
      ]),
    ]);
  }
}

class _ReviewStep extends StatelessWidget {
  const _ReviewStep({required this.name, required this.address, required this.owner, required this.contact, required this.phone, required this.type, required this.location});
  final String name, address, owner, contact, phone, type; final LocationSnapshot location;
  @override
  Widget build(BuildContext context) {
    final point = LatLng(location.latitude, location.longitude);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Review Data Outlet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)), const SizedBox(height: 4), const Text('Pastikan informasi dan titik lokasi sudah benar sebelum dikirim.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)), const SizedBox(height: 16),
      _FormCard(children: [_ReviewRow(Icons.storefront_outlined, 'Nama Outlet', name), _ReviewRow(Icons.category_outlined, 'Tipe Outlet', type), if (owner.isNotEmpty) _ReviewRow(Icons.person_outline_rounded, 'Pemilik', owner), if (contact.isNotEmpty) _ReviewRow(Icons.badge_outlined, 'Kontak', contact), if (phone.isNotEmpty) _ReviewRow(Icons.phone_outlined, 'No. Telepon', phone), _ReviewRow(Icons.location_on_outlined, 'Alamat', address)]),
      const SizedBox(height: 16), const Text('Lokasi Outlet', style: TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 8), SizedBox(height: 150, child: SfaOpenStreetMap(center: point, zoom: 16, markers: [SfaMapMarker(point: point, label: 'Outlet', color: AppColors.primary)])), const SizedBox(height: 8),
      Text('Latitude  ${point.latitude.toStringAsFixed(6)}\nLongitude  ${point.longitude.toStringAsFixed(6)}', style: const TextStyle(fontSize: 12, height: 1.6, color: AppColors.textSecondary)),
    ]);
  }
}

class _SuccessStep extends StatelessWidget {
  const _SuccessStep({required this.name, required this.code, required this.onDone});
  final String name, code; final VoidCallback onDone;
  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Container(width: 112, height: 112, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.success.withValues(alpha: .12)), child: const Icon(Icons.check_rounded, size: 72, color: AppColors.success)), const SizedBox(height: 22), const Text('Pengajuan Berhasil!', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800)), const SizedBox(height: 10), const Text('Outlet baru telah dikirim untuk persetujuan Branch Manager.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary, height: 1.45)), const SizedBox(height: 28),
    _FormCard(children: [Row(children: [const CircleAvatar(backgroundColor: AppColors.primarySoft, child: Icon(Icons.storefront_rounded, color: AppColors.primary)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: const TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 3), Text(code, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)), const SizedBox(height: 6), const _StatusPill()]))])]), const SizedBox(height: 28), SizedBox(width: double.infinity, child: FilledButton(onPressed: onDone, child: const Text('Selesai'))),
  ])));
}

class _StatusPill extends StatelessWidget { const _StatusPill(); @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: .13), borderRadius: BorderRadius.circular(8)), child: const Text('Menunggu Approval', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.warning))); }
class _FormCard extends StatelessWidget { const _FormCard({required this.children}); final List<Widget> children; @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children)); }
class _ReviewRow extends StatelessWidget { const _ReviewRow(this.icon, this.label, this.value); final IconData icon; final String label, value; @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 7), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, size: 17, color: AppColors.primary), const SizedBox(width: 10), Expanded(child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))), const SizedBox(width: 12), Flexible(child: Text(value, textAlign: TextAlign.end, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)))])); }
