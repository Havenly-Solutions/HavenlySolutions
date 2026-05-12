import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../models/api_exception.dart';
import '../core/security/secure_storage_service.dart';

class ApiService {
  final Dio _dio;
  static final ApiService _instance = ApiService._internal();

  factory ApiService() => _instance;

  ApiService._internal()
      : _dio = Dio(BaseOptions(
          baseUrl: AppConfig.baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 30),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        )) {
    _dio.interceptors.add(QueuedInterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await SecureStorageService.getAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401 &&
            error.requestOptions.path != '/auth/refresh' &&
            error.requestOptions.path != '/auth/login') {
          
          final refreshToken = await SecureStorageService.getRefreshToken();
          if (refreshToken != null) {
            try {
              final response = await _dio.post('/auth/refresh', data: {
                'refresh_token': refreshToken,
              });

              final newToken = response.data['access_token'];
              final newRefreshToken = response.data['refresh_token'];

              await SecureStorageService.saveTokens(
                accessToken: newToken,
                refreshToken: newRefreshToken,
              );

              // Retry original request
              final options = error.requestOptions;
              options.headers['Authorization'] = 'Bearer $newToken';
              final retryResponse = await _dio.fetch(options);
              return handler.resolve(retryResponse);
            } catch (e) {
              // Refresh failed, logout needed. 
              // TODO: Wire UserProvider.logout() here or trigger global event
              await SecureStorageService.clearTokens();
              return handler.next(error);
            }
          }
        }
        
        final apiException = _handleError(error);
        return handler.next(DioException(
          requestOptions: error.requestOptions,
          error: apiException,
          response: error.response,
          type: error.type,
        ));
      },
    ));
  }

  ApiException _handleError(DioException error) {
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout) {
      return ApiException.network();
    }
    if (error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return ApiException.timeout();
    }
    if (error.response != null) {
      final statusCode = error.response!.statusCode ?? 500;
      final message = error.response!.data?['message'] ?? 'An unknown error occurred';
      final errorCode = error.response!.data?['errorCode'];
      
      if (statusCode == 401) {
        return ApiException.unauthorized();
      }
      return ApiException(
        statusCode: statusCode,
        message: message,
        errorCode: errorCode,
      );
    }
    return ApiException.serverError(error.message ?? 'Unknown error');
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      return response.data;
    } on DioException catch (e) {
      throw e.error is ApiException ? e.error as ApiException : _handleError(e);
    }
  }

  Future<dynamic> post(String path, {dynamic data}) async {
    try {
      final response = await _dio.post(path, data: data);
      return response.data;
    } on DioException catch (e) {
      throw e.error is ApiException ? e.error as ApiException : _handleError(e);
    }
  }

  Future<dynamic> put(String path, {dynamic data}) async {
    try {
      final response = await _dio.put(path, data: data);
      return response.data;
    } on DioException catch (e) {
      throw e.error is ApiException ? e.error as ApiException : _handleError(e);
    }
  }

  Future<dynamic> patch(String path, {dynamic data}) async {
    try {
      final response = await _dio.patch(path, data: data);
      return response.data;
    } on DioException catch (e) {
      throw e.error is ApiException ? e.error as ApiException : _handleError(e);
    }
  }

  Future<dynamic> delete(String path, {dynamic data}) async {
    try {
      final response = await _dio.delete(path, data: data);
      return response.data;
    } on DioException catch (e) {
      throw e.error is ApiException ? e.error as ApiException : _handleError(e);
    }
  }
}
