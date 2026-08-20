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
}
