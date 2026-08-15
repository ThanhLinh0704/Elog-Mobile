import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../models/trip_model.dart';
import '../models/action_results.dart';
import '../models/driver_trip_model.dart';
import '../models/trip_outcome_model.dart';
import '../models/trip_progress_model.dart';
import '../models/update_order_result_request.dart';

/// @deprecated — old stop-level rejection body.
/// Kept for backwards compatibility with old TripRepository.
class RejectDeliveryRequest {
  final String rejectionType;
  final String? description;

  const RejectDeliveryRequest({
    required this.rejectionType,
    this.description,
  });

  Map<String, dynamic> toJson() => {
        'rejectionType': rejectionType,
        if (description != null && description!.isNotEmpty)
          'description': description,
      };
}

// ── OLD TripRepository (stop-level flow — still used by legacy pages) ─────────

class TripRepository {
  final Dio _dio;

  const TripRepository(this._dio);

  // ── GET /api/v1/trips/my-trips ──────────────────────────────────────────────
  /// Driver My Trips — gets trips assigned to current user from JWT
  Future<List<TripModel>> getMyTrips({
    required String date, // yyyy-MM-dd
    String? status,
  }) async {
    try {
      final params = <String, dynamic>{'date': date};
      if (status != null && status.isNotEmpty) params['status'] = status;

      final response = await _dio.get(
        '/api/v1/trips/my-trips',
        queryParameters: params,
      );
      final body = response.data as Map<String, dynamic>;
      final list = body['data'] as List<dynamic>? ?? [];
      return list
          .map((j) => TripModel.fromJson(j as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw parseDioError(e);
    }
  }

  // ── GET /api/v1/trips/{tripId} ──────────────────────────────────────────────
  /// Trip detail — includes tripStops list
  Future<TripModel> getTripDetail(int tripId) async {
    try {
      final response = await _dio.get('/api/v1/trips/$tripId');
      final body = response.data as Map<String, dynamic>;
      return TripModel.fromJson(body['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw parseDioError(e);
    }
  }

  // ── GET /api/v1/trips/my-trips/calendar ─────────────────────────────────────
  /// Monthly summary of days that have a trip assigned to the current driver
  /// — used to render red/green dots on the date picker. Only days with at
  /// least one trip are returned.
  Future<List<TripCalendarDayModel>> getMyTripsCalendar(String month) async {
    try {
      final response = await _dio.get(
        '/api/v1/trips/my-trips/calendar',
        queryParameters: {'month': month},
      );
      final body = response.data as Map<String, dynamic>;
      final list = body['data'] as List<dynamic>? ?? [];
      return list
          .map((j) => TripCalendarDayModel.fromJson(j as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw parseDioError(e);
    }
  }

  // ── POST /api/v1/trips/{id}/start ───────────────────────────────────────────
  Future<StartTripResult> startTrip(int tripId) async {
    try {
      final response = await _dio.post('/api/v1/trips/$tripId/start');
      final body = response.data as Map<String, dynamic>;
      return StartTripResult.fromJson(body['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw parseDioError(e);
    }
  }

  // ── POST /api/v1/trip-stops/{id}/arrive ────────────────────────────────────
  Future<ArriveStopResult> arriveAtStop(int tripStopId) async {
    try {
      final response = await _dio.post('/api/v1/trip-stops/$tripStopId/arrive');
      final body = response.data as Map<String, dynamic>;
      return ArriveStopResult.fromJson(body['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw parseDioError(e);
    }
  }

  // ── POST /api/v1/trip-stops/{id}/complete ──────────────────────────────────
  Future<CompleteStopResult> completeStop(int tripStopId) async {
    try {
      final response = await _dio.post('/api/v1/trip-stops/$tripStopId/complete');
      final body = response.data as Map<String, dynamic>;
      return CompleteStopResult.fromJson(body['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw parseDioError(e);
    }
  }

  // ── GET /api/v1/trips/{id}/progress ─────────────────────────────────────────
  /// Route map data — stop coordinates + road-following route polyline.
  /// BE already restricts this to the assigned driver (object-level check),
  /// so no extra guard needed client-side.
  Future<TripProgressModel> getTripProgress(int tripId) async {
    try {
      final response = await _dio.get('/api/v1/trips/$tripId/progress');
      final body = response.data as Map<String, dynamic>;
      return TripProgressModel.fromJson(body['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw parseDioError(e);
    }
  }

  // ── POST /api/v1/trip-stops/{id}/reject ────────────────────────────────────
  Future<RejectDeliveryResult> rejectDelivery(
    int tripStopId,
    RejectDeliveryRequest request,
  ) async {
    try {
      final response = await _dio.post(
        '/api/v1/trip-stops/$tripStopId/reject',
        data: request.toJson(),
      );
      final body = response.data as Map<String, dynamic>;
      return RejectDeliveryResult.fromJson(
          body['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw parseDioError(e);
    }
  }
}

// ── NEW DriverTripRepository (order-level flow — FT-09) ──────────────────────

class DriverTripRepository {
  final Dio _dio;

  const DriverTripRepository(this._dio);

  // ── GET /api/v1/driver/trips/active ─────────────────────────────────────────
  /// Returns active TripExecution for the logged-in Driver.
  /// Returns null if data field is null (no active trip).
  Future<DriverTripModel?> getActiveTrip() async {
    try {
      final response = await _dio.get('/api/v1/driver/trips/active');
      final body = response.data as Map<String, dynamic>;
      final data = body['data'];
      if (data == null) return null;
      return DriverTripModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      throw parseDioError(e);
    }
  }

  // ── GET /api/v1/driver/trips/pending-return ─────────────────────────────────
  /// Trips that are COMPLETED / COMPLETED_WITH_EXCEPTIONS but the driver has
  /// not yet confirmed the vehicle's return to warehouse. Used as a fallback
  /// when getActiveTrip() returns null (e.g. after app restart, since the
  /// "active" endpoint excludes completed executions and local state is gone).
  Future<List<DriverTripModel>> getPendingReturnTrips() async {
    try {
      final response = await _dio.get('/api/v1/driver/trips/pending-return');
      final body = response.data as Map<String, dynamic>;
      final list = body['data'] as List<dynamic>? ?? [];
      return list
          .map((j) => DriverTripModel.fromJson(j as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw parseDioError(e);
    }
  }

  // ── POST /api/v1/driver/trips/{executionId}/start ───────────────────────────
  /// Transitions TripExecution from ASSIGNED -> IN_PROGRESS.
  Future<DriverTripModel> startExecution(int executionId) async {
    try {
      final response = await _dio.post('/api/v1/driver/trips/$executionId/start');
      final body = response.data as Map<String, dynamic>;
      return DriverTripModel.fromJson(body['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw parseDioError(e);
    }
  }

  // ── POST /api/v1/driver/trips/{executionId}/stops/{stopId}/arrive ───────────
  /// Driver taps "Đã đến điểm giao". Must be called before updating any order
  /// result for that stop (server enforces stop must be PENDING and be the
  /// next stop in sequence — PREVIOUS_STOP_NOT_DONE otherwise). Marks the
  /// stop IN_PROGRESS and records the real "actual arrival time" that the web
  /// dispatcher's "Theo dõi chuyến hàng" screen reads.
  Future<DriverTripModel> arriveAtStop(int executionId, int stopId) async {
    try {
      final response = await _dio
          .post('/api/v1/driver/trips/$executionId/stops/$stopId/arrive');
      final body = response.data as Map<String, dynamic>;
      return DriverTripModel.fromJson(body['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw parseDioError(e);
    }
  }

  // ── PUT /api/v1/driver/trips/{executionId}/orders/{orderId}/result ──────────
  /// Update delivery result for a single Order.
  /// Returns updated full DriverTripResponse (server-side state refresh).
  Future<DriverTripModel> updateOrderResult(
    int executionId,
    int orderId,
    UpdateOrderResultRequest request,
  ) async {
    try {
      final response = await _dio.put(
        '/api/v1/driver/trips/$executionId/orders/$orderId/result',
        data: request.toJson(),
      );
      final body = response.data as Map<String, dynamic>;
      return DriverTripModel.fromJson(body['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw parseDioError(e);
    }
  }

  // ── POST /api/v1/driver/trips/{executionId}/complete ────────────────────────
  /// Complete the trip. Only allowed when pendingOrdersCount == 0.
  /// Returns TripOutcomeModel with status SUBMITTED.
  Future<TripOutcomeModel> completeExecution(int executionId) async {
    try {
      final response =
          await _dio.post('/api/v1/driver/trips/$executionId/complete');
      final body = response.data as Map<String, dynamic>;
      return TripOutcomeModel.fromJson(body['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw parseDioError(e);
    }
  }

  // ── POST /api/v1/driver/trips/{executionId}/return-to-warehouse ────────────
  /// Confirms vehicle has returned to warehouse.
  Future<DriverTripModel> returnToWarehouse(int executionId) async {
    try {
      final response =
          await _dio.post('/api/v1/driver/trips/$executionId/return-to-warehouse');
      final body = response.data as Map<String, dynamic>;
      return DriverTripModel.fromJson(body['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw parseDioError(e);
    }
  }
}
