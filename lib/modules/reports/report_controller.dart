import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:salesgo/core/auth/app_roles.dart';

import '../../core/auth/session_service.dart';
import '../../core/network/network_info.dart';
import '../../core/network/api_config.dart';
import '../../core/network/api_endpoints.dart';
import '../../data/repositories/monitoring_repository.dart';

class ReportController extends GetxController {
  ReportController({
    MonitoringRepository? repository,
    NetworkInfo? networkInfo,
    SessionService? session,
  }) : _repository = repository ?? MonitoringRepository(),
       _networkInfo = networkInfo ?? Get.find<NetworkInfo>(),
       _session = session ?? Get.find<SessionService>();
  final MonitoringRepository _repository;
  final NetworkInfo _networkInfo;
  final SessionService _session;
  final selectedType = 'revenue'.obs;
  final report = Rx<Map<String, dynamic>>({});
  final isLoading = false.obs;
  bool get isAllowed =>
      _session.currentRole.value?.canViewBranchReports ?? false;
  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> changeType(String type) async {
    selectedType.value = type;
    await load();
  }

  Future<void> load() async {
    if (!isAllowed) return;
    isLoading.value = true;
    try {
      final summary = await _repository.getReport(
        type: selectedType.value,
        online: await _networkInfo.isConnected,
      );
      final byType = summary['byType'];
      final rows = <Map<String, dynamic>>[
        {'label': 'Omset committed', 'subtitle': 'Sales order committed / selesai', 'value': summary['committedRevenue'] ?? 0},
        {'label': 'Order committed', 'subtitle': 'Jumlah order committed / selesai', 'value': summary['committedOrderCount'] ?? 0},
        {'label': 'Seluruh transaksi', 'subtitle': 'Sesuai filter periode', 'value': summary['transactionCount'] ?? 0},
        if (byType is List) ...byType.whereType<Map>().map((item) => {'label': item['type']?.toString().replaceAll('_', ' ') ?? 'Transaksi', 'subtitle': '${item['count'] ?? 0} transaksi', 'value': item['amount'] ?? 0}),
      ];
      report.value = {...summary, 'rows': rows};
    } finally {
      isLoading.value = false;
    }
  }

  Future<String> downloadVisitCsv({required bool ownOnly}) async {
    if (!isAllowed) throw StateError('Akses laporan hanya untuk Supervisor dan Branch Manager.');
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}${Platform.pathSeparator}laporan-kunjungan-${ownOnly ? 'saya' : 'tim'}-${DateTime.now().millisecondsSinceEpoch}.csv');
    final response = await Dio().get<List<int>>(
      '$baseUrl${ApiEndpoints.reportsVisitsCsv}',
      queryParameters: {'scope': ownOnly ? 'self' : 'team'},
      options: Options(responseType: ResponseType.bytes, headers: {'Authorization': 'Bearer ${_session.accessToken.value}', 'Accept': 'text/csv', 'ngrok-skip-browser-warning': 'true'}),
    );
    final bytes = response.data ?? const <int>[];
    if (bytes.isEmpty) throw StateError('Server mengirim CSV kosong.');
    final content = utf8.decode(bytes, allowMalformed: true).replaceFirst('\uFEFF', '').trim();
    final rows = content.split(RegExp(r'\r?\n'));
    if (rows.length <= 1) {
      throw StateError(
        'Belum ada kunjungan tersimpan di server untuk cabang ini. '
        'Master rute bukan riwayat kunjungan; data laporan akan tersedia '
        'setelah sales memulai perjalanan atau melakukan kunjungan.',
      );
    }
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  Future<String?> openDownloadedFile(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      return 'File CSV tidak ditemukan lagi di perangkat. Unduh laporan kembali.';
    }

    final result = await OpenFilex.open(path, type: 'text/csv');
    if (result.type == ResultType.done) return null;

    return switch (result.type) {
      ResultType.noAppToOpen =>
        'Tidak ada aplikasi untuk membuka CSV. Pasang Google Sheets, Microsoft Excel, atau aplikasi spreadsheet lain.',
      ResultType.permissionDenied =>
        'Izin untuk membuka file ditolak oleh perangkat.',
      ResultType.fileNotFound =>
        'File CSV tidak ditemukan lagi di perangkat. Unduh laporan kembali.',
      _ => result.message.isEmpty
          ? 'CSV belum dapat dibuka. Coba lagi atau buka dari pengelola file.'
          : result.message,
    };
  }
}
