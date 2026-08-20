import 'dart:io';

import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../models/important_file_model.dart';
import '../models/promotion_model.dart';

class InformationRepository {
  static const cacheQuotaBytes = 100 * 1024 * 1024;
  InformationRepository({ApiClient? apiClient}) : _api = apiClient ?? Get.find<ApiClient>();

  final ApiClient _api;

  Future<List<PromotionModel>> getPromotions({required bool online}) async {
    final box = await _box('promotions');
    if (online) {
      try {
        final response = await _api.get<List<dynamic>>(ApiEndpoints.promotions);
        final records = response
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
        await _replace(box, records);
      } catch (_) {
        // Cache remains usable when the API cannot be reached.
      }
    }
    return box.values
        .whereType<Map>()
        .map((item) => PromotionModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<List<ImportantFileModel>> getFiles({required bool online}) async {
    final box = await _box('files');
    if (online) {
      try {
        final response = await _api.get<List<dynamic>>(ApiEndpoints.files);
        final existingCache = <String, Map<String, dynamic>>{
          for (final value in box.values.whereType<Map>())
            if (value['id'] != null) value['id'].toString(): Map<String, dynamic>.from(value),
        };
        final records = response.whereType<Map>().map((item) {
          final record = Map<String, dynamic>.from(item);
          final cached = existingCache[record['id']?.toString()];
          if (cached != null && cached['version'] == record['version']) {
            record['cachePath'] = cached['cachePath'];
            record['cachedAt'] = cached['cachedAt'];
          }
          return record;
        }).toList();
        await _replace(box, records);
      } catch (_) {
        // Cache remains usable when the API cannot be reached.
      }
    }
    final results = <ImportantFileModel>[];
    for (final value in box.values.whereType<Map>()) {
      final file = ImportantFileModel.fromJson(Map<String, dynamic>.from(value));
      if (file.isCached && !await File(file.cachePath!).exists()) {
        await box.put(file.id, file.copyWith(cachePath: '').toJson());
        results.add(file.copyWith(cachePath: ''));
      } else {
        results.add(file);
      }
    }
    return results;
  }

  Future<ImportantFileModel> download(ImportantFileModel file) async {
    final response = await _api.post<Map<String, dynamic>>(
      '${ApiEndpoints.files}/${file.id}/download',
    );
    final url = response['downloadUrl']?.toString() ?? response['url']?.toString();
    if (url == null || url.isEmpty) {
      throw const FormatException('Server tidak mengirim URL unduhan.');
    }

    final baseDirectory = await getApplicationDocumentsDirectory();
    final cacheDirectory = Directory('${baseDirectory.path}${Platform.pathSeparator}offline_files');
    if (!await cacheDirectory.exists()) await cacheDirectory.create(recursive: true);
    final usage = await cacheUsage();
    final existingSize = file.isCached && await File(file.cachePath!).exists() ? await File(file.cachePath!).length() : 0;
    final requiredBytes = file.size > existingSize ? file.size - existingSize : 0;
    if (usage.usedBytes + requiredBytes > usage.quotaBytes) {
      throw CacheQuotaExceededException(usedBytes: usage.usedBytes, requiredBytes: requiredBytes, quotaBytes: usage.quotaBytes);
    }
    final extension = _safeExtension(file.name);
    final path = '${cacheDirectory.path}${Platform.pathSeparator}${file.id}$extension';
    await Dio().download(url, path, deleteOnError: true);

    final cached = file.copyWith(cachePath: path, cachedAt: DateTime.now());
    final box = await _box('files');
    await box.put(cached.id, cached.toJson());
    return cached;
  }

  Future<FileCacheUsage> cacheUsage() async {
    final baseDirectory = await getApplicationDocumentsDirectory();
    final directory = Directory('${baseDirectory.path}${Platform.pathSeparator}offline_files');
    if (!await directory.exists()) return const FileCacheUsage(usedBytes: 0, quotaBytes: cacheQuotaBytes);
    var used = 0;
    await for (final entity in directory.list(recursive: true, followLinks: false)) {
      if (entity is File) used += await entity.length();
    }
    return FileCacheUsage(usedBytes: used, quotaBytes: cacheQuotaBytes);
  }

  Future<void> removeCache(ImportantFileModel file) async {
    if (file.isCached) {
      final local = File(file.cachePath!);
      if (await local.exists()) await local.delete();
    }
    final box = await _box('files');
    await box.put(file.id, file.copyWith(cachePath: '').toJson());
  }

  Future<void> openCachedFile(ImportantFileModel file) async {
    if (!file.isCached || !await File(file.cachePath!).exists()) {
      throw StateError('File belum tersedia di perangkat. Unduh terlebih dahulu.');
    }
    final result = await OpenFilex.open(file.cachePath!);
    if (result.type != ResultType.done) {
      throw StateError(result.message.isEmpty ? 'Tidak ada aplikasi untuk membuka file ini.' : result.message);
    }
  }

  Future<Box> _box(String name) => Hive.isBoxOpen(name) ? Future.value(Hive.box(name)) : Hive.openBox(name);

  Future<void> _replace(Box box, List<Map<String, dynamic>> records) async {
    await box.clear();
    await box.putAll({for (var i = 0; i < records.length; i++) records[i]['id']?.toString() ?? '${box.name}-$i': records[i]});
  }

  String _safeExtension(String name) {
    final dot = name.lastIndexOf('.');
    if (dot < 0 || dot == name.length - 1) return '';
    return name.substring(dot).replaceAll(RegExp(r'[^a-zA-Z0-9.]'), '');
  }
}

class FileCacheUsage {
  const FileCacheUsage({required this.usedBytes, required this.quotaBytes});
  final int usedBytes;
  final int quotaBytes;
  double get ratio => quotaBytes == 0 ? 0 : usedBytes / quotaBytes;
}

class CacheQuotaExceededException implements Exception {
  const CacheQuotaExceededException({required this.usedBytes, required this.requiredBytes, required this.quotaBytes});
  final int usedBytes;
  final int requiredBytes;
  final int quotaBytes;
}
