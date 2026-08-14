import 'package:flutter/foundation.dart';

/// Production override, set at build time via:
///   flutter build apk --dart-define=API_BASE_URL=https://api.elog.click
/// Must NOT include a trailing "/api/v1" — every request path already
/// starts with "/api/v1/..." (see auth_service.dart, trip_repository.dart),
/// so appending it here would double the prefix and 404 every request.
const String _apiBaseUrlOverride = String.fromEnvironment('API_BASE_URL');

/// Dynamic API base URL based on running platform:
/// - Android Emulator: http://10.0.2.2:8080
/// - Web / Windows Desktop / iOS Simulator: http://localhost:8080
String get kBaseUrl {
  if (_apiBaseUrlOverride.isNotEmpty) {
    return _apiBaseUrlOverride;
  }
  if (kIsWeb) {
    return 'http://localhost:8080';
  }
  if (defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:8080';
  }
  return 'http://localhost:8080';
}

// Token storage keys
const String kAccessTokenKey = 'access_token';
const String kRefreshTokenKey = 'refresh_token';
const String kUsernameKey = 'username';
const String kRolesKey = 'roles';
const String kUserIdKey = 'user_id';
const String kFullNameKey = 'full_name';
