import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elog_driver/features/auth/presentation/login_page.dart';
import 'package:elog_driver/providers.dart';
import 'fakes.dart';

void main() {
  group('LoginPage Widget Tests', () {
    late FakeSecureStorage fakeStorage;
    late FakeAuthService fakeAuthService;

    setUp(() {
      fakeStorage = FakeSecureStorage();
      fakeAuthService = FakeAuthService(fakeStorage);
    });

    Widget createTestableWidget() {
      return ProviderScope(
        overrides: [
          secureStorageProvider.overrideWithValue(fakeStorage),
          authServiceProvider.overrideWithValue(fakeAuthService),
        ],
        child: const MaterialApp(
          home: LoginPage(),
        ),
      );
    }

    testWidgets('should render input fields and login button', (tester) async {
      await tester.pumpWidget(createTestableWidget());

      expect(find.widgetWithText(TextFormField, 'Tên đăng nhập'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Mật khẩu'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Đăng nhập'), findsOneWidget);
    });

    testWidgets('should show validation errors if fields are empty', (tester) async {
      await tester.pumpWidget(createTestableWidget());

      // Tap Login button immediately without inputs
      await tester.tap(find.widgetWithText(ElevatedButton, 'Đăng nhập'));
      await tester.pumpAndSettle();

      expect(find.text('Vui lòng nhập tên đăng nhập'), findsOneWidget);
      expect(find.text('Vui lòng nhập mật khẩu'), findsOneWidget);
    });

    testWidgets('should show error banner when user is not a driver', (tester) async {
      await tester.pumpWidget(createTestableWidget());

      // Enter normal user credentials
      await tester.enterText(find.widgetWithText(TextFormField, 'Tên đăng nhập'), 'user');
      await tester.enterText(find.widgetWithText(TextFormField, 'Mật khẩu'), 'password');

      await tester.tap(find.widgetWithText(ElevatedButton, 'Đăng nhập'));
      await tester.pumpAndSettle();

      // Should show the not driver error message
      expect(find.textContaining('không phải tài khoản Driver'), findsOneWidget);
    });

    testWidgets('should submit successfully with driver credentials', (tester) async {
      await tester.pumpWidget(createTestableWidget());

      // Enter driver credentials
      await tester.enterText(find.widgetWithText(TextFormField, 'Tên đăng nhập'), 'driver');
      await tester.enterText(find.widgetWithText(TextFormField, 'Mật khẩu'), 'password');

      await tester.tap(find.widgetWithText(ElevatedButton, 'Đăng nhập'));
      await tester.pump(); // Start auth request loading
      await tester.pump(const Duration(milliseconds: 100)); // Finish load and logic

      // Loader indicator should show or form submitted successfully
      expect(find.text('Vui lòng nhập tên đăng nhập'), findsNothing);
      expect(find.text('Vui lòng nhập mật khẩu'), findsNothing);
    });
  });
}
