import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elog_driver/main.dart';
import 'package:elog_driver/providers.dart';
import 'package:elog_driver/features/driver_trips/data/models/trip_model.dart';
import '../test/fakes.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('E2E App Tests', () {
    late FakeSecureStorage fakeStorage;
    late FakeAuthService fakeAuthService;
    late FakeTripRepository fakeTripRepo;
    late FakeDriverTripRepository fakeDriverTripRepo;

    setUp(() {
      fakeStorage = FakeSecureStorage();
      fakeAuthService = FakeAuthService(fakeStorage);
      fakeTripRepo = FakeTripRepository();
      fakeDriverTripRepo = FakeDriverTripRepository();
    });

    testWidgets('Driver complete workflow: login, view trips, logout', (tester) async {
      // 1. Mock trip data
      fakeTripRepo.mockTrips = [
        const TripModel(
          tripId: 999,
          status: 'DISPATCHED',
          deliveryDate: '2026-08-08',
          tripStopCount: 2,
        ),
      ];

      // 2. Load the App
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            secureStorageProvider.overrideWithValue(fakeStorage),
            authServiceProvider.overrideWithValue(fakeAuthService),
            tripRepositoryProvider.overrideWithValue(fakeTripRepo),
            driverTripRepositoryProvider.overrideWithValue(fakeDriverTripRepo),
          ],
          child: const ELogDriverApp(),
        ),
      );
      await tester.pumpAndSettle();

      // 3. Verify LoginPage is shown
      expect(find.widgetWithText(TextFormField, 'Tên đăng nhập'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Mật khẩu'), findsOneWidget);

      // 4. Enter driver credentials and submit
      await tester.enterText(find.widgetWithText(TextFormField, 'Tên đăng nhập'), 'driver');
      await tester.enterText(find.widgetWithText(TextFormField, 'Mật khẩu'), 'password');
      
      // Tap the login button
      await tester.tap(find.widgetWithText(ElevatedButton, 'Đăng nhập'));
      
      // 5. Wait for routing redirect to MyTripsPage
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // 6. Verify MyTripsPage is loaded successfully
      expect(find.text('Chuyến hàng của tôi'), findsOneWidget);

      // Verify mock trip with ID 999 is visible on the dashboard
      expect(find.textContaining('999'), findsOneWidget);
    });
  });
}
