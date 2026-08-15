import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elog_driver/main.dart';
import 'package:elog_driver/providers.dart';
import 'package:elog_driver/features/driver_trips/data/models/trip_model.dart';
import 'package:elog_driver/features/driver_trips/data/models/trip_stop_model.dart';
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

      // 7. Tap on the trip card to open TripDetailPage
      await tester.tap(find.textContaining('999'));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Verify TripDetailPage is loaded
      expect(find.text('Chi tiết chuyến đi'), findsOneWidget);
      expect(find.text('BẮT ĐẦU CHUYẾN ĐI'), findsOneWidget);

      // 8. Start the trip
      await tester.tap(find.text('BẮT ĐẦU CHUYẾN ĐI'));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Verify status changed (button changes text or status label updates)
      expect(find.text('BẮT ĐẦU CHUYẾN ĐI'), findsNothing);

      // 9. Arrive at the first stop (mock stop ID 1)
      expect(find.text('BÁO ĐẾN'), findsOneWidget);
      await tester.tap(find.text('BÁO ĐẾN'));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // 10. Complete the stop (mock delivery action)
      expect(find.text('HOÀN THÀNH'), findsOneWidget);
      await tester.tap(find.text('HOÀN THÀNH'));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // 11. Complete the trip (once all stops are completed)
      expect(find.text('HOÀN THÀNH CHUYẾN ĐI'), findsOneWidget);
      await tester.tap(find.text('HOÀN THÀNH CHUYẾN ĐI'));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Verify outcome summary screen shows status SUBMITTED
      expect(find.text('BÁO CÁO KẾT QUẢ'), findsOneWidget);
      expect(find.text('XÁC NHẬN TRẢ XE VỀ KHO'), findsOneWidget);

      // 12. Return vehicle to warehouse
      await tester.tap(find.text('XÁC NHẬN TRẢ XE VỀ KHO'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify returned successfully, back to completed state
      expect(find.text('Đã bàn giao xe'), findsOneWidget);
    });

    testWidgets('Driver workflow: login, start trip, reject stop with reason', (tester) async {
      // 1. Mock trip data with 1 pending stop
      fakeTripRepo.mockTrips = [
        const TripModel(
          tripId: 888,
          status: 'DISPATCHED',
          deliveryDate: '2026-08-08',
          tripStopCount: 1,
          tripStops: [TripStopModel(tripStopId: 1, sequenceOrder: 1, status: 'PENDING')],
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

      // 3. Login
      await tester.enterText(find.widgetWithText(TextFormField, 'Tên đăng nhập'), 'driver');
      await tester.enterText(find.widgetWithText(TextFormField, 'Mật khẩu'), 'password');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Đăng nhập'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // 4. Open Trip Detail
      await tester.tap(find.textContaining('888'));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // 5. Start Trip
      await tester.tap(find.text('BẮT ĐẦU CHUYẾN ĐI'));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // 6. Arrive at Stop
      await tester.tap(find.text('BÁO ĐẾN'));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // 7. Tap Reject button
      expect(find.text('TỪ CHỐI'), findsOneWidget);
      await tester.tap(find.text('TỪ CHỐI'));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Verify Rejection Bottom Sheet is visible
      expect(find.text('Báo cáo sự cố'), findsOneWidget);
      expect(find.text('Chọn lý do từ chối'), findsOneWidget);

      // Select a reason (mock tap on option)
      await tester.tap(find.text('Cửa hàng đóng cửa'));
      await tester.pumpAndSettle();

      // Submit rejection
      await tester.tap(find.text('XÁC NHẬN GỬI'));
      
      // Mock reload state where stop is EXCEPTION
      fakeTripRepo.mockTrips = [
        const TripModel(
          tripId: 888,
          status: 'IN_PROGRESS',
          tripStops: [TripStopModel(tripStopId: 1, sequenceOrder: 1, status: 'EXCEPTION')],
        ),
      ];
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // 8. Verify status updated to exception
      expect(find.text('Sự cố giao hàng'), findsOneWidget);
    });
  });
}
