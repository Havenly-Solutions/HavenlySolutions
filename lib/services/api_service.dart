import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../models/api_exception.dart';
import '../core/security/secure_storage_service.dart';
import 'offline_queue_service.dart';

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
        if (error.type == DioExceptionType.connectionError ||
            error.type == DioExceptionType.connectionTimeout) {
          
          final path = error.requestOptions.path;
          final method = error.requestOptions.method;
          final data = error.requestOptions.data;

          // Only enqueue mutations
          if (method != 'GET' && path != '/api/sos/trigger') {
            await OfflineQueueService().enqueue(path, method, data);
          }
          
          final apiException = ApiException.network();
          return handler.next(DioException(
            requestOptions: error.requestOptions,
            error: apiException,
            type: error.type,
          ));
        }

        if (error.response?.statusCode == 401 &&
            error.requestOptions.path != '/api/auth/refresh' &&
            error.requestOptions.path != '/api/auth/login') {
          
          final refreshToken = await SecureStorageService.getRefreshToken();
          if (refreshToken != null) {
            try {
              final response = await _dio.post('/api/auth/refresh', data: {
                'refreshToken': refreshToken,
              });

              final newToken =
                  response.data['accessToken'] ?? response.data['access_token'];
              final newRefreshToken =
                  response.data['refreshToken'] ?? response.data['refresh_token'];

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
