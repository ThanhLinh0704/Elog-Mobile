import 'package:flutter_test/flutter_test.dart';
import 'package:elog_driver/features/driver_trips/presentation/state/trip_state.dart';
import 'package:elog_driver/features/driver_trips/data/models/trip_model.dart';
import 'fakes.dart';

void main() {
  group('MyTripsNotifier Tests', () {
    late FakeTripRepository fakeRepo;

    setUp(() {
      fakeRepo = FakeTripRepository();
    });

    test('should load and sort trips correctly on initialization', () async {
      fakeRepo.mockTrips = [
        const TripModel(tripId: 1, status: 'COMPLETED'),
        const TripModel(tripId: 2, status: 'IN_PROGRESS'),
        const TripModel(tripId: 3, status: 'DISPATCHED'),
        const TripModel(tripId: 4, status: 'VALIDATED'),
      ];

      final notifier = MyTripsNotifier(fakeRepo);

      // loadTrips is called on construction, we wait for it to complete
      await Future.value(); 

      expect(notifier.debugState.isLoading, isFalse);
      expect(notifier.debugState.errorMessage, isNull);
      expect(notifier.debugState.trips.length, 4);

      // Verify sorting order: IN_PROGRESS (2) -> DISPATCHED (3) -> VALIDATED (4) -> COMPLETED (1)
      expect(notifier.debugState.trips[0].tripId, 2);
      expect(notifier.debugState.trips[1].tripId, 3);
      expect(notifier.debugState.trips[2].tripId, 4);
      expect(notifier.debugState.trips[3].tripId, 1);
    });

    test('should set errorMessage when repository call fails', () async {
      fakeRepo.shouldFail = true;

      final notifier = MyTripsNotifier(fakeRepo);
      await Future.value(); 

      expect(notifier.debugState.isLoading, isFalse);
      expect(notifier.debugState.errorMessage, contains('Failed to load trips'));
      expect(notifier.debugState.trips, isEmpty);
    });

    test('should reload trips when date is changed', () async {
      final notifier = MyTripsNotifier(fakeRepo);
      await Future.value();

      fakeRepo.mockTrips = [
        const TripModel(tripId: 10, status: 'IN_PROGRESS'),
      ];

      notifier.changeDate('2026-08-08');
      await Future.value();

      expect(notifier.debugState.date, '2026-08-08');
      expect(notifier.debugState.trips.length, 1);
      expect(notifier.debugState.trips[0].tripId, 10);
    });
  });
}
