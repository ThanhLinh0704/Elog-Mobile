import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/utils/date_time_utils.dart';
import '../../../../providers.dart';
import '../../data/models/action_results.dart';
import '../../data/models/trip_model.dart';
import '../../data/models/trip_stop_model.dart';
import '../../data/models/driver_trip_model.dart';
import '../../data/models/trip_outcome_model.dart';
import '../../data/models/update_order_result_request.dart';
import '../../data/repositories/trip_repository.dart';

String _formatError(dynamic e) {
  if (e is ApiBusinessException) return e.userMessage;
  if (e is NetworkException) return e.message;
  return e.toString();
}

// ── My Trips state ───────────────────────────────────────────────────────

class MyTripsState {
  final bool isLoading;
  final List<TripModel> trips;
  final String? errorMessage;
  final String date; // yyyy-MM-dd

  const MyTripsState({
    this.isLoading = false,
    this.trips = const [],
    this.errorMessage,
    required this.date,
  });

  MyTripsState copyWith({
    bool? isLoading,
    List<TripModel>? trips,
    String? errorMessage,
    String? date,
    bool clearError = false,
  }) {
    return MyTripsState(
      isLoading: isLoading ?? this.isLoading,
      trips: trips ?? this.trips,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      date: date ?? this.date,
    );
  }
}

class MyTripsNotifier extends StateNotifier<MyTripsState> {
  final TripRepository _repo;

  MyTripsNotifier(this._repo) : super(MyTripsState(date: todayForApi())) {
    loadTrips();
  }

  Future<void> loadTrips({String? date}) async {
    final d = date ?? state.date;
    state = state.copyWith(isLoading: true, clearError: true, date: d);
    try {
      final trips = await _repo.getMyTrips(date: d);
      // Sort by status priority then by tripId
      trips.sort((a, b) {
        const order = {
          'IN_PROGRESS': 0,
          'DISPATCHED': 1,
          'VALIDATED': 2,
          'COMPLETED': 3,
        };
        final aOrd = order[a.status.toUpperCase()] ?? 4;
        final bOrd = order[b.status.toUpperCase()] ?? 4;
        return aOrd.compareTo(bOrd);
      });
      state = state.copyWith(isLoading: false, trips: trips);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _formatError(e),
      );
    }
  }

  void changeDate(String date) {
    loadTrips(date: date);
  }
}

final myTripsProvider =
    StateNotifierProvider.autoDispose<MyTripsNotifier, MyTripsState>((ref) {
  return MyTripsNotifier(ref.watch(tripRepositoryProvider));
});

// ── Trip Calendar state (month dots for the date picker) ────────────────

class TripCalendarState {
  final bool isLoading;
  final Map<String, bool> daysWithTrips; // "yyyy-MM-dd" -> allCompleted
  final String? errorMessage;

  const TripCalendarState({
    this.isLoading = false,
    this.daysWithTrips = const {},
    this.errorMessage,
  });

  TripCalendarState copyWith({
    bool? isLoading,
    Map<String, bool>? daysWithTrips,
    String? errorMessage,
    bool clearError = false,
  }) {
    return TripCalendarState(
      isLoading: isLoading ?? this.isLoading,
      daysWithTrips: daysWithTrips ?? this.daysWithTrips,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class TripCalendarNotifier extends StateNotifier<TripCalendarState> {
  final TripRepository _repo;

  TripCalendarNotifier(this._repo) : super(const TripCalendarState());

  Future<void> loadMonth(String month) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final days = await _repo.getMyTripsCalendar(month);
      state = state.copyWith(
        isLoading: false,
        daysWithTrips: {for (final d in days) d.date: d.allCompleted},
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: _formatError(e));
    }
  }
}

final tripCalendarProvider = StateNotifierProvider.autoDispose<
    TripCalendarNotifier, TripCalendarState>((ref) {
  return TripCalendarNotifier(ref.watch(tripRepositoryProvider));
});

// ── Trip detail state ───────────────────────────────────────────────────

class TripDetailState {
  final bool isLoading;
  final TripModel? trip;
  final String? errorMessage;

  // Action loading flags
  final bool isStartingTrip;
  final Set<int> arrivingStops; // tripStopIds currently submitting arrive
  final Set<int> completingStops;
  final Set<int> rejectingStops;
  final bool isReturningToWarehouse;

  // After arrive result — to show time exception warning
  final ArriveStopResult? lastArriveResult;

  const TripDetailState({
    this.isLoading = false,
    this.trip,
    this.errorMessage,
    this.isStartingTrip = false,
    this.arrivingStops = const {},
    this.completingStops = const {},
    this.rejectingStops = const {},
    this.isReturningToWarehouse = false,
    this.lastArriveResult,
  });

  TripDetailState copyWith({
    bool? isLoading,
    TripModel? trip,
    String? errorMessage,
    bool clearError = false,
    bool? isStartingTrip,
    Set<int>? arrivingStops,
    Set<int>? completingStops,
    Set<int>? rejectingStops,
    bool? isReturningToWarehouse,
    ArriveStopResult? lastArriveResult,
    bool clearArriveResult = false,
  }) {
    return TripDetailState(
      isLoading: isLoading ?? this.isLoading,
      trip: trip ?? this.trip,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isStartingTrip: isStartingTrip ?? this.isStartingTrip,
      arrivingStops: arrivingStops ?? this.arrivingStops,
      completingStops: completingStops ?? this.completingStops,
      rejectingStops: rejectingStops ?? this.rejectingStops,
      isReturningToWarehouse:
          isReturningToWarehouse ?? this.isReturningToWarehouse,
      lastArriveResult: clearArriveResult
          ? null
          : (lastArriveResult ?? this.lastArriveResult),
    );
  }
}

class TripDetailNotifier extends StateNotifier<TripDetailState> {
  final TripRepository _repo;
  final DriverTripRepository _driverRepo;
  final int _tripId;

  TripDetailNotifier(this._repo, this._driverRepo, this._tripId)
      : super(const TripDetailState()) {
    loadTrip();
  }

  Future<void> loadTrip() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final trip = await _repo.getTripDetail(_tripId);
      // Sort stops by sequenceOrder
      final stops = List<TripStopModel>.from(trip.tripStops)
        ..sort(
            (a, b) => (a.sequenceOrder ?? 0).compareTo(b.sequenceOrder ?? 0));
      state = state.copyWith(
        isLoading: false,
        trip: TripModel(
          tripId: trip.tripId,
          tripDraftId: trip.tripDraftId,
          executionId: trip.executionId,
          returnedToWarehouseAt: trip.returnedToWarehouseAt,
          fixedRouteCode: trip.fixedRouteCode,
          deliveryDate: trip.deliveryDate,
          status: trip.status,
          vehicle: trip.vehicle,
          driver: trip.driver,
          totalWeightKg: trip.totalWeightKg,
          totalVolumeM3: trip.totalVolumeM3,
          plannedDepartureTime: trip.plannedDepartureTime,
          lockedAt: trip.lockedAt,
          completedAt: trip.completedAt,
          tripStopCount: trip.tripStopCount,
          manifestId: trip.manifestId,
          tripStops: stops,
          message: trip.message,
        ),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _formatError(e),
      );
    }
  }

  // ── Start Trip ────────────────────────────────────────────────────────

  Future<void> startTrip() async {
    state = state.copyWith(isStartingTrip: true, clearError: true);
    try {
      await _repo.startTrip(_tripId);
      // Reload trip from server to get updated status and first stop
      await loadTrip();
      state = state.copyWith(isStartingTrip: false);
    } catch (e) {
      state = state.copyWith(
        isStartingTrip: false,
        errorMessage: _formatError(e),
      );
      rethrow;
    }
  }

  // ── Arrive at Stop ────────────────────────────────────────────────────

  Future<ArriveStopResult> arriveAtStop(int tripStopId) async {
    final arriving = Set<int>.from(state.arrivingStops)..add(tripStopId);
    state = state.copyWith(arrivingStops: arriving, clearError: true);
    try {
      final result = await _repo.arriveAtStop(tripStopId);
      // Update stop in local state from response
      _updateStop(tripStopId, status: result.status);
      final notArriving = Set<int>.from(state.arrivingStops)
        ..remove(tripStopId);
      state = state.copyWith(
        arrivingStops: notArriving,
        lastArriveResult: result,
      );
      return result;
    } catch (e) {
      final notArriving = Set<int>.from(state.arrivingStops)
        ..remove(tripStopId);
      state = state.copyWith(
        arrivingStops: notArriving,
        errorMessage: _formatError(e),
      );
      rethrow;
    }
  }

  // ── Complete Stop ─────────────────────────────────────────────────────

  Future<CompleteStopResult> completeStop(int tripStopId) async {
    final completing = Set<int>.from(state.completingStops)..add(tripStopId);
    state = state.copyWith(completingStops: completing, clearError: true);
    try {
      final result = await _repo.completeStop(tripStopId);
      // Reload to get full updated state (trip may be COMPLETED, next stop etc.)
      await loadTrip();
      final notCompleting = Set<int>.from(state.completingStops)
        ..remove(tripStopId);
      state = state.copyWith(completingStops: notCompleting);
      return result;
    } catch (e) {
      final notCompleting = Set<int>.from(state.completingStops)
        ..remove(tripStopId);
      state = state.copyWith(
        completingStops: notCompleting,
        errorMessage: _formatError(e),
      );
      rethrow;
    }
  }

  // ── Reject Delivery ───────────────────────────────────────────────────

  Future<RejectDeliveryResult> rejectDelivery(
    int tripStopId,
    String rejectionType,
    String? description,
  ) async {
    final rejecting = Set<int>.from(state.rejectingStops)..add(tripStopId);
    state = state.copyWith(rejectingStops: rejecting, clearError: true);
    try {
      final request = RejectDeliveryRequest(
        rejectionType: rejectionType,
        description: description,
      );
      final result = await _repo.rejectDelivery(tripStopId, request);
      // Reload to reflect EXCEPTION status and possible Trip COMPLETED
      await loadTrip();
      final notRejecting = Set<int>.from(state.rejectingStops)
        ..remove(tripStopId);
      state = state.copyWith(rejectingStops: notRejecting);
      return result;
    } catch (e) {
      final notRejecting = Set<int>.from(state.rejectingStops)
        ..remove(tripStopId);
      state = state.copyWith(
        rejectingStops: notRejecting,
        errorMessage: _formatError(e),
      );
      rethrow;
    }
  }

  // ── Return to Warehouse ───────────────────────────────────────────────

  Future<void> returnToWarehouse() async {
    final trip = state.trip;
    if (trip == null || trip.executionId == null) return;
    state = state.copyWith(isReturningToWarehouse: true, clearError: true);
    try {
      await _driverRepo.returnToWarehouse(trip.executionId!);
      // Reload from /api/v1/trips/{tripId} to pick up the fresh returnedToWarehouseAt
      await loadTrip();
      state = state.copyWith(isReturningToWarehouse: false);
    } catch (e) {
      state = state.copyWith(
        isReturningToWarehouse: false,
        errorMessage: _formatError(e),
      );
      rethrow;
    }
  }

  void clearError() => state = state.copyWith(clearError: true);
  void clearArriveResult() => state = state.copyWith(clearArriveResult: true);

  void _updateStop(int tripStopId, {required String status}) {
    final trip = state.trip;
    if (trip == null) return;
    final updatedStops = trip.tripStops.map((s) {
      if (s.tripStopId == tripStopId) {
        return s.copyWith(status: status);
      }
      return s;
    }).toList();
    state = state.copyWith(
      trip: TripModel(
        tripId: trip.tripId,
        tripDraftId: trip.tripDraftId,
        executionId: trip.executionId,
        returnedToWarehouseAt: trip.returnedToWarehouseAt,
        fixedRouteCode: trip.fixedRouteCode,
        deliveryDate: trip.deliveryDate,
        status: trip.status,
        vehicle: trip.vehicle,
        driver: trip.driver,
        totalWeightKg: trip.totalWeightKg,
        totalVolumeM3: trip.totalVolumeM3,
        plannedDepartureTime: trip.plannedDepartureTime,
        lockedAt: trip.lockedAt,
        completedAt: trip.completedAt,
        tripStopCount: trip.tripStopCount,
        manifestId: trip.manifestId,
        tripStops: updatedStops,
        message: trip.message,
      ),
    );
  }
}

final tripDetailProvider = StateNotifierProvider.autoDispose
    .family<TripDetailNotifier, TripDetailState, int>((ref, tripId) {
  return TripDetailNotifier(
    ref.watch(tripRepositoryProvider),
    ref.watch(driverTripRepositoryProvider),
    tripId,
  );
});

// ── NEW Active Trip state (FT-09 order-level execution) ────────────────────────

class ActiveTripState {
  final bool isLoading;
  final DriverTripModel? trip;
  final TripOutcomeModel? outcome;
  final String? errorMessage;
  final bool isStarting;
  final bool isCompleting;
  final bool isReturningToWarehouse;
  final int? updatingOrderId;

  const ActiveTripState({
    this.isLoading = false,
    this.trip,
    this.outcome,
    this.errorMessage,
    this.isStarting = false,
    this.isCompleting = false,
    this.isReturningToWarehouse = false,
    this.updatingOrderId,
  });

  ActiveTripState copyWith({
    bool? isLoading,
    DriverTripModel? trip,
    bool clearTrip = false,
    TripOutcomeModel? outcome,
    bool clearOutcome = false,
    String? errorMessage,
    bool clearError = false,
    bool? isStarting,
    bool? isCompleting,
    bool? isReturningToWarehouse,
    int? updatingOrderId,
    bool clearUpdatingOrderId = false,
  }) {
    return ActiveTripState(
      isLoading: isLoading ?? this.isLoading,
      trip: clearTrip ? null : (trip ?? this.trip),
      outcome: clearOutcome ? null : (outcome ?? this.outcome),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isStarting: isStarting ?? this.isStarting,
      isCompleting: isCompleting ?? this.isCompleting,
      isReturningToWarehouse:
          isReturningToWarehouse ?? this.isReturningToWarehouse,
      updatingOrderId: clearUpdatingOrderId
          ? null
          : (updatingOrderId ?? this.updatingOrderId),
    );
  }
}

class ActiveTripNotifier extends StateNotifier<ActiveTripState> {
  final DriverTripRepository _repo;

  ActiveTripNotifier(this._repo) : super(const ActiveTripState()) {
    loadActiveTrip();
  }

  Future<void> loadActiveTrip() async {
    state =
        state.copyWith(isLoading: true, clearError: true, clearOutcome: true);
    try {
      final fetched = await _repo.getActiveTrip();
      if (fetched != null) {
        state = state.copyWith(isLoading: false, trip: fetched);
        return;
      }
      // Backend's "active" endpoint only matches ASSIGNED/IN_PROGRESS executions,
      // so a trip that was just completed but not yet confirmed back at the
      // warehouse will never come back from getActiveTrip(). Ask the server
      // directly instead of trusting local state, which is gone after an app
      // restart or provider dispose (this used to strand drivers on "Bận").
      final pending = await _repo.getPendingReturnTrips();
      state = state.copyWith(
        isLoading: false,
        trip: pending.isNotEmpty ? pending.first : null,
        clearTrip: pending.isEmpty,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _formatError(e),
      );
    }
  }

  Future<void> startTrip() async {
    final trip = state.trip;
    if (trip == null) return;
    state = state.copyWith(isStarting: true, clearError: true);
    try {
      final updated = await _repo.startExecution(trip.executionId);
      state = state.copyWith(isStarting: false, trip: updated);
    } catch (e) {
      state = state.copyWith(
        isStarting: false,
        errorMessage: _formatError(e),
      );
      rethrow;
    }
  }

  Future<void> updateOrderResult(
      int orderId, UpdateOrderResultRequest req) async {
    final trip = state.trip;
    if (trip == null) return;
    state = state.copyWith(updatingOrderId: orderId, clearError: true);
    try {
      final updated =
          await _repo.updateOrderResult(trip.executionId, orderId, req);
      state = state.copyWith(clearUpdatingOrderId: true, trip: updated);
    } catch (e) {
      state = state.copyWith(
        clearUpdatingOrderId: true,
        errorMessage: _formatError(e),
      );
      rethrow;
    }
  }

  Future<void> completeTrip() async {
    final trip = state.trip;
    if (trip == null) return;
    state = state.copyWith(isCompleting: true, clearError: true);
    try {
      final outcome = await _repo.completeExecution(trip.executionId);
      // getActiveTrip() would return null here (backend excludes COMPLETED
      // executions from the "active" query), so derive the post-complete trip
      // state locally instead of trusting a refetch to bring it back.
      final hasExceptions = outcome.failedCount > 0 || outcome.partialCount > 0;
      final updatedTrip = trip.copyWith(
        status: hasExceptions
            ? ExecutionStatus.completedWithExceptions
            : ExecutionStatus.completed,
        completedOrdersCount: outcome.totalOrders,
        pendingOrdersCount: 0,
      );
      state = state.copyWith(
        isCompleting: false,
        trip: updatedTrip,
        outcome: outcome,
      );
    } catch (e) {
      state = state.copyWith(
        isCompleting: false,
        errorMessage: _formatError(e),
      );
      rethrow;
    }
  }

  Future<void> returnToWarehouse() async {
    final trip = state.trip;
    if (trip == null) return;
    state = state.copyWith(isReturningToWarehouse: true, clearError: true);
    try {
      final updated = await _repo.returnToWarehouse(trip.executionId);
      state = state.copyWith(
        isReturningToWarehouse: false,
        trip: updated,
      );
    } catch (e) {
      state = state.copyWith(
        isReturningToWarehouse: false,
        errorMessage: _formatError(e),
      );
      rethrow;
    }
  }

  void clearError() => state = state.copyWith(clearError: true);
}

final activeTripProvider =
    StateNotifierProvider.autoDispose<ActiveTripNotifier, ActiveTripState>(
        (ref) {
  return ActiveTripNotifier(ref.watch(driverTripRepositoryProvider));
});
