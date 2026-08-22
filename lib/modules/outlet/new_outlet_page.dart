import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

import '../../app/theme/app_colors.dart';
import '../../app/widgets/sfa_feedback_dialog.dart';
import '../../app/widgets/sfa_open_street_map.dart';
import '../../core/location/location_service.dart';
import '../../core/network/api_client.dart';

class NewOutletPage extends StatefulWidget {
  const NewOutletPage({super.key});
  @override State<NewOutletPage> createState() => _NewOutletPageState();
}

class _NewOutletPageState extends State<NewOutletPage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController(), _address = TextEditingController(), _owner = TextEditingController(), _contact = TextEditingController(), _phone = TextEditingController();
  LocationSnapshot? _location;
  var _type = 'Grosir';
  var _saving = false;
  @override void dispose() { for (final item in [_name, _address, _owner, _contact, _phone]) { item.dispose(); } super.dispose(); }
  Future<void> _gps() async { try { final result = await LocationService().currentLocation(); if (mounted) setState(() => _location = result); } on LocationFailure catch (error) { await SfaFeedbackDialog.show(type: SfaFeedbackType.error, title: 'GPS tidak tersedia', message: error.message); } }
  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    if (_location == null) { await SfaFeedbackDialog.show(type: SfaFeedbackType.warning, title: 'Titik lokasi wajib', message: 'Ambil titik lokasi outlet terlebih dahulu.'); return; }
    setState(() => _saving = true);
    try { final result = await Get.find<ApiClient>().post<Map<String, dynamic>>('/outlets', data: {'name': _name.text.trim(), 'address': _address.text.trim(), 'type': _type, 'ownerName': _owner.text.trim(), 'contactName': _contact.text.trim(), 'phone': _phone.text.trim(), 'latitude': _location!.latitude, 'longitude': _location!.longitude}); if (!mounted) return; Get.back(); await SfaFeedbackDialog.show(type: SfaFeedbackType.approval, title: 'Outlet diajukan', message: 'Outlet ${result['code'] ?? ''} menunggu approval Branch Manager.'); } catch (error) { await SfaFeedbackDialog.show(type: SfaFeedbackType.error, title: 'Pengajuan gagal', message: error.toString()); } finally { if (mounted) setState(() => _saving = false); }
  }
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Pengajuan Outlet Baru')), body: Form(key: _form, child: ListView(padding: const EdgeInsets.all(16), children: [
    const Text('Data Outlet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
    TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'Nama outlet'), validator: (value) => value == null || value.trim().isEmpty ? 'Nama outlet wajib' : null),
    TextFormField(controller: _address, maxLines: 2, decoration: const InputDecoration(labelText: 'Alamat lengkap'), validator: (value) => value == null || value.trim().isEmpty ? 'Alamat wajib' : null),
    DropdownButtonFormField<String>(value: _type, decoration: const InputDecoration(labelText: 'Tipe outlet'), items: const ['Grosir', 'Retail', 'Distributor'].map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(), onChanged: (value) => setState(() => _type = value ?? _type)),
    const SizedBox(height: 16), const Text('Kontak', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
    TextField(controller: _owner, decoration: const InputDecoration(labelText: 'Nama pemilik')),
    TextField(controller: _contact, decoration: const InputDecoration(labelText: 'Nama kontak')),
    TextField(controller: _phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Telepon')),
    const SizedBox(height: 16), const Text('Titik Lokasi Outlet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)), const SizedBox(height: 8),
    SizedBox(height: 190, child: _location == null ? OutlinedButton.icon(onPressed: _gps, icon: const Icon(Icons.my_location_rounded), label: const Text('Ambil Titik Lokasi GPS')) : SfaOpenStreetMap(center: LatLng(_location!.latitude, _location!.longitude), markers: [SfaMapMarker(point: LatLng(_location!.latitude, _location!.longitude), label: 'Outlet', color: AppColors.primary)])),
    if (_location != null) Text('${_location!.latitude.toStringAsFixed(6)}, ${_location!.longitude.toStringAsFixed(6)}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
    const SizedBox(height: 20), FilledButton(onPressed: _saving ? null : _save, child: Text(_saving ? 'Mengirim...' : 'Ajukan ke Branch Manager')),
  ])));
}
