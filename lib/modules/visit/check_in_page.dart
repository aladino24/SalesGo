import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';

import '../../app/theme/app_colors.dart';
import '../../app/widgets/sfa_open_street_map.dart';
import '../../app/widgets/sfa_ui.dart';
import '../../app/widgets/sfa_feedback_dialog.dart';
import '../../core/location/location_service.dart';
import '../../core/media/image_capture_service.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/sync/sync_manager.dart';
import '../../data/datasources/local/visit_local_data_source.dart';
import '../../data/models/outlet_model.dart';
import '../../data/models/visit_model.dart';
import '../../data/repositories/visit_timeline_repository.dart';

class CheckInPage extends StatefulWidget {
  const CheckInPage({super.key, required this.outlet});

  final OutletModel outlet;

  @override
  State<CheckInPage> createState() => _CheckInPageState();
}

class _CheckInPageState extends State<CheckInPage> {
  static const _allowedRadiusMeters = 100.0;

  final _locationService = LocationService();
  final _imageService = ImageCaptureService();
  final _localVisits = VisitLocalDataSource();
  final _notesController = TextEditingController();

  LocationSnapshot? _location;
  String? _photoPath;
  String? _locationError;
  bool _isLoadingLocation = true;
  bool _isSubmitting = false;
  String? _overrideReason;

  double get _distanceMeters {
    final location = _location;
    if (location == null) return 0;
    return _locationService.distanceInMeters(
      fromLatitude: location.latitude,
      fromLongitude: location.longitude,
      toLatitude: widget.outlet.latitude,
      toLongitude: widget.outlet.longitude,
    );
  }

  bool get _isWithinRadius => _location != null && _distanceMeters <= _allowedRadiusMeters;

  @override
  void initState() {
    super.initState();
    _loadLocation();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _locationError = null;
    });

    try {
      _location = await _locationService.currentLocation();
    } on LocationFailure catch (error) {
      _locationError = error.message;
    } catch (_) {
      _locationError = 'Lokasi tidak dapat diambil. Coba lagi.';
    }

    if (mounted) setState(() => _isLoadingLocation = false);
  }

  Future<void> _capturePhoto() async {
    final photo = await _imageService.captureOutletPhoto();
    if (photo != null && mounted) setState(() => _photoPath = photo.path);
  }

  Future<void> _submit() async {
    if (_location == null) {
      SfaFeedbackDialog.show(type: SfaFeedbackType.warning, title: 'GPS diperlukan', message: _locationError ?? 'Ambil lokasi terlebih dahulu.');
      return;
    }
    if (!_isWithinRadius && _overrideReason == null) {
      await _requestOutOfRadiusOverride();
      if (_overrideReason == null) return;
    }
    if (_photoPath == null) {
      SfaFeedbackDialog.show(type: SfaFeedbackType.warning, title: 'Foto diperlukan', message: 'Ambil foto bukti kunjungan terlebih dahulu.');
      return;
    }

    final location = _location!;
    final isOverride = !_isWithinRadius;
    setState(() => _isSubmitting = true);

    try {
      const uuid = Uuid();
      final visit = VisitModel(
        id: 'VIS-${uuid.v4()}',
        outletName: widget.outlet.name,
        status: isOverride ? 'Pending' : 'In Progress',
        distanceKm: _distanceMeters / 1000,
        salesName: 'Sales',
        createdAt: DateTime.now(),
        outletId: widget.outlet.id,
      );

      await _localVisits.addVisit(visit);
      await Get.find<SyncManager>().queueItem(
        type: 'visit_check_in',
        endpoint: ApiEndpoints.checkIns,
        method: 'POST',
        uuid: uuid.v4(),
        idempotencyKey: uuid.v4(),
        payload: {
          'visitId': visit.id,
          'outletId': widget.outlet.id,
          'notes': _notesController.text.trim(),
          'photoPath': _photoPath,
          'attachmentIdempotencyKey': uuid.v4(),
          'location': location.toJson(),
          'distanceMeters': _distanceMeters,
          if (isOverride) 'outOfRadiusOverride': {'reason': _overrideReason, 'requestedAt': DateTime.now().toUtc().toIso8601String()},
        },
      );
      if (isOverride) {
        await Get.find<SyncManager>().queueItem(
          type: 'visit_out_of_radius_approval',
          endpoint: ApiEndpoints.visitApprovals,
          method: 'POST',
          uuid: uuid.v4(),
          idempotencyKey: uuid.v4(),
          payload: {'visitId': visit.id, 'outletId': widget.outlet.id, 'reason': _overrideReason, 'distanceMeters': _distanceMeters, 'location': location.toJson()},
        );
      }
      await VisitTimelineRepository().record(outletId: widget.outlet.id, visitId: visit.id, activity: 'check_in', description: isOverride ? 'Check-in di luar radius menunggu approval' : 'Check-in outlet', location: location.toJson());

      if (!mounted) return;
      Get.back(result: visit);
      await SfaFeedbackDialog.show(type: isOverride ? SfaFeedbackType.approval : SfaFeedbackType.success, title: isOverride ? 'Override diajukan' : 'Check-in berhasil', message: isOverride ? 'Check-in di luar radius menunggu approval.' : 'Kunjungan outlet dimulai dan akan disinkronkan saat online.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _requestOutOfRadiusOverride() async {
    final reason = TextEditingController();
    final submitted = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Check-in di luar radius'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Jarak Anda ${_distanceMeters.toStringAsFixed(0)} meter. Maksimum $_allowedRadiusMeters meter.', style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 12),
          TextField(controller: reason, maxLines: 3, maxLength: 200, decoration: const InputDecoration(labelText: 'Alasan override', hintText: 'Contoh: titik GPS outlet tidak akurat')),
        ]),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: const Text('Batal')),
          FilledButton(onPressed: () => Get.back(result: true), child: const Text('Ajukan Approval')),
        ],
      ),
    );
    if (submitted == true && reason.text.trim().isNotEmpty) {
      setState(() => _overrideReason = reason.text.trim());
    } else if (submitted == true) {
      SfaFeedbackDialog.show(type: SfaFeedbackType.warning, title: 'Alasan wajib', message: 'Tuliskan alasan untuk mengajukan override.');
    }
    reason.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Check-in Outlet', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _buildMap(),
            const SizedBox(height: 16),
            Text(widget.outlet.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 7),
            Text(widget.outlet.address, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 9),
            _buildLocationStatus(),
            const SizedBox(height: 22),
            const SfaSectionTitle(title: 'Foto Outlet', actionLabel: 'Wajib'),
            const SizedBox(height: 8),
            _buildPhotoCapture(),
            const SizedBox(height: 20),
            const Text('Catatan (Opsional)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 4,
              maxLength: 200,
              decoration: const InputDecoration(hintText: 'Tulis catatan...'),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(_isWithinRadius ? 'Check-in' : 'Ajukan Override Check-in'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMap() {
    final outletPoint = LatLng(widget.outlet.latitude, widget.outlet.longitude);
    final currentPoint = _location == null ? outletPoint : LatLng(_location!.latitude, _location!.longitude);
    return SizedBox(
      height: 188,
      child: Stack(
        children: [
          SfaOpenStreetMap(
            center: currentPoint,
            zoom: 16.5,
            markers: [
              SfaMapMarker(point: outletPoint, label: 'Outlet', color: AppColors.primary),
              SfaMapMarker(point: currentPoint, label: '', color: AppColors.success, isCurrentLocation: true),
            ],
          ),
          Positioned(
            top: 12,
            left: 12,
            child: SfaStatusChip(
              label: _isLoadingLocation ? 'Mengambil GPS' : _location == null ? 'GPS perlu diperbaiki' : 'GPS aktif',
              color: _location == null ? AppColors.danger : AppColors.success,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationStatus() {
    if (_isLoadingLocation) return const LinearProgressIndicator();
    if (_locationError != null) {
      return Row(children: [Expanded(child: Text(_locationError!, style: const TextStyle(fontSize: 12, color: AppColors.danger))), TextButton(onPressed: _loadLocation, child: const Text('Coba lagi'))]);
    }
    return Row(children: [const Icon(Icons.near_me_outlined, size: 16, color: AppColors.textSecondary), const SizedBox(width: 5), Text('Jarak Anda: ${_distanceMeters.toStringAsFixed(0)} meter', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)), const SizedBox(width: 8), SfaStatusChip(label: _isWithinRadius ? 'Akurat' : 'Di luar radius', color: _isWithinRadius ? AppColors.success : AppColors.danger)]);
  }

  Widget _buildPhotoCapture() {
    return InkWell(
      onTap: _capturePhoto,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 130,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
        child: _photoPath == null
            ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.camera_alt_outlined, color: AppColors.primary)), SizedBox(height: 8), Text('Ambil Foto', style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w700))]))
            : Image.file(File(_photoPath!), fit: BoxFit.cover, width: double.infinity),
      ),
    );
  }
}
