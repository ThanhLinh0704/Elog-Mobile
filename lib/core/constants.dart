import 'package:flutter/foundation.dart';

/// Dynamic API base URL based on running platform:
/// - Android Emulator: http://10.0.2.2:8080
/// - Web / Windows Desktop / iOS Simulator: http://localhost:8080
String get kBaseUrl {
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
