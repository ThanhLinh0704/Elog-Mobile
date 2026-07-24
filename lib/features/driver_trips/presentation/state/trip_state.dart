import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/utils/date_time_utils.dart';
import '../../../../providers.dart';
import '../../data/models/action_results.dart';
import '../../data/models/trip_model.dart';
import '../../data/models/trip_stop_model.dart';
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
      lastArriveResult: clearArriveResult
          ? null
          : (lastArriveResult ?? this.lastArriveResult),
    );
  }
}

class TripDetailNotifier extends StateNotifier<TripDetailState> {
  final TripRepository _repo;
  final int _tripId;

  TripDetailNotifier(this._repo, this._tripId)
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
  return TripDetailNotifier(ref.watch(tripRepositoryProvider), tripId);
});
