/// Mirrors backend TripProgressResponse (GET /api/v1/trips/{id}/progress).
/// Object-level authorization on this endpoint already restricts a Driver to
/// their own trip — no extra permission handling needed client-side.
class TripProgressModel {
  final int tripId;
  final String? fixedRouteCode;
  final String? deliveryDate;
  final String status;
  final double? totalDistanceKm;
  final String? routePolyline;
  final List<StopProgressModel> stops;

  const TripProgressModel({
    required this.tripId,
    this.fixedRouteCode,
    this.deliveryDate,
    required this.status,
    this.totalDistanceKm,
    this.routePolyline,
    this.stops = const [],
  });

  factory TripProgressModel.fromJson(Map<String, dynamic> json) {
    final stopsJson = json['stops'] as List<dynamic>? ?? [];
    return TripProgressModel(
      tripId: json['tripId'] as int,
      fixedRouteCode: json['fixedRouteCode'] as String?,
      deliveryDate: json['deliveryDate'] as String?,
      status: json['status'] as String? ?? '',
      totalDistanceKm: _toDouble(json['totalDistanceKm']),
      routePolyline: json['routePolyline'] as String?,
      stops: stopsJson
          .map((s) => StopProgressModel.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }
}

class StopProgressModel {
  final int tripStopId;
  final int sequenceOrder;
  final String storeCode;
  final String? storeName;
  final String status;
  final bool hasException;
  final double? latitude;
  final double? longitude;

  const StopProgressModel({
    required this.tripStopId,
    required this.sequenceOrder,
    required this.storeCode,
    this.storeName,
    required this.status,
    this.hasException = false,
    this.latitude,
    this.longitude,
  });

  bool get hasCoordinates => latitude != null && longitude != null;

  factory StopProgressModel.fromJson(Map<String, dynamic> json) =>
      StopProgressModel(
        tripStopId: json['tripStopId'] as int,
        sequenceOrder: json['sequenceOrder'] as int? ?? 0,
        storeCode: json['storeCode'] as String? ?? '',
        storeName: json['storeName'] as String?,
        status: json['status'] as String? ?? 'PENDING',
        hasException: json['hasException'] as bool? ?? false,
        latitude: _toDouble(json['latitude']),
        longitude: _toDouble(json['longitude']),
      );
}

double? _toDouble(dynamic v) {
  if (v == null) return null;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}
