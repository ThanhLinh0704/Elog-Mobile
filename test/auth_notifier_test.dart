import 'package:flutter_test/flutter_test.dart';
import 'package:elog_driver/providers.dart';
import 'fakes.dart';

void main() {
  group('AuthNotifier Tests', () {
    late FakeSecureStorage fakeStorage;
    late FakeAuthService fakeAuthService;
    late AuthNotifier authNotifier;

    setUp(() {
      fakeStorage = FakeSecureStorage();
      fakeAuthService = FakeAuthService(fakeStorage);
      authNotifier = AuthNotifier(fakeStorage, fakeAuthService);
    });

    test('should start with logged out session state', () {
      expect(authNotifier.debugState.isLoggedIn, isFalse);
      expect(authNotifier.debugState.isDriver, isFalse);
      expect(authNotifier.debugState.username, isNull);
    });

    test('should login driver and save session details successfully', () async {
      await authNotifier.login('driver', 'password');

      expect(authNotifier.debugState.isLoggedIn, isTrue);
      expect(authNotifier.debugState.isDriver, isTrue);
      expect(authNotifier.debugState.username, 'driver');

      // Check if tokens were written to secure storage
      expect(await fakeStorage.getAccessToken(), 'fake_access_token');
      expect(await fakeStorage.isDriver(), isTrue);
    });

    test('should login non-driver user and save session with isDriver = false', () async {
      await authNotifier.login('user', 'password');

      expect(authNotifier.debugState.isLoggedIn, isTrue);
      expect(authNotifier.debugState.isDriver, isFalse);
      expect(authNotifier.debugState.username, 'user');
    });

    test('should logout and clear all session details', () async {
      // Login first
      await authNotifier.login('driver', 'password');
      expect(authNotifier.debugState.isLoggedIn, isTrue);

      // Logout
      await authNotifier.logout();

      expect(authNotifier.debugState.isLoggedIn, isFalse);
      expect(authNotifier.debugState.isDriver, isFalse);
      expect(authNotifier.debugState.username, isNull);

      // Secure storage should be cleared
      expect(await fakeStorage.getAccessToken(), isNull);
    });
  });
}
