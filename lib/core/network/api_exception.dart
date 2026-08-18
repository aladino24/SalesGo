class ApiException implements Exception {
  ApiException({
    required this.message,
    this.statusCode,
    this.response,
    this.requestOptions,
  });

  final String message;
  final int? statusCode;
  final dynamic response;
  final dynamic requestOptions;

  @override
  String toString() => 'ApiException: $message (HTTP $statusCode)';
}

class NetworkException implements Exception {
  NetworkException({required this.message});
  final String message;

  @override
  String toString() => 'NetworkException: $message';
}

class TimeoutException implements Exception {
  TimeoutException({required this.message});
  final String message;

  @override
  String toString() => 'TimeoutException: $message';
}
