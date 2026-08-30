import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;

import '../network/api_client.dart';
import '../network/api_endpoints.dart';

class AttachmentUploadService {
  AttachmentUploadService({ApiClient? apiClient}) : _api = apiClient ?? Get.find<ApiClient>();
  final ApiClient _api;

  /// Replaces local file paths with server attachment IDs before an entity sync.
  Future<Map<String, dynamic>> preparePayload(Map<String, dynamic> payload) async {
    final prepared = Map<String, dynamic>.from(payload);
    final photoPath = prepared['photoPath']?.toString();
    if (photoPath != null && photoPath.isNotEmpty) {
      final photo = File(photoPath);
      if (!await photo.exists()) {
        throw StateError('Lampiran lokal tidak ditemukan: $photoPath');
      }
      final attachmentKey = prepared.remove('attachmentIdempotencyKey')?.toString();
      final attachmentId = await _upload(photo, attachmentKey);
      await _waitUntilFinalized(attachmentId);
      prepared
        ..remove('photoPath')
        ..['photoId'] = attachmentId;
    }
    return prepared;
  }

  Future<String> _upload(File file, String? idempotencyKey) async {
    final response = await _api.post<Map<String, dynamic>>(
      ApiEndpoints.attachments,
      data: FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: file.uri.pathSegments.last),
      }),
      idempotencyKey: idempotencyKey,
    );
    final id = response['id']?.toString() ?? response['fileId']?.toString();
    if (id == null || id.isEmpty) throw const FormatException('Server tidak mengembalikan ID lampiran.');
    return id;
  }

  /// Attachment diproses oleh worker Laravel. Check-in wajib luar radius
  /// hanya boleh mereferensikan attachment Finalized, sehingga polling singkat
  /// ini mencegah request visit terkirim terlalu cepat lalu gagal 422.
  Future<void> _waitUntilFinalized(String attachmentId) async {
    const retries = 8;
    for (var attempt = 0; attempt < retries; attempt++) {
      final attachment = await _api.get<Map<String, dynamic>>(
        '${ApiEndpoints.attachments}/$attachmentId',
      );
      final status = attachment['status']?.toString();
      if (status == 'Finalized') return;
      if (status == 'Failed') {
        throw StateError(
          'Foto gagal diproses server: ${attachment['error'] ?? 'tidak diketahui'}',
        );
      }
      await Future<void>.delayed(const Duration(seconds: 1));
    }
    throw StateError(
      'Foto masih diproses server. Override akan dicoba ulang otomatis.',
    );
  }
}
