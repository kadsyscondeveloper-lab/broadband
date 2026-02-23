import 'package:dio/dio.dart';
import 'app_config.dart';
import 'storage_service.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal() {
    _init();
  }

  late final Dio _dio;
  final _storage = StorageService();

  Dio get dio => _dio;

  // ← ADD THIS — exposes the current access token for WebView auth header
  String? get token => _storage.accessToken;

  void _init() {
    _dio = Dio(BaseOptions(
      baseUrl:        AppConfig.baseUrl,
      connectTimeout: AppConfig.connectTimeout,
      receiveTimeout: AppConfig.receiveTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept':        'application/json',
      },
    ));

    _dio.interceptors.add(_AuthInterceptor(_storage));

    _dio.interceptors.add(LogInterceptor(
      requestBody:  true,
      responseBody: true,
      error:        true,
      logPrint:     (obj) => print('[API] $obj'),
    ));

    _dio.interceptors.add(_RefreshInterceptor(_dio, _storage));
  }

  Future<Response> get(String path, {Map<String, dynamic>? params}) =>
      _dio.get(path, queryParameters: params);

  Future<Response> post(String path, {dynamic data}) =>
      _dio.post(path, data: data);

  Future<Response> put(String path, {dynamic data}) =>
      _dio.put(path, data: data);

  Future<Response> patch(String path, {dynamic data}) =>
      _dio.patch(path, data: data);

  Future<Response> delete(String path) => _dio.delete(path);
}

class _AuthInterceptor extends Interceptor {
  final StorageService _storage;
  _AuthInterceptor(this._storage);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _storage.accessToken;
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}

class _RefreshInterceptor extends Interceptor {
  final Dio          _dio;
  final StorageService _storage;
  bool _isRefreshing = false;

  _RefreshInterceptor(this._dio, this._storage);

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 && !_isRefreshing) {
      final refreshToken = _storage.refreshToken;
      if (refreshToken == null) {
        handler.next(err);
        return;
      }

      _isRefreshing = true;
      try {
        final response = await _dio.post(
          '/auth/refresh',
          data: {'refresh_token': refreshToken},
        );
        final tokens = response.data['data']['tokens'];
        await _storage.saveTokens(
          accessToken:  tokens['access_token'],
          refreshToken: tokens['refresh_token'],
        );
        final opts = err.requestOptions;
        opts.headers['Authorization'] = 'Bearer ${tokens['access_token']}';
        final retried = await _dio.fetch(opts);
        handler.resolve(retried);
      } catch (_) {
        await _storage.clearAll();
        handler.next(err);
      } finally {
        _isRefreshing = false;
      }
      return;
    }

    handler.next(err);
  }
}

class ApiException implements Exception {
  final String message;
  final int?   statusCode;
  final List<Map<String, dynamic>>? errors;

  const ApiException({
    required this.message,
    this.statusCode,
    this.errors,
  });

  factory ApiException.fromDio(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      return ApiException(
        message:    data['message'] ?? 'Something went wrong',
        statusCode: e.response?.statusCode,
        errors:     (data['errors'] as List?)
            ?.map((e) => Map<String, dynamic>.from(e))
            .toList(),
      );
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return const ApiException(
          message: 'Connection timed out. Please check your internet.');
    }
    if (e.type == DioExceptionType.connectionError) {
      return const ApiException(
          message: 'Cannot reach server. Check your network or server IP.');
    }
    return ApiException(
        message: e.message ?? 'Unknown error', statusCode: e.response?.statusCode);
  }

  @override
  String toString() => 'ApiException($statusCode): $message';
}