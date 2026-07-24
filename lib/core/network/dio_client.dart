import 'package:dio/dio.dart';
import '../constants.dart';
import '../error/exceptions.dart';
import '../storage/secure_storage_service.dart';

/// Dio client with Bearer token interceptor and error parsing.
Dio createDioClient(SecureStorageService storage) {
  final dio = Dio(BaseOptions(
    baseUrl: kBaseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  ));

  // ── Auth interceptor — attach Bearer token ──────────────────────────────
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final token = await storage.getAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    },
    onError: (error, handler) async {
      if (error.response?.statusCode == 401) {
        await storage.clearAll();
      }
      handler.next(error);
    },
  ));

  return dio;
}

/// Parse a Dio error into [ApiBusinessException] or [NetworkException].
Exception parseDioError(DioException e) {
  if (e.type == DioExceptionType.connectionError ||
      e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.receiveTimeout) {
    return const NetworkException(
        'Không thể kết nối đến máy chủ. Kiểm tra kết nối mạng và thử lại.');
  }

  final response = e.response;
  if (response == null) {
    return NetworkException('Lỗi mạng: ${e.message ?? 'Không xác định'}');
  }

  final body = response.data;
  if (body is Map<String, dynamic>) {
    final error = body['error'];
    if (error is Map<String, dynamic>) {
      return ApiBusinessException(
        statusCode: response.statusCode,
        code: error['code']?.toString(),
        message: error['message']?.toString() ?? 'Đã xảy ra lỗi.',
      );
    }
    // Fallback: top-level message
    final msg = body['message']?.toString() ?? 'Đã xảy ra lỗi.';
    return ApiBusinessException(
      statusCode: response.statusCode,
      message: msg,
    );
  }

  return ApiBusinessException(
    statusCode: response.statusCode,
    message: 'Đã xảy ra lỗi (${response.statusCode}).',
  );
}
