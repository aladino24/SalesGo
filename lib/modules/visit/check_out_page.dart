import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';

import '../../app/theme/app_colors.dart';
import '../../app/widgets/sfa_open_street_map.dart';
import '../../app/widgets/sfa_ui.dart';
import '../../core/location/location_service.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/sync/sync_manager.dart';
import '../../data/datasources/local/visit_local_data_source.dart';
import '../../data/models/outlet_model.dart';
import '../../data/repositories/visit_timeline_repository.dart';

class CheckOutPage extends StatefulWidget { const CheckOutPage({super.key, required this.outlet, required this.visitId}); final OutletModel outlet; final String visitId; @override State<CheckOutPage> createState() => _CheckOutPageState(); }
class _CheckOutPageState extends State<CheckOutPage> { final _location = LocationService(), _notes = TextEditingController(), _localVisits = VisitLocalDataSource(); LocationSnapshot? snapshot; String? error; bool loading = true, saving = false; @override void initState() { super.initState(); _load(); } @override void dispose() { _notes.dispose(); super.dispose(); }
  Future<void> _load() async { setState(() { loading = true; error = null; }); try { snapshot = await _location.currentLocation(); } on LocationFailure catch (e) { error = e.message; } catch (_) { error = 'Lokasi tidak dapat diambil.'; } if (mounted) setState(() => loading = false); }
  Future<void> _submit() async { if (snapshot == null) { Get.snackbar('GPS diperlukan', error ?? 'Ambil lokasi terlebih dahulu.'); return; } setState(() => saving = true); const uuid = Uuid(); await _localVisits.updateStatus(widget.visitId, 'Completed'); await Get.find<SyncManager>().queueItem(type: 'visit_check_out', endpoint: ApiEndpoints.checkOuts, method: 'POST', uuid: uuid.v4(), idempotencyKey: uuid.v4(), payload: {'visitId': widget.visitId, 'outletId': widget.outlet.id, 'notes': _notes.text.trim(), 'location': snapshot!.toJson()}); await VisitTimelineRepository().record(outletId: widget.outlet.id, visitId: widget.visitId, activity: 'check_out', description: 'Check-out outlet', location: snapshot!.toJson()); if (!mounted) return; setState(() => saving = false); Get.back(result: true); Get.snackbar('Check-out berhasil', 'Kunjungan selesai dan siap disinkronkan.', snackPosition: SnackPosition.BOTTOM); }
  @override Widget build(BuildContext context) { final outlet = LatLng(widget.outlet.latitude, widget.outlet.longitude); final current = snapshot == null ? outlet : LatLng(snapshot!.latitude, snapshot!.longitude); return Scaffold(appBar: AppBar(title: const Text('Check-out Outlet', style: TextStyle(fontWeight: FontWeight.w800))), body: SafeArea(child: ListView(padding: const EdgeInsets.all(16), children: [SizedBox(height: 205, child: SfaOpenStreetMap(center: current, zoom: 16.5, markers: [SfaMapMarker(point: outlet, label: 'Outlet', color: AppColors.primary), SfaMapMarker(point: current, label: '', color: AppColors.success, isCurrentLocation: true)])), const SizedBox(height: 16), Text(widget.outlet.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)), const SizedBox(height: 8), loading ? const LinearProgressIndicator() : error != null ? Row(children: [Expanded(child: Text(error!, style: const TextStyle(color: AppColors.danger, fontSize: 12))), TextButton(onPressed: _load, child: const Text('Coba lagi'))]) : const Row(children: [Icon(Icons.gps_fixed_rounded, color: AppColors.success), SizedBox(width: 8), Text('Lokasi checkout tervalidasi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600))]), const SizedBox(height: 20), const Text('Catatan Checkout (Opsional)', style: TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 8), TextField(controller: _notes, maxLines: 4, decoration: const InputDecoration(hintText: 'Tulis ringkasan kunjungan...')), const SizedBox(height: 20), FilledButton(onPressed: saving ? null : _submit, child: saving ? const CircularProgressIndicator(color: Colors.white) : const Text('Check-out'))]))); }
}
