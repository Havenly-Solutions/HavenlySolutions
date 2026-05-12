class ApiException implements Exception {
  final int statusCode;
  final String message;
  final String? errorCode;

  ApiException({
    required this.statusCode,
    required this.message,
    this.errorCode,
  });

  ApiException.network()
      : statusCode = 0,
        message = 'Network connection error. Please check your internet.',
        errorCode = 'NETWORK_ERROR';

  ApiException.timeout()
      : statusCode = 0,
        message = 'Request timed out. Please try again.',
        errorCode = 'TIMEOUT_ERROR';

  ApiException.unauthorized()
      : statusCode = 401,
        message = 'Session expired. Please login again.',
        errorCode = 'UNAUTHORIZED';

  ApiException.serverError(String msg)
      : statusCode = 500,
        message = msg,
        errorCode = 'SERVER_ERROR';

  @override
  String toString() => 'ApiException: [$statusCode] $message${errorCode != null ? ' ($errorCode)' : ''}';
}
