import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../auth/session_service.dart';
import 'api_config.dart';
import 'api_exception.dart';
import 'interceptors.dart';

class ApiClient {
  ApiClient({
    Dio? dio,
    SessionService? sessionService,
  })  : _dio = dio ?? Dio(),
        _sessionService = sessionService ?? Get.find<SessionService>() {
    _setupClient();
  }

  final Dio _dio;
  final SessionService _sessionService;

  void _setupClient() {
    _dio
      ..options.baseUrl = baseUrl
      ..options.connectTimeout = Duration(milliseconds: int.parse(apiTimeout))
      ..options.receiveTimeout = Duration(milliseconds: int.parse(apiTimeout))
      ..options.sendTimeout = Duration(milliseconds: int.parse(apiTimeout));

    // Add interceptors
    _dio.interceptors.addAll([
      AuthInterceptor(sessionService: _sessionService),
      IdempotencyInterceptor(),
      ErrorInterceptor(),
    ]);
  }

  /// GET request
  Future<T> get<T>(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.get<T>(
        endpoint,
        queryParameters: queryParameters,
        options: options,
      );
      return response.data as T;
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// POST request
  Future<T> post<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    String? idempotencyKey,
  }) async {
    try {
      final opts = options ?? Options();
      if (idempotencyKey != null) {
        opts.headers ??= {};
        opts.headers!['Idempotency-Key'] = idempotencyKey;
      }

      final response = await _dio.post<T>(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: opts,
      );
      return response.data as T;
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// PUT request
  Future<T> put<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    String? idempotencyKey,
  }) async {
    try {
      final opts = options ?? Options();
      if (idempotencyKey != null) {
        opts.headers ??= {};
        opts.headers!['Idempotency-Key'] = idempotencyKey;
      }

      final response = await _dio.put<T>(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: opts,
      );
      return response.data as T;
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// PATCH request
  Future<T> patch<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    String? idempotencyKey,
  }) async {
    try {
      final opts = options ?? Options();
      if (idempotencyKey != null) {
        opts.headers ??= {};
        opts.headers!['Idempotency-Key'] = idempotencyKey;
      }

      final response = await _dio.patch<T>(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: opts,
      );
      return response.data as T;
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// DELETE request
  Future<T> delete<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    String? idempotencyKey,
  }) async {
    try {
      final opts = options ?? Options();
      if (idempotencyKey != null) {
        opts.headers ??= {};
        opts.headers!['Idempotency-Key'] = idempotencyKey;
      }
      final response = await _dio.delete<T>(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: opts,
      );
      return response.data as T;
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  void _handleError(DioException e) {
    if (e.error is ApiException) {
      throw e.error as ApiException;
    }
    if (e.error is NetworkException) {
      throw e.error as NetworkException;
    }
    if (e.error is TimeoutException) {
      throw e.error as TimeoutException;
    }
  }
}
