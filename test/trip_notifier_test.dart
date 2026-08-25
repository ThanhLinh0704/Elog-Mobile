import 'package:flutter_test/flutter_test.dart';
import 'package:elog_driver/features/driver_trips/presentation/state/trip_state.dart';
import 'package:elog_driver/features/driver_trips/data/models/trip_model.dart';
import 'package:elog_driver/features/driver_trips/data/models/trip_stop_model.dart';
import 'package:elog_driver/features/driver_trips/data/models/driver_trip_model.dart';
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

  group('TripDetailNotifier Tests', () {
    late FakeTripRepository fakeTripRepo;
    late FakeDriverTripRepository fakeDriverRepo;

    setUp(() {
      fakeTripRepo = FakeTripRepository();
      fakeDriverRepo = FakeDriverTripRepository();
    });

    test('should load trip detail successfully', () async {
      fakeTripRepo.mockTrips = [
        const TripModel(tripId: 100, status: 'DISPATCHED', tripStops: []),
      ];

      final notifier = TripDetailNotifier(fakeTripRepo, fakeDriverRepo, 100);
      await Future.value(); // Wait for initialization loadTrip()

      expect(notifier.debugState.isLoading, isFalse);
      expect(notifier.debugState.trip, isNotNull);
      expect(notifier.debugState.trip!.tripId, 100);
      expect(notifier.debugState.trip!.status, 'DISPATCHED');
    });

    test('should change status and load trip after startTrip is called', () async {
      fakeTripRepo.mockTrips = [
        const TripModel(tripId: 100, status: 'DISPATCHED', tripStops: []),
      ];

      final notifier = TripDetailNotifier(fakeTripRepo, fakeDriverRepo, 100);
      await Future.value();

      // Mock startTrip behavior where state changes to IN_PROGRESS on reload
      fakeTripRepo.mockTrips = [
        const TripModel(tripId: 100, status: 'IN_PROGRESS', tripStops: []),
      ];

      await notifier.startTrip();

      expect(notifier.debugState.isStartingTrip, isFalse);
      expect(notifier.debugState.trip!.status, 'IN_PROGRESS');
    });

    test('should update stop status after arriveAtStop is called', () async {
      fakeTripRepo.mockTrips = [
        const TripModel(
          tripId: 100,
          status: 'IN_PROGRESS',
          tripStops: [TripStopModel(tripStopId: 1, sequenceOrder: 1, status: 'PENDING')],
        ),
      ];

      final notifier = TripDetailNotifier(fakeTripRepo, fakeDriverRepo, 100);
      await Future.value();

      await notifier.arriveAtStop(1);

      expect(notifier.debugState.lastArriveResult, isNotNull);
      expect(notifier.debugState.lastArriveResult!.status, 'IN_PROGRESS');
      expect(notifier.debugState.trip!.tripStops[0].status, 'IN_PROGRESS');
    });

    test('should update status to EXCEPTION after rejectDelivery is called', () async {
      fakeTripRepo.mockTrips = [
        const TripModel(
          tripId: 100,
          status: 'IN_PROGRESS',
          tripStops: [TripStopModel(tripStopId: 1, sequenceOrder: 1, status: 'IN_PROGRESS')],
        ),
      ];

      final notifier = TripDetailNotifier(fakeTripRepo, fakeDriverRepo, 100);
      await Future.value();

      // Mock reject behavior on reload
      fakeTripRepo.mockTrips = [
        const TripModel(
          tripId: 100,
          status: 'IN_PROGRESS',
          tripStops: [TripStopModel(tripStopId: 1, sequenceOrder: 1, status: 'EXCEPTION')],
        ),
      ];

      await notifier.rejectDelivery(1, 'DELIVERY_REJECTION', 'Cửa hàng đóng cửa');

      expect(notifier.debugState.rejectingStops, isEmpty);
      expect(notifier.debugState.trip!.tripStops[0].status, 'EXCEPTION');
    });
  });

  group('ActiveTripNotifier Tests', () {
    late FakeDriverTripRepository fakeDriverRepo;

    setUp(() {
      fakeDriverRepo = FakeDriverTripRepository();
    });

    test('should start active trip execution successfully', () async {
      fakeDriverRepo.mockActiveTrip = const DriverTripModel(
        executionId: 50,
        tripId: 100,
        tripCode: 'TRIP-100',
        deliveryDate: '2026-08-15',
        status: ExecutionStatus.assigned,
      );

      final notifier = ActiveTripNotifier(fakeDriverRepo);
      await Future.value(); // Wait for initialization getActiveTrip()

      expect(notifier.debugState.trip!.status, ExecutionStatus.assigned);

      await notifier.startTrip();

      expect(notifier.debugState.isStarting, isFalse);
      expect(notifier.debugState.trip!.status, ExecutionStatus.inProgress);
    });

    test('should complete active trip execution successfully', () async {
      fakeDriverRepo.mockActiveTrip = const DriverTripModel(
        executionId: 50,
        tripId: 100,
        tripCode: 'TRIP-100',
        deliveryDate: '2026-08-15',
        status: ExecutionStatus.inProgress,
      );

      final notifier = ActiveTripNotifier(fakeDriverRepo);
      await Future.value();

      await notifier.completeTrip();

      expect(notifier.debugState.isCompleting, isFalse);
      expect(notifier.debugState.outcome, isNotNull);
      expect(notifier.debugState.outcome!.status, 'SUBMITTED');
      expect(notifier.debugState.trip!.status, ExecutionStatus.completed);
    });

    test('should return vehicle to warehouse successfully', () async {
      fakeDriverRepo.mockActiveTrip = const DriverTripModel(
        executionId: 50,
        tripId: 100,
        tripCode: 'TRIP-100',
        deliveryDate: '2026-08-15',
        status: ExecutionStatus.completed,
      );

      final notifier = ActiveTripNotifier(fakeDriverRepo);
      await Future.value();

      await notifier.returnToWarehouse();

      expect(notifier.debugState.isReturningToWarehouse, isFalse);
      expect(notifier.debugState.trip!.status, ExecutionStatus.completed);
    });
  });
}
