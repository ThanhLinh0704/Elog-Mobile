import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../core/network/dio_client.dart';
import '../core/storage/secure_storage_service.dart';
import '../features/auth/data/auth_service.dart';
import '../features/driver_trips/data/repositories/trip_repository.dart';

// ── Infrastructure providers ──────────────────────────────────────────────

final secureStorageProvider = Provider<SecureStorageService>(
  (ref) => SecureStorageService(),
);

final dioProvider = Provider<Dio>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return createDioClient(storage);
});

// ── Service/Repository providers ──────────────────────────────────────────

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(dioProvider), ref.watch(secureStorageProvider));
});

final tripRepositoryProvider = Provider<TripRepository>((ref) {
  return TripRepository(ref.watch(dioProvider));
});

// ── Auth session state ────────────────────────────────────────────────────

class AuthSession {
  final bool isLoggedIn;
  final bool isDriver;
  final String? username;
  final String? fullName;

  const AuthSession({
    this.isLoggedIn = false,
    this.isDriver = false,
    this.username,
    this.fullName,
  });

  AuthSession copyWith({
    bool? isLoggedIn,
    bool? isDriver,
    String? username,
    String? fullName,
  }) {
    return AuthSession(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      isDriver: isDriver ?? this.isDriver,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthSession> {
  final SecureStorageService _storage;
  final AuthService _authService;

  AuthNotifier(this._storage, this._authService) : super(const AuthSession()) {
    _init();
  }

  Future<void> _init() async {
    final loggedIn = await _storage.isLoggedIn();
    if (loggedIn) {
      final isDriver = await _storage.isDriver();
      final username = await _storage.getUsername();
      final fullName = await _storage.getFullName();
      state = AuthSession(
        isLoggedIn: true,
        isDriver: isDriver,
        username: username,
        fullName: fullName,
      );
    }
  }

  Future<void> login(String username, String password) async {
    final result = await _authService.login(
      username: username,
      password: password,
    );
    final roles = (result['roles'] as List<String>?) ?? [];
    final isDriver = roles.contains('DRIVER');
    final uname = result['username'] as String? ?? username;
    state = AuthSession(
      isLoggedIn: true,
      isDriver: isDriver,
      username: uname,
      fullName: uname,
    );
  }

  Future<void> logout() async {
    await _authService.logout();
    state = const AuthSession();
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthSession>((ref) {
  return AuthNotifier(
    ref.watch(secureStorageProvider),
    ref.watch(authServiceProvider),
  );
});
