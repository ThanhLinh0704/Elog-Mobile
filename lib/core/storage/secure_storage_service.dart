import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required String username,
    required String roles,
    required String userId,
    required String fullName,
  }) async {
    await Future.wait([
      _storage.write(key: kAccessTokenKey, value: accessToken),
      _storage.write(key: kRefreshTokenKey, value: refreshToken),
      _storage.write(key: kUsernameKey, value: username),
      _storage.write(key: kRolesKey, value: roles),
      _storage.write(key: kUserIdKey, value: userId),
      _storage.write(key: kFullNameKey, value: fullName),
    ]);
  }

  Future<String?> getAccessToken() => _storage.read(key: kAccessTokenKey);
  Future<String?> getRefreshToken() => _storage.read(key: kRefreshTokenKey);
  Future<String?> getUsername() => _storage.read(key: kUsernameKey);
  Future<String?> getRoles() => _storage.read(key: kRolesKey);
  Future<String?> getUserId() => _storage.read(key: kUserIdKey);
  Future<String?> getFullName() => _storage.read(key: kFullNameKey);

  Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  Future<bool> isDriver() async {
    final roles = await getRoles();
    return roles != null && roles.contains('DRIVER');
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
