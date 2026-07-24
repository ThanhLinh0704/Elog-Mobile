import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../models/trip_model.dart';
import '../models/action_results.dart';


/// Rejection request body matching backend RejectStopRequest DTO
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

class TripRepository {
  final Dio _dio;

  const TripRepository(this._dio);

  // ── GET /api/trips/my-trips ──────────────────────────────────────────────
  /// Driver My Trips — gets trips assigned to current user from JWT
  Future<List<TripModel>> getMyTrips({
    required String date, // yyyy-MM-dd
    String? status,
  }) async {
    try {
      final params = <String, dynamic>{'date': date};
      if (status != null && status.isNotEmpty) params['status'] = status;

      final response = await _dio.get(
        '/api/trips/my-trips',
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

  // ── GET /api/trips/{tripId} ──────────────────────────────────────────────
  /// Trip detail — includes tripStops list
  Future<TripModel> getTripDetail(int tripId) async {
    try {
      final response = await _dio.get('/api/trips/$tripId');
      final body = response.data as Map<String, dynamic>;
      return TripModel.fromJson(body['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw parseDioError(e);
    }
  }

  // ── POST /api/trips/{id}/start ───────────────────────────────────────────
  Future<StartTripResult> startTrip(int tripId) async {
    try {
      final response = await _dio.post('/api/trips/$tripId/start');
      final body = response.data as Map<String, dynamic>;
      return StartTripResult.fromJson(body['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw parseDioError(e);
    }
  }

  // ── POST /api/trip-stops/{id}/arrive ────────────────────────────────────
  Future<ArriveStopResult> arriveAtStop(int tripStopId) async {
    try {
      final response = await _dio.post('/api/trip-stops/$tripStopId/arrive');
      final body = response.data as Map<String, dynamic>;
      return ArriveStopResult.fromJson(body['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw parseDioError(e);
    }
  }

  // ── POST /api/trip-stops/{id}/complete ──────────────────────────────────
  Future<CompleteStopResult> completeStop(int tripStopId) async {
    try {
      final response = await _dio.post('/api/trip-stops/$tripStopId/complete');
      final body = response.data as Map<String, dynamic>;
      return CompleteStopResult.fromJson(body['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw parseDioError(e);
    }
  }

  // ── POST /api/trip-stops/{id}/reject ────────────────────────────────────
  Future<RejectDeliveryResult> rejectDelivery(
    int tripStopId,
    RejectDeliveryRequest request,
  ) async {
    try {
      final response = await _dio.post(
        '/api/trip-stops/$tripStopId/reject',
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
