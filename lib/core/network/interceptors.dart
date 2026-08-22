import 'package:dio/dio.dart';

import '../../core/auth/session_service.dart';
import 'api_exception.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor({required this.sessionService});

  final SessionService sessionService;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = sessionService.accessToken.value;
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    if (options.data is! FormData) {
      options.headers['Content-Type'] = 'application/json';
    }
    options.headers['Accept'] = 'application/json';
    // ngrok free menampilkan halaman interstitial untuk client tanpa browser.
    // Header ini hanya relevan saat API development menggunakan domain ngrok.
    if (options.uri.host.endsWith('ngrok-free.dev') || options.uri.host.endsWith('ngrok.io')) {
      options.headers['ngrok-skip-browser-warning'] = 'true';
    }

    return handler.next(options);
  }
}

class ErrorInterceptor extends Interceptor {
  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.type == DioExceptionType.connectionTimeout) {
      return handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          error: TimeoutException(message: 'Connection timeout'),
        ),
      );
    }

    if (err.type == DioExceptionType.receiveTimeout) {
      return handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          error: TimeoutException(message: 'Receive timeout'),
        ),
      );
    }

    if (err.type == DioExceptionType.unknown) {
      return handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          error: NetworkException(message: 'Network error: ${err.message}'),
        ),
      );
    }

    if (err.response != null) {
      final statusCode = err.response?.statusCode ?? 0;
      final message = _getErrorMessage(statusCode, err.response?.data);

      return handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          error: ApiException(
            message: message,
            statusCode: statusCode,
            response: err.response?.data,
            requestOptions: err.requestOptions,
          ),
        ),
      );
    }

    return handler.next(err);
  }

  String _getErrorMessage(int statusCode, dynamic data) {
    switch (statusCode) {
      case 400:
        return 'Bad request: ${_extractMessage(data)}';
      case 401:
        return 'Unauthorized: Session expired';
      case 403:
        return 'Forbidden: Access denied';
      case 404:
        return 'Not found: Resource not available';
      case 409:
        return 'Conflict: ${_extractMessage(data)}';
      case 500:
        return 'Server error: Please try again later';
      case 503:
        return 'Service unavailable';
      default:
        return 'Error $statusCode: ${_extractMessage(data)}';
    }
  }

  String _extractMessage(dynamic data) {
    if (data is Map) {
      return data['message'] as String? ?? data['error'] as String? ?? '';
    }
    return '';
  }
}

class IdempotencyInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Add Idempotency-Key for POST, PUT, PATCH requests
    if (['POST', 'PUT', 'PATCH', 'DELETE'].contains(options.method)) {
      if (!options.headers.containsKey('Idempotency-Key')) {
        // Idempotency key should be set by the caller, but add empty placeholder if missing
        options.headers['Idempotency-Key'] = '';
      }
    }

    return handler.next(options);
  }
}
