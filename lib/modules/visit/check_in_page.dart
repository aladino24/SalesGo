import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';

import '../../app/theme/app_colors.dart';
import '../../app/routes/app_routes.dart';
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
import '../../data/repositories/visit_repository.dart';
import '../../data/repositories/visit_timeline_repository.dart';
import 'visit_controller.dart';
import '../home/home_controller.dart';

class CheckInPage extends StatefulWidget {
  const CheckInPage({
    super.key,
    required this.outlet,
    this.plannedVisitId,
    this.isRequired = true,
  });

  final OutletModel outlet;
  final String? plannedVisitId;
  final bool isRequired;

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
  bool get _requiresOverrideApproval => widget.isRequired && !_isWithinRadius;

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
    // Keputusan BM dapat diterima ketika notifikasi belum dibuka. Periksa
    // snapshot server sebelum menampilkan alur override baru agar visit yang
    // sudah Approved langsung kembali menjadi kunjungan aktif.
    final approvedVisit = await _approvedVisitFromServer();
    if (approvedVisit != null) {
      await _localVisits.addVisit(approvedVisit);
      if (Get.isRegistered<VisitController>()) {
        Get.find<VisitController>().setActiveVisit(approvedVisit);
      }
      if (!mounted) return;
      await SfaFeedbackDialog.show(
        type: SfaFeedbackType.success,
        title: 'Check-in telah disetujui',
        message: 'Anda sudah dapat melanjutkan aktivitas di ${widget.outlet.name}.',
      );
      await _openActiveVisit(approvedVisit);
      return;
    }
    if (_requiresOverrideApproval) {
      final continueOutside = await _confirmRequiredOutOfRadius();
      if (!continueOutside) return;
      if (_overrideReason == null) {
        await _requestOutOfRadiusOverride();
        if (_overrideReason == null) return;
      }
    }
    if (_requiresOverrideApproval && _photoPath == null) {
      SfaFeedbackDialog.show(type: SfaFeedbackType.warning, title: 'Foto diperlukan', message: 'Ambil foto bukti untuk pengajuan check-in luar radius.');
      return;
    }
    final confirmed = await _confirmCheckIn(isOverride: _requiresOverrideApproval);
    if (!confirmed) return;

    final location = _location!;
    final isOverride = _requiresOverrideApproval;
    setState(() => _isSubmitting = true);

    try {
      const uuid = Uuid();
      final visit = VisitModel(
        id: widget.plannedVisitId ?? 'VIS-${uuid.v4()}',
        outletName: widget.outlet.name,
        status: isOverride ? 'Pending' : 'In Progress',
        distanceKm: _distanceMeters / 1000,
        salesName: 'Sales',
        createdAt: DateTime.now(),
        outletId: widget.outlet.id,
        isRequired: widget.isRequired,
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
          if (_photoPath != null) 'photoPath': _photoPath,
          if (_photoPath != null) 'attachmentIdempotencyKey': uuid.v4(),
          'location': location.toJson(),
          'distanceMeters': _distanceMeters,
          'isRequired': widget.isRequired,
          if (isOverride) 'outOfRadiusOverride': {'reason': _overrideReason, 'requestedAt': DateTime.now().toUtc().toIso8601String()},
        },
      );
      // Backend membuat Approval secara atomik setelah check-in (beserta
      // pemeriksaan radius). Jangan antrekan endpoint approval terpisah,
      // karena keputusan harus selalu terkait visit yang sudah tersimpan.
      await VisitTimelineRepository().record(outletId: widget.outlet.id, visitId: visit.id, activity: 'check_in', description: isOverride ? 'Check-in wajib di luar radius menunggu approval' : (!_isWithinRadius ? 'Check-in kunjungan tidak wajib di luar radius' : 'Check-in outlet'), location: location.toJson());

      if (!mounted) return;
      await SfaFeedbackDialog.show(type: isOverride ? SfaFeedbackType.approval : SfaFeedbackType.success, title: isOverride ? 'Override diajukan' : 'Check-in berhasil', message: isOverride ? 'Pengajuan disimpan dan sedang dikirim. Setelah diterima server, pengajuan menunggu approval Branch Manager.' : (!_isWithinRadius ? 'Kunjungan tidak wajib di luar radius berhasil dimulai.' : 'Kunjungan outlet dimulai dan akan disinkronkan saat online.'));
      await _openActiveVisit(visit);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  /// Check-in dapat dibuka dari beberapa lapisan halaman/dialog GetX. Jangan
  /// meneruskan VisitModel melalui `Get.back`, karena route pemanggil lama
  /// kadang bertipe `bool` dan menghasilkan TypeError. State visit disimpan
  /// dahulu, lalu aplikasi menuju tab Kunjungan yang otomatis terkunci pada
  /// detail outlet aktif.
  Future<void> _openActiveVisit(VisitModel visit) async {
    if (Get.isRegistered<VisitController>()) {
      Get.find<VisitController>().setActiveVisit(visit);
    }
    if (!mounted) return;
    await Get.offAllNamed(AppRoutes.home);
    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (Get.isRegistered<HomeController>()) {
      Get.find<HomeController>().changeTab(1);
    }
  }

  Future<VisitModel?> _approvedVisitFromServer() async {
    try {
      final items = await VisitRepository().getVisits(isOnline: true);
      for (final item in items) {
        final samePlannedVisit = widget.plannedVisitId != null &&
            item.id == widget.plannedVisitId;
        final sameOutlet = item.outletId == widget.outlet.id;
        if ((samePlannedVisit || sameOutlet) && item.status == 'In Progress') {
          return item;
        }
      }
    } catch (_) {
      // Offline tetap menggunakan proses check-in dan antrean lokal normal.
    }
    return null;
  }

  Future<void> _requestOutOfRadiusOverride() async {
    final reason = TextEditingController();
    final submitted = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Check-in di luar radius'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Jarak Anda ${_distanceMeters.toStringAsFixed(0)} meter. Maksimum $_allowedRadiusMeters meter.', style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 12),
            TextField(controller: reason, maxLines: 3, maxLength: 200, decoration: const InputDecoration(labelText: 'Alasan override', hintText: 'Contoh: titik GPS outlet tidak akurat')),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: const Text('Batal')),
          FilledButton(onPressed: () => Get.back(result: true), child: const Text('Ajukan Approval')),
        ],
      ),
    );
    // Get.dialog menyelesaikan Future sebelum route dialog selesai dibuang.
    // Salin teks lebih dahulu agar TextField tidak membaca controller yang
    // telah dispose selama animasi penutupan.
    final reasonText = reason.text.trim();
    if (submitted == true && reasonText.isNotEmpty) {
      if (mounted) setState(() => _overrideReason = reasonText);
    } else if (submitted == true) {
      SfaFeedbackDialog.show(type: SfaFeedbackType.warning, title: 'Alasan wajib', message: 'Tuliskan alasan untuk mengajukan override.');
    }
    Future<void>.delayed(const Duration(milliseconds: 350)).then((_) {
      reason.dispose();
    });
  }

  Future<bool> _confirmRequiredOutOfRadius() async {
    return await Get.dialog<bool>(
          AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            icon: const CircleAvatar(radius: 26, backgroundColor: Color(0xFFFFF3E0), child: Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 30)),
            title: const Text('Di luar radius kunjungan'),
            content: Text('Jarak Anda ${_distanceMeters.toStringAsFixed(0)} meter, sedangkan radius outlet ${_allowedRadiusMeters.toStringAsFixed(0)} meter. Kunjungan wajib memerlukan approval Branch Manager.'),
            actions: [
              TextButton(onPressed: () => Get.back(result: false), child: const Text('Kembali')),
              FilledButton.icon(onPressed: () => Get.back(result: true), icon: const Icon(Icons.arrow_forward_rounded), label: const Text('Tetap lanjutkan')),
            ],
          ),
        ) ??
        false;
  }

  Future<bool> _confirmCheckIn({required bool isOverride}) async {
    final outside = !_isWithinRadius;
    return await Get.dialog<bool>(
          AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            icon: CircleAvatar(radius: 26, backgroundColor: isOverride ? const Color(0xFFFFF3E0) : AppColors.primarySoft, child: Icon(isOverride ? Icons.assignment_turned_in_rounded : Icons.login_rounded, color: isOverride ? AppColors.warning : AppColors.primary, size: 30)),
            title: Text(isOverride ? 'Ajukan check-in luar radius?' : 'Konfirmasi check-in'),
            content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.outlet.name, style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 7),
              Text(outside ? 'Lokasi Anda di luar radius (${_distanceMeters.toStringAsFixed(0)} meter).' : 'Lokasi Anda berada dalam radius outlet.'),
              const SizedBox(height: 10),
              Text(isOverride ? 'Pengajuan akan dikirim ke Branch Manager untuk approval.' : 'Setelah check-in, transaksi outlet dapat dilakukan.', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ]),
            actions: [
              TextButton(onPressed: () => Get.back(result: false), child: const Text('Batal')),
              FilledButton(onPressed: () => Get.back(result: true), child: Text(isOverride ? 'Ajukan' : 'Check-in')),
            ],
          ),
        ) ??
        false;
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
            if (widget.isRequired && !_isLoadingLocation && _requiresOverrideApproval) ...[
              const SfaSectionTitle(title: 'Foto Outlet', actionLabel: 'Wajib untuk override'),
              const SizedBox(height: 8),
              _buildPhotoCapture(),
              const SizedBox(height: 20),
            ],
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
                  : Text(_requiresOverrideApproval ? 'Ajukan Override Check-in' : 'Check-in'),
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
