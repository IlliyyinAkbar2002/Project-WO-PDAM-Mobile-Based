import 'package:dio/dio.dart';
import 'package:project_mobile_pdam/config/app_config.dart';
import '/core/utils/debug_log.dart';

enum ContentType { json, form, multipart }

class RemoteDatasource {
  late Dio dio;
  static final List<Function(Response response)> _onResponseSideEffects = [];
  static late final Function authTokenGetter;

  RemoteDatasource({String? domain, String baseEndPoint = '/api'}) {
    dio = Dio(
      BaseOptions(
        baseUrl: (domain ?? AppConfig.backendDomain) + baseEndPoint,
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 60),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          // Add X-Requested-With to indicate API request (not web browser)
          'X-Requested-With': 'XMLHttpRequest',
        },
      ),
    );
    _addDefaultInterceptors();
  }

  static void setAuthTokenGetter(Function getter) {
    authTokenGetter = getter;
  }

  static void addOnResponseSideEffect(
    Function(Response response) afterResponse,
  ) {
    _onResponseSideEffects.add(afterResponse);
  }

  Future<Response<T>> get<T>({
    String? path,
    Map<String, dynamic>? queryParameters,
    Object? data,
    ContentType? contentType,
  }) async {
    return dio.get<T>(
      path ?? '',
      queryParameters: queryParameters,
      options: Options(headers: headers(contentType: contentType)),
      data: data,
    );
  }

  Future<Response<T>> post<T>({
    String? path,
    Map<String, dynamic>? queryParameters,
    Object? data,
    ContentType? contentType,
  }) async {
    return dio.post<T>(
      path ?? '',
      queryParameters: queryParameters,
      options: Options(headers: headers(contentType: contentType)),
      data: data,
    );
  }

  Future<Response<T>> put<T>({
    String? path,
    Map<String, dynamic>? queryParameters,
    Object? data,
    ContentType? contentType,
  }) async {
    return dio.put<T>(
      path ?? '',
      queryParameters: queryParameters,
      options: Options(headers: headers(contentType: contentType)),
      data: data,
    );
  }

  Future<Response<T>> delete<T>({
    String? path,
    Map<String, dynamic>? queryParameters,
    Object? data,
    ContentType? contentType,
  }) async {
    return dio.delete<T>(
      path ?? '',
      queryParameters: queryParameters,
      options: Options(headers: headers(contentType: contentType)),
      data: data,
    );
  }

  Future<Response<T>> patch<T>({
    String? path,
    Map<String, dynamic>? queryParameters,
    Object? data,
    ContentType? contentType,
  }) async {
    return dio.patch<T>(
      path ?? '',
      queryParameters: queryParameters,
      options: Options(headers: headers(contentType: contentType)),
      data: data,
    );
  }

  Map<String, dynamic> headers({ContentType? contentType}) {
    try {
      final token = authTokenGetter();
      DebugLog.info(
        message:
            '🔑 Auth token for API request: ${token != null && token.isNotEmpty ? "EXISTS (${token.substring(0, 10)}...)" : "NULL/EMPTY"}',
      );
      return {
        'Content-Type': contentType == null || contentType == ContentType.json
            ? 'application/json'
            : contentType == ContentType.form
            ? 'application/x-www-form-urlencoded'
            : 'multipart/form-data',
        'Accept': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };
    } catch (e) {
      // If authTokenGetter not set, return headers without auth
      DebugLog.warning(message: '⚠️ Failed to get auth token: $e');
      return {
        'Content-Type': contentType == null || contentType == ContentType.json
            ? 'application/json'
            : contentType == ContentType.form
            ? 'application/x-www-form-urlencoded'
            : 'multipart/form-data',
        'Accept': 'application/json',
      };
    }
  }

  void _addDefaultInterceptors() {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          DebugLog.info(message: 'Request: ${options.method} ${options.uri}');
          handler.next(options);
        },
        onResponse: (response, handler) {
          DebugLog.info(message: 'Response: ${response.statusCode}');
          for (final sideEffect in _onResponseSideEffects) {
            sideEffect(response);
          }
          handler.next(response);
        },
        onError: (DioException e, handler) {
          DebugLog.error(
            message: 'Error: ${e.message}, response: ${e.response?.data}',
            stackTrace: e.stackTrace,
          );
          handler.next(e);
        },
      ),
    );
  }

  void addInterceptor(Interceptor interceptor) {
    dio.interceptors.add(interceptor);
  }
}
