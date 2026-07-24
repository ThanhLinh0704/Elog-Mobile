import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/secure_storage_service.dart';

class AuthService {
  final Dio _dio;
  final SecureStorageService _storage;

  const AuthService(this._dio, this._storage);

  /// POST /api/auth/login
  /// Returns roles list on success, throws ApiBusinessException on failure.
  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/api/auth/login',
        data: {'username': username, 'password': password},
      );
      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>;

      final accessToken = data['accessToken'] as String? ?? '';
      final refreshToken = data['refreshToken'] as String? ?? '';
      final roles = (data['roles'] as List<dynamic>?)
              ?.map((r) => r.toString())
              .toList() ??
          [];
      final userId = data['userId']?.toString() ?? '';
      final uname = data['username'] as String? ?? username;
      final fullName = uname; // no fullName in TokenResponse; use username

      await _storage.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
        username: uname,
        roles: roles.join(','),
        userId: userId,
        fullName: fullName,
      );

      return {
        'roles': roles,
        'username': uname,
        'userId': userId,
        'accessToken': accessToken,
      };
    } on DioException catch (e) {
      throw parseDioError(e);
    }
  }

  /// POST /api/auth/logout
  Future<void> logout() async {
    try {
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await _dio
            .post('/api/auth/logout', data: {'refreshToken': refreshToken});
      }
    } catch (_) {
      // Always clear local storage even if API call fails
    } finally {
      await _storage.clearAll();
    }
  }
}
